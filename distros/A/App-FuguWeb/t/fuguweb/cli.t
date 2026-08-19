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

subtest 'quiet keeps a diagnostic off standard error' => sub {
	my $empty = tempdir( CLEANUP => 1 );

	my ( $exit, $out, $err ) = run( '--quiet', '--project', $empty,
		'check' );
	is( $exit, 3,  'the exit code still reports the failure' );
	is( $err,  '', 'and nothing is written' );
};

subtest 'init writes a starter, once' => sub {
	my $dir = tempdir( CLEANUP => 1 );

	my ( $exit, $out, $err ) = run( 'init', $dir );
	is( $exit, 0, 'init succeeds' );
	ok( -s "$dir/.fuguwebrc", 'and writes the description' );

	( $exit, $out, $err ) = run( 'init', $dir );
	is( $exit, 1, 'a second init fails' );
	like( $err, qr/Already exists/, 'and says why' );

	( $exit, $out, $err ) = run( 'init', "$dir/nosuchdir" );
	is( $exit, 1, 'a directory that is absent fails' );
	like( $err, qr/Not a directory/, 'and says why' );
};

subtest 'clean needs no description when --out names the target' => sub {
	my $root = tempdir( CLEANUP => 1 );
	make_path("$root/out");
	open my $fh, '>', "$root/out/index.html" or die "Cannot write: $!";
	print {$fh} "<html></html>\n";
	close $fh;

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
		ok( -s "$root/out/index.html", 'and writes the page' );

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

		open my $fh, '>>', "$root/out/index.html"
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
		ok( -s "$root/elsewhere/index.html",
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

manuals "Manuals" {
	dir    = man
	anchor = manuals
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

done_testing();
