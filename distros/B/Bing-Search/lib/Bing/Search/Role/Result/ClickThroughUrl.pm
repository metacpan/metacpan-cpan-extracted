package Bing::Search::Role::Result::ClickThroughUrl;
use Moose::Role;
use Moose::Util::TypeConstraints;
use URI;

has 'ClickThroughUrl' => (
   is => 'rw',
   isa => 'Bing::Search::UrlType',
   coerce => 1
);

before '_populate' => sub { 
   my( $self ) = @_;
   my $data = $self->data;
   my $url = delete $data->{ClickThroughUrl};
   $self->ClickThroughUrl( $url );
};

1;
