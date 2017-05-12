use strict;
use warnings;

use Test::More;

use Algorithm::Damm qw/is_valid check_digit/;

my $tests;

plan tests => $tests * 11;

my %good;
BEGIN {
    %good = (
        572  => 4,
        5724 => 0,
        576  => 2,
        5762 => 0,
        );
    $tests += scalar( keys %good );
}
is( check_digit( $_ ), $good{$_}, "check_digit( $_ ) => $good{$_}" )
    for keys %good;

for my $key ( keys %good ) {
    ok( is_valid( $key . $good{$key} ), "is_valid( $key$good{$key} )" );
    for my $bad ( grep { $_ != $good{$key} } 0 .. 9 ) {
        ok( ! is_valid( $key . $bad ), "! is_valid( $key$bad )" );
    }
}
