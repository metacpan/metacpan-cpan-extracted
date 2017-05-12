package Biblio::ILL::ISO::ThirdPartyInfoType;

=head1 NAME

Biblio::ILL::ISO::ThirdPartyInfoType

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::SystemAddress;
use Biblio::ILL::ISO::Preference;
use Biblio::ILL::ISO::SendToListTypeSequence;
use Biblio::ILL::ISO::AlreadyTriedListType;

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

Biblio::ILL::ISO::ThirdPartyInfoType is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::SystemAddress
 Biblio::ILL::ISO::Preference
 Biblio::ILL::ISO::SendToListTypeSequence
 Biblio::ILL::ISO::AlreadyTriedListType

=head1 USED IN

 Biblio::ILL::ISO::Request

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Third-Party-Info-Type ::= SEQUENCE {
	permission-to-forward	[0]	IMPLICIT BOOLEAN, -- DEFAULT FALSE,
	permission-to-chain	[1]	IMPLICIT BOOLEAN, -- DEFAULT FALSE,
	permission-to-partition 	[2]	IMPLICIT BOOLEAN, -- DEFAULT FALSE,
	permission-to-change-send-to-list [3]	IMPLICIT BOOLEAN, -- DEFAULT FALSE,
	initial-requester-address 	[4]	IMPLICIT System-Address OPTIONAL,
		-- mandatory when initiating a FORWARD service or an
		-- ILL-REQUEST service for a partitioned ILL
		-- sub-transaction; optional otherwise
	preference	[5]	IMPLICIT ENUMERATED {
				ordered	(1),
				unordered	(2)
				} -- DEFAULT 2,
	send-to-list	[6]	IMPLICIT Send-To-List-Type OPTIONAL,
	already-tried-list	[7]	IMPLICIT Already-Tried-List-Type OPTIONAL
		-- mandatory when initiating a FORWARD service, or when
		-- initiating an ILL-REQUEST service for an ILL
		-- sub-transaction if the received ILL-REQUEST included an
		-- "already-tried-list"; optional otherwise
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $forward, $chain, $partition, $change, $pref [,$refrequester [,$refsendto [,$refalreadytried]]]] )

 Creates a new ThirdPartyInfoType object. 
 Expects a can-forward flag ( 0|1 ),
 a can-chain flag ( 0|1 ),
 a can-partition flag ( 0|1 ),
 a can-change flag ( 0|1 ),
 a preference for ordered or unordered (Biblio::ILL::ISO::Preference),
 (optionally) an initial-requester address (Biblio::ILL::ISO::SystemAddress), 
 (optionally) a send-to list (Biblio::ILL::ISO::SendToListTypeSequence), and 
 (optionally) an already-tried list (Biblio::ILL::ISO::AlreadyTriedListType).

=cut
sub new {
    my $class = shift;
    my $self = {};

    my ($forward, $chain, $partition, $change, $pref,
	$refrequester, $refsendto, $refalreadytried) = @_;
    
    $forward   = 0 unless ($forward);
    $chain     = 0 unless ($chain);
    $partition = 0 unless ($partition);
    $change    = 0 unless ($change);
    $pref = "unordered" unless ($pref);
    if ($refrequester) {
	croak "invalid initial-requester-address" unless (ref($refrequester) eq "Biblio::ILL::ISO::SystemAddress");
    }
    if ($refsendto) {
	croak "invalid send-to-list" unless (ref($refsendto) eq "Biblio::ILL::ISO::SendToListTypeSequence");
    }
    if ($refalreadytried) {
	croak "invalid already-tried-list" unless (ref($refalreadytried) eq "Biblio::ILL::ISO::AlreadyTriedListType");
    }
    
    $self->{"permission-to-forward"} = $forward;
    $self->{"permission-to-chain"} = $chain;
    $self->{"permission-to-partition"} = $partition;
    $self->{"permission-to-change-send-to-list"} = $change;
    $self->{"preference"} = new Biblio::ILL::ISO::Preference($pref);
    $self->{"initial-requester-address"} = $refrequester if ($refrequester);
    $self->{"send-to-list"} = $refsendto if ($refsendto);
    $self->{"already-tried-list"} = $refalreadytried if ($refalreadytried);

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $forward, $chain, $partition, $change, $pref [,$refrequester [,$refsendto [,$refalreadytried]]]] )

 Sets the object's forward flag ( 0|1 ),
 can-chain flag ( 0|1 ),
 can-partition flag ( 0|1 ),
 can-change flag ( 0|1 ),
 preference for ordered or unordered (Biblio::ILL::ISO::Preference),
 (optionally) initial-requester address (Biblio::ILL::ISO::SystemAddress), 
 (optionally) send-to list (Biblio::ILL::ISO::SendToListTypeSequence), and 
 (optionally) already-tried list (Biblio::ILL::ISO::AlreadyTriedListType).

=cut
sub set {
    my $self = shift;
    my ($forward, $chain, $partition, $change, $pref,
	$refrequester, $refsendto, $refalreadytried) = @_;
    
    $forward = 0 unless ($forward);
    $chain   = 0 unless ($chain);
    $partition = 0 unless ($partition);
    $pref = new Biblio::ILL::ISO::Preference("unordered") unless ($pref);
    if ($refrequester) {
	croak "invalid initial-requester-address" unless (ref($refrequester) eq "Biblio::ILL::ISO::SystemAddress");
    }
    if ($refsendto) {
	croak "invalid send-to-list" unless (ref($refsendto) eq "Biblio::ILL::ISO::SendToListTypeSequence");
    }
    if ($refalreadytried) {
	croak "invalid already-tried-list" unless (ref($refalreadytried) eq "Biblio::ILL::ISO::AlreadyTriedListType");
    }
    
    $self->{"permission-to-forward"} = $forward;
    $self->{"permission-to-chain"} = $chain;
    $self->{"permission-to-partition"} = $partition;
    $self->{"permission-to-change-send-to-list"} = $change;
    $self->{"preference"} = new Biblio::ILL::ISO::Preference($pref);
    $self->{"initial-requester-address"} = $refrequester if ($refrequester);
    $self->{"send-to-list"} = $refsendto if ($refsendto);
    $self->{"already-tried-list"} = $refalreadytried if ($refalreadytried);
    
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

	if (($k =~ /^permission-to-forward$/)
	    || ($k =~ /^permission-to-chain$/)
	    || ($k =~ /^permission-to-partition$/)
	    || ($k =~ /^permission-to-change-send-to-list$/)
	    ) {
	    $self->{$k} = $href->{$k};

	} elsif ($k =~ /^initial-requester-address$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SystemAddress();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^preference$/) {
	    $self->{$k} = new Biblio::ILL::ISO::Preference();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^send-to-list$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SendToListTypeSequence();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^already-tried-list$/) {
	    $self->{$k} = new Biblio::ILL::ISO::AlreadyTriedListType();
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
