package Biblio::ILL::ISO::ISO;

=head1 NAME

Biblio::ILL::ISO - Perl extension for handling ISO 10161 interlibrary loan messages

=cut

use Biblio::ILL::ISO::ILL_ASN_types_list;
use Biblio::ILL::ISO::asn;
use Biblio::ILL::ISO::1_0_10161_13_3;
use Convert::ASN1;
use Carp;

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';
#---------------------------------------------------------------------------
# Mods
# 0.06 - 2003.12.08 - Fixed t/02.types.t to compare eval'd (pre-existing)
#                     Data::Dumper output to existing hash, rather than
#                     trying to compare (pre-existing) Data::Dumper output
#                     to newly-dumped-from-existing-hash.
# 0.05 - 2003.10.26 - DamagedDetails is currently unsupported.
# 0.04 - 2003.09.07 - fixed the POD
# 0.03 - 2003.08.13 - added:
#                     Forward-Notification
#                     Shipped
#                     Conditional-Reply
#                     Cancel
#                     Cancel-Reply
#                     Received
#                     Recall
#                     Returned
#                     Checked-In
#                     Overdue
#                     Renew
#                     Renew-Answer
#                     Lost
#                     Damaged
#                     Message
#                     Status-Query
#                     Status-Or-Error-Report
#                     Expired
# 0.02 - 2003.07.27 - added Answer
#                   - added $self->{"ASN_TYPE"} for encode/decode
# 0.01 - 2003.07.15 - original version (Request)
#---------------------------------------------------------------------------

=head1 DESCRIPTION

The base class for the various ISO 10161 interlibrary loan message types
(eg: Biblio::ILL::ISO::Request and Biblio::ILL::ISO::Answer).

It knows how to handle all (most?) of the ISO 10161 ASN.1 types (eg: ILLString and ClientId) that make up these messages.

It knows how to do the ASN.1 encoding (from an existing message-type instance) and decoding (from an encoded message into a message class instance (eg: a Biblio::ILL::ISO::Request)).

Treat this class as if it were completely virtual - a program should never instantiate Biblio::ILL::ISO::ISO, but rather the various derived classes (eg: Biblio::ILL:ISO::Request).

=head1 EXPORT

None.

=head1 ERROR HANDLING

Each of the underlying ISO 10161 ASN.1 types (eg: ILLString, SystemId) from which this class is derived is very picky about accepting the correct data, and will blow up quite spectacularly if you aren't nice to it.

=cut

# When I've got this figured out, add it to the ISA list
# Biblio::ILL::ISO::Extension

# Currently unsupported:
#Biblio::ILL::ISO::DamagedDetails

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype
		  Biblio::ILL::ISO::AccountNumber
		  Biblio::ILL::ISO::AlreadyForwarded
		  Biblio::ILL::ISO::AlreadyTriedListType
		  Biblio::ILL::ISO::Amount
		  Biblio::ILL::ISO::AmountString
		  Biblio::ILL::ISO::ClientId
		  Biblio::ILL::ISO::CostInfoType
		  Biblio::ILL::ISO::ConditionalResults
		  Biblio::ILL::ISO::CurrentState
		  Biblio::ILL::ISO::DateDue
		  Biblio::ILL::ISO::DateTime
		  Biblio::ILL::ISO::DeliveryAddress
		  Biblio::ILL::ISO::DeliveryService
		  Biblio::ILL::ISO::EDeliveryDetails
		  Biblio::ILL::ISO::ElectronicDeliveryService
		  Biblio::ILL::ISO::ElectronicDeliveryServiceSequence
		  Biblio::ILL::ISO::ENUMERATED
		  Biblio::ILL::ISO::ErrorReport
		  Biblio::ILL::ISO::EstimateResults
		  Biblio::ILL::ISO::ExpiryFlag
		  Biblio::ILL::ISO::Flag
		  Biblio::ILL::ISO::GeneralProblem
		  Biblio::ILL::ISO::HistoryReport
		  Biblio::ILL::ISO::HoldPlacedResults
		  Biblio::ILL::ISO::ILLAPDUtype
		  Biblio::ILL::ISO::ILLServiceType
		  Biblio::ILL::ISO::ILLServiceTypeSequence
		  Biblio::ILL::ISO::ILLString
		  Biblio::ILL::ISO::IntermediaryProblem
		  Biblio::ILL::ISO::ISODate
		  Biblio::ILL::ISO::ISOTime
		  Biblio::ILL::ISO::ItemId
		  Biblio::ILL::ISO::ItemType
		  Biblio::ILL::ISO::LocationInfo
		  Biblio::ILL::ISO::LocationInfoSequence
		  Biblio::ILL::ISO::LocationsResults
		  Biblio::ILL::ISO::MediumType
		  Biblio::ILL::ISO::MostRecentService
		  Biblio::ILL::ISO::NameOfPersonOrInstitution
		  Biblio::ILL::ISO::PersonOrInstitutionSymbol
		  Biblio::ILL::ISO::PlaceOnHoldType
		  Biblio::ILL::ISO::PostalAddress
		  Biblio::ILL::ISO::Preference
		  Biblio::ILL::ISO::ProtocolVersionNum
		  Biblio::ILL::ISO::ProviderErrorReport
		  Biblio::ILL::ISO::ReasonLocsProvided
		  Biblio::ILL::ISO::ReasonNoReport
		  Biblio::ILL::ISO::ReasonUnfilled
		  Biblio::ILL::ISO::ReasonWillSupply
		  Biblio::ILL::ISO::ReportSource
		  Biblio::ILL::ISO::RequesterCHECKEDIN
		  Biblio::ILL::ISO::RequesterOptionalMessageType
		  Biblio::ILL::ISO::RequesterSHIPPED
		  Biblio::ILL::ISO::ResponderOptionalMessageType
		  Biblio::ILL::ISO::ResponderRECEIVED
		  Biblio::ILL::ISO::ResponderRETURNED
		  Biblio::ILL::ISO::ResultsExplanation
		  Biblio::ILL::ISO::RetryResults
		  Biblio::ILL::ISO::SearchType
		  Biblio::ILL::ISO::SecurityProblem
		  Biblio::ILL::ISO::SendToListType
		  Biblio::ILL::ISO::SendToListTypeSequence
		  Biblio::ILL::ISO::SEQUENCE_OF
		  Biblio::ILL::ISO::ServiceDateTime
		  Biblio::ILL::ISO::ShippedConditions
		  Biblio::ILL::ISO::ShippedServiceType
		  Biblio::ILL::ISO::ShippedVia
		  Biblio::ILL::ISO::StateTransitionProhibited
		  Biblio::ILL::ISO::StatusReport
		  Biblio::ILL::ISO::SupplyDetails
		  Biblio::ILL::ISO::SupplyMediumInfoType
		  Biblio::ILL::ISO::SupplyMediumInfoTypeSequence
		  Biblio::ILL::ISO::SupplyMediumType
		  Biblio::ILL::ISO::SystemAddress
		  Biblio::ILL::ISO::SystemId
		  Biblio::ILL::ISO::ThirdPartyInfoType
		  Biblio::ILL::ISO::TransactionId
		  Biblio::ILL::ISO::TransactionIdProblem
		  Biblio::ILL::ISO::TransactionResults
		  Biblio::ILL::ISO::TransactionType
		  Biblio::ILL::ISO::TransportationMode
		  Biblio::ILL::ISO::UnableToPerform
		  Biblio::ILL::ISO::UnfilledResults
		  Biblio::ILL::ISO::UnitsPerMediumType
		  Biblio::ILL::ISO::UserErrorReport
		  Biblio::ILL::ISO::WillSupplyResults
		  );
  }


# No sense re-preparing all the time....
our $_asn_initialized = 0;
our $_asn = "";



#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub _init {
    print "---------------\nInitializing\n";
    print "    Creating ASN1 object for extension....";
    my $asn_ext = Convert::ASN1->new;
    print "ok\n";
    print "    Preparing extension 1_0_10161_13_3....";
    $asn_ext->prepare( $Biblio::ILL::ISO::1_0_10161_13_3::desc );
    if ($asn_ext->error()) {
	print "\n" . $asn_ext->error(); 
	exit(1);
    }
    print "ok\n";

    print "    Creating ASN1 object....";
    $_asn = Convert::ASN1->new;
    print "ok\n";
    print "    Preparing ASN1....";
    $_asn->prepare( $Biblio::ILL::ISO::asn::desc );
    if ($_asn->error()) {
	print "\n" . $_asn->error(); 
	exit(1);
    }
    print "ok\n";

    #print "\n-- asn desc ------\n" . $Biblio::ILL::ISO::asn::desc . "\n-- end asn desc ------\n";

    #print "\n\n\n-- Dumping ASN1 -------\n";
    #$_asn->asn_hexdump();
    #print "\n-- End Dump of ASN1 -------\n\n";

    $_asn_initialized = 1;

    print "    Registering extension(s)....";
    # This is what is *should* be:
    #$_asn->registeroid("1.0.10161.13.3",$asn_ext->find("APDU-Delivery-Info"));
    # This is what it *is* (in the test record from Simon Fraser University):
    $_asn->registeroid("1",$asn_ext->find("APDU-Delivery-Info"));
    print "ok\n---------------\n";

}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub new {
    my $class = shift;
    my $self = {};

    &_init() if (not $_asn_initialized);
    $self->{"ASN_TYPE"} = "This is a base class";
    bless($self, ref($class) || $class);
    return ($self);
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub encode {
    my $self = shift;

    my $href = $self->as_asn();

    # Debugging:
    # Verify that this is a 'Convert::ASN1' thingy
    #print ">>>>>>>>> " . ref($_asn) . "<<<<<<<<<<\n";

    #my $asn = $_asn->find( 'ILL-Request' ) or warn $_asn->error;
    #my $asn = $_asn->find( 'ILL-Answer' ) or warn $_asn->error;
    my $asn = $_asn->find( $self->{"ASN_TYPE"} ) or warn $_asn->error;

    print STDERR "\nNo asn?\n" unless (defined $asn);

    #print "-=-=-=-=-=-=-=-\n";
    #print $self->debug($href);
    #print "-=-=-=-=-=-=-=-\n";

    my $pdu = $asn->encode( $href ) or warn $asn->error;

    return $pdu;
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub decode {
    my $self = shift;
    my $pdu = shift;

    my $asn = $_asn->find( $self->{"ASN_TYPE"} ) or warn $_asn->error;

    # The big question:
    # How, during the decode of a PDU that contains an Extension,
    # do we tell it to start using that extension's ASN.1 definition?
    my $href = $asn->decode( $pdu ) or warn $asn->error;

    return $href;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub as_pretty_string {
    my $self = shift;

    print "--base class (ISO)--\n";

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub write {
    my $self = shift;
    my $fname = shift;

    my $pdu = $self->encode();
    if (open(OUTFILE,"> $fname")) {
	print OUTFILE $pdu;
	close OUTFILE;
    }
    return $pdu;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub read {
    my $self = shift;
    my $fname = shift;
    my $debug_flag = shift;

    # must undefine $INPUT_RECORD_SEPARATOR to slurp entire file
    local $/;  

    if (open(INFILE, "< $fname")) {
	my $pdu = <INFILE>;
	close INFILE;

	my $asn = $_asn->find( $self->{"ASN_TYPE"} ) 
	    or warn $_asn->error;

	if (defined $debug_flag) {
	    if ($debug_flag == 1) {
		$asn->dump();
	    } else {
		$asn->hexdump();
	    }
	}

	my $out = $asn->decode( $pdu ) or warn $asn->error;

	## This is all from the "old" way....
	##
	#print $out->{"requester-note"}{"generalstring"} . "\n";
	#debug_print($out->{"requester-note"});
	##
	# How can I have the call be $obj->read("filename"), and have the
	# read-in data replace the existing data?
	##
	# doesn't work
	# $self = $out;
	##
	# This is a pain
 	# $self->protocol_version_num( $out->{"protocol-version-num"} );
 	# $self->transaction_id( $out->{"transaction-id"} );
        #     :
        #     :
	##
        # This works if the call is like $obj = $obj->read("filename")
	#return $self->new(%$out);
	##

	return $out;

    } else {
	croak "$!";
    }
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub debug {
    my $self = shift;
    my $ref = shift;

    $ref = $self unless ($ref);

    return _debug_print($ref);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub _debug_print {
#    my $self = shift;
    my ($ref, $indent) = @_;
    my $s = "";
    $indent = 0 if (not defined($indent));

#    return _debug_print_hash($self) if (not defined $ref);

    return _debug_print_hash($ref, $indent) if (ref($ref) eq "HASH");
    return _debug_print_array($ref, $indent) if (ref($ref) eq "ARRAY");

    for ($i=0; $i < $indent; $i++) {
	$s .= " ";
    }

    return ("$s$ref\n") if (not ref($ref));

    # If it's not any of the above, it is (should be?) an object,
    # which we treat as a hash.  Cheezy, I know - I can't think
    # of a better way.
    return _debug_print_hash($ref, $indent);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub _debug_print_hash {
    my ($href, $indent) = @_;
    my $s = "";
    $indent = 0 if (not defined($indent));

    foreach $key (sort keys %$href) {
	# There's got to be a better way :-)
	for ($i=0; $i < $indent; $i++) {
	    $s .= " ";
	}

	$s .= "$key ";
	$s .= "=>\n" unless (ref($href->{$key}) eq "HASH");
	$s .= "\n" if (ref($href->{$key}) eq "HASH");
	$s .= "\n" if (ref($href->{$key}) eq "ARRAY");
	$s .= _debug_print($href->{$key}, $indent+4);
    }
    return $s;
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub _debug_print_array {
    my ($aref, $indent) = @_;
    my $s = "";
    $indent = 0 if (not defined($indent));

    foreach $elm (@$aref) {
	# There's got to be a better way :-)
	for ($i=0; $i < $indent; $i++) {
	    $s .= " ";
	    #print "."; # DC - debugging
	}
	#print "\n"; # DC - debugging
	$s .= _debug_print($elm, $indent+4);
    }
    return $s;
}

1;
