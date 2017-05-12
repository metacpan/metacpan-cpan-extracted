package Bing::Search::Role::Result::ClickThroughPageUrl;
use Moose::Role;
use Moose::Util::TypeConstraints;
use URI;

with 'Bing::Search::Role::Types::UrlType';

has 'ClickThroughPageUrl' => (
   is => 'rw',
   isa => 'Bing::Search::UrlType',
   coerce => 1
);

before '_populate' => sub { 
   my( $self ) = @_;
   my $data = $self->data;
   my $url = delete $data->{ClickThroughPageUrl};
   $self->ClickThroughPageUrl( $url );
};

1;
