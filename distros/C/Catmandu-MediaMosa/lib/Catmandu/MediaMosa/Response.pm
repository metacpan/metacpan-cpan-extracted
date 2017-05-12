package Catmandu::MediaMosa::Response;
use Catmandu::Sane;
use Moo;
use Data::Util qw(:check :validate);
use Catmandu::MediaMosa::Response::Items;
use Catmandu::MediaMosa::Response::Header;

has header => (
  is => 'ro',
  isa => sub {
    instance($_[0],"Catmandu::MediaMosa::Response::Header");
  }
);
has items => (
  is => 'ro',
  isa => sub {
    instance($_[0],"Catmandu::MediaMosa::Response::Items");
  }
);

1;
