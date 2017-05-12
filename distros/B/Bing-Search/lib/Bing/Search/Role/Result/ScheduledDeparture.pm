package Bing::Search::Role::Result::ScheduledDeparture;
use Moose::Role;
requires 'data';
requires '_populate';

has 'ScheduledDeparture' => ( 
   is => 'rw', 
   isa => 'Bing::Search::DateType',
   coerce => 1
);

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{ScheduledDeparture};
   $self->ScheduledDeparture( $item ) if $item;
};

1;
