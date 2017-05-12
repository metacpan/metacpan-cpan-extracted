package Bing::Search::Role::Result::StatusString;
use Moose::Role;
requires 'data';
requires '_populate';

has 'StatusString' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{StatusString};
   $self->StatusString( $item );
};

1;
