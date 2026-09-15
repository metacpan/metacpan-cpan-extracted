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

package App::FuguBench;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Cwd          ();
use File::Temp   ();
use Getopt::Long ();

use Fugu::CLI;
use Fugu::File;
use Fugu::Process;
use Fugu::Sandbox;

use App::FuguBench::Checkout;
use App::FuguBench::Deps;
use App::FuguBench::Dist;
use App::FuguBench::Doctor;
use App::FuguBench::Fetch;
use App::FuguBench::Hook;
use App::FuguBench::Traces;
use App::FuguBench::Update;
use App::FuguBench::Version;
use App::FuguBench::Wiki;
use App::FuguBench::Worktree;

# App::FuguBench - the dispatcher of the fugubench program.
#
# Every verb shares one dispatcher, one checkout discovery, one
# sandbox entry, and one channel discipline. Fugu::CLI parses the
# global options, finds the verb, parses the options of the verb, and
# calls it. Its exit codes are the codes of the program.
#
# Standard output carries the result line of a verb, and nothing
# else. Every diagnostic goes to the logger, which writes to standard
# error, because a hook reads standard output.
#
# The namespace is an application, not a library. It uses Fugu:: and
# core Perl, and it never uses another App:: namespace.

# The verb table. Each entry names a verb and the module that holds
# it. The module returns the entry of the Fugu::CLI table from its
# command class method.
my @VERBS = (
	[ 'doctor',   'App::FuguBench::Doctor' ],
	[ 'hook',     'App::FuguBench::Hook' ],
	[ 'traces',   'App::FuguBench::Traces' ],
	[ 'version',  'App::FuguBench::Version' ],
	[ 'wiki',     'App::FuguBench::Wiki' ],
	[ 'worktree', 'App::FuguBench::Worktree' ],
	[ 'deps',     'App::FuguBench::Deps' ],
	[ 'fetch',    'App::FuguBench::Fetch' ],
	[ 'shim',     'App::FuguBench::Dist' ],
	[ 'install',  'App::FuguBench::Dist' ],
	[ 'update',   'App::FuguBench::Update' ],
);

# The sandbox row of each verb (CLI-SANDBOX). A row names the pledge
# promises of the verb, and the unveil paths of a verb that opens a
# file of its own. A row that names subcommands gives one promise set
# to each named subcommand, and the promises of the row to every
# other one.
#
# `version` opens no file, so its row holds `stdio` alone, and
# `stdio` denies open(2).
#
# `wiki` and `worktree` run git, and no row can name each file that
# git opens. So each row unveils nothing (CLI-SANDBOX-2). git pushes,
# so the row of `wiki` adds the network promises. The `list`
# subcommand of `worktree` writes no file, so it drops the write
# promises.
#
# `traces` opens its files itself and runs no child, so its row
# unveils. The list comes from the verb, because a path of it comes
# from an option and a path of it comes from the checkout.
#
# `shim` and `install` open a file of their own and run no child, so
# each row unveils as well. They are the two other verbs that unveil
# (CLI-SANDBOX-2). `shim` reads the running file, and `install`
# reads it and writes the copy, so each list comes from the verb
# too.
#
# `hook` runs the other verbs in its own process, so its row pledges
# the promises of `wiki` and of `worktree` together. Those verbs run
# git, so the row unveils nothing. The `install` subcommand writes one
# file of its own, and the write promises of the row cover that write.
# The row names no unveil list, so no walk runs in front of the verb.
#
# `doctor` runs git for the library check and for the fix, so its row
# unveils nothing too. It reads the settings file itself, and rpath
# covers that read. It writes no file of its own: git writes every
# byte of the fix.
#
# The install of `deps` runs a package manager, cpanm, and the
# commands of an archive, and each one writes outside every path of a
# row. So the row unveils nothing either. The file promises cover the
# manifest read and the digest file, `proc exec` covers each child,
# and `inet dns` covers each download.
#
# `fetch` runs the downloader of Fugu::Curl as a child, which writes
# its file beside the destination and renames it. So the row holds
# the promises of `deps`, and it unveils nothing.
#
# `update` runs that downloader as well, so its row unveils nothing
# too. It replaces the running file where that file sits, so no path
# list bounds the write. The file promises serve the replace, `fattr`
# serves the mode of the new program, and `inet dns` serves each
# download.
my %SANDBOX = (
	doctor => { promises => 'stdio rpath proc exec' },
	hook   => {
		promises => 'stdio rpath wpath cpath fattr proc exec inet dns'
	},
	traces => {
		promises => 'stdio rpath',
		unveil   => sub ($app) {
			return App::FuguBench::Traces->unveil_paths($app);
		},
	},
	version => { promises => 'stdio' },
	wiki    => {
		promises => 'stdio rpath wpath cpath fattr proc exec inet dns'
	},
	worktree => {
		promises    => 'stdio rpath wpath cpath fattr proc exec',
		subcommands => { list => 'stdio rpath proc exec' },
	},
	deps  => { promises => 'stdio rpath wpath cpath proc exec inet dns' },
	fetch => { promises => 'stdio rpath wpath cpath proc exec inet dns' },
	shim  => {
		promises => 'stdio rpath',
		unveil   => sub ($app) {
			return App::FuguBench::Dist->shim_paths($app);
		},
	},
	install => {
		promises => 'stdio rpath wpath cpath fattr',
		unveil   => sub ($app) {
			return App::FuguBench::Dist->install_paths($app);
		},
	},
	update => {
		promises => 'stdio rpath wpath cpath fattr proc exec inet dns'
	},
);

# The global options, in the form of Fugu::CLI. new gives the table
# to the dispatcher, and run reads the same table to find the verb.
my %OPTIONS = (
	'C=s'     => 'the directory that a verb reads as its checkout root',
	'verbose' => 'trace each command on standard error',
);

# App::FuguBench->new:
#	Build the dispatcher over Fugu::CLI. The global options are
#	-C <dir> and --verbose.
sub new ($class)
{
	my $self = bless {
		cli      => undef,
		checkout => undef,
		walked   => 0,
		missing  => undef,
		quiet    => 0,
		child    => undef,
		error    => undef,
	}, $class;

	$self->{cli} = Fugu::CLI->new(
		name  => 'fugubench',
		usage => '[-C <dir>] [--verbose] <verb> [options] [arguments]',
		options  => \%OPTIONS,
		commands => $self->_commands,
	);

	return $self;
}

# $self->_commands:
#	The Fugu::CLI command table. Each entry comes from the verb
#	module, and the wrapper enters the sandbox row of the verb
#	before the body runs.
sub _commands ($self)
{
	my %table;
	for my $verb (@VERBS) {
		my ( $name, $module ) = @$verb;
		die "$name has no sandbox row" unless $SANDBOX{$name};

		my $entry = $module->command($name);
		my $body  = $entry->{run};
		$entry->{run} = sub ( $, @argv ) {
			$self->_sandbox( $name, $argv[0] );
			return $body->( $self, @argv );
		};
		$table{$name} = $entry;
	}

	return \%table;
}

# $self->_sandbox($verb, $subcommand):
#	Enter the sandbox row of one verb. The method unveils the
#	paths of the row, and it pledges the promises of the row, or
#	the promises that the row gives to the subcommand. On a
#	platform other than OpenBSD the calls change nothing.
#
#	The unveil comes in front of the pledge. unveil(2) needs the
#	`unveil` promise, no row of the table holds that promise, and
#	a pledge in front of the call would stop the program. A row
#	with no list unveils nothing, and the whole filesystem stays
#	in view.
#
#	The row resolves here, after the option parse and before the
#	verb, so a path of a row can come from an option.
#
#	The unveil list of a row can name the checkout root, so the
#	row walks to that root here. The walk reports nothing, and
#	the verb reports a failed walk on its own call. A verb that
#	rejects its argument list then reports the usage, and no
#	configuration error (CLI-CHECKOUT-3).
sub _sandbox ( $self, $verb, $subcommand = undef )
{
	my $row      = $SANDBOX{$verb};
	my $named    = $row->{subcommands} // {};
	my $promises = $row->{promises};
	$promises = $named->{$subcommand}
	    if defined $subcommand && defined $named->{$subcommand};

	if ( $row->{unveil} ) {
		$self->{quiet} = 1;
		Fugu::Sandbox->unveil( paths => [ $row->{unveil}->($self) ] );
		$self->{quiet} = 0;
	}

	Fugu::Sandbox->pledge( promises => $promises );

	return $self;
}

# $self->run(@argv):
#	Parse, enter the sandbox, dispatch, and return the exit code.
#
#	A command line with no verb is a usage error, and a global
#	option in front of it changes nothing. Fugu::CLI prints the
#	help for such a line and returns success, and CLI-PROGRAM-3
#	wants the usage on standard error with exit 2. So the method
#	looks for the verb first, on a copy of the arguments and with
#	the parse rules of Fugu::CLI.
#
#	The copy declares the global options alone. It passes an
#	unknown option, a missing option value, and a request for the
#	help through, so each one stays in the array and the guard
#	passes. Fugu::CLI meets them again, and it answers or reports
#	each one once.
sub run ( $self, @argv )
{
	my @rest   = @argv;
	my $parser = Getopt::Long::Parser->new;
	$parser->configure(
		qw(require_order bundling no_ignore_case pass_through));

	my %values;
	$parser->getoptionsfromarray( \@rest, \%values, keys %OPTIONS );

	# The parse passes `--` through. It ends the options, and it
	# is no verb and no request for the help.
	shift @rest if @rest && $rest[0] eq q{--};

	return $self->{cli}->usage_error unless @rest;

	return $self->{cli}->run(@argv);
}

# $self->cli:
#	The Fugu::CLI dispatcher. A verb body reads its options
#	through $app->cli->option and reports through
#	$app->cli->log.
sub cli ($self)
{
	return $self->{cli};
}

# $self->error:
#	The reason of the last failure of command(), or undef.
sub error ($self)
{
	return $self->{error};
}

# $self->child:
#	The pid of the running child of the group form of command(),
#	or undef. A signal handler reads it to stop the group before
#	it starts its cleanup.
sub child ($self)
{
	return $self->{child};
}

# $self->start:
#	The start directory of the run: the -C value, or the current
#	directory. A verb that reads a path relative to the start, and
#	that walks up to no checkout, reads it here (CLI-CHECKOUT-5).
#	`deps` is that verb, and a guest runs it out of an extracted
#	tarball that holds no .toolingrc.
sub start ($self)
{
	return $self->{cli}->option('C') // Cwd::getcwd();
}

# $self->checkout($checkout):
#	The checkout of the run. Without an argument the walk runs on
#	the first call, from the start directory of start(). A verb
#	that reads no checkout never starts it, so the program runs in
#	a home with no .toolingrc.
#
#	The method returns undef when no .toolingrc sits above the
#	start. The call of the verb names the start directory in the
#	log, and the verb then returns EXIT_CONFIG_ERROR.
#
#	The walk runs one time, and a failed walk stays failed. A
#	sandbox row reads the checkout before the verb does, and that
#	row reports nothing. So the report waits for the call of the
#	verb, and it comes one time.
#
#	With an argument the method sets the checkout, for a verb that
#	reads its start from a payload. The argument drops the report
#	of a failed walk, so no later call writes it.
sub checkout ( $self, $checkout = undef )
{
	if ( defined $checkout ) {
		$self->{checkout} = $checkout;
		$self->{walked}   = 1;
		delete $self->{missing};
		return $checkout;
	}

	unless ( $self->{walked} ) {
		$self->{walked} = 1;

		my $start = $self->start;
		$self->{checkout} =
		    App::FuguBench::Checkout->new( start => $start );
		$self->{missing} = $start
		    unless defined $self->{checkout};
	}

	if ( defined $self->{missing} && !$self->{quiet} ) {
		$self->{cli}->log->error( 'no .toolingrc above %s',
			delete $self->{missing} );
	}

	return $self->{checkout};
}

# $self->command(\@cmd, %args):
#	Run one child command through Fugu::Process->run, as an
#	argument list and never through a shell. The remaining
#	arguments reach Fugu::Process->run, so a caller of the plain
#	form names cwd, stdin, env or timeout there. The group form
#	takes another set, and _group names it.
#
#	The method writes the command line to standard error under
#	--verbose, before the child runs. It writes the captured
#	standard error of the child to standard error, in full.
#
#	It returns the captured standard output, and undef with the
#	reason in error(). A child that writes nothing gives the empty
#	string, so a caller tests the return value with defined.
#
#	With group => 1 the child leads its own session, and the
#	method keeps its pid in child() while it waits. _group holds
#	that form.
sub command ( $self, $cmd, %args )
{
	my $log = $self->{cli}->log;
	$self->{error} = undef;

	$log->info( 'run: %s', join q{ }, @$cmd )
	    if $self->{cli}->option('verbose');

	return $self->_group( $cmd, %args ) if delete $args{group};

	my $result = Fugu::Process->run( cmd => $cmd, %args );
	if ( defined $result->{error} ) {
		$self->{error} = $result->{error};
		return;
	}

	print STDERR $result->{stderr} if length $result->{stderr};

	unless ( $result->{success} ) {
		$self->{error} =
		    $result->{timed_out}
		    ? "$cmd->[0] timed out"
		    : "$cmd->[0] exited $result->{exit_code}";
		return;
	}

	return $result->{stdout};
}

# $self->_group($cmd, %args):
#	The group form of command(). Fugu::Process->spawn_command
#	starts the child with daemonize, so the child leads its own
#	session and its own process group. The pid stays in child()
#	while the parent waits, so a signal handler stops the whole
#	tree with Fugu::Process->terminate.
#
#	spawn_command opens each stream by its path, and two opens of
#	one path truncate that file twice. So the child writes its two
#	streams to two files of one temporary directory. The method
#	writes both files to standard error after the exit, because a
#	child writes no part of the result (CLI-PROGRAM-4).
#
#	spawn_command takes stdin, env, and inherit, and it takes
#	neither cwd nor timeout. A caller that needs one of those two
#	uses the plain form.
sub _group ( $self, $cmd, %args )
{
	my $dir = File::Temp->newdir(
		TEMPLATE => 'fugubench-XXXXXXXX',
		TMPDIR   => 1
	);
	my @files = ( "$dir/stdout", "$dir/stderr" );

	my $result = Fugu::Process->spawn_command(
		cmd       => $cmd,
		daemonize => 1,
		stdout    => $files[0],
		stderr    => $files[1],
		%args
	);
	unless ( $result->{success} ) {
		$self->{error} = $result->{error};
		return;
	}

	$self->{child} = $result->{pid};
	my $reaped = waitpid $result->{pid}, 0;

	# The errno of the wait, next to the wait itself. A read below
	# that fails overwrites $!, and the message of a wait that
	# reaps no child must name the errno of the wait.
	my $errno = $!;
	my $code  = Fugu::Process->exit_code($?);
	$self->{child} = undef;

	for my $file (@files) {
		my $text = Fugu::File->read($file);
		print STDERR $text if defined $text && length $text;
	}

	# A wait that reaps no child leaves the status of an earlier
	# one in $?, so the code above belongs to no run of this
	# command.
	if ( $reaped != $result->{pid} ) {
		$self->{error} = "$cmd->[0] left no status: $errno";
		return;
	}

	unless ( $code == 0 ) {
		$self->{error} = "$cmd->[0] exited $code";
		return;
	}

	return q{};
}

1;
