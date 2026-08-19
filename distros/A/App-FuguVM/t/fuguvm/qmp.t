#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The QMP command set. The transport - the deadline on a read, the
# buffered remainder, the reassembly of a split line - belongs to
# Fugu::JSONSocket and is proven in t/fugu/jsonsocket.t.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use IO::Socket::UNIX;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use_ok('App::FuguVM::QMP');

# paired_qmp(): a QMP object wired to one end of a socketpair. The
# helper returns the peer, so the test can play QEMU. Both ends come
# from IO::Socket, so they autoflush exactly as the sockets the module
# opens for itself.
sub paired_qmp ()
{
	my ( $ours, $theirs ) =
	    IO::Socket::UNIX->socketpair( AF_UNIX, SOCK_STREAM, PF_UNSPEC );
	return if !defined $ours;

	my $qmp = App::FuguVM::QMP->new('/tmp/test-qmp.sock');
	$qmp->{socket}{sock} = $ours;

	return ( $qmp, $theirs );
}

# Test object creation
{
	my $qmp = App::FuguVM::QMP->new('/tmp/test-qmp.sock');
	ok( defined $qmp, 'QMP object created' );
}

# Test connection failure to non-existent socket
{
	my $qmp = App::FuguVM::QMP->new('/tmp/nonexistent-qmp.sock');
	is( $qmp->open_connection, 0, 'Connection fails for non-existent socket' );
}

# Test disconnect on unconnected socket
{
	my $qmp = App::FuguVM::QMP->new('/tmp/test-qmp.sock');
	ok( defined $qmp->disconnect, 'Disconnect returns the object' );
}

# Test run_command on unconnected socket returns undef
{
	my $qmp = App::FuguVM::QMP->new('/tmp/test-qmp.sock');
	is( $qmp->run_command('query-status'),
		undef, 'run_command returns undef when not connected' );
}

# The command set: a well-formed reply decodes into the answer that
# each method promises.
{
	my ( $qmp, $peer ) = paired_qmp();
	SKIP: {
		skip 'cannot create socketpair', 4 unless $qmp;

		print {$peer} qq({"return":{"running":true,"status":"running"}}\n);
		my $status = $qmp->query_status;
		ok( $status->{running}, 'query_status reports a running VM' );
		is( $status->{status}, 'running', 'and its status string' );

		print {$peer} qq({"return":{"running":false,"status":"paused"}}\n);
		is( $qmp->is_running, 0, 'is_running is false for a paused VM' );

		print {$peer} qq({"return":{"running":true}}\n);
		is( $qmp->is_running, 1, 'and true for a running one' );
	}
}

# An error reply is not an answer. Every command must tell the two
# apart, because a caller that treats an error as "not running" stops
# a VM that is up.
{
	my ( $qmp, $peer ) = paired_qmp();
	SKIP: {
		skip 'cannot create socketpair', 3 unless $qmp;

		print {$peer} qq({"error":{"class":"CommandNotFound"}}\n);
		is( $qmp->query_status, undef, 'query_status refuses an error' );

		print {$peer} qq({"error":{"class":"CommandNotFound"}}\n);
		ok( !$qmp->powerdown, 'powerdown refuses an error' );

		print {$peer} qq({"error":{"class":"CommandNotFound"}}\n);
		ok( !$qmp->quit, 'quit refuses an error' );
	}
}

# The lifecycle commands
{
	my ( $qmp, $peer ) = paired_qmp();
	SKIP: {
		skip 'cannot create socketpair', 2 unless $qmp;

		print {$peer} qq({"return":{}}\n);
		ok( $qmp->powerdown, 'powerdown succeeds' );

		print {$peer} qq({"return":{}}\n);
		ok( $qmp->quit, 'quit succeeds' );
	}
}

# quit closes the connection: QEMU is gone, so the socket is too
{
	my ( $qmp, $peer ) = paired_qmp();
	SKIP: {
		skip 'cannot create socketpair', 1 unless $qmp;

		print {$peer} qq({"return":{}}\n);
		$qmp->quit;
		is( $qmp->run_command('query-status'),
			undef, 'quit left the connection closed' );
	}
}

# A silent peer must not stall the caller. IO::Socket's timeout() does
# not bound a read, so this used to block for ever: 'fuguvm down' hung
# and never fell back to a force stop.
{
	my ( $qmp, $peer ) = paired_qmp();
	SKIP: {
		skip 'cannot create socketpair', 2 unless $qmp;

		# The module's own timeout is too long for a unit test
		$qmp->{socket}{timeout} = 0.5;

		my $start = time;
		is( $qmp->query_status, undef,
			'a silent peer gives undef, not a hang' );
		ok( time - $start < 10, 'and it returned near the deadline' );
	}
}

done_testing();
