# -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::YAML.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser|formatter: YML code (generic)

package DTA::CAB::Format::YAML;
use DTA::CAB::Format;
use DTA::CAB::Datum ':all';
# use YAML::XS;
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format);
our ($lib);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>'yaml', filenameRegex=>qr/\.(?i:ya?ml(?:[\.\-\_]xs)?)$/);
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_) foreach (qw(yamlxs yaml-xs yml ymlxs yml-xs));

  ##-- load underlying lib
  if (!$lib) {
    eval 'use YAML::XS qw();';
    $lib = 'YAML::XS' if (!$@);
  }
  if (!$lib) {
    eval 'use YAML::Syck qw();';
    $lib = 'YAML::Syck' if (!$@);
  }
  if (!$lib) {
    eval 'use YAML qw();';
    $lib = 'YAML' if (!$@);
  }

  undef $@;
}

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: assumed HASH
##    (
##     ##---- Input
##     doc => $doc,                    ##-- buffered input document
##     raw => $bool,                   ##-- if true, parse/print raw data (no document massaging)
##
##     ##---- INHERITED from DTA::CAB::Format
##     #encoding => $encoding,         ##-- n/a: always UTF-8 octets
##     level     => $formatLevel,      ##-- 0:raw, 1:typed, ...
##     outbuf    => $stringBuffer,     ##-- buffered output
##    )
sub new {
  my $that = shift;
  my $fmt = bless({
		   ##-- I/O common
		   #utf8 => 1, ##-- always true, but we don't want the I/O flag set

		   ##-- Input
		   #doc => undef,

		   ##-- Output
		   level  => 0,
		   outbuf => '',

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
sub noSaveKeys {
  return ($_[0]->SUPER::noSaveKeys, qw(doc outbuf));
}

##==============================================================================
## Methods: I/O: generic
##==============================================================================

## @layers = $fmt->iolayers()
##  + returns PerlIO layers to use for I/O handles
##  + override returns ':raw'
sub iolayers {
  return (':raw');
}

##==============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Input selection

## $fmt = $fmt->fromString(\$string)
##  + override calls $fmt->parseYamlString(\$string)
sub fromString {
  my $fmt = shift;
  $fmt->close();
  return $fmt->parseYamlString(ref($_[0]) ? $_[0] : \$_[0]);
}

## $fmt = $fmt->fromFile($filename_or_handle)
##  + inherited default calls $fmt->fromFh()

## $fmt = $fmt->fromFh($filename_or_handle)
##  + override calls $fmt->fromFh_str($fh)
sub fromFh {
  return $_[0]->fromFh_str(@_[1..$#_]);
}

##--------------------------------------------------------------
## Methods: Input: Local

## $fmt = $fmt->parseYamlString(\$str)
##  + parse a buffered YAML string
sub parseYamlString {
  my $fmt  = shift;
  my $bufr = ref($_[0]) ? $_[0] : \$_[0];
  utf8::encode($$bufr) if (utf8::is_utf8($$bufr));

  my ($doc);
  if (!$lib) {
    $fmt->logconfess("ParseYamlString(): no underlying YAML library found!");
  }
  elsif ($lib eq 'YAML::XS') {
    $doc = YAML::XS::Load($$bufr)
      or $fmt->logcluck("ParseYamlString(): YAML::XS::Load() failed: $!");
  }
  elsif ($lib eq 'YAML::Syck') {
    $doc = YAML::Syck::Load($$bufr)
      or $fmt->logcluck("ParseYamlString(): YAML::Syck::Load() failed: $!");
  }
  elsif ($lib eq 'YAML') {
    $doc = YAML::Load($$bufr)
      or $fmt->logcluck("ParseYamlString(): YAML::Load() failed: $!");
  }
  $fmt->{doc} = $fmt->{raw} ? $doc : $fmt->forceDocument($doc);
  return $fmt;
}

##--------------------------------------------------------------
## Methods: Input: Generic API

## $doc = $fmt->parseDocument()
sub parseDocument { return $_[0]{doc}; }

##==============================================================================
## Methods: Output
##==============================================================================

##--------------------------------------------------------------
## Methods: Output: MIME

## $type = $fmt->mimeType()
##  + override returns text/yaml
#sub mimeType { return 'text/yaml'; }
sub mimeType { return 'text/x-yaml'; }

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format
sub defaultExtension { return '.yml'; }

## $short = $fmt->formatName()
##  + returns "official" short name for this format
##  + default just returns package suffix
sub shortName {
  return 'yaml';
}

##--------------------------------------------------------------
## Methods: Output: output selection
##  + inherited


##--------------------------------------------------------------
## Methods: Output: Generic API

## \$buf = $fmt->formatBuf(\$buf)
##  + formats YAML buffer \$buf according to $fmt->{level}
sub formatBuf {
  #if (!$_[0]{level} || $_[0]{level} >= 2) 
  if ($_[0]{level} && $_[0]{level} >= 2) {
    #${$_[1]} =~ s/^\-\-\- !!perl\/\w+\:[\w\:]+\n/---\n/sg;     ##-- remove yaml typing on doc borders
    ${$_[1]} =~ s/(?<!^\-\-\- )!!perl\/\w+\:[\w\:]+\n\s*//sg;  ##-- remove yaml typing on content
  }
  return $_[1];
}


## $fmt = $fmt->putToken($tok)
sub putToken {
  my $tmp = YAML::XS::Dump($_[1]);
  $tmp =~ s/^---\s*//;
  $_[0]{fh}->print(${$_[0]->formatBuf(\$tmp)});
  return $_[0];
}

## $fmt = $fmt->putSentence($sent)
sub putSentence {
  my $tmp = YAML::XS::Dump($_[1]);
  $tmp =~ s/^---\s*//;
  $_[0]{fh}->print(${$_[0]->formatBuf(\$tmp)});
  return $_[0];
}

## $fmt = $fmt->putDocument($doc)
sub putDocument {
  my ($tmp);
  if (!$lib) {
    $_[0]->logconfess("putDocument(): no underlying YAML library found!");
  }
  elsif ($lib eq 'YAML::XS') {
    $tmp = YAML::XS::Dump($_[1]);
  }
  elsif ($lib eq 'YAML::Syck') {
    $tmp = YAML::Syck::Dump($_[1]);
  }
  elsif ($lib eq 'YAML') {
    $tmp = YAML::Dump($_[1]);
  }
  $_[0]{fh}->print(${$_[0]->formatBuf(\$tmp)});
  return $_[0];
}

## $fmt = $fmt->putData($data)
sub putData {
  $_[0]->putDocument($_[1]);
}

1; ##-- be happy

__END__
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Format::YAML - Datum parser|formatter: YAML code (generic)

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Format::YAML;
 
 $fmt = DTA::CAB::Format::YAML->new(%args);
 
 ##========================================================================
 ## Methods: Input
 
 $fmt = $fmt->close();
 $doc = $fmt->parseDocument();
 $fmt = $fmt->parseYAMLString($str);   ##-- abstract
 
 ##========================================================================
 ## Methods: Output
 
 $fmt = $fmt->flush();
 $str = $fmt->toString();
 $fmt = $fmt->putToken($tok);         ##-- abstract
 $fmt = $fmt->putSentence($sent);     ##-- abstract
 $fmt = $fmt->putDocument($doc);      ##-- abstract


=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Format::YAML is a L<DTA::CAB::Format|DTA::CAB::Format> datum parser/formatter
which reads & writes data as YAML code.  It really acts as a wrapper for the first available
subclass among:

=over 4

=item L<DTA::CAB::Format::YAML::XS|DTA::CAB::Format::YAML::XS>

=item L<DTA::CAB::Format::YAML::Syck|DTA::CAB::Format::YAML::Syck>

=item L<DTA::CAB::Format::YAML::YAML|DTA::CAB::Format::YAML::YAML>

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::YAML: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Format::YAML
inherits from
L<DTA::CAB::Format|DTA::CAB::Format>.

=item Filenames

DTA::CAB::Format::YAML registers the filename regex:

 /\.(?i:yaml|yml)$/

with L<DTA::CAB::Format|DTA::CAB::Format>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::YAML: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $fmt = CLASS_OR_OBJ->new(%args);

Constructor.

%args, %$fmt:

 ##---- Input
 doc    => $doc,                 ##-- buffered input document
 ##
 ##---- Output
 dumper => $dumper,              ##-- underlying Data::Dumper object
 ##
 ##---- INHERITED from DTA::CAB::Format
 #encoding => $encoding,         ##-- n/a
 level     => $formatLevel,      ##-- sets Data::Dumper->Indent() option
 outbuf    => $stringBuffer,     ##-- buffered output

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::YAML: Methods: Persistence
=pod

=head2 Methods: Persistence

=over 4

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();

Override returns list of keys not to be saved.
This implementation returns C<qw(doc outbuf)>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::YAML: Methods: Input
=pod

=head2 Methods: Input

=over 4

=item close

 $fmt = $fmt->close();

Override: close currently selected input source.

=item fromString

 $fmt = $fmt->fromString($string)

Override: select input from the string $string.

=item parseYAMLString

 $fmt = $fmt->parseYAMLString($str);

Evaluates $str as perl code, which is expected to
return a L<DTA::CAB::Document|DTA::CAB::Document>
object (or something which can be massaged into one),
and sets $fmt-E<gt>{doc} to this new document object.

=item parseDocument

 $doc = $fmt->parseDocument();

Returns the current contents of $fmt-E<gt>{doc},
e.g. the most recently parsed document.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::YAML: Methods: Output
=pod

=head2 Methods: Output

=over 4

=item flush

 $fmt = $fmt->flush();

Override: flush accumulated output.

=item toString

 $str = $fmt->toString();
 $str = $fmt->toString($formatLevel)

Override: flush buffered output document to byte-string.
This implementation just returns $fmt-E<gt>{outbuf},
which should already be a UTF-8 byte-string, and has no need of encoding.

=item putToken

 $fmt = $fmt->putToken($tok);

Override: writes a token to the output buffer (non-destructive on $tok).

=item putSentence

 $fmt = $fmt->putSentence($sent);

Override: write a sentence to the outupt buffer (non-destructive on $sent).

=item putDocument

 $fmt = $fmt->putDocument($doc);

Override: write a document to the outupt buffer (non-destructive on $doc).

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Example
##======================================================================
=pod

=head1 EXAMPLE

An example typed file in the format accepted/generated by this module is:

 --- !!perl/hash:DTA::CAB::Document
 body:
 - !!perl/hash:DTA::CAB::Sentence
   lang: de
   tokens:
   - !!perl/hash:DTA::CAB::Token
     text: wie
     errid: ec
     exlex: wie
     hasmorph: '1'
     lang:
     - de
     moot:
       lemma: wie
       tag: PWAV
       word: wie
     msafe: '1'
     xlit:
       isLatin1: '1'
       isLatinExt: '1'
       latin1Text: wie
   - !!perl/hash:DTA::CAB::Token
     text: oede
     moot:
       lemma: öde
       tag: ADJD
       word: öde
     msafe: '0'
     xlit:
       isLatin1: '1'
       isLatinExt: '1'
       latin1Text: oede
   - !!perl/hash:DTA::CAB::Token
     text: '!'
     errid: ec
     exlex: '!'
     moot:
       lemma: '!'
       tag: $.
       word: '!'
     msafe: '1'
     xlit:
       isLatin1: '1'
       isLatinExt: '1'
       latin1Text: '!'

The same example without YAML typing should also be accepted, or produced
with output formatting level=0:

 ---
 body:
 - lang: de
   tokens:
   - text: wie
     errid: ec
     exlex: wie
     hasmorph: '1'
     lang:
     - de
     moot:
       lemma: wie
       tag: PWAV
       word: wie
     msafe: '1'
     xlit:
       isLatin1: '1'
       isLatinExt: '1'
       latin1Text: wie
   - text: oede
     moot:
       lemma: öde
       tag: ADJD
       word: öde
     msafe: '0'
     xlit:
       isLatin1: '1'
       isLatinExt: '1'
       latin1Text: oede
   - text: '!'
     errid: ec
     exlex: '!'
     moot:
       lemma: '!'
       tag: $.
       word: '!'
     msafe: '1'
     xlit:
       isLatin1: '1'
       isLatinExt: '1'
       latin1Text: '!'

=cut

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

