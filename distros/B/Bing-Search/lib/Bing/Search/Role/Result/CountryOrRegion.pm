package Bing::Search::Role::Result::CountryOrRegion;
use Moose::Role;
requires 'data';
requires '_populate';

has 'CountryOrRegion' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{CountryOrRegion};
   $self->CountryOrRegion( $item );
};

1;
