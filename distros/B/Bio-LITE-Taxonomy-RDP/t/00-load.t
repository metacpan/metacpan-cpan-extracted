#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bio::LITE::Taxonomy::RDP' ) || print "Bail out!
";
}

diag( "Testing Bio::LITE::Taxonomy::RDP $Bio::LITE::Taxonomy::RDP::VERSION, Perl $], $^X" );
