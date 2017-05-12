#!perl -T
use 5.018;
use warnings FATAL => 'all';
use Test::More tests => 24;

BEGIN {
    use_ok( 'Acme::RJWETMORE::Utils' ) || BAIL_OUT();
}

diag( "Testing Acme::RJWETMORE::Utils $Acme::RJWETMORE::Utils::VERSION, Perl $], $^X" );

ok( defined &sum, 'defined sum' );

## Testing sum()
## Null argument
is( sum(), undef, 'sum() = undef  --- null arg' );

## One argument
is( sum(55), 55, 'sum(55) = 55  --- one arg' );

## positive integers
is( sum(1,2,3), 6, 'sum(1,2,3) = 6  --- pos ints' );

## postitive and negative integers
is( sum(1,-2,3,-4), -2, 
                   'sum(1,-2,3,-4) = -2 --- pos and neg ints' );

## positive integers with underscores
is( sum(1_300_438, 1_000_001),  2300439, 
                   'sum(1_300_438, 1_000_001) = 2300439 --- ints w/ underscores' );

## floating points
is( sum(1.345,-2.44), -1.095, 
                   'sum(1.345, -2.44) = -1.095 --- floating points' );

## positive hexadecimal
is( sum(0xA, 0xF), 25, 
                   'sum(0xA, 0xF) = 25 --- pos hex' );

## positive octal
is( sum(05, 013), 16, 
                   'sum(05, 013) = 16 --- pos oct' );

## positive binary 
is( sum(0b01, 0b11), 4, 
                   'sum(0b11, 0b001) = 4 --- pos bin' );

## positive/negative hexadecimal
is( sum(-0xA, 0xF), 5, 'sum(-0xA, 0xF) = 5  --- pos/neg hex' );

## positive/negative octal
is( sum(05, -013), -6, 'sum(05, -013) = -6 --- pos/neg oct' );

## positive/negative binary 
is( sum(0b01, -0b11), -2, 'sum(0b11, -0b001) = -2 --- pos/neg bin' );

## base 10, octal, hex, binary
is( sum(0b11, 0xA, 010, 20), 41, 
                   'sum(0b11, 0xA, 010, 20) = 41 --- mixed bases' );
#                          3,  10,   8, 20

## multiplicative argument
is( sum(4, 2*3 ), 10, 'sum(4, 2*3) = 10 --- multiplicative arg' );

## Large integers
is( sum(4e45, 7e45 ), 1.1e46, 'sum(4e45, 7e45) = 1.1e46 --- large ints' );

## Large floating points
ok(    sum(4.107e45, 4.982e45 ) > 9.088888e45
    && sum(4.107e45, 4.982e45 ) < 9.089001e45,
      'sum(4.107e45, 4.982e45) = 9.089e45 --- large floating points' );

## divisor argument and floating point
ok(    sum(4, 8/3 ) > 6.66666666 
    && sum(4, 8/3 ) < 6.66666668,
      'sum(4, 8/3) = 6.666666...  --- divisor argument; repeating fraction' );

## num1..num2 argument
is( sum(1..10 ), 55, 'sum(1..10) = 55 --- num1..num2 arg' );

## more than one array argument
my @arr1 = (1,2,3);
my @arr2 = (4,5,6);
is( sum(@arr1, @arr2), 21, 'sum(@arr1, @arr2) = 21 --- multiple array args' );

## non-numeric args
is ( sum('a','b'), 0, "sum('a','b') = 0 --- non-numeric arguments");

## mixed numeric and non-numeric args
is ( sum(1,2,'a','b'), 3, "sum(1,2,'a','b') = 3 --- numeric and non-numeric arguments");

## divide by 0 argument
{
eval { sum( 4, 2/0 ) };
ok( $@, "Including divide by 0 term results in: \$@ = $@" );
}

