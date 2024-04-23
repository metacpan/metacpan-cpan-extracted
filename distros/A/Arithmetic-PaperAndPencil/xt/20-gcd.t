# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the generation of HTML when computing the greatest common divisor
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

my @tests = (  [ qw<10 355000000   113   1> ]
            ,  [ qw<10     12345 54321   3> ]
            );
plan(tests => 2 + 2 * @tests);

my $refcsv  = slurp('xt/data/20-gcd.csv' );
my $refhtml = slurp('xt/data/20-gcd.html');
my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;

for my $data (@tests) {
  my ($radix, $first, $second, $result) = @$data;
  check_gcd_std($radix, $first, $second, $result);
}

for my $data (@tests) {
  my ($radix, $first, $second, $result) = @$data;
  check_gcd_cheat($radix, $first, $second, $result);
}


is($operation->csv, $refcsv, "Checking CSV file");
my $html = $operation->html(lang => 'fr', silent => 0, level => 6);
is($html, $refhtml, "Checking HTML file");

sub check_gcd_std($radix, $first1, $second1, $result1) {
  my $first   = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $first1);
  my $second  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $second1);
  my Arithmetic::PaperAndPencil::Number $result;
  $result = $operation->gcd(first => $first, second => $second);
  is($result->value, $result1, "gcd(@{[$first->value]}, @{[$second->value]}) = $result1 (radix $radix)");
}

sub check_gcd_cheat($radix, $first1, $second1, $result1) {
  my $first   = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $first1);
  my $second  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $second1);
  my Arithmetic::PaperAndPencil::Number $result;
  $result = $operation->gcd(first => $first, second => $second, div_type => 'cheating');
  is($result->value, $result1, "gcd(@{[$first->value]}, @{[$second->value]}) = $result1 (radix $radix)");
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
