## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::Raw::Perl.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser: raw untokenized text (pure-perl hack)

package DTA::CAB::Format::Raw::Perl;
use DTA::CAB::Format;
use DTA::CAB::Format::Raw::Base;
use DTA::CAB::Datum ':all';
use IO::File;
use Encode qw(encode decode);
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format::Raw::Base);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>'raw-perl', filenameRegex=>qr/\.(?i:raw-perl|txt-perl)$/);
}

## %ABBREVS
##  + default abbreviations
##  + set below
our (%ABBREVS);

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: assumed HASH
##    {
##     ##-- Input
##     doc => $doc,                    ##-- buffered input document
##     abbrevs => \%abbrevs,           ##-- hash of known abbrevs (default: \%ABBREVS)
##
##     ##-- Output
##     outbuf    => $stringBuffer,     ##-- buffered output: DISABLED
##     #level    => $formatLevel,      ##-- n/a
##
##     ##-- Common
##     utf8 => $bool,
sub new {
  my $that = shift;
  my $fmt = bless({
		   ##-- common
		   utf8 => 1,

		   ##-- input
		   doc => undef,
		   abbrevs => \%ABBREVS,

		   ##-- output
		   #outbuf => '',

		   ##-- user args
		   @_
		  }, ref($that)||$that);
  return $fmt;
}

##==============================================================================
## Methods: Persistence
##==============================================================================

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
##  + default just returns empty list
sub noSaveKeys {
  return (shift->SUPER::noSaveKeys(), qw(doc outbuf));
}

##==============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Input selection

## $fmt = $fmt->close()
sub close {
  delete($_[0]{doc});
  return $_[0]->SUPER::close(@_[1..$#_]);
}

## $fmt = $fmt->fromString( $string)
## $fmt = $fmt->fromString(\$string)
##  + select input from string $string
sub fromString {
  my $fmt = shift;
  $fmt->close();
  return $fmt->parseRawString(ref($_[0]) ? $_[0] : \$_[0]);
}

## $fmt = $fmt->fromFh($fh)
##  + override calls $fmt->fromFh_str()
sub fromFh {
  return $_[0]->fromFh_str(@_[1..$#_]);
}

##--------------------------------------------------------------
## Methods: Input: Local

## $fmt = $fmt->parseRawString(\$str)
##  + guts for fromString(): parse string $str into local document buffer.
sub parseRawString {
  my ($fmt,$src) = @_;
  utf8::decode($$src) if ($fmt->{utf8} && !utf8::is_utf8($$src));

  ##-- step 1: basic tokenization
  my (@toks);
  while ($$src =~ m/(
		      (?:([[:alpha:]_\-н\#\@]+)[\-м](?:\n\s*)([[:alpha:]_\-н\#\@]+))   ##-- line-broken alphabetics
		    | (?i:[IVXLCDM\#\@]+\.)                             ##-- dotted roman numerals (hack)
		    | (?:[[:alpha:]\#\@]\.)                             ##-- dotted single-letter abbreviations
		    | (?:[[:digit:]\#\@]+[[:alpha:]_\#\@]+)             ##-- numbers with optional alphabetic suffixes
		    | (?:[\-\+]?[[:digit:]_\#\@]*[[:digit:]_\,\.\#\@]+) ##-- comma- and\/or dot-separated numbers
		    | (?:\,\,|\`\`|\'\'|\-+|\.\.+|\[Formel\])           ##-- special punctuation sequences
		    | (?:[[:alpha:]_\-мн\#\@]+)                         ##-- "normal" alphabetics (with "#", "@" ~= unknown)
		    | (?:[[:punct:]]+)                                  ##-- "normal" punctuation characters
		    | (?:[^[:punct:][:digit:][:space:]]+)               ##-- "strange" alaphbetic tokens
		    | (?:\S+)                                           ##-- HACK: anything else
		    )
		   /xsg)
    {
      push(@toks, (defined($2) ? "$2$3" : $1));
    }

  ##-- step 2: abbreviation & eos detection
  my $abbrevs = $fmt->{abbrevs};
  my $s     = [];
  my @sents = ($s);
  my ($toki);
  for ($toki=0; $toki <= $#toks; $toki++) {
    if (exists($abbrevs->{$toks[$toki]}) && $toki < $#toks && $toks[$toki+1] eq '.') {
      ##-- abbreviation
      push(@$s, "$toks[$toki].");
      $toki++;
    }
    elsif ($toks[$toki] =~ /^[\.\?\!]+$/) {
      ##-- sentence-final punctuation
      push(@$s, $toks[$toki]);
      push(@sents, $s=[]);
    }
    else {
      ##-- normal token
      push(@$s, $toks[$toki]);
    }
  }
  pop(@sents) if (!@{$sents[$#sents]});

  ##-- step 3: build doc
  foreach (@sents) {
    @$_ = map { {text=>$_} } @$_;
  }
  $fmt->{doc} = bless({body=>[map { {tokens=>$_} } @sents]}, 'DTA::CAB::Document');
  return $fmt;
}


##--------------------------------------------------------------
## Methods: Input: Generic API

## $doc = $fmt->parseDocument()
sub parseDocument {
  return $_[0]{doc};
}


##==============================================================================
## Methods: Output
##  + output not supported
##==============================================================================

##--------------------------------------------------------------
## Methods: Output: Generic

## $type = $fmt->mimeType()
##  + default returns text/plain
sub mimeType { return 'text/plain'; }

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format
sub defaultExtension { return '.raw'; }


##==============================================================================
## Initialization
BEGIN {
  ## @ABBREVS: most frequent 128 abbreviations from DTA (as of Wed, 01 Dec 2010 11:26:04 +0100)
  ##  + derived from file ../automata/eqlemma/dta-abbrevs.nontrivial.tfa
  ##    - itself derived by hand from ../automata/eqlemma/cab.toka.db, ../automata/words/dta-words.tf
  ##      using Lingua::TT hackery and Data::Dumper
  my @ABBREVS =
    (
     'Abb',
     "Ab\x{17f}",
     'Anm',
     'Ann',
     'Arch',
     'Art',
     'Aufl',
     'Bd',
     'Bde',
     'Br',
     'Cap',
     'Ch',
     'Chr',
     'Co',
     'Cod',
     'Ctr',
     "Di\x{17f}\x{17f}",
     'Dr',
     'Ew',
     'Fig',
     'Fr',
     "Ge\x{17f}",
     "Ge\x{17f}ch",
     'Gr',
     'Hist',
     'Hr',
     'Hrn',
     'Jahrh',
     'Journ',
     'Kap',
     'Kilogr',
     "K\x{f6}nigl",
     'Lib',
     'Lit',
     'Matth',
     'Mill',
     'Mr',
     'No',
     'Nov',
     'Nr',
     'Num',
     'Ol',
     'Pal',
     'Pf',
     'Pfd',
     'Pfr',
     'Plut',
     'Prof',
     'Proz',
     "Re\x{17f}cr",
     'Sal',
     'Sept',
     'Sr',
     'St',
     'StGB',
     'Staatsr',
     'Str',
     'Tab',
     'Taf',
     'Th',
     'Thl',
     'Thlr',
     'Tit',
     'Tom',
     'Verf',
     'Vergl',
     'Vgl',
     'Vol',
     'Zeitschr',
     'Ziff',
     'acc',
     'adj',
     "ag\x{17f}",
     'ahd',
     'altn',
     "angel\x{17f}",
     'art',
     'betr',
     'cap',
     'cit',
     'dat',
     'dergl',
     'dgl',
     'diss',
     'ed',
     'engl',
     'eod',
     'etc',
     'fem',
     'ff',
     'fg',
     'fig',
     'fl',
     'fr',
     'geb',
     'gl',
     'goth',
     'gr',
     'griech',
     'jun',
     'ker',
     'lat',
     'lib',
     'lit',
     "ma\x{17f}c",
     'med',
     'mhd',
     'min',
     'nat',
     'neutr',
     'nhd',
     'nom',
     'pag',
     'part',
     'pl',
     'pr',
     'praes',
     'praet',
     "prae\x{17f}",
     'resp',
     'sing',
     'tab',
     'urspr',
     'vergl',
     'vgl',
     "zu\x{17f}",
     "\x{17f}t",
     "\x{17f}ub\x{17f}t",

     "usw",
    );

  %ABBREVS = map {($_=>undef)} @ABBREVS;
}



1; ##-- be happy

__END__
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Format::Raw::Perl - Document parser: raw untokenized text, pure-perl hack

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Format::Raw::Perl;
 
 ##========================================================================
 ## Methods
 
 $fmt = DTA::CAB::Format::Raw::Perl->new(%args);
 @keys = $class_or_obj->noSaveKeys();
 $fmt = $fmt->close();
 $fmt = $fmt->parseRawString(\$str);
 $doc = $fmt->parseDocument();
 $type = $fmt->mimeType();
 $ext = $fmt->defaultExtension();
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Format::Raw::Perl
is an input L<DTA::CAB::Format|DTA::CAB::Format> subclass
for untokenized raw string intput using pure perl.
It uses L<DTA::CAB::Format::Raw::Base|DTA::CAB::Format::Raw::Base> for output.


=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Raw::Perl: Globals
=pod

=head2 Globals

=over 4

=item Variable: %DTA::CAB::Format::Raw::Perl::ABBREVS

Pseudo-set of known abbreviations (hack).

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Raw::Perl: Constructors etc.
=pod

=head2 Methods

=over 4

=item new

 $fmt = CLASS_OR_OBJ->new(%args);

%$fmt, %args:

 ##-- Input
 doc => $doc,                    ##-- buffered input document
 abbrevs => \%abbrevs,           ##-- hash of known abbrevs (default: \%ABBREVS)
 ##
 ##-- Output (n/a)
 outbuf    => $stringBuffer,     ##-- buffered output: DISABLED
 #level    => $formatLevel,      ##-- n/a
 ##
 ##-- Common
 encoding => $inputEncoding,     ##-- default: UTF-8, where applicable

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();


Returns list of keys not to be saved
Override returns qw(doc outbuf).

=item close

 $fmt = $fmt->close();

Deletes buffered input document, if any.

=item fromString

 $fmt = $fmt->fromString($string)

Select input from string $string.

=item parseRawString

 $fmt = $fmt->parseRawString(\$str);

Guts for fromString(): parse string $str into local document buffer.

=item parseDocument

 $doc = $fmt->parseDocument();

Wrapper for $fmt-E<gt>{doc}.

=item mimeType

 $type = $fmt->mimeType();

Default returns text/plain.

=item defaultExtension

 $ext = $fmt->defaultExtension();

Returns default filename extension for this format, here '.raw'.

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

Copyright (C) 2010-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-convert.perl(1)|dta-cab-convert.perl>,
L<DTA::CAB::Format::Builtin(3pm)|DTA::CAB::Format::Builtin>,
L<DTA::CAB::Format(3pm)|DTA::CAB::Format>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...



=cut
