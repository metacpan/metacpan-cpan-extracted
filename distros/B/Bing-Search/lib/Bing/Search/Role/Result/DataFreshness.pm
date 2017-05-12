package Bing::Search::Role::Result::DataFreshness;
use Moose::Role;
requires 'data';
requires '_populate';

has 'DataFreshness' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{DataFreshness};
   $self->DataFreshness( $item );
};

1;
