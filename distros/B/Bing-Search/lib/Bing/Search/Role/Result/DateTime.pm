package Bing::Search::Role::Result::DateTime;
use Moose::Role;
requires 'data';
requires '_populate';

has 'DateTime' => ( is => 'rw', isa => 'Bing::Search::DateType', coerce => 1 );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $date = delete $data->{DateTime};
   $self->DateTime( $date );
};

1;
