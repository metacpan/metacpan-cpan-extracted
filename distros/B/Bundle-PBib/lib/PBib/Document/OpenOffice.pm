# --*-Perl-*-- coding: utf-8
# $Id: OpenOffice.pm 13 2004-11-27 08:58:44Z tandler $
#

=head1 NAME

PBib::Document::OpenOffice - Base Class for OpenOffice documents

=head1 SYNOPSIS

	use PBib::Document;
	my $doc = new PBib::Document(
		'filename' => 'test.sxw',
		'mode' => 'r',
		);
	print $doc->filename();
	my @paragraphs = $doc->paragraphs();
	$doc->close();

=head1 DESCRIPTION

Base class for OpenOffice documents.

All OpenOffice documents have a similar structure: They are a zip archive that contains a content.xml file with the content.

=cut

package PBib::Document::OpenOffice;
use 5.008; # for Unicode / utf-8 support
use strict;
use warnings;
use charnames ':full';	# enable \N{unicode char name} in strings
#  use English;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 13 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use base qw(PBib::Document::XML);

# used modules
use Carp::Assert;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

# used own modules


# module variables
#use vars qw(mmmm);

use constant {
	CONTENTNAME => 'content.xml',
	};
	
# Unicode chars, see http://www.unicode.org/charts/
my $EM_DASH = "\N{EM DASH}";				# = \x{2014}
my $EN_DASH = "\N{EN DASH}";				# = \x{2013}
my $FIG_DASH = "\N{FIGURE DASH}";			# 20 12
my $NB_HYPHEN = "\N{NON-BREAKING HYPHEN}";	# 20 11
my $HYPHEN = "\N{HYPHEN}";					# 20 10 (difference to "hypen-minus"?)
my $OPT_HYPHEN = "\N{SOFT HYPHEN}";			# 00 AD

my $LDBLQUOTE_EN = "\N{LEFT DOUBLE QUOTATION MARK}";	# 20 1C
my $RDBLQUOTE_EN = "\N{RIGHT DOUBLE QUOTATION MARK}";	# 20 1D
my $LQUOTE_EN = "\N{LEFT SINGLE QUOTATION MARK}";		# 20 18
my $RQUOTE_EN = "\N{RIGHT SINGLE QUOTATION MARK}";		# 20 19
my $LDBLQUOTE_DE = "\N{DOUBLE LOW-9 QUOTATION MARK}";	# 20 1E
# "\N{DOUBLE HIGH-REVERSED-9 QUOTATION MARK}";	# 20 1F
my $RDBLQUOTE_DE = "\N{LEFT DOUBLE QUOTATION MARK}";	# 20 1C
my $LQUOTE_DE = "\N{SINGLE LOW-9 QUOTATION MARK}";		# 20 1A
my $RQUOTE_DE = "\N{LEFT SINGLE QUOTATION MARK}";		# 20 18
# \N{SINGLE HIGH-REVERSED-9 QUOTATION MARK}		# 20 1B

my $NB_SPACE = "\N{NO-BREAK SPACE}";	# 00 A0 = \N{NBSP}
my $EM_SPACE = "\N{EM SPACE}";	# 20 03
my $EN_SPACE = "\N{EN SPACE}";	# 20 02

my $ELLIPSIS = "\{HORIZONTAL ELLIPSIS}";	# 20 26


=head1 METHODS

=cut

=head1 File Handling Methods

=over

=cut

=item $doc->zip()

Handle to Archive::Zip, used to (de)compress the OpenOffice file.

=cut

sub zip {
	my $self = shift;
	my $zip = $self->{'zip'};
	unless( $zip ) {
		my $filename = $self->filename() or return undef;
		$zip = Archive::Zip->new() or return undef;
		$self->{'zip'} = $zip;
	}
	return $zip;
}

=item $doc->close();

Close the file. Does nothing?

=cut

sub close {
# close file ... must the zip be closed???
  my $self = shift;
  my $zip = $self->{'zip'};
  #  if( defined($zip) ) { $zip->close(); }
  delete $self->{'zip'};
}

=item $doc->read()

=cut

sub read {
	my ($self) = @_;
	my $filename = $self->filename();
	assert($filename) if DEBUG;
	my $zip = $self->zip();
	assert($zip) if DEBUG;
	if( $zip->read($filename) != AZ_OK ) {
		print STDERR "Cannot read $filename\n";
		return undef;
	}
	
	my $text = $zip->contents(CONTENTNAME);
	my $p1 = new XML::Parser(
		Style => 'Tree',
		Handlers => {
			XMLDecl => \&PBib::Document::XML::handle_xmldecl,
			Doctype => \&PBib::Document::XML::handle_doctype,
			},
		);
	#### assert: the XML's encoding must be utf8!
	return $p1->parse($text);
}


=item $doc->write()

Write the document back to disk, if the document has been opened and it contains paragraphs().

=cut

sub write { my ($self) = @_;
	my $inDoc = $self->inDoc();
	# inDoc is set by the inDoc's prepareConvert method
	# get the original archive
	my $zip = $inDoc->zip() or return undef;
	my $sbfh = new PBib::Document::OpenOffice::StringBufferFileHandle();
	$self->PBib::Document::XML::write($sbfh);
	$zip->contents(CONTENTNAME, $sbfh->contents());
	# assert that input and output filename is different (for Archive::Zip to work)
	shouldnt($inDoc->filename(), $self->filename()) if DEBUG;
	if( $zip->writeToFileNamed($self->filename()) != AZ_OK ) {
		print STDERR "Error writing zip archive to ", $self->filename(), "\n";
	}
	$self->close();
}


##############################################

=back

=head1 Converting Methods

Methods used by L<PBib::ReferenceConverter::convert()>.

=over

=cut

=item $doc->prepareConvert($conv)

Pass the inDoc information to the outDoc. Not really nice ...

=cut

sub prepareConvert {
	my ($self, $conv) = @_;
	$conv->{outDoc}->{inDoc} = $self;
	return $self;
}

# can be used by outDoc objects to access the corresponding inDoc
sub inDoc { my $self = shift; return $self->{inDoc}; }

##############################################

=back

=head1 Formatting Methods

Methods used by PBib to create formatted text.

=over

=cut


sub quote { my ($self, $text) = @_;
	# convert $text from internal to external format
	#  $text =~ s/([\{\}])/\\$1/g;
	$text = $self->PBib::Document::XML::quote($text);
	$text =~ s/---/$EM_DASH/g;
	$text =~ s/--/$EN_DASH/g;
	$text =~ s/ - /$EN_DASH/g;
	# quote also ordinal numbers like 1st, 2nd, 3rd, NNNth
	return $text;
}

sub unquote { my ($self, $text) = @_;
	# convert $text from external to internal format
	# Any transformation necessary??
	return $text;
}

sub quoteFieldId { my ($self, $id) = @_;
	#
	# return a valid field ID
	#
	# strip all non-bookmark chars, and add a prefix "r"
	#
	$id =~ s/[^A-Z0-9]//gi;
	return $id;
}

#
#
# text formating methods
#
#

sub formatRange {
	my ($self, $text) = @_;
	# replace with endash
	$text =~ s/\s*-(-?)\s*/$EN_DASH/g if defined $text;
	return $text;
}

sub paragraph { my ($self, $text) = @_;
	# hmmmmmmm I guess this needs to be mor intelligent .....
	return "<text:p>$text</text:p>\n";
}
sub linebreak { my ($self) = @_;
	# return code that stands for a line-break
	return "<text:line-break/>\n";
}

sub singleQuotes { my ($self, $text) = @_;
	# return $text enclosed in single quotes
	return "$LQUOTE_EN$text$RQUOTE_EN";
}
sub doubleQuotes { my ($self, $text) = @_;
	# return $text enclosed in double quotes
	return "$LDBLQUOTE_EN$text$RDBLQUOTE_EN";
}

# fields

sub field {
	my ($self, $text, $code) = @_;
	return "$text" . $self->comment("field: $code");
}

sub bookmark {
	my ($self, $text, $bookmark) = @_;
	return $text unless defined($bookmark);
	return "<text:bookmark-start text:name=\"$bookmark\"/>$text<text:bookmark-end text:name=\"$bookmark\"/>";
}

sub bookmarkLink {
	# return $text marked as a hyperlink to bookmark $id
	my ($self, $text, $id) = @_;
	return "<text:bookmark-ref text:reference-format=\"text\" text:ref-name=\"$id\">$text</text:bookmark-ref>";
	# Alternative: 
	#  return $self->hyperlink($text, "#$id");
}

sub hyperlink {
	# return $text marked as bookmark (with $refID as bookmark)
	my ($self, $text, $url) = @_;
	$url = $text unless( $url );
	return "<text:a xlink:type=\"simple\" xlink:href=\"$url\">$text</text:a>";
}


sub bibitems_start { my ($self) = @_; return ""; }
sub bibitems_separator { my ($self) = @_; return $self->linebreak(); }
sub bibitems_end { my ($self) = @_; return ""; }

sub block_start { my ($self) = @_; return ""; }
sub block_separator { my ($self) = @_; return " "; }
sub block_end { my ($self) = @_; return "\n"; }
                                         
sub tieConnect { my $self = shift;
	# use non-breaking-space
	return join($NB_SPACE, @_);
}


sub comment { my ($self, $text) = @_;
	return $self->bold($self->italic($text));
}

#
#
# interactive editing methods
#
#

sub openInEditor { my ($self, $filename) = @_;
	#  $self->PBib::Document::MSWord::openInEditor($filename);
}

sub jumpToBookmark {
	my ($self, $bookmark) = @_;
	# this feature require some interaction with an appropriate editor
	# application for this kind of document
	# open the document in an editor, and jump to the given bookmark
	#  $self->PBib::Document::MSWord::jumpToBookmark($bookmark);
}

=back

=cut



#  =head1 NAME

#  PBib::Document::OpenOffice::StringBufferFileHandle - Print to a string instead to a file.

#  =head1 SYNOPSIS

	#  use PBib::Document::OpenOffice;
	#  my $sbfh = new PBib::OpenOffice::StringBufferFileHandle();
	#  my $string = $sbfh->contents();

#  =head1 DESCRIPTION

#  This can be passed to Document::write() to get the contents as a 
#  string instead of written into a file.

#  =cut

package PBib::Document::OpenOffice::StringBufferFileHandle;

sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  my $sbfh = bless {contents => ''}, $class;
  return $sbfh;
}

sub print {
	my $self = shift;
	$self->{contents} = $self->{contents} . "@_";
}

sub contents {
	my $self = shift;
	return $self->{contents};
}

1;
