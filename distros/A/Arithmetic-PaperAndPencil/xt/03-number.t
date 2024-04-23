#!perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the Number class
#
use 5.38.0;
use utf8;
use strict;
use warnings;
use Test::More;
use feature qw/class/;
use open ':encoding(UTF-8)';
use Arithmetic::PaperAndPencil::Number qw/max_unit adjust_sub/;

my @test_add =  (
         [ qw<10    6        9       15> ]
       , [ qw<13    6        9       12> ]
       , [ qw<30  004      007        B> ]
       , [ qw<16    4   2FFFFE   300002> ]
       , [ qw<16    4   FFFFFE  1000002> ]
       , [ qw<16  124        E      132> ]
       );

my @test_mult =  (
         [ qw<10    6    9  54> ]
       , [ qw<13    6    9  42> ] # See "The Restaurant at the end of the Universe", chapter 33, by Douglas Adams
       , [ qw<30  004  007  S>  ]
       );

my @test_sub = (
         [ qw<10 1 54 61 7> ]
       , [ qw<10 8 54 58 4> ]
       , [ qw<16 1 54 61 D> ]
       , [ qw<16 8 54 58 4> ]
       );

my @test_cmp = (
         [ qw<10 2 12    88> ]
       , [ qw<10 5 12 99988> ]
       , [ qw<16 2 12    EE> ]
       , [ qw<16 5 12 FFFEE> ]
       , [ qw<10 15 8867700 999999991132300> ]
       , [ qw<10 15 999999991132300 8867700> ]
       );

my @test_div = (
         [ qw<10 18 1 18> ]
       , [ qw<10 18 2  9> ]
       , [ qw<16 C0 A 13> ]
       , [ qw<10 35 8  4> ]
       , [ qw<10 24 2 12> ]
       , [ qw<10 20 2 10> ]
       );
my @test_odd = (
         [ qw<10    1 1> ]
       , [ qw<10    2 0> ]
       , [ qw<10  152 0> ]
       , [ qw<10  243 1> ]
       , [ qw< 2 1011 1> ]
       , [ qw< 2 1010 0> ]
       , [ qw<11 1010 0> ]
       , [ qw<11 1510 1> ]
       );

#plan 50 + @test_add + @test_mult + 2 × @test_sub + @test_cmp + @test_div + @test_odd;
plan(tests => 49 + @test_add + @test_mult + 2 * @test_sub + @test_cmp + @test_div + @test_odd);

# Check with the default radix
my $x = Arithmetic::PaperAndPencil::Number->new(value => '6');
my $y = Arithmetic::PaperAndPencil::Number->new(value => '9');
my $z = max_unit(10);
is( $z->value, "9", "highest single-digit is 9");

$z  = $x + $y;
is( $z->value, "15", "6 plus 9 is 15");
$z = $y - $x;
is( $z->value, "3", "9 minus 6 is 3");
$z = $x - $x;
is( $z->value, "0", "6 minus 6 is 0");
$z = $x * $y;
is( $z->value, "54", "6 times 9 is 54");
#is( $z.gist , "54", "6 times 9 is 54 (using gist)");

is( $x->carry->value, "0", "carry of single-digit '6' is '0'");
is( $x->unit ->value, "6", "unit of single-digit '6' is unaltered '6'");
is( $z->carry->value, "5", "carry of '54' is '5'");
is( $z->unit ->value, "4", "unit of '54' is '4'");
is( $z->carry(2)->value,  "0", "2-digit extended carry of '54' is '0'");
is( $z->unit( 2)->value, "54", "2-digit extended unit of '54' is '54'");
is( $z->carry(3)->value,  "0", "3-digit extended carry of '54' is '0'");
is( $z->unit( 3)->value, "54", "3-digit extended unit of '54' is '54'");

is( $x->square_root->value, "2", "square root of 6 is 2");
is( $y->square_root->value, "3", "square root of 9 is 3");
is( $z->square_root->value, "7", "square root of 54 is 7");

is($x <=> $y, -1,  "6 numerically less than 9");
is($x <=> $x,  0,  "6 numerically same as 6");
is($z <=> $x,  1, "54 numerically greater than 6");
is($x cmp $y, -1,  "6 alphabetically less than 9");
is($z cmp $x, -1, "54 alphabetically less than 6");
is($z cmp $z,  0, "54 alphabetically same as 54");

is( 0+($x <  $x), 0,  "6 numerically less than 6? No");
is( 0+($x <  $y), 1,  "6 numerically less than 9? Yes");
is( 0+($x <  $z), 1,  "6 numerically less than 54? Yes");
is( 0+($y <  $x), 0,  "9 numerically less than 6? No");
is( 0+($y <  $y), 0,  "9 numerically less than 9? No");
is( 0+($y <  $z), 1,  "9 numerically less than 54? Yes");
is( 0+($z <  $x), 0, "54 numerically less than 6? No");
is( 0+($z <  $y), 0, "54 numerically less than 9? No");
is( 0+($z <  $z), 0, "54 numerically less than 54? No");
is( 0+($x lt $y), 1,  "6 alphabetically less than 9? Yes");
is( 0+($x lt $z), 0,  "6 alphabetically less than 54? No");
is( 0+($y lt $x), 0,  "9 alphabetically less than 6? No");
is( 0+($y lt $z), 0,  "9 alphabetically less than 54? No");
is( 0+($z lt $x), 1, "54 alphabetically less than 6? Yes");
is( 0+($z lt $y), 1, "54 alphabetically less than 9? Yes");
is( 0+($x <= $x), 1,  "6 numerically less than or equal to 6? Yes");
is( 0+($x <= $y), 1,  "6 numerically less than or equal to 9? Yes");
is( 0+($x <= $z), 1,  "6 numerically less than or equal to 54? Yes");
is( 0+($y <= $x), 0,  "9 numerically less than or equal to 6? No");
is( 0+($y <= $y), 1,  "9 numerically less than or equal to 9? Yes");
is( 0+($y <= $z), 1,  "9 numerically less than or equal to 54? Yes");
is( 0+($z <= $x), 0, "54 numerically less than or equal to 6? No");
is( 0+($z <= $y), 0, "54 numerically less than or equal to 9? No");
is( 0+($z <= $z), 1, "54 numerically less than or equal to 54? Yes");

$z = Arithmetic::PaperAndPencil::Number->new(value => '000');
is($z       ->value, '0', "'000' is the same as '0'");
is($z->carry->value, "0", "carry of '000' is '0'");
is($z->unit ->value, "0", "unit of '000' is '0'");

# Check with explicit radix
for (@test_add) {
  check_add(@$_);
}

for (@test_mult) {
  check_mult(@$_);
}

for (@test_sub) {
  check_sub(@$_);
}

for (@test_cmp) {
  check_cmp(@$_);
}

for (@test_div) {
  check_div(@$_);
}

for (@test_odd) {
  check_odd(@$_);
}
done_testing;

sub check_add($radix, $x, $y, $sum) {
  my $xx = Arithmetic::PaperAndPencil::Number->new(value => $x, radix => $radix);
  my $yy = Arithmetic::PaperAndPencil::Number->new(value => $y, radix => $radix);
  my $zz = $xx + $yy;
  is($zz->value, $sum, "$x plus $y is $sum (radix $radix)");
}

sub check_mult($radix, $x, $y, $pdt) {
  my $xx = Arithmetic::PaperAndPencil::Number->new(value => $x, radix => $radix);
  my $yy = Arithmetic::PaperAndPencil::Number->new(value => $y, radix => $radix);
  my $zz = $xx * $yy;
  is( $zz->value, $pdt, "$x times $y is $pdt (radix $radix)");
}

sub check_sub($radix, $x, $y, $x1, $s) {
  my $xx = Arithmetic::PaperAndPencil::Number->new(value => $x, radix => $radix);
  my $yy = Arithmetic::PaperAndPencil::Number->new(value => $y, radix => $radix);
  my $x_adj;
  my $rem;
  ($x_adj, $rem) = adjust_sub($xx, $yy);
  is( $x_adj->value, $x1, "$x - $y : adjusted to $x1 - $y (radix $radix)");
  is( $rem->value,   $s , "$x1 - $y = $s (radix $radix)");
}

sub check_cmp($radix, $len, $orig, $dest) {
  my $x =  Arithmetic::PaperAndPencil::Number->new(value => $orig, radix => $radix);
  my $y  = $x->complement($len);
  is( $y->value, $dest, "$radix-complement of @{[$x->value]} is $dest");

}

sub check_div($radix, $dividend, $divisor, $quotient) {
  my $x = Arithmetic::PaperAndPencil::Number->new(value => $dividend, radix => $radix);
  my $y = Arithmetic::PaperAndPencil::Number->new(value => $divisor , radix => $radix);
  my $z = $x / $y;
  is($z->value, $quotient, "$dividend / $divisor = $quotient (radix $radix)");
}

sub check_odd($radix, $value, $result) {
  my $x = Arithmetic::PaperAndPencil::Number->new(value => $value, radix => $radix);
  my $comment = "even";
  if ($result) {
    $comment = "odd";
  }
  is( 0+ $x->is_odd, $result, "$value (radix $radix) is $comment");
}
