package Bing::Search::Role::Result::MediaUrl;
use Moose::Role;
use Moose::Util::TypeConstraints;

requires 'data';
requires '_populate';

has 'MediaUrl' => (
   is => 'rw',
   isa => 'Bing::Search::UrlType',
   coerce => 1
);

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $murl = delete $data->{MediaUrl};
   $self->MediaUrl( $murl ) if $murl;
};

1;
