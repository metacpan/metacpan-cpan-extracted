use Test::More;
use strict;
use warnings;

use App::VW;

our @tests = (
  sub {
    my $config = App::VW->config;
    is(ref($config), 'HASH', 'App::VW->config should return a hashref.');
  },
);

plan tests => scalar(@tests);

for my $test (@tests) { $test->() }
