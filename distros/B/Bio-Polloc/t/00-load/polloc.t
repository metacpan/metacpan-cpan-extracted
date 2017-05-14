#!perl -T

use Test::More tests => 1;

BEGIN {
   use_ok( 'Bio::Polloc::Polloc::Root' ) || print "Bail out!\n";
}

diag( "Testing Polloc $Bio::Polloc::Polloc::Root::VERSION, Perl $], $^X" );
