#!/usr/bin/env perl

# Logic tests: proofs of every boolean expression, state invariant and
# premise in lib/.  Each subtest is named after the rule it proves.
#
# Method
#	* Truth tables: every reachable combination of every condition is
#	  tested.  Combinations that cannot happen are named, with the reason.
#	* De Morgan: where the code tests "not (A and B and C)", the outcome
#	  is checked against "(not A) or (not B) or (not C)" for every row.
#	* Invariants: the Z specification's "running => bound /\ logging" and
#	  "count never decreases" are checked before, during and after work.
#	* State machine: each transition of the POD's STATE DIAGRAM.
#	* Contradictions: inputs that break a premise must be stopped by the
#	  first guard, with the documented message.
#
# Major premises (from the POD and the Z specification):
#	M1  open_socket() does nothing when a socket is open.
#	M2  run() opens the socket before its loop; open_socket() dies if it
#	    cannot.  _receive() runs only inside the loop.
#	M3  A log file is safe if and only if it is a regular file AND owned
#	    by us AND has exactly one link.
#	M4  A PRI is valid if and only if it matches the PRI pattern AND is
#	    at most 191.
#	M5  text() values are undef or a hash reference; nothing else.
#	M6  The caller's options are checked before Object::Configure can
#	    override them.
#	M7  While run() loops, the socket and the log are open.
#
# The state of a server is read as three facts: bound (it has a socket),
# logging (it has an open log) and running.

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Errno qw(EINTR ENOSPC EBADF EADDRINUSE);
use File::Spec;
use File::Temp qw(tempdir);
use Readonly;
use Socket qw(pack_sockaddr_in inet_aton);
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

# Builtins that can be bent to reach rows a test machine cannot produce
# for real.  CORE::GLOBAL overrides only reach code compiled after them,
# so they come before App::Syslogd is loaded.  Each is a no-op unless its
# switch is set.
our (%FAKE_STAT, $SYSWRITE, $SYSSEEK_FAILS);
BEGIN {
	# stat: fake the owner or link count; the real stat still runs, so
	# "-f _" (the file type) stays real
	mock_core('stat' => sub {
		my ($real, @args) = @_;
		my @st = $real->(@args);
		return @st unless(@st);
		$st[4] = $main::FAKE_STAT{owner} if(exists($main::FAKE_STAT{owner}));
		$st[3] = $main::FAKE_STAT{links} if(exists($main::FAKE_STAT{links}));
		return @st;
	});
	# syswrite: 'full' fails with ENOSPC, 'stuck' makes no progress,
	# 'half' writes half and then fails
	mock_core('syswrite' => sub {
		my ($real, $fh, $buffer, $length, $offset) = @_;
		$length //= length($buffer);
		$offset //= 0;
		my $mode = $main::SYSWRITE // '';
		if($mode eq 'full') { $! = Errno::ENOSPC(); return undef }
		if($mode eq 'stuck') { $! = 0; return 0 }
		if($mode eq 'half') { $main::SYSWRITE = 'full'; return $real->($fh, $buffer, int($length / 2), $offset) }
		return $real->($fh, $buffer, $length, $offset);
	});
	# sysseek: fail, so the start of a line is unknown
	mock_core('sysseek' => sub {
		my ($real, @args) = @_;
		return undef if($main::SYSSEEK_FAILS);
		return $real->(@args);
	});
}

use App::Syslogd;
use App::Syslogd::I18N;

# White-box: some gates are in private helpers, called directly here
$Sub::Private::BYPASS = $Sub::Protected::BYPASS = 1;

Readonly my %CONFIG => (
	peer_ip => '192.0.2.1',
	peer_name => 'sender.example.com',
	unprivileged_port => 5514,
	max_pri => 191,
	one_link => 1,
	two_links => 2,
	someone_else => $> + 1,		# a user id that is not ours
	header => '"Host","facility","severity","msg"',
);

my $PEER = pack_sockaddr_in(514, inet_aton($CONFIG{peer_ip}));
my $dir = tempdir(CLEANUP => 1);
my $serial = 0;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub verbose_diag { diag(@_) if($ENV{TEST_VERBOSE}); return }

sub new_path { return File::Spec->catfile($dir, 'logic' . ++$serial . '.csv') }

sub errno_text { my $errno = shift; local $! = $errno; return "$!" }

sub exact { my $message = shift; return qr/\A\Q$message\E at \S.* line \d+\.?\n?\z/s }

sub slurp { my $file = shift; open(my $fh, '<:raw', $file) or die "$file: $!"; local $/; return scalar(<$fh>) }

# The three facts that make up a server's state
sub state_of {
	my $server = shift;
	return { bound => ($server->{socket} ? 1 : 0), logging => ($server->{fh} ? 1 : 0), running => ($server->{running} ? 1 : 0) };
}

# The Z invariant: running => bound /\ logging
sub invariant_holds {
	my $state = shift;
	return (!$state->{running} || ($state->{bound} && $state->{logging})) ? 1 : 0;
}

# A socket double whose recv() runs scripted steps
{
	package StepSocket;
	sub new { my ($class, @steps) = @_; return bless { steps => [@steps], closed => 0 }, $class }
	sub recv { my $self = $_[0]; my $step = shift(@{$self->{steps}}) or die "StepSocket: no steps left\n"; return $step->(\$_[1]) }
	sub sockport { return 1 }
	sub sockhost { return '127.0.0.1' }
	sub close { my $self = shift; $self->{closed}++; die $self->{close_dies} if($self->{close_dies}); return 1 }
}

# A socket double with neither sockport() nor sockhost()
{
	package BareSocket;
	sub new { return bless {}, shift }
	sub recv { return undef }
	sub close { return 1 }
}

# A cache double driven by a code ref
{
	package LogicCache;
	sub new { my ($class, $code) = @_; return bless { code => $code }, $class }
	sub compute { my $self = shift; return $self->{code}->(@_) }
}

# A step that stops the server, as a signal would
sub stop_step { my $server_ref = shift; return sub { ${$server_ref}->stop(); $! = Errno::EINTR(); return undef } }

# ===========================================================================
# App::Syslogd: open_socket
# ===========================================================================

subtest 'M1: open_socket - (socket exists) x (constructor succeeds)' => sub {
	# All four rows.  When a socket exists the constructor is never
	# asked, so its result cannot matter (rows 1 and 2 agree).
	foreach my $exists (1, 0) {
		foreach my $succeeds (1, 0) {
			my $asked = 0;
			my $g = mock_scoped('IO::Socket::IP::new' => sub { $asked++; $IO::Socket::errstr = 'refused'; return $succeeds ? StepSocket->new() : undef });
			my $server = App::Syslogd->new($exists ? (socket => StepSocket->new()) : ());
			my $row = "exists=$exists succeeds=$succeeds";
			if($exists) {
				lives_ok { $server->open_socket() } "$row: no error";
				is($asked, 0, "$row: the constructor is not asked");
			} elsif($succeeds) {
				lives_ok { $server->open_socket() } "$row: no error";
				ok(state_of($server)->{bound}, "$row: bound");
			} else {
				throws_ok { $server->open_socket() } qr/\ACould not create a UDP socket on 0\.0\.0\.0 port 514: refused at /, "$row: dies";
				ok(!state_of($server)->{bound}, "$row: still not bound");
			}
		}
	}
};

subtest 'open_socket error text: errstr || $!' => sub {
	# Truth table of "errstr if set, otherwise $!".  $IO::Socket::errstr is
	# started empty, so an older value can never leak in (row 4 shows the
	# message is then just the prefix, never a stale reason).
	my @rows = (
		['set', EADDRINUSE, 'from errstr'],
		['set', 0, 'from errstr'],
		['', EADDRINUSE, errno_text(EADDRINUSE)],
		['', 0, ''],
	);
	foreach my $row (@rows) {
		my ($errstr, $errno, $expect) = @{$row};
		my $g = mock_scoped('IO::Socket::IP::new' => sub { $IO::Socket::errstr = $errstr ? 'from errstr' : ''; $! = $errno; return undef });
		throws_ok { App::Syslogd->new(port => $CONFIG{unprivileged_port})->open_socket() }
			exact("Could not create a UDP socket on 0.0.0.0 port $CONFIG{unprivileged_port}: $expect"),
			"errstr " . ($errstr ? 'set' : 'empty') . ", \$! " . ($errno ? 'set' : 'clear');
	}
};

subtest 'port and address: socket && socket->can(...)' => sub {
	# Three reachable rows; "no socket but it has the method" cannot exist
	is(App::Syslogd->new(port => 7, address => 'a')->port(), 7, 'no socket: the configured port');
	is(App::Syslogd->new(port => 7, address => 'a')->address(), 'a', 'no socket: the configured address');
	is(App::Syslogd->new(port => 7, socket => BareSocket->new())->port(), 7, 'socket without sockport(): configured');
	is(App::Syslogd->new(address => 'a', socket => BareSocket->new())->address(), 'a', 'socket without sockhost(): configured');
	is(App::Syslogd->new(port => 7, socket => StepSocket->new())->port(), 1, 'socket with sockport(): the real port');
	is(App::Syslogd->new(address => 'a', socket => StepSocket->new())->address(), '127.0.0.1', 'socket with sockhost(): the real address');
};

# ===========================================================================
# App::Syslogd: parse_message and process
# ===========================================================================

subtest 'parse_message: ref(d) && !overloaded(d)' => sub {
	# Three reachable rows; "not a reference but overloaded" cannot exist
	{
		package Stringy;
		use overload q{""} => sub { '<13>from object' }, fallback => 1;
	}
	lives_ok { App::Syslogd->parse_message('<13>x') } 'not a reference: accepted';
	is(App::Syslogd->parse_message(bless({}, 'Stringy'))->{message}, 'from object', 'reference, overloaded: accepted as its string');
	throws_ok { App::Syslogd->parse_message([]) } exact('A datagram must be a string (the type given was ARRAY)'), 'reference, not overloaded: refused';
};

subtest 'M4: valid = matches && pri <= 191' => sub {
	# Three reachable rows; "no match but <= 191" cannot exist (there is
	# no PRI to compare).  The boundary values decide the second test.
	is(App::Syslogd->parse_message('<x>m')->{valid}, 0, 'no match: invalid');
	is(App::Syslogd->parse_message("<$CONFIG{max_pri}>m")->{valid}, 1, 'match, 191: valid');
	is(App::Syslogd->parse_message('<' . ($CONFIG{max_pri} + 1) . '>m')->{valid}, 0, 'match, 192: invalid');
	# Post-condition (Z ParseMessage): invalid keeps the whole text
	is(App::Syslogd->parse_message('<192>m')->{message}, '<192>m', 'invalid: the whole text');
	is(App::Syslogd->parse_message('<191>m')->{message}, 'm', 'valid: the text after the PRI');
};

subtest 'process: (log open) x (datagram long enough)' => sub {
	# All four rows.  With no log the first guard decides, whatever the
	# datagram (fail fast); with a log, only a long-enough one is counted.
	foreach my $open (1, 0) {
		foreach my $long (1, 0) {
			my $server = App::Syslogd->new(file => new_path(), resolve => 0);
			$server->reopen_log() if($open);
			my $datagram = $long ? '<13>long enough' : 'x';
			my $row = "log open=$open long enough=$long";
			if(!$open) {
				throws_ok { $server->process($datagram, $PEER) } exact('process() was called before reopen_log() succeeded'), "$row: refused";
			} else {
				$server->process($datagram, $PEER);
				is($server->count(), $long, "$row: counted $long");
			}
		}
	}
	# The guard comes before the datagram is even looked at
	throws_ok { App::Syslogd->new()->process([], $PEER) } exact('process() was called before reopen_log() succeeded'), 'no log and a bad datagram: the log guard wins';
};

# ===========================================================================
# App::Syslogd: run, _receive and the invariants
# ===========================================================================

subtest 'M2: _receive() is unreachable without a socket' => sub {
	# open_socket() cannot bind, so run() dies there: before the loop,
	# before _receive(), and before the log is touched
	my $g = mock_scoped('IO::Socket::IP::new' => sub { $IO::Socket::errstr = 'Permission denied'; return undef });
	my $receive = spy('App::Syslogd::_receive');
	my $file = new_path();
	throws_ok { App::Syslogd->new(file => $file, port => $CONFIG{unprivileged_port})->run() }
		exact("Could not create a UDP socket on 0.0.0.0 port $CONFIG{unprivileged_port}: Permission denied"), 'dies in open_socket()';
	is(scalar(my @calls = $receive->()), 0, '_receive() never ran');
	ok(!-e $file, 'the log was never created');
	restore_all();
};

subtest 'run: reopen_log unless(logging); process if(peer)' => sub {
	# Gate 1, both rows: a log already open is not reopened by run()
	foreach my $logging (1, 0) {
		my $server;
		$server = App::Syslogd->new(file => new_path(), resolve => 0, socket => StepSocket->new(stop_step(\$server)));
		$server->reopen_log() if($logging);
		my $spy = spy('App::Syslogd::reopen_log');
		$server->run();
		is(scalar(my @calls = $spy->()), $logging ? 0 : 1, "logging=$logging: reopened " . ($logging ? 0 : 1) . ' time(s)');
		restore_all();
	}

	# Gate 2: a true sender is processed; '' and undef are not
	my $server;
	my @peers = ($PEER, '', undef);
	my $socket = StepSocket->new((map { my $peer = $_; sub { ${$_[0]} = '<13>x'; $! = Errno::EINTR() unless(defined($peer)); return $peer } } @peers), stop_step(\$server));
	$server = App::Syslogd->new(file => new_path(), resolve => 0, socket => $socket);
	$server->run();
	is($server->count(), 1, 'only the true sender was processed');
};

subtest 'run loop: (running) x (reopen requested)' => sub {
	# running false: the loop ends.  running true and a reopen requested:
	# reopen first.  running true and none: receive.  The fourth row
	# (not running, reopen requested) ends the loop without reopening,
	# and the request does not outlive run().
	my $server;
	my @log;
	my $g = mock_scoped('App::Syslogd::reopen_log' => do {
		my $real = \&App::Syslogd::reopen_log;
		sub { push @log, 'reopen'; return $real->(@_) };
	});
	my $socket = StepSocket->new(
		sub { push @log, 'receive'; $SIG{HUP}->('HUP'); $! = Errno::EINTR(); return undef },	# running, reopen requested
		sub { push @log, 'receive'; $! = Errno::EINTR(); return undef },			# running, none
		sub { push @log, 'receive'; $SIG{HUP}->('HUP'); $SIG{TERM}->('TERM'); $! = Errno::EINTR(); return undef },	# not running, requested
	);
	$server = App::Syslogd->new(file => new_path(), resolve => 0, socket => $socket);
	$server->run();
	is_deeply(\@log, ['reopen', 'receive', 'reopen', 'receive', 'receive'], 'reopen before receiving; nothing after the stop');
	ok(!$server->{reopen_requested}, 'the request does not outlive run()');
};

subtest '_receive: !defined(peer) && !EINTR warns' => sub {
	# All four rows; only "no sender and not interrupted" warns
	my @rows = ([1, Errno::EINTR(), 0], [1, EBADF, 0], [0, Errno::EINTR(), 0], [0, EBADF, 1]);
	foreach my $row (@rows) {
		my ($has_peer, $errno, $warns) = @{$row};
		my $server = App::Syslogd->new(socket => StepSocket->new(sub { ${$_[0]} = 'x'; $! = $errno; return $has_peer ? $PEER : undef }));
		my @warnings;
		{
			local $SIG{__WARN__} = sub { push @warnings, $_[0] };
			$server->_receive(\my $buffer);
		}
		is(scalar(@warnings), $warns, "sender=$has_peer errno=" . ($errno == Errno::EINTR() ? 'EINTR' : 'EBADF') . ": $warns warning(s)");
	}
};

subtest 'M7: invariant running => bound /\ logging, before, during and after' => sub {
	# Checked at every observable point of a run, including after a stop
	# with both signals at once
	my $server;
	my @states;
	my $check = sub { push @states, state_of($server) };
	my $socket = StepSocket->new(
		sub { $check->(); ${$_[0]} = '<13>a'; return $PEER },
		sub { $check->(); $SIG{HUP}->('HUP'); $! = Errno::EINTR(); return undef },
		sub { $check->(); $server->stop(); $! = Errno::EINTR(); return undef },
	);
	$server = App::Syslogd->new(file => new_path(), resolve => 0, socket => $socket);
	my $before = state_of($server);
	$server->run();
	my $after = state_of($server);
	verbose_diag(explain({ before => $before, during => \@states, after => $after }));

	ok(invariant_holds($before), 'before run(): holds');
	ok(!$before->{running}, 'before run(): not running');
	is(scalar(grep { $_->{running} && $_->{bound} && $_->{logging} } @states), scalar(@states), 'during run(): running, bound and logging at every step');
	ok(invariant_holds($after), 'after run(): holds');
	is_deeply($after, { bound => 0, logging => 0, running => 0 }, 'after run(): nothing held');
};

subtest 'invariant: count never decreases' => sub {
	# Every operation either keeps count or adds one
	my $server = App::Syslogd->new(file => new_path(), resolve => 0)->reopen_log();
	my @counts = ($server->count());
	foreach my $step (sub { $server->process('<13>a', $PEER) }, sub { $server->process('x', $PEER) },
		sub { $server->reopen_log() }, sub { local $SYSWRITE = 'full'; local $SIG{__WARN__} = sub { }; $server->process('<13>b', $PEER) },
		sub { $server->stop() }) {
		$step->();
		push @counts, $server->count();
	}
	is_deeply([map { $counts[$_ + 1] - $counts[$_] >= 0 ? 1 : 0 } 0 .. $#counts - 1], [(1) x $#counts], 'never decreases');
	is_deeply(\@counts, [0, 1, 1, 1, 2, 2], 'and grows only for datagrams long enough');
};

# ===========================================================================
# App::Syslogd: the log file
# ===========================================================================

subtest 'M3: safe = regular && owned && one link - all eight rows, and De Morgan' => sub {
	# Every combination of the three conditions.  "Not regular" comes from
	# /dev/null; owner and link count are faked through stat().  For each
	# row the outcome must equal both "A and B and C" and its De Morgan
	# form "not (not A or not B or not C)".
	plan(skip_all => 'needs /dev/null') unless(-c '/dev/null');
	foreach my $regular (1, 0) {
		foreach my $owned (1, 0) {
			foreach my $one_link (1, 0) {
				my $file = $regular ? new_path() : '/dev/null';
				local %FAKE_STAT = (owner => $owned ? $> : $CONFIG{someone_else}, links => $one_link ? $CONFIG{one_link} : $CONFIG{two_links});
				my $accepted = eval { App::Syslogd->new(file => $file)->reopen_log(); 1 } ? 1 : 0;
				my $and = ($regular && $owned && $one_link) ? 1 : 0;
				my $de_morgan = (!(!$regular || !$owned || !$one_link)) ? 1 : 0;
				my $row = "regular=$regular owned=$owned one link=$one_link";
				is($accepted, $and, "$row: accepted=$and");
				is($and, $de_morgan, "$row: De Morgan agrees");
				like($@, qr/\ARefusing to log to /, "$row: refused with the documented message") unless($accepted);
			}
		}
	}
};

subtest '_open_log: empty || starts with the header' => sub {
	# The OR's three reachable rows (an empty file is never checked for a
	# header): empty -> header written; content starting with the header
	# -> accepted, nothing added; other content -> refused, untouched
	my $empty = new_path();
	App::Syslogd->new(file => $empty)->reopen_log();
	is(slurp($empty), "$CONFIG{header}\n", 'empty: header written');

	# :raw so that Windows writes "\n", not "\r\n": slurp() reads bytes
	my $ours = new_path();
	open(my $fh, '>:raw', $ours) or die;
	print {$fh} "$CONFIG{header}\nold row\n";
	close($fh);
	App::Syslogd->new(file => $ours)->reopen_log();
	is(slurp($ours), "$CONFIG{header}\nold row\n", 'starts with the header: accepted, no second header');

	my $foreign = new_path();
	open($fh, '>:raw', $foreign) or die;
	print {$fh} "existing\n";
	close($fh);
	throws_ok { App::Syslogd->new(file => $foreign)->reopen_log() }
		exact("Refusing to log to $foreign: it is not empty and does not start with the syslog header line"), 'other content: refused';
	is(slurp($foreign), "existing\n", '...and untouched');
};

subtest '_write_header: csv error // append error' => sub {
	# Three rows: the CSV writer refuses (the write is not attempted), the
	# write fails, or both succeed
	my $file = new_path();
	my $server = App::Syslogd->new(file => $file);
	open(my $fh, '>>', $file) or die;
	{
		local $SYSWRITE = '';
		my $g = mock_scoped('Text::CSV::combine' => sub { 0 }, 'Text::CSV::error_diag' => sub { 'refused' });
		my $spy = spy('App::Syslogd::_append_line');
		throws_ok { $server->_write_header($fh) } exact("Could not write to log file $file: refused"), 'CSV refuses: dies';
		is(scalar(my @c = $spy->()), 0, '...without trying to write');
		restore_all();
	}
	{
		local $SYSWRITE = 'full';
		throws_ok { $server->_write_header($fh) } exact("Could not write to log file $file: " . errno_text(ENOSPC)), 'write fails: dies';
	}
	lives_ok { $server->_write_header($fh) } 'both succeed: no error';
	close($fh);
	is(slurp($file), "$CONFIG{header}\n", '...and the header is written once');
};

subtest '_append_line: done == length; $! ? $! : no_progress; done && defined(start)' => sub {
	# The success gate, the error-text gate, and the truncate gate
	my $file = new_path();
	my $server = App::Syslogd->new(file => $file);
	open(my $fh, '>>', $file) or die;
	is($server->_append_line($fh, "whole\n"), undef, 'done == length: undef (success)');

	{
		local $SYSWRITE = 'full';
		is($server->_append_line($fh, "a\n"), errno_text(ENOSPC), 'failed with $! set: the system reason');
	}
	{
		local $SYSWRITE = 'stuck';
		is($server->_append_line($fh, "b\n"), 'the system accepted no data', 'no progress, $! clear: no_progress');
	}

	# Truncate gate: nothing written (no truncate needed); part written
	# and the start known (truncated); part written, start unknown (kept)
	{
		local $SYSWRITE = 'half';
		$server->_append_line($fh, "half line\n");
	}
	is(slurp($file), "whole\n", 'part written, start known: the part is removed');
	{
		local $SYSWRITE = 'half';
		local $SYSSEEK_FAILS = 1;
		$server->_append_line($fh, "half line\n");
	}
	my $part = substr("half line\n", 0, int(length("half line\n") / 2));
	is(slurp($file), "whole\n$part", 'part written, start unknown: cannot be removed');
	close($fh);
};

subtest '_shutdown: (socket) x (close dies)' => sub {
	# Three reachable rows; "no socket, close dies" cannot exist.  In every
	# row the log ends up closed.
	foreach my $row ([1, 0], [1, 1], [0, 0]) {
		my ($has_socket, $dies) = @{$row};
		my $server = App::Syslogd->new(file => new_path())->reopen_log();
		$server->{socket} = StepSocket->new() if($has_socket);
		$server->{socket}{close_dies} = "close failed\n" if($dies);
		my $ok = eval { $server->_shutdown(); 1 };
		my $name = "socket=$has_socket close dies=$dies";
		is($ok ? 1 : 0, $dies ? 0 : 1, "$name: " . ($dies ? 'the error is passed on' : 'no error'));
		is_deeply(state_of($server), { bound => 0, logging => 0, running => 0 }, "$name: nothing left open");
	}
};

# ===========================================================================
# App::Syslogd: host names
# ===========================================================================

subtest '_peer_name: !defined(peer) || ref(peer)' => sub {
	# Three rows of the OR; either part alone short-circuits to ''
	my $server = App::Syslogd->new(resolve => 0);
	is($server->_peer_name(undef), '', 'undef: empty');
	is($server->_peer_name([$PEER]), '', 'a reference: empty');
	is($server->_peer_name($PEER), $CONFIG{peer_ip}, 'a packed address: the address');
};

subtest '_peer_name: resolve && length(address)' => sub {
	# All four rows.  Only "resolve on and an address" looks the name up.
	my $lookups = 0;
	my $address = $CONFIG{peer_ip};
	my $g = mock_scoped('App::Syslogd::getnameinfo' => sub {
		my (undef, $flags) = @_;
		return ('', $address) if($flags & Socket::NI_NUMERICHOST());
		$lookups++;
		return ('', $CONFIG{peer_name});
	});
	my $cache = LogicCache->new(sub { $_[2]->() });
	foreach my $resolve (1, 0) {
		foreach my $has_address (1, 0) {
			$address = $has_address ? $CONFIG{peer_ip} : '';
			$lookups = 0;
			my $result = App::Syslogd->new(resolve => $resolve, cache => $cache)->_peer_name($PEER);
			my $looked = ($resolve && $has_address) ? 1 : 0;
			is($lookups, $looked, "resolve=$resolve address=$has_address: looked up $looked time(s)");
			is($result, $looked ? $CONFIG{peer_name} : $address, '...and the right host');
		}
	}
};

subtest '_peer_name: defined(name) && length(name), and a failing cache' => sub {
	# The answer is used only if defined and not empty; otherwise, and
	# when the cache dies, the address
	my $g = mock_scoped('App::Syslogd::getnameinfo' => sub { return ('', $CONFIG{peer_ip}) });
	my %answers = ('a name' => [sub { $CONFIG{peer_name} }, $CONFIG{peer_name}], 'undef' => [sub { undef }, $CONFIG{peer_ip}],
		'empty' => [sub { '' }, $CONFIG{peer_ip}], 'the cache dies' => [sub { die "cache down\n" }, $CONFIG{peer_ip}]);
	foreach my $case (sort keys %answers) {
		my ($code, $want) = @{$answers{$case}};
		is(App::Syslogd->new(cache => LogicCache->new($code))->_peer_name($PEER), $want, "$case: $want");
	}
};

subtest 'M6: an invalid argument cannot be hidden by the environment' => sub {
	# The environment would override the port, but the caller's own value
	# is checked first, so its mistake is still reported
	local $ENV{App__Syslogd__port} = $CONFIG{unprivileged_port};
	throws_ok { App::Syslogd->new(port => 'abc') } qr/validate_strict: Parameter 'port' \(abc\) must be an integer/, 'still refused';
	is(App::Syslogd->new(port => 1)->port(), $CONFIG{unprivileged_port}, 'a valid argument is overridden, as documented');
};

# ===========================================================================
# The state machine (POD: STATE DIAGRAM)
# ===========================================================================

subtest 'state machine: every documented transition' => sub {
	# Each row: start state, trigger, expected end state.  The state is
	# (bound, logging); RUNNING and STOPPING happen inside run() and are
	# covered by the invariant subtest.
	my $g = mock_scoped('IO::Socket::IP::new' => sub { StepSocket->new() });
	my %states = (IDLE => [0, 0], BOUND => [1, 0], LOGGING => [0, 1], READY => [1, 1]);
	my $in = sub {
		my ($name) = @_;
		my $server = App::Syslogd->new(file => new_path(), resolve => 0);
		$server->open_socket() if($states{$name}[0]);
		$server->reopen_log() if($states{$name}[1]);
		return $server;
	};
	my $is_state = sub {
		my ($server, $name, $label) = @_;
		my $s = state_of($server);
		is_deeply([$s->{bound}, $s->{logging}], $states{$name}, "$label -> $name");
	};

	$is_state->(App::Syslogd->new(), 'IDLE', 'new()');
	$is_state->(App::Syslogd->new(socket => StepSocket->new()), 'BOUND', 'new(socket => S)');
	my @transitions = (
		['IDLE', 'open_socket', 'BOUND'], ['IDLE', 'reopen_log', 'LOGGING'],
		['BOUND', 'reopen_log', 'READY'], ['LOGGING', 'open_socket', 'READY'],
		['BOUND', 'open_socket', 'BOUND'], ['READY', 'open_socket', 'READY'],
		['LOGGING', 'reopen_log', 'LOGGING'], ['READY', 'reopen_log', 'READY'],
	);
	foreach my $t (@transitions) {
		my ($from, $trigger, $to) = @{$t};
		my $server = $in->($from);
		$server->$trigger();
		$is_state->($server, $to, "$from --$trigger");
	}
	foreach my $from (qw(LOGGING READY)) {
		my $server = $in->($from);
		my $count = $server->process('<13>x', $PEER)->count();
		$is_state->($server, $from, "$from --process");
		is($count, 1, "$from --process: count + 1");
	}
	foreach my $from (qw(IDLE BOUND LOGGING READY)) {
		my $server = $in->($from);
		# A socket that stops run() at once (replacing any from open_socket)
		$server->{socket} = StepSocket->new(stop_step(\$server));
		$server->run();
		$is_state->($server, 'IDLE', "$from --run, then stop");
	}

	# Failures: the method dies and the state moves as documented
	{
		my $fail = mock_scoped('IO::Socket::IP::new' => sub { $IO::Socket::errstr = 'x'; return undef });
		foreach my $from (qw(IDLE LOGGING)) {
			my $server = $from eq 'IDLE' ? App::Syslogd->new() : App::Syslogd->new(file => new_path())->reopen_log();
			dies_ok { $server->open_socket() } "$from --open_socket fails";
			$is_state->($server, $from, "$from --open_socket fails");
		}
	}
	foreach my $from (qw(LOGGING READY)) {
		my $server = $in->($from);
		$server->{file} = File::Spec->catfile($dir, 'missing', 'x.csv');
		dies_ok { $server->reopen_log() } "$from --reopen_log fails";
		$is_state->($server, $from eq 'LOGGING' ? 'IDLE' : 'BOUND', "$from --reopen_log fails (log closed)");
	}
};

# ===========================================================================
# App::Syslogd::I18N
# ===========================================================================

subtest 'text key: !defined || ref || !length' => sub {
	# The four partitions; the first three are each enough to refuse
	my $lh = App::Syslogd::I18N->handle('en');
	foreach my $key (undef, [], '') {
		throws_ok { $lh->text($key) } exact('A message key is needed'), 'key ' . (defined($key) ? (ref($key) || "''") : 'undef') . ': refused';
	}
	is($lh->text('no_such_key'), 'no_such_key', 'a real string: accepted');
};

subtest 'M5: text values - undef, a hash, or anything else' => sub {
	# undef and a hash are accepted; everything else is refused, including
	# the false values "" and 0, which "||=" used to let through
	my $lh = App::Syslogd::I18N->handle('en');
	returns_ok($lh->text('open_failed', undef), { type => 'string' }, 'undef: accepted');
	returns_ok($lh->text('open_failed', {}), { type => 'string' }, 'a hash: accepted');
	foreach my $bad ('', 0, '0', 'x') {
		throws_ok { $lh->text('open_failed', $bad) } exact('Message values must be a hash reference (the type given was SCALAR)'), "'$bad': refused";
	}
	throws_ok { $lh->text('open_failed', []) } exact('Message values must be a hash reference (the type given was ARRAY)'), 'an array: refused';
};

subtest 'gender: defined(g) && exists(form{lc g})' => sub {
	# Three reachable rows; "undefined but a known form" cannot exist
	my $lh = App::Syslogd::I18N->handle('en');
	is($lh->gender(undef, 'M', 'F', 'N'), 'N', 'undef: neutral');
	is($lh->gender('other', 'M', 'F', 'N'), 'N', 'defined, not a known form: neutral');
	is($lh->gender('FEMALE', 'M', 'F', 'N'), 'F', 'defined, a known form: that form');
};

subtest 'handle: get_handle(tag) || get_handle(en)' => sub {
	# Both rows of the OR: a match is used; no match falls back to English
	my @asked;
	my @answers;
	my $g = mock_scoped('App::Syslogd::I18N::get_handle' => sub { shift; push @asked, [@_]; return shift(@answers) });
	@answers = ('MATCH');
	is(App::Syslogd::I18N->handle('xx'), 'MATCH', 'a match: used');
	is_deeply(\@asked, [['xx']], '...English is not asked for');
	@asked = ();
	@answers = (undef, 'ENGLISH');
	is(App::Syslogd::I18N->handle('xx'), 'ENGLISH', 'no match: English');
	is_deeply(\@asked, [['xx'], ['en']], '...asked second');
};

subtest 'i18n: ref(self) chooses the handle' => sub {
	# An object uses its own handle; the class makes one from the environment
	my $made = 0;
	my $g = mock_scoped('App::Syslogd::I18N::handle' => do {
		my $real = \&App::Syslogd::I18N::handle;
		sub { $made++; return $real->(@_) };
	});
	my $server = App::Syslogd->new();
	$made = 0;
	$server->i18n('shutdown', { count => 1 });
	is($made, 0, 'an object: no new handle');
	App::Syslogd->i18n('shutdown', { count => 1 });
	is($made, 1, 'the class: a new handle');
};

done_testing();
