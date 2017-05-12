#!perl

use strict;
use warnings;

use Acme::Math::PerfectChristmasTree qw/calc_perfect_christmas_tree/;

BEGIN {
    use Test::Exception;
    use Test::More tests => 4;
}

my %got;
my %expected;

subtest 'perfect christmas tree that is 140cm' => sub {
    %got = calc_perfect_christmas_tree(140);
    ok( $got{'number_of_baubles'} == 29 );
    ok( $got{'star_or_fairy_height'} == 14 );
    ok( sprintf( '%5.7f', $got{'tinsel_length'} ) == 714.7123287 );
    ok( sprintf( '%5.7f', $got{'lights_length'} ) == 439.8229715 );
};

subtest 'perfect christmas tree that is 234.56cm' => sub {
    %got = calc_perfect_christmas_tree(234.56);
    ok( $got{'number_of_baubles'} == 48 );
    ok( sprintf( '%5.7f', $got{'star_or_fairy_height'} ) == 23.4560000 );
    ok( sprintf( '%5.7f', $got{'tinsel_length'} ) == 1197.4494558 );
    ok( sprintf( '%5.7f', $got{'lights_length'} ) == 736.8919728 );
};

throws_ok { calc_perfect_christmas_tree(0) }
    qr/Tree height must be a number greater than zero./,
    'Give zero to function.';

throws_ok { calc_perfect_christmas_tree(-1) }
    qr/Tree height must be a number greater than zero./,
    'Give nagative number to function';

done_testing();
