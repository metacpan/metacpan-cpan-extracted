#!/usr/bin/perl -Tw

use Test::More tests => 6;

use strict;
use CGI;
use CGI::Untaint;

my @dates = (
  "1950-05-02T11:23:22",
  "2020-04-02 02:01:59",
  "2008-12-30T01:59",
  "1970-01-01 00:00",
  "2004-12-01T14:11:42",
);

my $count = 0;
my %hash = map { "var" . ++$count => $_ } @dates;
my $q = CGI->new(\%hash);

ok(my $data = CGI::Untaint->new( $q->Vars ), "Can create the handler");

$count = 0;
foreach (@dates) {
  ++$count;
  isa_ok($data->extract(-as_datetime => "var$count"),"Time::Piece");
}
