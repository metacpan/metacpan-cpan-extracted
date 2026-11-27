#!/usr/bin/perl

# The cases that prove Class::Shared itself, rather than a target class:
#
#   1 lifecycle  hello -> class validation -> construction -> calls ->
#                shutdown, with the handle cleared at the end;
#   2 mid-flight a reply lost after the request was written rolls the
#                connection back, closes its handle and leaves the backend
#                serving;
#   3 TOCTOU     a path swapped by another process after it has been validated
#                is refused, and the file that process put there is never
#                deleted.
#
# The object under test is Shared::Counter, which the rest of the suite already
# uses: it reports its constructor arguments and the process it was built in,
# so the assertions are about what crossed the wire, not about a fixture.
#
# The target's own behaviour (a constructor that dies registering no object, a
# second shutdown being a no-op) is proved in t/function.t and
# t/10-regressions.t, where the code that implements it is under test.
#
# The file is ASCII only and indented with tabs.

use strict;
use warnings;

use Test::Most;
use Test::Needs;
use Test::Returns;
use Test::Mockingbird;

use Class::Shared ();

BEGIN {
	test_needs 'Test::Permissions';

	plan skip_all => 'these cases need a unix socket in an owner-only '
		. 'directory, which this perl cannot provide '
		. '(Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();
}

use File::Temp ();
use IO::Socket::UNIX;
use POSIX ();
use Socket qw(SOCK_STREAM);

use lib 't/lib';

use Class::Shared::Frontend;
use Class::Shared::Protocol;

my %config = (
	socket_name => 'class-shared.sock',
	pid         => '.pid',
	planted     => "not a socket\n",
	peer_closed => 'connection closed by peer',
	backlog     => 8,
	short_timeout => 0.3,

	error => {
		lost_backend => qr/Class::Shared: lost the backend for 'Shared::Counter': connection closed by peer/,
		gone         => qr/this frontend has no connection to a backend for 'Shared::Counter'; its object is gone/,
		not_a_socket => qr/exists and is not a socket; refusing to remove it/,
	},
);

# Short on purpose: a socket path may be at most 100 characters, and the
# temporary directory on macOS already takes about half of that.
my $tmp = File::Temp->newdir('cst-XXXXXX', TMPDIR => 1, CLEANUP => 1);

my @daemons;    # backends an autostart started, so a failed subtest leaks none

END {
	kill 'TERM', $_ for grep { $_ && kill(0, $_) } @daemons;
}

# A directory of its own for one case: 0700, which is what a backend requires.
sub area {
	my ($name) = @_;

	return File::Temp->newdir("$name-XXXXXX", DIR => "$tmp", CLEANUP => 1);
}

# Every frontend is remembered by the backend process it reached, so the END
# block can end one a failed assertion left running.
sub attach {
	my (%opt) = @_;

	my $frontend = Class::Shared::Frontend->new('Shared::Counter', %opt);

	push @daemons, $frontend->shared_pid if defined $frontend->shared_pid;

	return $frontend;
}

subtest 'lifecycle: attach, calls and shutdown' => sub {
	my $area = area('lifecycle');
	my $socket = "$area/$config{socket_name}";

	my $frontend = attach(socket => $socket, ctor => [start => 5]);

	ok($frontend->shared_connected, 'the handshake left a usable connection');
	like($frontend->shared_id, qr/\A[0-9]+\z/, 'the backend committed an object id');
	cmp_ok($frontend->shared_pid, '>', 0, 'the object lives in a process');
	returns_ok($frontend->shared_status, { type => 'hashref' },
		'a status request answers a message');

	is($frontend->value, 5, 'the constructor argument survived the handshake');
	is($frontend->pid, $frontend->shared_pid, 'the object was built in the backend, not here');
	is($frontend->constructed, 1, 'one object was constructed, not one per handshake');

	is($frontend->inc, 6, 'a call changes the state the next call sees');
	is($frontend->add(4, 5), 15, 'and the state carries across calls');
	is($frontend->value, 15, 'the last call sees what the earlier ones left');

	is($frontend->shared_shutdown, 1, 'the endpoint stops on request');
	ok(!$frontend->shared_connected, 'which closes the handle');
	is($frontend->shared_id, undef, 'and clears the object it stood for');
};

subtest 'mid-flight: a lost reply rolls back the connection and the object' => sub {
	my $area = area('lost');
	my $socket = "$area/$config{socket_name}";

	my $frontend = attach(socket => $socket, ctor => [start => 1]);
	my $pid = $frontend->shared_pid;

	# The request is written for real; only its answer is lost, which is what a
	# backend dying between the call and the reply looks like from here.
	my $real_write = \&Class::Shared::Protocol::write_all;
	my $written_to;
	mock 'Class::Shared::Protocol::write_all' => sub {
		$written_to = $_[0];
		$real_write->(@_);
	};
	mock 'Class::Shared::Protocol::read_frame' => sub { (undef, $config{peer_closed}) };

	throws_ok { $frontend->shared_status } $config{error}{lost_backend};

	ok(!$frontend->shared_connected, 'the frontend rolled its connection back');
	is($frontend->shared_id, undef, 'no object id is left behind');
	is($frontend->shared_pid, undef, 'no backend pid is left behind');
	is($frontend->shared_last_error, $config{peer_closed},
		'the reason is kept for whoever asks next');
	ok(defined $written_to, 'a request had been written before the reply was lost');
	ok(!defined fileno($written_to), 'the handle was closed, not leaked');
	throws_ok { $frontend->shared_status } $config{error}{gone};

	Test::Mockingbird::restore_all();

	ok(kill(0, $pid), 'the backend itself was never affected');

	my $next = attach(socket => $socket, autostart => 0, ctor => [start => 2]);
	is($next->value, 2, 'the next transaction starts cleanly');
	is($next->shared_shutdown, 1, 'and the endpoint is still healthy');
};

subtest 'TOCTOU: a path swapped after validation is never deleted' => sub {
	my $area = area('race');
	my $socket = "$area/$config{socket_name}";

	my $listener = IO::Socket::UNIX->new(
		Type     => SOCK_STREAM,
		Local    => $socket,
		Listen   => $config{backlog},
		Blocking => 1,
	) or BAIL_OUT("cannot listen on $socket: $!");

	# The instant after the endpoint passes its checks, another process replaces
	# the socket with a plain file of its own.
	my $real_check = \&Class::Shared::_check_endpoint;
	my $swaps = 0;
	mock 'Class::Shared::_check_endpoint' => sub {
		my @answer = $real_check->(@_);

		if (!$swaps++) {
			my $pid = fork;
			BAIL_OUT("cannot fork: $!") unless defined $pid;

			if (!$pid) {
				unlink($_[0]);
				open(my $planted, '>', $_[0]) or POSIX::_exit(1);
				print {$planted} $config{planted};
				close($planted);
				POSIX::_exit(0);
			}

			waitpid($pid, 0);
		}

		return @answer;
	};

	throws_ok {
		Class::Shared::Frontend->new(
			'Shared::Counter',
			socket  => $socket,
			timeout => $config{short_timeout},
			ctor    => [start => 1],
		);
	} $config{error}{not_a_socket};

	ok(-f $socket, 'the file another process put there is still there');

	open(my $planted, '<', $socket) or BAIL_OUT("cannot read $socket: $!");
	my $contents = do { local $/; <$planted> };
	close($planted);
	is($contents, $config{planted}, 'and is untouched');
	ok(!-e "$socket$config{pid}", 'no backend was started over it');

	Test::Mockingbird::restore_all();
	close($listener);
};

done_testing();
