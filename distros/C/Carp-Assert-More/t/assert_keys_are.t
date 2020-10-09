#!perl -Tw

use warnings;
use strict;

use Test::More tests => 1;

use Carp::Assert::More;

use Test::Exception;

subtest assert_keys_are => sub {
    plan tests => 8;

    my $monolith = {
        depth  => 1,
        width  => 4,
        height => 9,
    };
    my $shaq = {
        firstname => 'Shaquille',
        lastname  => 'O\'Neal',
        height    => 85,
    };

    my @object_keys = qw( height width depth );
    my @person_keys = qw( firstname lastname height );

    lives_ok( sub { assert_keys_are( $monolith, \@object_keys ) }, 'Monolith object has valid keys' );
    lives_ok( sub { assert_keys_are( $shaq,     \@person_keys ) }, 'Shaq object has valid keys' );
    lives_ok( sub { assert_keys_are( {}, [] ) }, 'Empty hash + empty keys works fine' );

    throws_ok(
        sub { assert_keys_are( $monolith, \@person_keys ) },
        qr/Assertion.*failed!/,
        'Monolith fails on person keys'
    );

    throws_ok(
        sub { assert_keys_are( $monolith, [@object_keys[0..1]] ) },
        qr/Assertion.*failed/,
        'Hash has too many keys'
    );
    throws_ok(
        sub { assert_keys_are( $monolith, [@object_keys, 'wavelength'] ) },
        qr/Assertion.*failed/,
        'Hash has one key too many'
    );
    throws_ok(
        sub { assert_keys_are( $monolith, [] ) },
        qr/Assertion.*failed/,
        'Empty key list fails for non-empty object'
    );
    throws_ok(
        sub { assert_keys_are( {}, \@object_keys ) },
        qr/Assertion.*failed/,
        'Empty hash fails for non-empty key list'
    );
};

exit 0;
