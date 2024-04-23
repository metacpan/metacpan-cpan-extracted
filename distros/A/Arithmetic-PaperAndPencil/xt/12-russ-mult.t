# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the generation of HTML for the Russian peasant multiplication
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

my @tests = ( [ qw<10  510 514   262140> ]
            , [ qw<10  514 510   262140> ]
            , [ qw<11  424 428   169A4A> ]
            , [ qw<11  515 515   243813> ]
            , [ qw<10  628 234   146952> ]
            , [ qw<2   101101101 101111100 100001110111001100> ]
            );
plan(tests => 2 + @tests);

my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;

for my $test (@tests) {
  my ($radix, $md, $mr, $pdt) = @$test;
  my $md1 = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $md);
  my $mr1 = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $mr);
  my Arithmetic::PaperAndPencil::Number $pd1;
  $pd1 = $operation->multiplication(multiplicand => $md1, multiplier => $mr1, type => 'russian');
  is($pd1->value, $pdt, "$md × $mr = $pdt (radix $radix)");
}

my $html = $operation->html(lang => 'fr', silent => 0, level => 3);
my $refcsv  = slurp('xt/data/12-russ-mult.csv' );
my $refhtml = slurp('xt/data/12-russ-mult.html');

is($operation->csv, $refcsv, "Checking CSV file");
is($html, $refhtml, "Checking HTML file");

sub slurp($fname) {
  open my $f, '<', $fname
    or die "Opening $fname $!";
  $/ = undef;
  my $result = <$f>;
  close $f
    or die "Closing $fname $!";
  return $result;
}
