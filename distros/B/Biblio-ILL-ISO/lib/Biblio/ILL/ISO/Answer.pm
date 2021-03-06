package Biblio::ILL::ISO::Answer;

=head1 NAME

Biblio::ILL::ISO::Answer - Perl extension for handling ISO 10161 interlibrary loan ILL-Answer messages

=cut

use Biblio::ILL::ISO::ISO;
use Carp;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.07.26 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::Answer is a derivation of the abstract 
Biblio::ILL::ISO::ISO object, and handles the ILL-Answer message type.

=head1 EXPORT

None.

=head1 ERROR HANDLING

Each of the set_() methods will croak on missing or invalid parameters.

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ISO );  }

=head1 FROM THE ASN DEFINITION
 

 ILL-Answer ::= [APPLICATION 4] SEQUENCE {
	protocol-version-num	[0]	IMPLICIT INTEGER, -- {
				-- version-1 (1),
				-- version-2 (2)
				-- },
	transaction-id	        [1]	IMPLICIT Transaction-Id,
	service-date-time	[2]	IMPLICIT Service-Date-Time,
	requester-id	        [3]	IMPLICIT System-Id OPTIONAL,
		-- mandatory when using store-and-forward communications
		-- optional when using connection-oriented communications
	responder-id	        [4]	IMPLICIT System-Id OPTIONAL,
		-- mandatory when using store-and-forward communications
		-- optional when using connection-oriented communications
	transaction-results	[31]	IMPLICIT Transaction-Results,
	results-explanation	[32]	Results-Explanation OPTIONAL,
		-- dc hmm
		-- optional if transaction-results equals RETRY, UNFILLED,
		-- WILL-SUPPLY or HOLD-PLACED;
		-- required if transaction-results equals CONDITIONAL,
		-- LOCATIONS-PROVIDED or ESTIMATE
 -- DC - 'EXTERNAL' is not supported in Convert::ASN1
 --	responder-specific-results	[33]	EXTERNAL OPTIONAL,
 		-- this type is mandatory if results-explanation
 		-- chosen for any result 
		-- has the value "responder-specific".
 -- DC - 'EXTERNAL' definition (see Supplemental-Item-Description)
 --	supplemental-item-description	[17]	IMPLICIT Supplemental-Item-Description OPTIONAL,
	send-to-list	        [23]	IMPLICIT Send-To-List-Type OPTIONAL,
	already-tried-list	[34]	IMPLICIT Already-Tried-List-Type OPTIONAL,
	responder-optional-messages	[28]	IMPLICIT Responder-Optional-Messages-Type OPTIONAL,
	responder-note	        [46]	ILL-String OPTIONAL,
	ill-answer-extensions	[49]	IMPLICIT SEQUENCE OF Extension OPTIONAL
	}

=cut

=head1 CONSTRUCTORS

new()

Base constructor for the class. It just returns a completely
empty message object, which you'll need to populate with the
various set_() methods, or use the read() method to read an
Answer message from a file (followed by a call to
from_asn() to turn the read's returned hash into a proper
Answer message.

The constructor also initializes the Convert::ASN1 if it
hasn't been initialized.

=cut
#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub new {
    my $class = shift;
    my $self = {};

    Biblio::ILL::ISO::ISO::_init() if (not $Biblio::ILL::ISO::ISO::_asn_initialized);
    $self->{"ASN_TYPE"} = "ILL-Answer";

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub as_pretty_string {
    my $self = shift;

    foreach my $key (sort keys %$self) {
	if ($key ne "ASN_TYPE") {
	    print "\n[$key]\n";
	    print $self->{$key}->as_pretty_string();
	}
    }
    return;
}

#---------------------------------------------------------------
# This will return a structure usable by Convert::ASN1
#---------------------------------------------------------------
sub as_asn {
    my $self = shift;

    my %h = ();
    foreach my $key (sort keys %$self) {
	if ($key ne "ASN_TYPE") {
	    #print "\n[$key]\n";
	    $h{$key} = $self->{$key}->as_asn();
	}
    }
    return \%h;
}

=head1 METHODS

For any example code, assume the following:
    my $msg = new Biblio::ILL::ISO::Answer;

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 from_asn($href)

To read a message from a file, use the following:

    my $href = $msg->read("msg_04.answer.ber");
    $msg = $msg->from_asn($href);

The from_asn() method turns the hash returned from read() into
a proper message-type object.

=cut
sub from_asn {
    my $self = shift;
    my $href = shift;

    foreach my $k (keys %$href) {

	if ($k =~ /^protocol-version-num$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ProtocolVersionNum();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^transaction-id$/) {
	    $self->{$k} = new Biblio::ILL::ISO::TransactionId();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^service-date-time$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ServiceDateTime();
	    $self->{$k}->from_asn($href->{$k});

	} elsif (($k =~ /^requester-id$/)
		 || ($k =~ /^responder-id$/)
		 ) {
	    $self->{$k} = new Biblio::ILL::ISO::SystemId();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^transaction-results$/) {
	    $self->{$k} = new Biblio::ILL::ISO::TransactionResults();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^results-explanation$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ResultsExplanation();
	    $self->{$k}->from_asn($href->{$k});

        # This is EXTERNAL, which we don't handle.	    
	#} elsif ($k =~ /^supplemental-item-description$/) {
	#    $self->{$k} = new Biblio::ILL::ISO::SupplementalItemDescription();
	#    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^send-to-list$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SendToListType();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^already-tried-list$/) {
	    $self->{$k} = new Biblio::ILL::ISO::AlreadyTriedListType();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^responder-optional-messages$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ResponderOptionalMessageType();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^responder-note$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString();
	    $self->{$k}->from_asn($href->{$k});

	} else {
	    croak "invalid " . ref($self) . " element: [$k]";
	}

    }
    return $self;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_protocol_version_num($pvn)

 Sets the protocol version number.
 Acceptable parameter values are the strings:
    version-1
    version-2

=cut
sub set_protocol_version_num {
    my $self = shift;
    my ($parm) = shift;

    croak "missing protocol-version-num" unless $parm;

    $self->{"protocol-version-num"} = new Biblio::ILL::ISO::ProtocolVersionNum($parm);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_transaction_id($tid)

 Sets the message's transaction-id.  
 Expects a valid Biblio::ILL::ISO::TransactionId.

    my $tid = new Biblio::ILL::ISO::TransactionId("PLS","001","", 
					          new Biblio::ILL::ISO::SystemId("MWPL"));
    $msg->set_transaction_id($tid);

 This is a mandatory field.

=cut
sub set_transaction_id {
    my $self = shift;
    my ($parm) = shift;

    croak "missing transaction-id" unless $parm;
    croak "invalid transaction-id" unless (ref($parm) eq "Biblio::ILL::ISO::TransactionId");

    $self->{"transaction-id"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_service_date_time($sdt)

 Sets the message's service-date-time.  
 Expects a valid Biblio::ILL::ISO::ServiceDateTime.

    my $dt_this = new Biblio::ILL::ISO::DateTime("20030623","114400");
    my $dt_orig = new Biblio::ILL::ISO::DateTime("20030623","114015")
    my $sdt = new Biblio::ILL::ISO::ServiceDateTime( $dt_this, $dt_orig);
    $msg->set_service_date_time($sdt);

 This is a mandatory field.

=cut
sub set_service_date_time {
    my $self = shift;
    my ($sdt) = shift;

    croak "missing service-date-time" unless $sdt;
    croak "invalid service-date-time" unless (ref($sdt) eq "Biblio::ILL::ISO::ServiceDateTime");

    $self->{"service-date-time"} = $sdt;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_requester_id($reqid)

 Sets the message's requester-id.  
 Expects a valid Biblio::ILL::ISO::SystemId.

    my $reqid = new Biblio::ILL::ISO::SystemId();
    $reqid->set_person_name("David A. Christensen");
    $msg->set_requester_id($reqid);

 This is an optional field.

=cut
sub set_requester_id {
    my $self = shift;
    my ($parm) = shift;

    croak "missing requester-id" unless $parm;
    croak "invalid requester-id" unless (ref($parm) eq "Biblio::ILL::ISO::SystemId");

    $self->{"requester-id"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_responder_id($resid)

 Sets the message's responder-id.  
 Expects a valid Biblio::ILL::ISO::SystemId.

    my $resid = new Biblio::ILL::ISO::SystemId("MWPL");
    $msg->set_responder_id($resid);

 This is an optional field.

=cut
sub set_responder_id {
    my $self = shift;
    my ($parm) = shift;

    croak "missing responder-id" unless $parm;
    croak "invalid responder-id" unless (ref($parm) eq "Biblio::ILL::ISO::SystemId");

    $self->{"responder-id"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_transaction_results($tr)

 Sets the message's transaction-results.
 Expects a valid Biblio::ILL::ISO::TransactionResults.

    my $tr = new Biblio::ILL::ISO::TransactionResults("conditional");
    $msg->set_transaction_results($tr);

 This is a mandatory field.

=cut
sub set_transaction_results {
    my $self = shift;
    my ($parm) = shift;

    $parm = new Biblio::ILL::ISO::TransactionResults("unfilled") unless ($parm);

    croak "invalid transaction-results" unless (ref($parm) eq "Biblio::ILL::ISO::TransactionResults");

    $self->{"transaction-results"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_results_explanation($rexp)

 Sets the message's results-explanation.
 Expects a valid Biblio::ILL::ISO::ResultsExplanation.

    # Build a location sequence
    my $sid = new Biblio::ILL::ISO::SystemId();
    $sid->set_person_name("David A. Christensen");
    $sid->set_institution_symbol("MWPL");
    my $sa = new Biblio::ILL::ISO::SystemAddress("SMTP","pls\@gov.mb.ca");
    my $note = new Biblio::ILL::ISO::ILLString("This is a location note.");
    my $loc = new Biblio::ILL::ISO::LocationInfo($sid,
					         $sa,
					         $note,
					         );
    my $locseq = new Biblio::ILL::ISO::LocationInfoSequence( $loc );
    $sid = new Biblio::ILL::ISO::SystemId();
    $sid->set_institution_name("Brandon Public Library");
    $sa = new Biblio::ILL::ISO::SystemAddress("SMTP","library\@brandon.mb.ca");
    $loc = new Biblio::ILL::ISO::LocationInfo($sid, $sa);
    $locseq->add($loc);

    # Build a conditional-results condition
    my $condition = new Biblio::ILL::ISO::ConditionalResultsCondition("charges");
    my $dt = new Biblio::ILL::ISO::ISODate("20030727");
    my $tm = new Biblio::ILL::ISO::TransportationMode("Canada Post");
    my $ds = new Biblio::ILL::ISO::DeliveryService( $tm )
    my $conres = new Biblio::ILL::ISO::ConditionalResults($condition,
						          $dt,
						          $locseq,
						          $ds
						          );

    my $rexp = new Biblio::ILL::ISO::ResultsExplanation( $conres );
    $msg->set_results_explanation($rexp);

 This is an optional field.

=cut
sub set_results_explanation {
    my $self = shift;
    my ($parm) = shift;

    croak "missing results-explanation" unless $parm;
    croak "invalid results-explanation" unless (ref($parm) eq "Biblio::ILL::ISO::ResultsExplanation");

    $self->{"results-explanation"} = $parm;

    return;
}

#---------------------------------------------------------------
#  This is EXTERNAL, which we don't handle
#---------------------------------------------------------------
#sub set_supplemental_item_description {
#    my $self = shift;
#    my ($parm) = shift;
#
#    croak "missing supplemental-item-description" unless $parm;
#    croak "invalid supplemental-item-description" unless (ref($parm) eq "Biblio::ILL::ISO::SupplementalItemDescription");
#
#    $self->{"supplemental-item-description"} = $parm;
#
#    return;
#}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_send_to_list($stlts)

 Sets the message's send-to-list.
 Expects a valid Biblio::ILL::ISO::SendToListTypeSequence.

    my $sid = new Biblio::ILL::ISO::SystemId("MBOM");
    my $stlt = new Biblio::ILL::ISO::SendToListType( $sid );
    my $stlts = new Biblio::ILL::ISO::SendToListTypeSequence( $stlt );

    $sid = new Biblio::ILL::ISO::SystemId("MWPL");
    my $act = new Biblio::ILL::ISO::AccountNumber("PLS001");
    my $sa = new Biblio::ILL::ISO::SystemAddress("SMTP","pls\@gov.mb.ca");
    $stlts->add( new Biblio::ILL::ISO::SendToListType( $sid,
						       $act,
						       $sa
						      )
 	        );

    $msg->set_send_to_list($stlts);

 This is an optional field.

=cut
sub set_send_to_list {
    my $self = shift;
    my ($parm) = shift;

    croak "missing send-to-list" unless $parm;
    croak "invalid send-to-list" unless (ref($parm) eq "Biblio::ILL::ISO::SendToListTypeSequence");

    $self->{"send-to-list"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_already_tried_list($atlt)

 Sets the message's already-tried-list.
 Expects a valid Biblio::ILL::ISO::AlreadyTriedListType.

    my $sid = new Biblio::ILL::ISO::SystemId("BVAS");
    my $atlt = new Biblio::ILL::ISO::AlreadyTriedListType( $sid );

    $sid = new Biblio::ILL::ISO::SystemId();
    $sid->set_institution_name("Winnipeg Public Library");
    $atlt->add($sid);

    $sid = new Biblio::ILL::ISO::SystemId();
    $sid->set_person_name("Frank Emil Urwald");
    $atlt->add($sid);

    $atlt->add( new Biblio::ILL::ISO::SystemId("MBOM"));

    $msg->set_already_tried_list($atlt);

 This is an optional field.

=cut
sub set_already_tried_list {
    my $self = shift;
    my ($parm) = shift;

    croak "missing already-tried-list" unless $parm;
    croak "invalid already-tried-list" unless (ref($parm) eq "Biblio::ILL::ISO::AlreadyTriedListType");

    $self->{"already-tried-list"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_responder_optional_messages($rom)

 Sets the message's responder-optional-messages.
 Expects a valid Biblio::ILL::ISO::ResponderOptionalMessageType.

    my $rom = new Biblio::ILL::ISO::ResponderOptionalMessageType(1,1,
                                                                 "desires",
                                                                 "requires"
                                                                 );
    $msg->set_responder_optional_messages($rom);

 This is an optional field.

=cut
sub set_responder_optional_messages {
    my $self = shift;
    my ($parm) = shift;

    croak "missing responder-optional-messages" unless $parm;
    croak "invalid responder-optional-messages" unless (ref($parm) eq "Biblio::ILL::ISO::ResponderOptionalMessageType");

    $self->{"responder-optional-messages"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_responder_note($note)

 Sets the message's responder-note.
 Expects a simple text string.

    $msg->set_responder_note("This is a responder note");

 This is an optional field.

=cut
sub set_responder_note {
    my $self = shift;
    my ($parm) = shift;

    croak "missing responder-note" unless $parm;
    croak "invalid responder-note" unless (ref($parm) eq "Biblio::ILL::ISO::ILLString");

    $self->{"responder-note"} = $parm;

    return;
}

=head1 RELATED MODULES

 Biblio::ILL::ISO::ISO
 Biblio::ILL::ISO::Request
 Biblio::ILL::ISO::ForwardNotification
 Biblio::ILL::ISO::Shipped
 Biblio::ILL::ISO::Answer
 Biblio::ILL::ISO::ConditionalReply
 Biblio::ILL::ISO::Cancel
 Biblio::ILL::ISO::CancelReply
 Biblio::ILL::ISO::Received
 Biblio::ILL::ISO::Recall
 Biblio::ILL::ISO::Returned
 Biblio::ILL::ISO::CheckedIn
 Biblio::ILL::ISO::Overdue
 Biblio::ILL::ISO::Renew
 Biblio::ILL::ISO::RenewAnswer
 Biblio::ILL::ISO::Lost
 Biblio::ILL::ISO::Damaged
 Biblio::ILL::ISO::Message
 Biblio::ILL::ISO::StatusQuery
 Biblio::ILL::ISO::StatusOrErrorReport
 Biblio::ILL::ISO::Expired

=cut

=head1 SEE ALSO

See the README for system design notes.

For more information on Interlibrary Loan standards (ISO 10160/10161),
a good place to start is:

http://www.nlc-bnc.ca/iso/ill/main.htm

=cut

=head1 AUTHOR

David Christensen, <DChristensenSPAMLESS@westman.wave.ca>

=cut


=head1 COPYRIGHT AND LICENSE

Copyright 2003 by David Christensen

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
