# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package App::FuguWeb::Index;
our $VERSION = '0.1.1';

use App::FuguWeb;
use Fugu::File;

# App::FuguWeb::Index - the body of the manual index.
#
# The groups follow the source directories, which is already how a
# tree is organized. Thus the index cannot drift when a manual is
# added: no list here names one.
#
# The index never retypes a description either. It asks each
# App::FuguWeb::Manual, and that reads the source.

# The fragment that replaces the generated opening, when a project
# writes one.
use constant OPENING_FRAGMENT => 'manuals.body.html';

# App::FuguWeb::Index->new(%args):
#	config => $config	the site description (required)
sub new ( $class, %args )
{
	my $config = $args{config};
	die 'config parameter required'
	    unless defined $config;

	return bless { config => $config }, $class;
}

# $self->title:
#	The title of the index page. It comes from the page block that
#	names the index as its source, so the heading and the browser
#	tab always agree. The build renders the index for such a block
#	only, so the block is always there.
sub title ($self)
{
	for my $page ( $self->{config}->pages ) {
		return $page->{title} if $page->{source} eq 'index';
	}

	return;
}

# $self->body:
#	The body fragment of the index page.
sub body ($self)
{
	my $html = $self->_opening;
	$html .= $self->_group($_) for $self->{config}->groups;

	return $html;
}

# $self->_opening:
#	The heading and the paragraph above the groups. A project
#	fragment in the source directory replaces both: the prose is
#	the project's, and only the project knows what its manuals are.
sub _opening ($self)
{
	my $path = $self->{config}->source_path(OPENING_FRAGMENT);
	return Fugu::File->read($path) // '' if -f $path;

	my $url  = $self->{config}->man_url;
	my $host = $url;
	$host =~ s{^[a-z]+://}{};
	$host =~ s{/$}{};

	return
	      '<h1>'
	    . App::FuguWeb::escape_html( $self->title )
	    . "</h1>\n" . "\n"
	    . '<p>These pages come from the same sources that'
	    . " <code>man</code> reads on an\n"
	    . 'installed system.  Cross-references between these pages'
	    . " are links; all\n"
	    . "other cross-references go to\n"
	    . qq{<a href="$url">$host</a>.</p>\n} . "\n";
}

# $self->_group($group):
#	One heading and one description list. A group with no manual
#	emits nothing, so an empty group leaves no heading behind.
sub _group ( $self, $group )
{
	my @manuals = $group->manuals;
	return '' unless @manuals;

	my $html =
	      '<h2 id="'
	    . App::FuguWeb::escape_attr( $group->anchor ) . '">'
	    . App::FuguWeb::escape_html( $group->heading )
	    . "</h2>\n<dl>\n";
	$html .= _entry($_) for @manuals;
	$html .= "</dl>\n\n";

	return $html;
}

# _entry($manual):
#	One term and one definition. The './' is mandatory: a browser
#	reads a relative URL whose first segment holds a colon as a
#	scheme, and a module page is named App::FuguWeb.3p.html.
sub _entry ($manual)
{
	my $name    = App::FuguWeb::escape_html( $manual->name );
	my $section = $manual->section;

	return
	    sprintf "<dt><a href=\"./%s\">%s(%s)</a></dt>\n" . "<dd>%s</dd>\n",
	    App::FuguWeb::escape_attr( $manual->page ), $name, $section,
	    App::FuguWeb::escape_html( $manual->description );
}

1;
