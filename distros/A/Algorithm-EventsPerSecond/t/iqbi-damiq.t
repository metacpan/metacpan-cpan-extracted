#!perl

# The iqbi-damiq launcher: CLI validation, and one end-to-end run
# covering the pidfile lifecycle and clean shutdown.

use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	plan skip_all => 'unix domain sockets and fork required'
		if $^O eq 'MSWin32';
}

use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use Socket      qw(SOCK_STREAM);
use POSIX       ();
use Time::HiRes qw(sleep);

my $script = 'src_bin/iqbi-damiq';
plan skip_all => "$script not found (not running from the dist root?)"
	unless -f $script;

alarm 120;    # watchdog: a hung daemon must fail the test, not the harness

# blib for an installed-style run, lib as the fallback; missing include
# dirs are harmless
my @perl = ( $^X, '-Iblib/lib', '-Iblib/arch', '-Ilib' );

# run a command, returning its exit code and combined stdout/stderr
sub run_capture {
	my (@cmd) = @_;
	my $pid   = open my $fh, '-|';
	die "fork failed: $!" unless defined $pid;
	if ( !$pid ) {
		open STDERR, '>&', \*STDOUT or die "cannot dup STDERR: $!";
		exec @cmd or POSIX::_exit(127);
	}
	my $out = do { local $/; <$fh> };
	close $fh;
	return ( $? >> 8, $out );
} ## end sub run_capture

my $dir = tempdir( CLEANUP => 1 );

#
# CLI validation
#
{
	my ( $rc, $out ) = run_capture( @perl, $script, '--help' );
	is( $rc, 0, '--help exits 0' );
	like( $out, qr/--socket/, '--help shows the options' );

	( $rc, $out ) = run_capture( @perl, $script, '--version' );
	is( $rc, 0, '--version exits 0' );
	like( $out, qr/iqbi-damiq/, '--version names the program' );

	( $rc, $out ) = run_capture( @perl, $script );
	is( $rc, 2, 'missing --socket exits 2' );
	like( $out, qr/--socket is required/, '...and says which option is missing' );

	( $rc, $out ) = run_capture( @perl, $script, '--bogus' );
	is( $rc, 2, 'unknown option exits 2' );

	local $ENV{ALGORITHM_EVENTSPERSECOND_PP} = 1;
	( $rc, $out ) = run_capture( @perl, $script, '-s', "$dir/x.sock", '--require-xs' );
	isnt( $rc, 0, '--require-xs refuses to start on the pure Perl backend' );
	like( $out, qr/require-xs/, '...and says why' );
}

#
# end to end: launch, serve, terminate; the pidfile appears with the
# right pid and is removed on exit, the socket is unlinked
#
{
	my $sockpath = "$dir/iqbi.sock";
	my $pidfile  = "$dir/iqbi.pid";

	my $pid = fork;
	die "fork failed: $!" unless defined $pid;
	if ( !$pid ) {
		open STDOUT, '>', '/dev/null' or die "cannot silence stdout: $!";
		exec @perl, $script, '-s', $sockpath, '-p', $pidfile, '-w', '5'
			or POSIX::_exit(127);
	}

	my $sock;
	for ( 1 .. 100 ) {
		last if $sock = IO::Socket::UNIX->new( Type => SOCK_STREAM, Peer => $sockpath );
		sleep 0.1;
	}
	if ( !$sock ) {
		kill 'KILL', $pid;
		waitpid $pid, 0;
		BAIL_OUT("iqbi-damiq did not come up on $sockpath");
	}
	ok( $sock, 'launcher brought the daemon up' );

	print $sock "PING\n";
	my $reply = <$sock>;
	$reply =~ s/\r?\n\z// if defined $reply;
	is( $reply, 'OK PONG', 'daemon answers through the launcher' );

	ok( -f $pidfile, 'pidfile written' );
	my $recorded = do {
		open my $fh, '<', $pidfile or die "cannot read $pidfile: $!";
		local $/;
		<$fh>;
	};
	is( $recorded, "$pid\n", 'pidfile holds the daemon pid' );

	kill 'TERM', $pid;
	waitpid $pid, 0;
	is( $? >> 8, 0, 'launcher exits 0 on SIGTERM' );
	ok( !-e $sockpath, 'socket unlinked on shutdown' );
	ok( !-e $pidfile,  'pidfile removed on shutdown' );
}

done_testing();
