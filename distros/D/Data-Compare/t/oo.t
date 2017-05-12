# -*- Mode: Perl -*-

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use Data::Compare;

local $^W = 1;
print "1..7\n";

my $t = 1;

my $a = { 'foo' => [ 'bar', 'baz' ] };
my $b = { 'Foo' => [ 'bar', 'baz' ] };

my $c = new Data::Compare ($a, $b);
print !$c->Cmp ? "" : "not ", "ok ", $t++, "\n";
print $c->Cmp($a, $a) ? "" : "not ", "ok ", $t++, "\n";
print !$c->Cmp($a, $b) ? "" : "not ", "ok ", $t++, "\n";

my $d = new Data::Compare;
print $d->Cmp ? "" : "not ", "ok ", $t++, "\n";
print $d->Cmp($a, $a) ? "" : "not ", "ok ", $t++, "\n";
print !$d->Cmp($a, $b) ? "" : "not ", "ok ", $t++, "\n";

my $e = new Data::Compare;

print $d->Cmp ($d, $e) ? "" : "not ", "ok ", $t++, "\n";
