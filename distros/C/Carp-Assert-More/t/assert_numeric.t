#!perl

use warnings;
use strict;

use Test::More tests => 21;

use Carp::Assert::More;

use Test::Exception;

my @good = (
    1,
    2112,
    '2112',
    3.1415926,
    -5150,
    '-0.12',
    '0.12',
    2.112E+03,
    2.112E3,
    2.112e3,
    2.112e0,
    2.112e-1,
);
my @bad = (
    undef,
    'zero',
    '',
    [],
    {},
    \99,
    \*STDIN,
    '3-5',
    3.5.4
);

for my $good ( @good ) {
    lives_ok(
        sub { assert_numeric( $good, "$good is good" ) },
        "$good passes assertion"
    );
}

for my $bad ( @bad ) {
    my $disp = $bad;
    $disp = '<undef>' unless defined $disp;
    throws_ok(
        sub { assert_numeric( $bad, "$disp is bad" ) },
        qr/\Q$disp is bad/,
        "$disp fails assertion"
    );
}


exit 0;
