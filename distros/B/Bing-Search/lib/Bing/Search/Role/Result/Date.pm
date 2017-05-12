package Bing::Search::Role::Result::Date;
use Moose::Role;

requires 'data';
requires '_populate';

has 'Date' => ( 
   is => 'rw',
   isa => 'Bing::Search::DateType',
   coerce => 1
);

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $date = delete $data->{Date};
   $self->Date( $date );
};

1;
