## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::TCF.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser|formatter: XML: CLARIN-D TCF (selected features only)
##  + uses DTA::CAB::Format::XmlTokWrap for output

package DTA::CAB::Format::TCF;
use DTA::CAB::Format::XmlCommon;
use DTA::CAB::Format::Raw; ##-- for tcf text tokenization
use DTA::CAB::Datum ':all';
#use DTA::CAB::Utils ':temp';
use XML::LibXML;
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format::XmlCommon);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, filenameRegex=>qr/\.(?i:(?:tcf[\.\-_]?xml)|(?:tcf))$/);

  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_, opts=>{tcflayers=>'text'})
      foreach (qw(tcf-text tcf+text));
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_, opts=>{tcflayers=>'text tokens sentences'})
      foreach (qw(tcf-tok tcf+tok));

  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_, opts=>{tcflayers=>'tokens sentences orthography'})
      foreach (qw(tcf-orth tcf+orth tcf-web)); ##-- for weblicht/dta
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_, opts=>{tcflayers=>'tokens sentences postags lemmas'})
      foreach (qw(tcf-pos tcf+pos)); ##-- for weblicht/d*
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_, opts=>{tcflayers=>'tokens sentences orthography postags lemmas'})
      foreach (qw(tcf tcf-xml tcfxml full-tcf xtcf));
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_, opts=>{tcflayers=>'tokens sentences orthography postags lemmas names'})
      foreach (qw(tcf+ner tcf+names)); ##-- for including named entities parsed from teiws

  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_, opts=>{tcflayers=>'tei text'})
      foreach (qw(tcf-tei-text tcf-tei+text tcf+tei+text));
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_, opts=>{tcflayers=>'tei text tokens sentences'})
      foreach (qw(tcf-tei-tok tcf-tei+tok tcf+tei+tok));
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
##     ##-- new in TCF
##     tcfbufr => \$buf,                       ##-- raw TCF buffer, for spliceback mode
##     textbufr => \$text,                     ##-- raw text buffer, for spliceback mode
##     tcflog  => $level,		       ##-- debugging log-level (default: 'off')
##     spliceback => $bool,                    ##-- (output) if true (default), splice data back into 'tcfbufr' if available; otherwise create new TCF doc
##     tcflayers => $tcf_layer_names,          ##-- layer names to include, space-separated list; known='tei text tokens sentences postags lemmas orthography'
##     tcftagset => $tagset,                   ##-- tagset name for POStags element (default='stts')
##     logsplice => $level,		       ##-- log level for spliceback messages (default:'none')
##     trimtext => $bool,                      ##-- if true (default), waste tokenizer hints will be trimmed from 'text' layer
##
##     ##-- input: inherited from XmlCommon
##     xdoc => $xdoc,                          ##-- XML::LibXML::Document
##     xprs => $xprs,                          ##-- XML::LibXML parser
##
##     ##-- output: inherited from XmlCommon
##     level => $level,                        ##-- output formatting level (OVERRIDE: default=1)
##     output => [$how,$arg]                   ##-- either ['fh',$fh], ['file',$filename], or ['str',\$buf]
##    }
sub new {
  my $that = shift;
  my $fmt = $that->SUPER::new(
			      ##-- local
			      #tcfbufr => undef,
			      tcflog   => 'off', ##-- debugging log-level
			      #tcflayers => 'tei text tokens sentences orthography postags lemmas names',
			      tcflayers => 'tokens sentences orthography',
			      tcftagset => 'stts',
			      spliceback => 1,
			      logsplice => 'none',
			      trimtext => 1,

			      ##-- overrides (XmlTokWrap, XmlNative, XmlCommon)
			      ignoreKeys => {
					     tcfbufr=>undef,
					     textbufr=>undef,
					     tcfdoc=>undef,
					    },
			      xprsopts => {keep_blanks=>0},
			      level => 1,

			      ##-- user args
			      @_
			     );

  return $fmt;
}


##=============================================================================
## Methods: Generic

##=============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Generic API

## $fmt = $fmt->close()
##  + close current input source, if any
##  + INHERITED from XmlCommon (calls flush())

## $fmt = $fmt->from(String|File|Fh)
##  + INHERITED from XmlCommon : populates $fmt->{xdoc}

## $doc = $fmt->parseDocument()
##  + parse buffered XML::LibXML::Document from $fmt->{xdoc}
sub parseDocument {
  my $fmt = shift;
  $fmt->vlog($fmt->{tcflog}, "parseDocument()");

  ##-- parse: basic
  my $doc   = DTA::CAB::Document->new();
  my $xdoc  = $fmt->{xdoc};
  my $xroot = $xdoc->documentElement;
  $doc->{tcfdoc} = $xdoc if ($fmt->{spliceback});

  ##-- parse: metadata
  if (defined(my $xmeta = [$xroot->getChildrenByLocalName("MetaData")]->[0])) {
    my ($xsrc) = $xmeta->getChildrenByLocalName('source');
    $doc->{source} = $xsrc->textContent if (defined($xsrc));
  }

  ##-- parse: corpus
  my $xcorpus = [$xroot->getChildrenByLocalName('TextCorpus')]->[0]
    or $fmt->logconfess("parseDocument(): no TextCorpus node found in XML document");

  ##-- parse: text (textbufr)
  ## + annoying hack: we grep for elements here b/c libxml getChildrenByLocalName('text') also returns text-nodes!
  my ($xtext) = grep {UNIVERSAL::isa($_,'XML::LibXML::Element')} $xcorpus->getChildrenByLocalName('text');
  if ($xtext) {
    my $textbuf = $xtext->textContent;
    $doc->{textbufr} = \$textbuf;
  }

  ##-- check for pre-tokenized input
  if (defined(my $xtokens = [$xcorpus->getChildrenByLocalName('tokens')]->[0])) {
    ##------------ pre-tokenized input
    ##-- parse: tokens
    my (@w,%id2w,$w);
    foreach ($xtokens->getChildrenByLocalName('token')) {
      push(@w, $w={text=>$_->textContent});
      if (!defined($w->{id}=$_->getAttribute('ID'))) {
	$w->{id} = sprintf("w%x", $#w);
	$_->setAttribute('ID'=>$w->{id});
      }
      $id2w{$w->{id}} = $w;
    }

    ##-- parse: sentences
    my ($s);
    if (defined(my $xsents = [$xcorpus->getChildrenByLocalName('sentences')]->[0])) {
      my $body = $doc->{body};
      foreach ($xsents->getChildrenByLocalName('sentence')) {
	push(@$body, $s={});
	$s->{id}     = $_->getAttribute('ID') if ($_->hasAttribute('ID'));
	$s->{tokens} = [ @id2w{split(' ',$_->getAttribute('tokenIDs'))} ];
      }
    } else {
      $doc->{body} = {tokens=>\@w}; ##-- single-sentence
    }

    ##-- parse: POStags -> moot/tag
    my ($id);
    if (defined(my $xpostags = [$xcorpus->getChildrenByLocalName('POStags')]->[0])) {
      foreach ($xpostags->getChildrenByLocalName('tag')) {
	$id = $_->getAttribute('tokenIDs');
	$id2w{$id}{moot}{tag} = $_->textContent;
      }
    }

    ##-- parse: lemmas -> moot/lemma
    if (defined(my $xlemmas = [$xcorpus->getChildrenByLocalName('lemmas')]->[0])) {
      foreach ($xlemmas->getChildrenByLocalName('lemma')) {
	$id = $_->getAttribute('tokenIDs');
	$id2w{$id}{moot}{lemma} = $_->textContent;
      }
    }

    ##-- parse: orthography -> moot/word
    if (defined(my $xorths = [$xcorpus->getChildrenByLocalName('orthography')]->[0])) {
      foreach (grep {($_->getAttribute('operation')//'') eq 'replace'} $xorths->getChildrenByLocalName('correction')) {
	$id = $_->getAttribute('tokenIDs');
	$id2w{$id}{moot}{word} = $_->textContent;
      }
    }
  }
  elsif ($doc->{textbufr}) {
    ##------------ un-tokenized input
    my $rawfmt = DTA::CAB::Format::Raw->new();
    my $rawdoc = DTA::CAB::Format::Raw->new->parseString( ${$doc->{textbufr}} );
    $doc->{body} = $rawdoc->{body};
  }
  else {
    ##------------ no source
    $fmt->logconfess("parseDocument(): no TextCorpus/text or TextCorpus/tokens node found in XML document");
  }

  $fmt->vlog($fmt->{tcflog}, "parseDocument(): returning");
  return $doc;
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
  return 'tcf';
}

## $type = $fmt->mimeType()
##  + override returns text/xml
sub mimeType { return 'text/tcf+xml'; }

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format (default='.cab')
sub defaultExtension { return '.tcf.xml'; }

##--------------------------------------------------------------
## Methods: Output: output selection

## $fmt = $fmt->flush()
##  + flush any buffered output to selected output source
sub flush {
  my $fmt = shift;
  $fmt->vlog($fmt->{tcflog}, "flush()") if (Log::Log4perl->initialized);
  $fmt->SUPER::flush(@_) || return undef;
  delete @$fmt{qw(tcfbufr tcfdoc outbufr)};
  return $fmt;
}

## $fmt = $fmt->to(String|File|Fh)
##  + INHERITED from XmlCommon : sets up $fmt->{output}=($outputHow,$outputArg)

##--------------------------------------------------------------
## Methods: Output: Generic API

## $fmt = $fmt->putDocument($doc)
##  + override respects local 'spliceback' and 'tcflayers' flags
sub putDocument {
  my ($fmt,$doc) = @_;
  $fmt->vlog($fmt->{tcflog}, "putDocument()");

  ##-- common vars
  my $spliceback = $fmt->{spliceback};
  my $layers = $fmt->{tcflayers} // '';

  ##-- spliceback?
  my ($xdoc);
  if ($spliceback) {
    $xdoc = $doc->{tcfdoc} // $fmt->{tcfdoc};
    if (!$xdoc) {
      my $bufr = $doc->{tcfbufr} // $fmt->{tcfbufr};
      if (!$bufr || !$$bufr) {
	$fmt->vlog($fmt->{logsplice}, "spliceback mode requested but no 'tcfdoc' or 'tcfbufr' document property - creating new document!");
	$spliceback = 0;
      }
    }
  }
  $xdoc //= XML::LibXML::Document->new("1.0","UTF-8");
  $fmt->{xdoc} = $xdoc;

  ##-- document structure: root
  my ($xroot);
  if (!defined($xroot = $xdoc->documentElement)) {
    $xdoc->setDocumentElement( $xroot = $xdoc->createElement('D-Spin') );
    $xroot->setNamespace('http://www.dspin.de/data');
    $xroot->setAttribute('version'=>'0.4');
  }

  ##-- document structure: metadata
  my ($xmeta) = $xroot->getChildrenByLocalName('MetaData');
  if (!defined($xmeta)) {
    $xmeta = $xroot->addNewChild(undef,'MetaData');
    $xmeta->setNamespace('http://www.dspin.de/data/metadata');
    $xmeta->appendTextChild('source', $doc->{source}) if (defined($doc->{source}));
  }

  ##-- document structure: corpus
  my ($xcorpus) = $xroot->getChildrenByLocalName('TextCorpus');
  if (!defined($xcorpus)) {
    $xcorpus = $xroot->addNewChild(undef,'TextCorpus');
    $xcorpus->setNamespace('http://www.dspin.de/data/textcorpus');
    $xcorpus->setAttribute('lang'=>'de');
  }

  ##-- document structure: TextCorpus/tei
  if ($layers =~ /\btei\b/ && defined($doc->{teibufr})) {
    my ($xtei) = $xcorpus->getChildrenByLocalName("textSource");
    my $xtype  = $xtei ? ($xtei->getAttribute('type')//'') : '';
    undef ($xtei) if ($xtype !~ m{^(?:text|application)/tei\+xml\b} || $xtype =~ m{\btokenized=(?![0n])});
    if (!defined($xtei)) {
      $xtei = $xcorpus->addNewChild(undef,'textSource');
      $xtei->setAttribute('type'=>'application/tei+xml');
      $xtei->appendText(${$doc->{teibufr}});
    }
  }

  ##-- document structure: TextCorpus/text
  if ($layers =~ /\btext\b/) {
    ##-- annoying hack: we grep for elements here b/c libxml getChildrenByLocalName('text') also returns text-nodes!
    my ($xtext) = grep {UNIVERSAL::isa($_,'XML::LibXML::Element')} $xcorpus->getChildrenByLocalName('text');
    if (!defined($xtext)) {
      $xtext = $xcorpus->addNewChild(undef,'text');
      if (defined($doc->{textbufr})) {
	##-- use doc-buffered text content
	my $txt = ${$doc->{textbufr}};
	$txt =~ s/\s*\$WB\$\s*/ /sg;
	$txt =~ s/\s*\$SB\$\s*/\n\n/sg;
	$txt =~ s/%%[^%]*%%//sg;
	$xtext->appendText($txt);
      }
      else {
	##-- generate dummy text content
	$xtext->appendText(join(' ', map {$_->{text}} @{$_->{tokens}})."\n") foreach (@{$doc->{body}});
      }
    }
  }

  ##-- document structure: corpus structure
  my ($tokens,$sents,$lemmas,$postags,$orths,$names);
  if ($layers =~ /\btokens\b/ && !$xcorpus->getChildrenByLocalName('tokens')) {
    $tokens = $xcorpus->addNewChild(undef,'tokens');
  }
  if ($layers =~ /\bsentences\b/ && !$xcorpus->getChildrenByLocalName('sentences')) {
    $sents = $xcorpus->addNewChild(undef,'sentences');
  }
  if ($layers =~ /\blemmas\b/ && !$xcorpus->getChildrenByLocalName('lemmas')) {
    $lemmas = $xcorpus->addNewChild(undef,'lemmas');
    #$lemmas->setAttribute('type'=>'CAB');
  }
  if ($layers =~ /\bpostags\b/ && !$xcorpus->getChildrenByLocalName('POStags')) {
    $postags = $xcorpus->addNewChild(undef,'POStags');
    $postags->setAttribute('tagset'=>$fmt->{tcftagset}) if ($fmt->{tcftagset});
    #$postags->setAttribute('type'=>'CAB');
  }
  if ($layers =~ /\borthography\b/ && !$xcorpus->getChildrenByLocalName('orthography')) {
    $orths = $xcorpus->addNewChild(undef,'orthography');
    #$orths->setAttribute('type'=>'CAB');
  }
  if ($layers =~ /\bnames\b/ && !$xcorpus->getChildrenByLocalName('namedEntities')) {
    $names = $xcorpus->addNewChild(undef,'namedEntities');
    $names->setAttribute('type'=>'CoNLL2002');
  }

  ##-- ensure ids
  my $wi = 0;
  my $si = 0;
  my $ni = 0;
  my (%nid2nod); ##-- ($nerEntityId => $tcfNamedEntityNode), for 'names' layer
  my ($s,$w,$wid,@wids,$snod,$wnod,$nnod);
  my ($pos,$lemma,$orth,$nea,$neid,$necls);
  foreach $s (@{$doc->{body}}) {
    ++$si;
    @wids = qw();
    foreach $w (@{$s->{tokens}}) {
      ++$wi;
      $wid = $w->{id} // sprintf("w%x",$wi);
      push(@wids,$wid);

      ##-- generate token node: <token ID="t_0">Karin</token>
      if ($tokens) {
	$wnod = $tokens->addNewChild(undef,'token');
	$wnod->setAttribute(ID=>$wid);
	$wnod->appendText($w->{text});
      }

      ##-- generate token data: tag, lemma, orthography
      $pos = $lemma = $orth = undef;
      if ($w->{moot}) {
	$pos   = $w->{moot}{tag};
	$lemma = $w->{moot}{lemma};
	$orth  = $w->{moot}{word};
      }
      elsif ($w->{dmoot}) {
	$orth = $w->{dmoot}{tag};
      }
      $orth  //= $w->{exlex} // ($w->{xlit} && $w->{xlit}{isLatinExt} ? $w->{xlit}{latin1Text} : undef);

      if ($postags && defined($pos)) {
	##-- POStags: <tag ID="pt_0" tokenIDs="t_0">NE</tag>
	  $wnod = $postags->addNewChild(undef,'tag');
	  $wnod->setAttribute(tokenIDs=>$wid);
	  $wnod->appendText($pos);
	}
      if ($lemmas && defined($lemma)) {
	##-- lemmas: <lemma ID="le_0" tokenIDs="t_0">Karin</lemma>
	$wnod = $lemmas->addNewChild(undef,'lemma');
	$wnod->setAttribute(tokenIDs=>$wid);
	$wnod->appendText($lemma);
      }
      if ($orths && defined($orth) && $orth ne $w->{text}) {
	##-- orthography: <correction operation="replace" tokenIDs="t_0">Karina</correction>
	$wnod = $orths->addNewChild(undef,'correction');
	$wnod->setAttribute(tokenIDs=>$wid);
	$wnod->setAttribute(operation=>'replace'); ##-- "norm" would be better, but isn't allowed
	$wnod->appendText($orth);
      }
      if ($names && defined($w->{ner})) {
	##-- names: populate %nid2nod
	foreach $nea (@{$w->{ner}}) {
	  $neid = $nea->{nid} || "n$wid";
	  if (defined($nnod=$nid2nod{$neid})) {
	    ##-- append token to existing tcf namedEntities/entity node
	    $nnod->setAttribute('tokenIDs',$nnod->getAttribute('tokenIDs').' '.$wid);
	  } else {
	    ##-- create new tcf namedEntities/entity node
	    ++$ni;
	    $nnod = $nid2nod{$neid} = $names->addNewChild(undef,'entity');

	    ##-- CoNLL2002 ner categories: PER, LOC, ORG, MISC
	    $necls = $nea->{func} || 'MISC';
	    $necls = ($necls =~ /^(?:per|\@(?:First|Last|Title))/i ? 'PER'
		      : ($necls =~ /^place|loc|geo/i ? 'LOC'
			 : ($necls =~ /^org/i ? 'ORG'
			    : 'MISC')));

	    $nnod->setAttribute('ID' => $neid);
	    $nnod->setAttribute('class' => $necls);
	    $nnod->setAttribute('tokenIDs' => $wid);
	  }
	}
      }
    }

    if ($sents) {
      ##-- generate sentence node: <sentence ID="s_0" tokenIDs="t_0 t_1 t_2 t_3 t_4 t_5"></sentence>
      $snod = $sents->addNewChild(undef,'sentence');
      $snod->setAttribute(ID=>($s->{id} // sprintf("s%x",$si)));
      $snod->setAttribute(tokenIDs=>join(' ',@wids));
    }
  }

  $fmt->vlog($fmt->{tcflog}, "putDocument(): returning");
  return $fmt;
}

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=encoding utf8

=head1 NAME

DTA::CAB::Format::TCF - Datum parser|formatter: CLARIN-D TCF (selected features only)

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Format::TCF;
 
 ##========================================================================
 ## Constructors etc.
 
 $fmt = CLASS_OR_OBJ->new(%args);
 
 ##========================================================================
 ## Methods: Input: Generic API
 
 $doc = $fmt->parseDocument();
 
 ##========================================================================
 ## Methods: Output: MIME & HTTP stuff
 
 $short = $fmt->shortName();
 $type = $fmt->mimeType();
 $ext = $fmt->defaultExtension();
 
 ##========================================================================
 ## Methods: Output: output selection
 
 $fmt = $fmt->flush();
 
 ##========================================================================
 ## Methods: Output: Generic API
 
 $fmt = $fmt->putDocument($doc);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::TCF: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Format::TCF inherits from L<DTA::CAB::Format::XmlCommon|DTA::CAB::Format::XmlCommon>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::TCF: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $fmt = CLASS_OR_OBJ->new(%args);

object structure: HASH ref

    {
     ##-- new in TCF
     tcfbufr => \$buf,                       ##-- raw TCF buffer, for spliceback mode
     textbufr => \$text,                     ##-- raw text buffer, for spliceback mode
     tcflog  => $level,		       ##-- debugging log-level (default: 'off')
     spliceback => $bool,                    ##-- (output) if true (default), splice data back into 'tcfbufr' if available; otherwise create new TCF doc
     tcflayers => $tcf_layer_names,          ##-- layer names to include, space-separated list; known='tei text tokens sentences postags lemmas orthography'
     tcftagset => $tagset,                   ##-- tagset name for POStags element (default='stts')
     logsplice => $level,		       ##-- log level for spliceback messages (default:'none')
     trimtext => $bool,                      ##-- if true (default), waste tokenizer hints will be trimmed from 'text' layer
     ##-- input: inherited from XmlCommon
     xdoc => $xdoc,                          ##-- XML::LibXML::Document
     xprs => $xprs,                          ##-- XML::LibXML parser
     ##-- output: inherited from XmlCommon
     level => $level,                        ##-- output formatting level (OVERRIDE: default=1)
     output => [$how,$arg]                   ##-- either ['fh',$fh], ['file',$filename], or ['str',\$buf]
    }

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::TCF: Methods: Input: Generic API
=pod

=head2 Methods: Input: Generic API

=over 4

=item parseDocument

 $doc = $fmt->parseDocument();

parse buffered XML::LibXML::Document from $fmt-E<gt>{xdoc}

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::TCF: Methods: Output: MIME & HTTP stuff
=pod

=head2 Methods: Output: MIME & HTTP stuff

=over 4

=item shortName

 $short = $fmt->shortName();

returns "official" short name for this format;
override returns "tcf".

=item mimeType

 $type = $fmt->mimeType();

override returns text/xml

=item defaultExtension

 $ext = $fmt->defaultExtension();

returns default filename extension for this format;
override returns ".tcf.xml".

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::TCF: Methods: Output: output selection
=pod

=head2 Methods: Output: output selection

=over 4

=item flush

 $fmt = $fmt->flush();

flush any buffered output to selected output source

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::TCF: Methods: Output: Generic API
=pod

=head2 Methods: Output: Generic API

=over 4

=item putDocument

 $fmt = $fmt->putDocument($doc);

override respects local 'spliceback' and 'tcflayers' flags

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
 <D-Spin xmlns="http://www.dspin.de/data" version="0.4">
  <MetaData xmlns="http://www.dspin.de/data/metadata"/>
  <TextCorpus xmlns="http://www.dspin.de/data/textcorpus" lang="de">
    <text>wie oede!</text>
    <tokens>
      <token ID="w1">wie</token>
      <token ID="w2">oede</token>
      <token ID="w3">!</token>
    </tokens>
    <sentences>
      <sentence ID="s1" tokenIDs="w1 w2 w3"/>
    </sentences>
    <lemmas>
      <lemma tokenIDs="w1">wie</lemma>
      <lemma tokenIDs="w2">öde</lemma>
      <lemma tokenIDs="w3">!</lemma>
    </lemmas>
    <POStags tagset="stts">
      <tag tokenIDs="w1">PWAV</tag>
      <tag tokenIDs="w2">ADJD</tag>
      <tag tokenIDs="w3">$.</tag>
    </POStags>
    <orthography>
      <correction tokenIDs="w2" operation="replace">öde</correction>
    </orthography>
  </TextCorpus>
 </D-Spin>

If the input contains a 'text' layer but no 'tokens' or 'sentences' layers,
the 'text' layer will be tokenized using the L<DTA::CAB::Format::Raw|DTA::CAB::Format::Raw> class.

=cut

##======================================================================
## Footer
##======================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2019 by Bryan Jurish

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
