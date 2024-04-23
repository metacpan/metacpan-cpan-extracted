# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the generation of HTML on two examples of multiplications.
#
# In some actions, the level has been tweaked a little to display
# intermediate results that would not have been displayed normally.
#
# Copyright 2023, 2024 Jean Forget
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

plan(tests => 8);

my $refcsv  = slurp('xt/data/07-mult.csv');
my $refhtml = slurp('xt/data/07-mult.html');
my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;
my $x = Arithmetic::PaperAndPencil::Number->new(value => '729', radix => 10);
my $y = Arithmetic::PaperAndPencil::Number->new(value =>   '3', radix => 10);
my $z = Arithmetic::PaperAndPencil::Number->new(value => '123', radix => 10);
my Arithmetic::PaperAndPencil::Number $pdt;

$pdt = $operation->multiplication(multiplicand => $x, multiplier => $y, type => 'std'       ); is($pdt->value, '2187');
$pdt = $operation->multiplication(multiplicand => $y, multiplier => $x, type => 'std'       ); is($pdt->value, '2187');
$pdt = $operation->multiplication(multiplicand => $x, multiplier => $y, type => 'jalousie-A'); is($pdt->value, '2187');
$pdt = $operation->multiplication(multiplicand => $x, multiplier => $y, type => 'jalousie-B'); is($pdt->value, '2187');
$pdt = $operation->multiplication(multiplicand => $x, multiplier => $z, type => 'jalousie-A', product => 'straight'); is($pdt->value, '89667');
$pdt = $operation->multiplication(multiplicand => $x, multiplier => $z, type => 'jalousie-B', product => 'straight'); is($pdt->value, '89667');

is($operation->csv, $refcsv, "Checking CSV file");
my $html = $operation->html(lang => 'fr', silent => 0, level => 2);
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
