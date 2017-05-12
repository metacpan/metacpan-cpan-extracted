package Bing::Search::Role::Result::FlightHistoryId;
use Moose::Role;
requires 'data';
requires '_populate';

has 'FlightHistoryId' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{FlightHistoryId};
   $self->FlightHistoryId( $item );
};

1;
