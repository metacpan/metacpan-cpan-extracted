package Bing::Search::Role::Result::AirlineName;
use Moose::Role;
requires 'data';
requires '_populate';

has 'AirlineName' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{AirlineName};
   $self->AirlineName( $item );
};

1;
