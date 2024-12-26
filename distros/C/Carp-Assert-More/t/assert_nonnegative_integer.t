#!perl

use warnings;
use strict;

use Test::More tests => 10;

use Carp::Assert::More;

use constant PASS => 1;
use constant FAIL => 2;

my @cases = (
    [ undef,    FAIL ],
    [ '',       FAIL ],
    [ [],       FAIL ],
    [ {},       FAIL ],
    [ 5,        PASS ],
    [ 0,        PASS ],
    [ 0.4,      FAIL ],
    [ -10,      FAIL ],
    [ "dog",    FAIL ],
    [ "14.",    FAIL ],
);

for my $case ( @cases ) {
    my ($val,$status) = @$case;

    my $desc = 'Checking ' . ($val // 'undef');
    eval { assert_nonnegative_integer( $val ) };

    if ( $status eq FAIL ) {
        like( $@, qr/Assertion.+failed/, $desc );
    }
    else {
        is( $@, '', $desc );
    }
}

exit 0;
