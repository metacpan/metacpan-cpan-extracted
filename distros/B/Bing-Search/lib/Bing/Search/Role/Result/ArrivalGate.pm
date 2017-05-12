package Bing::Search::Role::Result::ArrivalGate;
use Moose::Role;
requires 'data';
requires '_populate';

has 'ArrivalGate' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{ArrivalGate};
   $self->ArrivalGate( $item );
};

1;
