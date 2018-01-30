#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 18;

BEGIN {
    use_ok( 'Business::cXML' ) || print "Bail out!\n";
    use_ok( 'Business::cXML::Object' ) || print "Bail out!\n";
    use_ok( 'Business::cXML::Transmission' ) || print "Bail out!\n";
    use_ok( 'Business::cXML::Utils' ) || print "Bail out!\n";

    use_ok( 'Business::cXML::Address' ) || print "Bail out!\n";
    use_ok( 'Business::cXML::Address::Number' ) || print "Bail out!\n";
    use_ok( 'Business::cXML::Address::Postal' ) || print "Bail out!\n";
    use_ok( 'Business::cXML::Amount' ) || print "Bail out!\n";
    use_ok( 'Business::cXML::Carrier' ) || print "Bail out!\n";
    use_ok( 'Business::cXML::Contact' ) || print "Bail out!\n";
    use_ok( 'Business::cXML::Credential' ) || print "Bail out!\n";
    use_ok( 'Business::cXML::Description' ) || print "Bail out!\n";
    use_ok( 'Business::cXML::ItemIn' ) || print "Bail out!\n";
    use_ok( 'Business::cXML::ShipTo' ) || print "Bail out!\n";
    use_ok( 'Business::cXML::Transport' ) || print "Bail out!\n";

    use_ok( 'Business::cXML::Request::PunchOutSetup' ) || print "Bail out!\n";
    use_ok( 'Business::cXML::Response::PunchOutSetup' ) || print "Bail out!\n";

    use_ok( 'Business::cXML::Message::PunchOutOrder' ) || print "Bail out!\n";
}

diag( "Testing Business::cXML $Business::cXML::VERSION, Perl $], $^X" );
