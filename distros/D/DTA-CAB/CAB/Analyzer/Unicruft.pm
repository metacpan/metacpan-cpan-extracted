## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::Unicruft.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: latin-1 approximator

package DTA::CAB::Analyzer::Unicruft;

use DTA::CAB::Analyzer;
use DTA::CAB::Datum ':all';
use DTA::CAB::Token;

use Unicruft;
use Unicode::Normalize; ##-- compatibility decomposition 'KD' (see Unicode TR #15)
#use Unicode::UCD;       ##-- unicode character names, info, etc.
#use Unicode::CharName;  ##-- ... faster access to character name, block
#use Text::Unidecode;    ##-- last-ditch effort: transliterate to ASCII

use Encode qw(encode decode);
use IO::File;
use Carp;

use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Analyzer);

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure, new:
##     label => 'xlit',        ##-- analyzer label
##  + object structure, INHERITED from Analyzer:
##     label => $label,        ##-- analyzer label (default: from class name)
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   ##-- options
			   label => 'xlit',

			   ##-- user args
			   @_
			  );
}

##==============================================================================
## Methods: version

## $version_or_undef = $anl->version()
sub version {
  return "Unicruft-${Unicruft::VERSION} libunicruft-".Unicruft::library_version();
}

##==============================================================================
## Methods: I/O
##==============================================================================

## $bool = $anl->ensureLoaded()
##  + ensures analysis data is loaded
##  + always returns 1, but reports Unicruft module + library version if (!$anl->{loaded})
sub ensureLoaded {
  my $anl = shift;
  $anl->info("using Unicruft.xs v$Unicruft::VERSION; libunicruft v", Unicruft::library_version)
    if (!$anl->{loaded});
  return $anl->{loaded}=1;
}

##==============================================================================
## Methods: Analysis: v1.x
##==============================================================================

## $doc = $xlit->analyzeTypes($doc,\%types,\%opts)
##  + perform type-wise analysis of all (text) types in values(%types)
##  + sets:
##      $tok->{$anl->{label}} = { latin1Text=>$latin1Text, isLatin1=>$isLatin1, isLatinExt=>$isLatinExt }
##    with:
##      $latin1Text = $str     ##-- best latin-1 approximation of $token->{text}
##      $isLatin1   = $bool    ##-- true iff $token->{text} is losslessly encodable as latin1
##      $isLatinExt = $bool,   ##-- true iff $token->{text} is losslessly encodable as latin-extended
sub analyzeTypes {
  my ($xlit,$doc,$types,$opts) = @_;
  $types = $doc->types if (!$types);
  my $akey = $xlit->{label};

  my ($tok, $w,$uc, $ld, $isLatin1,$isLatinExt);
  foreach $tok (values(%$types)) {
    next if (defined($tok->{$akey})); ##-- avoid re-analysis
    $w   = $tok->{text};

    ##-- 2010-01-23: Mantis Bug #140: 'µ'="\x{b5}" gets mapped to 'm' rather than
    ##   + (unicruft-v0.07) 'u'
    ##   + (unicruft-v0.08) 'µ' (identity)
    ##   + problem is NFKC-decomposition which maps
    ##       'µ'="\x{b5}" = Latin1 Supplement / MICRO SIGN
    ##     to
    ##       "\x{03bc}" = Greek and Coptic / GREEK SMALL LETTER MU
    ##   + solution (hack): use NFC (canonical composition only)
    ##     rather than NFKC (compatibility decomposition + canonical composition) here,
    ##     and let Unicruft take care of decomposition
    ##   + potentially problematic cases (from unicode normalization form techreport
    ##     @ http://unicode.org/reports/tr15/ : fi ligature, 2^5, long-S + diacritics)
    ##     are all handled correctly by unicruft
    #$uc  = Unicode::Normalize::NFKC($w); ##-- compatibility(?) decomposition + canonical composition
    $uc  = Unicode::Normalize::NFC($w);   ##-- canonical composition only

    ##-- construct latin-1/de approximation
    $ld = decode('latin1',Unicruft::utf8_to_latin1_de($uc));

    ##-- special handling for double-initial-caps, e.g. "AUf", "CHristus", "GOtt", etc.
    $ld = ucfirst(lc($ld)) if ($ld =~ /^[[:upper:]]{2}[[:lower:]]+$/);

    ##-- properties
    if (
	#$uc !~ m([^\p{inBasicLatin}\p{inLatin1Supplement}]) #)
	$uc  =~ m(^[\x{00}-\x{ff}]*$) #)
       )
      {
	$isLatin1 = $isLatinExt = 1;
      }
    elsif ($uc =~ m(^[\x{00}-\x{ff}\p{Latin}\p{IsPunct}\p{IsMark}\x{a75b}\x{fffc}-\x{ffff}]*$))
      {
	$isLatin1 = 0;
	$isLatinExt = 1;
      }
    else
      {
	$isLatin1 = $isLatinExt = 0;
      }

    ##-- update token
    $tok->{$akey} = { latin1Text=>$ld, isLatin1=>$isLatin1, isLatinExt=>$isLatinExt };
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

DTA::CAB::Analyzer::Unicruft - latin-1 approximator using libunicruft

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Analyzer::Unicruft;
 
 $xl = DTA::CAB::Analyzer::Unicruft->new(%args);
  
 $bool = $xl->ensureLoaded();

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

This module replaces the (now obsolete) DTA::CAB::Analyzer::Transliterator module.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Unicruft: Globals
=pod

=head2 Globals

=over 4

=item @ISA

DTA::CAB::Analyzer::Unicruft
inherits from
L<DTA::CAB::Analyzer|DTA::CAB::Analyzer>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Unicruft: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $xl = CLASS_OR_OBJ->new(%args);

%args, %$xl:

 analysisKey => $key,   ##-- token analysis key (default='xlit')

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Unicruft: Methods: I/O
=pod

=head2 Methods: I/O

=over 4

=item ensureLoaded

 $bool = $aut->ensureLoaded();

Override: ensures analysis data is loaded

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
