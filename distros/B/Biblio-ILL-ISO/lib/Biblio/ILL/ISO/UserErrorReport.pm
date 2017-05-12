package Biblio::ILL::ISO::UserErrorReport;

=head1 NAME

Biblio::ILL::ISO::UserErrorReport

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::AlreadyForwarded;
use Biblio::ILL::ISO::IntermediaryProblem;
use Biblio::ILL::ISO::SecurityProblem;
use Biblio::ILL::ISO::UnableToPerform;

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

Biblio::ILL::ISO::UserErrorReport is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::AlreadyForwarded
 Biblio::ILL::ISO::IntermediaryProblem
 Biblio::ILL::ISO::SecurityProblem
 Biblio::ILL::ISO::UnableToPerform

=head1 USED IN

 Biblio::ILL::ISO::ErrorReport

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 User-Error-Report ::= CHOICE {
	already-forwarded	[0]	IMPLICIT Already-Forwarded,
	intermediary-problem	[1]	IMPLICIT Intermediary-Problem,
	security-problem	[2]	Security-Problem,
	unable-to-perform	[3]	IMPLICIT Unable-To-Perform
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [$objref] )

 Creates a new UserErrorReport object. 
 Expects either no paramaters, or one of:
 already-forwarded (Biblio::ILL::ISO::AlreadyForwarded),
 intermediary-problem (Biblio::ILL::ISO::IntermediaryProblem), 
 security-problem (Biblio::ILL::ISO::SecurityProblem), or 
 unable-to-perform (Biblio::ILL::ISO::UnableToPerform).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($objref) = @_;
	
	if (ref($objref) eq "Biblio::ILL::ISO::AlreadyForwarded") {
	    $self->{"already-forwarded"} = $objref;
	} elsif (ref($objref) eq "Biblio::ILL::ISO::IntermediaryProblem") {
	    $self->{"intermediary-problem"} = $objref;
	} elsif (ref($objref) eq "Biblio::ILL::ISO::SecurityProblem") {
	    $self->{"security-problem"} = $objref;
	} elsif (ref($objref) eq "Biblio::ILL::ISO::UnableToPerform") {
	    $self->{"unable-to-perform"} = $objref;
	} else {
	    croak "Invalid UserErrorReport";
	}
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $objref )

 Sets the object's report type.
 Expects one of:
 already-forwarded (Biblio::ILL::ISO::AlreadyForwarded),
 intermediary-problem (Biblio::ILL::ISO::IntermediaryProblem), 
 security-problem (Biblio::ILL::ISO::SecurityProblem), or 
 unable-to-perform (Biblio::ILL::ISO::UnableToPerform).

=cut
sub set {
    my $self = shift;
    my ($objref) = @_;
    
    if (ref($objref) eq "Biblio::ILL::ISO::AlreadyForwarded") {
	$self->{"already-forwarded"} = $objref;
    } elsif (ref($objref) eq "Biblio::ILL::ISO::IntermediaryProblem") {
	$self->{"intermediary-problem"} = $objref;
    } elsif (ref($objref) eq "Biblio::ILL::ISO::SecurityProblem") {
	$self->{"security-problem"} = $objref;
    } elsif (ref($objref) eq "Biblio::ILL::ISO::UnableToPerform") {
	$self->{"unable-to-perform"} = $objref;
    } else {
	croak "Invalid UserErrorReport";
    }
    
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

	if ($k =~ /^already-forwarded$/) {
	    $self->{$k} = new Biblio::ILL::ISO::AlreadyForwarded();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^intermediary-problem$/) {
	    $self->{$k} = new Biblio::ILL::ISO::IntermediaryProblem();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^security-problem$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SecurityProblem();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^unable-to-perform$/) {
	    $self->{$k} = new Biblio::ILL::ISO::UnableToPerform();
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
