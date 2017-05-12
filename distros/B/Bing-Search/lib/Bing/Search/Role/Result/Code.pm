package Bing::Search::Role::Result::Code;
use Moose::Role;
requires 'data';
requires '_populate';

has 'Code' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{Code};
   $self->Code( $item );
};

1;
