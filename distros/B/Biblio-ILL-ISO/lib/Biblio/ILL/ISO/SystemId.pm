package Biblio::ILL::ISO::SystemId;

=head1 NAME

Biblio::ILL::ISO::SystemId

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::PersonOrInstitutionSymbol;
use Biblio::ILL::ISO::NameOfPersonOrInstitution;

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

Biblio::ILL::ISO::SystemId is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::PersonOrInstitutionSymbol
 Biblio::ILL::ISO::NameOfPersonOrInstitution

=head1 USED IN

 Biblio::ILL::ISO::AlreadyForwarded
 Biblio::ILL::ISO::AlreadyTriedListType
 Biblio::ILL::ISO::EDeliveryDetails
 Biblio::ILL::ISO::HistoryReport
 Biblio::ILL::ISO::LocationInfo
 Biblio::ILL::ISO::SendToListType
 Biblio::ILL::ISO::TransactionId

=cut
BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 System-Id ::= SEQUENCE {
   --at least one of the following must be present
   person-or-institution-symbol  [0]	Person-Or-Institution-Symbol OPTIONAL,
   name-of-person-or-institution [1]	Name-Of-Person-Or-Institution OPTIONAL
   }

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [$person_or_institution_symbol] )

 Creates a new SystemId object. 
 Expects either no paramaters, or
 (optionally) a person or institution symbol (Biblio::ILL::ISO::PersonOrInstitutionSymbol).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) { 
	$self->{"person-or-institution-symbol"} = new Biblio::ILL::ISO::PersonOrInstitutionSymbol(shift); 
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

    return $self->{"person-or-institution-symbol"}->as_string() if ($self->{"person-or-institution-symbol"});
    return $self->{"name-of-person-or-institution"}->as_string() if ($self->{"name-of-person-or-institution"});
    return "";
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_person_symbol( $s )

 Sets the object's person-or-institution-symbol.
 Expects a text string.

=cut
sub set_person_symbol {
    my $self = shift;
    my ($s) = @_;

    $self->{"person-or-institution-symbol"} = new Biblio::ILL::ISO::PersonOrInstitutionSymbol();
    $self->{"person-or-institution-symbol"}->set_person_symbol($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_institution_symbol( $s )

 Sets the object's person-or-institution-symbol.
 Expects a text string.

=cut
sub set_institution_symbol {
    my $self = shift;
    my ($s) = @_;

    $self->{"person-or-institution-symbol"} = new Biblio::ILL::ISO::PersonOrInstitutionSymbol();
    $self->{"person-or-institution-symbol"}->set_institution_symbol($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_person_name( $s )

 Sets the object's name-of-person-or-institution.
 Expects a text string.

=cut
sub set_person_name {
    my $self = shift;
    my ($s) = @_;

    $self->{"name-of-person-or-institution"} = new Biblio::ILL::ISO::NameOfPersonOrInstitution();
    $self->{"name-of-person-or-institution"}->set_person_name($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_institution_name( $s )

 Sets the object's name-of-person-or-institution.
 Expects a text string.

=cut
sub set_institution_name {
    my $self = shift;
    my ($s) = @_;

    $self->{"name-of-person-or-institution"} = new Biblio::ILL::ISO::NameOfPersonOrInstitution();
    $self->{"name-of-person-or-institution"}->set_institution_name($s);

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

	if ($k =~ /^person-or-institution-symbol$/) {
	    $self->{$k} = new Biblio::ILL::ISO::PersonOrInstitutionSymbol();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^name-of-person-or-institution$/) {
	    $self->{$k} = new Biblio::ILL::ISO::NameOfPersonOrInstitution();
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
