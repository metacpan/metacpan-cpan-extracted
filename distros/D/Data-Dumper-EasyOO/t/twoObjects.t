#!perl
# test that 2 DDEz objects are isolated wrt print options
use strict;
use Test::More (tests => 135);
use vars qw($AR  $HR  @ARGold  @HRGold  @Arrays  @ArraysGold  @LArraysGold);
require 't/Testdata.pm';

use_ok qw(Data::Dumper::EasyOO);

my $ez1 = Data::Dumper::EasyOO->new();
my $ez2 = Data::Dumper::EasyOO->new(indent=>0);
isa_ok ($ez1, 'Data::Dumper::EasyOO', "1st DDEz object");
isa_ok ($ez2, 'Data::Dumper::EasyOO', "2nd DDEz object");

pass "dump with default indent & terse-ness ";
is ($ez1->($AR), $ARGold[0][2], "AR, with indent, terse defaults");
is ($ez1->($HR), $HRGold[0][2], "HR, with indent, terse defaults");
is ($ez2->($AR), $ARGold[0][0], "AR, with indent, terse defaults");
is ($ez2->($HR), $HRGold[0][0], "HR, with indent, terse defaults");

pass "test combos of Terse(T), Indent(I)";
for my $t (0..1) {
    pass "following with Terse($t)";
    $ez1->Terse($t);
    $ez2->Terse(1-$t);
    for my $i (0..2) {
	$ez1->Indent($i);
	$ez2->Indent(2-$i);

	is ($ez1->($AR), $ARGold[$t][$i],     "1st, with Indent($i)");
	is ($ez2->($AR), $ARGold[1-$t][2-$i], "2nd, with Indent(2-$i)");

	is ($ez1->($HR), $HRGold[$t][$i],     "1st, with Indent($i)");
	is ($ez2->($HR), $HRGold[1-$t][2-$i], "2nd, with Indent(2-$i)");
    }
}
pass "repeat with opposite nesting";
for my $i (0..2) {
    $ez1->Indent($i);
    $ez2->Indent(2-$i);
    for my $t (0..1) {
	pass "following with Terse($t)";
	$ez1->Terse($t);
	$ez2->Terse(1-$t);
	
	is ($ez1->($AR), $ARGold[$t][$i],     "1st, with Indent($i)");
	is ($ez2->($AR), $ARGold[1-$t][2-$i], "2nd, with Indent(2-$i)");

	is ($ez1->($HR), $HRGold[$t][$i],     "1st, with Indent($i)");
	is ($ez2->($HR), $HRGold[1-$t][2-$i], "2nd, with Indent(2-$i)");
    }
}


pass "test combos of Set(indent=>I), Set(terse=>T)";
for my $t (0..1) {
    pass "following with Set(terse=>$t)";
    $ez1->Set(terse=>$t);
    $ez2->Set(terse=>1-$t);
    for my $i (0..2) {
	$ez1->Set(indent=>$i);
	$ez2->Set(indent=>2-$i);

	is ($ez1->($AR), $ARGold[$t][$i],     "1st, with Indent($i)");
	is ($ez2->($AR), $ARGold[1-$t][2-$i], "2nd, with Indent(2-$i)");

	is ($ez1->($HR), $HRGold[$t][$i],     "1st, with Indent($i)");
	is ($ez2->($HR), $HRGold[1-$t][2-$i], "2nd, with Indent(2-$i)");

    }
}

pass "test combos of Set(indent=>I,terse=>T)";
for my $t (0..1) {
    pass "following with Set(terse=>$t)";
    for my $i (0..2) {
	$ez1->Set(indent=>$i,  terse=>$t);
	$ez2->Set(indent=>2-$i,terse=>1-$t);

	is ($ez1->($AR), $ARGold[$t][$i],     "1st, with Indent($i)");
	is ($ez2->($AR), $ARGold[1-$t][2-$i], "2nd, with Indent(2-$i)");

	is ($ez1->($HR), $HRGold[$t][$i],     "1st, with Indent($i)");
	is ($ez2->($HR), $HRGold[1-$t][2-$i], "2nd, with Indent(2-$i)");

    }
}

pass "test combos of Set(indent=>I,terse=>T) on 1, leave 2 alone";

$ez2->Set(indent=>1,terse=>1); # 

for my $t (0..1) {
    pass "following with Set(terse=>$t)";
    for my $i (0..2) {
	$ez1->Set(indent=>$i,  terse=>$t);

	is ($ez1->($AR), $ARGold[$t][$i], "1st, Set(indent=$i,terse=$t)");
	is ($ez2->($AR), $ARGold[1][1],   "2nd, unchanged");
    }
}

