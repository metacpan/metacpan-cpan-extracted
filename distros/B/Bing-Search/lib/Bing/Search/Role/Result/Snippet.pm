package Bing::Search::Role::Result::Snippet;
use Moose::Role;
requires 'data';
requires '_populate';

has 'Snippet' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $snip = delete $data->{Snippet};
   $self->Title( $snip);
};

1;
