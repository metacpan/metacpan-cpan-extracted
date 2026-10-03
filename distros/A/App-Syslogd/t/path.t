#!/usr/bin/env perl

# Path coverage: one test for every distinct path through every routine
# in lib/, including implicit "else" branches, early returns, exception
# exits and each way a loop can run.
#
# The path list for each routine is in the comment above its subtest.
# Paths are named "routine: Pn - description".  Builtins are bent through
# mock_core (installed before App::Syslogd is compiled) to reach paths a
# test machine cannot produce for real, such as a short write.
#
# Path analysis found no dead code, and no loop that never runs, runs
# exactly once, or runs at most once:
#	new()           foreach @CONFIGURE_EXTRAS     always 2 times
#	run()           while(running)                1 or more times
#	_append_line()  while(done < length)          1 or more times
#	BEGIN block     foreach $module               always 2 times
#	                foreach $name (unwrapped)     0 or more times
# so no TODO markers were needed in the modules.

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Errno qw(EBADF EINTR ENOSPC ENOENT);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3 qw(open3);
use Readonly;
use Socket qw(pack_sockaddr_in inet_aton);
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

# Switches for bent builtins; each passes through unless set.
#	$SYSWRITE: 'full' (ENOSPC), 'stuck' (0 bytes, no error),
#	           'half' (half, then 'full'), 'split' (half, then the rest)
#	$SYSSEEK_FAILS: sysseek returns undef
our ($SYSWRITE, $SYSSEEK_FAILS) = ('', 0);
BEGIN {
	mock_core('syswrite' => sub {
		my ($real, $fh, $buffer, $length, $offset) = @_;
		$length //= length($buffer);
		$offset //= 0;
		my $mode = $main::SYSWRITE;
		if($mode eq 'full') { $! = Errno::ENOSPC(); return undef }
		if($mode eq 'stuck') { $! = 0; return 0 }
		if($mode eq 'half') { $main::SYSWRITE = 'full'; return $real->($fh, $buffer, int($length / 2), $offset) }
		if($mode eq 'split') { $main::SYSWRITE = ''; return $real->($fh, $buffer, int($length / 2), $offset) }
		return $real->($fh, $buffer, $length, $offset);
	});
	mock_core('sysseek' => sub {
		my ($real, @args) = @_;
		return undef if($main::SYSSEEK_FAILS);
		return $real->(@args);
	});
}

use App::Syslogd;
use App::Syslogd::I18N;

# White-box: private helpers are called directly to reach their paths
$Sub::Private::BYPASS = $Sub::Protected::BYPASS = 1;

Readonly my %CONFIG => (
	peer_ip => '192.0.2.1',
	peer_name => 'sender.example.com',
	unprivileged_port => 5514,
	max_pri => 191,
	header => '"Host","facility","severity","msg"',
	lib => File::Spec->catdir($Bin, File::Spec->updir(), 'lib'),
);

my $PEER = pack_sockaddr_in(514, inet_aton($CONFIG{peer_ip}));
my $dir = tempdir(CLEANUP => 1);
my $serial = 0;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub verbose_diag { diag(@_) if($ENV{TEST_VERBOSE}); return }

sub new_path { return File::Spec->catfile($dir, 'path' . ++$serial . '.csv') }

sub errno_text { my $errno = shift; local $! = $errno; return "$!" }

sub exact { my $message = shift; return qr/\A\Q$message\E at \S.* line \d+\.?\n?\z/s }

sub slurp { my $file = shift; open(my $fh, '<:raw', $file) or die "$file: $!"; local $/; return scalar(<$fh>) }

# A writable handle on a new file, and its name
sub new_handle { my $file = new_path(); open(my $fh, '>>', $file) or die "$file: $!"; return ($fh, $file) }

# Collect warnings from $code
sub warnings_of { my $code = shift; my @w; local $SIG{__WARN__} = sub { push @w, $_[0] }; $code->(); return \@w }

# Run a Perl script in a child process (code in a file: no -e quoting
# problems on Windows); return (exit code, stdout, stderr)
sub run_child {
	my $code = shift;
	my $script = File::Spec->catfile($dir, 'child' . ++$serial . '.pl');
	open(my $fh, '>', $script) or die;
	print {$fh} "$code\n";
	close($fh);
	my ($out, $err) = map { File::Spec->catfile($dir, "child$serial.$_") } qw(out err);
	open(my $o, '>', $out) or die;
	open(my $e, '>', $err) or die;
	local $ENV{HARNESS_ACTIVE};
	delete $ENV{HARNESS_ACTIVE};	# the harness bypass would hide enforcement
	my $pid = open3(my $in, '>&' . fileno($o), '>&' . fileno($e), $^X, "-I$CONFIG{lib}", $script);
	close($in);
	waitpid($pid, 0);
	my $exit = $? >> 8;
	close($o);
	close($e);
	return ($exit, map { (my $t = slurp($_)) =~ s/\r\n/\n/g; $t } ($out, $err));
}

# Socket doubles
{
	package StepSocket;
	sub new { my ($class, @steps) = @_; return bless { steps => [@steps], closed => 0 }, $class }
	sub recv { my $self = $_[0]; my $step = shift(@{$self->{steps}}) or die "StepSocket: no steps left\n"; return $step->(\$_[1]) }
	sub sockport { return 1 }
	sub sockhost { return '127.0.0.1' }
	sub close { my $self = shift; $self->{closed}++; die $self->{close_dies} if($self->{close_dies}); return 1 }
}
{
	package BareSocket;
	sub new { return bless {}, shift }
	sub recv { return undef }
	sub close { return 1 }
}
{
	package PathCache;
	sub new { my ($class, $code) = @_; return bless { code => $code }, $class }
	sub compute { my $self = shift; return $self->{code}->(@_) }
}

# A step that stops run(), as a signal would
sub stop_step { my $server_ref = shift; return sub { ${$server_ref}->stop(); $! = Errno::EINTR(); return undef } }

# ===========================================================================
# App::Syslogd
# ===========================================================================

# new:
#	P1 no arguments (get_params gives undef -> {}); cache built
#	P2 a cache given (the ||= is skipped)
#	P3 Object::Configure gives no extras (the "if defined" is false)
#	P4 an undef option (the delete removes it)
#	P5 the first validation dies
#	P6 the second validation dies (a bad configured value)
subtest 'new: every path' => sub {
	my $p1 = App::Syslogd->new();
	returns_ok($p1, { type => 'object', isa => 'App::Syslogd' }, 'P1: no arguments');
	isa_ok($p1->{cache}, 'App::Syslogd::Cache', 'P1: the built-in cache is made');

	my $cache = PathCache->new(sub { });
	is(App::Syslogd->new(cache => $cache)->{cache}, $cache, 'P2: the given cache is kept');

	{
		my $g = mock_scoped('Object::Configure::configure' => sub { return { %{$_[1]} } });
		my $p3 = App::Syslogd->new(port => 1);
		ok(!exists($p3->{logger}) && !exists($p3->{config_path}), 'P3: no extras, none stored');
	}

	my $p4 = App::Syslogd->new(file => undef);
	is($p4->{file}, $App::Syslogd::DEFAULTS{file}, 'P4: an undef option is removed (the default stays)');

	throws_ok { App::Syslogd->new(prot => 1) } qr/validate_strict: Unknown parameter 'prot'/, 'P5: the first validation dies';
	{
		local $ENV{App__Syslogd__port} = 'abc';
		throws_ok { App::Syslogd->new() } qr/validate_strict: Parameter 'port' \(abc\)/, 'P6: the second validation dies';
	}
};

# open_socket:
#	P1 a socket exists (the constructor is not called)
#	P2 the constructor succeeds
#	P3 it fails, errstr set
#	P4 it fails, errstr empty (the reason comes from $!)
subtest 'open_socket: every path' => sub {
	my $called = 0;
	my $result;
	my $g = mock_scoped('IO::Socket::IP::new' => sub { $called++; return $result->() });

	$result = sub { StepSocket->new() };
	my $p1 = App::Syslogd->new(socket => BareSocket->new());
	$p1->open_socket();
	is($called, 0, 'P1: socket exists, not called');

	returns_ok(App::Syslogd->new()->open_socket(), { type => 'object', isa => 'App::Syslogd' }, 'P2: succeeds');

	$result = sub { $IO::Socket::errstr = 'from errstr'; return undef };
	throws_ok { App::Syslogd->new(port => 1)->open_socket() } exact('Could not create a UDP socket on 0.0.0.0 port 1: from errstr'), 'P3: errstr';

	$result = sub { $! = ENOENT; return undef };
	throws_ok { App::Syslogd->new(port => 1)->open_socket() }
		exact('Could not create a UDP socket on 0.0.0.0 port 1: ' . errno_text(ENOENT)), 'P4: $!';
};

# port / address:
#	P1 no socket; P2 a socket without the method; P3 a socket with it
subtest 'port and address: every path' => sub {
	is(App::Syslogd->new(port => 7)->port(), 7, 'port P1: no socket');
	is(App::Syslogd->new(port => 7, socket => BareSocket->new())->port(), 7, 'port P2: no sockport()');
	is(App::Syslogd->new(port => 7, socket => StepSocket->new())->port(), 1, 'port P3: sockport()');
	is(App::Syslogd->new(address => 'a')->address(), 'a', 'address P1: no socket');
	is(App::Syslogd->new(address => 'a', socket => BareSocket->new())->address(), 'a', 'address P2: no sockhost()');
	is(App::Syslogd->new(address => 'a', socket => StepSocket->new())->address(), '127.0.0.1', 'address P3: sockhost()');
};

# count / stop: one path each
subtest 'count and stop: their single path' => sub {
	my $server = App::Syslogd->new();
	returns_ok($server->count(), { type => 'integer', min => 0 }, 'count P1');
	returns_ok($server->stop(), { type => 'object', isa => 'App::Syslogd' }, 'stop P1');
	ok(!$server->{running}, 'stop P1: running cleared');
};

# reopen_log:
#	P1 success; P2 _open_log dies (after _close_log has run)
subtest 'reopen_log: every path' => sub {
	my $server = App::Syslogd->new(file => new_path());
	returns_ok($server->reopen_log(), { type => 'object', isa => 'App::Syslogd' }, 'P1: success');
	$server->{file} = File::Spec->catfile($dir, 'missing', 'x.csv');
	throws_ok { $server->reopen_log() } qr/\ACould not open log file /, 'P2: dies';
	ok(!$server->{fh}, 'P2: the old log was closed first');
};

# parse_message:
#	P1 a plain reference, called on the class -> dies
#	P2 a plain reference, called as a function ($self undef) -> dies
#	P3 an overloaded reference -> continues
#	P4 too short -> undef
#	P5 valid PRI
#	P6 no match -> invalid
#	P7 match but > 191 -> invalid
subtest 'parse_message: every path' => sub {
	throws_ok { App::Syslogd->parse_message([]) } exact('A datagram must be a string (the type given was ARRAY)'), 'P1: class call';
	throws_ok { App::Syslogd::parse_message(undef, {}) } exact('A datagram must be a string (the type given was HASH)'), 'P2: function call';
	{
		package PathString;
		use overload q{""} => sub { '<13>overloaded' }, fallback => 1;
	}
	is(App::Syslogd->parse_message(bless({}, 'PathString'))->{message}, 'overloaded', 'P3: overloaded');
	is(App::Syslogd->parse_message('x'), undef, 'P4: too short');
	is(App::Syslogd->parse_message(undef), undef, 'P4: undef (taken as "") is too short');
	is(App::Syslogd->parse_message('<13>m')->{valid}, 1, 'P5: valid');
	is(App::Syslogd->parse_message('nope')->{valid}, 0, 'P6: no match');
	is(App::Syslogd->parse_message('<' . ($CONFIG{max_pri} + 1) . '>m')->{valid}, 0, 'P7: above 191');
};

# process:
#	P1 no log -> dies; P2 too short -> nothing; P3 recorded
subtest 'process: every path' => sub {
	throws_ok { App::Syslogd->new()->process('<13>x', $PEER) } exact('process() was called before reopen_log() succeeded'), 'P1: no log';
	my $file = new_path();
	my $server = App::Syslogd->new(file => $file, resolve => 0)->reopen_log();
	$server->process('x', $PEER);
	is($server->count(), 0, 'P2: too short, nothing written');
	$server->process('<13>y', $PEER);
	is($server->count(), 1, 'P3: recorded');
	like(slurp($file), qr/"y"\n\z/, 'P3: written');
};

# run:
#	P1 the log is not open (reopened before the loop)
#	P2 the log is open (not reopened)
#	P3 loop: reopen requested
#	P4 loop: a sender (processed)
#	P5 loop: no sender (not processed)
#	P6 loop ends (running false) -> shut down
#	P7 open_socket dies before the loop
#	P8 the loop ends through the SIGTERM handler
#	P9 the loop ends through the SIGINT handler
subtest 'run: every path' => sub {
	my $spy = spy('App::Syslogd::reopen_log');
	my $server;
	my $socket = StepSocket->new(
		sub { $SIG{HUP}->('HUP'); $! = Errno::EINTR(); return undef },		# P5, and requests P3
		sub { ${$_[0]} = '<13>x'; return $PEER },			# P3 then P4
		stop_step(\$server),						# P6
	);
	$server = App::Syslogd->new(file => new_path(), resolve => 0, socket => $socket);
	$server->run();
	is(scalar(my @c = $spy->()), 2, 'P1 and P3: reopened before the loop and on the request');
	is($server->count(), 1, 'P4: the sender was processed; P5: the empty one was not');
	is($socket->{closed}, 1, 'P6: shut down');
	restore_all();

	$spy = spy('App::Syslogd::reopen_log');
	$server = App::Syslogd->new(file => new_path(), resolve => 0);
	$server->reopen_log();
	$server->{socket} = StepSocket->new(stop_step(\$server));
	$server->run();
	is(scalar(my @d = $spy->()), 1, 'P2: an open log is not reopened by run()');
	restore_all();

	foreach my $signal (qw(TERM INT)) {
		my $by_signal = App::Syslogd->new(file => new_path(), resolve => 0,
			socket => StepSocket->new(sub { $SIG{$signal}->($signal); $! = Errno::EINTR(); return undef }));
		lives_ok { $by_signal->run() } ($signal eq 'TERM' ? 'P8' : 'P9') . ": the $signal handler ends the loop";
	}

	my $g = mock_scoped('IO::Socket::IP::new' => sub { $IO::Socket::errstr = 'denied'; return undef });
	throws_ok { App::Syslogd->new(port => 1)->run() } exact('Could not create a UDP socket on 0.0.0.0 port 1: denied'), 'P7: dies before the loop';
};

# i18n: P1 an object; P2 the class
subtest 'i18n: every path' => sub {
	like(App::Syslogd->new()->i18n('shutdown', { count => 1 }), qr/1 message\z/, 'P1: object');
	like(App::Syslogd->i18n('shutdown', { count => 2 }), qr/2 messages\z/, 'P2: class');
};

# _receive:
#	P1 a sender; P2 interrupted (EINTR, silent); P3 another error (warns)
subtest '_receive: every path' => sub {
	my $make = sub { my ($peer, $errno) = @_; App::Syslogd->new(socket => StepSocket->new(sub { ${$_[0]} = 'd'; $! = $errno; return $peer })) };
	is($make->($PEER, 0)->_receive(\my $a), $PEER, 'P1: a sender');
	is_deeply(warnings_of(sub { $make->(undef, Errno::EINTR())->_receive(\my $b) }), [], 'P2: interrupted, silent');
	like(warnings_of(sub { $make->(undef, EBADF)->_receive(\my $c) })->[0] // '', exact('Error receiving a datagram: ' . errno_text(EBADF)), 'P3: warns');
};

# _open_log:
#	P1 sysopen fails -> dies
#	P2 opened but unsafe -> handle discarded, dies
#	P3 empty file, header written
#	P4 empty file, header fails -> handle discarded, dies
#	P5 not empty, starts with the header -> no second header
#	P6 not empty, does not start with the header -> discarded, dies
#	(chmod runs where fchmod exists; the other side is the Windows path)
subtest '_open_log: every path' => sub {
	throws_ok { App::Syslogd->new(file => File::Spec->catfile($dir, 'no', 'x'))->_open_log() } qr/\ACould not open log file /, 'P1: sysopen fails';

	my $discards = 0;
	my $g = mock_scoped('App::Syslogd::_discard' => do { my $real = \&App::Syslogd::_discard; sub { $discards++; $real->(@_) } });
	SKIP: {
		skip('no /dev/null', 2) unless(-c '/dev/null');
		throws_ok { App::Syslogd->new(file => '/dev/null')->_open_log() } qr/\ARefusing to log to /, 'P2: unsafe';
		is($discards, 1, 'P2: handle discarded');
	}

	my $p3 = new_path();
	App::Syslogd->new(file => $p3)->_open_log();
	is(slurp($p3), "$CONFIG{header}\n", 'P3: header written');

	$discards = 0;
	{
		local $SYSWRITE = 'full';
		my $p4 = new_path();
		throws_ok { App::Syslogd->new(file => $p4)->_open_log() } exact("Could not write to log file $p4: " . errno_text(ENOSPC)), 'P4: header fails';
		is($discards, 1, 'P4: handle discarded');
	}

	App::Syslogd->new(file => $p3)->_open_log();
	is(slurp($p3), "$CONFIG{header}\n", 'P5: not empty, no second header');

	$discards = 0;
	my $p6 = new_path();
	open(my $out, '>', $p6) or die;
	print {$out} "someone else's file\n";
	close($out);
	throws_ok { App::Syslogd->new(file => $p6)->_open_log() }
		exact("Refusing to log to $p6: it is not empty and does not start with the syslog header line"), 'P6: not one of our logs';
	is($discards, 1, 'P6: handle discarded');
};

# _starts_with_header:
#	P1 the header, LF; P2 the header, CRLF; P3 something else
#	P4 the seek fails (nothing read -> no match)
#	P5 the header line cannot be built (no match)
subtest '_starts_with_header: every path' => sub {
	my $server = App::Syslogd->new();
	my $with = sub {
		my $content = shift;
		my $file = new_path();
		open(my $out, '>:raw', $file) or die;
		print {$out} $content;
		close($out);
		open(my $in, '<', $file) or die;
		return $in;
	};
	is($server->_starts_with_header($with->("$CONFIG{header}\nrow\n")), 1, 'P1: LF');
	is($server->_starts_with_header($with->("$CONFIG{header}\r\n")), 1, 'P2: CRLF');
	is($server->_starts_with_header($with->("other\n")), 0, 'P3: something else');
	{
		local $SYSSEEK_FAILS = 1;
		is($server->_starts_with_header($with->("$CONFIG{header}\n")), 0, 'P4: the seek fails');
	}
	my $g = mock_scoped('Text::CSV::combine' => sub { 0 });
	is($server->_starts_with_header($with->("$CONFIG{header}\n")), 0, 'P5: no header line to compare');
};

# _discard: P1 close succeeds; P2 close fails (ignored)
subtest '_discard: every path' => sub {
	my ($fh) = new_handle();
	lives_ok { App::Syslogd::_discard($fh) } 'P1: closes';
	ok(!defined(fileno($fh)), 'P1: closed');
	is_deeply(warnings_of(sub { lives_ok { App::Syslogd::_discard($fh) } 'P2: closing again does not die' }), [], 'P2: and does not warn');
};

# _write_header and _write_row (same shape; one dies, one warns):
#	P1 the CSV writer refuses (no write attempted)
#	P2 the write fails
#	P3 both succeed
subtest '_write_header and _write_row: every path' => sub {
	my ($fh, $file) = new_handle();
	my $server = App::Syslogd->new(file => $file);
	$server->{fh} = $fh;
	{
		my $g = mock_scoped('Text::CSV::combine' => sub { 0 }, 'Text::CSV::error_diag' => sub { 'refused' });
		throws_ok { $server->_write_header($fh) } exact("Could not write to log file $file: refused"), 'header P1: CSV refuses';
		like(warnings_of(sub { $server->_write_row(['x']) })->[0] // '', exact("Could not write to log file $file: refused"), 'row P1: CSV refuses');
	}
	{
		local $SYSWRITE = 'full';
		throws_ok { $server->_write_header($fh) } exact("Could not write to log file $file: " . errno_text(ENOSPC)), 'header P2: write fails';
		local $SYSWRITE = 'full';
		like(warnings_of(sub { $server->_write_row(['x']) })->[0] // '', exact("Could not write to log file $file: " . errno_text(ENOSPC)), 'row P2: write fails');
	}
	returns_ok($server->_write_header($fh), { type => 'object', isa => 'App::Syslogd' }, 'header P3: succeeds');
	returns_ok($server->_write_row(['h', 1, 5, 'm']), { type => 'object', isa => 'App::Syslogd' }, 'row P3: succeeds');
	close($fh);
	is(slurp($file), qq{$CONFIG{header}\n"h","1","5","m"\n}, 'P3: both lines written');
};

# _append_line:
#	P1 one write, whole line (loop once) -> undef
#	P2 a short write, then the rest (loop twice) -> undef
#	P3 nothing written, error set -> that error, no truncate
#	P4 nothing written, no error -> no_progress
#	P5 part written, start known -> truncated
#	P6 part written, start unknown -> not truncated
subtest '_append_line: every path' => sub {
	my $server = App::Syslogd->new();
	my ($fh, $file) = new_handle();
	is($server->_append_line($fh, "one\n"), undef, 'P1: one write');
	{
		local $SYSWRITE = 'split';
		is($server->_append_line($fh, "two parts\n"), undef, 'P2: two writes');
	}
	{
		local $SYSWRITE = 'full';
		is($server->_append_line($fh, "x\n"), errno_text(ENOSPC), 'P3: the error');
	}
	{
		local $SYSWRITE = 'stuck';
		is($server->_append_line($fh, "x\n"), 'the system accepted no data', 'P4: no progress');
	}
	is(slurp($file), "one\ntwo parts\n", 'P1-P4: only whole lines in the file');
	{
		local $SYSWRITE = 'half';
		$server->_append_line($fh, "half line\n");
	}
	is(slurp($file), "one\ntwo parts\n", 'P5: the part is removed');
	{
		local $SYSWRITE = 'half';
		local $SYSSEEK_FAILS = 1;
		$server->_append_line($fh, "half line\n");
	}
	my $part = substr("half line\n", 0, int(length("half line\n") / 2));
	is(slurp($file), "one\ntwo parts\n$part", 'P6: the part stays (start unknown)');
	close($fh);
};

# _close_log: P1 a log is open; P2 none
subtest '_close_log: every path' => sub {
	my $server = App::Syslogd->new(file => new_path())->reopen_log();
	my $fh = $server->{fh};
	$server->_close_log();
	ok(!defined(fileno($fh)) && !$server->{fh}, 'P1: closed and forgotten');
	lives_ok { $server->_close_log() } 'P2: nothing open';
};

# _shutdown: P1 a socket that closes; P2 a socket whose close dies; P3 none
subtest '_shutdown: every path' => sub {
	my $make = sub { my $s = App::Syslogd->new(file => new_path())->reopen_log(); $s->{socket} = shift; return $s };
	my $p1 = $make->(StepSocket->new());
	lives_ok { $p1->_shutdown() } 'P1: closes';
	my $dying = StepSocket->new();
	$dying->{close_dies} = "close failed\n";
	my $p2 = $make->($dying);
	throws_ok { $p2->_shutdown() } qr/\Aclose failed\n\z/, 'P2: the error is passed on';
	ok(!$p2->{fh}, 'P2: the log was closed anyway');
	my $p3 = $make->(undef);
	lives_ok { $p3->_shutdown() } 'P3: no socket';
};

# _csv_line: P1 combine succeeds; P2 it fails with a reason; P3 it fails
# with no reason (the fallback text)
subtest '_csv_line: every path' => sub {
	my $server = App::Syslogd->new();
	is_deeply([$server->_csv_line(['a', 'b'])], [qq{"a","b"\n}], 'P1: the line');
	my $diag = 'refused';
	my $g = mock_scoped('Text::CSV::combine' => sub { 0 }, 'Text::CSV::error_diag' => sub { $diag });
	is_deeply([$server->_csv_line(['a'])], [undef, 'refused'], 'P2: the reason');
	$diag = '';
	is_deeply([$server->_csv_line(['a'])], [undef, 'Text::CSV could not build the line'], 'P3: the fallback');
};

# _peer_name:
#	P1 undef; P2 a reference
#	P3 the numeric lookup fails (address //= '')
#	P4 resolution off
#	P5 the name is found
#	P6 the name lookup fails (the lookup returns the address)
#	P7 the cache dies
#	P8 the cache answers nothing
subtest '_peer_name: every path' => sub {
	my $server = App::Syslogd->new(resolve => 1, cache => PathCache->new(sub { $_[2]->() }));
	is($server->_peer_name(undef), '', 'P1: undef');
	is($server->_peer_name([]), '', 'P2: a reference');
	is($server->_peer_name('garbage'), '', 'P3: undecodable');
	is(App::Syslogd->new(resolve => 0)->_peer_name($PEER), $CONFIG{peer_ip}, 'P4: resolution off');

	my $found = $CONFIG{peer_name};
	my $g = mock_scoped('App::Syslogd::getnameinfo' => sub {
		my (undef, $flags) = @_;
		return ('', $CONFIG{peer_ip}) if($flags & Socket::NI_NUMERICHOST());
		return $found ? ('', $found) : ('not found', undef);
	});
	is($server->_peer_name($PEER), $CONFIG{peer_name}, 'P5: the name');
	$found = undef;
	is($server->_peer_name($PEER), $CONFIG{peer_ip}, 'P6: not found, the address');
	is(App::Syslogd->new(cache => PathCache->new(sub { die "down\n" }))->_peer_name($PEER), $CONFIG{peer_ip}, 'P7: the cache dies');
	is(App::Syslogd->new(cache => PathCache->new(sub { undef }))->_peer_name($PEER), $CONFIG{peer_ip}, 'P8: no answer');
};

# _escape_controls: P1 nothing to escape; P2 something to escape
subtest '_escape_controls: every path' => sub {
	is(App::Syslogd::_escape_controls('plain'), 'plain', 'P1: unchanged');
	is(App::Syslogd::_escape_controls("a\tb"), 'a\x09b', 'P2: escaped');
};

# The protection block at the end of App/Syslogd.pm (runs at load time):
#	P1 loaded at compile time (CHECK will wrap; the loop body is skipped)
#	P2 loaded at run time (the subs are wrapped here; inner loop runs)
#	P3 loaded at run time with the encapsulation modules loaded first
#	   (import() wraps; the inner loop runs 0 times)
#	P4 loaded at run time and a module has no _process_one (skipped)
subtest 'protection block: every path' => sub {
	my $probe = 'my $s = App::Syslogd->new(); print eval { $s->_close_log(); 1 } ? "open\n" : "protected\n";';
	my %loaders = (
		'P1: compile time' => 'use App::Syslogd;',
		'P2: run time' => 'require App::Syslogd;',
		'P3: run time, modules loaded first' => 'BEGIN { require Sub::Private; require Sub::Protected } require App::Syslogd;',
	);
	foreach my $path (sort keys %loaders) {
		my ($exit, $stdout, $stderr) = run_child("$loaders{$path}\n$probe");
		is("$exit|$stdout|$stderr", "0|protected\n|", "$path: loads cleanly, helpers protected");
	}
	my ($exit, $stdout, $stderr) = run_child(
		"BEGIN { require Sub::Private; require Sub::Protected; no strict 'refs'; delete \$Sub::Private::{_process_one}; delete \$Sub::Protected::{_process_one} }\n"
		. "require App::Syslogd;\n"
		. 'print App::Syslogd->parse_message("<13>ok")->{message}, "\n";'
	);
	is("$exit|$stdout", "0|ok\n", 'P4: no _process_one: skipped, the module still loads and works');
};

# ===========================================================================
# App::Syslogd::I18N
# ===========================================================================

# handle:
#	P1 a tag that matches
#	P2 Locale::Maketext finds nothing, so the explicit English fallback
#	   runs.  (A tag such as "xx" is usually resolved to English by
#	   Locale::Maketext itself, from the environment, so it does not reach
#	   this path; the first lookup is made to fail instead.)
#	P3 no tag
subtest 'handle: every path' => sub {
	isa_ok(App::Syslogd::I18N->handle('en'), 'App::Syslogd::I18N::en', 'P1: a match');
	{
		my @asked;
		my $real = App::Syslogd::I18N->can('get_handle');
		my $g = mock_scoped('App::Syslogd::I18N::get_handle' => sub { push @asked, $_[1]; return @asked == 1 ? undef : $real->(@_) });
		isa_ok(App::Syslogd::I18N->handle('xx'), 'App::Syslogd::I18N::en', 'P2: nothing found, the English fallback');
		is_deeply(\@asked, ['xx', 'en'], 'P2: English was asked for second');
	}
	isa_ok(App::Syslogd::I18N->handle(undef), 'App::Syslogd::I18N', 'P3: no tag, the environment');
};

# text:
#	P1 a bad key -> dies
#	P2 values not a hash -> dies (P2a a reference, P2b a plain value)
#	P3 an unknown key with values -> "key (values)"
#	P4 an unknown key without values -> the key
#	P5 a known key (undef values become {})
subtest 'text: every path' => sub {
	my $lh = App::Syslogd::I18N->handle('en');
	foreach my $key (undef, [], '') {
		throws_ok { $lh->text($key) } exact('A message key is needed'), 'P1: a bad key (' . (defined($key) ? (ref($key) || 'empty') : 'undef') . ')';
	}
	throws_ok { $lh->text('k', []) } exact('Message values must be a hash reference (the type given was ARRAY)'), 'P2a: a reference';
	throws_ok { $lh->text('k', 'x') } exact('Message values must be a hash reference (the type given was SCALAR)'), 'P2b: a plain value';
	is($lh->text('unknown', { a => 1, b => undef }), 'unknown (a=1, b=)', 'P3: unknown, with values (an undef value shown empty)');
	is($lh->text('unknown'), 'unknown', 'P4: unknown, no values');
	is($lh->text('no_log_open', undef), 'process() was called before reopen_log() succeeded', 'P5: known');
	is($lh->text('open_failed', { file => undef }), 'Could not open log file : ', 'P5: known, undef values become empty');
};

# gender: P1 undef; P2 not a known form; P3 a known form
subtest 'gender: every path' => sub {
	my $lh = App::Syslogd::I18N->handle('en');
	is($lh->gender(undef, 'M', 'F', 'N'), 'N', 'P1: undef');
	is($lh->gender('x', 'M', 'F', 'N'), 'N', 'P2: unknown');
	is($lh->gender('female', 'M', 'F', 'N'), 'F', 'P3: known');
};

done_testing();
