# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the checks at build time
#
use 5.38.0;
use utf8;
use strict;
use warnings;
use feature qw/class/;
use open ':encoding(UTF-8)';
use Test::More;
use Arithmetic::PaperAndPencil::Number qw/max_unit adjust_sub/;

BEGIN {
  eval "use Test::Exception;";
  if ($@) {
    plan skip_all => "Test::Exception needed";
    exit;
  }
}

plan(tests => 44);

dies_ok  { max_unit( 1) } "radix is 2 or more";
lives_ok { max_unit( 2) } "radix is 2 or more";
lives_ok { max_unit(36) } "radix is 36 or less";
dies_ok  { max_unit(37) } "radix is 36 or less";

dies_ok  { Arithmetic::PaperAndPencil::Number->new(value => "101", radix =>  1) } "radix is 2 or more";
lives_ok { Arithmetic::PaperAndPencil::Number->new(value => "101", radix =>  2) } "radix is 2 or more";
lives_ok { Arithmetic::PaperAndPencil::Number->new(value => "XYZ", radix => 36) } "radix is 36 or less";
dies_ok  { Arithmetic::PaperAndPencil::Number->new(value => "XYZ", radix => 37) } "radix is 36 or less";
dies_ok  { Arithmetic::PaperAndPencil::Number->new(value => "210", radix =>  2) } "wrong digit in radix 2";
dies_ok  { Arithmetic::PaperAndPencil::Number->new(value => "XYZ", radix => 35) } "wrong digit in radix 35";

my $x = Arithmetic::PaperAndPencil::Number->new(value => "123");
my $y = Arithmetic::PaperAndPencil::Number->new(value => "123", radix => 16);
my $z = Arithmetic::PaperAndPencil::Number->new(value => "4"  , radix => 16);
my $t = Arithmetic::PaperAndPencil::Number->new(value => "4F" , radix => 16);
my $zero =  Arithmetic::PaperAndPencil::Number->new(value => "0" , radix => 16);

dies_ok  { $x + $y } "cannot add numbers with different bases";
dies_ok  { $x * $y } "cannot multiply number with different bases";
dies_ok  { $x + $x } "cannot add multi-digit numbers";
dies_ok  { $y + $y } "cannot add multi-digit numbers";
lives_ok { $y + $z } "can add a multi-digit number to a single-digit number";
dies_ok  { $y * $y } "cannot multiply a multi-digit number with a single-digit number";
dies_ok  { $x    - $y } "plain sub: cannot subtract number with different bases";
dies_ok  { $y    - $y } "plain sub: cannot subtract a single-digit number from a multi-digit number";
dies_ok  { $zero - $z } "plain sub: cannot subtract a high number from a low number";
dies_ok  { adjust_sub($x, $y) } "adjust_sub: cannot subtract numbers with different bases";
dies_ok  { adjust_sub($y, $z) } "adjust_sub: the high number must be a single-digit number";
dies_ok  { adjust_sub($z, $y) } "adjust_sub: the low number must be a single-digit number or a 2-digit number";
lives_ok { adjust_sub($z, $z) } "adjust_sub: the low number must be a single-digit number or a 2-digit number";
lives_ok { adjust_sub($z, $t) } "adjust_sub: the low number must be a single-digit number or a 2-digit number";
dies_ok  { $x / $y    } "cannot divide numbers with different bases";
dies_ok  { $y / $z    } "cannot divide a 3-digit number";
lives_ok { $t / $z    } "can divide a 2-digit number";
dies_ok  { $z / $t    } "cannot divide by a 2-digit number";
dies_ok  { $z / $zero } "cannot divide by zero";
lives_ok { $z->square_root } "square root of a single digit number is allowed";
lives_ok { $t->square_root } "square root of a double digit number is allowed";
dies_ok  { $y->square_root } "square root of a 3-digit number is not allowed";
dies_ok  { $y->complement(2) } "Cannot compute the 2-digit complement of a 3-digit number";
lives_ok { $y->complement(3) } "Can compute the 3-digit complement of a 3-digit number";

dies_ok  { $x cmp $y } "cannot compare numbers with different bases";
dies_ok  { $x lt  $y } "cannot compare numbers with different bases";
dies_ok  { $x <=> $y } "cannot compare numbers with different bases";
dies_ok  { $x <   $y } "cannot compare numbers with different bases";
dies_ok  { $x <=  $y } "cannot compare numbers with different bases";
lives_ok { $z cmp $y } "can compare numbers with same radix";
lives_ok { $z lt  $y } "can compare numbers with same radix";
lives_ok { $z <=> $y } "can compare numbers with same radix";
lives_ok { $z <   $y } "can compare numbers with same radix";
lives_ok { $z <=  $y } "can compare numbers with same radix";
