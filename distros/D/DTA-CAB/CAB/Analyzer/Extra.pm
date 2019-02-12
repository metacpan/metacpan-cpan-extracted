## -*- Mode: CPerl -*-
## File: DTA::CAB::Analyzer::Extra.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: CAB analyzers: extra analyzers (not loaded by default)

package DTA::CAB::Analyzer::Extra;

use DTA::CAB::Analyzer::Common;

use DTA::CAB::Analyzer::Dict::Json;
use DTA::CAB::Analyzer::Dict::JsonDB;
use DTA::CAB::Analyzer::Dict::JsonCDB;

use DTA::CAB::Analyzer::TextPhonetic;
use DTA::CAB::Analyzer::Koeln;
use DTA::CAB::Analyzer::Metaphone;
use DTA::CAB::Analyzer::Soundex;
use DTA::CAB::Analyzer::Phonem;
use DTA::CAB::Analyzer::Phonix;

use DTA::CAB::Analyzer::Unidecode;

use DTA::CAB::Analyzer::LangId;          ##-- language identification via Lingua::LangId::Map
use DTA::CAB::Analyzer::DocClassify;     ##-- document classification via DocClassify

use DTA::CAB::Analyzer::DmootSub;        ##-- DTA
use DTA::CAB::Analyzer::MootSub;         ##-- DTA
use DTA::CAB::Analyzer::ExLex;           ##-- DTA
use DTA::CAB::Analyzer::DTAClean;        ##-- DTA
use DTA::CAB::Analyzer::DTAMapClass;     ##-- DTA

use DTA::CAB::Analyzer::SynCoPe;	 ##-- DTA
use DTA::CAB::Analyzer::SynCoPe::NER;	 ##-- DTA

use strict;

1; ##-- be happy

__END__

##==============================================================================
## PODS
##==============================================================================
=pod

=head1 NAME

DTA::CAB::Analyzer::Extra - extra bonus analyzers for DTA::CAB suite

=head1 SYNOPSIS

 use DTA::CAB::Analyzer::Extra;
 
 $anl = CLASS_OR_OBJ->new(%args);
 $anl->analyzeDocument($doc,%analyzeOptions);
 # ... etc.
 

=cut

##==============================================================================
## Description
##==============================================================================
=pod

=head1 DESCRIPTION

The DTA::CAB::Analyzer::Extra package includes some additional
analyzer classes not commonly used by the rest of the DTA::CAB suite, namely:

=over 4

=item L<DTA::CAB::Analyzer::DocClassify|DTA::CAB::Analyzer::DocClassify>

Document classification via L<DocClassify|DocClassify>.

=item L<DTA::CAB::Analyzer::LangId|DTA::CAB::Analyzer::LangId>

Language guessing via L<Lingua::LangId::Map|Lingua::LangId::Map>.


=item L<DTA::CAB::Analyzer::TextPhonetic|DTA::CAB::Analyzer::TextPhonetic>

Phonetic digest assignment via L<Text::Phonetic> algorithms, including:

=over 4

=item L<DTA::CAB::Analyzer::Koeln|DTA::CAB::Analyzer::Koeln>

Phonetic digest analyzer: Koelner Phonetik algorithm.

=item L<DTA::CAB::Analyzer::Metaphone|DTA::CAB::Analyzer::Metaphone>

Phonetic digest analyzer: Metaphone algorithm.

=item L<DTA::CAB::Analyzer::Soundex|DTA::CAB::Analyzer::Soundex>

Phonetic digest analyzer: Soundex algorithm.

=item L<DTA::CAB::Analyzer::Phonem|DTA::CAB::Analyzer::Phonem>

Phonetic digest analyzer: Phonem algorithm.

=item L<DTA::CAB::Analyzer::Phonix|DTA::CAB::Analyzer::Phonix>

Phonetic digest analyzer: Phonix algorithm.

=back

=item L<DTA::CAB::Analyzer::Unidecode|DTA::CAB::Analyzer::Unidecode>

Transliterator using L<Text::Unidecode|Text::Unidecode>.

=back

=cut


##==============================================================================
## Footer
##==============================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2019 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
