package Dancer2::Plugin::OAuth2::Server;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.10';
use Dancer2::Plugin;
use URI;
use URI::QueryParam;
use Class::Load qw(try_load_class);
use Carp;

sub get_server_class {
    my ($settings) = @_;
    my $server_class = $settings->{server_class}//"Dancer2::Plugin::OAuth2::Server::Simple";
    my ($ok, $error) = try_load_class($server_class);
    if (! $ok) {
        confess "Cannot load server class $server_class: $error";
    }

    return $server_class->new();
}

on_plugin_import {
    my $dsl      = shift;
    my $settings = plugin_setting;
    my $authorization_route = $settings->{authorize_route}//'/oauth/authorize';
    my $access_token_route  = $settings->{access_token_route}//'/oauth/access_token';

    $dsl->app->add_route(
        method  => 'get',
        regexp  => $authorization_route,
        code    => sub { _authorization_request( $dsl, $settings ) }
    );
    $dsl->app->add_route(
        method  => 'post',
        regexp  => $access_token_route,
        code    => sub { _access_token_request( $dsl, $settings ) }
    );
};

register 'oauth_scopes' => sub {
    my ($dsl, $scopes, $code_ref) = @_;

    my $settings = plugin_setting;

    $scopes = [$scopes] unless ref $scopes eq 'ARRAY';

    return sub {
        my $server = get_server_class( $settings );
        my @res = _verify_access_token_and_scope( $dsl, $settings, $server,0, @$scopes );
        if( not $res[0] ) {
            $dsl->status( 400 );
            return $dsl->to_json( { error => $res[1] } );
        } else {
            $dsl->app->request->var( oauth_access_token => $res[0] );
            goto $code_ref;
        }
    }
};

sub _authorization_request {
    my ($dsl, $settings) = @_;
    my ( $c_id,$url,$type,$scope,$state )
        = map { $dsl->param( $_ ) // undef }
        qw/ client_id redirect_uri response_type scope state /;

    my $server = get_server_class( $settings );

    my @scopes = $scope ? split( / /,$scope ) : ();

    if (
        ! defined( $c_id )
            or ! defined( $type )
            or $type ne 'code'
    ) {
        $dsl->status( 400 );
        return $dsl->to_json(
            {
                error             => 'invalid_request',
                error_description => 'the request was missing one of: client_id, '
                . 'response_type;'
                . 'or response_type did not equal "code"',
                error_uri         => '',
            }
        );
    }

    my $state_required = $settings->{state_required} // 0;
    if(
        $state_required
            and ! defined $state
            and ! length $state
    ) {
        $dsl->status( 400 );
        return $dsl->to_json(
            {
                error             => 'invalid_request',
                error_description => 'the request was missing : state ',
                error_uri         => '',
            }
        );
    }

    my $uri = URI->new( $url );
    my ( $res,$error ) = $server->verify_client($dsl, $settings, $c_id, \@scopes, $url );

    if ( $res ) {
        if ( ! $server->login_resource_owner( $dsl, $settings ) ) {
            $dsl->debug( "OAuth2::Server: Resource owner not logged in" );
            # call to $resource_owner_logged_in method should have called redirect_to
            return;
        } else {
            $dsl->debug( "OAuth2::Server: Resource owner is logged in" );
            $res = $server->confirm_by_resource_owner($dsl, $settings, $c_id, \@scopes );
            if ( ! defined $res ) {
                $dsl->debug( "OAuth2::Server: Resource owner to confirm scopes" );
                # call to $resource_owner_confirms method should have called redirect_to
                return;
            }
            elsif ( $res == 0 ) {
                $dsl->debug( "OAuth2::Server: Resource owner denied scopes" );
                $error = 'access_denied';
            }
        }
    }

    if ( $res ) {
        $dsl->debug( "OAuth2::Server: Generating auth code for $c_id" );
        my $expires_in = $settings->{auth_code_ttl} // 600;

        my $auth_code = $server->generate_token($dsl, $settings, $expires_in, $c_id, \@scopes, 'auth', $url );

        $server->store_auth_code($dsl, $settings, $auth_code,$c_id,$expires_in,$url,@scopes );

        $uri->query_param_append( code  => $auth_code );

    } elsif ( $error ) {
        $uri->query_param_append( error => $error );
    } else {
        # callback has not returned anything, assume server error
        $uri->query_param_append( error             => 'server_error' );
        $uri->query_param_append( error_description => 'call to verify_client returned unexpected value' );
    }

    $uri->query_param_append( state => $state ) if defined( $state );

    $dsl->redirect( $uri );
}

sub _access_token_request {
    my ($dsl, $settings) = @_;
    my ( $client_id,$client_secret,$grant_type,$auth_code,$url,$refresh_token )
        = map { $dsl->param( $_ ) // undef }
        qw/ client_id client_secret grant_type code redirect_uri refresh_token /;

    my $server = get_server_class( $settings );

    if (
        ! defined( $grant_type )
            or ( $grant_type ne 'authorization_code' and $grant_type ne 'refresh_token' )
            or ( $grant_type eq 'authorization_code' and ! defined( $auth_code ) )
            or ( $grant_type eq 'authorization_code' and ! defined( $url ) )
    ) {
        $dsl->status( 400 );
        return $dsl->to_json(
            {
                error             => 'invalid_request',
                error_description => 'the request was missing one of: grant_type, '
                . 'client_id, client_secret, code, redirect_uri;'
                . 'or grant_type did not equal "authorization_code" '
                . 'or "refresh_token"',
                error_uri         => '',
            }
        );
        return;
    }

    my $json_response = {};
    my $status        = 400;
    my ( $client,$error,$scope,$old_refresh_token,$user_id );

    if ( $grant_type eq 'refresh_token' ) {
        ( $client,$error,$scope,$user_id ) = _verify_access_token_and_scope(
            $dsl, $settings, $server, $refresh_token
        );
        $old_refresh_token = $refresh_token;
    } else {
        ( $client,$error,$scope,$user_id ) = $server->verify_auth_code(
            $dsl, $settings, $client_id,$client_secret,$auth_code,$url
        );
    }

    if ( $client ) {

        $dsl->debug( "OAuth2::Server: Generating access token for $client" );

        my $expires_in    = $settings->{access_token_ttl} // 3600;
        my $access_token  = $server->generate_token($dsl, $settings, $expires_in,$client,$scope,'access',undef,$user_id );
        my $refresh_token = $server->generate_token($dsl, $settings, undef,$client,$scope,'refresh',undef,$user_id );

        $server->store_access_token(
            $dsl, $settings,
            $client,$auth_code,$access_token,$refresh_token,
            $expires_in,$scope,$old_refresh_token
        );

        $status = 200;
        $json_response = {
            access_token  => $access_token,
            token_type    => 'Bearer',
            expires_in    => $expires_in,
            refresh_token => $refresh_token,
        };

    } elsif ( $error ) {
        $json_response->{error} = $error;
    } else {
        # callback has not returned anything, assume server error
        $json_response = {
            error             => 'server_error',
            error_description => 'call to verify_auth_code returned unexpected value',
        };
    }

    $dsl->header( 'Cache-Control' => 'no-store' );
    $dsl->header( 'Pragma'        => 'no-cache' );

    $dsl->status( $status );
    return $dsl->to_json( $json_response );
}

sub _verify_access_token_and_scope {
    my ($dsl, $settings, $server, $refresh_token, @scopes) = @_;

    my $access_token;

    if ( ! $refresh_token ) {
        if ( my $auth_header = $dsl->app->request->header( 'Authorization' ) ) {
            my ( $auth_type,$auth_access_token ) = split( / /,$auth_header );

            if ( $auth_type ne 'Bearer' ) {
                $dsl->debug( "OAuth2::Server: Auth type is not 'Bearer'" );
                return ( 0,'invalid_request' );
            } else {
                $access_token = $auth_access_token;
            }
        } else {
            $dsl->debug( "OAuth2::Server: Authorization header missing" );
            return ( 0,'invalid_request' );
        }
    } else {
        $access_token = $refresh_token;
    }

    return $server->verify_access_token($dsl, $settings, $access_token,\@scopes,$refresh_token );
}

register_plugin;

1;
__END__

=encoding utf-8

=head1 NAME

Dancer2::Plugin::OAuth2::Server - Easier implementation of an OAuth2 Authorization
Server / Resource Server with Dancer2
Port of Mojolicious implementation : https://github.com/G3S/mojolicious-plugin-oauth2-server

=head1 SYNOPSIS

  use Dancer2::Plugin::OAuth2::Server;

  To protect a route, declare it like following:

  get '/protected' => oauth_scopes 'desired_scope' => sub { ... }

=head1 DESCRIPTION

Dancer2::Plugin::OAuth2::Server is a port of Mojolicious plugin for OAuth2 server
With this plugin, you can implement an OAuth2 Authorization server and Resource server without too much hassle.
The Basic flows are implemented, authorization code, access token, refresh token, ...

A "simple" implementation is provided with a "in memory" session management, however, it will not work on multi process persistent
environment, as each restart will loose all the access/refrest tokens. Token will also not be shared between processes.

For a usable implementation in a realistic context, you will need to create a class implementing the Role Dancer2::Plugin::OAuth2::Server::Role,
and configure the server_class option in configuration of the plugin. The following methods needs to be implemented:

	login_resource_owner
	confirm_by_resource_owner
	verify_client
	store_auth_code
	generate_token
	verify_auth_code
	store_access_token
	verify_access_token

On the resource server side, to protect a resource, just use the dsl keyword oauth_scopes with
either one scope or the list of scope needed. In case the authorization header provided is not correct,
a 400 http code is returned with an erro message.
If the Authorization header is correct and the access is granted, the access token information are
stored within the var keyword, in oauth_access_token, for the time of the request. You can access the
access token information through var('oauth_access_token') within the route code itself.

=head1 CONFIGURATION

=head2 authorize_route

The route that the Client calls to get an authorization code. Defaults to /oauth/authorize
The route is accessible through http GET method

=head2 access_token_route

The route the the Client calls to get an access token. Defaults to/oauth/access_token
The route is accessible through http POST method

=head2 auth_code_ttl

The validity period of the generated authorization code in seconds. Defaults to
600 seconds (10 minutes)

=head2 access_token_ttl

The validity period of the generated access token in seconds. Defaults to 3600
seconds (1 hour)

=head2 clients

list of clients for the simple default implementation

    clients:
      client1:
        client_secret: secret
        scopes:
          identity: 1
          other: 0
      client2:
        client_secret: secret2
        scopes:
          identity: 1
          other: 1
        redirect_uri:
          - url1
          - url2

Note the clients config is not required if you add the verify_client callback,
but is necessary for running the plugin in its simplest form (when no server class
is provided). In order to whitelist redirect_uri, provide an entry in the client
if no entry is present, all uri are accepted

=head2 state_required

State is optional in the sepcifications, however using state is really recommended to have a safe implementation on client side.
Client should send state and verify it, switching state_required to 1 make state a required parameter when trying to get
the authorization code

=head2 server_class

Package name of the server class for customizing the OAuth server behavior.
Defaults to Dancer2::Plugin::OAuth2::Server::Simple, the provided simple implementation

=head1 Server Class implementation

To customize the implementation in a more realistic way, the user needs to create a class implementing
the role Dancer2::Plugin::OAuth2::Server::Role , and provide the Class name in the configuration key
server_class. That role ensures that all the required functions are implemented.
All the function will receive the dsl and settings as first 2 parameters: $dsl, $settings
Those parameters will for instance allows user to access session, are plugin configuration

=head2 login_resource_owner

Function that tells if the Resource owner is logged in. It should return 1 if the
user is logged in, return 0 if not. That function is expected to redirect the user to login page if needed.

=head2 confirm_by_resource_owner

Function to tell the plugin if the Resource Owner allowed or denied access to
the Resource Server by the Client. Function receives the client_id and the list of scopes
requested by the client.
It should return 1 if access is allowed, 0 if access is not allowed, otherwise
it should redirect the user and return undef

=head2 verify_client

Reference: L<http://tools.ietf.org/html/rfc6749#section-4.1.1>

Function to verify if the client asking for an authorization code is known
to the Resource Server and allowed to get an authorization code for the passed
scopes.
The function receives the client id, and an array reference of request scopes, and
the redirect url. The callback should return a list with two elements. The first
element is either 1 or 0 to say that the client is allowed or disallowed, the second element
should be the error message in the case of the client being disallowed.
Note: Even if the redirect url is optional, there can be some security concern if
someone redirects to a compromised server. Because of that, some OAuth2 provider
requried to whitelist the redirect uri by client. To allow client to verify url,
it's passed as last argument to method verifiy_client

=head2 store_auth_code

Function to allow you to store the generated authorization code. After the 2 common parameters,
The Function is passed  the generated auth code, the client id, the auth code validity period in
seconds, the Client redirect URI, and a list of the scopes requested by the Client.
You should save the information to your data store, it can then be retrieved by
the verify_auth_code function for verification

=head2 generate_token

Function to generate a token. After the 2 common parameters, dsl and settings,
that function receives the validity period in seconds, the client id, the list of scopes,
the type of token and the redirect url.
That function should return the token that it generates, and should be unique.

=head2 verify_auth_code

Reference: L<http://tools.ietf.org/html/rfc6749#section-4.1.3>

Function to verify the authorization code passed from the Client to the
Authorization Server. The function is passed the dsl, the settings, and then
the client_id, the client_secret, the authorization code, and the redirect uri.
The Function should verify the authorization code using the rules defined in
the reference RFC above, and return a list with 4 elements. The first element
should be a client identifier (a scalar, or reference) in the case of a valid
authorization code or 0 in the case of an invalid authorization code. The second
element should be the error message in the case of an invalid authorization
code. The third element should be a hash reference of scopes as requested by the
client in the original call for an authorization code. The fourth element should
be a user identifier

=head2 store_access_token

Function to allow you to store the generated access and refresh tokens. The
function is passed the dsl, the settings, and then the client identifier as
returned from the verify_auth_code callback, the authorization code, the access
token, the refresh_token, the validity period in seconds, the scope returned
from the verify_auth_code callback, and the old refresh token,

Note that the passed authorization code could be undefined, in which case the
access token and refresh tokens were requested by the Client by the use of an
existing refresh token, which will be passed as the old refresh token variable.
In this case you should use the old refresh token to find out the previous
access token and revoke the previous access and refresh tokens (this is *not* a
hard requirement according to the OAuth spec, but i would recommend it).
That functions does not need to return anything.
You should save the information to your data store, it can then be retrieved by
the verify_access_token callback for verification

=head2 verify_access_token

Reference: L<http://tools.ietf.org/html/rfc6749#section-7>

Function to verify the access token. The function is passed the dsl, the
settings and then the access token, an optional reference to a list of the
scopes and if the access_token is actually a refresh token. Note that the access
token could be the refresh token, as this method is also called when the Client
uses the refresh token to get a new access token (in which case the value of the
$is_refresh_token variable will be true).

The function should verify the access code using the rules defined in the
reference RFC above, and return false if the access token is not valid otherwise
it should return something useful if the access token is valid - since this
method is called by the call to oauth_scopes you probably need to return a hash
of details that the access token relates to (client id, user id, etc).
In the event of an invalid, expired, etc, access or refresh token you should
return a list where the first element is 0 and the second contains the error
message (almost certainly 'invalid_grant' in this case)

=head1 AUTHOR

Pierre Vigier E<lt>pierre.vigier@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Pierre Vigier

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
