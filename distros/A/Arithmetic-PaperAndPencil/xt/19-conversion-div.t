# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the generation of HTML on radix conversions with cascading divisions
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

plan(tests => 9);

my $refcsv   = slurp('xt/data/19-conversion-div.csv');
my $refhtml1 = slurp('xt/data/19-conversion-div.html');
my $refhtml2 = slurp('xt/data/19-conversion-div-bis.html');

my $operation = Arithmetic::PaperAndPencil->new;
my $x = Arithmetic::PaperAndPencil::Number->new(value => '628', radix => 10);
my $z = Arithmetic::PaperAndPencil::Number->new(value => '3735928559', radix => 10);
my Arithmetic::PaperAndPencil::Number $result;

$result = $operation->conversion(number => $x, radix =>  8, nb_op => 2, type => 'div', div_type => 'prepared');
is($result->value, '1164', "628(10) -> 1164(8)");
$result = $operation->conversion(number => $x, radix => 16, nb_op => 2, type => 'div', div_type => 'prepared');
is($result->value, '274', "628(10) -> 274(16)");
$result = $operation->conversion(number => $z, radix => 16, nb_op => 2, type => 'div', div_type => 'prepared');
is($result->value, 'DEADBEEF', "3735928559(10) -> DEADBEEF(16)");
$result = $operation->conversion(number => $z, radix => 16, nb_op => 2, type => 'div', div_type => 'std');
is($result->value, 'DEADBEEF', "3735928559(10) -> DEADBEEF(16)");
$result = $operation->conversion(number => $z, radix => 16, nb_op => 2, type => 'div', div_type => 'cheating', mult_and_sub => 'combined');
is($result->value, 'DEADBEEF', "3735928559(10) -> DEADBEEF(16)");
$result = $operation->conversion(number => $z, radix => 16, nb_op => 2, type => 'div', div_type => 'cheating', mult_and_sub => 'separate');
is($result->value, 'DEADBEEF', "3735928559(10) -> DEADBEEF(16)");

is($operation->csv, $refcsv, "Checking CSV file");
my $html = $operation->html(lang => 'fr', silent => 0, level => 4);
is($html, $refhtml1, "Checking HTML file with level 4");
$html = $operation->html(lang => 'fr', silent => 0, level => 6);
is($html, $refhtml2, "Checking HTML file with level 6");

sub slurp($fname) {
  open my $f, '<', $fname
    or die "Opening $fname $!";
  $/ = undef;
  my $result = <$f>;
  close $f
    or die "Closing $fname $!";
  return $result;
}
