#!perl -Tw

use warnings;
use strict;

use Test::More tests => 7;

use Carp::Assert::More;

use Test::Exception;

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

lives_ok( sub { assert_all_keys_in( $monolith, \@object_keys ) }, 'Monolith object has valid keys' );
lives_ok( sub { assert_all_keys_in( $shaq,     \@person_keys ) }, 'Shaq object has valid keys' );

throws_ok(
    sub { assert_all_keys_in( $monolith, \@person_keys ) },
    qr/Assertion.*failed!.+Key "(depth|width)" is not a valid key\./sm,
    'Monolith fails on person keys'
);


throws_ok(
    sub { assert_all_keys_in( $monolith, [] ) },
    qr/Assertion.*failed!.+Key "(depth|width|height)" is not a valid key\./sm,
    'Monolith fails on empty list of keys'
);


throws_ok(
    sub { assert_all_keys_in( $monolith, {} ) },
    qr/Assertion.*failed!.+Argument for array of keys is not an arrayref\./sm,
    'Fails on a non-array list of keys'
);


throws_ok(
    sub { assert_all_keys_in( [], \@object_keys ) },
    qr/Assertion.*failed!.+Argument for hash is not a hashref\./sm,
    'Fails on a non-hashref hash'
);


lives_ok( sub { assert_all_keys_in( {}, [] ) }, 'Empty hash and empty keys' );

exit 0;
