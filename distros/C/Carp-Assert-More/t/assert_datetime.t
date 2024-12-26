#!perl

use warnings;
use strict;

use Test::More;

use Carp::Assert::More;

my $module = 'DateTime';

if ( !eval "use $module; 1;" ) { ## no critic (ProhibitStringyEval)
    plan skip_all => "$module required for testing assert_datetime()";
}

plan tests => 11;

my %bad = (
    'hashref'     => {},
    'undef'       => undef,
    'integer'     => 17,
    'coderef'     => \&like,
    'date string' => '1941-12-07',
);

while ( my ($desc,$val) = each %bad ) {
    my $rc = eval { assert_datetime( $val ); 1 };

    is( $rc, undef, "assertion did not pass: $desc" );
    like( $@, qr/Assertion.+failed/, "Error message matches: $desc" );
}


my $dt = DateTime->now;
assert_datetime( $dt );
pass( 'Got past a valid assertion' );

exit 0;
