package Bing::Search::Role::Result::Value;
use Moose::Role;
requires 'data';
requires '_populate';

has 'Value' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{Value};
   $self->Value( $item );
};

1;
