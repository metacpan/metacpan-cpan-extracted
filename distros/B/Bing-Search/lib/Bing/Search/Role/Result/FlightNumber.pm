package Bing::Search::Role::Result::FlightNumber;
use Moose::Role;
requires 'data';
requires '_populate';

has 'FlightNumber' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{FlightNumber};
   $self->FlightNumber( $item );
};

1;
