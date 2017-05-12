package Bing::Search::Role::Result::ContentType;
use Moose::Role;

requires 'data';
requires '_populate';

has 'ContentType' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $ctype = delete $data->{ContentType};
   $self->ContentType( $ctype ) if $ctype;
};

1;
