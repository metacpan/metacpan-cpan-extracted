#!/usr/bin/perl -w

use strict;
use CGI;
use CGI::Untaint;

use Test::More tests => 11;

my @ok = (
  '0099405172',
  '185723975X',
  '0-140-008055',
  '0 708 883095',
  '0_140_008055',
  '1S857[239$75X',
);

my @not = (
  '0099405173',
  '185723975Y',
  'ABCDEFGHIJ',
  '12345678901',
);

my $count = 0;
my %hash = map { "var" . ++$count => $_ } @ok, @not;

my $q = CGI->new({%hash});

isa_ok(CGI::Untaint->new( $q->Vars ), "CGI::Untaint");
my $data = CGI::Untaint->new( $q->Vars );

$count = 0;
foreach (@ok) {
  ++$count;
  my $key = "var" . $count;

  my $isbn = $data->extract(-as_isbn => $key);
  ok($isbn, "Valid: " . $q->param($key) . " (as $isbn)");
}

foreach (@not) {
  ++$count;
  ok(!$data->extract(-as_isbn => "var$count"),
    "Not Valid: " . $q->param("var$count"));
}
