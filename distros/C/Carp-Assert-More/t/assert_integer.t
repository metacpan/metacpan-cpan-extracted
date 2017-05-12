#!perl -Tw

use warnings;
use strict;

use Test::More tests => 6;

use Carp::Assert::More;

use Test::Exception;

use constant PASS => 1;
use constant FAIL => 2;

my @cases = (
    [ 5,        PASS ],
    [ 0,        PASS ],
    [ 0.4,      FAIL ],
    [ -10,      PASS ],
    [ 'dog',    FAIL ],
    [ '14.',    FAIL ],
);

for my $case ( @cases ) {
    my ($val,$status) = @$case;

    my $desc = "Checking \"$val\"";
    eval { assert_integer( $val ) };

    if ( $status eq FAIL ) {
        throws_ok( sub { assert_integer( $val ) }, qr/Assertion.+failed/, $desc );
    }
    else {
        lives_ok( sub { assert_integer( $val ) }, $desc );
    }
}
