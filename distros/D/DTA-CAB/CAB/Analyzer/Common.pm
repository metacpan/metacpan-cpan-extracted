## -*- Mode: CPerl -*-
## File: DTA::CAB::Analyzer::Common.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: CAB analyzers: common analyzers
##  + see also

package DTA::CAB::Analyzer::Common;

#use DTA::CAB::Analyzer;
use DTA::CAB::Analyzer::Automaton;
use DTA::CAB::Analyzer::Automaton::Gfsm;
use DTA::CAB::Analyzer::Automaton::Gfsm::XL;
use DTA::CAB::Analyzer::Unicruft;
use DTA::CAB::Analyzer::LTS;

use DTA::CAB::Analyzer::EqPho;           ##-- default eqpho-expander
#use DTA::CAB::Analyzer::EqPho::Dict;     ##-- via Dict::BDB (default)
#use DTA::CAB::Analyzer::EqPho::Dict;     ##-- via Dict (unused)
#use DTA::CAB::Analyzer::EqPho::Cascade;  ##-- via Gfsm::XL (unused)
#use DTA::CAB::Analyzer::EqPho::FST;      ##-- via Gfsm::Automaton (default)

use DTA::CAB::Analyzer::Morph;
#use DTA::CAB::Analyzer::Morph::Extra::BDB;
#use DTA::CAB::Analyzer::Morph::Extra::CDB;
#use DTA::CAB::Analyzer::Morph::Extra::OrtLexHessen;
#use DTA::CAB::Analyzer::Morph::Helsinki;
use DTA::CAB::Analyzer::Morph::Latin;
use DTA::CAB::Analyzer::MorphSafe;
use DTA::CAB::Analyzer::Null;
use DTA::CAB::Analyzer::Rewrite;
use DTA::CAB::Analyzer::RewriteSub;

#use DTA::CAB::Analyzer::Moot1;           ##-- moot/swig bindings: base class: moot:HMM
#use DTA::CAB::Analyzer::Moot1::DynLex;   ##-- moot/swig bindings: dynamic-lexical hmm (moot::DynLexHMM_Boltzmann)
##
use DTA::CAB::Analyzer::Moot;             ##-- moot/xs bindings: base class: Moot::HMM
use DTA::CAB::Analyzer::Moot::Boltzmann;  ##-- moot/xs bindings: dynamic-lexical hmm (Moot::HMM::Boltzmann)

use DTA::CAB::Analyzer::Lemmatizer;      ##-- tagh lemma extractor

use DTA::CAB::Analyzer::EqRW;            ##-- default eqrw-expander
#use DTA::CAB::Analyzer::EqRW::BDB;        ##-- via Dict::BDB (default)
#use DTA::CAB::Analyzer::EqRW::Dict;      ##-- via Dict (unused)
#use DTA::CAB::Analyzer::EqRW::Cascade;   ##-- via Gfsm::XL (unimplemented, unused)
#use DTA::CAB::Analyzer::EqRW::FST;       ##-- via Gfsm::Automaton (default)

use DTA::CAB::Analyzer::Dict;            ##-- generic dictionary-based analyzer (base class)
use DTA::CAB::Analyzer::Dict::BDB;        ##-- generic DB-dictionary-based analyzer (base class)
use DTA::CAB::Analyzer::Dict::CDB;        ##-- generic CDB-dictionary-based analyzer (base class)
#use DTA::CAB::Analyzer::Dict::EqClass;   ##-- generic dictionary-based equivalence class expander (obsolete, removed)

use DTA::CAB::Analyzer::TokPP;           ##-- token-based pre-processor (rule-based analysis)
#use DTA::CAB::Analyzer::TokPP::Perl;    ##-- token-based pre-processor (rule-based analysis)
#use DTA::CAB::Analyzer::TokPP::Waste;   ##-- token-based pre-processor (rule-based analysis)

use DTA::CAB::Analyzer::EqLemma;         ##-- lemma-equivalence class expander

use DTA::CAB::Analyzer::GermaNet;             ##-- GermaNet shared routines
use DTA::CAB::Analyzer::GermaNet::Hypernyms;  ##-- GermaNet hypernyms (superclasses)
use DTA::CAB::Analyzer::GermaNet::Hyponyms;   ##-- GermaNet hyponyms (subclasses)
use DTA::CAB::Analyzer::GermaNet::Synonyms;   ##-- GermaNet synonyms (super- and sub-classes)

use DTA::CAB::Analyzer::LangId::Simple;      ##-- simple stopword-based language guesser

use DTA::CAB::Chain;                     ##-- analyzer chains
use DTA::CAB::Chain::Multi;              ##-- analyzer multi-chains

use strict;

##==============================================================================
## Constants
##==============================================================================


1; ##-- be happy

__END__

##==============================================================================
## PODS
##==============================================================================
=pod

=head1 NAME

DTA::CAB::Analyzer::Common - common analyzers for DTA::CAB suite

=head1 SYNOPSIS

 use DTA::CAB::Analyzer::Common;
 
 $anl = $ANALYZER_CLASS->new(%args);
 $anl->analyzeDocument($doc,%analyzeOptions);
 # ... etc.
 

=cut

##==============================================================================
## Description
##==============================================================================
=pod

=head1 DESCRIPTION

The DTA::CAB::Analyzer::Common package just includes some default
analyzer classes used by the rest of the DTA::CAB suite, namely:

=over 4

=item L<DTA::CAB::Analyzer|DTA::CAB::Analyzer>

Abstract base class for analyzer objects.

=item L<DTA::CAB::Analyzer::Automaton|DTA::CAB::Analyzer::Automaton>

Generic API for finite-state automaton analyzers.

=item L<DTA::CAB::Analyzer::Automaton::Gfsm|DTA::CAB::Analyzer::Automaton::Gfsm>

Finite-state analyzer base class using Gfsm for low-level automaton operations (lookup).

=item L<DTA::CAB::Analyzer::Automaton::Gfsm::XL|DTA::CAB::Analyzer::Automaton::Gfsm::XL>

Finite-state analyzer base class using Gfsm::XL for low-level automaton operations (k-best cascade lookup).



=item L<DTA::CAB::Analyzer::Dict|DTA::CAB::Analyzer::Dict>

Full-form dictionary-based analyzer (aka "cache") using a flat hash.

=item L<DTA::CAB::Analyzer::Dict::BDB|DTA::CAB::Analyzer::Dict::BDB>

Full-form dictionary-based analyzer (aka "cache") using Berkeley DB.

=item L<DTA::CAB::Analyzer::Dict::CDB|DTA::CAB::Analyzer::Dict::CDB>

Full-form dictionary-based analyzer (aka "cache") using CDB.


=item L<DTA::CAB::Analyzer::EqLemma|DTA::CAB::Analyzer::EqLemma>

Lemma-equivalence expander (wrapper).

=item L<DTA::CAB::Analyzer::EqPho|DTA::CAB::Analyzer::EqPho>

Phonetic equivalence-class expander (wrapper).

=item L<DTA::CAB::Analyzer::EqRW|DTA::CAB::Analyzer::EqRW>

Rewrite equivalence class expander (wrapper).


=item L<DTA::CAB::Analyzer::Lemmatizer|DTA::CAB::Analyzer::Lemmatizer>

Lemma extractor for TAGH morphological analyses.

=item L<DTA::CAB::Analyzer::LTS|DTA::CAB::Analyzer::LTS>

Letter-To-Sound (phonetic) analysis via Gfsm automaton lookup.


=item L<DTA::CAB::Analyzer::Moot|DTA::CAB::Analyzer::Moot>

Hidden Markov Model Viterbi decoder using libmoot.

=item L<DTA::CAB::Analyzer::Moot::DynLex|DTA::CAB::Analyzer::Moot::DynLex>

Dynamic-Lexicon Hidden Markov Model Viterbi decoder using libmoot.


=item L<DTA::CAB::Analyzer::Morph|DTA::CAB::Analyzer::Morph>

Morphological analysis via Gfsm automaton lookup.

=item L<DTA::CAB::Analyzer::Morph::Latin|DTA::CAB::Analyzer::Morph::Latin>

Latin pesudo-morphological analyzer (wrapper).

=item L<DTA::CAB::Analyzer::MorphSafe|DTA::CAB::Analyzer::MorphSafe>

Safety heuristics for analyses output by TAGH via L<DTA::CAB::Analyzer::Morph|DTA::CAB::Analyzer::Morph>.



=item L<DTA::CAB::Analyzer::Null|DTA::CAB::Analyzer::Null>

Null analyzer, for testing purposes.



=item L<DTA::CAB::Analyzer::Rewrite|DTA::CAB::Analyzer::Rewrite>

Error-correction (rewrite) analyzer using a Gfsm::XL cascade.

=item L<DTA::CAB::Analyzer::RewriteSub|DTA::CAB::Analyzer::RewriteSub>

Sub-analyzer for rewrite output.



=item L<DTA::CAB::Analyzer::TokPP|DTA::CAB::Analyzer::TokPP>

Type-level heuristic token preprocessor (for punctuation etc)


=item L<DTA::CAB::Analyzer::Unicruft|DTA::CAB::Analyzer::Unicruft>

Transliterator for latin-1 approximation using libunicruft.



=item L<DTA::CAB::Chain|DTA::CAB::Chain>

Analyzer chains (aka "pipelines").

=item L<DTA::CAB::Chain::Multi|DTA::CAB::Chain::Multi>

Analyzer multi-chains (collection of named pipelines).


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

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<DTA::CAB::Analyzer(3pm)|DTA::CAB::Analyzer>,
L<DTA::CAB::Chain(3pm)|DTA::CAB::Chain>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...

=cut
