#!/usr/bin/env perl

# State transition tests for the finite state machine in the POD of
# lib/App/Syslogd.pm (=head1 STATE DIAGRAM, "Transition table").
#
# The tables are read from the POD when the test runs, so the test
# enforces the diagram:
#	* every documented transition (row x From state) must have a test
#	  here, or "documented transition has a test" fails;
#	* every test here must match a documented transition, or "every test
#	  is a documented transition" fails.
# A transition the code allows but the diagram does not show belongs in
# the "transitions the diagram does not allow" subtests, which must prove
# it is refused (or harmless).
#
# The state of a server is read from three facts: bound (a socket),
# logging (an open log) and running.  RUNNING and STOPPING exist only
# inside run(), so they are observed from the steps of a socket double.
#
# Also tested: the state machines of App::Syslogd::Cache and
# App::Syslogd::I18N, from their own STATE DIAGRAM sections.

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Errno qw(EBADF EINTR ENOSPC);
use File::Spec;
use File::Temp qw(tempdir);
use Readonly;
use Socket qw(pack_sockaddr_in inet_aton);
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

# Make writes fail on demand (the "a write fails" transition).  Installed
# before App::Syslogd is compiled, as CORE::GLOBAL overrides must be.
our $DISK_FULL = 0;
BEGIN {
	mock_core('syswrite' => sub {
		my ($real, $fh, $buffer, $length, $offset) = @_;
		if($main::DISK_FULL) { $! = Errno::ENOSPC(); return undef }
		return $real->($fh, $buffer, $length // length($buffer), $offset // 0);
	});
}

use App::Syslogd;
use App::Syslogd::Cache;
use App::Syslogd::I18N;

Readonly my %CONFIG => (
	module => File::Spec->catfile($Bin, File::Spec->updir(), 'lib', 'App', 'Syslogd.pm'),
	peer_ip => '192.0.2.1',
	ttl => 300,
	none => '(none)',
	same => '(same)',
);

# The four states outside run(), as (bound, logging)
Readonly my %STATIC_STATES => (IDLE => [0, 0], BOUND => [1, 0], LOGGING => [0, 1], READY => [1, 1]);

my $PEER = pack_sockaddr_in(514, inet_aton($CONFIG{peer_ip}));
my $dir = tempdir(CLEANUP => 1);
my $serial = 0;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub verbose_diag { diag(@_) if($ENV{TEST_VERBOSE}); return }

sub new_path { return File::Spec->catfile($dir, 'fsm' . ++$serial . '.csv') }

sub missing_path { return File::Spec->catfile($dir, 'missing' . ++$serial, 'log.csv') }

# The state a server is in (outside run(): RUNNING and STOPPING are
# reported by the steps that observe them)
sub state_of {
	my $server = shift;
	return 'STOPPING' if($server->{in_step} && !$server->{running});
	return 'RUNNING' if($server->{running});
	my $facts = join(',', $server->{socket} ? 1 : 0, $server->{fh} ? 1 : 0);
	my %name = map { join(',', @{$STATIC_STATES{$_}}) => $_ } keys %STATIC_STATES;
	return $name{$facts};
}

# A socket double: recv() runs the next scripted step
{
	package FsmSocket;
	sub new { my ($class, @steps) = @_; return bless { steps => [@steps], closed => 0 }, $class }
	sub recv {
		my $self = $_[0];
		my $step = shift(@{$self->{steps}}) or die "FsmSocket: no steps left\n";
		return $step->(\$_[1]);
	}
	sub sockport { return 1 }
	sub sockhost { return '127.0.0.1' }
	sub close { my $self = shift; $self->{closed}++; die $self->{close_dies} if($self->{close_dies}); return 1 }
}

# A server in one of the four static states.  Sockets come from mocked
# constructors (no network); $steps, if given, script the socket.
sub server_in {
	my ($state, @steps) = @_;
	my $server = App::Syslogd->new(file => new_path(), resolve => 0);
	$server->{socket} = FsmSocket->new(@steps) if($STATIC_STATES{$state}[0]);
	$server->reopen_log() if($STATIC_STATES{$state}[1]);
	is(state_of($server), $state, "precondition: in $state");
	return $server;
}

# A step that records the state seen inside run(), then does $action
sub observe {
	my ($server_ref, $seen, $action) = @_;
	return sub {
		my $buffer = shift;
		local ${$server_ref}->{in_step} = 1;
		push @{$seen}, state_of(${$server_ref});
		return $action ? $action->($buffer) : do { $! = Errno::EINTR(); undef };
	};
}

# A step that stops run(), as a signal would
sub stop_step { my $server_ref = shift; return sub { ${$server_ref}->stop(); $! = Errno::EINTR(); return undef } }

# Read the transition tables from the POD.  A row continues on the next
# line when the From cell there is empty, or when the From list ends in a
# comma (more states follow).
sub parse_fsm {
	my $file = shift;
	open(my $fh, '<', $file) or die "$file: $!";
	my $text = do { local $/; <$fh> };
	my ($section) = $text =~ /^=head2 Transition table\n(.*?)^=head1 /ms or die 'no transition table in the POD';
	my ($table, $current, @rows) = (0);
	foreach my $line (split /\n/, $section) {
		if($line =~ /^\t\+/) { $current = undef; next }
		next unless($line =~ /^\t\|(.*)\|\s*$/);
		my @cells = map { s/^\s+|\s+$//gr } split(/\|/, $1);
		if($cells[0] eq 'From') { $table++; next }
		if(!$current || (length($cells[0]) && $current->{cells}[0] !~ /,\z/)) {
			$current = { table => $table, cells => [@cells] };
			push @rows, $current;
		} else {
			$current->{cells}[$_] = join(' ', grep { length } $current->{cells}[$_], $cells[$_]) foreach(0 .. $#cells);
		}
	}
	my @transitions;
	foreach my $row (@rows) {
		my ($from, $trigger, $to, $effect) = @{$row->{cells}};
		push @transitions, map { { from => $_, trigger => $trigger, to => $to, effect => $effect, failure => ($row->{table} > 1 ? 1 : 0) } } split(/,\s*/, $from);
	}
	return \@transitions;
}

# The key of a transition: From state and trigger, as the POD writes them
sub key_of { my $t = shift; return "$t->{from} | $t->{trigger}" }

# ---------------------------------------------------------------------------
# One test per documented transition.  Each receives the parsed row and
# checks the end state and the side effect the row documents.
# ---------------------------------------------------------------------------

my %TEST;

# (none) -> IDLE / BOUND, and the refused constructor
$TEST{'(none) | new()'} = sub {
	my $server = App::Syslogd->new();
	returns_ok($server, { type => 'object', isa => 'App::Syslogd' }, 'an object');
	is(state_of($server), 'IDLE', 'IDLE');
	is($server->port(), 514, 'side effect: options checked and stored');
};
$TEST{'(none) | new(socket => S)'} = sub {
	my $socket = FsmSocket->new();
	my $server = App::Syslogd->new(socket => $socket);
	is(state_of($server), 'BOUND', 'BOUND');
	is($server->{socket}, $socket, 'side effect: S used as the socket');
};
$TEST{'(none) | new() with an invalid option'} = sub {
	my $server;
	throws_ok { $server = App::Syslogd->new(port => -1) } qr/validate_strict: Parameter 'port'/, 'dies with the validator message';
	ok(!defined($server), 'no object is made');
};

# open_socket()
foreach my $from (qw(IDLE BOUND LOGGING READY)) {
	$TEST{"$from | open_socket()"} = sub {
		my $t = shift;
		my $created = 0;
		my $g = mock_scoped('IO::Socket::IP::new' => sub { $created++; return FsmSocket->new() });
		my $server = server_in($from);
		my $before = $server->{socket};
		$server->open_socket();
		is(state_of($server), $t->{to}, $t->{to});
		if($STATIC_STATES{$from}[0]) {
			is($server->{socket}, $before, 'side effect: nothing (already bound)');
			is($created, 0, '...no socket created');
		} else {
			is($created, 1, 'side effect: one UDP socket bound');
		}
	};
}
foreach my $from (qw(IDLE LOGGING)) {
	$TEST{"$from | open_socket() fails"} = sub {
		my $t = shift;
		my $g = mock_scoped('IO::Socket::IP::new' => sub { $IO::Socket::errstr = 'refused'; return undef });
		my $server = server_in($from);
		throws_ok { $server->open_socket() } qr/\ACould not create a UDP socket /, 'dies "Could not create a UDP socket ..."';
		is(state_of($server), $from, 'state unchanged');
	};
}

# reopen_log()
foreach my $from (qw(IDLE BOUND LOGGING READY)) {
	$TEST{"$from | reopen_log()"} = sub {
		my $t = shift;
		my $server = server_in($from);
		my $old = $server->{fh};
		$server->reopen_log();
		is(state_of($server), $t->{to}, $t->{to});
		ok(defined(fileno($server->{fh})), 'side effect: a log is open');
		ok(!defined(fileno($old)), '...and the old one was closed first') if($old);
	};
	$TEST{"$from | reopen_log() fails"} = sub {
		my $t = shift;
		my $server = server_in($from);
		$server->{file} = missing_path();
		throws_ok { $server->reopen_log() } qr/\ACould not open log file /, 'dies "Could not open log file ..."';
		my $expected = $t->{to} eq $CONFIG{same} ? $from : ($STATIC_STATES{$from}[0] ? 'BOUND' : 'IDLE');
		is(state_of($server), $expected, "$expected (the log was closed)");
	};
}

# process()
foreach my $from (qw(LOGGING READY)) {
	$TEST{"$from | process()"} = sub {
		my $t = shift;
		my $server = server_in($from);
		$server->process('<13>row', $PEER);
		is(state_of($server), $t->{to}, $t->{to});
		is($server->count(), 1, 'side effect: one row written, count + 1');
	};
}
foreach my $from (qw(IDLE BOUND)) {
	$TEST{"$from | process()"} = sub {
		my $t = shift;
		my $server = server_in($from);
		throws_ok { $server->process('<13>row', $PEER) } qr/\Aprocess\(\) was called before reopen_log\(\) succeeded/, 'dies "process() was called before ..."';
		is(state_of($server), $from, 'state unchanged');
		is($server->count(), 0, 'nothing counted');
	};
}

# run() from each static state, into RUNNING, out through STOPPING to IDLE
foreach my $from (qw(IDLE BOUND LOGGING READY)) {
	$TEST{"$from | run()"} = sub {
		my $t = shift;
		my @seen;
		my $server;
		my @steps = (observe(\$server, \@seen), stop_step(\$server));
		my $g = mock_scoped('IO::Socket::IP::new' => sub { return FsmSocket->new(@steps) });
		$server = server_in($from, @steps);
		local $SIG{HUP} = 'DEFAULT';
		$server->run();
		is($seen[0], $t->{to}, "$t->{to} inside run()");
		is(state_of($server), 'IDLE', '...and IDLE after it');
		is($SIG{HUP}, 'DEFAULT', 'side effect: signal handlers installed only during run()');
	};
}
$TEST{'IDLE | run(), and the log cannot be opened'} = sub {
	my $t = shift;
	my $g = mock_scoped('IO::Socket::IP::new' => sub { return FsmSocket->new() });
	my $server = server_in('IDLE');
	$server->{file} = missing_path();
	throws_ok { $server->run() } qr/\ACould not open log file /, 'run() dies with the error';
	is(state_of($server), 'IDLE', 'IDLE: the socket run() opened was closed again');
};
$TEST{'BOUND | run(), and the log cannot be opened'} = sub {
	my $t = shift;
	my $server = server_in('BOUND');
	my $socket = $server->{socket};
	$server->{file} = missing_path();
	throws_ok { $server->run() } qr/\ACould not open log file /, 'run() dies with the error';
	is(state_of($server), 'BOUND', "BOUND: the caller's socket is left open");
	is($socket->{closed}, 0, '...not closed');
};
foreach my $from (qw(IDLE LOGGING)) {
	$TEST{"$from | run(), and the socket cannot be opened"} = sub {
		my $t = shift;
		my $g = mock_scoped('IO::Socket::IP::new' => sub { $IO::Socket::errstr = 'refused'; return undef });
		my $server = server_in($from);
		throws_ok { $server->run() } qr/\ACould not create a UDP socket /, 'dies "Could not create a UDP socket ..."';
		is(state_of($server), $from, 'state unchanged');
	};
}

# Inside run(): RUNNING -> RUNNING, RUNNING -> STOPPING -> IDLE
$TEST{'RUNNING | datagram arrives'} = sub {
	my @seen;
	my $server;
	$server = server_in('READY', sub { ${$_[0]} = '<13>x'; return $PEER }, observe(\$server, \@seen), stop_step(\$server));
	$server->run();
	is($seen[0], 'RUNNING', 'still RUNNING after the datagram');
	is($server->count(), 1, 'side effect: row written, count + 1');
};
$TEST{'RUNNING | SIGHUP'} = sub {
	my @seen;
	my $server;
	my $reopens = 0;
	my $g = mock_scoped('App::Syslogd::reopen_log' => do { my $real = \&App::Syslogd::reopen_log; sub { $reopens++; $real->(@_) } });
	$server = server_in('READY', sub { $SIG{HUP}->('HUP'); $! = Errno::EINTR(); return undef }, observe(\$server, \@seen), stop_step(\$server));
	$reopens = 0;
	$server->run();
	is($seen[0], 'RUNNING', 'still RUNNING');
	is($reopens, 1, 'side effect: log closed and opened again');
};
$TEST{'RUNNING | read error (not a signal)'} = sub {
	my @seen;
	my $server;
	$server = server_in('READY', sub { $! = EBADF; return undef }, observe(\$server, \@seen), stop_step(\$server));
	warning_like { $server->run() } qr/\AError receiving a datagram: /, 'side effect: warning "Error receiving ..."';
	is($seen[0], 'RUNNING', 'still RUNNING');
};
$TEST{'RUNNING | a write fails (e.g. disk full)'} = sub {
	my @seen;
	my $server;
	$server = server_in('READY', sub { $DISK_FULL = 1; ${$_[0]} = '<13>lost'; return $PEER }, observe(\$server, \@seen), stop_step(\$server));
	warning_like { $server->run() } qr/\ACould not write to log file /, 'side effect: warning "Could not write ..."';
	$DISK_FULL = 0;
	is($seen[0], 'RUNNING', 'still RUNNING');
};
$TEST{'RUNNING | SIGTERM, SIGINT or stop()'} = sub {
	foreach my $trigger (qw(TERM INT stop)) {
		my @seen;
		my $server;
		my $stop = $trigger eq 'stop' ? sub { $server->stop() } : sub { $SIG{$trigger}->($trigger) };
		$server = server_in('READY', sub {
			$stop->();
			local $server->{in_step} = 1;
			push @seen, state_of($server);
			$! = Errno::EINTR();
			return undef;
		});
		$server->run();
		is($seen[0], 'STOPPING', "$trigger: STOPPING");
		is(state_of($server), 'IDLE', "$trigger: then IDLE when the wait ends");
	}
};
$TEST{'STOPPING | the wait or datagram ends'} = sub {
	my $server;
	$server = server_in('READY', stop_step(\$server));
	my $socket = $server->{socket};
	local $SIG{TERM} = 'DEFAULT';
	$server->run();
	is(state_of($server), 'IDLE', 'IDLE');
	is($socket->{closed}, 1, 'side effect: socket closed');
	is($SIG{TERM}, 'DEFAULT', '...handlers restored, run() returned');
};
$TEST{'STOPPING | closing the socket dies'} = sub {
	my $server;
	$server = server_in('READY', stop_step(\$server));
	$server->{socket}{close_dies} = "close failed\n";
	throws_ok { $server->run() } qr/\Aclose failed\n\z/, 'run() dies with the error';
	is(state_of($server), 'IDLE', 'IDLE: the log was closed anyway');
};
$TEST{'RUNNING | SIGHUP, and the reopen fails'} = sub {
	my $server;
	$server = server_in('READY', sub { $server->{file} = missing_path(); $SIG{HUP}->('HUP'); $! = Errno::EINTR(); return undef });
	local $SIG{HUP} = 'DEFAULT';
	throws_ok { $server->run() } qr/\ACould not open log file /, 'run() dies with the error';
	is(state_of($server), 'BOUND', 'BOUND: log closed');
	is($SIG{HUP}, 'DEFAULT', 'handlers restored');
};
$TEST{'RUNNING | recv() dies (a broken socket)'} = sub {
	my $server = server_in('READY', sub { die "socket broken\n" });
	throws_ok { $server->run() } qr/\Asocket broken\n\z/, 'run() dies with the error';
	is(state_of($server), 'READY', 'READY: socket and log stay open');
};
$TEST{'RUNNING | run() again (from inside the loop)'} = sub {
	my ($inner, @seen);
	my $server;
	$server = server_in('READY',
		sub { $inner = eval { $server->run(); 1 } ? '' : $@; $! = Errno::EINTR(); return undef },
		observe(\$server, \@seen),
		stop_step(\$server),
	);
	lives_ok { $server->run() } 'the running loop carries on';
	like($inner, qr/\Arun\(\) is already running at /, 'the second run() dies "run() is already running"');
	is($seen[0], 'RUNNING', 'still RUNNING after the refused run()');
	is(state_of($server), 'IDLE', 'and stops normally');
};

# ---------------------------------------------------------------------------
# The diagram, enforced
# ---------------------------------------------------------------------------

my $documented = parse_fsm($CONFIG{module});
verbose_diag(join("\n", map { key_of($_) . " -> $_->{to}" } @{$documented}));
my %in_pod = map { key_of($_) => $_ } @{$documented};

foreach my $transition (@{$documented}) {
	my $name = "State: $transition->{from} -> Trigger: $transition->{trigger} -> State: $transition->{to}";
	subtest $name => sub {
		my $test = $TEST{key_of($transition)};
		# Diagram compliance: a documented transition with no test fails
		ok($test, 'documented transition has a test') or return;
		$test->($transition);
	};
}

subtest 'every test is a documented transition' => sub {
	# Diagram compliance the other way: a tested transition that the POD
	# does not show means the diagram is out of date
	my @undocumented = grep { !exists($in_pod{$_}) } sort keys %TEST;
	is_deeply(\@undocumented, [], 'no undocumented transitions are tested');
};

# ---------------------------------------------------------------------------
# Transitions the diagram does not allow
# ---------------------------------------------------------------------------

subtest 'routines that never change the state' => sub {
	# The POD: port(), address(), count(), parse_message() and i18n() never
	# change the state; stop() outside run() changes nothing that matters
	foreach my $state (sort keys %STATIC_STATES) {
		my $server = server_in($state);
		my $count = $server->count();
		$server->port();
		$server->address();
		$server->count();
		$server->parse_message('<13>x');
		$server->i18n('shutdown', { count => 1 });
		$server->stop();
		is(state_of($server), $state, "$state: unchanged");
		is($server->count(), $count, "$state: count unchanged");
	}
};

subtest 'refused arguments never move the state' => sub {
	# A bad argument is not a trigger: the method dies, nothing changes
	my $server = server_in('READY');
	my $count = $server->count();
	throws_ok { $server->process([], $PEER) } qr/\AA datagram must be a string/, 'a reference as the datagram';
	throws_ok { $server->i18n(undef) } qr/\AA message key is needed/, 'no message key';
	is(state_of($server), 'READY', 'still READY');
	is($server->count(), $count, 'nothing counted');
};

# ---------------------------------------------------------------------------
# App::Syslogd::Cache: one state, CACHE (its STATE DIAGRAM section)
# ---------------------------------------------------------------------------

subtest 'Cache: CACHE -> compute(k) hit -> CACHE' => sub {
	my $cache = App::Syslogd::Cache->new();
	$cache->compute('k', $CONFIG{ttl}, sub { 'v' });
	my $calls = 0;
	is($cache->compute('k', $CONFIG{ttl}, sub { $calls++; 'w' }), 'v', 'returns the value');
	is($calls, 0, 'side effect: nothing computed');
};
subtest 'Cache: CACHE -> compute(k) miss, ttl > 0, fits -> CACHE' => sub {
	my $cache = App::Syslogd::Cache->new();
	is($cache->compute('k', $CONFIG{ttl}, sub { 'v' }), 'v', 'returns the computed value');
	ok(exists($cache->{entries}{k}), 'side effect: remembered');
};
subtest 'Cache: CACHE -> compute(k) miss, ttl <= 0 or too big -> CACHE' => sub {
	my $cache = App::Syslogd::Cache->new(max_bytes => 100);
	$cache->compute('a', 0, sub { 'v' });
	$cache->compute('b', $CONFIG{ttl}, sub { 'x' x 200 });
	is_deeply($cache->{entries}, {}, 'side effect: nothing kept');
};
subtest 'Cache: CACHE -> code dies -> CACHE' => sub {
	my $cache = App::Syslogd::Cache->new();
	throws_ok { $cache->compute('k', $CONFIG{ttl}, sub { die "down\n" }) } qr/\Adown\n\z/, 'the error is passed on';
	is_deeply($cache->{entries}, {}, 'side effect: nothing kept');
};

# ---------------------------------------------------------------------------
# App::Syslogd::I18N: one state, READY (its STATE DIAGRAM section)
# ---------------------------------------------------------------------------

subtest 'I18N: (none) -> handle(LANG) -> READY -> text/gender -> READY' => sub {
	my $lh = App::Syslogd::I18N->handle('en');
	isa_ok($lh, 'App::Syslogd::I18N', 'READY');
	like($lh->text('shutdown', { count => 1 }), qr/1 message\z/, 'text(): a message, no change');
	is($lh->gender('female', 'm', 'f', 'n'), 'f', 'gender(): a word, no change');
	{
		package App::Syslogd::I18N::x_fsm;
		our @ISA = ('App::Syslogd::I18N');
		our %Lexicon = (listening => 'x');
	}
	throws_ok { App::Syslogd::I18N::x_fsm->new()->text('shutdown', { count => 1 }) } qr/maketext doesn't know how to say/,
		'READY -> text() for a key the language lacks -> dies (no English parent)';
};

done_testing();
