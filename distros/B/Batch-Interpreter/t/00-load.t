#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Batch::Interpreter' ) || print "Bail out!\n";
    use_ok( 'Batch::Interpreter::TestSupport' ) || print "Bail out!\n";
    use_ok( 'Batch::Interpreter::Locale::de_DE' ) || print "Bail out!\n";
}

diag( "Testing Batch::Interpreter $Batch::Interpreter::VERSION, Perl $], $^X" );
