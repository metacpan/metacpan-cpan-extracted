#!/usr/bin/perl

package InsideOut;

use strict;
use warnings;

eval "use Class::Field qw(field);";
use Class::Tie::InsideOut;

our @ISA = qw( Class::Tie::InsideOut );

our %GoodKey;

field('GoodKey');

package main;

use strict;
use warnings;

use Test::More skip_all => "Class::Field fails tests";

eval "use Class::Field;";
plan skip_all => "Class::Field is not installed" if ($@);

plan tests => 3;

my $obj = InsideOut->new();
ok($obj->isa("InsideOut"));
ok($obj->isa("Class::Tie::InsideOut"));

$obj->GoodKey(1);
ok($obj->GoodKey == 1, "set/get");

