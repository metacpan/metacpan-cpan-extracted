package Algorithm::Classifier::IsolationForest::App::Command::streamd;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest         ();
use Algorithm::Classifier::IsolationForest::Online ();
use Algorithm::Classifier::IsolationForest::App -command;
use File::Slurp      qw(read_file write_file);
use File::Path       qw(make_path);
use File::Basename   qw(dirname);
use File::Spec       ();
use Scalar::Util     qw(looks_like_number);
use IO::Socket::UNIX ();
use IO::Select       ();
use POSIX            qw(setsid strftime);
use Errno            qw();

# The daemon is a singleton per process, so its runtime state lives in
# file-scoped lexicals rather than being threaded through every helper.
my $JSON;          # JSON::MaybeXS codec (required at runtime, see execute)
my $OIF;           # the online model
my %OPT;           # resolved options
my $LOG_FH;        # log handle (STDERR in foreground without --log)
my %CONN;          # fileno => { sock, inbuf, outbuf, mode }
my $DIRTY = 0;     # learned anything since the last save?
my $RUN;           # cleared by SIGTERM/SIGINT
my $SAVE_NOW;      # set by SIGUSR1
my $REOPEN_LOG;    # set by SIGHUP

# Sanity caps on per-connection buffers: a client is allowed big batch
# messages, but one that streams an endless line (or stops reading its
# replies) gets dropped instead of eating the daemon's memory.
use constant MAX_INBUF  => 16 * 1024 * 1024;
use constant MAX_OUTBUF => 16 * 1024 * 1024;

sub opt_spec {
	return (
		[
			'set=s',
			'Named instance. Appended to --model-dir, and the socket/pid become <set>.sock / <set>.pid '
				. 'under the run dir, so several daemons run side by side with no other flags. '
				. 'Must match /\A[A-Za-z0-9+\-@_]+\z/.'
		],
		[
			'socket=s',
			'Unix domain socket to listen on; default /var/run/iforest_streamd/streamd.sock. With --set '
				. 'this is instead the base run dir (default /var/run/iforest_streamd) the <set>.sock is created in.',
			{ 'completion' => 'files' }
		],
		[
			'pid=s',
			'Where to write the daemon pid; default /var/run/iforest_streamd/streamd.pid. With --set '
				. 'this is instead the base run dir (default /var/run/iforest_streamd) the <set>.pid is created in.',
			{ 'completion' => 'files' }
		],
		[
			'model-dir=s',
			'Directory timestamped model saves land in; the symlink latest.json in it always points '
				. 'at the newest, and the daemon resumes from it at startup when it exists. With --set '
				. 'the set name is appended as a subdirectory.',
			{ 'default' => '/var/db/iforest_streamd', 'completion' => 'files' }
		],
		[
			'save-interval=i',
			'Seconds between periodic model saves (only when learning happened).',
			{ 'default' => 300 }
		],
		[ 'keep=i',       'Prune all but the newest N timestamped model files after each save.' ],
		[ 'f|foreground', 'Do not daemonize; log to stderr unless --log is given.' ],
		[
			'log=s',
			'Log file. Defaults to <model-dir>/streamd.log when daemonized; stderr in the foreground.',
			{ 'completion' => 'files' }
		],
		[ 'socket-mode=s', 'Octal permissions to chmod the socket file to (e.g. 0660).' ],
		[ 'threshold=f',   'Alternative decision threshold to use for the label field. 0 < $val < 1' ],

		# creation knobs, used only when <model-dir>/latest.json does not exist yet
		[ 'n=i',         'Number of isolation trees in the ensemble (new models only).' ],
		[ 'window=i',    'Sliding window size; 0 disables forgetting (new models only).' ],
		[ 'eta=i',       'max_leaf_samples: points a leaf accumulates before splitting (new models only).' ],
		[ 'growth=s',    "Leaf split-requirement growth, 'adaptive' or 'fixed' (new models only)." ],
		[ 'subsample=f', 'Per-tree stream subsampling probability, in (0, 1] (new models only).' ],
		[ 's=i',         'Seed int (new models only).' ],
		[
			'c=f',
			'Contamination. Expected fraction of anomalies, in (0, 0.5]; the decision threshold is '
				. 'relearned from the window before every save (new models only).'
		],
		[
			't=s@',
			'Feature name tag. Pass once per feature; enables the tagged (JSON object) row form '
				. '(new models only).'
		],
		[
			'mungers=s',
			'JSON file of Algorithm::ToNumberMunger specs, keyed by feature tag (new models only; requires -t).',
			{ 'completion' => 'files' }
		],
		[
			'prototype=s',
			'JSON prototype file to create the model from (new models only). May not be combined '
				. 'with -t or --mungers. See PROTOTYPES in the module POD.',
			{ 'completion' => 'files' }
		],
	);
} ## end sub opt_spec

sub abstract { 'Run an Online Isolation Forest scoring daemon on a Unix socket, speaking JSON lines' }

sub description {
	'Runs a prequential scoring daemon around an Online Isolation Forest
model (Algorithm::Classifier::IsolationForest::Online): clients connect
to the Unix domain socket and exchange one JSON document per line.

At startup the daemon resumes from <model-dir>/latest.json when it
exists; otherwise it creates a new model from the creation knobs (-n,
--window, --eta, --growth, --subsample, -s, -c, -t, --mungers,
--prototype -- the same set `iforest stream` takes). The model is saved
to a timestamped file in --model-dir every --save-interval seconds
(only when something was learned), on SIGUSR1, on the save command, and
at shutdown; the symlink latest.json is atomically repointed at every
save, so a restart resumes the stream losing at most one interval.

Requests are JSON objects carrying exactly one of "row", "rows", or
"cmd", an optional "mode", and an optional "tag" (any JSON value,
echoed back verbatim in the reply -- a correlation tag, not to be
confused with feature tags):

  {"row": [0.1, 0.7]}                        -> {"score": 0.41, "label": 0}
  {"row": {"cpu": 0.1, "mem": 0.7}}          -> {"score": 0.41, "label": 0}
  {"rows": [[...], {...}], "tag": "b7"}      -> {"scores": [[0.41,0], ...], "tag": "b7"}
  {"rows": [[...]], "mode": "learn"}         -> {"ok": {"learned": 1}}
  {"cmd": "mode", "mode": "score"}           -> {"ok": {"mode": "score"}}
  {"cmd": "ping"}                            -> {"ok": "pong"}
  {"cmd": "stats"}                           -> {"ok": {"seen": ..., ...}}
  {"cmd": "save"}                            -> {"ok": {"saved": "oiforest-....json"}}
  {"cmd": "relearn-threshold"}               -> {"ok": {"threshold": 0.61}}
  anything invalid                           -> {"error": "...", "tag": ...}

The array row form is positional (scalar mungers applied, like stream
CSV input); the object form is a tagged row and runs the full munger
plan, including expanding and combining mungers -- and, being JSON, the
raw values may safely contain commas, newlines, or any unicode.

A worked tagged example.  Create the daemon around raw HTTP request
data, with mungers turning the raw values into numbers (mungers.json
here; a --prototype carrying the same schema works identically):

  { "method":       { "munger": "http_method_enum", "default": -1 },
    "path_len":     { "munger": "length",  "from": "path" },
    "host_entropy": { "munger": "entropy", "from": "host" } }

  iforest streamd --set web -t method -t path_len -t host_entropy \
      --mungers mungers.json -c 0.05

Clients then send the raw values themselves -- note the input fields
are the munger SOURCES (method, path, host), not the feature tags,
because the plan derives path_len and host_entropy from them:

  -> {"row": {"method": "GET", "path": "/index.html",
      "host": "www.example.com"}, "tag": "r-1"}
  <- {"score": 0.31, "label": 0, "tag": "r-1"}
  -> {"row": {"method": "BREW", "path": "/aa,a\"a.php",
      "host": "kq3xv9z2.biz"}, "tag": "r-2"}
  <- {"score": 0.74, "label": 1, "tag": "r-2"}

The same rows work from the shell via
`iforest streamc --set web --jsonl -i rows.jsonl`.

Modes are prequential (score each row against the model as it stood, then
learn it -- the default), learn (learn only), and score (score only);
"mode" on a row/rows message overrides the connection default set by
the mode command for that message.  A bad row gets an {"error": ...}
reply on that message only; the connection and the daemon live on (for
a "rows" batch, rows before the failing one were already processed).

Multiple concurrent connections are supported; rows are applied to the
one shared model in the order their lines arrive, which defines the
stream order.

--set NAME runs a named instance: the set name is appended to
--model-dir (so its saves, latest.json, and default log live under
their own subdirectory) and the socket/pid become <set>.sock /
<set>.pid under the run dir -- with --set, --socket and --pid name the
base run dir instead of the files.  Several sets run side by side, each
with its own model, resume state, and double-start protection:

  iforest streamd --set web
  iforest streamd --set dns --prototype dns-proto.json -c 0.02

Set names must match /\A[A-Za-z0-9+\-@_]+\z/; since the class has no
"." or "/", a set name can only ever create one new path segment.

Everything under --model-dir and the socket/pid directories is created
at startup when missing; when that fails (e.g. running unprivileged
with the /var defaults) the daemon dies immediately, before forking,
naming the directory and the flag to override.
';
} ## end sub description

sub validate {
	my ( $self, $opt, $args ) = @_;

	# Anchored with \A/\z rather than ^/$ ($ tolerates a trailing newline).
	# The class has no '.' or '/', so a set name can only ever create one
	# new path segment -- no traversal is expressible.
	if ( defined( $opt->{'set'} ) && $opt->{'set'} !~ /\A[A-Za-z0-9+\-@_]+\z/ ) {
		$self->usage_error( '--set, "'
				. $opt->{'set'}
				. '", must match /\A[A-Za-z0-9+\-@_]+\z/ (letters, digits, and + - @ _ only)' );
	}

	if ( $opt->{'save_interval'} < 1 ) {
		$self->usage_error( '--save-interval, "' . $opt->{'save_interval'} . '", must be >= 1 second' );
	}

	if ( defined( $opt->{'keep'} ) && $opt->{'keep'} < 1 ) {
		$self->usage_error( '--keep, "' . $opt->{'keep'} . '", must be >= 1' );
	}

	if ( defined( $opt->{'threshold'} ) && ( $opt->{'threshold'} <= 0 || $opt->{'threshold'} >= 1 ) ) {
		$self->usage_error( '--threshold, "' . $opt->{'threshold'} . '", needs to be greater than 0 and less than 1' );
	}

	if ( defined( $opt->{'growth'} ) && $opt->{'growth'} !~ /\A(?:adaptive|fixed)\z/ ) {
		$self->usage_error( '--growth, "' . $opt->{'growth'} . '", must be either adaptive or fixed' );
	}

	if ( defined( $opt->{'socket_mode'} ) && $opt->{'socket_mode'} !~ /\A0?[0-7]{3}\z/ ) {
		$self->usage_error( '--socket-mode, "' . $opt->{'socket_mode'} . '", must be octal like 0660' );
	}

	if ( defined( $opt->{'mungers'} ) ) {
		if ( !-f $opt->{'mungers'} ) {
			$self->usage_error( '--mungers, "' . $opt->{'mungers'} . '", is not a file or does not exist' );
		} elsif ( !-r $opt->{'mungers'} ) {
			$self->usage_error( '--mungers, "' . $opt->{'mungers'} . '", is not readable' );
		} elsif ( !defined( $opt->{'t'} ) ) {
			$self->usage_error('--mungers requires feature tags (-t) to compile against');
		}
	}

	if ( defined( $opt->{'prototype'} ) ) {
		if ( !-f $opt->{'prototype'} ) {
			$self->usage_error( '--prototype, "' . $opt->{'prototype'} . '", is not a file or does not exist' );
		} elsif ( !-r $opt->{'prototype'} ) {
			$self->usage_error( '--prototype, "' . $opt->{'prototype'} . '", is not readable' );
		}
		if ( defined( $opt->{'t'} ) || defined( $opt->{'mungers'} ) ) {
			$self->usage_error(
				'--prototype may not be combined with -t or --mungers; the schema comes only from the prototype');
		}
	} ## end if ( defined( $opt->{'prototype'} ) )

	return 1;
} ## end sub validate

sub execute {
	my ( $self, $opt, $args ) = @_;

	# JSON::MaybeXS is required lazily so a box without it still has a
	# working iforest CLI (App::Cmd loads every command module up front).
	eval { require JSON::MaybeXS; 1 }
		or die( 'iforest streamd requires JSON::MaybeXS for its wire protocol; install it: ' . $@ );
	$JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1, allow_nonref => 0 );

	%OPT = %$opt;

	# --set turns --socket/--pid into base run dirs holding <set>.sock /
	# <set>.pid and appends the set name to --model-dir, so several named
	# daemons run side by side with no other flags.  Without a set the
	# flags are the socket/pid files themselves, defaulting as documented.
	if ( defined $OPT{'set'} ) {
		my $run = defined $OPT{'socket'} ? $OPT{'socket'} : '/var/run/iforest_streamd';
		$OPT{'socket'} = File::Spec->catfile( $run, $OPT{'set'} . '.sock' );
		my $prun = defined $OPT{'pid'} ? $OPT{'pid'} : '/var/run/iforest_streamd';
		$OPT{'pid'}       = File::Spec->catfile( $prun, $OPT{'set'} . '.pid' );
		$OPT{'model_dir'} = File::Spec->catdir( $OPT{'model_dir'}, $OPT{'set'} );
	} else {
		$OPT{'socket'} = '/var/run/iforest_streamd/streamd.sock' unless defined $OPT{'socket'};
		$OPT{'pid'}    = '/var/run/iforest_streamd/streamd.pid'  unless defined $OPT{'pid'};
	}

	# Daemonizing chdirs to /, so every path used after that point must be
	# absolute -- including the socket and pid file, which are unlinked at
	# shutdown.
	for my $path_opt (qw(socket pid model_dir log)) {
		$OPT{$path_opt} = File::Spec->rel2abs( $OPT{$path_opt} )
			if defined $OPT{$path_opt};
	}

	# sun_path is 104 bytes on the BSDs and 108 on Linux (including the
	# NUL); Socket.pm just warns and TRUNCATES an over-long path, which
	# binds a socket nobody will ever find.  Refuse loudly instead.
	die(      '--socket, "'
			. $OPT{'socket'}
			. '", is '
			. length( $OPT{'socket'} )
			. ' bytes; Unix socket paths are limited to ~104 bytes -- use a shorter path'
			. "\n" )
		if length( $OPT{'socket'} ) > 100;

	# --- directories, before anything forks or binds -----------------------
	_ensure_dir( $OPT{'model_dir'},         '--model-dir' );
	_ensure_dir( dirname( $OPT{'socket'} ), '--socket' );
	_ensure_dir( dirname( $OPT{'pid'} ),    '--pid' );

	# --- refuse to double-start ---------------------------------------------
	if ( -e $OPT{'socket'} ) {
		my $probe = IO::Socket::UNIX->new( Peer => $OPT{'socket'} );
		die( 'another daemon is already listening on "' . $OPT{'socket'} . '"' . "\n" ) if $probe;
		unlink $OPT{'socket'};    # stale socket from an unclean exit
	}
	if ( -f $OPT{'pid'} ) {
		my $old = read_file( $OPT{'pid'} );
		chomp $old if defined $old;
		if ( defined $old && $old =~ /\A\d+\z/ && ( kill( 0, $old ) || $!{EPERM} ) ) {
			die( 'another daemon appears to be running (pid ' . $old . ' from "' . $OPT{'pid'} . '")' . "\n" );
		}
		unlink $OPT{'pid'};       # stale pid file
	}

	# --- resume or create the model ----------------------------------------
	my $latest = File::Spec->catfile( $OPT{'model_dir'}, 'latest.json' );
	if ( -e $latest ) {
		$OIF = Algorithm::Classifier::IsolationForest->load($latest);
		die( '"' . $latest . '" is not an online model; streamd only works on those' . "\n" )
			unless ref $OIF eq 'Algorithm::Classifier::IsolationForest::Online';
	} elsif ( defined $OPT{'prototype'} ) {
		my $proto = eval {
			Algorithm::Classifier::IsolationForest->validate_prototype( scalar read_file( $OPT{'prototype'} ) );
		};
		die( '--prototype, "' . $OPT{'prototype'} . '", is not a valid prototype: ' . $@ ) if $@;
		die( '--prototype, "' . $OPT{'prototype'} . '", is for a batch model; streamd needs an online one' . "\n" )
			unless $proto->{class} eq 'online';

		my %overrides;
		$overrides{'n_trees'}          = $OPT{'n'}         if defined $OPT{'n'};
		$overrides{'window_size'}      = $OPT{'window'}    if defined $OPT{'window'};
		$overrides{'max_leaf_samples'} = $OPT{'eta'}       if defined $OPT{'eta'};
		$overrides{'growth'}           = $OPT{'growth'}    if defined $OPT{'growth'};
		$overrides{'subsample'}        = $OPT{'subsample'} if defined $OPT{'subsample'};
		$overrides{'seed'}             = $OPT{'s'}         if defined $OPT{'s'};
		$overrides{'contamination'}    = $OPT{'c'}         if defined $OPT{'c'};

		$OIF = eval { Algorithm::Classifier::IsolationForest->new_from_prototype( $proto, %overrides ) };
		die( '--prototype, "' . $OPT{'prototype'} . '", failed to create a model: ' . $@ ) if $@;
	} else {
		my $mungers;
		if ( defined $OPT{'mungers'} ) {
			$mungers = eval { $JSON->decode( scalar read_file( $OPT{'mungers'} ) ) };
			die( '--mungers, "' . $OPT{'mungers'} . '", did not parse as JSON: ' . $@ ) if $@;
			die( '--mungers, "' . $OPT{'mungers'} . '", must be a JSON object of tag => spec' )
				unless ref $mungers eq 'HASH';
		}
		$OIF = Algorithm::Classifier::IsolationForest::Online->new(
			'n_trees'          => $OPT{'n'},
			'window_size'      => $OPT{'window'},
			'max_leaf_samples' => $OPT{'eta'},
			'growth'           => $OPT{'growth'},
			'subsample'        => $OPT{'subsample'},
			'seed'             => $OPT{'s'},
			'contamination'    => $OPT{'c'},
			'feature_names'    => $OPT{'t'},
			'mungers'          => $mungers,
		);
	} ## end else [ if ( -e $latest ) ]

	# --- bind, then daemonize (the listening fd survives the forks) --------
	my $listener = IO::Socket::UNIX->new(
		Local  => $OPT{'socket'},
		Listen => 64,
	) or die( 'failed to listen on "' . $OPT{'socket'} . '": ' . $! . "\n" );
	$listener->blocking(0);
	if ( defined $OPT{'socket_mode'} ) {
		chmod( oct( $OPT{'socket_mode'} ), $OPT{'socket'} )
			or die( 'failed to chmod "' . $OPT{'socket'} . '" to ' . $OPT{'socket_mode'} . ': ' . $! . "\n" );
	}

	if ( !$OPT{'f'} ) {
		$OPT{'log'} = File::Spec->catfile( $OPT{'model_dir'}, 'streamd.log' )
			unless defined $OPT{'log'};
		_daemonize();
	}
	_open_log();

	write_file( $OPT{'pid'}, { 'atomic' => 1 }, $$ . "\n" );

	# --- signals -------------------------------------------------------------
	$RUN        = 1;
	$SAVE_NOW   = 0;
	$REOPEN_LOG = 0;
	local $SIG{TERM} = sub { $RUN        = 0 };
	local $SIG{INT}  = sub { $RUN        = 0 };
	local $SIG{USR1} = sub { $SAVE_NOW   = 1 };
	local $SIG{HUP}  = sub { $REOPEN_LOG = 1 };
	local $SIG{PIPE} = 'IGNORE';

	_log(     'listening on '
			. $OPT{'socket'}
			. ( -e $latest          ? ' (resumed '                : ' (new model, ' )
			. ( defined $OPT{'set'} ? 'set=' . $OPT{'set'} . ', ' : '' ) . 'seen='
			. $OIF->seen
			. ', save-interval='
			. $OPT{'save_interval'} . 's'
			. ', model-dir='
			. $OPT{'model_dir'}
			. ')' );

	# --- event loop ----------------------------------------------------------
	my $rsel      = IO::Select->new($listener);
	my $wsel      = IO::Select->new();
	my $next_save = time + $OPT{'save_interval'};

	while ($RUN) {
		my $timeout = $next_save - time;
		$timeout = 0 if $timeout < 0;

		my @ready = $rsel->can_read($timeout);
		for my $s (@ready) {
			if ( $s == $listener ) {
				while ( my $cl = $listener->accept ) {
					$cl->blocking(0);
					$CONN{ fileno($cl) } = { sock => $cl, inbuf => '', outbuf => '', mode => 'prequential' };
					$rsel->add($cl);
				}
				next;
			}
			_read_from( $s, $rsel, $wsel );
		} ## end for my $s (@ready)

		# Drain clients whose replies did not fit in one write.
		if ( $wsel->count ) {
			for my $s ( $wsel->can_write(0) ) {
				_flush( $s, $rsel, $wsel );
			}
		}

		if ($REOPEN_LOG) {
			$REOPEN_LOG = 0;
			_open_log();
			_log('log reopened on SIGHUP');
		}
		if ( $SAVE_NOW || time >= $next_save ) {
			_save_model( $SAVE_NOW ? 'signal' : 'interval' ) if $DIRTY || $SAVE_NOW;
			$SAVE_NOW  = 0;
			$next_save = time + $OPT{'save_interval'};
		}
	} ## end while ($RUN)

	# --- shutdown ------------------------------------------------------------
	_log('shutting down');
	_save_model('shutdown') if $DIRTY;
	for my $c ( values %CONN ) {
		close $c->{sock};
	}
	%CONN = ();
	close $listener;
	unlink $OPT{'socket'};
	unlink $OPT{'pid'};
	_log('bye');

	return 1;
} ## end sub execute

#-------------------------------------------------------------------------------
# startup helpers
#-------------------------------------------------------------------------------

# Make sure a directory the daemon needs exists and is writable, creating
# it when it does not.  Run before daemonizing so a permissions problem is
# reported to the terminal that started the daemon rather than buried in a
# log the user has not found yet.
#
# Args:
#   $dir :: the directory to create or check.
#   $flag :: the option that asked for it, e.g. '--model-dir'.  Only used
#            to name the fix in the error message.
#
# Returns: 1 when the directory exists and is writable.  Dies otherwise,
# telling the user to create it, fix its permissions, or point $flag
# somewhere else.
#
# Example:
#   _ensure_dir( $OPT{'model_dir'}, '--model-dir' );
sub _ensure_dir {
	my ( $dir, $flag ) = @_;
	if ( !-d $dir ) {
		my $err;
		make_path( $dir, { mode => oct('0755'), error => \$err } );
		die(      'could not create "'
				. $dir
				. '" (needed for '
				. $flag
				. '); create it, fix permissions, or point '
				. $flag
				. ' somewhere writable'
				. "\n" )
			if !-d $dir;
	} ## end if ( !-d $dir )
	die( '"' . $dir . '" (needed for ' . $flag . ') is not writable; fix permissions or override ' . $flag . "\n" )
		unless -w $dir;
	return 1;
} ## end sub _ensure_dir

# Classic double-fork daemonization.  The parents leave via POSIX::_exit
# so no END blocks (Inline's, App::Cmd's) run twice.  The second fork is
# what guarantees the daemon can never reacquire a controlling terminal.
#
# Args: none.  Reads nothing and takes nothing -- the caller decides
# whether to daemonize at all (-f keeps the process in the foreground).
#
# Returns: 1, in the grandchild only.  The two parents never return: they
# _exit(0) immediately, so the caller either continues as the daemon or
# does not continue.  Dies on a failed fork, setsid, chdir or STDIN
# reopen.
#
# Example:
#   _daemonize() unless $OPT{'f'};
#   # from here on we are the daemon
sub _daemonize {
	defined( my $pid = fork() ) or die( 'fork failed: ' . $! . "\n" );
	POSIX::_exit(0) if $pid;
	setsid()                 or die( 'setsid failed: ' . $! . "\n" );
	defined( $pid = fork() ) or die( 'second fork failed: ' . $! . "\n" );
	POSIX::_exit(0) if $pid;
	chdir '/'                       or die( 'chdir / failed: ' . $! . "\n" );
	open( STDIN, '<', '/dev/null' ) or die( 'reopen STDIN failed: ' . $! . "\n" );
	return 1;
} ## end sub _daemonize

# Point the daemon's logging at wherever --log said, falling back to
# STDERR.  When daemonized, STDOUT and STDERR are reopened onto the log
# too, so a warn from anywhere in the process still lands somewhere the
# operator can read.  Everything is unbuffered: a daemon's log is useless
# if the interesting line is still sitting in a buffer when it wedges.
#
# Args: none.  Reads $OPT{'log'} and $OPT{'f'}.
#
# Returns: 1.  Sets the package's $LOG_FH as its whole purpose.  Dies when
# the log file cannot be opened.
#
# Example:
#   _open_log();
#   _log('listening');
sub _open_log {
	if ( defined $OPT{'log'} ) {
		open( my $fh, '>>', $OPT{'log'} ) or die( 'failed to open log "' . $OPT{'log'} . '": ' . $! . "\n" );
		$fh->autoflush(1);
		$LOG_FH = $fh;
		if ( !$OPT{'f'} ) {
			open( STDOUT, '>>', $OPT{'log'} ) or die( 'reopen STDOUT failed: ' . $! . "\n" );
			open( STDERR, '>>', $OPT{'log'} ) or die( 'reopen STDERR failed: ' . $! . "\n" );
			STDOUT->autoflush(1);
			STDERR->autoflush(1);
		}
	} else {
		$LOG_FH = \*STDERR;
	}
	return 1;
} ## end sub _open_log

# Write one timestamped, pid-stamped line to the log.  The pid matters
# because several named instances (--set) can share one log file.
#
# Args:
#   $msg :: the message, without a trailing newline -- one is added.
#
# Returns: 1.
#
# Example:
#   _log( 'saved ' . $name . ' (' . $why . ')' );
#   # 2026-08-08T14:02:11 [4821] saved oiforest-20260808-140211.json (interval)
sub _log {
	my ($msg) = @_;
	print {$LOG_FH} strftime( '%Y-%m-%dT%H:%M:%S', localtime ) . ' [' . $$ . '] ' . $msg . "\n";
	return 1;
}

#-------------------------------------------------------------------------------
# model persistence
#-------------------------------------------------------------------------------

# Timestamped save + atomic symlink flip.  The symlink stores a relative
# name, so the whole model directory can be moved without breaking it.
#
# Args:
#   $why :: a short reason recorded in the log line, e.g. 'interval',
#           'command', 'SIGUSR1' or 'shutdown'.
#
# Returns: the file name written, relative to --model-dir.  Also clears
# the dirty flag, repoints latest.json, and prunes old models when --keep
# is set.  Dies if the write fails; a failed symlink or rename only warns
# to the log, since the model itself is already safely on disk.
#
# Example:
#   my $name = _save_model('interval');   # 'oiforest-20260808-140211.json'
sub _save_model {
	my ($why) = @_;

	# Keep the persisted default cutoff tracking the stream, like the
	# stream command does before its save.
	if ( defined $OIF->{contamination} && $OIF->window_count ) {
		$OIF->relearn_threshold;
	}

	my $base = 'oiforest-' . strftime( '%Y%m%d-%H%M%S', localtime );
	my $name = $base . '.json';
	my $n    = 0;
	while ( -e File::Spec->catfile( $OPT{'model_dir'}, $name ) ) {
		$n++;
		$name = $base . '-' . $n . '.json';
	}
	write_file( File::Spec->catfile( $OPT{'model_dir'}, $name ), { 'atomic' => 1 }, $OIF->to_json );

	my $tmp = File::Spec->catfile( $OPT{'model_dir'}, '.latest.tmp.' . $$ );
	unlink $tmp;
	symlink( $name, $tmp )
		or _log( 'WARNING: symlink for latest.json failed: ' . $! );
	rename( $tmp, File::Spec->catfile( $OPT{'model_dir'}, 'latest.json' ) )
		or _log( 'WARNING: renaming latest.json symlink failed: ' . $! );

	$DIRTY = 0;
	_log( 'saved ' . $name . ' (' . $why . ', seen=' . $OIF->seen . ')' );
	_prune_models() if defined $OPT{'keep'};
	return $name;
} ## end sub _save_model

# Keep only the newest --keep timestamped models, deleting the rest
# oldest-first.  Ordered by mtime rather than by the name's timestamp so
# a clock stepping backwards cannot strand a file forever.  latest.json is
# a symlink, not a match for the model pattern, so it is never a
# candidate.
#
# Args: none.  Reads $OPT{'model_dir'} and $OPT{'keep'}, and is only
# called when --keep is set.
#
# Returns: 1, or an empty return when the model directory cannot be
# opened -- pruning is housekeeping, so it never takes the daemon down.
#
# Example:
#   _prune_models() if defined $OPT{'keep'};
sub _prune_models {
	opendir( my $dh, $OPT{'model_dir'} ) or return;
	my @models = sort { ( stat($a) )[9] <=> ( stat($b) )[9] }
		map { File::Spec->catfile( $OPT{'model_dir'}, $_ ) }
		grep { /\Aoiforest-.*\.json\z/ } readdir($dh);
	closedir $dh;
	while ( scalar @models > $OPT{'keep'} ) {
		my $old = shift @models;
		unlink $old and _log( 'pruned ' . $old );
	}
	return 1;
} ## end sub _prune_models

#-------------------------------------------------------------------------------
# connection handling
#-------------------------------------------------------------------------------

# Close one client connection and forget everything about it.  The single
# teardown path, so a connection can never be left in a selector after its
# socket is gone.
#
# Args:
#   $s :: the client socket.
#   $rsel :: the read IO::Select set it may be registered in.
#   $wsel :: the write IO::Select set it may be registered in.
#
# Returns: 1.  Callers return its value directly, which is why the read
# and write loops read as "return _drop(...)".
#
# Example:
#   return _drop( $s, $rsel, $wsel ) if $got == 0;   # client closed
sub _drop {
	my ( $s, $rsel, $wsel ) = @_;
	$rsel->remove($s);
	$wsel->remove($s);
	delete $CONN{ fileno($s) };
	close $s;
	return 1;
}

# Read whatever is available from one client, dispatch every complete
# line in it, and push the replies back out.  Partial lines stay in the
# connection's input buffer for the next readable event, which is what
# lets one non-blocking loop serve many clients.
#
# A client that sends an unterminated line past MAX_INBUF, or backs up
# past MAX_OUTBUF of unread replies, is dropped: neither is recoverable,
# and both would otherwise let one client exhaust the daemon's memory.
#
# Args:
#   $s :: the readable client socket.
#   $rsel :: the read IO::Select set.
#   $wsel :: the write IO::Select set, which gains $s when a reply cannot
#            be written in full.
#
# Returns: 1 after servicing the client, or the result of _drop when the
# connection ended or misbehaved.  An empty return on EAGAIN/EINTR, or for
# a socket with no connection record, leaves the client untouched.
#
# Example:
#   _read_from( $_, $rsel, $wsel ) for $rsel->can_read($timeout);
sub _read_from {
	my ( $s, $rsel, $wsel ) = @_;
	my $c = $CONN{ fileno($s) } or return;

	my $got = sysread( $s, my $chunk, 65536 );
	if ( !defined $got ) {
		return if $!{EAGAIN} || $!{EWOULDBLOCK} || $!{EINTR};
		return _drop( $s, $rsel, $wsel );
	}
	return _drop( $s, $rsel, $wsel ) if $got == 0;    # client closed

	$c->{inbuf} .= $chunk;
	if ( length( $c->{inbuf} ) > MAX_INBUF && $c->{inbuf} !~ /\n/ ) {
		_log( 'dropping client: unterminated line exceeded ' . MAX_INBUF . ' bytes' );
		return _drop( $s, $rsel, $wsel );
	}

	while ( $c->{inbuf} =~ s/\A([^\n]*)\n// ) {
		my $line = $1;
		next if $line =~ /\A\s*\z/;
		_handle_line( $c, $line );
		return _drop( $s, $rsel, $wsel ) if length( $c->{outbuf} ) > MAX_OUTBUF;
	}
	_flush( $s, $rsel, $wsel ) if length $c->{outbuf};
	return 1;
} ## end sub _read_from

# Push as much of a connection's pending output as the socket will take.
# A client that cannot keep up leaves the remainder buffered and the
# socket registered for write-readiness, so the daemon never blocks on a
# slow reader.
#
# Args:
#   $s :: the client socket.
#   $rsel :: the read IO::Select set, needed only to hand to _drop.
#   $wsel :: the write IO::Select set.  $s is added while output remains
#            and removed once it has all gone out.
#
# Returns: 1 when the buffer drained completely, the result of _drop on a
# write error, or an empty return when the socket would block with output
# still pending.
#
# Example:
#   _flush( $s, $rsel, $wsel ) if length $c->{outbuf};
sub _flush {
	my ( $s, $rsel, $wsel ) = @_;
	my $c = $CONN{ fileno($s) } or return;
	while ( length $c->{outbuf} ) {
		my $wrote = syswrite( $s, $c->{outbuf} );
		if ( !defined $wrote ) {
			if ( $!{EAGAIN} || $!{EWOULDBLOCK} || $!{EINTR} ) {
				$wsel->add($s) unless $wsel->exists($s);
				return;
			}
			return _drop( $s, $rsel, $wsel );
		}
		substr( $c->{outbuf}, 0, $wrote, '' );
	} ## end while ( length $c->{outbuf} )
	$wsel->remove($s) if $wsel->exists($s);
	return 1;
} ## end sub _flush

#-------------------------------------------------------------------------------
# protocol
#-------------------------------------------------------------------------------

# One request line -> one reply line, appended to the connection's
# output buffer.  Any croak from the model becomes an {"error": ...}
# reply on this message alone; the connection and daemon live on.
#
# Args:
#   $c :: the connection record hashref, holding inbuf, outbuf and the
#         connection's default mode.
#   $line :: one request line, without its newline.  Must be a JSON object
#            carrying exactly one of row, rows or cmd, optionally with mode
#            and tag.
#
# Returns: whatever _reply returns (1).  Every path replies, including
# every error path, so a client is never left waiting.  A "tag" in the
# request is echoed on the reply, errors included.
#
# Example:
#   _handle_line( $c, '{"row":[0.2,0.7],"tag":"req-1"}' );
#   # queues {"score":0.41,"label":0,"tag":"req-1"}
sub _handle_line {
	my ( $c, $line ) = @_;

	my $msg = eval { $JSON->decode($line) };
	if ( $@ || ref $msg ne 'HASH' ) {
		( my $err = $@ ) =~ s/ at \S+ line \d+\.?\s*\z//s;
		return _reply( $c, { error => 'request is not a JSON object: ' . ( $err || 'wrong type' ) } );
	}

	my @tag = exists $msg->{tag} ? ( tag => $msg->{tag} ) : ();

	my @kinds = grep { exists $msg->{$_} } qw(row rows cmd);
	if ( scalar @kinds != 1 ) {
		return _reply( $c, { error => q{request needs exactly one of "row", "rows", or "cmd"}, @tag } );
	}
	my $kind = $kinds[0];

	my $mode = exists $msg->{mode} ? $msg->{mode} : $c->{mode};
	if ( !defined $mode || ref $mode || $mode !~ /\A(?:prequential|learn|score)\z/ ) {
		return _reply( $c, { error => q{mode must be "prequential", "learn", or "score"}, @tag } );
	}

	if ( $kind eq 'cmd' ) {
		return _handle_cmd( $c, $msg, \@tag );
	}

	my $rows = $kind eq 'row' ? [ $msg->{row} ] : $msg->{rows};
	if ( ref $rows ne 'ARRAY' || !@$rows ) {
		return _reply( $c, { error => q{"rows" must be a non-empty JSON array of rows}, @tag } );
	}

	my @scored;
	my $i = 0;
	for my $row (@$rows) {
		my $score = eval { _apply_row( $row, $mode ) };
		if ($@) {
			( my $err = $@ ) =~ s/ at \S+ line \d+\.?\s*\z//s;
			chomp $err;
			my $where = $kind eq 'row' ? '' : 'row ' . $i . ': ';
			return _reply( $c, { error => $where . $err, @tag } );
		}
		push @scored, $score if defined $score;
		$i++;
	} ## end for my $row (@$rows)

	if ( $mode eq 'learn' ) {
		return _reply( $c, { ok => { learned => scalar @$rows }, @tag } );
	}

	my $threshold = _threshold();
	my @pairs     = map { [ 0 + $_, ( $_ >= $threshold ? 1 : 0 ) ] } @scored;
	if ( $kind eq 'row' ) {
		return _reply( $c, { score => $pairs[0][0], label => $pairs[0][1], @tag } );
	}
	return _reply( $c, { scores => \@pairs, @tag } );
} ## end sub _handle_line

# The control half of the protocol: everything that inspects or steers
# the daemon rather than feeding it data.  Split out of _handle_line so
# the data path stays readable.
#
# Recognised commands:
#   - ping :: liveness check, replies "pong".
#   - mode :: set this connection's default mode for later messages.
#   - stats :: counters, window fill, effective threshold, connection
#              count and the instance's --set name.
#   - save :: save the model now, replying with the file name written.
#   - relearn-threshold :: recompute the contamination cutoff from the
#                          current window, replying with the new value.
#
# Args:
#   $c :: the connection record hashref.  The mode command mutates its
#         default mode.
#   $msg :: the decoded request hashref.
#   $tag :: arrayref of the (tag => value) pair to echo, or empty when the
#           request carried no tag.  Flattened into every reply.
#
# Returns: whatever _reply returns (1).  An unknown command gets an error
# reply naming it rather than closing the connection.
#
# Example:
#   _handle_cmd( $c, { cmd => 'stats' }, [] );
#   # queues {"ok":{"seen":48210,"window":2048,...}}
sub _handle_cmd {
	my ( $c, $msg, $tag ) = @_;
	my $cmd = $msg->{cmd};
	$cmd = '' if !defined $cmd || ref $cmd;

	if ( $cmd eq 'ping' ) {
		return _reply( $c, { ok => 'pong', @$tag } );
	}
	if ( $cmd eq 'mode' ) {
		my $mode = $msg->{mode};
		if ( !defined $mode || ref $mode || $mode !~ /\A(?:prequential|learn|score)\z/ ) {
			return _reply( $c, { error => q{mode must be "prequential", "learn", or "score"}, @$tag } );
		}
		$c->{mode} = $mode;
		return _reply( $c, { ok => { mode => $mode }, @$tag } );
	}
	if ( $cmd eq 'stats' ) {
		return _reply(
			$c,
			{
				ok => {
					seen        => 0 + $OIF->seen,
					window      => 0 + $OIF->window_count,
					n_features  => ( defined $OIF->{n_features} ? 0 + $OIF->{n_features} : undef ),
					threshold   => 0 + _threshold(),
					connections => 0 + scalar( keys %CONN ),
					dirty       => ( $DIRTY ? 1 : 0 ),
					set         => $OPT{'set'},
				},
				@$tag
			}
		);
	} ## end if ( $cmd eq 'stats' )
	if ( $cmd eq 'save' ) {
		my $name = eval { _save_model('command') };
		if ($@) {
			( my $err = $@ ) =~ s/ at \S+ line \d+\.?\s*\z//s;
			return _reply( $c, { error => $err, @$tag } );
		}
		return _reply( $c, { ok => { saved => $name }, @$tag } );
	}
	if ( $cmd eq 'relearn-threshold' ) {
		my $ok = eval { $OIF->relearn_threshold; 1 };
		if ( !$ok ) {
			( my $err = $@ ) =~ s/ at \S+ line \d+\.?\s*\z//s;
			chomp $err;
			return _reply( $c, { error => $err, @$tag } );
		}
		return _reply( $c, { ok => { threshold => 0 + $OIF->decision_threshold }, @$tag } );
	}
	return _reply( $c, { error => 'unknown cmd "' . $cmd . '"', @$tag } );
} ## end sub _handle_cmd

# Queue one reply on a connection.  Encoding and the trailing newline
# live here alone, so every reply the daemon emits is one JSON document
# per line no matter which handler produced it.
#
# Args:
#   $c :: the connection record hashref.  Its outbuf grows.
#   $reply :: the reply as a hashref, ready to encode.
#
# Returns: 1.  The bytes are not written here -- _read_from's _flush call
# does that once the current batch of lines has been handled.
#
# Example:
#   _reply( $c, { ok => 'pong' } );
sub _reply {
	my ( $c, $reply ) = @_;
	$c->{outbuf} .= $JSON->encode($reply) . "\n";
	return 1;
}

# The effective label cutoff, resolved per message so relearns and the
# contamination refresh at save time take effect immediately.
#
# Args: none.  Reads $OPT{'threshold'} and the model's own learned cutoff.
#
# Returns: the cutoff as a float -- --threshold when given, else the
# model's contamination-learned decision_threshold, else 0.5.
#
# Example:
#   my $label = $score >= _threshold() ? 1 : 0;
sub _threshold {
	return
		  defined $OPT{'threshold'}        ? $OPT{'threshold'}
		: defined $OIF->decision_threshold ? $OIF->decision_threshold
		:                                    0.5;
}

# One row through the model.  A JSON object is a tagged row (full munger
# plan, expanding/combining mungers included); a JSON array is positional
# (scalar mungers, like stream CSV input).  Either way the final vector
# is validated numeric before it touches the model -- JSON delivers
# typed values, so anything non-numeric left after munging is a caller
# bug worth an explicit error rather than Perl's silent string-to-0.
#
# Args:
#   $row :: one row, either a hashref of tagged raw values or an arrayref
#           of positional ones.  undef cells are left alone and defer to
#           the model's missing policy.
#   $mode :: 'learn', 'score' or 'prequential' -- learn only, score
#            without learning, or score then learn.
#
# Returns: the anomaly score as a float, or undef in learn mode.  Sets the
# dirty flag whenever the model actually learned, which is what makes the
# interval save skip a quiet period.  Dies on a row that is neither shape,
# on a cell left non-numeric after munging, or on anything the model
# itself croaks about.
#
# Example:
#   _apply_row( { method => 'GET', host => 'h' }, 'prequential' );   # 0.41
#   _apply_row( [ 0.2, 0.7 ], 'learn' );                             # undef
sub _apply_row {
	my ( $row, $mode ) = @_;

	my $vec;
	if ( ref $row eq 'HASH' ) {
		$vec = $OIF->tagged_row_to_array( $row, 'streamd' );
	} elsif ( ref $row eq 'ARRAY' ) {
		$vec = $row;
		if ( ref $OIF->{mungers} eq 'HASH' && %{ $OIF->{mungers} } ) {
			$vec = $OIF->munge_rows( [$row] )->[0];
		}
	} else {
		die 'row must be a JSON array (positional) or object (tagged)' . "\n";
	}

	for my $col ( 0 .. $#$vec ) {
		next if !defined $vec->[$col];    # undef defers to the model's missing policy
		die 'column ' . ( $col + 1 ) . ' is not a number after munging' . "\n"
			unless looks_like_number( $vec->[$col] );
	}

	if ( $mode eq 'learn' ) {
		$OIF->learn( [$vec] );
		$DIRTY = 1;
		return undef;
	}
	if ( $mode eq 'score' ) {
		return $OIF->score_samples( [$vec] )->[0];
	}
	my $score = $OIF->score_learn( [$vec] )->[0];
	$DIRTY = 1;
	return $score;
} ## end sub _apply_row

=head1 NAME

Algorithm::Classifier::IsolationForest::App::Command::streamd - Run an Online Isolation Forest scoring daemon on a Unix socket, speaking JSON lines

=head1 DESCRIPTION

Wraps the prequential loop of C<iforest stream> in a daemon: it listens
on a Unix domain socket, serves many concurrent connections from one
shared model, and exchanges one JSON document per line.  Because values
travel as JSON rather than positionally, raw input headed for mungers may
safely contain commas, newlines or any unicode, and object rows run the
full munger plan -- expanding and combining mungers included, which
positional CSV cannot express.

An optional C<"tag"> on a request is echoed back verbatim.  Errors are
always per-message: a bad row gets an C<{"error": ...}> reply and the
connection lives on.

Models are saved to C<--model-dir> as timestamped files every
C<--save-interval> seconds when learning has happened, plus on the C<save>
command, on SIGUSR1, and at shutdown.  The C<latest.json> symlink is
repointed atomically at each save and resumed from at the next startup, so
a crash loses at most one interval of learning.

Several named instances can run side by side: C<--set> gives each its own
socket, pid file, model subdirectory and resume state.

C<iforest streamc> is the matching client.

Run it as C<iforest streamd>; C<iforest help streamd> lists every option.

=head1 METHODS

L<App::Cmd> calls these while dispatching the subcommand.  Nothing else
should.

=head2 opt_spec

Returns this command's option specifications, as the list of arrayrefs
L<Getopt::Long::Descriptive> expects.

=head2 abstract

Returns the one-line summary C<iforest commands> prints beside the
command name.

=head2 description

Returns the long help text C<iforest help streamd> prints under the option
list.

=head2 validate

Checks the parsed options before anything is read or written, so a
mistake costs nothing.

Checks that C<--set> is a usable instance name, that C<--save-interval>,
C<--keep>, C<--threshold>, C<--growth> and C<--socket-mode> hold sane
values, and that a C<--mungers> spec is readable and accompanied by the
feature tags (C<-t>) it compiles against.

Takes the parsed options hashref and the arrayref of remaining
arguments.  Calls C<usage_error>, which prints the usage and exits, on
the first problem it finds, and returns 1 when everything checks out.

=head2 execute

Prepares the runtime and model directories, daemonizes unless C<-f> was
given, and runs the accept/serve loop until it is asked to stop.

Takes the parsed options hashref and the arrayref of remaining
arguments, and returns 1.

=cut

return 1;
