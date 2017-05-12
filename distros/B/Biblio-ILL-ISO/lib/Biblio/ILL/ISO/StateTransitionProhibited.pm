package Biblio::ILL::ISO::StateTransitionProhibited;

=head1 NAME

Biblio::ILL::ISO::StateTransitionProhibited

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ILLAPDUtype;
use Biblio::ILL::ISO::CurrentState;

use Carp;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.08.12 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::StateTransitionProhibited is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ILLAPDUtype
 Biblio::ILL::ISO::CurrentState

=head1 USED IN

 Biblio::ILL::ISO::ProviderErrorReport

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 State-Transition-Prohibited ::= EXPLICIT SEQUENCE {
	aPDU-type	[0]	IMPLICIT ILL-APDU-Type,
	current-state	[1]	IMPLICIT Current-State
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $APDUtype, $current_state )

Creates a new StateTransitionProhibited object. 
 Expects an APDU-type (Biblio::ILL::ISO::ILLAPDUtype), and
 the current state (Biblio::ILL::ISO::CurrentState).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($itype, $cs) = @_;
	
	croak "missing aPDU-type" unless ($itype);
	croak "invalid aPDU-type" unless (ref($itype) eq "Biblio::ILL::ISO::ILLAPDUtype");
	croak "missing current-state" unless ($cs);
	croak "invalid current-state" unless (ref($cs) eq "Biblio::ILL::ISO::CurrentState");

	$self->{"aPDU-type"} = $itype;
	$self->{"current-state"} = $cs;
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $APDUtype, $current_state )

Sets the object's aPDU-type (Biblio::ILL::ISO::ILLAPDUtype), and
 current-state (Biblio::ILL::ISO::CurrentState).

=cut
sub set {
    my $self = shift;
    my ($itype, $cs) = @_;
    
    croak "missing aPDU-type" unless ($itype);
    croak "invalid aPDU-type" unless (ref($itype) eq "Biblio::ILL::ISO::ILLAPDUtype");
    croak "missing current-state" unless ($cs);
    croak "invalid current-state" unless (ref($cs) eq "Biblio::ILL::ISO::CurrentState");
    
    $self->{"aPDU-type"} = $itype;
    $self->{"current-state"} = $cs;
    
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

	if ($k =~ /^aPDU-type$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLAPDUType();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^current-state$/) {
	    $self->{$k} = new Biblio::ILL::ISO::CurrentState();
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
