package Bing::Search::Role::Result::ReviewCount;
use Moose::Role;
requires 'data';
requires '_populate';

has 'ReviewCount' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{ReviewCount};
   $self->ReviewCount( $item );
};

1;
