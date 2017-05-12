package Biblio::ILL::ISO::SystemAddress;

=head1 NAME

Biblio::ILL::ISO::SystemAddress

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ILLString;

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

Biblio::ILL::ISO::SystemAddress is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ILLString

=head1 USED IN

 Biblio::ILL::ISO::AlreadyForwarded
 Biblio::ILL::ISO::DeliveryAddress
 Biblio::ILL::ISO::EDeliveryDetails
 Biblio::ILL::ISO::LocationInfo
 Biblio::ILL::ISO::SendToListType
 Biblio::ILL::ISO::ThirdPartyInfoType

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 System-Address ::= SEQUENCE {
	telecom-service-identifier	[0]	ILL-String OPTIONAL,
	telecom-service-address	        [1]	ILL-String OPTIONAL
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $telecom_service_identifier, $telecom_service_address )

 Creates a new SystemAddress object. 
 Expects a telecom-service-identifier (Biblio::ILL::ISO::ILLString), and
 a telecom-service-address (Biblio::ILL::ISO::ILLString). 

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) { 
	my ($id, $addr) = @_;
	$self->{"telecom-service-identifier"} = new Biblio::ILL::ISO::ILLString($id); 
	$self->{"telecom-service-address"} = new Biblio::ILL::ISO::ILLString($addr); 
    }
    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_id( $telecom_service_identifier )

 Sets the object's telecom-service-identifier.
 Expects a valid Biblio::ILL::ISO::ILLString.

=cut
sub set_id {
    my $self = shift;
    my ($s) = @_;

    $self->{"telecom-service-identifier"} = new Biblio::ILL::ISO::ILLString($s);
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_address( $telecom_service_address )

 Sets the object's telecom-service-address.
 Expects a valid Biblio::ILL::ISO::ILLString.

=cut
sub set_address {
    my $self = shift;
    my ($s) = @_;

    $self->{"telecom-service-address"} = new Biblio::ILL::ISO::ILLString($s);
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

	if (($k =~ /^telecom-service-identifier$/)
	    || ($k =~ /^telecom-service-address$/)
	    ) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString();
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
