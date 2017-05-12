package Biblio::ILL::ISO::LocationInfo;

=head1 NAME

Biblio::ILL::ISO::LocationInfo

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::SystemId;
use Biblio::ILL::ISO::SystemAddress;
use Biblio::ILL::ISO::ILLString;

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

Biblio::ILL::ISO::LocationInfo is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::SystemId;
 Biblio::ILL::ISO::SystemAddress;
 Biblio::ILL::ISO::ILLString;

=head1 USED IN

 Biblio::ILL::ISO::LocationInfoSequence

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Location-Info ::= EXPLICIT SEQUENCE {
	location-id	[0]	IMPLICIT System-Id,
	location-address	[1]	IMPLICIT System-Address OPTIONAL,
	location-note	[2]	ILL-String OPTIONAL
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $loc_id [,$loc_addr] [,$note] )

Creates a new LocationInfo object. 
 Expects a location-id (Biblio::ILL::ISO::SystemId),
 (optionally) a location-address (Biblio::ILL::ISO::SystemAddress), and
 (optionally) a location-note (Biblio::ILL::ISO::ILLString).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($locid, $locaddr, $locnote) = @_;

	croak "invalid location-id" unless (ref($locid) eq "Biblio::ILL::ISO::SystemId");
	if ($locaddr) {
	    croak "invalid location-address" unless (ref($locaddr) eq "Biblio::ILL::ISO::SystemAddress");
	}
	if ($locnote) {
	    croak "invalid location-note" unless (ref($locnote) eq "Biblio::ILL::ISO::ILLString");
	}
	
	$self->{"location-id"} = $locid;
	$self->{"location-address"} = $locaddr if ($locaddr);
	$self->{"location-note"} = $locnote if ($locnote);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $loc_id [,$loc_addr] [,$note] )

 Sets the object's location-id, location-address, and note.
 Expects a location-id (Biblio::ILL::ISO::SystemId),
 (optionally) a location-address (Biblio::ILL::ISO::SystemAddress), and
 (optionally) a location-note (Biblio::ILL::ISO::ILLString).

=cut
sub set {
    my $self = shift;

    my ($locid, $locaddr, $locnote) = @_;

    croak "invalid location-id" unless (ref($locid) eq "Biblio::ILL::ISO::SystemId");
    if ($locaddr) {
	croak "invalid location-address" unless (ref($locaddr) eq "Biblio::ILL::ISO::SystemAddress");
    }
    if ($locnote) {
	croak "invalid location-note" unless (ref($locnote) eq "Biblio::ILL::ISO::ILLString");
    }
	
    $self->{"location-id"} = $locid;
    $self->{"location-address"} = $locaddr if ($locaddr);
    $self->{"location-note"} = $locnote if ($locnote);

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

	if ($k =~ /^location-id$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SystemId();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^location-address$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SystemAddress();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^location-note$/) {
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
