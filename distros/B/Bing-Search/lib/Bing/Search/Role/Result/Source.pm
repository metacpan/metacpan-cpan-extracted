package Bing::Search::Role::Result::Source;
use Moose::Role;

requires 'data';
requires '_populate';

has 'Source' => ( is => 'rw' );

before '_populate' => sub {
   my $self = shift;
   my $data = $self->data;
   my $source = delete $data->{Source};
   $self->Source( $source );
};

1;
