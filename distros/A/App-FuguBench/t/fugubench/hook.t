#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The four events of the hook verb (HOOK-EVENTS, HOOK-SESSION,
# HOOK-WORKTREE), the payload start of the checkout (CLI-CHECKOUT-1),
# and the port of the hook subtest of the Workspace test t/ci/wiki.t
# (CLI-CONFORMANCE-1). The port changes the invocation, the fixture,
# the pragma block of the source floor, and the unit citations.
#
# Each case runs bin/fugubench as a child with -Ilib, and it feeds one
# payload on standard input. The child reads the temporary tree as its
# home, and it reads no system configuration, so no case reads the
# operator home and no case reaches the network.
#
# Each case takes a tree of its own, because every checkout of one
# tree pushes to one origin.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use Cwd        qw(abs_path);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin    qw($RealBin);
use JSON::PP   ();
use POSIX      qw(strftime);
use lib "$RealBin/../../lib";

use Fugu::File;
use Fugu::Process;

my $root    = "$RealBin/../..";
my $program = "$root/bin/fugubench";

plan skip_all => 'git is absent'
    unless Fugu::Process->find_command('git');

my $today = strftime( '%Y-%m-%d', gmtime );

# The encoder of one payload. It sorts the keys, and it writes the
# bytes that the verb decodes.
my $JSON = JSON::PP->new->canonical->utf8;

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
#	the path of the origin, in that order.
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

	my $seed = "$dir/seed";
	_git( $dir, 'clone', '--quiet', $origin, $seed );
	_git( $dir, '-C', $seed, 'commit', '--quiet', '--allow-empty', '-m',
		'Initial commit' );
	_git( $dir, '-C', $seed, 'branch', '-M', 'main' );
	_git( $dir, '-C', $seed, 'push', '--quiet', 'origin', 'main' );

	return ( $dir, $origin );
}

# _checkout($tree, $name, $config):
#	A checkout of the tree with a clone of the library. The
#	.toolingrc holds the configuration of the caller, and the walk
#	of the program stops at that file.
sub _checkout ( $tree, $name, $config )
{
	my $dir = "$tree/$name";
	_write( "$dir/.toolingrc", $config );
	_git( $tree, 'clone', '--quiet', "$tree/origin.git", "$dir/Wiki" );

	return $dir;
}

# _repo($tree, $name, $config):
#	A checkout with one commit on main, for the worktree events.
#	git makes a worktree of a main checkout alone, and a branch of
#	a repository that holds a commit alone.
#
#	The method returns the path and the resolved path, in that
#	order. A temporary directory of the host can sit under a
#	symbolic link, and the verb writes the resolved path.
sub _repo ( $tree, $name, $config )
{
	my $dir = "$tree/$name";
	_write( "$dir/.toolingrc", $config );
	_write( "$dir/.gitignore", ".claude/worktrees/\ntrees/\n" );
	_git( $tree, 'init', '--quiet', '-b', 'main', $dir );
	_git( $tree, '-C', $dir, 'add', '-A' );
	_git( $tree, '-C', $dir, 'commit', '--quiet', '-m', 'Initial commit' );

	return ( $dir, abs_path($dir) );
}

# _hook($tree, $event, $payload, %args):
#	Run one hook event with one payload on standard input, and
#	return the result of Fugu::Process->run. The global option of
#	the caller comes in front of the verb, and cwd names the
#	working directory of the child.
sub _hook ( $tree, $event, $payload, %args )
{
	my $result = Fugu::Process->run(
		cmd => [
			$^X, "-I$root/lib", $program,
			@{ $args{global} // [] }, 'hook', $event
		],
		env   => _env($tree),
		stdin => $payload,
		exists $args{cwd} ? ( cwd => $args{cwd} ) : (),
	);
	die "cannot run $program: $result->{error}\n"
	    if defined $result->{error};

	return $result;
}

# _child($tree, $payload, @argv):
#	Run the program with one payload on standard input, and return
#	the result of Fugu::Process->run. A case that names no event,
#	or that names an argument after one, builds its own line.
sub _child ( $tree, $payload, @argv )
{
	my $result = Fugu::Process->run(
		cmd   => [ $^X, "-I$root/lib", $program, @argv ],
		env   => _env($tree),
		stdin => $payload,
	);
	die "cannot run $program: $result->{error}\n"
	    if defined $result->{error};

	return $result;
}

# _json(%fields):
#	One payload, as the bytes of a JSON object.
sub _json (%fields)
{
	return $JSON->encode( \%fields );
}

# _pages($dir, $glob):
#	The pages of one library clone that match one pattern.
sub _pages ( $dir, $glob = 'Session-*' )
{
	return sort glob "$dir/Wiki/$glob";
}

subtest 'the hooks skip a sub-agent and find the checkout' => sub {
	my ( $tree, $origin ) = _tree();
	my $co =
	    _checkout( $tree, 'Workspace', "wiki.origin\tfile://$origin\n" );

	# An observer dispatches an operator for each step and a
	# verifier for each claim. Without this test each of them opens
	# its own page (HOOK-EVENTS-4).
	is(
		_hook(
			$tree, 'SessionStart',
			_json(
				session_id => 's1',
				cwd        => $co,
				agent_id   => 'a1'
			) )->{exit_code},
		0,
		'a sub-agent payload exits zero'
	);
	is( scalar( glob "$co/Wiki/Session-*" ),
		undef, 'a sub-agent opens no page' );

	is(
		_hook( $tree, 'SessionStart',
			_json( session_id => 's1', cwd => $co ) )->{exit_code},
		0,
		'a main session payload exits zero'
	);
	my @pages = _pages( $co, 'Session-Workspace-*' );
	is( scalar @pages, 1, 'the main session opens one page' );

	# A session under the projects directory belongs to that
	# project (HOOK-SESSION-2).
	make_path("$co/Projects/FuguSTX");
	is(
		_hook(
			$tree, 'SessionStart',
			_json(
				session_id => 's2',
				cwd        => "$co/Projects/FuguSTX"
			) )->{exit_code},
		0,
		'a project session exits zero'
	);
	@pages = _pages( $co, 'Session-FuguSTX-*' );
	is( scalar @pages, 1, 'the project name comes from the path' );

	# A hook must never stop a session (HOOK-EVENTS-2).
	is( _hook( $tree, 'SessionStart', 'not json at all' )->{exit_code},
		0, 'a payload that does not parse exits zero' );
	is( _hook( $tree, 'SessionEnd', '{}' )->{exit_code},
		0, 'a payload with no cwd exits zero' );
};

subtest 'a payload that does not parse warns' => sub {
	my ($tree) = _tree();

	# The port above keeps the exit code of the source, and this
	# case reads the warning of the verb (HOOK-EVENTS-2).
	my $r = _hook( $tree, 'SessionStart', 'not json at all' );
	like( $r->{stderr}, qr/does not parse/, 'the warning names the parse' );
	is( $r->{stdout}, q{}, 'that event writes no page name' );
};

subtest 'SessionStart runs init in front of open' => sub {
	my ( $tree, $origin ) = _tree();

	# init clones the library of a checkout that holds none
	# (HOOK-SESSION-1, WIKI-CLONE-1).
	my $co = "$tree/fresh";
	_write( "$co/.toolingrc", "wiki.origin\tfile://$origin\n" );

	my $r = _hook( $tree, 'SessionStart',
		_json( session_id => 's1', cwd => $co ) );
	is( $r->{exit_code}, 0, 'the event exits zero' ) or diag $r->{stderr};
	ok( -e "$co/Wiki/.git", 'init cloned the library' );

	# A hook reads standard output, so the page name is the whole
	# of it (CLI-PROGRAM-4). init writes the directory of the
	# clone that it made, and that line takes the other channel.
	is( $r->{stdout}, "Session-fresh-$today-1.md\n",
		'the page name is the whole of the standard output' );
	like( $r->{stderr}, qr{^\Q$co\E/Wiki$}m,
		'the directory of the clone reaches standard error' );

	# A checkout that names no library stops init with the
	# configuration code. The session must start all the same, so
	# the event maps that code to a warning (HOOK-EVENTS-3,
	# WIKI-CLONE-3).
	my $bare = "$tree/bare";
	_write( "$bare/.toolingrc", "# this checkout names no library\n" );

	$r = _hook( $tree, 'SessionStart',
		_json( session_id => 's2', cwd => $bare ) );
	is( $r->{exit_code}, 0, 'a checkout with no library exits zero' );
	like( $r->{stderr}, qr/wiki init exited 3/,
		'the warning names the call and the code' );
	is( $r->{stdout}, q{}, 'that event writes no page name' );

	# An identifier that starts with a dash reaches git as an
	# option, so open refuses it. The event maps that code too
	# (HOOK-EVENTS-3, WIKI-OPEN-5).
	$r = _hook( $tree, 'SessionStart',
		_json( session_id => '-x', cwd => $co ) );
	is( $r->{exit_code}, 0, 'an identifier that open refuses exits zero' );
	like( $r->{stderr}, qr/wiki open exited 2/,
		'the warning names the open call' );
};

subtest 'one session holds one page, and SessionEnd closes it' => sub {
	my ( $tree, $origin ) = _tree();
	my $co =
	    _checkout( $tree, 'Workspace', "wiki.origin\tfile://$origin\n" );
	my $page = "Session-Workspace-$today-1.md";

	# The verb replaces each character outside the five
	# (HOOK-SESSION-1).
	my $wild = 's 1/2';
	my $r    = _hook( $tree, 'SessionStart',
		_json( session_id => $wild, cwd => $co ) );
	is( $r->{stdout}, "$page\n", 'the first event writes the page name' )
	    or diag $r->{stderr};
	like( Fugu::File->read("$co/Wiki/$page"),
		qr/^Session: s-1-2$/m,
		'the identifier holds no other character' );

	# The identifier lives in the page, so a second event of one
	# session opens no second page (WIKI-PAGES-4).
	$r = _hook( $tree, 'SessionStart',
		_json( session_id => $wild, cwd => $co ) );
	is( $r->{stdout}, "$page\n", 'a second event writes the same page' );
	my @pages = _pages($co);
	is( scalar @pages, 1, 'one session holds one page' );

	# SessionEnd closes that page (HOOK-SESSION-3).
	$r = _hook( $tree, 'SessionEnd',
		_json( session_id => $wild, cwd => $co ) );
	is( $r->{exit_code}, 0, 'SessionEnd exits zero' ) or diag $r->{stderr};
	like( Fugu::File->read("$co/Wiki/$page"),
		qr/^Closed: /m, 'the page holds the closed line' );

	# A payload that names no cwd and no session stops the event.
	# The walk must not start at the working directory of the
	# child (HOOK-EVENTS-5).
	$r = _hook( $tree, 'SessionEnd', '{}' );
	is( $r->{exit_code}, 0, 'a SessionEnd with no session exits zero' );
	like( $r->{stderr}, qr/names no cwd or no session/,
		'the warning names the absent keys' );
	is( $r->{stdout}, q{}, 'that event writes no page name' );
};

subtest 'the project comes from the two wiki keys' => sub {
	my ( $tree, $origin ) = _tree();
	my $config = "wiki.origin\tfile://$origin\n"
	    . "wiki.project\tBench\n"
	    . "wiki.projects\tClones\n";
	my $co = _checkout( $tree, 'c1', $config );

	# The wiki.project value names the session of the root
	# (HOOK-SESSION-2).
	my $r = _hook( $tree, 'SessionStart',
		_json( session_id => 's1', cwd => $co ) );
	is( $r->{stdout}, "Session-Bench-$today-1.md\n",
		'the root session takes the wiki.project value' )
	    or diag $r->{stderr};

	# The wiki.projects value names the directory of the clones,
	# and the child of it that holds the cwd names the session.
	make_path("$co/Clones/FuguCTX/deep");
	$r = _hook( $tree, 'SessionStart',
		_json( session_id => 's2', cwd => "$co/Clones/FuguCTX/deep" ) );
	is( $r->{stdout}, "Session-FuguCTX-$today-1.md\n",
		'a session below the clone takes the name of the clone' )
	    or diag $r->{stderr};

	# A directory beside the clones is no project.
	make_path("$co/other/FuguTTX");
	$r = _hook( $tree, 'SessionStart',
		_json( session_id => 's3', cwd => "$co/other/FuguTTX" ) );
	is( $r->{stdout}, "Session-Bench-$today-2.md\n",
		'a directory outside the clones takes the wiki.project value' )
	    or diag $r->{stderr};
};

subtest 'the payload names the checkout, and -C names it first' => sub {
	my ( $tree, $origin ) = _tree();
	my $co =
	    _checkout( $tree, 'Workspace', "wiki.origin\tfile://$origin\n" );
	my $outside = "$tree/outside";
	make_path($outside);

	# The walk starts at the payload cwd, and not at the working
	# directory of the child (CLI-CHECKOUT-1, HOOK-EVENTS-5). The
	# child runs in a directory with no .toolingrc above it, and
	# the payload checkout leaves no report for a later call.
	my $r = _hook( $tree, 'SessionStart',
		_json( session_id => 's1', cwd => $co ), cwd => $outside );
	is( $r->{stdout}, "Session-Workspace-$today-1.md\n",
		'the payload cwd gives the checkout' )
	    or diag $r->{stderr};
	unlike( $r->{stderr}, qr/no \.toolingrc/,
		'the payload checkout reports no configuration error' );

	# A cwd with no .toolingrc above it warns, and the session
	# still starts (HOOK-EVENTS-3).
	$r = _hook( $tree, 'SessionStart',
		_json( session_id => 's2', cwd => $outside ) );
	is( $r->{exit_code}, 0, 'a cwd with no checkout exits zero' );
	like( $r->{stderr}, qr/no \.toolingrc above \Q$outside\E/,
		'the warning names the cwd' );
	is( $r->{stdout}, q{}, 'that event writes no page name' );

	# -C names the root ahead of the payload (CLI-CHECKOUT-1).
	$r = _hook(
		$tree, 'SessionStart',
		_json( session_id => 's3', cwd => $outside ),
		global => [ '-C', $co ] );
	is( $r->{stdout}, "Session-Workspace-$today-2.md\n",
		'-C gives the checkout of the run' )
	    or diag $r->{stderr};
};

subtest 'a session in a worktree reads the worktree' => sub {
	my ( $tree, $origin ) = _tree();
	my $co = _checkout( $tree, 'Workspace',
		"wiki.origin\tfile://$origin\n" . "wiki.project\tWorkspace\n" );

	# A worktree holds its own .toolingrc and its own library
	# clone, so it is a checkout of its own. The walk must not cut
	# the cwd at the marker (CLI-CHECKOUT-4, HOOK-EVENTS-5).
	my $wt = "$co/.claude/worktrees/wt-1";
	_write( "$wt/.toolingrc",
		"wiki.origin\tfile://$origin\n" . "wiki.project\tTree\n" );
	_git( $tree, 'clone', '--quiet', "$tree/origin.git", "$wt/Wiki" );

	my $page = "Session-Tree-$today-1.md";
	my $r    = _hook( $tree, 'SessionStart',
		_json( session_id => 's1', cwd => $wt ) );
	is( $r->{stdout}, "$page\n", 'the page takes the project of the worktree' )
	    or diag $r->{stderr};
	ok( -e "$wt/Wiki/$page", 'the page lands in the library of the worktree' );
	is( scalar( glob "$co/Wiki/Session-*" ),
		undef, 'the library above the worktree holds no page' );

	# SessionEnd reads the same checkout, and it closes that page.
	$r = _hook( $tree, 'SessionEnd',
		_json( session_id => 's1', cwd => $wt ) );
	is( $r->{exit_code}, 0, 'SessionEnd exits zero' ) or diag $r->{stderr};
	like( Fugu::File->read("$wt/Wiki/$page"),
		qr/^Closed: /m, 'the page of the worktree holds the closed line' );
};

subtest 'WorktreeCreate writes the path, and a second run repeats it' => sub {
	my ($tree) = _tree();
	my ( $repo, $real ) = _repo( $tree, 'repo', q{} );
	my $wt = "$real/.claude/worktrees/wt-1";

	my $r = _hook( $tree, 'WorktreeCreate',
		_json( cwd => $repo, name => 'wt-1' ) );
	is( $r->{exit_code}, 0, 'the event exits zero' ) or diag $r->{stderr};
	is( $r->{stdout}, "$wt\n", 'the path is the only line of the output' );
	ok( -e "$wt/.git", 'the worktree exists' );

	# Claude Code runs the create hook again when a session
	# reconnects (HOOK-WORKTREE-3, WT-CREATE-7).
	$r = _hook( $tree, 'WorktreeCreate',
		_json( cwd => $repo, name => 'wt-1' ) );
	is( $r->{exit_code}, 0, 'a second create of one name exits zero' )
	    or diag $r->{stderr};
	is( $r->{stdout}, "$wt\n", 'the second create writes the path again' );

	# The harness needs the path, so this event reports a failure
	# (HOOK-EVENTS-3).
	$r = _hook( $tree, 'WorktreeCreate', _json( cwd => $repo ) );
	is( $r->{exit_code}, 1,   'a payload with no name exits 1' );
	is( $r->{stdout},    q{}, 'a payload with no name writes no path' );

	# The event returns the code of the subcommand, and the
	# subcommand refuses a name that leaves the base (WT-CREATE-2).
	$r = _hook( $tree, 'WorktreeCreate',
		_json( cwd => $repo, name => '../escape' ) );
	is( $r->{exit_code}, 1, 'a name that the subcommand refuses exits 1' );
	like( $r->{stderr}, qr/invalid worktree name/,
		'the subcommand names the reason' );

	is(
		_hook( $tree, 'WorktreeCreate', _json( name => 'wt-2' ) )
		    ->{exit_code},
		1,
		'a payload with no cwd exits 1'
	);

	my $outside = "$tree/outside";
	make_path($outside);
	is(
		_hook(
			$tree, 'WorktreeCreate',
			_json( cwd => $outside, name => 'wt-3' ) )->{exit_code},
		1,
		'a cwd with no checkout exits 1'
	);

	# A sub-agent payload changes nothing (HOOK-EVENTS-4).
	$r = _hook( $tree, 'WorktreeCreate',
		_json( cwd => $repo, name => 'wt-4', agent_id => 'a1' ) );
	is( $r->{exit_code}, 0, 'a sub-agent payload exits zero' );
	ok( !-e "$real/.claude/worktrees/wt-4",
		'a sub-agent makes no worktree' );
};

subtest 'WorktreeRemove keeps the worktree and prints the command' => sub {
	my ($tree) = _tree();
	my ($repo) = _repo( $tree, 'repo', q{} );
	my $wt = "$repo/.claude/worktrees/team/wt-1";
	make_path($wt);

	my $r = _hook( $tree, 'WorktreeRemove',
		_json( cwd => $repo, worktree_path => $wt ) );
	is( $r->{exit_code}, 0,   'the event exits zero' );
	is( $r->{stdout},    q{}, 'the event writes no result line' );
	ok( -d $wt, 'the event removes nothing' );
	like( $r->{stderr}, qr/\Qworktree kept: $wt\E/,
		'the hint names the path' );
	like(
		$r->{stderr},
		qr{\Qto remove it: make -C $repo worktree-remove NAME=team/wt-1\E},
		'the hint names the root and the name'
	);

	# The split takes the worktree.base value of the checkout.
	my ($other) = _repo( $tree, 'other', "worktree.base\ttrees\n" );
	$r = _hook( $tree, 'WorktreeRemove',
		_json( cwd => $other, worktree_path => "$other/trees/wt-2" ) );
	like( $r->{stderr}, qr{\Qmake -C $other worktree-remove NAME=wt-2\E},
		'the split takes the configured base' );

	# Without a checkout the verb prints the path alone.
	$r = _hook( $tree, 'WorktreeRemove', _json( worktree_path => $wt ) );
	is( $r->{exit_code}, 0, 'a payload with no cwd exits zero' );
	like( $r->{stderr}, qr/\Qworktree kept: $wt\E/,
		'the hint names the path' );
	unlike( $r->{stderr}, qr/to remove it/,
		'the hint holds no command without a base' );

	# A path with no segment of the base gives the same, and so
	# does a path that ends at the base.
	$r = _hook( $tree, 'WorktreeRemove',
		_json( cwd => $repo, worktree_path => "$repo/plain" ) );
	unlike( $r->{stderr}, qr/to remove it/,
		'a path outside the base gives no command' );

	$r = _hook(
		$tree,
		'WorktreeRemove',
		_json(
			cwd           => $repo,
			worktree_path => "$repo/.claude/worktrees/"
		) );
	unlike( $r->{stderr}, qr/to remove it/,
		'a path with no name after the base gives no command' );

	# The split takes the last segment of the base.
	my $nested = "$repo/.claude/worktrees/a/.claude/worktrees/b";
	$r = _hook( $tree, 'WorktreeRemove',
		_json( cwd => $repo, worktree_path => $nested ) );
	like(
		$r->{stderr},
		qr{\Qmake -C $repo/.claude/worktrees/a worktree-remove NAME=b\E},
		'the split takes the last segment of the base'
	);

	$r = _hook( $tree, 'WorktreeRemove', _json( cwd => $repo ) );
	is( $r->{exit_code}, 0, 'a payload with no path exits zero' );
	like( $r->{stderr}, qr/names no worktree path/,
		'the warning names the absent key' );
};

subtest 'a word outside the events is a usage error' => sub {
	my ($tree) = _tree();

	my $r = _hook( $tree, 'SessionResume', '{}' );
	is( $r->{exit_code}, 2, 'an unknown event exits 2' );
	like( $r->{stderr}, qr/SessionStart/, 'the usage names each event' );

	$r = _child( $tree, '{}', 'hook', 'SessionEnd', 'again' );
	is( $r->{exit_code}, 2, 'an argument after the event exits 2' );

	$r = _child( $tree, '{}', 'hook' );
	is( $r->{exit_code}, 2, 'the verb with no event exits 2' );

	$r = _child( $tree, '{}', 'hook', '--help' );
	is( $r->{exit_code}, 0, 'the help of the verb exits 0' );
	like( $r->{stdout}, qr/SessionStart/, 'the help names each event' );
};

done_testing();
