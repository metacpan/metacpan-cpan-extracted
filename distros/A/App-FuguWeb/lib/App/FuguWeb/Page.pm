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

package App::FuguWeb::Page;
our $VERSION = '0.11.2';

use App::FuguWeb;
use App::FuguWeb::Language;
use Fugu::File;

# App::FuguWeb::Page - the one chrome around one body fragment.
#
# Every source format is reduced to one HTML body fragment, and this
# module wraps it: the head, the header, the navigation, the fragment,
# and the footer, per WEB-CHROME. The layout is fixed. What a project
# decides is the site name, the languages, the navigation, and the
# footer prose.
#
# A page takes its path below the site root, and relative() makes each
# link of the chrome from that path, per WEB-LINKS-1. The place of the
# path decides the rest: a page of a tree, a page of the top level, or
# the human page of a key directory. The forward page of the top level
# takes a shape of its own, per WEB-TOP-1.
#
# The module builds the document as characters, with string operations
# and not with a substitution over a template. A title may therefore
# hold any character. The write encodes the document to UTF-8.

# The em dash between the page title and the site name. It is not
# ASCII, so it is a character, and the encode writes its bytes.
use constant EM_DASH => "\x{2014}";

# A link of the description that passes unchanged, per WEB-LINKS-2: an
# absolute URL, and a root-absolute path, which the check refuses, per
# WEB-LINKS-4.
my $UNCHANGED = qr{\A(?:[A-Za-z][A-Za-z0-9.+-]*:|/)};

# relative($from, $to):
#	The link from the page at the path $from to the file at the
#	path $to, per WEB-LINKS-1. Each path names a file below the
#	site root. The link steps up out of each directory of $from that
#	$to does not share, then down into $to. A query or a fragment of
#	$to stays at the end of the link.
#
#	A browser reads a link whose first segment holds a colon as a
#	URL scheme, so such a link takes ./ in front of it. A module
#	page such as Fugu::Daemon.3p.html needs it.
sub relative ( $from, $to )
{
	my ( $path, $suffix ) = $to =~ m{\A([^?#]*)(.*)\z}s;

	my @up = split m{/}, $from;
	pop @up;
	my @down = split m{/}, $path, -1;
	my $file = pop @down;

	while ( @up && @down && $up[0] eq $down[0] ) {
		shift @up;
		shift @down;
	}

	my $link = join '/', ( ('..') x @up ), @down, $file;
	$link = "./$link" if $link =~ m{\A[^/]*:};

	return $link . $suffix;
}

# body_lang($entry, $language):
#	The tag of the language of the main element of the page of one
#	entry of the description in the tree of the language, per
#	WEB-LANGUAGE-11: the language of the value of the entry. The
#	index marks each part of its own, so the element that holds it
#	takes the language of the tree. The build and the check read
#	the language here, so the two agree.
sub body_lang ( $entry, $language )
{
	return $entry->{source} eq 'index' ? $language->tag : $entry->{lang};
}

# App::FuguWeb::Page->new(%args):
#	config   => $config	the site description (required)
#	language => $language	the language of the tree whose words
#				the chrome takes (default: the default
#				language)
#	footer   => $html	the footer fragment of that language, as
#				characters (default: none)
sub new ( $class, %args )
{
	my $config = $args{config};
	die 'config parameter required'
	    unless defined $config;

	return bless {
		config => $config,
		tree   => $args{language} // $config->default_language,
		footer => $args{footer},
	}, $class;
}

# $self->write($out, $path, $title, $fragment, %page):
#	Write the whole page to the path below the output directory:
#	the chrome around the fragment, encoded to UTF-8. The fragment
#	goes in unchanged: it is already HTML, from a renderer or from
#	the project's own source directory. The method returns true on
#	success, and undef with a message in the log otherwise. The
#	page arguments are those of document.
sub write ( $self, $out, $path, $title, $fragment, %page )
{
	return Fugu::File->write(
		"$out/$path",
		App::FuguWeb::encode(
			$self->document( $path, $title, $fragment, %page ) ) );
}

# $self->document($path, $title, $fragment, %page):
#	body_lang => $tag	the language of the fragment
#				(default: the language of the page)
#
#	The whole page at the path below the site root, as characters.
#	A caller that writes the file itself, or that holds the page
#	beside other generated bytes, reads the document here and never
#	repeats the chrome.
#
#	A page in the tree of the language is a tree page, and it takes
#	the whole chrome. A page of the top level takes the base of
#	WEB-TOP-3, and the list of the languages of WEB-TOP-4. The human
#	page of a key directory is a page of en, per WEB-CHROME-8. A
#	fragment of another language than the page carries that language
#	on the main element, per WEB-LANGUAGE-11.
sub document ( $self, $path, $title, $fragment, %page )
{
	my $at   = $self->_at($path);
	my $body = $page{body_lang} // $at->{lang}->tag;

	return
	      $self->_head( $at, $title )
	    . "<body>\n"
	    . $self->_header($at)
	    . $self->_nav($at) . '<main'
	    . $self->_marks( $at, $body ) . ">\n"
	    . ( $fragment // '' )
	    . "</main>\n"
	    . $self->_footer($at)
	    . "</body>\n</html>\n";
}

# $self->forward:
#	The forward page of WEB-TOP-1, index.html of the top level, as
#	characters. The page takes the language of the object, so the
#	caller makes the object with the default language. A meta
#	refresh forwards to the entry page of the tree of the object,
#	the default tree, and the page loads nothing, per D-01. The head
#	holds the charset, the refresh, the title and the links of
#	WEB-CHROME-6, in that order. The title is the site name.
#
#	On a site of more than one language, the body holds the list of
#	the languages, per WEB-TOP-2. Each link goes to the entry page
#	of its language, and no link is the current one. On a site of
#	one language, the body holds one link to the entry page, with
#	the site name as its text.
sub forward ($self)
{
	my $config = $self->{config};
	my $at     = $self->_at(App::FuguWeb::FORWARD_PAGE);

	my $html  = $at->{lang}->attributes;
	my $site  = App::FuguWeb::escape_html( $self->{tree}->site );
	my $to    = $self->_href( $at, $config->entry );
	my $links = $self->_alternates( '', $config->entry );
	my $body  = $self->_languages($at)
	    || qq{<p><a href="$to">$site</a></p>\n};

	return <<"HTML";
<!DOCTYPE html>
<html$html>
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=$to">
<title>$site</title>
$links</head>
<body>
$body</body>
</html>
HTML
}

# $self->sections(@bodies):
#	The main part of the top-level 404.html, per WEB-TOP-5. Each
#	body is an array reference of the tag of the language of its
#	text, and the body. Each body sits in its own section, in order,
#	with the marks of its language, per WEB-LANGUAGE-11. The body
#	goes in unchanged, so the caller fits it first, per WEB-TOP-6.
sub sections ( $self, @bodies )
{
	my $tree = $self->{tree};

	return join '', map {
		my ( $tag, $body ) = @$_;
		'<section'
		    . $tree->marks( $self->{config}->language($tag) ) . ">\n"
		    . $body
		    . "</section>\n"
	} @bodies;
}

# $self->_at($path):
#	The place of the page at the path below the site root: its path,
#	its name, whether it sits in the tree of the language or at the
#	top level, and the language of the page. A page in the tree of
#	the language is a tree page. The human page of a key directory
#	is a page of en, per WEB-CHROME-8.
sub _at ( $self, $path )
{
	my ( $dir, $name ) = $path =~ m{\A(?:([^/]+)/)?([^/]+)\z}
	    or die "not the path of a page: $path";
	my $tree = $self->{tree};

	my $at = {
		path    => $path,
		name    => $name,
		in_tree => defined $dir && $dir eq $tree->path,
		top     => !defined $dir,
	};
	$at->{lang} =
	      $at->{in_tree} || $at->{top}
	    ? $tree
	    : App::FuguWeb::Language->new(
		tag => App::FuguWeb::Language::ENGLISH );

	return $at;
}

# $self->_marks($at, $tag):
#	The marks of an element whose text comes from the language of
#	the tag, per WEB-LANGUAGE-11. Text of the language of the page
#	takes none. The key page is a page of en, which a site need not
#	declare, so the test of the tag comes before the search.
sub _marks ( $self, $at, $tag )
{
	return '' if $tag eq $at->{lang}->tag;

	return $at->{lang}->marks( $self->{config}->language($tag) );
}

# $self->_href($at, $href):
#	One href of the chrome, escaped. A relative href names a page
#	of the tree, so the link goes from the page to that page. Any
#	other href passes unchanged, per WEB-LINKS-2.
sub _href ( $self, $at, $href )
{
	my $link =
	      $href =~ $UNCHANGED
	    ? $href
	    : relative( $at->{path}, $self->{tree}->path . "/$href" );

	return App::FuguWeb::escape_attr( App::FuguWeb::as_text($link) );
}

# $self->_head($at, $title):
#	The head of the page, per WEB-CHROME-1. Every value is escaped
#	before the heredoc reads it, so nothing raw reaches the markup.
sub _head ( $self, $at, $title )
{
	my $tree = $self->{tree};
	my $html = $at->{lang}->attributes;

	# WEB-CHROME-8. The site name is of the default language, so
	# the title of the key page holds its own English words alone.
	my $full = App::FuguWeb::escape_html($title);
	$full .= ' ' . EM_DASH . ' ' . App::FuguWeb::escape_html( $tree->site )
	    if $at->{in_tree} || $at->{top};

	# A host serves a page of the top level at each path that no
	# file answers. The base makes each relative link of the page
	# resolve from the site root, and not from the missing path.
	my $base =
	    $at->{top}
	    ? '<base href="'
	    . App::FuguWeb::escape_attr(
		App::FuguWeb::as_text( $self->{config}->url_path ) )
	    . qq{">\n}
	    : '';

	my $links =
	      $at->{in_tree}
	    ? $self->_alternates( $at->{path}, $at->{name} )
	    : '';
	my $sheet = App::FuguWeb::escape_attr(
		relative( $at->{path}, App::FuguWeb::STYLESHEET ) );

	return <<"HTML";
<!DOCTYPE html>
<html$html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
$base<title>$full</title>
$links<link rel="stylesheet" href="$sheet">
</head>
HTML
}

# $self->_alternates($path, $name):
#	The links of WEB-CHROME-6 of the page at the path: the page
#	itself, the page of the name in the tree of each language, its
#	own included, and the forward page of the top level. Each href
#	is the url of the site, then the path of the target page. The
#	forward page is the bare url, so its own path is empty, and each
#	language links its entry page, per WEB-TOP-2.
sub _alternates ( $self, $path, $name )
{
	my $config = $self->{config};
	my $url    = sub ($path) {
		return App::FuguWeb::escape_attr(
			App::FuguWeb::as_text( $config->url . $path ) );
	};

	my $links = '<link rel="canonical" href="' . $url->($path) . qq{">\n};
	for my $language ( $config->languages ) {
		$links .=
		      '<link rel="alternate" hreflang="'
		    . App::FuguWeb::escape_attr( $language->tag )
		    . '" href="'
		    . $url->( $language->path . "/$name" )
		    . qq{">\n};
	}
	$links .=
	      '<link rel="alternate" hreflang="x-default" href="'
	    . $url->('')
	    . qq{">\n};

	return $links;
}

# $self->_header($at):
#	The banner: the link to the entry page of the tree, with the
#	site name as its text, per WEB-CHROME-2. A site name of another
#	language than the page carries its marks on the link.
sub _header ( $self, $at )
{
	my $tree = $self->{tree};

	return
	      "<header>\n"
	    . '<a href="'
	    . $self->_href( $at, $self->{config}->entry ) . '"'
	    . $self->_marks( $at, $tree->site_lang ) . '>'
	    . App::FuguWeb::escape_html( $tree->site )
	    . "</a>\n"
	    . $self->_languages($at)
	    . "</header>\n";
}

# $self->_languages($at):
#	The list of the languages of WEB-CHROME-3, on a tree page or a
#	page of the top level of a site of more than one language. The
#	link of each item has the name of the language as its text. The
#	tag is its lang and its hreflang, and its direction is its dir
#	when the two directions differ.
#
#	On a tree page, each link goes to the same page in that
#	language, and the link of the language of the page is the
#	current one. A page of the top level belongs to no tree, so each
#	link goes to the entry page of its language, and no link is the
#	current one, per WEB-TOP-2 and WEB-TOP-4.
sub _languages ( $self, $at )
{
	my @languages = $self->{config}->languages;
	return '' unless ( $at->{in_tree} || $at->{top} ) && @languages > 1;

	my $own   = $self->{tree};
	my $name  = $at->{in_tree} ? $at->{name} : $self->{config}->entry;
	my $items = '';
	for my $language (@languages) {
		my $tag  = App::FuguWeb::escape_attr( $language->tag );
		my $href = App::FuguWeb::escape_attr(
			App::FuguWeb::as_text(
				relative(
					$at->{path}, $language->path . "/$name"
				) ) );
		my $dir =
		    $language->dir eq $own->dir
		    ? ''
		    : ' dir="' . $language->dir . '"';
		my $current =
		    $at->{in_tree} && $language->tag eq $own->tag
		    ? ' aria-current="page"'
		    : '';

		$items .=
qq{<li><a href="$href" hreflang="$tag" lang="$tag"$dir$current>}
		    . App::FuguWeb::escape_html( $language->name )
		    . "</a></li>\n";
	}

	return "<ul>\n$items</ul>\n";
}

# $self->_nav($at):
#	The navigation of WEB-CHROME-4: one list of the nav entries of
#	the tree, in the order of the description. A label of another
#	language than the page carries its marks on its link. The entry
#	whose path, with no query, resolves from the tree to the page
#	is the current one. A site with no nav entry gets no nav.
sub _nav ( $self, $at )
{
	my @entries = $self->{config}->nav( $self->{tree}->tag );
	return '' unless @entries;

	my $items = '';
	for my $entry (@entries) {
		my ($path) = App::FuguWeb::ref_parts( $entry->{href} );
		my $names =
		    App::FuguWeb::resolve_ref( $self->{tree}->path, $path )
		    // '';
		my $current =
		    $at->{in_tree} && $names eq $at->{path}
		    ? ' aria-current="page"'
		    : '';

		$items .=
		      '<li><a href="'
		    . $self->_href( $at, $entry->{href} ) . '"'
		    . $self->_marks( $at, $entry->{label_lang} )
		    . $current . '>'
		    . App::FuguWeb::escape_html( $entry->{label} )
		    . "</a></li>\n";
	}

	return "<nav>\n<ul>\n$items</ul>\n</nav>\n";
}

# $self->_footer($at):
#	The footer of WEB-CHROME-7. A tree page carries the footer
#	fragment of its language, and no other page does. A project
#	with no footer fragment gets no footer element: an empty
#	footer is not chrome, it is a gap.
#
#	The fragment is the prose of the project, and this class
#	copies it in unchanged. A relative link of it resolves against
#	the directory of the page. Inside a tree that link names a page
#	of the tree. On the key page it would name a file of the key
#	directory, per WEB-KEYS-32, and on a page of the top level a
#	file of the root. The writer of the fragment named neither.
sub _footer ( $self, $at )
{
	my $footer = $self->{footer};
	return '' unless defined $footer && $at->{in_tree};

	my $marks = $self->_marks( $at, $self->{tree}->footer_lang );

	return "<footer$marks>\n$footer</footer>\n";
}

1;
