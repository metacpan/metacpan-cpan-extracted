package Bing::Search::Role::Result::Description;
use Moose::Role;
requires 'data';
requires '_populate';

has 'Description' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $desc = delete $data->{Description};
   $self->Description( $desc );
};

1;
