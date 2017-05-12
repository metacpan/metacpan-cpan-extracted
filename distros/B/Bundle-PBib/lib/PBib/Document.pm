# --*-Perl-*--
# $Id: Document.pm 25 2005-09-17 21:45:54Z tandler $
#

=head1 NAME

PBib::Document - Abstract Base and Factory class for Documents

=head1 SYNOPSIS

	use PBib::Document;
	my $doc = new PBib::Document(
		'filename' => $filename,
		'mode' => 'r',
		'verbose' => 1,
		);
	print $doc->filename();
	my @paragraphs = $doc->paragraphs();
	$doc->close();

=head1 DESCRIPTION

Factory class to create documents that are processed by PBib.

=cut

package PBib::Document;
use 5.006;
use strict;
use warnings;
#use English;

# for debug:
#use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 25 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
#use YYYY;
#use vars qw(@ISA);
#@ISA = qw(YYYY);

# used modules
use FileHandle;
use File::Spec;
use Encode;
use Carp;

# module variables
#use vars qw(mmmm);

#
#
# constructor
#
#

=head1 CONSTRUCTOR

=over

=item $doc = new PBib::Document('filename' => $filename);

Arguments are passed as hash:

=over

=item B<filename> => string for filename

=item B<class> => document class to use, e.g. 'RTF' or 'MSWord'

If class is not defined, it is tried to be guessed by looking at the file. (Currently, the filename's extension only.)

=item B<formatOptions> => hash with options passed to ReferenceFormator

OBSOLETE??

=item B<bibitemOptions> => hash with options passed to BibItemFormator

OBSOLETE??

=item B<converter> => string for ReferenceConverter class

OBSOLETE??

=item B<formator> => string for ReferenceFormator class

OBSOLETE??

=item B<mode> => "r" | "w"

Mode for this document, used to open the file.
"r" = Read, "w" = Write

=item B<verbose> => If true, produce more verbose output.

=back

=cut

sub new {
  my $self = shift;
  my %args = @_;
  my $class = ref($self) || $self;
  if( $class eq 'PBib::Document' ) {
    $class = findDocumentClass(%args);
  }
  my $doc = bless \%args, $class;
#print Dumper $doc;
  $doc->initialize();
  return $doc;
}

sub initialize {
  my $self = shift;
}

sub findDocumentClass {
  my %args = @_;
  my $class = $args{'class'};
  my $filename = $args{'filename'};
  unless( defined $class ) {
    if( defined $filename ) {
	  FILETYPE: {
		foreach my $pattern (keys(%{$args{'file-types'} || {}})) {
			if( $filename =~ /$pattern/i ) { 
				$class = $args{'file-types'}->{$pattern}; last FILETYPE;
			}
		}
	    if( $filename =~ /\.doc$/i ) { $class = 'MSWord'; last FILETYPE; }
	    if( $filename =~ /\.rtf$/i ) { $class = 'RTF'; last FILETYPE; }
	    if( $filename =~ /\.s[tx]w$/i ) { $class = 'OpenOfficeSXW'; last FILETYPE; }
	    if( $filename =~ /\.xml$/i ) { $class = 'XML'; last FILETYPE; }
	    if( $filename =~ /\.xhtml$/i ) { $class = 'XHTML'; last FILETYPE; }
	    #  if( $filename =~ /\.html$/i ) { $class = 'XHTML'; last FILETYPE; }
	  }
	}
  }
  if( defined $class ) {
    unless( $class =~ /::/ ) {
      $class = "PBib::Document::$class";
	}
  } else {
    $class = 'PBib::Document';
  }

  if( defined $class ) {
    #print ("use $class; \$${class}::VERSION\n");
    my $version = eval("use $class; \$${class}::VERSION");
    unless( defined $version ) {
      croak "Failed to open module $class\n";
    }
    print STDERR "using $class version $version\n" if $args{'verbose'};
  }
  return $class;
}

#
#
# destructor
#
#

sub DESTROY ($) {
  my $self = shift;
  $self->close();
}



##############################################

=back

=head1 File Handling Methods

=over

=cut

=item $filename = $doc->filename();

Return the document's filename.

=cut

sub filename { my $self = shift; return File::Spec->rel2abs($self->{'filename'}); }

=item $handle = $doc->handle();

Return the document's Perl FileHandle.

Caution: This method might not be used by all subclasses of PBib::Document.

=cut


sub handle {
	# open file and return handle
	# per default the handle is a FileHandle, but subclasses may use
	# other internal handles, like Win32::OLE
	my $self = shift;
	my $fh = $self->{'filehandle'};
	if( not defined($fh) ) {
		my $filename = $self->filename();
		my $mode = $self->{'mode'} || "<";
		if( defined($filename) ) {
			print STDERR "Open $filename ($mode)\n" unless $self->{quiet};
			$fh = $self->{'filehandle'} = new FileHandle($filename, $mode);
			if( not defined($fh) ) {
				print STDERR "Can't open file $filename\n"; # always print error message(?)
			}
		} else {
			if( $mode eq ">" ) {
				print STDERR "Write to stdout\n" unless $self->{quiet};
				$filename = "> -";
			} else {
				print STDERR "Read from stdin\n" unless $self->{quiet};
				$filename = "< -";
			}
			$fh = $self->{'filehandle'} = new FileHandle($filename);
			if( not defined($fh) ) {
				print STDERR "Can't open stdin or stdout ... strange ...\n";
			}
		}
	}
	my $enc = $self->encoding();
	if( defined($enc) ) {
		if( Encode::perlio_ok($enc) ) {
			print STDERR "encoding: $enc\n" if $self->{verbose};
			binmode $fh, ":encoding($enc)"
		} else {
			print STDERR "Unsupported file encoding: $enc\n"; # print when quiet?
		}
	}
	return $fh;
}

=item $doc->encoding();

Return the document's encoding.

Returns undef if not specified.

=cut

sub encoding {
	return undef;
}

=item $doc->close();

Close the file.

=cut

sub close {
# close file
  my $self = shift;
  my $fh = $self->{'filehandle'};
  if( defined($fh) ) { $fh->close(); }
  delete $self->{'filehandle'};
}


=item $doc->read()

Read the document from disk. Return the content of the document 
in a format internal to the document class.
(Per default a ref to an array of the lines.)

=cut

sub read {
	my ($self) = @_;
	my $fh = $self->handle() or return undef;
	my @lines;
	# don't chomp line ends!
	@lines = <$fh>;
	# $fh->close(); # close it now or later?
	return \@lines;
}


=item $doc->write()

Write the document back to disk, if the document has been opened and it contains paragraphs().

=cut

sub write { my ($self) = @_;
  my $fh = $self->handle() or return undef;
  my @lines = @{$self->paragraphs()};
  return unless @lines;
  foreach my $p (@lines) {
    $fh->print($p);
  }
  $self->close();
}

=item $boolean = $doc->exists()

Check, if this document is exists, independent of being accessable.
(Perl's -f test)

=cut

sub exists {
  my $self = shift;
  my $filename = $self->filename() || *STDIN;
  return -f $filename;
}

=item $boolean = $doc->isValid()

Check, if this document is ok, e.g. if the file exists and can be accessed.
(Perl's -w or -r, depending on $doc->mode()

=cut

sub isValid {
  my $self = shift;
  my $filename = $self->filename() || *STDIN;
  return $self->{'mode'} eq "w" ? -w $filename : -r $filename;
}


##############################################

=back

=head1 Text Access Methods

Methods used by PBib to access the document.

=over

=cut

=item $inDoc->processParagraphs($func, $rc, $outDoc, @_)

Process all paragraphs of the $inDoc by calling $func. If $outDoc is defined, the result of the function call is added to $outDoc.

The default implementation assumes a linear sequence of paragraphs, using $inDoc's paragraphCount() and getParagraph().

$func is called on $rc with the current paragraph, its index and @_ as parameters:

	$par = $rc->$func($par, $i, @_);

=cut

sub processParagraphs {
	my $self = shift;
	my $func = shift;
	my $rc = shift;
	my $outDoc = shift;
	my $par;
	my $numPars = $self->paragraphCount();
	for( my $i = 0; $i < $numPars; $i++ ) {
		$self->{currentParagraph} = $i;
		$par = $self->getParagraph($i);
		$par = $rc->$func($par, $i, @_);
		$outDoc->addParagraph($par) if $outDoc;
	}
}


=item $int = $doc->paragraphCount();

Return the number of paragraphs in document.

=cut

sub paragraphCount {
# how many paragraphs does this doc have?
  my $self = shift;
  my $pars = $self->paragraphs();
  return undef if ! defined $pars;
  return scalar @{$pars};
}

=item $string = $doc->getParagraph($int);

Return the paragraph with index $int

=cut

sub getParagraph {
  my ($self, $idx) = @_;
  return $self->paragraphs()->[$idx];
}

=item @strings = $doc->paragraphs()

Return all paragraphs in document as an array with all paragraphs as plain (ascii) strings.

Calles $doc->read() if the file has not been read before.

=cut

sub paragraphs {
	my $self = shift;
	return $self->{'paragraphs'} if defined($self->{'paragraphs'});
	return $self->{'paragraphs'} = $self->read();
}


=item $doc->addParagraph($str1, $str2, ...), $doc->addParagraphs($str1, $str2, ...)

Append paragraphs to document.

=cut

sub addParagraph { my $self = shift; return $self->addParagraphs(@_); }
sub addParagraphs { my $self = shift;
  foreach my $p (@_) {
    push @{$self->{'paragraphs'}}, $p;
  }
}


##############################################

=back

=head1 Converting Methods

Methods used by L<PBib::ReferenceConverter::convert()>.

=over

=cut


=item $doc->prepareConvert($conv)

Do anything you want to before being converted. (Hook for subclasses.)
The document object that is returned is used for conversion.

This is called by L<PBib::ReferenceConverter::convert()> on the I<input> document with $conv as the current converter.

=cut

sub prepareConvert {
	my ($self) = @_;
	return $self;
}

=item $doc->finalizeConvert($conv)

Do anything you want to after being converted. (Hook for subclasses.)
The object that is returned is used for further processing.

This is called by L<PBib::ReferenceConverter::convert()> on the I<output> document with $conv as the current converter.

=cut

sub finalizeConvert {
	my ($self) = @_;
	return $self;
}


##############################################

=back

=head1 Formatting Methods

Methods used by PBib to create formatted text.

=over

=cut


#
#
# char set converting methods
#
#

sub quote { my ($self, $text) = @_; return $text; }
sub unquote { my ($self, $text) = @_; return $text; }

sub quoteFieldId { my ($self, $text) = @_;
	#
	# return a valid field ID
	#
	return $text;
}

#
#
# text formating methods
#
#

sub formatRange {
	my ($self, $text) = @_;
	$text =~ s/\s*-(-?)\s*/-/g if defined $text;
	return $text;
}

sub paragraph {
	my ($self, $text) = @_;
	$text = '' unless $text;
	return "$text\n";
}
sub linebreak {
	my ($self, $text) = @_;
	$text = '' unless $text;
	return "$text\n";
}
sub singleQuotes { my ($self, $text) = @_;
# return $text enclosed in single quotes
  return "'$text'";
}
sub doubleQuotes { my ($self, $text) = @_;
# return $text enclosed in double quotes
  return "\"$text\"";
}

# text styles

sub italic { my ($self, $text) = @_;
# return $text as italic
  return $text;
}
sub bold { my ($self, $text) = @_;
# return $text as bold
  return $text;
}
sub underline { my ($self, $text) = @_;
# return $text as underlined
  return $text;
}

sub highlight { my ($self, $text) = @_;
# return $text highlighted, whatever this means.
# It could be bold + italic, or colored etc.
  return $self->bold($self->italic($text));
}

# fonts

sub tt { my ($self, $text) = @_;
# return text in typewriter (Courier) font
  return $text;
}

# fields

sub bookmark {
# return $text marked as bookmark (with $id as bookmark)
  my ($self, $text, $id) = @_;
  return $text;
}

sub bookmarkLink {
# return $text marked as a hyperlink to bookmark $id
  my ($self, $text, $id) = @_;
  return $text;
}

sub hyperlink {
# return $text marked as a hyperlink to $url
  my ($self, $text, $url) = @_;
  $url = $text unless( $url );
  return $text eq $url ? $text : "$text ($url)";
}

sub comment { my ($self, $text) = @_;
	return $self->bold($self->italic($text));
}

#
#
# bibliography formating methods
#
#


sub bibitems_start { my ($self) = @_; return ""; }
sub bibitems_separator { my ($self) = @_; return $self->paragraph(); }
sub bibitems_end { my ($self) = @_; return ""; }

sub block_start { my ($self) = @_; return ""; }
sub block_separator { my ($self) = @_; return ' '; }
sub block_end { my ($self) = @_; return ""; }

sub sentence_start { my ($self) = @_; return ""; }
sub sentence_separator { my ($self) = @_; return ". "; }
sub sentence_end { my ($self) = @_; return "."; }

sub phrase_start { my ($self) = @_; return ""; }
sub phrase_separator { my ($self) = @_; return ", "; }
sub phrase_end { my ($self) = @_; return ""; }

sub spaceConnect { my $self = shift;
# connect all args with spaces
  return join($self->quote(" "), @_);
}
sub tieConnect { my ($self, $a, $b) = @_;
  # use non-breaking-space
  return $self->spaceConnect($a, $b);
}
sub tieOrSpaceConnect { my ($self, $a, $b) = @_;
  # use non-breaking-space, if $a or $b is short (i.e. < 3 characters)
  return '' if ! defined $a && ! defined $b;
  return $a if ! defined $b;
  return $b if ! defined $a;
  return length($a) < 5 || length($b) < 3 ?
	$self->tieConnect($a, $b) :
	$self->spaceConnect($a, $b);
}


##############################################

=back

=head1 Interactive Editing Methods

Methods used by PBib for interactive editing of documents, e.g. open in editor.

=over

=cut


sub openInEditor { my ($self) = @_;
  my $filename = $self->filename();
  if( not defined($filename) ) {
    print STDERR "can't open document with no filename specified.\n";
	return;
  }
  PBib::Document::openFile($filename);
}

sub jumpToBookmark {
  my ($self, $bookmark) = @_;
# this feature require some interaction with an appropriate editor
# application for this kind of document
# open the document in an editor, and jump to the given bookmark
  $self->openInEditor();
####  Selection.GoTo What:=wdGoToBookmark, Name:="BookMark" ###, Which:=???
}

sub searchInEditor { my ($self, $text) = @_;
  $self->openInEditor();
}


##############################################

=back

=head1 Class Methods

=over

=cut

=item PBib::Document::openFile($filename);

Open the file with it's associated default application.

=cut

sub openFile {
  my $filename = shift;
# fork currently crashes ...
  system($filename);
  return;
  my $pid = fork();
  if( not defined($pid) ) {
    print STDERR "fork failed opening $filename\n";
	return;
  }
  if( $pid == 0 ) {
   exec($filename) or print STDERR "exec $filename failed.\n";
  }
  return $pid;
}


=back

=cut

1;

#
# $Log: Document.pm,v $
# Revision 1.15  2003/06/12 22:06:01  tandler
# support prepareConvert() / finalizeConvert()
#
# Revision 1.14  2003/05/22 11:54:23  tandler
# remove spaces around the dash (-) in page ranges (e.g. 3 - 7 ==> 3-7)
#
# Revision 1.13  2002/11/05 18:29:13  peter
# space/tie connect
#
# Revision 1.12  2002/11/03 22:14:51  peter
# minor
#
# Revision 1.11  2002/10/11 10:13:13  peter
# minor fixes and cleanup
#
# Revision 1.10  2002/10/01 21:27:22  ptandler
# fix: paragraph count with non-existing document
#
# Revision 1.9  2002/07/16 17:35:41  Diss
# check if file exists
#
# Revision 1.8  2002/06/24 10:42:14  Diss
# use PBib::Document as default class for all unknown file types
#
# Revision 1.7  2002/06/06 10:23:59  Diss
# searchInEditor support - jump to CiteKeys in editor
# (litUI uses PBib::Doc classes)
#
# Revision 1.6  2002/06/06 09:02:00  Diss
# constructor can now be used as uniform interface for several
# document types (RTF, MSWord)
#
# Revision 1.5  2002/05/27 10:22:41  Diss
# started editing support
#
# Revision 1.4  2002/04/03 10:18:24  Diss
# - new method 'highlight'
#
# Revision 1.3  2002/03/27 10:00:50  Diss
# new module structure, not yet included in LitRefs/LitUI (R2)
#
# Revision 1.2  2002/03/22 17:31:02  Diss
# small changes
#
# Revision 1.1  2002/03/18 11:15:50  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#