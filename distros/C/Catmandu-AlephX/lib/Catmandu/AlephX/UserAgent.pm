package Catmandu::AlephX::UserAgent;
use Catmandu::Sane;
use Catmandu::Util qw(:check);
use Moo::Role;

our $VERSION = "1.072";

has url => (
  is => 'ro',
  isa => sub { $_[0] =~ /^https?:\/\//o or die("url must be a valid web url\n"); },
  required => 1
);
has default_args => (
  is => 'ro',
  isa => sub { check_hash_ref($_[0]); },
  lazy => 1,
  default => sub { +{}; }
);

#usage: request($params,$methods)
requires qw(request);

1;
