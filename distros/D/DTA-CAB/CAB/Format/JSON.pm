## -*- Mode: CPerl; coding: utf-8 -*-
##
## File: DTA::CAB::Format::JSON.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser|formatter: YML code (generic)

package DTA::CAB::Format::JSON;
use DTA::CAB::Format;
use DTA::CAB::Datum ':all';
use IO::File;
use JSON::XS;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>'json-xs', filenameRegex=>qr/\.(?i:json(?:[\.\-\_]xs)?)$/);
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>'json');
}

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: assumed HASH
##    (
##     ##---- Input
##     doc => $doc,                    ##-- buffered input document
##     raw => $bool,                   ##-- if true, format parses raw data
##
##     ##---- INHERITED from DTA::CAB::Format
##     #utf8     => $bool,             ##-- always true
##     level     => $formatLevel,      ##-- 0:compressed, 1:formatted, ...
##     #outbuf   => $stringBuffer,     ##-- buffered output
##    )
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   ##-- I/O common
			   raw  => 0,

			   ##-- Input
			   #doc => undef,

			   ##-- Output
			   level  => 0,
			   #outbuf => '',

			   ##-- common
			   utf8 => 1,
			   jxs  => undef, ##-- see jsonxs() method, below

			   ##-- user args
			   @_
			  );
}

## $jxs = $CLASS_OR_OBJECT->jsonxs()
##  + returns a (new) JSON::XS object
##  + returns $obj->{jxs} if defined
##  + otherwise caches $obj->{jxs} as new JSON::XS object
sub jsonxs {
  return $_[0]{jxs} if (ref($_[0]) && defined($_[0]{jxs}));
  my $jxs = JSON::XS->new->utf8(0)->relaxed(1)->canonical(0)->allow_blessed(1)->convert_blessed(1)->allow_nonref(1);
  $_[0]{jxs} = $jxs if (ref($_[0]));
  return $jxs;
}

##==============================================================================
## Methods: Persistence
##==============================================================================

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
sub noSaveKeys {
  return ($_[0]->SUPER::noSaveKeys, qw(doc outbuf jxs));
}

##==============================================================================
## Methods: I/O: generic
##==============================================================================

## @layers = $fmt->iolayers()
##  + override returns only ':raw'
sub iolayers {
  return qw(:raw);
}

##==============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Input selection

## $fmt = $fmt->fromFh($fh)
##  + override calls $fmt->fromFh_str
sub fromFh {
  return $_[0]->fromFh_str(@_[1..$#_]);
}

## $fmt = $fmt->fromString(\$string)
sub fromString {
  my $fmt = shift;
  $fmt->close();
  return $fmt->parseJsonString(ref($_[0]) ? $_[0] : \$_[0]);
}

##--------------------------------------------------------------
## Methods: Input: Local

## $fmt = $fmt->parseJsonString(\$str)
##  + must be defined by child classes!
##  + if $rawMode is true, no document massaging will be performed
sub parseJsonString {
  my $fmt = shift;
  my $doc = $fmt->jsonxs->utf8( utf8::is_utf8(${$_[0]}) ? 0 : 1 )->decode(${$_[0]})
    or $fmt->logcluck("parseJsonString(): JSON::XS::decode() failed: $!");
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
## Methods: Output: Generic

## $type = $fmt->mimeType()
##  + override
sub mimeType { return 'application/json'; }

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format
sub defaultExtension { return '.json'; }

## $short = $fmt->formatName()
##  + returns "official" short name for this format
##  + default just returns package suffix
sub shortName {
  return 'json';
}


##--------------------------------------------------------------
## Methods: Output: output selection

## $fmt_or_undef = $fmt->toFh($fh,$formatLevel)
##  + select output to filehandle $fh
sub toFh {
  $_[0]->DTA::CAB::Format::toFh(@_[1..$#_]);
  $_[0]->jsonxs->utf8((grep {$_ eq 'utf8'} PerlIO::get_layers($_[1])) ? 0 : 1)->pretty(($_[0]{level}||0)>0 ? 1 : 0);
  return $_[0];
}

##--------------------------------------------------------------
## Methods: Output: Generic API
##  + these methods just dump raw json
##  + you're pretty much restricted to dumping a single document here

## $fmt = $fmt->putRef($thingy)
##  + puts a raw thingy with $fmt->{jxs}->encode()
sub putRef {
  $_[0]{fh}->print($_[0]{jxs}->encode($_[1]));
  return $_[0];
}

## $fmt = $fmt->putDocument($doc)
sub putDocument {
  my $fmt = shift;
  my $doc = {%{$_[0]}};
  delete @$doc{grep {UNIVERSAL::isa($doc->{$_},'SCALAR') || UNIVERSAL::isa($doc->{$_},'CODE')} keys %$doc};
  return $fmt->putRef($doc);
}

## $fmt = $fmt->putToken($tok)
## $fmt = $fmt->putSentence($sent)
## $fmt = $fmt->putDocument($doc)
## $fmt = $fmt->putData($data)
BEGIN {
  *putToken = \&putRef;
  *putSentence = \&putRef;
  *putData = \&putRef;
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

DTA::CAB::Format::JSON - Datum parser|formatter: JSON code via JSON::XS

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Format::JSON;
 
 $fmt = DTA::CAB::Format::JSON->new(%args);
 
 ##========================================================================
 ## Methods: Input
 
 $fmt = $fmt->parseJsonString($str);   ##-- guts
 $doc = $fmt->parseDocument();
 
 ##========================================================================
 ## Methods: Output
 
 $fmt = $fmt->toFh($fh);
 $fmt = $fmt->putToken($tok);
 $fmt = $fmt->putSentence($sent);
 $fmt = $fmt->putDocument($doc);


=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Format::JSON::XS is a L<DTA::CAB::Format|DTA::CAB::Format> datum parser/formatter
which reads & writes data as JSON::XS code using the JSON::XS module.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::JSON: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Format::JSON
inherits from
L<DTA::CAB::Format|DTA::CAB::Format>.

=item Filenames

DTA::CAB::Format::JSON registers the filename regex:

 /\.(?i:json(?:[\.\-\_]xs)?)$/

with L<DTA::CAB::Format|DTA::CAB::Format>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::JSON: Constructors etc.
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
 ##---- INHERITED from DTA::CAB::Format
 #utf8     => $bool,             ##-- output is always UTF-8
 level     => $formatLevel,      ##-- sets $jsonxs->pretty() level

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::JSON: Methods: Persistence
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
## DESCRIPTION: DTA::CAB::Format::JSON: Methods: Input
=pod

=head2 Methods: Input

=over 4

=item iolayers

 $fmt = $fmt->iolayers()

Override always returns ':raw'.

=item fromString

 $fmt = $fmt->fromString(\$string)

Override: select input from the string $string.

=item fromFh($fh)

 $fmt = $fmt->fromFh($fh)

Override calls $fmt->fromFh_str().

=item parseJsonString

 $fmt = $fmt->parseJsonString($str);

Evaluates $str as JSON code, which is expected to
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
## DESCRIPTION: DTA::CAB::Format::JSON: Methods: Output
=pod

=head2 Methods: Output

=over 4

=item toFh

 $fmt = $fmt->toFh($fh)
 $fmt = $fmt->toFh($fh, $formatLevel)

Override: select output to filehandle $fh.
Creates and caches $fmt->{jxs} as a side effect.

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

An example file in the format accepted/generated by this module is:

 {
    "body" : [
       {
          "tokens" : [
             {
                "moot" : {
                   "tag" : "PWAV",
                   "word" : "wie",
                   "lemma" : "wie"
                },
                "lang" : [
                   "de"
                ],
                "msafe" : "1",
                "errid" : "ec",
                "exlex" : "wie",
                "text" : "wie",
                "hasmorph" : "1",
                "xlit" : {
                   "latin1Text" : "wie",
                   "isLatinExt" : "1",
                   "isLatin1" : "1"
                }
             },
             {
                "text" : "oede",
                "msafe" : "0",
                "moot" : {
                   "lemma" : "öde",
                   "tag" : "ADJD",
                   "word" : "öde"
                },
                "xlit" : {
                   "isLatin1" : "1",
                   "latin1Text" : "oede",
                   "isLatinExt" : "1"
                }
             },
             {
                "text" : "!",
                "errid" : "ec",
                "exlex" : "!",
                "xlit" : {
                   "isLatinExt" : "1",
                   "latin1Text" : "!",
                   "isLatin1" : "1"
                },
                "moot" : {
                   "lemma" : "!",
                   "tag" : "$.",
                   "word" : "!"
                },
                "msafe" : "1"
             }
          ],
          "lang" : "de"
       }
    ]
 }

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

