#!perl
# 92-streamc.t
#
# Integration test for `iforest streamc`: spawns a streamd daemon (as
# t/91 does) and drives it through the real streamc CLI in a
# subprocess.  Covers command mode (--ping/--stats/--save, exit codes,
# --json), CSV stream mode in all three --mode settings with -d,
# --jsonl tagged rows, client- and daemon-side error attribution by
# input line, --set socket resolution, and connect-failure behaviour.
#
# Skipped on Windows (Unix sockets + fork) and without JSON::MaybeXS.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

my $bin = File::Spec->rel2abs('bin/iforest');
plan skip_all => 'bin/iforest not found' unless -x $bin;
plan skip_all => 'streamc needs Unix sockets and fork()' if $^O eq 'MSWin32';
plan skip_all => 'JSON::MaybeXS is not installed'
	unless eval { require JSON::MaybeXS; 1 };

my $JSON = JSON::MaybeXS->new( utf8 => 1 );

my $tmp  = tempdir( CLEANUP => 1 );
my $mdir = "$tmp/models";
my $logf = "$tmp/streamd.log";

plan skip_all => 'temp socket path too long for a Unix socket'
	if length("$tmp/alpha.sock") > 100;

my @ALL_PIDS;

END {
	for my $pid (@ALL_PIDS) {
		kill( 'TERM', $pid ) if kill( 0, $pid );
	}
}

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

# The daemon under test: a named set, so streamc's --set resolution is
# exercised by every call.
my $daemon = spawn_daemon(
	"$tmp/alpha.sock",
	'--set'           => 'alpha',
	'--socket'        => $tmp,
	'--pid'           => $tmp,
	'--model-dir'     => $mdir,
	'--save-interval' => 60,
	'-n'              => 20,
	'--window'        => 64,
	'--eta'           => 8,
	'-s'              => 42,
	'-t'              => 'cpu',
	'-t'              => 'mem'
);
ok( -S "$tmp/alpha.sock", 'daemon is up' ) or diag( scalar `cat $logf` );

my $sc = "$^X -Ilib $bin streamc --set alpha --socket $tmp";

# Fixture CSVs.
my $warm_csv = "$tmp/warm.csv";
my $q_csv    = "$tmp/q.csv";
my $bad_csv  = "$tmp/bad.csv";
{
	open my $fh, '>', $warm_csv or die $!;
	srand(3);
	printf {$fh} "%.4f,%.4f\n", rand, rand for 1 .. 60;
	close $fh;
}
{
	open my $fh, '>', $q_csv or die $!;
	srand(4);
	printf {$fh} "%.4f,%.4f\n", rand, rand for 1 .. 5;
	close $fh;
}
{
	open my $fh, '>', $bad_csv or die $!;
	print {$fh} "0.1,0.2\n0.3,0.4\n0.5,0.6,0.7\n";
	close $fh;
}

subtest 'command mode: ping, stats, --json, exit codes' => sub {
	my $out = `$sc --ping 2>&1`;
	is( $?, 0, '--ping exits 0' ) or diag $out;
	like( $out, qr/\Apong\n\z/, 'and says pong' );

	$out = `$sc --ping --json 2>&1`;
	my $obj = eval { $JSON->decode($out) };
	ok( !$@, '--json output parses' ) or diag $out;
	is( $obj->{ok}, 'pong', 'raw reply carried through' );

	$out = `$sc --stats 2>&1`;
	is( $?, 0, '--stats exits 0' );
	like( $out, qr/^\s+set\s+alpha$/m, 'stats renders the set' );
	like( $out, qr/^\s+seen\s+0$/m,    'nothing learned yet' );

	$out = `$sc --ping --stats 2>&1`;
	isnt( $?, 0, 'two command flags are refused' );
	$out = `$sc 2>&1`;
	isnt( $?, 0, 'no mode at all is refused' );
	$out = `$sc --relearn-threshold 2>&1`;
	isnt( $?, 0, 'relearn-threshold without contamination propagates the daemon error' );
	like( $out, qr/contamination/, 'and names the cause' );
}; ## end 'command mode: ping, stats, --json, exit codes' => sub

subtest 'CSV stream mode: learn, prequential, score, -d' => sub {
	my $out = `$sc -i $warm_csv --mode learn 2>&1`;
	is( $?,   0,  '--mode learn exits 0' ) or diag $out;
	is( $out, '', 'and emits nothing' );
	like( `$sc --stats`, qr/^\s+seen\s+60$/m, 'the daemon learned all 60 rows' );

	$out = `$sc -i $q_csv 2>&1`;
	is( $?, 0, 'prequential stream exits 0' );
	my @lines = split /\n/, $out;
	is( scalar @lines, 5, 'one output row per input row' );
	like( $lines[0],     qr/\A[\d.eE+-]+,[01]\z/, 'rows match "score,label"' );
	like( `$sc --stats`, qr/^\s+seen\s+65$/m,     'prequential rows were learned' );

	$out = `$sc -i $q_csv --mode score -d 2>&1`;
	is( $?, 0, 'score mode with -d exits 0' );
	my @f = split /,/, ( split /\n/, $out )[0];
	is( scalar @f, 4, '-d output has 2 features + score + label' );
	like( `$sc --stats`, qr/^\s+seen\s+65$/m, 'score mode did not advance the model' );

	# --batch 2 over 5 rows exercises partial-batch flush and ordering.
	my $batched = `$sc -i $q_csv --mode score --batch 2 2>&1`;
	my $whole   = `$sc -i $q_csv --mode score 2>&1`;
	is( $batched, $whole, 'batch size does not change the output' );

	# -o writes the same thing to a file.
	my $out_csv = "$tmp/scores.csv";
	`$sc -i $q_csv --mode score -o $out_csv 2>&1`;
	is(
		scalar(
			do { local ( @ARGV, $/ ) = ($out_csv); <> }
		),
		$whole,
		'-o file matches stdout output'
	);
}; ## end 'CSV stream mode: learn, prequential, score, -d' => sub

subtest 'jsonl stream mode: tagged rows, verbatim replies' => sub {
	my $jsonl = "$tmp/rows.jsonl";
	{
		open my $fh, '>', $jsonl or die $!;
		print {$fh} '{"cpu":0.5,"mem":0.5}' . "\n" . '{"cpu":9,"mem":9}' . "\n";
		close $fh;
	}
	my $out = `$sc -i $jsonl --jsonl --batch 1 --mode score 2>&1`;
	is( $?, 0, 'jsonl stream exits 0' ) or diag $out;
	my @lines = split /\n/, $out;
	is( scalar @lines, 2, 'one reply line per row at --batch 1' );
	my $r = $JSON->decode( $lines[1] );
	like( $r->{scores}[0][0], qr/\A[\d.eE+-]+\z/, 'replies are the daemon JSON, verbatim' );

	$out = `$sc -i $jsonl --jsonl -d 2>&1`;
	isnt( $?, 0, '-d with --jsonl is refused' );
}; ## end 'jsonl stream mode: tagged rows, verbatim replies' => sub

subtest 'errors are attributed to the input line' => sub {
	my $out = `$sc -i $bad_csv --mode score 2>&1`;
	isnt( $?, 0, 'a ragged CSV exits non-zero' );
	like( $out, qr/Line 3 of input has 3 columns but expected 2/, 'client-side check names line 3' );

	my $jsonl = "$tmp/badrows.jsonl";
	{
		open my $fh, '>', $jsonl or die $!;
		print {$fh} '{"cpu":1,"mem":2}' . "\n" . '{"cpu":1}' . "\n";
		close $fh;
	}
	$out = `$sc -i $jsonl --jsonl --mode score 2>&1`;
	isnt( $?, 0, 'a daemon-rejected row exits non-zero' );
	like( $out, qr/line 2 of input: missing feature name/, 'daemon error mapped back to input line 2' );

	like( `$sc --ping`, qr/pong/, 'the daemon survived all of it' );
}; ## end 'errors are attributed to the input line' => sub

subtest 'connect failure and timeouts' => sub {
	my $out = `$^X -Ilib $bin streamc --socket $tmp/nope.sock --ping 2>&1`;
	isnt( $?, 0, 'missing socket exits non-zero' );
	like( $out, qr/is streamd running/, 'error hints at the cause' );

	$out = `$^X -Ilib $bin streamc --set 'bad/name' --ping 2>&1`;
	isnt( $?, 0, 'invalid set name is refused' );
	like( $out, qr/--set/, 'and names the flag' );
};

subtest 'save through the client' => sub {
	my $out = `$sc --save 2>&1`;
	is( $?, 0, '--save exits 0' );
	like( $out, qr/^\s+saved\s+(oiforest-\S+\.json)$/m, 'prints the saved file name' );
	my ($name) = $out =~ /saved\s+(\S+)/;
	ok( -f "$mdir/alpha/$name", 'the file exists under the set model dir' );
};

kill( 'TERM', $daemon );
waitpid( $daemon, 0 );

done_testing;
