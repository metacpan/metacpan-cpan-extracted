#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Bio::KEGGI' ) || print "Bail out!
";
    use_ok( 'Bio::KEGG' ) || print "Bail out!
";
}

diag( "Testing Bio::KEGGI $Bio::KEGGI::VERSION, Perl $], $^X" );
