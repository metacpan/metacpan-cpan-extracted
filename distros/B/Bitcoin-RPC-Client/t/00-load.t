#!perl -T
use 5.006;
use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bitcoin::RPC::Client' ) || print "Bail out!\n";
}

diag( "Testing Bitcoin::RPC::Client $Bitcoin::RPC::Client::VERSION, Perl $], $^X" );
