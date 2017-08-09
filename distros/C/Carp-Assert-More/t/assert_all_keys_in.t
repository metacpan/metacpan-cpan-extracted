#!perl -Tw

use warnings;
use strict;

use Test::More tests => 3;

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
    qr/Assertion.*failed!/,
    'Monolith fails on person keys'
);

done_testing();
exit 0;
