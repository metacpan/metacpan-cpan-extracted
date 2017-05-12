package Bing::Search::Role::Result::City;
use Moose::Role;
requires 'data';
requires '_populate';

has 'City' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{City};
   $self->City( $item );
};

1;
