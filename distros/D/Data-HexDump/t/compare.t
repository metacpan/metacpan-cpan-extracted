# -*- Mode: Perl -*-

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use Data::HexDump;

local $^W = 1;
my $t = 1;
print "1..2\n";

# data
my $org = "";
for (my $i = 0; $i <= 255; $i++) {
  $org .= pack 'c', $i;
}
$org = $org x 17 . "more data";

# non-oo
print &undump(HexDump $org) eq $org ? "" : "not ", "ok $t\n";
$t++;

# data
my $f = new Data::HexDump;
$f->data($org);
print &undump($f->dump) eq $org ? "" : "not ", "ok $t\n";

# filehandle
# todo

# file
# todo

sub undump {
  my $res = shift;
  my @t = split /\n/, $res;
  $res = '';
  splice @t, 0, 2;
  for my $line (@t) {
    $line = substr $line, 10, 49;
    my @n = split / +(?:\- )?/, $line;
    map { $res .= chr hex } @n;
  }
  $res;
}
