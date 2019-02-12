## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::XmlNative.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser|formatter: XML (native)

package DTA::CAB::Format::XmlNative;
use DTA::CAB::Format::XmlCommon;
use DTA::CAB::Datum ':all';
use XML::LibXML;
use IO::File;
use Carp;
use strict;

#require 5.10.0;   ##-- for ${^POSTMATCH} ; but this syntax makes services (perl v5.10.0) complain
require 5.010_000; ##-- same thing which doesn't make v5.10.0 complain

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format::XmlCommon);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, filenameRegex=>qr/\.(?i:xml\-native|xml\-dta\-cab|(?:dta[\-\._]cab[\-\._]xml))$/);
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>'cab-xml');
}

BEGIN {
  *isa = \&UNIVERSAL::isa;
  *can = \&UNIVERSAL::can;
}

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: HASH ref
##    {
##     ##-- input: inherited
##     xdoc => $xdoc,                          ##-- XML::LibXML::Document
##     xprs => $xprs,                          ##-- XML::LibXML parser
##
##     ##-- input: new
##     parseXmlData => $bool,		       ##-- if unspecified or true, _xmldata key will be populated by parseNode() (default=undef->true)
##
##     ##-- input+output: new
##     xml2key => \%xml2key,                   ##-- maps xml keys to internal keys
##     ignoreKeys => \%key2undef,              ##-- keys to ignore for i/o
##
##     ##-- output: new
##     arrayEltKeys => \%akey2ekey,            ##-- maps array keys to element keys for output
##     arrayImplicitKeys => \%akey2undef,      ##-- pseudo-hash of array keys NOT mapped to explicit elements
##     key2xml => \%key2xml,                   ##-- maps keys to XML-safe names
##
##     ##-- output: inherited
##     #encoding => $inputEncoding,             ##-- default: UTF-8; applies to output only!
##     level => $level,                        ##-- output formatting level (default=0)
##    }
sub new {
  my $that = shift;
  my $fmt = $that->SUPER::new(
			      ##-- defaults: output
			      #xmlns =>
			      #{
			      # 'cab' => 'http://www.deutschestextarchiv.de/cab/spec/1.0/XmlNative',
			      # ''    => 'http://www.deutschestextarchiv.de/cab/spec/1.0/XmlNative',
			      #},

			      key2xml => {
					  'xml:id' => 'id',
					  'xml:base' => 'base',
					  #'text' => 't', ##-- for TokWrap .t.xml
					 },
			      xml2key => {
					  'xml:id' => 'id',
					  'xml:base' => 'base',
					  't' => 'text',	##-- for TokWrap .t.xml
					  'cab:t' => 'text',	##-- for ddc-build/splice-cleaner.xsl output
					  'cab:text' => 'text', ##-- for ddc-build/splice-cleaner.xsl output
					 },

			      arrayEltKeys => {
					       'body' => 's',
					       'tokens' => 'w',
					       'DEFAULT' => 'a',
					      },

			      arrayImplicitKeys => {
						    body=>undef,
						    tokens=>undef,
						    'a'=>undef,
						   },
			      ignoreKeys => {
					     'teibufr'=>undef,
					     'textbufr'=>undef,
					    },
			      #parseXmlData => 1,

			      ##-- user args
			      @_
			     );
  $fmt->xmlparser->keep_blanks(0);
  return $fmt;
}

##==============================================================================
## Methods: I/O: Block-wise
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Block-wise: Generic

## %blockOpts = $CLASS_OR_OBJECT->blockDefaults()
##  + returns default block options as for blockOptions()
##  + override returns as for $CLASS_OR_OBJECT->blockOptions('512k@s')
sub blockDefaults {
  return ($_[0]->SUPER::blockDefaults(), bsize=>(512*1024), eob=>'s');
}

##--------------------------------------------------------------
## Methods: I/O: Block-wise: Input

## \%head = blockScanHead(\$buf,$io,\%opts)
##  + gets header (${io}head) offset, length from (mmapped) \$buf
##  + %opts are as for blockScan()
sub blockScanHead {
  my ($fmt,$bufr,$io,$opts) = @_;
  my $elt = $opts->{xmlelt} || $opts->{eob} || 'w';
  return $$bufr =~ m(\Q<$elt\E\b) ? [0,$-[0]] : [0,0];
}

## \%head = blockScanFoot(\$buf,$io,\%opts)
##  + gets footer (${io}foot) offset, length from (mmaped) \$buf
##    - override works from and may alter last body block in $opts->{${io}body}
##    - also uses $opts->{${io}fsize} (default=length($$buf)) to compute footer length
##  + %opts are as for blockScan()
sub blockScanFoot {
  use bytes;
  my ($fmt,$bufr,$io,$opts) = @_;
  return [0,0] if (!$opts || !$opts->{"${io}body"} || !@{$opts->{"${io}body"}});
  my $blk = $opts->{"${io}body"}[$#{$opts->{"${io}body"}}];
  my $elt = $opts->{xmlelt} || $opts->{eob} || 'w';
  pos($$bufr) = $blk->{"${io}off"} || 0; ##-- set to offset of final body block

  if (0) {
    ##-- v0: use negative lookahead regex match: elegant but buggy under some perls
    ## + causes segfault on in ddc/dta2012/build/cab_corpus for ddc/dta2012/build/xml_tok/campe_robinson02_1780.TEI-P5.chr.ddc.t.xml
    ## + bug appears both on kaskade (debian-lenny, perl 5.10.0-19lenny5) and plato (debian-squeeze, perl 5.10.1-17squeeze3)
    ## + only sefgaults under make (changing make -j , -blockSize , -njobs has no effect)
    ## + backtrace:
    ##   #0  0x00002b26f788ef77 in ?? () from /usr/lib/libperl.so.5.10
    ##   #1  0x00002b26f7896fd0 in ?? () from /usr/lib/libperl.so.5.10
    ##   #2  0x00002b26f789ad29 in Perl_regexec_flags () from /usr/lib/libperl.so.5.10
    ##   #3  0x00002b26f7837e76 in Perl_pp_match () from /usr/lib/libperl.so.5.10
    ##   #4  0x00002b26f7831392 in Perl_runops_standard () from /usr/lib/libperl.so.5.10
    ##   #5  0x00002b26f782c5df in perl_run () from /usr/lib/libperl.so.5.10
    ##   #6  0x0000000000400d0c in main ()
    if ($$bufr =~ m((?s:</\Q$elt\E>|<\Q$elt\E\b[^>]*/>)(?!.*(?s:</\Q$elt\E>|<\Q$elt\E\b[^>]*/>)))sg) {
      my $end = $+[0];
      $blk->{"${io}len"} = $end - ($blk->{"${io}off"} || 0);
      return [$end, ($opts->{"${io}fsize"}||length($$bufr))-$end];
    }
  }
  elsif (0) {
    ##-- v1: !$useNegativeLookaheadRegex: use ${^POSTMATCH} safer but __much__ slower
    my ($end);
    while ($$bufr =~ m{</\Q$elt\E>|<\Q$elt\E\b[^>]*/>}msgp && defined($end=$+[0]) && ${^POSTMATCH} =~ m{</\Q$elt\E>|<\Q$elt\E\b[^>]*/>}ms) {
      pos($$bufr) = $end = $end+$+[0];
    }
    if (defined($end)) {
      $blk->{"${io}len"} = $end - ($blk->{"${io}off"} || 0);
      return [$end, ($opts->{"${io}fsize"}||length($$bufr))-$end];
    }
  }
  else {
    ##-- v2: !$useNegativeLookaheadRegex : v0.1: use rindex()

    ##-- scan for literal end-of-element with rindex() for a first-stab
    ## + doesn't find all valid element closers, just the likely ones
    my $pos0 = pos($$bufr);
    my $end = rindex(substr($$bufr,$pos0),"</$elt>");             ##-- usual case
    $end    = rindex(substr($$bufr,$pos0),"<$elt/>") if ($end<0); ##-- empty element

    ##-- now use slow regex scan
    pos($$bufr) = $pos0+$end if ($end>=0);
    while ($$bufr =~ m{</\Q$elt\E>|<\Q$elt\E\b[^>]*/>}msgp && defined($end=$+[0]) && ${^POSTMATCH} =~ m{</\Q$elt\E>|<\Q$elt\E\b[^>]*/>}ms) {
      pos($$bufr) = $end = $end+$+[0];
    }
    if (defined($end) && $end>=0) {
      $blk->{"${io}len"} = $end - ($blk->{"${io}off"} || 0);
      return [$end, ($opts->{"${io}fsize"}||length($$bufr))-$end];
    }
  }
  return [0,0];
}

## \@blocks = $fmt->blockScanBody(\$buf,\%opts)
##  + scans $filename for block boundaries according to \%opts
sub blockScanBody {
  my ($fmt,$bufr,$opts) = @_;

  ##-- scan blocks into head, body, foot
  my $bsize  = $opts->{bsize};
  my $fsize  = $opts->{ifsize};
  my $elt    = $opts->{xmlelt} || $opts->{eob} || 'w';
  my $eos    = $elt eq 's' ? 1 : 0;
  my $re_s   = '(?s:<'.quotemeta($elt).'\b)';
  my $blocks = [];

  ##-- hack workaround for slow m($re_qr)g on kira (ubuntu 16.04.1 LTS, perl 5.22.1)
  #my $re     = qr($re_s);
  my $matchoff = eval qq{sub { \$\$bufr =~ m{$re_s}g ? \$-[0] : \$fsize }};

  my ($off0,$off1,$blk);
  for ($off0=$opts->{ihead}[0]+$opts->{ihead}[1]; $off0 < $fsize; $off0=$off1) {
    push(@$blocks, $blk={bsize=>$bsize, eob=>$elt, ioff=>$off0, eos=>$eos});
    pos($$bufr) = ($off0+$bsize < $fsize ? $off0+$bsize : $fsize);
    $off1 = $matchoff->();
    $blk->{eos}  = 1 if ($off1 >= $fsize); ##-- for tt
    $blk->{ilen} = $off1-$off0;
  }

  return $blocks;
}

##--------------------------------------------------------------
## Methods: I/O: Block-wise: Output
##  + inherited from DTA::CAB::Format


##=============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Local

## $obj = $fmt->parseNode($nod)
##  + returns a perl object represented by the XML::LibXML::Node $nod
##  + attempts to map xml to perl structure "sensibly"
##  + DTA::CAB::Datum nodes (documen,sentence,token) get some additional baggage:
##     _xmldata  => $data,    ##-- unparsed content (raw string)
sub parseNode {
  my ($fmt,$top) = @_;
  return undef if (!defined($top));

  my $xml2key = $fmt->{xml2key};
  my $parseXmlData = !exists($fmt->{parseXmlData}) || $fmt->{parseXmlData};
  my ($cd,$cs,$cw);
  my ($nod,$cur,$name,$nxt);
  my ($topval);

  my @stack = ([$top]);
  while (@stack) {
    ($nod,$cur) = @{pop @stack};
    $name = $nod->nodeName;
    $name = $xml2key->{$name} if (defined($xml2key->{$name}));
    next if (exists($fmt->{ignoreKeys}{$name}));

    if (isa($nod,'XML::LibXML::Element')) {
      ##-- Element
      if ($name eq 'doc') {
	##-- Element: special: DTA::CAB::Document
	$nxt = $cd = DTA::CAB::Document->new;
      }
      elsif ($name eq 's') {
	##-- Element: special: DTA::CAB::Sentence
	#$nxt = $cs = DTA::CAB::Sentence->new;
	$nxt = $cs = {tokens=>[]};
	push(@{$cd->{body}},$cs);
      }
      elsif ($name eq 'w') {
	##-- Element: special: DTA::CAB::Token
	#$nxt = $cw = DTA::CAB::Token->new;
	$nxt = $cw = {text=>undef};
	push(@{$cs->{tokens}},$cw);
      }
      elsif ($name eq 'a' && $nod->parentNode->nodeName eq 'w') {
	##-- Element: special: tokenizer analysis (toka)
	push(@{$cw->{toka}}, $nod->textContent);
      }
      elsif ($name eq 'msafe') {
	##-- Element: special: msafe (backwards-compatible)
	$cur->{msafe} = $nod->getAttribute('safe');
      }
      elsif ($nod->hasAttributes) {
	##-- Element: default: +attributes: HASH
	$nxt = _pushValue($cur,$name,{});
      }
      elsif ($nod->hasChildNodes && $nod->parentNode->nodeName ne 'toka') {
	##-- Element: default: -attributes, +dtrs: ARRAY
	$nxt = _pushValue($cur,$name,[]);
      }
      else {
	##-- Element: default: -attributes, -dtrs: append to _xmldata
	$cur->{_xmldata} .= $nod->toString if ($parseXmlData && isa($cur,'HASH'));
      }
      ##-- Element: common: enqueue child nodes
      push(@stack, map {[$_,$nxt]} reverse($nod->childNodes), $nod->attributes);

      ##-- Element: save top value
      $topval = $nxt if (!defined($topval));
    }
    elsif (isa($nod,'XML::LibXML::Attr')) {
      if ($name eq 'lang' && $nod->parentNode->nodeName eq 'w') {
	##-- attribute: special: lang
	$cur->{$name} = [split(/ /, $nod->value)];
      }
      else {
	##-- Attribute (hash only)
	$cur->{$name} = $nod->value if (isa($cur,'HASH'));
      }
    }
    elsif (isa($nod,'XML::LibXML::Text')) {
      ##-- Text
      if (isa($cur,'HASH')) {
	##-- Text: to hash: append to _xmldata
	$cur->{'_xmldata'} .= $nod->toString if ($parseXmlData);
      }
      elsif (isa($cur,'ARRAY')) {
	##-- Text: to array: append to array
	push(@$cur,$nod->toString);
      }
    }
    else {
      $fmt->logwarn("parseNode() can't handle XML node of class ", ref($nod), " - skipping\n");
    }
  }##--/while (@queue)

  return $topval;
}

## $val = PACKAGE::_pushValue(\%hash,  $key, $val); ##-- $hash{$key}=$val
## $val = PACKAGE::_pushValue(\@array, $key, $val); ##-- push(@array,$val)
sub _pushValue {
  return $_[0]{$_[1]}=$_[2] if (isa($_[0],'HASH'));
  push(@{$_[0]},$_[2]);
  return $_[2];
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

## $short = $fmt->shortName()
##  + returns "official" short name for this format
##  + default just returns package suffix
sub shortName {
  return 'xml';
}

##--------------------------------------------------------------
## Methods: Output: Local

## $nod = $fmt->xmlNode($thingy,$name)
##  + returns an xml node for $thingy using $name as key
sub xmlNode {
  my ($fmt,$topval,$topkey) = @_;
  my $topmom = XML::LibXML::Element->new('__root__');

  my $akey2ekey = $fmt->{arrayEltKeys};
  my $key2xml   = $fmt->{key2xml};

  my ($val,$key,$mom,$nod, $skey,$sval);
  my @queue = ([$topval,$topkey,$topmom]); ## [$val,$key,$mom], ...
  while (@queue) {
    ($val,$key,$mom) = @{shift @queue};
    $key = $key2xml->{$key} if (defined($key2xml->{$key}));

    if (exists($fmt->{ignoreKeys}{$key})) {
      ;##-- ignored: skip it
    }
    elsif (!defined($val)) {
      ;##-- undefined: skip it
    }
    elsif (!ref($val)) {
      ##-- scalar: raw text
      #$val = '' if (!defined($val));
      if ($key eq '#text') {
	$mom->appendText($val);
      } else {
	$mom->appendTextChild($key,$val);
      }
    }
    elsif (can($val,'xmlNode') && UNIVERSAL::can($val,'xmlNode') ne \&defaultXmlNode) {
      ##-- object: xml-aware (avoid circularities)
      $nod = $val->xmlNode($key,$mom,$fmt);
      $mom->appendChild($nod); ##-- fails if already added
    }
    elsif (isa($val,'HASH')) {
      ##-- hash: map to element
      $nod = $mom->addNewChild(undef,$key);
      $nod->appendWellBalancedChunk($val->{_xmldata}) if (defined($val->{_xmldata}));
      while (($skey,$sval)=each(%$val)) {
	$skey = $key2xml->{$skey} if (defined($key2xml->{$skey}));
	if ($skey eq '_xmldata' || !defined($sval)) {
	  next;
	} elsif (!ref($sval)) {
	  $nod->setAttribute($skey,$sval);
	} else {
	  push(@queue, [$sval,$skey,$nod]);
	}
      }
    }
    elsif (isa($val,'ARRAY')) {
      if (exists($fmt->{arrayImplicitKeys}{$key})) {
	##-- array: implicit
	$nod = $mom;
      } elsif ($key eq 'lang') {
	##-- special: 'lang'
	$mom->setAttribute('lang', join(' ', @$val));
	next;
      } else {
	##-- array: default: map to element
	$nod = $mom->addNewChild(undef,$key);
      }
      ##-- array: append elements
      $skey = $akey2ekey->{$key} || $akey2ekey->{DEFAULT};
      push(@queue, [$_,$skey,$nod]) foreach (@$val);
    }
    else {
      ##-- other: complain
      $fmt->logcarp("xmlNode(): default node generator clause called for key='$key', value='$val'");
      $nod = $mom->addNewChild(undef,$key);
    }
  }

  ##-- unbind & return
  my $topnod = $topmom->firstChild();
  $topnod->unbindNode if (defined($topnod));
  return $topnod;
}

##--------------------------------------------------------------
## Methods: Output: Generic API

## $fmt = $fmt->putDocument($doc)
sub putDocument {
  my ($fmt,$doc) = @_;
  my $xdoc   = $fmt->xmlDocument();
  my $docnod = $fmt->xmlNode($doc,'doc');
  my ($root);
  if (!defined($root=$xdoc->documentElement)) {
    $xdoc->setDocumentElement($docnod);
  } else {
    $root->appendChild($_) foreach ($docnod->childNodes); ##-- hack
  }
  return $fmt;
}

##==============================================================================
## Package: Xml (alias)
package DTA::CAB::Format::Xml;
our @ISA = qw(DTA::CAB::Format::XmlNative);

1; ##-- be happy

__END__
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Format::XmlNative - Datum parser|formatter: XML (native)

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Format::XmlNative;
 
 ##========================================================================
 ## Methods
 
 $fmt = DTA::CAB::Format::XmlNative->new(%args);
 $obj = $fmt->parseNode($nod);
 $doc = $fmt->parseDocument();
 $fmt = $fmt->putDocument($doc);
 
 ##========================================================================
 ## Utilities
 
 $nod = $fmt->xmlNode($thingy,$name);
 $val = PACKAGE::_pushValue(\%hash,  $key, $val); ##-- $hash{$key}=$val;
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Format::XmlNative
is a L<DTA::CAB::Format|DTA::CAB::Format> subclass for document I/O
using a native XML dialect.
It inherits from L<DTA::CAB::Format::XmlCommon|DTA::CAB::Format::XmlCommon>.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlNative: Constructors etc.
=pod

=head2 Methods

=over 4

=item new

 $fmt = CLASS_OR_OBJ->new(%args);

%$fmt, %args:

 ##-- input: inherited
 xdoc => $xdoc,                          ##-- XML::LibXML::Document
 xprs => $xprs,                          ##-- XML::LibXML parser
 ##
 ##-- input: new
 parseXmlData => $bool,                  ##-- if specified and true, _xmldata key will be populated by parseNode() (default=unspecified:true)
 ##
 ##-- input+output: new
 xml2key => \%xml2key,                   ##-- maps xml keys to internal keys
 ignoreKeys => \%key2undef,              ##-- keys to ignore for i/o
 ##
 ##-- output: new
 arrayEltKeys => \%akey2ekey,            ##-- maps array keys to element keys for output
 arrayImplicitKeys => \%akey2undef,      ##-- pseudo-hash of array keys NOT mapped to explicit elements
 key2xml => \%key2xml,                   ##-- maps keys to XML-safe names
 xml2key => \%xml2key,                   ##-- maps xml keys to internal keys
 ##
 ##-- output: inherited
 encoding => $inputEncoding,             ##-- default: UTF-8; applies to output only!
 level => $level,                        ##-- output formatting level (default=0)

=item parseDocument

 $doc = $fmt->parseDocument();

Parses buffered XML::LibXML::Document into a buffered L<DTA::CAB::Document|DTA::CAB::Document>.

=item shortName

Returns "official" short name for this format, here just 'xml'.

=item putDocument

 $fmt = $fmt->putDocument($doc);

Formats the L<DTA::CAB::Document|DTA::CAB::Document> $doc as XML
to the in-memory buffer $fmt-E<gt>{xdoc}.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlNative: Package: Xml (alias)
=pod

=head2 Utilities

=over 4

=item parseNode

 $obj = $fmt->parseNode($nod);

Returns a perl object represented by the XML::LibXML::Node $nod;
attempting to map xml to perl structure "sensibly".

DTA::CAB::Datum nodes (document, sentence, token) get some additional baggage:

 _xmldata  => $data,    ##-- unparsed content (raw string)

=item xmlNode

 $nod = $fmt->xmlNode($thingy,$name);

Returns an xml node for the perl scalar $thingy using $name as its key,
used in constructing XML output documents.

=item _pushValue

 $val = PACKAGE::_pushValue(\%hash,  $key, $val); ##-- $hash{$key}=$val;
 $val = PACKAGE::_pushValue(\@array, $key, $val); ##-- push(@array,$val)

Convenience routine used by parseNode() when constructing perl data structures
from XML input.

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
 <doc>
   <s lang="de">
     <w exlex="wie" hasmorph="1" msafe="1" errid="ec" t="wie" lang="de">
       <moot word="wie" lemma="wie" tag="PWAV"/>
       <xlit latin1Text="wie" isLatin1="1" isLatinExt="1"/>
     </w>
     <w msafe="0" t="oede">
       <moot tag="ADJD" lemma="öde" word="öde"/>
       <xlit isLatinExt="1" isLatin1="1" latin1Text="oede"/>
     </w>
     <w msafe="1" errid="ec" t="!" exlex="!">
       <moot lemma="!" word="!" tag="$."/>
       <xlit isLatinExt="1" isLatin1="1" latin1Text="!"/>
     </w>
   </s>
 </doc>

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

=head1 SEE ALSO

L<dta-cab-convert.perl(1)|dta-cab-convert.perl>,
L<DTA::CAB::Format::XmlCommon(3pm)|DTA::CAB::Format::XmlCommon>,
L<DTA::CAB::Format::Builtin(3pm)|DTA::CAB::Format::Builtin>,
L<DTA::CAB::Format(3pm)|DTA::CAB::Format>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...



=cut
