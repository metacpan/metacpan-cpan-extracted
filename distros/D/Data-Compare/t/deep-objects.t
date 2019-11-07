#!/usr/bin/perl -w

use strict;
use warnings;
# use diagnostics;

use Test::More;

use Data::Compare;

my $c = bless { foo => 1 }, 'Foo';
my $d = bless { c => $c }, "Foo::D";
my $e = bless { d => $d }, "Foo::E";
my $f = bless { e => $e }, "Foo::F";
my $g = bless { f => $f }, "Foo::G";
my $h = bless { g => $g }, "Foo::H";
my $i = bless { h => $h }, "Foo::I";
my $j = bless { i => $i }, "Foo::J";
my $k = Clone::clone $j;

Compare($j, $k);
ok(Compare($j, $k), 'Can compare deeply-nested objecty jibber-jabber');

done_testing();
