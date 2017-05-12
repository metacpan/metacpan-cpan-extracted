#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 8;

BEGIN {
    use_ok( 'Banal::Utils' ) 			|| print "Bail out!\n";
    use_ok( 'Banal::Utils::String' ) 	|| print "Bail out!\n";
    use_ok( 'Banal::Utils::Array' ) 	|| print "Bail out!\n";
    use_ok( 'Banal::Utils::Hash' ) 		|| print "Bail out!\n";
    use_ok( 'Banal::Utils::Data' ) 		|| print "Bail out!\n";
    use_ok( 'Banal::Utils::Class' ) 	|| print "Bail out!\n";
    use_ok( 'Banal::Utils::File' ) 		|| print "Bail out!\n";    
    use_ok( 'Banal::Utils::General' ) 	|| print "Bail out!\n";        
}

diag( "Testing Banal::Utils $Banal::Utils::VERSION, Perl $], $^X" );
