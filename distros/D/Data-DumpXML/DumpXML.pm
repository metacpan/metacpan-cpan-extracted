package Data::DumpXML;

use strict;
use vars qw(@EXPORT_OK $VERSION);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK=qw(dump_xml dump_xml2 dump);

$VERSION = "1.06";  # $Date: 2003/12/18 09:18:27 $

# configuration
use vars qw($INDENT $INDENT_STYLE $XML_DECL $CPAN $NAMESPACE $NS_PREFIX $SCHEMA_LOCATION $DTD_LOCATION);
$INDENT_STYLE = "XML" unless defined $INDENT_STYLE;
$XML_DECL = 1 unless defined $XML_DECL;
$INDENT = " " unless defined $INDENT;
$CPAN = "http://www.cpan.org/modules/by-authors/Gisle_Aas/" unless defined $CPAN;
$NAMESPACE = $CPAN . "Data-DumpXML-1.05.xsd" unless defined $NAMESPACE;
$NS_PREFIX = "" unless defined $NS_PREFIX;
$SCHEMA_LOCATION = "" unless defined $SCHEMA_LOCATION;
$DTD_LOCATION = $CPAN . "Data-DumpXML-1.04.dtd" unless defined $DTD_LOCATION;

# other globals
use vars qw($NL);


use overload ();
use vars qw(%seen %ref $count $prefix);

sub dump_xml2 {
    local $DTD_LOCATION = "";
    local $XML_DECL = "";
    dump_xml(@_);
}

sub dump_xml {
    local %seen;
    local %ref;
    local $count = 0;
    local $prefix = ($NAMESPACE && $NS_PREFIX) ? "$NS_PREFIX:" : "";

    local $NL = ($INDENT) ? "\n" : "";

    my $out = "";
    $out .= qq(<?xml version="1.0" encoding="US-ASCII"?>\n) if $XML_DECL;
    $out .= qq(<!DOCTYPE data SYSTEM "$DTD_LOCATION">\n) if $DTD_LOCATION;

    $out .= "<${prefix}data";
    $out .= " " . ($NS_PREFIX ? "xmlns:$NS_PREFIX" : "xmlns") . qq(="$NAMESPACE")
	if $NAMESPACE;
    $out .= qq( xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="$SCHEMA_LOCATION")
	if $SCHEMA_LOCATION;

    $out .= ">";
    $out .= format_list(map _dump($_), @_);
    $out .= "</${prefix}data>\n";

    $count = 0;
    $out =~ s/\01/$ref{++$count} ? qq( id="r$ref{$count}") : ""/ge;

    print STDERR $out unless defined wantarray;
    $out;
}

*dump = \&dump_xml;

sub _dump {
    my $rval = \$_[0]; shift;
    my $deref = shift;
    $rval = $$rval if $deref;

    my($class, $type, $id);
    if (overload::StrVal($rval) =~ /^(?:([^=]+)=)?([A-Z]+)\(0x([^\)]+)\)$/) {
	$class = $1;
	$type  = $2;
	$id    = $3;
    } else {
	return qq(<!-- Can\'t parse \") . overload::StrVal($rval) . qq(\" -->);
    }

    if (my $seq = $seen{$id}) {
	my $ref_no = $ref{$seq} || ($ref{$seq} = keys(%ref) + 1);
	return qq(<${prefix}alias ref="r$ref_no"/>);
    }
    $seen{$id} = ++$count;

    $class = $class ? " class=" . quote($class) : "";
    $id = "\1";  # magic that is removed or expanded to ' id="r1"' in the end.

    if ($type eq "SCALAR" || $type eq "REF") {
	return "<${prefix}undef$class$id/>"
	    unless defined $$rval;
	return "<${prefix}ref$class$id>" . format_list(_dump($$rval, 1)) . "</${prefix}ref>"
	    if ref $$rval;
	my($str, $enc) = esc($$rval);
	return "<${prefix}str$class$id$enc>$str</${prefix}str>";
    }
    elsif ($type eq "ARRAY") {
	return "<${prefix}array$class$id/>" unless @$rval;
	return "<${prefix}array$class$id>" . format_list(map _dump($_), @$rval) .
	       "</${prefix}array>";
    }
    elsif ($type eq "HASH") {
	my $out = "<${prefix}hash$class$id>$NL";
	for my $key (sort keys %$rval) {
	    my $val = \$rval->{$key};
	    $val = _dump($$val);
	    if ($INDENT) {
		$val =~ s/^/$INDENT$INDENT/gm;
		$out .= $INDENT;
	    }
	    my($str, $enc) = esc($key);
	    $out .= "<${prefix}key$enc>$str</${prefix}key>$NL$val$NL";
	}
	if ($INDENT_STYLE eq "Lisp") {
	    # kill final NL
	    substr($out, -length($NL)) = "";
	}
	$out .= "</${prefix}hash>";
	return $out;
    }
    elsif ($type eq "GLOB") {
	return "<${prefix}glob$class$id/>";
    }
    elsif ($type eq "CODE") {
	return "<${prefix}code$class$id/>";
    }
    else {
	#warn "Can't handle $type data";
	return "<!-- Unknown type $type -->";
    }
    die "Assert";
}

sub format_list {
    my @elem = @_;
    if ($INDENT) {
	for (@elem) { s/^/$INDENT/gm; }
    }
    return join($NL, "", @elem, ($INDENT_STYLE eq "Lisp" ? () : ("")) );
}

# put a string value in double quotes
sub quote {
    local($_) = shift;
    s/&/&amp;/g;
    s/\"/&quot;/g;
    s/]]>/]]&gt;/g;
    s/</&lt;/g;
    s/([^\040-\176])/sprintf("&#x%x;", ord($1))/ge;
    return qq("$_");
}

sub esc {
    local($_) = shift;
    if (/[\x00-\x08\x0B\x0C\x0E-\x1F\x7f-\xff]/) {
	# \x00-\x08\x0B\x0C\x0E-\x1F these chars can't be represented in XML at all
	# \x7f is special
	# \x80-\xff will be mangled into UTF-8
	require MIME::Base64;
	my $nl = (length($_) < 40) ? "" : $NL;
	my $b64 = MIME::Base64::encode($_, $nl);
	return $nl.$b64, qq( encoding="base64");
    }

    s/&/&amp;/g;
    s/</&lt;/g;
    s/]]>/]]&gt;/g;
    s/([^\040-\176])/sprintf("&#x%x;", ord($1))/ge;
    return $_, "";
}

1;

__END__

=head1 NAME

Data::DumpXML - Dump arbitrary data structures as XML

=head1 SYNOPSIS

 use Data::DumpXML qw(dump_xml);
 $xml = dump_xml(@list)

=head1 DESCRIPTION

This module provides a single function called dump_xml() that takes a
list of Perl values as its argument and produces a string as its result.
The string returned is an XML document that represents any Perl data
structures passed to the function.  Reference loops are handled correctly.

The following data model is used:

   data : scalar*
   scalar = undef | str | ref | alias
   ref : scalar | array | hash | glob | code
   array: scalar*
   hash: (key scalar)*

The distribution comes with an XML schema and a DTD that more formally
describe this structure.

As an example of the XML documents produced, the following call:

  $a = bless [1,2], "Foo";
  dump_xml($a);

produces:

  <?xml version="1.0" encoding="US-ASCII"?>
  <data xmlns="http://www.cpan.org/.../Data-DumpXML.xsd">
   <ref>
    <array class="Foo">
     <str>1</str>
     <str>2</str>
    </array>
   </ref>
  </data>

If dump_xml() is called in a void context, then the dump is printed
on STDERR automatically.  For compatibility with C<Data::Dump>, there
is also an alias for dump_xml() called simply dump().

C<Data::DumpXML::Parser> is a class that can restore
data structures dumped by dump_xml().


=head2 Configuration variables

The generated XML is influenced by a set of configuration variables.
If you modify them, then it is a good idea to localize the effect. For example:

  sub my_dump_xml {
      local $Data::DumpXML::INDENT = "";
      local $Data::DumpXML::XML_DECL = 0;
      local $Data::DumpXML::DTD_LOCATION = "";
      local $Data::DumpXML::NS_PREFIX = "dumpxml";

      return dump_xml(@_);
  }

The variables are:

=over

=item $Data::DumpXML::INDENT

You can set the variable $Data::DumpXML::INDENT to control the amount
of indenting.  The variable contains the whitespace you want to be
used for each level of indenting.  The default is a single space.  To
suppress indenting, set it to "".

=item $Data::DumpXML::INDENT_STYLE

This variable controls where end element are placed.  If you set this
variable to the value "Lisp" then end tags are not prefixed by NL.
This give a more compact output.

=item $Data::DumpXML::XML_DECL

This boolean variable controls whether an XML declaration should be
prefixed to the output.  The XML declaration is the <?xml ...?>
thingy.  The default is 1.  Set this value to 0 to suppress the
declaration.

=item $Data::DumpXML::NAMESPACE

This variable contains the namespace used for the XML elements.
The default is to let this be a URI that actually resolve to the XML
schema on CPAN.  Set it to "" to disable use of namespaces.

=item $Data::DumpXML::NS_PREFIX

This variable contains the namespace prefix to use on the elements.
The default is "", which means that a default namespace will be declared.

=item $Data::DumpXML::SCHEMA_LOCATION

This variable contains the location of the XML schema.  If this
variable is non-empty, then an C<xsi:schemaLocation> attribute is
added to the top level C<data> element.  The default is not to include
this, as the location can be inferred from the default XML namespace
used.

=item $Data::DumpXML::DTD_LOCATION

This variable contains the location of the DTD.  If this variable is
non-empty, then a <!DOCTYPE ...> is included in the output.  The
default is to point to the DTD on CPAN.  Set it to "" to suppress the
<!DOCTYPE ...> line.

=back

=head1 BUGS

Class names with 8-bit characters are dumped as Latin-1, but
converted to UTF-8 when restored by the Data::DumpXML::Parser.

The content of globs and subroutines are not dumped.  They are
restored as the strings "** glob **" and "** code **".

LVALUE and IO objects are not dumped at all.  They simply
disappear from the restored data structure.

=head1 SEE ALSO

L<Data::DumpXML::Parser>, L<XML::Parser>, L<XML::Dumper>, L<Data::Dump>

=head1 AUTHORS

The C<Data::DumpXML> module is written by Gisle Aas <gisle@aas.no>,
based on C<Data::Dump>.

The C<Data::Dump> module was written by Gisle Aas, based on
C<Data::Dumper> by Gurusamy Sarathy <gsar@umich.edu>.

 Copyright 1998-2003 Gisle Aas.
 Copyright 1996-1998 Gurusamy Sarathy.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
