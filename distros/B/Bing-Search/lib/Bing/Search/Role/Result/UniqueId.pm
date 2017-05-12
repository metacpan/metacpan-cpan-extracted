package Bing::Search::Role::Result::UniqueId;
use Moose::Role;
requires 'data';
requires '_populate';

has 'UniqueId' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{UniqueId};
   $self->UniqueId( $item );
};

1;
