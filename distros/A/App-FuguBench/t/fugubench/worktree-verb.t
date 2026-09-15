#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The create, the remove, the list, and the clone subcommands of the
# worktree verb (WT-CREATE, WT-REMOVE, WT-LIST, WT-CLONE, WT-SAFETY).
#
# Each case runs bin/fugubench as a child with -Ilib, against a
# temporary repository with one commit on main and an empty
# .toolingrc. No case reads the operator home, and no case writes
# outside its temporary tree.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use Cwd        qw(abs_path);
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";

use Fugu::File;
use Fugu::Process;

my $root    = "$RealBin/../..";
my $program = "$root/bin/fugubench";

plan skip_all => 'git is absent'
    unless Fugu::Process->find_command('git');
plan skip_all => 'make is absent'
    unless Fugu::Process->find_command('make');

# _git(@args):
#	Run git, and die on a failure. The method returns the standard
#	output of the child.
sub _git (@args)
{
	my $result = Fugu::Process->run( cmd => [ 'git', @args ] );
	die "git @args: $result->{stderr}" unless $result->{success};

	return $result->{stdout};
}

# _write($path, $text):
#	Write one file, and die on a failure.
sub _write ( $path, $text )
{
	Fugu::File->write( $path, $text ) or die "write $path";

	return;
}

# _repo($recipe, $parent):
#	A checkout with one commit on main, an empty .toolingrc, and
#	the bootstrap recipe of the caller. The checkout sits in the
#	parent directory of the caller, or in a temporary directory of
#	its own.
#
#	The method returns the path of the checkout and the resolved
#	path of it, in that order: the temporary directory is a
#	symbolic link on macOS, and git reports the resolved path.
sub _repo ( $recipe = undef, $parent = undef )
{
	make_path($parent) if defined $parent && !-d $parent;
	my $dir = tempdir(
		CLEANUP => 1,
		defined $parent ? ( DIR => $parent ) : () );
	_git( 'init', '--quiet', '-b',     'main',       $dir );
	_git( '-C',   $dir,      'config', 'user.email', 'a@b' );
	_git( '-C',   $dir,      'config', 'user.name',  'a' );

	# The test must not depend on the operator signing agent.
	_git( '-C', $dir, 'config', 'commit.gpgsign', 'false' );

	_write( "$dir/.toolingrc",  q{} );
	# The checkout ignores each worktree base that a case
	# configures, as a checkout of the operator does.
	_write( "$dir/.gitignore",  ".claude/worktrees/\ntrees/\n" );
	_write( "$dir/f.txt",       "x\n" );
	_write( "$dir/GNUmakefile", "bootstrap:\n\t$recipe\n" )
	    if defined $recipe;

	_git( '-C', $dir, 'add', '-A' );
	_git( '-C', $dir, 'commit', '--quiet', '-m', 'Initial commit' );

	return ( $dir, abs_path($dir) );
}

# _run($dir, @argv):
#	Run the worktree verb against one checkout, and return the
#	result of Fugu::Process->run.
sub _run ( $dir, @argv )
{
	my $result = Fugu::Process->run(
		cmd => [
			$^X,  "-I$root/lib", $program, '-C',
			$dir, 'worktree',    @argv
		] );
	die "cannot run $program: $result->{error}"
	    if defined $result->{error};

	return $result;
}

# _branches($dir):
#	Each branch of one checkout, in sorted order.
sub _branches ($dir)
{
	my $out = _git( '-C', $dir, 'branch', '--format=%(refname:short)' );

	my @branches = sort split /\n/, $out;

	return @branches;
}

# _poll($code, $limit):
#	Call the code every tenth of a second until it answers true,
#	or until the limit of seconds runs out. The method returns the
#	answer of the code.
sub _poll ( $code, $limit = 30 )
{
	for ( 1 .. $limit * 10 ) {
		my $value = $code->();
		return $value if $value;
		select undef, undef, undef, 0.1;
	}

	return;
}

# _source($path, $origin):
#	A git repository at one path, with one commit on main and one
#	origin URL. Clone reads the URL from the source, so the clone
#	of a bootstrap points at the same remote.
sub _source ( $path, $origin )
{
	_git( 'init', '--quiet', '-b', 'main', $path );
	_git( '-C', $path, 'config', 'user.email',     'a@b' );
	_git( '-C', $path, 'config', 'user.name',      'a' );
	_git( '-C', $path, 'config', 'commit.gpgsign', 'false' );
	_git( '-C', $path, 'remote', 'add', 'origin', $origin );
	_write( "$path/f.txt", "x\n" );
	_git( '-C', $path, 'add',    '-A' );
	_git( '-C', $path, 'commit', '--quiet', '-m', 'Initial commit' );

	return;
}

# _clone($dir, $cwd, @paths):
#	Run the clone subcommand of one checkout from one current
#	directory. A bootstrap target runs it that way: the current
#	directory is the worktree, and -C names the main checkout.
sub _clone ( $dir, $cwd, @paths )
{
	my $result = Fugu::Process->run(
		cmd => [
			$^X,  "-I$root/lib", $program, '-C',
			$dir, 'worktree',    'clone',  @paths
		],
		cwd => $cwd,
	);
	die "cannot run $program: $result->{error}"
	    if defined $result->{error};

	return $result;
}

subtest 'create makes one worktree and reports its path' => sub {
	my ( $dir, $real ) = _repo('@echo "MAIN=$(MAIN)" > bootstrap.log');
	my $wt = "$real/.claude/worktrees/fix/auth";

	my $result = _run( $dir, 'create', 'fix/auth' );
	is( $result->{exit_code}, 0, 'create exits 0' )
	    or diag $result->{stderr};
	is( $result->{stdout}, "$wt\n",
		'create writes the path as the only line (WT-CREATE-5)' );
	ok( -d $wt, 'the worktree exists' );
	is_deeply(
		[ _branches($dir) ],
		[ 'fix/auth', 'main' ],
		'create makes the branch (WT-CREATE-1)'
	);
	is(
		Fugu::File->read("$wt/bootstrap.log"),
		"MAIN=$real\n",
		'the bootstrap target reads MAIN (WT-CREATE-4)'
	);
};

subtest 'create refuses a name of the wrong shape' => sub {
	my ( $dir, $real ) = _repo();
	my %case = (
		'a name that starts with a dash' => [ '--', '-x' ],
		'a name that starts with a dot'  => ['.hidden'],
		'a name with a parent segment'   => ['a/../b'],
	);

	for my $name ( sort keys %case ) {
		my $result = _run( $dir, 'create', @{ $case{$name} } );
		is( $result->{exit_code}, 1,   "$name exits 1 (WT-CREATE-2)" );
		is( $result->{stdout},    q{}, "$name writes no path" );

		# The shape check stops the name, so a name of the
		# wrong shape never reaches git as an argument.
		like(
			$result->{stderr},
			qr/invalid worktree name/,
			"the verb refuses $name itself"
		);
	}

	is_deeply( [ _branches($dir) ], ['main'], 'a refusal makes no branch' );
	ok( !-e "$real/.claude/worktrees", 'a refusal makes no directory' );
};

subtest 'a second create repairs the bootstrap and reports the path' => sub {

	# A caller can run the same create twice. The second run must
	# write the path and exit 0 (WT-CREATE-7).
	my ( $dir, $real ) = _repo('@echo run >> bootstrap.log');
	my $wt = "$real/.claude/worktrees/again";

	my $result = _run( $dir, 'create', 'again' );
	is( $result->{exit_code}, 0, 'the first create exits 0' )
	    or diag $result->{stderr};

	$result = _run( $dir, 'create', 'again' );
	is( $result->{exit_code}, 0, 'the second create exits 0' )
	    or diag $result->{stderr};
	is( $result->{stdout}, "$wt\n",
		'the second create writes the path (WT-CREATE-7)' );

	# Each clone step of a bootstrap skips what exists, so the
	# second run repairs a bootstrap that stopped early.
	is(
		Fugu::File->read("$wt/bootstrap.log"),
		"run\nrun\n",
		'the second create runs the bootstrap again (WT-CREATE-7)'
	);
	ok( -d $wt, 'the worktree stays' );
	is_deeply( [ _branches($dir) ],
		[ 'again', 'main' ], 'the second create keeps the branch' );
};

subtest 'create refuses debris, a branch, and a nest' => sub {
	my ( $dir, $real ) = _repo();
	my $base = "$real/.claude/worktrees";

	# A directory that git does not know is debris of a killed
	# create. Only remove clears it (WT-CREATE-7).
	make_path("$base/debris");
	my $result = _run( $dir, 'create', 'debris' );
	is( $result->{exit_code}, 1, 'create refuses debris' );
	is( $result->{stdout},    q{}, 'the refusal writes no path' );
	like(
		$result->{stderr},
		qr/not a worktree of debris/,
		'the message names the cause'
	);
	like(
		$result->{stderr},
		qr/fugubench worktree remove debris/,
		'the message names the remove command as the remedy'
	);
	ok( !-e "$base/debris/.git", 'create makes no worktree in it' );
	is_deeply( [ _branches($dir) ],
		['main'],
		'create makes no branch for a directory that exists' );

	# The branch step is the lock of WT-CREATE-3, so a branch that
	# exists stops the create.
	_git( '-C', $dir, 'branch', 'taken' );
	$result = _run( $dir, 'create', 'taken' );
	is( $result->{exit_code}, 1, 'create refuses a branch that exists' );
	ok( !-e "$base/taken", 'create makes no directory for it' );

	$result = _run( $dir, 'create', 'outer' );
	is( $result->{exit_code}, 0, 'create makes the outer worktree' )
	    or diag $result->{stderr};
	$result = _run( $dir, 'create', 'outer/inner' );
	is( $result->{exit_code}, 1,
		'create refuses a name inside a worktree (WT-CREATE-2)' );
	ok( !-e "$base/outer/inner", 'create makes no nested directory' );
	is_deeply(
		[ _branches($dir) ],
		[ 'main', 'outer', 'taken' ],
		'create makes no branch for a nested name'
	);
};

subtest 'a failed bootstrap leaves no worktree and no branch' => sub {
	my ( $dir, $real ) = _repo('@exit 1');

	my $result = _run( $dir, 'create', 's/t' );
	is( $result->{exit_code}, 1,   'create exits 1 (WT-CREATE-6)' );
	is( $result->{stdout},    q{}, 'create writes no path' );
	ok(
		!-e "$real/.claude/worktrees/s",
		'the cleanup removes the empty parent'
	);
	is_deeply( [ _branches($dir) ],
		['main'], 'the cleanup deletes the branch' );
	unlike( _git( '-C', $dir, 'worktree', 'list', '--porcelain' ),
		qr{worktrees/s/t}, 'the cleanup prunes the worktree record' );
};

subtest 'a signal during the bootstrap leaves no worktree' => sub {
	my ( $dir, $real ) = _repo('@echo $$$$ > bootstrap.pid; sleep 30');
	my $wt  = "$real/.claude/worktrees/sig/t";
	my $tmp = tempdir( CLEANUP => 1 );

	my $child = Fugu::Process->spawn_command(
		cmd => [
			$^X,  "-I$root/lib", $program, '-C',
			$dir, 'worktree',    'create', 'sig/t'
		],
		stdout => "$tmp/stdout",
		stderr => "$tmp/stderr",
	);
	ok( $child->{success}, 'the program starts' )
	    or die "cannot start $program: $child->{error}";

	# The bootstrap reports the pid of its own child, so the case
	# can prove that the signal stops the whole group.
	my $pid = _poll( sub { Fugu::File->read("$wt/bootstrap.pid") } );
	chomp $pid if defined $pid;
	ok( $pid, 'the bootstrap child reports its pid' )
	    or diag Fugu::File->read("$tmp/stderr") // q{};

	kill 'TERM', $child->{pid};
	waitpid $child->{pid}, 0;
	is( $? >> 8, 1, 'the signal gives the failure code (WT-CREATE-6)' );
	is( Fugu::File->read("$tmp/stdout"), q{}, 'create writes no path' );

	ok( _poll( sub { !kill 0, $pid }, 10 ),
		'the child of the bootstrap is gone (WT-SAFETY-3)' );
	ok( !-e $wt, 'the worktree is gone' );
	ok(
		!-e "$real/.claude/worktrees/sig",
		'the empty parent is gone (WT-CREATE-6)'
	);
	is_deeply( [ _branches($dir) ], ['main'], 'the branch is gone' );
};

subtest 'remove takes the worktree, the branch, and the parent' => sub {
	my ( $dir, $real ) = _repo();
	my $base = "$real/.claude/worktrees";

	my $result = _run( $dir, 'create', 'gone/one' );
	is( $result->{exit_code}, 0, 'create makes the worktree' )
	    or diag $result->{stderr};

	$result = _run( $dir, 'remove', 'gone/one' );
	is( $result->{exit_code}, 0, 'remove exits 0 (WT-REMOVE-1)' )
	    or diag $result->{stderr};
	is( $result->{stdout}, q{}, 'remove writes no line' );
	ok( !-e "$base/gone/one", 'the worktree is gone' );
	ok( !-e "$base/gone",     'the empty parent is gone (WT-REMOVE-7)' );
	is_deeply( [ _branches($dir) ],
		['main'], 'remove deletes the branch (WT-REMOVE-1)' );

	# A second run finds no directory and no branch, and it
	# changes nothing (WT-REMOVE-4).
	$result = _run( $dir, 'remove', 'gone/one' );
	is( $result->{exit_code}, 0, 'a second remove exits 0 (WT-REMOVE-4)' )
	    or diag $result->{stderr};
	is_deeply( [ _branches($dir) ], ['main'], 'the second run keeps main' );
};

subtest 'remove takes a lock, debris, and a removal by hand' => sub {
	my ( $dir, $real ) = _repo();
	my $base = "$real/.claude/worktrees";

	my $result = _run( $dir, 'create', 'locked' );
	is( $result->{exit_code}, 0, 'create makes the worktree' )
	    or diag $result->{stderr};
	_git( '-C', $dir, 'worktree', 'lock', "$base/locked" );

	$result = _run( $dir, 'remove', 'locked' );
	is( $result->{exit_code}, 0,
		'remove takes a locked worktree (WT-REMOVE-4)' )
	    or diag $result->{stderr};
	ok( !-e "$base/locked", 'the locked worktree is gone' );

	# A directory that git does not know is debris from a killed
	# create. git refuses it, and the verb takes the directory
	# itself (WT-SAFETY-2).
	make_path("$base/debris");
	_write( "$base/debris/f.txt", "x\n" );
	$result = _run( $dir, 'remove', 'debris' );
	is( $result->{exit_code}, 0, 'remove takes debris (WT-SAFETY-2)' )
	    or diag $result->{stderr};
	ok( !-e "$base/debris", 'the debris is gone' );
	like(
		$result->{stderr},
		qr/git refused, deleting the directory/,
		'the message names the second step'
	);

	# A user who removes the directory by hand leaves the branch
	# and the worktree record of git.
	$result = _run( $dir, 'create', 'byhand' );
	is( $result->{exit_code}, 0, 'create makes the worktree' )
	    or diag $result->{stderr};
	remove_tree("$base/byhand");
	$result = _run( $dir, 'remove', 'byhand' );
	is( $result->{exit_code}, 0,
		'remove takes a removal by hand (WT-REMOVE-4)' )
	    or diag $result->{stderr};
	is_deeply( [ _branches($dir) ], ['main'], 'the branch is gone' );
	unlike( _git( '-C', $dir, 'worktree', 'list', '--porcelain' ),
		qr{worktrees/byhand}, 'remove prunes the worktree record' );
};

subtest 'remove takes debris while the main checkout holds work' => sub {
	my ( $dir, $real ) = _repo();
	my $base = "$real/.claude/worktrees";

	# git knows no debris, so the discovery of git walks up from
	# it to the main checkout. The main checkout here holds both
	# causes of WT-REMOVE-2, and neither one belongs to the debris
	# (WT-REMOVE-4).
	_git( '-C', $dir, 'checkout', '--quiet', '-b', 'work' );
	_write( "$dir/g.txt", "new\n" );
	_git( '-C', $dir, 'add',      '-A' );
	_git( '-C', $dir, 'commit',   '--quiet', '-m', 'a commit of the root' );
	_git( '-C', $dir, 'checkout', '--quiet', 'main' );
	_write( "$dir/f.txt", "changed\n" );

	make_path("$base/debris");
	_write( "$base/debris/f.txt", "x\n" );

	my $result = _run( $dir, 'remove', 'debris' );
	is( $result->{exit_code}, 0,
		'remove takes debris under a dirty root (WT-REMOVE-4)' )
	    or diag $result->{stderr};
	unlike( $result->{stderr}, qr/work at risk/,
		'no state of the main checkout stops the removal' );
	ok( !-e "$base/debris", 'the debris is gone' );
	is( Fugu::File->read("$dir/f.txt"),
		"changed\n", 'the change of the main checkout stays' );
	is_deeply( [ _branches($dir) ],
		[ 'main', 'work' ], 'remove keeps each branch of the root' );
};

subtest 'remove frees the name after a killed create' => sub {
	my ( $dir, $real ) = _repo();
	my $base = "$real/.claude/worktrees";

	# A killed create leaves the branch and a directory that git
	# does not know. git reads the branch of the main checkout in
	# that directory, so remove must read none. The branch must
	# go, or the name stays locked (WT-REMOVE-4).
	_git( '-C', $dir, 'branch', 'killed' );
	make_path("$base/killed");
	_write( "$base/killed/f.txt", "x\n" );

	my $result = _run( $dir, 'remove', 'killed' );
	is( $result->{exit_code}, 0, 'remove takes the debris (WT-SAFETY-2)' )
	    or diag $result->{stderr};
	is_deeply( [ _branches($dir) ],
		['main'],
		'remove deletes the branch of the killed create' );

	$result = _run( $dir, 'create', 'killed' );
	is( $result->{exit_code}, 0, 'create takes the name again' )
	    or diag $result->{stderr};
	ok( -e "$base/killed/.git", 'the second create makes the worktree' );
};

subtest 'remove refuses work at risk, and --force overrides' => sub {
	my ( $dir, $real ) = _repo();
	my $base = "$real/.claude/worktrees";

	my $result = _run( $dir, 'create', 'dirty' );
	is( $result->{exit_code}, 0, 'create makes the worktree' )
	    or diag $result->{stderr};
	_write( "$base/dirty/f.txt", "changed\n" );

	$result = _run( $dir, 'remove', 'dirty' );
	is( $result->{exit_code}, 1,
		'remove refuses an uncommitted change (WT-REMOVE-2)' );
	like(
		$result->{stderr},
		qr/\Q.: uncommitted change\E$/m,
		'the message holds the risk line of the worktree'
	);
	ok( -d "$base/dirty", 'the worktree stays' );
	is_deeply( [ _branches($dir) ],
		[ 'dirty', 'main' ], 'the branch stays' );

	$result = _run( $dir, 'remove', '--force', 'dirty' );
	is( $result->{exit_code}, 0,
		'--force overrides the refusal (WT-REMOVE-2)' )
	    or diag $result->{stderr};
	ok( !-e "$base/dirty", 'the worktree is gone after --force' );

	# A commit that no remote holds is the second cause. The
	# fixture has no remote, and main does not hold the commit.
	$result = _run( $dir, 'create', 'ahead' );
	is( $result->{exit_code}, 0, 'create makes the worktree' )
	    or diag $result->{stderr};
	_write( "$base/ahead/g.txt", "new\n" );
	_git( '-C', "$base/ahead", 'add',    '-A' );
	_git( '-C', "$base/ahead", 'commit', '--quiet', '-m', 'work at risk' );

	$result = _run( $dir, 'remove', 'ahead' );
	is( $result->{exit_code}, 1,
		'remove refuses a commit that no remote holds (WT-REMOVE-2)' );
	like(
		$result->{stderr},
		qr/\Q.: 1 commit(s) that no remote holds\E$/m,
		'the message holds the risk line with the count'
	);
	ok( -d "$base/ahead", 'the worktree stays' );

	$result = _run( $dir, 'remove', '--force', 'ahead' );
	is( $result->{exit_code}, 0, '--force takes the worktree' )
	    or diag $result->{stderr};
	is_deeply( [ _branches($dir) ],
		['main'], '--force deletes the branch' );
};

subtest 'remove never deletes main or the checked-out branch' => sub {
	my ( $dir, $real ) = _repo();
	my $base = "$real/.claude/worktrees";

	# The root holds main, and it has another branch checked out.
	# The two guards of WT-REMOVE-5 are then apart.
	_git( '-C', $dir, 'checkout', '--quiet', '-b', 'keep' );
	_git( '-C', $dir, 'worktree', 'add', '--quiet', "$base/main", 'main' );

	my $result = _run( $dir, 'remove', 'main' );
	is( $result->{exit_code}, 0, 'remove exits 0' ) or diag $result->{stderr};
	ok( !-e "$base/main", 'the worktree of main is gone' );
	is_deeply( [ _branches($dir) ],
		[ 'keep', 'main' ], 'remove keeps main (WT-REMOVE-5)' );

	# Debris that carries the name of the checked-out branch. git
	# reports that branch inside the directory, and the branch
	# must stay (WT-REMOVE-5).
	make_path("$base/keep");
	$result = _run( $dir, 'remove', 'keep' );
	is( $result->{exit_code}, 0, 'remove exits 0 for the debris' )
	    or diag $result->{stderr};
	ok( !-e "$base/keep", 'the debris is gone' );
	is_deeply(
		[ _branches($dir) ],
		[ 'keep', 'main' ],
		'remove keeps the checked-out branch (WT-REMOVE-5)'
	);
};

subtest 'remove refuses a link that resolves outside the base' => sub {
	my ( $dir, $real ) = _repo();
	my $base = "$real/.claude/worktrees";

	# The target sits outside the checkout, so no risk walk of the
	# checkout reports it and stops the removal by itself.
	my $away = tempdir( CLEANUP => 1 );
	_write( "$away/keep.txt", "work\n" );
	make_path($base);
	symlink $away, "$base/link" or die "symlink: $!";

	my $result = _run( $dir, 'remove', 'link' );
	is( $result->{exit_code}, 1,
		'remove refuses the link (WT-REMOVE-6)' );
	like(
		$result->{stderr},
		qr/resolves outside/,
		'the message names the cause'
	);
	ok( -e "$away/keep.txt", 'the file outside the base stays' );
	ok( -l "$base/link",     'the link stays' );
};

subtest 'list reports each worktree with its age and its state' => sub {
	my ( $dir, $real ) = _repo();

	my $result = _run( $dir, 'list' );
	is( $result->{exit_code}, 0, 'list exits 0' );
	is(
		$result->{stdout},
		"no worktrees\n",
		'list reports an empty base (WT-LIST-2)'
	);

	$result = _run( $dir, 'create', 'clean' );
	is( $result->{exit_code}, 0, 'create makes the worktree' )
	    or diag $result->{stderr};

	$result = _run( $dir, 'list' );
	like(
		$result->{stdout},
		qr/^clean\s+\d+ d\s+clean$/m,
		'the line holds the name, the age and the state'
	);

	# The age comes from the gitfile of the worktree, and a
	# gitfile that no read reaches gives the age ? (WT-LIST-1).
	unlink "$real/.claude/worktrees/clean/.git"
	    or die "unlink the gitfile: $!";
	$result = _run( $dir, 'list' );
	is( $result->{exit_code}, 0, 'list exits 0 without a gitfile' );
	like(
		$result->{stdout},
		qr/^clean\s+[?] d\s+/m,
		'the age of a gitfile that no read reaches is a question mark'
	);
};

subtest 'clone makes local clones and copies the env files' => sub {
	my ( $dir, $real ) = _repo();
	my $dest = tempdir( CLEANUP => 1 );

	_source( "$real/Projects/one", 'https://example.com/one.git' );
	_source( "$real/Projects/two", 'https://example.com/two.git' );

	# A .env file is gitignored, so no clone of git carries it.
	# The copy must keep the mode of the source, and it must skip
	# a link: a .env link is content of the repository (WT-CLONE-3).
	make_path("$real/Projects/one/deep");
	Fugu::File->write( "$real/Projects/one/deep/.env",
		"KEY=value\n", mode => 0600 )
	    or die 'write the .env file';
	symlink 'f.txt', "$real/Projects/two/.env" or die "symlink: $!";

	my $result = _clone( $dir, $dest, 'Projects' );
	is( $result->{exit_code}, 0, 'clone exits 0' )
	    or diag $result->{stderr};
	ok( -d "$dest/Projects/one/.git",
		'clone takes the first child of the directory (WT-CLONE-2)' );
	ok( -d "$dest/Projects/two/.git",
		'clone takes the second child of the directory (WT-CLONE-2)' );
	is(
		_git( '-C', "$dest/Projects/one", 'remote', 'get-url',
			'origin' ),
		"https://example.com/one.git\n",
		'the clone carries the origin URL of the source (WT-CLONE-2)'
	);

	ok( -f "$dest/Projects/one/deep/.env",
		'the .env file at depth arrives (WT-CLONE-3)' );
	is(
		( stat "$dest/Projects/one/deep/.env" )[2] & 07777,
		0600,
		'the copy keeps the mode of the source (WT-CLONE-3)'
	);
	ok( !-e "$dest/Projects/two/.env",
		'clone skips a .env symbolic link (WT-CLONE-3)' );
};

subtest 'clone keeps what exists and refuses a bad path' => sub {
	my ( $dir, $real ) = _repo();
	my $dest = tempdir( CLEANUP => 1 );

	_source( "$real/Wiki", 'https://example.com/wiki.git' );
	_write( "$real/.env", "KEY=value\n" );

	# A destination that exists stays as it is, so a second run
	# repairs a bootstrap that stopped early (WT-CLONE-4).
	make_path("$dest/Wiki");
	_write( "$dest/Wiki/local.txt", "mine\n" );

	# A project can leave a symbolic link at the destination of a
	# file copy. The copy replaces the link, and it writes no byte
	# through it (WT-CLONE-4).
	my $away = tempdir( CLEANUP => 1 );
	_write( "$away/target.txt", "outside\n" );
	symlink "$away/target.txt", "$dest/.env" or die "symlink: $!";

	my $result = _clone( $dir, $dest, 'Wiki', '.env', 'absent' );
	is( $result->{exit_code}, 0, 'clone exits 0' )
	    or diag $result->{stderr};
	ok( !-e "$dest/Wiki/.git",
		'clone keeps the destination that exists (WT-CLONE-4)' );
	is( Fugu::File->read("$dest/Wiki/local.txt"),
		"mine\n", 'the local change stays (WT-CLONE-4)' );
	like(
		$result->{stderr},
		qr{already exists, skipped: Wiki},
		'the message names the destination that clone skips'
	);

	ok( !-l "$dest/.env", 'clone replaces the destination link' );
	is( Fugu::File->read("$dest/.env"),
		"KEY=value\n", 'the copy holds the source (WT-CLONE-4)' );
	is( Fugu::File->read("$away/target.txt"),
		"outside\n", 'the file outside the tree keeps its content' );

	like(
		$result->{stderr},
		qr{missing in main checkout, skipped: absent},
		'clone skips an absent path with a message (WT-CLONE-5)'
	);

	# A path with a parent segment leaves the current directory,
	# so the shape check stops it before any work (WT-CLONE-5).
	$result = _clone( $dir, $dest, '../escape' );
	is( $result->{exit_code}, 1,
		'clone refuses a path with a parent segment (WT-CLONE-5)' );
	like( $result->{stderr}, qr/invalid path/,
		'the message names the cause' );

	# In the main checkout itself, clone changes nothing
	# (WT-CLONE-6).
	$result = _clone( $dir, $dir, 'Wiki' );
	is( $result->{exit_code}, 0, 'clone exits 0 in the main checkout' )
	    or diag $result->{stderr};
	like(
		$result->{stderr},
		qr/already the main checkout, nothing to do/,
		'the message names the cause (WT-CLONE-6)'
	);
	ok( -d "$real/Wiki/.git",
		'the main checkout keeps its repository (WT-CLONE-6)' );
};

subtest 'the base of the worktrees resolves against the root' => sub {

	# A clone under Projects/ inherits worktree.base from the
	# workspace above it, and its worktrees belong to the clone.
	# So the value resolves against the root, and not against the
	# home of the key (CLI-CONFIG-2).
	my $home = tempdir( CLEANUP => 1 );
	_write( "$home/.toolingrc", "worktree.base trees\n" );
	my ( $dir, $real ) = _repo( undef, "$home/Projects" );

	my $result = _run( $dir, 'create', 'one' );
	is( $result->{exit_code}, 0, 'create exits 0 with a configured base' )
	    or diag $result->{stderr};
	is( $result->{stdout}, "$real/trees/one\n",
		'the worktree sits under the configured base (CLI-CONFIG-2)' );

	$result = _run( $dir, 'list' );
	like(
		$result->{stdout},
		qr/^one\s+\d+ d\s+clean$/m,
		'list reads the configured base'
	);
};

subtest 'the nested worktree directory follows the configured base' => sub {

	# The skip of WT-REMOVE-3 and WT-CLONE-3 names the
	# worktree.base directory, and a checkout can configure
	# another one.
	my $home = tempdir( CLEANUP => 1 );
	_write( "$home/.toolingrc", "worktree.base trees\n" );
	my ( $dir, $real ) = _repo( undef, "$home/Projects" );

	my $result = _run( $dir, 'create', 'outer' );
	is( $result->{exit_code}, 0, 'create makes the worktree' )
	    or diag $result->{stderr};

	# A worktree of the worktree sits under the configured base.
	# The risk walk must skip it, so no state of it stops the
	# removal of the outer worktree.
	my $inner = "$real/trees/outer/trees/inner";
	make_path($inner);
	_git( 'init', '--quiet', '-b', 'main', $inner );
	_write( "$inner/f.txt", "work\n" );

	$result = _run( $dir, 'remove', 'outer' );
	is( $result->{exit_code}, 0,
		'the risk walk skips the configured base (WT-REMOVE-3)' )
	    or diag $result->{stderr};
	ok( !-e "$real/trees/outer", 'the worktree is gone' );

	# The .env walk of clone skips the same directory
	# (WT-CLONE-3).
	my $dest = tempdir( CLEANUP => 1 );
	_source( "$real/Projects/one", 'https://example.com/one.git' );
	make_path("$real/Projects/one/trees/inner");
	make_path("$real/Projects/one/deep");
	_write( "$real/Projects/one/trees/inner/.env", "KEY=nested\n" );
	_write( "$real/Projects/one/deep/.env",        "KEY=value\n" );

	$result = _clone( $dir, $dest, 'Projects' );
	is( $result->{exit_code}, 0, 'clone exits 0' )
	    or diag $result->{stderr};
	ok( -f "$dest/Projects/one/deep/.env",
		'the .env file outside the base arrives (WT-CLONE-3)' );
	ok( !-e "$dest/Projects/one/trees/inner/.env",
		'the .env walk skips the configured base (WT-CLONE-3)' );
};

subtest 'a base of the root stops each subcommand' => sub {

	# A worktree.base of . resolves to the root. The base then
	# holds every path of the checkout, and the containment guard
	# of remove admits each one. So the verb stops with the
	# configuration error (CLI-CONFIG-3).
	my ($dir) = _repo();
	make_path("$dir/lib");
	_write( "$dir/lib/Real.pm", "1;\n" );
	_write( "$dir/.toolingrc",  "worktree.base .\n" );
	_git( '-C', $dir, 'add', '-A' );
	_git( '-C', $dir, 'commit', '--quiet', '-m', 'Add a tracked tree' );

	for my $case ( [ 'create', 'one' ], [ 'remove', 'one' ], ['list'] ) {
		my $result = _run( $dir, @{$case} );
		is( $result->{exit_code}, 3,
			"$case->[0] stops with the configuration error" );
		like( $result->{stderr}, qr/worktree[.]base/,
			'the message names the key' );
	}

	my $dest   = tempdir( CLEANUP => 1 );
	my $result = _clone( $dir, $dest, 'lib' );
	is( $result->{exit_code}, 3,
		'clone stops with the configuration error' );
	ok( !-e "$dest/lib", 'clone copies nothing' );

	# The remove of a tracked directory of the checkout. No other
	# guard holds here: the risk walk finds no repository in a
	# plain directory, and _take then deletes the tree
	# (WT-SAFETY-1).
	$result = _run( $dir, 'remove', 'lib' );
	is( $result->{exit_code}, 3, 'remove refuses a tracked directory' );
	ok( -f "$dir/lib/Real.pm", 'the tracked tree stays' );
	is( _git( '-C', $dir, 'status', '--porcelain' ),
		q{}, 'the checkout holds no change' );
};

subtest 'a base of the wrong shape stops each subcommand' => sub {

	# The value leaves the tree, so the shape check of
	# CLI-CONFIG-3 refuses it. Every subcommand reads the base,
	# so each one stops with the configuration error.
	my ($dir) = _repo();
	_write( "$dir/.toolingrc", "worktree.base ../escape\n" );

	for my $case ( [ 'create', 'one' ], [ 'remove', 'one' ], ['list'] ) {
		my $result = _run( $dir, @{$case} );
		is( $result->{exit_code}, 3,
			"$case->[0] stops with the configuration error" );
		like( $result->{stderr}, qr/worktree[.]base: .*leaves the tree/,
			'the message names the key and the cause' );
	}

	my $dest   = tempdir( CLEANUP => 1 );
	my $result = _clone( $dir, $dest, 'Projects' );
	is( $result->{exit_code}, 3,
		'clone stops with the configuration error' );
	like( $result->{stderr}, qr/worktree[.]base: .*leaves the tree/,
		'the message names the key and the cause' );
};

subtest 'a linked worktree is no main checkout' => sub {
	my ( $dir, $real ) = _repo();

	my $result = _run( $dir, 'create', 'inner' );
	is( $result->{exit_code}, 0, 'create makes the worktree' )
	    or diag $result->{stderr};

	# The worktree holds the .toolingrc of the checkout, so the
	# walk stops in it. Its .git is a file, not a directory.
	$result = _run( "$real/.claude/worktrees/inner", 'list' );
	is( $result->{exit_code}, 1,   '-C on a linked worktree exits 1' );
	is( $result->{stdout},    q{}, 'the refusal writes no line' );
};

done_testing();
