#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use Time::HiRes 'gettimeofday';
use ASP4::API;
my $api = ASP4::API->new;

ok(1);

{
  my ($time, $persec) = bench('/handlers/dev.simple', 1000);
  warn "\nGET /handlers/dev.simple 1000 times in $time seconds ($persec/second)\n";
}

{
  my ($time, $persec) = bench('/handlers/dev.speed', 1000);
  warn "GET /handlers/dev.speed 1000 times in $time seconds ($persec/second)\n";
}

{
  my ($time, $persec) = bench('/useragent/hello-world.asp', 1000);
  warn "GET /useragent/hello-world.asp 1000 times in $time seconds ($persec/second)\n";
}

{
  my ($time, $persec) = bench('/pageparser/child-inner2.asp', 1000);
  warn "GET /pageparser/child-inner2.asp 1000 times in $time seconds ($persec/second)\n";
}

{
  my ($time, $persec) = bench('/masters/deep.asp', 1000);
  warn "GET /masters/deep.asp 1000 times in $time seconds ($persec/second)\n";
}

sub bench {
  my ($uri, $times) = @_;
  my $start = gettimeofday();
  for( 1..$times ) {
    $api->ua->get($uri)->is_success or die "ERROR";
  }
  
  my $diff = gettimeofday() - $start;
  my $persec = $times / $diff;
  return ($diff, $persec);
}

