#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Page: the chrome, the two byte separators, the
# escaping, and the optional footer fragment.
#
# The test builds each site in a File::Temp directory. It never reads
# the repository, so a change to web/ cannot break it.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use_ok('App::FuguWeb::Config');
use_ok('App::FuguWeb::Page');

# site($rc, %files):
#	Build a project with the description $rc and the named files
#	in its source directory. Return the loaded configuration.
sub site ( $rc, %files )
{
	my $root = tempdir( CLEANUP => 1 );
	open my $fh, '>', "$root/.fuguwebrc"
	    or die "Cannot write the description: $!";
	print {$fh} $rc;
	close $fh;

	make_path("$root/web");
	for my $name ( sort keys %files ) {
		open my $out, '>', "$root/web/$name"
		    or die "Cannot write $name: $!";
		print {$out} $files{$name};
		close $out;
	}

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	die "$reason\n" unless $config;

	return $config;
}

# render($page, $title, $fragment):
#	Write one page into a scratch file and return its bytes.
#	write is the one public method, so the test reads back what
#	it wrote.
sub render ( $page, $title, $fragment )
{
	my $path = tempdir( CLEANUP => 1 ) . '/page.html';
	$page->write( $path, $title, $fragment )
	    or die 'write failed';

	open my $fh, '<', $path or die "Cannot read $path: $!";
	binmode $fh;
	local $/ = undef;
	my $html = <$fh>;
	close $fh;

	return $html;
}

my $RC = <<'RC';
site = Example

nav "index.html" {
	label = Home
}

nav "manuals.html" {
	label = Manuals
}
RC

subtest 'the whole chrome, in order' => sub {
	my $page = App::FuguWeb::Page->new( config => site($RC) );
	my $html = render( $page, 'Install', "<h1>Install</h1>\n" );

	my $expected = <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Install \xe2\x80\x94 Example</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
<header class="banner"><a href="index.html">Example</a></header>
<nav>
<a href="index.html">Home</a> \xc2\xb7
<a href="manuals.html">Manuals</a>
</nav>
<hr>
<main>
<h1>Install</h1>
</main>
</body>
</html>
HTML

	is( $html, $expected, 'the page is byte for byte the chrome' );
};

subtest 'the two separators are the UTF-8 bytes' => sub {
	is( App::FuguWeb::Page::EM_DASH(),    "\xe2\x80\x94",
		'the em dash' );
	is( App::FuguWeb::Page::MIDDLE_DOT(), "\xc2\xb7",
		'the middle dot' );

	my $page = App::FuguWeb::Page->new( config => site($RC) );
	my $html = render( $page, 'Install', '' );

	like( $html, qr/<title>Install \xe2\x80\x94 Example<\/title>/,
		'an em dash separates the title from the site' );
	like( $html, qr/<\/a> \xc2\xb7\n/,
		'a middle dot separates two navigation entries' );
	unlike( $html, qr/<\/a> \xc2\xb7\n<\/nav>/,
		'the last entry carries no separator' );
};

subtest 'the title and the labels are escaped' => sub {
	my $config = site( <<'RC' );
site = A & B

nav "index.html" {
	label = <Home>
}
RC
	my $page = App::FuguWeb::Page->new( config => $config );
	my $html = render( $page, 'Tags < & >', '' );

	like( $html, qr/<title>Tags &lt; &amp; &gt; /,
		'the title is escaped' );
	like( $html, qr/&amp; B<\/title>/, 'the site name is escaped' );
	like( $html, qr/>&lt;Home&gt;<\/a>/, 'a navigation label is escaped' );

	# The shell chrome that this replaced substituted the title with
	# sed. A slash ended the substitution and an ampersand meant
	# "the whole match", so neither could ever reach a page.
	$html = render( $page, 'openhapd.conf(5) / 8', '' );
	like( $html, qr{<title>openhapd\.conf\(5\) / 8 },
		'a title may hold a slash' );
};

subtest 'a value that reaches an attribute is escaped' => sub {
	my $config = site( <<'RC' );
site  = Example
lang  = en" onload="x
entry = index.html?a&b

nav "search.html?q=1&r=2" {
	label = Search
}
RC
	my $page = App::FuguWeb::Page->new( config => $config );
	my $html = render( $page, 'Install', '' );

	# A quote in a value would end the attribute early, and
	# everything after it would become markup.
	like( $html, qr/<html lang="en&quot; onload=&quot;x">/,
		'the lang attribute is escaped' );
	unlike( $html, qr/onload="x"/, 'no attribute was injected' );

	# An ampersand is not markup, but it is not valid in an
	# attribute either, and the same escape covers both.
	like( $html, qr{href="index\.html\?a&amp;b"},
		'the header link is escaped' );
	like( $html, qr{href="search\.html\?q=1&amp;r=2"},
		'a navigation href is escaped' );
};

subtest 'the footer fragment is optional' => sub {
	my $page = App::FuguWeb::Page->new( config => site($RC) );
	my $html = render( $page, 'Install', '' );
	unlike( $html, qr/<footer>/, 'no fragment, no footer element' );
	like( $html, qr/<\/main>\n<\/body>/, 'and no rule before one' );

	$page = App::FuguWeb::Page->new(
		config => site( $RC, 'footer.body.html' => "<p>ISC.</p>\n" ) );
	$html = render( $page, 'Install', '' );
	like( $html, qr{</main>\n<hr>\n<footer>\n<p>ISC\.</p>\n</footer>\n},
		'the fragment becomes the footer' );
};

done_testing();
