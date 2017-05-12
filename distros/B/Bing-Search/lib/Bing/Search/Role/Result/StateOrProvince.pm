package Bing::Search::Role::Result::StateOrProvince;
use Moose::Role;
requires 'data';
requires '_populate';

has 'StateOrProvince' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{StateOrProvince};
   $self->StateOrProvince( $item );
};

1;
