# --*-Perl-*--
# $Id: XHTML.pm 25 2005-09-17 21:45:54Z tandler $
#

=head1 NAME

PBib::Document::XHTML - XHTML documents

=head1 SYNOPSIS

	use PBib::Document;
	my $doc = new PBib::Document(
		'filename' => 'sample.xhtml',
		'mode' => 'r',
		);
	print $doc->filename();
	$doc->close();

=head1 DESCRIPTION

Provide an interface to XHTML for PBib.

=cut

package PBib::Document::XHTML;
use strict;
use warnings;
#  use English;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 25 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use base qw(PBib::Document::XML);

# used own modules


# module variables
#use vars qw(mmmm);


##############################################

=head1 Formatting Methods

Methods used by PBib to create formatted text.

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
	return "<p>$text\n</p>";
}
sub linebreak {
	my ($self, $text) = @_;
	$text = '' unless $text;
	return "$text\n<br>";
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
	return "<i>$text</i>";
}
sub bold { my ($self, $text) = @_;
# return $text as bold
	return "<b>$text</b>";
}
sub underline { my ($self, $text) = @_;
# return $text as underlined
	return "<u>$text</u>";
}

sub highlight { my ($self, $text) = @_;
# return $text highlighted, whatever this means.
# It could be bold + italic, or colored etc.
	return $self->bold($self->italic($text));
}

# fonts

sub tt { my ($self, $text) = @_;
# return text in typewriter (Courier) font
	return "<tt>$text</tt>";
}

# fields

sub bookmark {
# return $text marked as bookmark (with $id as bookmark)
	my ($self, $text, $id) = @_;
	return "<a name=\"$id\">$text</a>";
}

sub bookmarkLink {
# return $text marked as a hyperlink to bookmark $id
	my ($self, $text, $id) = @_;
	return $self->hyperlink($text, "#$id");
}

sub hyperlink {
# return $text marked as a hyperlink to $url
	my ($self, $text, $url) = @_;
	$url = $text unless( $url );
	return "<a href=\"$url\">$text</a>"
}

sub comment { my ($self, $text) = @_;
	return $self->bold($self->italic($text));
}

#
#
# bibliography formating methods
#
#


sub bibitems_start { my ($self) = @_; return "<ol>\n<li>"; }
sub bibitems_separator { my ($self) = @_; return "</li>\n<li>"; }
sub bibitems_end { my ($self) = @_; return "</li>\n</ol>"; }

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
sub tieConnect { my $self = shift;
  # use non-breaking-space
  return join("&nbsp;", @_);
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


1;

