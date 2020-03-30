## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::Moot.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic Moot analysis API

package DTA::CAB::Analyzer::Moot;
use DTA::CAB::Analyzer ':child';
use DTA::CAB::Datum ':all';

use Moot;
use Encode qw(encode decode);
use IO::File;
use Carp;

#use Devel::Cycle; ##-- debug

use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Analyzer);

##==============================================================================
## Closure stuff

## $DEFAULT_ANALYZE_CODE
##  + default analysis code
##  + available variables:
##     $anl     # Analyzer::Moot object
##     $_       # sentence to be analyzed
our $DEFAULT_ANALYZE_CODE = '
package '. __PACKAGE__ .';
my $moot=$anl;
my $lab =$moot->{label};
my $hmm =$moot->{hmm};
my $tagx=$moot->{tagx};
my $utf8=$moot->{hmmUtf8};
my $prune=$moot->{prune};
my $lctext=$moot->{lctext};
my $notag=$moot->{notag};
my $use_dmoot=$moot->{use_dmoot};
my $moot_lang=$moot->{lang};
my $xpne=$moot->{xpne};
my $xpfm=$moot->{xpfm};
my $fmtag=$moot->{fmtag};
my ($s,$msent,$w,$mw,$t,$at,$lang,$val);
sub {
 $s     = $_;
 $msent = [map {
   $w  = $_;
   $mw = $w->{$lab} = $w->{$lab} ? {%{$w->{$lab}}} : ($w->{$lab}={}); ##-- copy $w->{moot} if present
   $mw->{text} = (defined($mw->{word}) ? $mw->{word} : '._am_tag('($use_dmoot ? $_->{dmoot} : undef)', _am_xlit).') if (!defined($mw->{text}));
   $mw->{text} = lc($mw->{text}) if ($lctext);
   $mw->{analyses} = [{tag=>"NE",details=>"NE.xp",prob=>0}] if ($xpne && ($w->{xp}//"") =~ /\b((?:pers)Name)\b/i); #place
   $mw->{analyses} = [{tag=>$fmtag,details=>"$fmtag.xp",prob=>0}] if ($xpfm && ($w->{xp}//"") =~ /\bforeign\b/i);
   $val = undef; ##-- temporary for _am_tagh_moota_uniq()
   $mw->{analyses} = ['._am_tagh_list2moota_uniq('map {$_ ? @$_ : qw()}
			    @$w{qw(mlatin tokpp toka)},
                            ($use_dmoot && $w->{xlit} && !$w->{xlit}{isLatinExt} ? [$fmtag, "XY"] : qw()),
			    ($use_dmoot && $w->{dmoot} ? $w->{dmoot}{morph}
                             : ($w->{morph}, ($w->{rw} ? (map {$_->{morph}} @{$w->{rw}}) : qw())))'
			   ).'
     ] if (!defined($mw->{analyses}));
   foreach (@{$mw->{analyses}}) {
     ##-- tag-translation hack: apply BEFORE sending to moot!
     $_->{tag}=$t if (defined($t=$tagx->{$_->{tag}}));
   }
   $mw
 } @{$s->{tokens}}];
 return if (!@$msent); ##-- ignore empty sentences

 $hmm->tag_sentence($msent, $utf8) if (!$notag);

 ##-- language-guesser hack
 if ($moot_lang && ($lang=$s->{lang}) && $lang ne $moot_lang) {
   $_->{tag} = "$fmtag.$lang" foreach (grep {$_->{tag} !~ /^\$/} @$msent);
 }

 foreach (@$msent) {
   $_->{word}=$_->{text};
   delete($_->{text});
   #$_->{tag}=$t if (defined($t=$tagx->{$_->{tag}//""})); ##-- do NOT translate output tags (breaks en-wsj, 2016-06-09)
   $_->{tag}="NE"   if ($xpne && $_->{analyses} && $_->{analyses}[0] && $_->{analyses}[0]{details} eq "NE.xp");
   $_->{tag}=$fmtag if ($xpfm && $_->{analyses} && $_->{analyses}[0] && $_->{analyses}[0]{details} eq "FM.xp");
   if ($prune) {
     $t = $_->{tag}//"";
     @{$_->{analyses}} = grep {$_->{tag} eq $t} @{$_->{analyses}};
   }
 }
}
';


##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure:
##    (
##     ##-- Filename Options
##     hmmFile => $filename,     ##-- default: none (REQUIRED)
##     tagxFile  => $tagxFile,   ##-- tag-translation file (hack)
##
##     ##-- Analysis Options
##     hmmArgs        => \%args, ##-- clobber Moot::HMM->new() defaults (default: none)
##     hmmUtf8        => $bool,  ##-- use hmm utf8 mode? (default=true)
##
##     analyzeCode => $code,     ##-- pseudo-closure: analyze current sentence $_
##     label       => $lab,      ##-- destination key (default='moot')
##     prune       => $bool,     ##-- if true (default), prune analyses after tagging
##     lctext      => $bool,     ##-- if true, input text will be bashed to lower-case (default: false)
##     notag       => $bool,     ##-- if true, hmm tagger won't actually be called; read from global analyzer options as "${lab}.notag"
##     use_dmoot   => $bool,     ##-- if true, hmm tagger will try to get text & analyses from token {dmoot} key, otherwise it will be ignored
##     xpne        => $bool,     ##-- if true, force 'NE' tags whenever $w->{xp} =~ /\b(?:pers)Name\b/i (default=true) #NOT 'placeName', the tags are often appositions
##     xpfm        => $bool,     ##-- if true, force 'FM' tags whenever $w->{xp} =~ /\bforeign\b/i (default=true)
##     lang        => $lang,     ##-- only tag sentences marked as language "$lang"; read from global analyzer options as "${lab}.lang" (default='de')
##     fmtag       => $fmtag,    ##-- prefix for "foreign-material" tags; default='FM'
##
##     ##-- Analysis Objects
##     hmm         => $hmm,   ##-- a moot::HMM object
##     tagx        => \%tagx,      ##-- tag-translation table (loaded via DTA::CAB::Analyzer::Dict from $tagxFile)
##    )
sub new {
  my $that = shift;
  my $moot = $that->SUPER::new(
			       ##-- filenames
			       hmmFile => undef,
			       tagxFile => undef,

			       ##-- options
			       hmmArgs   => {
					     #verbose=>Moot::vlWarnings,
					     #relax => 1,
					    },
			       hmmUtf8  => 1,

			       #prune => 1,
			       #uniqueAnalyses=>0,

			       ##-- analysis I/O
			       #analysisClass => 'DTA::CAB::Analyzer::Moot::Analysis',
			       label => 'moot',
			       analyzeCode => $DEFAULT_ANALYZE_CODE,
			       lctext => 0,
			       #notag => undef,
			       #use_dmoot => undef,
			       lang => 'de',
			       xpne => 1,
			       xpfm => 1,
			       fmtag => 'FM',

			       #analyzeCostFuncs => {},
			       #requireAnalyses => 0,
			       #wantTaggedWord => 1,

			       ##-- analysis objects
			       #hmm => undef,

			       ##-- user args
			       @_
			      );
  return $moot;
}

## $moot = $moot->clear()
sub clear {
  my $moot = shift;

  ##-- analysis sub(s)
  $moot->dropClosures();

  ##-- analysis objects
  delete($moot->{hmm});
  delete($moot->{tagx});

  return $moot;
}

## @keys = $anl->typeKeys(\%opts)
##  + returns list of type-wise keys to be expanded for this analyzer by expandTypes()
##  + override returns empty list
sub typeKeys {
  return qw();
}

##==============================================================================
## Methods: Generic
##==============================================================================

## $bool = $moot->hmmOk()
##  + should return false iff HMM is undefined or "empty"
##  + default version checks for non-empty 'lexprobs' and 'n_tags'
sub hmmOk {
   return defined($_[0]{hmm}) && $_[0]{hmm}->n_tags()>1 && $_[0]{hmm}->n_toks()>1;
    #&& $_[0]{hmm}{lexprobs}->size > 1;
}

## $class = $moot->hmmClass()
##  + returns class for $moot->{hmm} object
##  + default just returns 'Moot::HMM'
sub hmmClass { return 'Moot::HMM'; }

##==============================================================================
## Methods: I/O
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Input: all

## $bool = $moot->ensureLoaded()
##  + ensures model data is loaded from default files (if available)
sub ensureLoaded {
  my $moot = shift;
  my $rc = 1; ##-- allow empty models

  ##-- ensure: hmm
  $rc &&= $moot->loadHMM($moot->{hmmFile}) if (defined($moot->{hmmFile}) && !$moot->hmmOk);

  ##-- ensure: dict: tagx
  $rc &&= $moot->ensureDict('tagx',{}) if (!$moot->{tagx});

  return $rc;
}

##--------------------------------------------------------------
## Methods: I/O: Input: HMM

## $moot = $moot->loadHMM($model_file)
BEGIN { *loadHMM = *loadHmm = \&loadHMM; }
sub loadHMM {
  my ($moot,$model) = @_;
  my $hmmClass = $moot->hmmClass;
  $moot->info("loading HMM model file '$model' using HMM class '$hmmClass'");
  if (!defined($moot->{hmm})) {
    $moot->{hmm} = $hmmClass->new()
      or $moot->logconfess("could not create HMM object of class '$hmmClass': $!");
    $moot->{hmm}->config($moot->{hmmArgs}) if ($moot->{hmmArgs});
  }
  $moot->{hmm}->load($model)
    or $moot->logconfess("loadHMM(): load failed for '$model': $!");
  $moot->dropClosures();
  return $moot;
}

##--------------------------------------------------------------
## Methods: I/O: Input: Dictionaries: generic

## $bool = $a->ensureDict($dictName,\%dictDefault)
sub ensureDict {
  my ($a,$name,$default) = @_;
  return 1 if ($a->{$name}); ##-- already defined
  return $a->loadDict($name,$a->{"${name}File"}) if ($a->{"${name}File"});
  $a->{$name} = $default ? {%$default} : {};
  return 1;
}

## \%dictHash_or_undef = $a->loadDict($dictName,$dictFile)
sub loadDict {
  my ($a,$name,$dfile) = @_;
  delete($a->{$name});
  my $dclass = 'DTA::CAB::Analyzer::Dict';
  $a->info("loading map from '$dfile' as $dclass");

  ##-- hack: generate a temporary dict object
  my $dict = $dclass->new(label=>($a->{label}.".dict.$name"), dictFile=>$dfile);
  $dict->ensureLoaded();
  return undef if (!$dict->dictOk);

  ##-- clobber dict
  $a->{$name} = $dict->dictHash;
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
  return ($that->SUPER::noSaveKeys, qw(hmm));
}

## $saveRef = $obj->savePerlRef()
##  + inherited from DTA::CAB::Persistent

## $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref)
##  + implicitly calls $obj->clear()
sub loadPerlRef {
  my ($that,$ref) = @_;
  my $obj = $that->SUPER::loadPerlRef($ref);
  $obj->clear();
  return $obj;
}

##==============================================================================
## Methods: Analysis
##==============================================================================

##------------------------------------------------------------------------
## Methods: Analysis: Generic

## $bool = $anl->canAnalyze()
##  + returns true if analyzer can perform its function (e.g. data is loaded & non-empty)
sub canAnalyze {
  return $_[0]->hmmOk();
}


##------------------------------------------------------------------------
## Methods: Analysis: v1.x: API

## $bool = $anl->doAnalyze(\%opts, $name)
##  + override: only allow analyzeSentences()
sub doAnalyze {
  my $anl = shift;
  return 0 if (defined($_[1]) && $_[1] ne 'Sentences');
  return $anl->SUPER::doAnalyze(@_);
}

## $doc = $anl->analyzeSentences($doc,\%opts)
##  + perform sentence-wise analysis of all sentences $doc->{body}[$si]
##  + no default implementation
sub analyzeSentences {
  my ($moot,$doc,$opts) = @_;
  return undef if (!$moot->ensureLoaded()); ##-- uh-oh...
  return $doc if (!$moot->canAnalyze);      ##-- ok...
  $doc = toDocument($doc);

  ##-- inherit global options
  my $notag        = $moot->{notag};
  my $use_dmoot    = $moot->{use_dmoot};
  $moot->{notag}     //= $opts->{"$moot->{label}.notag"};
  $moot->{use_dmoot} //= $opts->{"$moot->{label}.use_dmoot"};
  $moot->{use_dmoot} //= 1;
  $moot->{lang}        = $opts->{"$moot->{label}.lang"} if ($opts->{"$moot->{label}.lang"});

  ##-- setup access closures
  my $acode_str  = $moot->analysisCode();
  my $acode_sub  = $moot->accessClosure($acode_str);

  ##-- ye olde loope
  foreach (@{$doc->{body}}) {
    $acode_sub->();
  }

  ##-- restore local options
  $moot->{notag}     = $notag;
  $moot->{use_dmoot} = $use_dmoot;

  ##-- DEBUG
  #print STDERR "find_cycle()\n";
  #find_cycle([$moot,$doc,$acode_sub]);
  ##--/DEBUG

  return $doc;
}

##------------------------------------------------------------------------
## Methods: Analysis: Closure Utilities

## $asub_code = $moot->analysisCode()
##  + analysis closure for passing to Analyzer::accessClosure()
##  + default just returns $moot->{analyzeCode} || $DEFAULT_ANALYZE_CODE
sub analysisCode {
  my $moot = shift;
  return
    #analysisCodeDEBUG($moot) ||
    $moot->{analyzeCode} || $DEFAULT_ANALYZE_CODE;
}

##------------------------------------------------------------------------
## Methods: Analysis: DEBUG

## analysisCodeDEBUG() : from $DEFAULT_ANALYZE_CODE
sub analysisCodeDEBUG {
  my $anl = shift;

  ## copy+paste from debugger "print $DEFAULT_ANALYZE_CODE" after breaking first e.g. in analysisCode() above
  package DTA::CAB::Analyzer::Moot;
  my $moot=$anl;
  my $lab =$moot->{label};
  my $hmm =$moot->{hmm};
  my $tagx=$moot->{tagx};
  my $utf8=$moot->{hmmUtf8};
  my $prune=$moot->{prune};
  my $lctext=$moot->{lctext};
  my $notag=$moot->{notag};
  my $use_dmoot=$moot->{use_dmoot};
  my $moot_lang=$moot->{lang};
  my $xpne=$moot->{xpne};
  my $xpfm=$moot->{xpfm};
  my $fmtag=$moot->{fmtag};
  my ($s,$msent,$w,$mw,$t,$at,$lang,$val);
  sub {
    $s     = $_;
    $msent = [map {
      $w  = $_;
      $mw = $w->{$lab} = $w->{$lab} ? {%{$w->{$lab}}} : ($w->{$lab}={}); ##-- copy $w->{moot} if present
      $mw->{text} = (defined($mw->{word}) ? $mw->{word} : (($use_dmoot ? $_->{dmoot} : undef) ? ($use_dmoot ? $_->{dmoot} : undef)->{tag} : ($_->{xlit} ? $_->{xlit}{latin1Text} : $_->{text}) ##== _am_xlit
							  ) ##== _am_tag
		    ) if (!defined($mw->{text}));
      $mw->{text} = lc($mw->{text}) if ($lctext);
      $mw->{analyses} = [{tag=>"NE",details=>"NE.xp",prob=>0}] if ($xpne && ($w->{xp}//"") =~ /\b((?:pers)Name)\b/i); #place
      $mw->{analyses} = [{tag=>$fmtag,details=>"$fmtag.xp",prob=>0}] if ($xpfm && ($w->{xp}//"") =~ /\bforeign\b/i);
      $val = undef;	      ##-- temporary for _am_tagh_moota_uniq()
      $mw->{analyses} = [(map {$val && $val->{details} eq $_->{details} ? qw() : ($val=$_)} sort {($a->{details}//"") cmp ($b->{details}//"") || ($a->{prob}//0) <=> ($b->{prob}//0)} (map {{details=>$_->{hi}, prob=>($_->{w}||0), tag=>($_->{hi} =~ /\[\_?((?:[A-Za-z0-9.]+|\$[^\]]+))\]/ ? $1 : $_->{hi})} ##-- _am_tagh_fst2moota
																							  } map {ref($_) ? $_ : {hi=>$_}} map {$_ ? @$_ : qw()}
																						       @$w{qw(mlatin tokpp toka)},
																						       ($use_dmoot && $w->{xlit} && !$w->{xlit}{isLatinExt} ? [$fmtag, "XY"] : qw()),
																						       ($use_dmoot && $w->{dmoot} ? $w->{dmoot}{morph}
																							: ($w->{morph}, ($w->{rw} ? (map {$_->{morph}} @{$w->{rw}}) : qw())))) ##-- _am_tagh_list2moota
			 )	##== _am_tagh_moota_uniq

			] if (!defined($mw->{analyses}));
      foreach (@{$mw->{analyses}}) {
	##-- tag-translation hack: apply BEFORE sending to moot!
	$_->{tag}=$t if (defined($t=$tagx->{$_->{tag}}));
      }
      $mw
    } @{$s->{tokens}}];
    return if (!@$msent);	##-- ignore empty sentences

    $hmm->tag_sentence($msent, $utf8) if (!$notag);

    ##-- language-guesser hack
    if ($moot_lang && ($lang=$s->{lang}) && $lang ne $moot_lang) {
      $_->{tag} = "$fmtag.$lang" foreach (grep {$_->{tag} !~ /^\$/} @$msent);
    }

    foreach (@$msent) {
      $_->{word}=$_->{text};
      delete($_->{text});
      #$_->{tag}=$t if (defined($t=$tagx->{$_->{tag}//""})); ##-- do NOT translate output tags (breaks en-wsj, 2016-06-09)
      $_->{tag}="NE"   if ($xpne && $_->{analyses} && $_->{analyses}[0] && $_->{analyses}[0]{details} eq "NE.xp");
      $_->{tag}=$fmtag if ($xpfm && $_->{analyses} && $_->{analyses}[0] && $_->{analyses}[0]{details} eq "FM.xp");
      if ($prune) {
	$t = $_->{tag}//"";
	@{$_->{analyses}} = grep {$_->{tag} eq $t} @{$_->{analyses}};
      }
    }
  }
}

1; ##-- be happy

__END__
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Analyzer::Moot - generic Moot HMM tagger/disambiguator analysis API

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Analyzer::Moot;
 
 ##========================================================================
 ## Constructors etc.
 
 $obj = CLASS_OR_OBJ->new(%args);
 $moot = $moot->clear();
 
 ##========================================================================
 ## Methods: Generic
 
 $bool = $moot->hmmOk();
 $class = $moot->hmmClass();
 
 ##========================================================================
 ## Methods: I/O
 
 $bool = $moot->ensureLoaded();
 $moot = $moot->loadHMM($model_file);
 
 ##========================================================================
 ## Methods: Persistence: Perl
 
 @keys = $class_or_obj->noSaveKeys();
 $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref);
 
 ##========================================================================
 ## Methods: Analysis
 
 $bool = $anl->canAnalyze();
 $bool = $anl->doAnalyze(\%opts, $name);
 $doc = $anl->analyzeSentences($doc,\%opts);
 


=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Moot: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Analyzer::Moot
inherits from
L<DTA::CAB::Analyzer|DTA::CAB::Analyzer>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Moot: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $obj = CLASS_OR_OBJ->new(%args);

Object structure, %args:

 ##-- Filename Options
 hmmFile => $filename,     ##-- default: none (REQUIRED)
 ##
 ##-- Analysis Options
 hmmArgs        => \%args, ##-- clobber moot::HMM->new() defaults (default: verbose=>$moot::HMMvlWarnings)
 hmmEnc         => $enc,   ##-- encoding of model file(s) (default='UTF-8')
 analyzeTextGet => $code,  ##-- pseudo-closure: token 'text' (default=$DEFAULT_ANALYZE_TEXT_GET)
 analyzeTagsGet => $code,  ##-- pseudo-closure: token 'analyses' (defualt=$DEFAULT_ANALYZE_TAGS_GET)
 analyzeCostFuncs =>\%fnc, ##-- maps source 'analyses' key(s) to cost-munging functions
                           ##     %fnc = ($akey=>$perlcode_str, ...)
                           ##   + evaluates $perlcode_str as subroutine body to derive analysis
                           ##     'weights' from source-key weights
                           ##   + $perlcode_str may use variables:
                           ##       $moot    ##-- current Analyzer::Moot object
                           ##       $tag     ##-- source analysis tag
                           ##       $details ##-- source analysis 'details' "$hi <$w>"
                           ##       $cost    ##-- source analysis weight
                           ##       $text    ##-- source token text
                           ##   + Default just returns $cost (identity function)
 label           =>$lab,   ##-- destination key (default='moot')
 requireAnalyses => $bool, ##-- if true all tokens MUST have non-empty analyses (useful for DynLex; default=1)
 prune          => $bool,  ##-- if true (default), prune analyses after tagging
 uniqueAnalyses => $bool,  ##-- if true, only cost-minimal analyses for each tag will be added (default=false)
 wantTaggedWord => $bool,  ##-- if true, output field will contain top-level 'word' element (default=true)
 ##
 ##-- Analysis Objects
 hmm            => $hmm,   ##-- a moot::HMM object


OBSOLETE fields (use analyzeTextGet, analyzeTagsGet pseudo-closure accessors):

 #analyzeTextSrc => $src,   ##-- source token 'text' key (default='text')
 #analyzeTagSrcs => \@srcs, ##-- source token 'analyses' key(s) (default=['morph'], undef for none)
 #analyzeLiteralFlag=>$key, ##-- if ($tok->{$key}), only literal analyses are allowed (default='dmootLiteral')
 #analyzeLiteralSrc =>$key, ##-- source key for literal analyses (default='xlit')

The 'hmmFile' argument can be specified in any format accepted by mootHMM::load_model().

=item clear

 $moot = $moot->clear();

Clears the object.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Moot: Methods: Generic
=pod

=head2 Methods: Generic

=over 4

=item hmmOk

 $bool = $moot->hmmOk();

Should return false iff HMM is undefined or "empty".
Default version checks for non-empty 'lexprobs' and 'n_tags'

=item hmmClass

 $class = $moot->hmmClass();

Returns class for $moot-E<gt>{hmm} object.
Default just returns 'moot::HMM'.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Moot: Methods: I/O
=pod

=head2 Methods: I/O

=over 4

=item ensureLoaded

 $bool = $moot->ensureLoaded();

Ensures model data is loaded from default files.

=item loadHMM

 $moot = $moot->loadHMM($model_file);

Loads HMM model from $model_file.  See mootfiles(5).

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Moot: Methods: Persistence: Perl
=pod

=head2 Methods: Persistence: Perl

=over 4

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();

Returns list of keys not to be saved

=item loadPerlRef

 $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref);

Implicitly calls $obj-E<gt>clear()

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Moot: Methods: Analysis
=pod

=head2 Methods: Analysis

=over 4

=item typeKeys

 @keys = $anl->typeKeys(\%opts);

Returns list of type-wise keys to be expanded for this analyzer by expandTypes().
Override returns empty list.

=item canAnalyze

 $bool = $anl->canAnalyze();

Returns true if analyzer can perform its function (e.g. data is loaded & non-empty)

=item doAnalyze

 $bool = $anl->doAnalyze(\%opts, $name);

Override: only allow analyzeSentences().

=item analyzeSentences

 $doc = $anl->analyzeSentences($doc,\%opts);

Perform sentence-wise analysis of all sentences $doc-E<gt>{body}[$si].

=back

=cut


##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Footer
##======================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<DTA::CAB::Analyzer::Moot::DynLex(3pm)|DTA::CAB::Analyzer::Moot::DynLex>,
L<DTA::CAB::Analyzer(3pm)|DTA::CAB::Analyzer>,
L<DTA::CAB::Chain(3pm)|DTA::CAB::Chain>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
L<mootutils(1)|mootutils>,
L<moot(1)|moot>,
...

=cut
