#!/usr/bin/perl

BEGIN{push @INC, "./../blib/lib/"}

use Biblio::ILL::ISO::Shipped;

#
# transaction-id
#
my $tid = new Biblio::ILL::ISO::TransactionId("PLS","001","", 
					      new Biblio::ILL::ISO::SystemId("MWPL"));

#
# service-date-time
#
my $sdt = new Biblio::ILL::ISO::ServiceDateTime( new Biblio::ILL::ISO::DateTime("20030623","114400"),
						 new Biblio::ILL::ISO::DateTime("20030623","114015")
						 );
#
# requester-id
#
my $reqid = new Biblio::ILL::ISO::SystemId();
$reqid->set_person_name("David A. Christensen");

#
# responder-id
#
my $resid = new Biblio::ILL::ISO::SystemId("MWPL");

#
# responder-address
#
my $rad = new Biblio::ILL::ISO::SystemAddress("SMTP","DChristensen\@westman.wave.ca");

#
# intermediary-id
#
my $iid = new Biblio::ILL::ISO::SystemId();
$iid->set_institution_name("The Great Library of Alexandria");

#
# supplier-id
#
my $sid = new Biblio::ILL::ISO::SystemId("MWPL");

#
# client-id
#
my $cid = new Biblio::ILL::ISO::ClientId("David Christensen","Most excellent","007");

#
# transaction-type
#
my $tt = new Biblio::ILL::ISO::TransactionType("simple");

#
# shipped-service-type
#
my $sst = new Biblio::ILL::ISO::ShippedServiceType("loan");

#
# responder-optional-messages
#
my $rom = new Biblio::ILL::ISO::ResponderOptionalMessageType(1,1,"desires","requires");

#
# supply-details
#
my $sd = new Biblio::ILL::ISO::SupplyDetails("20030813",
					     "20030920",
					     123,
					     "45.67",
					     new Biblio::ILL::ISO::ShippedConditions("no-reproduction"),
					     new Biblio::ILL::ISO::ShippedVia( new Biblio::ILL::ISO::TransportationMode("Canada Post") ),
					     new Biblio::ILL::ISO::Amount("50.00"),
					     "50.00",
					     new Biblio::ILL::ISO::UnitsPerMediumType( new Biblio::ILL::ISO::SupplyMediumType("audio-recording"), 3)
					     );


#
# return-to-address
#
my $rta = new Biblio::ILL::ISO::PostalAddress("Manitoba Public Library Services",
					      "",
					      "Unit 200",
					      "1525 First Street South",
					      "",
					      "Brandon",
					      "MB",
					      "CANADA",
					      "R7A 7A1"
					      );


#
# responder-note
#
my $rn = new Biblio::ILL::ISO::ILLString("This is a responder note.");


#-------------------------------------------------------------------------------------------

my $msg = new Biblio::ILL::ISO::Shipped();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );
$msg->set_transaction_type( $tt );
$msg->set_shipped_service_type( $sst );
$msg->set_supply_details( $sd );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_responder_address( $rad );
$msg->set_intermediary_id( $iid );
$msg->set_supplier_id( $sid );
$msg->set_client_id( $cid );
$msg->set_return_to_address( $rta );
$msg->set_responder_note( $rn );

#
#print "\n-as_pretty_string------------------------------------\n";
#print $msg->as_pretty_string();
#print "\n-----------------------------------------------------\n";
#
#print "\n-debug(ans->as_asn())--------------------------------\n";
#my $href = $msg->as_asn();
#print $msg->debug($href);
#print "\n-----------------------------------------------------\n";
#
#$msg->encode();
#

#print "\n-write-----------------------------------------------\n";
$msg->write("msg_03.shipped.ber");
#print "\n-----------------------------------------------------\n";

#print "---end---\n";

