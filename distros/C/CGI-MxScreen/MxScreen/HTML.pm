#
# $Id: HTML.pm,v 0.1 2001/04/22 17:57:03 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: HTML.pm,v $
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

#
# HTML generation utils for the CGI::MxScreen framework.
#

use strict;

package CGI::MxScreen::HTML;

use vars qw(@EXPORT @EXPORT_OK @ISA);

require Exporter;
@ISA = qw(Exporter);

use Getargs::Long;
use CGI qw/:html/;

@EXPORT = qw(
	color red yellow orange green blue purple violet magenta cyan
	flash blink center
	escape_HTML 
	unescape_HTML 
);

#
# Color makers and useful wrappers
#

BEGIN {
	no strict 'refs';
	my @rainbow = qw[red yellow orange green blue purple violet];
	my @others =  qw[magenta cyan];
	for my $color (@rainbow, @others) {
		*$color = sub { qq<<FONT COLOR="\U$color\E">@_</FONT>> };
	}
}

sub color {
    my $shade = shift;
    qq<<FONT COLOR="\U$shade\E">@_</FONT>>; 
};

sub flash  { qq[<FLASH>@_</FLASH>] }
sub blink  { qq[<BLINK>@_</BLINK>] }
sub center { qq[<CENTER>@_</CENTER>] }

#
# escape_HTML
#
# Escape the HTML special characters, for safe printing in <PRE> sections
# for instance.
#
sub escape_HTML {
	my ($t) = @_;
	$t =~ s/&/&amp;/g;			# Must come first
	$t =~ s/\"/&quot;/g;
	$t =~ s/>/&gt;/g;
	$t =~ s/</&lt;/g;
	return $t;
}

#
# unescape_HTML
#
# Un-escape all HTML escaped sequences.
#
sub unescape_HTML {
	my ($s) = @_;
	$s =~ s/&quot;/\"/ig;
	$s =~ s/&gt;/>/ig;
	$s =~ s/&lt;/</ig;
	$s =~ s/&amp;/&/ig;			# Must come last
}

1;

=head1 NAME

CGI::MxScreen::HTML - various HTML utility routines

=head1 SYNOPSIS

 use CGI::MxScreen::HTML;

 # Colours
 print p("Those are ".red("red words"));

 # Extra HTML tags
 print center(
     p(
         flash("flashing") . " and " . blink("blinking") . " centered words"
     )
 );

 # HTML escapes
 my $escaped = escape_HTML("This & that <will> show");
 print "<p>$escaped</p>";
 my $str = unescape_HTML($escaped);

=head1 DESCRIPTION

This package holds various utility routines taken out of Tom Christiansen's
C<MxScreen> program (a "graphical" front-end to his I<Magic: The Gathering>
database) which greatly inspired this framework.

=head2 Colours

Those routines simply emit text within enclosing HTML tags.  The following
color routines are defined:

 red yellow orange green blue purple violet magenta cyan

For instance:

    print p(big(strong(red("WARNING:"))));

would print a big boldface (usually) WARNING: in red.

=head2 Non-portable HTML tags

The following routine add non-portable HTML tags that were introduced by
Netscape.  I don't recommend their use, but if you can't avoid it, they are:

 flash blink center

For instance:

	print center(h1("Title"));

would print a level-1 header centered.

=head2 HTML escaping

Two routines, C<escape_HTML()> and C<unescape_HTML()> perform basic HTML
quoting and un-quoting.  By I<basic>, I mean they only take care of
escaping (and repectively unescaping) the "&", "<" and ">" characters. The
quote character (") is also escaped as "&quot;".

=head1 AUTHORS

Tom Christiansen F<E<lt>tchrist@perl.comE<gt>> within his MxScreen program.

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>> for the repackaging
within the C<CGI::MxScreen> framework.

Send bug reports, suggestions, problems or questions to
Jason Purdy F<E<lt>Jason@Purdy.INFOE<gt>>


=head1 SEE ALSO

CGI::MxScreen(3).

=cut

