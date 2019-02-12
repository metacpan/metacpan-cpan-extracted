## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::EqLemma::JsonCDB.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DB dictionary-based equivalence-class expander, rewrite variant

package DTA::CAB::Analyzer::EqLemma::JsonCDB;
use DTA::CAB::Analyzer ':child';
use DTA::CAB::Analyzer::Dict::JsonCDB;
use strict;

##==============================================================================
## Globals
##==============================================================================
our @ISA = qw(DTA::CAB::Analyzer::Dict::JsonCDB);

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure: see DTA::CAB::Analyzer::Dict::CDB
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   ##-- options
			   label       => 'eqlemma',
			   ##-- user args
			   @_
			  );
}


##========================================================================
## analysis overrides

## $bool = $anl->doAnalyze(\%opts, $name)
sub doAnalyze {
  my $anl = shift;
  return 0 if ($_[1] eq 'Types');
  return $anl->SUPER::doAnalyze(@_);
}

## $doc = $anl->analyzeTypes($doc,\%types,\%opts)
##  + perform type-wise analysis of all (text) types in $doc->{types}
##  + override does nothing
sub analyzeTypes { return $_[1]; }

## $doc = $anl->analyzeSentences($doc,\%opts)
##  + perform sentence-wise analysis of all sentences $doc->{body}[$si]
##  + expand lemma equivalence
sub analyzeSentences {
  my ($anl,$doc,$opts) = @_;

  ##-- common vars
  my $lab  = $anl->{label};
  my $tied = $anl->{dbf}{tied};
  my $jxs  = $anl->jsonxs;

  ##-- map by moot lemmata
  my $l2eql = {}; ##-- $l2eql = {$lemma => \@eqlemma, ...}; cache
  my ($l,$eqls);
  foreach (map {@{$_->{tokens}}} @{$doc->{body}}) {
    next if (!$_->{moot} || !defined($l=$_->{moot}{lemma}));
    if (exists($l2eql->{$l})) {
      $_->{$lab} = $l2eql->{$l};
      next;
    }
    $_->{$lab} = $l2eql->{$l} = defined($eqls=$tied->FETCH($l)) ? $jxs->decode($eqls) : [$l];
  }

  ##-- return
  return $doc;
}


1; ##-- be happy

__END__
