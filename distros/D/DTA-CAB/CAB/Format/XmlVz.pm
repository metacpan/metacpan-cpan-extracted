## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::XmlVz.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser|formatter: XML (Vz)

package DTA::CAB::Format::XmlVz;
use DTA::CAB::Format::XmlCommon;
use DTA::CAB::Datum ':all';
use XML::LibXML;
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format::XmlCommon);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, filenameRegex=>qr/\.(?i:xml\-vz|(?:vz[\-\._]xml))$/);
}

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: HASH ref
##    {
##     ##-- input
##     xdoc => $xdoc,                          ##-- XML::LibXML::Document
##     xprs => $xprs,                          ##-- XML::LibXML parser
##
##     ##-- output
##     #encoding => $inputEncoding,             ##-- default: UTF-8; applies to output only!
##     level => $level,                        ##-- output formatting level (default=0)
##    }
sub new {
  my $that = shift;
  my $fmt = $that->SUPER::new(
			      ##-- input
			      xprs => undef,
			      xdoc => undef,

			      ##-- output
			      #encoding => 'UTF-8',
			      level => 1,

			      ##-- user args
			      @_
			     );

  if (!$fmt->{xprs}) {
    $fmt->{xprs} = XML::LibXML->new;
    $fmt->{xprs}->keep_blanks(0);
  }
  return $fmt;
}

##==============================================================================
## Methods: Persistence
##  + see Format::XmlCommon
##==============================================================================

##=============================================================================
## Methods: Input
##==============================================================================


##--------------------------------------------------------------
## Methods: Input: Input selection
##  + see Format::XmlCommon

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
  my $root = $fmt->{xdoc}->documentElement;
  my $sents = [];
  my $doc   = bless({body=>$sents},'DTA::CAB::Document');

  ##-- common variables
  my ($cnod,$c, $snod,$s,$stoks, $wnod,$w);

  ##-- doc attributes: xmlbase
  $doc->{$_->name} = $_->value foreach ($root->attributes);

  ##-- classes
  foreach $cnod (@{ $root->findnodes(".//cat|.//vat") }) {
    $c = {};
    $c->{$_->name} = $_->value foreach ($cnod->attributes);
    push(@{$doc->{cats}},$c);
  }

  ##-- loop: sentences
  foreach $snod (@{ $root->findnodes(".//s") }) {
    push(@$sents, $s=bless({tokens=>($stoks=[])},'DTA::CAB::Sentence'));
    $s->{$_->name} = $_->value foreach ($snod->attributes);

    ##-- loop: sentence/tokens
    foreach $wnod (@{ $snod->findnodes("./w") }) {
      push(@$stoks, $w=bless({},'DTA::CAB::Token'));
      $w->{$_->name} = $_->value foreach ($wnod->attributes);
      $w->{text} = $w->{plain} if (!defined($w->{text})); ##-- hack
    }
  }

  ##-- return document
  return $doc;
}


##=============================================================================
## Methods: Output
##==============================================================================

##--------------------------------------------------------------
## Methods: Output: Local: Nodes

## $xmlnod = $fmt->tokenNode($tok)
##  + returns formatted token $tok as an XML node
sub tokenNode {
  my ($fmt,$tok) = @_;
  $tok = toToken($tok);
  my $wnod = XML::LibXML::Element->new('w');
  $wnod->setAttribute($_,$tok->{$_}) foreach (grep {defined($tok->{$_}) && !ref($tok->{$_})} sort(keys(%$tok)));
  return $wnod;
}

## $xmlnod = $fmt->sentenceNode($sent)
sub sentenceNode {
  my ($fmt,$sent) = @_;
  $sent = toSentence($sent);
  my $snod  = XML::LibXML::Element->new('s');
  $snod->setAttribute($_,$sent->{$_}) foreach (grep {defined($sent->{$_}) && !ref($sent->{$_})} sort(keys(%$sent)));
  $snod->addChild($fmt->tokenNode($_)) foreach (@{$sent->{tokens}});
  return $snod;
}

## $xmlnod = $fmt->documentNode($doc)
sub documentNode {
  my ($fmt,$doc) = @_;
  $doc = toDocument($doc);
  my $docnod = XML::LibXML::Element->new('doc');
  $docnod->setAttribute($_,$doc->{$_}) foreach (grep {defined($doc->{$_}) && !ref($doc->{$_})} sort(keys(%$doc)));
  if ($doc->{cats}) {
    my $croot = $docnod->addNewChild(undef,'classification');
    my ($c,$cnod);
    foreach $c (@{$doc->{cats}}) {
      $cnod = $croot->addNewChild(undef,'cat');
      $cnod->setAttribute($_, (defined($c->{$_}) ? $c->{$_} : '')) foreach (sort(keys(%$c)));
    }
  }
  if ($doc->{body}) {
    my $cooked = $docnod->addNewChild(undef,'cooked');
    $cooked->addChild($fmt->sentenceNode($_)) foreach (@{$doc->{body}});
  }
  return $docnod;
}

##--------------------------------------------------------------
## Methods: Output: Local: Utils

## $xmldoc = $fmt->xmlDocument()
##  + create or return output buffer $fmt->{xdoc}
##  + inherited from XmlCommon

## $rootnode = $fmt->xmlRootNode($nodname)
##  + returns root node
##  + inherited from XmlCommon

## $bodynode = $fmt->xmlBodyNode()
##  + really just a wrapper for $fmt->xmlRootNode($fmt->{documentElement})
sub xmlBodyNode {
  my $fmt = shift;
  return $fmt->xmlRootNode('doc');
}

## $sentnod = $fmt->xmlSentenceNode()
sub xmlSentenceNode {
  my $fmt = shift;
  my $body = $fmt->xmlBodyNode();
  my ($snod) = $body->findnodes(".//s\[last()]");
  return $snod if (defined($snod));
  return $body->addNewChild(undef,'s');
}


##--------------------------------------------------------------
## Methods: Output: API

## $fmt = $fmt->putToken($tok)
sub putToken {
  my ($fmt,$tok) = @_;
  $fmt->xmlSentenceNode->addChild($fmt->tokenNode($tok));
  return $fmt;
}

## $fmt = $fmt->putSentence($sent)
sub putSentence {
  my ($fmt,$sent) = @_;
  $fmt->xmlBodyNode->addChild($fmt->sentenceNode($sent));
  return $fmt;
}

## $fmt = $fmt->putDocument($doc)
sub putDocument {
  my ($fmt,$doc) = @_;
  my $docnod = $fmt->documentNode($doc);
  my ($xdoc,$root);
  if (!defined($xdoc=$fmt->{xdoc}) || !defined($root=$fmt->{xdoc}->documentElement)) {
    $xdoc = $fmt->{xdoc} = $fmt->xmlDocument() if (!$fmt->{xdoc});
    $xdoc->setDocumentElement($docnod);
  } else {
    ##-- append-mode for real or converted input
    $root->appendChild($docnod);
  }

  return $fmt;
}

##========================================================================
## package DTA::CAB::Format::VzXml : alias for 'XmlVz'
package DTA::CAB::Format::VzXml;
use strict;
use base qw(DTA::CAB::Format::XmlVz);


1; ##-- be happy

__END__
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Format::XmlVz - Datum parser|formatter: XML (Vz)

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Format::XmlVz;
 
 ##========================================================================
 ## Methods
 
 $fmt = DTA::CAB::Format::XmlVz->new(%args);
 
 ##========================================================================
 ## Methods: Input: Generic API
 
 $doc = $fmt->parseDocument();
 
 ##========================================================================
 ## Methods: Output: Local: Nodes
 
 $xmlnod = $fmt->tokenNode($tok);
 $xmlnod = $fmt->sentenceNode($sent);
 $xmlnod = $fmt->documentNode($doc);
 
 ##========================================================================
 ## Methods: Output: Local: Utils
 
 $bodynode = $fmt->xmlBodyNode();
 $sentnod = $fmt->xmlSentenceNode();
 
 ##========================================================================
 ## Methods: Output: API
 
 $fmt = $fmt->putToken($tok);
 $fmt = $fmt->putSentence($sent);
 $fmt = $fmt->putDocument($doc);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

B<UNMAINTAINED>

DTA::CAB::Format::XmlVz is a
L<DTA::CAB::Format|DTA::CAB::Format> subclass
for I/O of documents for use with the
(likewise unmaintained)
L<DTA::CAB::Analyzer::DocClassify|DTA::CAB::Analyzer::DocClassify>
document classification analyzer.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlVz: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $fmt = CLASS_OR_OBJ->new(%args);

object structure: HASH ref

    {
     ##-- input
     xdoc => $xdoc,                          ##-- XML::LibXML::Document
     xprs => $xprs,                          ##-- XML::LibXML parser
     ##-- output
     encoding => $inputEncoding,             ##-- default: UTF-8; applies to output only!
     level => $level,                        ##-- output formatting level (default=0)
    }

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlVz: Methods: Input: Generic API
=pod

=head2 Methods: Input: Generic API

=over 4

=item parseDocument

 $doc = $fmt->parseDocument();

parses buffered XML::LibXML::Document

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlVz: Methods: Output: Local: Nodes
=pod

=head2 Methods: Output: Local: Nodes

=over 4

=item tokenNode

 $xmlnod = $fmt->tokenNode($tok);

returns formatted token $tok as an XML node

=item sentenceNode

 $xmlnod = $fmt->sentenceNode($sent);

(undocumented)

=item documentNode

 $xmlnod = $fmt->documentNode($doc);

(undocumented)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlVz: Methods: Output: Local: Utils
=pod

=head2 Methods: Output: Local: Utils

=over 4

=item xmlBodyNode

 $bodynode = $fmt->xmlBodyNode();

really just a wrapper for $fmt-E<gt>xmlRootNode($fmt-E<gt>{documentElement})

=item xmlSentenceNode

 $sentnod = $fmt->xmlSentenceNode();

(undocumented)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlVz: Methods: Output: API
=pod

=head2 Methods: Output: API

=over 4

=item putToken

 $fmt = $fmt->putToken($tok);

(undocumented)

=item putSentence

 $fmt = $fmt->putSentence($sent);

(undocumented)

=item putDocument

 $fmt = $fmt->putDocument($doc);

(undocumented)

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
