# --*-Perl-*--
# $Id: XML.pm 13 2004-11-27 08:58:44Z tandler $
#

=head1 NAME

PBib::Document::XML - XML documents

=head1 SYNOPSIS

	use PBib::Document;
	my $doc = new PBib::Document(
		'filename' => 'sample.xml',
		'mode' => 'r',
		);
	print $doc->filename();
	$doc->close();

=head1 DESCRIPTION

Provide an interface to XML for PBib.

Main difference to other documents is that XML documents have a hierarchical structure, not a linear one.

Therefore, processParagraphs() is overwritten.

Used as base class for OpenOffice documents.

=cut

package PBib::Document::XML;
use strict;
use warnings;
#  use English;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 13 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use base qw(PBib::Document Exporter);
our @EXPORT=qw(mkXML);

use XML::Parser;
use Carp::Assert;

# used own modules


# module variables
#use vars qw(mmmm);
#### TODO: put this into the doc object!!!
our ($xml_version, $xml_enc, $xml_standalone);
our ($doc_name, $doc_sysid, $doc_pubid, $doc_internal);



##############################################

=head1 File Handling Methods

=over

=cut


=item $doc->encoding();

Return the document's encoding.

Returns undef if not specified.

=cut

sub encoding {
	return $xml_enc;
}


=item $doc->read()

Read the document from disk. Return the content of the document 
in a format internal to the document class.
(Per default a ref to an array of the lines.)

=cut

sub read {
	my ($self) = @_;
	my $fh = $self->handle() or return undef;
	my $p1 = new XML::Parser(
		Style => 'Tree',
		Handlers => {
			XMLDecl => \&handle_xmldecl,
			Doctype => \&handle_doctype,
			},
		);
	return $p1->parsefile($self->filename());
}

sub handle_xmldecl {
	my ($expat, $version, $enc, $standalone) = @_;
	#  print Dumper {version => $version, enc => $enc, standalone => $standalone};
	$xml_version = $version;
	$xml_enc = $enc;
	$xml_standalone = $standalone;
}

sub handle_doctype {
	my ($expat, $name, $sysid, $pubid, $internal) = @_;
	#  print Dumper {name => $name, sysid => $sysid, 
		#  pubid => $pubid, internal => $internal};
	$doc_name = $name;
	$doc_sysid = $sysid;
	$doc_pubid = $pubid;
	$doc_internal = $internal;
}


=item $doc->write($fh)

Write the document back to disk, if the document has been opened and it contains paragraphs().

$fh is the FileHandle it should print to. If undef, $self->handle() is used.

=cut

sub write {
	my ($self, $fh) = @_;
	$fh = $self->handle() unless defined $fh;
	shouldnt($fh, undef) if DEBUG;
	my $doc = $self->docRoot();
	shouldnt($doc, undef) if DEBUG;
	
	$fh->print("<?xml version=\"$xml_version\" encoding=\"$xml_enc\"?>\n");
	$fh->print("<!DOCTYPE $doc_name PUBLIC \"$doc_pubid\" \"$doc_sysid\">\n");

	$self->printXML($doc, $fh);
	$self->close();
}

sub printXML {
	my ($self, $xml, $fh) = @_;
	
	#  print Dumper $xml;
	while( @$xml ) {
		my $tag = shift @$xml;
		my $elem = shift @$xml;
		if( $tag ) {
			#  print "<$tag>";
			my $attr = shift @$elem;
			$attr = formatXMLAttributes($attr);
			if( @$elem ) {
				$fh->print("<$tag$attr>");
				$self->printXML($elem, $fh);
				$fh->print("</$tag>");
			} else {
				$fh->print("<$tag$attr/>");
			}
		} else {
			# text
			#  print $elem;
			$fh->print($elem);
		}
	}
}


sub formatXMLAttributes {
	my ($attr) = @_;
	if( %$attr ) {
		#### TODO: quote the attribute value!
		return ' ' . join(" ", map( "$_=\"" . $attr->{$_} . "\"" , keys(%$attr)));
	}
	return '';
}

##############################################

=back

=head1 Text Access Methods

Methods used by PBib to access the document.

=over

=cut


=item $inDoc->processParagraphs($func, $rc, $outDoc, @_)

For an XML document, a "paragraph" is each CDATA element.

Here, we return the number of paragraphs.

=cut

sub processParagraphs {
	my $self = shift;
	my $func = shift;
	my $rc = shift;
	my $outDoc = shift;
	$self->{currentParagraph} = 0;
	$self->{tagPath} = [];
	my $result = $self->processXML($self->docRoot(), $func, $rc, $outDoc, @_);
	#  print "processParagraphs($func) --> ", Dumper($result);
	$outDoc->{docRoot} = $result if defined($outDoc);
	#  print Dumper $self->docRoot();
	return 	$self->{currentParagraph};
}

sub processXML {
	my $self = shift;
	my @xml = @{shift()};
	my $func = shift;
	my $rc = shift;
	my $outDoc = shift;
	my @result;
	
	return undef unless @xml;
	
	while( @xml ) {
		my $tag = shift @xml;
		if( $tag ) {
			#  print "<$tag>";
			my @elem = @{shift @xml};
			my $attr = shift @elem;
			push @{$self->{tagPath}}, [$tag, $attr]; # remember all parent tags
			my $result = $self->processXML(\@elem, $func, $rc, $outDoc, @_);
			pop @{$self->{tagPath}};
			if( $outDoc ) {
				unshift @$result, $attr;
				push @result, $tag, $result;
			}
		} else {
			# text, i.e. a paragraph that needs to be processed
			my $par = shift @xml;
			#  print $par;
			my $i = ++($self->{currentParagraph});
			$par = $rc->$func($par, $i, @_) if defined $func;
			if( $outDoc ) {
				push @result, 0, $par;
			}
		}
		#  print Dumper($outDoc, \@result);
	}
	return \@result if $outDoc;
}

=item $arrref = $doc->tagPath();

While processing the document (C<processParagraphs()>), this returns
an array with all parent [tag, attrib]

=cut

sub tagPath {
	my ($self) = @_;
	return $self->{tagPath};
}


=item $int = $doc->paragraphCount();

Return the number of paragraphs in document.

=cut

sub paragraphCount {
# how many paragraphs does this doc have?
	my $self = shift;
	return $self->processParagraphs();
}


=item $doc->docRoot()

Return the doc root as L<XML::Parser>'s hash encoding.

(Equivalent of L<PBib::Document::paragraphs()>.)

=cut

sub docRoot {
	my ($self) = @_;
	return $self->{docRoot} if defined $self->{docRoot};
	return $self->{docRoot} = $self->read();
}

=item $doc->getElement(@path);

Return element at @path, e.g. getElement('body', 'p', 'ol', 'i').

If there are multiple elements with the same tag, the first is used.

=cut

sub getElement {
	my $self = shift;
	return getElementIn($self->docRoot(), @_);
}

sub getElementIn {
	my $doc = shift;
	my $arg = shift;
	
	return undef unless defined($doc); # not found (no doc)
	return $doc unless defined($arg); # found (no path)
	
	my @xml = @$doc;
	while( @xml ) {
		my $tag = shift @xml;
		my $elem = shift @xml;
		#  print "$tag eq $arg?\n";
		if( $tag eq $arg ) { # tag found
			#  print "--> yes!\n";
			return $elem unless @_; # done
			@xml = @$elem; # copy array before attr is removed
			shift @xml; # remove attr
			return getElementIn(\@xml, @_);
		}
	}
	return undef; # not found
}

sub mkXML {
	my ($tag, $attr, @elems) = @_;
	return ($tag, [$attr || {}, @elems]);
}

##############################################

=back

=head1 Formatting Methods

Methods used by PBib to create formatted text.

=over

=cut


sub quote { my ($self, $text) = @_;
	# convert $text from internal to external format
	$text =~ s/&/&amp;/g;
	#  $text =~ s/</&lt;/g;
	#  $text =~ s/>/&gt;/g;
	return $text;
}

sub unquote { my ($self, $text) = @_;
	# convert $text from external to internal format
	$text =~ s/&([a-z]+);/<<<$1>>>/gi;
	return $text;
}

=back

=cut

1;

