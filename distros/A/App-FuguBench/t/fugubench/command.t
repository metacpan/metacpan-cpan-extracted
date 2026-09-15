#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The child command of the dispatcher: the trace line of --verbose,
# the pass-through of the standard error of the child, and the three
# failures that set error (CLI-PROGRAM-4, CLI-PROGRAM-6,
# CLI-PROGRAM-7).
#
# The method runs in the process of the test, so each case captures
# the standard error of the test itself. The capture swaps the
# descriptor, because the logger and the pass-through write to two
# different handles of it.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use File::Temp qw(tempdir);
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";

use Fugu::File;

use App::FuguBench;

my $dir  = tempdir( CLEANUP => 1 );
my $file = "$dir/stderr.txt";

# _stderr($code):
#	Run the code with the standard error of the process on a file.
#	The method returns the text of the file and the value of the
#	code, in that order.
sub _stderr ($code)
{
	open my $saved, '>&', \*STDERR or die "cannot save stderr: $!\n";
	open STDERR, '>', $file or die "cannot redirect stderr: $!\n";

	my $value = $code->();

	open STDERR, '>&', $saved or die "cannot restore stderr: $!\n";
	close $saved;

	return ( Fugu::File->read($file) // q{}, $value );
}

# The dispatcher of the trace, and the silent one beside it. No verb
# of this change runs a child, so the loud one takes --verbose from a
# command line of its own. run parses the global options before it
# looks for the verb, so a line with an unknown verb stores the
# option, enters no sandbox, and writes to standard error alone. The
# test drops that usage text.
my $loud  = App::FuguBench->new;
my $quiet = App::FuguBench->new;

my ( undef, $code ) =
    _stderr( sub { return $loud->run( '--verbose', 'nosuchverb' ) } );
is( $code, 2, 'the line of the unknown verb exits 2' );
is(
	$loud->cli->option('verbose'), 1,
	'--verbose of the command line reaches the dispatcher'
);

# --verbose traces the command line, before the child runs
{
	my @cmd = ( $^X, '-e', 'print "one"' );
	my $line = join q{ }, @cmd;

	my ( $err, $out ) = _stderr( sub { return $loud->command( \@cmd ) } );
	is( $out, 'one', 'command returns the standard output of the child' );
	like( $err, qr/\Qrun: $line\E/, 'the trace names the command line' );
}

# Without --verbose the run writes nothing (CLI-PROGRAM-7)
{
	my @cmd = ( $^X, '-e', 'print "two"' );

	my ( $err, $out ) = _stderr( sub { return $quiet->command( \@cmd ) } );
	is( $out, 'two', 'the silent run returns the standard output' );
	is( $err, q{},   'the silent run writes nothing to standard error' );
}

# The standard error of the child reaches standard error, in full
{
	my @cmd = ( $^X, '-e', 'print STDERR "first\nsecond\n"' );

	my ( $err, $out ) = _stderr( sub { return $quiet->command( \@cmd ) } );
	is( $out, q{}, 'the child writes nothing to standard output' );
	is(
		$err, "first\nsecond\n",
		'the standard error of the child passes through in full'
	);
}

# A child that exits non-zero gives undef with the reason in error
{
	my @cmd = ( $^X, '-e', 'exit 3' );

	my ( $err, $out ) = _stderr( sub { return $quiet->command( \@cmd ) } );
	is( $out, undef, 'a child that fails gives undef' );
	is( $quiet->error, "$^X exited 3", 'error names the exit code' );
	is( $err, q{}, 'a child that fails writes no diagnostic of its own' );
}

# A child that outlives its timeout gives undef, and error says so
{
	my @cmd = ( $^X, '-e', 'sleep 10' );

	my ( $err, $out ) = _stderr(
		sub { return $quiet->command( \@cmd, timeout => 1 ) } );
	is( $out, undef, 'a child that times out gives undef' );
	is( $quiet->error, "$^X timed out", 'error names the timeout' );
	is( $err, q{}, 'a child that times out writes no diagnostic' );
}

# A command that never starts gives undef with the reason in error
{
	my @cmd = ("$dir/no-such-command");

	my ( $err, $out ) = _stderr( sub { return $quiet->command( \@cmd ) } );
	is( $out, undef, 'a command that never starts gives undef' );
	ok( defined $quiet->error, 'error holds the reason of the start' );
	is( $err, q{}, 'a command that never starts writes nothing' );
}

# A run that succeeds clears the reason of the last failure
{
	my @cmd = ( $^X, '-e', '1' );

	my ( $err, $out ) = _stderr( sub { return $quiet->command( \@cmd ) } );
	is( $out, q{}, 'a child that writes nothing gives the empty string' );
	is( $quiet->error, undef, 'a run that succeeds clears error' );
	is( $err,          q{},   'a run that succeeds writes nothing' );
}

done_testing();
