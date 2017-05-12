package Bing::Search::Role::Result::UpdatedArrival;
use Moose::Role;
requires 'data';
requires '_populate';

has 'UpdatedArrival' => ( is => 'rw', isa => 'Bing::Search::DateType', coerce => 1 );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{UpdatedArrival};
   $self->UpdatedArrival( $item ) if $item;
};

1;
