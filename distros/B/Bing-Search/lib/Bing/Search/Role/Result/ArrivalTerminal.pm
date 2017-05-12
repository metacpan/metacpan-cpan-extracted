package Bing::Search::Role::Result::ArrivalTerminal;
use Moose::Role;
requires 'data';
requires '_populate';

has 'ArrivalTerminal' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{ArrivalTerminal};
   $self->ArrivalTerminal( $item );
};

1;
