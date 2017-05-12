package Bing::Search::Role::Result::BreakingNews;
use Moose::Role;

requires 'data';
requires '_populate';

has 'BreakingNews' => ( is => 'rw', isa => 'Bool' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $breaking = delete $data->{BreakingNews};
   $self->BreakingNews( $breaking );
};

1;
