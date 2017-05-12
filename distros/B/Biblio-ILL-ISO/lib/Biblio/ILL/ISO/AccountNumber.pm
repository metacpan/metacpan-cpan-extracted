package Biblio::ILL::ISO::AccountNumber;

=head1 NAME

Biblio::ILL::ISO::AccountNumber

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

Biblio::ILL::ISO::AccountNumber is a derivation of Biblio::ILL::ISO::ILLString
(in fact, it is just a renamed ILLString).

=head1 USES

 Biblio::ILL::ISO::ILLString

=head1 USED IN

 Biblio::ILL::ISO::CostInfoType
 Biblio::ILL::ISO::SendToListType

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLString 
		  Biblio::ILL::ISO::ILLASNtype 
		  );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Account-Number ::= ILL-String

=cut

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
