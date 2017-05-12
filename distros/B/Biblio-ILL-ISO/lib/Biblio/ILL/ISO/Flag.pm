package Biblio::ILL::ISO::Flag;

=head1 NAME

Biblio::ILL::ISO::Flag

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ENUMERATED;
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

Biblio::ILL::ISO::Flag is a derivation of Biblio::ILL::ISO::ENUMERATED.

=head1 USES

 None.

=head1 USED IN

 Biblio::ILL::ISO::DateDue
 Biblio::ILL::ISO::RenewAnswer
 Biblio::ILL::ISO::Request

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ENUMERATED 
		  Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
  (part of ILL-Request)
 
 	forward-flag	[22]	IMPLICIT BOOLEAN --DEFAULT FALSE,
 
=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $flag )

 Creates a new Flag object. 
 Valid paramaters are the strings "true" and "false".

=cut
sub new {
    my $class = shift;
    my $self = {};

    $self->{"ENUM_LIST"} = {"false" => 0,
			    "true" => 1
			    };
    
    if (@_) {
	my $s = shift;
	
	if ( exists $self->{"ENUM_LIST"}->{$s} ) {
	    $self->{"ENUMERATED"} = $self->{"ENUM_LIST"}->{$s};
	} else {
	    croak "invalid flag: [$s]";
	}
    }

    bless($self, ref($class) || $class);
    return ($self);
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
