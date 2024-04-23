# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the generation of HTML on division
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

plan(tests => 7);

my $refcsv  = slurp('xt/data/14-division.csv' );
my $refhtml = slurp('xt/data/14-division.html');
my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;
my Arithmetic::PaperAndPencil::Number $result;
my $x   = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '9212');
my $x1  = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '101212');
my $x2  = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '83645');
my $y   = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '139');
my $one = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '1');

$result = $operation->division(dividend => $x, divisor => $one);                      is($result->value, '9212', "division by 1 is obvious");
$result = $operation->division(dividend => $y, divisor => $x);                        is($result->value, '0'   , "division of a small dividend by a large divisor is obvious");
$result = $operation->division(dividend => $x, divisor => $y, result => 'remainder'); is($result->value, '38'  , "9212 divided by 139 gives 66, remainder 38");
$result = $operation->division(dividend => $x, divisor => $y, type   => 'cheating');  is($result->value, '66'  , "9212 divided by 139 gives 66");
$result = $operation->division(dividend => $x1, divisor => $y);                       is($result->value, '728' , "101212 divided by 139 gives 728");

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
