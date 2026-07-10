#!perl
# 91-streamd.t
#
# Integration test for `iforest streamd`: starts the daemon in the
# foreground in a forked child on a temp Unix socket and drives it over
# the JSON-lines protocol.  Covers startup artefacts (socket, pid file),
# the request kinds (row / rows / cmd) and modes, client-tag echo on
# success and error, per-message error isolation, multiple concurrent
# connections, command and interval saves with the latest.json symlink,
# clean SIGTERM shutdown, resume-from-latest, and (when
# Algorithm::ToNumberMunger is installed) raw munged values that CSV
# framing could never carry.
#
# Skipped on Windows (Unix sockets + fork) and without JSON::MaybeXS.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use IO::Select       ();
use IO::Socket::UNIX ();

my $bin = File::Spec->rel2abs('bin/iforest');
plan skip_all => 'bin/iforest not found' unless -x $bin;
plan skip_all => 'streamd needs Unix sockets and fork()' if $^O eq 'MSWin32';
plan skip_all => 'JSON::MaybeXS is not installed'
	unless eval { require JSON::MaybeXS; 1 };

my $JSON = JSON::MaybeXS->new( utf8 => 1 );

my $tmp    = tempdir( CLEANUP => 1 );
my $sock   = "$tmp/s.sock";
my $pidf   = "$tmp/s.pid";
my $mdir   = "$tmp/models";
my $logf   = "$tmp/streamd.log";
my $latest = "$mdir/latest.json";

# sun_path caps out around 104 bytes; a deep TMPDIR would make the whole
# run fail for reasons that have nothing to do with the daemon.
plan skip_all => 'temp socket path too long for a Unix socket'
	if length($sock) > 100;

my %BUF;         # per-connection read buffer, for line framing
my @ALL_PIDS;    # every daemon spawned, for the END sweep

# Fork+exec a daemon with the given argv and wait for its socket.
sub spawn_daemon {
	my ( $wait_sock, @argv ) = @_;
	my $pid = fork();
	die "fork failed: $!" unless defined $pid;
	if ( !$pid ) {
		open( STDOUT, '>>', $logf ) or die $!;
		open( STDERR, '>>', $logf ) or die $!;
		exec( $^X, '-Ilib', $bin, 'streamd', '-f', @argv ) or die "exec failed: $!";
	}
	push @ALL_PIDS, $pid;
	for ( 1 .. 100 ) {
		last if -S $wait_sock;
		select( undef, undef, undef, 0.1 );    ## no critic (ProhibitSleepViaSelect)
	}
	return $pid;
} ## end sub spawn_daemon

sub start_daemon {
	my (@extra) = @_;
	return spawn_daemon(
		$sock,
		'--socket'    => $sock,
		'--pid'       => $pidf,
		'--model-dir' => $mdir,
		'--log'       => $logf,
		@extra
	);
} ## end sub start_daemon

sub stop_daemon {
	my ($pid) = @_;
	kill( 'TERM', $pid );
	waitpid( $pid, 0 );
	return $? >> 8;
}

sub connect_client {
	my ($path) = @_;
	$path //= $sock;
	my $s = IO::Socket::UNIX->new( Peer => $path )
		or die "connect to $path failed: $!";
	$s->autoflush(1);
	$BUF{ fileno($s) } = '';
	return $s;
}

sub read_reply {
	my ( $s, $timeout ) = @_;
	$timeout //= 10;
	my $deadline = time + $timeout;
	my $sel      = IO::Select->new($s);
	my $buf      = \$BUF{ fileno($s) };
	while ( $$buf !~ /\n/ ) {
		my $left = $deadline - time;
		return undef if $left <= 0 || !$sel->can_read($left);
		my $got = sysread( $s, my $chunk, 65536 );
		return undef unless $got;
		$$buf .= $chunk;
	}
	$$buf =~ s/\A([^\n]*)\n//;
	return $JSON->decode($1);
} ## end sub read_reply

# One request in, one decoded reply out.
sub rt {
	my ( $s, $msg ) = @_;
	print {$s} $JSON->encode($msg) . "\n";
	return read_reply($s);
}

my $daemon = start_daemon(
	'--save-interval' => 1,
	'-n'              => 20,
	'--window'        => 64,
	'--eta'           => 8,
	'-s'              => 42,
	'-t'              => 'cpu',
	'-t'              => 'mem'
);

END {
	for my $pid (@ALL_PIDS) {
		kill( 'TERM', $pid ) if kill( 0, $pid );
	}
}

subtest 'startup artefacts' => sub {
	ok( -S $sock, 'socket exists' ) or diag( scalar `cat $logf` );
	ok( -f $pidf, 'pid file exists' );
	my $recorded = do { local ( @ARGV, $/ ) = ($pidf); <> };
	chomp $recorded;
	is( $recorded, $daemon, 'pid file records the daemon pid (foreground: the child)' );
};

my $c = connect_client();

subtest 'ping and client-tag echo' => sub {
	is_deeply( rt( $c, { cmd => 'ping' } ), { ok => 'pong' }, 'ping pongs, no tag when none sent' );
	is_deeply(
		rt( $c, { cmd => 'ping', tag => 'req-1' } ),
		{ ok => 'pong', tag => 'req-1' },
		'string tag echoed back'
	);
	is_deeply(
		rt( $c, { cmd => 'ping', tag => { batch => 7, src => [ 'a', 'b' ] } } ),
		{ ok => 'pong', tag => { batch => 7, src => [ 'a', 'b' ] } },
		'structured tag echoed back verbatim'
	);
}; ## end 'ping and client-tag echo' => sub

subtest 'learn, prequential, score modes' => sub {
	srand(5);
	my @warm = map { [ rand, rand ] } 1 .. 60;
	is_deeply(
		rt( $c, { rows => \@warm, mode => 'learn' } ),
		{ ok => { learned => 60 } },
		'rows batch in learn mode learns them all'
	);

	my $r = rt( $c, { row => [ 0.5, 0.5 ], tag => 'p1' } );
	is( $r->{tag}, 'p1', 'row reply carries the tag' );
	like( $r->{score}, qr/\A[\d.eE+-]+\z/, 'prequential row returns a numeric score' );
	ok( $r->{label} == 0 || $r->{label} == 1, 'and a 0/1 label' );

	my $stats = rt( $c, { cmd => 'stats' } );
	is( $stats->{ok}{seen},       61, 'prequential row was learned (seen=61)' );
	is( $stats->{ok}{n_features}, 2,  'stats reports n_features' );

	rt( $c, { row => [ 0.5, 0.5 ], mode => 'score' } );
	is( rt( $c, { cmd => 'stats' } )->{ok}{seen}, 61, 'score mode does not advance the model' );

	my $batch = rt( $c, { rows => [ [ 0.4, 0.4 ], [ 0.6, 0.6 ] ], mode => 'score' } );
	is( scalar @{ $batch->{scores} },    2, 'rows batch returns one [score,label] pair per row' );
	is( scalar @{ $batch->{scores}[0] }, 2, 'pairs have two elements' );

	my $tagged     = rt( $c, { row => { cpu => 0.5, mem => 0.5 }, mode => 'score' } );
	my $positional = rt( $c, { row => [ 0.5, 0.5 ], mode => 'score' } );
	cmp_ok( abs( $tagged->{score} - $positional->{score} ),
		'<', 1e-12, 'tagged (object) row form scores like the positional form' );
}; ## end 'learn, prequential, score modes' => sub

subtest 'errors are per-message and carry the tag' => sub {
	print {$c} "this is not json\n";
	like( read_reply($c)->{error}, qr/not a JSON object/, 'unparseable line gets an error reply' );

	my $r = rt( $c, { row => [ 1, 2, 3 ], tag => 'w1' } );
	like( $r->{error}, qr/3 features but model expects 2/, 'wrong-width row errors' );
	is( $r->{tag}, 'w1', 'error reply carries the tag' );

	like(
		rt( $c, { row => { cpu => 1 } } )->{error},
		qr/missing feature name/,
		'tagged row missing a feature errors'
	);
	like(
		rt( $c, { row => [ 1, 'not a number' ], tag => 'n1' } )->{error},
		qr/not a number after munging/,
		'non-numeric cell errors'
	);
	like( rt( $c, { row => [ 1, 2 ], cmd => 'ping' } )->{error}, qr/exactly one of/,
		'row and cmd together errors' );
	like( rt( $c, { cmd => 'frobnicate' } )->{error},          qr/unknown cmd/,  'unknown cmd errors' );
	like( rt( $c, { row => [ 1, 2 ], mode => 'x' } )->{error}, qr/mode must be/, 'bad mode errors' );

	is_deeply( rt( $c, { cmd => 'ping' } ), { ok => 'pong' }, 'connection is alive after all of it' );
}; ## end 'errors are per-message and carry the tag' => sub

subtest 'multiple concurrent connections' => sub {
	my $c2 = connect_client();
	is( rt( $c2, { cmd => 'stats' } )->{ok}{connections}, 2, 'stats sees both connections' );

	# Per-connection mode: c2 goes learn-only, c stays prequential.
	is_deeply( rt( $c2, { cmd => 'mode', mode => 'learn' } ), { ok => { mode => 'learn' } }, 'mode command' );
	is_deeply( rt( $c2, { row => [ 0.3, 0.3 ] } ), { ok => { learned => 1 } },
		'c2 rows now learn without scoring' );
	ok( defined rt( $c, { row => [ 0.3, 0.3 ] } )->{score}, 'c still gets scores' );

	close $c2;
	# Give the daemon a beat to notice the close.
	select( undef, undef, undef, 0.3 );    ## no critic (ProhibitSleepViaSelect)
	is( rt( $c, { cmd => 'stats' } )->{ok}{connections}, 1, 'closed connection is reaped' );
}; ## end 'multiple concurrent connections' => sub

subtest 'saves: command, interval, symlink' => sub {
	my $r = rt( $c, { cmd => 'save', tag => 's1' } );
	like( $r->{ok}{saved}, qr/\Aoiforest-\d{8}-\d{6}(?:-\d+)?\.json\z/, 'save returns the file name' );
	is( $r->{tag}, 's1', 'save reply carries the tag' );
	ok( -f "$mdir/$r->{ok}{saved}", 'the timestamped file exists' );
	ok( -l $latest,                 'latest.json is a symlink' );
	is( readlink($latest), $r->{ok}{saved}, 'and points at the newest save (relative target)' );

	# Interval saves happen only after learning; learn then wait past the
	# 1s interval.
	my $count_before = () = glob("$mdir/oiforest-*.json");
	rt( $c, { row => [ 0.2, 0.8 ] } );
	select( undef, undef, undef, 2.5 );    ## no critic (ProhibitSleepViaSelect)
	rt( $c, { cmd => 'ping' } );           # tick the loop
	my $count_after = () = glob("$mdir/oiforest-*.json");
	cmp_ok( $count_after, '>', $count_before, 'a periodic save fired after learning' );
}; ## end 'saves: command, interval, symlink' => sub

my $seen_at_shutdown = rt( $c, { cmd => 'stats' } )->{ok}{seen};

subtest 'clean shutdown and resume' => sub {
	is( stop_daemon($daemon), 0, 'SIGTERM exits 0' );
	undef $daemon;
	ok( !-e $sock, 'socket removed' );
	ok( !-e $pidf, 'pid file removed' );

	# latest.json is a complete model; the parent class loads it and it
	# carries everything learned (the shutdown save flushed the tail).
	require Algorithm::Classifier::IsolationForest;
	my $m = Algorithm::Classifier::IsolationForest->load($latest);
	isa_ok( $m, 'Algorithm::Classifier::IsolationForest::Online', 'latest.json' );
	is( $m->seen, $seen_at_shutdown, 'shutdown save captured everything learned' );

	# Restart with no creation knobs: resumes from latest.json.
	$daemon = start_daemon( '--save-interval' => 60 );
	my $c3 = connect_client();
	is( rt( $c3, { cmd => 'stats' } )->{ok}{seen}, $seen_at_shutdown, 'restart resumed from latest.json' );
	close $c3;
	is( stop_daemon($daemon), 0, 'second daemon exits 0' );
	undef $daemon;
}; ## end 'clean shutdown and resume' => sub

subtest 'raw munged values that CSV could never carry' => sub {
	plan skip_all => 'Algorithm::ToNumberMunger is not installed'
		unless eval { require Algorithm::ToNumberMunger; 1 };

	# A munged online model via a prototype, in its own model dir.
	my $mdir2 = "$tmp/models2";
	my $proto = "$tmp/proto.json";
	{
		open my $fh, '>', $proto or die $!;
		print {$fh} $JSON->encode(
			{
				format             => 'Algorithm::Classifier::IsolationForest::Prototype',
				class              => 'online',
				schema_version     => 'd1',
				schema_description => 'streamd munger test',
				schema             => {
					feature_names => [ 'method', 'path_len' ],
					mungers       => {
						method   => { munger => 'http_method_enum', default => -1 },
						path_len => { munger => 'length',           from    => 'path' },
					},
				},
				params => { n_trees => 20, window_size => 64, max_leaf_samples => 8 },
			}
		);
		close $fh;
	}

	$daemon = start_daemon(
		'--save-interval' => 60,
		'--model-dir'     => $mdir2,
		'-s'              => 7,
		'--prototype'     => $proto
	);
	my $c4 = connect_client();

	# Raw values with embedded commas, quotes, newline escapes, and
	# unicode -- the reason the protocol is JSON.
	my @raw = map { { method => 'GET', path => '/a,b/"c"/' . ( 'p' x ( 3 + $_ % 15 ) ) . "\x{2603}" } } 1 .. 60;
	is_deeply(
		rt( $c4, { rows => \@raw, mode => 'learn' } ),
		{ ok => { learned => 60 } },
		'raw tagged rows with hostile content learn cleanly'
	);
	my $r = rt( $c4, { row => { method => 'BREW', path => '/' . ( 'a' x 90 ) . ',oh no' }, tag => "t,\x{2603}" } );
	like( $r->{score}, qr/\A[\d.eE+-]+\z/, 'raw anomalous row scores' );
	is( $r->{tag}, "t,\x{2603}", 'unicode/comma tag round-trips' );

	close $c4;
	is( stop_daemon($daemon), 0, 'munged daemon exits 0' );
	undef $daemon;
}; ## end 'raw munged values that CSV could never carry' => sub

subtest '--set runs named instances side by side' => sub {
	my $sdir  = "$tmp/sets";
	my @knobs = ( '--save-interval' => 60, '-n' => 10, '--window' => 64, '--eta' => 8 );
	my $alpha = spawn_daemon(
		"$tmp/alpha.sock",
		'--set'       => 'alpha',
		'--socket'    => $tmp,
		'--pid'       => $tmp,
		'--model-dir' => $sdir,
		'-s'          => 1,
		@knobs
	);
	my $beta = spawn_daemon(
		"$tmp/beta.sock",
		'--set'       => 'beta',
		'--socket'    => $tmp,
		'--pid'       => $tmp,
		'--model-dir' => $sdir,
		'-s'          => 2,
		@knobs
	);

	ok( -S "$tmp/alpha.sock", 'set alpha listens on <rundir>/alpha.sock' ) or diag( scalar `cat $logf` );
	ok( -f "$tmp/alpha.pid",  'and writes <rundir>/alpha.pid' );
	ok( -S "$tmp/beta.sock",  'set beta listens on <rundir>/beta.sock' );

	my $ca = connect_client("$tmp/alpha.sock");
	my $cb = connect_client("$tmp/beta.sock");
	srand(6);
	rt( $ca, { rows => [ map { [ rand, rand ] } 1 .. 30 ], mode => 'learn' } );
	rt( $cb, { rows => [ map { [ rand, rand ] } 1 .. 5 ],  mode => 'learn' } );

	my $sa = rt( $ca, { cmd => 'stats' } );
	my $sb = rt( $cb, { cmd => 'stats' } );
	is( $sa->{ok}{set},  'alpha', 'stats reports the set name' );
	is( $sa->{ok}{seen}, 30,      'alpha learned its own stream' );
	is( $sb->{ok}{set},  'beta',  'beta reports its set name' );
	is( $sb->{ok}{seen}, 5,       'beta is independent of alpha' );

	my $saved = rt( $ca, { cmd => 'save' } )->{ok}{saved};
	ok( -f "$sdir/alpha/$saved", 'saves land under <model-dir>/<set>/' );
	is( readlink("$sdir/alpha/latest.json"), $saved, 'the set has its own latest.json symlink' );
	ok( !-e "$sdir/beta/$saved", 'and beta did not get alpha\'s save' );

	close $ca;
	close $cb;
	is( stop_daemon($alpha), 0, 'alpha exits 0' );
	is( stop_daemon($beta),  0, 'beta exits 0' );
	ok( !-e "$tmp/alpha.sock" && !-e "$tmp/alpha.pid", 'alpha cleaned up its socket and pid' );

	# Set names that could mangle paths are refused before anything runs.
	for my $bad ( 'bad/name', 'a.b', '..' ) {
		my $quoted = quotemeta $bad;
		my $out    = `$^X -Ilib $bin streamd -f --set $quoted 2>&1`;
		isnt( $?, 0, "--set '$bad' exits non-zero" );
		like( $out, qr/--set/, 'the error names the flag' );
	}
}; ## end '--set runs named instances side by side' => sub

subtest 'default directories refused when not writable' => sub {
	plan skip_all => 'running as root; the /var defaults would work'
		if $> == 0;
	plan skip_all => '/var/db/iforest_streamd is creatable here; nothing to refuse'
		if -w '/var/db/iforest_streamd' || ( !-e '/var/db/iforest_streamd' && -w '/var/db' );

	my $out = `$^X -Ilib $bin streamd -f 2>&1`;
	isnt( $?, 0, 'streamd with unwritable default dirs exits non-zero' );
	like( $out, qr/--model-dir/, 'the error names the flag to override' );
}; ## end 'default directories refused when not writable' => sub

done_testing;
