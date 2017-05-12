package Biblio::ILL::ISO::AlreadyForwarded;

=head1 NAME

Biblio::ILL::ISO::AlreadyForwarded

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::SystemId;
use Biblio::ILL::ISO::SystemAddress;

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

Biblio::ILL::ISO::AlreadyForwarded is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::SystemId
 Biblio::ILL::ISO::SystemAddress

=head1 USED IN

 Biblio::ILL::ISO::UserErrorReport

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Already-Forwarded ::= EXPLICIT SEQUENCE {
	responder-id	   [0]	IMPLICIT System-Id,
	responder-address  [1]	IMPLICIT System-Address OPTIONAL
	}	

=cut

=head1 METHODS

=cut
#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new($system_id [, $system_addr])

Creates a new AlreadyForwarded object. Expects either no parameters, or
a valid Biblio::ILL::ISO::SystemId and (optionally) a valid Biblio::ILL::ISO::SystemAddress.

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($id, $addr) = @_;

	croak "invalid responder-id" unless (ref($id) eq "Biblio::ILL::ISO::SystemId");
	if ($addr) {
	    croak "invalid responder-address" unless (ref($addr) eq "Biblio::ILL::ISO::SystemAddress");
	}
	
	$self->{"responder-id"} = $id;
	$self->{"responder-address"} = $addr if ($addr);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set($system_id [, $system_addr])

Sets the object's responder-id (a Biblio::ILL::ISO::SystemId) and (optionally) responder-address
(a Biblio::ILL::ISO::SystemAddress).

=cut
sub set {
    my $self = shift;

    my ($id, $addr) = @_;

    croak "invalid responder-id" unless (ref($id) eq "Biblio::ILL::ISO::SystemId");
    if ($addr) {
	croak "invalid responder-address" unless (ref($addr) eq "Biblio::ILL::ISO::SystemAddress");
    }
	
    $self->{"responder-id"} = $id;
    $self->{"responder-address"} = $addr if ($addr);

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

	if ($k =~ /^responder-id$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SystemId();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^responder-address$/) {
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
