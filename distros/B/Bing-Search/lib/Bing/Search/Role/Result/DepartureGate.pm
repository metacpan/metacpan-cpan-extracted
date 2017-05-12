package Bing::Search::Role::Result::DepartureGate;
use Moose::Role;
requires 'data';
requires '_populate';

has 'DepartureGate' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{DepartureGate};
   $self->DepartureGate( $item );
};

1;
