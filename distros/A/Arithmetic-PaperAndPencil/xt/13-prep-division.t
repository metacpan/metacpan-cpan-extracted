# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the generation of HTML on prepared division
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

my $refcsv  = slurp('xt/data/13-prep-division.csv' );
my $refhtml = slurp('xt/data/13-prep-division.html');
my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;

my @list;
my Arithmetic::PaperAndPencil::Number $result;
my $dividend  = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '3500');
my $divisor   = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '85');

$result = $operation->division(dividend => $dividend, divisor => $divisor, type => 'prepared');
is($result->value, '41', "3500 divided by 85 is 41 (long hook, no zero)");

$dividend = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '24696000');
$divisor  = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '25882');

$result = $operation->division(dividend => $dividend, divisor => $divisor, type => 'prepared', result => 'remainder');
is($result->value, '4572', "24696000 divided by 25882 is 954, remainder 4572 (long hook, no zero)");

$dividend = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '34048000');

@list = $operation->division(dividend => $dividend, divisor => $divisor, type => 'prepared', result => 'both');
is($list[0]->value, '1315' , "34048000 divided by 25882 is 1315");
is($list[1]->value, '13170', "34048000 divided by 25882 is 1315, remainder 13170 (short hook, no zero)");

$dividend = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '26048000');
$result = $operation->division(dividend => $dividend, divisor => $divisor, type => 'prepared');
is($result->value, '1006', "26048000 divided by 25882 is 1006 (short hook, two inner zeroes)");

$dividend = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '26399640');
$result = $operation->division(dividend => $dividend, divisor => $divisor, type => 'prepared');
is($result->value, '1020', "26399640 divided by 25882 is 1020 (short hook, one inner zero and one final zero)");

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
