#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The sandbox row, the failures, and the launch cases of the traces
# verb (CLI-PROGRAM, CLI-CHECKOUT, CLI-SANDBOX, TRACE-NAME,
# TRACE-PANEL, TRACE-SUB).
#
# The row of traces is the first row of the table that unveils, so
# this test holds the two sides of that branch: the row of traces
# with its paths, and the row of version with none. Fugu::Sandbox
# changes nothing outside OpenBSD, so the test reads the arguments of
# the two calls. It replaces each call for the run, and it runs the
# program in process to reach them.
#
# The port of the Workspace test holds the columns of the verb, and
# it takes no assertion of its own (CLI-CONFORMANCE-1). So the cases
# that the port leaves open sit here: a launch of the reviewer type,
# and a sub-agent trace under a workflow directory.
#
# The failures run the program as a child, because a failure reports
# on standard error. The columns run as a child too, because _entered
# sends the standard output of the verb to a string. No test reads the
# operator home, and no test writes outside its temp tree.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin    qw($RealBin);
use JSON::PP   ();
use lib "$RealBin/../../lib";

use Fugu::Process;
use Fugu::Sandbox;

use App::FuguBench;
use App::FuguBench::Checkout;

my $root    = "$RealBin/../..";
my $program = "$root/bin/fugubench";
my $json    = JSON::PP->new->canonical;

# _checkout():
#	A temporary checkout: a directory with an empty .toolingrc.
#	The walk stops there, so no run reads the operator home
#	(CLI-CHECKOUT-2).
sub _checkout ()
{
	my $dir = tempdir( CLEANUP => 1 );
	open my $fh, '>', "$dir/.toolingrc" or die "write $dir: $!";
	close $fh;

	return $dir;
}

# _entered(@argv):
#	Run the program in process, with the two sandbox calls
#	replaced. The helper returns the exit code, the promise sets
#	of the run, and the unveil entries of the run. The result of
#	the verb goes to a string, so it stays out of the test
#	output.
sub _entered (@argv)
{
	my ( @promises, @paths );
	my $out = q{};
	my $code;

	{
		no warnings 'redefine';
		local *Fugu::Sandbox::pledge = sub ( $, %args ) {
			push @promises, $args{promises};
			return 1;
		};
		local *Fugu::Sandbox::unveil = sub ( $, %args ) {
			push @paths, @{ $args{paths} };
			return 1;
		};

		# A verb writes its result with say and printf, and
		# both take the selected handle.
		open my $fh, '>', \$out or die "capture: $!";
		my $old = select $fh;
		$code = App::FuguBench->new->run(@argv);
		select $old;
		close $fh;
	}

	return ( $code, \@promises, \@paths );
}

# _run($dir, @argv):
#	Run the program as a child in one directory, and return the
#	result of Fugu::Process->run.
sub _run ( $dir, @argv )
{
	my $result = Fugu::Process->run(
		cmd => [ $^X, "-I$root/lib", $program, @argv ],
		cwd => $dir,
	);
	die "cannot run $program: $result->{error}\n"
	    if defined $result->{error};

	return $result;
}

# _write($path, $text):
#	Write one file, and make its parent directories.
sub _write ( $path, $text )
{
	make_path( $path =~ s{/[^/]+\z}{}r );
	open my $fh, '>', $path or die "write $path: $!";
	print {$fh} $text;
	close $fh;
}

# _record($req, $in, $out, @blocks):
#	One assistant record of one request. The verb adds the three
#	input counts of the usage, and an absent count is a zero, so
#	$in holds the whole context of the request.
sub _record ( $req, $in, $out, @blocks )
{
	return $json->encode( {
			type      => 'assistant',
			timestamp => '2026-09-13T10:00:00.000Z',
			requestId => $req,
			message   => {
				role  => 'assistant',
				usage => {
					input_tokens  => $in,
					output_tokens => $out,
				},
				content => [@blocks],
			},
		} ) . "\n";
}

subtest 'the row of traces unveils its paths' => sub {
	my $dir   = _checkout();
	my $trace = "$dir/traces";
	make_path($trace);

	my ( $code, $promises, $paths ) =
	    _entered( '-C', $dir, 'traces', '--root', $trace );
	is( $code, 0, 'traces exits zero' );
	is_deeply( $promises, ['stdio rpath'],
		'the row pledges stdio rpath, with no network promise' );

	# The verb reads the trace root, and perl reads its library
	# directories. The verb resolves the real path of the checkout
	# root after the entry, so the row names that root too. It
	# names nothing else (CLI-SANDBOX-2).
	my @want = sort ( Fugu::Sandbox->perl_lib_dirs, $dir, $trace );
	my @got  = sort map { $_->[0] } @$paths;
	is_deeply( \@got, \@want, 'the row unveils those paths, and no other' );
	is_deeply(
		[ map { $_->[1] } @$paths ],
		[ ('r') x scalar @$paths ],
		'each path is read-only'
	);

	# The verb reports an absent trace root itself, and a required
	# entry would die in front of that report. The checkout root
	# exists, because the walk found a file in it.
	my %optional =
	    map { $_->[0] => ( $_->[2] // {} )->{optional} ? 1 : 0 } @$paths;
	is( $optional{$trace}, 1, 'the trace root is an optional entry' );
	is( $optional{$dir},   0, 'the checkout root is a required entry' );
};

subtest 'the row of traces names the checkout under --name' => sub {
	my $dir   = _checkout();
	my $trace = "$dir/traces";
	make_path($trace);

	# The option --name replaces the derived name, and it leaves
	# the edit boundary alone. That boundary comes from the
	# checkout, so the row names the checkout root in each run
	# (TRACE-PANEL-3).
	my ( $code, $promises, $paths ) = _entered( '-C', $dir, 'traces',
		'--root', $trace, '--name', 'fixture' );
	is( $code, 0, 'traces exits zero' );
	is_deeply( $promises, ['stdio rpath'], 'the row pledges stdio rpath' );

	my @want = sort ( Fugu::Sandbox->perl_lib_dirs, $dir, $trace );
	my @got  = sort map { $_->[0] } @$paths;
	is_deeply( \@got, \@want, 'the row unveils the checkout root too' );
};

subtest 'a row with no list unveils nothing' => sub {
	my ( $code, $promises, $paths ) = _entered('version');
	is( $code, 0, 'version exits zero' );
	is_deeply( $promises, ['stdio'], 'the row pledges stdio alone' );
	is_deeply( $paths,    [],        'the dispatcher calls no unveil' );
};

subtest 'a trace root that is no directory is a failure' => sub {
	my $dir = _checkout();

	my $r = _run( $root, '-C', $dir, 'traces', '--root',
		"$dir/nosuch", '--name', 'fixture' );
	is( $r->{exit_code}, 1, 'the verb exits 1' );
	like(
		$r->{stderr},
		qr/no such trace root: \Q$dir\E\/nosuch/,
		'the message holds the path'
	);
	is( $r->{stdout}, '', 'the verb writes nothing to standard output' );
};

subtest 'an argument is a usage error' => sub {
	my $dir = _checkout();

	my $r = _run( $root, '-C', $dir, 'traces', 'extra' );
	is( $r->{exit_code}, 2, 'the verb exits 2' );
	like(
		$r->{stderr},
		qr/^usage: fugubench traces /m,
		'the usage goes to standard error'
	);

	# The sandbox row reads the checkout in front of the verb, and
	# the walk fails under a start with no .toolingrc. The report
	# of that walk waits for the verb, so no configuration error
	# joins the usage (CLI-CHECKOUT-3).
	my $bare = tempdir( CLEANUP => 1 );
	ok(
		!defined App::FuguBench::Checkout->new( start => $bare ),
		'the temporary tree sits under no checkout'
	);

	my $b = _run( $root, '-C', $bare, 'traces', 'extra' );
	is( $b->{exit_code}, 2, 'a start under no .toolingrc exits 2 too' );
	like(
		$b->{stderr},
		qr/^usage: fugubench traces /m,
		'and the usage goes to standard error'
	);
	unlike( $b->{stderr}, qr/toolingrc/,
		'and no configuration error joins it' );
};

subtest 'a start under no .toolingrc reports one time' => sub {
	my $dir = tempdir( CLEANUP => 1 );
	ok(
		!defined App::FuguBench::Checkout->new( start => $dir ),
		'the temporary tree sits under no checkout'
	);

	# The sandbox row reads the checkout in front of the verb, so
	# the walk of a failure must not run a second time.
	#
	# The run names an absent trace root. The verb then reads no
	# operator home, and the configuration error of the walk comes
	# in front of that failure on every host (CLI-CHECKOUT-3).
	my $r = _run( $root, '-C', $dir, 'traces', '--root', "$dir/nosuch" );
	is( $r->{exit_code}, 3, 'the verb exits 3' );
	my @lines = grep { /no [.]toolingrc above/ } split /\n/, $r->{stderr};
	is( scalar @lines, 1, 'the walk reports the absent file one time' )
	    or diag $r->{stderr};
	like( $lines[0] // q{}, qr/\Q$dir\E/, 'the message names the start' );
};

subtest 'a reviewer launch and a sub-agent of a workflow' => sub {
	my $dir    = _checkout();
	my $traces = "$dir/traces";
	my $id     = '55555555-5555-5555-5555-555555555555';

	# The launch names the reviewer type, and its description
	# names no role. So the type alone makes the request a round
	# (TRACE-PANEL-1).
	_write(
		"$traces/fixture/$id.jsonl",
		_record(
			'req_1', 100, 10,
			{
				type  => 'tool_use',
				id    => 'toolu_rev',
				name  => 'Agent',
				input => {
					subagent_type => 'reviewer',
					description   => 'round 1 member A',
				},
			} ) );

	# The trace of that reviewer sits under a workflow directory,
	# which is where the harness keeps the sub-agents of a
	# workflow. The sub-agent columns hold every sub-agent
	# (TRACE-SUB-1), and the meta file names the launch, so
	# rev-peak takes the peak of this one (TRACE-SUB-2).
	my $flow = "$traces/fixture/$id/subagents/workflows/wf_1";
	_write( "$flow/agent-r1.jsonl",
		_record( 'req_r', 700, 30, { type => 'text', text => 'x' } ) );
	_write( "$flow/agent-r1.meta.json",
		$json->encode( { toolUseId => 'toolu_rev' } ) . "\n" );

	my $r = _run( $root, '-C', $dir, 'traces', '--root', $traces,
		'--name', 'fixture' );
	is( $r->{exit_code}, 0, 'the verb exits zero' );

	my ($line) = grep { /^55555555\b/ } split /\n/, $r->{stdout};
	ok( $line, 'the session gets a row' ) or diag $r->{stdout};

	my @field = split q{ }, $line // q{};
	is( $field[5], 1,   'a launch of the reviewer type is a round' );
	is( $field[7], 700, 'a sub-agent of a workflow joins sub-in' );
	is( $field[8], 30,  'and it joins sub-out' );
	is( $field[9], 700, 'and rev-peak takes its peak' );
};

done_testing();
