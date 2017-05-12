# TKTAuthCookieExpires testing

use File::Basename;
use Test::More tests => 21;
BEGIN { use_ok( Apache::AuthTkt ) }
use strict;

my $dir = dirname($0);

my $at;
my %tests = (
  'expires01.conf' => 12345,
  'expires02.conf' => 1064,              # seconds
  'expires03.conf' => 25 * 60,           # minutes
  'expires04.conf' => 12 * 3600,         # hours
  'expires05.conf' => 3 * 86400,         # days
  'expires06.conf' => 3 * 7 * 86400,     # weeks
  'expires07.conf' => 2 * 30 * 86400,    # months
  'expires08.conf' => 1 * 365 * 86400,   # years
  # complex mixed cases
  'expires09.conf' => 1 * 365 * 86400 +
                      3 * 30 * 86400 +
                      2 * 7 * 86400 +
                      4 * 86400 +
                      6 * 3600 + 
                      12 * 60 + 
                      10,
  'expires10.conf' => 2 * 365 * 86400 +
                      3 * 30 * 86400 +
                      1 * 86400 +
                      2 * 3600 + 
                      12,
);

for my $test (sort keys %tests) {
  ok($at = Apache::AuthTkt->new(conf => "$dir/t06/$test"),
    "$test conf constructor ok");
  is($at->cookie_expires, $tests{$test}, "$test cookie_expires ok");
}

# vim:ft=perl
