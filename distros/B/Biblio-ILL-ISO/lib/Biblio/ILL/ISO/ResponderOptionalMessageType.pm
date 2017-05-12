package Biblio::ILL::ISO::ResponderOptionalMessageType;

=head1 NAME

Biblio::ILL::ISO::ResponderOptionalMessageType

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ResponderRECEIVED;
use Biblio::ILL::ISO::ResponderRETURNED;

use Carp;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.07.27 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::ResponderOptionalMessageType is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ResponderRECEIVED
 Biblio::ILL::ISO::ResponderRETURNED

=head1 USED IN

 Biblio::ILL::ISO::Answer
 Biblio::ILL::ISO::Shipped

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
# From the ASN
#
#Responder-Optional-Messages-Type ::= EXPLICIT SEQUENCE {
#	can-send-SHIPPED	[0]	IMPLICIT BOOLEAN,
#	can-send-CHECKED-IN	[1]	IMPLICIT BOOLEAN,
#	responder-RECEIVED	[2]	IMPLICIT ENUMERATED {
#				requires 	(1),
#				desires 	(2),
#				neither 	(3)
#				}
#	responder-RETURNED	[3]	IMPLICIT ENUMERATED {
#				requires 	(1),
#				desires 	(2),
#				neither 	(3)
#				}
#	}
#
=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $can_send_shipped, $can_send_checked_in, $responder_received, $responder_returned )

 Creates a new ResponderOptionalMessageType object. 
 Expects a can-send-SHIPPED flag ( 0|1 ),
 a can-send-CHECKED-IN flag ( 0|1 ), 
 a responder-RECEIVED string (a valid Biblio::ILL::ISO::ResponderRECEIVED enumerated value), and 
 a responder-RETURNED string (a valid Biblio::ILL::ISO::ResponderRETURNED enumerated value).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($bshipped, $bcheckedin, $sreceived, $sreturned) = @_;
	
	croak "missing ResponderOptionalMessageType parameter can-send-SHIPPED" unless $bshipped;
	croak "missing ResponderOptionalMessageType parameter can-send-CHECKED-IN" unless $bcheckedin;
	croak "missing ResponderOptionalMessageType parameter responder-RECEIVED" unless $sreceived;
	croak "missing ResponderOptionalMessageType parameter responder-RETURNED" unless $sreturned;

	$self->{"can-send-SHIPPED"} = $bshipped;
	$self->{"can-send-CHECKED-IN"} = $bcheckedin;
	$self->{"responder-RECEIVED"} = new Biblio::ILL::ISO::ResponderRECEIVED($sreceived);
	$self->{"responder-RETURNED"} = new Biblio::ILL::ISO::ResponderRETURNED($sreturned);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $can_send_shipped, $can_send_checked_in, $responder_received, $responder_returned )

 Sets the object's can-send-SHIPPED flag ( 0|1 ),
 can-send-CHECKED-IN flag ( 0|1 ), 
 responder-RECEIVED string (a valid Biblio::ILL::ISO::ResponderRECEIVED enumerated value), and 
 responder-RETURNED string (a valid Biblio::ILL::ISO::ResponderRETURNED enumerated value).

=cut
sub set {
    my $self = shift;
    my ($bshipped, $bcheckedin, $sreceived, $sreturned) = @_;
	
    croak "missing ResponderOptionalMessageType parameter can-send-SHIPPED" unless $bshipped;
    croak "missing ResponderOptionalMessageType parameter can-send-CHECKED-IN" unless $bcheckedin;
    croak "missing ResponderOptionalMessageType parameter responder-RECEIVED" unless $sreceived;
    croak "missing ResponderOptionalMessageType parameter responder-RETURNED" unless $sreturned;

    $self->{"can-send-SHIPPED"} = $bshipped;
    $self->{"can-send-CHECKED-IN"} = $bcheckedin;
    $self->{"responder-RECEIVED"} = new Biblio::ILL::ISO::ResponderRECEIVED($sreceived);
    $self->{"responder-RETURNED"} = new Biblio::ILL::ISO::ResponderRETURNED($sreturned);

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

	if (($k =~ /^can-send-SHIPPED$/)
	    || ($k =~ /^can-send-CHECKED-IN$/)
	    ) {
	    $self->{$k} = $href->{$k};

	} elsif ($k =~ /^responder-RECEIVED$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ResponderRECEIVED();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^responder-RETURNED$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ResponderRETURNED();
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
