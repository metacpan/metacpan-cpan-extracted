# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the generation of HTML on square root extraction
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

my @tests = (  [ qw<10  2000000  1414> ]
            ,  [ qw<10 11000000  3316> ]
            ,  [ qw<10 18000000  4242> ]
            ,  [ qw<10 32000000  5656> ]
            ,  [ qw<10 99123456  9956> ]
            ,  [ qw<10  9000000  3000> ]
            ,  [ qw<10  9006001  3001> ]
            ,  [ qw<10  6554900  2560> ]
            ,  [ qw<16     2710    64> ]
            ,  [ qw<16    F4240   3E8> ]
            );
plan(tests => 2 + 2 * @tests);

my $refcsv  = slurp('xt/data/17-square-root.csv' );
my $refhtml = slurp('xt/data/17-square-root.html');
my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;

for my $data (@tests) {
  my ($radix, $number, $result) = @$data;
  check_sqrt($radix, $number, $result);
}

for my $data (@tests) {
  my ($radix, $number, $result) = @$data;
  check_sqrt_sep($radix, $number, $result);
}


is($operation->csv, $refcsv, "Checking CSV file");
my $html = $operation->html(lang => 'fr', silent => 0, level => 4);
is($html, $refhtml, "Checking HTML file");

done_testing;

sub check_sqrt($radix, $number1, $result1) {
  my $number = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $number1);
  my Arithmetic::PaperAndPencil::Number $result;
  $result = $operation->square_root($number);
  is($result->value, $result1, "sqrt @{[$number->value]} = $result1 (radix $radix)");
}

sub check_sqrt_sep($radix, $number1, $result1) {
  my $number = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $number1);
  my Arithmetic::PaperAndPencil::Number $result;
  $result = $operation->square_root($number, mult_and_sub => 'separate');
  is($result->value, $result1, "sqrt @{[$number->value]} = $result1 (radix $radix)");
}

sub slurp($fname) {
  open my $f, '<', $fname
    or die "Opening $fname $!";
  $/ = undef;
  my $result = <$f>;
  close $f
    or die "Closing $fname $!";
  return $result;
}
