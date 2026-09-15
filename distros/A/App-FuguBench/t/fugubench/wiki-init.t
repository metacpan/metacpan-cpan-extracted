#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The clone of the library, the wiki.origin key, and the anchor of
# the library directory (WIKI-CLONE, WIKI-OPEN-5, CLI-CONFIG-2).
#
# Each case runs bin/fugubench as a child with -Ilib, against a
# temporary tree with a bare repository as the origin. The child
# reads that tree as its home, and it reads no system configuration,
# so no case reads the operator home and no case reaches the network.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";

use Fugu::File;
use Fugu::Process;

my $root    = "$RealBin/../..";
my $program = "$root/bin/fugubench";

plan skip_all => 'git is absent'
    unless Fugu::Process->find_command('git');

# _env($home):
#	The environment of one child. The child reads the temporary
#	tree as its home, so it reads no operator identity and no
#	signing agent of the operator. The child gets this environment
#	in place of the environment of the test, so this environment
#	must carry PERL5LIB. CI installs Fugu into a local library, and
#	names that library in PERL5LIB.
sub _env ($home)
{
	my %env = (
		PATH                => $ENV{PATH},
		HOME                => $home,
		GIT_CONFIG_NOSYSTEM => 1,
	);

	# An undefined value is an error, and a host that installs
	# Fugu in the default @INC sets no PERL5LIB.
	$env{PERL5LIB} = $ENV{PERL5LIB} if defined $ENV{PERL5LIB};

	return \%env;
}

# _write($path, $text):
#	Write one file, and make its parent directories.
sub _write ( $path, $text )
{
	make_path( $path =~ s{/[^/]+\z}{}r );
	Fugu::File->write( $path, $text ) or die "write $path";

	return;
}

# _git($home, @args):
#	Run git with the home of one tree, and die on a failure.
sub _git ( $home, @args )
{
	my $result = Fugu::Process->run(
		cmd => [ 'git', @args ],
		env => _env($home),
	);
	die "git @args: $result->{stderr}" unless $result->{success};

	return $result->{stdout};
}

# _tree():
#	A temporary tree with a git identity of its own, and a bare
#	repository with one commit on main as the origin. The tree and
#	the URL of the origin, in that order.
#
#	The origin refuses a push that is no fast-forward, as the
#	ruleset of the library does.
sub _tree ()
{
	my $dir = tempdir( CLEANUP => 1 );
	_write( "$dir/.gitconfig", <<'CONFIG' );
[user]
	name = a
	email = a@b
[commit]
	gpgsign = false
CONFIG

	my $origin = "$dir/origin.git";
	_git( $dir, 'init', '--quiet', '--bare', $origin );
	_git( $dir, '-C', $origin, 'symbolic-ref', 'HEAD', 'refs/heads/main' );
	_git( $dir, '-C', $origin, 'config', 'receive.denyNonFastForwards',
		'true' );

	my $seed = "$dir/seed";
	_git( $dir, 'clone', '--quiet', $origin, $seed );
	_git( $dir, '-C', $seed, 'commit', '--quiet', '--allow-empty', '-m',
		'Initial commit' );
	_git( $dir, '-C', $seed, 'branch', '-M', 'main' );
	_git( $dir, '-C', $seed, 'push', '--quiet', 'origin', 'main' );

	return ( $dir, "file://$origin" );
}

# _checkout($tree, $name, $text):
#	A checkout of the tree, with the .toolingrc of the caller.
sub _checkout ( $tree, $name, $text )
{
	my $dir = "$tree/$name";
	_write( "$dir/.toolingrc", $text );

	return $dir;
}

# _run($tree, $dir, @args):
#	Run the wiki verb against one checkout, and return the result
#	of Fugu::Process->run.
sub _run ( $tree, $dir, @args )
{
	my $result = Fugu::Process->run(
		cmd => [
			$^X,  "-I$root/lib", $program, '-C',
			$dir, 'wiki',        @args
		],
		env => _env($tree),
	);
	die "cannot run $program: $result->{error}\n"
	    if defined $result->{error};

	return $result;
}

subtest 'init clones the library, and a second run changes nothing' => sub {
	my ( $tree, $origin ) = _tree();
	my $co = _checkout( $tree, 'ws', "wiki.origin\t$origin\n" );

	my $r = _run( $tree, $co, 'init' );
	is( $r->{exit_code}, 0, 'init exits 0' ) or diag $r->{stderr};
	is( $r->{stdout}, "$co/Wiki\n", 'init writes the library directory' );
	ok( -e "$co/Wiki/.git", 'the clone arrives' );

	my $head = _git( $tree, '-C', "$co/Wiki", 'rev-parse', 'HEAD' );

	$r = _run( $tree, $co, 'init' );
	is( $r->{exit_code}, 0, 'a second init exits 0' );
	is( $r->{stdout}, q{}, 'a second init writes no result line' );
	like( $r->{stderr}, qr/already exists, nothing to do/,
		'a second init reports the directory' );
	is( _git( $tree, '-C', "$co/Wiki", 'rev-parse', 'HEAD' ),
		$head, 'a second init leaves the clone as it is' );
};

subtest 'a wiki.origin that no repository answers' => sub {
	my ($tree) = _tree();
	my $co =
	    _checkout( $tree, 'ws', "wiki.origin\tfile://$tree/absent.git\n" );

	my $r = _run( $tree, $co, 'init' );
	is( $r->{exit_code}, 0, 'init exits 0 after a failed clone' );
	is( $r->{stdout},    q{}, 'init writes no result line' );
	like( $r->{stderr}, qr/the library stays absent/, 'init warns' );
	ok( !-e "$co/Wiki", 'init makes no directory' );
};

subtest 'a URL of the wrong shape is a configuration error' => sub {
	my ($tree) = _tree();
	my $co = _checkout( $tree, 'ws', "wiki.origin\texample.org/Wiki.git\n" );

	my $r = _run( $tree, $co, 'init' );
	is( $r->{exit_code}, 3, 'init exits 3 on a URL with no scheme' );
	like( $r->{stderr}, qr/wiki[.]origin/, 'the message names the key' );
	ok( !-e "$co/Wiki", 'init makes no directory' );
};

subtest 'a wiki.dir that resolves to the home of wiki.origin' => sub {
	my ( $tree, $origin ) = _tree();
	my $co =
	    _checkout( $tree, 'ws', "wiki.origin\t$origin\nwiki.dir\t.\n" );

	# The home of wiki.origin is a checkout, and a checkout holds
	# a .git. So this value makes the checkout the library: open
	# would write a session page into the checkout, and the push
	# would carry it to the origin of the checkout (CLI-CONFIG-3).
	_git( $tree, 'init', '--quiet', $co );

	for my $argv ( ['init'], [ 'open', 'FuguSTX', 'sess-1' ] ) {
		my $r = _run( $tree, $co, @$argv );
		is( $r->{exit_code}, 3, "$argv->[0] exits 3" );
		is( $r->{stdout},    q{}, "$argv->[0] writes no result line" );
		like( $r->{stderr}, qr/wiki[.]dir/,
			'the message names the key' );
	}

	my @pages = glob "$co/Session-*";
	is( scalar @pages, 0, 'no session page reaches the checkout' );
};

subtest 'no wiki.origin on the walk' => sub {
	my ($tree) = _tree();
	my $co = _checkout( $tree, 'bare', "# this checkout sets no key\n" );

	my $r = _run( $tree, $co, 'init' );
	is( $r->{exit_code}, 3, 'init exits 3 without the key' );
	is( $r->{stdout},    q{}, 'init writes no result line' );
	like( $r->{stderr}, qr/wiki[.]origin/, 'the message names the key' );

	# Every other subcommand treats an absent key as an absent
	# clone, so no hook stops a session (WIKI-CLONE-3).
	$r = _run( $tree, $co, 'open', 'FuguSTX', 'sess-1' );
	is( $r->{exit_code}, 0, 'open exits 0 without the key' );
	is( $r->{stdout},    q{}, 'open writes no result line' );
	like( $r->{stderr}, qr/no library, wiki[.]origin is unset/,
		'open reports the absent key' );
};

subtest 'a clone under Projects/ reads the library of the workspace' => sub {
	my ( $tree, $origin ) = _tree();
	my $ws = _checkout( $tree, 'ws', "wiki.origin\t$origin\n" );

	# The clone is a checkout of its own, and its .toolingrc holds
	# no wiki.origin. So the walk for the key reaches the
	# workspace, and the home of the key anchors the library
	# (CLI-CONFIG-2).
	my $proj = "$ws/Projects/FuguSTX";
	_write( "$proj/.toolingrc", "worktree.base\t.worktrees\n" );

	my $r = _run( $tree, $proj, 'init' );
	is( $r->{exit_code}, 0, 'init exits 0 in the clone' )
	    or diag $r->{stderr};
	is( $r->{stdout}, "$ws/Wiki\n",
		'the library is the one of the workspace' );
	ok( -e "$ws/Wiki/.git", 'the clone arrives in the workspace' );
	ok( !-e "$proj/Wiki",   'the clone makes no library of its own' );
};

subtest 'no clone' => sub {
	my ( $tree, $origin ) = _tree();
	my $co = _checkout( $tree, 'ws', "wiki.origin\t$origin\n" );

	# Every subcommand except init reports the absence and exits
	# zero, so no hook stops a session (WIKI-CLONE-3). candidates
	# runs inside make check, so it passes with no clone
	# (WIKI-STATUS-3).
	for my $argv ( [ 'open', 'FuguSTX', 'sess-1' ], ['status'],
		['candidates'] )
	{
		my $r = _run( $tree, $co, @$argv );
		is( $r->{exit_code}, 0, "$argv->[0] exits 0 with no clone" );
		is( $r->{stdout}, q{}, "$argv->[0] writes no result line" );
		like( $r->{stderr}, qr/\Qno library at $co\E/,
			"$argv->[0] names the absent library" );
	}
};

subtest 'a clone with no candidate page' => sub {
	my ( $tree, $origin ) = _tree();
	my $co = _checkout( $tree, 'ws', "wiki.origin\t$origin\n" );

	my $r = _run( $tree, $co, 'init' );
	is( $r->{exit_code}, 0, 'init clones the library' ) or diag $r->{stderr};

	# The clone answers, and the page is absent. The subcommand
	# runs inside make check, so it passes here too
	# (WIKI-STATUS-3).
	$r = _run( $tree, $co, 'candidates' );
	is( $r->{exit_code}, 0, 'candidates exits 0 with no page' );
	is( $r->{stdout},    q{}, 'candidates writes no result line' );
	like( $r->{stderr}, qr/no Rule-candidates[.]md, nothing to report/,
		'candidates names the absent page' );
};

subtest 'a token of the wrong shape gives the usage error' => sub {
	my ( $tree, $origin ) = _tree();
	my $co = _checkout( $tree, 'ws', "wiki.origin\t$origin\n" );
	_run( $tree, $co, 'init' );

	# A token reaches the page name, and the page name reaches the
	# filesystem and git (WIKI-OPEN-5, WIKI-CONFINE-1).
	for my $bad ( '../etc', 'sub/dir', '.hidden' ) {
		my $r = _run( $tree, $co, 'open', $bad, 'sess-1' );
		is( $r->{exit_code}, 2, "open refuses the project $bad" );
		like( $r->{stderr}, qr/invalid project/,
			'the message names the token' );
	}

	my $r = _run( $tree, $co, 'open', 'FuguSTX', '../etc' );
	is( $r->{exit_code}, 2, 'open refuses a session of that shape' );
	like( $r->{stderr}, qr/invalid session/,
		'the message names the token' );

	my @pages = glob "$co/Wiki/Session-*";
	is( scalar @pages, 0, 'no page arrives' );
};

subtest 'an unknown subcommand gives the usage error' => sub {
	my ( $tree, $origin ) = _tree();
	my $co = _checkout( $tree, 'ws', "wiki.origin\t$origin\n" );

	for my $case ( ['nosuchsubcommand'], [] ) {
		my $r = _run( $tree, $co, @$case );
		is( $r->{exit_code}, 2, 'the verb exits 2' );
		like( $r->{stderr}, qr/^usage: fugubench wiki /m,
			'the verb prints its usage to standard error' );
		is( $r->{stdout}, q{},
			'the verb writes nothing to standard output' );
	}
};

done_testing();
