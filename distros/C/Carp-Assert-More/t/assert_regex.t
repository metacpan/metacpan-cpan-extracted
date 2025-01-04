#!perl

use warnings;
use strict;

use Test::More tests => 15;

use Carp::Assert::More;

use Test::Exception;

my @good = (
    qr//,
    qr/Foo/,
    qr/slash i/i,
    qr/slash m/m,
    qr/slash s/s,
    qr/slash x/x,
);

my @bad = (
    undef,
    14,
    '',
    '//',
    '/Foo/',
    [],
    {},
    \99,
    \*STDIN,
);

for my $good ( @good ) {
    lives_ok(
        sub { assert_regex( $good, "$good is good" ) },
        "$good passes assertion"
    );
}

for my $bad ( @bad ) {
    my $disp = $bad;
    $disp = '<undef>' unless defined $disp;
    throws_ok(
        sub { assert_regex( $bad, "$disp is bad" ) },
        qr/\Q$disp is bad/,
        "$disp fails assertion"
    );
}


exit 0;
