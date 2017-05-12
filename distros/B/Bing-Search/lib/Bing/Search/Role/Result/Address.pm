package Bing::Search::Role::Result::Address;
use Moose::Role;
requires 'data';
requires '_populate';

has 'Address' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{Address};
   $self->Address( $item );
};

1;
