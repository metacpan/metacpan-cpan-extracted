#!perl

use warnings;
use strict;

use Test::More tests => 9;

use Carp::Assert::More;

use Test::Exception;

my $af = qr/Assertion failed!\n/;

MAIN: {
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

    my @object_keys = keys %{$monolith};
    my @person_keys = keys %{$shaq};

    lives_ok( sub { assert_all_keys_in( $monolith, \@object_keys ) }, 'Monolith object has valid keys' );
    lives_ok( sub { assert_all_keys_in( $shaq,     \@person_keys ) }, 'Shaq object has valid keys' );

    throws_ok(
        sub { assert_all_keys_in( $monolith, \@person_keys ) },
        qr/${af}Key "(depth|width)" is not a valid key\./sm,
        'Monolith fails on person keys'
    );


    throws_ok(
        sub { assert_all_keys_in( $monolith, [] ) },
        qr/${af}Key "(depth|width|height)" is not a valid key\./sm,
        'Monolith fails on empty list of keys'
    );


    throws_ok(
        sub { assert_all_keys_in( $monolith, {} ) },
        qr/${af}Argument for array of keys is not an arrayref\./sm,
        'Fails on a non-array list of keys'
    );


    throws_ok(
        sub { assert_all_keys_in( [], \@object_keys ) },
        qr/${af}Argument for hash is not a hashref\./sm,
        'Fails on a non-hashref hash'
    );


    lives_ok( sub { assert_all_keys_in( {}, [] ) }, 'Empty hash and empty keys' );


    # Check that all keys get reported.
    my @expected = (
        qr/Key "depth" is not a valid key/,
        qr/Key "width" is not a valid key/,
    );
    for my $expected ( @expected ) {
        throws_ok(
            sub { assert_all_keys_in( $monolith, \@person_keys ) },
            qr/${af}.*$expected/sm,
            "Message found: $expected"
        );
    }
}


exit 0;
