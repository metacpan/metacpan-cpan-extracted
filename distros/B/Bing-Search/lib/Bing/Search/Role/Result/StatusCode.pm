package Bing::Search::Role::Result::StatusCode;
use Moose::Role;
requires 'data';
requires '_populate';

has 'StatusCode' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{StatusCode};
   $self->StatusCode( $item );
};

1;
