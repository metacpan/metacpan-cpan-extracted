#!perl

use warnings;
use strict;

use Test::More tests => 11;

use Carp::Assert::More;

use Test::Exception;

use constant PASS => 1;
use constant FAIL => 2;

my @cases = (
    [ undef,    FAIL ],
    [ '',       FAIL ],
    [ [],       FAIL ],
    [ {},       FAIL ],
    [ 5,        PASS ],
    [ 0,        FAIL ],
    [ 0.4,      FAIL ],
    [ -10,      FAIL ],
    [ 'dog',    FAIL ],
    [ '14.',    FAIL ],
    [ '14',     PASS ],
);

for my $case ( @cases ) {
    my ($val,$status) = @{$case};

    my $desc = 'Checking ' . ($val // 'undef');
    if ( $status eq FAIL ) {
        throws_ok( sub { assert_positive_integer( $val ) }, qr/Assertion failed/, $desc );
    }
    else {
        lives_ok( sub { assert_positive_integer( $val ) }, $desc );
    }
}

exit 0;
