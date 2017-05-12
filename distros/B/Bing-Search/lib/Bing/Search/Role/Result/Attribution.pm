package Bing::Search::Role::Result::Attribution;
use Moose::Role;


requires 'data';
requires '_populate';

has 'Attribution' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $attr = delete $data->{Attribution};
   $self->Attribution( $attr );
};

1;
