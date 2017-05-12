#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Amazon::SQS::Producer', 'use Amazon::SQS::Producer' ) || print "Bail out!\n";
}

BEGIN {
    use_ok( 'Amazon::SQS::Consumer', 'use Amazon::SQS::Consumer' ) || print "Bail out!\n";
}