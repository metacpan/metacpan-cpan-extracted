package Bing::Search::Role::Result::HelpUrl;
use Moose::Role;

has 'HelpUrl' => (
   is => 'rw',
   isa => 'Bing::Search::UrlType',
   coerce => 1
);

before '_populate' => sub { 
   my( $self ) = @_;
   my $data = $self->data;
   my $url = delete $data->{HelpUrl};
   $self->HelpUrl( $url ) if $url;
};

1;
