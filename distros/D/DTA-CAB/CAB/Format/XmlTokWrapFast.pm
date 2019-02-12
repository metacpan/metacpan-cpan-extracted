## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::XmlTokWrap.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser|formatter: XML (tokwrap), fast quick & dirty I/O for (.ddc).t.xml

package DTA::CAB::Format::XmlTokWrapFast;
use DTA::CAB::Format::XmlTokWrap;
use DTA::CAB::Datum ':all';
use XML::Parser;
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format::XmlTokWrap);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, filenameRegex=>qr/(?:\.(?i:f[tuws](?:\.?)xml))$/);
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_) foreach (qw(ftxml ft-xml ftwxml ftw-xml));
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
##     output_moot => $bool,		       ##-- include <moot> output element? (default=1)
##     output_ner  => $bool,		       ##-- include <ner> output element? (default=0)
##    }
sub new {
  my $that = shift;
  my $fmt = $that->DTA::CAB::Format::XmlCommon::new
    (
     xprs => undef,
     doc => undef,
     output_moot => 1,
     output_ner  => 0,
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
  my ($doc,$body, $s,$stoks, $w,@stack,%attrs);

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
		      if (defined($attrs{t}) && !defined($attrs{text})) {
			$attrs{text} = $attrs{t};
			delete($attrs{t});
		      }
		      push(@$stoks, $w={%attrs});
		    } elsif ($_[1] eq 'moot') {
		      ##-- w/moot : parse
		      $w->{moot} = {%attrs} if ($w);
		    } elsif ($_[1] eq 'a') {
		      ##-- w/a : do nothing
		      ;
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
		    pop(@stack);
		  },

		  ##----------------
		  ## undef = cb_char($expat,$string)
		  Char  => sub {
		    push(@{$w->{toka}}, $_[1]) if ($stack[$#stack] eq 'a');
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
##  + inherited

##=============================================================================
## Methods: I/O: generic
##==============================================================================

## $fmt = $fmt->close($savetmp=0)
##  + override calls $fmt->flush() and deletes @$fmt{qw(xdoc output)}
sub close {
  return $_[0]->DTA::CAB::Format::close(@_[1..$#_]);
}

## @layers = $fmt->iolayers()
##  + returns PerlIO layers to use for I/O handles
##  + override returns ':raw'
sub iolayers {
  return qw(:raw);
}

##==============================================================================
## Methods: I/O: Block-wise
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Block-wise: Generic

## %blockOpts = $CLASS_OR_OBJECT->blockDefaults()
##  + returns default block options as for blockOptions()
##  + override returns as for $CLASS_OR_OBJECT->blockOptions('2m@s')
sub blockDefaults {
  return ($_[0]->SUPER::blockDefaults(), bsize=>(2*1024*1024), eob=>'s');
}

##=============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Input selection

## $fmt = $fmt->fromString(\$string)
##  + input from string
sub fromString {
  my $fmt = shift;
  $fmt->{doc} = $fmt->xmlparser->parse(ref($_[0]) ? ${$_[0]} : $_[0])
    or $fmt->logconfess("fromString(): XML::Parser::parse() failed: $!");
  return $fmt;
}

## $fmt = $fmt->fromFile($filename)
##  + input from named file: override buffers XML document in $fmt->{xdoc}
sub fromFile {
  my ($fmt,$file) = @_;
  $fmt->{doc} = $fmt->xmlparser->parsefile($file)
    or $fmt->logconfess("fromFile(): XML::Parser::parsefile($file) failed: $!");
  return $fmt;
}

## $fmt = $fmt->fromFh($handle)
##  + input from filehandle: override buffers XML document in $fmt->{xdoc}
sub fromFh {
  my ($fmt,$fh) = @_;
  $fmt->{doc} = $fmt->xmlparser->parse($fh)
    or $fmt->logconfess("fromFh(): XML::Parser::parse($fh) failed: $!");
  return $fmt;
}

##--------------------------------------------------------------
## Methods: Input: Generic API

## $doc = $fmt->parseDocument()
##   + parse document from currently selected input source
##   + override returns buffered $fmt->{doc}
sub parseDocument {
  return $_[0]{doc};
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
  return 'ftxml';
}

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format (default='.ft.xml')
sub defaultExtension { return '.ft.xml'; }

##--------------------------------------------------------------
## Methods: Output: output selection

## $fmt = $fmt->flush()
##  + flush accumulated output
sub flush {
  $_[0]->DTA::CAB::Format::flush(@_[1..$#_]);
}

## $str = $fmt->toString()
## $str = $fmt->toString($formatLevel)
##  + flush buffered output document to byte-string
sub toString {
  $_[0]->DTA::CAB::Format::toString(@_[1..$#_]);
}

## $fmt_or_undef = $fmt->toFile($filename_or_handle, $formatLevel)
##  + flush buffered output document to $filename_or_handle
##  + default implementation calls $fmt->toFh()
sub toFile {
  $_[0]->DTA::CAB::Format::toFile(@_[1..$#_]);
}

## $fmt_or_undef = $fmt->toFh($fh,$formatLevel)
##  + flush buffered output document to filehandle $fh
sub toFh {
  $_[0]->DTA::CAB::Format::toFh(@_[1..$#_]);
}

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

  ##-- $str = fstelt($name,$aname,\@analyses)
  my ($_fsta);
  my $fstelt = sub {
    return '' if (!$_[2]);
    return $xmlelt->($_[0],$nil,
		     map {
		       $_fsta=$_;
		       $xmlempty->(($_[1]||'a'), map {($_=>$_fsta->{$_})} qw(lo lemma hi w))
		     } @{$_[2]}
		    );
  };

  ##-- $str = mootelt($name,$aname,\%data)
  my ($_moota);
  my $mootelt = sub {
    return '' if (!$_[2]);
    return $xmlelt->($_[0],[word=>$_[2]{word},tag=>$_[2]{tag},lemma=>$_[2]{lemma}],
		     #$fstelt->('morph', 'a', $_[2]{morph})
		     ##
		     #(!$_[2]{analyses} || !@{$_[2]{analyses}} ? qw()
		     # : $xmlelt->('analyses',$nil,
		     #	  map {
		     #	    $_moota=$_;
		     #	    $xmlempty->(($_[1]||'a'), map {($_=>$_moota->{$_})} qw(tag lemma prob details))
		     #	  } @{$_[2]{analyses}}))
		    );
  };

  ##-- $str = nerelt($name,$aname,\@analyses)
  my ($_nera);
  my $nerelt = sub {
    return '' if (!$_[2]);
    return $xmlelt->($_[0],$nil,
		     map {
		       $_nera = $_;
		       $xmlempty->($_[1],map {defined($_nera->{$_}) ? ($_=>$_nera->{$_}) : qw()} qw(nid label labid cat func depth))
		     } @{$_[2]}
		    );
  };

  ##--------------------
  ## output handle
  my $fh = $fmt->{fh};
  binmode($fh,':utf8');
  $fh->print("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");

  ##--------------------
  ## guts
  my ($output_moot,$output_ner) = @$fmt{qw(output_moot output_ner)};
  my ($s,$w);
  $fh->print("\n", $xmlstart->('doc', base=>$doc->{base}));
  foreach $s (@{$doc->{body}}) {
    $fh->print("\n ", $xmlstart->('s',id=>$s->{id}, (exists($s->{pn}) ? (pn=>$s->{pn}) : qw())));
    foreach $w (@{$s->{tokens}}) {
      $fh->print("\n\t",
		 $xmlelt->('w',
			   [
			    ##-- word attributes: literals
			    (t=>$w->{text}),
			    (map {$_=>$w->{$_}} qw(u id exlex pnd mapclass errid xc xr xp pb lb bb b xb msafe ws)), #c coff clen b boff blen
			   ],
			   ##
			   ##-- content: tokenizer analyses
			   #(map {$xmlelt->('a',$nil,$xmlescape->($w->{$_}))} @{$w->{toka}||$nil}),
			   #($w->{tokpp} && @{$w->{tokpp}} ? $xmlelt->('tokpp',$nil,map {xmlelt('a',$nil,$xmlescape->($_))} @{$w->{tokpp}}) : qw()),
			   ##
			   ##-- content: xlit
			   #($w->{xlit} ? $xmlempty->('xlit',%{$w->{xlit}}) : qw()),
			   ##
			   ##-- content: fsts
			   #(map {$fstelt->($_,'a',$w->{$_})} qw(lts morph rw mlatin eqpho eqrw)),
			   ##
			   ##-- content: moot
			   #$mootelt->('dmoot','a',$w->{dmoot}),
			   ($output_moot ? $mootelt->('moot','a',$w->{moot}) : qw()),
			   ##
			   ##-- content: ner
			   ($output_ner ? $nerelt->('ner','a',$w->{ner}) : qw()),
			  ));
    }
    $fh->print("\n </s>");
  }
  $fh->print("\n</doc>\n");

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

DTA::CAB::Format::XmlTokWrapFast - DTA::TokWrap XML, fast quick & dirty I/O for (.ddc).t.xml

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Format::XmlTokWrapFast;
 
 ##========================================================================
 ## Constructors etc.
 
 $fmt = CLASS_OR_OBJ->new(%args);
 $xmlparser = $fmt->xmlparser();
 
 ##========================================================================
 ## Methods: I/O: generic
 
 $fmt = $fmt->close($savetmp=0);
 @layers = $fmt->iolayers();
 
 ##========================================================================
 ## Methods: I/O: Block-wise: Generic
 
 %blockOpts = $CLASS_OR_OBJECT->blockDefaults();
 
 ##========================================================================
 ## Methods: Input: Input selection
 
 $fmt = $fmt->fromString(\$string);
 $fmt = $fmt->fromFile($filename);
 $fmt = $fmt->fromFh($handle);
 
 ##========================================================================
 ## Methods: Input: Generic API
 
 $doc = $fmt->parseDocument();
 
 ##========================================================================
 ## Methods: Output: MIME & HTTP stuff
 
 $short = $fmt->shortName();
 $ext = $fmt->defaultExtension();
 
 ##========================================================================
 ## Methods: Output: output selection
 
 $fmt = $fmt->flush();
 $str = $fmt->toString();
 $fmt_or_undef = $fmt->toFile($filename_or_handle, $formatLevel);
 $fmt_or_undef = $fmt->toFh($fh,$formatLevel);
 
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
## DESCRIPTION: DTA::CAB::Format::XmlTokWrapFast: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Format::XmlTokWrapFast inherits from the more generic
but slower L<DTA::CAB::Format::XmlTokWrap|DTA::CAB::Format::XmlTokWrap>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlTokWrapFast: Constructors etc.
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
     level => $level,                        ##-- output formatting level (default=0)
     output_moot => $bool,		       ##-- include <moot> output element? (default=1)
     output_ner  => $bool,		       ##-- include <ner> output element? (default=0)
    }

=item xmlparser

 $xmlparser = $fmt->xmlparser();

returns cached $fmt-E<gt>{xprs} if available,
otherwise caches & returns new XML::Parser

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlTokWrapFast: Methods: I/O: generic
=pod

=head2 Methods: I/O: generic

=over 4

=item close

 $fmt = $fmt->close($savetmp=0);

override calls $fmt-E<gt>flush() and deletes @$fmt{qw(xdoc output)}

=item iolayers

 @layers = $fmt->iolayers();

returns PerlIO layers to use for I/O handles;
override returns ':raw'

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlTokWrapFast: Methods: I/O: Block-wise: Generic
=pod

=head2 Methods: I/O: Block-wise: Generic

=over 4

=item blockDefaults

 %blockOpts = $CLASS_OR_OBJECT->blockDefaults();

returns default block options as for blockOptions();
override returns as for $CLASS_OR_OBJECT-E<gt>blockOptions('2m@s')

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlTokWrapFast: Methods: Input: Input selection
=pod

=head2 Methods: Input: Input selection

=over 4

=item fromString

 $fmt = $fmt->fromString(\$string);

input from string

=item fromFile

 $fmt = $fmt->fromFile($filename);

input from named file: override buffers XML document in $fmt-E<gt>{xdoc}

=item fromFh

 $fmt = $fmt->fromFh($handle);

input from filehandle: override buffers XML document in $fmt-E<gt>{xdoc}

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlTokWrapFast: Methods: Input: Generic API
=pod

=head2 Methods: Input: Generic API

=over 4

=item parseDocument

 $doc = $fmt->parseDocument();

parse document from currently selected input source;
override returns buffered $fmt-E<gt>{doc}.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlTokWrapFast: Methods: Output: MIME & HTTP stuff
=pod

=head2 Methods: Output: MIME & HTTP stuff

=over 4

=item shortName

 $short = $fmt->shortName();

returns "official" short name for this format;
override returns "ftxml".

=item defaultExtension

 $ext = $fmt->defaultExtension();

returns default filename extension for this format;
override returns ".ft.xml".

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlTokWrapFast: Methods: Output: output selection
=pod

=head2 Methods: Output: output selection

=over 4

=item flush

 $fmt = $fmt->flush();

flush accumulated output

=item toString

 $str = $fmt->toString();
 $str = $fmt->toString($formatLevel);

flush buffered output document to byte-string

=item toFile

 $fmt_or_undef = $fmt->toFile($filename_or_handle, $formatLevel);

flush buffered output document to $filename_or_handle;
default implementation calls $fmt-E<gt>toFh().

=item toFh

 $fmt_or_undef = $fmt->toFh($fh,$formatLevel);

flush buffered output document to filehandle $fh

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlTokWrapFast: Methods: Output: quick and dirty
=pod

=head2 Methods: Output: quick and dirty

=over 4

=item putDocument

 $fmt = $fmt->putDocument($doc);

quick and dirty output using .ddc.t.xml attributes only.

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
  <s>
 	<w t="wie" exlex="wie" errid="ec" msafe="1"><moot word="wie" tag="PWAV" lemma="wie"/></w>
 	<w t="oede" msafe="0"><moot word="öde" tag="ADJD" lemma="öde"/></w>
 	<w t="!" exlex="!" errid="ec" msafe="1"><moot word="!" tag="$." lemma="!"/></w>
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

Copyright (C) 2011-2019 by Bryan Jurish

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
