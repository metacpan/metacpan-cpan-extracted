## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::GermaNet::Hyperonyms.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: GermaNet relation expander: hyponymy (subclasses)

package DTA::CAB::Analyzer::GermaNet::Hyponyms;
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
##     relations => ['hyponymy'],	##-- override
##     label => 'gn-asi',		##-- override
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
			      relations => [qw(has_hyponym)],
			      label => 'gn-asi',

			      ##-- user args
			      @_
			     );
  return $gna;
}

##==============================================================================
## Alias DTA::CAB::Analyzer::GermaNet::Hyponymy
package DTA::CAB::Analyzer::GermaNet::Hyponymy;
use strict;
our @ISA = qw(DTA::CAB::Analyzer::GermaNet::Hyponyms);

##==============================================================================
## Alias DTA::CAB::Analyzer::GermaNet::asi
package DTA::CAB::Analyzer::GermaNet::asi;
use strict;
our @ISA = qw(DTA::CAB::Analyzer::GermaNet::Hyponyms);


1; ##-- be happy

__END__
