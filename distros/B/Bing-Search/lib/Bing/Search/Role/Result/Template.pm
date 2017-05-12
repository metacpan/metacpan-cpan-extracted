package Bing::Search::Role::Result::TEMPLATE;
use Moose::Role;
requires 'data';
requires '_populate';

has 'TEMPLATE' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{TEMPLATE};
   $self->TEMPLATE( $item );
};

1;
