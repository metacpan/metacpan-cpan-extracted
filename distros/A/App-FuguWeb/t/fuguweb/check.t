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

# The pages of a site that passes every check. Each subtest starts
# from this and breaks exactly one thing.
my %GOOD = (
	'index.html' => <<'HTML',
<title>Home &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<a href="./other.html">Other</a>
<a href="./other.html#here">The anchor</a>
HTML
	'404.html' => <<'HTML',
<title>Not found &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
HTML
	'other.html' => <<'HTML',
<title>Other &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<h2 id="here">Here</h2>
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
	make_path($out);

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
	my @problems = built( 'other.html' => undef )->run;
	like( join( "\n", @problems ), qr/other\.html: missing from the output/,
		'a missing page' );

	@problems = built( 'other.html' => '' )->run;
	like( join( "\n", @problems ), qr/other\.html: empty/,
		'an empty page' );
};

subtest 'a page with no title' => sub {
	my @problems = built( 'other.html' =>
		    "<a href=\"index.html\">Home</a>\n"
		    . "<a href=\"https://example.org/\">Elsewhere</a>\n"
		    . "<h2 id=\"here\">Here</h2>\n" )->run;
	like( join( "\n", @problems ), qr/other\.html: has no title/,
		'no title' );
};

subtest 'a page that drops the navigation' => sub {
	my @problems = built( 'other.html' => <<'HTML' )->run;
<title>Other &#8212; Example</title>
<a href="index.html">Home</a>
<h2 id="here">Here</h2>
HTML
	my $expected = 'other.html: does not carry the navigation entry'
	    . ' https://example.org/';
	like( join( "\n", @problems ), qr/\Q$expected\E/,
		'the missing entry is named' );
};

subtest 'a link that leads nowhere, or to no such anchor' => sub {
	my @problems = built( 'other.html' => <<'HTML' )->run;
<title>Other &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<a href="./gone.html">Gone</a>
<h2 id="here">Here</h2>
HTML
	like( join( "\n", @problems ),
		qr{other\.html: \./gone\.html leads nowhere}, 'a dead link' );

	@problems = built( 'other.html' => <<'HTML' )->run;
<title>Other &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<a href="./index.html#absent">Absent</a>
<h2 id="here">Here</h2>
HTML
	like( join( "\n", @problems ),
		qr{other\.html: \./index\.html#absent has no such anchor},
		'a dead fragment' );
};

subtest 'a reference that leaves the site' => sub {
	my @problems = built( 'other.html' => <<'HTML' )->run;
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
	like( $joined, qr{other\.html: /index\.html is root-absolute},
		'a root-absolute reference' );
	like( $joined, qr{is a file: URL}, 'a file: URL' );
};

subtest 'a local link that reads as a URL scheme' => sub {
	my @problems = built( 'other.html' => <<'HTML' )->run;
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
	my @problems = built( 'other.html' => <<'HTML' )->run;
<title>Other &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
<a class="Xr" href="./gone.1.html">gone(1)</a>
<h2 id="here">Here</h2>
HTML
	my $joined = join "\n", @problems;
	like( $joined, qr{other\.html: \./gone\.1\.html leads nowhere},
		'a local .Xr that leads nowhere' );
};

subtest 'a page that nothing links to' => sub {
	# index.html no longer links to other.html. 404.html is
	# unlinked on purpose, so it must not be reported.
	my @problems = built( 'index.html' => <<'HTML' )->run;
<title>Home &#8212; Example</title>
<a href="index.html">Home</a>
<a href="https://example.org/">Elsewhere</a>
HTML
	my $joined = join "\n", @problems;

	like( $joined, qr{other\.html: no page links to it},
		'the unreachable page' );
	unlike( $joined, qr{404\.html: no page links to it},
		'a page marked unlinked is not reported' );
};

subtest 'what is not a problem stays not a problem' => sub {
	# The two skip rules. Without a case that exercises each of
	# them, a check that lost one would report a false positive and
	# only the real site would notice.
	my @problems = built( 'other.html' => <<'HTML' )->run;
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
};

done_testing();
