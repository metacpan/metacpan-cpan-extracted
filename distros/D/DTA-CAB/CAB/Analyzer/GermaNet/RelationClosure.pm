## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::GermaNet::RelationClosure.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: wrapper for GermaNet relation expanders

package DTA::CAB::Analyzer::GermaNet::RelationClosure;
use DTA::CAB::Analyzer ':child';
use DTA::CAB::Analyzer::GermaNet;
use Carp;

use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Analyzer::GermaNet);

##--------------------------------------------------------------
## Globals: Accessors

## $DEFAULT_ANALYZE_GET
##  + default coderef or eval-able string for {analyzeGet}
our $DEFAULT_ANALYZE_GET = _am_lemma('$_->{moot}').' || '._am_word('$_->{moot}',_am_xlit);

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure:
##    (
##     ##-- NEW in GermaNet::RelationClosure
##     relations => \@relns,		##-- relations whose closure to compute (default: qw(has_hyperonym has_hyponym))
##     analyzeGet => $code,		##-- accessor: coderef or string: source text (default=$DEFAULT_ANALYZE_GET; return undef for no analysis)
##     allowRegex => $regex,		##-- only analyze types matching $regex
##     ${lab}_max_depth => $max_depth,	##-- maximum expansion depth
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
			      ##-- filenames
			      gnFile => undef,

			      ##-- runtime
			      relations => [qw(has_hypernym has_hyponym)],
			      max_depth => 128,
			      analyzeGet => $DEFAULT_ANALYZE_GET,
			      allowRegex => undef,

			      ##-- analysis output
			      label => 'gnet',

			      ##-- user args
			      @_
			     );
  return $gna;
}


##==============================================================================
## Methods: Analysis
##==============================================================================

##------------------------------------------------------------------------
## Methods: Analysis: utils

## $bool = $anl->doAnalyze(\%opts, $name)
##  + override: only allow analyzeSentences()
sub doAnalyze {
  my $anl = shift;
  return 0 if (defined($_[1]) && $_[1] ne 'Sentences');
  return $anl->SUPER::doAnalyze(@_);
}

## $doc = $anl->analyzeSentences($doc,\%opts)
##  + perform sentence-wise analysis of $doc
sub analyzeSentences {
  my ($gna,$doc,$opts) = @_;

  ##-- setup common variables
  my $lab       = $gna->{label};
  my $gn	= $gna->{gn};
  my $relations = $gna->{relations} || [];
  my $max_depth = $opts->{"${lab}_max_depth"} // $gna->{"${lab}_max_depth"} // $opts->{max_depth} // $gna->{max_depth};
  my $allow_re  = defined($gna->{allowRegex}) ? qr($gna->{allowRegex}) : undef;
  my $aget_code = defined($gna->{analyzeGet}) ? $gna->{analyzeGet} :  $DEFAULT_ANALYZE_GET;
  my $aget      = $gna->accessClosure($aget_code);
  my %cache     = qw();

  my ($w,$lemma, $synsets, $syn,@syns,$cached);
  foreach (map {@{$_->{tokens}}} @{$doc->{body}}) {
    next if (defined($allow_re) && $_->{text} !~ $allow_re);
    $w       = $_;
    $lemma   = $aget->();
    if (defined($cached=$cache{$lemma})) {
      ##-- used cached data
      delete $w->{$lab};
      $w->{$lab} = $cached if (@$cached);
      next;
    }

    ##-- lookup
    $synsets = $gn->get_synsets($lemma) // [];
    push(@$synsets, grep {exists($gn->{rel}{"syn2lex:$_"})} $lemma); ##-- allow synset names as 'lemma' queries
    @syns = map {
      $syn = $_;
      map {
	$gna->relation_closure($syn, $_, $max_depth)
      } @$relations
    } @$synsets;

    $w->{$lab} = $cache{$lemma} = [grep {$_ ne 'GNROOT'} @{$gna->synsets_terms(\@syns)}];
    delete($w->{$lab}) if (!@{$w->{$lab}});
  }

  return $doc;
}


1; ##-- be happy

__END__
