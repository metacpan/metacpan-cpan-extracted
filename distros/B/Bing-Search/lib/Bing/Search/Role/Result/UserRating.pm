package Bing::Search::Role::Result::UserRating;
use Moose::Role;
requires 'data';
requires '_populate';

has 'UserRating' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{UserRating};
   $self->UserRating( $item );
};

1;
