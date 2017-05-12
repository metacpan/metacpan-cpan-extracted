package Bing::Search::Role::Result::AirlineCode;
use Moose::Role;
requires 'data';
requires '_populate';

has 'AirlineCode' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{AirlineCode};
   $self->AirlineCode( $item );
};

1;
