#!perl -Tw

use warnings;
use strict;

use Test::More tests=>7;

BEGIN { use_ok( 'Carp::Assert::More' ); }

use constant PASS => 1;
use constant FAIL => 2;

my @cases = (
    [ 5,        PASS ],
    [ 0,        FAIL ],
    [ 0.4,      FAIL ],
    [ -10,      PASS ],
    [ "dog",    FAIL ],
    [ "14.",    FAIL ],
);

for my $case ( @cases ) {
    my ($val,$status) = @$case;

    my $desc = "Checking \"$val\"";
    eval { assert_nonzero_integer( $val ) };

    if ( $status eq FAIL ) {
        like( $@, qr/Assertion.+failed/, $desc );
    } else {
        is( $@, "", $desc );
    }
}

