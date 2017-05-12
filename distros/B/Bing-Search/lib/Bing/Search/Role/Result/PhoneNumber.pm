package Bing::Search::Role::Result::PhoneNumber;
use Moose::Role;
requires 'data';
requires '_populate';

has 'PhoneNumber' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{PhoneNumber};
   $self->PhoneNumber( $item );
};

1;
