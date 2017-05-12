#!/usr/bin/perl -Tw

use Test::More tests => 5;

use strict;
use CGI;
use CGI::Untaint;

my @dates = (
  "December 12, 2001",
  "12th December, 2001",     
  "2001-12-12",              
  "second Wednesday in December, 2001",
);

my $count = 0;
my %hash = map { "var" . ++$count => $_ } @dates;
my $q = CGI->new(\%hash);

ok(my $data = CGI::Untaint->new( $q->Vars ), "Can create the handler");

$count = 0;
foreach (@dates) {
  ++$count;
  is $data->extract(-as_date => "var$count")->format, "2001-12-12",
    "$_ = 2001-12-12";
}
