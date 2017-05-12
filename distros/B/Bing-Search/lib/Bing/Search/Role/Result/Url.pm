package Bing::Search::Role::Result::Url;
use Moose::Role;

has 'Url' => (
   is => 'rw',
   isa => 'Bing::Search::UrlType',
   coerce => 1
);

before '_populate' => sub { 
   my( $self ) = @_;
   my $data = $self->data;
   my $url = delete $data->{Url};
   $self->Url( $url ) if $url;
};

1;
