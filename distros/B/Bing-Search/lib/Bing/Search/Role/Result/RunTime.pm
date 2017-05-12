package Bing::Search::Role::Result::RunTime;
use Moose::Role;
requires 'data';
requires '_populate';

has 'RunTime' => ( is => 'rw', isa => 'Bing::Search::DurationType', coerce => 1 );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{RunTime};
   $self->RunTime( $item );
};

1;
