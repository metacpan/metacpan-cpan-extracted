use strict;
use warnings;

use Test::More;
use Test::Needs;
use Class::Shared ();

# A backend is reached over a unix socket in a directory only its owner can
# write to.  Whether this perl can make the socket is asked of the module, and
# whether a directory here can really be made owner-only is asked of
# Test::Permissions, which tries chmod rather than guessing from the platform's
# name: on Windows chmod sets only the read-only attribute, which directories
# ignore.
BEGIN {
	test_needs 'Test::Permissions';

	plan skip_all => 'the frontend here talks to a backend over a unix socket '
		. 'in an owner-only directory, which this perl cannot provide '
		. '(Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();
}

use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use Socket qw(SOCK_STREAM);
use lib 't/lib';

use Class::Shared::Frontend;
use Class::Shared::Backend ();
use Class::Shared::Protocol;

my $dir = tempdir(CLEANUP => 1);

my @frontends;

sub frontend {
	my %opt = @_;
	my $frontend = Class::Shared::Frontend->new('Shared::Counter', dir => $dir, %opt);
	push @frontends, $frontend;
	return $frontend;
}

sub wait_for_objects {
	my ($frontend, $count) = @_;

	my $deadline = time + 5;
	my $seen;
	while (time < $deadline) {
		$seen = eval { $frontend->shared_status->{objects} };
		last if defined $seen && $seen == $count;
		select(undef, undef, undef, 0.02);
	}

	return $seen;
}

END {
	for my $frontend (@frontends) {
		next unless $frontend && $frontend->shared_connected;
		eval { $frontend->shared_shutdown };
	}
}

my $first = frontend(ctor => [start => 10, tag => 'first']);

is($first->shared_class, 'Shared::Counter', 'the frontend knows what it wraps');
like($first->shared_address, qr/\.sock\z/, 'it knows where its backend is');
ok($first->shared_connected, 'it is connected to a backend');
ok(defined $first->shared_id, 'it has an object id');
ok(!defined $INC{'Shared/Counter.pm'}, 'the frontend never loads the target class');

is($first->value, 10, 'constructor arguments reached the object');
is($first->tag, 'first', 'named constructor arguments survive');
is($first->inc, 11, 'a call changes the object');
is($first->inc(4), 15, 'a call with an argument works');

# A second frontend is a second object, in the same one copy of the code.
my $second = frontend(ctor => [start => 100]);

isnt($second->shared_id, $first->shared_id, 'a second frontend holds a second object');
is($second->shared_pid, $first->shared_pid, 'both objects live in the same backend');
is($second->pid, $first->pid, 'and in the same process');
is($second->value, 100, 'the second object was built with its own arguments');
is($second->tag, undef, 'and has its own state');
is($second->inc, 101, 'the second object changes on its own');
is($first->value, 15, 'the first object is untouched');
is($first->constructed, 2, 'the class was constructed once per object, not once per call');

# Calling context is preserved.
is_deeply([$first->triple], [1, 2, 3], 'list context gets the whole list');
my @triple = $first->shared_call('triple');
is(scalar(@triple), 3, 'shared_call honours list context');
my $scalar = $first->triple;
is($scalar, 3, 'scalar context gets the scalar value');
is(scalar($first->empty_list), undef, 'an empty list in scalar context');
my @empty = $first->empty_list;
is(scalar(@empty), 0, 'an empty list in list context stays empty');
is($first->one, 'one', 'an ordinary scalar comes back');
is($first->maybe_undef, undef, 'undef survives the trip');
is_deeply([$first->echo_list('a', 'b')], ['a', 'b'], 'arguments come back intact');

# Errors from the target are rethrown in the client.
eval { $first->boom('bad thing') };
like($@, qr/kaboom: bad thing/, 'the target exception is rethrown');
like($@, qr/Counter\.pm/, 'with the target file the original die() pointed at');

# Misuse is refused.
eval { $first->no_such_method };
like($@, qr/has no method 'no_such_method'/, 'unknown methods are refused');

ok($first->can('inc'), 'can() answers through the proxy');
ok(!$first->can('no_such_method'), 'can() says no to missing methods');
my $code = $first->can('inc');
is($first->$code, 16, 'the code reference can() returned really calls the object');
ok($first->isa('Shared::Counter'), 'isa() answers through the proxy');

# A class that cannot be loaded is refused at the handshake, and the refusal
# says which module was missing, so a frontend with a typo learns what it was.
{
	my $socket = IO::Socket::UNIX->new(
		Type => SOCK_STREAM,
		Peer => $first->shared_address,
	);
	ok($socket, 'the socket can be opened directly');

	my ($bytes) = Class::Shared::Protocol::encode_frame({
		op    => 'hello',
		proto => $Class::Shared::PROTOCOL_VERSION,
		class => 'Shared::SomethingElse',
	});
	Class::Shared::Protocol::write_all($socket, $bytes);
	my ($response) = Class::Shared::Protocol::read_frame($socket);
	ok(!$response->{ok}, 'a request for a class that does not exist is refused');
	like($response->{error}, qr/cannot load Shared::SomethingElse/,
		'and names the module it could not load');
	close $socket;
}

# A call before the handshake is refused, and another client's object is out
# of reach even with its id.
{
	my $socket = IO::Socket::UNIX->new(
		Type => SOCK_STREAM,
		Peer => $first->shared_address,
	);

	my ($ping) = Class::Shared::Protocol::encode_frame({ op => 'ping' });
	Class::Shared::Protocol::write_all($socket, $ping);
	my ($refused) = Class::Shared::Protocol::read_frame($socket);
	like($refused->{error}, qr/handshake required/, 'the handshake cannot be skipped');

	my ($hello) = Class::Shared::Protocol::encode_frame({
		op    => 'hello',
		proto => $Class::Shared::PROTOCOL_VERSION,
		class => 'Shared::Counter',
	});
	Class::Shared::Protocol::write_all($socket, $hello);
	my ($greeted) = Class::Shared::Protocol::read_frame($socket);
	ok($greeted->{ok}, 'a second connection can handshake');

	my ($call) = Class::Shared::Protocol::encode_frame({
		op     => 'call',
		id     => $first->shared_id,
		method => 'value',
		args   => [],
		want   => 'scalar',
	});
	Class::Shared::Protocol::write_all($socket, $call);
	my ($answer) = Class::Shared::Protocol::read_frame($socket);
	ok(!$answer->{ok}, "another client's object cannot be called");
	like($answer->{error}, qr/belongs to another connection/, 'and the reason is clear');

	my ($bogus) = Class::Shared::Protocol::encode_frame({
		op     => 'call',
		id     => 999_999,
		method => 'value',
		args   => [],
		want   => 'scalar',
	});
	Class::Shared::Protocol::write_all($socket, $bogus);
	my ($nobody) = Class::Shared::Protocol::read_frame($socket);
	like($nobody->{error}, qr/no object #999999/, 'an unknown id is refused');

	close $socket;
}

# Status.
my $status = $first->shared_status;
ok($status->{ok}, 'ping answers');
is_deeply($status->{classes}, ['Shared::Counter'], 'status names the classes it has loaded');
is($status->{objects}, 2, 'status counts the objects the backend holds');
is($status->{constructed}, 2, 'and how many were built');
ok($status->{calls} > 0, 'status counts calls');
is($status->{pid}, $first->shared_pid, 'status reports the backend pid');

# Releasing a frontend releases its object.
$second->shared_close;
is(wait_for_objects($first, 1), 1, 'closing a frontend destroys its object');

eval { $second->value };
like($@, qr/no connection/, 'a closed frontend cannot be called');

# Letting a frontend go out of scope releases its object the same way.
{
	my $temporary = frontend(ctor => [start => 7]);
	is(scalar($first->shared_status->{objects}), 2, 'a third object exists while its frontend does');
	$temporary->shared_close;
}
is(wait_for_objects($first, 1), 1, 'destroying a frontend destroys its object');

# The singleton itself: a second backend for the same class must refuse.
{
	my $intruder = Class::Shared::Backend->new(
		dir           => $dir,
		start_timeout => 0.2,
	);
	eval { $intruder->_setup };
	like($@, qr/another backend is already serving/, 'a second backend refuses to start');
}

# Shutdown, then a clean restart with one fresh object.
ok($first->shared_shutdown, 'the backend shuts down on request');
ok(!-e $first->shared_socket_path, 'the socket is removed');
ok(!$first->shared_connected, 'the frontend is disconnected');

my $third = frontend();

is($third->value, 0, 'a new backend starts with a new object');
is($third->constructed, 1, 'the new backend constructed exactly one object');
is($third->shared_status->{objects}, 1, 'and holds exactly one');

ok($third->shared_shutdown, 'the second backend shuts down too');

# A token is for TCP: on a unix socket the mode 0600 file is the check, so
# asking for both is a mistake worth naming.
eval { Class::Shared::Frontend->new('Shared::Counter', dir => $dir, token => 's3cret'); 1 };
like($@, qr/a unix socket needs no token/, 'the frontend refuses a token on a unix socket');

eval { Class::Shared::Backend->new(dir => $dir, token => 's3cret'); 1 };
like($@, qr/a unix socket needs no token/, 'and so does the backend');

# TLS is for TCP for the same reason: the kernel has already decided who may
# connect to a 0600 socket, so a certificate there only looks like a defence.
eval { Class::Shared::Frontend->new('Shared::Counter', dir => $dir, tls_ca => 'ca.pem'); 1 };
like($@, qr/a unix socket needs no TLS/, 'the frontend refuses TLS on a unix socket');

eval { Class::Shared::Backend->new(dir => $dir, tls_cert => 'cert.pem'); 1 };
like($@, qr/a unix socket needs no TLS/, 'and so does the backend');

eval { Class::Shared::Frontend->new('Shared::Counter', dir => $dir, tls_fingerprint => ('ab' x 32)); 1 };
like($@, qr/a unix socket needs no TLS/, 'and so does a pinned fingerprint');

done_testing();
