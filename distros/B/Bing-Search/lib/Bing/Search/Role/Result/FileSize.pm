package Bing::Search::Role::Result::FileSize;
use Moose::Role;


requires 'data';
requires '_populate';

has 'FileSize' => ( is => 'rw', isa => 'Num' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $size = delete $data->{FileSize};
   $self->FileSize( $size ) if $size;;
};

1;
