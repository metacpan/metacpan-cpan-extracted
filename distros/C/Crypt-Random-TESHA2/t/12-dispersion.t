#!/usr/bin/env perl
use strict;
use warnings;
use Crypt::Random::TESHA2 qw/random_bytes/;
use Time::HiRes qw/gettimeofday/;
use Test::More;

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    plan( skip_all => 'these tests are for release candidate testing' );
  }
}

eval { require Statistics::Basic; Statistics::Basic->import(); };
plan skip_all => "Statistics::Basic needed for dispersion test." if $@;

plan tests => 2;

my $amount = 1e4;
my $approxsd = 6;  # 1k => 2, 10k => 6, 100k => 20, 1M => 60
my %dispersion;
$dispersion{ord random_bytes(1)}++ for 1..$amount;

is_deeply( [map { 0 + exists $dispersion{$_} } 0..255],
           [map { 1 } 0..255],
           "All numeric values 0-255 can be produced" );

my $s = Statistics::Basic::stddev(
  map {defined $_ ? $_ : 0} @dispersion{0..255}
)->query;
ok 2 > log($s) / log(10),
  "$amount values are roughly evenly distributed "
  . "(standard deviation was $s, should be about $approxsd)";
