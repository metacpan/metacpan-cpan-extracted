#!perl -Tw

use warnings;
use strict;

use Test::More tests => 6;

BEGIN { use_ok( 'Carp::Assert::More' ); }

local $@;
$@ = '';

# 3 is nonref
eval {
    assert_nonref( 3 );
};
is( $@, '' );

# 0 is nonref
eval {
    assert_nonref( 0 );
};
is( $@, '' );

# '' is nonref
eval {
    assert_nonref( 0 );
};
is( $@, '' );

# undef is not a reference, but it also fails by my rules
eval {
    assert_nonref( undef );
};
like( $@, qr/Assertion.*failed/ );

# A reference is not a non-reference
eval {
    my $scalar = "Blah blah";
    my $ref = \$scalar;
    assert_nonref( $ref );
};
like( $@, qr/Assertion.*failed/ );
