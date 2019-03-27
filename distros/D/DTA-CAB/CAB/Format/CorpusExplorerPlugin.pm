## -*- Mode: CPerl; coding: utf-8; -*-
##
## File: DTA::CAB::Format::CorpusExplorerPlugin.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser/formatter: CorpusExplorer normalization plugin

## Format description (from Jan Oliver Rüdiger, 2019-03-19)
##
## > Wie würde der CorpusExplorer Texte einsenden:
## > + Die Sätze werden mittels \n getrennt.
## > + Die Token werden mittels \t getrennt.
## > + Der Aufruf des Webservice geschieht nacheinander.
## > + Der CorpusExplorer stellt sicher, dass KEINE Dokumente >1MB verschickt werden (Ablehnung vor Request).
## > + Der CorpusExplorer stellt sicher, dass die Dokumente nacheinander und nicht parallel verschickt werden.
## >   Bei Bedarf kann auch nach nach jedem Dokument (oder) nach einer festen Anzahl (z. B. 100) eine Pause eingelegt werden.
## > + Der CorpusExplorer stellt sicher, dass nicht mehr als XXXXX Dokumente annotiert werden. Bitte XXXXX spezifizieren.
## >
## > Was würde der CorpusExplorer erwarten:
## > + Die Sätze sind mittels \n getrennt
## > + Die Token sind mittels \t getrennt
## > + Es werden nur Korrekturvorschläge übermittelt. Token, die keine Korrektur benötigen
## >   (bzw. eine Korrektur nicht möglich ist), bleiben leer. z. B. \t\tKorrektur\t\t\tBeispiel\n

package DTA::CAB::Format::CorpusExplorerPlugin;
use DTA::CAB::Format;
use DTA::CAB::Datum ':all';
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_, filenameRegex=>qr/\.(?i:ceplug(?:in)?)$/)
      foreach (qw(ceplugin ceplug));
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
##     level    => $formatLevel,      ##-- output formatting level:
##                                    ##   0: norm (terse; empty for identity-normalizations)
##                                    ##   1: norm (verbose)
##     #outbuf    => $stringBuffer,     ##-- buffered output
##
##     ##---- Common
##     utf8  => $bool,                 ##-- default: 1
##     fh  => $fh,                     ##-- IO::Handle for read/write
##    )
sub new {
  my $that = shift;
  my $fmt = bless({
		   ##-- input
		   doc => undef,

		   ##-- common
		   utf8 => 1,

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
##  + override
sub noSaveKeys {
  return ($_[0]->SUPER::noSaveKeys, qw(doc outbuf));
}

##==============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Input selection

## $fmt = $fmt->fromFh($filename_or_handle)
##  + override calls fromFh_str()
sub fromFh {
  return $_[0]->fromFh_str(@_[1..$#_]);
}

## $fmt = $fmt->fromString(\$string)
##  + select input from string $string
sub fromString {
  my $fmt = shift;
  $fmt->close();
  return $fmt->parseCeString(ref($_[0]) ? $_[0] : \$_[0]);
}


##--------------------------------------------------------------
## Methods: Input: Local

## $fmt = $fmt->parseCeString(\$string)
sub parseCeString {
  my ($fmt,$src) = @_;
  no warnings qw(uninitialized);
  utf8::decode($$src) if ($fmt->{utf8} && !utf8::is_utf8($$src));

  my ($toks);
  my $sents =
    [
     map {
       {tokens=>[map {{text=>$_}} split(/\t/,$_)]}
     } split(/\n+/,$$src)
    ];
  $fmt->{doc} = bless({body=>$sents}, 'DTA::CAB::Document');

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
##  + default returns text/plain
sub mimeType { return 'text/plain'; }

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format
sub defaultExtension { return '.ceplugin'; }

## $str = $fmt->toString()
## $str = $fmt->toString($formatLevel)
##  + flush buffered output document to byte-string

## $fmt_or_undef = $fmt->toFile($filename_or_handle, $formatLevel)
##  + flush buffered output document to $filename_or_handle
##  + default implementation calls $fmt->toFh()

## $fmt_or_undef = $fmt->toFh($fh,$formatLevel)
##  + flush buffered output document to filehandle $fh
##  + default implementation calls to $fmt->formatString($formatLevel)
sub toFh {
  $_[0]->DTA::CAB::Format::toFh(@_[1..$#_]);
  $_[0]->setLayers();
  return $_[0];
}

##--------------------------------------------------------------
## Methods: Output: API

## $fmt = $fmt->putDocument($doc)
## $fmt = $fmt->putDocument($doc,\$buf)
##  + override
sub putDocument {
  my ($fmt,$doc,$bufr) = @_;
  #$bufr = \(my $buf='') if (!defined($bufr));

  my $level = $fmt->{level} // 0;
  my ($s,$w, $wnew);
  foreach $s (@{$doc->{body}}) {
    $fmt->{fh}->print(join("\t",
			   map {
			     $wnew   = $_->{moot} && defined($_->{moot}{word}) ? $_->{moot}{word} : $_->{text};
			     ($level > 0 || $wnew ne $_->{text} ? $wnew : '')
			   } @{$s->{tokens}}),
		      "\n");
  }
  return $fmt;
}

## $fmt = $fmt->putData($data)
##  + puts raw data (uses forceDocument())
sub putData {
  $_[0]->putDocument($_[0]->forceDocument($_[1]));
}



1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Format::CorpusExplorerPlugin - Datum parser/formatter: CorpusExplorer normalization plugin

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Format::CorpusExplorerPlugin;
 
 ##========================================================================
 ## Constructors etc.
 
 $fmt = CLASS_OR_OBJ->new(%args);
 
 ##========================================================================
 ## Methods: Persistence
 
 @keys = $class_or_obj->noSaveKeys();
 
 ##========================================================================
 ## Methods: Input: Input selection
 
 $fmt = $fmt->fromFh($filename_or_handle);
 $fmt = $fmt->fromString(\$string);
 
 ##========================================================================
 ## Methods: Input: Local
 
 $fmt = $fmt->parseCeString(\$string);
 
 ##========================================================================
 ## Methods: Input: Generic API
 
 $doc = $fmt->parseDocument();
 
 ##========================================================================
 ## Methods: Output: Generic
 
 $type = $fmt->mimeType();
 $ext = $fmt->defaultExtension();
 $fmt = $fmt->toFh($fh,$level)
 
 ##========================================================================
 ## Methods: Output: API
 
 $fmt = $fmt->putDocument($doc);
 $fmt = $fmt->putData($data);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::CorpusExplorerPlugin: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

Inherits from L<DTA::CAB::Format|DTA::CAB::Format>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::CorpusExplorerPlugin: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $fmt = CLASS_OR_OBJ->new(%args);

object structure: assumed HASH

    (
     ##---- Input
     doc => $doc,                    ##-- buffered input document
 
     ##---- Output
     level    => $formatLevel,      ##-- output formatting level:
                                    ##   0: norm (terse; empty for identity-normalizations)
                                    ##   1: norm (verbose)
 
     ##---- Common
     utf8  => $bool,                 ##-- default: 1
     fh  => $fh,                     ##-- IO::Handle for read/write
    )

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::CorpusExplorerPlugin: Methods: Persistence
=pod

=head2 Methods: Persistence

=over 4

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();

List of keys not to be saved; override returns C<qw(doc outbuf)>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::CorpusExplorerPlugin: Methods: Input: Input selection
=pod

=head2 Methods: Input: Input selection

=over 4

=item fromFh

 $fmt = $fmt->fromFh($filename_or_handle);

override calls fromFh_str()

=item fromString

 $fmt = $fmt->fromString(\$string);

select input from string $string

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::CorpusExplorerPlugin: Methods: Input: Local
=pod

=head2 Methods: Input: Local

=over 4

=item parseCeString

 $fmt = $fmt->parseCeString(\$string);

Local parsing guts.
Input is one sentence per line, sentence tokens (text only) separated by TABs.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::CorpusExplorerPlugin: Methods: Input: Generic API
=pod

=head2 Methods: Input: Generic API

=over 4

=item parseDocument

 $doc = $fmt->parseDocument();

Override returns buffered C<doc>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::CorpusExplorerPlugin: Methods: Output: Generic
=pod

=head2 Methods: Output: Generic

=over 4

=item mimeType

 $type = $fmt->mimeType();

override returns C<text/plain>.

=item defaultExtension

 $ext = $fmt->defaultExtension();

returns default filename extension for this format;
override returns C<.ceplugin>.

=item toFh

 $fmt_or_undef = $fmt->toFh($fh,$formatLevel);

Select output to filehandle C<$fh>.
Thin wrapper for
L<DTA::CAB::Format::toFh|DTA::CAB::Format/toFh>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::CorpusExplorerPlugin: Methods: Output: API
=pod

=head2 Methods: Output: API

=over 4

=item putDocument

 $fmt = $fmt->putDocument($doc);

Output guts.
Output format is one sentence per line, sentence tokens ("canonical" / "modern" / "normalized" text only) separated by TABs.
If C<$fmt-E<gt>{level}> is false (the default),
tokens with identity canonicalizations (C<w_old == w_new>) will be written as the empty string.

=item putData

 $fmt = $fmt->putData($data);

puts raw data (uses forceDocument())

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Footer
##======================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>jurish@bbaw.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
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
