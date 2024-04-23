# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the generation of HTML on radix conversions
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

plan(tests => 11);

my $refcsv  = slurp('xt/data/18-conversion.csv' );
my $refhtml = slurp('xt/data/18-conversion.html');

my $operation = Arithmetic::PaperAndPencil->new;
my $x = Arithmetic::PaperAndPencil::Number->new(value => '628', radix => 10);
my $y = Arithmetic::PaperAndPencil::Number->new(value =>   '4', radix => 10);
my $z = Arithmetic::PaperAndPencil::Number->new(value =>   'Y', radix => 36);
my $t = Arithmetic::PaperAndPencil::Number->new(value => '4095', radix => 10);
my Arithmetic::PaperAndPencil::Number $result;

$result = $operation->conversion(number => $x, radix => 10, nb_op => 2); is($result->value,    '628', "Same radix, obvious conversion");
$result = $operation->conversion(number => $y, radix => 16, nb_op => 2); is($result->value,      '4', "Single digit, obvious conversion");
$result = $operation->conversion(number => $x, radix =>  8, nb_op => 2); is($result->value,   '1164', "No longer obvious conversion");
$result = $operation->conversion(number => $x, radix => 16, nb_op => 2); is($result->value,    '274', "No longer obvious conversion");
$result = $operation->conversion(number => $z, radix => 10, nb_op => 2); is($result->value,     '34', "Single digit, but still not an obvious conversion");
$result = $operation->conversion(number => $z, radix =>  2, nb_op => 2); is($result->value, '100010', "Single digit, but still not an obvious conversion");
$result = $operation->conversion(number => $t, radix => 16, nb_op => 2); is($result->value,    'FFF', "Not an obvious conversion (except if you are a geek)");
$result = $operation->conversion(number => $t, radix =>  8, nb_op => 2); is($result->value,   '7777', "Not an obvious conversion (except if you are a geek)");
$result = $operation->conversion(number => $t, radix =>  8);             is($result->value,   '7777', "Conversion without changing page");

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
