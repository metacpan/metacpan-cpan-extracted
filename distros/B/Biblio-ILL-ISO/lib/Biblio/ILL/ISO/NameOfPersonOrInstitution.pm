package Biblio::ILL::ISO::NameOfPersonOrInstitution;

=head1 NAME

Biblio::ILL::ISO::NameOfPersonOrInstitution

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

Biblio::ILL::ISO::NameOfPersonOrInstitution is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ILLString

=head1 USED IN

 Biblio::ILL::ISO::PostalAddress
 Biblio::ILL::ISO::SystemId

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Name-Of-Person-Or-Institution ::= CHOICE {
	name-of-person	        [0]	ILL-String,
	name-of-institution	[1]	ILL-String
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [$name_of_institution] )

 Creates a new NameOfPersonOrInstitution object. 
 Expects either no paramaters, or 
 an institution name (text string).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) { 
	$self->{"name-of-institution"} = new Biblio::ILL::ISO::ILLString(shift); 
    }
    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 as_string( )

Returns a stringified representation of the object.

=cut
sub as_string {
    my $self = shift;

    return $self->{"name-of-person"}->as_string() if ($self->{"name-of-person"});
    return $self->{"name-of-institution"}->as_string() if ($self->{"name-of-institution"});
    return "";
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_person_name( $s )

 Sets the object's name-of-person.
 Expects a text string.

=cut
sub set_person_name {
    my $self = shift;
    my ($s) = @_;

    $self->{"name-of-person"} = new Biblio::ILL::ISO::ILLString($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_institution_name( $s )

 Sets the object's name-of-institution.
 Expects a text string.

=cut
sub set_institution_name {
    my $self = shift;
    my ($s) = @_;

    $self->{"name-of-institution"} = new Biblio::ILL::ISO::ILLString($s);

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

	if (($k =~ /^name-of-person$/)
	    || ($k =~ /^name-of-institution$/)
	    ) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString($href->{$k});

	} else {
	    croak "invalid " . ref($self) . "element: [$k]";
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
