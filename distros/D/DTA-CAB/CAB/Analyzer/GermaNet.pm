## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::GermaNet.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: wrapper for GermaNet relation expanders

package DTA::CAB::Analyzer::GermaNet;
use DTA::CAB::Analyzer ':child';
use Storable;
use Carp;

use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA     = qw(DTA::CAB::Analyzer);

our ($HAVE_GERMANET_FLAT);
BEGIN{
  eval 'use GermaNet::Flat;' if (!UNIVERSAL::can('GermaNet::Flat','new'));
  $HAVE_GERMANET_FLAT = UNIVERSAL::can('GermaNet::Flat','new') ? 1 : 0;
}

our %FILE2GN = qw(); ##-- maps source files to GermaNet::GermaNet objects (for data sharing)

##--------------------------------------------------------------
## Globals: Accessors

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure:
##    (
##     ##-- Filename Options
##     gnFile=> $dirname_or_binfile,	##-- default: none
##
##     ##-- Runtime
##     gn => $gn_obj,			##-- underlying GermaNet::Flat object
##     max_depth => $depth,		##-- default maximum closure depth for relation_closure() [default=128]
##
##     ##-- Analysis Output
##     label => $lab,			##-- analyzer label
##    )
sub new {
  my $that = shift;
  my $gna = $that->SUPER::new(
			      ##-- filenames
			      gnFile => undef,

			      ##-- runtime
			      max_depth => 128,
			      gn => undef,

			      ##-- analysis output
			      label => 'gnet',

			      ##-- user args
			      @_
			     );
  return $gna;
}

## $gna = $gna->clear()
sub clear {
  my $gna = shift;
  delete $gna->{gn};
  return $gna;
}


##==============================================================================
## Methods: Embedded API
##==============================================================================

## $bool = $gna->gnOk()
##  + returns false iff gn is undefined or "empty"
sub gnOk {
  return defined($_[0]{gn});
}

##==============================================================================
## Methods: I/O
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Input: all

## $rc = $gna->load()
## $rc = $gna->load($gnFile)
##  + force re-load
sub load {
  my ($gna,$gnFile) = @_;
  $gna->{gnFile} = ($gnFile ||= $gna->{gnFile});
  if (!$gnFile) {
    return 0;
  }
  elsif (!$HAVE_GERMANET_FLAT) {
    $gna->warn("GermaNet::Flat module unvailable -- cannot load $gnFile");
    return 0;
  }
  elsif (exists $FILE2GN{$gnFile}) {
    ##-- binary data sharing
    $gna->{gn} = $FILE2GN{$gnFile};
  }
  elsif (-d $gnFile) {
    $gna->info("loading GermaNet data from XML directory $gnFile ...");
  }
  elsif ($gnFile =~ /\.[cb]?db$/i) {
    $gna->info("attaching GermaNet data to file $gnFile ...");
  }
  elsif ($gnFile =~ /\.(?:sto|bin)$/i) {
    $gna->info("loading GermaNet data from binary file $gnFile ...");
  }
  else {
    $gna->info("loading GermaNet data from text file $gnFile");
  }
  $gna->{gn} = $FILE2GN{$gnFile} = GermaNet::Flat->load($gnFile);
  return $gna->gnOk();
}

## $bool = $gna->ensureLoaded()
##  + ensures analyzer data is loaded from default file(s)
sub ensureLoaded {
  my $gna = shift;
  my $rc = 1;
  if (!$HAVE_GERMANET_FLAT) {
    $gna->warn("GermaNet::GermaNet module unvailable disabling analyzer '$gna->{label}'") if ($gna->{enabled});
    $gna->{enabled} = 0;
  }
  elsif (defined($gna->{gnFile}) && !$gna->gnOk) {
    $rc &&= $gna->load();
  }
  return $rc;
}

##==============================================================================
## Methods: Persistence
##==============================================================================

##======================================================================
## Methods: Persistence: Perl

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
sub noSaveKeys {
  my $that = shift;
  return ($that->SUPER::noSaveKeys, qw(gn));
}

## $saveRef = $obj->savePerlRef()
##  + inherited from DTA::CAB::Persistent

## $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref)
sub loadPerlRef {
  my ($that,$ref) = @_;
  my $obj = $that->SUPER::loadPerlRef($ref);
  return $obj;
}

##==============================================================================
## Methods: Analysis
##==============================================================================

##------------------------------------------------------------------------
## Methods: Analysis: Generic

## $bool = $anl->canAnalyze()
##  + returns true if analyzer can perform its function (e.g. data is loaded & non-empty)
##  + override calls gnOk()
sub canAnalyze {
  return $_[0]->gnOk();
}

##------------------------------------------------------------------------
## Methods: Analysis: v1.x: API

## $doc = $anl->analyzeTypes($doc,\%types,\%opts)
##  + perform type-wise analysis of all (text) types in $doc->{types}
##  + NOT IMPLEMENTED HERE!
#sub analyzeTypes { }; 

##==============================================================================
## Methods: Utils

## @terms = $gna->synset_terms($synset)
sub synset_terms {
#  return map {s/\s/_/g; $_} map {@{$_->get_orth_forms}} @{$_[1]->get_lex_units};
  return @{$_[0]{gn}->synset_terms($_[1])};
}

## \@terms = $gna->synsets_terms(\@synsets)
## + unique elements only
sub synsets_terms {
  #my $gna = shift;
  #my $prev='';
  my $gn = $_[0]{gn};
  return $gn->auniq( $gn->relation('lex2orth',$gn->relation('syn2lex',$_[1])) );
}

## $str = $gna->synset_str($synset,%opts)
##  + %opts:
##     show_ids => $bool,	##-- default=1
##     show_lex => $bool,	##-- default=1
##     canonical => $bool,	##-- default=1
sub synset_str {
  my ($gna,$syn,%opts) = @_;
  return 'undef' if (!defined($syn));
  %opts = (show_ids=>1,show_lex=>1,canonical=>1) if (!%opts);
  my $str = (($opts{show_ids}
	      ? ($syn.($opts{show_lex} || $opts{canonical} ? ':' : ''))
	      : '')
	     .($opts{show_lex}
	       ? ($opts{canonical}
		  ? $gna->{gn}->relation('lex2orth',$gna->{gn}->relation('syn2lex',$syn)->[0])->[0]
		  : $gna->{gn}->relation('lex2orth',$gna->{gn}->relation('syn2lex',$syn)))
	       : ''));
  return $str;
}

## $str = $gna->path_str(\@synsets)
## $str = $gna->path_str( @synsets)
sub path_str {
  return join('/',map {$_[0]->synset_str($_)} (UNIVERSAL::isa($_[1],'ARRAY') ? @{$_[1]} : @_));
}

## %relation_alias : global relation aliases
my %relation_alias = (
		      'hyperonymy'=>'has_hypernym',
		      'hypernyms' =>'has_hypernym',
		      'hypernym'  =>'has_hypernym',
		      'hyponymy'  =>'has_hyponym',
		      'hyponyms'  =>'has_hyponym',
		      'hyponym'   =>'has_hyponym',
		     );

## @synsets = $gna->relation_closure($synset,$relation,$max_depth,\%syn2depth);	##-- list context
## $synsets = $gna->relation_closure($synset,$relation,$max_depth,\%syn2depth);	##-- scalar context
##  + returns transitive + reflexive closure of relation $relation (up to $max_depth=$gna->{max_depth})
sub relation_closure {
  my ($gna,$synset,$rel,$maxdepth,$syn2depth) = @_;
  $maxdepth //= $gna->{max_depth};
  $maxdepth   = 65536 if (!defined($maxdepth) || $maxdepth < 0);

  $syn2depth = {$synset=>0} if (!$syn2depth); ##-- $synset => $depth, ...
  my $gn = $gna->{gn};
  my @queue = ($synset);
  my @syns  = qw();
  my ($syn,$depth,$next);
  while (defined($syn=shift(@queue))) {
    push(@syns,$syn);
    $depth = $syn2depth->{$syn};
    if ((!defined($maxdepth) || $depth < $maxdepth) && defined($next=$gn->relation($relation_alias{$rel}//$rel,$syn))) {
      foreach (@$next) {
	next if (exists $syn2depth->{$_});
	$syn2depth->{$_} = $depth+1;
	push(@queue,$_);
      }
    }
  }
  return wantarray ? @syns : \@syns;
}

## @paths = $gna->synset_paths($synset,$maxdepth)
##  + returns all paths to $synset from root
sub synset_paths {
  my ($gna,$synset,$depth) = @_;
  $depth //= $gna->{max_depth};
  $depth   = 65536 if (!defined($depth) || $depth < 0);

  my (@paths,$i,$path,$hyps);
  my @queue = ([0,$synset]); ##-- queue items: [$depth,@path...]

  while (defined($path=shift(@queue))) {
    $i = shift(@$path);
    if ($i>=$depth) {
      push(@paths,$path);
      next;
    }
    $hyps = $path->[0]->relation('has_hyponym');
    if ($hyps && @$hyps) {
      if (@$hyps==1) {
	unshift(@$path, $i+1, $hyps->[0]);	##-- re-use path for 1st hyponym
	push(@queue, $path);
      } else {
	push(@queue, map {[$i+1, $_, @$path]} @$hyps);
      }
    } else {
      push(@paths, $path);
    }
  }
  return wantarray ? @paths : \@paths;
}


1; ##-- be happy

__END__
