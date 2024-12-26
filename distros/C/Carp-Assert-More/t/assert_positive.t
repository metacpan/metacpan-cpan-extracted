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
    [ 0,        FAIL ],
    [ 0.4,      PASS ],
    [ -10,      FAIL ],
    [ 'dog',    FAIL ],
    [ '14.',    PASS ],
);

for my $case ( @cases ) {
    my ($val,$status) = @{$case};

    my $desc = 'Checking ' . ($val // 'undef');
    eval { assert_positive( $val ) };

    if ( $status eq FAIL ) {
        like( $@, qr/Assertion.+failed/, $desc );
    }
    else {
        is( $@, '', $desc );
    }
}

exit 0;
