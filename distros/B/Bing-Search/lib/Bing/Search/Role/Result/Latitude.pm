package Bing::Search::Role::Result::Latitude;
use Moose::Role;
requires 'data';
requires '_populate';

has 'Latitude' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{Latitude};
   $self->Latitude( $item );
};

1;
