#!/usr/bin/perl -w

use Test::More tests => 10;

use strict;
use CGI;
use CGI::Untaint;

my @ok = ('10.0.0.1', '255.255.255.255');

my @not = ('foo', '00:03:93:d7:4d:b6', '10:1:4:1', '10.0250.20.10',
           '256.256.256.256', '1.1.2.300', '1.2.3.4.5');

my $count = 1;
my %hash = map { "var" . $count++ => $_ } @ok, @not;
my $q = CGI->new({%hash});

ok(my $data = CGI::Untaint->new( $q->Vars ), "Can create the handler");

$count = 0;
foreach (@ok) {
  ++$count;
  ok($data->extract(-as_ipaddress => "var$count"), "Valid: " . $q->param("var$count"));
}

foreach (@not) {
  ++$count;
  ok(!$data->extract(-as_ipaddress => "var$count"), "Not valid: " . $q->param("var$count"));
}
