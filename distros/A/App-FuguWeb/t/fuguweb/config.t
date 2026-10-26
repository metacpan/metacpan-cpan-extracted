#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Config: the defaults, the accessors, and every way a
# site description can be wrong.
#
# The test builds each description in a File::Temp directory. It never
# reads the repository, so a change to .fuguwebrc cannot break it.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use_ok('App::FuguWeb::Config');

# write_rc($text):
#	Write a .fuguwebrc in a new temporary directory and return the
#	directory.
sub write_rc ($text)
{
	my $root = tempdir( CLEANUP => 1 );
	open my $fh, '>', "$root/.fuguwebrc"
	    or die "Cannot write the description: $!";
	print {$fh} $text;
	close $fh;

	return $root;
}

# load_rc($text):
#	Load a description and return ($config, $reason).
sub load_rc ($text)
{
	my $root = write_rc($text);
	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );

	return ( $config, $reason, $root );
}

subtest 'the defaults' => sub {
	my ( $config, $reason ) = load_rc("site = Example\nurl = https://example.org/\n");
	ok( $config, 'a description with only a site loads' )
	    or diag $reason;

	is( $config->site,        'Example',   'site' );
	is( $config->url, 'https://example.org/', 'url' );
	is_deeply( [ map { $_->tag } $config->languages ], ['en'],
		'one language, en, per WEB-LANGUAGE-4' );
	is( $config->default_language->path, 'en', 'and its tree en' );
	is( $config->default_language->footer, undef, 'no footer' );
	is( $config->out_dir,     'web/build', 'out_dir' );
	is( $config->source_dir,  'web',       'source_dir' );
	is( $config->entry,       'index.html', 'entry' );
	is( $config->module_root, 'lib',        'module_root' );
	is( $config->man_url, 'https://man.openbsd.org/', 'man_url' );
	is( $config->stylesheet,  undef, 'stylesheet is searched for' );
	is( scalar $config->nav,   0, 'no navigation' );
	is( scalar $config->pages, 0, 'no page' );
};

subtest 'every setting overrides its default' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site        = Example
url         = https://example.org/docs/
footer      = parts/footer.body.html
out_dir     = out
source_dir  = site
entry       = home.html
module_root = code
man_url     = https://man.example.org/
stylesheet  = site/base.css
RC
	ok( $config, 'the description loads' ) or diag $reason;

	is( $config->url, 'https://example.org/docs/', 'url' );
	is( $config->default_language->footer, 'parts/footer.body.html',
		'footer' );
	is( $config->out_dir,     'out',               'out_dir' );
	is( $config->source_dir,  'site',              'source_dir' );
	is( $config->entry,       'home.html',         'entry' );
	is( $config->module_root, 'code',              'module_root' );
	is( $config->man_url, 'https://man.example.org/', 'man_url' );
	is( $config->stylesheet,  'site/base.css',     'stylesheet' );
};

subtest 'root, path and source_path' => sub {
	my ( $config, $reason, $root ) = load_rc("site = Example\nurl = https://example.org/\n");
	ok( $config, 'the description loads' ) or diag $reason;

	is( $config->root, $root,                 'root' );
	is( $config->path, "$root/.fuguwebrc",    'path' );
	is( $config->source_path, "$root/web",    'the source directory' );
	is( $config->source_path('footer.body.html'),
		"$root/web/footer.body.html",
		'one file in the source directory' );
};

subtest 'the inventory holds the whole site, once' => sub {
	my $root = write_rc( <<'RC' );
site = Example
url  = https://example.org/

page "index.html" {
	title = Home
	body  = index.body.html
}

page "manuals.html" {
	title = Manuals
	index = yes
	body  = manuals.body.html
}

manuals manuals {
	heading = Manuals
	dir     = man
}
RC
	mkdir "$root/man" or die "Cannot create the directory: $!";
	mkdir "$root/web" or die "Cannot create the directory: $!";

	for my $pair (
		[ 'man/tool.1'            => ".Sh NAME\n.Nd a tool\n" ],
		[ 'web/index.body.html'   => "<h1>Home</h1>\n" ],
		[ 'web/manuals.body.html' => "<p>Read them.</p>\n" ],
		[ 'web/robots.txt'        => "User-agent: *\n" ] )
	{
		open my $fh, '>', "$root/$pair->[0]"
		    or die "Cannot write $pair->[0]: $!";
		print {$fh} $pair->[1];
		close $fh;
	}

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	ok( $config, 'the description loads' ) or diag $reason;

	# Each page of the tree of en, the forward of the top level,
	# the stylesheet, and the assets. A body fragment is a source
	# and never an asset, and so is the body of the index page.
	# The description holds no 404 page, so the top level holds no
	# 404.html.
	is_deeply(
		[ $config->inventory ],
		[ qw(en/index.html en/manuals.html en/tool.1.html index.html
		    style.css robots.txt) ],
		'every name the output must hold, and nothing else'
	);
	is_deeply( [ $config->page_names ],
		[qw(index.html manuals.html tool.1.html)],
		'one tree holds the pages and the manuals' );
	is_deeply( [ $config->top_pages ], ['index.html'],
		'and the top level holds the forward alone' );
};

subtest 'a 404 page adds a 404.html at the top level' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

page "index.html" {
	body = index.body.html
}

page "404.html" {
	body     = 404.body.html
	unlinked = yes
}
RC
	ok( $config, 'the description loads' ) or diag $reason;

	is_deeply(
		[ $config->inventory ],
		[qw(en/index.html en/404.html index.html 404.html style.css)],
		'the tree holds the page, and the top level one more'
	);
	is_deeply( [ $config->top_pages ], [qw(index.html 404.html)],
		'the top level holds the forward and the 404.html' );
};

subtest 'the navigation keeps its file order' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

nav "index.html" {
	label = Home
}

nav "https://example.org/" {
	label = Elsewhere
}
RC
	ok( $config, 'the description loads' ) or diag $reason;

	my @nav = $config->nav;
	is( scalar @nav, 2, 'two entries' );
	is( $nav[0]{href},  'index.html',           'the first href' );
	is( $nav[0]{label}, 'Home',                 'the first label' );
	is( $nav[1]{href},  'https://example.org/', 'the second href' );
	is( $nav[1]{label}, 'Elsewhere',            'the second label' );
};

subtest 'the pages keep their file order and their source' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

page "index.html" {
	title = Home
	body  = index.body.html
}

page "install.html" {
	title    = Install
	markdown = INSTALL.md
}

page "manuals.html" {
	title = Manuals
	index = yes
}

page "404.html" {
	body     = 404.body.html
	unlinked = yes
}
RC
	ok( $config, 'the description loads' ) or diag $reason;

	my @pages = $config->pages;
	is( scalar @pages, 4, 'four pages' );

	is( $pages[0]{file},   'index.html',      'the first file' );
	is( $pages[0]{title},  'Home',            'the first title' );
	is( $pages[0]{source}, 'body',            'a body source' );
	is( $pages[0]{value},  'index.body.html', 'the fragment' );
	ok( !$pages[0]{unlinked}, 'the front page is linked' );

	is( $pages[1]{source}, 'markdown',  'a markdown source' );
	is( $pages[1]{value},  'INSTALL.md', 'the markdown file' );

	is( $pages[2]{source}, 'index', 'an index source' );
	is( $pages[2]{value},  undef,   'the index names no file' );
	is_deeply( [ map { $_->{lang} } @pages ], [qw(en en en en)],
		'each body is a body of en' );

	is( $pages[3]{title}, '404.html',
		'a page with no title takes its file name' );
	ok( $pages[3]{unlinked}, 'unlinked = yes' );
};

subtest 'a page block names exactly one source' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

page "index.html" {
	body     = index.body.html
	markdown = README.md
}
RC
	is( $config, undef, 'two sources fail the load' );
	like( $reason, qr/page "index\.html" names body and markdown/,
		'the message names the block and both sources' );

	( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

page "index.html" {
	title = Home
}
RC
	is( $config, undef, 'no source fails the load' );
	like( $reason, qr/page "index\.html" names no source/,
		'the message names the block' );
};

subtest 'a page file belongs to one block' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

page "index.html" {
	body = index.body.html
}

page "index.html" {
	body = other.body.html
}
RC
	is( $config, undef, 'a page declared twice fails the load' );
	like( $reason, qr/page "index\.html" is declared twice/,
		'the message names the page' );

	# WEB-OUTPUT-17. A file system without case keeps the two names
	# as one file, so the test folds each name.
	( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

page "about.html" {
	body = about.body.html
}

page "ABOUT.html" {
	body = other.body.html
}
RC
	is( $config, undef, 'a page in another case fails the load' );
	like( $reason, qr/page "ABOUT\.html" is declared twice/,
		'the message names the page' );
};

subtest 'a nav block needs a label' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

nav "index.html" {
}
RC
	is( $config, undef, 'a nav block with no label fails the load' );
	like( $reason, qr/nav "index\.html" has no label/,
		'the message names the block' );
};

subtest 'a path setting stays inside the project' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site    = Example
url     = https://example.org/
out_dir = ../elsewhere
RC
	is( $config, undef, 'a .. in out_dir fails the load' );
	like( $reason, qr/out_dir is \.\.\/elsewhere/,
		'the message names the setting and the value' );

	( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

page "index.html" {
	body = ../../etc/passwd
}
RC
	is( $config, undef, 'a .. in a page source fails the load' );
	like( $reason, qr/page "index\.html" body names/,
		'the message names the block' );

	( $config, $reason ) = load_rc( <<'RC' );
site    = Example
url     = https://example.org/
out_dir = ..config/build
RC
	ok( $config, 'a name that merely starts with two dots is fine' )
	    or diag $reason;

	# WEB-SITE-7. The record of the translations sits at the
	# project root, per WEB-STATUS-1, and the build publishes each
	# plain file of the source directory.
	for my $dir ( '.', './', './.', './/', '""' ) {
		( $config, $reason ) = load_rc( <<"RC" );
site       = Example
url        = https://example.org/
source_dir = $dir
RC
		is( $config, undef, "a source_dir of $dir fails the load" );
		like( $reason, qr/source_dir is .*, which is the project root/,
			'and the message names the setting' );
	}

	( $config, $reason ) = load_rc( <<'RC' );
site       = Example
url        = https://example.org/
source_dir = ./web
RC
	ok( $config, 'a source_dir below the root is fine' ) or diag $reason;
};

subtest 'a page name stays inside the output directory' => sub {
	# The block name becomes a file in the output, so it is a path
	# and needs the guard the sources get.
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

page "../../ESCAPED.html" {
	body = index.body.html
}
RC
	is( $config, undef, 'a .. in a page name fails the load' );
	like( $reason, qr/leaves the output directory/, 'and says why' );

	( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

page "/etc/passwd" {
	body = index.body.html
}
RC
	is( $config, undef, 'an absolute page name fails the load' );
	like( $reason, qr/is an absolute path/, 'and says why' );

	# Each language tree is one flat directory of pages. A name
	# with a solidus writes into a directory below the tree, and
	# the build would fail at the write with a reason that names
	# no page.
	for my $name ( 'keys/index.html', '.man/tool.1.html', 'a/b.html' ) {
		( $config, $reason ) = load_rc( <<"RC" );
site = Example
url  = https://example.org/

page "$name" {
	body = index.body.html
}
RC
		is( $config, undef, "the page name $name fails the load" );
		like( $reason, qr/holds a solidus/, "and says why for $name" );
	}
};

subtest 'an unlinked value that does not parse is a typo' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

page "index.html" {
	body     = index.body.html
	unlinked = probably
}
RC
	is( $config, undef, 'the load fails' );
	like( $reason, qr/sets unlinked to probably; use yes or no/,
		'and names the value' );
};

subtest 'a symlink in the source directory fails the load' => sub {
	my $root = write_rc("site = Example\nurl = https://example.org/\n");
	mkdir "$root/web" or die "Cannot create the source directory: $!";

	open my $fh, '>', "$root/secret.txt" or die "Cannot write: $!";
	print {$fh} "TOPSECRET\n";
	close $fh;

	# Every file in the source directory that the build does not
	# render is copied into the site. A symlink would publish
	# whatever it points at, from anywhere on the machine.
	symlink "$root/secret.txt", "$root/web/notes.txt"
	    or plan skip_all => 'this filesystem has no symlinks';

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	is( $config, undef, 'the load fails' );
	like( $reason, qr{web/notes\.txt is a symlink}, 'and names the file' );
};

subtest 'a symlink on the path of a fragment fails the load' => sub {
	my $rc = <<'RC';
site = Example
url  = https://example.org/

language en {
	name = English
}

language de {
	name   = Deutsch
	footer = de/footer.body.html
}

page "index.html" {
	body = index.body.html
}

page de "index.html" {
	body = de/parts/index.body.html
}
RC

	# Each case takes a new project: the description, the source
	# directory, and a secret directory outside of it.
	my $project = sub ($text) {
		my $root = write_rc($text);
		make_path( "$root/web", "$root/secret" );

		open my $fh, '>', "$root/secret/secret.txt"
		    or die "Cannot write: $!";
		print {$fh} "TOPSECRET\n";
		close $fh;

		return $root;
	};
	my $load = sub ($root) {
		my $config = App::FuguWeb::Config->load(
			root  => $root,
			error => \my $reason
		);
		return ( $config, $reason );
	};

	# The build reads the footer of a language below the source
	# directory, and copies it into each page of the tree.
	my $root = $project->($rc);
	make_path("$root/web/de");
	symlink "$root/secret/secret.txt", "$root/web/de/footer.body.html"
	    or plan skip_all => 'this filesystem has no symlinks';

	my ( $config, $reason ) = $load->($root);
	is( $config, undef, 'a symlinked fragment of de fails the load' );
	like( $reason, qr{web/de/footer\.body\.html is a symlink},
		'and the message names it' );

	# The build reads each fragment of de through the directory.
	$root = $project->($rc);
	symlink "$root/secret", "$root/web/de"
	    or die "Cannot make the symlink: $!";

	( $config, $reason ) = $load->($root);
	is( $config, undef, 'a symlinked directory of de fails the load' );
	like( $reason, qr{web/de is a symlink;}, 'and the message names it' );

	# A directory below the top of the source directory gets the
	# same rule, on the way to the body of a page.
	$root = $project->($rc);
	make_path("$root/web/de");
	symlink "$root/secret", "$root/web/de/parts"
	    or die "Cannot make the symlink: $!";

	( $config, $reason ) = $load->($root);
	is( $config, undef, 'a symlinked directory below de fails the load' );
	like( $reason, qr{web/de/parts is a symlink;},
		'and the message names it' );

	# The output directory sits inside the source directory by
	# default. A body that a page names there is a fragment all the
	# same, and so is a body when the output directory is the
	# source directory.
	for my $out ( undef, 'web' ) {
		my $text = "site = Example\nurl = https://example.org/\n";
		$text .= "out_dir = $out\n" if defined $out;
		$text .= qq{\npage "index.html" {\n\tbody = build/x.body.html\n}\n};

		$root = $project->($text);
		make_path("$root/web/build");
		symlink "$root/secret/secret.txt", "$root/web/build/x.body.html"
		    or die "Cannot make the symlink: $!";

		my $what = defined $out ? "out_dir = $out" : 'the default out_dir';
		( $config, $reason ) = $load->($root);
		is( $config, undef, "a symlinked body in build fails, $what" );
		like( $reason, qr{web/build/x\.body\.html is a symlink},
			'and the message names it' );
	}
};

subtest 'a namespace is a name and not a path' => sub {
	my $root = write_rc( <<'RC' );
site = Example
url  = https://example.org/

manuals manuals {
	heading   = Manuals
	dir       = man
	namespace = "../../"
}
RC
	mkdir "$root/man" or die "Cannot create the directory: $!";

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	is( $config, undef, 'a separator in a namespace fails the load' );
	like( $reason, qr/holds a path separator/, 'and says why' );
};

subtest 'a modules group lives below the module root' => sub {
	my $root = write_rc( <<'RC' );
site        = Example
url         = https://example.org/
module_root = lib

modules elsewhere {
	heading = Elsewhere
	dir     = docs
}
RC
	mkdir "$root/docs" or die "Cannot create the directory: $!";

	# A directory outside the module root has no Perl name to turn
	# into, and the build would publish the whole absolute path.
	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	is( $config, undef, 'the load fails' );
	like( $reason, qr/is not below the module root/, 'and says why' );
};

subtest 'module_root drops a trailing slash' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site        = Example
url         = https://example.org/
module_root = lib/
RC
	ok( $config, 'the description loads' ) or diag $reason;

	# The value becomes the prefix that a module name drops. A
	# trailing slash would survive into it, the strip would miss,
	# and the page name would keep the whole absolute path.
	is( $config->module_root, 'lib', 'the slash is gone' );
};

subtest 'a description must name the site' => sub {
	my ( $config, $reason ) = load_rc("out_dir = build\n");
	is( $config, undef, 'no site fails the load' );
	like( $reason, qr/no site setting/, 'the message says which' );
};

subtest 'an absent file and a parse error' => sub {
	my $empty = tempdir( CLEANUP => 1 );
	my $config =
	    App::FuguWeb::Config->load( root => $empty, error => \my $reason );
	is( $config, undef, 'an absent description fails the load' );
	like( $reason, qr/\Q$empty\E\/\.fuguwebrc/,
		'the message names the path it looked for' );

	( $config, $reason ) = load_rc( <<'RC' );
site = Example
}
RC
	is( $config, undef, 'a malformed line fails the load' );
	like( $reason, qr/\.fuguwebrc:2:/,
		'the message carries the line number' );
};

subtest 'an index page takes a body that opens it' => sub {
	# WEB-MANUALS-8. The body is the value of an index page, and
	# the index writes no opening of its own.
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

page "manuals.html" {
	title = Manuals
	index = yes
	body  = manuals.body.html
}
RC
	ok( $config, 'the description loads' ) or diag $reason;

	my ($page) = $config->pages;
	is( $page->{source}, 'index',             'an index source' );
	is( $page->{value},  'manuals.body.html', 'with the body that opens it' );

	( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

page "manuals.html" {
	index    = yes
	markdown = MANUALS.md
}
RC
	is( $config, undef, 'an index page with a Markdown source fails' );
	like( $reason, qr/page "manuals\.html" names markdown and index/,
		'and names both sources' );

	( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

page "manuals.html" {
	index = yes
	body  = ../../etc/passwd
}
RC
	is( $config, undef, 'a body that leaves the project fails' );
	like( $reason, qr/page "manuals\.html" body names \.\.\/\.\.\/etc/,
		'and names the block and the setting' );
};

# The description of a site of three languages. The language blocks
# give the order, and the first one is the default.
my $LANGUAGES = <<'RC';
site = Example
url  = https://example.org/

language en {
	name = English
}

language de {
	name = Deutsch
}

language fr {
	name = Français
}

nav "index.html" {
	label = Home
}

nav "install.html" {
	label = Install
}

page "index.html" {
	title = Home
	body  = index.body.html
}

page "install.html" {
	title    = Install
	markdown = INSTALL.md
}

page "manuals.html" {
	title = Manuals
	index = yes
	body  = manuals.body.html
}

page fr "index.html" {
	title = Accueil
}

nav de "index.html" {
	label = Start
}

page de "index.html" {
	title = Start
}

page de "install.html" {
	markdown = de/INSTALL.md
}

page de "manuals.html" {
	title = Handbuch
	body  = de/manuals.body.html
}
RC

subtest 'the language blocks declare the languages' => sub {
	# WEB-LANGUAGE-5. The languages take the order of their blocks,
	# and each tree holds the same pages.
	my ( $config, $reason ) = load_rc($LANGUAGES);
	ok( $config, 'the description loads' ) or diag $reason;

	is_deeply( [ map { $_->tag } $config->languages ], [qw(en de fr)],
		'each language, in the order of its block' );
	is( $config->default_language->tag, 'en', 'the first is the default' );
	is( $config->language('fr')->name, "Fran\x{e7}ais",
		'a name is characters' );
	is( $config->language('xx'), undef, 'an undeclared tag names none' );

	# Each tree holds the same page names.
	is_deeply( [ $config->page_names ],
		[qw(index.html install.html manuals.html)],
		'one list of names serves every tree' );
	is_deeply(
		[ grep { m{/} } $config->inventory ],
		[
			map {
				my $code = $_;
				map { "$code/$_" }
				    qw(index.html install.html manuals.html)
			} qw(en de fr)
		],
		'and the inventory holds each name in each tree'
	);
};

subtest 'a translation takes each value it names' => sub {
	# WEB-LANGUAGE-8. A value of the translation, and the value of
	# the default block where the translation holds none.
	my ( $config, $reason ) = load_rc($LANGUAGES);
	ok( $config, 'the description loads' ) or diag $reason;

	my @de = $config->pages('de');
	is_deeply(
		[ map { [ $_->{file}, $_->{title}, $_->{value}, $_->{lang} ] }
			    @de ],
		[
			[ 'index.html',   'Start',    'index.body.html',      'en' ],
			[ 'install.html', 'Install',  'de/INSTALL.md',        'de' ],
			[ 'manuals.html', 'Handbuch', 'de/manuals.body.html', 'de' ],
		],
		'each page of de, in the order of the default blocks'
	);
	is( $de[2]{source}, 'index', 'the translation keeps the source' );

	# A body that the translation does not name comes from the
	# default source, and the lang says so.
	is_deeply( [ map { $_->{lang} } $config->pages('fr') ],
		[qw(en en en)], 'a page of fr with no body of its own' );
	is( ( $config->pages('fr') )[0]{title}, 'Accueil',
		'takes its title all the same' );

	# The title_lang follows the same rule for the title.
	is_deeply( [ map { $_->{title_lang} } @de ], [qw(de en de)],
		'a title of de, the default title, and a title of de' );
	is_deeply( [ map { $_->{title_lang} } $config->pages('fr') ],
		[qw(fr en en)], 'and the titles of fr' );
	is_deeply( [ map { $_->{title_lang} } $config->pages ],
		[qw(en en en)], 'and each title of en' );

	is_deeply( [ map { $_->{title} } $config->pages ],
		[qw(Home Install Manuals)], 'the default pages stay' );
	is_deeply( [ map { $_->{value} } $config->pages ],
		[qw(index.body.html INSTALL.md manuals.body.html)],
		'with their own values' );

	is_deeply( [ map { $_->{label} } $config->nav('de') ],
		[qw(Start Install)], 'a nav of de takes each label it names' );
	is_deeply( [ map { $_->{label} } $config->nav('fr') ],
		[qw(Home Install)], 'and a nav of fr takes the default' );
	is_deeply( [ map { $_->{href} } $config->nav('de') ],
		[qw(index.html install.html)], 'an href never changes' );
	is_deeply( [ map { $_->{label_lang} } $config->nav('de') ],
		[qw(de en)], 'and each label records its language' );
	is_deeply( [ map { $_->{label_lang} } $config->nav('fr') ],
		[qw(en en)], 'in each language' );
};

subtest 'a translation keeps the rules of its page' => sub {
	# A translation that names a second source makes a page of
	# two sources, which the default block cannot hold either.
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

language en {
	name = English
}

language de {
	name = Deutsch
}

page "index.html" {
	body = index.body.html
}

page de "index.html" {
	markdown = de/README.md
}
RC
	is( $config, undef, 'a page of two sources fails the load' );
	like( $reason, qr/page de "index\.html" names body and markdown/,
		'and names the translation' );

	( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

language en {
	name = English
}

language de {
	name = Deutsch
}

page "index.html" {
	body = index.body.html
}

page de "index.html" {
	body = ../../de.body.html
}
RC
	is( $config, undef, 'a body that leaves the project fails' );
	like( $reason, qr/page de "index\.html" body names \.\.\/\.\.\//,
		'and names the translation' );

	( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

language en {
	name = English
}

language de {
	name = Deutsch
}

nav "index.html" {
	label = Home
}

nav de "index.html" {
	label = ""
}
RC
	is( $config, undef, 'an empty label fails the load' );
	like( $reason, qr/nav de "index\.html" has no label/,
		'and names the translation' );
};

subtest 'a translation names a declared language' => sub {
	# WEB-LANGUAGE-6. The tag of a translation names a language
	# block, and not the default one.
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

page "index.html" {
	body = index.body.html
}

page de "index.html" {
	title = Start
}
RC
	is( $config, undef, 'a translation with no language block fails' );
	like( $reason,
qr/page de "index\.html" names the language de, and no language block declares it/,
		'and names the tag' );

	( $config, $reason ) = load_rc( $LANGUAGES . <<'RC' );

page en "index.html" {
	title = Start
}
RC
	is( $config, undef, 'a translation into the default fails the load' );
	like( $reason,
		qr/page en "index\.html" names en, which is the default language/,
		'and says why' );

	( $config, $reason ) = load_rc( $LANGUAGES . <<'RC' );

page pt-BR "index.html" {
	title = Início
}
RC
	is( $config, undef, 'a tag that no block declares fails the load' );
	like( $reason, qr/names the language pt-BR, and no language block/,
		'and names the tag' );
};

subtest 'a translation names a default block of its type' => sub {
	# WEB-LANGUAGE-6. Each failure names the block and the reason.
	my %case = (
		'page de "absent.html"' => [
			qq{page de "absent.html" {\n\ttitle = Weg\n}\n},
qr/page de "absent\.html" translates no page block, because no page "absent\.html" stands/
		],
		'nav de "absent.html"' => [
			qq{nav de "absent.html" {\n\tlabel = Weg\n}\n},
qr/nav de "absent\.html" translates no nav block, because no nav "absent\.html" stands/
		],
		'a group of the other type' => [
			qq{modules commands {\n\theading = Commands\n\tdir = lib\n}\n}
			    . qq{manuals de commands {\n\theading = Befehle\n}\n},
qr/manuals de "commands" translates no manuals block, because no manuals "commands" stands/
		],
		'a second translation' => [
			qq{page de "index.html" {\n\ttitle = Start\n}\n}
			    . qq{page de "index.html" {\n\ttitle = Anfang\n}\n},
			qr/page de "index\.html" is declared twice/
		],
		'three arguments' => [
			qq{page de at "index.html" {\n\ttitle = Start\n}\n},
qr/page de at "index\.html" takes 3 arguments, and a translation takes a language tag and a name/
		],
		'a keys block' => [
			qq{keys de "keys" {\n\torg = example\n}\n},
qr/keys de "keys" takes more than a name, and a keys block takes no translation/
		],
		'a key block' => [
			qq{key de "example-root-1" {\n\tstatus = current\n}\n},
qr/key de "example-root-1" takes more than a name, and a key block takes no translation/
		],
		'a language block' => [
			qq{language de fr {\n\tname = Fran\xc3\xa7ais\n}\n},
qr/language de "fr" takes more than a name, and a language block takes no translation/
		],
	);

	for my $name ( sort keys %case ) {
		my ( $block, $expected ) = @{ $case{$name} };
		my ( $config, $reason ) = load_rc( <<"RC" . $block );
site = Example
url  = https://example.org/

language en {
	name = English
}

language de {
	name = Deutsch
}

page "index.html" {
	body = index.body.html
}

nav "index.html" {
	label = Home
}

RC
		is( $config, undef, "$name fails the load" );
		like( $reason, $expected, "and the message says why for $name" );
	}
};

subtest 'a translation takes the settings of its language' => sub {
	# WEB-LANGUAGE-7. A setting outside the set of the type fails,
	# and the message names the set.
	my %case = (
		page => [
			qq{page de "index.html" {\n\tunlinked = yes\n}\n},
qr/page de "index\.html" names the setting unlinked, and a translation of a page block takes title, body and markdown/
		],
		nav => [
			qq{nav de "index.html" {\n\thref = elsewhere.html\n}\n},
qr/nav de "index\.html" names the setting href, and a translation of a nav block takes label/
		],
		manuals => [
			qq{manuals de manuals {\n\tnamespace = Fugu::\n}\n},
qr/manuals de "manuals" names the setting namespace, and a translation of a manuals block takes heading and dir/
		],
		modules => [
			qq{modules de modules {\n\tanchor = module\n}\n},
qr/modules de "modules" names the setting anchor, and a translation of a modules block takes heading and dir/
		],
	);

	for my $type ( sort keys %case ) {
		my ( $block, $expected ) = @{ $case{$type} };
		my $root = write_rc( <<"RC" . $block );
site = Example
url  = https://example.org/

language en {
	name = English
}

language de {
	name = Deutsch
}

page "index.html" {
	body = index.body.html
}

nav "index.html" {
	label = Home
}

manuals manuals {
	heading = Manuals
	dir     = man
}

modules modules {
	heading = Modules
	dir     = lib
}

RC
		mkdir "$root/$_" or die "Cannot create $_: $!" for qw(man lib);

		my $config = App::FuguWeb::Config->load(
			root  => $root,
			error => \my $reason
		);
		is( $config, undef, "a setting of a $type translation fails" );
		like( $reason, $expected, "and the message names the set" );
	}
};

subtest 'the url is the absolute URL of the site root' => sub {
	# WEB-SITE-1. The description takes a url of https or http that
	# ends in a solidus.
	my ( $config, $reason ) = load_rc("site = Example\n");
	is( $config, undef, 'a description with no url fails the load' );
	like( $reason, qr/no url setting/, 'and the message says which' );

	for my $url (
		'https://example.org', 'ftp://example.org/',
		'example.org/',        '//example.org/',
		'https:///',           'https://example .org/'
	    )
	{
		( $config, $reason ) =
		    load_rc("site = Example\nurl = \"$url\"\n");
		is( $config, undef, "the url $url fails the load" );
		like( $reason, qr/url is \Q$url\E, which is not an absolute URL/,
			"and the message names $url" );
	}

	for my $url ( 'https://example.org/', 'http://example.org/docs/' ) {
		( $config, $reason ) = load_rc("site = Example\nurl = $url\n");
		ok( $config, "the url $url loads" ) or diag $reason;
	}
};

subtest 'a word that fuguweb(1) does not document fails the load' => sub {
	# WEB-SITE-4. The message names the block and the word. An old
	# setting fails as an unknown setting, with no word of what to
	# write in its place.
	my %case = (
		'a setting' => [
			"colour = red\n",
			qr/: the description names the unknown setting colour\z/
		],
		'the old mandoc_os' => [
			"mandoc_os = OpenBSD\n",
			qr/: the description names the unknown setting mandoc_os\z/
		],
		'a block type' => [
			qq{widget "box" {\n\tsize = 1\n}\n},
			qr/: widget "box" names the unknown block type widget\z/
		],
		'a page setting' => [
			qq{page "index.html" {\n\tbody = i.body.html\n\tcolour = red\n}\n},
			qr/: page "index\.html" names the unknown setting colour\z/
		],
		'a nav setting' => [
			qq{nav "index.html" {\n\tlabel = Home\n\ttitle = Home\n}\n},
			qr/: nav "index\.html" names the unknown setting title\z/
		],
		'a language setting' => [
			qq{language en {\n\tname = English\n\tlabel = en\n}\n},
			qr/: language "en" names the unknown setting label\z/
		],
		'an anchor of a group' => [
			qq{manuals commands {\n\theading = Commands\n\tdir = man\n\tanchor = commands\n}\n},
			qr/: manuals "commands" names the unknown setting anchor\z/
		],
		'a namespace of a modules group' => [
			qq{modules modules {\n\theading = Modules\n\tdir = lib\n\tnamespace = "X::"\n}\n},
			qr/: modules "modules" names the unknown setting namespace\z/
		],
	);

	for my $name ( sort keys %case ) {
		my ( $text, $expected ) = @{ $case{$name} };
		my $root = write_rc( "site = Example\nurl = https://example.org/\n"
			    . $text );
		mkdir "$root/$_" or die "Cannot create $_: $!" for qw(man lib);

		my $config = App::FuguWeb::Config->load(
			root  => $root,
			error => \my $reason
		);
		is( $config, undef, "$name fails the load" );
		like( $reason, $expected, "and the message names $name" );
	}
};

subtest 'the description is UTF-8, and a value keeps each byte' => sub {
	# WEB-SITE-5. The load holds the whole description to UTF-8, and
	# the message names the file.
	my ( $config, $reason, $root ) =
	    load_rc("site = Example\nurl = https://example.org/\n# caf\xe9\n");
	is( $config, undef, 'a description that is not UTF-8 fails the load' );
	like( $reason, qr{\Q$root\E/\.fuguwebrc is not valid UTF-8 at byte 47},
		'and the message names the file and the byte' );

	# Fugu::Config of an older release trimmed the last byte of
	# voilà, because \s matched the byte 0xA0. The value reads
	# byte for byte now, as the characters of the description.
	( $config, $reason ) = load_rc( <<"RC" );
site = voil\xc3\xa0
url  = https://example.org/

nav "index.html" {
	label = voil\xc3\xa0
}

page "index.html" {
	title = \xe7\xae\x80\xe4\xbd\x93
	body  = index.body.html
}
RC
	ok( $config, 'the description loads' ) or diag $reason;

	is( $config->site, "voil\x{e0}", 'the site name is characters' );
	is( App::FuguWeb::encode( $config->site ), "voil\xc3\xa0",
		'and its bytes are those of the description' );
	is( ( $config->nav )[0]{label}, "voil\x{e0}", 'so is a label' );
	is( ( $config->pages )[0]{title}, "\x{7b80}\x{4f53}",
		'and a title' );
};

subtest 'the decode refuses each form that strict UTF-8 refuses' => sub {
	# WEB-SITE-5. The decode is strict, and each form below fails at
	# the byte after the a.
	my %form = (
		'an overlong form'         => "\xc0\xaf",
		'a surrogate'              => "\xed\xa0\x80",
		'the noncharacter U+FFFE'  => "\xef\xbf\xbe",
		'the noncharacter U+FDD0'  => "\xef\xb7\x90",
		'a code point above U+10FFFF' => "\xf4\x90\x80\x80",
	);
	for my $name ( sort keys %form ) {
		my $text =
		    App::FuguWeb::decode( "a$form{$name}b", 'the text', \my $why );
		is( $text, undef, "$name is refused" );
		like( $why, qr/^the text is not valid UTF-8 at byte 1\z/,
			'and the reason names the byte' );
	}

	is( App::FuguWeb::decode( "voil\xc3\xa0", 'the text', \my $why ),
		"voil\x{e0}", 'valid UTF-8 decodes' );
};

subtest 'the fold joins an NFC name and its NFD form' => sub {
	# WEB-OUTPUT-17. APFS keeps the NFC and the NFD form of one name
	# as one entry, so the fold takes NFD before the case fold. The
	# NFC name holds U+00E9, and the NFD name holds e and U+0301.
	my $nfc = "caf\xc3\xa9.html";
	my $nfd = "cafe\xcc\x81.html";
	isnt( $nfc, $nfd, 'the two names differ in their bytes' );
	is( App::FuguWeb::fold_name($nfd), App::FuguWeb::fold_name($nfc),
		'and the fold joins them' );
	is( App::FuguWeb::fold_name("CAFE\xcc\x81.HTML"),
		App::FuguWeb::fold_name($nfc), 'and a name in another case' );

	my ( $config, $reason ) = load_rc( <<"RC" );
site = Example
url  = https://example.org/

page "$nfc" {
	body = one.body.html
}

page "$nfd" {
	body = two.body.html
}
RC
	is( $config, undef, 'two pages of one fold fail the load' );
	like( $reason, qr/page "\Q$nfd\E" is declared twice/,
		'and the message names the second page' );
};

subtest 'a source path holds no white space and no parenthesis' => sub {
	# WEB-SITE-6. The record of the translations cannot name such a
	# path. The message names the path from the project root.
	my %case = (
		'a body' => [
			qq{page "index.html" {\n\tbody = my index.body.html\n}\n},
			'web/my index.body.html'
		],
		'a Markdown page' => [
			qq{page "index.html" {\n\tmarkdown = READ(ME).md\n}\n},
			'READ(ME).md'
		],
		'a footer' => [ "footer = foot\ter.body.html\n",
			"web/foot\ter.body.html" ],
		'a footer of a language' => [
			qq{language en {\n\tname = English\n\tfooter = (en).body.html\n}\n},
			'web/(en).body.html'
		],
		'a manual' => [
			qq{manuals manuals {\n\theading = Manuals\n\tdir = man\n}\n},
			'man/my tool.1'
		],
	);

	for my $name ( sort keys %case ) {
		my ( $text, $path ) = @{ $case{$name} };
		my $root = write_rc( "site = Example\nurl = https://example.org/\n"
			    . $text );
		make_path("$root/man");
		open my $fh, '>', "$root/man/my tool.1" or die "Cannot write: $!";
		print {$fh} ".Sh NAME\n.Nd a tool\n";
		close $fh;

		my $config = App::FuguWeb::Config->load(
			root  => $root,
			error => \my $reason
		);
		is( $config, undef, "$name fails the load" );
		like( $reason,
			qr/: the source \Q$path\E holds ASCII white space or a parenthesis/,
			"and the message names $path" );
	}

	my ( $config, $reason ) = load_rc( <<"RC" );
site = Example
url  = https://example.org/

page "index.html" {
	body = \xe7\xb4\xa2\xe5\xbc\x95.body.html
}
RC
	ok( $config, 'a path of letters outside ASCII loads' ) or diag $reason;
};

subtest 'a language block declares one language' => sub {
	# WEB-LANGUAGE-1. A tag of BCP 47 in its canonical case, which a
	# block declares once.
	for my $tag (qw(EN zh-hans zh-HANS pt-br en_US e english en-US-x de-1996))
	{
		my ( $config, $reason ) = load_rc( <<"RC" );
site = Example
url  = https://example.org/

language "$tag" {
	name = Name
}
RC
		is( $config, undef, "the tag $tag fails the load" );
		like( $reason,
			qr/language "\Q$tag\E" names no BCP 47 tag in its canonical case/,
			"and the message names $tag" );
	}

	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

language en {
	name = English
}

language en {
	name = English
}
RC
	is( $config, undef, 'a tag that two blocks declare fails the load' );
	like( $reason, qr/language "en" is declared twice/, 'and says which' );

	# WEB-LANGUAGE-2. A name, and a direction of ltr or rtl.
	( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

language en {
	dir = ltr
}
RC
	is( $config, undef, 'a language with no name fails the load' );
	like( $reason, qr/language "en" has no name/, 'and says which' );

	( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

language ar {
	name = Arabic
	dir  = right
}
RC
	is( $config, undef, 'a direction of another word fails the load' );
	like( $reason, qr/language "ar" sets dir to right; use ltr or rtl/,
		'and names the word' );

	# A tree path is the tag in lowercase, per WEB-LANGUAGE-5, and a
	# language is left to right when its block names no direction.
	( $config, $reason ) = load_rc( <<"RC" );
site = Example
url  = https://example.org/

language zh-Hans {
	name = \xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87
}

language ar {
	name = Arabic
	dir  = rtl
}

language es-419 {
	name = Espa\xc3\xb1ol
}
RC
	ok( $config, 'the description loads' ) or diag $reason;
	is_deeply(
		[ map { [ $_->tag, $_->path, $_->dir ] } $config->languages ],
		[
			[ 'zh-Hans', 'zh-hans', 'ltr' ],
			[ 'ar',      'ar',      'rtl' ],
			[ 'es-419',  'es-419',  'ltr' ],
		],
		'each tag, its tree and its direction'
	);
	is( $config->default_language->tag, 'zh-Hans',
		'the first block is the default, also when it is not en' );
	is( $config->default_language->name, "\x{7b80}\x{4f53}\x{4e2d}\x{6587}",
		'and its name is characters' );
};

subtest 'a language takes its own site and footer' => sub {
	# WEB-LANGUAGE-3 and WEB-LANGUAGE-8. The value of the language
	# block, or the value of the description when the block names
	# none. Each records the language that it comes from.
	my ( $config, $reason ) = load_rc( <<"RC" );
site   = Example
url    = https://example.org/
footer = footer.body.html

language en {
	name = English
}

language zh-Hans {
	name   = \xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87
	site   = \xe7\xa4\xba\xe4\xbe\x8b
	footer = zh-hans/footer.body.html
}

language ar {
	name = Arabic
	dir  = rtl
}
RC
	ok( $config, 'the description loads' ) or diag $reason;

	is_deeply(
		[
			map {
				[ $_->tag, $_->site, $_->site_lang, $_->footer,
					$_->footer_lang ]
			} $config->languages
		],
		[
			[ 'en', 'Example', 'en', 'footer.body.html', 'en' ],
			[
				'zh-Hans', "\x{793a}\x{4f8b}",
				'zh-Hans', 'zh-hans/footer.body.html',
				'zh-Hans'
			],
			[ 'ar', 'Example', 'en', 'footer.body.html', 'en' ],
		],
		'each site and each footer, with its language'
	);

	( $config, $reason ) = load_rc( <<'RC' );
site = Example
url  = https://example.org/

language en {
	name   = English
	footer = ../footer.body.html
}
RC
	is( $config, undef, 'a footer that leaves the project fails the load' );
	like( $reason, qr/language "en" footer is \.\.\/footer\.body\.html, which leaves the project/,
		'and names the block' );
};

done_testing();
