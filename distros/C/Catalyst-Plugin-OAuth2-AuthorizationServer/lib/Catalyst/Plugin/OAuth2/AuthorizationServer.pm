package Catalyst::Plugin::OAuth2::AuthorizationServer;
use v5.36;
use Scalar::Util qw/blessed/;
use JSON::MaybeXS ();
use Try::Tiny;
use URI;
use Catalyst::Plugin::OAuth2::AuthorizationServer::Server;
use Catalyst::Plugin::OAuth2::AuthorizationServer::Error;

our $VERSION = '0.003';

my $CONFIG_KEY = 'Catalyst::Plugin::OAuth2::AuthorizationServer';
my $JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

# Build a per-request engine from app config. Stateless: the only stateful
# collaborator is the app-provided Store, resolved fresh each call.
sub _oauth_engine ( $c ) {
    my %cfg = %{ $c->config->{$CONFIG_KEY} // {} };

    my $store = delete $cfg{store};
    $store = $c->model($store) if defined $store && !blessed $store;
    Catalyst::Exception->throw("OAuth2 AS: no Store configured")
        unless blessed $store;

    return Catalyst::Plugin::OAuth2::AuthorizationServer::Server->new(
        store => $store, %cfg );
}

# Slurp + decode a JSON request body (DCR). Returns a hashref or throws a
# 400 invalid_request.
sub _oauth_json_body ( $c ) {
    my $body = $c->request->body;
    my $raw  = q{};
    if ( defined $body && ref $body ) {
        binmode $body; seek $body, 0, 0; local $/ = undef; $raw = <$body> // q{};
    }
    elsif ( defined $body ) { $raw = $body }
    my $data = try { $JSON->decode($raw) }
        catch { undef };
    Catalyst::Plugin::OAuth2::AuthorizationServer::Error->throw(
        error => 'invalid_request', error_description => 'invalid JSON body',
        http_status => 400 )
        unless ref $data eq 'HASH';
    return $data;
}

# Catalyst delivers a repeated query/body parameter as an arrayref. RFC 6749
# 3.2.1 requires a request that repeats a parameter to be rejected, rather than
# quietly picking one of the values (which lets an attacker show one value to a
# validating layer and another to a consuming one). This check runs before any
# validation, so the error deliberately carries no redirect_uri: the authorize
# seam then renders it directly instead of 302ing to an unvalidated,
# client-supplied redirect_uri.
sub _oauth_params ( $c, $params ) {
    my %out;
    for my $k ( keys %$params ) {
        my $v = $params->{$k};
        if ( ref $v eq 'ARRAY' ) {
            Catalyst::Plugin::OAuth2::AuthorizationServer::Error->throw(
                error             => 'invalid_request',
                error_description => 'request parameters must not be repeated',
                http_status       => 400,
            ) if @$v > 1;
            $v = $v->[0];
        }
        $out{$k} = $v;
    }
    return \%out;
}

sub oauth_error ( $c, $error, $status = 400, $desc = undef ) {
    my %body = ( error => $error );
    $body{error_description} = $desc if defined $desc;
    my $res = $c->response;
    $res->status($status);
    $res->content_type('application/json');
    $res->header( 'Cache-Control' => 'no-store' );
    $res->body( $JSON->encode( \%body ) );
    return;
}

# Render any caught error: our structured Error -> its envelope; anything else
# -> a generic 500 server_error (text never leaked).
sub _oauth_render_error ( $c, $err ) {
    if ( blessed $err
        && $err->isa('Catalyst::Plugin::OAuth2::AuthorizationServer::Error') )
    {
        my ( $body, $status ) = $err->to_response;
        my $res = $c->response;
        $res->status($status);
        $res->content_type('application/json');
        $res->header( 'Cache-Control' => 'no-store' );
        $res->body( $JSON->encode($body) );
        return;
    }
    return $c->oauth_error( 'server_error', 500 );
}

sub oauth_metadata ( $c ) {
    my $doc = $c->_oauth_engine->metadata_document;
    my $res = $c->response;
    $res->status(200);
    $res->content_type('application/json');
    $res->body( $JSON->encode($doc) );
    return;
}

sub oauth_register ( $c ) {
    return try {
        if ( $c->can('oauth_dcr_allow_registration')
            && !$c->oauth_dcr_allow_registration )
        {
            return $c->oauth_error( 'too_many_requests', 429,
                'registration rate limit exceeded' );
        }
        my $metadata = $c->_oauth_json_body;
        my $client   = $c->_oauth_engine->register_client($metadata);
        my $res = $c->response;
        $res->status(201);
        $res->content_type('application/json');
        $res->header( 'Cache-Control' => 'no-store' );
        $res->body( $JSON->encode($client) );
        return;
    }
    catch { $c->_oauth_render_error($_) };
}

sub oauth_authorize ( $c ) {
    return try {
        my $params = $c->_oauth_params( $c->request->query_parameters );
        my $out    = $c->_oauth_engine->validate_authorize($params);
        # Hand off to the app's authn/consent hook with the opaque request_id.
        return $c->oauth_authenticate( $out->{request_id} );
    }
    catch {
        my $err = $_;
        # Redirect-safe authorize errors (client + redirect_uri already valid)
        # go back to the client per RFC 6749 4.1.2.1; the rest render directly.
        if ( blessed $err
            && $err->isa('Catalyst::Plugin::OAuth2::AuthorizationServer::Error')
            && defined $err->redirect_uri )
        {
            my $uri = URI->new( $err->redirect_uri );
            $uri->query_form(
                error => $err->error,
                ( defined $err->error_description
                    ? ( error_description => $err->error_description ) : () ),
                ( defined $err->state ? ( state => $err->state ) : () ),
            );
            $c->response->redirect( $uri, 302 );
            return;
        }
        return $c->_oauth_render_error($err);
    };
}

# Called BY the app once the user has consented. On success returns
# { code, redirect_uri, state }. On a handled error (unknown/expired/replayed
# request) it renders the OAuth error envelope and returns undef, so callers
# must check: my $out = $c->oauth_issue_code(...); return unless $out;
sub oauth_issue_code ( $c, $subject, $request_id ) {
    return try {
        $c->_oauth_engine->issue_code( $subject, $request_id );
    }
    catch {
        $c->_oauth_render_error($_);
        undef;
    };
}

sub oauth_token ( $c ) {
    return try {
        my $p   = $c->_oauth_params( $c->request->body_parameters );
        my $eng = $c->_oauth_engine;
        my $gt  = $p->{grant_type};
        Catalyst::Plugin::OAuth2::AuthorizationServer::Error->throw(
            error => 'invalid_request',
            error_description => 'grant_type is required',
            http_status => 400,
        ) unless defined $gt && length $gt;
        my $tok =
              $gt eq 'authorization_code' ? $eng->exchange_authorization_code($p)
            : $gt eq 'refresh_token'      ? $eng->refresh($p)
            : Catalyst::Plugin::OAuth2::AuthorizationServer::Error->throw(
                error => 'unsupported_grant_type',
                error_description => 'unsupported grant_type',
                http_status => 400 );
        my $res = $c->response;
        $res->status(200);
        $res->content_type('application/json');
        $res->header( 'Cache-Control' => 'no-store' );
        $res->body( $JSON->encode($tok) );
        return;
    }
    catch { $c->_oauth_render_error($_) };
}

=head1 NAME

Catalyst::Plugin::OAuth2::AuthorizationServer - MCP-profile OAuth 2.1
Authorization Server plugin for Catalyst

=head1 SYNOPSIS

    package MyApp;
    use Catalyst qw/+Catalyst::Plugin::OAuth2::AuthorizationServer/;

    __PACKAGE__->config(
        'Catalyst::Plugin::OAuth2::AuthorizationServer' => {
            store       => 'OAuth::Store',           # $c->model name, or an object
            signing_key => $ENV{MCP_OAUTH_JWT_KEY},
            issuer      => 'https://api.example',
            resource    => 'https://api.example/mcp',
            scopes_supported => [ 'example:read' ],
        },
    );

    # the app provides the authn/consent hook; the plugin calls it after it has
    # validated /authorize and stashed the request under an opaque request_id
    sub oauth_authenticate ( $c, $request_id ) {
        # 302 to your SPA consent route carrying $request_id; after consent the
        # SPA posts back and you call $c->oauth_issue_code($user_id, $request_id)
    }

    __PACKAGE__->setup;

In a controller, mount the routes onto the plugin methods: C<oauth_metadata>,
C<oauth_register>, C<oauth_authorize>, C<oauth_token>.

=head1 DESCRIPTION

Adds an OAuth 2.1 Authorization Server (the MCP profile: public PKCE-S256
client, C<authorization_code> + C<refresh_token> grants, Dynamic Client
Registration, and AS metadata) to a Catalyst application. The protocol engine
lives in L<Catalyst::Plugin::OAuth2::AuthorizationServer::Server>; this module
is the thin Catalyst seam.

Access tokens are signed with a symmetric HMAC algorithm only: C<jwt_alg> may
be C<HS256> (the default), C<HS384> or C<HS512>, and C<signing_key> must be at
least 32, 48 or 64 bytes respectively (RFC 7518 3.2). Asymmetric signing and
C<alg=none> are not supported and no JWKS is published, which is deliberate
for the MCP single-server profile: the Authorization Server and the Resource
Server share a deployment and a key. If you need an AS whose tokens are
verified by a third party you do not share a secret with, this is not that
plugin.

Repeated request parameters are rejected with C<invalid_request> rather than
collapsed to a single value (RFC 6749 3.2.1).

=head1 METHODS

=head2 oauth_metadata

Render the RFC 8414 Authorization Server Metadata document as C<200 application/json>.

=head2 oauth_register

Dynamic Client Registration endpoint (RFC 7591). Calls the optional app hook
C<oauth_dcr_allow_registration($c)> first: if it returns false, responds 429.
Reads a JSON body, calls the engine's C<register_client>, and writes C<201>
JSON with C<Cache-Control: no-store>. Metadata that asks for something the AS
metadata does not advertise is rejected with C<invalid_client_metadata>; see
L<Catalyst::Plugin::OAuth2::AuthorizationServer::Server/register_client> for
exactly what is enforced.

=head2 oauth_authorize

Validates the authorize query parameters via the engine. On success, calls the
app hook C<oauth_authenticate($c, $request_id)> (see below). On a redirect-safe
error (valid client + redirect_uri already confirmed), redirects to the
C<redirect_uri> with C<error=> and C<state=> params (RFC 6749 4.1.2.1).
Otherwise renders a JSON error envelope directly.

=head2 oauth_issue_code( $subject, $request_id )

Called BY the app (typically inside C<oauth_authenticate>) once the user has
consented. Returns C<{ code, redirect_uri, state }> on success, or C<undef>
if the request_id is unknown/expired (in which case the OAuth error envelope
has already been rendered). Callers must check the return value:
C<< my $out = $c->oauth_issue_code(...); return unless $out; >>

=head2 oauth_token

Reads form parameters, dispatches C<authorization_code> or C<refresh_token>
grants via the engine, writes C<200> JSON with C<Cache-Control: no-store>.

=head2 oauth_error( $error, $status, $desc )

Render a bare OAuth error envelope. C<$status> defaults to 400; C<$desc> is
optional.

=head1 APP HOOKS

The consuming Catalyst application must provide:

=head2 oauth_authenticate( $c, $request_id )

Called by C<oauth_authorize> after the request is validated. A real app would
redirect to a login/consent page. In that page handler, call
C<< $c->oauth_issue_code($subject, $request_id) >> and redirect to the
returned C<redirect_uri> carrying the C<code> (and C<state>).

=head2 oauth_dcr_allow_registration( $c )   (optional)

If present and returns false, C<oauth_register> responds 429
C<too_many_requests>. Use for rate-limiting DCR.

=head1 LIMITATIONS

Refresh-token reuse revokes the whole token family (RFC 9700): when a rotated
token is replayed, every refresh token descended from the same authorization
is revoked, including the one the legitimate client currently holds. Reuse
detection depends on the Store retaining rotated tokens until they expire; see
C<rotate_refresh_token> in
L<Catalyst::Plugin::OAuth2::AuthorizationServer::Role::Store>.

B<Security limitation:> revoking the family does B<not> kill access tokens
already minted from it. They are stateless JWTs, verified without consulting
the Store, and stay valid until C<access_ttl> elapses. Keep C<access_ttl>
short. Access tokens carry a C<jti> claim so a denylist can be added later
without changing the token format, but this plugin implements no denylist and
no RFC 7009 revocation endpoint.

A concurrent double-refresh (the same token presented twice at once, with no
attacker involved) is indistinguishable from a replay and will revoke the
family. This is inherent to RFC 9700 reuse detection. Both requests fail: the
one that lost the race is rejected as a replay, and the one still in flight is
refused when it tries to persist its successor into the now-revoked family, so
it answers C<invalid_grant> rather than surviving with a live token. The client
must start a new authorization.

Apps can call C<revoke_refresh_tokens_for_subject> on logout/deactivation.

Pruning revoked refresh tokens after they expire is the host application's
responsibility, as is garbage-collecting abandoned Dynamic Client
Registrations (clients that never completed a token exchange): the Store has
the visibility to identify and remove them. This plugin tracks no client
usage.

=head1 EXAMPLES

A runnable example lives in F<examples/>: a small Catalyst app exposing the
metadata, dynamic client registration, authorize, and token endpoints backed
by an in-memory store, plus a core-Perl client that drives the full
authorization-code + PKCE flow. Start it with C<plackup examples/app.psgi>
and run C<perl examples/client.pl>. See F<examples/README.md>.

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
