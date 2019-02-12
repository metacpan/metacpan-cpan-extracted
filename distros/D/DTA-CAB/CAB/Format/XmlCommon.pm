## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::Common.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser|formatter: XML (common)

package DTA::CAB::Format::XmlCommon;
use DTA::CAB::Format;
use DTA::CAB::Datum ':all';
use DTA::CAB::Utils ':libxml';
use XML::LibXML;
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format);

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: assumed HASH
##    (
##     ##-- input
##     xdoc => $xdoc,                          ##-- XML::LibXML::Document
##     xprs => $xprs,                          ##-- XML::LibXML parser
##     xprsopts => \%opts,                     ##-- XML::LibXML parser options
##
##     ##-- output
##     #utf8  => $bool,                         ##-- always true
##     level => $level,                        ##-- output formatting level (default=0)
##     output => [$how,$arg]                   ##-- either ['fh',$fh], ['file',$filename], or ['str',\$buf]
##
##     ##-- common
##    )
sub new {
  my $that = shift;
  my $fmt = bless({
		   ##-- input
		   xprs => undef, ##-- see xmlparser() method, below
		   xdoc => undef,
		   #xmlparser_opts => {},

		   ##-- output
		   utf8  => 1,
		   level => 0,
		   output => undef,

		   ##-- common

		   ##-- user args
		   @_
		  }, ref($that)||$that);
  return $fmt;
}

## $xmlparser = $fmt->xmlparser(%xmlparser_opts)
##  + returns cached $fmt->{xprs} if available
##  + otherwise caches & returns DTA::CAB::Utils::libxml_parser()
sub xmlparser {
  return $_[0]{xprs} if (ref($_[0]) && defined($_[0]{xprs}));
  return $_[0]{xprs} = DTA::CAB::Utils::libxml_parser( %{$_[0]{xprsopts}//{}}, @_[1..$#_] );
}

##==============================================================================
## Methods: Persistence
##==============================================================================

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
sub noSaveKeys {
  return ($_[0]->SUPER::noSaveKeys, qw(xdoc xprs));
}

##=============================================================================
## Methods: I/O: generic
##==============================================================================

## $fmt = $fmt->close($savetmp=0)
##  + override calls $fmt->flush() and deletes @$fmt{qw(xdoc output)}
sub close {
  $_[0]->flush();# if (!$_[0]{flushing});
  delete @{$_[0]}{qw(xdoc output)};
  return $_[0]->SUPER::close(@_[1..$#_]);
}

## @layers = $fmt->iolayers()
##  + returns PerlIO layers to use for I/O handles
##  + override returns ':raw'
sub iolayers {
  return qw(:raw);
}

## $fmt = $fmt->flush()
##  + flush any buffered output to selected output channel
##  + override dumps buffered $fmt->{xdoc} to output sink in ($outputHow,$outputArg)=@{$fmt->{out}} and deletes $fmt->{xdoc}
sub flush {
  my $fmt = shift;
  if (defined(my $xdoc=$fmt->{xdoc}) && defined(my $out=$fmt->{output})) {
    if ($out->[0] eq 'string') {
      ${$out->[1]} = $xdoc->toString($fmt->{level} || 0)
	or $fmt->logconfess(ref($xdoc)."::toString() failed: $!");
    }
    if ($out->[0] eq 'file') {
      $xdoc->toFile($out->[1], $fmt->{level} || 0)
	or $fmt->logconfess(ref($xdoc)."::toFile() failed for $out->[1]: $!");
    }
    elsif ($out->[0] eq 'fh') {
      $xdoc->toFH($out->[1], $fmt->{level} || 0)
	or $fmt->logconfess(ref($xdoc)."::toFH() failed for $out->[1]: $!");
    }
  }
  delete $fmt->{xdoc};
  return $fmt;
}

##=============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Input selection

## $fmt = $fmt->fromString(\$string)
##  + input from string: override buffers XML document in $fmt->{xdoc}
sub fromString {
  my $fmt = shift;
  $fmt->{xdoc} = $fmt->xmlparser->parse_string(ref($_[0]) ? ${$_[0]} : $_[0])
    or $fmt->logconfess("XML::LibXML::parse_string() failed: $!");
  return $fmt;
}

## $fmt = $fmt->fromFile($filename)
##  + input from named file: override buffers XML document in $fmt->{xdoc}
sub fromFile {
  my ($fmt,$file) = @_;
  return $fmt->fromFh($file) if (ref($file));
  $fmt->{xdoc} = $fmt->xmlparser->parse_file($file)
    or $fmt->logconfess("XML::LibXML::parse_file() failed for '$file': $!");
  return $fmt;
}

## $fmt = $fmt->fromFh($handle)
##  + input from filehandle: override buffers XML document in $fmt->{xdoc}
sub fromFh {
  my ($fmt,$fh) = @_;
  $fmt->{xdoc} = $fmt->xmlparser->parse_fh($fh)
    or $fmt->logconfess("XML::LibXML::parse_fh() failed for handle '$fh': $!");
  return $fmt;
}

##--------------------------------------------------------------
## Methods: Input: Generic API

## $doc = $fmt->parseDocument()
##   + parse document from currently selected input source
##   + to be overridden by child classes
sub parseDocument {
  my $fmt = shift;
  $fmt->logconfess("parseDocument() not implemented in abstract base class ", __PACKAGE__);
}


##==============================================================================
## Methods: Output
##==============================================================================

##--------------------------------------------------------------
## Methods: Output: Generic

## $type = $fmt->mimeType()
##  + override returns text/xml
sub mimeType { return 'text/xml'; }

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format
sub defaultExtension { return '.xml'; }

##--------------------------------------------------------------
## Methods: Output: output selection

## $fmt = $fmt->toString(\$str)
## $fmt = $fmt->toString(\$str, $formatLevel)
##  + select output to string
##  + override sets $fmt->{output}=['string',\$str]
sub toString {
  my $fmt = shift;
  $fmt->close;
  $fmt->{output} = ['string', ref($_[0]) ? $_[0] : \$_[0]];
  $fmt->formatlevel($_[1]) if (defined($_[1]));
  #$fmt->xmlDocument(); ##-- prepare document
  return $fmt;
}

## $fmt_or_undef = $fmt->toFile($filename, $formatLevel)
##  + select output to file
##  + override sets $fmt->{output}=['file',\$filename]
sub toFile {
  my $fmt = shift;
  return $fmt->toFh(@_)       if (ref($_[0]));
  return $fmt->toFh(\*STDOUT) if ($_[0] eq '-');
  $fmt->close;
  $fmt->{output} = ['file', $_[0]];
  $fmt->formatlevel($_[1]) if (defined($_[1]));
  #$fmt->xmlDocument(); ##-- prepare document
  return $fmt;
}

## $fmt_or_undef = $fmt->toFh($handle, $formatLevel)
##  + flush buffered output document to $filename_or_handle
##  + override sets $fmt->{output}=['fh',$handle]
sub toFh {
  my $fmt = shift;
  $fmt->close;
  $fmt->{output} = ['fh', $_[0]];
  binmode($_[0],':raw'); ##-- set raw mode for XML output
  $fmt->formatlevel($_[1]) if (defined($_[1]));
  #$fmt->xmlDocument();   ##-- prepare document
  return $fmt;
}


##--------------------------------------------------------------
## Methods: Output: local

## $xmldoc = $fmt->xmlDocument()
##  + create or return output buffer $fmt->{xdoc}
sub xmlDocument {
  return $_[0]{xdoc} if (defined($_[0]{xdoc}));
  return $_[0]{xdoc} = XML::LibXML::Document->new("1.0","UTF-8");
}

## $rootnode = $fmt->xmlRootNode()
## $rootnode = $fmt->xmlRootNode($nodname)
##  + returns root node
##  + $nodname defaults to 'doc'
sub xmlRootNode {
  my ($fmt,$name) = @_;
  my $xdoc = $fmt->xmlDocument;
  my $root = $xdoc->documentElement;
  if (!defined($root)) {
    $xdoc->setDocumentElement($root = XML::LibXML::Element->new(defined($name) ? $name : 'doc'));
  }
  return $root;
}

##--------------------------------------------------------------
## Methods: Output: Generic API

sub putToken    { $_[0]->logconfess("putToken(): not implemented in abstract base class ", __PACKAGE__); }
sub putSentence { $_[0]->logconfess("putSentence(): not implemented in abstract base class ", __PACKAGE__); }
sub putDocument { $_[0]->logconfess("putDocument(): not implemented in abstract base class ", __PACKAGE__); }


##--------------------------------------------------------------
## Methods: Output: XML Nodes: Generic

## $nod = $fmt->defaultXmlNode($value,\%opts)
##  + default XML node generator
##  + \%opts:
##     hashElt => $elt,                        ##-- output hash element (default='HASH')
##     listElt => $elt,                        ##-- ouput list element (default='ARRAY')
##     atomElt => $elt,                        ##-- ouput atom element (default='VALUE')
our $HASH_ELT = 'HASH';
our $LIST_ELT = 'ARRAY';
our $ATOM_ELT = 'VALUE';
sub defaultXmlNode {
  my ($fmt,$val,$opts) = @_;
  my $hashElt = $opts->{hashElt}||$fmt->{hashElt}||$HASH_ELT;
  my $listElt = $opts->{listElt}||$fmt->{listElt}||$LIST_ELT;
  my $atomElt = $opts->{atomElt}||$fmt->{atomElt}||$ATOM_ELT;
  my ($vnod);
  if (UNIVERSAL::can($val,'xmlNode') && UNIVERSAL::can($val,'xmlNode') ne \&defaultXmlNode) {
    ##-- xml-aware object (avoiding circularities): $val->xmlNode()
    return $val->xmlNode(@_[2..$#_]);
  }
  elsif (!ref($val)) {
    ##-- non-reference: <ATOM>$val</ATOM> or <VALUE undef="1"/>
    $vnod = XML::LibXML::Element->new($atomElt);
    if (defined($val)) {
      $vnod->appendText($val);
    } else {
      $vnod->setAttribute("undef","1");
    }
  }
  elsif (UNIVERSAL::isa($val,'HASH')) {
    ##-- HASH ref: <HASH ref="$ref"> ... <ENTRY key="$eltKey">defaultXmlNode($eltVal)</ENTRY> ... </HASH>
    $vnod = XML::LibXML::Element->new($hashElt);
    $vnod->setAttribute("ref",ref($val)) if (ref($val) ne 'HASH');
    foreach (keys(%$val)) {
      my $enod = $fmt->defaultXmlNode($val->{$_},$opts);
      $enod->setAttribute("key",$_);
      $vnod->addChild($enod);
    }
  }
  elsif (UNIVERSAL::isa($val,'ARRAY')) {
    ##-- ARRAY ref: <ARRAY ref="$ref"> ... xmlNode($eltVal) ... </ARRAY>
    $vnod = XML::LibXML::Element->new($listElt);
    $vnod->setAttribute("ref",ref($val)) if (ref($val) ne 'ARRAY');
    foreach (@$val) {
      $vnod->addChild($fmt->defaultXmlNode($_));
    }
  }
#  elsif (UNIVERSAL::isa($val,'SCALAR')) {
#    ##-- SCALAR ref: <SCALAR ref="$ref"> xmlNode($$val) </SCALAR>
#    $vnod = XML::LibXML::Element->new("SCALAR");
#    $vnod->setAttribute("ref",ref($val)); #if (ref($val) ne 'SCALAR');
#    $vnod->addChild($fmt->defaultXmlNode($$val));
#  }
  else {
    ##-- other reference (CODE,etc.): <VALUE ref="$ref" unknown="1">"$val"</VALUE>
    $fmt->logcarp("defaultXmlNode(): default node generator clause called for value '$val'");
    $vnod = XML::LibXML::Element->new($atomElt);
    $vnod->setAttribute("ref",ref($val));
    $vnod->setAttribute("unknown","1");
    $vnod->appendText("$val");
  }
  return $vnod;
}



1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Format::XmlCommon - Datum parser|formatter: XML: base class

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Format::XmlCommon;
 
 ##========================================================================
 ## Constructors etc.
 
 $fmt = DTA::CAB::Format::XmlCommon->new(%args);
  
 ##========================================================================
 ## Methods: Input
 
 $fmt = $fmt->close();
 $fmt = $fmt->fromFile($filename_or_handle);
 $fmt = $fmt->fromFh($filename_or_handle);
 $fmt = $fmt->fromString($string);
 
 ##========================================================================
 ## Methods: Output
 
 $fmt = $fmt->flush();
 $fmt = $fmt->toString(\$str);
 $fmt = $fmt->toFile($file);
 $fmt = $fmt->toFh($fh);
 $xmldoc = $fmt->xmlDocument();
 $rootnode = $fmt->xmlRootNode();
 $nod = $fmt->defaultXmlNode($value,\%opts);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Format::XmlCommon is a base class for XML-formatters
using XML::LibXML, and is not a fully functional format class by itself.
See subclass documentation for details.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlCommon: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Format::XmlCommon
inherits from
L<DTA::CAB::Format|DTA::CAB::Format>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlCommon: Constructors etc.
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
## DESCRIPTION: DTA::CAB::Format::XmlCommon: Methods: Persistence
=pod

=head2 Methods: Persistence

=over 4

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();

Override: returns list of keys not to be saved.
Here, C<qw(xdoc xprs)>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlCommon: Methods: Input
=pod

=head2 Methods: Input

=over 4

=item close

 $fmt = $fmt->close();

Override: close current input source.

=item fromFile

 $fmt = $fmt->fromFile($filename_or_handle);

Override: select input from file.

=item fromFh

 $fmt = $fmt->fromFh($fh);

Override: select input from filehandle $fh.

=item fromString

 $fmt = $fmt->fromString($string);

Override: select input from string $string.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::XmlCommon: Methods: Output
=pod

=head2 Methods: Output

=over 4

=item flush

 $fmt = $fmt->flush();

Override: flush accumulated output.

=item toString

 $str = $fmt->toString();
 $str = $fmt->toString($formatLevel);

Override: flush buffered output to byte-string.
$formatLevel is passed to XML::LibXML::Document::toString(),
and defaults to $fmt-E<gt>{level}.

=item toFh

 $fmt_or_undef = $fmt->toFh($fh,$formatLevel);

Override: flush buffered output document to filehandle $fh.

=item xmlDocument

 $xmldoc = $fmt->xmlDocument();

Returns output buffer $fmt-E<gt>{xdoc}, creating it
if not yet defined.

=item xmlRootNode

 $rootnode = $fmt->xmlRootNode();
 $rootnode = $fmt->xmlRootNode($nodname);

Returns output buffer root node, creating one if not yet defined.

$nodname is the name of the root node to create (if required);
default='doc'.

=item putToken

Not implemented here.

=item putSentence

Not implemented here.

=item putDocument

Not implemented here.

=item defaultXmlNode

 $nod = $fmt->defaultXmlNode($value,\%opts);

Default XML node generator, which creates very perl-ish XML.

%opts is unused.

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

Copyright (C) 2009-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.
