#!/usr/bin/perl

BEGIN{push @INC, "./../blib/lib/"}

use Biblio::ILL::ISO::Request;

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
# transaction-type
#
my $tt = new Biblio::ILL::ISO::TransactionType("simple");

#
# delivery-address
#
my $da = new Biblio::ILL::ISO::DeliveryAddress( new Biblio::ILL::ISO::SystemAddress("SMTP","DChristens\@gov.mb.ca"),
						new Biblio::ILL::ISO::PostalAddress("Manitoba Public Library Services",
										    "",
										    "Unit 200",
										    "1525 First Street South",
										    "",
										    "Brandon",
										    "MB",
										    "CANADA",
										    "R7A 7A1"
										    )
						);

#
# delivery-service
#
my $ds = new Biblio::ILL::ISO::DeliveryService( new Biblio::ILL::ISO::TransportationMode("Canada Post") );

#
# iLL-service-type
#
my $ists = new Biblio::ILL::ISO::ILLServiceTypeSequence( new Biblio::ILL::ISO::ILLServiceType("loan"),
							 new Biblio::ILL::ISO::ILLServiceType("copy-non-returnable")
							 );
$ists->add(new Biblio::ILL::ISO::ILLServiceType("locations"));  #example of adding to a sequence_of

#
# requester-optional-messages
#
my $rom = new Biblio::ILL::ISO::RequesterOptionalMessageType(1,1,"desires","requires");

#
# search-type
#
my $st = new Biblio::ILL::ISO::SearchType("need-Before-Date","1","20030720");

#
# supply-medium-into-type
#
my $smit = new Biblio::ILL::ISO::SupplyMediumInfoType("photocopy","legal-size paper");
my $smits = new Biblio::ILL::ISO::SupplyMediumInfoTypeSequence( $smit );

#
# place-on-hold
#
my $poh = new Biblio::ILL::ISO::PlaceOnHoldType("no");

#
# client-id
#
my $cid = new Biblio::ILL::ISO::ClientId("David Christensen","Most excellent","007");

#
# item-id
#
my $iid = new Biblio::ILL::ISO::ItemId("My Book","David Christensen","CHR001.1");
$iid->set_item_type("monograph");
$iid->set_medium_type("printed");
$iid->set_pagination("456");
$iid->set_publication_date("2003");

#
# cost-info-type
#
my $cit = new Biblio::ILL::ISO::CostInfoType("","","","PLS001","\$40.00");

#
# third-party-info-type
#
my $stlts = new Biblio::ILL::ISO::SendToListTypeSequence( new Biblio::ILL::ISO::SendToListType( new Biblio::ILL::ISO::SystemId("MBOM") ));
$stlts->add(new Biblio::ILL::ISO::SendToListType( new Biblio::ILL::ISO::SystemId("MWPL"),
						  new Biblio::ILL::ISO::AccountNumber("PLS001"),
						  new Biblio::ILL::ISO::SystemAddress("SMTP","pls\@gov.mb.ca")
						  )
	    );
my $atlt = new Biblio::ILL::ISO::AlreadyTriedListType( new Biblio::ILL::ISO::SystemId("BVAS") );
$obj = new Biblio::ILL::ISO::SystemId();
$obj->set_institution_name("Winnipeg Public Library");
$atlt->add($obj);
$obj = new Biblio::ILL::ISO::SystemId();
$obj->set_person_name("Frank Emil Urwald");
$atlt->add($obj);
$atlt->add( new Biblio::ILL::ISO::SystemId("MBOM"));
my $tpit = new Biblio::ILL::ISO::ThirdPartyInfoType(1,1,1,1,"ordered",
						    new Biblio::ILL::ISO::SystemAddress("SMTP","David_A_Christensen\@hotmail.com"),
						    $stlts,
						    $atlt
						    );


#-------------------------------------------------------------------------------------------

my $msg = new Biblio::ILL::ISO::Request();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );
$msg->set_transaction_type( $tt );
$msg->set_ILL_service_type_sequence( $ists );
$msg->set_requester_optional_messages( $rom );
$msg->set_place_on_hold( $poh );
$msg->set_item_id( $iid );
$msg->set_retry_flag("false");
$msg->set_forward_flag("true");

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_delivery_address( $da );
$msg->set_billing_address( $da );
$msg->set_delivery_service( $ds );
$msg->set_search_type( $st );
$msg->set_supply_medium_info_type_sequence( $smits );
$msg->set_client_id( $cid );

$msg->set_cost_info_type( $cit );
$msg->set_copyright_compliance("CanCopy");
$msg->set_third_party_info_type( $tpit );
$msg->set_requester_note("This is a requester note");
$msg->set_forward_note("This is a forward note");

#
#print $msg->as_pretty_string();
#
#my $href = $msg->as_asn();
#print $msg->debug($href);
#
#$msg->encode();
#

$msg->write("msg_01.request.ber");

#print "---end---\n";

