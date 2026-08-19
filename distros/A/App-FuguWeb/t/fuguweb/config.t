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
	my ( $config, $reason ) = load_rc("site = Example\n");
	ok( $config, 'a description with only a site loads' )
	    or diag $reason;

	is( $config->site,        'Example',   'site' );
	is( $config->lang,        'en',        'lang' );
	is( $config->out_dir,     'web/build', 'out_dir' );
	is( $config->source_dir,  'web',       'source_dir' );
	is( $config->entry,       'index.html', 'entry' );
	is( $config->module_root, 'lib',        'module_root' );
	is( $config->mandoc_os,   'OpenBSD',    'mandoc_os' );
	is( $config->man_url, 'https://man.openbsd.org/', 'man_url' );
	is( $config->stylesheet,  undef, 'stylesheet is searched for' );
	is( scalar $config->nav,   0, 'no navigation' );
	is( scalar $config->pages, 0, 'no page' );
};

subtest 'every setting overrides its default' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site        = Example
lang        = sv
out_dir     = out
source_dir  = site
entry       = home.html
module_root = code
mandoc_os   = Example OS
man_url     = https://man.example.org/
stylesheet  = site/base.css
RC
	ok( $config, 'the description loads' ) or diag $reason;

	is( $config->lang,        'sv',                'lang' );
	is( $config->out_dir,     'out',               'out_dir' );
	is( $config->source_dir,  'site',              'source_dir' );
	is( $config->entry,       'home.html',         'entry' );
	is( $config->module_root, 'code',              'module_root' );
	is( $config->mandoc_os,   'Example OS',        'mandoc_os' );
	is( $config->man_url, 'https://man.example.org/', 'man_url' );
	is( $config->stylesheet,  'site/base.css',     'stylesheet' );
};

subtest 'root, path and source_path' => sub {
	my ( $config, $reason, $root ) = load_rc("site = Example\n");
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

page "index.html" {
	title = Home
	body  = index.body.html
}

page "manuals.html" {
	title = Manuals
	index = yes
}

manuals "Manuals" {
	dir    = man
	anchor = manuals
}
RC
	mkdir "$root/man" or die "Cannot create the directory: $!";
	mkdir "$root/web" or die "Cannot create the directory: $!";

	for my $pair (
		[ 'man/tool.1'          => ".Sh NAME\n.Nd a tool\n" ],
		[ 'web/index.body.html' => "<h1>Home</h1>\n" ],
		[ 'web/robots.txt'      => "User-agent: *\n" ] )
	{
		open my $fh, '>', "$root/$pair->[0]"
		    or die "Cannot write $pair->[0]: $!";
		print {$fh} $pair->[1];
		close $fh;
	}

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	ok( $config, 'the description loads' ) or diag $reason;

	# The pages, one page per manual, the stylesheet, and the
	# assets. The body fragment is a source and never an asset.
	is_deeply(
		[ $config->inventory ],
		[ qw(index.html manuals.html tool.1.html style.css
		    robots.txt) ],
		'every name the output must hold, and nothing else'
	);
};

subtest 'the navigation keeps its file order' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example

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

	is( $pages[3]{title}, '404.html',
		'a page with no title takes its file name' );
	ok( $pages[3]{unlinked}, 'unlinked = yes' );
};

subtest 'a page block names exactly one source' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example

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
};

subtest 'a nav block needs a label' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example

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
out_dir = ../elsewhere
RC
	is( $config, undef, 'a .. in out_dir fails the load' );
	like( $reason, qr/out_dir is \.\.\/elsewhere/,
		'the message names the setting and the value' );

	( $config, $reason ) = load_rc( <<'RC' );
site = Example

page "index.html" {
	body = ../../etc/passwd
}
RC
	is( $config, undef, 'a .. in a page source fails the load' );
	like( $reason, qr/page "index\.html" body names/,
		'the message names the block' );

	( $config, $reason ) = load_rc( <<'RC' );
site    = Example
out_dir = ..config/build
RC
	ok( $config, 'a name that merely starts with two dots is fine' )
	    or diag $reason;
};

subtest 'a page name stays inside the output directory' => sub {
	# The block name becomes a file in the output, so it is a path
	# and needs the guard the sources get.
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example

page "../../ESCAPED.html" {
	body = index.body.html
}
RC
	is( $config, undef, 'a .. in a page name fails the load' );
	like( $reason, qr/leaves the output directory/, 'and says why' );

	( $config, $reason ) = load_rc( <<'RC' );
site = Example

page "/etc/passwd" {
	body = index.body.html
}
RC
	is( $config, undef, 'an absolute page name fails the load' );
	like( $reason, qr/is an absolute path/, 'and says why' );
};

subtest 'an unlinked value that does not parse is a typo' => sub {
	my ( $config, $reason ) = load_rc( <<'RC' );
site = Example

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
	my $root = write_rc("site = Example\n");
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

subtest 'a namespace is a name and not a path' => sub {
	my $root = write_rc( <<'RC' );
site = Example

manuals "Manuals" {
	dir       = man
	anchor    = manuals
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
module_root = lib

modules "Elsewhere" {
	dir    = docs
	anchor = elsewhere
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

done_testing();
