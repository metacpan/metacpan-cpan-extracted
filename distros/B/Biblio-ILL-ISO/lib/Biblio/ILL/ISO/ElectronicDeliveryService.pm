package Biblio::ILL::ISO::ElectronicDeliveryService;

=head1 NAME

Biblio::ILL::ISO::ElectronicDeliveryService

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::EDeliveryDetails;
use Biblio::ILL::ISO::ILLString;
use Biblio::ILL::ISO::ISOTime;

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

Biblio::ILL::ISO::ElectronicDeliveryService is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::EDeliveryDetails
 Biblio::ILL::ISO::ISOTime
 Biblio::ILL::ISO::ILLString
 Biblio::ILL::ISO::DeliveryService

=head1 USED IN

 Biblio::ILL::ISO::ResultsExplanation

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 #
 # WARNING!  Document-Type is not implemented...
 #

 Electronic-Delivery-Service ::= EXPLICIT SEQUENCE {
	-- the first four parameters are intended to be used in an automated
	-- environment
		e-delivery-service	[0] IMPLICIT E-Delivery-Service OPTIONAL,
		document-type		[1] IMPLICIT Document-Type OPTIONAL,
		e-delivery-description		[4] ILL-String OPTIONAL,
		-- holds a human readable name or description of the
		-- required electronic delivery service and document type;
		-- this may also be used to identify an electronic delivery
		-- service for which there is no object identifier.
		-- This parameter may be present instead of, or in addition
		-- to, the previous 4 parameters
		e-delivery-details		[5] CHOICE {
			e-delivery-address	[0] IMPLICIT System-Address,
			e-delivery-id		[1] IMPLICIT System-Id
			}
		name-or-code		[6] ILL-String OPTIONAL,
		-- holds a human-readable identifier or correlation
		-- information for the document as shipped, e.g. a directory 
		-- and/or file name or message-id
		delivery-time		[7] IMPLICIT ISO-Time OPTIONAL
		-- holds the requester's preferred delivery time or
		-- the responder's proposed or actual delivery time
		}

=cut

=head1 METHODS

=cut
#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [$e_delivery_details] )

Creates a new ElectronicDeliveryService object. 
 Expects either no paramaters or 
 an e-delivery-details (Biblio::ILL::ISO::EDeliveryDetails).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	# if there's anything, it's the one mandatory field....
	my $objref = shift;
	
	if (ref($objref) eq "Biblio::ILL::ISO::EDeliveryDetails") {
	    $self->{"e-delivery-details"} = $objref;
	} else {
	    croak "Invalid e-delivery-details";
	}
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 from_asn($href)

Given a properly formatted hash, builds the object.

=cut
sub from_asn {
    my $self = shift;
    my $href = shift;

    foreach my $k (keys %$href) {
	print ref($self) . "...$k\n";

	if (($k =~ /^e-delivery-description$/)
	    || ($k =~ /^name-or-code$/)
	    ) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^e-delivery-details$/) {
	    $self->{$k} = new Biblio::ILL::ISO::EDeliveryDetails();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^delivery-time$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ISOTime();
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

=head2 set_description($s)

 Sets the object's e-delivery-description.
 Expects a text string.

=cut
sub set_description {
    my $self = shift;
    my ($s) = @_;

    $self->{"e-delivery-description"} = new Biblio::ILL::ISO::ILLString($s);
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_details($e_delivery_details)

 Sets the object's e-delivery-details.
 Expects a valid Biblio::ILL::ISO::EDeliveryDetails.

=cut
sub set_details {
    my $self = shift;
    my $objref = shift;
    
    if (ref($objref) eq "Biblio::ILL::ISO::EDeliveryDetails") {
	$self->{"e-delivery-details"} = $objref;
    } else {
	croak "Invalid e-delivery-details";
    }

    return;
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_name_or_code($s)

 Sets the object's name-or-code.
 Expects a text string.

=cut
sub set_name_or_code {
    my $self = shift;
    my ($s) = @_;

    $self->{"name-or-code"} = new Biblio::ILL::ISO::ILLString($s);
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_delivery_time($s)

 Sets the object's delivery-time.
 Expects a text string in time format (HHMMSS).

=cut
sub set_delivery_time {
    my $self = shift;
    my ($s) = @_;

    $self->{"delivery-time"} = new Biblio::ILL::ISO::ISOTime($s);
    return;
}

=head1 SEE ALSO

See the README for system design notes.
See the parent class(es) for other available methods.

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
