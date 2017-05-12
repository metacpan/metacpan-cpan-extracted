package Bing::Search::Role::Result::UpdatedDeparture;
use Moose::Role;
requires 'data';
requires '_populate';

has 'UpdatedDeparture' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{UpdatedDeparture};
   $self->UpdatedDeparture( $item ) if $item;
};

1;
