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

package App::FuguWeb::Check;
our $VERSION = '0.11.2';

use App::FuguWeb;
use App::FuguWeb::Fragment;
use App::FuguWeb::Keys;
use App::FuguWeb::Page;
use Fugu::File;

# App::FuguWeb::Check - what a built site must be true of.
#
# The checks are generic, so every project that uses the tool gets
# them. A project keeps only the assertions that are about its own
# content.
#
# The class never fetches a link. It collects the external ones and
# reports them, because the build and its checks touch no network.
#
# The class reads each attribute of a page through the one reader of
# App::FuguWeb, as the fit of a fragment does. The text of a value,
# such as title="see href=x", is therefore no attribute, and a name
# such as data-id is no id.

# App::FuguWeb::Check->new(%args):
#	config => $config	the site description (required)
#	out    => $dir		the built site (required)
sub new ( $class, %args )
{
	my $config = $args{config};
	die 'config parameter required'
	    unless defined $config;
	die 'out parameter required'
	    unless defined $args{out};

	return bless {
		config   => $config,
		out      => $args{out},
		external => {},
	}, $class;
}

# $self->pages:
#	Every page of every language tree, in a stable order: for each
#	language, the pages of the description, then one page for each
#	manual. Each name is <path>/<page>, where the path is that of
#	the tree of the language.
sub pages ($self)
{
	my $config = $self->{config};
	my @names  = $config->page_names;

	return map {
		my $path = $_->path;
		map { "$path/$_" } @names
	} $config->languages;
}

# $self->generated_pages:
#	The human page of each key directory. The build writes it
#	itself, and no description block names it. The pages of the
#	top level are the other pages outside every tree, and
#	top_pages of the description names them.
#
#	The page gets the checks of a page, so a broken link of the
#	chrome fails the check. It gets no reachability check: the
#	site links the key directory when it wants to, and a site that
#	does not is not broken.
sub generated_pages ($self)
{
	return grep { m{\.html\z} } $self->{config}->key_paths;
}

# $self->external:
#	The external links that the last run collected, sorted. The
#	class never fetches one.
sub external ($self)
{
	my @links = sort keys %{ $self->{external} };

	return @links;
}

# $self->run:
#	Check the site and return the problems, each one a sentence
#	that names the page. An empty list means the site is good.
#
#	Each page of a tree, the top-level 404.html and the human page
#	of each key directory take the checks of a page. The place of
#	the path of a page decides its chrome, as it does in
#	App::FuguWeb::Page. The forward takes the checks of its own
#	shape, per WEB-TOP-1 and WEB-TOP-2.
sub run ($self)
{
	$self->{external}  = {};
	$self->{inventory} = { map { $_ => 1 } $self->{config}->inventory };

	my @problems = $self->_check_inventory;

	my $forward   = App::FuguWeb::FORWARD_PAGE;
	my @not_found = grep { $_ ne $forward } $self->{config}->top_pages;

	for my $page ( $self->pages, @not_found, $self->generated_pages ) {
		next unless -f $self->{out} . "/$page";
		push @problems, $self->_check_page($page);
	}

	push @problems, $self->_check_forward
	    if -f $self->{out} . "/$forward";
	push @problems, $self->_check_nav;
	push @problems, $self->_check_outlines;
	push @problems, $self->_check_reachable;
	push @problems, $self->_check_keys;

	return @problems;
}

# $self->_check_keys:
#	Hold each key directory to the design. A description with no
#	keys block has no key directory, and the checks then find
#	nothing to say.
#
#	The rules read the source directory and not the output, so the
#	answer does not depend on a build having run. A stray key file
#	and a stale digest are faults of the checkout.
sub _check_keys ($self)
{
	my $config = $self->{config};

	return map {
		App::FuguWeb::Keys->new( config => $config, dir => $_ )
		    ->problems
	} $config->keys_dirs;
}

# $self->_check_inventory:
#	Every page and asset exists and is not empty, and the output
#	holds nothing else: no staging directory, no editor backup, no
#	stray source.
sub _check_inventory ($self)
{
	my @problems;

	unless ( -d $self->{out} ) {
		return "$self->{out}: the site is not built";
	}

	my @expected = $self->{config}->inventory;
	for my $name (@expected) {
		my $path = $self->{out} . "/$name";
		push @problems, "$name: missing from the output"
		    unless -e $path;
		push @problems, "$name: empty" if -e $path && !-s $path;
	}

	# The walk reads the whole tree. Each language tree and each
	# key directory sit below the top level, and a walk of one
	# level would take every page and every key for a stray file.
	my $entries = App::FuguWeb::list_tree( $self->{out} )
	    or return "$self->{out}: cannot read the output directory: $!";

	my %expected = map { $_ => 1 } @expected;
	push @problems, "$_: in the output but not in the site"
	    for grep { !$expected{$_} } @$entries;

	return @problems;
}

# An href of the description that passes unchanged, per WEB-LINKS-2: an
# absolute URL, and a root-absolute path, which the check of the
# references refuses, per WEB-LINKS-4.
my $UNCHANGED = qr{\A(?:[A-Za-z][A-Za-z0-9.+-]*:|/)};

# $self->_check_nav:
#	Hold each relative nav href of the description to a page of
#	each tree, per WEB-LINKS-2. The path of the href resolves from
#	each tree, and it must name a page of that tree.
sub _check_nav ($self)
{
	my $config = $self->{config};
	my @names  = $config->page_names;
	my %tree   = map {
		my $path = $_->path;
		( $path => { map { ( "$path/$_" => 1 ) } @names } )
	} $config->languages;

	my @problems;
	for my $href ( map { $_->{href} } $config->nav ) {
		next if $href =~ $UNCHANGED;

		my ($path) = App::FuguWeb::ref_parts($href);
		push @problems,
		    map { qq{nav "$href": names no page of the tree $_} }
		    grep {
			!$tree{$_}{ App::FuguWeb::resolve_ref( $_, $path )
				    // '' }
		    }
		    sort keys %tree;
	}

	return @problems;
}

# $self->_check_outlines:
#	Hold each heading id of each tree page of another language than
#	the default, per WEB-OUTLINE-3. The heading at each position
#	takes the id of the heading at the same position in the
#	namesake of the default tree, or no id when that heading has
#	none. The check reads the outline of the main element through
#	App::FuguWeb::Fragment, as the build does. A footer is the
#	fragment of its own language, so its headings are no part of
#	the outline.
sub _check_outlines ($self)
{
	my $config  = $self->{config};
	my $default = $config->default_language;

	my @problems;
	for my $language ( $config->languages ) {
		next if $language->tag eq $default->tag;

		for my $name ( $config->page_names ) {
			my $page   = $language->path . "/$name";
			my $source = $default->path . "/$name";
			next
			    unless -f $self->{out} . "/$page"
			    && -f $self->{out} . "/$source";

			push @problems, $self->_check_outline( $page, $source );
		}
	}

	return @problems;
}

# $self->_check_outline($page, $source):
#	Hold the heading ids of one page to those of its namesake of the
#	default tree, per WEB-OUTLINE-3.
sub _check_outline ( $self, $page, $source )
{
	my @have = @{ $self->_outline_of($page) };
	my @want = @{ $self->_outline_of($source) };

	my @problems;
	push @problems,
	      "$page: holds "
	    . scalar(@have)
	    . " headings, and $source holds "
	    . scalar(@want)
	    unless @have == @want;

	my $last = @have < @want ? $#have : $#want;
	for my $i ( 0 .. $last ) {
		my ( $held, $id ) = ( $have[$i][1], $want[$i][1] );
		next if !defined $held && !defined $id;
		next if defined $held && defined $id && $held eq $id;

		push @problems,
		      "$page: heading "
		    . ( $i + 1 )
		    . ' takes '
		    . _id_text($held)
		    . ", and $source takes "
		    . _id_text($id);
	}

	return @problems;
}

# $self->_outline_of($page):
#	The outline of the main element of one page of the output.
sub _outline_of ( $self, $page )
{
	return App::FuguWeb::Fragment::outline( $self->_main_of($page) // '' );
}

# $self->_main_of($page):
#	The part of one page of the output inside its main element, or
#	undef when the page holds none.
sub _main_of ( $self, $page )
{
	my ($main) = $self->_read($page) =~ m{<main\b[^>]*>(.*)</main>}s;

	return $main;
}

# $self->_read($page):
#	The bytes of one file of the output, or an empty string when the
#	file is missing. The check of the inventory reports a missing
#	file.
sub _read ( $self, $page )
{
	return Fugu::File->read( $self->{out} . "/$page" ) // '';
}

# _id_text($id):
#	The words of one id in a problem.
sub _id_text ($id)
{
	return defined $id ? qq{the id "$id"} : 'no id';
}

# $self->_check_page($page):
#	Everything that one page must be true of. A page of a tree
#	takes the chrome of its tree. The top-level 404.html and the
#	human page of a key directory take the chrome of the default
#	tree. The top-level 404.html carries the base, and the checks
#	of WEB-TOP.
sub _check_page ( $self, $page )
{
	my $html = $self->_read($page);
	my @problems;

	my ($title) = $html =~ m{<title>([^<]*)</title>};
	push @problems, "$page: has no title"
	    unless defined $title && length $title;

	# WEB-LANGUAGE-13. A tree page carries the tag and the
	# direction of its tree on its html element.
	my $tree = $self->_tree_of($page);
	if ($tree) {
		my $element = '<html' . $tree->attributes . '>';
		push @problems, "$page: does not carry $element"
		    unless index( $html, $element ) >= 0;
	}

	my ( undef, $name ) = split m{/}, $page, 2;
	push @problems,
	    $self->_check_head( $page, $html,
		$tree ? $self->_alternates( $page, $name ) : () );
	push @problems, $self->_check_chrome( $page, $html, $tree );
	push @problems, $self->_check_not_found( $page, $html )
	    if $page !~ m{/};

	$html = _without_alternates($html);

	# WEB-LINKS-4. The base of a page of the top level is the one
	# root-absolute href of the site. The check takes it out, so
	# every other root-absolute href still fails. Each relative
	# reference of the page then resolves from the base, which is
	# the site root, per WEB-LINKS-3.
	my $base;
	if ( $page !~ m{/} ) {
		my $element =
		      '<base href="'
		    . App::FuguWeb::escape_attr( $self->{config}->url_path )
		    . '">';
		my $at = index $html, $element;
		if ( $at < 0 ) {
			push @problems, "$page: does not carry $element";
		}
		else {
			substr( $html, $at, length $element ) = '';
			$base = '';
		}
	}

	push @problems, $self->_check_references( $page, $html, $base );

	return @problems;
}

# $self->_tree_of($page):
#	The language of the tree that holds one page of the output, or
#	undef for a page outside every tree. A page of a tree is one
#	segment below the path of the tree.
sub _tree_of ( $self, $page )
{
	my ( $path, $name, @deeper ) = split m{/}, $page;
	return if !defined $name || @deeper;

	my ($language) =
	    grep { $_->path eq $path } $self->{config}->languages;

	return $language;
}

# _is_alternate($attributes):
#	Report whether the attributes of a link element name a link of
#	WEB-CHROME-6: a canonical link or an alternate link.
sub _is_alternate ($attributes)
{
	return ( App::FuguWeb::attribute( $attributes, 'rel' ) // '' ) =~
	    m{\A(?:canonical|alternate)\z} ? 1 : 0;
}

# _without_alternates($html):
#	The page with no link of WEB-CHROME-6 in its head. The links
#	name the site by its url, and the check of the head holds each
#	one, so none of them is an external link. A link of the body is
#	no link of the head, so the check of the references holds it.
sub _without_alternates ($html)
{
	return $html =~ s{(<head>.*?</head>)}{
		my $head = $1;
		$head =~ s{(<link\b([^>]*)>)}{ _is_alternate($2) ? '' : $1 }ger
	}ser;
}

# $self->_alternates($path, $name):
#	The links of WEB-CHROME-6 that the head of the page at the path
#	takes, in order: the page itself, the page of the name in the
#	tree of each language, and the forward page. Each href is the
#	url of the site, then the path of the target page. The forward
#	page is the bare url, so its own path is empty, and each
#	language links its entry page, per WEB-TOP-2.
sub _alternates ( $self, $path, $name )
{
	my $url = $self->{config}->url;
	my $to  = sub ($path) {
		return App::FuguWeb::escape_attr( $url . $path );
	};

	return (
		'<link rel="canonical" href="' . $to->($path) . '">',
		(
			map {
				      '<link rel="alternate" hreflang="'
				    . $_->tag
				    . '" href="'
				    . $to->( $_->path . "/$name" ) . '">'
			} $self->{config}->languages
		),
		'<link rel="alternate" hreflang="x-default" href="'
		    . $to->('') . '">',
	);
}

# $self->_check_head($page, $html, @want):
#	Hold the links of WEB-CHROME-6 in the head of a page to the
#	links of @want. A tree page and the forward link a page in each
#	language, and the forward page. Any other page links none. Each
#	href is the url of the site, then the path of a page of the
#	inventory, or the bare url, per WEB-LINKS-5.
sub _check_head ( $self, $page, $html, @want )
{
	my $url = $self->{config}->url;

	my ($head) = $html =~ m{<head>(.*?)</head>}s;
	$head //= '';

	my @held;
	while ( $head =~ m{(<link\b([^>]*)>)}g ) {
		push @held, [ $1, $2 ] if _is_alternate($2);
	}

	my @problems;
	for my $link (@held) {
		my $href =
		    _unescape( App::FuguWeb::attribute( $link->[1], 'href' )
			    // '' );

		my $path =
		    index( $href, $url ) == 0
		    ? substr( $href, length $url )
		    : undef;
		push @problems,
		    "$page: $href is no URL of a page of the site"
		    unless defined $path
		    && (
			$path eq ''
			|| ( $path =~ m{\.html\z} && $self->{inventory}{$path} )
		    );
	}

	my %held = map { $_->[0] => 1 } @held;
	push @problems, map { "$page: the head does not carry $_" }
	    grep { !$held{$_} } @want;
	push @problems,
	      "$page: the head carries "
	    . scalar(@held)
	    . ' canonical and alternate links, and the page takes '
	    . scalar(@want)
	    unless @held == @want;

	return @problems;
}

# $self->_check_chrome($page, $html, $tree):
#	Hold the chrome of the body of a page: the header, the list of
#	the languages and the nav, per WEB-CHROME-2 to WEB-CHROME-5. A
#	tree page takes the words of its tree. A page outside every
#	tree takes the words of the default tree. _check_languages
#	holds the list of the languages. The top-level 404.html also
#	carries that list, per WEB-TOP-4. Each link of the chrome
#	resolves from the path of the page, per WEB-LINKS-3.
sub _check_chrome ( $self, $page, $html, $tree )
{
	my $words = $tree // $self->{config}->default_language;

	# The chrome is the page around the body fragment and the
	# footer fragment. The two fragments are the writer's own.
	my $chrome = $html;
	$chrome =~ s{(<main\b[^>]*>).*</main>}{$1</main>}s;
	$chrome =~ s{(<footer\b[^>]*>).*</footer>}{$1</footer>}s;

	my @problems;
	push @problems, "$page: the chrome carries a class"
	    if _values( $chrome, 'class' );
	push @problems, "$page: the chrome carries an hr"
	    if $chrome =~ m{<hr\b};

	# WEB-CHROME-5. Each word of the chrome of the body is the
	# text of a link. A word between two links is a separator, and
	# the sheet draws each one instead, per WEB-STYLE-9.
	my ($body) = $chrome =~ m{<body>(.*)</body>}s;
	my $loose = ( $body // '' ) =~ s{<a\b[^>]*>.*?</a>}{}gsr;
	$loose =~ s{<[^>]*>}{}g;
	push @problems, "$page: the chrome carries a text separator"
	    if $loose =~ /\S/;

	# WEB-CHROME-2. The site link comes before the list of the
	# languages.
	my ($header) = $chrome =~ m{<header\b[^>]*>(.*?)</header>}s;
	$header //= '';
	my ($lead) = $header =~ m{\A(.*?)(?:<ul\b|\z)}s;
	my ($site) = _links($lead);
	my $entry  = $words->path . '/' . $self->{config}->entry;
	push @problems, "$page: the header does not link $entry"
	    unless $site && _target( $page, $site->{href} ) eq $entry;
	push @problems, _current( $page, 'the site link', $site // {}, 0 );

	push @problems, $self->_check_languages( $page, $header, $tree );
	push @problems,
	    $self->_check_navigation( $page, $chrome, $words, $tree );

	return @problems;
}

# $self->_check_languages($page, $part, $tree):
#	Hold the list of the languages of WEB-CHROME-3 in one part of a
#	page. A tree page and a page of the top level of a site of more
#	than one language hold one item for each language, in the order
#	of the declaration. The text of each link is the name of the
#	language, and the tag is its lang and its hreflang.
#
#	On a tree page, each link goes to the same page in that
#	language, and the link of the language of the page is the
#	current one. A page of the top level belongs to no tree, so each
#	link goes to the entry page of its language, and no link is the
#	current one, per WEB-TOP-2 and WEB-TOP-4. Any other page holds
#	no item.
sub _check_languages ( $self, $page, $part, $tree )
{
	my $config    = $self->{config};
	my @languages = $config->languages;
	@languages = () unless ( $tree || $page !~ m{/} ) && @languages > 1;

	my ($list) = $part =~ m{<ul\b[^>]*>(.*?)</ul>}s;
	my @items = _items( $list // '' );

	my @problems;
	push @problems,
	      "$page: carries "
	    . scalar(@items)
	    . ' language links, and the page takes '
	    . scalar(@languages)
	    unless @items == @languages;

	my ( undef, $name ) = split m{/}, $page, 2;
	my $what = $tree ? 'the page' : 'the entry page';
	$name = $config->entry unless $tree;
	for my $i ( 0 .. $#languages ) {
		my $language = $languages[$i];
		my $link     = $items[$i] // {};
		my $tag      = $language->tag;
		my $text     = App::FuguWeb::encode(
			App::FuguWeb::escape_html( $language->name ) );

		push @problems, "$page: does not link $what in $tag"
		    unless _target( $page, $link->{href} ) eq $language->path
		    . "/$name"
		    && ( $link->{hreflang} // '' ) eq $tag
		    && ( $link->{lang}     // '' ) eq $tag
		    && ( $link->{text}     // '' ) eq $text;

		push @problems,
		    _current(
			$page, "the link to $tag",
			$link, $tree && $tag eq $tree->tag
		    );
	}

	return @problems;
}

# $self->_check_navigation($page, $chrome, $words, $tree):
#	Hold the nav of WEB-CHROME-4: one item for each nav entry of the
#	tree of the words, in the order of the description. A relative
#	href resolves from the page to the page of the tree that it
#	names. Any other href stands as the description writes it. The
#	entry whose path, with no query, resolves from the tree to the
#	page is the current one. A site with no nav entry carries no
#	nav.
sub _check_navigation ( $self, $page, $chrome, $words, $tree )
{
	my @entries = $self->{config}->nav( $words->tag );
	my ($nav) = $chrome =~ m{<nav\b[^>]*>(.*?)</nav>}s;

	unless (@entries) {
		return () unless defined $nav;
		return "$page: carries a nav, and the site has no nav entry";
	}

	my ($list) = ( $nav // '' ) =~ m{<ul\b[^>]*>(.*?)</ul>}s;
	my @items = _items( $list // '' );

	my @problems;
	push @problems,
	      "$page: carries "
	    . scalar(@items)
	    . ' navigation links, and the site has '
	    . scalar(@entries)
	    unless @items == @entries;

	for my $i ( 0 .. $#entries ) {
		my $href = $entries[$i]{href};
		my $link = $items[$i] // {};

		my $held =
		    $href =~ $UNCHANGED
		    ? _unescape( $link->{href} // '' ) eq $href
		    : _target( $page, $link->{href} ) eq
		    ( App::FuguWeb::resolve_ref( $words->path, $href ) // '' );
		push @problems,
		    "$page: does not carry the navigation entry $href"
		    unless $held;

		my ($path) = App::FuguWeb::ref_parts($href);
		my $current = $tree
		    && ( App::FuguWeb::resolve_ref( $words->path, $path )
			// '' ) eq $page;
		push @problems,
		    _current( $page, "the navigation entry $href",
			$link, $current );
	}

	return @problems;
}

# _current($page, $what, $link, $current):
#	The problem of a link that carries aria-current="page" and is
#	not the current one, or the reverse. The answer is empty when
#	the link agrees.
sub _current ( $page, $what, $link, $current )
{
	my $held = ( $link->{'aria-current'} // '' ) eq 'page';
	return () if $held == !!$current;

	return
	      "$page: $what "
	    . ( $current ? 'does not carry' : 'carries' )
	    . ' aria-current="page"';
}

# _links($html):
#	Each link of a part of a page, in order, as a hash reference of
#	the value of each of its attributes, by its name in lowercase,
#	with its text under the key text.
sub _links ($html)
{
	my @links;
	while ( $html =~ m{<a\b([^>]*)>(.*?)</a>}gs ) {
		my %link = ( text => $2 );
		App::FuguWeb::edit_attributes(
			$1,
			sub ( $attribute, $name, $value ) {
				$link{ lc $name } //= $value if defined $value;
				return $attribute;
			} );
		push @links, \%link;
	}

	return @links;
}

# _values($html, @names):
#	The value of each attribute of the names, in each start tag of
#	the HTML, in order. Each name is in lowercase. An attribute with
#	no value gives none.
sub _values ( $html, @names )
{
	my %want = map { $_ => 1 } @names;

	my @values;
	while ( $html =~ m{<[A-Za-z][^\s/>]*([^>]*)>}ga ) {
		App::FuguWeb::edit_attributes(
			$1,
			sub ( $attribute, $name, $value ) {
				push @values, $value
				    if defined $value && $want{ lc $name };
				return $attribute;
			} );
	}

	return @values;
}

# _references($html):
#	The value of each href and each src of the HTML, in order. An
#	empty value names no file, so it gives none.
sub _references ($html)
{
	return grep { length } _values( $html, qw(href src) );
}

# _items($list):
#	The link of each item of one list, in order. An item with no
#	link gives an empty hash reference.
sub _items ($list)
{
	return
	    map { ( _links($_) )[0] // {} } $list =~ m{<li\b[^>]*>(.*?)</li>}gs;
}

# _target($page, $href):
#	The path below the site root that one href of the chrome of a
#	page names, or an empty string when it names none.
sub _target ( $page, $href )
{
	return App::FuguWeb::resolve_ref( _dir($page),
		_unescape( $href // '' ) ) // '';
}

# $self->_check_forward:
#	Hold the top-level index.html to WEB-TOP-1 and WEB-TOP-2. It is
#	a page of the default language. Its head holds the charset, a
#	meta refresh to the entry page of the default tree, the title
#	and the links of WEB-CHROME-6, in that order, and nothing else.
#	The title is the site name of the default language. The
#	canonical link is the bare url, and the link of each language
#	goes to the entry page of that language.
#
#	On a site of more than one language, the body holds the list of
#	the languages, with no current link. On a site of one language,
#	it holds one link to the entry page, with the site name as its
#	text. The body holds no other reference, so the page loads
#	nothing, per D-01, and it carries no nav.
sub _check_forward ($self)
{
	my $page      = App::FuguWeb::FORWARD_PAGE;
	my $html      = $self->_read($page);
	my $config    = $self->{config};
	my $default   = $config->default_language;
	my @languages = $config->languages;
	my $entry     = $default->path . '/' . $config->entry;
	my $to        = App::FuguWeb::escape_attr($entry);
	my $site =
	    App::FuguWeb::encode( App::FuguWeb::escape_html( $default->site ) );

	my @problems;
	my $element = '<html' . $default->attributes . '>';
	push @problems, "$page: does not carry $element"
	    unless index( $html, $element ) >= 0;
	push @problems,
	    _check_parts( $page, $html, qw(charset refresh title links) );

	my ($head) = $html =~ m{<head>(.*?)</head>}s;
	push @problems,
	    "$page: does not forward to $to"
	    unless index( $head // '',
		qq{<meta http-equiv="refresh" content="0; url=$to">} ) >= 0;

	my ($title) = $html =~ m{<title>([^<]*)</title>};
	push @problems,
	    "$page: the title is not the site name of " . $default->tag
	    unless ( $title // '' ) eq $site;

	push @problems,
	    $self->_check_head( $page, $html,
		$self->_alternates( '', $config->entry ) );

	my ($body) = $html =~ m{<body>(.*)</body>}s;
	$body //= '';
	push @problems, "$page: carries a nav, and the forward takes none"
	    if $body =~ m{<nav\b};

	my $want = 1;
	if ( @languages > 1 ) {
		push @problems, $self->_check_languages( $page, $body, undef );
		$want = @languages;
	}
	else {
		my ($link) = _links($body);
		push @problems,
		    "$page: does not link $entry with the site name"
		    unless $link
		    && _target( $page, $link->{href} ) eq $entry
		    && $link->{text} eq $site;
	}

	my @refs = _references($body);
	push @problems,
	      "$page: the body holds "
	    . scalar(@refs)
	    . " references, and the forward takes $want"
	    unless @refs == $want;

	push @problems,
	    $self->_check_references( $page, _without_alternates($html),
		undef );

	return @problems;
}

# $self->_check_not_found($page, $html):
#	Hold the top-level 404.html to WEB-TOP-3 to WEB-TOP-6. Its head
#	holds the charset, the viewport, the base, the title and the
#	stylesheet link, in that order, and nothing else. It is a page
#	of the default language, and its title is the title of the
#	404.html of the default tree. The check of the chrome holds its
#	header, its list of the languages and its nav.
#
#	Its main carries no mark. It holds one section for each
#	language, in the order of the declaration, and nothing else.
#	Each section carries the marks of the language of its text, per
#	WEB-LANGUAGE-11. It holds the body of the 404.html of the tree
#	of its language, with no id, and with each relative link from
#	the site root. The check fits that body through
#	App::FuguWeb::Fragment, as the build does.
sub _check_not_found ( $self, $page, $html )
{
	my $config    = $self->{config};
	my $default   = $config->default_language;
	my $not_found = App::FuguWeb::NOT_FOUND_PAGE;

	my @problems = _check_parts( $page, $html,
		qw(charset viewport base title stylesheet) );

	my $element = '<html' . $default->attributes . '>';
	push @problems, "$page: does not carry $element"
	    unless index( $html, $element ) >= 0;

	my $source  = $default->path . "/$not_found";
	my ($title) = $html                 =~ m{<title>([^<]*)</title>};
	my ($want)  = $self->_read($source) =~ m{<title>([^<]*)</title>};
	push @problems, "$page: does not carry the title of $source"
	    if defined $want && ( $title // '' ) ne $want;

	my ($main) = $html =~ m{<main>(.*)</main>}s;
	return @problems, "$page: does not carry <main>" unless defined $main;

	my $at = 0;
	for my $language ( $config->languages ) {
		my $tree = $language->path . "/$not_found";

		my ($entry) = grep { $_->{file} eq $not_found }
		    $config->pages( $language->tag );
		my $text = $config->language(
			App::FuguWeb::Page::body_lang( $entry, $language ) );
		my $open = '<section' . $default->marks($text) . '>';

		my ( $gap, $held ) =
		    substr( $main, $at ) =~ m{\A(\n?)(<section\b[^>]*>)};
		unless ( defined $held ) {
			push @problems, "$page: holds no section for $tree";
			return @problems;
		}
		my $section = "$page: the section for $tree";
		push @problems, "$section does not open as $open"
		    unless $held eq $open;
		$at += length($gap) + length($held);

		# A tree page with no main gives no body to hold. The check
		# passes over its section, and holds each other section.
		my $body = $self->_main_of($tree);
		unless ( defined $body ) {
			push @problems, "$page: $tree does not carry <main>";
			my $end = index( $main, '</section>', $at );
			return @problems if $end < 0;
			$at = $end + length '</section>';
			next;
		}

		# The body of the tree page and the section each open with
		# the line break that App::FuguWeb::Page writes.
		my $fitted = App::FuguWeb::encode(
			App::FuguWeb::Fragment::not_found(
				App::FuguWeb::as_text($body),
				$language->path
			) ) . '</section>';
		unless ( substr( $main, $at, length $fitted ) eq $fitted ) {
			push @problems, "$section does not hold its body";
			return @problems;
		}
		$at += length $fitted;
	}

	push @problems,
	    "$page: the main holds more than one section for each language"
	    if substr( $main, $at ) =~ /\S/;

	return @problems;
}

# _check_parts($page, $html, @want):
#	Hold the head of a page to the parts of @want, in order, and to
#	nothing else.
sub _check_parts ( $page, $html, @want )
{
	my @held = _head_parts($html);
	return () if join( ' ', @held ) eq join( ' ', @want );

	return
	      "$page: the head holds "
	    . ( @held ? join( ', ', @held ) : 'nothing' )
	    . ', and the page takes '
	    . join( ', ', @want );
}

# _head_parts($html):
#	The part of each element of the head of a page, in order: the
#	charset, the viewport, the refresh, the base, the title, the
#	links of WEB-CHROME-6 as one part, and the stylesheet link. Any
#	other element names its own part.
sub _head_parts ($html)
{
	my ($head) = $html =~ m{<head>(.*?)</head>}s;
	$head //= '';

	my @parts;
	while ( $head =~ m{<([A-Za-z][^\s/>]*)([^>]*)>}ga ) {
		my ( $name, $attributes ) = ( lc $1, $2 );
		my $part = $name;
		if ( $name eq 'meta' ) {
			$part =
			    defined App::FuguWeb::attribute( $attributes,
				'charset' )
			    ? 'charset'
			    : lc(
				App::FuguWeb::attribute( $attributes,
					'http-equiv' )
				    // App::FuguWeb::attribute( $attributes,
					'name' ) // $name
			    );
		}
		elsif ( $name eq 'link' ) {
			$part =
			    _is_alternate($attributes)
			    ? 'links'
			    : lc( App::FuguWeb::attribute( $attributes, 'rel' )
				    // $name );
		}

		push @parts, $part
		    unless $part eq 'links' && @parts && $parts[-1] eq 'links';
	}

	return @parts;
}

# $self->_check_references($page, $html, $base):
#	Every href and src of one page. A relative reference resolves
#	against the directory of the page. It resolves against the base
#	when the page holds one, and the base is then the directory
#	below the site root that it names, per WEB-LINKS-3.
sub _check_references ( $self, $page, $html, $base )
{
	my @problems;

	for my $ref ( map { _unescape($_) } _references($html) ) {

		# The host may serve the site from a path below the
		# root, where a leading slash leaves the site entirely.
		if ( $ref =~ m{^/} ) {
			push @problems, "$page: $ref is root-absolute";
			next;
		}
		if ( $ref =~ m{^file:}i ) {
			push @problems, "$page: $ref is a file: URL";
			next;
		}
		if ( $ref =~ m{^https?://} ) {
			$self->{external}{$ref} = 1;
			next;
		}
		next if $ref =~ m{^(?:mailto|news|ftp):}i;

		# A browser reads a relative URL whose first segment
		# holds a colon as a scheme, so a page named
		# Fugu::Daemon.3p.html needs its './'.
		if ( $ref =~ /^[A-Za-z][A-Za-z0-9.+-]*:/ ) {
			push @problems, "$page: $ref reads as a URL scheme;"
			    . ' a local link needs its ./';
			next;
		}

		# A fragment alone names the page itself, or the base
		# when the page holds one. A base names a directory,
		# and a directory is no page.
		my ( $path, $fragment ) = App::FuguWeb::ref_parts($ref);
		if ( length $path ) {
			$path = App::FuguWeb::resolve_ref( $base // _dir($page),
				$path );
		}
		else {
			$path = defined $base ? undef : $page;
		}
		unless ( defined $path ) {
			push @problems, "$page: $ref names no page of the site";
			next;
		}

		# The target is a file of the inventory. A file that the
		# inventory does not name is a stray, and a directory is
		# no file.
		unless ( $self->{inventory}{$path}
			&& -f $self->{out} . "/$path" )
		{
			push @problems, "$page: $ref leads nowhere";
			next;
		}
		next unless defined $fragment && length $fragment;

		my %id = map { _unescape($_) => 1 }
		    _values( $self->_read($path), 'id' );
		push @problems, "$page: $ref has no such anchor"
		    unless $id{$fragment};
	}

	return @problems;
}

# _dir($page):
#	The directory of one page, as a path below the site root: a
#	language tree, a key directory, or the empty path of the top
#	level.
sub _dir ($page)
{
	return $page =~ s{/?[^/]*\z}{}r;
}

# _unescape($text):
#	Turn the four attribute entities back into their characters. A
#	reference is compared against a file name, and the file holds
#	the character and not the entity.
sub _unescape ($text)
{
	my $plain = $text;
	$plain =~ s/&lt;/</g;
	$plain =~ s/&gt;/>/g;
	$plain =~ s/&quot;/"/g;
	$plain =~ s/&amp;/&/g;

	return $plain;
}

# $self->_check_reachable:
#	Every page of each tree is reachable from the entry page of
#	that tree, per WEB-LANGUAGE-13. A page that no other page links
#	to declares itself unlinked, as a 404 page does: the host
#	serves that one for an unknown path.
#
#	The pages of the top level take no walk. The forward leads
#	into the default tree, and the top-level 404.html answers a
#	path that no page links to.
sub _check_reachable ($self)
{
	my $config = $self->{config};

	my %unlinked = map { $_->{file} => 1 }
	    grep { $_->{unlinked} } $config->pages;

	my @problems;
	for my $tree ( map { $_->path } $config->languages ) {
		my $entry = "$tree/" . $config->entry;
		unless ( -f $self->{out} . "/$entry" ) {
			push @problems, "$entry: the entry page is missing";
			next;
		}

		my $seen = $self->_walk( $tree, $entry );

		push @problems, map { "$tree/$_: no page links to it" }
		    grep { !$seen->{"$tree/$_"} && !$unlinked{$_} }
		    $config->page_names;
	}

	return @problems;
}

# $self->_walk($tree, $entry):
#	Every path that the tree reaches from its entry page, as a hash
#	reference. The tree is the path of the tree below the output.
#	The walk stays inside the tree, so a link into another tree
#	reaches no page of this one.
sub _walk ( $self, $tree, $entry )
{
	my %seen  = ( $entry => 1 );
	my @queue = ($entry);

	while ( my $page = shift @queue ) {
		next unless $page =~ /\.html$/;

		for my $ref ( map { _unescape($_) }
			_references( $self->_read($page) ) )
		{
			next if $ref =~ m{^[A-Za-z][A-Za-z0-9.+-]*:};

			my ($path) = App::FuguWeb::ref_parts($ref);
			next unless length $path;
			$path = App::FuguWeb::resolve_ref( _dir($page), $path );
			next unless defined $path;
			next unless App::FuguWeb::path_below( $path, $tree );

			next if $seen{$path}++;
			push @queue, $path;
		}
	}

	return \%seen;
}

1;
