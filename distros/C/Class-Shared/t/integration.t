#!/usr/bin/env perl

# End-to-end tests of Class::Shared: the frontend, the backend, the protocol
# and the command line working together, checked against what the POD says.
#
# Strategy: nothing here replaces the backend.  Backends are real processes
# (started by the frontend itself, by bin/class-shared, or by a forked
# Class::Shared::Backend), and the only fakes are small servers that play a
# backend badly (garbage, silence, a closed door) to see how a client copes.
# Test::Mockingbird's spy records what the frontend hands to the protocol
# without changing what it does.
#
# Set TEST_VERBOSE=1 to see the state the subtests print with diag.

use strict;
use warnings;

use Test::Most;
use Test::Needs;

BEGIN {
	test_needs 'Test::Mockingbird', 'Test::Returns', 'Test::Permissions', 'Test::Without::Module';

	require Class::Shared;
	plan skip_all => 'a backend needs unix sockets in an owner-only directory, which this perl cannot provide'
		unless Class::Shared::_has_unix_sockets() && Test::Permissions::can_revoke_create();

	Test::Mockingbird->import;
	Test::Returns->import;
	Test::Permissions->import(qw(:revoke :guard :report));
}

use File::Spec ();
use File::Temp qw(tempdir);
use IO::Socket::UNIX ();
use POSIX ();
use Socket qw(SOCK_STREAM);
use Time::HiRes ();

use lib 'lib', 't/lib';

# Every number and string the subtests depend on is named here, once.
my %config = (
	class        => 'Shared::Counter',
	other_class  => 'Shared::Tally',
	start_wait   => 15,        # a backend must answer within this
	quick        => 5,         # a failure that must not hang must arrive within this
	short_timeout=> 1,
	call_limit   => 1,         # the backend's call_timeout in the runaway-call test
	busy_seconds => 4,         # how long the method that keeps a backend busy takes         # the frontend's timeout option where a stall is wanted
	watchdog     => 240,       # the whole file must end within this
	token        => 's3cret-token',
	certs        => File::Spec->catdir('t', 'certs'),
	cli          => "$^X -Ilib -It/lib bin/class-shared",
);

my $VERBOSE = $ENV{TEST_VERBOSE};

$SIG{ALRM} = sub { BAIL_OUT("t/integration.t ran for more than $config{watchdog} seconds") };
alarm $config{watchdog};

sub state_of {
	diag(@_) if $VERBOSE;
	return;
}

sub private_dir {
	my $dir = tempdir(CLEANUP => 1);
	chmod 0700, $dir;
	return $dir;
}

# Run $code and say what it died with, what it warned, and how long it took.
# A hang is a failure, not a wait.
sub outcome {
	my ($code) = @_;

	my @warnings;
	my ($value, $died);
	my $start = Time::HiRes::time();
	{
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		local $SIG{ALRM} = sub { die "HUNG\n" };
		alarm $config{quick} * 4;
		$value = eval { $code->() };
		$died = $@;
		alarm $config{watchdog};
	}

	return { value => $value, died => $died, warnings => \@warnings, seconds => Time::HiRes::time() - $start };
}

sub slurp {
	my ($path) = @_;
	open(my $fh, '<', $path) or return '';
	local $/;
	my $text = <$fh>;
	close($fh);
	return defined $text ? $text : '';
}

# The backends this file starts are stopped, whatever happens.
my @started;
END {
	# system() would replace the exit status of the test with its own.
	local $?;
	foreach my $dir (@started) {
		system("$config{cli} stop --dir $dir >/dev/null 2>&1");
	}
}

sub frontend {
	my ($dir, %option) = @_;
	my $class = delete $option{class} || $config{class};
	return Class::Shared::Frontend->new($class, dir => $dir, %option);
}

use_ok($_) for qw(Class::Shared Class::Shared::Protocol Class::Shared::Frontend Class::Shared::Backend);

# ===========================================================================
# One backend, many clients
# ===========================================================================

subtest 'a frontend starts a backend and several frontends share it' => sub {
	my $dir = private_dir();
	push @started, $dir;

	my $first = frontend($dir, ctor => [start => 10]);
	isa_ok($first, 'Class::Shared::Frontend');
	my $pid = $first->shared_pid;
	ok($pid && $pid != $$, 'a separate backend process was started');
	ok(-S $first->shared_socket_path, 'and its socket exists');
	state_of("backend pid $pid at " . $first->shared_address);

	# Independent objects: each frontend has an object of its own in the one backend.
	my $second = frontend($dir, ctor => [start => 100]);
	my $third = frontend($dir, ctor => [start => 1000]);
	is($second->shared_pid, $pid, 'a second frontend reaches the same backend');
	is($third->shared_pid, $pid, 'and a third');
	isnt($first->shared_id, $second->shared_id, 'each has an object of its own');

	is($first->value, 10, 'the first object kept its own start');
	is($second->value, 100, 'the second its own');
	is($first->inc(5), 15, 'a call on the first changes only the first');
	is($second->value, 100, 'the second is not affected');
	is($third->add(1, 2, 3), 1006, 'a list of arguments reaches the target');

	is_deeply([$first->triple], [1, 2, 3], 'list context comes back as a list');
	is(scalar $first->one, 'one', 'scalar context comes back as a scalar');
	is_deeply([$first->empty_list], [], 'an empty list stays empty');

	my $status = $first->shared_status;
	returns_ok($status, { type => 'hashref' }, 'status is a hash reference');
	is($status->{objects}, 3, 'the backend holds three objects');
	is($status->{clients}, 3, 'for three clients');
	is($status->{pid}, $pid, 'and says whose it is');
	is_deeply($status->{classes}, [$config{class}], 'having loaded one class');

	# Leaving takes only your own object away.
	$second->shared_close;
	# The backend learns of the close from its own loop, so it may answer this
	# frontend before it has dealt with that one.
	my $deadline = time + 5;
	Class::Shared::poll_pause()
		while $first->shared_status->{objects} != 2 && time < $deadline;
	is($first->shared_status->{objects}, 2, 'a closed frontend\'s object is gone');
	is($third->value, 1006, 'the others carry on');

	# Instances created in the same block do not share any state.
	my $other = Class::Shared::Frontend->new($config{class}, dir => $dir, ctor => [start => 7]);
	is($other->value, 7, 'a frontend made later starts clean');
	is($first->value, 15, 'and does not disturb the first');

	is($first->shared_shutdown, 1, 'a shutdown request is accepted');
	ok(!-e $first->{socket_path} && !defined $first->shared_pid, 'afterwards the socket is gone and the frontend is closed');
	like(slurp(File::Spec->catfile($dir, 'class-shared.sock.log')), qr/serving on .*\n.*shutdown requested.*\n.*stopped/s, 'the backend logged its life: start, shutdown, stop');
};

subtest 'one backend can serve two classes, and two backends are independent' => sub {
	my $dir = private_dir();
	push @started, $dir;
	my $other_dir = private_dir();
	push @started, $other_dir;

	my $counter = frontend($dir, ctor => [start => 1]);
	my $tally = frontend($dir, class => $config{other_class}, ctor => [start => 50]);
	is($counter->shared_pid, $tally->shared_pid, 'two classes in one backend');
	is($tally->add(5), 55, 'the second class works');
	is($counter->inc, 2, 'and the first');
	is_deeply([sort @{ $counter->shared_status->{classes} }], [sort $config{class}, $config{other_class}], 'the backend has loaded both');

	my $apart = frontend($other_dir, ctor => [start => 1]);
	isnt($apart->shared_pid, $counter->shared_pid, 'another directory has a backend of its own');
	$apart->inc for 1 .. 3;
	is($counter->value, 2, 'what happens in one does not reach the other');

	$counter->shared_shutdown;
	is($apart->value, 4, 'stopping one backend leaves the other running');
	is($apart->shared_shutdown, 1, 'and it stops on its own request');
};

subtest 'the frontend passes its requests to the protocol, and the target\'s errors come back' => sub {
	my $dir = private_dir();
	push @started, $dir;

	my $spy_encode = Test::Mockingbird::spy('Class::Shared::Protocol::encode_frame');
	my $spy_read = Test::Mockingbird::spy('Class::Shared::Protocol::read_frame');

	my $frontend = frontend($dir, ctor => [start => 2]);
	my $incremented = $frontend->inc(3);
	my @messages = map { $_->[1] } $spy_encode->();
	is_deeply([map { $_->{op} } @messages], [qw(hello new call)], 'the frontend says hello, asks for an object, then calls');
	is($messages[0]{class}, $config{class}, 'the hello names the class');
	is($messages[1]{args}[1], 2, 'the constructor arguments are sent');
	is_deeply([@{ $messages[2] }{qw(method args want)}], ['inc', [3], 'scalar'], 'a call carries the method, the arguments and the context');
	is(scalar(grep { defined $_->[2] } $spy_encode->()), 0, 'a unix socket sends no secret');
	cmp_ok(scalar($spy_read->()), '>=', 3, 'every request waited for its answer');
	Test::Mockingbird::restore_all();

	# The target's own exception text arrives unchanged.
	throws_ok { $frontend->boom('now') } qr/\Akaboom: now at /, 'a target that dies: its own text comes back';
	is($frontend->inc, 6, 'and the object still works afterwards');
	throws_ok { $frontend->no_such_method } qr/has no method 'no_such_method'/, 'a method the target lacks';
	throws_ok { $frontend->shared_call('Other::function') } qr/is not a plain method name/, 'a qualified method name is refused';

	# can and isa follow the target.
	ok($frontend->can('inc'), 'can: the target\'s method');
	ok(!$frontend->can('no_such_method'), 'can: not a method it lacks');
	ok($frontend->can('shared_call'), 'can: the frontend\'s own methods');

	$frontend->shared_shutdown;
};

# ===========================================================================
# The command line
# ===========================================================================

subtest 'bin/class-shared start, status and stop work with a frontend' => sub {
	my $dir = private_dir();
	push @started, $dir;
	my $cli = $config{cli};

	# First-time user: nothing is running, so status says so and exits non-zero.
	my $nothing = `$cli status --dir $dir 2>/dev/null`;
	isnt($? >> 8, 0, 'status with no backend exits non-zero');
	is($nothing, '', 'and prints nothing');

	chomp(my $path = `$cli path --dir $dir`);
	is($path, Class::Shared::socket_path($dir), 'path names the socket a frontend would use');

	system("$cli start --dir $dir");
	is($? >> 8, 0, 'start in the background returns 0');
	my $until = time + $config{start_wait};
	select(undef, undef, undef, 0.1) until -S $path || time > $until;
	ok(-S $path, 'the backend came up');

	my $status = `$cli status --dir $dir 2>&1`;
	is($? >> 8, 0, 'status now exits 0');
	like($status, qr/^pid \d+/m, 'and names the backend');

	my $frontend = frontend($dir, ctor => [start => 4], autostart => 0);
	is($frontend->inc, 5, 'a frontend (no autostart) uses the backend the command started');
	like(`$cli status --dir $dir 2>&1`, qr/\b1 object\(s\)/, 'status counts the frontend\'s object');

	my $stopped = `$cli stop --dir $dir 2>&1`;
	is($? >> 8, 0, 'stop exits 0');
	like($stopped, qr/\Astopped\n?\z/, 'and prints "stopped"');
	ok(!-e $path, 'the socket is gone when stop returns');
	throws_ok { $frontend->inc } qr/\AClass::Shared: lost the backend for '\Q$config{class}\E': /, 'the frontend of a stopped backend says it lost it';
	throws_ok { $frontend->inc } qr/its object is gone/, 'and then says its object is gone';

	system("$cli stop --dir $dir >/dev/null 2>&1");
	isnt($? >> 8, 0, 'stop with nothing running exits non-zero');
};

# ===========================================================================
# Things that go wrong
# ===========================================================================

subtest 'a backend that dies underneath a frontend' => sub {
	my $dir = private_dir();
	push @started, $dir;

	my $frontend = frontend($dir, ctor => [start => 1]);
	my $pid = $frontend->shared_pid;
	kill 'KILL', $pid;
	my $until = time + $config{quick};
	select(undef, undef, undef, 0.05) while kill(0, $pid) && time < $until;

	my $result = outcome(sub { $frontend->inc });
	like($result->{died}, qr/\AClass::Shared: lost the backend for '\Q$config{class}\E': /, 'the call fails and names the cause');
	cmp_ok($result->{seconds}, '<', $config{quick}, 'without hanging');
	is_deeply($result->{warnings}, [], 'and without warnings');
	is($frontend->shared_connected, 0, 'the frontend is closed');

	# The next frontend finds the dead backend's socket and starts a new one.
	my $fresh = outcome(sub { frontend($dir, ctor => [start => 9]) });
	is($fresh->{died}, '', 'a new frontend recovers: it replaces the leftover socket') or diag $fresh->{died};
	is($fresh->{value}->value, 9, 'and has a working object');
	isnt($fresh->{value}->shared_pid, $pid, 'in a new backend');
	$fresh->{value}->shared_shutdown;
};

# Play a backend badly: accept one connection and do $behave with it.
sub fake_backend {
	my ($dir, $behave) = @_;

	my $path = Class::Shared::socket_path($dir);
	my $listen = IO::Socket::UNIX->new(Type => SOCK_STREAM, Local => $path, Listen => 5) or die "listen: $!";

	my $pid = fork() // die "fork: $!";
	if (!$pid) {
		while (my $client = $listen->accept) {
			$behave->($client);
		}
		POSIX::_exit(0);
	}
	close($listen);

	return $pid;
}

subtest 'a backend that answers badly or not at all' => sub {
	my %behaviours = (
		'closes the door' => [sub { close($_[0]) },
			qr/\AClass::Shared: cannot reach a backend at \S+: handshake failed: (?:connection closed by peer|read failed: .+|write failed: .+)/],
		'sends garbage' => [sub { my $s = shift; syswrite($s, pack('N', 4) . 'junk'); sleep 1 },
			qr/\AClass::Shared: cannot reach a backend at \S+: handshake failed: cannot deserialise message: /],
		'claims a huge frame' => [sub { my $s = shift; syswrite($s, pack('N', 0xFFFFFFF0)); sleep 1 },
			qr/\AClass::Shared: cannot reach a backend at \S+: handshake failed: frame of \d+ bytes exceeds the limit of \d+/],
	);

	foreach my $name (sort keys %behaviours) {
		my ($behave, $expected) = @{ $behaviours{$name} };
		my $dir = private_dir();
		my $pid = fake_backend($dir, $behave);

		my $result = outcome(sub { frontend($dir, autostart => 0, timeout => $config{short_timeout}) });
		like($result->{died}, $expected, "a backend that $name: the frontend fails with the documented reason");
		cmp_ok($result->{seconds}, '<', $config{quick}, '  and does not hang');
		is_deeply($result->{warnings}, [], '  and does not warn');

		kill 'KILL', $pid;
		waitpid($pid, 0);
	}
};

# A backend that is busy running another client's method answers late.  The
# frontend's timeout covers that wait, so a caller learns what is going on
# instead of waiting without end.  The busy backend here is a real one.
subtest 'a busy backend: the handshake gives up after the timeout' => sub {
	my $dir = private_dir();
	push @started, $dir;

	my $busy = frontend($dir, ctor => [start => 1]);
	my $pid = $busy->shared_pid;

	# Another process occupies the backend with a method that takes a while.
	my $hog = fork() // die "fork: $!";
	if (!$hog) {
		eval { $busy->sleepy($config{busy_seconds}) };
		POSIX::_exit(0);
	}
	select(undef, undef, undef, 0.5);

	my $result = outcome(sub { frontend($dir, autostart => 0, timeout => $config{short_timeout}) });
	like($result->{died}, qr/\AClass::Shared: cannot reach a backend at \S+: handshake failed: timed out waiting for a reply \(the backend may be busy running another client's method; try again, or raise timeout\)\n\z/, 'a frontend that cannot be served in time says the backend is busy');
	cmp_ok($result->{seconds}, '<', $config{busy_seconds}, '  and gave up before the method ended');
	is_deeply($result->{warnings}, [], '  without warnings');

	waitpid($hog, 0);
	my $later = outcome(sub { frontend($dir, autostart => 0, timeout => $config{short_timeout}) });
	is($later->{died}, '', 'once the method has ended the same call succeeds') or diag $later->{died};
	$later->{value}->shared_shutdown if $later->{value};
};

# The backend serves one request at a time, so a call that does not return
# would hold every client.  call_timeout ends it: one client's slow call is
# stopped, and the other client, who was waiting behind it, is served.
subtest 'a runaway call is stopped and does not hold the other clients' => sub {
	my $dir = private_dir();
	my $socket = File::Spec->catfile($dir, 'b.sock');

	my $pid = fork() // die "fork: $!";
	if (!$pid) {
		eval { Class::Shared::Backend->new(socket => $socket, log => "$socket.log", call_timeout => $config{call_limit})->run };
		POSIX::_exit(0);
	}
	my $until = time + $config{start_wait};
	select(undef, undef, undef, 0.05) until -S $socket || time > $until;

	my $slow = Class::Shared::Frontend->new($config{class}, socket => $socket, autostart => 0);
	my $other = Class::Shared::Frontend->new($config{class}, socket => $socket, autostart => 0, ctor => [start => 40]);
	is($slow->shared_status->{pid}, $pid, 'a backend with a short call_timeout is running');

	my $hog = fork() // die "fork: $!";
	if (!$hog) {
		my $answer = eval { $slow->sleepy($config{busy_seconds} * 5); 'finished' } || $@;
		POSIX::_exit($answer =~ /took longer than call_timeout/ ? 0 : 1);
	}
	select(undef, undef, undef, 0.3);

	my $start = time;
	is($other->value, 40, 'a second client, queued behind the runaway call, is served');
	cmp_ok(time - $start, '<=', $config{call_limit} + 2, 'once the call has been stopped, and not after it would have finished');
	waitpid($hog, 0);
	is($? >> 8, 0, 'the runaway call got the "took longer than call_timeout" error');

	is($slow->inc, 1, 'its object is still there and works');
	like(slurp("$socket.log"), qr/sleepy took longer than call_timeout \($config{call_limit} seconds\) and was stopped/, 'the log says which call was stopped');

	$other->shared_shutdown;
	waitpid($pid, 0);
};

subtest 'a directory that cannot be used' => sub {
	my $parent = private_dir();
	my $dir = File::Spec->catdir($parent, 'cs');
	mkdir $dir, 0700 or die;

	# No permission to create the socket or the lock: the backend cannot start.
	with_revoked(create => $dir, sub {
		my $result = outcome(sub { frontend($dir) });
		like($result->{died}, qr/\AClass::Shared: could not start a backend: /, 'create revoked: the failure is explained');
		like($result->{died}, qr/\(socket \Q$dir\E\/class-shared\.sock, log \Q$dir\E\/class-shared\.sock\.log\)\n\z/, '  with the socket and log it would have used');
		cmp_ok($result->{seconds}, '<', $config{start_wait}, '  and the wait is bounded');
		is_deeply($result->{warnings}, [], '  without warnings');
	}) if can_revoke_create($dir);

	# No permission to search the directory: no socket can be reached.
	with_revoked(search => $dir, sub {
		my $result = outcome(sub { frontend($dir, autostart => 0) });
		like($result->{died}, qr/\AClass::Shared: cannot reach a backend at /, 'search revoked: the failure is explained');
		cmp_ok($result->{seconds}, '<', $config{quick}, '  and quick');
	}) if can_revoke_search($dir);

	# Nothing was left broken: the same directory works once it is allowed again.
	my $frontend = outcome(sub { frontend($dir, ctor => [start => 1]) });
	is($frontend->{died}, '', 'after the permissions return, the same directory works') or diag $frontend->{died};
	push @started, $dir;
	$frontend->{value}->shared_shutdown if $frontend->{value};

	# A directory that others can write to is refused, and nothing is started in it.
	my $open = private_dir();
	chmod 0777, $open;
	my $refused = outcome(sub { frontend($open) });
	like($refused->{died}, qr/\AClass::Shared: could not start a backend: \Q$open\E is writable by group or others; refusing to use it/, 'a directory others can write to is refused');
	ok(!-e File::Spec->catfile($open, 'class-shared.sock'), 'no socket was made there');
	chmod 0700, $open;

	# A log that cannot be written does not stop the backend serving.
	my $log_dir = private_dir();
	my $log = File::Spec->catfile($log_dir, 'no-such-dir', 'b.log');
	my $quiet = outcome(sub { frontend(private_dir(), log => $log, ctor => [start => 2]) });
	is($quiet->{died}, '', 'a log that cannot be opened does not stop the backend') or diag $quiet->{died};
	if ($quiet->{value}) {
		is($quiet->{value}->inc, 3, 'and it serves');
		$quiet->{value}->shared_shutdown;
	}
};

subtest 'a first-time user, in unusual orders' => sub {
	my $dir = private_dir();
	push @started, $dir;

	# No class, nothing at all.
	my $none = outcome(sub { Class::Shared::Frontend->new() });
	like($none->{died}, qr/\AClass::Shared::Frontend->new: no class name given\n\z/, 'new with nothing: a clear sentence');
	is_deeply($none->{warnings}, [], '  and no warning');

	my $bad = outcome(sub { Class::Shared::Frontend->new('not a class!', dir => $dir) });
	like($bad->{died}, qr/\AClass::Shared: 'not a class!' is not a valid class name\n\z/, 'an invalid class name');
	ok(!-e File::Spec->catfile($dir, 'class-shared.sock'), 'and no backend was started for it');

	my $missing = outcome(sub { frontend($dir, class => 'No::Such::Class') });
	like($missing->{died}, qr/\AClass::Shared: cannot load No::Such::Class: Can't locate No\/Such\/Class\.pm in \@INC/, 'a class that does not exist: Perl\'s own reason');

	# Minimal input works: no ctor, no options.
	my $frontend = frontend($dir);
	is($frontend->value, 0, 'the constructor with no arguments works');

	# Repeated and out of order calls.
	is($frontend->shared_close, 1, 'close once: 1');
	is($frontend->shared_close, 0, 'close again: 0, not an error');
	is($frontend->shared_shutdown, 0, 'shutdown after close: 0, not an error');
	is($frontend->shared_pid, undef, 'the pid is undef once closed');
	throws_ok { $frontend->shared_status } qr/this frontend has no connection to a backend/, 'status after close says why it cannot';

	my $again = frontend($dir);
	is($again->shared_shutdown, 1, 'shutdown works for a frontend that never called anything');
	is($again->shared_shutdown, 0, 'and a second shutdown is 0');

	# A new frontend after the stop starts a new backend.
	my $reborn = frontend($dir, ctor => [start => 3]);
	is($reborn->value, 3, 'after a shutdown the next frontend starts a backend again');
	$reborn->shared_shutdown;

	# Options in the wrong place.
	my $token = outcome(sub { frontend($dir, token => $config{token}) });
	like($token->{died}, qr/\AClass::Shared::Frontend->new: a unix socket needs no token: /, 'a token on a unix socket is refused with the reason');
	my $path = outcome(sub { frontend('x' x 120) });
	like($path->{died}, qr/\AClass::Shared: socket path '.*' is \d+ characters, more than the 100 allowed/, 'a directory that makes the socket path too long');
};

# ===========================================================================
# Optional dependencies
# ===========================================================================

# The one optional dependency is IO::Socket::SSL, loaded only for TCP.  A
# child process runs with it hidden, so nothing it has loaded here leaks in.
my %pem = map { $_ => File::Spec->catfile($config{certs}, "$_.pem") } qw(ca server server-key client client-key other-ca other-client other-client-key);

sub in_child {
	my ($code) = @_;
	pipe(my $reader, my $writer) or die "pipe: $!";
	my $pid = fork() // die "fork: $!";
	if (!$pid) {
		close($reader);
		my @answer = eval { $code->() };
		my $text = $@ ? "DIED:$@" : join("\n", map { defined $_ ? $_ : '(undef)' } @answer);
		print {$writer} $text;
		close($writer);
		POSIX::_exit(0);
	}
	close($writer);
	local $/;
	my $text = <$reader>;
	waitpid($pid, 0);
	return defined $text ? $text : '';
}

subtest 'without IO::Socket::SSL, unix sockets still work and TCP says why it cannot' => sub {
	my $dir = private_dir();
	push @started, $dir;

	my $answer = in_child(sub {
		require Test::Without::Module;
		Test::Without::Module->import('IO::Socket::SSL');
		delete $INC{'IO/Socket/SSL.pm'};
		require Class::Shared::Frontend;
		my $frontend = Class::Shared::Frontend->new($config{class}, dir => $dir, ctor => [start => 2]);
		my $value = $frontend->inc;
		my $tls = '';
		my $tcp = eval {
			Class::Shared::Frontend->new($config{class}, host => '127.0.0.1', port => 1, tls_cert => 'c', tls_key => 'k', tls_ca => 'ca', token => 't', timeout => $config{short_timeout});
			'connected';
		} || $@;
		return ($value, $tls, $tcp);
	});
	my ($value, $tcp) = (split /\n/, $answer, 3)[0, 2];
	is($value, 3, 'a unix frontend works with the TLS library missing');
	ok(length($answer) > 0, 'the child reported');
	like($tcp // '', qr/IO\/Socket\/SSL\.pm|SSL/, 'a TCP frontend says the TLS library is missing');
	unlike($tcp // '', qr/\bconnected\b/, 'and does not pretend to connect');
	state_of("without SSL: $answer");

	# Everything available: the same child, nothing hidden, gets as far as the network.
	subtest 'with IO::Socket::SSL' => sub {
		test_needs 'IO::Socket::SSL';
		my $with = in_child(sub {
			eval { Class::Shared::Frontend->new($config{class}, host => '127.0.0.1', port => 1, tls_cert => $pem{client}, tls_key => $pem{'client-key'}, tls_ca => $pem{ca}, token => 't', timeout => $config{short_timeout}); 1 };
			return $@;
		});
		like($with, qr/cannot reach a backend at 127\.0\.0\.1:1/, 'with the library present a TCP frontend fails only at the network');
	};

	my $frontend = frontend($dir);
	$frontend->shared_shutdown;
};

# ===========================================================================
# TCP with TLS
# ===========================================================================

subtest 'a TCP backend with TLS serves frontends that hold the right credentials' => sub {
	test_needs 'IO::Socket::SSL';

	my $dir = private_dir();
	my $token_file = File::Spec->catfile($dir, 'token');
	open(my $fh, '>', $token_file) or die; print {$fh} "$config{token}\n"; close($fh);
	chmod 0600, $token_file;

	my $probe = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp', Listen => 1, ReuseAddr => 1) or plan skip_all => "no TCP: $!";
	my $port = $probe->sockport;
	close($probe);

	my $pid = fork() // die;
	if (!$pid) {
		my $status = eval {
			Class::Shared::Backend->new(
				host => '127.0.0.1', port => $port, token => $config{token},
				tls_cert => $pem{server}, tls_key => $pem{'server-key'}, tls_ca => $pem{ca},
				dir => $dir, log => File::Spec->catfile($dir, 'log'),
			)->run;
		};
		if (!defined $status) { open(my $e, '>>', File::Spec->catfile($dir, 'log')); print {$e} "died: $@"; close($e) }
		POSIX::_exit(defined $status ? $status : 99);
	}

	my %good = (host => '127.0.0.1', port => $port, token_file => $token_file, tls_ca => $pem{ca}, tls_cert => $pem{client}, tls_key => $pem{'client-key'}, timeout => $config{short_timeout});

	my $first;
	for (1 .. 200) {
		$first = eval { Class::Shared::Frontend->new($config{class}, %good, ctor => [start => 1]) };
		last if $first;
		select(undef, undef, undef, 0.05);
	}
	ok($first, 'a frontend with the right credentials gets an object') or BAIL_OUT('no TLS backend: ' . slurp(File::Spec->catfile($dir, 'log')));

	my $second = Class::Shared::Frontend->new($config{class}, %good, ctor => [start => 20]);
	is($first->shared_pid, $pid, 'it is the backend we started');
	is($first->shared_address, "127.0.0.1:$port", 'at the address we gave');
	is($first->inc, 2, 'a call works over TLS');
	is($second->value, 20, 'a second frontend has its own object');
	is($first->shared_status->{clients}, 2, 'both are clients of the one backend');

	# Wrong credentials are refused at the handshake, and quickly.
	my %cases = (
		'a wrong token'           => [{ token_file => undef, token => 'wrong' }, qr/token|authenticat|refused|lost the backend/i],
		'a certificate from another CA' => [{ tls_cert => $pem{'other-client'}, tls_key => $pem{'other-client-key'} }, qr/certificate|refused|lost the backend|cannot (?:connect|reach)/i],
		'the wrong CA to check the backend' => [{ tls_ca => $pem{'other-ca'} }, qr/certificate|verify|cannot (?:connect|reach)/i],
	);
	foreach my $name (sort keys %cases) {
		my ($override, $expected) = @{ $cases{$name} };
		my %option = (%good, %$override);
		delete @option{ grep { !defined $option{$_} } keys %option };
		my $result = outcome(sub { Class::Shared::Frontend->new($config{class}, %option) });
		like($result->{died}, $expected, "$name is refused");
		cmp_ok($result->{seconds}, '<', $config{quick}, '  quickly');
	}
	is($first->inc, 3, 'the refusals did not disturb the clients that were connected');

	# Plain TCP, with no TLS at all, cannot talk to it.
	my $plain = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp');
	ok($plain, 'a plain TCP connection can be made');
	if ($plain) {
		require Class::Shared::Protocol;
		my ($bytes) = Class::Shared::Protocol::encode_frame({ op => 'hello', proto => 2 }, $config{token});
		Class::Shared::Protocol::write_all($plain, $bytes);
		my ($reply) = Class::Shared::Protocol::read_frame($plain, $config{short_timeout}, $config{token});
		ok(!$reply || !$reply->{ok}, 'but the backend does not answer a client that skipped TLS');
	}

	is($first->shared_shutdown, 1, 'a shutdown request over TLS is accepted');
	my $until = time + $config{start_wait};
	my $reaped = 0;
	while (time < $until && !$reaped) {
		$reaped = waitpid($pid, POSIX::WNOHANG()) == $pid;
		select(undef, undef, undef, 0.05);
	}
	ok($reaped, 'and the backend process ends');
	kill 'KILL', $pid unless $reaped;
};

alarm 0;
done_testing();
