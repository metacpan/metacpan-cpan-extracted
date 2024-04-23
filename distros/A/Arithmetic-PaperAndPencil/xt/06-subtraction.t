# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the generation of HTML on subtraction
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

my @tests = (  [ qw< 10  123450000012345  8867700  123449991144645 > ]
            ,  [ qw< 16  DEAD             BEEF     1FBE            > ]
            ,  [ qw< 10  9987             9987     0               > ]
            ,  [ qw< 10  9987             128      9859            > ]
            ,  [ qw< 10  128              77       51              > ]
            );
plan(tests => 2 + 2 * @tests);

my $fcsv  = 'xt/data/06-subtraction.csv' ;
my $fhtml = 'xt/data/06-subtraction.html';
open my $f1, '<', $fcsv  or die "opening $fcsv $!";
open my $f2, '<', $fhtml or die "opening $fhtml $!";
my $refcsv;
my $refhtml;
{ local $/ = undef;
  $refcsv  = <$f1>;
  $refhtml = <$f2>;
}
close $f1 or die "closing $fcsv $!";
close $f2 or die "closing $fhtml $!";

my $operation = Arithmetic::PaperAndPencil->new;

for my $data (@tests) {
  my ($radix, $high, $low, $result) = @$data;
  check_sub($radix, $high, $low, $result);
}


is($operation->csv, $refcsv, "Checking CSV file");
my $html = $operation->html();
is($html, $refhtml, "Checking HTML file");

sub check_sub($radix, $high1, $low1, $result1) {

  my $high  =  Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $high1);
  my $low   =  Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $low1);
  my $result = $operation->subtraction(high => $high, low => $low);
  is($result->value, $result1, "$high1 - $low1 = $result1 (radix $radix)");
  $result = $operation->subtraction(high => $high, low => $low, type => 'compl');
  is($result->value, $result1, "$high1 - $low1 = $result1 (adding the $radix complement)");
}
