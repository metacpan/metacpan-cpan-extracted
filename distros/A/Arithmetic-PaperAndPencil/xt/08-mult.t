# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the generation of HTML on two examples of multiplication with embedded zeroes.
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

plan(tests => 4);

my $refcsv  = slurp('xt/data/08-mult.csv');
my $refhtml = slurp('xt/data/08-mult.html');
my $operation = Arithmetic::PaperAndPencil->new;
my $x = Arithmetic::PaperAndPencil::Number->new(value => '10200300040000', radix => 10);
my $y = Arithmetic::PaperAndPencil::Number->new(value => '2'  , radix => 10);
my $z = Arithmetic::PaperAndPencil::Number->new(value => '101', radix => 10);
my Arithmetic::PaperAndPencil::Number $pdt;

$pdt = $operation->multiplication(multiplicand => $x, multiplier => $x, type => 'std');
is($pdt->value, '104046120906024001600000000', "product is 104046120906024001600000000");
$pdt = $operation->multiplication(multiplicand => $y, multiplier => $z, type => 'std');
is($pdt->value, '202', "product is 202");

is($operation->csv, $refcsv, "checking the CSV file");
my $html = $operation->html(lang => 'fr', silent => 0, level => 3);
is($html, $refhtml, "checking the HTML file");

sub slurp($fname) {
  open my $f, '<', $fname
    or die "Opening $fname $!";
  $/ = undef;
  my $result = <$f>;
  close $f
    or die "Closing $fname $!";
  return $result;
}
