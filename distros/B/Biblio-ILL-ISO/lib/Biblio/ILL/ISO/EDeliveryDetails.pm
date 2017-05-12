package Biblio::ILL::ISO::EDeliveryDetails;

=head1 NAME

Biblio::ILL::ISO::EDeliveryDetails

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::SystemAddress;
use Biblio::ILL::ISO::SystemId;

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

Biblio::ILL::ISO::EDeliveryDetails is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::SystemAddress
 Biblio::ILL::ISO::SystemId

=head1 USED IN

 Biblio::ILL::ISO::ElectronicDeliveryService

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION

 (part of Electronic-Delivery-Service)

    e-delivery-details		[5] CHOICE {
	e-delivery-address	[0] IMPLICIT System-Address,
	e-delivery-id		[1] IMPLICIT System-Id
	}

=cut

=head1 METHODS

=cut
#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [$system_address | $system_id] )

Creates a new EDeliveryDetails object. 
 Expects either no parameters, or one of
 e-delivery-address (Biblio::ILL::ISO::SystemAddress), or
 e-delivery-id (Biblio::ILL::ISO::SystemId).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($objref) = @_;

	if (ref($objref) eq "Biblio::ILL::ISO::SystemAddress") {
	    $self->{"e-delivery-address"} = $objref;
	} elsif (ref($objref) eq "Biblio::ILL::ISO::SystemId") {
	    $self->{"e-delivery-id"} = $objref;
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

=head2 set( $system_address | $system_id )

Sets the object's  e-delivery-address (Biblio::ILL::ISO::SystemAddress), or
e-delivery-id (Biblio::ILL::ISO::SystemId).

=cut
sub set {
    my $self = shift;
    my ($objref) = @_;
    
    if (ref($objref) eq "Biblio::ILL::ISO::SystemAddress") {
	$self->{"e-delivery-address"} = $objref;
    } elsif (ref($objref) eq "Biblio::ILL::ISO::SystemId") {
	$self->{"e-delivery-id"} = $objref;
    } else {
	croak "Invalid e-delivery-details";
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
	print ref($self) . "...$k\n";

	if ($k =~ /^e-delivery-address$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SystemAddress();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^e-delivery-id$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SystemId();
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
