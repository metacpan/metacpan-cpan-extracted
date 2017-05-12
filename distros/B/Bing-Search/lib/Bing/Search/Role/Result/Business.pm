package Bing::Search::Role::Result::Business;
use Moose::Role;
requires 'data';
requires '_populate';

has 'Business' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{Business};
   $self->Business( $item );
};

1;
