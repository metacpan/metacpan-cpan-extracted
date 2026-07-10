#!/usr/bin/perl
# benchmarking/bench-streamd.pl
#
# Benchmarks `iforest streamd` end to end: the script spawns its own
# daemon on a temp Unix socket and pumps rows through the JSON-lines
# protocol, measuring points/second wall-clock at the client.
#
# Sections:
#   1. in-process baseline -- score_learn on an identical model in this
#      process; the ceiling everything else is measured against.  The
#      gap between it and the socket numbers is protocol + JSON + IPC
#      overhead, not model work.
#   2. batch-size sweep    -- prequential rows per {"rows": [...]}
#      message; directly informs streamc's --batch choice.
#   3. modes               -- prequential vs score vs learn at a fixed
#      batch size.
#   4. row forms           -- positional arrays vs tagged objects (the
#      tagged form pays hashref building + tagged_row_to_array).
#   5. concurrent clients  -- total throughput with 1/2/4 connections
#      pumping at once.  The daemon is a single select loop sharing one
#      model, so this should stay ~flat: it measures fairness overhead,
#      not parallel speedup.
#   6. command latency     -- ping round trips (pure protocol floor)
#      and the wall cost of an on-demand save.
#
# Reference numbers (2026-07-08, 8-core dev box, C backend,
# Cpanel::JSON::XS, 100 trees, window 2048, eta 32, 5 features):
# in-process score_learn ~2,770 pts/s; over the socket ~2,700 pts/s at
# any batch >= 16 (~2% overhead) and ~2,500 pts/s even at batch 1;
# score mode ~29,000 pts/s (no learning -- the tree walk is cheap, the
# learn is what costs); tagged objects ~21,000 vs positional ~30,000 in
# score mode; throughput is flat across 1/2/4 concurrent clients (one
# shared model, one loop -- by design); ping ~29,000 round trips/s;
# save ~140 ms.  The wire is nowhere near the bottleneck -- the model
# is.
#
# Run with:
#   perl -Ilib benchmarking/bench-streamd.pl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin";
use BenchAccel                                     qw(wall_rate wall_time_median);
use Time::HiRes                                    qw(time);
use File::Temp                                     qw(tempdir);
use IO::Select                                     ();
use IO::Socket::UNIX                               ();
use POSIX                                          ();
use Algorithm::Classifier::IsolationForest::Online ();

eval { require JSON::MaybeXS; 1 }
	or die "this benchmark needs JSON::MaybeXS (streamd's wire protocol): $@";
my $JSON = JSON::MaybeXS->new( utf8 => 1 );

use constant PI => 3.14159265358979;

sub gaussian {
	my ( $mu, $sigma ) = @_;
	return $mu + $sigma * sqrt( -2 * log( rand() || 1e-12 ) ) * cos( 2 * PI * rand() );
}

sub make_data {
	my ( $n, $nf ) = @_;
	return [
		map {
			[ map { gaussian( 0, 1 ) } 1 .. $nf ]
		} 1 .. $n
	];
}

# --- model shape (matches bench-online-score-accel.pl) -------------------
my $N_TREES = 100;
my $WINDOW  = 2048;
my $ETA     = 32;
my $NF      = 5;
my @TAGS    = map { "f$_" } 0 .. $NF - 1;

# --- spawn the daemon -----------------------------------------------------
my $bin = "$FindBin::Bin/../src_bin/iforest";
die "cannot find $bin\n" unless -f $bin;

my $tmp  = tempdir( CLEANUP => 1 );
my $sock = "$tmp/b.sock";
die "temp socket path too long for a Unix socket ($sock)\n" if length($sock) > 100;

my $daemon = fork();
die "fork failed: $!" unless defined $daemon;
if ( !$daemon ) {
	open( STDOUT, '>>', "$tmp/streamd.log" ) or die $!;
	open( STDERR, '>>', "$tmp/streamd.log" ) or die $!;
	exec(
		$^X, "-I$FindBin::Bin/../lib", $bin, 'streamd', '-f',
		'--socket'        => $sock,
		'--pid'           => "$tmp/b.pid",
		'--model-dir'     => "$tmp/models",
		'--save-interval' => 3600,            # no interval saves mid-benchmark
		'-n'              => $N_TREES,
		'--window'        => $WINDOW,
		'--eta'           => $ETA,
		'-s'              => 42,
		( map { ( '-t' => $_ ) } @TAGS ),
	) or die "exec failed: $!";
} ## end if ( !$daemon )
for ( 1 .. 100 ) {
	last if -S $sock;
	select( undef, undef, undef, 0.1 );    ## no critic (ProhibitSleepViaSelect)
}
die "daemon never came up; see $tmp/streamd.log\n" unless -S $sock;

END {
	kill( 'TERM', $daemon ) if $daemon && kill( 0, $daemon );
}

# --- wire helpers ----------------------------------------------------------
my %BUF;

sub connect_daemon {
	my $s = IO::Socket::UNIX->new( Peer => $sock ) or die "connect failed: $!";
	$s->autoflush(1);
	$BUF{ fileno($s) } = '';
	return $s;
}

sub rt {
	my ( $s, $msg ) = @_;
	print {$s} $JSON->encode($msg) . "\n";
	my $buf = \$BUF{ fileno($s) };
	my $sel = IO::Select->new($s);
	while ( $$buf !~ /\n/ ) {
		die "no reply from the daemon\n" unless $sel->can_read(30);
		my $got = sysread( $s, my $chunk, 262144 );
		die "daemon closed the connection\n" unless $got;
		$$buf .= $chunk;
	}
	$$buf =~ s/\A([^\n]*)\n//;
	my $reply = $JSON->decode($1);
	die "daemon error: $reply->{error}\n" if defined $reply->{error};
	return $reply;
} ## end sub rt

# Pump rows through in lockstep batches; returns elapsed seconds.
sub pump {
	my ( $s, $rows, $batch, $mode ) = @_;
	my $n  = scalar @$rows;
	my $t0 = time;
	my $i  = 0;
	while ( $i < $n ) {
		my $end = $i + $batch - 1;
		$end = $n - 1 if $end > $n - 1;
		rt( $s, { rows => [ @{$rows}[ $i .. $end ] ], mode => $mode } );
		$i = $end + 1;
	}
	return time - $t0;
} ## end sub pump

sub report {
	my ( $label, $n, $elapsed ) = @_;
	printf "  %-34s  %10.0f pts/s  (%d rows in %.2fs)\n", $label, $n / $elapsed, $n, $elapsed;
	return;
}

print "=" x 70, "\n";
print " streamd end-to-end benchmarks (JSON lines over a Unix socket)\n";
print "=" x 70, "\n";
printf " %d trees, window %d, eta %d, %d features; JSON backend: %s\n",
	$N_TREES, $WINDOW, $ETA, $NF, JSON::MaybeXS::JSON();
print " (points/second wall-clock at the client; higher is faster)\n";

# Warm both the daemon and the baseline model past the window size so
# every section measures steady-state, full-window work.
srand(42);
my $warm = make_data( 3000, $NF );
srand(43);
my $feed = make_data( 60000, $NF );

my $c = connect_daemon();
pump( $c, $warm, 500, 'learn' );

# -----------------------------------------------------------------------
# 1. In-process baseline: the same stream loop without the wire
# -----------------------------------------------------------------------
print "\n--- 1. in-process score_learn baseline (no socket, no JSON) ---\n";
my $base = Algorithm::Classifier::IsolationForest::Online->new(
	n_trees          => $N_TREES,
	window_size      => $WINDOW,
	max_leaf_samples => $ETA,
	seed             => 42,
);
$base->learn($warm);
{
	my @rows    = @{$feed}[ 0 .. 9999 ];
	my $t0      = time;
	my $s       = $base->score_learn( \@rows );
	my $elapsed = time - $t0;
	report( 'score_learn, one 10k-row call', scalar @rows, $elapsed );
}

# Successive slices of the feed, wrapping around; prequential learning
# mutates the window anyway, so reuse costs nothing.
my $off = 0;

sub take {
	my ($n) = @_;
	$off = 0 if $off + $n > scalar @$feed;
	my @rows = @{$feed}[ $off .. $off + $n - 1 ];
	$off += $n;
	return \@rows;
}

# -----------------------------------------------------------------------
# 2. Batch-size sweep (prequential over the socket)
# -----------------------------------------------------------------------
print "\n--- 2. batch-size sweep, prequential over the socket ---\n";
for my $batch ( 1, 16, 64, 256, 1024 ) {
	my $n       = $batch == 1 ? 3000 : 8000;
	my $rows    = take($n);
	my $elapsed = pump( $c, $rows, $batch, 'prequential' );
	report( "batch $batch", $n, $elapsed );
}

# -----------------------------------------------------------------------
# 3. Modes at a fixed batch size
# -----------------------------------------------------------------------
print "\n--- 3. modes, batch 256 ---\n";
for my $mode (qw(prequential learn score)) {
	my $n       = 8000;
	my $rows    = take($n);
	my $elapsed = pump( $c, $rows, 256, $mode );
	report( $mode, $n, $elapsed );
}

# -----------------------------------------------------------------------
# 4. Row forms: positional arrays vs tagged objects
# -----------------------------------------------------------------------
print "\n--- 4. row forms, batch 256, score mode ---\n";
{
	my $n   = 8000;
	my @pos = @{$feed}[ 0 .. $n - 1 ];
	my @tag_rows;
	for my $r (@pos) {
		my %row;
		@row{@TAGS} = @$r;
		push @tag_rows, \%row;
	}
	report( 'positional (arrays)', $n, pump( $c, \@pos,      256, 'score' ) );
	report( 'tagged (objects)',    $n, pump( $c, \@tag_rows, 256, 'score' ) );
}

# -----------------------------------------------------------------------
# 5. Concurrent clients (shared model, single event loop)
# -----------------------------------------------------------------------
print "\n--- 5. concurrent clients, batch 256, prequential ---\n";
for my $n_clients ( 1, 2, 4 ) {
	my $n_total = 8000;
	my $per     = int( $n_total / $n_clients );
	my @rows    = @{ take($n_total) };

	my $t0 = time;
	my @pids;
	for my $i ( 1 .. $n_clients ) {
		my $pid = fork();
		die "fork failed: $!" unless defined $pid;
		if ( !$pid ) {
			# _exit so the child never runs the END block that TERMs
			# the daemon.
			my $s     = connect_daemon();
			my @slice = @rows[ ( $i - 1 ) * $per .. $i * $per - 1 ];
			pump( $s, \@slice, 256, 'prequential' );
			POSIX::_exit(0);
		}
		push @pids, $pid;
	} ## end for my $i ( 1 .. $n_clients )
	waitpid( $_, 0 ) for @pids;
	report( "$n_clients client(s)", $per * $n_clients, time - $t0 );
} ## end for my $n_clients ( 1, 2, 4 )

# -----------------------------------------------------------------------
# 6. Command latency
# -----------------------------------------------------------------------
print "\n--- 6. command latency ---\n";
{
	my $rate = wall_rate( sub { rt( $c, { cmd => 'ping' } ) }, 1 );
	printf "  %-34s  %10.0f round trips/s\n", 'ping (protocol floor)', $rate;

	my $save_t = wall_time_median( sub { rt( $c, { cmd => 'save' } ) }, 3 );
	printf "  %-34s  %10.1f ms  (window %d, %d trees)\n", 'save (on demand)', $save_t * 1000, $WINDOW, $N_TREES;
}

print "\ndone\n";
