# --*-Perl-*--
# $Id: RTF.pm 11 2004-11-22 23:56:20Z tandler $
#

package PBib::Document::RTF;
use strict;
#  use English;

# for debug:
#use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 11 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use base qw(PBib::Document);

# used own modules
use PBib::Document::MSWord;


# module variables
#use vars qw(mmmm);



#
#
# text access methods
#
#

sub paragraphs {
# return an array with all paragraphs as plain (ascii) strings
# per default read an ascii file
  my $self = shift;
  return $self->{'paragraphs'} if defined($self->{'paragraphs'});
  my $fh = $self->handle() or return undef;
  my @lines = <$fh>; # don't chomp line ends!
  my @pars = shift @lines;
  # only return true RTF paragraphs!
  foreach my $p (@lines) {
    if( $p =~ /^\\par/ ) {
	  push @pars, $p;
	} else {
	  $pars[-1] .= $p;
    }
  }
  # $fh->close(); # close it now or later?
  return $self->{'paragraphs'} = \@pars;
}


#
#
# converting to internal format
#
#

sub quote { my ($self, $text) = @_;
# convert $text from internal to external format
#  $text =~ s/([\{\}])/\\$1/g;
  $text =~ s/---/\\emdash /g;
  $text =~ s/--/\\endash /g;
  $text =~ s/ - /\\endash /g;
# quote also ordinal numbers like 1st, 2nd, 3rd, NNNth
  return $text;
}

sub unquote { my ($self, $text) = @_;
# convert $text from external to internal format
  $text =~ s/\{\\\*\\bkmk[^\{\}]*\}//g; # strip bookmarks
  $text =~ s/(?<!\\)[\{\}]//g; # strip braces in the text
  $text =~ s/\\([\{\}\\])/$1/g;
  # strange Word XP RTF:
  $text =~ s/\\insrsid\d* ?//g;
  $text =~ s/\\charrsid\d* ?//g;
  $text =~ s/\\lang[a-z]*\d* ?//g;
  $text =~ s/\\noproof ?//g;
  
  # convert HEX characters
  $text =~ s/\\'(..)/ chr(hex($1)) /eg;
  
  $text =~ s/\\emdash ?/---/g;
  $text =~ s/\\endash ?/--/g;
  $text =~ s/\r?\n//g;
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
  $text =~ s/\s*-(-?)\s*/\\endash /g if defined $text;
  return $text;
}

sub paragraph { my ($self, $text) = @_;
#  return "\{\\pard $text\\par\}\n";
# \\pard without pard the par inherits formating from previous paragraph.
# That's what we are likely to want in bibliographies ...
  return "\{$text\\par\}\n";
}
sub linebreak { my ($self) = @_;
# return code that stands for a line-break
  return "\\line\n";
}

sub singleQuotes { my ($self, $text) = @_;
# return $text enclosed in single quotes
  return "\\lquote $text\\rquote ";
}
sub doubleQuotes { my ($self, $text) = @_;
# return $text enclosed in double quotes
  return "\\ldblquote $text\\rdblquote ";
}

# text styles

sub italic {
  my ($self, $text) = @_;
  return "{\\i $text}";
}
sub bold {
# return $text as bold
  my ($self, $text) = @_;
  return "{\\b $text}";
}
sub underlined {
# return $text as underlined
  my ($self, $text) = @_;
  return "{\\u $text}";
}

# fonts

sub tt { my ($self, $text) = @_;
# return text in tyoewriter font
### well, maybe not that easy ...
  return $text;
}

# fields

sub field {
  my ($self, $text, $code) = @_;
  return "{\\field{\\*\\fldinst {$code}}{\\fldrslt {$text}}}";
}

sub bookmark {
  my ($self, $text, $bookmark) = @_;
  return "\{$text\}" unless defined($bookmark);
  return "\{\{\\*\\bkmkstart $bookmark\}$text\{\\*\\bkmkend $bookmark\}\}";
}

sub bookmarkLink {
# return $text marked as a hyperlink to bookmark $id
  my ($self, $text, $id) = @_;
  return $self->field($text, " HYPERLINK \\\\l $id");
}

sub hyperlink {
# return $text marked as bookmark (with $refID as bookmark)
  my ($self, $text, $url) = @_;
  $url = $text unless( $url );
  return $self->field($text, " HYPERLINK $url");
}


sub bibitems_start { my ($self) = @_; return "{"; }
sub bibitems_separator { my ($self) = @_; return "\\par\n"; }
sub bibitems_end { my ($self) = @_; return "}\n"; }

sub block_start { my ($self) = @_; return "{"; }
sub block_separator { my ($self) = @_; return " "; }
sub block_end { my ($self) = @_; return "}\n"; }
                                         
sub tieConnect { my $self = shift;
  # use non-breaking-space
  return join("\\~", @_);
}


sub comment { my ($self, $text) = @_;
  return "{\\v $text}\n";
}

#
#
# interactive editing methods
#
#

sub openInEditor { my ($self, $filename) = @_;
  $self->PBib::Document::MSWord::openInEditor($filename);
}

sub jumpToBookmark {
  my ($self, $bookmark) = @_;
# this feature require some interaction with an appropriate editor
# application for this kind of document
# open the document in an editor, and jump to the given bookmark
  $self->PBib::Document::MSWord::jumpToBookmark($bookmark);
}

sub saveAsDoc {
	my ($self, $name) = @_;
	if( ! defined $name ) {
		$name = $self->filename();
		$name =~ s/\.rtf$/.doc/i;
	}
	print STDERR "save ", $self->filename(), " (doc) as $name (rtf)\n";
	my $result = $self->doc()->SaveAs({
		'FileName' => $name,
		'FileFormat' => wdFormatDocument(),
		'AddToRecentFiles' => 0,
		'EmbedTrueTypeFonts' => 0,
		});
	print STDERR " --> <", $result ? $result : "<undef>", ">\n";
	return $name;
}

1;

#
# $Log: RTF.pm,v $
# Revision 1.8  2003/09/15 21:09:30  tandler
# improved matching of RTF \lang* tags
#
# Revision 1.7  2003/06/12 22:09:10  tandler
# some Office 10's RTF fixes.
# new sub saveAsDoc(), not yet tested
#
# Revision 1.6  2003/05/22 11:54:58  tandler
# remove spaces around the dash (-) in page ranges (e.g. 3 - 7 ==> 3-7)
# remove WordXP's \charrsid entries ...
#
# Revision 1.5  2003/01/21 10:26:36  ptandler
# support for Word XP generated RTF (untested :-)
#
# Revision 1.4  2002/09/23 11:06:37  peter
# fix: formatRange if text is undef
#
# Revision 1.3  2002/05/27 10:25:22  Diss
# started editing support
#
# Revision 1.2  2002/03/27 10:00:51  Diss
# new module structure, not yet included in LitRefs/LitUI (R2)
#
# Revision 1.1  2002/03/18 11:15:50  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#