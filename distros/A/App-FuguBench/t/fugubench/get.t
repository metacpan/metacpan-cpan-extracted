#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The stub of the install address, web/get (DIST-INSTALL-3 to
# DIST-INSTALL-6).
#
# Each case runs web/get as a child of /bin/sh. The whole PATH of the
# child is the bin directory of a temporary tree, and that directory
# holds the stub downloader of the case, or no downloader at all. So
# no case reaches the network, and each case reads and writes inside
# its own tree.
#
# A stub prints the install script of its case, and that script
# writes the marker file of the tree. The marker is the proof that sh
# ran the fetched text.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use File::Basename qw(basename);
use File::Temp     qw(tempdir);
use FindBin        qw($RealBin);
use lib "$RealBin/../../lib";

use Fugu::File;
use Fugu::Process;

my $root = "$RealBin/../..";
my $get  = "$root/web/get";

# The release tarball holds t/fugubench and no web directory.
plan skip_all => 'no web/get' unless -f $get;

# The URL that the stub fetches. GitHub resolves the latest release
# at the moment of the fetch, so no release changes the website.
my $URL =
    'https://github.com/FuguBSD/FuguBench/releases/latest/download/install.sh';

# The line bound of the stub (DIST-INSTALL-5). A visitor reads the
# file before the visitor runs it, and one screen holds it.
my $MAX_LINES = 30;

# The argument list that the stub builds for each downloader
# (DIST-INSTALL-4). curl takes -f, so an HTTP error writes no error
# page, and -L, so it follows the redirect of the latest-release
# path. wget takes --tries=1, so no retry appends to standard output.
# Each tool writes the body to standard output.
my %COMMAND = (
	curl => "curl -fsSL $URL",
	wget => "wget -q --tries=1 -O - $URL",
	ftp  => "ftp -V -o - $URL",
);

# The value that the install script writes into the marker. It holds
# a backslash, because a transport that reads an escape changes it:
# the echo of a POSIX shell turns \t into a tab, and printf '%s'
# leaves the two bytes alone.
my $TOKEN = 'in\tstalled';

# The commands that the bin directory of a tree holds beside the
# stub. web/get runs sh, and a host whose sh holds no printf builtin
# needs printf. A stub prints its script with cat.
my @LINKED = qw(sh printf cat);

# _tree():
#	One temporary tree, with a bin directory as the whole PATH of
#	a child. A command of @LINKED that this host lacks stays out,
#	and the case that needs it then fails on its own.
sub _tree ()
{
	my $tree = tempdir( CLEANUP => 1 );
	mkdir "$tree/bin" or die "mkdir $tree/bin";

	for my $name (@LINKED) {
		my $path = Fugu::Process->find_command($name) or next;
		symlink $path, "$tree/bin/" . basename($path)
		    or die "symlink $path";
	}

	return $tree;
}

# _stub($tree, $name, @body):
#	One stub downloader in the bin directory of the tree. The stub
#	records its own command line in the log, and it then runs the
#	body lines of its case.
sub _stub ( $tree, $name, @body )
{
	my $path = "$tree/bin/$name";
	my $text = join "\n", '#!/bin/sh',
	    qq{echo "$name \$*" >> '$tree/log'}, @body, q{};
	Fugu::File->write( $path, $text, mode => 0755 ) or die "write $path";

	return;
}

# _install($tree):
#	One install script of two lines. The lines set a variable that
#	holds a backslash, and write it to the marker with printf. A
#	marker with the exact bytes proves that every byte of the
#	script reached sh.
sub _install ($tree)
{
	return "token='$TOKEN'\n"
	    . "printf '%s\\n' \"\$token\" > '$tree/marker'\n";
}

# _print($tree, $text):
#	The body line of a stub that prints one install script. The
#	test writes the text into the tree, so no quoting of a stub
#	reaches the text.
sub _print ( $tree, $text )
{
	Fugu::File->write( "$tree/script", $text )
	    or die "write $tree/script";

	return "cat '$tree/script'";
}

# _run($tree):
#	Run web/get as a child of /bin/sh, in the tree and with the
#	bin directory of the tree as the whole PATH.
sub _run ($tree)
{
	return Fugu::Process->run(
		cmd => [ '/bin/sh', $get ],
		cwd => $tree,
		env => { PATH => "$tree/bin" },
	);
}

# _log($tree):
#	The command line that the stub of the tree recorded, or the
#	empty string when no stub ran.
sub _log ($tree)
{
	return Fugu::File->read("$tree/log") // q{};
}

# The file: the shell accepts it, and it fits on one screen.
my $syntax = Fugu::Process->run( cmd => [ '/bin/sh', '-n', $get ] );
ok( $syntax->{success}, 'sh -n accepts web/get' );

my $text = Fugu::File->read($get) // q{};
cmp_ok( ( $text =~ tr/\n// ),
	'<=', $MAX_LINES, "web/get holds at most $MAX_LINES lines" );

# One stub downloader of each name, in the order of the search. The
# stub prints the install script, sh runs it, and the log holds the
# whole argument list that the stub built.
for my $name (qw(curl wget ftp)) {
	my $tree = _tree();
	_stub( $tree, $name, _print( $tree, _install($tree) ) );

	my $result = _run($tree);
	is( $result->{exit_code}, 0, "$name: the stub exits 0" );
	is( Fugu::File->read("$tree/marker"),
		"$TOKEN\n", "$name: sh ran the script byte for byte" );
	is( _log($tree), "$COMMAND{$name}\n",
		"$name: the stub runs $COMMAND{$name}" );
}

# Two stub downloaders in one tree (DIST-INSTALL-4). The search takes
# curl before wget, so the log holds the command of curl alone. A tree
# with one downloader proves no order.
{
	my $tree   = _tree();
	my $script = _print( $tree, _install($tree) );
	_stub( $tree, 'curl', $script );
	_stub( $tree, 'wget', $script );

	my $result = _run($tree);
	is( $result->{exit_code}, 0, 'two downloaders: the stub exits 0' );
	is( _log($tree), "$COMMAND{curl}\n",
		'the search takes curl before wget' );
}

# A second pair in one tree (DIST-INSTALL-4). The search takes wget
# before ftp, so the log holds the command of wget alone. The two
# pairs together pin the whole order.
{
	my $tree   = _tree();
	my $script = _print( $tree, _install($tree) );
	_stub( $tree, 'wget', $script );
	_stub( $tree, 'ftp',  $script );

	my $result = _run($tree);
	is( $result->{exit_code}, 0, 'wget and ftp: the stub exits 0' );
	is( _log($tree), "$COMMAND{wget}\n",
		'the search takes wget before ftp' );
}

# The asset of a release answers 302. curl without -L then exits 0
# and writes nothing, so this stub holds that answer: it prints the
# script for an argument list that follows a redirect, and nothing
# for one that does not.
{
	my $tree = _tree();
	_stub(
		$tree, 'curl',
		'follow=',
		'for a in "$@"; do',
		"\tcase \$a in -*L*|--location) follow=1 ;; esac",
		'done',
		'[ -n "$follow" ] || exit 0',
		_print( $tree, _install($tree) ),
	);

	my $result = _run($tree);
	is( $result->{exit_code}, 0, 'the fetch follows a redirect' );
	is( Fugu::File->read("$tree/marker"),
		"$TOKEN\n", 'the script of the redirect reaches sh' );
}

# An absent asset answers 404. curl without -f then writes the error
# page of the server to standard output and exits 0, and a non-empty
# page passes the emptiness guard. This stub holds that answer, and
# it makes the error page the install script: a marker then proves
# that the page of an HTTP error reached sh.
{
	my $tree = _tree();
	_stub(
		$tree, 'curl',
		'fail=',
		'for a in "$@"; do',
		"\tcase \$a in -*f*|--fail) fail=1 ;; esac",
		'done',
		'[ -n "$fail" ] && exit 22',
		_print( $tree, _install($tree) ),
	);

	my $result = _run($tree);
	isnt( $result->{exit_code}, 0, 'an HTTP error stops the stub' );
	ok( !-e "$tree/marker", 'the page of an HTTP error reaches no sh' );
	like( $result->{stderr}, qr/\Q$URL\E/, 'the reason names the URL' );
}

# A failed fetch. The stub writes nothing and exits 1. A pipe of the
# downloader into sh exits 0 here, because sh reads an empty script.
{
	my $tree = _tree();
	_stub( $tree, 'curl', 'exit 1' );

	my $result = _run($tree);
	isnt( $result->{exit_code}, 0, 'a failed fetch stops the stub' );
	ok( !-e "$tree/marker", 'a failed fetch reaches no sh' );
	like( $result->{stderr}, qr/\Q$URL\E/, 'the reason names the URL' );
}

# An empty text under a zero exit, as a 302 without -L gives.
{
	my $tree = _tree();
	_stub( $tree, 'curl', 'exit 0' );

	my $result = _run($tree);
	isnt( $result->{exit_code}, 0, 'an empty text stops the stub' );
	ok( !-e "$tree/marker", 'an empty text reaches no sh' );
}

# The exit code of sh is the exit code of the stub.
{
	my $tree = _tree();
	_stub( $tree, 'curl', _print( $tree, "exit 3\n" ) );

	my $result = _run($tree);
	is( $result->{exit_code}, 3, 'the stub exits with the code of sh' );
}

# No downloader on PATH (DIST-INSTALL-6). The bin directory holds the
# linked commands and no stub.
{
	my $tree   = _tree();
	my $result = _run($tree);
	isnt( $result->{exit_code}, 0, 'no downloader stops the stub' );
	like(
		$result->{stderr},
		qr/\bcurl\b.*\bwget\b.*\bftp\b/,
		'the reason names curl, wget, and ftp'
	);
}

done_testing();
