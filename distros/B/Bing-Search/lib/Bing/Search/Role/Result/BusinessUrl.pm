package Bing::Search::Role::Result::BusinessUrl;
use Moose::Role;

has 'BusinessUrl' => (
   is => 'rw',
   isa => 'Bing::Search::UrlType',
   coerce => 1
);

before '_populate' => sub { 
   my( $self ) = @_;
   my $data = $self->data;
   my $url = delete $data->{BusinessUrl};
   $self->BusinessUrl( $url ) if $url;
};

1;
