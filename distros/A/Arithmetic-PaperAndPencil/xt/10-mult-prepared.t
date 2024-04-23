# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the generation of HTML on two examples of prepared multiplications
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

my $refcsv  = slurp('xt/data/10-mult-prepared.csv' );
my $refhtml = slurp('xt/data/10-mult-prepared.html');
my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;
my $x = Arithmetic::PaperAndPencil::Number->new(value => '141421356');
my $y = Arithmetic::PaperAndPencil::Number->new(value => '42426408712');
my Arithmetic::PaperAndPencil::Number $pdt;

$pdt = $operation->multiplication(multiplicand => $x, multiplier => $x, type => 'prepared');
is($pdt->value, '19999999932878736', "Square of 141421356 is 19999999932878736");

$pdt = $operation->multiplication(multiplicand => $y, multiplier => $y, type => 'prepared');
is($pdt->value, '1800000156197669498944', "Square of 42426408712 is 1800000156197669498944");

is($operation->csv, $refcsv, "Checking CSV file");
my $html = $operation->html(lang => 'fr', silent => 0, level => 3);
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
