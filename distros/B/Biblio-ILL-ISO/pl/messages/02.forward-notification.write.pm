#!/usr/bin/perl

BEGIN{push @INC, "./../blib/lib/"}

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

my $msg = new Biblio::ILL::ISO::ForwardNotification();

# Minimum required:
$msg->set_protocol_version_num("version-2");
$msg->set_transaction_id( $tid );
$msg->set_service_date_time( $sdt );

# Extra, useful info:
$msg->set_requester_id( $reqid );
$msg->set_responder_id( $resid );
$msg->set_responder_address( $rad );
$msg->set_intermediary_id( $iid );
$msg->set_notification_note( $nn );

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
$msg->write("msg_02.forward-notification.ber");
#print "\n-----------------------------------------------------\n";

#print "---end---\n";

