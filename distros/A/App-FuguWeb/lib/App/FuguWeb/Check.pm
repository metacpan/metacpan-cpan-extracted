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
our $VERSION = '0.10.1';

use App::FuguWeb;
use App::FuguWeb::Keys;
use Fugu::File;

# App::FuguWeb::Check - what a built site must be true of.
#
# The checks are generic, so every project that uses the tool gets
# them. A project keeps only the assertions that are about its own
# content.
#
# The class never fetches a link. It collects the external ones and
# reports them, because the build and its checks touch no network.

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
#	manual. Each name is <code>/<page>.
sub pages ($self)
{
	my $config = $self->{config};
	my @names  = $config->page_names;

	return map {
		my $code = $_;
		map { "$code/$_" } @names
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
#	Each kind of page takes the checks of its own chrome, per
#	WEB-LANG-15. The forward takes the checks of its own shape.
sub run ($self)
{
	$self->{external} = {};

	my @problems = $self->_check_inventory;

	my $forward   = App::FuguWeb::FORWARD_PAGE;
	my @not_found = grep { $_ ne $forward } $self->{config}->top_pages;

	my @kinds = (
		( map { [ $_, 'tree' ] } $self->pages ),
		( map { [ $_, 'top' ] } @not_found ),
		( map { [ $_, 'keys' ] } $self->generated_pages ),
	);
	for my $each (@kinds) {
		my ( $page, $kind ) = @$each;
		next unless -f $self->{out} . "/$page";
		push @problems, $self->_check_page( $page, $kind );
	}

	push @problems, $self->_check_forward
	    if -f $self->{out} . "/$forward";
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

# The base element of the top-level copy of the 404 page, per
# WEB-LANG-9. Its href is the one root-absolute href of the site.
use constant BASE_ELEMENT => '<base href="/">';

# $self->_check_page($page, $kind):
#	Everything that one page must be true of. The kind is tree,
#	keys or top, as App::FuguWeb::Page names it.
sub _check_page ( $self, $page, $kind )
{
	my $html = Fugu::File->read( $self->{out} . "/$page" ) // '';
	my @problems;

	my ($title) = $html =~ m{<title>([^<]*)</title>};
	push @problems, "$page: has no title"
	    unless defined $title && length $title;

	# WEB-LANG-14. A tree page carries the code of its tree.
	if ( $kind eq 'tree' ) {
		my ($code) = split m{/}, $page;
		push @problems, qq{$page: does not carry lang="$code"}
		    unless index( $html, qq{<html lang="$code">} ) >= 0;
	}

	# WEB-LANG-15. The header link and each nav link take the form
	# of the kind of page. The chrome escapes an attribute on its
	# way out, so the search escapes it the same way.
	my $entry = $self->{config}->entry;
	push @problems,
	    "$page: the header does not link $entry"
	    unless index( $html,
		'<header><a href="' . _chrome( $kind, $entry ) . '">' ) >= 0;

	for my $each ( $self->{config}->nav ) {
		my $href = $each->{href};

		push @problems,
		    "$page: does not carry the navigation" . " entry $href"
		    unless
		    index( $html, 'href="' . _chrome( $kind, $href ) . '"' ) >=
		    0;
	}

	push @problems, $self->_check_languages( $page, $kind, $html );

	# The base href of the top-level copy of the 404 page is the
	# one root-absolute href that the site holds. The check takes
	# it out, so every other root-absolute href still fails.
	if ( $kind eq 'top' ) {
		my $at = index $html, BASE_ELEMENT;
		if ( $at < 0 ) {
			push @problems, "$page: does not carry " . BASE_ELEMENT;
		}
		else {
			substr( $html, $at, length BASE_ELEMENT ) = '';
		}
	}

	push @problems, $self->_check_references( $page, $html );

	return @problems;
}

# $self->_check_languages($page, $kind, $html):
#	Hold the language links of the chrome to WEB-LANG-7. A tree
#	page links the same page in each other language of the site,
#	with the code as the text and the hreflang of the link. No
#	other page carries a language link. The chrome ends where the
#	main element starts, so a link of the body is the writer's own.
sub _check_languages ( $self, $page, $kind, $html )
{
	my ($chrome) = $html =~ m{\A(.*?)<main\b}s;
	$chrome //= $html;

	my ( $code, $name ) = split m{/}, $page, 2;
	my @others =
	    $kind eq 'tree'
	    ? grep { $_ ne $code } $self->{config}->languages
	    : ();

	my @problems;
	for my $other (@others) {
		my $link =
		      qq{<a href="../$other/}
		    . App::FuguWeb::escape_attr($name)
		    . qq{" hreflang="$other">$other</a>};
		push @problems, "$page: does not link the page in $other"
		    unless index( $chrome, $link ) >= 0;
	}

	my $held = () = $chrome =~ m{\bhreflang="}g;
	push @problems,
	    "$page: carries $held language links, and the page takes "
	    . scalar(@others)
	    unless $held == @others;

	return @problems;
}

# $self->_check_forward:
#	Hold the top-level index.html to the shape of WEB-LANG-8: a
#	meta refresh to the entry page of the default tree, and one
#	link to that page as its one reference. The page loads nothing
#	and carries no nav.
sub _check_forward ($self)
{
	my $page = App::FuguWeb::FORWARD_PAGE;
	my $html = Fugu::File->read( $self->{out} . "/$page" ) // '';
	my $to   = App::FuguWeb::escape_attr(
		App::FuguWeb::DEFAULT_LANGUAGE . '/' . $self->{config}->entry );

	my @problems;

	push @problems, "$page: does not forward to $to"
	    unless
	    index( $html, qq{<meta http-equiv="refresh" content="0; url=$to">} )
	    >= 0;

	# One reference, and that one the link to the entry page. A
	# second href or any src is a thing that the page loads, or a
	# second way out of it.
	my @refs = $html =~ m{(?:href|src)="([^"]+)"}g;
	push @problems, "$page: holds a reference other than one link to $to"
	    unless @refs == 1
	    && index( $html, qq{<a href="$to">} ) >= 0;

	push @problems, "$page: carries a nav, and the forward takes none"
	    if $html =~ m{<nav\b};

	push @problems, $self->_check_references( $page, $html );

	return @problems;
}

# _chrome($kind, $href):
#	The form of one link of the chrome on a page of the kind, as
#	App::FuguWeb::Page writes it, per WEB-LANG-15. A tree page
#	takes <page>, the key page ../en/<page>, and the top-level copy
#	of the 404 page en/<page>. An absolute URL and a fragment pass
#	unchanged.
sub _chrome ( $kind, $href )
{
	my $written = App::FuguWeb::escape_attr($href);
	return $written
	    if $href =~ m{\A(?:[A-Za-z][A-Za-z0-9.+-]*:|/|\#)};

	my $lang = App::FuguWeb::DEFAULT_LANGUAGE;
	return "../$lang/$written" if $kind eq 'keys';
	return "$lang/$written"    if $kind eq 'top';

	return $written;
}

# $self->_check_references($page, $html):
#	Every href and src of one page.
sub _check_references ( $self, $page, $html )
{
	my @problems;

	for my $ref ( map { _unescape($_) }
		$html =~ m{(?:href|src)="([^"]+)"}g )
	{

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

		my ( $path, $fragment ) = split /#/, $ref, 2;
		if ( defined $path && length $path ) {
			$path = _resolve( $page, $path );
			unless ( defined $path ) {
				push @problems,
				    "$page: $ref names no page of the site";
				next;
			}
		}
		else {
			$path = $page;
		}

		unless ( -e $self->{out} . "/$path" ) {
			push @problems, "$page: $ref leads nowhere";
			next;
		}
		next unless defined $fragment && length $fragment;

		my $target = Fugu::File->read( $self->{out} . "/$path" ) // '';
		push @problems, "$page: $ref has no such anchor"
		    unless $target =~ /\bid="\Q$fragment\E"/;
	}

	return @problems;
}

# _resolve($page, $ref):
#	One relative reference of a page, as a path below the output
#	directory. A reference is relative to the directory of its own
#	page: a language tree, a key directory, or the top level.
sub _resolve ( $page, $ref )
{
	my @parts = split m{/}, $page;
	pop @parts;

	for my $step ( split m{/}, $ref, -1 ) {
		next if $step eq '' || $step eq '.';
		if ( $step eq '..' ) {

			# A step above the site root names no file of
			# the output. A pop of an empty list does
			# nothing, so the reference would clamp to the
			# root and read like a link that resolves.
			return unless @parts;
			pop @parts;
			next;
		}
		push @parts, $step;
	}

	# A reference of './' names the directory of its own page, and
	# a directory is no page of a site. An empty answer also reads
	# as false in the walk of the reachability check. The walk
	# would then stop at the first page that holds one.
	return unless @parts;

	return join '/', @parts;
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
#	that tree, per WEB-LANG-14. A page that no other page links to
#	declares itself unlinked, as a 404 page does: the host serves
#	that one for an unknown path.
#
#	The pages of the top level take no walk. The forward leads
#	into the default tree, and the copy of the 404 page answers a
#	path that no page links to.
sub _check_reachable ($self)
{
	my $config = $self->{config};

	my %unlinked = map { $_->{file} => 1 }
	    grep { $_->{unlinked} } $config->pages;

	my @problems;
	for my $code ( $config->languages ) {
		my $entry = "$code/" . $config->entry;
		unless ( -f $self->{out} . "/$entry" ) {
			push @problems, "$entry: the entry page is missing";
			next;
		}

		my $seen = $self->_walk( $code, $entry );

		push @problems, map { "$code/$_: no page links to it" }
		    grep { !$seen->{"$code/$_"} && !$unlinked{$_} }
		    $config->page_names;
	}

	return @problems;
}

# $self->_walk($code, $entry):
#	Every path that the tree of the code reaches from its entry
#	page, as a hash reference. The walk stays inside the tree, so a
#	link into another tree reaches no page of this one.
sub _walk ( $self, $code, $entry )
{
	my %seen  = ( $entry => 1 );
	my @queue = ($entry);

	while ( my $page = shift @queue ) {
		next unless $page =~ /\.html$/;

		my $html = Fugu::File->read( $self->{out} . "/$page" ) // '';
		for my $ref ( map { _unescape($_) }
			$html =~ m{(?:href|src)="([^"]+)"}g )
		{
			next if $ref =~ m{^[A-Za-z][A-Za-z0-9.+-]*:};

			my ($path) = split /#/, $ref, 2;
			next unless defined $path && length $path;
			$path = _resolve( $page, $path );
			next unless defined $path;
			next unless App::FuguWeb::path_below( $path, $code );

			next if $seen{$path}++;
			push @queue, $path;
		}
	}

	return \%seen;
}

1;
