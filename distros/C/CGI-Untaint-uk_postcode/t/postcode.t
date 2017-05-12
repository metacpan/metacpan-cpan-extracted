#!/usr/bin/perl -w

use Test::More tests => 19;

use strict;
use CGI;
use CGI::Untaint;

my @ok = ('W1 3NT', 'E17 8pr', 'BT6 2NG', 'Bt23 1NG', 
          'N1C 8UH', 'ne6 9Rw', 'BPO1PS');

my @not = ('', 'B', '1', 'BT', '11', 'BT1', 'B1F1 5NG',
           'BT6 888', 'BT100 5RT', 'WCF 200', 'BT6 8CI');

my $count = 1;
my %hash = map { "var" . $count++ => $_ } @ok, @not;
my $q = CGI->new({%hash});

ok(my $data = CGI::Untaint->new( $q->Vars ), "Can create the handler");

$count = 0;
foreach (@ok) {
  ++$count;
  ok($data->extract(-as_uk_postcode => "var$count"), "Valid: " . $q->param("var$count"));
}

foreach (@not) {
  ++$count;
  ok(!$data->extract(-as_uk_postcode => "var$count"), "Not valid: " . $q->param("var$count"));
}
