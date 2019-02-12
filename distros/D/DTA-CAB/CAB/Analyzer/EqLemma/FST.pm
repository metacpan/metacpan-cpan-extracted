## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::EqLemma::FST.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: lemma-equivalence class expansion via Gfsm::Automaton

##==============================================================================
## Package: Analyzer::Morph
##==============================================================================
package DTA::CAB::Analyzer::EqLemma::FST;
use DTA::CAB::Analyzer ':access';
use DTA::CAB::Analyzer::Automaton::Gfsm;
use Carp;
use strict;
our @ISA = qw(DTA::CAB::Analyzer::Automaton::Gfsm);

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure: see DTA::CAB::Analyzer::Automaton::Gfsm, DTA::CAB::Analyzer::Automaton
sub new {
  my $that = shift;
  my $aut = $that->SUPER::new(
			      ##-- overrides
			      #tolower => 0,
			      #check_symbols => 0,

			      ##-- analysis selection
			      label          => 'eqlemma',
			      analyzeGet     => $DTA::CAB::Analyzer::Automataon::DEFAULT_ANALYZE_GET,
			      analyzeSet     => ('$_->{$lab} = ['._am_id_fst().', ($wa ? @$wa : qw())];'),
			      attInput       => 1,
			      wantAnalysisLo => 0,
			      allowTextRegex => DTA::CAB::Analyzer::_am_wordlike_regex(),
			      #allowWordRegex => '.',

			      ##-- type expansion
			      #typeKeys => [qw(eqlemma)],

			      ##-- user args
			      @_
			     );
  return $aut;
}

##==============================================================================
## Analysis Formatting
##==============================================================================


1; ##-- be happy

__END__
