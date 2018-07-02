#!perl

use strict;
use warnings;
use Test::More;

use Assert::Refute;

my $smart = contract {
    package T;
    use Assert::Refute::T::Scalar;
    maybe_is( shift, shift );
};

contract_is $smart->apply( undef, undef ), "t1d", "undef match undef";
contract_is $smart->apply( 1, undef ), "tNd", "scalar v undef = no go";

contract_is $smart->apply( undef, 42 ), "t1d", "undef match anything";
contract_is $smart->apply( 42, 42 ), "t1d", "number match number";
contract_is $smart->apply( "foo", "foo" ), "t1d", "string match string";
contract_is $smart->apply( "foo", "bar" ), "tNd", "string != string";

contract_is $smart->apply( undef, qr/a^/ ), "t1d", "Impossible rex ok for undef";
contract_is $smart->apply( "foo", qr/foo/ ), "t1d", "Rex match";
contract_is $smart->apply( "foo", qr/bar/ ), "tNd", "Rex no match";

# now the hard part

contract_is $smart->apply( "foo", sub { $_[0]->like( $_, qr/foo/) }),
    "t1d", "match sub underscore";
contract_is $smart->apply( "foo", sub { $_[0]->like( $_, qr/bar/) }),
    "tNd", "no match sub underscore";
contract_is $smart->apply( "foo", sub { $_[0]->like( $_[1], qr/foo/) }),
    "t1d", "match sub arg";
contract_is $smart->apply( "foo", sub { $_[0]->like( $_[1], qr/bar/) }),
    "tNd", "no match sub arg";

contract_is $smart->apply( "foo", {} ), "tE", "Dies if wrong condition";

done_testing;
