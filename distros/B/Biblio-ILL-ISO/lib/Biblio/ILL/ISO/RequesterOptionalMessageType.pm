package Biblio::ILL::ISO::RequesterOptionalMessageType;

=head1 NAME

Biblio::ILL::ISO::RequesterOptionalMessageType

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::RequesterSHIPPED;
use Biblio::ILL::ISO::RequesterCHECKEDIN;

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

Biblio::ILL::ISO::RequesterOptionalMessageType is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::RequesterSHIPPED
 Biblio::ILL::ISO::RequesterCHECKEDIN

=head1 USED IN

 Biblio::ILL::ISO::Request

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Requester-Optional-Messages-Type ::= SEQUENCE {
	can-send-RECEIVED	[0]	IMPLICIT BOOLEAN,
	can-send-RETURNED	[1]	IMPLICIT BOOLEAN,
	requester-SHIPPED	[2]	IMPLICIT ENUMERATED {
				requires	(1),
				desires 	(2),
				neither	(3)
				}
	requester-CHECKED-IN	[3]	IMPLICIT ENUMERATED {
				requires 	(1),
				desires 	(2),
				neither 	(3)
				}
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $can_send_received, $can_send_shipped, $requester_shipped, $requester_checked_in )

 Creates a new RequesterOptionalMessageType object. 
 Expects a can-send-RECEIVED flag ( 0|1 ),
 a can-send-RETURNED flag ( 0|1 ), 
 a requester-SHIPPED string (a valid Biblio::ILL::ISO::RequesterSHIPPED enumerated value), and 
 a requester-CHECKED-IN string (a valid Biblio::ILL::ISO::RequesterCHECKEDIN enumerated value).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($brec, $bret, $sshipped, $scheckedin) = @_;
	
	croak "missing RequesterOptionalMessageType parameter can-send-RECEIVED" unless $brec;
	croak "missing RequesterOptionalMessageType parameter can-send-RETURNED" unless $bret;
	croak "missing RequesterOptionalMessageType parameter requester-SHIPPED" unless $sshipped;
	croak "missing RequesterOptionalMessageType parameter requester-CHECKED-IN" unless $scheckedin;

	$self->{"can-send-RECEIVED"} = $brec;
	$self->{"can-send-RETURNED"} = $bret;
	$self->{"requester-SHIPPED"} = new Biblio::ILL::ISO::RequesterSHIPPED($sshipped);
	$self->{"requester-CHECKED-IN"} = new Biblio::ILL::ISO::RequesterCHECKEDIN($scheckedin);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $can_send_received, $can_send_shipped, $requester_shipped, $requester_checked_in )

 Sets the object's can-send-RECEIVED flag ( 0|1 ),
 can-send-RETURNED flag ( 0|1 ), 
 requester-SHIPPED string (a valid Biblio::ILL::ISO::RequesterSHIPPED enumerated value), and 
 requester-CHECKED-IN string (a valid Biblio::ILL::ISO::RequesterCHECKEDIN enumerated value).

=cut
sub set {
    my $self = shift;
    my ($brec, $bret, $sshipped, $scheckedin) = @_;
    
    croak "missing RequesterOptionalMessageType parameter can-send-RECEIVED" unless $brec;
    croak "missing RequesterOptionalMessageType parameter can-send-RETURNED" unless $bret;
    croak "missing RequesterOptionalMessageType parameter requester-SHIPPED" unless $sshipped;
    croak "missing RequesterOptionalMessageType parameter requester-CHECKED-IN" unless $scheckedin;
    
    $self->{"can-send-RECEIVED"} = $brec;
    $self->{"can-send-RETURNED"} = $bret;
    $self->{"requester-SHIPPED"} = new Biblio::ILL::ISO::RequesterSHIPPED($sshipped);
    $self->{"requester-CHECKED-IN"} = new Biblio::ILL::ISO::RequesterCHECKEDIN($scheckedin);

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

	if (($k =~ /^can-send-RECEIVED$/)
	    || ($k =~ /^can-send-RETURNED$/)
	    ) {
	    $self->{$k} = $href->{$k};

	} elsif ($k =~ /^requester-SHIPPED$/) {
	    $self->{$k} = new Biblio::ILL::ISO::RequesterSHIPPED();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^requester-CHECKED-IN$/) {
	    $self->{$k} = new Biblio::ILL::ISO::RequesterCHECKEDIN();
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
