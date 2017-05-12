package Dancer2::Plugin::OAuth2::Server::Simple;
use Moo;
use Time::HiRes qw/ gettimeofday /;
use MIME::Base64 qw/ encode_base64 decode_base64 /;
use Carp qw/ croak /;
use Crypt::PRNG qw/ random_string /;
use Dancer2::Plugin::OAuth2::Server::Role;
with 'Dancer2::Plugin::OAuth2::Server::Role';
use feature qw/state/;

sub _get_clients  {
    my ($self, $dsl, $settings) = @_;

    return $settings->{clients} // {};
}

sub login_resource_owner {
    my ($self, $dsl, $settings) = @_;

    return 1;
}

sub confirm_by_resource_owner {
    my ($self, $dsl, $settings, $client_id, $scopes) = @_;

    return 1;
}

sub verify_client {
    my ($self, $dsl, $settings, $client_id, $scopes, $uri) = @_;

    if ( my $client = $self->_get_clients($dsl, $settings)->{$client_id} ) {

        foreach my $scope ( @{ $scopes // [] } ) {

            if ( ! exists( $self->_get_clients($dsl, $settings)->{$client_id}{scopes}{$scope} ) ) {
                $dsl->debug( "OAuth2::Server: Client lacks scope ($scope)" );
                return ( 0,'invalid_scope' );
            } elsif ( ! $self->_get_clients($dsl, $settings)->{$client_id}{scopes}{$scope} ) {
                $dsl->debug( "OAuth2::Server: Client cannot scope ($scope)" );
                return ( 0,'access_denied' );
            }
        }

        if ( exists( $self->_get_clients($dsl, $settings)->{$client_id}{redirect_uri} ) ) {
            my $whitelisted_uris = $self->_get_clients($dsl, $settings)->{$client_id}{redirect_uri};
            if( ! grep { $_ eq $uri } @$whitelisted_uris ) {
                $dsl->debug( "OAuth2::Server: Client does not accept uri ($uri)" );
                return ( 0,'unauthorized_uri' );
            } else {
                $dsl->debug( "OAuth2::Server: Client accept uri ($uri)" );
            }
        }

        return ( 1 );
    }

    $dsl->debug( "OAuth2::Server: Client ($client_id) does not exist" );
    return ( 0,'unauthorized_client' );
}

sub generate_token {
    my ( $self, $dsl, $settings, $ttl,$client_id,$scopes,$type,$redirect_url,$user_id ) = @_;

    my $code;

    #if ( ! $JWT_SECRET ) {
    my ( $sec,$usec ) = gettimeofday;
    $code = encode_base64( join( '-',$sec,$usec,rand(),random_string(30) ),'' );
    #} else {
    #$code = Mojo::JWT->new(
    #( $ttl ? ( expires => time + $ttl ) : () ),
    #secret  => $JWT_SECRET,
    #set_iat => 1,
    ## https://tools.ietf.org/html/rfc7519#section-4
    #claims  => {
    ## Registered Claim Names
    ##        iss    => undef, # us, the auth server / application (set using plugin config?)
    ##        sub    => undef, # the logged in user, we could get this by returning it from the resource_owner_logged_in callback
    #aud    => $redirect_url, # the "audience"
    #jti    => random_string(32),

    ## Private Claim Names
    #user_id      => $user_id,
    #client       => $client_id,
    #type         => $type,
    #scopes       => $scopes,
    #},
    #)->encode;
    #}

    return $code;
}

state %AUTH_CODES;
sub store_auth_code {
    my ( $self, $dsl, $settings, $auth_code,$client_id,$expires_in,$uri,@scopes ) = @_;
    #return if $JWT_SECRET;

    $AUTH_CODES{$auth_code} = {
        client_id     => $client_id,
        expires       => time + $expires_in,
        redirect_uri  => $uri,
        scope         => { map { $_ => 1 } @scopes },
    };

    return 1;
}

state %REFRESH_TOKENS;
state %ACCESS_TOKENS;
sub verify_access_token {
    my ( $self, $dsl, $settings, $access_token,$scopes_ref,$is_refresh_token ) = @_;

    #return _verify_access_token_jwt( @_ ) if $JWT_SECRET;

    if (
        $is_refresh_token
        && exists( $REFRESH_TOKENS{$access_token} )
    ) {

        if ( $scopes_ref ) {
            foreach my $scope ( @{ $scopes_ref // [] } ) {
                if (
                    ! exists( $REFRESH_TOKENS{$access_token}{scope}{$scope} )
                        or ! $REFRESH_TOKENS{$access_token}{scope}{$scope}
                ) {
                    $dsl->debug( "OAuth2::Server: Refresh token does not have scope ($scope)" );
                    return ( 0,'invalid_grant' )
                }
            }
        }

        return $REFRESH_TOKENS{$access_token}{client_id};
    }
    elsif ( exists( $ACCESS_TOKENS{$access_token} ) ) {

        if ( $ACCESS_TOKENS{$access_token}{expires} <= time ) {
            $dsl->debug( "OAuth2::Server: Access token has expired" );
            $self->revoke_access_token( $dsl, $settings, $access_token );
            return ( 0,'invalid_grant' )
        } elsif ( $scopes_ref ) {

            foreach my $scope ( @{ $scopes_ref // [] } ) {
                if (
                    ! exists( $ACCESS_TOKENS{$access_token}{scope}{$scope} )
                        or ! $ACCESS_TOKENS{$access_token}{scope}{$scope}
                ) {
                    $dsl->debug( "OAuth2::Server: Access token does not have scope ($scope)" );
                    return ( 0,'invalid_grant' )
                }
            }

        }

        $dsl->debug( "OAuth2::Server: Access token is valid" );
        return $ACCESS_TOKENS{$access_token}{client_id};
    }

    $dsl->debug( "OAuth2::Server: Access token does not exist" );
    return ( 0,'invalid_grant' )
}

sub revoke_access_token {
    my ( $self, $dsl, $settings, $access_token ) = @_;
    delete( $ACCESS_TOKENS{$access_token} );
}

sub verify_auth_code {
    my ($self, $dsl, $settings, $client_id,$client_secret,$auth_code,$uri ) = @_;
    #return _verify_auth_code_jwt( @_ ) if $JWT_SECRET;

    my ( $sec,$usec,$rand ) = split( '-',decode_base64( $auth_code ) );

    if (
        ! exists( $AUTH_CODES{$auth_code} )
            or ! exists( $self->_get_clients($dsl, $settings)->{$client_id} )
            or ( $client_secret ne $self->_get_clients($dsl, $settings)->{$client_id}{client_secret} )
            or $AUTH_CODES{$auth_code}{access_token}
            or ( $uri && $AUTH_CODES{$auth_code}{redirect_uri} ne $uri )
            or ( $AUTH_CODES{$auth_code}{expires} <= time )
    ) {

        $dsl->debug( "OAuth2::Server: Auth code does not exist" )
            if ! exists( $AUTH_CODES{$auth_code} );
        $dsl->debug( "OAuth2::Server: Client ($client_id) does not exist" )
            if ! exists( $self->_get_clients($dsl, $settings)->{$client_id} );
        $dsl->debug( "OAuth2::Server: Client secret does not match" )
            if (
                ! $client_secret
                    or ! $self->_get_clients($dsl, $settings)->{$client_id}
                    or $client_secret ne $self->_get_clients($dsl, $settings)->{$client_id}{client_secret}
            );

        if ( $AUTH_CODES{$auth_code} ) {
            $dsl->debug( "OAuth2::Server: Redirect URI does not match" )
                if ( $uri && $AUTH_CODES{$auth_code}{redirect_uri} ne $uri );
            $dsl->debug( "OAuth2::Server: Auth code expired" )
                if ( $AUTH_CODES{$auth_code}{expires} <= time );
        }

        if ( my $access_token = $AUTH_CODES{$auth_code}{access_token} ) {
            # this auth code has already been used to generate an access token
            # so we need to revoke the access token that was previously generated
            $dsl->debug(
                "OAuth2::Server: Auth code already used to get access token"
            );

            $self->revoke_access_token($dsl, $settings, $access_token );
        }

        return ( 0,'invalid_grant' );
    } else {
        return ( 1,undef,$AUTH_CODES{$auth_code}{scope} );
    }

}

sub store_access_token {
    my (
        $self, $dsl, $settings, $c_id,$auth_code,$access_token,$refresh_token,
        $expires_in,$scope,$old_refresh_token
    ) = @_;
    #return if $JWT_SECRET;

    if ( ! defined( $auth_code ) && $old_refresh_token ) {
        # must have generated an access token via a refresh token so revoke the old
        # access token and refresh token and update the AUTH_CODES hash to store the
        # new one (also copy across scopes if missing)
        $auth_code = $REFRESH_TOKENS{$old_refresh_token}{auth_code};

        my $prev_access_token = $REFRESH_TOKENS{$old_refresh_token}{access_token};

        # access tokens can be revoked, whilst refresh tokens can remain so we
        # need to get the data from the refresh token as the access token may
        # no longer exist at the point that the refresh token is used
        $scope //= $REFRESH_TOKENS{$old_refresh_token}{scope};

        $dsl->debug( "OAuth2::Server: Revoking old access token (refresh)" );
        $self->revoke_access_token($dsl, $settings, $prev_access_token );
    }

    delete( $REFRESH_TOKENS{$old_refresh_token} )
        if $old_refresh_token;

    $ACCESS_TOKENS{$access_token} = {
        scope         => $scope,
        expires       => time + $expires_in,
        refresh_token => $refresh_token,
        client_id     => $c_id,
    };

    $REFRESH_TOKENS{$refresh_token} = {
        scope         => $scope,
        client_id     => $c_id,
        access_token  => $access_token,
        auth_code     => $auth_code,
    };

    $AUTH_CODES{$auth_code}{access_token} = $access_token;

    return $c_id;
}


no Moo;
1;
