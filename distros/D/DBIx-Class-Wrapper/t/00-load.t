#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::Wrapper' ) || print "Bail out!";
}
