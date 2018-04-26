package Activiti::Rest::UserAgent;
use Activiti::Sane;
use Data::Util qw(:validate :check);
use Moo::Role;

has url => (
    is => 'ro',
    isa => sub { $_[0] =~ /^https?:\/\//o or die("url must be a valid web url\n"); },
    required => 1
);
has timeout => (
  is => 'ro',
  isa => sub { is_integer($_[0]) && $_[0] >= 0 || die("timeout should be natural number"); },
  lazy => 1,
  default => sub { 180; }
);
has default_headers => (
    is => 'ro',
    isa => sub { array_ref($_[0]); },
    default => sub { [["Accept","application/json; charset=UTF-8"]]; }
);

#usage: request($params,$method)
requires qw(request);

1;
