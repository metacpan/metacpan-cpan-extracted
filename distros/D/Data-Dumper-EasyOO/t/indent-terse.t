#!perl
# creates 1 EzDD, and alters it repeatedly, using both Set and AUTOLOAD
use strict;

use Test::More (tests => 98);
use vars qw($AR  $HR  @ARGold  @HRGold  @Arrays  @ArraysGold  @LArraysGold);
require 't/Testdata.pm';

use_ok qw(Data::Dumper::EasyOO);

my $ddez = Data::Dumper::EasyOO->new();
isa_ok ($ddez, 'Data::Dumper::EasyOO', "good DDEz object");

pass "dump with default indent";
is ($ddez->($AR), $ARGold[0][2], "AR, with indent, terse defaults");
is ($ddez->($HR), $HRGold[0][2], "HR, with indent, terse defaults");

pass "test combos of Terse(T), Indent(I)";
for my $t (0..1) {
    pass "following with Terse($t)";
    $ddez->Terse($t);
    for my $i (0..3) {
	$ddez->Indent($i);
	is ($ddez->($AR), $ARGold[$t][$i], "HR, with Indent($i)");
	is ($ddez->($HR), $HRGold[$t][$i], "HR, with Indent($i)");
    }
}
pass "repeat with opposite nesting";
for my $i (0..3) {
    $ddez->Indent($i);
    pass "following with Indent($i)";
    for my $t (0..1) {
	$ddez->Terse($t);
	is ($ddez->($AR), $ARGold[$t][$i], "HR, with Indent($i)");
	is ($ddez->($HR), $HRGold[$t][$i], "HR, with Indent($i)");
    }
}


pass "test combos of Set(indent=>I), Set(terse=>T)";
for my $t (0..1) {
    pass "following with Set(terse=>$t)";
    $ddez->Set(terse=>$t);
    for my $i (0..3) {
	$ddez->Set(indent=>$i);
	is ($ddez->($AR), $ARGold[$t][$i], "AR, with Set(indent=>$i)");
	is ($ddez->($HR), $HRGold[$t][$i], "HR, with Set(indent=>$i)");
    }
}


pass "test combos of Set(indent=>I,terse=>T)";
for my $t (0..1) {
    for my $i (0..3) {
	$ddez->Set(indent=>$i,terse=>$t);
	is ($ddez->($AR), $ARGold[$t][$i],
	    "AR, with Set(indent=>$i,terse=>$t)");
	is ($ddez->($HR), $HRGold[$t][$i],
	    "HR, with Set(indent=>$i,terse=>$t)");
    }
}
pass "repeat with opposite nesting";
for my $i (0..3) {
    for my $t (0..1) {
	$ddez->Set(indent=>$i,terse=>$t);
	is ($ddez->($AR), $ARGold[$t][$i],
	    "AR, with Set(indent=>$i,terse=>$t)");
	is ($ddez->($HR), $HRGold[$t][$i],
	    "HR, with Set(indent=>$i,terse=>$t)");
    }
}

