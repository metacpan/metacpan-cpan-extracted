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

package App::FuguWeb::Fragment;
our $VERSION = '0.11.2';

use App::FuguWeb;

# App::FuguWeb::Fragment - the fit of a body fragment to its page.
#
# A renderer reduces each source to one body fragment. The build then
# fits the fragment to the page: it reads the outline, it gives each
# heading of a translation the id of its counterpart in the default
# language, per D-06, and it removes the frame that a renderer writes
# around the content, per D-07. The fit of each renderer stays in one
# function, so the renderer stays replaceable.
#
# Each function reads text and returns text, and holds no state. The
# build and the check read the outline through the same function, so
# the two agree. Each function reads an attribute through the one
# reader of App::FuguWeb, so the text of a value is never an attribute.

# A link that the fit of a 404 body keeps as it stands: a link with a
# scheme, and a link from the root, which the check refuses, per
# WEB-LINKS-4.
my $UNCHANGED = qr{\A(?:[A-Za-z][A-Za-z0-9.+-]*:|/)};

# The level of each heading of a manual page, by the class that
# mandoc(1) writes, per WEB-MANUALS-10. mandoc 1.14.6 writes a section
# heading as an h1 and a subsection heading as an h2. The mandoc of
# OpenBSD writes an h2 and an h3. The class is the same in each
# version, so the fit reads the class and not the level.
my %LEVEL = ( Sh => 2, Ss => 3 );

# outline($html):
#	The outline of a fragment, per WEB-OUTLINE: one array
#	reference for each heading, in order, of its level and its id.
#	The id is undef when the heading carries none. The id holds a
#	double quote as &quot;, so it can go into a double-quoted
#	attribute as it stands.
sub outline ($html)
{
	my @outline;
	while ( $html =~ m{<[hH]([1-6])\b([^>]*)>}g ) {
		push @outline, [ $1, _id($2) ];
	}

	return \@outline;
}

# follow($html, $outline, $at):
#	The fragment of a page of another language, held to the outline
#	of its namesake in the default language. Each heading takes the
#	id of the heading at the same position in the outline, or no id
#	when that heading has none, per WEB-OUTLINE-2.
#
#	Each link of the fragment to a heading of the fragment then
#	names the id that the heading takes, per WEB-OUTLINE-4. A link
#	of the class Sx of mandoc(1) names the heading of the same text.
#	mandoc makes the link from the text, and can give the heading
#	no id. Each other link names the heading of its old id. A link
#	to a heading that takes no id stays as it stands.
#
#	The function returns undef when the two outlines differ, per
#	WEB-OUTLINE-1. $at then holds the position of the first heading
#	that differs, from 1: a heading of another level, a heading that
#	the outline does not hold, or a heading of the outline that the
#	fragment does not hold.
sub follow ( $html, $outline, $at )
{
	my $count = 0;
	my ( $differs, %by_id, %by_text );

	my $fitted =
	    $html =~ s{(<[hH]([1-6]))\b([^>]*)>(?=((?:(?!</?[hH][1-6]\b).)*))}{
		my ( $open, $level, $attributes, $text ) = ( $1, $2, $3, $4 );
		my $want = $outline->[ $count++ ];
		$differs //= $count unless $want && $want->[0] == $level;

		my $id = $want ? $want->[1] : undef;
		if ( defined $id ) {
			my $old = _id($attributes);
			$by_id{$old} //= $id if defined $old;
			$by_text{ _text($text) } //= $id;
		}
		$open . _with_id( $attributes, $id ) . '>'
	}gser;
	$differs //= $count + 1 if $count < @$outline;

	if ( defined $differs ) {
		$$at = $differs;
		return;
	}

	return _relinked( $fitted, \%by_id, \%by_text );
}

# manual($html, $title):
#	The fit of a fragment of mandoc(1) to a manual page, per
#	WEB-MANUALS-9 to WEB-MANUALS-11. The title is the name and the
#	section of the manual, as in fuguweb(1), as characters.
#
#	The fit removes the head and the foot, per D-07. mandoc 1.14.6
#	writes each one as a table. The mandoc of OpenBSD writes each one
#	as a div, and a main around the text. The fit replaces that main
#	with a div, as in 1.14.6, so a page holds one main.
#
#	Each section heading becomes an h2, and each subsection heading
#	an h3. A heading loses the link to itself and keeps its text and
#	its id. Each character reference to a character outside ASCII
#	becomes the character. A reference to an ASCII character stays,
#	because it can be markup, such as &#x3C;.
#
#	The fragment then opens with the title in one h1.
sub manual ( $html, $title )
{
	my $body = $html;

	$body =~ s{<(table|div) class="(?:head|foot)"[^>]*>.*?</\1>\n?}{}gs;
	$body =~ s{<main( class="manual-text">.*)</main>}{<div$1</div>}s;

	$body =~ s{(<h[1-6]\b([^>]*)>(.*?)</h[1-6]>)}{
		my ( $heading, $attributes, $text ) = ( $1, $2, $3 );
		my $level =
		    $LEVEL{ App::FuguWeb::attribute( $attributes, 'class' ) // '' };
		defined $level
		    ? "<h$level$attributes>" . _unlinked($text) . "</h$level>"
		    : $heading
	}gse;

	$body =~ s{&#x([0-9A-Fa-f]+);}{
		hex $1 > 0x7F ? chr( hex $1 ) : "&#x$1;"
	}ge;

	return '<h1>' . App::FuguWeb::escape_html($title) . "</h1>\n" . $body;
}

# not_found($html, $tree):
#	The fit of the body of the 404.html of one tree to the top-level
#	404.html, per WEB-TOP-6. The tree is the path of the tree below
#	the site root, such as zh-hans.
#
#	Each start tag loses its id, so the page that holds the body of
#	each language holds no duplicate id. Each relative link resolves
#	against the 404.html of the tree, to a path below the site root.
#	The top-level page resolves each link from the site root, per
#	WEB-TOP-3, so the link then names the same file. A query and a
#	fragment stay at the end of the link: index.html becomes
#	zh-hans/index.html, and #x becomes zh-hans/404.html#x.
#
#	A link with a scheme and a link from the root stay as they
#	stand. So does a link that steps above the site root, and the
#	check reports it.
sub not_found ( $html, $tree )
{
	my $page = "$tree/" . App::FuguWeb::NOT_FOUND_PAGE;

	return $html =~ s{(<[A-Za-z][^\s/>]*)([^>]*)>}{
		$1 . App::FuguWeb::edit_attributes( $2, sub ( $attribute, $name, $value ) {
			return $attribute unless defined $value;
			return '' if lc $name eq 'id';
			return $attribute unless lc($name) =~ m{\A(?:href|src)\z};
			return qq{ $name="} . _quoted( _rebased( $value, $page ) ) . '"';
		} ) . '>'
	}ger;
}

# _rebased($link, $page):
#	One link of the page at the path, as a path below the site root.
#	A link of a fragment alone names the page itself. The function
#	reads the path through App::FuguWeb::resolve_ref, the one reader
#	of a reference.
sub _rebased ( $link, $page )
{
	return $link if $link =~ $UNCHANGED;

	my ( $path, $rest ) = $link =~ m{\A([^?#]*)(.*)\z}s;
	return $page . $rest unless length $path;

	my $dir = $page =~ s{/[^/]*\z}{}r;
	my $to  = App::FuguWeb::resolve_ref( $dir, $path ) // return $link;

	return $to . $rest;
}

# _relinked($html, $by_id, $by_text):
#	The fragment, with each link to a heading of the fragment that
#	names the id that the heading takes, per WEB-OUTLINE-4. A link of
#	the class Sx finds its heading by its text, and each other link
#	by its old id.
sub _relinked ( $html, $by_id, $by_text )
{
	return $html =~ s{(<[aA]\b)([^>]*)>(?=(.*?)</[aA]\s*>|)}{
		my ( $open, $attributes, $text ) = ( $1, $2, $3 // '' );
		my $sx = ( App::FuguWeb::attribute( $attributes, 'class' ) // '' ) =~ m{(?:\A|\s)Sx(?:\s|\z)};
		$open . App::FuguWeb::edit_attributes( $attributes, sub ( $attribute, $name, $value ) {
			return $attribute
			    unless lc $name eq 'href'
			    && defined $value
			    && $value =~ m{\A#(.*)\z}s;
			my $old = _quoted($1);
			my $id  = $sx ? $by_text->{ _text($text) } : $by_id->{$old};
			return defined $id ? qq{ $name="#$id"} : $attribute;
		} ) . '>'
	}gser;
}

# _id($attributes):
#	The id of a start tag, or undef when it carries none.
sub _id ($attributes)
{
	my $id = App::FuguWeb::attribute( $attributes, 'id' ) // return;

	return _quoted($id);
}

# _with_id($attributes, $id):
#	The attributes of a start tag, with the id in place of its own
#	one, or with no id when the id is undef. The id takes the place
#	of the first id of the tag, so a tag whose id does not change
#	keeps its bytes. A tag with no id takes the id at the end.
sub _with_id ( $attributes, $id )
{
	my $new    = defined $id ? qq{ id="$id"} : '';
	my $held   = 0;
	my $fitted = App::FuguWeb::edit_attributes(
		$attributes,
		sub ( $attribute, $name, $value ) {
			return $attribute
			    unless lc $name eq 'id' && defined $value;
			return $held++ ? '' : $new;
		} );

	return $held ? $fitted : $fitted . $new;
}

# _text($html):
#	The text of a part of a fragment, with no tag, and with each run
#	of white space as one space. mandoc(1) can break the text of a
#	heading over two lines, and not the text of its link.
sub _text ($html)
{
	return join ' ', split ' ', $html =~ s{<[^>]*>}{}gr;
}

# _quoted($value):
#	A value of an attribute, for a double-quoted attribute. A value
#	in single quotes can hold a double quote, which then ends the
#	attribute early.
sub _quoted ($value)
{
	return $value =~ s/"/&quot;/gr;
}

# _unlinked($text):
#	The text of a heading of mandoc(1), with no link to itself, per
#	WEB-MANUALS-10. The link holds the whole text, and the text can
#	hold a link of its own, such as a cross-reference.
sub _unlinked ($text)
{
	return $text =~
	    s{\A<a class="permalink" href="#[^"]*">(.*)</a>\z}{$1}sr;
}

1;
