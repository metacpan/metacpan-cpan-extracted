package API::DeutscheBahn::Fahrplan;

use Moose;
use namespace::autoclean;

# VERSION
our $VERSION = '0.02';

# IMPORTS
use Carp;
use HTTP::Tiny      ();
use JSON::XS        ();
use URI             ();
use URI::Encode qw(uri_encode);
use URI::QueryParam ();

=encoding utf-8

=head1 NAME

API::DeutscheBahn::Fahrplan - Deutsche Bahn Fahrplan API Client

=head1 SYNOPSIS


    my $fahrplan_free = API::DeutscheBahn::Fahrplan->new;
    my $fahrplan_plus = API::DeutscheBahn::Fahrplan->new( access_token => $access_token );

    $data = $fahrplan->location( name => 'Berlin' );
    $data = $fahrplan->arrival_board( id => 8503000, date => '2018-09-24T11:00:00' );
    $data = $fahrplan->departure_board( id => 8503000, date => '2018-09-24T11:00:00' );
    $data = $fahrplan->journey_details( id => '87510%2F49419%2F965692%2F453678%2F80%3fstation_evaId%3D850300' );

=head1 DESCRIPTION

API::DeutscheBahn::Fahrplan provides a simple interface to the Deutsche Bahn Fahrplan
API. See L<https://developer.deutschebahn.com/> for further information.

=head1 ATTRIBUTES

=over

=item fahrplan_free_url

URL endpoint for DB Fahrplan free version. Defaults to I<https://api.deutschebahn.com/freeplan/v1>.

=item fahrplan_plus_url

URL endpoint for DB Fahrplan subscribed version. Defaults to I<https://api.deutschebahn.com/fahrplan-plus/v1>.

=item access_token

Access token to sign requests. If provided the client will use the C<fahrplan_plus_url> endpoint.

=back

=cut

has 'fahrplan_free_url' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://api.deutschebahn.com/freeplan/v1',
);

has 'fahrplan_plus_url' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://api.deutschebahn.com/fahrplan-plus/v1',
);

has 'access_token' => (
    is  => 'ro',
    isa => 'Str',
);

has '_client' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_client',
);


=head1 METHODS

=head2 location

    $fahrplan->location( name => 'Berlin' );

Fetch information about locations matching the given name or name fragment.

=cut

sub location {
    return shift->_request( 'location', @_ );
}

=head2 arrival_board

    $fahrplan->arrival_board( id => 8503000, date => '2018-09-24T11:00:00' );

Fetch the arrival board at a given location at a given date and time. The date
parameter should be in the ISO-8601 format.

=cut

sub arrival_board {
    return shift->_request( 'arrival_board', @_ );
}

=head2 departure_board

    $fahrplan->departure_board( id => 8503000, date => '2018-09-24T11:00:00' );

Fetch the departure board at a given location at a given date and time. The date
parameter should be in the ISO-8601 format.

=cut

sub departure_board {
    return shift->_request( 'departure_board', @_ );
}

=head2 journey_details

    $fahrplan->journey_details( id => '87510%2F49419%2F965692%2F453678%2F80%3fstation_evaId%3D850300' );

Retrieve details of a journey for a given id.

=cut

sub journey_details {
    my ( $self, %args ) = @_;
    return $self->_request( 'journey_details',
        # id needs to be uri encoded
        id => uri_encode( $args{id} ) );
}


# PRIVATE METHODS


sub _request {
    my ( $self, $name, %args ) = @_;
    my ( $method, $uri ) = $self->_create_uri( $name, %args );
    my $response = $self->_client->$method($uri);
    return JSON::XS::decode_json $response->{content};
}


sub _create_uri {
    my ( $self, $name, %args ) = @_;

    my $uri        = $self->_base_uri;
    my $definition = $self->_api->{$name};
    my ( $method, $path ) = @{$definition}{qw(method path)};

    # add path parameters
    for ( @{ $definition->{path_parameters} } ) {
        my $value = $args{$_};
        croak sprintf 'Missing path parameter: %s', $_ unless $value;
        $path .= "/${value}";
    }

    # set the uri path including the path set in the base url
    $uri->path( $uri->path . $path );

    # add query parameters
    for my $param ( keys %{ $definition->{query_parameters} } ) {
        if ( my $value = $args{$param} ) {
            $uri->query_param( $param => $value );
        } 
        # check if param is required
        elsif ( $definition->{query_parameters}->{$param} ) {
            croak sprintf 'Missing query parameter: %s', $param;
        }
    }

    return ( lc $method, $uri );

}


sub _base_uri {
    return URI->new(
          $_[0]->access_token
        ? $_[0]->fahrplan_plus_url
        : $_[0]->fahrplan_free_url
    );
}


sub _api {
    return {
        location => {
            method          => 'GET',
            path            => '/location',
            path_parameters => ['name'],
        },
        arrival_board => {
            method           => 'GET',
            path             => '/arrivalBoard',
            path_parameters  => ['id'],
            query_parameters => { date => 1 },
        },
        departure_board => {
            method           => 'GET',
            path             => '/departureBoard',
            path_parameters  => ['id'],
            query_parameters => { date => 1 },
        },
        journey_details => {
            method          => 'GET',
            path            => '/journeyDetails',
            path_parameters => ['id'],
        },
    };
}


# BUILDERS


sub _build_client {
    my $self = $_[0];
    my @args;

    push @args, 'Authorization' => sprintf( 'Bearer %s', $self->access_token )
        if $self->access_token;

    return HTTP::Tiny->new(
        default_headers => {
            'Accept'     => 'application/json',
            'User-Agent' => sprintf( 'Perl-%s::%s', __PACKAGE__, $VERSION ),
            @args,
        },
    );
}

1;

=head1 LICENSE

Copyright (C) Edward Francis.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Edward Francis E<lt>edwardafrancis@gmail.comE<gt>

=cut
