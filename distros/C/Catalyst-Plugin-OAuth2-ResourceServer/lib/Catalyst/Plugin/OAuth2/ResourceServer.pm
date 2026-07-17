package Catalyst::Plugin::OAuth2::ResourceServer;
use v5.36;
use Scalar::Util qw/blessed/;
use JSON::MaybeXS ();
use Try::Tiny;
use URI ();
use Catalyst::Plugin::OAuth2::ResourceServer::Server;
use Catalyst::Plugin::OAuth2::ResourceServer::Error;

our $VERSION = '0.003';

my $CONFIG_KEY = 'Catalyst::Plugin::OAuth2::ResourceServer';
my $SLOT       = 'Catalyst::Plugin::OAuth2::ResourceServer/ctx';
my $JSON       = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub _oauth_rs_config ( $c ) { return $c->config->{$CONFIG_KEY} // {} }

# RFC 7230 quoted-string: backslash-escape `\` and `"` so a value carrying
# either cannot terminate the quoted-string or forge extra auth-params.
# A plain function, not a method.
sub _oauth_rs_quote_hval ( $value ) {
    my $v = $value // '';
    $v =~ s/([\\"])/\\$1/g;
    return $v;
}

# RFC 9728 3.1: derive the protected-resource metadata URL from the resource
# identifier by inserting the well-known segment after the authority, before
# the resource's path. This is only defined for an http(s) resource id: for a
# URN or any other non-hierarchical scheme there is no authority to insert
# after, so return undef and let the caller omit the parameter rather than
# emit a malformed one. A plain function, not a method.
sub _oauth_rs_metadata_url ( $base ) {
    return undef unless defined $base && length $base;
    my $u = URI->new($base);
    return undef unless $u->can('scheme') && defined $u->scheme;
    return undef unless $u->scheme =~ /\A https? \z/xi;
    return undef unless $u->can('authority') && $u->can('path');
    return undef unless defined $u->authority && length $u->authority;
    my $path = $u->path // '';
    $path = '' if $path eq '/';
    $u->path( '/.well-known/oauth-protected-resource' . $path );
    return $u->as_string;
}

# Per-request engine built from config. Only the engine's own attrs are passed
# (StrictConstructor rejects the seam/metadata-only keys).
sub _oauth_rs_engine ( $c ) {
    my $cfg = $c->_oauth_rs_config;
    return Catalyst::Plugin::OAuth2::ResourceServer::Server->new(
        map { exists $cfg->{$_} ? ( $_ => $cfg->{$_} ) : () }
            qw/signing_key resource issuer jwt_alg leeway/
    );
}

# Write a WWW-Authenticate: Bearer challenge. $err is an optional ...::Error.
sub oauth_challenge ( $c, $err = undef ) {
    my $status = ( $err && $err->http_status ) ? $err->http_status : 401;
    my @p;
    push @p, sprintf( 'error="%s"', _oauth_rs_quote_hval( $err->error ) )
        if $err && defined $err->error;
    push @p,
        sprintf( 'error_description="%s"',
        _oauth_rs_quote_hval( $err->error_description ) )
        if $err && defined $err->error_description;
    push @p, sprintf( 'scope="%s"', _oauth_rs_quote_hval( $err->scope ) )
        if $err && defined $err->scope;
    if ( $status == 401 ) {
        my $cfg  = $c->_oauth_rs_config;
        my $base = ref $cfg->{resource} eq 'ARRAY'
            ? ( $cfg->{resource}[0] // '' )
            : ( $cfg->{resource} // '' );
        # An explicit override always wins; otherwise derive it, which only
        # works for an http(s) resource id.
        my $url = $cfg->{resource_metadata_url} // _oauth_rs_metadata_url($base);
        if ( defined $url && length $url ) {
            push @p,
                sprintf( 'resource_metadata="%s"', _oauth_rs_quote_hval($url) );
        }
        else {
            # Warn once per process: omitting the parameter is correct, but the
            # deployer probably wants to set resource_metadata_url explicitly.
            state $warned = 0;
            $c->log->warn( 'OAuth2 RS: cannot derive resource_metadata from a '
                    . 'non-http(s) resource identifier; set resource_metadata_url '
                    . 'explicitly to advertise it in 401 challenges' )
                if !$warned++ && $c->can('log');
        }
    }
    my $hdr = 'Bearer' . ( @p ? ' ' . join( ', ', @p ) : '' );

    my $res = $c->response;
    $res->status($status);
    $res->header( 'WWW-Authenticate' => $hdr );
    $res->header( 'Cache-Control'    => 'no-store' );
    $res->content_type('application/json');
    $res->body(
        $JSON->encode( { ( $err && defined $err->error ) ? ( error => $err->error ) : () } ) );
    return;
}

sub oauth_protect ( $c ) {
    my $auth = $c->request->header('Authorization') // '';
    # RFC 7235 auth-scheme names are case-insensitive.
    my ($jwt) = $auth =~ /\A Bearer \s+ (\S+) \z/xi;
    unless ( defined $jwt && length $jwt ) {
        # RFC 6750 section 3: a malformed *Bearer* attempt is invalid_request; an
        # absent header or a different/unsupported scheme gets a bare 401.
        if ( $auth =~ /\A \s* Bearer \b/xi ) {
            $c->oauth_challenge(
                Catalyst::Plugin::OAuth2::ResourceServer::Error->new(
                    error => 'invalid_request', http_status => 400 ) );
        }
        else {
            $c->oauth_challenge;    # no credentials -> plain 401
        }
        return 0;
    }

    # Token verification: a structured Error is a token failure (-> its 401);
    # anything else (engine misconfig, internal bug) is a 500, never invalid_token.
    my $verified = 1;
    my $claims = try {
        $c->_oauth_rs_engine->verify_token($jwt);
    }
    catch {
        if ( blessed $_
            && $_->isa('Catalyst::Plugin::OAuth2::ResourceServer::Error') )
        {
            $c->oauth_challenge($_);
        }
        else {
            # Deliberately a fixed string: this path is credential-adjacent and
            # the exception could carry token material.
            $c->log->error('OAuth2 RS: token verification failed')
                if $c->can('log');
            $c->_oauth_server_error;
        }
        $verified = 0;
        undef;
    };
    return 0 unless $verified;

    # Subject resolution is an app hook; a die in it is an internal error (500),
    # NOT an invalid_token. An undef return means the subject is rejected (401).
    my $identity;
    if ( $c->can('oauth_resolve_subject') ) {
        my $resolved = 1;
        $identity = try {
            $c->oauth_resolve_subject($claims);
        }
        catch {
            # Fixed string for the same reason as the verify_token catch above:
            # the hook is handed the verified claims, so an exception raised in
            # it can carry them into the log. The host app is better placed to
            # log its own failure detail than we are to guess what is safe.
            $c->log->error('OAuth2 RS: oauth_resolve_subject died')
                if $c->can('log');
            $c->_oauth_server_error;
            $resolved = 0;
            undef;
        };
        return 0 unless $resolved;
        unless ($identity) {
            # subject rejected -> generic 401 (no account-state leak)
            $c->oauth_challenge(
                Catalyst::Plugin::OAuth2::ResourceServer::Error->new(
                    error => 'invalid_token', http_status => 401 ) );
            return 0;
        }
    }

    $c->stash->{$SLOT} = { claims => $claims, identity => $identity };
    return 1;
}

# Render a clean 500 for an internal/operational failure (engine misconfig, a
# die in an app hook): never leak the underlying reason to the client.
sub _oauth_server_error ( $c ) {
    my $res = $c->response;
    $res->status(500);
    $res->content_type('application/json');
    $res->header( 'Cache-Control' => 'no-store' );
    $res->body( $JSON->encode( { error => 'server_error' } ) );
    return;
}

sub oauth_claims ( $c )   { return ( $c->stash->{$SLOT} // {} )->{claims} }
sub oauth_identity ( $c ) { return ( $c->stash->{$SLOT} // {} )->{identity} }

sub oauth_scopes ( $c ) {
    my $claims = $c->oauth_claims or return ();
    my $s = $claims->{scope};
    return ()  unless defined $s;
    return @$s if ref $s eq 'ARRAY';   # some ASes emit scope as a JSON array
    return ()  unless length $s;
    return split ' ', $s;
}

sub oauth_assert_scope ( $c, @required ) {
    # oauth_protect must have run; without verified claims this is an
    # unauthenticated request (401), not insufficient scope (403).
    unless ( $c->stash->{$SLOT} ) {
        $c->oauth_challenge;    # bare 401
        return 0;
    }
    my %have = map { $_ => 1 } $c->oauth_scopes;
    my @missing = grep { !$have{$_} } @required;
    if (@missing) {
        $c->oauth_challenge(
            Catalyst::Plugin::OAuth2::ResourceServer::Error->new(
                error       => 'insufficient_scope',
                http_status => 403,
                scope       => join( ' ', @required ),
            )
        );
        return 0;
    }
    return 1;
}

sub oauth_protected_resource_metadata ( $c ) {
    my $cfg = $c->_oauth_rs_config;
    # RFC 9728 `resource` is a single identifier string. `resource` config may
    # be an arrayref (the engine matches aud against any of them); advertise the
    # first as the canonical resource id.
    my $resource = ref $cfg->{resource} eq 'ARRAY'
        ? $cfg->{resource}[0]
        : $cfg->{resource};
    my %doc = (
        resource                 => $resource,
        authorization_servers    => $cfg->{authorization_servers} // [],
        bearer_methods_supported => ['header'],
    );
    $doc{scopes_supported} = $cfg->{scopes_supported} if $cfg->{scopes_supported};
    my $res = $c->response;
    $res->status(200);
    $res->content_type('application/json');
    $res->header( 'Cache-Control' => 'no-store' );
    $res->body( $JSON->encode( \%doc ) );
    return;
}

=head1 NAME

Catalyst::Plugin::OAuth2::ResourceServer - MCP-profile OAuth 2.1 Resource
Server plugin for Catalyst

=head1 SYNOPSIS

    package MyApp;
    use Catalyst qw/+Catalyst::Plugin::OAuth2::ResourceServer/;

    __PACKAGE__->config(
        'Catalyst::Plugin::OAuth2::ResourceServer' => {
            signing_key           => $ENV{MCP_OAUTH_JWT_KEY},  # same key the AS mints with
            resource              => 'https://api.example/mcp',
            issuer                => 'https://api.example',
            authorization_servers => ['https://api.example'],
            scopes_supported      => ['example:read'],
        },
    );

    # re-validate the subject on every request; return undef to force a 401
    sub oauth_resolve_subject ( $c, $claims ) {
        my $user = MyApp::User->active->find( $claims->{sub} ) or return undef;
        return $user;
    }

    __PACKAGE__->setup;

    # in a controller
    sub mcp :Path('/mcp') :Args(0) {
        my ( $self, $c ) = @_;
        return unless $c->oauth_protect;
        return unless $c->oauth_assert_scope('example:read');
        # $c->oauth_identity / $c->oauth_claims now available
    }

Mount C<oauth_protected_resource_metadata> at
C</.well-known/oauth-protected-resource>.

=head1 CONFIGURATION

Configuration is supplied under the key C<Catalyst::Plugin::OAuth2::ResourceServer>
in the Catalyst app config. The seam reads keys by name, so a typo'd key is
silently ignored (a missing I<required> engine key such as C<signing_key> still
croaks at construction, but a typo'd C<authorization_servers> just yields an
empty list in the metadata document).

=over 4

=item C<signing_key> (required)

The symmetric key (plain string for HS256/HS384/HS512) used to verify bearer
JWTs. Must match the key the Authorization Server mints with.

=item C<resource> (required)

The resource identifier (URI string, or arrayref of URIs) used to verify the
C<aud> claim. The first element is advertised as the canonical resource id in
the metadata document.

=item C<issuer> (required)

The expected C<iss> claim value; tokens from other issuers are rejected.

=item C<jwt_alg>

The permitted JWT algorithm. Defaults to C<HS256>; supported values are
C<HS256>, C<HS384>, C<HS512>.

=item C<leeway>

Seconds of clock-skew leeway for C<exp>, C<nbf> and C<iat> verification.
Default 0.

=item C<authorization_servers>

Arrayref of Authorization Server URIs. Included in the RFC 9728 metadata
document; not used for token verification. A typo here yields an empty list
in the metadata: it is not caught at construction.

=item C<scopes_supported>

Optional arrayref of scope strings to advertise in the metadata document.

=item C<resource_metadata_url>

Override for the C<resource_metadata> URI embedded in 401 challenges. When set,
it is used verbatim and always wins over the derivation below.

When it is not set, the URI is derived from the first C<resource> value per
RFC 9728 section 3.1: the C</.well-known/oauth-protected-resource> segment is
inserted after the authority and before any path of the resource. So
C<https://api.example.com/v1> derives
C<https://api.example.com/.well-known/oauth-protected-resource/v1>, and
C<https://api.example.com> derives
C<https://api.example.com/.well-known/oauth-protected-resource>.

B<Derivation only works for an C<http> or C<https> resource identifier.> A URN
(C<urn:example:resource>) or any other non-hierarchical scheme has no authority
to insert the well-known segment after, so nothing can be derived: the
C<resource_metadata> parameter is then B<omitted> from the challenge (which
remains a valid RFC 6750 C<Bearer> challenge; C<resource_metadata> is optional)
and a warning is logged once per process. If your C<resource> is not an http(s)
URI and you want 401 challenges to advertise your metadata document, you must
set C<resource_metadata_url> explicitly.

=back

=head1 DESCRIPTION

Protects Catalyst routes with OAuth 2.1 bearer tokens: verifies the access-token
JWT, calls an app-supplied subject resolver, exposes claims/scopes, and emits
RFC 6750 challenges + an RFC 9728 protected-resource metadata document. The
verification engine lives in
L<Catalyst::Plugin::OAuth2::ResourceServer::Server>; this module is the thin
Catalyst seam.

Challenge and metadata responses are sent with C<Cache-Control: no-store>. The
consuming application is responsible for setting an appropriate C<Cache-Control>
on its own protected responses (RFC 6750 section 5.3).

=head1 METHODS

=head2 oauth_protect

    return unless $c->oauth_protect;

Extracts a C<Bearer> token from the C<Authorization> header (scheme name is
case-insensitive per RFC 7235), verifies it via the engine, and optionally
calls the app hook C<oauth_resolve_subject>. Returns true on success and stashes
identity + claims; writes a 401 challenge and returns false on failure.

=head2 oauth_assert_scope( @required )

    return unless $c->oauth_assert_scope('example:read', 'example:write');

Returns true if all required scopes are present in the verified token; writes a
403 C<insufficient_scope> challenge and returns false otherwise. Call after
C<oauth_protect>.

=head2 oauth_claims

Returns the raw decoded JWT claims hashref (after a successful C<oauth_protect>),
or C<undef>.

=head2 oauth_scopes

Returns the list of scopes from the token's C<scope> claim (split on whitespace),
or an empty list.

=head2 oauth_identity

Returns the identity value returned by C<oauth_resolve_subject> (if the hook was
defined), or C<undef>.

=head2 oauth_protected_resource_metadata

Emits the RFC 9728 protected-resource metadata JSON document with
C<Cache-Control: no-store>. Mount at
C</.well-known/oauth-protected-resource>.

=head2 oauth_challenge( $err )

    $c->oauth_challenge;                       # plain 401
    $c->oauth_challenge( $err_obj );           # 401/403 with error= params

Writes a C<WWW-Authenticate: Bearer> response. C<$err> is an optional
L<Catalyst::Plugin::OAuth2::ResourceServer::Error> object. 401 responses
include a C<resource_metadata> parameter whenever one is available: either
configured via C<resource_metadata_url> or derivable from an http(s)
C<resource> (see L</CONFIGURATION>). All parameter values are escaped as
RFC 7230 quoted-strings.

=head1 APP HOOKS

=head2 oauth_resolve_subject( $c, $claims )

Optional method the consuming application may define. Receives the Catalyst
context and the decoded JWT claims hashref; should return an identity value
(any truthy scalar or hashref) to allow the request, or C<undef> to reject
it with a generic 401 C<invalid_token> challenge.

B<Security note:> if you do not provide C<oauth_resolve_subject>, C<oauth_protect>
accepts any cryptographically valid, non-expired token without checking whether
the subject still exists or is active. Token revocation and account-deactivation
enforcement depend entirely on this hook; omitting it means a revoked subject's
token keeps working until it expires. Also: C<oauth_identity> is C<undef> when no
resolver is defined, so guard before dereferencing it.

=head1 EXAMPLES

A runnable example lives in F<examples/>: a small Catalyst app protecting
C</api/whoami> with a Bearer token, plus a core-Perl client that mints its own
demo JWT (via C<Crypt::JWT>) to exercise it. Start it with
C<plackup examples/app.psgi> and run C<perl examples/client.pl>. See
F<examples/README.md>.

=head1 AUTHOR

Mike Whitaker <mike@altrion.org>

Built with tool assistance from Claude Code/(mostly) Opus 4.8 to accelerate
code generation and maximise test coverage (and reduce typing :D).

With thanks to

=over

=item *

Jesse Vincent for C</superpowers> (L<https://github.com/obra/superpowers>) and
the C<AGENTS.md> boilerplate

=item *

Curtis "Ovid" Poe for C</paad> (L<https://github.com/Ovid/paad>)

=back

for providing an agentic development framework that keeps code authority
firmly where it belongs.

Iteratively reviewed by Finn Kempers <finn@shadow.cat> with analysis from
ZCode/GLM-5.2.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License, as distributed with Perl.

=cut

1;
