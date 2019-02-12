## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::XmlLing.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser|formatter: XML (flat att.linguistic), fast quick & dirty "flat" XML formatter using TEI att.linguistic features

package DTA::CAB::Format::XmlLing;
use DTA::CAB::Format::XmlTokWrapFast;
use DTA::CAB::Datum ':all';
use XML::Parser;
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format::XmlTokWrapFast);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, filenameRegex=>qr/(?:\.(?i:(?:ling|l[tuws])(?:\.?)xml))$/);
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_) foreach (qw(ltxml lxml ling-xml lt-xml ltwxml ltw-xml));
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
##     ##-- input: new
##     doc   => $doc,         ##-- cached parsed DTA::CAB::Document
##
##     ##-- input: inherited (but unused)
##     #xdoc => $xdoc,                          ##-- XML::LibXML::Document
##     #xprs => $xprs,                          ##-- override: XML::Parser parser
##
##     ##-- output: inherited from DTA::CAB::Format
##     utf8  => $bool,                         ##-- always true
##     level => $level,                        ##-- output formatting level (default=0)
##
##     ##-- input/output: new
##     twcompat => $bool,                      ##-- read/write DTA::TokWrap-style attributes? (for use as CAB::Format::TEI txmlfmt sub-formatter; default=0)
##    }
sub new {
  my $that = shift;
  my $fmt = $that->DTA::CAB::Format::XmlCommon::new
    (
     xprs => undef,
     doc => undef,
     twcompat => 0,
     @_
    );
  return $fmt;
}

## $xmlparser = $fmt->xmlparser()
##  + returns cached $fmt->{xprs} if available
##  + otherwise caches & returns new XML::Parser
sub xmlparser {
  return $_[0]{xprs} if (defined($_[0]{xprs}));
  #my $fmt = shift;

  ##--------------------------------------
  ## closure variables
  my ($doc,$body, $s,$stoks, $w,$wprev,@stack,%attrs);
  my ($wpos,$xpos) = (-2,0);
  my $twcompat = $_[0]{twcompat};

  ##--------------------------------------
  ## parser
  $_[0]{xprs} = XML::Parser->new
    (
     ErrorContext => 1,
     ProtocolEncoding => 'UTF-8',
     #ParseParamEnt => '???',
     Handlers => {
		  ##----------------
		  ## undef = cb_init($expat)
		  Init => sub {
		    $body = [];
		    $doc  = {body=>$body};
		    @stack = qw();
		  },

		  ##----------------
		  ## undef = cb_start($expat, $elt,%attrs)
		  Start => sub {
		    %attrs = @_[2..$#_];
		    push(@stack,$_[1]);

		    if ($_[1] eq 'w') {
		      ##-- w
		      $attrs{id}          = $attrs{'xml:id'} if (defined($attrs{'xml:id'}) && !defined($attrs{'id'}));
		      $attrs{text}        = $attrs{t}     if ($twcompat && !defined($attrs{text}) && defined($attrs{t}));
		      $attrs{moot}{tag}   = $attrs{pos}   if (defined($attrs{pos}));
		      $attrs{moot}{lemma} = $attrs{lemma} if (defined($attrs{lemma}));
		      $attrs{moot}{word}  = $attrs{norm}  if (defined($attrs{norm}));
		      delete @attrs{qw(pos lemma norm xml:id)};
		      push(@$stoks, $w={%attrs});
		    } elsif ($_[1] eq 's') {
		      ##-- s
		      push(@$body, $s={%attrs,tokens=>($stoks=[])});
		    } elsif (@stack==1) {
		      ##-- doc
		      if (defined($attrs{'xml:base'})) {
			$attrs{'base'}=$attrs{'xml:base'};
			delete($attrs{'xml:base'});
		      }
		      $doc = {%attrs, body=>$body};
		    }
		  },

		  ##----------------
		  ## undef = cb_end($expat,$elt)
		  End => sub {
		    if ($stack[$#stack] eq 'w' && !defined($w->{text}) && defined($w->{textRaw})) {
		      $w->{text} = $w->{textRaw};
		      $w->{text} =~ s/\s+/ /sg;
		      $w->{text} =~ s/^\s//s;
		      $w->{text} =~ s/\s$//s;
		      delete($w->{textRaw}) if ($w->{textRaw} eq $w->{text});
		    }
		    pop(@stack);
		  },

		  ##----------------
		  ## undef = cb_char($expat,$string)
		  Char  => sub {
		    $w->{textRaw} .= $_[1] if ($stack[$#stack] eq 'w' && !defined($w->{text}));
		  },

		  ##----------------
		  ## undef = cb_default($expat, $str)
		  #Default => $cb_default,

		  ##----------------
		  ## $parse_rv = cb_final($expat)
		  Final => sub {
		    $body = $s = $stoks = $w = undef;
		    return bless($doc,'DTA::CAB::Document');
		  },
		 },
    )
    or $_[0]->logconfess("couldn't create XML::Parser");

  return $_[0]{xprs};
}

##==============================================================================
## Methods: Persistence
##==============================================================================

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
##  + inherited from XmlTokWrap

##=============================================================================
## Methods: I/O: generic
##==============================================================================

## $fmt = $fmt->close($savetmp=0)
##  + override calls $fmt->flush() and deletes @$fmt{qw(xdoc output)}
##  + inherited from XmlTokWrapFast

## @layers = $fmt->iolayers()
##  + returns PerlIO layers to use for I/O handles
##  + override returns ':raw'
##  + inherited from XmlTokWrapFast

##==============================================================================
## Methods: I/O: Block-wise
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Block-wise: Generic

## %blockOpts = $CLASS_OR_OBJECT->blockDefaults()
##  + returns default block options as for blockOptions()
##  + override returns as for $CLASS_OR_OBJECT->blockOptions('2m@s')
##  + inherited from XmlTokWrapFast

##=============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Input selection

## $fmt = $fmt->fromString(\$string)
##  + input from string
##  + inherited from XmlTokWrapFast

## $fmt = $fmt->fromFile($filename)
##  + input from named file: override buffers XML document in $fmt->{xdoc}
##  + inherited from XmlTokWrapFast

## $fmt = $fmt->fromFh($handle)
##  + input from filehandle: override buffers XML document in $fmt->{xdoc}
##  + inherited from XmlTokWrapFast

##--------------------------------------------------------------
## Methods: Input: Generic API

## $doc = $fmt->parseDocument()
##   + parse document from currently selected input source
##   + override returns buffered $fmt->{doc}
##   + inherited from XmlTokWrapFast

##=============================================================================
## Methods: Output
##==============================================================================

##--------------------------------------------------------------
## Methods: Output: MIME & HTTP stuff

## $short = $fmt->shortName()
##  + returns "official" short name for this format
##  + default just returns package suffix
sub shortName {
  return 'ltxml';
}

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format (default='.ling.xml')
sub defaultExtension { return '.lt.xml'; }

##--------------------------------------------------------------
## Methods: Output: output selection

## $fmt = $fmt->flush()
##  + flush accumulated output
##  + inherited from XmlTokWrapFast

## $str = $fmt->toString()
## $str = $fmt->toString($formatLevel)
##  + flush buffered output document to byte-string
##  + inherited from XmlTokWrapFast

## $fmt_or_undef = $fmt->toFile($filename_or_handle, $formatLevel)
##  + flush buffered output document to $filename_or_handle
##  + default implementation calls $fmt->toFh()
##  + inherited from XmlTokWrapFast

## $fmt_or_undef = $fmt->toFh($fh,$formatLevel)
##  + flush buffered output document to filehandle $fh
##  + inherited from XmlTokWrapFast

##--------------------------------------------------------------
## Methods: Output: quick and dirty

## $fmt = $fmt->putDocument($doc)
sub putDocument {
  my ($fmt,$doc) = @_;

  ##--------------------
  ## local subs

  my $nil = [];

  ##-- $escaped = xmlesc($str) : xml escape (single string)
  my ($_esc);
  my $xmlescape = sub {
    $_esc=shift;
    $_esc=~s/([\&\'\"\<\>])/'&#'.ord($1).';'/ge;
    return $_esc;
  };

  ##-- $str = xmlattrs(%attrs)
  my $xmlattrs = sub {
    return join('', map {' '.$_[$_].'="' . $xmlescape->($_[$_+1]).'"'} grep {defined($_[$_+1])} map {$_*2} (0..$#{_}/2));
  };

  ##-- $str = xmlstart($name,%attrs)
  my $xmlstart = sub {
    return "<$_[0]" . $xmlattrs->(@_[1..$#_]) . ">";
  };

  ##-- $str = xmlempty($name,%attrs)
  my $xmlempty = sub {
    return "<$_[0]" . $xmlattrs->(@_[1..$#_]) . "/>";
  };

  ##-- $str = xmlelt($name,\@attrs,@content_strings)
  my $xmlelt = sub {
    return $xmlempty->($_[0], @{$_[1]||$nil}) if (@_ < 3);
    return $xmlstart->($_[0], @{$_[1]||$nil}) . join('',@_[2..$#_]) . "</$_[0]>";
  };

  ##-- ($beg,$end) = twloc($w)
  my (@loc);
  my $twloc = sub {
    return undef if (!$_[0] || !defined($_[0]{b}));
    @loc = split(' ',$_[0]{b},2);
    return [$loc[0],$loc[0]+$loc[1]];
  };

  ##--------------------
  ## output handle
  my $fh = $fmt->{fh};
  binmode($fh,':utf8');
  $fh->print("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");

  ##--------------------
  ## compatibility
  my $twcompat = $fmt->{twcompat};
  my @twattrs = ($twcompat ? qw(b xb) : qw());

  ##--------------------
  ## guts
  my ($s,$wi,$w, $wjoin,$loc,$loc_prev,$loc_next);
  $fh->print("\n", $xmlstart->('text'));
  foreach $s (@{$doc->{body}}) {
    $fh->print("\n ", $xmlstart->('s','xml:id'=>($s->{id}||$s->{'xml:id'})));

    $loc_prev = undef;
    $loc      = $twloc->($s->{tokens}[0]);

    for ($wi=0; $wi <= $#{$s->{tokens}}; ++$wi) {
      $w = $s->{tokens}[$wi];

      ##-- compute att.linguistic 'join' attribute from TokWrap 'b' attribute
      if (!defined($wjoin=$w->{join}) && $loc) {
	$loc_next  = $twloc->($s->{tokens}[$wi+1]);
	$wjoin     = ($loc_prev    && $loc->[0] == $loc_prev->[1]
		      ? ($loc_next && $loc->[1] == $loc_next->[0]
			 ? 'both'
			 : 'left')
		      : ($loc_next && $loc->[1] == $loc_next->[0]
			 ? 'right'
			 : undef));
	$loc_prev = $loc;
	$loc      = $loc_next;
      } else {
	undef $wjoin;
      }

      $fh->print("\n\t",
		 $xmlelt->('w',
			   [
			    ##-- word attributes: tokwrap (for use as CAB::Format::TEI txmlfmt sub-formatter)
			    (map {($_=>$w->{$_})} @twattrs),
			    ##
			    ##-- word attributes: id
			    ('xml:id'=>($w->{id}||$w->{'xml:id'})),
			    ##
			    ##-- word attributes: att.linguistic
			    ($w->{moot}
			     ? ('lemma'=>$w->{moot}{lemma},
				'pos'=>$w->{moot}{tag},
				'norm'=>$w->{moot}{word})
			     : ($w->{xlit}
				? ('norm'=>$w->{xlit}{latin1Text})
				: qw())),
			    ('join'=>(defined($w->{join}) ? $w->{join} : $wjoin)),
			   ],
			   ##
			   ($twcompat ? qw() : (defined($w->{textRaw}) ? $w->{textRaw} : $xmlescape->($w->{text}))),
			  ));
    }
    $fh->print("\n </s>");
  }
  $fh->print("\n</text>\n");

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

DTA::CAB::Format::XmlLing - Datum parser|formatter: XML: fast quick-and-dirty "flat" XML formatter using TEI att.linguistic features

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Format::XmlLing;
 
 ##========================================================================
 ## Constructors etc.
 
 $fmt = CLASS_OR_OBJ->new(%args);
 $xmlparser = $fmt->xmlparser();
 
 ##========================================================================
 ## Methods: Output: MIME & HTTP stuff
 
 $short = $fmt->shortName();
 $ext = $fmt->defaultExtension();
 
 ##========================================================================
 ## Methods: Output: quick and dirty
 
 $fmt = $fmt->putDocument($doc);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlLing: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Format::XmlLing inherits from 
L<DTA::CAB::Format::XmlTokWrapFast|DTA::CAB::Format::XmlTokWrapFast>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlLing: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $fmt = CLASS_OR_OBJ->new(%args);

object structure: HASH ref

    {
     ##-- input: new
     doc   => $doc,         ##-- cached parsed DTA::CAB::Document
     ##-- input: inherited (but unused)
     #xdoc => $xdoc,                          ##-- XML::LibXML::Document
     #xprs => $xprs,                          ##-- override: XML::Parser parser
     ##-- output: inherited from DTA::CAB::Format
     utf8  => $bool,                         ##-- always true
     level => $level,                        ##-- output formatting level (default=0; unused)
    }

=item xmlparser

 $xmlparser = $fmt->xmlparser();

returns cached $fmt-E<gt>{xprs} if available,
otherwise caches & returns new XML::Parser

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlLing: Methods: Output: MIME & HTTP stuff
=pod

=head2 Methods: Output: MIME & HTTP stuff

=over 4

=item shortName

 $short = $fmt->shortName();

returns "official" short name for this format;
override returns "ltxml".

=item defaultExtension

 $ext = $fmt->defaultExtension();

returns default filename extension for this format (default='.lt.xml')

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlLing: Methods: Output: quick and dirty
=pod

=head2 Methods: Output: quick and dirty

=over 4

=item putDocument

 $fmt = $fmt->putDocument($doc);

quick and dirty output using TEI att.linguistic attributes only;
see L<http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-att.linguistic.html>.

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
 <?xml version="1.0" encoding="UTF-8"?>
 <text>
	<w lemma="wie" pos="PWAV" norm="wie">wie</w>
	<w join="right" lemma="öde" pos="ADJD" norm="öde">oede</w>
	<w join="left" lemma="!" pos="$." norm="!">!</w>
  </s>
 </text>

=cut

##======================================================================
## Footer
##======================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2019 by Bryan Jurish

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
