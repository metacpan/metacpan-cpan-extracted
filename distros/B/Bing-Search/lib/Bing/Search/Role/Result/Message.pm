package Bing::Search::Role::Result::Message;
use Moose::Role;
requires 'data';
requires '_populate';

has 'Message' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{Message};
   $self->Message( $item );
};

1;
