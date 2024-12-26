#!perl

use warnings;
use strict;

use Test::More tests => 15;

use Carp::Assert::More;

use Test::Exception;

my $af = qr/Assertion failed!\n/;
my $failed = qr/${af}Failed:/;

BASICS: {
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
        qr/$af/,
        'Monolith fails on person keys'
    );

    throws_ok(
        sub { assert_keys_are( $monolith, [@object_keys[0..1]] ) },
        qr/$af/,
        'Hash has too many keys'
    );
    throws_ok(
        sub { assert_keys_are( $monolith, [@object_keys, 'wavelength'] ) },
        qr/$af/,
        'Hash has one key too many'
    );
    throws_ok(
        sub { assert_keys_are( $monolith, [] ) },
        qr/${af}Key "(depth|height|width)" is not a valid key\./sm,
        'Empty key list fails for non-empty object'
    );
    throws_ok(
        sub { assert_keys_are( {}, \@object_keys ) },
        qr/${af}Key "(depth|height|width)" is not in the hash\./sm,
        'Empty hash fails for non-empty key list'
    );

    throws_ok(
        sub { assert_keys_are( $monolith, {} ) },
        qr/${af}Argument for array of keys is not an arrayref\./sm,
        'Fails on a non-array list of keys'
    );

    throws_ok(
        sub { assert_keys_are( [], \@object_keys ) },
        qr/${af}Argument for hash is not a hashref\./sm,
        'Fails on a non-hashref hash'
    );

    my @keys = qw( a b c height );
    my @expected = (
        qr/Key "depth" is not a valid key/,
        qr/Key "width" is not a valid key/,
        qr/Key "a" is not in the hash/,
        qr/Key "b" is not in the hash/,
        qr/Key "c" is not in the hash/,
    );
    for my $expected ( @expected ) {
        throws_ok(
            sub { assert_keys_are( $monolith, \@keys ) },
            qr/${af}.*$expected/sm,
            "Message found: $expected"
        );
    }
}


exit 0;
