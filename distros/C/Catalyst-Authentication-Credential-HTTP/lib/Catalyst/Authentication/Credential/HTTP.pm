package Catalyst::Authentication::Credential::HTTP;
use base qw/Catalyst::Authentication::Credential::Password/;

use strict;
use warnings;

use String::Escape ();
use URI::Escape    ();
use Catalyst       ();
use Digest::MD5    ();

__PACKAGE__->mk_accessors(qw/
    _config
    authorization_required_message
    password_field
    username_field
    type
    realm
    algorithm
    use_uri_for
    no_unprompted_authorization_required
    require_ssl
    broken_dotnet_digest_without_query_string
/);

our $VERSION = '1.016';

sub new {
    my ($class, $config, $app, $realm) = @_;

    $config->{username_field} ||= 'username';
    # _config is shity back-compat with our base class.
    my $self = { %$config, _config => $config, _debug => $app->debug ? 1 : 0 };
    bless $self, $class;

    $self->realm($realm);

    $self->init;
    return $self;
}

sub init {
    my ($self) = @_;
    my $type = $self->type || 'any';

    if (!grep /$type/, ('basic', 'digest', 'any')) {
        Catalyst::Exception->throw(__PACKAGE__ . " used with unsupported authentication type: " . $type);
    }
    $self->type($type);
}

sub authenticate {
    my ( $self, $c, $realm, $auth_info ) = @_;
    my $auth;

    $self->authentication_failed( $c, $realm, $auth_info )
        if $self->require_ssl ? $c->req->base->scheme ne 'https' : 0;

    $auth = $self->authenticate_digest($c, $realm, $auth_info) if $self->_is_http_auth_type('digest');
    return $auth if $auth;

    $auth = $self->authenticate_basic($c, $realm, $auth_info) if $self->_is_http_auth_type('basic');
    return $auth if $auth;

    $self->authentication_failed( $c, $realm, $auth_info );
}

sub authentication_failed {
    my ( $self, $c, $realm, $auth_info ) = @_;
    unless ($self->no_unprompted_authorization_required) {
        $self->authorization_required_response($c, $realm, $auth_info);
        die $Catalyst::DETACH;
    }
}

sub authenticate_basic {
    my ( $self, $c, $realm, $auth_info ) = @_;

    $c->log->debug('Checking http basic authentication.') if $c->debug;

    my $headers = $c->req->headers;

    if ( my ( $username, $password ) = $headers->authorization_basic ) {
	    my $user_obj = $realm->find_user( { $self->username_field => $username }, $c);
	    if (ref($user_obj)) {
            my $opts = {};
            $opts->{$self->password_field} = $password
                if $self->password_field;
            if ($self->check_password($user_obj, $opts)) {
                return $user_obj;
            }
            else {
                $c->log->debug("Password mismatch!") if $c->debug;
                return;
            }
         }
         else {
             $c->log->debug("Unable to locate user matching user info provided")
                if $c->debug;
            return;
        }
    }

    return;
}

sub authenticate_digest {
    my ( $self, $c, $realm, $auth_info ) = @_;

    $c->log->debug('Checking http digest authentication.') if $c->debug;

    my $headers       = $c->req->headers;
    my @authorization = $headers->header('Authorization');
    foreach my $authorization (@authorization) {
        next unless $authorization =~ m{^Digest};
        my %res = map {
            my @key_val = split /=/, $_, 2;
            $key_val[0] = lc $key_val[0];
            $key_val[1] =~ s{"}{}g;    # remove the quotes
            @key_val;
        } split /,\s?/, substr( $authorization, 7 );    #7 == length "Digest "

        my $opaque = $res{opaque};
        my $nonce  = $self->get_digest_authorization_nonce( $c, __PACKAGE__ . '::opaque:' . $opaque );
        next unless $nonce;

        $c->log->debug('Checking authentication parameters.')
          if $c->debug;

        my $uri         = $c->request->uri->path_query;
        my $algorithm   = $res{algorithm} || 'MD5';
        my $nonce_count = '0x' . $res{nc};

        my $check = ($uri eq $res{uri} ||
                     ($self->broken_dotnet_digest_without_query_string &&
                      $c->request->uri->path eq $res{uri}))
          && ( exists $res{username} )
          && ( exists $res{qop} )
          && ( exists $res{cnonce} )
          && ( exists $res{nc} )
          && $algorithm eq $nonce->algorithm
          && hex($nonce_count) > hex( $nonce->nonce_count )
          && $res{nonce} eq $nonce->nonce;    # TODO: set Stale instead

        unless ($check) {
            $c->log->debug('Digest authentication failed. Bad request.')
              if $c->debug;
            $c->res->status(400);             # bad request
            Carp::confess $Catalyst::DETACH;
        }

        $c->log->debug('Checking authentication response.')
          if $c->debug;

        my $username = $res{username};

        my $user_obj;

        unless ( $user_obj = $auth_info->{user} ) {
            $user_obj = $realm->find_user( { $self->username_field => $username }, $c);
        }
        unless ($user_obj) {    # no user, no authentication
            $c->log->debug("Unable to locate user matching user info provided") if $c->debug;
            return;
        }

        # everything looks good, let's check the response
        # calculate H(A2) as per spec
        my $ctx = Digest::MD5->new;
        $ctx->add( join( ':', $c->request->method, $res{uri} ) );
        if ( $res{qop} eq 'auth-int' ) {
            my $digest =
              Digest::MD5::md5_hex( $c->request->body );    # not sure here
            $ctx->add( ':', $digest );
        }
        my $A2_digest = $ctx->hexdigest;

        # the idea of the for loop:
        # if we do not want to store the plain password in our user store,
        # we can store md5_hex("$username:$realm:$password") instead
        my $password_field = $self->password_field;
        for my $r ( 0 .. 1 ) {
            # calculate H(A1) as per spec
            my $A1_digest = $r ? $user_obj->$password_field() : do {
                $ctx = Digest::MD5->new;
                $ctx->add( join( ':', $username, $realm->name, $user_obj->$password_field() ) );
                $ctx->hexdigest;
            };
            if ( $nonce->algorithm eq 'MD5-sess' ) {
                $ctx = Digest::MD5->new;
                $ctx->add( join( ':', $A1_digest, $res{nonce}, $res{cnonce} ) );
                $A1_digest = $ctx->hexdigest;
            }

            my $digest_in = join( ':',
                    $A1_digest, $res{nonce},
                    $res{qop} ? ( $res{nc}, $res{cnonce}, $res{qop} ) : (),
                    $A2_digest );
            my $rq_digest = Digest::MD5::md5_hex($digest_in);
            $nonce->nonce_count($nonce_count);
            my $key = __PACKAGE__ . '::opaque:' . $nonce->opaque;
            $self->store_digest_authorization_nonce( $c, $key, $nonce );
            if ($rq_digest eq $res{response}) {
                return $user_obj;
            }
        }
    }
    return;
}

sub _check_cache {
    my $c = shift;

    die "A cache is needed for http digest authentication."
      unless $c->can('cache');
    return;
}

sub _is_http_auth_type {
    my ( $self, $type ) = @_;
    my $cfgtype = lc( $self->type );
    return 1 if $cfgtype eq 'any' || $cfgtype eq lc $type;
    return 0;
}

sub authorization_required_response {
    my ( $self, $c, $realm, $auth_info ) = @_;

    $c->res->status(401);
    $c->res->content_type('text/plain');
    if (exists $self->{authorization_required_message}) {
        # If you set the key to undef, don't stamp on the body.
        $c->res->body($self->authorization_required_message)
            if defined $self->authorization_required_message;
    }
    else {
        $c->res->body('Authorization required.');
    }

    # *DONT* short circuit
    my $ok;
    $ok++ if $self->_create_digest_auth_response($c, $auth_info);
    $ok++ if $self->_create_basic_auth_response($c, $auth_info);

    unless ( $ok ) {
        die 'Could not build authorization required response. '
        . 'Did you configure a valid authentication http type: '
        . 'basic, digest, any';
    }
    return;
}

sub _add_authentication_header {
    my ( $c, $header ) = @_;
    $c->response->headers->push_header( 'WWW-Authenticate' => $header );
    return;
}

sub _create_digest_auth_response {
    my ( $self, $c, $opts ) = @_;

    return unless $self->_is_http_auth_type('digest');

    if ( my $digest = $self->_build_digest_auth_header( $c, $opts ) ) {
        _add_authentication_header( $c, $digest );
        return 1;
    }

    return;
}

sub _create_basic_auth_response {
    my ( $self, $c, $opts ) = @_;

    return unless $self->_is_http_auth_type('basic');

    if ( my $basic = $self->_build_basic_auth_header( $c, $opts ) ) {
        _add_authentication_header( $c, $basic );
        return 1;
    }

    return;
}

sub _build_auth_header_realm {
    my ( $self, $c, $opts ) = @_;
    if ( my $realm_name = String::Escape::qprintable($opts->{realm} ? $opts->{realm} : $self->realm->name) ) {
        $realm_name = qq{"$realm_name"} unless $realm_name =~ /^"/;
        return 'realm=' . $realm_name;
    }
    return;
}

sub _build_auth_header_domain {
    my ( $self, $c, $opts ) = @_;
    if ( my $domain = $opts->{domain} ) {
        Catalyst::Exception->throw("domain must be an array reference")
          unless ref($domain) && ref($domain) eq "ARRAY";

        my @uris =
          $self->use_uri_for
          ? ( map { $c->uri_for($_) } @$domain )
          : ( map { URI::Escape::uri_escape($_) } @$domain );

        return qq{domain="@uris"};
    }
    return;
}

sub _build_auth_header_common {
    my ( $self, $c, $opts ) = @_;
    return (
        $self->_build_auth_header_realm($c, $opts),
        $self->_build_auth_header_domain($c, $opts),
    );
}

sub _build_basic_auth_header {
    my ( $self, $c, $opts ) = @_;
    return _join_auth_header_parts( Basic => $self->_build_auth_header_common( $c, $opts ) );
}

sub _build_digest_auth_header {
    my ( $self, $c, $opts ) = @_;

    my $nonce = $self->_digest_auth_nonce($c, $opts);

    my $key = __PACKAGE__ . '::opaque:' . $nonce->opaque;

    $self->store_digest_authorization_nonce( $c, $key, $nonce );

    return _join_auth_header_parts( Digest =>
        $self->_build_auth_header_common($c, $opts),
        map { sprintf '%s="%s"', $_, $nonce->$_ } qw(
            qop
            nonce
            opaque
            algorithm
        ),
    );
}

sub _digest_auth_nonce {
    my ( $self, $c, $opts ) = @_;

    my $package = __PACKAGE__ . '::Nonce';

    my $nonce   = $package->new;

    if ( my $algorithm = $opts->{algorithm} || $self->algorithm) {
        $nonce->algorithm( $algorithm );
    }

    return $nonce;
}

sub _join_auth_header_parts {
    my ( $type, @parts ) = @_;
    return "$type " . join(", ", @parts );
}

sub get_digest_authorization_nonce {
    my ( $self, $c, $key ) = @_;

    _check_cache($c);
    return $c->cache->get( $key );
}

sub store_digest_authorization_nonce {
    my ( $self, $c, $key, $nonce ) = @_;

    _check_cache($c);
    return $c->cache->set( $key, $nonce );
}

package Catalyst::Authentication::Credential::HTTP::Nonce;

use strict;
use base qw[ Class::Accessor::Fast ];
use Data::UUID ();

our $VERSION = '0.02';

__PACKAGE__->mk_accessors(qw[ nonce nonce_count qop opaque algorithm ]);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->nonce( Data::UUID->new->create_b64 );
    $self->opaque( Data::UUID->new->create_b64 );
    $self->qop('auth,auth-int');
    $self->nonce_count('0x0');
    $self->algorithm('MD5');

    return $self;
}

1;

__END__

=pod

=head1 NAME

Catalyst::Authentication::Credential::HTTP - HTTP Basic and Digest authentication
for Catalyst.

=head1 SYNOPSIS

    use Catalyst qw/
        Authentication
    /;

    __PACKAGE__->config( authentication => {
        default_realm => 'example',
        realms => {
            example => {
                credential => {
                    class => 'HTTP',
                    type  => 'any', # or 'digest' or 'basic'
                    password_type  => 'clear',
                    password_field => 'password'
                },
                store => {
                    class => 'Minimal',
                    users => {
                        Mufasa => { password => "Circle Of Life", },
                    },
                },
            },
        }
    });

    sub foo : Local {
        my ( $self, $c ) = @_;

        $c->authenticate({}, "example");
        # either user gets authenticated or 401 is sent
        # Note that the authentication realm sent to the client (in the
        # RFC 2617 sense) is overridden here, but this *does not*
        # effect the Catalyst::Authentication::Realm used for
        # authentication - to do that, you need
        # $c->authenticate({}, 'otherrealm')

        do_stuff();
    }

    sub always_auth : Local {
        my ( $self, $c ) = @_;

        # Force authorization headers onto the response so that the user
        # is asked again for authentication, even if they successfully
        # authenticated.
        my $realm = $c->get_auth_realm('example');
        $realm->credential->authorization_required_response($c, $realm);
    }

    # with ACL plugin
    __PACKAGE__->deny_access_unless("/path", sub { $_[0]->authenticate });

=head1 DESCRIPTION

This module lets you use HTTP authentication with
L<Catalyst::Plugin::Authentication>. Both basic and digest authentication
are currently supported.

When authentication is required, this module sets a status of 401, and
the body of the response to 'Authorization required.'. To override
this and set your own content, check for the C<< $c->res->status ==
401 >> in your C<end> action, and change the body accordingly.

=head2 TERMS

=over 4

=item Nonce

A nonce is a one-time value sent with each digest authentication
request header. The value must always be unique, so per default the
last value of the nonce is kept using L<Catalyst::Plugin::Cache>. To
change this behaviour, override the
C<store_digest_authorization_nonce> and
C<get_digest_authorization_nonce> methods as shown below.

=back

=head1 METHODS

=over 4

=item new $config, $c, $realm

Simple constructor.

=item init

Validates that $config is ok.

=item authenticate $c, $realm, \%auth_info

Tries to authenticate the user, and if that fails calls
C<authorization_required_response> and detaches the current action call stack.

Looks inside C<< $c->request->headers >> and processes the digest and basic
(badly named) authorization header.

This will only try the methods set in the configuration. First digest, then basic.

The %auth_info hash can contain a number of keys which control the authentication behaviour:

=over

=item realm

Sets the HTTP authentication realm presented to the client. Note this does not alter the
Catalyst::Authentication::Realm object used for the authentication.

=item domain

Array reference to domains used to build the authorization headers.

This list of domains defines the protection space. If a domain URI is an
absolute path (starts with /), it is relative to the root URL of the server being accessed.
An absolute URI in this list may refer to a different server than the one being accessed.

The client will use this list to determine the set of URIs for which the same authentication
information may be sent.

If this is omitted or its value is empty, the client will assume that the
protection space consists of all URIs on the responding server.

Therefore, if your application is not hosted at the root of this domain, and you want to
prevent the authentication credentials for this application being sent to any other applications.
then you should use the I<use_uri_for> configuration option, and pass a domain of I</>.

=back

=item authenticate_basic $c, $realm, \%auth_info

Performs HTTP basic authentication.

=item authenticate_digest $c, $realm, \%auth_info

Performs HTTP digest authentication.

The password_type B<must> be I<clear> for digest authentication to
succeed.  If you do not want to store your user passwords as clear
text, you may instead store the MD5 digest in hex of the string
'$username:$realm:$password'.

L<Catalyst::Plugin::Cache> is used for persistent storage of the nonce
values (see L</Nonce>).  It must be loaded in your application, unless
you override the C<store_digest_authorization_nonce> and
C<get_digest_authorization_nonce> methods as shown below.

Takes an additional parameter of I<algorithm>, the possible values of which are 'MD5' (the default)
and 'MD5-sess'. For more information about 'MD5-sess', see section 3.2.2.2 in RFC 2617.

=item authorization_required_response $c, $realm, \%auth_info

Sets C<< $c->response >> to the correct status code, and adds the correct
header to demand authentication data from the user agent.

Typically used by C<authenticate>, but may be invoked manually.

%opts can contain C<domain> and C<algorithm>, which are used to build
%the digest header.

=item store_digest_authorization_nonce $c, $key, $nonce

=item get_digest_authorization_nonce $c, $key

Set or get the C<$nonce> object used by the digest auth mode.

You may override these methods. By default they will call C<get> and C<set> on
C<< $c->cache >>.

=item authentication_failed

Sets the 401 response and calls C<< $ctx->detach >>.

=back

=head1 CONFIGURATION

All configuration is stored in C<< YourApp->config('Plugin::Authentication' => { yourrealm => { credential => { class => 'HTTP', %config } } } >>.

This should be a hash, and it can contain the following entries:

=over

=item type

Can be either C<any> (the default), C<basic> or C<digest>.

This controls C<authorization_required_response> and C<authenticate>, but
not the "manual" methods.

=item authorization_required_message

Set this to a string to override the default body content "Authorization required.", or set to undef to suppress body content being generated.

=item password_type

The type of password returned by the user object. Same usage as in
L<Catalyst::Authentication::Credential::Password|Catalyst::Authentication::Credential::Password/password_type>

=item password_field

The name of accessor used to retrieve the value of the password field from the user object. Same usage as in
L<Catalyst::Authentication::Credential::Password|Catalyst::Authentication::Credential::Password/password_field>

=item username_field

The field name that the user's username is mapped into when finding the user from the realm. Defaults to 'username'.

=item use_uri_for

If this configuration key has a true value, then the domain(s) for the authorization header will be
run through $c->uri_for(). Use this configuration option if your application is not running at the root
of your domain, and you want to ensure that authentication credentials from your application are not shared with
other applications on the same server.

=item require_ssl

If this configuration key has a true value then authentication will be denied
(and a 401 issued in normal circumstances) unless the request is via https.

=item no_unprompted_authorization_required

Causes authentication to fail as normal modules do, without calling
C<< $c->detach >>. This means that the basic auth credential can be used as
part of the progressive realm.

However use like this is probably not optimum it also means that users in
browsers ill never get a HTTP authenticate dialogue box (unless you manually
return a 401 response in your application), and even some automated
user agents (for APIs) will not send the Authorization header without
specific manipulation of the request headers.

=item broken_dotnet_digest_without_query_string

Enables support for .NET (or other similarly broken clients), which
fails to include the query string in the uri in the digest
Authorization header, contrary to rfc2617.

This option has no effect on clients that include the query string;
they will continue to work as normal.

=back

=head1 RESTRICTIONS

When using digest authentication, this module will only work together
with authentication stores whose User objects have a C<password>
method that returns the plain-text password. It will not work together
with L<Catalyst::Authentication::Store::Htpasswd>, or
L<Catalyst::Authentication::Store::DBIC> stores whose
C<password> methods return a hashed or salted version of the password.

=head1 AUTHORS

Updated to current name space and currently maintained
by: Tomas Doran C<bobtfish@bobtfish.net>.

Original module by:

=over

=item Yuval Kogman, C<nothingmuch@woobling.org>

=item Jess Robinson

=item Sascha Kiefer C<esskar@cpan.org>

=back

=head1 CONTRIBUTORS

Patches contributed by:

=over

=item Peter Corlett

=item Devin Austin (dhoss) C<dhoss@cpan.org>

=item Ronald J Kimball

=back

=head1 SEE ALSO

RFC 2617 (or its successors), L<Catalyst::Plugin::Cache>, L<Catalyst::Plugin::Authentication>

=head1 COPYRIGHT & LICENSE

        Copyright (c) 2005-2008 the aforementioned authors. All rights
        reserved. This program is free software; you can redistribute
        it and/or modify it under the same terms as Perl itself.

=cut

