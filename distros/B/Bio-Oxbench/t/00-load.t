#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bio::Oxbench::Util' ) || print "Bail out!
";
}

diag( "Testing Bio::Oxbench::Util $Bio::Oxbench::Util::VERSION, Perl $], $^X" );
