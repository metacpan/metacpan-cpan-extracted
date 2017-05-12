package Bing::Search::Role::Result::TimeZoneOffset;
use Moose::Role;
requires 'data';
requires '_populate';

has 'TimeZoneOffset' => ( is => 'rw' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $item = delete $data->{TimeZoneOffset};
   $self->TimeZoneOffset( $item );
};

1;
