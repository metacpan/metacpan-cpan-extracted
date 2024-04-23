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

plan(tests => 6);

my $refcsv  = slurp('xt/data/11-mult-boat.csv' );
my $refhtml = slurp('xt/data/11-mult-boat.html');
my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;
my $x = Arithmetic::PaperAndPencil::Number->new(value => '729', radix => 10);
my $y = Arithmetic::PaperAndPencil::Number->new(value =>  '53', radix => 10);
my Arithmetic::PaperAndPencil::Number $pdt;

$pdt = $operation->multiplication(multiplicand => $x, multiplier => $y, type => 'boat');
is($pdt->value, '38637', "53 times 729 is 38637");
$pdt = $operation->multiplication(multiplicand => $x, multiplier => $y, type => 'boat', direction => 'rtl');
is($pdt->value, '38637', "53 times 729 is 38637, even if calculated right-to-left");

$x = Arithmetic::PaperAndPencil::Number->new(value => '628');
$y = Arithmetic::PaperAndPencil::Number->new(value => '234');
$pdt = $operation->multiplication(multiplicand => $x, multiplier => $y, type => 'boat', mult_and_add => 'combined');
is($pdt->value, '146952', '234 times 628 is 146952');

$x = Arithmetic::PaperAndPencil::Number->new(value => '345');
$y = Arithmetic::PaperAndPencil::Number->new(value => '333');
$pdt = $operation->multiplication(multiplicand => $x, multiplier => $y, type => 'boat', mult_and_add => 'combined', direction => 'rtl');
is($pdt->value, '114885', '333 times 345 is 114885');

is($operation->csv, $refcsv, "Checking CSV file");
my $html = $operation->html(lang => 'fr', silent => 0, level => 4);
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
