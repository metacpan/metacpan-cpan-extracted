package Activiti::Rest::UserAgent;
use Activiti::Sane;
use Data::Util qw(:validate :check);
use Moo::Role;

has url => (
    is => 'ro',
    isa => sub { $_[0] =~ /^https?:\/\//o or die("url must be a valid web url\n"); },
    required => 1
);
has default_headers => (
    is => 'ro',
    isa => sub { array_ref($_[0]); },
    default => sub { [["Accept","application/json; charset=UTF-8"]]; }
);

#usage: request($params,$method)
requires qw(request);

1;
