## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::Lemmatizer.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: lemma extractor for TAGH analyses or bare text

package DTA::CAB::Analyzer::Lemmatizer;
use DTA::CAB::Analyzer;
use Carp;
use strict;
our @ISA = qw(DTA::CAB::Analyzer);

##==============================================================================
## Globals

## $GET_MORPH
##  + code string: \@morph_analyses = "$GET_MORPH"->()
##  + available vars: $tok, $lz
our $GET_MORPH = '$tok->{morph}';

## $GET_DMOOT_MORPH
##  + code string: \@morph_analyses = "$GET_DMOOT_MORPH"->()
##  + available vars: $tok, $lz
our $GET_DMOOT_MORPH = '$tok->{dmoot} ? $tok->{dmoot}{morph} : undef';

## $GET_TEXT
##  + code string: get text for analysis $_
##  + available vars: $tok, $tokm (array of analyses), $ma (current analysis), $lz (analyzer obj),
our $GET_TEXT = '$tok->{xlit} ? $tok->{xlit}{latin1Text} : $tok->{text}';

## $GET_MOOT_ANALYSES
##  + code string: \@morph_analyses = "$GET_DMOOT_MORPH"->()
##  + available vars: $tok, $lz
our $GET_MOOT_ANALYSES = '$tok->{moot} ? $tok->{moot}{analyses} : undef';

## $GET_MOOT_TEXT
##  + code string: get text for analysis $_
##  + available vars: $tok, $tokm (array of analyses), $ma (current analysis), $lz (analyzer obj),
our $GET_MOOT_TEXT = '$tok->{moot} ? $tok->{moot}{word} : ('.$GET_TEXT.')';

##==============================================================================
## Methods

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure, %args:
##     analyzeGet   => $code,    ##-- pseudo-accessor: @morph_analyses = "$code"->(\@toks)
##     analyzeWhich => $which,   ##-- e.g. 'Types','Tokens','Sentences','Local': default=Types
##                               ##   + the underlying analysis is always performed by the analyzeTypes() method! (default='Types')
##     analyzeLabel => $label,   ##-- ouput label (default='lemma')
sub new {
  my $that = shift;
  my $lz = $that->SUPER::new(
			     ##-- analysis selection
			     label => 'lemma',
			     analyzeLabel => 'lemma',
			     analyzeGet => $GET_MORPH,
			     analyzeGetText => $GET_TEXT,
			     analyzeWhich => 'Types',
			     #typeKeys => undef,

			     ##-- user args
			     @_
			    );
  return $lz;
}

## @keys = $anl->typeKeys()
##  + returns list of type-wise keys to be expanded for this analyzer by expandTypes()
##  + override returns @{$lt->{typeKeys}}
sub typeKeys {
  return @{$_[0]{typeKeys}} if ($_[0]{typeKeys} && @{$_[0]{typeKeys}});
  return qw();
}

## $bool = $anl->doAnalyze(\%opts, $name)
##  + override: only allow analyzeSentences()
sub doAnalyze {
  my $anl = shift;
  return 0 if (defined($_[1]) && $_[1] ne $anl->{analyzeWhich});
  return $anl->SUPER::doAnalyze(@_);
}

## \@toks = $anl->_analyzeGuts(\@toks,\%opts)
##  + guts: analyze all tokens in \@toks
sub _analyzeGuts {
  my ($lz,$toks,$opts) = @_;

  ##-- common vars
  my $lab = $lz->{label};
  my $alab = defined($lz->{analyzeLabel}) ? $lz->{analyzeLabel} : $lab;
  my $lab_txt = $lab."_text";
  my $lab_key = $lab."_key";

  ##-- prepare map $key2a = { "$text\t$hi" => $analysis, ... }
  my $key2a = {};
  my ($tok,$tokm,$ma,$txt,$key);
  my $prep_code =
    'foreach $tok (@$toks) {
       next if (!($tokm='.$lz->{analyzeGet}.'));
       foreach (grep {defined($_)} @$tokm) {
         $txt = $_->{$lab_txt} = '.$lz->{analyzeGetText}.';
         $key = $_->{$lab_key} = $txt."\t".(defined($_->{hi}) ? $_->{hi} : $_->{details});
         next if (exists($key2a->{$key}));
         $key2a->{$key} = $_;
       }
     }';
  my $prep_sub = eval "sub { $prep_code }";
  $lz->logcluck("_analyzeGuts(): could not compile preprocessing sub {$prep_code}: $@") if (!$prep_sub);
  $prep_sub->();

  ##-- lemmatize, type-wise by (text+analysis)-pair
  my ($lemma,$tag,$lemmaFromMorph);
  foreach (values %$key2a) {
    $lemma = defined($_->{hi}) ? $_->{hi} : $_->{details};
    if (defined($lemma) && $lemma ne '' && $lemma =~ /^[^\]]+\[/) { ##-- tagh analysis (vs. tokenizer-supplied analysis)
      #$lemma =~ s/\~e?t(?=\W)/\~en/g;	   ##-- rename verb inflection morphs [BUG: l("Christ/N\en~tum[_NN]") = Christenenum]
      $lemma =~ s/\[<([^\>\]]*)>\]/<$1>/g; ##-- unquote taghm-2.5 "diamond-tags", e.g "kurz<A>\@Stiel<N>~ig[_ADJD]<none>"
      $lemma =~ s/\[.*$//;	           ##-- trim everything after first non-character symbol
      #$lemma =~ s/(?:\/[A-Za-z]{1,2})|(?:\bge\\\|)|(?:[\\\~\|\=\+\#\x{ac}])//g;  ##-- hack: remove "ge\|" prefixes too (but not e.g. "ver\|", "be\|", etc.)
      $lemma =~ s/(?:\/[A-Za-z]{1,2})|(?:\[?<[^>]+>\]?)|(?:[\@\\\~\|\=\+\#\x{ac}])//g;   ##-- unhack: don't remove "ge\|" prefixes (for consistency e.g. with dwds-kc20)
      $lemmaFromMorph = 1;
    } else {
      $lemma = $_->{$lab_txt};
      $lemma =~ s/\x{ac}//g;
      $lemmaFromMorph = 0;
    }
    ##-- extract tag if available
    $tag = $_->{tag} || ($_->{hi} && $_->{hi} =~ m/\[_([^\]]+)\]/ ? $1 : '');
    ##
    ##-- normalization
    $lemma =~ s/(?:^\s+|\s+\z)//g;
    $lemma =~ s/\s+/_/g;
    if ($lemmaFromMorph && $tag =~ /^(?:NE|XY)$/) {
      ##-- retain morphology-supplied original case for names and symbols
      ;
    }
    elsif ($_->{tag} ne 'XY') {
      ##-- lower-case all lemmata here, otherwise Anschlußstelle->AnschlußStelle (mantis #23127)
      $lemma = lc($lemma);
      $lemma =~ s/(?:^|(?<=[\-\_]))(.)/\U$1\E/g
	if (#$_->{tag} ? ($_->{tag}=~m/^N/) :  ##-- disabled 2016-06-01 for Helsinki-style english morphology; see ucTags key in Analyzer::MootSub
	    ($_->{hi} && $_->{hi}=~m/\[_N/)
	   );
    }
    $_->{$alab} = $lemma;
  }

  ##-- postprocessing: re-expand types
  my $postp_code =
    'foreach $tok (@$toks) {
       next if (!($tokm='.$lz->{analyzeGet}.'));
       foreach (grep {defined($_)} @$tokm) {
         $_->{$alab} = $key2a->{$_->{$lab_key}}{$alab};
         delete(@$_{$lab_key,$lab_txt});
       }
     }';
  my $postp_sub = eval "sub { $postp_code }";
  $lz->logcluck("_analyzeGuts(): could not compile postprocessing sub {$postp_code}: $@") if (!$postp_sub);
  $postp_sub->();

  return $toks;
}


## $doc = $anl->analyzeTypes($doc,\%types,\%opts)
##  + perform type-wise analysis of all (text) types in $doc->{types}
sub analyzeTypes {
  my ($lz,$doc,$types,$opts) = @_;
  return $doc if ($lz->{analyzeWhich} ne 'Types');
  $lz->_analyzeGuts([values %$types],$opts);
  return $doc;
}

## $doc = $anl->analyzeOther($which, $doc,\%opts)
##  + analyze all tokens in $doc
sub analyzeOther {
  my ($anl,$which,$doc,$opts) = @_;
  return $doc if (defined($which) && $which ne $anl->{analyzeWhich});
  $anl->_analyzeGuts([map {@{$_->{tokens}}} @{$doc->{body}}],$opts);
  return $doc;
}

sub analyzeTokens { return $_[0]->analyzeOther('Tokens',@_[1..$#_]); }
sub analyzeSentences { return $_[0]->analyzeOther('Sentences',@_[1..$#_]); }
sub analyzeLocal { return $_[0]->analyzeOther('Local',@_[1..$#_]); }
sub analyzeClean { return $_[0]->analyzeOther('Clean',@_[1..$#_]); }



1; ##-- be happy

__END__
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Analyzer::Lemmatizer - lemma extractor for TAGH analyses or bare text

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Analyzer::Lemmatizer;
 
 ##========================================================================
 ## Methods
 
 $obj = $CLASS_OR_OBJ->new(%args);
 @keys = $anl->typeKeys();
 $bool = $anl->doAnalyze(\%opts, $name);
 \@toks = $anl->_analyzeGuts(\@toks,\%opts);
 $doc = $anl->analyzeTypes($doc,\%types,\%opts);
 $doc = $anl->analyzeOther($which, $doc,\%opts);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Lemmatizer: Globals
=pod

=head2 Globals

=over 4

=item Variable: $GET_MORPH

 \@morph_analyses = "$GET_MORPH"->();

Code string;
available vars: $tok, $lz

=item Variable: $GET_DMOOT_MORPH

 \@morph_analyses = "$GET_DMOOT_MORPH"->();


code string;
available vars: $tok, $lz

=item Variable: $GET_TEXT

 $text = "$GET_TEXT"->();

Get text for analysis $_.
Available vars: $tok, $tokm (array of analyses), $ma (current analysis), $lz (analyzer obj).

=item Variable: $GET_MOOT_ANALYSES

 \@morph_analyses = "$GET_DMOOT_MORPH"->();

code string;
available vars: $tok, $lz

=item Variable: $GET_MOOT_TEXT

 $txt = "$GET_MOOT_TEXT"->();

code string: get text for analysis $_.
available vars: $tok, $tokm (array of analyses), $ma (current analysis), $lz (analyzer obj),

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Lemmatizer: Methods
=pod

=head2 Methods

=over 4

=item new

 $obj = CLASS_OR_OBJ->new(%args);

object structure, %args:

 analyzeGet   => $code,    ##-- pseudo-accessor: @morph_analyses = "$code"-E<gt>(\@toks)
 analyzeWhich => $which,   ##-- e.g. 'Types','Tokens','Sentences','Local': default=Types
                           ##   + the underlying analysis is always performed by the analyzeTypes() method! (default='Types')
 analyzeLabel => $label,   ##-- ouput label (default='lemma')

=item typeKeys

 @keys = $anl->typeKeys();

Returns list of type-wise keys to be expanded for this analyzer by expandTypes()
Override returns @{$lt-E<gt>{typeKeys}}.

=item doAnalyze

 $bool = $anl->doAnalyze(\%opts, $name);

Override: only allow analyzeSentences().

=item _analyzeGuts

 \@toks = $anl->_analyzeGuts(\@toks,\%opts);

guts: analyze all tokens in \@toks

=item analyzeTypes

 $doc = $anl->analyzeTypes($doc,\%types,\%opts);

perform type-wise analysis of all (text) types in $doc-E<gt>{types}

=item analyzeOther

 $doc = $anl->analyzeOther($which, $doc,\%opts);

analyze all tokens in $doc

=item analyzeTokens

wrapper for analyzeOther()

=item analyzeSentences

wrapper for analyzeOther()

=item analyzeLocal

wrapper for analyzeOther()

=item analyzeClean

wrapper for analyzeOther()

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
