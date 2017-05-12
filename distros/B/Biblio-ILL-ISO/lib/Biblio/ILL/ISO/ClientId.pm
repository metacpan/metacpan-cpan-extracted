package Biblio::ILL::ISO::ClientId;

=head1 NAME

Biblio::ILL::ISO::ClientId

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

Biblio::ILL::ISO::ClientId is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ILLString

=head1 USED IN

 Biblio::ILL::ISO::Request
 Biblio::ILL::ISO::Shipped

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Client-Id ::= SEQUENCE {
	client-name	        [0]	ILL-String OPTIONAL,
	client-status	        [1]	ILL-String OPTIONAL,
	client-identifier	[2]	ILL-String OPTIONAL
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [ [$name], [$status], [$id] ] )

Creates a new ClientId object. Expects either no parameters, or
1, 2, or 3 text strings.  Pass in empty strings ("") as placeholders.

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($name, $status, $identifier) = @_;
	
	$self->{"client-name"} = new Biblio::ILL::ISO::ILLString($name) if ($name);
	$self->{"client-status"} = new Biblio::ILL::ISO::ILLString($status) if ($status);
	$self->{"client-identifier"} = new Biblio::ILL::ISO::ILLString($identifier) if ($identifier);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set(( [ [$name], [$status], [$id] ] )

Sets the object's client-name, client-status, and/or client-identifier.
Expects 1, 2, or 3 text strings.  Pass in empty strings ("") as placeholders.

=cut
sub set {
    my $self = shift;
    my ($name, $status, $identifier) = @_;
    
    $self->{"client-name"} = new Biblio::ILL::ISO::ILLString($name) if ($name);
    $self->{"client-status"} = new Biblio::ILL::ISO::ILLString($status) if ($status);
    $self->{"client-identifier"} = new Biblio::ILL::ISO::ILLString($identifier) if ($identifier);

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

	if (($k =~ /^client-name$/)
	    || ($k =~ /^client-status$/)
	    || ($k =~ /^client-identifier$/)
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
