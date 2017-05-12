#!perl -T

use Test::More tests => 6;

BEGIN {
    use_ok( 'Business::Payment' );
    use_ok( 'Business::Payment::Charge' );
    use_ok( 'Business::Payment::Result' );
    use_ok( 'Business::Payment::Processor::Test::True' );
    use_ok( 'Business::Payment::Processor::Test::False' );
    use_ok( 'Business::Payment::Processor::Test::Random' );
}

diag( "Testing Business::Payment $Business::Payment::VERSION, Perl $], $^X" );
