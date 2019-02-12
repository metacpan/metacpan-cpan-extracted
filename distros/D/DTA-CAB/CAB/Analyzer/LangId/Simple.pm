## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::LangId::Simple.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: language identification using stopword lists

##==============================================================================
package DTA::CAB::Analyzer::LangId::Simple;
use DTA::CAB::Analyzer::Dict::Json;
use Carp;
use strict;
our @ISA = qw(DTA::CAB::Analyzer::Dict::Json);

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure: see DTA::CAB::Analyzer::Dict::Json
sub new {
  my $that = shift;
  my $lid = $that->SUPER::new(
			      ##-- analysis selection
			      label      => 'lang',
			      #slabel     => 'lang', ##-- sentence-level label
			      #vlabel     => 'lang_counts', ##-- DEBUG: verbose sentence-level counts, empty or undef for none
			      defaultLang => 'de',
			      defaultCount => 0.1,  ##-- bonus count for default lang (characters)
			      minSentLen   => 2,    ##-- minimum number of tokens in sentence required before guessing
			      minSentChars => 8,    ##-- minimum number of text characters in sentence required begore guessing

			      ##-- user args
			      @_
			     );
  return $lid;
}

##==============================================================================
## Methods: Prepare

## $bool = $dic->ensureLoaded()
##  + ensures analyzer data is loaded from default files
sub ensureLoaded {
  my $lid = shift;
  return $lid->SUPER::ensureLoaded(@_) && $lid->decodeDictValues();
}


##==============================================================================
## Methods: Analysis

##------------------------------------------------------------------------
## Methods: Analysis: v1.x: API

## $doc = $anl->analyzeTypes($doc,\%types,\%opts)
##  + perform type-wise analysis of all (text) types in $doc->{types}
sub analyzeTypes {
  my ($lid,$doc,$types,$opts) = @_;

  ##-- common vars
  my $label  = $lid->{label} || $lid->defaultLabel;
  my $slabel = $lid->{slabel} || $label;
  my $swd    = $lid->{ttd}{dict};
  my $allow_re = defined($lid->{allowRegex}) ? qr($lid->{allowRegex}) : undef;
  my $l0     = $lid->{defaultLang};
  my (@l);

  ##-- word-wise analysis
  my ($l,$prev);
  foreach (values %$types) {
    next if (defined($allow_re) && $_->{text} !~ $allow_re);

    ##-- list check
    @l = (defined($l=$swd->{lc($_->{text})}) ? @$l : qw());

    ##-- local analysis check(s)
    if (!$_->{xlit} || !$_->{xlit}{isLatinExt}) {
      if    ($_->{text} =~ /^\p{Greek}{2,}$/)  { push(@l, 'el'); }
      elsif ($_->{text} =~ /^\p{Hebrew}{2,}$/) { push(@l, 'he'); }
      elsif ($_->{text} =~ /^\p{Arabic}{2,}$/) { push(@l, 'ar'); }
      elsif ($_->{text} =~ /[[:alpha:]]{2,}/ && $_->{text} !~ /\p{Latin}/) { push(@l,'xy'); } ##-- combination of latin and non-latin characters
    }
    if    ($_->{text} =~ /[\p{InMathematicalOperators}]/) { push(@l,'xy'); }
    elsif ($_->{text} =~ /[[:alpha:]](?:.?)[[:digit:]]/ && $_->{text} !~ m{^[a-zA-Z]+://}) {
      ##-- don't treat links as 'xy' specials
      push(@l,'xy');
    }

    ##-- latin: use {mlatin}, but don't count known NE; workaround for mantis bug #6737
    push(@l, 'la') if ($_->{mlatin} && (!$_->{morph} || !grep {$_->{hi} =~ /\[_NE\]/} @{$_->{morph}}));

    ##-- default language: use {morph} and {msafe}, disregarding NE,FM
    push(@l, $l0) if ($l0 && $_->{morph} && ($_->{msafe}//1) && grep {$_->{hi} !~ /\[_(?:FM|NE)\]/} @{$_->{morph}});

    ##-- exlex language (not really)
    #push(@l, $l0, 'exlex') if (($_->{exlex} && $_->{exlex} ne $_->{text}));

    ##-- make unique
    if (@l) {
      $prev = '';
      $_->{$label} = [map {$prev eq $_ ? qw() : ($prev=$_)} sort @l];
    } else {
      $_->{$label} = undef;
    }
  }

  return $doc;
}


## $doc = $anl->analyzeSentences($doc,\%opts)
sub analyzeSentences {
  my ($lid,$doc,$opts) = @_;

  ##-- common vars
  my $label  = $lid->{label} || $lid->defaultLabel;
  my $slabel = $lid->{slabel} || $label;
  my $vlabel = $lid->{vlabel};
  my $l0     = $lid->{defaultLang} // '';
  my $n0     = $l0 ? ($lid->{defaultCount}//0) : 0;
  my $minlen = $lid->{minSentLen} // 0;
  my $minchrs= $lid->{minSentChars} // 0;
  my $nil    = [];

  ##-- ye olde loope
  my (%ln,$s,$nchrs,$l,$n,$w);
  foreach $s (@{$doc->{body}}) {
    ##-- check minimum sentence length in tokens
    next if (@{$s->{tokens}} < $minlen);

    ##-- count number of stopword-CHARACTERS per language
    %ln = ($l0=>$n0);
    $nchrs = 0;
    foreach $w (@{$s->{tokens}}) {
      $nchrs  += length($w->{text});
      $ln{$_} += length($w->{text}) foreach (@{$w->{$label}//$nil});
    }
    next if ($nchrs < $minchrs);

    ##-- get top-ranked language for this sentence
    ($l,$n) = ($l0,$n0);
    foreach (sort keys %ln) {
      ($l,$n)=($_,$ln{$_}) if ($n < $ln{$_});
    }
    $s->{$slabel} = $l;
    $s->{$vlabel} = {%ln} if ($vlabel); ##-- DEBUG
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

=encoding utf8

=head1 NAME

DTA::CAB::Analyzer::LangId::Simple - simple language guesser using stopword lists

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Analyzer::LangId::Simple;
 
 ##========================================================================
 ## Methods: Prepare
 
 $bool = $lid->ensureLoaded();
 
 ##========================================================================
 ## Methods: Analysis: v1.x: API
 
 $doc = $anl->analyzeTypes($doc,\%types,\%opts);
 $doc = $anl->analyzeSentences($doc,\%opts);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::LangId::Simple: Methods: Constructors etc.
=pod

=head2 Methods: Constructors etc.

=over 4

=item new

 $obj = CLASS_OR_OBJ->new(%args)

Creates a new simple language-guesser object, which inherits
from L<DTA::CAB::Analyzer::Dict::Json|DTA::CAB::Analyzer::Dict::Json>.
Known options in %args:

 ##-- analysis selection
 label      => 'lang', ##-- analyzer label
 defaultLang => 'de',  ##-- default language (if e.g. known by 'morph')
 defaultCount => 0.1,  ##-- bonus count for default lang (characters)
 minSentLen   => 2,    ##-- minimum number of tokens in sentence required before guessing
 minSentChars => 8,    ##-- minimum number of text characters in sentence required begore guessing

=back

=cut


##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::LangId::Simple: Methods: Prepare
=pod

=head2 Methods: Prepare

=over 4

=item ensureLoaded

 $bool = $lid->ensureLoaded();

ensures analyzer data is loaded from default files.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::LangId::Simple: Methods: Analysis: v1.x: API
=pod

=head2 Methods: Analysis: v1.x: API

=over 4

=item analyzeTypes

 $doc = $anl->analyzeTypes($doc,\%types,\%opts);

perform type-wise analysis of all (text) types in $doc-E<gt>{types}

=item analyzeSentences

 $doc = $anl->analyzeSentences($doc,\%opts);

perform sentence-wise analysis of all sentences in $doc-E<gt>{body}.

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

Copyright (C) 2013-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<dta-cab-convert.perl(1)|dta-cab-convert.perl>,
L<dta-cab-http-server.perl(1)|dta-cab-http-server.perl>,
L<dta-cab-http-client.perl(1)|dta-cab-http-client.perl>,
L<dta-cab-xmlrpc-server.perl(1)|dta-cab-xmlrpc-server.perl>,
L<dta-cab-xmlrpc-client.perl(1)|dta-cab-xmlrpc-client.perl>,
L<DTA::CAB::Server(3pm)|DTA::CAB::Server>,
L<DTA::CAB::Client(3pm)|DTA::CAB::Client>,
L<DTA::CAB::Format(3pm)|DTA::CAB::Format>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...

=cut
