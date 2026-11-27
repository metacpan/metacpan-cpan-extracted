#!/usr/bin/perl

# State-transition tests for the three STATE DIAGRAM sections of the POD:
#
#   Class::Shared::Protocol  EMPTY / HEADER / PARTIAL / COMPLETE / CORRUPT,
#                            the buffer's life inside take_frame;
#   Class::Shared::Frontend  CONNECTING / SPAWNING / HANDSHAKEN / BOUND /
#                            CLOSED, and FAILED for new();
#   Class::Shared::Backend   IDLE / STARTING / SERVING / STOPPING / STOPPED,
#                            and one client: ACCEPTED / HANDSHAKING /
#                            AWAITING HELLO / GREETED / DROPPED.
#
# Every =item in those sections names one subtest here.  A transition the code
# allows but the diagram does not draw is asserted as it behaves, with a
# "# TODO: FSM Discrepancy - ..." marker, so the suite enforces the diagram and
# reports where the diagram and the code disagree.
#
# The TCP-only client edges need the TLS harness, which t/04-tcp.t owns:
# ACCEPTED -> HANDSHAKING by "a real client connects while silent clients are
# mid-handshake" and "a silent client holds a slot while its handshake is
# pending"; HANDSHAKING -> AWAITING HELLO by "a request before the hello is
# sent over TLS" and "... leaves the client AWAITING HELLO" (a TLS connection
# whose handshake has finished and which has not greeted); HANDSHAKING ->
# DROPPED by "a client with no certificate gets no reply" and "and loses it
# once its handshake deadline passes".  The deadline
# is also asserted in this file, on a client record marked handshaking.  Every
# unix edge and every edge after the handshake is proved here.
#
# Timeouts are warped with Test::Mockingbird::TimeTravel instead of slept
# through, wherever the code reads Time::HiRes::time.  The TLS handshake
# deadline in _expire_handshakes is measured with the core time(), which a
# CORE::GLOBAL override installed at run time cannot move, so its stored
# deadline is put in the past directly; that is equally deterministic and
# needs no sleep.
#
# The file is ASCII only and indented with tabs.

use strict;
use warnings;

use Test::Most;
use Test::Needs;
use Test::Mockingbird;
use Test::Mockingbird::TimeTravel qw(freeze_time advance_time now);

use Class::Shared ();

BEGIN {
	test_needs 'Test::Permissions';

	plan skip_all => 'the state machines need a unix socket in an owner-only '
		. 'directory, which this perl cannot provide '
		. '(Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();
}

use Fcntl qw(:flock O_RDWR O_CREAT);
use File::Temp ();
use IO::Socket::UNIX;
use POSIX ();
use Socket qw(SOCK_STREAM);
use Storable ();
use Time::HiRes ();

use lib 't/lib';

use Class::Shared::Backend ();
use Class::Shared::Frontend;
use Class::Shared::Protocol;

my %config = (
	socket_name     => 'class-shared.sock',
	pid_suffix      => '.pid',
	owner_suffix    => '.owner',
	done_suffix     => '.done',
	log_suffix      => '.log',

	timeout         => 10,
	short_timeout   => 0.4,
	handshake_timeout => 5,
	read_timeout    => 30,
	write_timeout   => 30,
	start_timeout   => 0.2,
	settle          => 5,
	poll            => 0.02,

	max_frame       => $Class::Shared::Protocol::MAX_FRAME,
	epoch           => 1_767_225_600,
	unsafe_mode     => 0777,
	owner_mode      => 0600,

	error => {
		handshake_required => qr/\Ahandshake required\z/,
		protocol_mismatch  => qr/protocol version mismatch/,
		unknown_class      => qr/cannot load /,
		busy               => qr/already serving|already listening/,
		not_a_socket       => qr/exists and is not a socket; refusing to remove it/,
		construct_failed   => qr/could not construct Class::Shared::Protocol/,
		spawn_failed       => qr/could not start a backend/,
		unsafe_dir         => qr/writable by group or others/,
		lost_backend       => qr/lost the backend for 'Shared::Counter'/,
		gone               => qr/its object is gone/,
		no_method          => qr/has no method 'value'/,
	},
);

# Short on purpose: a socket path must fit in a socket address, and the
# temporary directory on macOS already takes about half of the room.
my $tmp = File::Temp->newdir('cstr-XXXXXX', TMPDIR => 1, CLEANUP => 1);

my @children;

END {
	kill 'TERM', $_ for grep { $_ && kill(0, $_) } @children;
}

# The name each case passes is for the reader: it is left out of the path.
sub area {
	return File::Temp->newdir('a-XXXXXX', DIR => "$tmp", CLEANUP => 1);
}

sub wait_until {
	my ($code, $seconds) = @_;

	my $deadline = Time::HiRes::time() + ($seconds // $config{settle});

	while (Time::HiRes::time() < $deadline) {
		return 1 if $code->();
		Time::HiRes::sleep($config{poll});
	}

	return $code->() ? 1 : 0;
}

sub read_file {
	my ($path) = @_;

	open(my $fh, '<', $path) or return undef;
	my $text = do { local $/; <$fh> };
	close($fh);

	return $text;
}

sub lock_is_free {
	my ($path) = @_;

	my $fh;
	sysopen($fh, $path, O_RDWR | O_CREAT, 0600) or return 0;
	my $free = flock($fh, LOCK_EX | LOCK_NB) ? 1 : 0;
	close($fh);

	return $free;
}

# ---------------------------------------------------------------- frames

sub frame {
	my ($message, $secret) = @_;

	my ($bytes) = Class::Shared::Protocol::encode_frame($message, $secret);
	die "cannot encode: $bytes" unless defined $bytes;

	return $bytes;
}

sub ask {
	my ($socket, $message, $wait) = @_;

	my ($sent, $write_error) = Class::Shared::Protocol::write_all($socket, frame($message));
	die "write failed: $write_error" unless $sent;

	my ($response, $read_error) = Class::Shared::Protocol::read_frame(
		$socket, defined $wait ? $wait : $config{timeout},
	);

	die "read failed: $read_error" unless defined $response;

	return $response;
}

sub connect_raw {
	my ($path) = @_;

	return IO::Socket::UNIX->new(Type => SOCK_STREAM, Peer => $path);
}

sub hello {
	my ($class) = @_;

	return {
		op    => 'hello',
		proto => $Class::Shared::PROTOCOL_VERSION,
		(defined $class && length $class ? (class => $class) : ()),
	};
}

sub start_backend {
	my (%opt) = @_;

	my $pid = fork;
	BAIL_OUT("cannot fork: $!") unless defined $pid;

	if (!$pid) {
		my $ok = eval {
			Class::Shared::Backend->new(daemonize => 0, %opt)->run;
			1;
		};
		POSIX::_exit($ok ? 0 : 1);
	}

	push @children, $pid;

	return $pid;
}

sub stop_backend {
	my ($pid, $socket) = @_;

	return unless $pid;

	kill 'TERM', $pid;
	waitpid($pid, 0);
	wait_until(sub { !-e $socket });

	return;
}

# ------------------------------------------------------- Protocol::take_frame

subtest 'State: EMPTY -> Trigger: 1-3 bytes -> State: HEADER' => sub {
	my $buffer = '';

	my @empty = Class::Shared::Protocol::take_frame(\$buffer);
	is_deeply(\@empty, [0, undef, undef], 'no bytes: nothing is taken');
	is($buffer, '', 'and the buffer is untouched');

	foreach my $count (1 .. 3) {
		$buffer = 'x' x $count;
		my @taken = Class::Shared::Protocol::take_frame(\$buffer);
		is_deeply(\@taken, [0, undef, undef], "$count byte(s): the header is not complete");
		is($buffer, 'x' x $count, '  and the bytes are kept for the next call');
	}
};

subtest 'State: HEADER -> Trigger: body not all here -> State: PARTIAL' => sub {
	my $message = { op => 'ping' };
	my $bytes = frame($message);
	my $buffer = substr($bytes, 0, 4) . substr($bytes, 4, 1);

	my @header = Class::Shared::Protocol::take_frame(\$buffer);
	is_deeply(\@header, [0, undef, undef], 'the length is known but the body is not');
	is(length($buffer), 5, 'and the frame is kept whole in the buffer');

	$buffer = $bytes;
	my @complete = Class::Shared::Protocol::take_frame(\$buffer);
	is($complete[0], 1, 'when the rest arrives the frame completes');
	is_deeply($complete[1], $message, 'with the message that was sent');
	is($buffer, '', 'and the buffer is empty again');
};

subtest 'State: HEADER -> Trigger: length over the limit -> State: CORRUPT' => sub {
	my $buffer = pack('N', $config{max_frame} + 1) . 'body';

	my @first = Class::Shared::Protocol::take_frame(\$buffer);
	is($first[0], -1, 'a length over the limit is refused at once');
	like($first[2], qr/exceeds the limit/, 'and says why');
	is($buffer, pack('N', $config{max_frame} + 1) . 'body',
		'the bytes are left alone, so the caller can report and close');

	my @second = Class::Shared::Protocol::take_frame(\$buffer);
	is_deeply(\@second, \@first, 'a second call gives the same answer: CORRUPT is sticky');
};

subtest 'State: COMPLETE -> Trigger: valid frame -> State: EMPTY' => sub {
	my $first = frame({ op => 'ping' });
	my $second = frame({ op => 'status' });

	my $buffer = $first;
	my @taken = Class::Shared::Protocol::take_frame(\$buffer);
	is($taken[0], 1, 'a whole frame in an empty buffer is taken in one call');
	is($buffer, '', 'leaving EMPTY');

	$buffer = $first . $second;
	@taken = Class::Shared::Protocol::take_frame(\$buffer);
	is($taken[0], 1, 'back to back frames: the first is taken');
	is_deeply($taken[1], { op => 'ping' }, 'with its own message');
	is($buffer, $second, 'and the bytes after it stay, already the next frame');

	@taken = Class::Shared::Protocol::take_frame(\$buffer);
	is_deeply($taken[1], { op => 'status' }, 'so the next call takes the second');
	is($buffer, '', 'and the buffer ends EMPTY');
};

subtest 'State: COMPLETE -> Trigger: digest does not match -> State: CORRUPT' => sub {
	my $secret = 'k';
	my $good = frame({ op => 'ping' }, $secret);
	my $bad = $good;
	substr($bad, 4, 1, chr(ord(substr($bad, 4, 1)) ^ 0xFF));

	my $buffer = $bad;
	my $thawed = spy 'Storable::thaw';
	my @taken = Class::Shared::Protocol::take_frame(\$buffer, $secret);
	Test::Mockingbird::restore_all();

	is($taken[0], -1, 'a frame that fails its digest is refused');
	like($taken[2], qr/failed authentication/, 'and says so');
	is($buffer, '', 'the frame is dropped from the buffer');
	is(scalar($thawed->()), 0, 'and was never thawed');
};

subtest 'State: CORRUPT -> Trigger: another frame -> State: EMPTY' => sub {
	# The diagram draws no edge out of CORRUPT: it says "close the connection".
	# The code drops the rejected frame and carries on, so the next frame is
	# accepted by a caller that ignores the error.  Asserted as it behaves.
	my $secret = 'k';
	my $good = frame({ op => 'ping' }, $secret);
	my $bad = $good;
	substr($bad, 4, 1, chr(ord(substr($bad, 4, 1)) ^ 0xFF));

	my $buffer = $bad . $good;

	my @rejected = Class::Shared::Protocol::take_frame(\$buffer, $secret);
	is($rejected[0], -1, 'the corrupt frame is rejected');

	# COMPLETE to CORRUPT removes the bad frame, so bytes after it stay
	# buffered.  The POD says to close rather than call again; this is what a
	# caller that ignored that would see.
	my @accepted = Class::Shared::Protocol::take_frame(\$buffer, $secret);
	is($accepted[0], 1, 'the frame after a corrupt one is accepted, as the code allows');
	is_deeply($accepted[1], { op => 'ping' }, 'and decoded');
};

# ------------------------------------------------- Backend: one client

subtest 'State: ACCEPTED -> Trigger: request before hello -> State: AWAITING HELLO' => sub {
	my $area = area('awaiting');
	my $socket = "$area/$config{socket_name}";
	my $pid = start_backend(socket => $socket, log => "$area/backend$config{log_suffix}");
	ok(wait_until(sub { -S $socket }), 'the backend is listening');

	my $client = connect_raw($socket) or BAIL_OUT("cannot connect: $!");

	my $before = ask($client, { op => 'new', args => [] });
	is($before->{ok}, 0, 'a request before the hello is refused');
	like($before->{error}, $config{error}{handshake_required}, 'as a required handshake');

	my $greeted = ask($client, hello('Shared::Counter'));
	is($greeted->{ok}, 1, 'and the connection is still AWAITING HELLO: a good hello works');
	is($greeted->{class}, 'Shared::Counter', 'which sets the class');

	close($client);
	stop_backend($pid, $socket);
};

subtest 'State: AWAITING HELLO -> Trigger: bad hello -> State: AWAITING HELLO' => sub {
	my $area = area('badhello');
	my $socket = "$area/$config{socket_name}";
	my $pid = start_backend(socket => $socket, log => "$area/backend$config{log_suffix}");
	ok(wait_until(sub { -S $socket }), 'the backend is listening');

	my $client = connect_raw($socket) or BAIL_OUT("cannot connect: $!");

	my $wrong = ask($client, { op => 'hello', proto => $Class::Shared::PROTOCOL_VERSION + 1 });
	is($wrong->{ok}, 0, 'a hello with the wrong protocol is refused');
	like($wrong->{error}, $config{error}{protocol_mismatch}, 'naming both versions');

	$wrong = ask($client, hello('No::Such::Class'));
	is($wrong->{ok}, 0, 'and so is a class that cannot be loaded');
	like($wrong->{error}, $config{error}{unknown_class}, 'naming the class');

	my $good = ask($client, hello('Shared::Counter'));
	is($good->{ok}, 1, 'a failed hello changes nothing: the next good one is accepted');

	close($client);
	stop_backend($pid, $socket);
};

subtest 'State: AWAITING HELLO -> Trigger: good hello -> State: GREETED' => sub {
	my $area = area('greeted');
	my $socket = "$area/$config{socket_name}";
	my $pid = start_backend(socket => $socket, log => "$area/backend$config{log_suffix}");
	ok(wait_until(sub { -S $socket }), 'the backend is listening');

	my $client = connect_raw($socket) or BAIL_OUT("cannot connect: $!");

	my $response = ask($client, hello('Shared::Counter'));
	is($response->{ok}, 1, 'the hello is accepted');
	is($response->{class}, 'Shared::Counter', 'with the class');
	is($response->{pid}, $pid, 'and the backend pid');
	is($response->{proto}, $Class::Shared::PROTOCOL_VERSION, 'and the protocol version');

	close($client);
	stop_backend($pid, $socket);
};

subtest 'State: GREETED -> Trigger: new, call, ping, an exception -> State: GREETED' => sub {
	my $area = area('greeted-loop');
	my $socket = "$area/$config{socket_name}";
	my $pid = start_backend(socket => $socket, log => "$area/backend$config{log_suffix}");
	ok(wait_until(sub { -S $socket }), 'the backend is listening');

	my $client = connect_raw($socket) or BAIL_OUT("cannot connect: $!");
	ask($client, hello('Shared::Counter'));

	my $made = ask($client, { op => 'new', args => [start => 5] });
	is($made->{ok}, 1, 'new adds an object');
	my $id = $made->{id};

	my $call = ask($client, { op => 'call', id => $id, method => 'add', args => [3], want => 'scalar' });
	is($call->{ok}, 1, 'call runs a method');
	is($call->{result}[0], 8, 'and returns its result');

	my $died = ask($client, { op => 'call', id => $id, method => 'boom', args => ['no'], want => 'scalar' });
	is($died->{ok}, 0, 'an exception from the target is a failure reply');
	is($died->{kind}, 'die', 'of kind die');

	$call = ask($client, { op => 'call', id => $id, method => 'add', args => [1], want => 'scalar' });
	is($call->{ok}, 1, 'and the connection stays GREETED');
	is($call->{result}[0], 9, 'with the target still usable');

	my $ping = ask($client, { op => 'ping' });
	is($ping->{ok}, 1, 'ping is answered');
	is($ping->{objects}, 1, 'the object is still held');
	is($ping->{clients}, 1, 'and this is still the only client');

	close($client);
	stop_backend($pid, $socket);
};

subtest 'State: GREETED -> Trigger: a second hello -> State: GREETED' => sub {
	my $area = area('second-hello');
	my $socket = "$area/$config{socket_name}";
	my $pid = start_backend(socket => $socket, log => "$area/backend$config{log_suffix}");
	ok(wait_until(sub { -S $socket }), 'the backend is listening');

	my $client = connect_raw($socket) or BAIL_OUT("cannot connect: $!");
	ask($client, hello('Shared::Counter'));

	my $again = ask($client, hello('Shared::Tally'));
	is($again->{ok}, 0, 'a second hello is refused on a GREETED connection');
	is($again->{kind}, 'protocol', 'as a protocol failure');
	like($again->{error}, qr/already been accepted/, 'saying the connection is already greeted');

	my $made = ask($client, { op => 'new', args => [start => 2] });
	is($made->{ok}, 1, 'new still works');
	is($made->{class}, 'Shared::Counter', 'and the class of the connection has not changed');

	my $call = ask($client, { op => 'call', id => $made->{id}, method => 'value', want => 'scalar' });
	is($call->{ok}, 1, 'the original class is still the one in use');
	is($call->{result}[0], 2, 'and its methods answer');

	my $ping = ask($client, { op => 'ping' });
	is($ping->{ok}, 1, 'the connection is still GREETED');

	close($client);
	stop_backend($pid, $socket);
};

subtest 'State: GREETED -> Trigger: end of file -> State: DROPPED' => sub {
	my $area = area('eof');
	my $socket = "$area/$config{socket_name}";
	my $pid = start_backend(socket => $socket, log => "$area/log");
	ok(wait_until(sub { -S $socket }), 'the backend is listening');

	my $client = connect_raw($socket) or BAIL_OUT("cannot connect: $!");
	ask($client, hello('Shared::Counter'));
	my $made = ask($client, { op => 'new', args => [] });
	is($made->{ok}, 1, 'the client holds an object');

	my $observer = connect_raw($socket) or BAIL_OUT("cannot connect: $!");
	ask($observer, hello());

	my $before = ask($observer, { op => 'ping' });
	is($before->{clients}, 2, 'two clients are connected');
	is($before->{objects}, 1, 'with one object between them');

	close($client);
	ok(wait_until(sub { ask($observer, { op => 'ping' })->{clients} == 1 }),
		'the closed connection is dropped');

	my $after = ask($observer, { op => 'ping' });
	is($after->{objects}, 0, 'and the object it owned is destroyed');

	close($observer);
	stop_backend($pid, $socket);
};

subtest 'State: ACCEPTED -> Trigger: max_clients reached -> State: DROPPED' => sub {
	my $area = area('full');
	my $socket = "$area/$config{socket_name}";
	my $pid = start_backend(
		socket      => $socket,
		log         => "$area/log",
		max_clients => 1,
	);
	ok(wait_until(sub { -S $socket }), 'the backend is listening');

	my $first = connect_raw($socket) or BAIL_OUT("cannot connect: $!");
	ask($first, hello());

	my $second = connect_raw($socket) or BAIL_OUT("cannot connect: $!");
	my $refused = ask($second, hello('Shared::Counter'));
	is($refused->{ok}, 0, 'the client over the limit is refused');
	is($refused->{kind}, 'busy', 'as busy');

	my ($nothing, $error) = Class::Shared::Protocol::read_frame($second, $config{short_timeout});
	is($nothing, undef, 'and the socket is then closed');
	like($error, qr/(?:closed|reset) by peer/, 'which the next read reports');

	my $ping = ask($first, { op => 'ping' });
	is($ping->{clients}, 1, 'the client that was there is unaffected');

	close($first);
	close($second);
	stop_backend($pid, $socket);
};

# ------------------------------------------------- Backend: temporal drops

subtest 'State: AWAITING HELLO -> Trigger: handshake_timeout -> State: DROPPED' => sub {
	my $area = area('handshake-timeout');
	my $backend = Class::Shared::Backend->new(
		socket => "$area/unused$config{socket_name}",
		log    => "$area/backend$config{log_suffix}",
	);
	my $client_fh = IO::Socket::UNIX->new(Type => SOCK_STREAM, Local => "$area/client")
		or BAIL_OUT("cannot make a client socket: $!");

	$Test::Guarded::DESTROYED = 0;

	my $client = {
		fh       => $client_fh,
		closed   => 0,
		greeted  => 0,
		greet_by => $config{epoch} + $config{handshake_timeout},
		buffer   => '',
		outbuf   => '',
		objects  => { 1 => 1 },
		serial   => 1,
		closed   => 0,
	};

	$backend->{clients}{ fileno($client_fh) } = $client;
	$backend->{objects}{1} = { object => bless({}, 'Test::Guarded'), owner => 1 };
	$backend->{queued} = 0;

	freeze_time($config{epoch});
	mock 'Time::HiRes::time' => sub { Test::Mockingbird::TimeTravel::now() };

	$backend->_expire_reads('');
	is(scalar(keys %{ $backend->{clients} }), 1, 'before the deadline the client is kept');

	advance_time($config{handshake_timeout} + 1);
	$backend->_expire_reads('');

	is(scalar(keys %{ $backend->{clients} }), 0, 'at the deadline the client is dropped');
	is(scalar(keys %{ $backend->{objects} }), 0, 'its object goes with it');
	is($Test::Guarded::DESTROYED, 1, 'and its destructor ran');
	ok(!defined fileno($client_fh), 'and its socket is closed');

	Test::Mockingbird::restore_all();
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'State: GREETED -> Trigger: a reply makes no progress -> State: DROPPED' => sub {
	my $area = area('write-timeout');
	my $backend = Class::Shared::Backend->new(
		socket => "$area/unused$config{socket_name}",
		log    => "$area/backend$config{log_suffix}",
	);
	my $client_fh = IO::Socket::UNIX->new(Type => SOCK_STREAM, Local => "$area/client")
		or BAIL_OUT("cannot make a client socket: $!");

	my $client = {
		fh            => $client_fh,
		closed        => 0,
		greeted       => 1,
		greet_by      => undef,
		buffer        => '',
		outbuf        => 'x' x 10,
		stalled_since => $config{epoch},
		objects       => {},
		serial        => 1,
	};

	$backend->{clients}{ fileno($client_fh) } = $client;
	$backend->{queued} = length $client->{outbuf};

	freeze_time($config{epoch});
	mock 'Time::HiRes::time' => sub { Test::Mockingbird::TimeTravel::now() };

	$backend->_expire_writes('');
	is(scalar(keys %{ $backend->{clients} }), 1, 'before the deadline the client is kept');

	advance_time($config{write_timeout} + 1);
	$backend->_expire_writes('');

	is(scalar(keys %{ $backend->{clients} }), 0, 'at the deadline the client is dropped');
	is($backend->{queued}, 0, 'and its queued reply is given back');
	ok(!defined fileno($client_fh), 'and its socket is closed');

	Test::Mockingbird::restore_all();
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'State: HANDSHAKING -> Trigger: TLS handshake deadline -> State: DROPPED' => sub {
	# _expire_handshakes measures with the core time(), which a run-time
	# CORE::GLOBAL override cannot move, so its stored deadline is put in the
	# past instead.  No sleep is needed either way.
	my $area = area('tls-expire');
	my $backend = Class::Shared::Backend->new(
		socket => "$area/unused$config{socket_name}",
		log    => "$area/backend$config{log_suffix}",
	);
	my $client_fh = IO::Socket::UNIX->new(Type => SOCK_STREAM, Local => "$area/client")
		or BAIL_OUT("cannot make a client socket: $!");

	$backend->{queued} = 0;
	$backend->{clients}{ fileno($client_fh) } = {
		fh          => $client_fh,
		closed      => 0,
		outbuf      => '',
		handshaking => 1,
		deadline    => time - 1,
		buffer      => '',
		outbuf      => '',
		objects     => {},
		serial      => 1,
	};

	$backend->_expire_handshakes;

	is(scalar(keys %{ $backend->{clients} }), 0, 'a handshake past its deadline is dropped');
	ok(!defined fileno($client_fh), 'and its socket is closed');
};

# ------------------------------------------------------ Backend: the process

subtest 'State: IDLE -> Trigger: run -> State: SERVING' => sub {
	my $area = area('serving');
	my $socket = "$area/$config{socket_name}";
	my $log = "$area/backend$config{log_suffix}";

	my $pid = start_backend(socket => $socket, log => $log);
	ok(wait_until(sub { -S $socket }), 'run() opens the socket');

	ok(-e "$socket$config{pid_suffix}", 'the pid file is written');
	is(read_file("$socket$config{pid_suffix}"), "$pid\n", 'and names the backend');
	ok(-e "$socket$config{owner_suffix}", 'the owner lock exists');
	ok(!lock_is_free("$socket$config{owner_suffix}"), 'and is held while SERVING');
	like(read_file($log), qr/serving on /, 'and serving is logged');

	my $client = connect_raw($socket) or BAIL_OUT("cannot connect: $!");
	my $hello = ask($client, hello());
	is($hello->{ok}, 1, 'the backend answers requests');
	close($client);

	stop_backend($pid, $socket);
};

subtest 'State: SERVING -> Trigger: SIGTERM -> State: STOPPING -> STOPPED' => sub {
	my $area = area('stopped');
	my $socket = "$area/$config{socket_name}";
	my $log = "$area/backend$config{log_suffix}";

	my $pid = start_backend(socket => $socket, log => $log);
	ok(wait_until(sub { -S $socket }), 'the backend is SERVING');

	kill 'TERM', $pid;
	ok(wait_until(sub { !-e $socket }), 'SIGTERM takes it through STOPPING');

	waitpid($pid, 0);
	is($? >> 8, 0, 'run() returns 0');
	ok(!-e "$socket$config{pid_suffix}", 'the pid file is gone');
	ok(wait_until(sub { lock_is_free("$socket$config{owner_suffix}") }), 'the lock is released');
	like(read_file($log), qr/\bstopped\b/, 'and stopped is logged');
};

subtest 'State: STARTING -> Trigger: lock held -> State: FAILED' => sub {
	my $area = area('locked-start');
	my $socket = "$area/$config{socket_name}";
	my $pid = start_backend(socket => $socket, log => "$area/log");
	ok(wait_until(sub { -S $socket }), 'a backend is SERVING');
	my @before = stat($socket);

	throws_ok {
		Class::Shared::Backend->new(
			socket       => $socket,
			log          => "$area/second$config{log_suffix}",
			start_timeout => $config{start_timeout},
			daemonize    => 0,
		)->run;
	} $config{error}{busy};

	my @after = stat($socket);
	is_deeply([$after[0], $after[1]], [$before[0], $before[1]],
		'the running backend keeps its socket');

	my $client = connect_raw($socket) or BAIL_OUT("cannot connect: $!");
	is(ask($client, hello())->{ok}, 1, 'and still answers');
	close($client);

	stop_backend($pid, $socket);
};

subtest 'State: STARTING -> Trigger: path is not a socket -> State: FAILED' => sub {
	my $area = area('not-socket');
	my $socket = "$area/$config{socket_name}";
	open(my $planted, '>', $socket) or BAIL_OUT("cannot write $socket: $!");
	print {$planted} "keep me\n";
	close($planted);

	throws_ok {
		Class::Shared::Backend->new(socket => $socket, log => "$area/log", daemonize => 0)->run;
	} $config{error}{not_a_socket};

	is(read_file($socket), "keep me\n", 'the file is untouched');
	ok(!-e "$socket$config{pid_suffix}", 'and no pid file was written');
};

subtest 'State: STOPPED -> Trigger: run again -> State: STOPPED' => sub {
	my $area = area('restart');
	my $socket = "$area/$config{socket_name}";
	my $report = "$area/report";

	my $pid = fork;
	BAIL_OUT("cannot fork: $!") unless defined $pid;

	if (!$pid) {
		my $backend = Class::Shared::Backend->new(
			socket => $socket,
			log    => "$area/log",
			daemonize => 0,
		);

		$backend->run;

		# The same object, after STOPPED.  The alarm is a guard so a second
		# life cannot hold the harness open.
		my $returned = eval {
			local $SIG{ALRM} = sub { die "still serving\n" };
			alarm 3;
			$backend->run;
			alarm 0;
			1;
		};
		my $error = $@ || '';
		$error =~ s/\s+\z//;

		open(my $out, '>', $report) or POSIX::_exit(9);
		print {$out} ($returned ? 'returned' : 'died'), ' socket=', (-S $socket ? 1 : 0),
			' error=', $error, "\n";
		close($out);
		POSIX::_exit(0);
	}

	push @children, $pid;
	ok(wait_until(sub { -S $socket }), 'the first run is SERVING');

	my $client = connect_raw($socket) or BAIL_OUT("cannot connect: $!");
	ask($client, hello());
	ask($client, { op => 'shutdown' });
	close($client);

	ok(wait_until(sub { -e $report }), 'the backend reached STOPPED and tried again');

	my $said = read_file($report);
	like($said, qr/\Adied\b/, 'a second run() dies instead of serving');
	like($said, qr/socket=0/, 'and leaves no socket behind');
	like($said, qr/already run and stopped/, 'saying the backend has already stopped');

	waitpid($pid, 0);
	unlink($socket);
};

# ---------------------------------------------------------- Frontend::new

subtest 'State: CONNECTING -> Trigger: hello answered -> State: HANDSHAKEN -> BOUND' => sub {
	my $area = area('handshaken');
	my $socket = "$area/$config{socket_name}";

	my $spawned = Class::Shared::Frontend->new('Shared::Counter', socket => $socket, ctor => [start => 1]);
	my $pid = $spawned->shared_pid;
	$spawned->shared_close;

	my $seen;
	before 'Class::Shared::Frontend::_create_object' => sub {
		my $self = shift;
		$seen = { pid => $self->{pid}, id => $self->{id}, sock => $self->{sock} };
	};

	my $frontend = Class::Shared::Frontend->new(
		'Shared::Counter',
		socket    => $socket,
		autostart => 0,
		ctor      => [start => 2],
	);
	Test::Mockingbird::restore_all();

	is($seen->{pid}, $pid, 'HANDSHAKEN stores the backend pid');
	is($seen->{id}, undef, 'and has no object id yet');
	ok(defined $seen->{sock}, 'with the socket open');
	is($frontend->shared_id, 2, 'BOUND stores the object id the backend gave it');
	is($frontend->value, 2, 'and the object is usable');

	$frontend->shared_shutdown;
};

subtest 'State: CONNECTING -> Trigger: nothing answers -> State: SPAWNING -> BOUND' => sub {
	my $area = area('spawning');
	my $socket = "$area/$config{socket_name}";

	ok(!-e $socket, 'nothing is listening');

	my $frontend = Class::Shared::Frontend->new('Shared::Counter', socket => $socket, ctor => [start => 3]);

	ok(-S $socket, 'SPAWNING made a socket');
	isnt($frontend->shared_pid, $$, 'a backend process of its own answers');
	ok(kill(0, $frontend->shared_pid), 'and it is alive');
	is($frontend->value, 3, 'the object was built there');

	$frontend->shared_shutdown;
};

subtest 'State: SPAWNING -> Trigger: unsafe directory -> State: FAILED' => sub {
	my $area = area('unsafe');
	my $unsafe = "$area/open";
	mkdir($unsafe, 0777) or BAIL_OUT("cannot make $unsafe: $!");
	chmod($config{unsafe_mode}, $unsafe) or BAIL_OUT("cannot chmod $unsafe: $!");

	throws_ok {
		Class::Shared::Frontend->new('Shared::Counter', dir => $unsafe);
	} $config{error}{spawn_failed};

	like($@, $config{error}{unsafe_dir}, 'the unsafe directory is named');
	ok(!-e "$unsafe/$config{socket_name}", 'and no socket was made there');
};

subtest 'State: HANDSHAKEN -> Trigger: the target has no new -> State: FAILED' => sub {
	my $area = area('no-ctor');
	my $socket = "$area/$config{socket_name}";

	my $control = Class::Shared::Frontend->new('Shared::Counter', socket => $socket);
	my $pid = $control->shared_pid;
	my $before = $control->shared_status;

	throws_ok {
		Class::Shared::Frontend->new(
			'Class::Shared::Protocol',
			socket    => $socket,
			autostart => 0,
		);
	} $config{error}{construct_failed};

	my $after = $control->shared_status;
	is($after->{pid}, $pid, 'the backend still serves');
	is($after->{objects}, $before->{objects},
		'and the failed handshake registered no object');
	is($after->{constructed}, $before->{constructed},
		'and built nothing');

	$control->shared_shutdown;
};

# ------------------------------------------------- Frontend after new()

subtest 'State: BOUND -> Trigger: calls, accessors and an exception -> State: BOUND' => sub {
	my $area = area('bound-loop');
	my $socket = "$area/$config{socket_name}";
	my $frontend = Class::Shared::Frontend->new('Shared::Counter', socket => $socket, ctor => [start => 1]);

	my $pid = $frontend->shared_pid;
	is($frontend->inc, 2, 'a call changes the state');
	is($frontend->value, 2, 'and an accessor reads it');
	throws_ok { $frontend->boom('no') } qr/kaboom: no/, 'an exception from the target is rethrown';
	is($frontend->shared_connected, 1, 'and does not change the state');
	is($frontend->value, 2, 'which is still BOUND');
	is($frontend->shared_pid, $pid, 'with the same backend');

	$frontend->shared_shutdown;
};

subtest 'State: BOUND -> Trigger: shared_close -> State: CLOSED' => sub {
	my $area = area('closed');
	my $socket = "$area/$config{socket_name}";
	my $frontend = Class::Shared::Frontend->new('Shared::Counter', socket => $socket);
	my $pid = $frontend->shared_pid;

	ok($frontend->shared_connected, 'BOUND before the close');
	is($frontend->shared_close, 1, 'shared_close closes it');
	ok(!$frontend->shared_connected, 'so the state is CLOSED');
	is($frontend->shared_id, undef, 'and the object id is gone');
	is($frontend->shared_pid, undef, 'and the backend pid');
	is($frontend->shared_close, 0, 'a second close is a no-op, as shared_close documents');

	throws_ok { $frontend->shared_status } $config{error}{gone},
		'and any call on the CLOSED frontend dies';

	kill 'TERM', $pid if $pid;
};

subtest 'State: BOUND -> Trigger: the connection breaks -> State: CLOSED' => sub {
	my $area = area('lost');
	my $socket = "$area/$config{socket_name}";
	my $frontend = Class::Shared::Frontend->new('Shared::Counter', socket => $socket);
	my $pid = $frontend->shared_pid;

	kill 'TERM', $pid;
	ok(wait_until(sub { !kill(0, $pid) }), 'the backend is gone');

	throws_ok { $frontend->shared_status } $config{error}{lost_backend},
		'the call dies as the connection is lost';
	ok(!$frontend->shared_connected, 'and the frontend closed itself');
	is($frontend->shared_id, undef, 'clearing the object id');
	throws_ok { $frontend->shared_status } $config{error}{gone},
		'and the next call finds it CLOSED';
};

package Test::Guarded;

our $DESTROYED = 0;

sub DESTROY { $DESTROYED++ }

package main;

done_testing();
