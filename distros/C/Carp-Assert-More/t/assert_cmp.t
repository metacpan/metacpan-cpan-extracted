#!perl

use warnings;
use strict;

use Test::More tests => 113;

use Test::Exception;

use Carp::Assert::More;

my $af = qr/Assertion failed!\n/;
my $failed = qr/${af}Failed:/;


NUMERIC_EQ: {
    lives_ok( sub { assert_cmp( 1, '==', 1 ) },     'num == num' );
    lives_ok( sub { assert_cmp( 2, '==', '2' ) },   'num == str' );
    lives_ok( sub { assert_cmp( '3', '==', 3 ) },   'str == num' );
    lives_ok( sub { assert_cmp( '4', '==', '4' ) }, 'str == str' );
    lives_ok( sub { assert_cmp( 5, '==', 5.0 ) },   'int == float' );

    throws_ok( sub { assert_cmp( -1, '==', 1 ) },     qr/$failed -1 == 1/, 'num == num' );
    throws_ok( sub { assert_cmp( -2, '==', '2' ) },   qr/$failed -2 == 2/, 'num == str' );
    throws_ok( sub { assert_cmp( '-3', '==', 3 ) },   qr/$failed -3 == 3/, 'str == num' );
    throws_ok( sub { assert_cmp( '-4', '==', '4' ) }, qr/$failed -4 == 4/, 'str == str' );
    throws_ok( sub { assert_cmp( -5, '==', 5.0 ) },   qr/$failed -5 == 5/, 'int == float' );
}


NUMERIC_NE: {
    lives_ok( sub { assert_cmp( -1, '!=', 1 ) },     'num != num' );
    lives_ok( sub { assert_cmp( -2, '!=', '2' ) },   'num != str' );
    lives_ok( sub { assert_cmp( '-3', '!=', 3 ) },   'str != num' );
    lives_ok( sub { assert_cmp( '-4', '!=', '4' ) }, 'str != str' );
    lives_ok( sub { assert_cmp( -5, '!=', 5.0 ) },   'int != float' );

    throws_ok( sub { assert_cmp( 1, '!=', 1 ) },     qr/$failed 1 != 1/, 'num != num' );
    throws_ok( sub { assert_cmp( 2, '!=', '2' ) },   qr/$failed 2 != 2/, 'num != str' );
    throws_ok( sub { assert_cmp( '3', '!=', 3 ) },   qr/$failed 3 != 3/, 'str != num' );
    throws_ok( sub { assert_cmp( '4', '!=', '4' ) }, qr/$failed 4 != 4/, 'str != str' );
    throws_ok( sub { assert_cmp( 5, '!=', 5.0 ) },   qr/$failed 5 != 5/, 'int != float' );
}


NUMERIC_LT: {
    lives_ok( sub { assert_cmp( 1, '<', 2 ) },     'num < num' );
    lives_ok( sub { assert_cmp( 2, '<', '3' ) },   'num < str' );
    lives_ok( sub { assert_cmp( '3', '<', 4 ) },   'str < num' );
    lives_ok( sub { assert_cmp( '4', '<', '5' ) }, 'str < str' );
    lives_ok( sub { assert_cmp( 5, '<', 6.0 ) },   'int < float' );
    lives_ok( sub { assert_cmp( 6.0, '<', 7 ) },   'float < int' );
    lives_ok( sub { assert_cmp( 7.0, '<', 8.0 ) }, 'float < float' );

    throws_ok( sub { assert_cmp( 1, '<', 1 ) },     qr/$failed 1 < 1/, 'num < num' );
    throws_ok( sub { assert_cmp( 2, '<', '2' ) },   qr/$failed 2 < 2/, 'num < str' );
    throws_ok( sub { assert_cmp( '3', '<', 3 ) },   qr/$failed 3 < 3/, 'str < num' );
    throws_ok( sub { assert_cmp( '4', '<', '4' ) }, qr/$failed 4 < 4/, 'str < str' );
    throws_ok( sub { assert_cmp( 5, '<', 5.0 ) },   qr/$failed 5 < 5/, 'int < float' );
    throws_ok( sub { assert_cmp( 6.0, '<', 6 ) },   qr/$failed 6 < 6/, 'float < int' );
    throws_ok( sub { assert_cmp( 7.0, '<', 7.0 ) }, qr/$failed 7 < 7/, 'float < float' );
}


NUMERIC_LE: {
    lives_ok( sub { assert_cmp( 1, '<=', 2 ) },     'num <= num' );
    lives_ok( sub { assert_cmp( 2, '<=', '3' ) },   'num <= str' );
    lives_ok( sub { assert_cmp( '3', '<=', 4 ) },   'str <= num' );
    lives_ok( sub { assert_cmp( '4', '<=', '5' ) }, 'str <= str' );
    lives_ok( sub { assert_cmp( 5, '<=', 6.0 ) },   'int <= float' );
    lives_ok( sub { assert_cmp( 6.0, '<=', 7 ) },   'float <= int' );
    lives_ok( sub { assert_cmp( 7.0, '<=', 8.0 ) }, 'float <= float' );

    throws_ok( sub { assert_cmp( 1, '<=', 0 ) },     qr/$failed 1 <= 0/, 'num <= num' );
    throws_ok( sub { assert_cmp( 2, '<=', '1' ) },   qr/$failed 2 <= 1/, 'num <= str' );
    throws_ok( sub { assert_cmp( '3', '<=', 2 ) },   qr/$failed 3 <= 2/, 'str <= num' );
    throws_ok( sub { assert_cmp( '4', '<=', '3' ) }, qr/$failed 4 <= 3/, 'str <= str' );
    throws_ok( sub { assert_cmp( 5, '<=', 4.0 ) },   qr/$failed 5 <= 4/, 'int <= float' );
    throws_ok( sub { assert_cmp( 6.0, '<=', 5 ) },   qr/$failed 6 <= 5/, 'float <= int' );
    throws_ok( sub { assert_cmp( 7.0, '<=', 6.0 ) }, qr/$failed 7 <= 6/, 'float <= float' );
}


NUMERIC_GT: {
    lives_ok( sub { assert_cmp( 1, '>', 0 ) },     'num > num' );
    lives_ok( sub { assert_cmp( 2, '>', '1' ) },   'num > str' );
    lives_ok( sub { assert_cmp( '3', '>', 2 ) },   'str > num' );
    lives_ok( sub { assert_cmp( '4', '>', '3' ) }, 'str > str' );
    lives_ok( sub { assert_cmp( 5, '>', 4.0 ) },   'int > float' );
    lives_ok( sub { assert_cmp( 6.0, '>', 5 ) },   'float > int' );
    lives_ok( sub { assert_cmp( 7.0, '>', 6.0 ) }, 'float > float' );

    throws_ok( sub { assert_cmp( 1, '>', 1 ) },     qr/$failed 1 > 1/, 'num > num' );
    throws_ok( sub { assert_cmp( 2, '>', '2' ) },   qr/$failed 2 > 2/, 'num > str' );
    throws_ok( sub { assert_cmp( '3', '>', 3 ) },   qr/$failed 3 > 3/, 'str > num' );
    throws_ok( sub { assert_cmp( '4', '>', '4' ) }, qr/$failed 4 > 4/, 'str > str' );
    throws_ok( sub { assert_cmp( 5, '>', 5.0 ) },   qr/$failed 5 > 5/, 'int > float' );
    throws_ok( sub { assert_cmp( 6.0, '>', 6 ) },   qr/$failed 6 > 6/, 'float > int' );
    throws_ok( sub { assert_cmp( 7.0, '>', 7.0 ) }, qr/$failed 7 > 7/, 'float > float' );
}



NUMERIC_GE: {
    lives_ok( sub { assert_cmp( 1, '>=', 1 ) },     'num >= num' );
    lives_ok( sub { assert_cmp( 2, '>=', '2' ) },   'num >= str' );
    lives_ok( sub { assert_cmp( '3', '>=', 3 ) },   'str >= num' );
    lives_ok( sub { assert_cmp( '4', '>=', '4' ) }, 'str >= str' );
    lives_ok( sub { assert_cmp( 5, '>=', 5.0 ) },   'int >= float' );
    lives_ok( sub { assert_cmp( 6.0, '>=', 6 ) },   'float >= int' );
    lives_ok( sub { assert_cmp( 7.0, '>=', 7.0 ) }, 'float >= float' );

    throws_ok( sub { assert_cmp( 0, '>=', 1 ) },     qr/$failed 0 >= 1/, 'num >= num' );
    throws_ok( sub { assert_cmp( 1, '>=', '2' ) },   qr/$failed 1 >= 2/, 'num >= str' );
    throws_ok( sub { assert_cmp( '2', '>=', 3 ) },   qr/$failed 2 >= 3/, 'str >= num' );
    throws_ok( sub { assert_cmp( '3', '>=', '4' ) }, qr/$failed 3 >= 4/, 'str >= str' );
    throws_ok( sub { assert_cmp( 4, '>=', 5.0 ) },   qr/$failed 4 >= 5/, 'int >= float' );
    throws_ok( sub { assert_cmp( 5.0, '>=', 6 ) },   qr/$failed 5 >= 6/, 'float >= int' );
    throws_ok( sub { assert_cmp( 6.0, '>=', 7.0 ) }, qr/$failed 6 >= 7/, 'float >= float' );
}


BAD_NUMBERS: {
    my @operators = qw( == != > >= < <= );

    for my $op ( @operators ) {
        throws_ok( sub { assert_cmp( 12, $op, undef ) },   qr/$failed 12 $op undef/, "num $op undef" );
        throws_ok( sub { assert_cmp( undef, $op, 14 ) },   qr/$failed undef $op 14/, "undef $op num" );
        throws_ok( sub { assert_cmp( undef, $op, undef) }, qr/$failed undef $op undef/, "undef $op undef" );
    }
}


STRINGS: {
    lives_ok( sub { assert_cmp( 'a', 'lt', 'b' ) }, 'lt' );
    lives_ok( sub { assert_cmp( 'a', 'le', 'a' ) }, 'le' );
    lives_ok( sub { assert_cmp( 'b', 'gt', 'a' ) }, 'gt' );
    lives_ok( sub { assert_cmp( 'a', 'ge', 'a' ) }, 'ge' );

    throws_ok( sub { assert_cmp( 'a', 'lt', 'a' ) }, qr/$failed a lt a/ );
    throws_ok( sub { assert_cmp( 'b', 'le', 'a' ) }, qr/$failed b le a/ );
    throws_ok( sub { assert_cmp( 'a', 'gt', 'a' ) }, qr/$failed a gt a/ );
    throws_ok( sub { assert_cmp( 'a', 'ge', 'b' ) }, qr/$failed a ge b/ );
}



BAD_OPERATOR: {
    for my $op ( qw( xx eq ne lte gte LT LE GT GE ), undef ) {
        my $dispop = $op ? qq{"$op"} : '<undef>';
        throws_ok( sub { assert_cmp( 3, $op, 3 ) }, qr/${af}Invalid operator $dispop/ );
    }
}


BAD_VALUES: {
    throws_ok( sub { assert_cmp( 9, '>', undef ) }, qr/$failed 9 > undef/ );
}


exit 0;
