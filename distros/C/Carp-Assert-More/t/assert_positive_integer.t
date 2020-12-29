#!perl -Tw

use warnings;
use strict;

use Test::More tests => 7;

use Carp::Assert::More;

use Test::Exception;

use constant PASS => 1;
use constant FAIL => 2;

my @cases = (
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

    my $desc = "Checking \"$val\"";

    if ( $status eq FAIL ) {
        throws_ok( sub { assert_positive_integer( $val ) }, qr/Assertion failed/, $desc );
    }
    else {
        lives_ok( sub { assert_positive_integer( $val ) }, $desc );
    }
}

done_testing();
exit 0;
