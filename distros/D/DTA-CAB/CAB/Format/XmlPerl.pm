## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::XmlPerl.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser|formatter: XML (perl-near)

package DTA::CAB::Format::XmlPerl;
use DTA::CAB::Format::XmlCommon;
use DTA::CAB::Datum ':all';
use DTA::CAB::Utils ':libxml';
use XML::LibXML;
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format::XmlCommon);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, filenameRegex=>qr/\.(?i:xml(?:\-?)perl|perl(?:[\-\.]?)xml)$/);
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_) foreach (qw(xml-perl xml_perl));
}

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: assumed HASH
##    (
##     ##-- input
##     xdoc => $xdoc,                          ##-- XML::LibXML::Document
##     xprs => $xprs,                          ##-- XML::LibXML parser
##
##     ##-- output
##     #encoding => $inputEncoding,             ##-- default: UTF-8; applies to output only!
##     level => $level,                        ##-- output formatting level (default=0)
##     hashElt => $elt,                        ##-- output hash element (default='map')
##     listElt => $elt,                        ##-- ouput list element (default='list')
##     atomElt => $elt,                        ##-- ouput atom element (default='val')
##
##     ##-- common
##    )
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   ##-- input
			   #xdoc => undef,
			   xprs => libxml_parser(keep_blanks=>0),

			   ##-- output
			   level    => 0,

			   hashElt => 'm',
			   listElt => 'l',
			   atomElt => 'a',

			   ##-- common

			   ##-- user args
			   @_
			  );
}

##==============================================================================
## Methods: Persistence
##==============================================================================

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
##  + inherited from XmlCommon


##=============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Local

## $obj = $fmt->parseNode($nod)
##  + Returns the perl object represented by the XML::LibXML::Node $nod
our %atomNames = map {($_=>undef)} (qw(VALUE VAL V value val v ATOM atom a), '#text');
our %hashNames = map {($_=>undef)} qw(HASH H hash h MAP M map m);
our %listNames = map {($_=>undef)} qw(ARRAY array   LIST L list l);
our %allNames  = (%atomNames,%hashNames,%listNames);
sub parseNode {
  my ($fmt,$nod) = @_;
  return undef if (!defined($nod));
  my $nodname = $nod->nodeName;
  my ($val,$ref);
  if (exists($atomNames{$nodname})) {
    ##-- non-reference: <VALUE>$val</VALUE> or <VALUE undef="1"/> or plain text
    $val = $nod->can('getAttribute') && $nod->getAttribute('undef') ? undef : $nod->textContent;
  }
  elsif (exists($hashNames{$nodname})){
    ##-- HASH ref: <HASH ref="$ref"> ... <ENTRY key="$eltKey">defaultXmlNode($eltVal)</ENTRY> ... </HASH>
    $ref = $nod->getAttribute('ref');
    $val = {};
    $val = bless($val,$ref) if ($ref && $ref ne 'HASH');
    foreach (grep {ref($_) eq 'XML::LibXML::Element' && $_->hasAttribute('key')} $nod->childNodes) {
      $val->{ $_->getAttribute('key') } = $fmt->parseNode($_);
    }
  }
  elsif (exists($listNames{$nodname})) {
    ##-- ARRAY ref: <ARRAY ref="$ref"> ... xmlNode($eltVal) ... </ARRAY>
    $ref = $nod->getAttribute('ref');
    $val = [];
    $val = bless($val,$ref) if ($ref && $ref ne 'ARRAY');
    foreach ($nod->childNodes) {
      push(@$val, $fmt->parseNode($_));
    }
  }
  elsif ($nodname =~ /^\#/) {
    ;##-- special node, e.g. #cdata-section, #comment, etc.: skip
  }
  else {
    $fmt->logwarn("cannot handle node with name=$nodname - skipping");
  }
  return $val;
}

##--------------------------------------------------------------
## Methods: Input: Generic API

## $doc = $fmt->parseDocument()
##  + parses buffered XML::LibXML::Document
sub parseDocument {
  my $fmt = shift;
  if (!defined($fmt->{xdoc})) {
    $fmt->logconfess("parseDocument(): no source document {xdoc} defined!");
    return undef;
  }
  my $parsed = $fmt->parseNode($fmt->{xdoc}->documentElement);

  ##-- force document
  return $fmt->forceDocument($parsed);
}


##=============================================================================
## Methods: Output
##==============================================================================

##--------------------------------------------------------------
## Methods: Output: MIME & HTTP stuff

## $short = $fmt->formatName()
##  + returns "official" short name for this format
##  + default just returns package suffix
sub shortName {
  return 'xmlperl';
}

##--------------------------------------------------------------
## Methods: Output: Local: Nodes

## $xmlnod = $fmt->tokenNode($tok)
##  + returns formatted token $tok as an XML node
sub tokenNode { return $_[0]->defaultXmlNode($_[1]); }

## $xmlnod = $fmt->sentenceNode($sent)
sub sentenceNode { return $_[0]->defaultXmlNode($_[1]); }

## $xmlnod = $fmt->documentNode($doc)
sub documentNode { return $_[0]->defaultXmlNode($_[1]); }


## $body_array_node = $fmt->xmlBodyNode()
##  + gets or creates buffered body array node
sub xmlBodyNode {
  my $fmt = shift;
  my $root = $fmt->xmlRootNode('doc');
  my ($body) = $root->findnodes('./*[@key="body"][last()]');
  if (!defined($body)) {
    $body = $root->addNewChild(undef,$fmt->{listElt});
    $body->setAttribute('key','body');
  }
  return $body;
}

## $sentence_array_node = $fmt->xmlSentenceNode()
##  + gets or creates buffered sentence array node
sub xmlSentenceNode {
  my $fmt = shift;
  my $body = $fmt->xmlBodyNode();
  my ($snod) = $body->findnodes('./*[@ref="DTA::CAB::Sentence"][last()]');
  if (!defined($snod)) {
    $snod = $body->addNewChild(undef,$fmt->{hashElt});
    $snod->setAttribute("ref","DTA::CAB::Sentence");
  }
  my ($toks) = $snod->findnodes('./'.$fmt->{listElt}.'[@key="tokens"][last()]');
  if (!defined($toks)) {
    $toks = $body->addNewChild(undef,$fmt->{listElt});
    $toks->setAttribute("key","tokens");
  }
  return $toks;
}

##--------------------------------------------------------------
## Methods: Output: API

## $fmt = $fmt->putToken($tok)
sub putToken {
  my ($fmt,$tok) = @_;
  $fmt->xmlSentenceNode->addChild( $fmt->tokenNode($tok) );
  return $fmt;
}

## $fmt = $fmt->putSentence($sent)
sub putSentence {
  my ($fmt,$sent) = @_;
  $fmt->xmlBodyNode->addChild( $fmt->sentenceNode($sent) );
  return $fmt;
}

## $fmt = $fmt->putDocument($doc)
sub putDocument {
  my ($fmt,$doc) = @_;
  my $docnod = $fmt->documentNode($doc);
  my $xdoc = $fmt->xmlDocument();
  my ($root);
  if (!defined($root=$xdoc->documentElement)) {
    $xdoc->setDocumentElement($docnod);
  } else {
    my $body = $fmt->xmlBodyNode();
    $body->addChild($_) foreach ($docnod->findnodes('./'.$fmt->{listElt}.'[@key="body"]/*'));
  }
  return $fmt;
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

DTA::CAB::Format::XmlPerl - Datum parser|formatter: XML (perl-like)

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Format::XmlPerl;
 
 ##========================================================================
 ## Constructors etc.
 
 $fmt = DTA::CAB::Format::XmlPerl->new(%args);
 
 ##========================================================================
 ## Methods: Input
 
 $obj = $fmt->parseNode($nod);
 $doc = $fmt->parseDocument();
 
 ##========================================================================
 ## Methods: Output
 
 $xmlnod = $fmt->tokenNode($tok);
 $xmlnod = $fmt->sentenceNode($sent);
 $xmlnod = $fmt->documentNode($doc);
 $body_array_node = $fmt->xmlBodyNode();
 $sentence_array_node = $fmt->xmlSentenceNode();
 $fmt = $fmt->putToken($tok);
 $fmt = $fmt->putSentence($sent);
 $fmt = $fmt->putDocument($doc);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlPerl: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Format::XmlPerl
inherits from
L<DTA::CAB::Format::XmlCommon|DTA::CAB::Format::XmlCommon>.

=item Filenames

DTA::CAB::Format::XmlPerl registers the filename regex:

 /\.(?i:xml-perl|perl[\-\.]xml)$/

with L<DTA::CAB::Format|DTA::CAB::Format>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlPerl: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $fmt = CLASS_OR_OBJ->new(%args);

Constructor.

%args, %$fmt:

 ##-- input
 xdoc => $xdoc,                          ##-- XML::LibXML::Document
 xprs => $xprs,                          ##-- XML::LibXML parser
 ##
 ##-- output
 encoding => $inputEncoding,             ##-- default: UTF-8; applies to output only!
 level => $level,                        ##-- output formatting level (default=0)
 ##
 ##-- common
 #(nothing here)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlPerl: Methods: Persistence
=pod

=head2 Methods: Persistence

=over 4

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();

Override: returns list of keys not to be saved.
Here, returns C<qw(xdoc xprs)>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlPerl: Methods: Input
=pod

=head2 Methods: Input

=over 4

=item parseNode

 $obj = $fmt->parseNode($nod);

Returns the perl object represented by the XML::LibXML::Node $nod.

=item parseDocument

 $doc = $fmt->parseDocument();

Override: parses buffered XML::LibXML::Document in $fmt-E<gt>{xdoc}

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlPerl: Methods: Output
=pod

=head2 Methods: Output

=over 4

=item tokenNode

 $xmlnod = $fmt->tokenNode($tok);

Returns an XML::LibXML::Node representing the token $tok.

=item sentenceNode

 $xmlnod = $fmt->sentenceNode($sent);

Returns an XML::LibXML::Node representing the sentence $sent.

=item documentNode

 $xmlnod = $fmt->documentNode($doc);

Returns an XML::LibXML::Node representing the document $doc.

=item xmlBodyNode

 $body_array_node = $fmt->xmlBodyNode();

Gets or creates buffered array node representing document body.

=item xmlSentenceNode

 $sentence_array_node = $fmt->xmlSentenceNode();

Gets or creates buffered array node representing (current) document sentence.

=item putToken

 $fmt = $fmt->putToken($tok);

Override: write token $tok to output buffer.

=item putSentence

 $fmt = $fmt->putSentence($sent);

Override: write sentence $sent to output buffer.

=item putDocument

 $fmt = $fmt->putDocument($doc);

Override: write document $doc to output buffer.

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

 <?xml version="1.0" encoding="UTF-8"?>
 <m ref="DTA::CAB::Document">
   <l key="body">
     <m>
       <a key="lang">de</a>
       <l key="tokens">
         <m>
           <m key="moot">
             <a key="lemma">wie</a>
             <a key="word">wie</a>
             <a key="tag">PWAV</a>
           </m>
           <l key="lang">
             <a>de</a>
           </l>
           <a key="hasmorph">1</a>
           <a key="msafe">1</a>
           <a key="text">wie</a>
           <a key="exlex">wie</a>
           <a key="errid">ec</a>
           <m key="xlit">
             <a key="latin1Text">wie</a>
             <a key="isLatinExt">1</a>
             <a key="isLatin1">1</a>
           </m>
         </m>
         <m>
           <a key="text">oede</a>
           <a key="msafe">0</a>
           <m key="moot">
             <a key="word">öde</a>
             <a key="tag">ADJD</a>
             <a key="lemma">öde</a>
           </m>
           <m key="xlit">
             <a key="latin1Text">oede</a>
             <a key="isLatin1">1</a>
             <a key="isLatinExt">1</a>
           </m>
         </m>
         <m>
           <m key="moot">
             <a key="lemma">!</a>
             <a key="tag">$.</a>
             <a key="word">!</a>
           </m>
           <a key="msafe">1</a>
           <a key="text">!</a>
           <a key="exlex">!</a>
           <a key="errid">ec</a>
           <m key="xlit">
             <a key="latin1Text">!</a>
             <a key="isLatin1">1</a>
             <a key="isLatinExt">1</a>
           </m>
         </m>
       </l>
     </m>
   </l>
 </m>

=cut


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
