package Biblio::ILL::ISO::SendToListType;

=head1 NAME

Biblio::ILL::ISO::SendToListType

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::SystemId;
use Biblio::ILL::ISO::AccountNumber;
use Biblio::ILL::ISO::SystemAddress;

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

Biblio::ILL::ISO::SendToListType is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::SystemId
 Biblio::ILL::ISO::AccountNumber
 Biblio::ILL::ISO::SystemAddress

=head1 USED IN

Each of these uses Biblio::ILL::ISO::SendToListTypeSequence, which is
a sequence of SendToListType:

 Biblio::ILL::ISO::Answer
 Biblio::ILL::ISO::Request
 Biblio::ILL::ISO::ThirdPartyInfoType

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 (see SendToListTypeSequence.pm)

 Send-To-List-Type ::= SEQUENCE OF SEQUENCE {
	system-id	[0]	IMPLICIT System-Id,
	account-number	[1]	Account-Number OPTIONAL,
	system-address	[2]	IMPLICIT System-Address OPTIONAL
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $system_id [,$account_number] [,$system_address] )

Creates a new SendToListType object. 
 Expects a system-id (Biblio::ILL::ISO::SystemId),
 (optionally) an account-number (Biblio::ILL::ISO::AccountNumber), and
 (optionally) a system-address (Biblio::ILL::ISO::SystemAddress)

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($refSystemId, $refAccountNumber, $refSystemAddress) = @_;
	
	croak "missing System-Id" unless $refSystemId;
	croak "invalid System-Id" unless (ref($refSystemId) eq "Biblio::ILL::ISO::SystemId");

	$self->{"system-id"} = $refSystemId;
	$self->{"account-number"} = $refAccountNumber if ($refAccountNumber);
	$self->{"system-address"} = $refSystemAddress if ($refSystemAddress);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $system_id [,$account_number] [,$system_address] )

Sets the object's system-id (Biblio::ILL::ISO::SystemId),
 (optionally) account-number (Biblio::ILL::ISO::AccountNumber), and
 (optionally) system-address (Biblio::ILL::ISO::SystemAddress)

=cut
sub set {
    my $self = shift;
    my ($refSystemId, $refAccountNumber, $refSystemAddress) = @_;
    
    croak "missing System-Id" unless $refSystemId;
    croak "invalid System-Id" unless (ref($refSystemId) eq "Biblio::ILL::ISO::SystemId");
    
    $self->{"system-id"} = $refSystemId;
    $self->{"account-number"} = $refAccountNumber if ($refAccountNumber);
    $self->{"system-address"} = $refSystemAddress if ($refSystemAddress);

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

	if ($k =~ /^system-id$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SystemId();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^account-number$/) {
	    $self->{$k} = new Biblio::ILL::ISO::AccountNumber();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^system-address$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SystemAddress();
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
