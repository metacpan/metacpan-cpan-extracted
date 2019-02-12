## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::MorphSafe.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: safety checker for analyses output by DTA::CAB::Analyzer::Morph (TAGH)

package DTA::CAB::Analyzer::MorphSafe;

use DTA::CAB::Analyzer;
use DTA::CAB::Analyzer::Dict;
use DTA::CAB::Unify ':all';

use Encode qw(encode decode);
use IO::File;
use Carp;

use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Analyzer);

## %badTypes = ($text=>$isGood, ...)
##  + default hash of bad text types
our %badTypes = (
		 #Andre=>0,    ##-- bad: type: Andre[_NE][firstname][none][none][sg][nom_acc_dat]
		);

## %badMorphs = ($taghMorph=>$isBad, ...)
##  + default hash of bad TAGH morphs
our %badMorphs = (
		  #'Thür'=>1,  ##-- bad: stem
		  #'/ON'=>1,   ##-- bad: stem class: organization name
		 );

## %badTags = ($taghTag=>$isBad, ...)
##  + default hash of bad TAGH tags
our %badTags = (
		'FM'=>1,       ##-- bad: FM  (e.g. That:That[_FM][en])
		'XY'=>1,       ##-- bad: XY
		'ITJ'=>1,      ##-- bad: ITJ
	       );

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure, new:
##    ##-- analysis selection
##    allowTokenizerAnalyses => $bool, ##-- if true, tokenizer-analyzed tokens (as determined by $tok->{toka}, $tok->{tokpp}) are "safe"; (default=true)
##    allowExlexAnalyses => $bool,     ##-- if true, exlex-analyzed tokens (as determined by $tok->{exlex}) are "safe"; (default=false)
##    allowApostropheS => $bool,       ##-- if true, "-'s" tokens with a morph analysis are "safe" (default=true)
##    tokMorphKey => $key,             ##-- key for token 'morph' property (default='morph')
##    morphHiKey => $key,              ##-- key for morph analysis 'hi' property (default='hi')
##
##    ##-- Exception lexicon options
##    #dict      => $dict,       ##-- exception lexicon as a DTA::CAB::Analyzer::Dict object or option hash
##    #                          ##   + default=undef
##    #dictClass => $class,      ##-- fallback class for new dict (default='DTA::CAB::Analyzer::Dict')
##
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   ##-- options
			   label => 'msafe',
			   allowTokenizerAnalyses => 1,
			   allowExlexAnalyses => 0,
			   allowApostropheS => 1,
			   tokMorphKey => 'morph',
			   morphHiKey => 'hi',

			   ##-- dictionary stuff
			   #badTypesFile  => undef,            ##-- filename of ($text "\t" $isGoodBool) mapping for raw utf8 text types
			   #badTypes      => {%badTypes},      ##-- hash of bad utf8 text types ($text=>$isGoodBool)
			   ##
			   #badMorphsFile  => undef,           ##-- filename of ($taghMorph "\t" $isBadBool) mapping for TAGH morph components
			   #badMorphs      => {%badMorphs},    ##-- hash of bad TAGH morphs ($taghMorph=>$isBadBool)
			   ##
			   #badTagsFile    => undef,           ##-- filename of ($taghTag "\t" $isBadBool) mapping for TAGH tags (without '[_', ']')
			   #badTags        => {%badTags},      ##-- hash of bad TAGH tags ($taghTag=>$isBadBool)

			   ##-- user args
			   @_
			  );
}

##==============================================================================
## Methods: I/O
##==============================================================================

## $bool = $msafe->ensureLoaded()
##  + ensures analysis data is loaded
sub ensureLoaded {
  my $msafe = shift;
  my $rc = 1;

  ##-- ensure: dict: badTypes
  $rc &&= $msafe->ensureDict('badTypes',\%badTypes) if (!$msafe->{badTypes});

  ##-- ensure: dict: badMorphs
  $rc &&= $msafe->ensureDict('badMorphs',\%badMorphs) if (!$msafe->{badMorphs});

  ##-- ensure: dict: badTags
  $rc &&= $msafe->ensureDict('badTags',\%badTags) if (!$msafe->{badTags});

  return $rc;
}

##--------------------------------------------------------------
## Methods: I/O: Input: Dictionaries: generic

## $bool = $msafe->ensureDict($dictName,\%dictDefault)
sub ensureDict {
  my ($ms,$name,$default) = @_;
  return 1 if ($ms->{$name}); ##-- already defined
  return $ms->loadDict($name,$ms->{"${name}File"}) if ($ms->{"${name}File"});
  $ms->{$name} = $default ? {%$default} : {};
  return 1;
}

## \%dictHash_or_undef = $msafe->loadDict($dictName,$dictFile)
sub loadDict {
  my ($ms,$name,$dfile) = @_;
  delete($ms->{$name});
  $ms->info("loading exception lexicon from '$dfile'");

  ##-- hack: generate a temporary dict object
  my $dict = DTA::CAB::Analyzer::Dict->new(label=>($ms->{label}.".dict.$name"), dictFile=>$dfile);
  $dict->ensureLoaded();
  return undef if (!$dict->dictOk);

  ##-- clobber dict
  $ms->{$name} = $dict->dictHash;
}


##==============================================================================
## Methods: Analysis: v1.x
##==============================================================================

## $doc = $msafe->analyzeTypes($doc,\%types,\%opts)
##  + perform type-wise analysis of all (text) types in %types (= %{$doc->{types}})
##  + checks for "safe" analyses in $tok->{morph} for each $tok in $doc->{types}
##  + sets $tok->{ $anl->{label} } = $bool
sub analyzeTypes {
  my ($ms,$doc,$types,$opts) = @_;
  $types = $doc->types if (!$types);
  #$types = $doc->extendTypes($types,'morph') if (!grep {$_->{morph}} values(%$types)); ##-- DEBUG

  my $label     = $ms->{label};
  my $want_toka = $ms->{allowTokenizerAnalyses};
  my $want_exlex= $ms->{allowExlexAnalyses};
  my $want_apos_s = $ms->{allowApostropheS};
  my $tok_morph = $ms->{tokMorphKey};
  my $morph_hi  = $ms->{morphHiKey};
  my $badTypes  = $ms->{badTypes}||{};
  my $badTags   = $ms->{badTags}||{};
  my $badMorphs = $ms->{badMorphs}||{};

  my ($tok,$safe,$nsafe,@m,$ma);
  foreach $tok (values %$types) {
    next if (defined($tok->{$label})); ##-- avoid re-analysis (e.g. of global exlex-provided analyses)

    ##-- no dict entry: use morph heuristics
    $safe =
      (($want_exlex && defined($tok->{exlex}))             ##-- exception-lexicon analyses are considered "safe"
       || (
	   $want_toka
	   && (
	       ($tok->{toka} && @{$tok->{toka}})           ##-- tokenizer-analyzed words are considered "safe"
	       ||
	       ($tok->{tokpp} && @{$tok->{tokpp}})
	      )
	  )
       || (
	   $tok->{text} !~ m/^[\p{Letter}\#\@]/            ##-- non-alphabetic tokens are (usually) "safe"
	   						   ##   ... unless they contain a placeholder for unrecognized material ('#' or '@')
	                                                   ##   [replaces /[[:digit:][:punct:]]/ heuristic; Tue, 28 Feb 2012 11:21:29 +0100]
	  )
       || $tok->{mlatin}                                   ##-- latin words are "safe" [NEW Fri, 01 Apr 2011 11:38:45 +0200]
       || (
	   $want_apos_s  				   ##-- "-'s" words with a morph analysis may be safe
	   && $tok->{$tok_morph}
	   && $tok->{text} =~ m/^(.+)[\'\x{2018}\x{2019}]s$/
	  )
      );

    ##-- are we still unsafe?  then check for some "safe" morph analysis: if found, set $safe=1 & bug out
    if (!$safe
        && !defined($safe=$badTypes->{$tok->{text}})  	   ##-- ... only if it's not a known type
	&& $tok->{$tok_morph}	                           ##-- ... and it has morph analyses (empty $tok->{morph} will still be "unsafe")
       )
      {
      MORPHA:
	foreach (@{$tok->{$tok_morph}}) {
	  @m = $_->{$morph_hi} =~ m{\G
				    (?:[^\~\#\/\[\=\|\-\+\\\ ]+)  ##-- morph: stem
				    |(?:\/[A-Z]{1,2})             ##-- morph: stem class
				    |(?:[\~\#\=\|\-\+\\\ ]+)      ##-- morph: separator
				    |(?:\[.*$)                    ##-- morph: syntax (tag+features)
		  		   }gx;
	  $ma = pop @m;

	  ##-- check for bad tags (unsafe)
	  next if (
		   $badTags->{$ma =~ /^\[_([A-Z0-9]+)\]/ ? $1 : $ma}
		   ||
		   $ma =~ m{
			     ^\[_NE\]\[
			     (?:
			       #geoname|
			       #firstname|
			       lastname|
			       orgname|
			       productname
			     )
			     \]
			 }x
		  );

	  ##-- check for unsafe roots
	  foreach (@m) {
	    next MORPHA if ($badMorphs->{$_});
	  }

	  ##-- check for suspicious composites, e.g. "Mittheilung:Mitte/N#heil/V~ung", "Abtheilung:Abt/N#heil/V~ung"
	  next if ($_->{$morph_hi} =~ m{te?\/[A-Z]{1,2}\#[Hh]});

	  ##-- this analysis is safe: update flag & break out of morph-analysis loop
	  $safe=1;
	  last;
	}
      }

    ##-- output
    $tok->{$label} = $safe ? 1 : 0;
  }

  return $doc;
}


1; ##-- be happy

__END__
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Analyzer::MorphSafe - safety checker for analyses output by DTA::CAB::Analyzer::Morph (TAGH)

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Analyzer::MorphSafe;
 
 $msafe = CLASS_OR_OBJ->new(%args);
 
 $bool = $msafe->ensureLoaded();
 
=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::MorphSafe: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Analyzer::MorphSafe inherits from
L<DTA::CAB::Analyzer|DTA::CAB::Analyzer>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::MorphSafe: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $msafe = CLASS_OR_OBJ->new(%args);

%args, %$msafe:

 ##-- selection options
 allowTokenizerAnalyses => 1,
 allowExlexAnalyses => 1,

 ##-- dictionary options
 badTypesFile  => $filename,         ##-- filename of ($text "\t" $isGoodBool) mapping for raw utf8 text types
 badMorphsFile  => $filename,        ##-- filename of ($taghMorph "\t" $isBadBool) mapping for TAGH morph components
 badTagsFile    => $filename,        ##-- filename of ($taghTag "\t" $isBadBool) mapping for TAGH tags (tags appear without '[_', ']')

 ##-- low-level data (after prepare())
 badTypes       => \%badTypes,       ##-- hash of bad utf8 text types ($text=>$isGoodBool)
 badMorphs      => \%badMorphs,      ##-- hash of bad TAGH morphs ($taghMorph=>$isBadBool)
 badTags        => \%badTags,        ##-- hash of bad TAGH tags ($taghTag=>$isBadBool)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::MorphSafe: Methods
=pod

=head2 Methods

=over 4

=item ensureLoaded

 $bool = $msafe->ensureLoaded();

Override: ensures analysis data is loaded

=over 4

=item analyzeTypes

 $doc = $msafe->analyzeTypes($doc,\%types,\%opts)

Override: implements L<DTA::CAB::Analyzer::analyzeTypes|DTA::CAB::Analyzer/analyzeTypes>.

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

=cut
