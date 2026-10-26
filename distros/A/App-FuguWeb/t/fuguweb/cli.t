#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::CLI: the subcommands, the global options, and the exit
# codes that a script reads.
#
# The exit codes are a contract. A caller that builds in a container
# tells a renderer that is not installed from a page that is malformed
# by the number alone, so every one of them is asserted here.
#
# The test drives the class in-process and builds each project in a
# File::Temp directory. It never reads the repository.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use_ok('App::FuguWeb::CLI');

# have($tool):
#	Report whether the program is on the path.
sub have ($tool)
{
	return system("command -v $tool >/dev/null 2>&1") == 0;
}

my $RENDERERS =
    have('mandoc') && have('lowdown') && have('pod2man');

my $RC = <<'RC';
site       = Example
url        = https://example.org/
source_dir = web
out_dir    = out

nav "index.html" {
	label = Home
}

page "index.html" {
	title = Home
	body  = index.body.html
}
RC

# project(%file):
#	A project with the standard description, plus any extra file.
sub project (%file)
{
	my $root = tempdir( CLEANUP => 1 );
	my %all  = (
		'.fuguwebrc'          => $RC,
		'web/index.body.html' => "<h1>Home</h1>\n",
		%file,
	);

	for my $relative ( sort keys %all ) {
		my $path = "$root/$relative";
		make_path( $path =~ s{/[^/]+$}{}r );

		open my $fh, '>', $path or die "Cannot write $path: $!";
		print {$fh} $all{$relative};
		close $fh;
	}

	return $root;
}

# run(@argv):
#	Run the CLI with output captured. Return ($exit, $out, $err).
sub run (@argv)
{
	my ( $out, $err ) = ( '', '' );

	open my $saved_out, '>&', \*STDOUT or die "Cannot save stdout: $!";
	open my $saved_err, '>&', \*STDERR or die "Cannot save stderr: $!";
	close STDOUT;
	close STDERR;
	open STDOUT, '>', \$out or die 'Cannot capture stdout';
	open STDERR, '>', \$err or die 'Cannot capture stderr';

	my $exit = eval { App::FuguWeb::CLI->run(@argv) };
	my $died = $@;

	close STDOUT;
	close STDERR;
	open STDOUT, '>&', $saved_out or die "Cannot restore stdout: $!";
	open STDERR, '>&', $saved_err or die "Cannot restore stderr: $!";

	die $died if $died;

	return ( $exit, $out, $err );
}

subtest 'the exit codes are the documented ones' => sub {
	is( App::FuguWeb::CLI::EXIT_SUCCESS(),       0, 'success' );
	is( App::FuguWeb::CLI::EXIT_ERROR(),         1, 'error' );
	is( App::FuguWeb::CLI::EXIT_INVALID_ARGS(),  2, 'invalid arguments' );
	is( App::FuguWeb::CLI::EXIT_CONFIG_ERROR(),  3, 'configuration' );
	is( App::FuguWeb::CLI::EXIT_RENDER_FAILED(), 4, 'a renderer failed' );
	is( App::FuguWeb::CLI::EXIT_CHECK_FAILED(),  5, 'the check failed' );
	is( App::FuguWeb::CLI::EXIT_TOOL_MISSING(),  6, 'a tool is absent' );
};

subtest 'an unknown command' => sub {
	my ( $exit, $out, $err ) = run('nonesuch');
	is( $exit, 2, 'an unknown command gives EXIT_INVALID_ARGS' );
	like( $err, qr/unknown command: nonesuch/, 'and says which' );

	( $exit, $out ) = run('help');
	is( $exit, 0, 'asking for help is not a failure' );
	like( $out, qr/\bbuild\b/, 'and the help lists the commands' );
};

subtest 'a description that is absent or broken' => sub {
	my $empty = tempdir( CLEANUP => 1 );
	my ( $exit, $out, $err ) = run( '--project', $empty, 'check' );
	is( $exit, 3, 'no description gives EXIT_CONFIG_ERROR' );
	like( $err, qr/\.fuguwebrc/, 'and names the file it looked for' );

	my $root = project( '.fuguwebrc' => "site = Example\n}\n" );
	( $exit, $out, $err ) = run( '--project', $root, 'check' );
	is( $exit, 3, 'a malformed description gives EXIT_CONFIG_ERROR' );
	like( $err, qr/\.fuguwebrc:2:/, 'and carries the line number' );
};

# The quiet option stops the informational messages alone. An exit code
# does not name the fault, so each error must still print. The end of
# the file holds the quiet subtests of the other verbs.
subtest 'quiet keeps the error of a description' => sub {
	my $empty = tempdir( CLEANUP => 1 );

	my ( $exit, $out, $err ) = run( '--quiet', '--project', $empty,
		'check' );
	is( $exit, 3, 'no description gives EXIT_CONFIG_ERROR' );
	like( $err, qr/\.fuguwebrc/, 'and names the file it looked for' );

	my $root = project( '.fuguwebrc' => $RC . "colour = red\n" );
	( $exit, $out, $err ) = run( '-q', '--project', $root, 'build' );
	is( $exit, 3, 'an unknown setting gives EXIT_CONFIG_ERROR' );
	like( $err, qr/unknown setting colour/, 'and names the setting' );
};

subtest 'init writes a starter, once' => sub {
	my $dir = tempdir( CLEANUP => 1 );

	my ( $exit, $out, $err ) = run( 'init', $dir );
	is( $exit, 0, 'init succeeds' );
	ok( -s "$dir/.fuguwebrc", 'and writes the description' );

	# WEB-SITE-1 and WEB-SITE-3. The starter names the url and the
	# footer, and it builds once the two fragments exist.
	my $config =
	    App::FuguWeb::Config->load( root => $dir, error => \my $reason );
	ok( $config, 'the starter loads' ) or diag $reason;
	is( $config->url, 'https://example.org/', 'and names a url' );
	is( $config->default_language->footer, 'footer.body.html',
		'and a footer' );

	SKIP: {
		skip 'a renderer is not installed', 1 unless $RENDERERS;

		make_path("$dir/web");
		for my $name (qw(index.body.html footer.body.html)) {
			open my $fh, '>', "$dir/web/$name" or die "Cannot write: $!";
			print {$fh} "<p>$name</p>\n";
			close $fh;
		}
		( $exit, $out, $err ) = run( '--project', $dir, 'build' );
		is( $exit, 0, 'and it builds with the two fragments' )
		    or diag $err;
	}

	( $exit, $out, $err ) = run( 'init', $dir );
	is( $exit, 1, 'a second init fails' );
	like( $err, qr/Already exists/, 'and says why' );

	( $exit, $out, $err ) = run( 'init', "$dir/nosuchdir" );
	is( $exit, 1, 'a directory that is absent fails' );
	like( $err, qr/Not a directory/, 'and says why' );
};

subtest 'clean needs no description when --out names the target' => sub {
	my $root = tempdir( CLEANUP => 1 );
	make_path("$root/out/en");

	# The forward, the stylesheet, and one page of the tree of en.
	# The clean reads the tree by its shape, because no description
	# names it.
	for my $name (qw(index.html style.css en/index.html)) {
		open my $fh, '>', "$root/out/$name" or die "Cannot write: $!";
		print {$fh} "<html></html>\n";
		close $fh;
	}

	# clean is the command an operator reaches for when the
	# description is the thing that is broken.
	my ( $exit, $out, $err ) = run( 'clean', '--out', "$root/out" );
	is( $exit, 0, 'clean succeeds with no .fuguwebrc anywhere' );
	ok( !-e "$root/out", 'and the directory is gone' );

	( $exit, $out, $err ) = run( 'clean', '--out', "$root/out" );
	is( $exit, 0, 'and it is idempotent' );
};

subtest 'clean refuses a directory that no build made' => sub {
	my $root = tempdir( CLEANUP => 1 );
	make_path("$root/victim/deep");
	open my $fh, '>', "$root/victim/deep/keep.txt" or die "Cannot: $!";
	print {$fh} "important\n";
	close $fh;

	my ( $exit, $out, $err ) = run( 'clean', '--out', "$root/victim" );
	is( $exit, 1, 'clean fails' );
	ok( -e "$root/victim/deep/keep.txt", 'and removes nothing' );
	like( $err, qr/refusing to remove it/, 'and says why' );
};

SKIP: {
	skip 'a renderer is not installed', 3 unless $RENDERERS;

	subtest 'build renders and check passes' => sub {
		my $root = project();

		my ( $exit, $out, $err ) = run( '--project', $root, 'build' );
		is( $exit, 0, 'build succeeds' ) or diag $err;
		ok( -s "$root/out/en/index.html", 'and writes the page' );
		ok( -s "$root/out/index.html",    'and the forward' );

		( $exit, $out, $err ) = run( '--project', $root, 'check' );
		is( $exit, 0,  'check passes' ) or diag $err;
		is( $err,  '', 'and says nothing' );

		( $exit, $out, $err ) =
		    run( '--project', $root, 'check', '--verbose' );
		is( $exit, 0, 'check --verbose passes too' );
	};

	subtest 'check reports a broken site with EXIT_CHECK_FAILED' => sub {
		my $root = project();
		run( '--project', $root, 'build' );

		open my $fh, '>>', "$root/out/en/index.html"
		    or die "Cannot append: $!";
		print {$fh} qq{<a href="./gone.html">Gone</a>\n};
		close $fh;

		my ( $exit, $out, $err ) = run( '--project', $root, 'check' );
		is( $exit, 5, 'a dead link gives EXIT_CHECK_FAILED' );
		like( $err, qr{gone\.html leads nowhere}, 'and names the link' );
	};

	subtest '--out is resolved against the project root' => sub {
		my $root = project();

		# The setting it overrides is relative to the project, so
		# the flag has to mean the same thing from any directory.
		my ( $exit, $out, $err ) =
		    run( '--project', $root, 'build', '--out', 'elsewhere' );
		is( $exit, 0, 'build succeeds' ) or diag $err;
		ok( -s "$root/elsewhere/en/index.html",
			'and writes below the project root' );

		( $exit, $out, $err ) =
		    run( '--project', $root, 'clean', '--out', 'elsewhere' );
		is( $exit, 0, 'clean succeeds' );
		ok( !-e "$root/elsewhere", 'and removes the same directory' );
	};
}

SKIP: {
	skip 'mandoc not found', 1 unless have('mandoc');

	subtest 'a malformed manual fails the build with the reason' => sub {
		my $root = project(
			'.fuguwebrc' => $RC . <<'RC',

manuals manuals {
	heading = Manuals
	dir     = man
}
RC
			'man/bad.1' => ".Sh NAME\n.Nm bad\n",
		);

		my ( $exit, $out, $err ) = run( '--project', $root, 'build' );
		is( $exit, 4, 'a malformed page gives EXIT_RENDER_FAILED' );

		# mandoc -Tlint writes its diagnostics to standard output,
		# so a caller that logged only stderr would report the
		# failure with no line, no column and no reason.
		like( $err, qr/mandoc rejected a manual source/,
			'the build says what failed' );
		like( $err, qr/bad\.1:\d+:\d+/,
			'and carries the line and column from mandoc' );
	};
}

subtest 'build reports a renderer that is not installed' => sub {
	my $root = project();

	# The probe runs before anything is written, so the operator
	# learns which package to install and not that the build failed.
	local $ENV{PATH} = '/nonexistent';
	my ( $exit, $out, $err ) = run( '--project', $root, 'build' );

	is( $exit, 6, 'an absent renderer gives EXIT_TOOL_MISSING' );
	like( $err, qr/mandoc is not installed/, 'and names the tool' );
	ok( !-e "$root/out", 'and the build wrote nothing' );
};

# A site of en and zh-Hans. zh-Hans names each value of its own, so
# the one part that can leave its source is the body of its page.
my $HOME = "\xe9\xa6\x96\xe9\xa1\xb5";
my $RC_ZH = <<"RC";
site       = Example
url        = https://example.org/
source_dir = web
out_dir    = out

language en {
	name = English
}

language zh-Hans {
	name = \xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87
	site = \xe7\xa4\xba\xe4\xbe\x8b
}

nav "index.html" {
	label = Home
}

nav zh-Hans "index.html" {
	label = $HOME
}

page "index.html" {
	title = Home
	body  = index.body.html
}

page zh-Hans "index.html" {
	title = $HOME
	body  = zh-hans/index.body.html
}
RC

# zh_project(%file):
#	A project of en and zh-Hans, plus any extra file.
sub zh_project (%file)
{
	return project(
		'.fuguwebrc'                  => $RC_ZH,
		'web/zh-hans/index.body.html' => "<h1>$HOME</h1>\n",
		%file,
	);
}

subtest 'status reports the coverage and the age of a translation' => sub {
	my ( $exit, $out ) = run('help');
	like( $out, qr/\bstatus\b/,     'the help lists status' );
	like( $out, qr/\btranslated\b/, 'and translated' );

	# WEB-STATUS-3 and WEB-STATUS-5. One line for the body that no
	# record names, with a tab between two fields, and exit 1.
	my $root = zh_project();
	my $err;
	( $exit, $out, $err ) = run( '--project', $root, 'status' );
	is( $exit, 1, 'a part that does not follow its source gives 1' );
	is( $out, "zh-Hans\tunrecorded\tpage\tindex.html\n",
		'and the line names the tag, the state, the kind and the name' );
	is( $err, '', 'and says nothing more' );

	# WEB-STATUS-2. The record takes the digest of the default source.
	( $exit, $out, $err ) = run( '--project', $root, 'translated',
		'web/zh-hans/index.body.html' );
	is( $exit, 0, 'translated succeeds' ) or diag $err;
	is( $out . $err, '', 'and says nothing' );
	ok( -f "$root/TRANSLATIONS", 'and writes the record' );

	( $exit, $out, $err ) = run( '--project', $root, 'status' );
	is( $exit, 0, 'each part follows its source' ) or diag $out;
	is( $out . $err, '', 'and status says nothing' );

	# WEB-STATUS-4. A change to the en source after the record.
	open my $fh, '>', "$root/web/index.body.html" or die "Cannot write: $!";
	print {$fh} "<h1>Home, again</h1>\n";
	close $fh;

	( $exit, $out ) = run( '--project', $root, 'status' );
	is( $exit, 1, 'a change to the default source gives 1' );
	is( $out, "zh-Hans\tstale\tpage\tindex.html\n",
		'and the translation is stale' );

	run( '--project', $root, 'translated', 'web/zh-hans/index.body.html' );
	( $exit, $out ) = run( '--project', $root, 'status' );
	is( $exit, 0, 'a new record makes it follow again' );
};

subtest 'translated refuses a file that translates no source' => sub {
	my $root = zh_project();

	my ( $exit, $out, $err ) = run( '--project', $root, 'translated' );
	is( $exit, 2, 'no file gives EXIT_INVALID_ARGS' );
	like( $err, qr/translated needs a file/, 'and says why' );

	( $exit, $out, $err ) =
	    run( '--project', $root, 'translated', 'web/index.body.html' );
	is( $exit, 1, 'a default source gives EXIT_ERROR' );
	like( $err, qr{web/index\.body\.html translates no source},
		'and names the file' );
	ok( !-e "$root/TRANSLATIONS", 'and writes no record' );
};

subtest 'status fails on a record that does not parse' => sub {
	my $root = zh_project( 'TRANSLATIONS' => "not a manifest\n" );

	# Exit 1 is the answer of WEB-STATUS-5, so a failure takes the
	# code of a project file that does not load.
	my ( $exit, $out, $err ) = run( '--project', $root, 'status' );
	is( $exit, 3,  'a malformed record gives EXIT_CONFIG_ERROR' );
	is( $out,  '', 'and prints no line' );
	like( $err, qr{TRANSLATIONS: .*not a manifest}, 'and names the record' );
};

subtest 'translated fails on a record or a source that does not read' => sub {
	my $root = zh_project( 'TRANSLATIONS' => "not a manifest\n" );

	# WEB-STATUS-2. The fault takes the code of status.
	my ( $exit, $out, $err ) = run( '--project', $root, 'translated',
		'web/zh-hans/index.body.html' );
	is( $exit, 3, 'a malformed record gives EXIT_CONFIG_ERROR' );
	like( $err, qr{TRANSLATIONS: .*not a manifest}, 'and names the record' );

	$root = zh_project();
	unlink "$root/web/index.body.html" or die "Cannot remove: $!";
	( $exit, $out, $err ) = run( '--project', $root, 'translated',
		'web/zh-hans/index.body.html' );
	is( $exit, 3, 'a default source that is gone gives EXIT_CONFIG_ERROR' );
	like( $err, qr{Cannot read .*/web/index\.body\.html}, 'and names it' );
	ok( !-e "$root/TRANSLATIONS", 'and writes no record' );
};

subtest 'an empty record holds no line' => sub {
	my $root = zh_project( 'TRANSLATIONS' => '' );

	# WEB-STATUS-1. Each verb reads an empty record as no line.
	my ( $exit, $out, $err ) = run( '--project', $root, 'status' );
	is( $exit, 1, 'status reads an empty record' ) or diag $err;
	is( $out, "zh-Hans\tunrecorded\tpage\tindex.html\n",
		'and the body is unrecorded' );

	( $exit, $out, $err ) = run( '--project', $root, 'translated',
		'./web//zh-hans/index.body.html' );
	is( $exit, 0, 'translated writes into an empty record' ) or diag $err;

	# WEB-STATUS-2. The record names the file in the one form.
	open my $fh, '<', "$root/TRANSLATIONS" or die "Cannot read: $!";
	my $record = do { local $/; <$fh> };
	close $fh;
	like(
		$record,
		qr{\ASHA256 \(web/zh-hans/index\.body\.html\) = [0-9a-f]{64}\n\z},
		'and holds the one line, in the one form'
	);

	( $exit, $out ) = run( '--project', $root, 'status' );
	is( $exit, 0, 'and the body follows its source' ) or diag $out;
};

subtest 'one translated file over two default sources is a fault' => sub {
	my $root = zh_project(
		'.fuguwebrc' => $RC_ZH . <<'RC',

page "other.html" {
	title = Other
	body  = other.body.html
}

page zh-Hans "other.html" {
	body = zh-hans/index.body.html
}
RC
		'web/other.body.html' => "<h1>Other</h1>\n",
	);
	my $two = join ' ', 'web/zh-hans/index.body.html translates',
	    'web/index.body.html and web/other.body.html';
	$two = qr/\Q$two\E/;

	# WEB-STATUS-7. Each verb refuses the description, and names the
	# file and the two sources.
	my ( $exit, $out, $err ) = run( '--project', $root, 'status' );
	is( $exit, 3,  'status gives EXIT_CONFIG_ERROR' );
	is( $out,  '', 'and prints no line' );
	like( $err, $two, 'and names the file and the two sources' );

	( $exit, $out, $err ) = run( '--project', $root, 'translated',
		'web/zh-hans/index.body.html' );
	is( $exit, 3, 'translated gives EXIT_CONFIG_ERROR' );
	like( $err, $two, 'and names the file and the two sources' );
	ok( !-e "$root/TRANSLATIONS", 'and writes no record' );
};

SKIP: {
	skip 'a renderer is not installed', 1 unless $RENDERERS;

	subtest 'the build and the check do not read the record' => sub {

		# WEB-STATUS-6. A record that does not parse changes
		# nothing in the build, the check or the site.
		my $root = zh_project( 'TRANSLATIONS' => "not a manifest\n" );

		my ( $exit, $out, $err ) = run( '--project', $root, 'build' );
		is( $exit, 0, 'the build succeeds' ) or diag $err;

		( $exit, $out, $err ) = run( '--project', $root, 'check' );
		is( $exit, 0, 'and the check passes' ) or diag $err;

		ok( !-e "$root/out/TRANSLATIONS", 'and the site holds no record' );
	};
}

# The quiet option on each verb. Each error, each warning, each problem
# of the check and each line of status must still print, with the exit
# code that it has without the option. An informational message must
# not print. A subtest that asserts the absence of a note first shows
# the note without the option.

subtest 'quiet keeps the error of init, and stops its note' => sub {
	my $dir = tempdir( CLEANUP => 1 );

	my ( $exit, $out, $err ) = run( 'init', $dir );
	like( $err, qr/INFO: Wrote /, 'without quiet, init notes the file' );

	$dir = tempdir( CLEANUP => 1 );
	( $exit, $out, $err ) = run( '-q', 'init', $dir );
	is( $exit, 0, 'init succeeds' );
	ok( -s "$dir/.fuguwebrc", 'and writes the description' );
	is( $err, '', 'and does not note the file' );

	( $exit, $out, $err ) = run( '-q', 'init', $dir );
	is( $exit, 1, 'a second init fails' );
	like( $err, qr/Already exists/, 'and says why' );
};

subtest 'quiet keeps the refusal of clean' => sub {
	my $root = tempdir( CLEANUP => 1 );
	make_path("$root/victim/deep");
	open my $fh, '>', "$root/victim/deep/keep.txt" or die "Cannot: $!";
	print {$fh} "important\n";
	close $fh;

	my ( $exit, $out, $err ) =
	    run( '-q', 'clean', '--out', "$root/victim" );
	is( $exit, 1, 'clean fails' );
	ok( -e "$root/victim/deep/keep.txt", 'and removes nothing' );
	like( $err, qr/refusing to remove it/, 'and says why' );
};

subtest 'quiet keeps the lines of status and each fault' => sub {
	my $root = zh_project();

	# WEB-STATUS-3. The lines are the answer, not a note.
	my ( $exit, $out, $err ) = run( '-q', '--project', $root, 'status' );
	is( $exit, 1, 'a part that does not follow its source gives 1' );
	is( $out, "zh-Hans\tunrecorded\tpage\tindex.html\n",
		'and status prints its line' );

	( $exit, $out, $err ) =
	    run( '-q', '--project', $root, 'translated', 'web/index.body.html' );
	is( $exit, 1, 'a default source gives EXIT_ERROR' );
	like( $err, qr{web/index\.body\.html translates no source},
		'and translated names the file' );

	$root = zh_project( 'TRANSLATIONS' => "not a manifest\n" );
	( $exit, $out, $err ) = run( '-q', '--project', $root, 'status' );
	is( $exit, 3, 'a malformed record gives EXIT_CONFIG_ERROR' );
	like( $err, qr{TRANSLATIONS: .*not a manifest}, 'and names the record' );
};

SKIP: {
	skip 'a renderer is not installed', 3 unless $RENDERERS;

	subtest 'quiet keeps each problem of the check' => sub {
		my $root = project( 'web/index.body.html' =>
			    qq{<h1>Home</h1>\n<a href="https://example.com/">Out</a>\n}
		);
		run( '--project', $root, 'build' );

		open my $fh, '>>', "$root/out/en/index.html"
		    or die "Cannot append: $!";
		print {$fh} qq{<a href="./gone.html">Gone</a>\n};
		close $fh;

		my ( $exit, $out, $err ) =
		    run( '--project', $root, 'check', '--verbose' );
		like( $err, qr{INFO: external link: https://example\.com/},
			'without quiet, the check notes the external link' );

		( $exit, $out, $err ) =
		    run( '-q', '--project', $root, 'check', '--verbose' );
		is( $exit, 5, 'a dead link gives EXIT_CHECK_FAILED' );
		like( $err, qr{gone\.html leads nowhere}, 'and names the link' );
		unlike( $err, qr/external link/,
			'and does not note the external link' );
	};

	subtest 'quiet keeps the warning of a kept entry' => sub {
		my $root = project();
		run( '--project', $root, 'build' );

		# write_out($name):
		#	Put one file into the output, as a stray maker does.
		my $write_out = sub ($name) {
			make_path( "$root/out/$name" =~ s{/[^/]+$}{}r );
			open my $fh, '>', "$root/out/$name"
			    or die "Cannot write: $!";
			print {$fh} "<p>$name</p>\n";
			close $fh;
		};

		$write_out->('en/old.html');
		my ( $exit, $out, $err ) = run( '--project', $root, 'build' );
		like( $err, qr{INFO: Removing en/old\.html},
			'without quiet, the build notes a removal' );

		# WEB-OUTPUT-4. The build keeps a directory that the site
		# does not name, and must report it.
		$write_out->($_) for qw(en/old.html mine/keep.txt);
		( $exit, $out, $err ) = run( '--quiet', '--project', $root, 'build' );
		is( $exit, 0, 'build succeeds' ) or diag $err;
		ok( -e "$root/out/mine/keep.txt", 'and keeps the entry' );
		like( $err, qr{WARNING: mine\S* is in the output},
			'and reports it' );
		ok( !-e "$root/out/en/old.html", 'and removes the stale page' );
		unlike( $err, qr/Removing/, 'and does not note the removal' );
	};

	subtest 'quiet keeps the error of an outline that differs' => sub {
		my $root =
		    zh_project( 'web/zh-hans/index.body.html' => "<h2>$HOME</h2>\n" );

		# WEB-OUTLINE-1. The message names the page, the language
		# and the position.
		my ( $exit, $out, $err ) = run( '-q', '--project', $root, 'build' );
		is( $exit, 4, 'an outline that differs gives EXIT_RENDER_FAILED' );
		like(
			$err,
			qr{zh-hans/index\.html: the outline of zh-Hans differs},
			'and names the page'
		);
	};
}

done_testing();
