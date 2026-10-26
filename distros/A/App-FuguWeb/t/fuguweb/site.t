#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Site: a small site builds into the tree of its
# language, holds what the description names and nothing else, drops
# the staging directory, and builds a second time to the same bytes.
# A site of several languages builds one tree for each, below the path
# of its tag, from the sources of each language.
#
# The test builds its site in a File::Temp directory. It never reads
# the repository; t/web/site.t covers the real site.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Find ();
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

# have($tool):
#	Report whether the program is on the path.
sub have ($tool)
{
	return system("command -v $tool >/dev/null 2>&1") == 0;
}

# The whole file drives the renderers, so the skip comes before the
# first assertion. A plan that arrives after one is not a plan.
plan skip_all => 'mandoc not found'  unless have('mandoc');
plan skip_all => 'lowdown not found' unless have('lowdown');
plan skip_all => 'pod2man not found' unless have('pod2man');

use_ok('App::FuguWeb::Check');
use_ok('App::FuguWeb::Config');
use_ok('App::FuguWeb::Render');
use_ok('App::FuguWeb::Site');
use_ok('Fugu::Log');

my $RC = <<'RC';
site       = Example
url        = https://example.org/
footer     = footer.body.html
source_dir = web
out_dir    = out

nav "index.html" {
	label = Home
}

page "index.html" {
	title = Home
	body  = index.body.html
}

page "readme.html" {
	title    = Readme
	markdown = README.md
}

page "manuals.html" {
	title = Manuals
	index = yes
}

page "404.html" {
	title    = Not found
	body     = 404.body.html
	unlinked = yes
}

manuals manuals {
	heading = Manuals
	dir     = man
}

modules modules {
	heading = Modules
	dir     = lib/Thing
}
RC

# project(%more):
#	Write a whole small project, and each more file, and return its
#	root. A more file of the description is added to its end.
sub project (%more)
{
	my $root = tempdir( CLEANUP => 1 );

	my %file = (
		'.fuguwebrc'          => $RC,
		'README.md'           => "# Readme\n\nA paragraph.\n",
		'web/index.body.html' => "<h1>Home</h1>\n",
		'web/404.body.html'   =>
		    qq{<h1>Not found</h1>\n<p><a href="index.html">Home</a></p>\n},
		'web/footer.body.html' => "<p>ISC.</p>\n",
		'web/robots.txt'      => "User-agent: *\n",

		# Not an asset: a note for the maintainers, not content
		'web/CLAUDE.md' => "# web/\n\nNotes.\n",

		'man/tool.1' => <<'MDOC',
.Dd $Mdocdate: July 27 2026 $
.Dt TOOL 1
.Os
.Sh NAME
.Nm tool
.Nd a tool
.Sh DESCRIPTION
Words.
MDOC
		'lib/Thing/Depot.pod' => <<'POD',
=head1 NAME

Thing::Depot - the persistence contract

=head1 DESCRIPTION

Words.
POD
	);
	for my $relative ( sort keys %more ) {
		$file{$relative} =
		    $relative eq '.fuguwebrc'
		    ? $file{$relative} . $more{$relative}
		    : $more{$relative};
	}

	for my $relative ( sort keys %file ) {
		my $path = "$root/$relative";
		make_path( $path =~ s{/[^/]+$}{}r );

		open my $fh, '>', $path or die "Cannot write $path: $!";
		print {$fh} $file{$relative};
		close $fh;
	}

	return $root;
}

# site($root, $out):
#	A site over the project, with a quiet log.
sub site ( $root, $out )
{
	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	die "$reason\n" unless $config;

	return App::FuguWeb::Site->new(
		config => $config,
		out    => $out,
		log    => Fugu::Log->new( mode => Fugu::Log::MODE_QUIET() ),
	);
}

# said($root, $out, $command):
#	Run one command of a site over the project into the target, and
#	return what the command returned and what its log said.
sub said ( $root, $out, $command )
{
	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	die "$reason\n" unless $config;

	my $said = '';
	open my $saved, '>&', \*STDERR or die "Cannot save stderr: $!";
	close STDERR;
	open STDERR, '>', \$said or die 'Cannot capture stderr';

	my $done =
	    App::FuguWeb::Site->new( config => $config, out => $out )->$command;

	close STDERR;
	open STDERR, '>&', $saved or die "Cannot restore stderr: $!";

	return ( $done, $said );
}

# tree($root):
#	Each entry below the root, and the bytes of each file. A test
#	compares two of them to prove that a command changed nothing.
sub tree ($root)
{
	my %tree;
	File::Find::find( {
			no_chdir => 1,
			wanted   => sub {
				my $relative = substr $_, length $root;
				if ( -d $_ ) {
					$tree{"$relative/"} = 1;
					return;
				}

				open my $fh, '<:raw', $_ or die "Cannot read $_: $!";
				local $/;
				$tree{$relative} = <$fh>;
				close $fh;
			},
		},
		$root
	);

	return \%tree;
}

my $ROOT = project();
my $OUT  = tempdir( CLEANUP => 1 ) . '/out';

subtest 'the build makes the site and nothing else' => sub {
	my $site = site( $ROOT, $OUT );
	ok( $site->build, 'the build succeeds' );
	is( $site->missing_tool, undef, 'and records no missing tool' );

	# The probe is the first step, so the failure names the tool
	# that is missing. Without it the build reaches the lint and
	# reports that a manual source was rejected, which sends the
	# reader to the wrong place.
	my $absent = tempdir( CLEANUP => 1 ) . '/out';
	my $config = site( $ROOT, $absent )->config;
	my $said   = '';

	open my $saved, '>&', \*STDERR or die "Cannot save stderr: $!";
	close STDERR;
	open STDERR, '>', \$said or die 'Cannot capture stderr';

	my $broken = App::FuguWeb::Site->new(
		config => $config,
		out    => $absent,
		render => App::FuguWeb::Render->new(
			config => $config,
			mandoc => '/nonexistent/mandoc',
		),
	);
	my $failed = $broken->build;

	close STDERR;
	open STDERR, '>&', $saved or die "Cannot restore stderr: $!";

	ok( !$failed, 'a build with no mandoc fails' );
	is( $broken->missing_tool, '/nonexistent/mandoc',
		'and the build records the missing tool' );
	like( $said, qr{/nonexistent/mandoc is not installed},
		'and names the tool that is missing' );
	unlike( $said, qr/rejected a manual source/,
		'and does not blame a manual for it' );
	ok( !-e $absent, 'and writes nothing' );

	# The pages of the description and one page per manual, in the
	# tree of en. The forward, the top-level 404.html, the base
	# stylesheet, and the assets at the top level.
	my @expected = qw(
	    404.html en/404.html en/Thing::Depot.3p.html en/index.html
	    en/manuals.html en/readme.html en/tool.1.html
	    index.html robots.txt style.css
	);
	ok( -s "$OUT/$_", "$_ exists and is not empty" ) for @expected;

	# Staging is a build detail and never part of the published
	# tree.
	ok( !-e "$OUT/.man", 'the staging directory is gone' );

	is_deeply( App::FuguWeb::list_tree($OUT), \@expected,
		'the output holds the site only' );

	# A site of one language carries no list of the languages.
	for my $name ( grep { /\.html\z/ } @expected ) {
		open my $fh, '<', "$OUT/$name" or die "Cannot read: $!";
		my $html = do { local $/; <$fh> };
		close $fh;
		unlike( $html, qr/<a [^>]*hreflang/,
			"$name carries no language link" );
	}
};

subtest 'the top level holds the forward and the 404 page' => sub {
	open my $fh, '<', "$OUT/index.html" or die "Cannot read: $!";
	my $forward = do { local $/; <$fh> };
	close $fh;

	# WEB-TOP-1 and WEB-TOP-2. One meta refresh, the links of
	# WEB-CHROME-6, one link with the site name, and nothing loaded.
	is( $forward, <<'HTML', 'the forward is byte for byte its shape' );
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=en/index.html">
<title>Example</title>
<link rel="canonical" href="https://example.org/">
<link rel="alternate" hreflang="en" href="https://example.org/en/index.html">
<link rel="alternate" hreflang="x-default" href="https://example.org/">
</head>
<body>
<p><a href="en/index.html">Example</a></p>
</body>
</html>
HTML

	# The top-level 404.html is a page of the default language, with
	# its base, and its chrome links the default tree from the top
	# level.
	open $fh, '<', "$OUT/404.html" or die "Cannot read: $!";
	my $copy = do { local $/; <$fh> };
	close $fh;

	like( $copy, qr{<html lang="en">}, 'the top-level 404.html is a page of en' );
	like( $copy, qr{<base href="/">\n<title>Not found },
		'with its base before the title' );
	like( $copy, qr{<link rel="stylesheet" href="style\.css">},
		'the stylesheet beside it' );
	like( $copy, qr{<header>\n<a href="en/index\.html">Example</a>},
		'the header link into the default tree' );
	like( $copy,
		qr{<nav>\n<ul>\n<li><a href="en/index\.html">Home</a></li>\n</ul>\n</nav>},
		'and the nav link' );
	like( $copy,
		qr{<main>\n<section>\n<h1>Not found</h1>\n<p><a href="en/index\.html">Home</a></p>\n</section>\n</main>},
		'the body of en in its section, with each link from the root' );
	unlike( $copy, qr/<footer>/, 'and no footer' );

	open $fh, '<', "$OUT/en/404.html" or die "Cannot read: $!";
	my $tree = do { local $/; <$fh> };
	close $fh;

	like( $tree, qr{<footer>}, 'the 404 page of the tree takes the footer' );
	unlike( $tree, qr{<base}, 'and no base' );
};

subtest 'each source reaches its page' => sub {
	open my $fh, '<', "$OUT/en/readme.html" or die "Cannot read: $!";
	my $readme = do { local $/; <$fh> };
	close $fh;
	like( $readme, qr/A paragraph\./, 'lowdown rendered the Markdown' );

	open $fh, '<', "$OUT/en/manuals.html" or die "Cannot read: $!";
	my $index = do { local $/; <$fh> };
	close $fh;
	like( $index, qr{href="\./tool\.1\.html"}, 'the index lists the page' );
	like( $index, qr/a tool/, 'with the description of its source' );
	like( $index, qr{href="\./Thing::Depot\.3p\.html"},
		'and the sidecar' );

	open $fh, '<', "$OUT/en/Thing::Depot.3p.html" or die "Cannot read: $!";
	my $module = do { local $/; <$fh> };
	close $fh;
	like( $module, qr/the persistence contract/,
		'pod2man and mandoc rendered the sidecar' );
	like( $module, qr{<title>Thing::Depot\(3p\) },
		'and the chrome carries the title' );
	like( $module, qr{<html lang="en">}, 'the page is a page of en' );
	like( $module, qr{<link rel="stylesheet" href="\.\./style\.css">},
		'it links the stylesheet one step up' );
	like( $module, qr{<header>\n<a href="index\.html">Example</a>},
		'and the entry page of its tree from its directory' );
	like( $module, qr{<footer>\n<p>ISC\.</p>\n</footer>},
		'and it carries the footer' );
};

# The translation of the small project into de. The index page and
# the readme take no translation of their own, so their bodies come
# from the default sources. Two more nav entries make each page
# reachable, so the whole check runs over the site.
my %DE = (
	'.fuguwebrc' => <<'RC',

language en {
	name = English
}

language de {
	name   = Deutsch
	footer = de/footer.body.html
}

nav "readme.html" {
	label = Readme
}

nav "manuals.html" {
	label = Manuals
}

page de "index.html" {
	title = Start
	body  = de/index.body.html
}

nav de "index.html" {
	label = Start
}

manuals de manuals {
	heading = Handbuch
	dir     = man/de
}

modules de modules {
	heading = Module
	dir     = lib/de/Thing
}
RC
	'web/de/index.body.html'   => "<h1>Start</h1>\n",
	'web/de/footer.body.html'  => "<p>ISC-Lizenz.</p>\n",
	'man/de/tool.1'            => <<'MDOC',
.Dd $Mdocdate: July 27 2026 $
.Dt TOOL 1
.Os
.Sh NAME
.Nm tool
.Nd ein Werkzeug
.Sh DESCRIPTION
Worte.
MDOC
	'lib/Thing.pod'    => "=head1 NAME\n\nThing - the umbrella\n",
	'lib/de/Thing.pod' => "=head1 NAME\n\nThing - der Schirm\n",
	'lib/de/Thing/Depot.pod' => <<'POD',
=head1 NAME

Thing::Depot - der Vertrag

=head1 DESCRIPTION

Worte.
POD
);

# read_page($path):
#	The bytes of one page of the output.
sub read_page ($path)
{
	open my $fh, '<', $path or die "Cannot read $path: $!";
	my $html = do { local $/; <$fh> };
	close $fh;

	return $html;
}

# main_of($html):
#	The part of a page from the <main> element to its end tag.
sub main_of ($html)
{
	my ($main) = $html =~ m{(<main[ >].*</main>)}s;

	return $main // '';
}

subtest 'a site of two languages builds one tree for each' => sub {
	my $root = project(%DE);
	my $out  = tempdir( CLEANUP => 1 ) . '/out';
	my $site = site( $root, $out );
	ok( $site->build, 'the build succeeds' );

	my $check    = App::FuguWeb::Check->new( config => $site->config, out => $out );
	my @problems = $check->run;
	is( scalar @problems, 0, 'and the check finds no problem' )
	    or diag join "\n", @problems;

	# WEB-LANGUAGE-5. Each tree holds the same page names.
	my @tree = @{ App::FuguWeb::list_tree($out) };
	my %in;
	for my $path (@tree) {
		my ( $code, $name ) = split m{/}, $path, 2;
		push @{ $in{$code} }, $name if defined $name;
	}
	is_deeply( $in{de}, $in{en}, 'de and en hold the same pages' );
	ok( grep( { $_ eq 'Thing.3p.html' } @{ $in{de} } ),
		'and each holds the umbrella' );

	# WEB-LANGUAGE-8 and WEB-LANGUAGE-11. A translated page takes
	# its own body, and a page with no translation the default body
	# with lang="en" on the element that holds it.
	my $index = read_page("$out/de/index.html");
	like( $index, qr{<html lang="de">}, 'the front page of de is a page of de' );
	like( $index, qr{<title>Start \xe2\x80\x94 Example</title>},
		'with the title of de' );
	like( $index, qr{<main>\n<h1>Start</h1>}, 'and the body of de' );
	like( $index, qr{<a href="index\.html" aria-current="page">Start</a>},
		'and the nav of de, with the page as the current entry' );
	like( $index, qr{<a href="readme\.html" lang="en">Readme</a>},
		'and a label of en, with its mark' );
	like( $index, qr{<header>\n<a href="index\.html" lang="en">Example</a>},
		'and the site name of en, with its mark' );

	my $readme = read_page("$out/de/readme.html");
	like( $readme, qr{<html lang="de">}, 'the readme of de is a page of de' );
	like( $readme, qr{<main lang="en">\n.*A paragraph\.}s,
		'with the body of en, which carries lang="en"' );

	# An index page marks each part of the default source, and the
	# element that holds its body takes the language of the tree.
	my $manuals = read_page("$out/de/manuals.html");
	like( $manuals, qr{<main>\n<h1 lang="en">Manuals</h1>},
		'the index of de has no page translation, so its title is of en' );
	my $marks = () = main_of($manuals) =~ / lang=/g;
	is( $marks, 1, 'and no other part is' );
	like( $manuals, qr{<h2 id="manuals">Handbuch</h2>},
		'and it takes the heading of de, with the same anchor' );
	like( $manuals, qr{<dd>ein Werkzeug</dd>},
		'and the description of the source of de' );
	like( $manuals, qr{<h2 id="modules">Module</h2>.*<dd>der Vertrag</dd>}s,
		'and the same for the modules' );

	# A manual of de comes from its namesake, and keeps the page
	# name of the default source.
	my $tool = read_page("$out/de/tool.1.html");
	like( $tool,   qr{<main>\n},  'the manual of de carries no marker' );
	like( $tool,   qr{Worte\.},   'and comes from the source of de' );
	unlike( $tool, qr{Words\.},   'and not from the default source' );
	like( read_page("$out/de/Thing::Depot.3p.html"),
		qr{<main>\n.*der Vertrag}s, 'a sidecar of de' );
	like( read_page("$out/de/Thing.3p.html"),
		qr{der Schirm}, 'and the umbrella of de' );
	like( read_page("$out/en/tool.1.html"),
		qr{<main>\n.*Words\.}s, 'the manual of en stays' );

	# Each tree page links the same page in each language, and a
	# page of the top level links none.
	like(
		read_page("$out/en/tool.1.html"),
		qr{<li><a href="\.\./de/tool\.1\.html" hreflang="de" lang="de">Deutsch</a></li>},
		'a page of en links its page of de'
	);
	like(
		read_page("$out/de/Thing::Depot.3p.html"),
		qr{<li><a href="\.\./en/Thing::Depot\.3p\.html" hreflang="en" lang="en">English</a></li>\n<li><a href="\./Thing::Depot\.3p\.html" hreflang="de" lang="de" aria-current="page">Deutsch</a></li>},
		'a page of de links its page of en, and itself'
	);

	# WEB-TOP-2 and WEB-TOP-4. A page of the top level lists each
	# language, with a link to the entry page of each one, and no
	# current link.
	like(
		read_page("$out/$_"),
		qr{<ul>\n<li><a href="en/index\.html" hreflang="en" lang="en">English</a></li>\n<li><a href="de/index\.html" hreflang="de" lang="de">Deutsch</a></li>\n</ul>\n},
		"the top-level $_ lists the entry page of each language"
	) for qw(index.html 404.html);

	# WEB-LANGUAGE-3. A tree takes the footer of its language.
	like( $index, qr{<footer>\n<p>ISC-Lizenz\.</p>\n</footer>},
		'a page of de carries the footer of de' );
	like( read_page("$out/en/index.html"),
		qr{<footer>\n<p>ISC\.</p>\n</footer>},
		'and a page of en the footer of the description' );
	unlike( read_page("$out/404.html"), qr{<footer>},
		'and the top-level 404.html none' );

	# A source of a translation is no asset.
	ok( !-e "$out/de/index.body.html" && !-e "$out/index.body.html",
		'the body of de is not published' );

	# The check holds each language link.
	my $broken = $readme =~ s{<li><a href="\.\./en/readme\.html"[^\n]*\n}{}r;
	open my $fh, '>', "$out/de/readme.html" or die "Cannot write: $!";
	print {$fh} $broken;
	close $fh;

	my $top = read_page("$out/404.html")
	    =~ s{<li><a href="de/index\.html"[^\n]*\n}{}r;
	open $fh, '>', "$out/404.html" or die "Cannot write: $!";
	print {$fh} $top;
	close $fh;

	my $joined = join "\n", $check->run;
	like( $joined, qr{^de/readme\.html: does not link the page in en$}m,
		'the check reports a missing language link' );
	like( $joined,
		qr{^404\.html: carries 1 language links, and the page takes 2$}m,
		'and a missing language link on a page of the top level' );
};

subtest 'an index page marks each part of the default source' => sub {
	# WEB-LANGUAGE-11. The parts of an index page come from the
	# sources of more than one language. Each part from the default
	# source carries lang="en" on its own element, and <main>
	# carries no marker. The page of de translates each part, and
	# the page of fr translates the title and the manual of one
	# group alone.
	my $root = project(
		%DE,
		'.fuguwebrc' => $DE{'.fuguwebrc'} . <<'RC',

language fr {
	name = Fran\xc3\xa7ais
}

nav "handbook.html" {
	label = Handbook
}

page "handbook.html" {
	title = Handbook
	index = yes
	body  = handbook.body.html
}

page de "handbook.html" {
	title = Handbuch
	body  = de/handbook.body.html
}

page fr "handbook.html" {
	title = Manuel
}

manuals fr manuals {
	dir = man/fr
}
RC
		'web/handbook.body.html'    => "<p>Read them.</p>\n",
		'web/de/handbook.body.html' => "<p>Lies sie.</p>\n",
		'man/fr/tool.1' => $DE{'man/de/tool.1'} =~ s/ein Werkzeug/un outil/r,
	);
	my $out  = tempdir( CLEANUP => 1 ) . '/out';
	my $site = site( $root, $out );
	ok( $site->build, 'the build succeeds' );

	# WEB-LANGUAGE-13. The check holds each tree page to its
	# language.
	my @problems =
	    App::FuguWeb::Check->new( config => $site->config, out => $out )->run;
	is( scalar @problems, 0, 'and the check finds no problem' )
	    or diag join "\n", @problems;

	my $en = read_page("$out/en/handbook.html");
	like( $en, qr{<main>\n<h1>Handbook</h1>\n\n<p>Read them\.</p>\n},
		'the index of en takes its own parts' );
	unlike( main_of($en), qr/ lang=/, 'and carries no marker' );

	my $de = read_page("$out/de/handbook.html");
	like( $de, qr{<main>\n<h1>Handbuch</h1>\n\n<p>Lies sie\.</p>\n},
		'the index of de takes its own title and opening' );
	like( $de, qr{<h2 id="manuals">Handbuch</h2>.*<dd>ein Werkzeug</dd>}s,
		'and the heading and the description of de' );
	unlike( main_of($de), qr/ lang=/,
		'and with each part translated, no part carries a marker' );

	my $fr = read_page("$out/fr/handbook.html");
	like( $fr, qr{<html lang="fr">}, 'the index of fr is a page of fr' );
	like( $fr, qr{<main>\n<h1>Manuel</h1>\n},
		'its title is of fr, and <main> carries no marker' );
	like( $fr, qr{\n<div lang="en">\n<p>Read them\.</p>\n</div>\n},
		'the opening of the default source carries lang="en"' );
	like( $fr, qr{<h2 id="manuals" lang="en">Manuals</h2>},
		'and so does a heading that the translation does not name' );
	like( $fr, qr{<dd>un outil</dd>},
		'a description from the dir of fr carries no marker' );
	like( $fr, qr{<h2 id="modules" lang="en">Modules</h2>},
		'a group with no translation takes the default heading' );
	like( $fr, qr{<dd lang="en">the persistence contract</dd>},
		'and a description of the default source carries lang="en"' );
};

# The site of three languages: en, zh-Hans and ar. The tree of zh-Hans
# takes the path zh-hans, and ar is right to left. The site name of en
# ends in a, with a grave accent, whose last byte is 0xA0. A trim of
# white space that read that byte as a space would cut the value.
my $THREE = <<"RC";
site       = voil\xc3\xa0
url        = https://example.org/
footer     = footer.body.html
source_dir = web
out_dir    = out

language en {
	name = English
}

language zh-Hans {
	name   = \xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87
	site   = \xe7\xa4\xba\xe4\xbe\x8b
	footer = zh-hans/footer.body.html
}

language ar {
	name = \xd8\xa7\xd9\x84\xd8\xb9\xd8\xb1\xd8\xa8\xd9\x8a\xd8\xa9
	dir  = rtl
}

nav "index.html" {
	label = Home
}

nav "manuals.html" {
	label = Manuals
}

nav zh-Hans "index.html" {
	label = \xe9\xa6\x96\xe9\xa1\xb5
}

page "index.html" {
	title = Home
	body  = index.body.html
}

page zh-Hans "index.html" {
	title = \xe9\xa6\x96\xe9\xa1\xb5
	body  = zh-hans/index.body.html
}

page "manuals.html" {
	title = Manuals
	index = yes
}

page "404.html" {
	title    = Not found
	body     = 404.body.html
	unlinked = yes
}

manuals manuals {
	heading = Manuals
	dir     = man
}

manuals zh-Hans manuals {
	heading = \xe6\x89\x8b\xe5\x86\x8c
}
RC

# three(%more):
#	The project of the site of three languages.
sub three (%more)
{
	my $root = project(
		'web/zh-hans/index.body.html'  => "<h1>\xe9\xa6\x96\xe9\xa1\xb5</h1>\n",
		'web/zh-hans/footer.body.html' => "<p>ISC \xe8\xae\xb8\xe5\x8f\xaf\xe3\x80\x82</p>\n",
		%more
	);

	open my $fh, '>', "$root/.fuguwebrc" or die "Cannot write: $!";
	print {$fh} $THREE;
	close $fh;

	return $root;
}

subtest 'a site of three languages builds each tree below its path' => sub {
	my $root = three();
	my $out  = tempdir( CLEANUP => 1 ) . '/out';
	my $site = site( $root, $out );
	ok( $site->build, 'the build succeeds' );

	my @problems =
	    App::FuguWeb::Check->new( config => $site->config, out => $out )->run;
	is( scalar @problems, 0, 'and the check finds no problem' )
	    or diag join "\n", @problems;

	# WEB-LANGUAGE-5. One tree for each language, below the tag in
	# lowercase, and each tree holds the same pages.
	my %in;
	for my $path ( @{ App::FuguWeb::list_tree($out) } ) {
		my ( $tree, $name ) = split m{/}, $path, 2;
		push @{ $in{$tree} }, $name if defined $name;
	}
	is_deeply( [ sort keys %in ], [qw(ar en zh-hans)],
		'the trees are en, zh-hans and ar, and nothing else' );
	is_deeply( $in{'zh-hans'}, $in{en}, 'zh-hans holds the pages of en' );
	is_deeply( $in{ar},        $in{en}, 'and so does ar' );
	is_deeply( $in{en}, [qw(404.html index.html manuals.html tool.1.html)],
		'which are the pages of the description and the manual' );
	ok( !-e "$out/.man", 'and the staging directory is gone' );

	# WEB-LANGUAGE-10. Each page of a tree carries the tag of its
	# language, and dir="rtl" in the tree of ar.
	my %html = (
		en        => '<html lang="en">',
		'zh-hans' => '<html lang="zh-Hans">',
		ar        => '<html lang="ar" dir="rtl">',
	);
	for my $tree ( sort keys %html ) {
		for my $name ( @{ $in{$tree} } ) {
			my $page = read_page("$out/$tree/$name");
			like( $page, qr{^<!DOCTYPE html>\n\Q$html{$tree}\E\n},
				"$tree/$name carries $html{$tree}" );
		}
	}

	# The value that ends in a grave accent reads byte for byte.
	my $en = read_page("$out/en/index.html");
	like( $en, qr{<title>Home \xe2\x80\x94 voil\xc3\xa0</title>},
		'the site name of en reaches the title byte for byte' );
	like( $en, qr{<header>\n<a href="index\.html">voil\xc3\xa0</a>\n},
		'and the site link' );
	like( read_page("$out/index.html"), qr{<title>voil\xc3\xa0</title>},
		'and the forward' );

	# WEB-LANGUAGE-11. The tree of zh-Hans takes its own site name,
	# label, body and footer, and marks each part of en.
	my $zh = read_page("$out/zh-hans/index.html");
	like( $zh, qr{<header>\n<a href="index\.html">\xe7\xa4\xba\xe4\xbe\x8b</a>\n},
		'zh-Hans takes its own site name' );
	like(
		$zh,
		qr{<a href="index\.html" aria-current="page">\xe9\xa6\x96\xe9\xa1\xb5</a>},
		'and its own label'
	);
	like( $zh, qr{<a href="manuals\.html" lang="en">Manuals</a>},
		'and marks a label of en' );
	like( $zh, qr{<main>\n<h1>\xe9\xa6\x96\xe9\xa1\xb5</h1>},
		'it takes its own body' );
	like( $zh,
		qr{<footer>\n<p>ISC \xe8\xae\xb8\xe5\x8f\xaf\xe3\x80\x82</p>\n</footer>},
		'and its own footer' );
	like(
		$zh,
		qr{<a href="\.\./ar/index\.html" hreflang="ar" lang="ar" dir="rtl">\xd8\xa7\xd9\x84\xd8\xb9\xd8\xb1\xd8\xa8\xd9\x8a\xd8\xa9</a>},
		'and links the page of ar, with its direction'
	);
	like(
		read_page("$out/en/index.html"),
		qr{<a href="\.\./zh-hans/index\.html" hreflang="zh-Hans" lang="zh-Hans">\xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87</a>},
		'a page of en links the tree of zh-Hans'
	);

	my $manuals = read_page("$out/zh-hans/manuals.html");
	like( $manuals, qr{<h1 lang="en">Manuals</h1>},
		'the index of zh-Hans marks the title of en' );
	like( $manuals, qr{<h2 id="manuals">\xe6\x89\x8b\xe5\x86\x8c</h2>},
		'and takes its own heading' );

	# The tree of ar takes each value of en, and each mark carries
	# the direction of en, which differs from that of the page.
	my $ar = read_page("$out/ar/index.html");
	like( $ar,
		qr{<header>\n<a href="index\.html" lang="en" dir="ltr">voil\xc3\xa0</a>\n},
		'the site name of en carries its marks on a page of ar' );
	like(
		$ar,
		qr{<a href="index\.html" lang="en" dir="ltr" aria-current="page">Home</a>},
		'and so does a label'
	);
	like( $ar, qr{<main lang="en" dir="ltr">\n<h1>Home</h1>},
		'and the body' );

	# WEB-CHROME-1 and WEB-CHROME-6. The head names the page in each
	# language below the url, and the bare url for the forward page.
	like(
		$ar,
		qr{<title>Home \xe2\x80\x94 voil\xc3\xa0</title>
<link rel="canonical" href="https://example\.org/ar/index\.html">
<link rel="alternate" hreflang="en" href="https://example\.org/en/index\.html">
<link rel="alternate" hreflang="zh-Hans" href="https://example\.org/zh-hans/index\.html">
<link rel="alternate" hreflang="ar" href="https://example\.org/ar/index\.html">
<link rel="alternate" hreflang="x-default" href="https://example\.org/">
<link rel="stylesheet" href="\.\./style\.css">
</head>},
		'the head of a page of ar names it in each language'
	);
	like( $ar, qr{<footer lang="en" dir="ltr">\n<p>ISC\.</p>\n</footer>},
		'and the footer' );

	ok( site( $root, $out )->build, 'a second build succeeds' );
	ok( site( $root, $out )->clean, 'and the clean takes the three trees' );
	ok( !-e $out, 'and the directory is gone' );

	# A description that does not load still declares its trees.
	# The clean is the command an operator reaches for then, and it
	# takes each tree that the language blocks of the file name.
	ok( site( $root, $out )->build, 'a third build succeeds' );
	open my $fh, '>>', "$root/.fuguwebrc" or die "Cannot write: $!";
	print {$fh} "}\n";
	close $fh;

	my $broken = App::FuguWeb::Site->new(
		config => App::FuguWeb::Config->anonymous($root),
		out    => $out,
		log    => Fugu::Log->new( mode => Fugu::Log::MODE_QUIET() ),
	);
	ok( $broken->clean, 'the clean of a broken description takes them' );
	ok( !-e $out, 'and the directory is gone' );
};

subtest 'the top level of a site of three languages' => sub {
	# The 404 page of zh-Hans takes its own body. Its heading takes
	# the id of en, per WEB-OUTLINE-2, and its link to the heading
	# follows, per WEB-OUTLINE-4. The tree of ar takes the body of
	# en. A body links an asset from its tree.
	my $root = three(
		'web/404.body.html' => qq{<h1 id="lost">Not found</h1>\n}
		    . qq{<p><a href="index.html">Home</a> <a href="#lost">Up</a>}
		    . qq{ <img src="../logo.png" alt=""></p>\n},
		'web/zh-hans/404.body.html' =>
		    qq{<h1 id="section">\xe6\x9c\xaa\xe6\x89\xbe\xe5\x88\xb0</h1>\n}
		    . qq{<p><a href="index.html">\xe9\xa6\x96\xe9\xa1\xb5</a>}
		    . qq{ <a href="#section">\xe4\xb8\x8a</a></p>\n},
		'web/logo.png' => "PNG\n",
	);
	open my $fh, '>>', "$root/.fuguwebrc" or die "Cannot write: $!";
	print {$fh} <<"RC";

page zh-Hans "404.html" {
	title = \xe6\x9c\xaa\xe6\x89\xbe\xe5\x88\xb0
	body  = zh-hans/404.body.html
}
RC
	close $fh;

	my $out  = tempdir( CLEANUP => 1 ) . '/out';
	my $site = site( $root, $out );
	ok( $site->build, 'the build succeeds' );

	# The check holds both pages to WEB-TOP.
	my @problems =
	    App::FuguWeb::Check->new( config => $site->config, out => $out )->run;
	is( scalar @problems, 0, 'and the check finds no problem' )
	    or diag join "\n", @problems;

	# WEB-TOP-1 and WEB-TOP-2. The forward is a page of en. The
	# links of its head name the bare url and the entry page of each
	# language, and its body lists each language.
	is( read_page("$out/index.html"), <<"HTML", 'the forward is byte for byte its shape' );
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=en/index.html">
<title>voil\xc3\xa0</title>
<link rel="canonical" href="https://example.org/">
<link rel="alternate" hreflang="en" href="https://example.org/en/index.html">
<link rel="alternate" hreflang="zh-Hans" href="https://example.org/zh-hans/index.html">
<link rel="alternate" hreflang="ar" href="https://example.org/ar/index.html">
<link rel="alternate" hreflang="x-default" href="https://example.org/">
</head>
<body>
<ul>
<li><a href="en/index.html" hreflang="en" lang="en">English</a></li>
<li><a href="zh-hans/index.html" hreflang="zh-Hans" lang="zh-Hans">\xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87</a></li>
<li><a href="ar/index.html" hreflang="ar" lang="ar" dir="rtl">\xd8\xa7\xd9\x84\xd8\xb9\xd8\xb1\xd8\xa8\xd9\x8a\xd8\xa9</a></li>
</ul>
</body>
</html>
HTML

	# WEB-TOP-3 and WEB-TOP-4. The top-level 404.html is a page of en,
	# with the base, the title of en/404.html, the list of the
	# languages and the nav of en.
	my $top = read_page("$out/404.html");
	like(
		$top,
		qr{\A<!DOCTYPE html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" [^\n]*\n<base href="/">\n<title>Not found \xe2\x80\x94 voil\xc3\xa0</title>\n<link rel="stylesheet" href="style\.css">\n</head>\n},
		'its head holds five parts, the base before the title'
	);
	like(
		$top,
		qr{<header>\n<a href="en/index\.html">voil\xc3\xa0</a>\n<ul>\n<li><a href="en/index\.html" hreflang="en" lang="en">English</a></li>\n<li><a href="zh-hans/index\.html" hreflang="zh-Hans" lang="zh-Hans">[^<]+</a></li>\n<li><a href="ar/index\.html" hreflang="ar" lang="ar" dir="rtl">[^<]+</a></li>\n</ul>\n</header>\n<nav>\n<ul>\n<li><a href="en/index\.html">Home</a></li>\n<li><a href="en/manuals\.html">Manuals</a></li>\n</ul>\n</nav>\n},
		'its header lists the entry page of each language, and its nav links en'
	);

	# WEB-TOP-5 and WEB-TOP-6. The body of each language, in its own
	# section, with no id, and with each link from the site root. The
	# body of zh-Hans carries its marks, and ar takes the body of en.
	is( main_of($top), <<"HTML" =~ s/\n\z//r, 'its main holds the body of each language' );
<main>
<section>
<h1>Not found</h1>
<p><a href="en/index.html">Home</a> <a href="en/404.html#lost">Up</a> <img src="logo.png" alt=""></p>
</section>
<section lang="zh-Hans">
<h1>\xe6\x9c\xaa\xe6\x89\xbe\xe5\x88\xb0</h1>
<p><a href="zh-hans/index.html">\xe9\xa6\x96\xe9\xa1\xb5</a> <a href="zh-hans/404.html#lost">\xe4\xb8\x8a</a></p>
</section>
<section>
<h1>Not found</h1>
<p><a href="ar/index.html">Home</a> <a href="ar/404.html#lost">Up</a> <img src="logo.png" alt=""></p>
</section>
</main>
HTML

	# The tree of zh-Hans holds the id of en, and the link to it.
	like( read_page("$out/zh-hans/404.html"),
		qr{<h1 id="lost">\xe6\x9c\xaa.*<a href="#lost">}s,
		'the 404 page of zh-Hans takes the id of en' );

	# The check holds each section to the body of its tree.
	my $broken = $top =~ s{<section lang="zh-Hans">}{<section>}r;
	open $fh, '>', "$out/404.html" or die "Cannot write: $!";
	print {$fh} $broken;
	close $fh;
	is_deeply(
		[ App::FuguWeb::Check->new( config => $site->config, out => $out )->run ],
		[
			'404.html: the section for zh-hans/404.html does not'
			    . ' open as <section lang="zh-Hans">'
		],
		'the check reports a section with no marks'
	);
};

subtest 'the default language need not be en' => sub {
	# D-05. The first language is the default. The forward and the
	# top-level 404.html are pages of it, and they lead into its
	# tree.
	my ($ar) = $THREE =~ m/(language ar \{\n[^\}]*\}\n\n)/;
	my $rc = $THREE =~ s/\Q$ar\E//r;
	$rc =~ s/(language en \{)/$ar$1/;

	my $root = three();
	open my $fh, '>', "$root/.fuguwebrc" or die "Cannot write: $!";
	print {$fh} $rc;
	close $fh;

	my $out  = tempdir( CLEANUP => 1 ) . '/out';
	my $site = site( $root, $out );
	is( $site->config->default_language->tag, 'ar', 'ar is the default' );
	ok( $site->build, 'the build succeeds' );

	my @problems =
	    App::FuguWeb::Check->new( config => $site->config, out => $out )->run;
	is( scalar @problems, 0, 'and the check finds no problem' )
	    or diag join "\n", @problems;

	my $forward = read_page("$out/index.html");
	like( $forward, qr{<html lang="ar" dir="rtl">\n},
		'the forward is a page of ar' );
	like( $forward, qr{<meta http-equiv="refresh" content="0; url=ar/index\.html">},
		'and it leads into the tree of ar' );

	my $copy = read_page("$out/404.html");
	like( $copy, qr{<html lang="ar" dir="rtl">\n},
		'so is the top-level 404.html' );
	like( $copy, qr{<header>\n<a href="ar/index\.html">voil\xc3\xa0</a>},
		'and its chrome links the tree of ar' );
	like( read_page("$out/en/index.html"), qr{<html lang="en">\n},
		'and en is one more tree' );
};

subtest 'a source that is not UTF-8 fails the build' => sub {
	# WEB-SITE-5. The message names the source.
	my %case = (
		'web/index.body.html'          => "<h1>caf\xe9</h1>\n",
		'web/footer.body.html'         => "<p>caf\xe9</p>\n",
		'web/zh-hans/footer.body.html' => "<p>caf\xe9</p>\n",
		'README.md'                    => "# caf\xe9\n",
		'man/tool.1' => ".Dd \$Mdocdate: July 27 2026 \$\n.Dt TOOL 1\n.Os\n"
		    . ".Sh NAME\n.Nm tool\n.Nd caf\xe9\n",
	);

	for my $source ( sort keys %case ) {
		my $root = three( $source => $case{$source} );

		# A Markdown page of the description names README.md.
		open my $fh, '>>', "$root/.fuguwebrc" or die "Cannot write: $!";
		print {$fh} qq{\npage "readme.html" {\n\tmarkdown = README.md\n}\n};
		close $fh;

		my $out  = tempdir( CLEANUP => 1 ) . '/out';
		my $said = '';
		open my $saved, '>&', \*STDERR or die "Cannot save stderr: $!";
		close STDERR;
		open STDERR, '>', \$said or die 'Cannot capture stderr';

		my $config = App::FuguWeb::Config->load(
			root  => $root,
			error => \my $reason
		);
		my $built =
		    App::FuguWeb::Site->new( config => $config, out => $out )
		    ->build;

		close STDERR;
		open STDERR, '>&', $saved or die "Cannot restore stderr: $!";

		ok( !$built, "a $source that is not UTF-8 fails the build" );
		like( $said, qr{\Q$root/$source\E is not valid UTF-8 at byte},
			"and the message names $source" );
	}
};

subtest 'a translation dir mirrors the default dir' => sub {
	# WEB-LANGUAGE-9. A source of a translation dir with no namesake
	# is a page that no other tree holds.
	my %case = (
		'man/de/extra.1' => qr{manuals de "manuals" holds man/de/extra\.1, which has no namesake in man; a translation dir mirrors the default dir},
		'lib/de/Thing/Extra.pod' => qr{modules de "modules" holds lib/de/Thing/Extra\.pod, which has no namesake in lib/Thing},
	);
	for my $orphan ( sort keys %case ) {
		my $root = project( %DE, $orphan => $DE{'man/de/tool.1'} );

		my $config = App::FuguWeb::Config->load(
			root  => $root,
			error => \my $reason
		);
		is( $config, undef, "$orphan fails the load" );
		like( $reason, $case{$orphan}, 'and the message names it' );
	}

	# The umbrella of a translation dir mirrors the umbrella of the
	# default dir, and a default dir with none takes none.
	my %files = %DE;
	delete $files{'lib/Thing.pod'};
	my $root = project(%files);
	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	is( $config, undef, 'an umbrella with no namesake fails the load' );
	like( $reason, qr{holds lib/de/Thing\.pod, which has no namesake in lib/Thing},
		'and the message names it' );

	# The lint reads the source of each language. A malformed
	# source of de must fail the build, as one of en does.
	$root = project( %DE, 'man/de/tool.1' => ".Sh NAME\n.Nm tool\n" );
	ok( !site( $root, tempdir( CLEANUP => 1 ) . '/out' )->build,
		'a malformed source of de fails the build' );

	# A file that the group does not take is no source, in either
	# directory.
	$root   = project( %DE, 'man/de/CLAUDE.md' => "# man/de\n" );
	$config = App::FuguWeb::Config->load( root => $root, error => \$reason );
	ok( $config, 'a file that is no manual is no orphan' ) or diag $reason;
};

subtest 'the site is a pure function of the project' => sub {
	my $second = tempdir( CLEANUP => 1 ) . '/out';
	ok( site( $ROOT, $second )->build, 'the second build succeeds' );

	my $diff = `diff -r '$OUT' '$second' 2>&1`;
	is( $diff, '', 'two builds are byte-identical' );
};

subtest 'a second build over the same directory succeeds' => sub {
	my $site = site( $ROOT, $OUT );
	ok( $site->build, 'the build is idempotent' );
	ok( !-e "$OUT/.man", 'and leaves no staging behind' );
};

subtest 'a stylesheet that is not found fails the build' => sub {
	my $root = project();
	open my $fh, '>>', "$root/.fuguwebrc"
	    or die "Cannot append to the description: $!";
	print {$fh} "stylesheet = web/absent.css\n";
	close $fh;

	my $out = tempdir( CLEANUP => 1 ) . '/out';

	# A site with no stylesheet must not look like a success.
	ok( !site( $root, $out )->build, 'the build fails' );
};

subtest 'clean removes the output directory' => sub {
	my $site = site( $ROOT, $OUT );
	ok( -d $OUT, 'the output is there' );
	ok( $site->clean, 'clean succeeds' );
	ok( !-e $OUT, 'and the directory is gone' );

	ok( $site->clean, 'clean is idempotent' );
};

# The translation of the small project into zh-Hans: a body page, a
# Markdown page, a manual and a sidecar. Each heading of zh-Hans holds
# Han text, so lowdown(1) and mandoc(1) give it no id of the heading of
# en. Two more nav entries make each page reachable, so the whole check
# runs over the site.
my %ZH = (
	'.fuguwebrc' => <<"RC",

language en {
	name = English
}

language zh-Hans {
	name = \xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87
}

nav "readme.html" {
	label = Readme
}

nav "manuals.html" {
	label = Manuals
}

page zh-Hans "index.html" {
	title = \xe9\xa6\x96\xe9\xa1\xb5
	body  = zh-hans/index.body.html
}

page zh-Hans "readme.html" {
	title    = \xe8\x87\xaa\xe8\xbf\xb0
	markdown = zh-hans/README.md
}

manuals zh-Hans manuals {
	dir = man/zh-hans
}

modules zh-Hans modules {
	dir = lib/zh-hans/Thing
}
RC
	'README.md' => "# Readme\n\nA paragraph.\n\n## Install\n\nSteps.\n"
	    . "\n## For the CTO\n\nWords.\n",
	'zh-hans/README.md' => "# \xe8\x87\xaa\xe8\xbf\xb0\n\n"
	    . "\xe4\xb8\x80\xe6\xae\xb5\xe3\x80\x82\n\n"
	    . "## \xe5\xae\x89\xe8\xa3\x85\n\n"
	    . "\xe6\xad\xa5\xe9\xaa\xa4\xe3\x80\x82\n\n"
	    . "## \xe9\x9d\xa2\xe5\x90\x91 CTO\n\n"
	    . "\xe6\x96\x87\xe5\xad\x97\xe3\x80\x82\n",
	'web/zh-hans/index.body.html' => "<h1>\xe9\xa6\x96\xe9\xa1\xb5</h1>\n",
	'man/tool.1'                  => <<'MDOC',
.Dd $Mdocdate: July 27 2026 $
.Dt TOOL 1
.Os
.Sh NAME
.Nm tool
.Nd a tool
.Sh DESCRIPTION
Words.
.Ss Install
Steps.
MDOC
	'man/zh-hans/tool.1' => <<"MDOC",
.Dd \$Mdocdate: July 27 2026 \$
.Dt TOOL 1
.Os
.Sh NAME
.Nm tool
.Nd \xe5\xb7\xa5\xe5\x85\xb7
.Sh \xe6\x8f\x8f\xe8\xbf\xb0
\xe6\x96\x87\xe5\xad\x97\xe3\x80\x82
.Ss \xe5\xae\x89\xe8\xa3\x85
\xe6\xad\xa5\xe9\xaa\xa4\xe3\x80\x82
MDOC
	'lib/Thing/Depot.pod' => <<'POD',
=head1 NAME

Thing::Depot - the persistence contract

=head1 DESCRIPTION

Words.

=head2 Part

More.
POD
	'lib/zh-hans/Thing/Depot.pod' => <<"POD",
=encoding utf8

=head1 NAME

Thing::Depot - \xe5\xb7\xa5\xe5\x85\xb7

=head1 \xe6\x8f\x8f\xe8\xbf\xb0

\xe6\x96\x87\xe5\xad\x97\xe3\x80\x82

=head2 \xe9\x83\xa8\xe5\x88\x86

\xe6\xad\xa5\xe9\xaa\xa4\xe3\x80\x82
POD
);

# heading_ids($html):
#	The id of each heading of the main element of a page, in order,
#	with an empty string for a heading that has none. The test reads
#	the page with its own pattern, and not with App::FuguWeb::Fragment.
sub heading_ids ($html)
{
	return map { /\sid="([^"]*)"/ ? $1 : '' }
	    main_of($html) =~ m{<h[1-6]\b([^>]*)>}g;
}

subtest 'each page of zh-Hans takes the heading ids of en' => sub {
	# WEB-OUTLINE-1 and WEB-OUTLINE-2. A body page, a Markdown page,
	# a manual and a sidecar of zh-Hans each follow the outline of
	# their namesake of en, and take its ids.
	my $root = project(%ZH);
	my $out  = tempdir( CLEANUP => 1 ) . '/out';
	my $site = site( $root, $out );
	ok( $site->build, 'the build succeeds' );

	my @problems =
	    App::FuguWeb::Check->new( config => $site->config, out => $out )->run;
	is( scalar @problems, 0, 'and the check finds no problem' )
	    or diag join "\n", @problems;

	my @names = qw(404.html Thing::Depot.3p.html index.html manuals.html
	    readme.html tool.1.html);
	for my $name (@names) {
		my @en = heading_ids( read_page("$out/en/$name") );
		my @zh = heading_ids( read_page("$out/zh-hans/$name") );
		ok( scalar @en, "en/$name holds a heading" );
		is_deeply( \@zh, \@en, "zh-hans/$name takes the ids of en/$name" );
	}

	# lowdown(1) gives a heading of Han text the id section, and a
	# heading of Han text and Latin letters the id of the letters.
	my $readme = read_page("$out/zh-hans/readme.html");
	is_deeply(
		[ heading_ids($readme) ],
		[qw(readme install for-the-cto)],
		'the Markdown page of zh-Hans takes the ids of en'
	);
	like( $readme, qr{<h2 id="install">\xe5\xae\x89\xe8\xa3\x85</h2>},
		'and keeps the text of each heading' );
	unlike( $readme, qr{id="(?:section|cto)}, 'and no id of lowdown' );

	# WEB-MANUALS-9 to WEB-MANUALS-11. A manual page opens with its
	# title. It holds no head and no foot of mandoc(1), its sections
	# are h2 and its subsections h3, and it holds each character
	# outside ASCII as text.
	my %manual = (
		'en/tool.1.html' => [
			'tool(1)', [ 'NAME', 'DESCRIPTION' ], 'Install',
			"<code class=\"Nm\">tool</code> \xe2\x80\x94"
		],
		'zh-hans/tool.1.html' => [
			'tool(1)', [ 'NAME', "\xe6\x8f\x8f\xe8\xbf\xb0" ],
			"\xe5\xae\x89\xe8\xa3\x85",
			"\xe5\xb7\xa5\xe5\x85\xb7"
		],
		'en/Thing::Depot.3p.html' => [
			'Thing::Depot(3p)', [ 'NAME', 'DESCRIPTION' ], 'Part',
			'the persistence contract'
		],
		'zh-hans/Thing::Depot.3p.html' => [
			'Thing::Depot(3p)', [ 'NAME', "\xe6\x8f\x8f\xe8\xbf\xb0" ],
			"\xe9\x83\xa8\xe5\x88\x86",
			"Thing::Depot - \xe5\xb7\xa5\xe5\x85\xb7"
		],
	);
	for my $page ( sort keys %manual ) {
		my ( $title, $sections, $subsection, $text ) =
		    @{ $manual{$page} };
		my $html = read_page("$out/$page");

		like( $html, qr{<main>\n<h1>\Q$title\E</h1>\n<div class="manual-text">\n},
			"$page opens with its title" );
		unlike( $html, qr{class="(?:head|foot)\b},
			"$page holds no head and no foot of mandoc" );
		is( scalar( () = main_of($html) =~ /<h1\b/g ), 1,
			"$page holds one h1" );
		like(
			$html,
			qr{<h2 class="Sh" id="NAME">\Q$sections->[0]\E</h2>.*<h2 class="Sh" id="DESCRIPTION">\Q$sections->[1]\E</h2>}s,
			"$page holds each section heading as an h2, with the id of en"
		);
		like( $html, qr{<h3 class="Ss" id="[^"]+">\Q$subsection\E</h3>},
			"$page holds the subsection heading as an h3" );
		unlike( $html, qr{&#x}, "$page holds no character reference" );
		like( $html, qr{\Q$text\E}, "$page holds its text as UTF-8" );
	}
};

subtest 'a link to a section of a translated manual names the id of en' => sub {
	# WEB-OUTLINE-4. mandoc(1) writes .Sx BESCHREIBUNG as a link to
	# #BESCHREIBUNG, and the heading takes the id DESCRIPTION of en.
	# mandoc 1.14.6 gives a heading of Han text no id, and writes .Sx
	# of that text as a link to an id that no heading holds. The whole
	# check runs over the build, so a link that names no id fails it.
	my $root = project(
		%ZH,
		'.fuguwebrc' => $ZH{'.fuguwebrc'} . <<'RC',

language de {
	name = Deutsch
}

manuals de manuals {
	dir = man/de
}
RC
		'man/tool.1' => <<'MDOC',
.Dd $Mdocdate: July 27 2026 $
.Dt TOOL 1
.Os
.Sh NAME
.Nm tool
.Nd a tool
.Sh DESCRIPTION
See
.Sx INSTALL .
.Sh INSTALL
See
.Sx DESCRIPTION .
MDOC
		'man/de/tool.1' => <<'MDOC',
.Dd $Mdocdate: July 27 2026 $
.Dt TOOL 1
.Os
.Sh NAME
.Nm tool
.Nd ein Werkzeug
.Sh BESCHREIBUNG
Siehe
.Sx INSTALLATION .
.Sh INSTALLATION
Siehe
.Sx BESCHREIBUNG .
MDOC
		'man/zh-hans/tool.1' => <<"MDOC",
.Dd \$Mdocdate: July 27 2026 \$
.Dt TOOL 1
.Os
.Sh NAME
.Nm tool
.Nd \xe5\xb7\xa5\xe5\x85\xb7
.Sh \xe6\x8f\x8f\xe8\xbf\xb0
\xe8\xa7\x81
.Sx \xe5\xae\x89\xe8\xa3\x85 .
.Sh \xe5\xae\x89\xe8\xa3\x85
\xe8\xa7\x81
.Sx \xe6\x8f\x8f\xe8\xbf\xb0 .
MDOC
	);
	my $out  = tempdir( CLEANUP => 1 ) . '/out';
	my $site = site( $root, $out );
	ok( $site->build, 'the build succeeds' );

	my @problems =
	    App::FuguWeb::Check->new( config => $site->config, out => $out )->run;
	is( scalar @problems, 0, 'and the check finds no problem' )
	    or diag join "\n", @problems;

	my %link = (
		'de/tool.1.html' => [ 'BESCHREIBUNG', 'INSTALLATION' ],
		'zh-hans/tool.1.html' =>
		    [ "\xe6\x8f\x8f\xe8\xbf\xb0", "\xe5\xae\x89\xe8\xa3\x85" ],
	);
	for my $page ( sort keys %link ) {
		my ( $description, $install ) = @{ $link{$page} };
		my $html = read_page("$out/$page");
		like( $html, qr{<h2 class="Sh" id="INSTALL">\Q$install\E</h2>},
			"$page gives the heading the id of en" );
		like( $html, qr{<a class="Sx" href="#INSTALL">\Q$install\E</a>},
			'and the link to it names that id' );
		like( $html,
			qr{<a class="Sx" href="#DESCRIPTION">\Q$description\E</a>},
			'and so does the link to the other section' );
	}
};

subtest 'a translation that leaves the outline fails the build' => sub {
	# WEB-OUTLINE-1. The message names the page, the language and the
	# position of the first heading that differs.
	my %case = (
		'zh-hans/README.md' => [
			$ZH{'zh-hans/README.md'} . "\n## \xe9\xa2\x9d\xe5\xa4\x96\n",
			'zh-hans/readme.html', 4
		],
		'man/zh-hans/tool.1' => [
			$ZH{'man/zh-hans/tool.1'} =~ s/^\.Ss /.Sh /mr,
			'zh-hans/tool.1.html', 4
		],
		'web/zh-hans/index.body.html' => [
			"<h2>\xe9\xa6\x96\xe9\xa1\xb5</h2>\n", 'zh-hans/index.html', 1
		],
	);

	for my $source ( sort keys %case ) {
		my ( $text, $page, $position ) = @{ $case{$source} };
		my $root = project( %ZH, $source => $text );
		my $out  = tempdir( CLEANUP => 1 ) . '/out';

		my $said = '';
		open my $saved, '>&', \*STDERR or die "Cannot save stderr: $!";
		close STDERR;
		open STDERR, '>', \$said or die 'Cannot capture stderr';

		my $config = App::FuguWeb::Config->load(
			root  => $root,
			error => \my $reason
		);
		my $built =
		    App::FuguWeb::Site->new( config => $config, out => $out )
		    ->build;

		close STDERR;
		open STDERR, '>&', $saved or die "Cannot restore stderr: $!";

		ok( !$built, "a $source that leaves the outline fails the build" );
		like( $said,
			qr{\Q$page\E: the outline of zh-Hans differs from en at heading $position\b},
			'and the message names the page, the language and the heading'
		);
	}
};

subtest 'a stale staging directory does not reach the next build' => sub {
	my $root = project();
	my $out  = tempdir( CLEANUP => 1 ) . '/out';

	# mandoc reads a cross-reference as a local link when a file of
	# that name sits in its working directory. A stale source left
	# by an interrupted build would therefore turn a reference that
	# belongs on the manual host into a link that leads nowhere.
	open my $fh, '>>', "$root/man/tool.1"
	    or die "Cannot extend the source: $!";
	print {$fh} ".Sh SEE ALSO\n.Xr ghost 1\n";
	close $fh;

	make_path("$out/.man/en");
	open my $ghost, '>', "$out/.man/en/ghost.1"
	    or die "Cannot write the stale source: $!";
	print {$ghost} ".Dd \$Mdocdate: July 27 2026 \$\n.Dt GHOST 1\n.Os\n"
	    . ".Sh NAME\n.Nm ghost\n.Nd a source no group names\n";
	close $ghost;

	ok( site( $root, $out )->build, 'the build succeeds' );
	ok( !-e "$out/.man",         'and the staging directory is gone' );
	ok( !-e "$out/en/ghost.1.html", 'the stale source rendered nothing' );

	open my $page, '<', "$out/en/tool.1.html" or die "Cannot read: $!";
	my $html = do { local $/; <$page> };
	close $page;

	like( $html, qr{href="https://man\.openbsd\.org/ghost\.1"},
		'and the cross-reference still leaves for the manual host' );
};

subtest 'a page the site no longer holds is removed' => sub {
	my $root = project();
	my $out  = tempdir( CLEANUP => 1 ) . '/out';

	ok( site( $root, $out )->build, 'the first build succeeds' );
	ok( -e "$out/en/tool.1.html", 'the manual has a page' );

	rename "$root/man/tool.1", "$root/man/renamed.1"
	    or die "Cannot rename the source: $!";

	ok( site( $root, $out )->build, 'the second build succeeds' );
	ok( -e "$out/en/renamed.1.html", 'the new page is there' );
	ok( !-e "$out/en/tool.1.html",   'and the old one is gone' );
};

subtest 'the build removes a stale page and keeps a dropped tree' => sub {
	my $root = project(%DE);
	my $out  = tempdir( CLEANUP => 1 ) . '/out';

	ok( site( $root, $out )->build, 'the first build succeeds' );

	# A plain file at the top level, and a stale page of a declared
	# tree, are files that a build writes, per WEB-OUTPUT-1.
	for my $stale (qw(manuals.html de/gone.html)) {
		open my $fh, '>', "$out/$stale" or die "Cannot write: $!";
		print {$fh} "<h1>Stale</h1>\n";
		close $fh;
	}

	ok( site( $root, $out )->build, 'the second build succeeds' );
	ok( !-e "$out/$_", "$_ is gone" ) for qw(manuals.html de/gone.html);
	ok( -e "$out/de/index.html", 'the tree of de stays' );
	ok( -e "$out/index.html",    'and so does the forward' );

	# WEB-OUTPUT-4. The tree of a language that the description
	# dropped holds the files of whoever made it. The build keeps
	# it and reports it, and the clean refuses it.
	open my $rc, '>', "$root/.fuguwebrc" or die "Cannot write: $!";
	print {$rc} $RC;
	close $rc;

	my $said = '';
	open my $saved, '>&', \*STDERR or die "Cannot save stderr: $!";
	close STDERR;
	open STDERR, '>', \$said or die 'Cannot capture stderr';

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	my $built =
	    App::FuguWeb::Site->new( config => $config, out => $out )->build;

	close STDERR;
	open STDERR, '>&', $saved or die "Cannot restore stderr: $!";

	ok( $built, 'a build of en alone succeeds' );
	ok( -e "$out/de/index.html", 'and keeps the tree of de' );
	like( $said,
		qr{de/index\.html is in the output, and the site does not name it},
		'and reports it' );
	ok( !site( $root, $out )->clean, 'which the clean refuses' );
	ok( -e "$out/en/index.html", 'and removes nothing' );

	# A tree is one flat directory of pages. A deeper directory of
	# a tree belongs to whoever made it, and the build keeps it.
	$root = project();
	$out  = tempdir( CLEANUP => 1 ) . '/out';
	make_path("$out/en/deep");
	open my $fh, '>', "$out/en/deep/keep.txt" or die "Cannot write: $!";
	print {$fh} "important\n";
	close $fh;

	ok( site( $root, $out )->build, 'a build succeeds' );
	ok( -e "$out/en/deep/keep.txt", 'and keeps the deeper file' );
	ok( !site( $root, $out )->clean, 'which the clean refuses' );
	ok( -e "$out/en/index.html", 'and removes nothing' );
};

subtest 'the build refuses an output directory it must not own' => sub {
	my $root = project();

	# Every refused target, and the home directory through a HOME
	# of this test alone. --out reaches build and clean alike, and
	# the setting it overrides is checked in the description.
	my $home = tempdir( CLEANUP => 1 );
	local $ENV{HOME} = $home;

	my @bad = (
		$root, '/', "$root/..", File::Spec->rootdir,
		$home, "$root/web",
	);

	for my $bad (@bad) {
		ok( !site( $root, $bad )->build,
			"the build refuses $bad" );
		ok( !site( $root, $bad )->clean,
			"and the clean refuses it too" );
	}

	ok( -e "$root/.fuguwebrc",           'the project is untouched' );
	ok( -e "$root/web/index.body.html",  'and the source with it' );
	ok( -d $home,                        'and the home directory' );

	# A directory that no rule names still builds. The guard is
	# not "inside the project": the tests and the CI both build
	# into a temporary directory outside it.
	my $good = tempdir( CLEANUP => 1 ) . '/out';
	ok( site( $root, $good )->build, "the build takes $good" );

	# The output directory that the description names is the one
	# exception below the source. This description names out, so
	# web/build is a directory of the source like any other.
	ok( !site( $root, "$root/web/build" )->build,
		'the build refuses a source directory that it does not own' );
	ok( !site( $root, "$root/web/build" )->clean,
		'and the clean refuses it too' );
	ok( -e "$root/web/index.body.html", 'the source is untouched' );

	# WEB-OUTPUT-17. On a file system without case, WEB is the
	# source directory web, so each refusal folds the paths.
	ok( !site( $root, "$root/WEB" )->build,
		'the build refuses the source directory in another case' );
	ok( !site( $root, "$root/WEB" )->clean,
		'and the clean refuses it too' );
	ok( -e "$root/web/index.body.html", 'the source is untouched' );

	# t/web/site.t builds the description of this repository, which
	# names neither setting and therefore takes web/build.
};

subtest 'the exception reads the output directory as it stands' => sub {
	# WEB-OUTPUT-13 and WEB-OUTPUT-17. On a file system with case,
	# web/BUILD is a directory of the source, and not the output
	# directory web/build. A fold of the exception would let the
	# build own it. The skip comes before the first assertion.
	my $probe = tempdir( CLEANUP => 1 );
	open my $fh, '>', "$probe/case" or die "Cannot write: $!";
	close $fh;
	plan skip_all => 'the file system of the temporary directory has'
	    . ' no case'
	    if -e "$probe/CASE";

	my $root = project();
	open $fh, '>', "$root/.fuguwebrc" or die "Cannot write: $!";
	print {$fh} $RC =~ s{^out_dir\s+= out$}{out_dir    = web/build}mr;
	close $fh;

	ok( !site( $root, "$root/web/BUILD" )->build,
		'the build refuses the output directory in another case' );
	ok( !-e "$root/web/BUILD", 'and makes nothing' );
	ok( !site( $root, "$root/web/BUILD" )->clean,
		'and the clean refuses it too' );
	ok( site( $root, "$root/web/build" )->build,
		'the build takes the output directory as it stands' );
};

subtest 'the build and the clean refuse a target that holds a source' => sub {
	# WEB-OUTPUT-18. The prune removes each plain file of the top
	# level that the site does not name, and the clean removes the
	# whole target. Each one would remove a source that the target
	# holds.
	my $blocks = <<'RC';

page "about.html" {
	title    = About
	markdown = doc/about.md
}

manuals demo {
	heading = Demo
	dir     = man/demo
}
RC
	my %more = (
		'doc/about.md'    => "# About\n\nWords.\n",
		'theme/style.css' => "body{}\n",
		'man/demo/demo.1' => <<'MDOC',
.Dd $Mdocdate: July 27 2026 $
.Dt DEMO 1
.Os
.Sh NAME
.Nm demo
.Nd a demo
.Sh DESCRIPTION
Words.
MDOC
	);

	# The out_dir of the description, the target, and what the
	# message says of the source that the target would lose. The
	# source directory is the output directory of the first one,
	# and the exception of WEB-OUTPUT-13 must not take it. DOC
	# is doc on a file system without case, per WEB-OUTPUT-17.
	my @cases = (
		[ 'web', 'web',      'holds the source', 'web/footer.body.html' ],
		[ 'doc', 'doc',      'holds the source', 'doc/about.md' ],
		[ 'out', 'doc',      'holds the source', 'doc/about.md' ],
		[ 'out', 'DOC',      'holds the source', 'doc/about.md' ],
		[ 'out', 'theme',    'holds the source', 'theme/style.css' ],
		[ 'out', 'man/demo', 'holds the source', 'man/demo/demo.1' ],
		[ 'out', 'lib/Thing/build', 'is inside the source', 'lib/Thing' ],
	);

	for my $case (@cases) {
		my ( $setting, $target, $relation, $source ) = @$case;

		my $root = project(%more);
		open my $fh, '>', "$root/.fuguwebrc" or die "Cannot write: $!";
		print {$fh} "stylesheet = theme/style.css\n",
		    $RC =~ s{^out_dir\s+= out$}{out_dir    = $setting}mr, $blocks;
		close $fh;

		my $before = tree($root);
		for my $command (qw(build clean)) {
			my ( $done, $said ) =
			    said( $root, "$root/$target", $command );
			ok( !$done,
				"the $command refuses $target with out_dir $setting"
			);
			like(
				$said,
qr{The output directory \Q$root/$target\E \Q$relation\E \Q$root/$source\E\n},
				'and the message names the source'
			);
			is_deeply( tree($root), $before,
				'and the project is untouched' );
		}
	}

	# The exception of WEB-OUTPUT-13 still takes a target inside the
	# source directory that holds no source.
	my $root = project();
	open my $fh, '>', "$root/.fuguwebrc" or die "Cannot write: $!";
	print {$fh} $RC =~ s{^out_dir\s+= out$}{out_dir    = web/build}mr;
	close $fh;

	ok( site( $root, "$root/web/build" )->build,
		'the build takes the output directory inside the source' );
	ok( -e "$root/web/index.body.html", 'and the source stays' );
	ok( site( $root, "$root/web/build" )->clean,
		'and the clean takes it too' );
	ok( !-e "$root/web/build", 'which is gone' );
};

subtest 'clean takes the trees and the staging of a build' => sub {
	my $root = project(%DE);
	my $out  = tempdir( CLEANUP => 1 ) . '/out';
	ok( site( $root, $out )->build, 'the build succeeds' );

	# A stale page of a declared tree and the staging of an
	# interrupted build are both shapes that a build writes, per
	# WEB-OUTPUT-5.
	make_path("$out/.man/de");
	for my $made (qw(de/gone.html .man/de/tool.1)) {
		open my $fh, '>', "$out/$made" or die "Cannot write: $!";
		print {$fh} "made\n";
		close $fh;
	}

	ok( site( $root, $out )->clean, 'the clean succeeds' );
	ok( !-e $out,                    'and the directory is gone' );
};

subtest 'the build refuses a staging directory of another shape' => sub {
	my $root = project();

	# WEB-OUTPUT-14. A build stages one flat directory of plain
	# files for each language. A plain file at the top of the
	# staging directory, and a directory of another name, are
	# each somebody else's.
	for my $stray ( '.man/tool.1', '.man/mine/notes.txt', '.man/en/deep/x.1' )
	{
		my $out = tempdir( CLEANUP => 1 ) . '/out';
		make_path( "$out/" . ( $stray =~ s{/[^/]+\z}{}r ) );
		open my $fh, '>', "$out/$stray" or die "Cannot write: $!";
		print {$fh} "theirs\n";
		close $fh;

		ok( !site( $root, $out )->build, "the build refuses $stray" );
		ok( -e "$out/$stray",            'and removes nothing' );
		ok( !site( $root, $out )->clean, 'and the clean refuses it too' );
	}
};

subtest 'clean refuses a directory that no build made' => sub {
	my $root = project();
	my $out  = tempdir( CLEANUP => 1 ) . '/out';
	make_path("$out/deep");

	open my $fh, '>', "$out/deep/keep.txt" or die "Cannot write: $!";
	print {$fh} "important\n";
	close $fh;

	ok( !site( $root, $out )->clean, 'clean fails' );
	ok( -e "$out/deep/keep.txt",     'and removes nothing' );
};

subtest 'the prune and the clean read each name as it stands' => sub {
	# WEB-OUTPUT-17. Two names of one fold cannot both stand on a
	# file system without case, so the test runs on a file system
	# with case alone. The skip comes before the first assertion.
	my $probe = tempdir( CLEANUP => 1 );
	open my $fh, '>', "$probe/case" or die "Cannot write: $!";
	close $fh;
	plan skip_all => 'the file system of the temporary directory has'
	    . ' no case'
	    if -e "$probe/CASE";

	my $root = project();
	my $out  = tempdir( CLEANUP => 1 ) . '/out';
	ok( site( $root, $out )->build, 'the first build succeeds' );

	# EN is no tree of the language en, and STYLE.CSS is no name
	# of the site.
	make_path("$out/EN");
	for my $made (qw(EN/index.html STYLE.CSS)) {
		open my $fh, '>', "$out/$made" or die "Cannot write: $!";
		print {$fh} "theirs\n";
		close $fh;
	}

	ok( site( $root, $out )->build, 'the second build succeeds' );
	ok( -e "$out/EN/index.html", 'and keeps the page of EN' );
	ok( !-e "$out/STYLE.CSS",    'and removes STYLE.CSS' );
	ok( -e "$out/style.css",     'and keeps the stylesheet' );

	ok( !site( $root, $out )->clean, 'the clean refuses EN' );
	ok( -e "$out/EN/index.html",     'and removes nothing' );
};

done_testing();
