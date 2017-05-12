#!perl -T

use Test::More tests => 5;

BEGIN {
    use_ok( 'Business::Edifact::Interchange' ) || print "Bail out!  ";
    use_ok( 'Business::Edifact::Message' ) || print "Bail out!  ";
    use_ok( 'Business::Edifact::Message::LineItem' ) || print "Bail out!";
}

my $obj = Business::Edifact::Interchange->new;
isa_ok( $obj, 'Business::Edifact::Interchange');
can_ok( $obj, qw( messages ));

diag( "Testing Business::Edifact::Interchange $Business::Edifact::Interchange::VERSION, Perl $], $^X" );
