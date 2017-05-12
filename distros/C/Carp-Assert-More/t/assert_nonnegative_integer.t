#!perl -Tw

use warnings;
use strict;

use Test::More tests=>7;

BEGIN { use_ok( 'Carp::Assert::More' ); }

use constant PASS => 1;
use constant FAIL => 2;

my @cases = (
    [ 5,        PASS ],
    [ 0,        PASS ],
    [ 0.4,      FAIL ],
    [ -10,      FAIL ],
    [ "dog",    FAIL ],
    [ "14.",    FAIL ],
);

for my $case ( @cases ) {
    my ($val,$status) = @$case;

    my $desc = "Checking \"$val\"";
    eval { assert_nonnegative_integer( $val ) };

    if ( $status eq FAIL ) {
        like( $@, qr/Assertion.+failed/, $desc );
    } else {
        is( $@, "", $desc );
    }
}

