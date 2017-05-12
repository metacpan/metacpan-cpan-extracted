package Bing::Search::Role::Result::Name;
use Moose::Role;
requires 'data';
requires '_populate';

has 'Name' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{Name};
   $self->Name( $item );
};

1;
