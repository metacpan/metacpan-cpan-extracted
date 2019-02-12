## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::MootSub.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: post-processing for moot PoS tagger in DTA chain
##  + tweaks $tok->{moot}{word}, instantiates $tok->{moot}{lemma}

package DTA::CAB::Analyzer::MootSub;
use DTA::CAB::Analyzer ':child';
use DTA::CAB::Analyzer::Lemmatizer;
use Text::LevenshteinXS qw();
use Carp;
use strict;
our @ISA = qw(DTA::CAB::Analyzer);

##======================================================================
## Methods

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure, %args:
##     mootLabel => $label,    ##-- label for Moot tagger object (default='moot')
##     lz => $lemmatizer,      ##-- DTA::CAB::Analyzer::Lemmatizer sub-object
##     bytoken => $bool,       ##-- type-wise expand $mootLabel if true; depends on global option "${label}.bytoken"; see typeKeys() method
##     xyTags => $xytags,      ##-- use literal text (not dmoot) for these tags (string, array, or HASH-ref; default=[qw(XY FM)])
##     ucTags => $uctags,      ##-- implicitly upper-case lemmata for these tags (string, array, or HASH-ref; default=[qw(NN NE)])
##     stts => $bool,          ##-- implicitly use STTS-specific heuristics? (default=1)
##     wMorph => $bool,        ##-- morph-cost coefficient for lemma-selection heuristics (default=1000)
sub new {
  my $that = shift;
  my $asub = $that->SUPER::new(
			       ##-- analysis selection
			       label => 'mootsub',
			       mootLabel => 'moot',
			       bytoken => 1,
			       lz => DTA::CAB::Analyzer::Lemmatizer->new(analyzeGet    =>$DTA::CAB::Analyzer::Lemmatizer::GET_MOOT_ANALYSES,
									 analyzeGetText=>$DTA::CAB::Analyzer::Lemmatizer::GET_MOOT_TEXT,
									 analyzeWhich  =>'Sentences',
									 segmentLabel  =>'segs',
									),
			       xyTags => 'XY FM', #CARD NE ##-- use literal text (not dmoot) for these tags
			       ucTags => 'NN NE',          ##-- implicitly upper-case lemmata for these tags
			       stts   => 1,
			       wMorph => 1000,

			       ##-- user args
			       @_
			      );

  $asub->{lz}{label} = $asub->{label}."_lz";
  return $asub;
}

## $bool = $anl->doAnalyze(\%opts, $name)
##  + override: only allow analyzeSentences()
sub doAnalyze {
  my $anl = shift;
  return 0 if (defined($_[1]) && $_[1] ne 'Sentences');
  return $anl->SUPER::doAnalyze(@_);
}

## $doc = $anl->Sentences($doc,\%opts)
##  + post-processing for 'moot' object
sub analyzeSentences {
  my ($asub,$doc,$opts) = @_;
  return $doc if (!$asub->enabled($opts));

  ##-- tweak list-tags
  foreach my $lkey (grep {defined($asub->{$_})} qw(xyTags ucTags)) {
    $asub->{$lkey} = [split(' ',$asub->{$lkey})] if (!ref($asub->{$lkey}));
    $asub->{$lkey} = {map {($_=>undef)} @{$asub->{$lkey}}} if (!UNIVERSAL::isa($asub->{$lkey},'HASH'));
    #$asub->trace("$lkey = ".join(' ', sort keys %{$asub->{$lkey}})); ##-- DEBUG
  }

  ##-- common variables
  my $mlabel = $asub->{mootLabel};
  my $lz     = $asub->{lz};
  my $xytags = $asub->{xyTags} // {};
  my $uctags = $asub->{ucTags} // {};
  my $stts   = $asub->{stts};
  my $wmorph = $asub->{wMorph};
  my $toks   = [map {@{$_->{tokens}}} @{$doc->{body}}];

  ##-- Step 1: ensure $tok->{moot}, $tok->{moot}{tag} are defined (should be obsolete!), apply tag hacks
  my ($tok,$m,$w);
  foreach $tok (@$toks) {
    $m = $tok->{$mlabel} = {} if (!defined($m=$tok->{$mlabel}));
    $m->{tag} = '@UNKNOWN' if (!defined($m->{tag}));
    $w = $m->{word} // $tok->{text};

    ##-- tag hacks: stts
    if ($stts) {
      if ($m->{tag} eq 'TRUNC' && $w !~ m/\w/) {
	##-- tag-hack: avoid TRUNC tags for non-wordlike tokens
	$m->{tag} = ($w =~ /[^[:punct:]]$/ ? 'XY' : '$(');
      }
      elsif ($w !~ m/[^[:punct:]\p{MathematicalOperators}]/ && $m->{tag} !~ /^(?:\$|XY)/) {
	##-- tag-hack: avoid "normal" tags for punctuation-only tokens
	$m->{tag} = '$(';
      }
    }
  }

  ##-- Step 2: run lemmatizer (populates $tok->{moot}{analyses}[$i]{lemma}
  $lz->_analyzeGuts($toks,$opts) if ($lz->enabled($opts));

  ##-- Step 3: lemma-extraction & tag-sensitive lemmatization hacks
  my %cache = qw(); ##-- $cache{"$word\t$tag"} = $best_analysis
  my ($t,$la,$l,$key,$ma,$maa,%l2d, $ld, $a0,$ld0);
  foreach $tok (@$toks) {
    $m      = $tok->{$mlabel};
    ($w,$t) = @$m{qw(word tag)};
    $key    = "$w/$t";
    if (defined($la=$cache{$key})) {
      ##-- cached value
      @$m{qw(details lemma)} = ($la,$la->{lemma});
      next;
    }

    ##-- get analyses
    $ma  = $m->{analyses} || [];                       ##-- all
    $maa = @$ma ? [grep {$_->{tag} eq $t} @$ma] : $ma; ##-- ... with matching tag?
    $ma  = $maa if ($maa ne $ma && @$maa);             ##-- ... or without!

    if (!@$ma
	|| exists($xytags->{$t})
	|| $t =~ /^FM\./
        #|| ($t eq 'NE' && !$tok->{msafe})
        )
      {
	##-- hack: bash XY-tagged elements to raw (possibly transliterated) text
	$l = $m->{word} = (defined($tok->{exlex}) ? $tok->{exlex} : (defined($tok->{xlit}) && $tok->{xlit}{isLatinExt} ? $tok->{xlit}{latin1Text} : $tok->{text}));
	$l =~ s/\s+/_/g;
	#$l =~ s/^(.)(.*)$/$1\L$2\E/ ;#if (length($l) > 3 || $l =~ /[[:lower:]]/);
	$l =~ s/[\x{ac}]//g;
	$l = lc($l);
	$l =~ s/(?:^|(?<=[\-\_]))(.)/\U$1\E/g if (exists($uctags->{$t})); ##-- implicitly upper-case NN, NE (in case e.g. 'NE' \in $xytags)
	$m->{details} = $cache{$key} = {lemma=>$l,tag=>$t,details=>"*",prob=>0};
      }
    else
      {
	##-- extract lemma from "best" analysis
	%l2d = qw();

	$a0 = $ld0 = undef;
	foreach (sort {($a->{cost}||$a->{prob}||0)<=>($b->{cost}||$b->{prob}||0)} @$ma) {
	  ##-- get lemma distance
	  $l   = $_->{lemma};
	  $ld  = Text::LevenshteinXS::distance($w, $l) ;
	  $ld += $wmorph*($_->{cost}||$_->{prob}||0);				     ##-- hack: morph cost clobbers edit-distance
	  $ld += $wmorph*(10) if (($_->{hi}||$_->{details}||'') =~ /\[orgname\]/); ##-- hack: punish orgname targets
	  $l2d{$l} = $ld if (!defined($l2d{$l}) || $l2d{$l} > $ld);
	  next if (defined($ld0) && $ld0 <= $ld);
	  $ld0 = $ld;
	  $a0  = $_;
	}
	#print STDERR "$tok->{text}:\n", map {"\t$_ : $l2d{$_}\n"} sort keys %l2d; ##-- DEBUG

	$a0->{lemma} =~ s/(?:^|(?<=[\-\_]))(.)/\U$1\E/g if (exists($uctags->{$t})); ##-- implicitly upper-case lemmata NN, NE (in case e.g. 'NE')
	$m->{details} = $cache{$key} = $a0;
      }
    $m->{lemma} = $m->{details}{lemma};
  }

  ##-- return
  return $doc;
}

## @keys = $anl->typeKeys(\%opts)
##  + returns list of type-wise keys to be expanded for this analyzer by expandTypes()
##  + override returns $anl->{mootLabel} or empty list, depending on $anl->{bytoken}
sub typeKeys {
  my ($anl,$opts) = @_;
  return ($opts->{"$anl->{label}.bytoken"} // $anl->{bytoken} ? qw() : $_[0]{mootLabel});
}

1; ##-- be happy

__END__
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Analyzer::MootSub - post-processing for moot PoS tagger in DTA chain

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Analyzer::MootSub;
 
 ##========================================================================
 ## Methods
 
 $obj = CLASS_OR_OBJ->new(%args);
 $bool = $anl->doAnalyze(\%opts, $name);
 @keys = $anl->typeKeys();
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

This class provides a
L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> implementation
for post-processing of moot PoS tagger output in the DTA analysis chain
L<DTA::CAB::Chain::DTA|DTA::CAB::Chain::DTA>.  In particular,
this class tweaks $tok->{moot}{word} and instantiates $tok->{moot}{lemma}.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::MootSub: Methods
=pod

=head2 Methods

=over 4

=item Variable: %LITERAL_WORD_TAGS

(undocumented)

=item new

 $obj = CLASS_OR_OBJ->new(%args);

object structure, %args:

 mootLabel => $label,    ##-- label for Moot tagger object (default='moot')
 lz => $lemmatizer,      ##-- DTA::CAB::Analyzer::Lemmatizer sub-object

=item doAnalyze

 $bool = $anl->doAnalyze(\%opts, $name);

override: only allow analyzeSentences()

=item analyzeSentences

Actual analysis guts.

=item typeKeys

 @keys = $anl->typeKeys();

Returns list of type-wise keys to be expanded for this analyzer by expandTypes()
Override returns @$anl{qw(mootLabel)}.

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl
=pod



=cut

##======================================================================
## Footer
##======================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
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
