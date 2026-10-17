#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Check: one problem for each thing that can be wrong
# with a built site.
#
# The test builds a small site in a File::Temp directory and then
# breaks it, one way at a time. It never reads the repository;
# t/web/site.t covers the real site.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use_ok('App::FuguWeb::Check');
use_ok('App::FuguWeb::Config');

my $RC = <<'RC';
site       = Example
source_dir = web
out_dir    = out

nav "index.html" {
	label = Home
}

nav "https://example.org/" {
	label = Elsewhere
}

page "index.html" {
	title = Home
	body  = index.body.html
}

page "404.html" {
	title    = Not found
	body     = 404.body.html
	unlinked = yes
}
RC

# The chrome of a page of the tree of en: the language of the tree,
# the stylesheet one step up, and the header link by name. Each page
# of the tree below starts with it.
my $TREE = <<'HTML';
<html lang="en">
<link rel="stylesheet" href="../style.css">
<header><a href="index.html">Example</a></header>
HTML

# The pages of a site that passes every check. Each subtest starts
# from this and breaks exactly one thing.
my %GOOD = (
	'en/index.html' => $TREE . <<'HTML',
<title>Home &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<a href="./other.html">Other</a>
<a href="./other.html#here">The anchor</a>
HTML
	'en/404.html' => $TREE . <<'HTML',
<title>Not found &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
HTML
	'en/other.html' => $TREE . <<'HTML',
<title>Other &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<h2 id="here">Here</h2>
HTML

	# The copy of the 404 page at the top level. Its base is the
	# one root-absolute href of the site, and its chrome links the
	# default tree.
	'404.html' => <<'HTML',
<html lang="en">
<base href="/">
<title>Not found &#8212; Example</title>
<link rel="stylesheet" href="style.css">
<header><a href="en/index.html">Example</a></header>
<a href="en/index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
HTML

	# The forward of the top level, per WEB-LANG-8.
	'index.html' => <<'HTML',
<html lang="en">
<meta http-equiv="refresh" content="0; url=en/index.html">
<title>Example</title>
<p><a href="en/index.html">Example</a></p>
HTML
	'style.css'  => "body { color: black }\n",
	'robots.txt' => "User-agent: *\n",
);

# built(%override):
#	Build a site on disk, with the named pages replaced or added,
#	and return a Check over it. A value of undef removes the file.
sub built (%override)
{
	my $root = tempdir( CLEANUP => 1 );
	make_path("$root/web");

	for my $pair (
		[ '.fuguwebrc',             $RC ],
		[ 'web/index.body.html',    "<h1>Home</h1>\n" ],
		[ 'web/404.body.html',      "<h1>Not found</h1>\n" ],
		[ 'web/robots.txt',         "User-agent: *\n" ] )
	{
		open my $fh, '>', "$root/$pair->[0]"
		    or die "Cannot write $pair->[0]: $!";
		print {$fh} $pair->[1];
		close $fh;
	}

	# A third page that the description does not name. It is a
	# manual page as far as the checks are concerned, so the
	# description has to know about it: this test uses a page block
	# instead, appended here.
	open my $rc, '>>', "$root/.fuguwebrc"
	    or die "Cannot append to the description: $!";
	print {$rc} <<'PAGE';

page "other.html" {
	title = Other
	body  = other.body.html
}
PAGE
	close $rc;

	open my $body, '>', "$root/web/other.body.html"
	    or die "Cannot write the fragment: $!";
	print {$body} "<h2 id=\"here\">Here</h2>\n";
	close $body;

	my $out = "$root/out";
	make_path("$out/en");

	my %page = ( %GOOD, %override );
	for my $name ( sort keys %page ) {
		unless ( defined $page{$name} ) {
			unlink "$out/$name";
			next;
		}

		open my $fh, '>', "$out/$name"
		    or die "Cannot write $name: $!";
		print {$fh} $page{$name};
		close $fh;
	}

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	die "$reason\n" unless $config;

	return App::FuguWeb::Check->new( config => $config, out => $out );
}

subtest 'a site that is good gives no problem' => sub {
	my $check    = built();
	my @problems = $check->run;

	is( scalar @problems, 0, 'no problem' ) or diag join "\n", @problems;

	is_deeply( [ $check->external ], ['https://example.org/'],
		'the external link is collected and not fetched' );
};

subtest 'a page that is missing or empty' => sub {
	my @problems = built( 'en/other.html' => undef )->run;
	like( join( "\n", @problems ),
		qr{en/other\.html: missing from the output}, 'a missing page' );

	@problems = built( 'en/other.html' => '' )->run;
	like( join( "\n", @problems ), qr{en/other\.html: empty},
		'an empty page' );

	@problems = built( 'index.html' => undef )->run;
	like( join( "\n", @problems ), qr{^index\.html: missing from the output}m,
		'a missing forward' );

	@problems = built( '404.html' => undef )->run;
	like( join( "\n", @problems ), qr{^404\.html: missing from the output}m,
		'a missing copy of the 404 page' );
};

subtest 'a page with no title' => sub {
	my @problems = built( 'en/other.html' => $TREE
		    . "<a href=\"index.html\">Home</a>\n"
		    . "<a href=\"https://example.org/\">Elsewhere</a>\n"
		    . "<h2 id=\"here\">Here</h2>\n" )->run;
	like( join( "\n", @problems ), qr{en/other\.html: has no title},
		'no title' );
};

subtest 'a page that drops the navigation' => sub {
	my @problems = built( 'en/other.html' => $TREE . <<'HTML' )->run;
<title>Other &#8212; Example</title>
<a href="index.html">Home</a>
<h2 id="here">Here</h2>
HTML
	my $expected = 'en/other.html: does not carry the navigation entry'
	    . ' https://example.org/';
	like( join( "\n", @problems ), qr/\Q$expected\E/,
		'the missing entry is named' );
};

subtest 'a tree page of another language' => sub {
	# WEB-LANG-14. A tree page carries the code of its tree.
	my @problems = built( 'en/other.html' => <<'HTML' )->run;
<html lang="sv">
<link rel="stylesheet" href="../style.css">
<header><a href="index.html">Example</a></header>
<title>Other &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<h2 id="here">Here</h2>
HTML
	is_deeply( \@problems, ['en/other.html: does not carry lang="en"'],
		'the page is held to the language of its tree' );
};

subtest 'each kind of page takes one form of the chrome' => sub {
	# WEB-LANG-15. A tree page takes <page>, the key page
	# ../en/<page>, and the top-level copy of the 404 page
	# en/<page>. An absolute URL passes unchanged on each.
	my %form = (
		tree => 'index.html',
		keys => '../en/index.html',
		top  => 'en/index.html',
	);
	for my $kind ( sort keys %form ) {
		is( App::FuguWeb::Check::_chrome( $kind, 'index.html' ),
			$form{$kind}, "the form of a $kind page" );
		is( App::FuguWeb::Check::_chrome( $kind, 'https://example.org/' ),
			'https://example.org/',
			"and an absolute URL of a $kind page" );
	}

	# A tree page that links the default tree from outside it.
	my @problems = built( 'en/other.html' => <<'HTML' )->run;
<html lang="en">
<link rel="stylesheet" href="../style.css">
<header><a href="../en/index.html">Example</a></header>
<title>Other &#8212; Example</title>
<a href="../en/index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<h2 id="here">Here</h2>
HTML
	is_deeply(
		\@problems,
		[
			'en/other.html: the header does not link index.html',
			'en/other.html: does not carry the navigation entry'
			    . ' index.html'
		],
		'a tree page names each page of its tree by name'
	);

	# The copy of the 404 page with the links of a tree page. The
	# base makes each one resolve from the root, so each one would
	# name a page of the top level.
	@problems = built( '404.html' => <<'HTML' )->run;
<html lang="en">
<base href="/">
<title>Not found &#8212; Example</title>
<link rel="stylesheet" href="style.css">
<header><a href="index.html">Example</a></header>
<a href="index.html">Home</a>
<a href="en/https://example.org/">Elsewhere</a>
HTML
	my $joined = join "\n", @problems;
	like( $joined, qr{^404\.html: the header does not link index\.html}m,
		'the top-level copy takes en/ in front of the header link' );
	like(
		$joined,
		qr{^404\.html: does not carry the navigation entry index\.html}m,
		'and in front of a nav link'
	);
	like(
		$joined,
qr{^404\.html: does not carry the navigation entry https://example\.org/}m,
		'and an absolute nav URL passes unchanged'
	);
};

subtest 'a language link that the site does not hold' => sub {
	# WEB-LANG-7. A site of one language carries no language link.
	# The site of two languages is in site.t, which builds it.
	my @problems = built( 'en/other.html' => $GOOD{'en/other.html'}
		    . qq{<a href="../de/other.html" hreflang="de">de</a>\n} )->run;
	like(
		join( "\n", @problems ),
qr{^en/other\.html: carries 1 language links, and the page takes 0$}m,
		'a tree page with a link to a language the site does not hold'
	);

	# The chrome ends where the main element starts. A link of the
	# body is the writer's own.
	@problems = built( 'en/other.html' => $GOOD{'en/other.html'}
		    . "<main>\n"
		    . qq{<a href="https://example.org/de/" hreflang="de">de</a>\n} )
	    ->run;
	is( scalar @problems, 0, 'a link of the body is no language link' )
	    or diag join "\n", @problems;
};

subtest 'the base href is the one root-absolute href' => sub {
	# WEB-LANG-15. The top-level copy of the 404 page carries the
	# base, and no other page and no other href may be rooted.
	my @problems = built( '404.html' => <<'HTML' )->run;
<html lang="en">
<title>Not found &#8212; Example</title>
<link rel="stylesheet" href="style.css">
<header><a href="en/index.html">Example</a></header>
<a href="en/index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
HTML
	is_deeply( \@problems, ['404.html: does not carry <base href="/">'],
		'the copy needs its base' );

	@problems = built( '404.html' => <<'HTML' )->run;
<html lang="en">
<base href="/">
<title>Not found &#8212; Example</title>
<link rel="stylesheet" href="style.css">
<header><a href="en/index.html">Example</a></header>
<a href="en/index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<a href="/en/index.html">Rooted</a>
HTML
	is_deeply( \@problems, ['404.html: /en/index.html is root-absolute'],
		'a second root-absolute href of the copy fails' );

	@problems = built( 'en/other.html' => "<base href=\"/\">\n"
		    . $GOOD{'en/other.html'} )->run;
	is_deeply( \@problems, ['en/other.html: / is root-absolute'],
		'and a base on a tree page fails' );
};

subtest 'the forward takes one shape' => sub {
	# WEB-LANG-8. A meta refresh, one link, and nothing loaded.
	my @problems = built( 'index.html' => <<'HTML' )->run;
<html lang="en">
<title>Example</title>
<p><a href="en/index.html">Example</a></p>
HTML
	is_deeply( \@problems, ['index.html: does not forward to en/index.html'],
		'a forward with no refresh' );

	@problems = built( 'index.html' => <<'HTML' )->run;
<html lang="en">
<meta http-equiv="refresh" content="0; url=en/index.html">
<title>Example</title>
<link rel="stylesheet" href="style.css">
<p><a href="en/index.html">Example</a></p>
HTML
	is_deeply(
		\@problems,
		[
			'index.html: holds a reference other than one link to'
			    . ' en/index.html'
		],
		'a forward that loads a stylesheet'
	);

	@problems = built( 'index.html' => <<'HTML' )->run;
<html lang="en">
<meta http-equiv="refresh" content="0; url=en/index.html">
<title>Example</title>
<nav>
</nav>
<p><a href="en/index.html">Example</a></p>
HTML
	is_deeply(
		\@problems,
		['index.html: carries a nav, and the forward takes none'],
		'a forward with a nav'
	);
};

subtest 'a link that leads nowhere, or to no such anchor' => sub {
	my @problems = built( 'en/other.html' => $TREE . <<'HTML' )->run;
<title>Other &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<a href="./gone.html">Gone</a>
<h2 id="here">Here</h2>
HTML
	like( join( "\n", @problems ),
		qr{en/other\.html: \./gone\.html leads nowhere}, 'a dead link' );

	@problems = built( 'en/other.html' => $TREE . <<'HTML' )->run;
<title>Other &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<a href="./index.html#absent">Absent</a>
<h2 id="here">Here</h2>
HTML
	like( join( "\n", @problems ),
		qr{en/other\.html: \./index\.html#absent has no such anchor},
		'a dead fragment' );
};

subtest 'a reference that leaves the site' => sub {
	my @problems = built( 'en/other.html' => $TREE . <<'HTML' )->run;
<title>Other &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<a href="/index.html">Rooted</a>
<a href="file:///etc/passwd">Local</a>
<h2 id="here">Here</h2>
HTML
	my $joined = join "\n", @problems;

	# The host may serve the site from a path below the root, where
	# a leading slash leaves the site entirely.
	like( $joined, qr{en/other\.html: /index\.html is root-absolute},
		'a root-absolute reference' );
	like( $joined, qr{is a file: URL}, 'a file: URL' );
};

subtest 'a local link that reads as a URL scheme' => sub {
	my @problems = built( 'en/other.html' => $TREE . <<'HTML' )->run;
<title>Other &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<a href="Thing::Depot.3p.html">A module</a>
<h2 id="here">Here</h2>
HTML

	# A browser reads a relative URL whose first segment holds a
	# colon as a scheme, so the link above asks for thing:.
	like(
		join( "\n", @problems ),
		qr{Thing::Depot\.3p\.html reads as a URL scheme},
		'the missing ./ is named'
	);
};

subtest 'a cross-reference that dangles' => sub {
	# A local .Xr link is a reference like any other, and the
	# reference check catches it.
	my @problems = built( 'en/other.html' => $TREE . <<'HTML' )->run;
<title>Other &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<a class="Xr" href="./gone.1.html">gone(1)</a>
<h2 id="here">Here</h2>
HTML
	my $joined = join "\n", @problems;
	like( $joined, qr{en/other\.html: \./gone\.1\.html leads nowhere},
		'a local .Xr that leads nowhere' );
};

subtest 'a page that nothing links to' => sub {
	# en/index.html no longer links to other.html. 404.html is
	# unlinked on purpose, so it must not be reported.
	my @problems = built( 'en/index.html' => $TREE . <<'HTML' )->run;
<title>Home &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
HTML
	my $joined = join "\n", @problems;

	like( $joined, qr{en/other\.html: no page links to it},
		'the unreachable page' );
	unlike( $joined, qr{404\.html: no page links to it},
		'a page marked unlinked is not reported' );

	# WEB-LANG-14. The walk starts at the entry page of the tree,
	# and never at a page of the top level. A link of the forward
	# or of the copy of the 404 page reaches no page of the tree.
	@problems = built(
		'en/index.html' => $TREE . <<'HTML',
<title>Home &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
HTML
		'404.html' => $GOOD{'404.html'} . <<'HTML',
<a href="en/other.html">Other</a>
HTML
	)->run;
	like( join( "\n", @problems ), qr{en/other\.html: no page links to it},
		'a link of the top level does not count' );

	# The walk stays inside the tree. A link out of the tree to the
	# top level reaches no page of the tree through it.
	@problems = built(
		'en/index.html' => $TREE . <<'HTML',
<title>Home &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<a href="../404.html">Out</a>
HTML
		'404.html' => $GOOD{'404.html'} . <<'HTML',
<a href="en/other.html">Other</a>
HTML
	)->run;
	is_deeply( \@problems, ['en/other.html: no page links to it'],
		'and neither does a page of the top level on the way' );

	@problems = built( 'en/index.html' => undef )->run;
	like( join( "\n", @problems ), qr{en/index\.html: the entry page is missing},
		'the entry page of the tree is missing' );
};

subtest 'what is not a problem stays not a problem' => sub {
	# The two skip rules. Without a case that exercises each of
	# them, a check that lost one would report a false positive and
	# only the real site would notice.
	my @problems = built( 'en/other.html' => $TREE . <<'HTML' )->run;
<title>Other &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<a href="mailto:hi@example.org">Mail</a>
<a class="Xr" href="https://man.openbsd.org/rc.8">rc(8)</a>
<h2 id="here">Here</h2>
HTML
	my $joined = join "\n", @problems;

	is( scalar @problems, 0, 'no problem' ) or diag $joined;
	unlike( $joined, qr/mailto/,
		'a mailto: link is not a dead local link' );
	unlike( $joined, qr/man\.openbsd\.org/,
		'a cross-reference that left for the host does not dangle' );
};

subtest 'a stray file in the output' => sub {
	my @problems = built( 'index.html~' => "an editor backup\n" )->run;
	like( join( "\n", @problems ),
		qr{index\.html~: in the output but not in the site},
		'the stray file is named' );

	# A page of the old flat layout is a stray file of the new one.
	@problems = built( 'other.html' => $GOOD{'en/other.html'} )->run;
	is_deeply( \@problems, ['other.html: in the output but not in the site'],
		'a page at the top level is named' );
};

done_testing();
