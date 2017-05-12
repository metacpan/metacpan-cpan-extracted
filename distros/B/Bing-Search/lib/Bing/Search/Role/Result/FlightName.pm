package Bing::Search::Role::Result::FlightName;
use Moose::Role;
requires 'data';
requires '_populate';

has 'FlightName' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{FlightName};
   $self->FlightName( $item );
};

1;
