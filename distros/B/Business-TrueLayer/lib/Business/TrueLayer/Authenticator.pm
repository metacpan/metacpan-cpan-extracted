package Business::TrueLayer::Authenticator;

=head1 NAME

Business::TrueLayer::Authenticator - Class to handle low level request
authentication, you probably don't need to use this and should use the
main L<Business::TrueLayer> module instead.

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
extends 'Business::TrueLayer::Request';

no warnings qw/ experimental::signatures experimental::postderef /;

use Business::TrueLayer::Types;

use Try::Tiny::SmartCatch;
use Mojo::UserAgent;
use Carp qw/ croak /;
use JSON;

has 'scope' => (
    is        => 'rw',
    isa       => 'ArrayRef',
    required  => 0,
    default   => sub { [ qw/ payments / ] },
);

has [ qw/ _auth_token _token_type _refresh_token / ] => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
);

has [ qw/ _expires_at / ] => (
    is        => 'rw',
    isa       => 'Int',
    required  => 0,
    default   => sub { time },
);

sub access_token ( $self ) {

    return $self
        ->_authenticate
        ->_auth_token
    ;
}

sub _authenticate ( $self ) {

    if (
        $self->_auth_token
        && $self->_token_type
        && ! $self->_token_is_expired
    ) {
        return $self;
    }

    my $url = "https://" . $self->host . "/connect/token";
    my $json = JSON->new->utf8->canonical->encode(
        {
            grant_type    => 'client_credentials',
            client_id     => $self->client_id,
            client_secret => $self->client_secret,
            scope         => join( " ",$self->scope->@* ),
        }
    );

    my $res_content = $self->_ua_request( $url, $json );

    # If any of these are missing, we get "interesting" errors from Moose
    # constraint violations.
    for my $key ( qw/ access_token expires_in token_type refresh_token / ) {
        my $val = $res_content->{ $key };
        if ( !length $val ) {
            # refresh_token is optional
            next
                if $key eq 'refresh_token';
            croak( "TrueLayer POST $url missing key $key - we have "
                       . join( ', ', map { "'$_'" } sort keys %$res_content ) );
        }
        if( $key eq 'expires_in' ) {
            $self->_expires_at(time + $val);
        } else {
            my $method = $key eq 'access_token' ? '_auth_token' : "_$key";
            $self->$method( $val );
        }
    }

    return $self;
}

sub _token_is_expired ( $self ) {
	return time >= $self->_expires_at;
}

1;

# vim: ts=4:sw=4:et
