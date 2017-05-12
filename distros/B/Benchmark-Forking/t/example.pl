#!perl
use strict;

use Benchmark qw( cmpthese );

sub do_benchmark {
  my @global;
  cmpthese( $ARGV[0] || 1000, {
    "test_1" => sub { push @global, scalar grep 1, @global },
    "test_2" => sub { push @global, scalar grep 1, @global },
    "test_3" => sub { push @global, scalar grep 1, @global },
  } );
  print "\n";
}

print "Baseline...\n";
do_benchmark();

print "Forking loaded but disabled...\n";
require "Forking.pm";
Benchmark::Forking->disable;
do_benchmark();

print "Forking enabled...\n";
Benchmark::Forking->enable;
do_benchmark();

1;
