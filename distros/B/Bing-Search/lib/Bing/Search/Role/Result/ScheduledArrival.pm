package Bing::Search::Role::Result::ScheduledArrival;
use Moose::Role;
requires 'data';
requires '_populate';

has 'ScheduledArrival' => ( 
   is => 'rw',
   isa => 'Bing::Search::DateType',
   coerce => 1
);

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{ScheduledArrival};
   $self->ScheduledArrival( $item ) if $item;
};

1;
