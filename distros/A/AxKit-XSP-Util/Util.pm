# $Id: Util.pm,v 1.15 2002/05/27 15:52:01 matt Exp $

package AxKit::XSP::Util;
use strict;
use Apache::AxKit::Language::XSP;
use HTTP::GHTTP;
use Apache::File;
use XML::LibXML 1.31;
use Time::Piece; # overrides localtime

use vars qw/@ISA $NS $VERSION/;

@ISA = ('Apache::AxKit::Language::XSP');
$NS = 'http://apache.org/xsp/util/v1';

$VERSION = "1.6";

## Taglib subs

# insert from a local file
sub include_file {
    my ($document, $parent, $filename) = @_;
    my $doc = XML::LibXML->new()->parse_file($filename);
    if ($doc) {
        my $root = $doc->getDocumentElement();
        $root = $document->importNode($root);
        $parent->appendChild($root);
    }
    else {
        die "XML::LibXML returned undef";
    }
}


# insert from a (possibly) remote file
# the cool (or maybe *not* so cool) thing is that
# if the uri is located on an AxKit-enabled server,
# we get it "pre-transformed" by any stylesheets
# declared in the doc. could be useful for widget building. . .
sub include_uri {
    my ($document, $parent, $uri) = @_;
    
    my $raw_xml;
    if ($uri =~ /^axkit:/) {
        $raw_xml = AxKit::get_axkit_uri($uri);
    }
    else {
        my $ua = HTTP::GHTTP->new($uri);
        $ua->process_request;
        $raw_xml = $ua->get_body;
    }
    my $doc = XML::LibXML->new()->parse_string($raw_xml);
    if ($doc) {
        my $root = $doc->getDocumentElement();
        $root = $document->importNode($root);
        $parent->appendChild($root);
    }
    else {
        die "XML::LibXML returned undef";
    }
}

# insert from a SCALAR
sub include_expr {
    my ($document, $parent, $frag) = @_;
    if ($frag || $frag == 0) {
        my $doc = XML::LibXML->new()->parse_string( $frag ); 
        if ($doc) {
            my $root = $doc->getDocumentElement();
            $root = $document->importNode($root);
            $parent->appendChild($root);
        }
        else {
            die "XML::LibXML returned undef";
        }
    }
}

# insert from a local file as plain text
sub get_file_contents {
    my ($filename) = @_;
    my $fh = Apache::File->new($filename) || 
       throw Apache::AxKit::Exception::IO( -text => "error opening $filename");
    flock($fh, 1);
    local $/;
    my $content = <$fh>;
    $fh->close;
    return $content;
}

# return the time in strftime formats.
sub get_date {
    my ($format) = @_;
    my $t = localtime;
    my $ret = $t->strftime($format);
    return $ret;
}

## Parser subs
        
sub parse_char {
    my ($e, $text) = @_;
    $text =~ s/^\s*//;
    $text =~ s/\s*$//;

    return '' unless $text;

    $text =~ s/\|/\\\|/g;
    if ($e->current_element() =~ /^(format|name|href)$/) {
        return ". q|$text|"
    }
    return ''; # nothing else in util: should have text (?)
}

sub parse_start {
    my ($e, $tag, %attribs) = @_; 
#    warn "Checking: $tag\n";


    if ($tag eq 'include-file') {

        my $code = "{# start include-file\nmy (\$_file_name);";
        if ($attribs{name}) {
            $code .= '$_file_name = q|' . $attribs{name} . '|;';
        }
        return $code;
    }
    elsif ($tag eq 'include-uri') {
        my $code = "{# start include-uri\nmy (\$_uri);";
        if ($attribs{href}) {
            $code .= '$_uri = q|' . $attribs{href} . '|;';
        }
        return $code;
    }
    elsif ($tag eq 'get-file-contents') {
        $e->start_expr($tag);
        my $code = 'my ($_file_name);';
        if ($attribs{name}) {
            $code .= '$_file_name = q|' . $attribs{name} . '|;';
        }
        return $code;
    }
    elsif ($tag eq 'time') {
        $e->start_expr($tag);
        my $code = 'my ($_format);';
        if ($attribs{format}) {
            $code .= '$_format =  q|' . $attribs{format} . '|;';
        }        
        return $code;
    }
    elsif ($tag eq 'format') {
        return '$format = ""';
    }
    elsif ($tag eq 'include-expr') {
        return '{ my $_expression = ""'; 
    }
    elsif ($tag eq 'name') {
        return '$_file_name = ""';
    }
    elsif ($tag eq 'href') {        
        return '$_uri = ""';     
    }
    else {
        die "Unknown util tag: $tag";
    }
}

sub parse_end {
    my ($e, $tag) = @_;

    if ($tag eq 'include-file') {
        return ";\nAxKit::XSP::Util::include_file(\n" .
        '$document, $parent, $_file_name' .
        ");}\n";
    }
    elsif ($tag eq 'include-uri') {
        return ";\nAxKit::XSP::Util::include_uri(\n" .
        '$document, $parent, $_uri' .
        ");}\n";
    }
    elsif ($tag eq 'include-expr') {
        return ";\nAxKit::XSP::Util::include_expr(\n" .
        '$document, $parent, $_expression' .
        ");}\n";
    }
    elsif ($tag eq 'get-file-contents') {
        $e->append_to_script('AxKit::XSP::Util::get_file_contents($_file_name);');
        $e->end_expr();
        return '';
    }
    elsif ($tag eq 'time') {
        $e->append_to_script('AxKit::XSP::Util::get_date($_format)');
        $e->end_expr();
        return '';       
    }
    elsif ($tag eq 'format') {
    }
    elsif ($tag eq 'name') {
    }
    elsif ($tag eq 'href') {
    }
    return ";";
}
        
1;
                
__END__

=head1 NAME

AxKit::XSP::Util - XSP util: taglib.

=head1 SYNOPSIS

Add the util: namespace to your XSP C<<xsp:page>> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:util="http://apache.org/xsp/util/v1"
    >

And add this taglib to AxKit (via httpd.conf or .htaccess):

    AxAddXSPTaglib AxKit::XSP::Util

=head1 DESCRIPTION

The XSP util: taglib seeks to add a short list of basic utility
functions to the eXtesible Server Pages library. It trivializes the
inclusion of external fragments and adds a few other useful bells and
whistles.

=head1 TAG STRUCTURE

Most of of the tags require some sort of "argument" to be passed (e.g.
C<<util:include-file>> requires the B<name> of the file that is to be
read). Unless otherwise noted, all tags allow you to pass this
information either as an attribute of the current  element or as the
text node of an appropriately named child.

Thus, both:

    <util:include-file name="foo.xml" />

and

    <util:include-file>
    <util:name>foo.xml</util:name>
    </util:include-file>

are valid.

=head1 TAG REFERENCE

=head2 C<<util:include-file>>

Provides a way to include an XML fragment from a local file into the
current parse tree. Requires a B<name> argument. The path may be relative
or absolute.

=head2 C<<util:include-uri>>

Provides a way to include an XML fragment from a (possibly) remote URI.
Requires an B<href> argument.

=head2 C<<util:get-file-contents>>

Provides a way to include a local file B<as plain text>. Requires a
B<name> argument. The path may be relative or absolute.

=head2 C<<util:include-expr>>

Provides a way to include an XML fragment from a scalar variable. Note
that this tag may B<only> pass the required  B<expr> argument as a
child node. Example: 

    <util:include-expr>
    <xsp:expr>$xml_fragment</xsp:expr>
    </util:include-expr>

=head2 C<<util:time>>

Returns a formatted time/date string. Requires a B<format> attribute.
The format is defined using the standard strftime() syntax.

=head1 AUTHOR

Kip Hampton, khampton@totalcinema.com

=head1 SEE ALSO

AxKit.

=cut
