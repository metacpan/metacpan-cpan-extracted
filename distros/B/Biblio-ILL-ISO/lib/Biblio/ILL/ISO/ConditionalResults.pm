package Biblio::ILL::ISO::ConditionalResults;

=head1 NAME

Biblio::ILL::ISO::ConditionalResults

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ConditionalResultsCondition;
use Biblio::ILL::ISO::ISODate;
use Biblio::ILL::ISO::LocationInfoSequence;
use Biblio::ILL::ISO::DeliveryService;
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

Biblio::ILL::ISO::ConditionalResults is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ConditionalResultsCondition
 Biblio::ILL::ISO::ISODate
 Biblio::ILL::ISO::LocationInfoSequence
 Biblio::ILL::ISO::DeliveryService

=head1 USED IN

 Biblio::ILL::ISO::ResultsExplanation

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Conditional-Results ::= EXPLICIT SEQUENCE {
	conditions	[0]	IMPLICIT ENUMERATED {
                                   cost-exceeds-limit 				(13),
				    charges 					(14),
				    prepayment-required 			(15),
				    lacks-copyright-compliance 			(16),
				    library-use-only 				(22),
				    no-reproduction 				(23),
				    client-signature-required 			(24),
				    special-collections-supervision-required	(25),
				    other 					(27),
				    responder-specific 				(28),
				    proposed-delivery-service 			(30) 
				    },
	date-for-reply	[1]	IMPLICIT ISO-Date OPTIONAL,
	locations	[2]	IMPLICIT SEQUENCE OF Location-Info OPTIONAL,
	proposed-delivery-service		Delivery-Service OPTIONAL
		-- this parameter specifies a proposed delivery service the
		-- acceptance of which is a condition of supply.  It may be a
		-- physical service or an electronic service.  This parameter
		-- may only be present in APDUs with a 
		-- protocol-version-num value of 2 or greater
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $condition [,$replydate] [,$locations] [,proposed_delivery_service] )

 Creates a new ConditionalResults object. 
 Expects a condition (Biblio::ILL::ISO::ConditionalResultsCondition),
 (optionally) a date for reply (Biblio::ILL::ISO::ISODate), 
 (optionally) a location sequence (Biblio::ILL::ISO::LocationInfoSequence), and 
 (optionally) a proposed delivery service (Biblio::ILL::ISO::DeliveryService).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($condition, $replydate, $locations, $proposed_delivery_service) = @_;

	croak "missing conditional-result condition" unless ($condition);
	croak "invalid conditional-result condition" unless (ref($condition) eq "Biblio::ILL::ISO::ConditionalResultsCondition");

	if ($replydate) {
	    croak "invalid date-for-reply" unless (ref($replydate) eq "Biblio::ILL::ISO::ISODate");
	}
	if ($locations) {
	    croak "invalid locations" unless (ref($locations) eq "Biblio::ILL::ISO::LocationInfoSequence");
	}
	if ($proposed_delivery_service) {
	    croak "invalid proposed-delivery-service" unless (ref($proposed_delivery_service) eq "Biblio::ILL::ISO::DeliveryService");
	}
	
	$self->{"conditions"} = $condition;
	$self->{"date-for-reply"} = $replydate if ($replydate);
	$self->{"locations"} = $locations if ($locations);;
	$self->{"proposed-delivery-service"} = $proposed_delivery_service if ($proposed_delivery_service);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $condition [,$replydate] [,$locations] [,proposed_delivery_service] )

Sets the object's conditional-result (Biblio::ILL::ISO::ConditionalResultsCondition),
 (optionally) date-for-reply (Biblio::ILL::ISO::ISODate), 
 (optionally) locations (Biblio::ILL::ISO::LocationInfoSequence), and 
 (optionally) a proposed-delivery-service (Biblio::ILL::ISO::DeliveryService).

=cut
sub set {
    my $self = shift;

    my ($condition, $replydate, $locations, $proposed_delivery_service) = @_;

    croak "missing conditional-result condition" unless ($condition);
    croak "invalid conditional-result condition" unless (ref($condition) eq "Biblio::ILL::ISO::ConditionalResultsCondition");
    
    if ($replydate) {
	croak "invalid date-for-reply" unless (ref($replydate) eq "Biblio::ILL::ISO::ISODate");
    }
    if ($locations) {
	croak "invalid locations" unless (ref($locations) eq "Biblio::ILL::ISO::LocationInfoSequence");
    }
    if ($proposed_delivery_service) {
	croak "invalid proposed-delivery-service" unless (ref($proposed_delivery_service) eq "Biblio::ILL::ISO::DeliveryService");
    }
    
    $self->{"conditions"} = $condition;
    $self->{"date-for-reply"} = $replydate if ($replydate);
    $self->{"locations"} = $locations if ($locations);;
    $self->{"proposed-delivery-service"} = $proposed_delivery_service if ($proposed_delivery_service);
    
    return;
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
	#print ref($self) . "...$k\n";

	if ($k =~ /^conditions$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ConditionalResultsCondition();
	    $self->{$k}->from_asn($href->{$k});
	
	} elsif ($k =~ /^date-for-reply$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ISODate();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^locations$/) {
	    $self->{$k} = new Biblio::ILL::ISO::LocationInfoSequence();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^proposed-delivery-service$/) {
	    $self->{$k} = new Biblio::ILL::ISO::DeliveryService();
	    $self->{$k}->from_asn($href->{$k});

	} else {
	    croak "invalid " . ref($self) . " element: [$k]";
	}

    }
    return $self;
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
