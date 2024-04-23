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

my @tests = ( [ qw<10     9212    139   66    38> ]
            , [ qw<10   101212    139  728    20> ]
            , [ qw<10    97445    139  701     6> ]
            , [ qw<10 24696000  25882  954  4572> ]
            , [ qw<10 34048000  25882 1315 13170> ]
            );
plan(tests => 2 + 2 * @tests);

my $refcsv  = slurp('xt/data/16-div-boat.csv' );
my $refhtml = slurp('xt/data/16-div-boat.html');
my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;
my Arithmetic::PaperAndPencil $dummy_op  = Arithmetic::PaperAndPencil->new;

for my $data (@tests) {
  my ($radix, $dividend, $divisor, $quotient, $remainder) = @$data;
  check_div($radix,  $dividend, $divisor, $quotient, $remainder);
}
is($operation->csv, $refcsv, "Checking CSV file");
my $html = $operation->html(lang => 'fr', silent => 0, level => 5);
is($html, $refhtml, "Checking HTML file");
done_testing;

sub check_div($radix, $dividend1, $divisor1, $quotient, $remainder) {

  my $dividend  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $dividend1);
  my $divisor   = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $divisor1 );
  my Arithmetic::PaperAndPencil::Number $result;
  $result = $operation->division(type => 'boat', dividend => $dividend, divisor => $divisor);
  is($result->value, $quotient, "$dividend1 divided by $divisor1 is $quotient");
  $result = $dummy_op->division(type => 'boat', dividend => $dividend, divisor => $divisor, result=> 'remainder');
  is($result->value, $remainder, "$dividend1 divided by $divisor1 is $quotient, remaining $remainder");

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
