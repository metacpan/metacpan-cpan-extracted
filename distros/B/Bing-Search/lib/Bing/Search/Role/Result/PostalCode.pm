package Bing::Search::Role::Result::PostalCode;
use Moose::Role;
requires 'data';
requires '_populate';

has 'PostalCode' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{PostalCode};
   $self->PostalCode( $item );
};

1;
