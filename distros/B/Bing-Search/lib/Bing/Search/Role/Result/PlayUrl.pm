package Bing::Search::Role::Result::PlayUrl;
use Moose::Role;

has 'PlayUrl' => (
   is => 'rw',
   isa => 'Bing::Search::UrlType',
   coerce => 1
);

before '_populate' => sub { 
   my( $self ) = @_;
   my $data = $self->data;
   my $url = delete $data->{PlayUrl};
   $self->PlayUrl( $url ) if $url;
};

1;
