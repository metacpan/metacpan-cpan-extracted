#!perl
# test use-time print-style control
use strict;
use vars qw($ezfoo $ezbar);

package Foo;
use Data::Dumper::EasyOO ( indent => 1 );
$main::ezfoo = Data::Dumper::EasyOO->new;

package Bar;
use Data::Dumper::EasyOO ( indent => 2 );
$main::ezbar = Data::Dumper::EasyOO->new;

package main;
use Test::More tests => 5;
use vars qw($AR  $HR  @ARGold  @HRGold  @Arrays  @ArraysGold  @LArraysGold);
require 't/Testdata.pm';

pass "dump with default indent";
is ($ezfoo->($AR), $ARGold[0][1], "AR, with Foo imported defaults");
is ($ezbar->($AR), $ARGold[0][2], "AR, with Bar imported defaults");

is ($ezfoo->($HR), $HRGold[0][1], "HR, with Foo imported defaults");
is ($ezbar->($HR), $HRGold[0][2], "HR, with Bar imported defaults");

