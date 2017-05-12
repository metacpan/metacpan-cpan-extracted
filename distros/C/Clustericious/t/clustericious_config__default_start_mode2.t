use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More tests => 2;

create_config_ok Foo => {
  url => "http://localhost:3014",
  start_mode => "hypnotoad",
  hypnotoad => {
  },
};

do {
  package Foo;
  
  use base 'Clustericious::App';
  use Clustericious::RouteBuilder;
};

my $app = eval { Foo->new };
is $@, '', 'string start mod edoes not crash';
