package Bing::Search::Role::Result::Width;
use Moose::Role;
requires 'data';
requires '_populate';

has 'Width' => ( is => 'rw', isa => 'Num' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $width = delete $data->{Width};
   $self->Width( $width ) if $width;
};

1;
