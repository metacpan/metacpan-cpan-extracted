package Algorithm::Classifier::IsolationForest::App::Command::streamc;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest::App -command;
use File::Slurp      qw(write_file);
use File::Spec       ();
use Scalar::Util     qw(looks_like_number);
use IO::Socket::UNIX ();
use IO::Select       ();

# JSON::MaybeXS codec and the connected socket, set up in execute.
my $JSON;
my $SOCK;
my $TIMEOUT;
my $READ_BUF = '';

sub opt_spec {
	return (
		[
			'set=s',
			'Named streamd instance to talk to; the socket becomes <set>.sock under the run dir, '
				. 'exactly as streamd resolves it. Must match /\A[A-Za-z0-9+\-@_]+\z/.'
		],
		[
			'socket=s',
			'Unix domain socket streamd listens on; default /var/run/iforest_streamd/streamd.sock. With '
				. '--set this is instead the base run dir (default /var/run/iforest_streamd) holding <set>.sock.',
			{ 'completion' => 'files' }
		],
		[ 'timeout=i', 'Seconds to wait for each reply from the daemon.', { 'default' => 30 } ],

		# stream mode
		[
			'i=s',
			'Input to stream through the daemon, one row per line; - reads stdin.',
			{ 'completion' => 'files' }
		],
		[ 'o=s', 'Output the results to this file instead of printing.', { 'completion' => 'files' } ],
		[ 'w',   'If the file specified via -o exists, over write it.' ],
		[ 'd',   'Include the input data in the output (CSV input only).' ],
		[
			'mode=s',
			"What each row does: 'prequential' (score against the model as it stood, then learn -- the "
				. "default), 'learn' (learn only, no output), or 'score' (score only, nothing learned).",
			{ 'default' => 'prequential' }
		],
		[
			'jsonl',
			'Input lines are JSON rows instead of CSV: an array is positional, an object is a tagged row '
				. '(full munger plan, raw values may contain anything JSON can). Output is the daemon\'s '
				. 'reply JSON lines verbatim, one per request (--batch 1 for one per row).'
		],
		[
			'batch=i',
			'Rows per request message. Bigger amortises round trips; 1 gives per-row latency for '
				. 'tail -F style pipelines.',
			{ 'default' => 256 }
		],

		# command mode
		[ 'ping',              'Check the daemon is alive; exits 0 on pong.' ],
		[ 'stats',             'Print the daemon stats (seen, window, threshold, connections, set, ...).' ],
		[ 'save',              'Ask the daemon to save the model now; prints the file name.' ],
		[ 'relearn-threshold', 'Ask the daemon to relearn the contamination decision threshold.' ],
		[ 'json',              'Command mode: print the raw JSON reply instead of the text rendering.' ],
	);
} ## end sub opt_spec

sub abstract { 'Client for iforest streamd: stream rows through it or send it commands' }

sub description {
	'Talks to a running `iforest streamd` daemon over its Unix socket,
speaking the same one-JSON-document-per-line protocol.

Stream mode (-i) feeds rows through the daemon and prints one result
per row, in order.  Input is CSV by default (positional rows, matching
`iforest stream`; fields are sent as numbers when they look like
numbers and as raw strings otherwise, so munged columns pass through
untouched) and the output is `$score,$label` lines, with -d prepending
the input columns.  With --jsonl each input line is instead a JSON row
-- an array for positional data, an object for a tagged row through
the full munger plan -- and the output is the daemon\'s reply JSON
lines verbatim.  Rows are sent in --batch sized messages, lockstep;
each request is tagged with its starting input line number, so a bad
row dies naming the input line (rows earlier in that message were
already applied by the daemon -- prequential learning is not
transactional).  All row validation is the daemon\'s: only it knows
whether the model munges.

Command mode sends exactly one of --ping, --stats, --save, or
--relearn-threshold and renders the reply as text (--json for the raw
reply).  The exit code is 0 on ok and non-zero on error, connect
failure, or timeout, so `iforest streamc --set web --ping` works
directly in health checks.

--set/--socket resolve the socket path exactly as streamd does, so the
same flags reach the same daemon.
';
} ## end sub description

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( defined( $opt->{'set'} ) && $opt->{'set'} !~ /\A[A-Za-z0-9+\-@_]+\z/ ) {
		$self->usage_error( '--set, "'
				. $opt->{'set'}
				. '", must match /\A[A-Za-z0-9+\-@_]+\z/ (letters, digits, and + - @ _ only)' );
	}

	my @cmds = grep { $opt->{$_} } qw(ping stats save relearn_threshold);
	if ( defined( $opt->{'i'} ) ) {
		if ( scalar @cmds ) {
			$self->usage_error('-i may not be combined with --ping/--stats/--save/--relearn-threshold');
		}
	} elsif ( scalar @cmds != 1 ) {
		$self->usage_error(
			'need either -i (stream mode) or exactly one of --ping, --stats, --save, --relearn-threshold');
	}

	if ( defined( $opt->{'i'} ) && $opt->{'i'} ne '-' ) {
		if ( !-f $opt->{'i'} ) {
			$self->usage_error( '-i, "' . $opt->{'i'} . '", is not a file or does not exist' );
		} elsif ( !-r $opt->{'i'} ) {
			$self->usage_error( '-i, "' . $opt->{'i'} . '", is not readable' );
		}
	}

	if ( defined( $opt->{'o'} ) && !$opt->{'w'} && -e $opt->{'o'} ) {
		$self->usage_error( '-o, "' . $opt->{'o'} . '", already exists and -w is not specified' );
	}

	if ( $opt->{'mode'} !~ /\A(?:prequential|learn|score)\z/ ) {
		$self->usage_error( '--mode, "' . $opt->{'mode'} . '", must be prequential, learn, or score' );
	}

	if ( $opt->{'d'} && $opt->{'jsonl'} ) {
		$self->usage_error('-d only applies to CSV input; --jsonl replies are already self-describing');
	}

	if ( $opt->{'json'} && defined( $opt->{'i'} ) ) {
		$self->usage_error('--json only applies to command mode');
	}

	if ( $opt->{'batch'} < 1 ) {
		$self->usage_error( '--batch, "' . $opt->{'batch'} . '", must be >= 1' );
	}

	if ( $opt->{'timeout'} < 1 ) {
		$self->usage_error( '--timeout, "' . $opt->{'timeout'} . '", must be >= 1' );
	}

	return 1;
} ## end sub validate

sub execute {
	my ( $self, $opt, $args ) = @_;

	# Lazily required for the same reason streamd does it: App::Cmd loads
	# every command module up front, and the rest of the CLI should work
	# on a box without JSON::MaybeXS.
	eval { require JSON::MaybeXS; 1 }
		or die( 'iforest streamc requires JSON::MaybeXS for its wire protocol; install it: ' . $@ );
	$JSON    = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
	$TIMEOUT = $opt->{'timeout'};

	# Resolve the socket exactly as streamd does (keep in sync with it):
	# without a set the flag is the socket file; with one it is the base
	# run dir holding <set>.sock.
	my $socket;
	if ( defined $opt->{'set'} ) {
		my $run = defined $opt->{'socket'} ? $opt->{'socket'} : '/var/run/iforest_streamd';
		$socket = File::Spec->catfile( $run, $opt->{'set'} . '.sock' );
	} else {
		$socket = defined $opt->{'socket'} ? $opt->{'socket'} : '/var/run/iforest_streamd/streamd.sock';
	}
	die(      '--socket, "'
			. $socket
			. '", is '
			. length($socket)
			. ' bytes; Unix socket paths are limited to ~104 bytes -- use a shorter path'
			. "\n" )
		if length($socket) > 100;

	$SOCK = IO::Socket::UNIX->new( Peer => $socket )
		or die( 'failed to connect to "'
			. $socket . '": '
			. $!
			. ' -- is streamd running'
			. ( defined $opt->{'set'} ? ' with --set ' . $opt->{'set'} : '' ) . '?'
			. "\n" );
	$SOCK->autoflush(1);

	# A daemon dropping us mid-write should surface as the read-side
	# "no reply" error, not a silent SIGPIPE death.
	local $SIG{PIPE} = 'IGNORE';

	return _command( $self, $opt ) if !defined $opt->{'i'};
	return _stream( $self, $opt );
} ## end sub execute

#-------------------------------------------------------------------------------
# wire helpers
#-------------------------------------------------------------------------------

sub _request {
	my ($msg) = @_;
	print {$SOCK} $JSON->encode($msg) . "\n";
	my $reply = _read_reply();
	die( 'no reply from the daemon within ' . $TIMEOUT . 's (or it closed the connection)' . "\n" )
		unless defined $reply;
	return $reply;
}

sub _read_reply {
	my $deadline = time + $TIMEOUT;
	my $sel      = IO::Select->new($SOCK);
	while ( $READ_BUF !~ /\n/ ) {
		my $left = $deadline - time;
		return undef if $left <= 0 || !$sel->can_read($left);
		my $got = sysread( $SOCK, my $chunk, 65536 );
		return undef unless $got;
		$READ_BUF .= $chunk;
	}
	$READ_BUF =~ s/\A([^\n]*)\n//;
	my $line  = $1;
	my $reply = eval { $JSON->decode($line) };
	die( 'daemon sent an unparseable reply: ' . $@ ) if $@;
	return { raw => $line, reply => $reply };
} ## end sub _read_reply

#-------------------------------------------------------------------------------
# command mode
#-------------------------------------------------------------------------------

sub _command {
	my ( $self, $opt ) = @_;

	my ($which) = grep { $opt->{$_} } qw(ping stats save relearn_threshold);
	( my $cmd = $which ) =~ tr/_/-/;

	my $got   = _request( { cmd => $cmd } );
	my $reply = $got->{reply};
	die( 'daemon error: ' . $reply->{error} . "\n" ) if defined $reply->{error};

	if ( $opt->{'json'} ) {
		print $got->{raw} . "\n";
		return 1;
	}

	my $ok = $reply->{ok};
	if ( ref $ok eq 'HASH' ) {
		for my $k ( sort keys %$ok ) {
			printf "  %-20s  %s\n", $k, ( defined $ok->{$k} ? $ok->{$k} : '(unset)' );
		}
	} else {
		print( ( defined $ok ? $ok : 'ok' ) . "\n" );
	}
	return 1;
} ## end sub _command

#-------------------------------------------------------------------------------
# stream mode
#-------------------------------------------------------------------------------

sub _stream {
	my ( $self, $opt ) = @_;

	my $in_fh;
	if ( $opt->{'i'} eq '-' ) {
		$in_fh = \*STDIN;
	} else {
		open( $in_fh, '<', $opt->{'i'} ) or die( 'failed to open -i, "' . $opt->{'i'} . '": ' . $! . "\n" );
	}

	# -o accumulates and writes atomically at the end (matching `iforest
	# stream`), so it is unsuitable for an endless stdin; without it,
	# results print as replies arrive.
	my $results = '';
	my $emit    = sub {
		if ( defined $opt->{'o'} ) { $results .= $_[0] . "\n" }
		else                       { print $_[0] . "\n" }
	};

	my $expected_cols;
	my @rows;               # decoded rows for the pending request
	my @raw;                # matching raw input lines, for -d
	my $batch_start = 1;    # input line number of $rows[0]
	my $line_int    = 0;

	my $flush = sub {
		return unless @rows;
		my $got   = _request( { rows => [@rows], mode => $opt->{'mode'}, tag => $batch_start } );
		my $reply = $got->{reply};
		if ( defined $reply->{error} ) {
			my $line = $batch_start;
			my $err  = $reply->{error};
			# Batch errors come back as "row N: ..." with N relative to
			# the message; map it back to the input line.
			if ( $err =~ s/\Arow (\d+): // ) {
				$line = $batch_start + $1;
			}
			die( 'line ' . $line . ' of input: ' . $err . "\n" );
		} ## end if ( defined $reply->{error} )
		if ( $opt->{'mode'} ne 'learn' ) {
			if ( $opt->{'jsonl'} ) {
				$emit->( $got->{raw} );
			} else {
				my $pairs = $reply->{scores};
				for my $i ( 0 .. $#$pairs ) {
					my $prefix = $opt->{'d'} ? $raw[$i] . ',' : '';
					$emit->( $prefix . $pairs->[$i][0] . ',' . $pairs->[$i][1] );
				}
			}
		} ## end if ( $opt->{'mode'} ne 'learn' )
		@rows        = ();
		@raw         = ();
		$batch_start = $line_int + 1;
	}; ## end $flush = sub

	while ( my $line = <$in_fh> ) {
		$line_int++;
		chomp $line;
		if ( $line =~ /^\s*$/ ) {
			$flush->();    # keep line-number accounting exact across blanks
			$batch_start = $line_int + 1;
			next;
		}

		if ( $opt->{'jsonl'} ) {
			my $row = eval { $JSON->decode($line) };
			die( 'line ' . $line_int . ' of -i did not parse as JSON: ' . $@ ) if $@;
			die( 'line ' . $line_int . ' of -i must be a JSON array (positional) or object (tagged)' . "\n" )
				unless ref $row eq 'ARRAY' || ref $row eq 'HASH';
			push @rows, $row;
		} else {
			my @fields = split( /,/, $line, -1 );
			if ( !defined $expected_cols ) {
				$expected_cols = scalar @fields;
				die( 'Line ' . $line_int . ' of input has no columns' ) if $expected_cols < 1;
			} elsif ( scalar @fields != $expected_cols ) {
				die(      'Line '
						. $line_int
						. ' of input has '
						. scalar(@fields)
						. ' columns but expected '
						. $expected_cols );
			}

			# Numeric-looking fields travel as JSON numbers, everything
			# else as strings for the daemon's munger plan to handle; the
			# daemon owns validation either way.
			push @rows, [ map { looks_like_number($_) ? 0 + $_ : $_ } @fields ];
			push @raw,  $line;
		} ## end else [ if ( $opt->{'jsonl'} ) ]

		$flush->() if scalar @rows >= $opt->{'batch'};
	} ## end while ( my $line = <$in_fh> )
	$flush->();

	if ( defined $opt->{'o'} ) {
		write_file( $opt->{'o'}, { 'atomic' => 1 }, $results );
	}
	return 1;
} ## end sub _stream

return 1;
