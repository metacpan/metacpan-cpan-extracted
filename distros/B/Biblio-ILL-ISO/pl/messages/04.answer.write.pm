#!/usr/bin/perl

BEGIN{push @INC, "./../blib/lib/"}

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

my $msg = new Biblio::ILL::ISO::Answer();

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
$msg->write("msg_04.answer.ber");
#print "\n-----------------------------------------------------\n";

#print "---end---\n";

