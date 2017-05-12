package Bing::Search::Role::Result::Parameter;
use Moose::Role;
requires 'data';
requires '_populate';

has 'Parameter' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{Parameter};
   $self->Parameter( $item );
};

1;
