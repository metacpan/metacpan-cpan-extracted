package Bing::Search::Role::Result::Longitude;
use Moose::Role;
requires 'data';
requires '_populate';

has 'Longitude' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{Longitude};
   $self->Longitude( $item );
};

1;
