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

package App::FuguBench::Hook;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Cwd        ();
use File::Spec ();
use JSON::PP   ();

use Fugu::CLI qw(EXIT_SUCCESS EXIT_ERROR);
use Fugu::File;

use App::FuguBench::Checkout;
use App::FuguBench::Wiki;
use App::FuguBench::Worktree;

# App::FuguBench::Hook - the hook verb.
#
# The verb answers one hook event of Claude Code. The harness writes
# a JSON payload to standard input, and the verb reads that payload
# itself, so no hook command needs jq (D-07). The events are
# SessionStart, SessionEnd, WorktreeCreate, and WorktreeRemove. A
# word outside the four is a usage error (HOOK-EVENTS-1).
#
# This verb and the trace verb hold the Claude Code assumptions of
# the program, and every other verb is agent-agnostic (D-10). The
# payload shape lives here, and in no shared module. The settings
# path, the keys of that file, the entries, and the worktree settings
# live here too, and the doctor reads each one from this module.
#
# The payload comes first, and the checkout after. The verb builds
# the checkout from the payload cwd, and it sets that checkout on the
# dispatcher (HOOK-EVENTS-5). A session can start in a worktree, and
# a worktree is a checkout with its own library clone. The option -C
# names the root ahead of the payload (CLI-CHECKOUT-1).
#
# The verb runs the other verbs in process. It calls the body of the
# Fugu::CLI entry of a verb with the dispatcher and the arguments, as
# the dispatcher does, so no child perl runs and no option parses
# twice.
#
# A session event must never stop a session, so it maps every
# non-zero code to a warning and returns zero (HOOK-EVENTS-3).
# WorktreeCreate returns the code of worktree create, because the
# harness needs the path of the worktree.
#
# The install subcommand writes the entries of those four events into
# the settings file of the checkout (HOOK-INSTALL-1). It reads no
# payload, and it takes the checkout of the dispatcher.

# The events of the verb (HOOK-EVENTS-1). Each value holds the
# handler of the event and the timeout of its settings entry, in
# seconds (HOOK-INSTALL-3). One table holds the four events, so the
# dispatch and the installer can never name a different set.
my %EVENT = (
	SessionStart   => [ \&_session_start,   60 ],
	SessionEnd     => [ \&_session_end,     30 ],
	WorktreeCreate => [ \&_worktree_create, 120 ],
	WorktreeRemove => [ \&_worktree_remove, 60 ],
);

# The shape of a project name that comes from a path (WIKI-OPEN-5).
# The name reaches git as an argument of wiki open, and a name that
# starts with a dash reaches git as an option.
my $PROJECT = qr{\A[A-Za-z0-9][A-Za-z0-9._-]*\z};

# The command of each settings entry (HOOK-INSTALL-2). The harness
# expands CLAUDE_PROJECT_DIR, and the quotes hold a root that carries
# a space. The command names the shim and the event, and nothing
# else, so no entry needs jq (D-07).
my $SHIM = '"$CLAUDE_PROJECT_DIR/scripts/fugubench" hook ';

# The settings file of one checkout, under its root
# (HOOK-INSTALL-1), and the two keys of it that the install owns:
# hooks for the entries, and worktree for the base reference
# (HOOK-INSTALL-4). Claude Code names the path and the keys, so they
# live in this verb (D-10), and settings_path, hooks_key, and
# worktree_key give them to the doctor.
use constant SETTINGS_DIR  => '.claude';
use constant SETTINGS_FILE => 'settings.json';
use constant HOOKS_KEY     => 'hooks';
use constant WORKTREE_KEY  => 'worktree';

# The JSON of the verb: the decoder of one payload, and the decoder
# and the encoder of the settings file. It takes the bytes and it
# handles the UTF-8 itself. An :encoding layer loads the
# PerlIO::encoding extension at the first read, and no row of the
# sandbox gives a promise for the load of a shared object.
#
# The encoder sorts the keys, indents with two spaces, and writes one
# space after a colon and none in front of it. Sorted keys make the
# second install byte-equal to the first one, and prettier writes
# that same shape.
my $JSON =
    JSON::PP->new->utf8->canonical->indent->indent_length(2)->space_after;

# App::FuguBench::Hook->command($verb):
#	The entry of the Fugu::CLI table. The module holds one verb,
#	so it ignores the name.
sub command ( $, $ )
{
	return {
		summary => 'answer one Claude Code hook event',
		usage   => 'install | SessionStart | SessionEnd'
		    . ' | WorktreeCreate | WorktreeRemove',
		run => sub ( $app, @argv ) { return _run( $app, @argv ) },
	};
}

# _run($app, @argv):
#	The body of the verb. It reads one word as its first argument,
#	and it takes no other argument. The word install names the
#	subcommand, and every other word names an event.
#
#	The subcommand comes in front of the payload read, because it
#	answers no event and reads no standard input.
#
#	The two early exits answer every event with the code zero. A
#	payload that does not parse warns (HOOK-EVENTS-2), and a
#	payload of a sub-agent stops the verb with no change
#	(HOOK-EVENTS-4). An observer dispatches an operator for each
#	step and a verifier for each claim, so without that exit each
#	of them opens a page of its own.
sub _run ( $app, @argv )
{
	my $word = shift @argv;
	return $app->cli->command_usage_error('hook')
	    if !defined $word || @argv;

	return _install($app) if $word eq 'install';

	my $event = $EVENT{$word};
	return $app->cli->command_usage_error('hook') unless $event;

	my $payload = _payload($app);
	return EXIT_SUCCESS unless $payload;
	return EXIT_SUCCESS if defined $payload->{agent_id};

	return $event->[0]->( $app, $payload );
}

# _payload($app):
#	The payload of the event: the whole standard input, decoded as
#	JSON (HOOK-EVENTS-2). The method warns and returns undef when
#	the text is no JSON object.
sub _payload ($app)
{
	# The harness writes the payload to standard input, so the
	# verb reads that handle by name. <> and <ARGV> read the files
	# that @ARGV names, and @ARGV holds the verb and the event.
	my $raw = do {
		## no critic (InputOutput::ProhibitExplicitStdin)
		local $/ = undef;
		<STDIN>;
	};
	my $payload = eval { $JSON->decode( $raw // q{} ) };
	return $payload if ref $payload eq 'HASH';

	$app->cli->log->warning('the hook payload does not parse');

	return;
}

# _checkout($app, $cwd):
#	The checkout of the payload, set on the dispatcher
#	(HOOK-EVENTS-5). The method warns and returns undef when no
#	.toolingrc sits above the cwd.
#
#	The walk starts at the cwd, and it cuts no path at a marker,
#	so a session in a worktree reads the worktree
#	(CLI-CHECKOUT-4).
#
#	With -C the dispatcher owns the start, and the value names the
#	root ahead of the payload (CLI-CHECKOUT-1). The call of the
#	dispatcher reports a walk that finds nothing.
sub _checkout ( $app, $cwd )
{
	return $app->checkout if defined $app->cli->option('C');

	my $checkout = App::FuguBench::Checkout->new( start => $cwd );
	unless ($checkout) {
		$app->cli->log->warning( 'no .toolingrc above %s', $cwd );
		return;
	}

	return $app->checkout($checkout);
}

# _verb($app, $module, $verb, @args):
#	Run one verb of the program in process, and return its exit
#	code. The entry of the Fugu::CLI table holds the body, and the
#	dispatcher runs that same body.
#
#	The call takes the body, and not the wrapper of the
#	dispatcher, so no second sandbox entry runs. The row of the
#	hook verb pledges the promises of every verb that it calls.
sub _verb ( $app, $module, $verb, @args )
{
	return $module->command($verb)->{run}->( $app, @args );
}

# _quiet($app, $module, $verb, @args):
#	Run one verb with its standard output on standard error, and
#	return its exit code. A hook reads standard output, so the
#	result line of an event must reach it alone (CLI-PROGRAM-4).
#	The result of a call inside an event is no result of the
#	event.
#
#	The alias holds for the call, and local puts the glob back
#	after it. The verb writes its line to the selected handle, and
#	that handle is the STDOUT glob.
sub _quiet ( $app, $module, $verb, @args )
{
	local *STDOUT = *STDERR;

	return _verb( $app, $module, $verb, @args );
}

# _never_stop($app, $what, $code):
#	Map a non-zero code of one call to a warning, and return zero
#	(HOOK-EVENTS-3). A session event must never stop a session.
#	The verb of the call reported the reason already, so the
#	warning names the call alone.
sub _never_stop ( $app, $what, $code )
{
	$app->cli->log->warning( '%s exited %d', $what, $code )
	    if $code != EXIT_SUCCESS;

	return EXIT_SUCCESS;
}

# _session($app, $payload):
#	The cwd and the session identifier of a session event, in that
#	order. The method warns and returns the empty list when the
#	payload omits one of the two.
#
#	The identifier reaches git through wiki open, so the method
#	replaces each character outside a letter, a digit, a dot, a
#	dash, and an underscore with a dash (HOOK-SESSION-1).
sub _session ( $app, $payload )
{
	my $cwd     = $payload->{cwd};
	my $session = $payload->{session_id};
	unless ( defined $cwd && defined $session ) {
		$app->cli->log->warning(
			'the hook payload names no cwd or no session');
		return;
	}
	$session =~ s/[^A-Za-z0-9._-]/-/g;

	return ( $cwd, $session );
}

# _session_start($app, $payload):
#	Clone the library, and start the session page: wiki init
#	first, and then wiki open (HOOK-SESSION-1).
#
#	The page name of wiki open is the result of the event, and it
#	reaches standard output alone (CLI-PROGRAM-4). The harness
#	adds that line to the context of the session. init writes the
#	directory of a clone that it makes (WIKI-CLONE-1), so that
#	call runs with its standard output on standard error.
sub _session_start ( $app, $payload )
{
	my ( $cwd, $session ) = _session( $app, $payload );
	return EXIT_SUCCESS unless defined $session;

	my $checkout = _checkout( $app, $cwd );
	return EXIT_SUCCESS unless $checkout;

	_never_stop( $app, 'wiki init',
		_quiet( $app, 'App::FuguBench::Wiki', 'wiki', 'init' ) );

	return _never_stop(
		$app,
		'wiki open',
		_verb(
			$app, 'App::FuguBench::Wiki', 'wiki', 'open',
			_project( $app, $checkout, $cwd ), $session
		) );
}

# _session_end($app, $payload):
#	Close the session page (HOOK-SESSION-3). A session with no
#	page is normal, and wiki close reports it.
sub _session_end ( $app, $payload )
{
	my ( $cwd, $session ) = _session( $app, $payload );
	return EXIT_SUCCESS unless defined $session;

	return EXIT_SUCCESS unless _checkout( $app, $cwd );

	return _never_stop(
		$app,
		'wiki close',
		_verb(
			$app, 'App::FuguBench::Wiki', 'wiki', 'close', $session
		) );
}

# _project($app, $checkout, $cwd):
#	The project of the session (HOOK-SESSION-2): the child of the
#	projects directory that holds the cwd, and otherwise the
#	wiki.project value.
#
#	The home of wiki.origin anchors wiki.projects, as it anchors
#	every wiki. value (CLI-CONFIG-2). A checkout with no
#	wiki.origin holds no library, and the key has no home there,
#	so the root anchors the value.
#
#	The value must name a directory below that home
#	(CLI-CONFIG-3), and the child must hold the token shape of
#	wiki open. A value that fails the shape check warns, and the
#	method then gives the wiki.project value.
#
#	The method resolves both paths before the match, because one
#	of them can hold a symbolic link that the other one resolves.
sub _project ( $app, $checkout, $cwd )
{
	my ($project) = $checkout->config('wiki.project');
	my $home = ( $checkout->config('wiki.origin') )[1] // $checkout->root;

	my ($value) = $checkout->config('wiki.projects');
	my $dir = $checkout->dir_value($value);
	unless ( defined $dir ) {
		$app->cli->log->warning( 'wiki.projects: %s',
			$checkout->error );
		return $project;
	}

	my $under = Cwd::abs_path( File::Spec->catdir( $home, $dir ) );
	my $abs   = Cwd::abs_path($cwd);
	return $project unless defined $under && defined $abs;
	return $project unless index( $abs, "$under/" ) == 0;

	my ($child) = split m{/}, substr $abs, length "$under/";

	return defined $child && $child =~ $PROJECT ? $child : $project;
}

# _worktree_create($app, $payload):
#	Make the worktree of the payload, and return the code of
#	worktree create (HOOK-WORKTREE-1). That subcommand writes the
#	path of the worktree to standard output as the only line, and
#	the harness needs that path (WT-CREATE-5).
#
#	So this event returns the code 1 after a failure, where a
#	session event returns zero (HOOK-EVENTS-3). A payload that
#	names no worktree, and a cwd with no checkout above it, both
#	give that code and no path line.
#
#	Claude Code runs the create hook again when a session
#	reconnects, with the same name. The subcommand then bootstraps
#	the worktree again, writes the path again, and returns zero
#	(HOOK-WORKTREE-3, WT-CREATE-7).
sub _worktree_create ( $app, $payload )
{
	my $log  = $app->cli->log;
	my $name = $payload->{name};
	unless ( defined $name ) {
		$log->error('the hook payload names no worktree');
		return EXIT_ERROR;
	}

	my $cwd = $payload->{cwd};
	unless ( defined $cwd ) {
		$log->error('the hook payload names no cwd');
		return EXIT_ERROR;
	}
	return EXIT_ERROR unless _checkout( $app, $cwd );

	return _verb( $app, 'App::FuguBench::Worktree', 'worktree', 'create',
		$name );
}

# _worktree_remove($app, $payload):
#	Keep the worktree, print the manual command, and return zero
#	(HOOK-WORKTREE-2). The event removes nothing (D-06), and it
#	exits zero always (HOOK-EVENTS-3).
#
#	Both lines go to standard error, because the event has no
#	result (CLI-PROGRAM-4).
sub _worktree_remove ( $app, $payload )
{
	my $log  = $app->cli->log;
	my $path = $payload->{worktree_path};
	unless ( defined $path ) {
		$log->warning('the hook payload names no worktree path');
		return EXIT_SUCCESS;
	}

	$log->notice( 'worktree kept: %s', $path );

	# The value goes in a variable first. A call in the argument
	# list runs in list context, and a base that is absent then
	# gives the empty list in place of one argument.
	my $base = _base( $app, $payload );
	my ( $root, $name ) = _split( $path, $base );
	$log->notice( 'to remove it: make -C %s worktree-remove NAME=%s',
		$root, $name )
	    if defined $name;

	return EXIT_SUCCESS;
}

# _base($app, $payload):
#	The worktree.base value of the checkout of the payload, or
#	undef. That value names the segment that splits the worktree
#	path.
#
#	A payload with no cwd, a cwd with no checkout above it, and a
#	value that fails the shape check all give undef. The event
#	then prints the path alone, and it prints no command with a
#	root that it guessed.
sub _base ( $app, $payload )
{
	my $cwd = $payload->{cwd};
	return unless defined $cwd;

	my $checkout = _checkout( $app, $cwd );
	return unless $checkout;

	my ($value) = $checkout->config('worktree.base');
	my $base = $checkout->dir_value($value);
	$app->cli->log->warning( 'worktree.base: %s', $checkout->error )
	    unless defined $base;

	return $base;
}

# _split($path, $base):
#	The root and the name of one worktree path, in that order. The
#	method splits the path at its last <base> segment: the part in
#	front is the root, and the part after is the name. It returns
#	the empty list without a base, without such a segment, and
#	when no name follows the segment.
#
#	The split serves the hint alone, and it finds no checkout, so
#	CLI-CHECKOUT-4 holds.
sub _split ( $path, $base )
{
	return unless defined $base;

	my $marker = "/$base/";
	my $at     = rindex $path, $marker;
	return if $at < 0;

	my $name = substr $path, $at + length $marker;
	return unless length $name;

	return ( substr( $path, 0, $at ), $name );
}

# App::FuguBench::Hook->entries:
#	The settings entries of the four events, as a reference to a
#	hash of the event names. Each value is one list with one
#	matcher-less group, and the group holds one entry.
#
#	An entry holds three keys: the type, the command, and the
#	timeout of the event (HOOK-INSTALL-3). It carries no
#	statusMessage, because the harness names the event itself.
#
#	The doctor reads the same hash, so the report of an entry and
#	the write of an entry never disagree.
sub entries ($)
{
	my %entries;
	for my $event ( keys %EVENT ) {
		my $entry = {
			type    => 'command',
			command => $SHIM . $event,
			timeout => $EVENT{$event}[1],
		};
		$entries{$event} = [ { hooks => [$entry] } ];
	}

	return \%entries;
}

# App::FuguBench::Hook->worktree:
#	The worktree settings of the install, as a reference to a hash
#	(HOOK-INSTALL-4). baseRef takes the value head, because a
#	worktree starts at the local HEAD. Without the hooks, the
#	built-in creation branches from origin/main and skips the
#	bootstrap.
#
#	The doctor reads the same hash, so the report of a value and
#	the write of a value never disagree.
sub worktree ($)
{
	return { baseRef => 'head' };
}

# App::FuguBench::Hook->settings_path($root):
#	The settings file of one checkout root (HOOK-INSTALL-1).
#	Claude Code reads that path, so this verb holds it (D-10), and
#	the doctor reads the file here.
sub settings_path ( $, $root )
{
	return File::Spec->catfile( $root, SETTINGS_DIR, SETTINGS_FILE );
}

# App::FuguBench::Hook->hooks_key:
#	The key of the settings file that holds the entries of the
#	events (HOOK-INSTALL-1).
sub hooks_key ($)
{
	return HOOKS_KEY;
}

# App::FuguBench::Hook->worktree_key:
#	The key of the settings file that holds the worktree settings
#	(HOOK-INSTALL-4).
sub worktree_key ($)
{
	return WORKTREE_KEY;
}

# _install($app):
#	Write the four entries and the base reference into
#	.claude/settings.json of the checkout, and return the exit
#	code (HOOK-INSTALL-1).
#
#	The subcommand reads no payload, so it takes the checkout of
#	the dispatcher. An operator runs it by hand, and -C names the
#	root (CLI-CHECKOUT-1).
#
#	The method keeps every key that it does not own, at the top
#	level and under hooks. It replaces the list of each event of
#	%EVENT, and it leaves every other event as it is, so the
#	settings of the operator survive the write.
#
#	The worktree method holds the value of baseRef, and the write
#	takes it from there (HOOK-INSTALL-4). It keeps every other key
#	of that object, as it keeps every other event.
#
#	The keys reach the file in sorted order, so a second run writes
#	the same bytes and causes no change (HOOK-INSTALL-1).
sub _install ($app)
{
	my $checkout = $app->checkout;
	return Fugu::CLI::EXIT_CONFIG_ERROR() unless $checkout;

	my $dir  = File::Spec->catdir( $checkout->root, SETTINGS_DIR );
	my $path = __PACKAGE__->settings_path( $checkout->root );

	my $settings = _settings( $app, $path );
	return EXIT_ERROR unless $settings;

	my $hooks = _object( $app, $settings, HOOKS_KEY, $path );
	return EXIT_ERROR unless $hooks;

	my $entries = __PACKAGE__->entries;
	$hooks->{$_} = $entries->{$_} for keys %$entries;

	my $worktree = _object( $app, $settings, WORKTREE_KEY, $path );
	return EXIT_ERROR unless $worktree;

	my $want = __PACKAGE__->worktree;
	$worktree->{$_} = $want->{$_} for keys %$want;

	return EXIT_ERROR unless Fugu::File->ensure_dir($dir);

	# The encoder ends the text with a newline of its own, after
	# the last brace.
	return EXIT_ERROR
	    unless Fugu::File->write_atomic( $path, $JSON->encode($settings) );

	return EXIT_SUCCESS;
}

# _settings($app, $path):
#	The settings of one file, as a hash reference. An absent file
#	gives an empty hash, and the subcommand then writes a new file.
#
#	The method reports and returns undef when the file does not
#	read, and when it holds no JSON object. An empty file holds
#	none, and so does a file that lost a brace. The subcommand then
#	writes nothing, and the operator repairs the file.
sub _settings ( $app, $path )
{
	return {} unless -e $path;

	my $text = Fugu::File->read($path);
	unless ( defined $text ) {
		$app->cli->log->error( 'cannot read %s', $path );
		return;
	}

	my $settings = eval { $JSON->decode($text) };
	return $settings if ref $settings eq 'HASH';

	$app->cli->log->error( '%s holds no JSON object', $path );

	return;
}

# _object($app, $settings, $key, $path):
#	The object under one key of the settings. The method makes an
#	empty object when the file omits the key, and it reports and
#	returns undef when the key holds another kind of value.
#
#	A hooks key of another kind belongs to no settings file that
#	this subcommand can extend. The write then stops, and it
#	destroys no file of the operator.
sub _object ( $app, $settings, $key, $path )
{
	my $value = $settings->{$key} //= {};
	return $value if ref $value eq 'HASH';

	$app->cli->log->error( '%s: the %s key holds no object', $path, $key );

	return;
}

1;
