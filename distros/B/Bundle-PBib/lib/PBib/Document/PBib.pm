# --*-Perl-*--
# $Id: PBib.pm 10 2004-11-02 22:14:09Z tandler $
#

package PBib::Document::PBib;
use strict;
use warnings;
#use English;

# for debug:
#use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 10 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use PBib::Document;
use vars qw(@ISA);
@ISA = qw(PBib::Document);

# module variables
#use vars qw(mmmm);

#
#
#
#
#

sub xtags {
	my $self = shift;
	unless( defined $self->{'xtags'} ) {
		$self->{'xtags'} = {};
	}
	return $self->{'xtags'};
}
sub xchars {
	my $self = shift;
	unless( defined $self->{'xchars'} ) {
		$self->{'xchars'} = {};
	}
	return $self->{'xchars'};
}

#
#
# text formating methods
#
#

#
# xchars
#
# [#p#]	- new paragraph
# [#br#]	- line break
# [#optbr#]	- optional line break (similar to a optional hyphen, but shows no hyphen)
# [#pbr#]	- page break
# [#cbr#]	- column break
# [#tab#]
# [#em-#]	- em dash
# [#en-#]	- en dash
# [#nbr-#]	- non-breaking hyphen
# [#opt-#]	- optional hyphen
# [#nbr #]	- non-breaking space (tie)
# [#em #]	- em space
# [#en #]	- en space
#

our %xchars = (
	'p' => "\n",
	'br' => "\n",
	'optbr' => '',
	'pbr' => "\n",
	'cbr' => "\n",
	'tab' => "\t",
	'em-' => '-',
	'en-' => '-',
	'nbr-' => '-',
	'opt-' => '',
	'nbr ' => ' ',
	'em ' => ' ',
	'en ' => ' ',
	);
sub xchar {
	my ($self, $xchar) = @_;
	return $xchars{$xchar} || '';
}
sub replace_xchars {
	my ($self, $text) = @_;
	foreach my $xchar ($self->xchars()) {
		print "[#$xchar#] --> ", $self->xchar($xchar), "\n";
		$text =~ s/\[\#$xchar\#\]/ $self->xchar($xchar) /ge;
	}
	return $text;
}

sub formatRange {
	my ($self, $text) = @_;
	$text =~ s/-(-?)/[#en-#]/g;
	$self->xchars()->{"en-"} ++;
	return $text;
}

sub paragraph { my ($self, $text) = @_;
#  return "\{\\pard $text\\par\}\n";
# \\pard without pard the par inherits formating from previous paragraph.
# That's what we are likely to want in bibliographies ...
	$self->xchars()->{"p"} ++;
	return $text . "[#p#]";
}

sub linebreak { my ($self) = @_;
# return code that stands for a line-break
	$self->xchars()->{"br"} ++;
	return "[#br#]"; #####
}

sub tieConnect { my $self = shift;
	# use non-breaking-space
	$self->xchars()->{"nbr "} ++;
	return join("[#nbr #]", @_);
}

#
# xtags
#

sub singleQuotes { my ($self, $text) = @_;
# return $text enclosed in single quotes
	$self->xtags()->{"quote"} ++;
	return "[+quote+]$text\[-quote-]";
#  return "[#quote:$text#]";
#  return $text;
}
sub doubleQuotes { my ($self, $text) = @_;
# return $text enclosed in double quotes
	$self->xtags()->{"dblquote"} ++;
	return "[+dblquote+]$text\[-dblquote-]";
#  return $text;
}

# text styles

sub italic {
	my ($self, $text) = @_;
	$self->xtags()->{"i"} ++;
	return $text ? "[+i+]$text\[-i-]" : '';
}
sub bold {
# return $text as bold
	my ($self, $text) = @_;
	$self->xtags()->{"b"} ++;
	return $text ? "[+b+]$text\[-b-]" : '';
}
sub underlined {
# return $text as underlined
	my ($self, $text) = @_;
	$self->xtags()->{"u"} ++;
	return $text ? "[+u+]$text\[-u-]" : '';
}

# fonts

sub tt { my ($self, $text) = @_;
# return text in tyoewriter font
### well, maybe not that easy ...
	$self->xtags()->{"tt"} ++;
	return "[+tt+]$text\[-tt-]";
}

# fields

sub field {
	my ($self, $text, $code) = @_;
#print  "[#field:$code#$text#]";
	$self->xtags()->{"field:"} ++;
	$self->xtags()->{"field:$code"} ++;
	return "[+field:$code+]$text\[-field:$code-]";
}

sub bookmark {
	my ($self, $text, $bookmark) = @_;
	return $text unless defined($bookmark);
	$self->xtags()->{"bkmk:"} ++;
	$self->xtags()->{"bkmk:$bookmark"} ++;
	return "[+bkmk:$bookmark+]$text\[-bkmk:$bookmark-]";
}

sub bookmarkLink {
# return $text marked as a hyperlink to bookmark $id
	my ($self, $text, $id) = @_;
	$self->xtags()->{"bkmkref:"} ++;
	$self->xtags()->{"bkmkref:$id"} ++;
	return "[+bkmkref:$id+]$text\[-bkmkref:$id-]";
}

sub hyperlink {
# return $text marked as bookmark (with $refID as bookmark)
	my ($self, $text, $url) = @_;
	$url = $text unless( $url );
#print STDERR "href: url=<$url>, text=<$text>\n";
	$self->xtags()->{"href:"} ++;
	$self->xtags()->{"href:$url"} ++;
	return "[+href:$url+]$text" . "[-href:$url-]";
}


1;

#
# $Log: PBib.pm,v $
# Revision 1.1  2002/10/11 10:15:24  peter
# refactored: uses new superclass Document::PBib
#
