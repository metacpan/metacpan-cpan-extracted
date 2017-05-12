#!perl
# test pp()
use strict;
use Test::More tests => 8;
use vars qw($AR  $HR  @ARGold  @HRGold  @Arrays  @ArraysGold  @LArraysGold);
require 't/Testdata.pm';

use Data::Dumper::EasyOO;
use vars qw($ezfoo $ezbar);
$ezfoo = Data::Dumper::EasyOO->new (indent => 1);
$ezbar = Data::Dumper::EasyOO->new (indent => 2);

is ($ezfoo->pp($AR), $ARGold[0][1], "\$a->pp(AR)");
is ($ezbar->pp($AR), $ARGold[0][2], "\$b->pp(AR)");

is ($ezfoo->pp($HR), $HRGold[0][1], "\$a->pp(HR)");
is ($ezbar->pp($HR), $HRGold[0][2], "\$b->pp(HR)");


is ($ezfoo->dump($AR), $ARGold[0][1], "\$a->dump(AR)");
is ($ezbar->dump($AR), $ARGold[0][2], "\$b->dump(AR)");

is ($ezfoo->dump($HR), $HRGold[0][1], "\$a->dump(HR)");
is ($ezbar->dump($HR), $HRGold[0][2], "\$b->dump(HR)");

