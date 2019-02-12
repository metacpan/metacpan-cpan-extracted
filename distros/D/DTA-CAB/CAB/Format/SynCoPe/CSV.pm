## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::SynCoPe::CSV.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser: SynCoPe CSV (for NE-recognizer)

package DTA::CAB::Format::SynCoPe::CSV;
use DTA::CAB::Format;
use DTA::CAB::Format::TT;
use DTA::CAB::Datum ':all';
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format::TT);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>'syncope-csv', filenameRegex=>qr/\.(?i:syn(?:cope)?[-\.](?:csv|tsv|tab)|)$/);
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>'syncope-tab');
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>'syn-csv');
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>'syn-tab');
}

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: assumed HASH
##    (
##     ##---- Input
##     doc => $doc,                    ##-- buffered input document
##
##     ##---- Output
##     syntags => $bool,	       ##-- output POS-tags as 1st field? (default: true; for SynCoPe NER >= 2013-12-09)
##     #level    => $formatLevel,      ##-- output formatting level: n/a
##     #outbuf    => $stringBuffer,    ##-- buffered output
##     outbase => $outputBasename,     ##-- for use by syncope (default: $inputDoc->{base})
##
##     ##---- Common
##     utf8  => $bool,                 ##-- default: 1
##    )
sub new {
  my $that = shift;
  return $that->SUPER::new(syntags=>1, @_);
}

##==============================================================================
## Methods: Persistence
##==============================================================================

##==============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Local

## $fmt = $fmt->parseCsvString(\$string)
BEGIN { *parseTTString = \&parseCsvString; }
sub parseCsvString {
  my ($fmt,$src) = @_;
  no warnings 'uninitialized';
  $$src =~ s{^(\S+).*\n}{%% base=$1\n};
  $$src =~ s{^normal$}{}mg;
  if ($fmt->{syntags}) {
    $$src =~ s{^([^\t]+)\t([^\t]*)\t([^\t]*)(?:\t([^\t]*))?(?:\t([^\t]*))?$}{$1\t[syncope_tag] $2\t[syncope_type] $3\t[syncope_loc] $4}mg;
  } else {
    $$src =~ s{^([^\t]+)\t([^\t]*)(?:\t([^\t]*))?(?:\t([^\t]*))?$}{$1\t[syncope_type] $2\t[syncope_loc] $3}mg;
  }
  return DTA::CAB::Format::TT::parseTTString($fmt,$src);
}

##==============================================================================
## Methods: Output
##==============================================================================

##--------------------------------------------------------------
## Methods: Output: Generic

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format
sub defaultExtension { return '.syncope-csv'; }

##--------------------------------------------------------------
## Methods: Output: put Document

## $fmt = $fmt->putDocument($doc)
## $fmt = $fmt->putDocument($doc,\$buf)
##  + concatenates formatted sentences, adding document 'xmlbase' comment if available
##  + \$bufr is ignored here.
sub putDocument {
  my ($fmt,$doc) = @_;
  my $fh = $fmt->{fh};
  my $docname = $fmt->{outbase}||$doc->{base}||ref($doc)||$doc;
  my $syntags = $fmt->{syntags};
  $fh->print("$docname\n");
  my ($si,$s,$wi,$sid,$wid,$w,$txt,$tag,$typ);
  foreach $si (0..$#{$doc->{body}}) {
    $s   = $doc->{body}[$si];
    $sid = $s->{id}||'';
    $fh->print("normal\n");
    foreach $wi (0..$#{$s->{tokens}}) {
      $w   = $s->{tokens}[$wi];
      $wid = ($w->{id}||'');
      $txt = $w->{moot} ? $w->{moot}{word} : ($w->{xlit} ? $w->{xlit}{latin1Text} : $w->{text});

      if (defined($typ=$w->{syncope_type}) && $typ ne '') { ; } ##-- re-use stored type
      elsif ($txt =~ /^[[:upper:]]+$/)	{ $typ = 'UPPERCASE '.(length($txt)==1 ? 'LETTER' : 'WORD'); }
      elsif ($txt =~ /^[[:lower:]]+$/)	{ $typ = 'LOWERCASE WORD'; }
      elsif ($txt =~ /^[[:punct:]][[:lower:]]+$/) { $typ = 'LOWERCASE WORD'; } ##-- 2013-02-22: "'s" should be LOWERCASE_WORD since python islower("'")=>1
      elsif ($txt =~ /^[[:upper:]]/)	{ $typ = 'CAPITALIZED WORD'; }
      elsif ($txt =~ /^[[:digit:]]+\.?$/) { $typ = 'DIGIT'; }
      elsif ($txt eq '-')		{ $typ = 'HYPHEN-MINUS'; }
      elsif ($txt eq '.')		{ $typ = 'FULL STOP'; }
      elsif ($txt eq ',')		{ $typ = 'COMMA'; }
      elsif ($txt eq ':')		{ $typ = 'COLON'; }
      elsif ($txt =~ /^[\"\']$/)	{ $typ = 'QUOTATION MARK'; }
      elsif ($txt eq '!')		{ $typ = 'EXCLAMATION MARK'; }
      elsif ($txt eq '&')		{ $typ = 'AMPERSAND'; }
      elsif ($txt eq '?')		{ $typ = 'QUESTION MARK'; }
      elsif ($txt eq '/')		{ $typ = 'SOLIDUS'; }
      else 				{ $typ = 'SYMBOL'; }

      $tag = $w->{syncope_tag} // ($w->{moot} ? $w->{moot}{tag} : 'NOTAG') if ($syntags);

      $fh->print(join("\t", $txt, ($syntags ? $tag : qw()), $typ, join(' ',$si,$wi,$sid,$wid)), "\n");
    }
  }
  return $fmt;
}


1; ##-- be happy

__END__
