#!/usr/bin/perl
# This code is used in pl/ (as ISO-msg-t-dumper.pm) to create the message test cases 
# and in t/ (as 03.messages.t) to test them.
# (each script is tweaked a bit... Some day I'll work out a more clever way of doing this)

#BEGIN{unshift @INC, "./../lib/"}
BEGIN{unshift @INC, "./lib/"}

#use Test::More tests => 20;
#use Data::Dumper;


my %msgs = ();
my $msg;

#========================================================================================


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

$msg = new Biblio::ILL::ISO::Request();

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



#$msg->write("msg_01.request.ber");
$msgs{"01.request"} = $msg;





#========================================================================================


use Biblio::ILL::ISO::ForwardNotification;

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
# notification-note
#
my $nn = new Biblio::ILL::ISO::ILLString("This is a notification-note.");


#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::ForwardNotification();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );
$msg->set_responder_id( $resid );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_address( $rad );
$msg->set_intermediary_id( $iid );
$msg->set_notification_note( $nn );



#$msg->write("msg_02.forward-notification.ber");
$msgs{"02.forward-notification"} = $msg;






#========================================================================================


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
my $upmt = new Biblio::ILL::ISO::UnitsPerMediumType( new Biblio::ILL::ISO::SupplyMediumType("audio-recording"), 3);
my $upmts = new Biblio::ILL::ISO::UnitsPerMediumTypeSequence( $upmt );
my $sd = new Biblio::ILL::ISO::SupplyDetails("20030813",
					     "20030920",
					     123,
					     "45.67",
					     new Biblio::ILL::ISO::ShippedConditions("no-reproduction"),
					     new Biblio::ILL::ISO::ShippedVia( new Biblio::ILL::ISO::TransportationMode("Canada Post") ),
					     new Biblio::ILL::ISO::Amount("50.00"),
					     "50.00",
					     $upmts
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

$msg = new Biblio::ILL::ISO::Shipped();

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



#$msg->write("msg_03.shipped.ber");
$msgs{"03.shipped"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::Answer;

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
# transaction-results
#
my $tr = new Biblio::ILL::ISO::TransactionResults("conditional");

#
# results-explanation
#
my $sid = new Biblio::ILL::ISO::SystemId();
$sid->set_person_name("David A. Christensen");
$sid->set_institution_symbol("MWPL");
my $loc = new Biblio::ILL::ISO::LocationInfo($sid,
					     new Biblio::ILL::ISO::SystemAddress("SMTP","DChristensen\@westman.wave.ca"),
					     new Biblio::ILL::ISO::ILLString("This is a location note.")
					     );
my $locseq = new Biblio::ILL::ISO::LocationInfoSequence( $loc );
$sid = new Biblio::ILL::ISO::SystemId();
$sid->set_institution_name("Brandon Public Library");
$loc = new Biblio::ILL::ISO::LocationInfo($sid, new Biblio::ILL::ISO::SystemAddress("SMTP","library\@brandon.mb.ca") );
$locseq->add($loc);
my $conres = new Biblio::ILL::ISO::ConditionalResults(new Biblio::ILL::ISO::ConditionalResultsCondition("charges"),
						      new Biblio::ILL::ISO::ISODate("20030727"),
						      $locseq,
						      new Biblio::ILL::ISO::DeliveryService( new Biblio::ILL::ISO::TransportationMode("Canada Post") )
						      );
my $rexp = new Biblio::ILL::ISO::ResultsExplanation( $conres );

#
# send-to-list
#
my $stlt = new Biblio::ILL::ISO::SendToListType( new Biblio::ILL::ISO::SystemId("MBOM") );
my $stlts = new Biblio::ILL::ISO::SendToListTypeSequence( $stlt );
$stlts->add( new Biblio::ILL::ISO::SendToListType( new Biblio::ILL::ISO::SystemId("MWPL"),
						   new Biblio::ILL::ISO::AccountNumber("PLS001"),
						   new Biblio::ILL::ISO::SystemAddress("SMTP","pls\@gov.mb.ca")
						   )
	     );
	     
#
# already-tried-list
#
my $atlt = new Biblio::ILL::ISO::AlreadyTriedListType( new Biblio::ILL::ISO::SystemId("BVAS") );
$obj = new Biblio::ILL::ISO::SystemId();
$obj->set_institution_name("Winnipeg Public Library");
$atlt->add($obj);
$obj = new Biblio::ILL::ISO::SystemId();
$obj->set_person_name("Frank Emil Urwald");
$atlt->add($obj);
$atlt->add( new Biblio::ILL::ISO::SystemId("MBOM"));

#
# responder-optional-messages
#
my $rom = new Biblio::ILL::ISO::ResponderOptionalMessageType(1,1,"desires","requires");

#
# responder-note
#
my $rn = new Biblio::ILL::ISO::ILLString("This is a responder-note.");


#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::Answer();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );
$msg->set_transaction_results( $tr );
$msg->set_results_explanation( $rexp );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_responder_optional_messages( $rom );
$msg->set_send_to_list( $stlts );
$msg->set_already_tried_list( $atlt );
$msg->set_responder_note( $rn );



#$msg->write("msg_04.answer.ber");
$msgs{"04.answer"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::ConditionalReply;

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
# responder-note
#
my $rn = new Biblio::ILL::ISO::ILLString("This is a responder-note.");


#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::ConditionalReply();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );
$msg->set_answer("true");

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_requester_note( $rn );



#$msg->write("msg_05.conditional-reply.ber");
$msgs{"05.conditional-reply"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::Cancel;

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
# requester-note
#
my $rn = new Biblio::ILL::ISO::ILLString("This is a requester-note.");


#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::Cancel();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_requester_note( $rn );



#$msg->write("msg_06.cancel.ber");
$msgs{"06.cancel"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::CancelReply;

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
# responder-note
#
my $rn = new Biblio::ILL::ISO::ILLString("This is a responder-note.");


#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::CancelReply();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );
$msg->set_answer("true");

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_responder_note( $rn );



#$msg->write("msg_07.cancel-reply.ber");
$msgs{"07.cancel-reply"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::Received;

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
# supplier-id
#
my $sid = new Biblio::ILL::ISO::SystemId("MBOM");

#
# date-received
#
my $dr = new Biblio::ILL::ISO::ISODate("20030813");

#
# shipped-service-type
#
my $sst = new Biblio::ILL::ISO::ShippedServiceType("loan");

#
# requester-note
#
my $rn = new Biblio::ILL::ISO::ILLString("This is a requester-note.");


#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::Received();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );
$msg->set_date_received( $dr );
$msg->set_shipped_service_type( $sst );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_supplier_id( $sid );
$msg->set_requester_note( $rn );



#$msg->write("msg_08.received.ber");
$msgs{"08.received"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::Recall;

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
# responder-note
#
my $rn = new Biblio::ILL::ISO::ILLString("This is a responder-note.");


#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::Recall();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_responder_note( $rn );



#$msg->write("msg_09.recall.ber");
$msgs{"09.recall"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::Returned;

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
# date-returned
#
my $dr = new Biblio::ILL::ISO::ISODate("20030814");

#
# returned-via
#
my $rv = new Biblio::ILL::ISO::TransportationMode("Canada Post");

#
# insured-for
#
my $ins = new Biblio::ILL::ISO::Amount("123.45");

#
# requester-note
#
my $rn = new Biblio::ILL::ISO::ILLString("This is a requester-note.");


#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::Returned();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );
$msg->set_date_returned( $dr );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_requester_id( $resid );
$msg->set_returned_via( $rv );
$msg->set_insured_for( $ins );
$msg->set_requester_note( $rn );


#$msg->write("msg_10.returned.ber");
$msgs{"10.returned"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::CheckedIn;

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
# date-checked-in
#
my $dci = new Biblio::ILL::ISO::ISODate("20030814");

#
# responder-note
#
my $rn = new Biblio::ILL::ISO::ILLString("This is a responder-note.");


#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::CheckedIn();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );
$msg->set_date_checked_in( $dci );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_responder_note( $rn );



#$msg->write("msg_11.checked-in.ber");
$msgs{"11.checked-in"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::Overdue;

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
# date-due
#
my $dd = new Biblio::ILL::ISO::DateDue("20030814","false");

#
# responder-note
#
my $rn = new Biblio::ILL::ISO::ILLString("This is a responder-note.");


#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::Overdue();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );
$msg->set_date_due( $dd );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_responder_note( $rn );



#$msg->write("msg_12.overdue.ber");
$msgs{"12.overdue"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::Renew;

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
# desired-due-date
#
my $ddd = new Biblio::ILL::ISO::ISODate("20030814");

#
# requester-note
#
my $rn = new Biblio::ILL::ISO::ILLString("This is a requester-note.");


#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::Renew();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_requester_id( $resid );
$msg->set_desired_due_date( $ddd );
$msg->set_requester_note( $rn );



#$msg->write("msg_13.renew.ber");
$msgs{"13.renew"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::RenewAnswer;

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
# date-due
#
my $dd = new Biblio::ILL::ISO::DateDue("20030814","true");

#
# responder-note
#
my $rn = new Biblio::ILL::ISO::ILLString("This is a responder-note.");


#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::RenewAnswer();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );
$msg->set_answer("true");

# Extra, useful info:
$msg->set_responder_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_date_due( $dd );
$msg->set_responder_note( $rn );



#$msg->write("msg_14.renew-answer.ber");
$msgs{"14.renew-answer"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::Lost;

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


#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::Lost();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_note("This is a note.");



#$msg->write("msg_15.lost.ber");
$msgs{"15.lost"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::Damaged;

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
# damaged-details
#
# Unsupported. (At least, it is until I figure out the whole 'extensions' thing).



#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::Damaged();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_note("This is a note.");



#$msg->write("msg_16.damaged.ber");
$msgs{"16.damaged"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::Message;

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
# note
#
my $note = new Biblio::ILL::ISO::ILLString("This is a note.");



#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::Message();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );
$msg->set_note( $note );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );



#$msg->write("msg_17.message.ber");
$msgs{"17.message"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::StatusQuery;

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
# note
#
my $note = new Biblio::ILL::ISO::ILLString("This is a note.");



#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::StatusQuery();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_note( $note );



#$msg->write("msg_18.status-query.ber");
$msgs{"18.status-query"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::StatusOrErrorReport;

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
# status-report
#
my $cs = new Biblio::ILL::ISO::CurrentState("sHIPPED");
my $hr = new Biblio::ILL::ISO::HistoryReport("20030811",
					     "fORWARD",
					     "20030813",
					     new Biblio::ILL::ISO::SystemId("MBOM"),
					     "20030815",
					     "Anne Author",
					     "A Title",
					     "",
					     "",
					     "loan",
					     new Biblio::ILL::ISO::TransactionResults("will-supply"),
					     "This is a history report."
					     );
my $sr = new Biblio::ILL::ISO::StatusReport($hr, $cs);


#
# note
#
my $note = new Biblio::ILL::ISO::ILLString("This is a note.");



#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::StatusOrErrorReport();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );
$msg->set_status_report( $sr );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_note( $note );



#$msg->write("msg_19.status-or-error-report.ber");
$msgs{"19.status-or-error-report"} = $msg;






#========================================================================================


use Biblio::ILL::ISO::Expired;

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



#-------------------------------------------------------------------------------------------

$msg = new Biblio::ILL::ISO::Expired();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );


#$msg->write("msg_20.expired.ber");
$msgs{"20.expired"} = $msg;


#========================================================================================
#========================================================================================
#========================================================================================

my %tester = ();
$tester{"01.request"} = new Biblio::ILL::ISO::Request;
$tester{"02.forward-notification"} = new Biblio::ILL::ISO::ForwardNotification;
$tester{"03.shipped"} = new Biblio::ILL::ISO::Shipped;
$tester{"04.answer"} = new Biblio::ILL::ISO::Answer;
$tester{"05.conditional-reply"} = new Biblio::ILL::ISO::ConditionalReply;
$tester{"06.cancel"} = new Biblio::ILL::ISO::Cancel;
$tester{"07.cancel-reply"} = new Biblio::ILL::ISO::CancelReply;
$tester{"08.received"} = new Biblio::ILL::ISO::Received;
$tester{"09.recall"} = new Biblio::ILL::ISO::Recall;
$tester{"10.returned"} = new Biblio::ILL::ISO::Returned;
$tester{"11.checked-in"} = new Biblio::ILL::ISO::CheckedIn;
$tester{"12.overdue"} = new Biblio::ILL::ISO::Overdue;
$tester{"13.renew"} = new Biblio::ILL::ISO::Renew;
$tester{"14.renew-answer"} = new Biblio::ILL::ISO::RenewAnswer;
$tester{"15.lost"} = new Biblio::ILL::ISO::Lost;
$tester{"16.damaged"} = new Biblio::ILL::ISO::Damaged;
$tester{"17.message"} = new Biblio::ILL::ISO::Message;
$tester{"18.status-query"} = new Biblio::ILL::ISO::StatusQuery;
$tester{"19.status-or-error-report"} = new Biblio::ILL::ISO::StatusOrErrorReport;
$tester{"20.expired"} = new Biblio::ILL::ISO::Expired;

my $generate = "Build me some new test cases!";

foreach $key (sort keys %tester) {
    if (defined $generate) {
	$msgs{$key}->write("t/msg_$key.ber");
    }
#    $msgs{$key}->write("t/test.ber");
#    
#    $/ = undef;
#    
#    open( IN, "t/test.ber");
#    my $actual = <IN>;
#    close( IN );
#    
#    open( IN, "t/msg_$key.ber");
#    my $expected = <IN>;
#    close( IN );
#    
#    is( $actual, $expected, "messages: $key");
} 



