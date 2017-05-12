package Bing::Search::Role::Result::DepartureTerminal;
use Moose::Role;
requires 'data';
requires '_populate';

has 'DepartureTerminal' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $title = delete $data->{DepartureTerminal};
   $self->DepartureTerminal( $title );
};

1;
