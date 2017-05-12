package Biblio::ILL::ISO::Request;

=head1 NAME

Biblio::ILL::ISO::Request - Perl extension for handling ISO 10161 interlibrary loan ILL-Request messages

=cut

use Biblio::ILL::ISO::ISO;
use Carp;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.07.15 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::Request is a derivation of the abstract 
Biblio::ILL::ISO::ISO object, and handles the ILL-Request message type.

=head1 EXPORT

None.

=head1 ERROR HANDLING

Each of the set_() methods will croak on missing or invalid parameters.

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ISO );  }

=head1 FROM THE ASN DEFINITION
    
 ILL-Request ::= [APPLICATION 1] EXPLICIT SEQUENCE {
    	protocol-version-num	[0]	IMPLICIT INTEGER, -- {
    				-- version-1 (1),
    				-- version-2 (2)
    				--},
    	transaction-id	[1]	IMPLICIT Transaction-Id,
    	service-date-time	[2]	IMPLICIT Service-Date-Time,
    	requester-id	[3]	IMPLICIT System-Id OPTIONAL,
    		-- mandatory when using store-and-forward communications
    		-- optional when using connection-oriented communications
    	responder-id	[4]	IMPLICIT System-Id OPTIONAL,
    		-- mandatory when using store-and-forward communications
    		-- optional when using connection-oriented communications
    	transaction-type	[5]	IMPLICIT Transaction-Type, --DEFAULT 1,
    	delivery-address	[6]	IMPLICIT Delivery-Address OPTIONAL, 
    	delivery-service		Delivery-Service OPTIONAL,
    	billing-address	[8]	IMPLICIT Delivery-Address OPTIONAL,
    	iLL-service-type	[9]	IMPLICIT SEQUENCE OF ILL-Service-Type, --  SIZE (1..5)
    		-- this sequence is a list, in order of preference
 -- DC - 'EXTERNAL' is not supported in Convert::ASN1
 --	responder-specific-service	[10]	EXTERNAL OPTIONAL,
 --		-- use direct reference style
    	requester-optional-messages	[11]	IMPLICIT Requester-Optional-Messages-Type,
    	search-type	[12]	IMPLICIT Search-Type OPTIONAL,
    	supply-medium-info-type 	[13]	IMPLICIT SEQUENCE OF Supply-Medium-Info-Type OPTIONAL, -- SIZE (1..7)
    		-- this sequence is a list, in order of preference,
    		-- with a maximum number of 7 entries
    	place-on-hold	[14]	IMPLICIT Place-On-Hold-Type, --DEFAULT 3,
    	client-id	[15]	IMPLICIT Client-Id OPTIONAL,     
    	item-id	[16]	IMPLICIT Item-Id,
 -- DC - 'EXTERNAL' definition (see Supplemental-Item-Description)
 --	supplemental-item-description	[17]	IMPLICIT Supplemental-Item-Description OPTIONAL,
    	cost-info-type	[18]	IMPLICIT Cost-Info-Type OPTIONAL,
    	copyright-compliance	[19]	ILL-String OPTIONAL,
    	third-party-info-type	[20]	IMPLICIT Third-Party-Info-Type OPTIONAL,
    		-- mandatory when initiating a FORWARD service or an
    		-- ILL-REQUEST service for a partitioned ILL sub-
    		-- transaction or when initiating an ILL-REQUEST service for
    		-- an ILL sub-transaction if the received ILL-REQUEST
    		-- included an "already-tried-list";optional otherwise
    	retry-flag	[21]	IMPLICIT BOOLEAN, -- DEFAULT FALSE,
    	forward-flag	[22]	IMPLICIT BOOLEAN, -- DEFAULT FALSE,
    	requester-note	[46]	ILL-String OPTIONAL,
    	forward-note	[47]	ILL-String OPTIONAL,
    	iLL-request-extensions 	[49]	IMPLICIT SEQUENCE OF Extension OPTIONAL
    	--iLL-request-extensions 	[49]	IMPLICIT SEQUENCE OF Extension
     	}
    
=cut

=head1 CONSTRUCTORS

new()

Base constructor for the class. It just returns a completely
empty message object, which you'll need to populate with the
various set_() methods, or use the read() method to read an
ILL-Request message from a file (followed by a call to
from_asn() to turn the read's returned hash into a proper
Request message.

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
    $self->{"ASN_TYPE"} = "ILL-Request";

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
    my $msg = new Biblio::ILL::ISO::Request;

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 from_asn($href)

To read a message from a file, use the following:

    my $href = $msg->read("msg_01.request.ber");
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

	} elsif ($k =~ /^transaction-type$/) {
	    $self->{$k} = new Biblio::ILL::ISO::TransactionType();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^delivery-service$/) {
	    $self->{$k} = new Biblio::ILL::ISO::DeliveryService();
	    $self->{$k}->from_asn($href->{$k});

	} elsif (($k =~ /^billing-address$/)
	    || ($k =~ /^delivery-address$/)
	    ) {
	    $self->{$k} = new Biblio::ILL::ISO::DeliveryAddress();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^iLL-service-type$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLServiceTypeSequence();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^requester-optional-messages$/) {
	    $self->{$k} = new Biblio::ILL::ISO::RequesterOptionalMessageType();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^search-type$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SearchType();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^supply-medium-info-type$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SupplyMediumInfoTypeSequence();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^place-on-hold$/) {
	    $self->{$k} = new Biblio::ILL::ISO::PlaceOnHoldType();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^client-id$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ClientId();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^item-id$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ItemId();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^cost-info-type$/) {
	    $self->{$k} = new Biblio::ILL::ISO::CostInfoType();
	    $self->{$k}->from_asn($href->{$k});

	} elsif (($k =~ /^copyright-compliance$/)
		 || ($k =~ /^requester-note$/)
		 || ($k =~ /^forward-note$/)
		 ) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^third-party-info-type$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ThirdPartyInfoType();
	    $self->{$k}->from_asn($href->{$k});

	} elsif (($k =~ /^retry-flag$/)
		 || ($k =~ /^forward-flag$/)
		 ) {
	    $self->{$k} = new Biblio::ILL::ISO::Flag();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^iLL-request-extensions$/) {
	    print "---------- Found iLL-request-extensions ----------\n";
	    print "k = [$k]\n---------------------------------------------------\n";
	    #$self->{$k} = new Biblio::ILL::ISO::Extension();
	    #$self->{$k}->from_asn($href->{$k});

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

 This is a mandatory field.

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

=head2 set_transaction_type($tt)

 Sets the message's transaction-type.  
 Expects a valid Biblio::ILL::ISO::TransactionType.

    my $tt = new Biblio::ILL::ISO::TransactionType("simple");
    $msg->set_transaction_type($tt);

 This is a mandatory field.

=cut
sub set_transaction_type {
    my $self = shift;
    my ($parm) = shift;

    $parm = new Biblio::ILL::ISO::TransactionType("simple") unless ($parm);

    croak "invalid transaction-type" unless (ref($parm) eq "Biblio::ILL::ISO::TransactionType");

    $self->{"transaction-type"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_delivery_address($da)

 Sets the message's delivery-address.
 Expects a valid Biblio::ILL::ISO::DeliveryAddress.

    my $sa = new Biblio::ILL::ISO::SystemAddress("SMTP","DChristens\@gov.mb.ca")'
    my $pa = new Biblio::ILL::ISO::PostalAddress("Manitoba Public Library Services",
					         "",
					         "Unit 200",
					         "1525 First Street South",
					         "",
					         "Brandon",
					         "MB",
					         "CANADA",
					         "R7A 7A1"
					         )
    my $da = new Biblio::ILL::ISO::DeliveryAddress($sa,	$pa);
    $msg->set_delivery_address($da);

 This is an optional field.

=cut
sub set_delivery_address {
    my $self = shift;
    my ($parm) = shift;

    croak "missing delivery-address" unless $parm;
    croak "invalid delivery-address" unless (ref($parm) eq "Biblio::ILL::ISO::DeliveryAddress");

    $self->{"delivery-address"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_delivery_service($ds)

 Sets the message's delivery-service.
 Expects a valid Biblio::ILL::ISO::DeliveryService.

    my $tm = new Biblio::ILL::ISO::TransportationMode("Canada Post")
    my $ds = new Biblio::ILL::ISO::DeliveryService( $tm );
    $msg->set_delivery_service($ds);

 This is an optional field.

=cut
sub set_delivery_service {
    my $self = shift;
    my ($parm) = shift;

    croak "missing delivery-service" unless $parm;
    croak "invalid delivery-service" unless (ref($parm) eq "Biblio::ILL::ISO::DeliveryService");

    $self->{"delivery-service"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_billing_address($ba)

 Sets the message's billing-address.
 Expecs a valid Biblio::ILL::ISO::DeliveryAddress.

    my $sa = new Biblio::ILL::ISO::SystemAddress("SMTP","DChristens\@gov.mb.ca")'
    my $pa = new Biblio::ILL::ISO::PostalAddress("Manitoba Public Library Services",
					         "",
					         "Unit 200",
					         "1525 First Street South",
					         "",
					         "Brandon",
					         "MB",
					         "CANADA",
					         "R7A 7A1"
					         )
    my $ba = new Biblio::ILL::ISO::DeliveryAddress($sa,	$pa);
    $msg->set_delivery_address($ba);

 This is an optional field.

=cut
sub set_billing_address {
    my $self = shift;
    my ($parm) = shift;

    croak "missing billing-address" unless $parm;
    croak "invalid billing-address" unless (ref($parm) eq "Biblio::ILL::ISO::DeliveryAddress");

    $self->{"billing-address"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_ILL_service_type_sequence($ists)

 Sets the message's iLL-service-type sequence.
 Expects a valid Biblio::ILL::ISO::ILLServiceTypeSequence.

    my $ist1 = new Biblio::ILL::ISO::ILLServiceType("loan");
    my $ist2 = new Biblio::ILL::ISO::ILLServiceType("copy-non-returnable");
    # You can pass an array of ILLServiceType(s)
    my $ists = new Biblio::ILL::ISO::ILLServiceTypeSequence( $ist1, $ist2 );
							 
    #example of adding to a sequence_of
    $ists->add(new Biblio::ILL::ISO::ILLServiceType("locations"));

    $msg->set_ILL_service_type_sequence($ists);

 This is a mandatory field.

=cut
sub set_ILL_service_type_sequence {
    my $self = shift;
    my ($parm) = shift;

    croak "missing iLL-service-type sequence" unless $parm;
    croak "invalid iLL-service-type sequence" unless (ref($parm) eq "Biblio::ILL::ISO::ILLServiceTypeSequence");
    croak "too many iLL-service-type in the sequence (max 5)" if ($parm->count() > 5);

    $self->{"iLL-service-type"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_requester_optional_messages($rom)

 Sets the message's requester-optional-messages.
 Expects a valid Biblio::ILL::ISO::RequesterOptionalMessageType.

    my $rom = new Biblio::ILL::ISO::RequesterOptionalMessageType(1,
                                                                 1,
                                                                 "desires",
                                                                 "requires"
                                                                 );
    $msg->set_requester_optional_messages($rom);

 This is a mandatory field.

=cut
sub set_requester_optional_messages {
    my $self = shift;
    my ($parm) = shift;

    croak "missing requester-optional-messages" unless $parm;
    croak "invalid requester-optional-messages" unless (ref($parm) eq "Biblio::ILL::ISO::RequesterOptionalMessageType");

    $self->{"requester-optional-messages"} = $parm;

    return;
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_search_type($st)

 Sets the message's search-type.
 Expects a valid Biblio::ILL::ISO::SearchType.

    my $st = new Biblio::ILL::ISO::SearchType("need-Before-Date",
                                              "1",
                                              "20030720"
                                              );
    $msg->set_search_type($st);

 This is an optional field.

=cut
sub set_search_type {
    my $self = shift;
    my ($parm) = shift;

    croak "missing search-type" unless $parm;
    croak "invalid search-type" unless (ref($parm) eq "Biblio::ILL::ISO::SearchType");

    $self->{"search-type"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_supply_medium_info_type_sequence($smits)

 Sets the message's supply-medium-info-type sequence.
 Expects a valid Biblio::ILL::ISO::SupplyMediumInfoTypeSequence.

    my $smit = new Biblio::ILL::ISO::SupplyMediumInfoType("photocopy","legal-size paper");
    # Just a sequence of one....
    my $smits = new Biblio::ILL::ISO::SupplyMediumInfoTypeSequence( $smit );
    $msg->set_supply_medium_info_type_sequence($smits);

 This is an optional field.

=cut
sub set_supply_medium_info_type_sequence {
    my $self = shift;
    my ($parm) = shift;

    croak "missing supply-medium-info-type sequence" unless $parm;
    croak "invalid supply-medium-info-type sequence" unless (ref($parm) eq "Biblio::ILL::ISO::SupplyMediumInfoTypeSequence");
    croak "too many supply-medium-info-type in the sequence (max 7)" if ($parm->count() > 7);

    $self->{"supply-medium-info-type sequence"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_place_on_hold($poh)

 Sets the message's place-on-hold.
 Expects a valid Biblio::ILL::ISO::PlaceOnHoldType.

    my $poh = new Biblio::ILL::ISO::PlaceOnHoldType("no");
    $msg->set_place_on_hold($poh);

 This is a mandatory field.

=cut
sub set_place_on_hold {
    my $self = shift;
    my ($parm) = shift;

    $parm = new Biblio::ILL::ISO::PlaceOnHoldType("according-to-responder-policy") unless ($parm);
    croak "invalid place-on-hold" unless (ref($parm) eq "Biblio::ILL::ISO::PlaceOnHoldType");

    $self->{"place-on-hold"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_client_id($cid)

 Sets the message's client-id.
 Expects a valid Biblio::ILL::ISO::ClientId.

    my $cid = new Biblio::ILL::ISO::ClientId("David Christensen",
                                             "Most excellent",
                                             "007"
                                             );
    $msg->set_client_id($cid)

 This is an optional field.

=cut
sub set_client_id {
    my $self = shift;
    my ($parm) = shift;

    croak "missing client-id" unless $parm;
    croak "invalid client-id" unless (ref($parm) eq "Biblio::ILL::ISO::ClientId");

    $self->{"client-id"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_item_id($iid)

 Sets the message's item-id.
 Expects a valid Biblio::ILL::ISO::ItemId.

    my $iid = new Biblio::ILL::ISO::ItemId("My Book",
                                           "David Christensen",
                                           "CHR001.1"
                                           );
    $iid->set_item_type("monograph");
    $iid->set_medium_type("printed");
    $iid->set_pagination("456");
    $iid->set_publication_date("2003");
               :
               :

    $msg->set_item_id($iid);

 This is a mandatory field.

=cut
sub set_item_id {
    my $self = shift;
    my ($parm) = shift;

    croak "missing item-id" unless $parm;
    croak "invalid item-id" unless (ref($parm) eq "Biblio::ILL::ISO::ItemId");

    $self->{"item-id"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_cost_info_type($cit)

 Sets the message's cost-info-type.
 Expects a valid Biblio::ILL::ISO::CostInfoType.

    my $cit = new Biblio::ILL::ISO::CostInfoType("","","","PLS001","\$40.00");
    $msg->set_cost_info_type($cit);

 This is an optional field.

=cut
sub set_cost_info_type {
    my $self = shift;
    my ($parm) = shift;

    croak "missing cost-info-type" unless $parm;
    croak "invalid cost-info-type" unless (ref($parm) eq "Biblio::ILL::ISO::CostInfoType");

    $self->{"cost-info-type"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_copyright_compliance($s)

 Sets the message's copyright-compliance.
 Expects a simple text string.

    msg->set_copyright_compliance("Statement of copyright compliance");

 This is an optional field.

=cut
sub set_copyright_compliance {
    my $self = shift;
    my ($parm) = shift;

    croak "missing copyright-compliance" unless $parm;

    $self->{"copyright-compliance"} = new Biblio::ILL::ISO::ILLString($parm);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_third_party_info_type($tpit)

 Sets the message's third-party-info-type.
 Expects a valid Biblio::ILL::ISO::ThirdPartyInfoType.

    # The send-to-list-type sequence
    my $stlt = new Biblio::ILL::ISO::SendToListType( new Biblio::ILL::ISO::SystemId("MBOM") )
    my $stlts = new Biblio::ILL::ISO::SendToListTypeSequence( $stlt );
    $stlts->add(new Biblio::ILL::ISO::SendToListType( new Biblio::ILL::ISO::SystemId("MWPL"),
                                                      new Biblio::ILL::ISO::AccountNumber("PLS001"),
				                      new Biblio::ILL::ISO::SystemAddress("SMTP","pls\@gov.mb.ca")
				                    )
  	       );

    # The already-tried-list-type
    my $atlt = new Biblio::ILL::ISO::AlreadyTriedListType( new Biblio::ILL::ISO::SystemId("BVAS") );
    my $obj = new Biblio::ILL::ISO::SystemId();
    $obj->set_institution_name("Winnipeg Public Library");
    $atlt->add($obj);
    $obj = new Biblio::ILL::ISO::SystemId();
    $obj->set_person_name("Frank Emil Urwald");
    $atlt->add($obj);
    $atlt->add( new Biblio::ILL::ISO::SystemId("MBOM"));

    # And finally, the third-party-info-type
    my $sa = new Biblio::ILL::ISO::SystemAddress("SMTP","David_A_Christensen\@hotmail.com");
    my $tpit = new Biblio::ILL::ISO::ThirdPartyInfoType(1,1,1,1,
                                                        "ordered",
						        $sa,
						        $stlts,
						        $atlt
						       );
    msg->set_third_party_info_type($tpit);

 This is an optional field.

=cut
sub set_third_party_info_type {
    my $self = shift;
    my ($parm) = shift;

    croak "missing third-party-info-type" unless $parm;
    croak "invalid third-party-info-type" unless (ref($parm) eq "Biblio::ILL::ISO::ThirdPartyInfoType");

    $self->{"third-party-info-type"} = $parm;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_retry_flag($flag)

 Sets the message's retry-flag.
 Acceptable parameter values are the strings:
     true
     false

 This is a mandatory field.

=cut
sub set_retry_flag {
    my $self = shift;
    my ($parm) = shift;

    $parm = "false" unless $parm;
    $self->{"retry-flag"} = new Biblio::ILL::ISO::Flag($parm);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_forward_flag($flag)

 Sets the message's forward-flag.
 Acceptable parameter values are the strings:
     true
     false

 This is a mandatory field.

=cut
sub set_forward_flag {
    my $self = shift;
    my ($parm) = shift;

    $parm = "false" unless $parm;
    $self->{"forward-flag"} = new Biblio::ILL::ISO::Flag($parm);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_requester_note($note)

 Sets the message's requester-note.
 Expects a simple text string.

    $msg->set_requester_note("This is a requester note");

 This is an optional field.

=cut
sub set_requester_note {
    my $self = shift;
    my ($parm) = shift;

    croak "missing requester-note" unless $parm;

    $self->{"requester-note"} = new Biblio::ILL::ISO::ILLString($parm);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_forward_note($note)

 Sets the message's forward-note.
 Expects a simple text string.

    $msg->set_forward_note("This is a forward note");

 This is an optional field.

=cut
sub set_forward_note {
    my $self = shift;
    my ($parm) = shift;

    croak "missing forward-note" unless $parm;

    $self->{"forward-note"} = new Biblio::ILL::ISO::ILLString($parm);

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
