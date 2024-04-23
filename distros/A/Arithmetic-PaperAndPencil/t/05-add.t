# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the generation of HTML on addition
#
# Copyright 2024 Jean Forget
#
# This programme is free software; you can redistribute it and modify it under the Artistic License 2.0.

use 5.38.0;
use utf8;
use strict;
use warnings;
use Test::More;
use Arithmetic::PaperAndPencil;
use feature qw/class/;
use open ':encoding(UTF-8)';

plan(tests => 4);

my $refcsv;
my $refhtml;
my $fcsv  = 't/data/05-add.csv';
my $fhtml = 't/data/05-add.html';
open my $f1, '<', $fcsv  or die "opening $fcsv $!";
open my $f2, '<', $fhtml or die "opening $fhtml $!";
{ local $/ = undef;
  $refcsv  = <$f1>;
  $refhtml = <$f2>;
}
close $f1 or die "closing $fcsv $!";
close $f2 or die "closing $fhtml $!";

my $operation = Arithmetic::PaperAndPencil->new;
my @list;

# using radix 3 to have "big" carries (that is, carries with 2 digits or more)
for my $ch (qw<12 220 121 212 200 210>) {
  my $x =  Arithmetic::PaperAndPencil::Number->new(value => $ch, radix => 3);
  push(@list, $x);
}

# first test, using a single list parameter
my $sum = $operation->addition(@list);
is($sum->value, '10222', "Checking the sum (radix 3)");

# second test, using separate scalars
my $dead = Arithmetic::PaperAndPencil::Number->new(value => 'DEAD', radix => 16);
my $beef = Arithmetic::PaperAndPencil::Number->new(value => 'BEEF', radix => 16);
$sum = $operation->addition($dead, $beef);
is($sum->value, '19D9C', "DEAD + BEEF = 19D9C (radix 16)");

is($operation->csv, $refcsv, "Checking CSV file");
my $html = $operation->html(lang => 'fr', silent => 0, level => 3, css => {});
is($html, $refhtml, "Checking HTML file");

