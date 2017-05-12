package Bing::Search::Role::Result::Height;
use Moose::Role;

requires 'data';
requires '_populate';

has 'Height' => ( is => 'rw', isa => 'Num' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $height = delete $data->{Height};
   $self->Height( $height ) if $height;
};

1;
