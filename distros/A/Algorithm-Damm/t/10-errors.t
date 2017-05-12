use strict;
use warnings;
no warnings 'uninitialized';

use Test::More;

use Algorithm::Damm qw/is_valid check_digit/;

my $tests;

plan tests => $tests;

my @check_digit_errors;
BEGIN {
    @check_digit_errors = (
        '',
        undef,
        'a',
        '123a',
        );
    $tests += @check_digit_errors;
}
is( check_digit( $_ ), undef, "check_digit( $_ ) => undef" )
     for @check_digit_errors;

my @check_digit_non_errors;
BEGIN {
    @check_digit_non_errors = (
        '0' .. '9'
        );
    $tests += @check_digit_non_errors;
}
isnt( check_digit( $_ ), undef, "check_digit( $_ ) not undef" )
     for @check_digit_non_errors;

my @is_valid_errors;
BEGIN {
    @is_valid_errors = (
        '',
        undef,
        'a',
        'aa',
        '1',
        '123a',
        );
    $tests += @is_valid_errors;
}
is( is_valid( $_ ), undef, "is_valid( $_ ) => undef" )
     for @is_valid_errors;

my @is_valid_non_errors;
BEGIN {
    @is_valid_non_errors = (
        '11',
        '00',
        );
    $tests += @is_valid_non_errors;
}
isnt( is_valid( $_ ), undef, "is_valid( $_ ) not undef" )
     for @is_valid_non_errors;
