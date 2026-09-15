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

package App::FuguBench::Doctor;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use File::Spec ();
use JSON::PP   ();

use Fugu::CLI qw(EXIT_SUCCESS EXIT_ERROR);
use Fugu::Curl;
use Fugu::File;
use Fugu::Process;

use App::FuguBench::Hook;
use App::FuguBench::Version;
use App::FuguBench::Wiki;

# App::FuguBench::Doctor - the doctor verb.
#
# The verb reports the state of one checkout (CLI-DOCTOR-1): the
# version of the program, the tools on PATH, the hook entries of the
# settings file, and the library clone. Each check writes one line to
# standard output, and the verb returns 1 when it wrote a problem
# line, so a make target can gate on the report (CLI-DOCTOR-3).
#
# The verb reads the state, and --fix repairs one shape of it: the
# debris of the open race, a clone that sits in a stopped rebase over
# a session page with no observation (CLI-DOCTOR-2). Every other
# pending commit is a refusal, and the operator resolves that rebase.
#
# The report holds the facts of the other verbs. The version line
# comes from the version verb. The settings path, the keys of that
# file, the entries, and the worktree settings come from the hook
# verb, so this module holds no assumption of Claude Code (D-10). The
# shape of a session page and the body of one come from the wiki
# verb.
#
# The library directory is the one fact that this module reads for
# itself. It reads the two keys that the wiki verb reads
# (CLI-CONFIG-2), and a key that names no library gives one report
# line here. The wiki verb reports the reason on its own call.

# The tools of the report (CLI-DOCTOR-1). git drives every clone, and
# make drives every gate.
my @TOOLS = qw(git make);

# The encoder of the hook comparison. It sorts the keys, so two equal
# entries give two equal strings, and the comparison reads a nested
# entry without a walk of its own.
#
# It takes the bytes and it handles the UTF-8 itself, as the hook
# verb does. An :encoding layer loads the PerlIO::encoding extension,
# and the row of the verb gives no promise for the load of a shared
# object.
my $JSON = JSON::PP->new->utf8->canonical;

# App::FuguBench::Doctor->command($verb):
#	The entry of the Fugu::CLI table. The module holds one verb,
#	so it ignores the name.
sub command ( $, $ )
{
	return {
		summary => 'report the state of the checkout and its tools',
		usage   => '[--fix]',
		options => {
			fix => 'skip the pending commit of a stopped'
			    . ' rebase in the library',
		},
		run => sub ( $app, @argv ) { return _run( $app, @argv ) },
	};
}

# _run($app, @argv):
#	The body of the verb. It takes no argument, and every check
#	writes its line to standard output.
#
#	The verb reads the settings file and the library of one
#	checkout, so an absent .toolingrc stops it with a
#	configuration error (CLI-CHECKOUT-3).
sub _run ( $app, @argv )
{
	return $app->cli->command_usage_error('doctor') if @argv;

	my $checkout = $app->checkout;
	return Fugu::CLI::EXIT_CONFIG_ERROR() unless $checkout;

	my @lines = (
		_version(), _tools(),
		_hooks( $app, $checkout ),
		_library( $app, $checkout ) );
	say for @lines;

	my @problems = grep { index( $_, 'problem ' ) == 0 } @lines;

	return @problems ? EXIT_ERROR : EXIT_SUCCESS;
}

# _ok($check, $detail):
#	The line of a check that holds.
sub _ok ( $check, $detail )
{
	return "ok $check: $detail";
}

# _problem($check, $detail):
#	The line of a check that fails. One such line makes the exit
#	code of the verb 1 (CLI-DOCTOR-3).
sub _problem ( $check, $detail )
{
	return "problem $check: $detail";
}

# _version():
#	The version line of the program, as the version verb prints
#	it. The check never fails: the program answers, so it runs.
sub _version ()
{
	return _ok( 'version', App::FuguBench::Version->line );
}

# _tools():
#	One line for each tool of the report. The detail of a tool
#	that answers is its path, so the operator sees which copy of
#	it the program runs.
#
#	Fugu::Curl searches curl, then wget, then the ftp(1) of
#	OpenBSD, and it holds that order. So the downloader line names
#	the command that a download runs (CLI-FUGU-1), and this module
#	holds no second search list.
sub _tools ()
{
	my @lines;
	for my $name (@TOOLS) {
		my $path = Fugu::Process->find_command($name);
		push @lines, defined $path
		    ? _ok( $name, $path )
		    : _problem( $name, 'absent from PATH' );
	}

	my $downloader = Fugu::Curl->new->command;
	push @lines, defined $downloader
	    ? _ok( 'downloader', $downloader )
	    : _problem( 'downloader', 'no curl, wget, or ftp on PATH' );

	return @lines;
}

# _hooks($app, $checkout):
#	The lines of the hook entries of the settings file that the
#	hook verb names (CLI-DOCTOR-1). A checkout that holds no
#	event of the four gives one line, ok hooks: none. Most
#	checkouts install no hook, and that is no problem.
#
#	A checkout that holds one event of the four gives one line for
#	each of the four, so the report names an event that the file
#	lost.
#
#	A checkout that holds one event gives one worktree.baseRef
#	line too, because hook install writes that value beside the
#	entries (HOOK-INSTALL-4). A worktree key that holds no object
#	gives the problem line of that key in its place.
#
#	The file that no read reaches, the file that holds no JSON
#	object, and a container key that holds no object are problems,
#	because each one stops hook install. An absent file stops
#	nothing.
sub _hooks ( $app, $checkout )
{
	my $path = App::FuguBench::Hook->settings_path( $checkout->root );
	return _ok( 'hooks', 'none' ) unless -e $path;

	my $text = Fugu::File->read($path);
	return _problem( 'hooks', "cannot read $path" ) unless defined $text;

	my $settings = eval { $JSON->decode($text) };
	return _problem( 'hooks', "$path holds no JSON object" )
	    unless ref $settings eq 'HASH';

	my $key   = App::FuguBench::Hook->hooks_key;
	my $hooks = $settings->{$key} // {};
	return _problem( 'hooks', "$path: the $key key holds no object" )
	    unless ref $hooks eq 'HASH';

	my $entries = App::FuguBench::Hook->entries;
	my @named   = grep { exists $hooks->{$_} } keys %$entries;

	my @lines =
	    @named
	    ? map { _same( "hook $_", $hooks->{$_}, $entries->{$_} ) }
	    sort keys %$entries
	    : _ok( 'hooks', 'none' );

	return ( @lines, _worktree( $settings, $path, scalar @named ) );
}

# _same($check, $found, $want):
#	The line of one value of the settings file. The value of hook
#	install is the measure, so the report and the write never
#	disagree.
#
#	The encoder takes a reference, and a value of another kind is
#	no reference. So each value goes in a list of one, and every
#	kind compares.
sub _same ( $check, $found, $want )
{
	return _problem( $check, 'absent' ) unless defined $found;

	return $JSON->encode( [$found] ) eq $JSON->encode( [$want] )
	    ? _ok( $check, 'installed' )
	    : _problem( $check, 'differs from hook install' );
}

# _worktree($settings, $path, $installed):
#	The lines of the worktree settings of hook install
#	(HOOK-INSTALL-4). The subcommand writes them beside the
#	entries. Without the hooks, a worktree of the harness starts
#	at origin/main.
#
#	A value line follows an install alone, because a checkout that
#	installs no hook needs no value of that key. A key of another
#	kind is a problem without one: it stops the install, as a
#	container key of another kind does.
sub _worktree ( $settings, $path, $installed )
{
	my $key   = App::FuguBench::Hook->worktree_key;
	my $found = $settings->{$key};
	return _problem( $key, "$path: the $key key holds no object" )
	    if defined $found && ref $found ne 'HASH';
	return () unless $installed;

	my $want = App::FuguBench::Hook->worktree;

	return map {
		_same( "$key.$_", ref $found eq 'HASH' ? $found->{$_} : undef,
			$want->{$_} )
	} sort keys %$want;
}

# _library($app, $checkout):
#	The line of the library clone (CLI-DOCTOR-1). The clone
#	answers when it is clean, and the detail is then its path.
#
#	A stopped rebase comes first, because a clone in one holds a
#	conflicted file, and the change list would name that file and
#	hide the rebase.
sub _library ( $app, $checkout )
{
	my $dir = _dir($checkout);
	return _ok( 'library', 'absent' )
	    unless defined $dir && -d $dir && -e "$dir/.git";

	return _rebase( $app, $dir ) if _stopped( $app, $dir );

	my $status =
	    $app->command( [ 'git', 'status', '--porcelain' ], cwd => $dir );
	return _problem( 'library', 'cannot read the clone: ' . $app->error )
	    unless defined $status;

	my @changed = map { substr $_, 3 } split /\n/, $status;
	return _problem( 'library', 'changes ' . join( ', ', @changed ) )
	    if @changed;

	return _ok( 'library', $dir );
}

# _dir($checkout):
#	The library directory of the checkout, or undef. The home of
#	wiki.origin anchors the value of wiki.dir, as it anchors every
#	wiki. value (CLI-CONFIG-2), and the wiki verb reads the same
#	two keys.
#
#	The method gives undef for a checkout that names no library: a
#	checkout without wiki.origin, a wiki.dir that fails the shape
#	check, and a wiki.dir that resolves to the home itself
#	(CLI-CONFIG-3). The report then names an absent library, and
#	the wiki verb reports the reason on its own call.
sub _dir ($checkout)
{
	my ( $origin, $home ) = $checkout->config('wiki.origin');
	return unless defined $origin;

	my ($value) = $checkout->config('wiki.dir');
	my $name = $checkout->dir_value($value);
	return unless defined $name;

	my $dir = File::Spec->catdir( $home, $name );
	return if $dir eq $home;

	return $dir;
}

# _stopped($app, $dir):
#	True when the clone sits in a stopped rebase. git holds the
#	state of one in a directory of the git directory:
#	rebase-merge for the merge backend, and rebase-apply for the
#	apply backend.
#
#	REBASE_HEAD tells no stopped rebase. git writes that reference
#	when a rebase stops, and a rebase that runs to its end leaves
#	it behind. So the reference answers after the fix as it
#	answers before it.
sub _stopped ( $app, $dir )
{
	my $paths = $app->command( [
			'git',        'rev-parse',
			'--git-path', 'rebase-merge',
			'--git-path', 'rebase-apply'
		],
		cwd => $dir
	);
	return 0 unless defined $paths;

	for my $path ( split /\n/, $paths ) {

		# The directory goes in a variable first. On perl 5.34 a
		# file test reads the class name of a method call as a
		# bareword filehandle.
		my $state = File::Spec->rel2abs( $path, $dir );
		return 1 if -d $state;
	}

	return 0;
}

# _rebase($app, $dir):
#	The line of a clone that sits in a stopped rebase
#	(CLI-DOCTOR-2). Without --fix the report names the pending
#	commit and changes nothing.
#
#	With --fix the verb runs git rebase --skip for a pending
#	commit of the race shape, and it refuses every other one. The
#	refusal holds the reason, so the operator reads what the
#	commit carries before the manual repair.
#
#	The fix takes one pending commit. A rebase of several commits
#	stops again at the next one, and git exits 1 after that skip.
#	The line then names the skip and the new stop, and it is a
#	problem line: the clone needs the operator. The next run of
#	the verb reports the new pending commit.
#
#	A skip that leaves the same pending commit ran no skip, and
#	the line is the refusal with the reason of git.
sub _rebase ( $app, $dir )
{
	my ( $page, $reason ) = _shape( $app, $dir );

	unless ( $app->cli->option('fix') ) {
		return _problem( 'library',
			defined $page
			? "stopped rebase, the pending commit adds $page"
			: "stopped rebase, $reason" );
	}

	return _problem( 'library', "stopped rebase, fix refused: $reason" )
	    unless defined $page;

	my $before = _pending( $app, $dir );
	$app->command( [ 'git', 'rebase', '--skip' ], cwd => $dir );
	my $error = $app->error;
	return _ok( 'library', "skipped the pending commit $page" )
	    unless _stopped( $app, $dir );

	my $after = _pending( $app, $dir );
	return _problem( 'library',
		"skipped the pending commit $page, the rebase stopped again" )
	    if defined $after && ( !defined $before || $after ne $before );

	return _problem( 'library',
		'stopped rebase, fix refused: '
		    . ( $error // 'the pending commit stands' ) );
}

# _pending($app, $dir):
#	The commit that REBASE_HEAD names, or undef. git writes that
#	reference for the commit that a rebase stopped on. A skip that
#	stopped again writes the next commit there, and a skip that
#	ended the rebase leaves the reference on the commit it skipped.
#	So the caller reads this value while the rebase stands, and two
#	equal values then tell that no skip ran.
sub _pending ( $app, $dir )
{
	my $out =
	    $app->command( [ 'git', 'rev-parse', 'REBASE_HEAD' ], cwd => $dir );
	return unless defined $out;
	chomp $out;

	return $out;
}

# _shape($app, $dir):
#	The page of the race, and the reason of a refusal, in that
#	order. The page is defined for a pending commit of the shape
#	that --fix takes, and the reason is defined for every other
#	commit.
#
#	The shape has three parts (CLI-DOCTOR-2). The commit adds one
#	file, the file is a session page, and the page holds no
#	observation. Two sessions of one day take one page name, and
#	each one pushes a header alone. The commit that loses the race
#	carries no work, so the skip destroys nothing.
sub _shape ( $app, $dir )
{
	my $files = _files( $app, $dir );
	return ( undef, 'cannot read the pending commit: ' . $app->error )
	    unless $files;

	unless ( @$files == 1 && $files->[0][0] eq 'A' ) {
		my @paths = map { $_->[1] } @$files;
		my $list  = @paths ? join ', ', @paths : 'no file';
		return ( undef, "the pending commit changes $list" );
	}

	my $page = $files->[0][1];
	return ( undef, "$page is no session page" )
	    unless App::FuguBench::Wiki->session_page($page);

	my $text =
	    $app->command( [ 'git', 'show', "REBASE_HEAD:$page" ],
		cwd => $dir );
	return ( undef, "cannot read $page: " . $app->error )
	    unless defined $text;

	my $body = App::FuguBench::Wiki->observations($text);
	return ( undef, "$page holds no observation heading" )
	    unless defined $body;
	return ( undef, "$page holds an observation" ) if $body =~ /\S/;

	return $page;
}

# _files($app, $dir):
#	The status and the path of each file of the pending commit,
#	as a reference to a list of pairs. REBASE_HEAD names that
#	commit, and it resolves while the rebase stands.
#
#	A failed call gives undef, and the caller then reports the
#	reason of git. A commit that changes no file gives a list of
#	no pair, and the two states read apart.
#
#	A rename carries two paths in one line, and the split of two
#	fields keeps both. That status is no A, so the fix refuses the
#	commit either way.
sub _files ( $app, $dir )
{
	my $out = $app->command(
		[ 'git', 'show', '--name-status', '--format=', 'REBASE_HEAD' ],
		cwd => $dir
	);
	return unless defined $out;

	my @files;
	for my $line ( split /\n/, $out ) {
		my ( $status, $path ) = split /\t/, $line, 2;
		next unless defined $path;
		push @files, [ $status, $path ];
	}

	return \@files;
}

1;
