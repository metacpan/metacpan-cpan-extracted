# --*-Perl-*--
# $Id: OpenOfficeSXW.pm 13 2004-11-27 08:58:44Z tandler $
#

=head1 NAME

PBib::Document::OpenOfficeSXW - OpenOffice Text documents

=head1 SYNOPSIS

	use PBib::Document;
	my $doc = new PBib::Document(
		'filename' => 'sample.sxw',
		'mode' => 'r',
		);
	print $doc->filename();
	my @paragraphs = $doc->paragraphs();
	$doc->close();

=head1 DESCRIPTION

OpenOffice Text documents.

We'll see if there's a difference to the base clase :-)

=cut

package PBib::Document::OpenOfficeSXW;
use strict;
#  use English;
use Carp::Assert;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 13 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use base qw(PBib::Document::OpenOffice);

# used own modules
use PBib::Document::XML;

# module variables
#use vars qw(mmmm);


##############################################

=head1 Converting Methods

Methods used by L<PBib::ReferenceConverter::convert()>.

=over

=cut

=item $doc->finalizeConvert($conv)

Insert PBib styles into document.

=cut

sub finalizeConvert {
	my ($self) = @_;
	my $styles = $self->getElement('office:document-content', 'office:automatic-styles');
	push @$styles, mkXML('style:style', {
			'style:name' => "PBibTextItalic",
			'style:family' => "text",
			}, (
			mkXML('style:properties', {
				'fo:font-style' => "italic",
				'style:font-style-asian' => "italic",
				}),
			)
		);
	push @$styles, mkXML('style:style', {
			'style:name' => "PBibTextBold",
			'style:family' => "text",
			}, (
			mkXML('style:properties', {
				'fo:font-style' => "bold",
				'style:font-style-asian' => "bold",
				}),
			)
		);
	push @$styles, mkXML('style:style', {
			'style:name' => "PBibTextUL",
			'style:family' => "text",
			}, (
			mkXML('style:properties', {
				'style:text-underline' => "single",
				'style:text-underline-color' => "font-color",
				}),
			)
		);
	#  print Dumper($styles);
	return $self;
}


##############################################

=back

=head1 Formatting Methods

Methods used by PBib to create formatted text.

=over

=cut


# text styles

sub italic {
	my ($self, $text) = @_;
	return "<text:span text:style-name=\"PBibTextItalic\">$text</text:span>";
}
sub bold {
	# return $text as bold
	my ($self, $text) = @_;
	return "<text:span text:style-name=\"PBibTextBold\">$text</text:span>";
}
sub underlined {
	# return $text as underlined
	my ($self, $text) = @_;
	return "<text:span text:style-name=\"PBibTextUL\">$text</text:span>";
}

# fonts

sub tt { my ($self, $text) = @_;
	# return text in tyoewriter font
	### well, maybe not that easy ...
	return $text;
}


sub bibitems_start { my ($self) = @_; return ""; }
sub bibitems_separator {
	my ($self) = @_;
	my @path = @{$self->inDoc()->tagPath()};
	my $sep = "\n";
	my ($tag, $attr);
	$tag = shift(@path);
	should($tag->[0], "office:document-content") if DEBUG;
	$tag = shift(@path);
	should($tag->[0], "office:body") if DEBUG;
	assert(scalar(@path) > 0) if DEBUG; # there should be at least one element left (e.g. text:p).
	if( scalar(@path) > 1 ) {
		$tag = shift(@path);
		print STDERR "keep toplevel list item: $tag->[0]\n" if $self->{'verbose'} && $self->{'verbose'} > 1;
		assert( $tag->[0] =~ /^text:.*-list$/ );
	} else {
		print STDERR "plain text, no list: $path[0]->[0]\n" if $self->{'verbose'} && $self->{'verbose'} > 1;
	}
	foreach $tag (@path) {
		$attr = PBib::Document::XML::formatXMLAttributes($tag->[1]);
		$tag = $tag->[0];
		$sep = "</$tag>$sep<$tag$attr>";
	}
	return $sep;
}
sub bibitems_end { my ($self) = @_; return ""; }

=back

=cut

1;

