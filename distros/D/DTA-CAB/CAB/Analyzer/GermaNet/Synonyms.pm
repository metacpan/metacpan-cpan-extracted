## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::GermaNet::Synonyms.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: GermaNet relation expander: synonyms

package DTA::CAB::Analyzer::GermaNet::Synonyms;
use DTA::CAB::Analyzer::GermaNet::RelationClosure;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Analyzer::GermaNet::RelationClosure);

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure:
##    (
##     ##-- OVERRIDES in Hyperonyms
##     relations => ['hyperonymy','hyponymy'],	##-- override
##     label => 'gn-syn',			##-- override
##     max_depth => 0,				##-- override
##
##     ##-- INHERITED from GermaNet::RelationClosure
##     relations => \@relns,		##-- relations whose closure to compute
##     analyzeGet => $code,		##-- accessor: coderef or string: source text (default=$DEFAULT_ANALYZE_GET; return undef for no analysis)
##     allowRegex => $regex,		##-- only analyze types matching $regex
##
##     ##-- INHERITED from Analyzer::GermaNet
##     gnFile=> $dirname_or_binfile,	##-- default: none
##     gn => $gn_obj,			##-- underlying GermaNet object
##     max_depth => $depth,		##-- default maximum closure depth for relation_closure() [default=128]
##     label => $lab,			##-- analyzer label
##    )
sub new {
  my $that = shift;
  my $gna = $that->SUPER::new(
			      ##-- overrides
			      relations => [qw(has_hypernym has_hyponym)],
			      label => 'gn-syn',
			      max_depth => 0,

			      ##-- user args
			      @_
			     );
  return $gna;
}

##==============================================================================
## Alias DTA::CAB::Analyzer::GermaNet::syn

package DTA::CAB::Analyzer::GermaNet::syn;
use strict;
our @ISA = qw(DTA::CAB::Analyzer::GermaNet::Synonyms);


1; ##-- be happy

__END__
