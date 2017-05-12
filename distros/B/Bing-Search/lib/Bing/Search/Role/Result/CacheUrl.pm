package Bing::Search::Role::Result::CacheUrl;
use Moose::Role;
use Moose::Util::TypeConstraints;
use URI;

has 'CacheUrl' => (
   is => 'rw',
   isa => 'Bing::Search::UrlType',
   coerce => 1
);

before '_populate' => sub { 
   my( $self ) = @_;
   my $data = $self->data;
   my $url = delete $data->{CacheUrl};
   $self->CacheUrl( $url ) if $url;
};

1;
