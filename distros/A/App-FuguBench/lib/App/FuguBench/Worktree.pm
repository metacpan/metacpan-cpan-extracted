# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package App::FuguBench::Worktree;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Cwd            ();
use File::Basename qw(basename dirname);
use File::Copy     ();
use File::Find     ();
use File::Path     ();
use File::Spec     ();

use Fugu::CLI qw(EXIT_SUCCESS EXIT_ERROR);
use Fugu::Process;

# App::FuguBench::Worktree - the worktree verb.
#
# The verb makes, removes, and lists the worktrees of one checkout,
# and it clones the gitignored trees of that checkout into a
# worktree. The subcommands are create, remove, list, and clone. An
# unknown subcommand gives the usage error.
#
# The root of the verb is the main checkout, and -C names it. A
# linked worktree holds a .git file, not a directory, so the verb
# refuses such a root. No worktree then nests under another one.
#
# Create makes the branch first, as its own step. That step is the
# lock against a parallel create of one name. After that step the
# verb owns all that it makes, so a failure and a signal both run
# one cleanup.
#
# A second create of a name whose worktree exists runs the bootstrap
# again and writes the path again. A second create must not fail,
# and HOOK-WORKTREE-3 gives the reason.
#
# Only an operator runs remove, and no hook calls it (D-06). A
# session captures its work in the clones inside its worktree, so
# remove refuses a worktree that holds work at risk. The option
# --force overrides that refusal.
#
# Clone is the tool of a bootstrap target. It copies the gitignored
# paths of the main checkout into the current directory, with no
# network. A destination that exists stays as it is, so a second run
# repairs a bootstrap that stopped early.

# The subcommands of the verb. An unknown word gives the usage error.
my %SUBCOMMAND = (
	create => \&_create,
	remove => \&_remove,
	list   => \&_list,
	clone  => \&_clone,
);

# The shape of a worktree name (WT-CREATE-2). The first character is
# a letter or a digit: a name that starts with a dash reaches git as
# an option.
my $NAME = qr{\A[A-Za-z0-9][A-Za-z0-9._/-]*\z};

# The shape of a path of clone (WT-CLONE-5). A gitignored path can
# start with a dot, such as .env, so the first character takes a dot
# and an underscore too. It takes no dash, which reaches git as an
# option.
my $PATH = qr{\A[A-Za-z0-9._][A-Za-z0-9._/-]*\z};

# The format of one line of the listing (WT-LIST-1): the name, the
# age in days, and the state.
use constant LINE => '%-40s %4s d  %s';

# The makefiles that make reads, in the order of make itself.
use constant MAKEFILES => qw(GNUmakefile Makefile makefile);

# App::FuguBench::Worktree->command($verb):
#	The entry of the Fugu::CLI table. The module holds one verb,
#	so it ignores the name.
sub command ( $, $ )
{
	return {
		summary => 'create, remove, list, or clone into a worktree',
		usage   => 'create <name> | remove [--force] <name> | list'
		    . ' | clone <path>...',
		options => {
			force => 'remove a worktree that holds work at risk'
		},
		run => sub ( $app, @argv ) { return _run( $app, @argv ) },
	};
}

# _run($app, @argv):
#	The body of the verb. It reads the subcommand as its first
#	argument. Each subcommand counts its own arguments before it
#	looks for the root, so a usage error comes before a
#	configuration error.
sub _run ( $app, @argv )
{
	my $word = shift @argv;
	my $sub  = defined $word ? $SUBCOMMAND{$word} : undef;
	return $app->cli->command_usage_error('worktree') unless $sub;

	return $sub->( $app, @argv );
}

# _root($app):
#	The exit code and the main checkout, in that order. The code
#	is EXIT_SUCCESS when the root holds a value, and the method
#	reports every failure itself.
#
#	The path of the root comes from abs_path, because git reports
#	the resolved path of a worktree. The two must agree, or the
#	listing finds no worktree of the base.
sub _root ($app)
{
	my $checkout = $app->checkout
	    or return Fugu::CLI::EXIT_CONFIG_ERROR();
	my $root = Cwd::abs_path( $checkout->root );

	# A linked worktree holds a .git file, and the main checkout
	# holds a .git directory.
	unless ( defined $root && -d "$root/.git" ) {
		$app->cli->log->error( 'not the main checkout: %s',
			$checkout->root );
		return EXIT_ERROR;
	}

	return ( EXIT_SUCCESS, $root );
}

# _setup($app):
#	The exit code, the main checkout, and the worktree base, in
#	that order. Create, remove, list, and clone all read the base.
#
#	The base is the worktree.base key, and it resolves against the
#	root (CLI-CONFIG-2). A clone under Projects/ can inherit the
#	key from the workspace, and its worktrees belong to the clone.
#
#	The base must name a directory below the root. A value of .
#	resolves to the root itself, and the base then holds every
#	path of the checkout. The containment guard of remove admits
#	each one, so a plain directory of the checkout reaches
#	remove_tree. The method refuses that value (CLI-CONFIG-3).
sub _setup ($app)
{
	my ( $code, $root ) = _root($app);
	return $code if $code != EXIT_SUCCESS;

	my $checkout = $app->checkout;
	my ($value)  = $checkout->config('worktree.base');
	my $dir      = $checkout->dir_value($value);
	unless ( defined $dir ) {
		$app->cli->log->error( 'worktree.base: %s', $checkout->error );
		return Fugu::CLI::EXIT_CONFIG_ERROR();
	}

	my $base = File::Spec->catdir( $root, $dir );
	if ( $base eq $root ) {
		$app->cli->log->error(
			'worktree.base: the directory is the root: %s', $dir );
		return Fugu::CLI::EXIT_CONFIG_ERROR();
	}

	return ( EXIT_SUCCESS, $root, $base );
}

# _nested($root, $base):
#	The pattern of a nested worktree directory (WT-REMOVE-3,
#	WT-CLONE-3). The directory is the worktree.base value, a
#	relative path under a checkout root. So the pattern matches it
#	as a whole segment at the end of a path.
#
#	_setup refuses a base that equals the root, and every caller
#	reads the base from _setup. So the base is longer than the
#	root, and the substr stays inside the string.
sub _nested ( $root, $base )
{
	my $dir = substr $base, length($root) + 1;

	return qr{(?:\A|/)\Q$dir\E\z};
}

# _known($dir):
#	True when git knows the directory as a checkout of its own. A
#	linked worktree holds a .git file, and a main checkout holds a
#	.git directory.
#
#	Debris from a killed create holds neither. The discovery of
#	git then walks up from it to the checkout above it, so every
#	answer of `git -C <debris>` is an answer about that checkout.
#	No caller must trust one.
sub _known ($dir)
{
	return -e "$dir/.git" ? 1 : 0;
}

# _create($app, @argv):
#	Make one worktree of the checkout, and write its path to
#	standard output as the only line (WT-CREATE-5).
#
#	The branch step comes first, and the cleanup starts after it.
#	A failure and a signal then remove all that the verb made: the
#	worktree, the branch, and each empty parent directory.
#
#	A name whose worktree exists goes to _again, which repeats the
#	bootstrap and the path line (WT-CREATE-7).
sub _create ( $app, @argv )
{
	return $app->cli->command_usage_error('worktree') if @argv != 1;
	my ($name) = @argv;

	my ( $code, $root, $base ) = _setup($app);
	return $code if $code != EXIT_SUCCESS;

	my $log = $app->cli->log;
	unless ( $name =~ $NAME && $name !~ m{[.][.]} ) {
		$log->error( 'invalid worktree name: %s', $name );
		return EXIT_ERROR;
	}

	my $wt = File::Spec->catdir( $base, $name );
	return _again( $app, $root, $name, $wt ) if -e $wt;
	return EXIT_ERROR unless _outside( $app, $base, $name, $wt );

	# The branch step is the lock against a parallel create of one
	# name: one create is successful, and the others stop here and
	# change nothing (WT-CREATE-3).
	unless (
		defined $app->command(
			[ 'git', '-C', $root, 'branch', $name ],
			group => 1
		) )
	{
		$log->error( 'cannot make the branch %s: %s',
			$name, $app->error );
		return EXIT_ERROR;
	}

	my $cleanup = sub { _cleanup( $app, $root, $base, $name, $wt ) };
	my $signal  = sub {
		$SIG{INT} = $SIG{TERM} = 'IGNORE';
		$log->error('interrupted, cleaning up');
		Fugu::Process->terminate( $app->child, group => 1 )
		    if defined $app->child;
		$cleanup->();
		exit EXIT_ERROR;
	};
	local $SIG{INT}  = $signal;
	local $SIG{TERM} = $signal;

	unless (
		defined $app->command(
			[ 'git', '-C', $root, 'worktree', 'add', $wt, $name ],
			group => 1
		) )
	{
		$log->error( 'cannot add the worktree %s: %s',
			$wt, $app->error );
		$cleanup->();
		return EXIT_ERROR;
	}

	unless ( _bootstrap( $app, $root, $wt ) ) {
		$log->error( 'the bootstrap of %s failed: %s',
			$wt, $app->error );
		$cleanup->();
		return EXIT_ERROR;
	}

	say $wt;

	return EXIT_SUCCESS;
}

# _again($app, $root, $name, $wt):
#	The result of a second create of one name (WT-CREATE-7). A
#	second create must not fail, so the method runs the bootstrap
#	again and writes the path again. Each clone step of the
#	bootstrap skips what exists, so the run repairs a bootstrap
#	that stopped early.
#
#	A path that is no worktree of the name is debris from a killed
#	create, and only remove clears it. The cleanup of _create must
#	not run here, because the worktree belongs to the create before
#	this one.
sub _again ( $app, $root, $name, $wt )
{
	my $log = $app->cli->log;
	my $branch =
	      _known($wt)
	    ? _capture( $app, 'git', '-C', $wt, 'branch', '--show-current' )
	    : undef;
	unless ( defined $branch && $branch eq $name ) {
		$log->error( 'already exists, not a worktree of %s: %s',
			$name, $wt );
		$log->error( 'remove it with: %s worktree remove %s',
			$app->cli->name, $name );
		return EXIT_ERROR;
	}

	unless ( _bootstrap( $app, $root, $wt ) ) {
		$log->error( 'the bootstrap of %s failed: %s',
			$wt, $app->error );
		return EXIT_ERROR;
	}

	say $wt;

	return EXIT_SUCCESS;
}

# _outside($app, $base, $name, $wt):
#	True when no existing worktree holds the new one
#	(WT-CREATE-2). The removal of an outer worktree destroys an
#	inner one, and it reports nothing. An empty parent directory
#	of a sibling holds no .git, so two worktrees under one plain
#	parent are permitted.
sub _outside ( $app, $base, $name, $wt )
{
	my $dir = dirname($wt);
	while ( length($dir) > length($base) ) {
		if ( -e "$dir/.git" ) {
			$app->cli->log->error(
				'%s nests inside the worktree %s',
				$name, $dir );
			return 0;
		}
		$dir = dirname($dir);
	}

	return 1;
}

# _bootstrap($app, $root, $wt):
#	Run the bootstrap target of the worktree (WT-CREATE-4). The
#	target belongs to the repository, and it names the paths to
#	clone. A worktree with no makefile needs no bootstrap.
sub _bootstrap ( $app, $root, $wt )
{
	return 1 unless grep { -f "$wt/$_" } MAKEFILES;

	return
	    defined $app->command(
		[ 'make', '-C', $wt, 'bootstrap', "MAIN=$root" ],
		group => 1 );
}

# _cleanup($app, $root, $base, $name, $wt):
#	Remove all that create made (WT-CREATE-6). Every step runs,
#	also after a step that fails: the worktree removal, the
#	directory removal, the branch deletion, the prune of the git
#	records, and the prune of each empty parent.
sub _cleanup ( $app, $root, $base, $name, $wt )
{
	$app->command( [
			'git',    '-C',      $root,     'worktree',
			'remove', '--force', '--force', $wt
		] ) if -d $wt;

	if ( -d $wt ) {
		File::Path::remove_tree( $wt, { error => \my $failed } );
		$app->cli->log->error( 'cannot remove %s', $wt )
		    if @{ $failed // [] };
	}

	_delete_branch( $app, $root, $name );
	$app->command( [ 'git', '-C', $root, 'worktree', 'prune' ] );
	_prune_parents( $base, $wt );

	return;
}

# _remove($app, @argv):
#	Remove one worktree of the checkout, and delete its branch
#	(WT-REMOVE-1). Only an operator runs it, and no hook calls it.
#
#	Without --force the subcommand refuses a worktree that holds
#	work at risk, and it reports each cause (WT-REMOVE-2).
#
#	The path resolves first, and the resolved path must sit under
#	the base (WT-REMOVE-6). A symbolic link in the base must not
#	permit a removal outside the base.
sub _remove ( $app, @argv )
{
	return $app->cli->command_usage_error('worktree') if @argv != 1;
	my ($name) = @argv;

	my ( $code, $root, $base ) = _setup($app);
	return $code if $code != EXIT_SUCCESS;

	my $log = $app->cli->log;
	unless ( $name =~ $NAME && $name !~ m{[.][.]} ) {
		$log->error( 'invalid worktree name: %s', $name );
		return EXIT_ERROR;
	}

	my $wt = File::Spec->catdir( $base, $name );

	# A parallel remove can take the directory between the test and
	# the resolution, and abs_path then gives undef. Both results
	# reach the branch below, which is no error (WT-REMOVE-6).
	my $resolved = -d $wt ? Cwd::abs_path($wt) : undef;
	unless ( defined $resolved ) {

		# The worktree is gone, or a user removed it by hand.
		# The prune and the branch deletion free the name again
		# (WT-REMOVE-4).
		$app->command( [ 'git', '-C', $root, 'worktree', 'prune' ] );
		my $deleted = _delete_branch( $app, $root, $name );
		_prune_parents( $base, $wt );

		return $deleted ? EXIT_SUCCESS : EXIT_ERROR;
	}

	unless ( rindex( $resolved, "$base/", 0 ) == 0 ) {
		$log->error( 'refusing to remove %s: it resolves outside %s',
			$name, $base );
		return EXIT_ERROR;
	}

	# The guard of D-06: the work inside the worktree must survive.
	# Debris from a killed create is no checkout, so the walk reads
	# no state of it. A clone below it is a repository of its own,
	# and the walk reads that one.
	unless ( $app->cli->option('force') ) {
		my @risk = _risks( $app, $resolved, _nested( $root, $base ) );
		if (@risk) {
			$log->error( '%s', $_ ) for @risk;
			$log->error(
				'refusing to remove %s: it holds work at '
				    . 'risk; --force overrides',
				$name
			);
			return EXIT_ERROR;
		}
	}

	# The branch that the worktree has checked out. git knows no
	# debris of a killed create, so it reads the branch of the
	# checkout above it. The name that create gives the branch is
	# the right one there.
	my $branch =
	    _known($resolved)
	    ? _capture( $app, 'git', '-C', $resolved, 'branch',
		'--show-current' )
	    : undef;
	$branch = $name unless defined $branch && length $branch;

	return EXIT_ERROR unless _take( $app, $root, $resolved );

	my $deleted = _delete_branch( $app, $root, $branch );
	_prune_parents( $base, $wt );

	return $deleted ? EXIT_SUCCESS : EXIT_ERROR;
}

# _take($app, $root, $wt):
#	Take the directory of one worktree. The second --force takes a
#	locked worktree too (WT-REMOVE-4). A directory that git does
#	not know is debris inside the base, so the method takes the
#	directory itself. It returns 0 when the directory stays.
sub _take ( $app, $root, $wt )
{
	return 1
	    if defined $app->command( [
		    'git',    '-C',      $root,     'worktree',
		    'remove', '--force', '--force', $wt
	    ] );

	my $log = $app->cli->log;
	$log->error('git refused, deleting the directory');

	# The error key stops remove_tree from dying, and the directory
	# itself is the result: a parallel remove that takes it first is
	# no error (WT-REMOVE-6).
	File::Path::remove_tree( $wt, { error => \my $failed } );
	$app->command( [ 'git', '-C', $root, 'worktree', 'prune' ] );
	return 1 unless -d $wt;

	$log->error( 'cannot remove %s', $wt );

	return 0;
}

# _list($app, @argv):
#	Report each worktree of the base with its name, its age in
#	days, and its state (WT-LIST-1). An operator reads the state
#	to see which worktree is safe to remove, because no hook
#	removes one.
sub _list ( $app, @argv )
{
	return $app->cli->command_usage_error('worktree') if @argv;

	my ( $code, $root, $base ) = _setup($app);
	return $code if $code != EXIT_SUCCESS;

	my $out = $app->command(
		[ 'git', '-C', $root, 'worktree', 'list', '--porcelain' ] );
	unless ( defined $out ) {
		$app->cli->log->error( 'cannot list the worktrees: %s',
			$app->error );
		return EXIT_ERROR;
	}

	my @paths;
	for my $line ( split /\n/, $out ) {
		next unless $line =~ /\Aworktree (.+)\z/;
		my $path = $1;
		push @paths, $path if rindex( $path, "$base/", 0 ) == 0;
	}
	unless (@paths) {
		say 'no worktrees';
		return EXIT_SUCCESS;
	}

	my $nested = _nested( $root, $base );
	for my $path ( sort @paths ) {

		# The gitfile records the creation, and later work
		# leaves it alone, so its mtime is the age.
		my @stat  = stat "$path/.git";
		my $age   = @stat ? int( ( time - $stat[9] ) / 86_400 ) : -1;
		my @risk  = _risks( $app, $path, $nested );
		my $state = @risk ? join( '; ', @risk ) : 'clean';
		say sprintf LINE, substr( $path, length($base) + 1 ),
		    $age < 0 ? '?' : $age, $state;
	}

	return EXIT_SUCCESS;
}

# _risks($app, $wt, $nested):
#	Each reason why one worktree holds work at risk
#	(WT-REMOVE-2). An empty list names a worktree that is safe to
#	remove. Each string names one repository and one cause.
sub _risks ( $app, $wt, $nested )
{
	my @risk;
	for my $repo ( _repos_in( $wt, $nested ) ) {
		my $rel = $repo eq $wt ? '.' : substr( $repo, length($wt) + 1 );

		my $dirty = _capture( $app, 'git', '-C', $repo, 'status',
			'--porcelain' );
		push @risk, "$rel: uncommitted change"
		    if defined $dirty && length $dirty;

		# Without a remote, a commit that the main branch
		# holds is safe: the merge to main is where the work
		# lands.
		#
		# A linked worktree shares one ref store with its main
		# checkout, so --branches counts the branch of every
		# other worktree too. Its own HEAD is the one ref that
		# it owns. A nested clone is a repository of its own,
		# so --branches is right for it.
		my $linked  = -f "$repo/.git";
		my $remotes = _capture( $app, 'git', '-C', $repo, 'remote' );
		my @not     = ('--remotes');
		push @not, 'main'
		    if !( defined $remotes && length $remotes )
		    && _branch_exists( $app, $repo, 'main' );

		my $count =
		    _capture( $app, 'git', '-C', $repo, 'rev-list', '--count',
			$linked ? 'HEAD' : '--branches',
			'--not', @not );
		push @risk, "$rel: $count commit(s) that no remote holds"
		    if defined $count && $count =~ /\A\d+\z/ && $count > 0;
	}

	return @risk;
}

# _repos_in($wt, $nested):
#	Each git repository in one worktree: the worktree itself, and
#	each repository below it, such as a clone under Projects/ or
#	the library at Wiki/ (WT-REMOVE-3). The walk stops at each
#	repository that it finds, because the content of a clone is
#	the business of that clone. It skips scratch/ and a nested
#	worktree directory, which hold no session work.
#
#	Debris from a killed create is no repository, so the list
#	holds it only when git knows it. A clone that a partial
#	bootstrap left inside it is a repository, and the walk finds
#	that one.
sub _repos_in ( $wt, $nested )
{
	my @repos = _known($wt) ? ($wt) : ();
	File::Find::find( {
			no_chdir   => 1,
			preprocess => sub {
				my @kept = sort
				    grep { $_ ne '.git' && $_ ne 'scratch' } @_;

				return @kept;
			},
			wanted => sub {
				my $name = $File::Find::name;
				return if $name eq $wt;
				return unless -d $name && !-l $name;
				if ( $name =~ $nested ) {
					$File::Find::prune = 1;
					return;
				}
				return unless _known($name);
				push @repos, $name;
				$File::Find::prune = 1;

				return;
			},
		},
		$wt
	);

	return @repos;
}

# _clone($app, @argv):
#	Copy the gitignored paths of the main checkout into the
#	current directory, with no network and no gh (WT-CLONE-1). A
#	bootstrap target of a worktree names the paths.
#
#	Each path passes the shape check before any work starts, so
#	one bad path stops the run and changes nothing (CLI-PROGRAM-6).
#	The subcommand writes inside the current directory only, and
#	in the main checkout itself it changes nothing (WT-CLONE-6).
sub _clone ( $app, @argv )
{
	return $app->cli->command_usage_error('worktree') unless @argv;

	my ( $code, $root, $base ) = _setup($app);
	return $code if $code != EXIT_SUCCESS;

	my $log = $app->cli->log;
	my @paths;
	for my $path (@argv) {
		$path =~ s{/+\z}{};
		unless ( _valid_path($path) ) {
			$log->error( 'invalid path: %s', $path );
			return EXIT_ERROR;
		}
		push @paths, $path;
	}

	my $here = Cwd::abs_path(q{.});
	if ( defined $here && $here eq $root ) {
		$log->notice('already the main checkout, nothing to do');
		return EXIT_SUCCESS;
	}

	my $nested = _nested( $root, $base );
	for my $path (@paths) {
		return EXIT_ERROR
		    unless _clone_path( $app, $root, $path, $nested );
	}

	return EXIT_SUCCESS;
}

# _valid_path($path):
#	True when one path of clone holds the shape of WT-CLONE-5: a
#	relative path, with no .. segment, and not the current
#	directory.
sub _valid_path ($path)
{
	return $path =~ $PATH && $path !~ m{[.][.]} && $path ne q{.};
}

# _clone_path($app, $root, $path, $nested):
#	Take one path of clone (WT-CLONE-2). A repository gives a
#	local clone, a directory gives one clone of each child, and a
#	plain file gives a copy. An absent path gives a message and no
#	failure, because a consumer names a path that its own tree can
#	omit (WT-CLONE-5). The method returns 0 after a failure.
sub _clone_path ( $app, $root, $path, $nested )
{
	my $log = $app->cli->log;
	my $src = File::Spec->catdir( $root, $path );

	return _clone_repo( $app, $src, $path, $nested )
	    if -d $src && -e "$src/.git";

	if ( -d $src ) {
		opendir my $dh, $src or do {
			$log->error( 'cannot read %s: %s', $src, $! );
			return 0;
		};
		my @names =
		    sort grep { !m{\A[.]} && -d "$src/$_" } readdir $dh;
		closedir $dh;

		for my $name (@names) {
			return 0
			    unless _clone_repo( $app, "$src/$name",
				"$path/$name", $nested );
		}

		return 1;
	}

	return _copy_file( $app, $src, $path ) if -f $src;

	unless ( -e $src ) {
		$log->notice( 'missing in main checkout, skipped: %s', $path );
		return 1;
	}

	$log->error( 'not a repository, directory or file: %s', $src );

	return 0;
}

# _clone_repo($app, $src, $dst, $nested):
#	Make one local clone of a repository of the main checkout, and
#	set its origin to the origin URL of the source (WT-CLONE-2). A
#	destination that exists stays as it is (WT-CLONE-4).
#
#	A project that no clone reaches gives an incomplete worktree,
#	and no message names it later. So a failure stops the run.
sub _clone_repo ( $app, $src, $dst, $nested )
{
	my $log = $app->cli->log;
	if ( -e $dst ) {
		$log->notice( 'already exists, skipped: %s', $dst );
		return 1;
	}

	unless ( -r $src && -x $src && -e "$src/.git" ) {
		$log->error( 'unreadable or not a git repository: %s', $src );
		return 0;
	}

	my $parent = dirname($dst);
	unless ( -d $parent ) {
		File::Path::make_path($parent);
		unless ( -d $parent ) {
			$log->error( 'cannot make the directory %s', $parent );
			return 0;
		}
	}

	unless (
		defined $app->command(
			[ 'git', 'clone', '--quiet', $src, $dst ] ) )
	{
		$log->error( 'cannot clone %s: %s', $src, $app->error );
		return 0;
	}

	# A source with no origin gives undef here, and the clone keeps
	# the source itself as its origin.
	my $origin =
	    _capture( $app, 'git', '-C', $src, 'remote', 'get-url', 'origin' );
	if ( defined $origin && length $origin ) {
		unless (
			defined $app->command( [
					'git',     '-C',
					$dst,      'remote',
					'set-url', 'origin',
					$origin
				] ) )
		{
			$log->error( 'cannot set the origin of %s: %s',
				$dst, $app->error );
			return 0;
		}
	}

	return _copy_env_tree( $app, $src, $dst, $nested );
}

# _copy_env_tree($app, $src, $dst, $nested):
#	Copy each regular .env file of one source tree, at any depth,
#	into the clone (WT-CLONE-3). The files are gitignored, so the
#	clone above holds none of them. The walk skips .git and a
#	nested worktree directory, and it copies no symbolic link: a
#	.env link is content of the repository, and it stays there.
sub _copy_env_tree ( $app, $src, $dst, $nested )
{
	my $ok = 1;
	File::Find::find( {
			no_chdir => 1,
			wanted   => sub {
				my $name = $File::Find::name;
				my $base = basename($name);
				my $skip = $base eq '.git'
				    || ( $name ne $src && $name =~ $nested );
				if ($skip) {
					$File::Find::prune = 1;
					return;
				}
				return unless $base eq '.env';
				return if -l $name || !-f $name;

				# A gitignored parent directory is absent
				# in the clone, so the copy makes it.
				my $rel    = substr $name, length($src) + 1;
				my $parent = dirname("$dst/$rel");
				File::Path::make_path($parent)
				    unless -d $parent;
				$ok = 0
				    unless _copy_file( $app, $name,
					"$dst/$rel" );

				return;
			},
		},
		$src
	);

	return $ok;
}

# _copy_file($app, $src, $dst):
#	Copy one file with the mode of the source. The method returns
#	0 after a failure.
sub _copy_file ( $app, $src, $dst )
{
	my $log = $app->cli->log;

	# A project can leave a symbolic link at the destination, and
	# the copy must not write through it. A regular file that
	# exists stays, so a second run keeps a local change
	# (WT-CLONE-4).
	unlink $dst if -l $dst;
	if ( -e $dst ) {
		$log->notice( 'already exists, skipped: %s', $dst );
		return 1;
	}

	# A .env file holds credentials, so the copy takes the mode of
	# the source and not the default of the umask. The stat runs
	# before the copy: a stat after it can follow a parallel
	# removal of the source, and the chmod then gives the copy the
	# mode 0.
	my @stat = stat $src;
	unless ( File::Copy::copy( $src, $dst ) ) {
		$log->error( 'cannot copy %s -> %s: %s', $src, $dst, $! );
		return 0;
	}
	if ( @stat && chmod( $stat[2] & 07777, $dst ) != 1 ) {
		$log->error( 'cannot set the mode of %s: %s', $dst, $! );

		# A copy of a credential file at the mode of the umask
		# is wider than the source, so it must not stay.
		unlink $dst
		    or $log->error( 'cannot remove %s: %s', $dst, $! );

		return 0;
	}
	$log->notice( 'copied %s -> %s', $src, $dst );

	return 1;
}

# _delete_branch($app, $root, $branch):
#	Delete one branch, and report nothing about a branch that is
#	gone. The method never deletes main, and never the branch that
#	the main checkout has checked out (WT-REMOVE-5). A parallel
#	remove that deletes the branch first is no error. The method
#	returns 0 when the branch stays.
sub _delete_branch ( $app, $root, $branch )
{
	return 1
	    unless defined $branch && length $branch && $branch ne 'main';

	my $head = _capture( $app, 'git', '-C', $root, 'symbolic-ref',
		'--quiet', '--short', 'HEAD' );
	return 1 if defined $head && $branch eq $head;
	return 1 unless _branch_exists( $app, $root, $branch );

	return 1
	    if defined $app->command(
		[ 'git', '-C', $root, 'branch', '-D', $branch ] );
	return 1 unless _branch_exists( $app, $root, $branch );

	$app->cli->log->error( 'cannot delete the branch %s', $branch );

	return 0;
}

# _branch_exists($app, $repo, $branch):
#	True when the repository holds the branch.
sub _branch_exists ( $app, $repo, $branch )
{
	return defined $app->command( [
		'git',      '-C',
		$repo,      'show-ref',
		'--verify', '--quiet',
		"refs/heads/$branch"
	] );
}

# _prune_parents($base, $wt):
#	Remove each empty parent directory of one worktree, up to the
#	base (WT-REMOVE-7). A name with a slash sits in a nested
#	directory, and the first parent that holds a file stops the
#	walk.
sub _prune_parents ( $base, $wt )
{
	my $dir = dirname($wt);
	while ( length($dir) > length($base)
		&& rindex( $dir, "$base/", 0 ) == 0 )
	{
		rmdir $dir or last;
		$dir = dirname($dir);
	}

	return;
}

# _capture($app, @cmd):
#	The standard output of one child, without the last newline,
#	or undef when the child fails.
sub _capture ( $app, @cmd )
{
	my $out = $app->command( \@cmd );
	return unless defined $out;
	chomp $out;

	return $out;
}

1;
