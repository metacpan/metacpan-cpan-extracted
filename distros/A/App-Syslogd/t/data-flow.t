#!/usr/bin/env perl

# Data-flow tests: follow each piece of data and each resource through its
# whole life - where it is defined, where it is used, and where it is
# destroyed - and check that nothing leaks, goes stale or is left open.
#
# Define-use chains covered
#	options:  new() arguments / environment -> validated -> object fields
#	datagram: recv -> parse_message -> _escape_controls -> CSV line ->
#	          _append_line -> file
#	host:     sockaddr -> getnameinfo / cache -> _escape_controls -> CSV
#	log fh:   _open_log (sysopen) -> _append_line -> _close_log
#	socket:   open_socket (or new()) -> _receive -> _shutdown
#	flags:    run(): running and reopen_requested, set and cleared
#	errors:   $!, $IO::Socket::errstr -> the messages that report them
#
# Strategy
#	* Open descriptors are counted (on systems that list them in
#	  /proc/self/fd or /dev/fd) before and after each operation, including
#	  operations that die part way, to prove no handle is ever left open.
#	* Spies (Test::Mockingbird) record the order data passes through the
#	  stages, without changing what happens.
#	* syswrite is replaced (mock_core, before the module is compiled) to
#	  make writes fail on demand.
#	* Tests marked "regression" cover data-flow anomalies found and fixed
#	  while writing them.

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Errno qw(EADDRINUSE EINTR ENOSPC);
use File::Spec;
use File::Temp qw(tempdir);
use Readonly;
use Scalar::Util qw(weaken);
use Socket qw(pack_sockaddr_in inet_aton);
use Test::Mockingbird;
use Test::Most;
use Test::Returns;
use Text::CSV;

# Make syswrite fail on demand.  CORE::GLOBAL overrides only reach code
# compiled after them, so this comes before App::Syslogd is loaded.
our $SYSWRITE_MODE = 'real';
BEGIN {
	mock_core('syswrite' => sub {
		my ($real, $fh, $buffer, $length, $offset) = @_;
		if($main::SYSWRITE_MODE eq 'full') {
			$! = Errno::ENOSPC();
			return undef;
		}
		if($main::SYSWRITE_MODE eq 'stuck') {	# no progress and no error
			$! = 0;
			return 0;
		}
		return $real->($fh, $buffer, $length // length($buffer), $offset // 0);
	});
}

use App::Syslogd;
use App::Syslogd::I18N;

# White-box: the spies wrap private helpers, which the encapsulation
# modules allow only when told to (prove sets HARNESS_ACTIVE; this makes
# the test work when run directly too)
$Sub::Private::BYPASS = $Sub::Protected::BYPASS = 1;

Readonly my %CONFIG => (
	peer_ip => '192.0.2.1',
	peer_name => 'sender.example.com',
	unprivileged_port => 5514,
	header => [qw(Host facility severity msg)],
	stale_error => 'stale: an older, unrelated socket failure',
	fd_dirs => ['/proc/self/fd', '/dev/fd'],
);

my $PEER = pack_sockaddr_in(514, inet_aton($CONFIG{peer_ip}));
my $dir = tempdir(CLEANUP => 1);
my $serial = 0;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub verbose_diag { diag(@_) if($ENV{TEST_VERBOSE}); return }

sub new_path { return File::Spec->catfile($dir, 'flow' . ++$serial . '.csv') }

sub errno_text { my $errno = shift; local $! = $errno; return "$!" }

sub exact { my $message = shift; return qr/\A\Q$message\E at \S.* line \d+\.?\n?\z/s }

sub read_csv {
	my $file = shift;
	my $csv = Text::CSV->new({ binary => 1, decode_utf8 => 0 });
	open(my $fh, '<:raw', $file) or die "$file: $!";
	my $rows = $csv->getline_all($fh);
	close($fh);
	return $rows;
}

# Where this system lists the open descriptors, if anywhere
my ($FD_DIR) = grep { opendir(my $dh, $_) } @{$CONFIG{fd_dirs}};

# How many descriptors this process has open, or undef if unknown
sub open_fds {
	return undef unless($FD_DIR);
	opendir(my $dh, $FD_DIR) or return undef;
	my @fds = grep { /\A\d+\z/ } readdir($dh);
	closedir($dh);
	return scalar(@fds);
}

# Run $code and check it leaves no more descriptors open than before.
# Exceptions from $code are caught and returned, so a test can check the
# descriptors even when the operation dies part way.
sub no_fd_leak {
	my ($code, $name) = @_;
	my $before = open_fds();
	my $ok = eval { $code->(); 1 };
	my $error = $ok ? undef : $@;
	SKIP: {
		skip('this system does not list open descriptors', 1) unless(defined($before));
		is(open_fds(), $before, "$name: no descriptor left open");
	}
	return $error;
}

# A socket double that counts how often it is closed, and can be made to
# die when it is
{
	package CountingSocket;
	sub new { my ($class, %args) = @_; return bless { steps => [], closed => 0, %args }, $class }
	# Running out of steps is a test bug that would loop for ever: die
	sub recv { my $self = $_[0]; my $step = shift(@{$self->{steps}}) or die "CountingSocket: no steps left\n"; return $step->(\$_[1]) }
	sub close { my $self = shift; $self->{closed}++; die $self->{close_dies} if($self->{close_dies}); return 1 }
}

# ===========================================================================
# Options: new() -> object
# ===========================================================================

subtest 'options: defined once, copied, never shared with the caller' => sub {
	# Purpose: new() reads the caller's options but must not change them,
	# and the object must not change if the caller's hash changes later.
	# undef values are killed (not stored); objects are shared by design.
	my $cache = bless {}, 'SharedCache';
	{ no strict 'refs'; *{'SharedCache::compute'} = sub { $_[3]->() } }
	my $args = { port => $CONFIG{unprivileged_port}, file => undef, cache => $cache };
	my %snapshot = %{$args};

	my $server = App::Syslogd->new($args);
	returns_ok($server, { type => 'object', isa => 'App::Syslogd' }, 'an App::Syslogd');
	is_deeply($args, \%snapshot, "the caller's options are not changed");

	$args->{port} = 1;
	is($server->port(), $CONFIG{unprivileged_port}, "changing the caller's hash later does not change the object");
	ok(!exists($server->{file}) || defined($server->{file}), 'an undef option is not stored as undef');
	is($server->{file}, $App::Syslogd::DEFAULTS{file}, '...the default takes its place');
	is($server->{cache}, $cache, 'an object option is shared, not copied (documented)');

	# Two objects never share their option data
	my ($one, $two) = map { App::Syslogd->new(port => $_) } (1, 2);
	$one->{port} = 3;
	is($two->port(), 2, 'objects do not share option storage');
	isnt($one->{csv}, $two->{csv}, 'each object has its own CSV writer');
	isnt($one->{lh}, $two->{lh}, 'and its own language handle');
};

# ===========================================================================
# Datagram: recv -> parse -> escape -> CSV -> file
# ===========================================================================

subtest 'datagram: each stage gets the previous stage output' => sub {
	# Purpose: follow one datagram through every stage.  Strategy: spies
	# record the calls (and let them run), in order.
	my $file = new_path();
	my $server = App::Syslogd->new(file => $file, resolve => 0)->reopen_log();

	my @order;
	my @spies = map {
		my $stage = $_;
		my $spy = spy("App::Syslogd::$stage");
		[$stage, $spy];
	} qw(parse_message _peer_name _write_row _csv_line _append_line);

	my $datagram = "<34>line\none";
	$server->process($datagram, $PEER);

	my %calls = map { $_->[0] => [$_->[1]->()] } @spies;
	restore_all();
	verbose_diag(explain({ map { $_ => scalar(@{$calls{$_}}) } keys %calls }));

	is($calls{parse_message}[0][2], $datagram, 'parse_message gets the datagram unchanged');
	is($calls{_peer_name}[0][2], $PEER, '_peer_name gets the sender address');
	is_deeply($calls{_write_row}[0][2], [$CONFIG{peer_ip}, 4, 2, 'line\x0Aone'], '_write_row gets [escaped host, facility, severity, escaped message]');
	is_deeply($calls{_csv_line}[0][2], [$CONFIG{peer_ip}, 4, 2, 'line\x0Aone'], '_csv_line gets the same fields');
	is($calls{_append_line}[0][3], qq{"$CONFIG{peer_ip}","4","2","line\\x0Aone"\n}, '_append_line gets one quoted line');
	is_deeply(read_csv($file)->[1], [$CONFIG{peer_ip}, 4, 2, 'line\x0Aone'], 'and that is what the file holds');
	is($datagram, "<34>line\none", "the caller's datagram is not changed");
	is($server->count(), 1, 'counted once');
};

subtest 'datagram: results are fresh, never shared' => sub {
	# Purpose: parse_message returns a new hash every time; changing one
	# result cannot affect another or the next call
	my $first = App::Syslogd->parse_message('<13>same');
	$first->{message} = 'changed';
	my $second = App::Syslogd->parse_message('<13>same');
	is($second->{message}, 'same', 'a later result is not affected');
	isnt($first, $second, 'two calls give two different hashes');
};

subtest 'regression: parse_message assigns each value once' => sub {
	# Purpose: the body used to be taken from the regular expression and
	# then overwritten for an invalid PRI (a DD anomaly).  Behaviour must
	# be the same now that each value is assigned once.
	is_deeply(App::Syslogd->parse_message('<13>ok'), { facility => 1, severity => 5, message => 'ok', valid => 1 }, 'valid PRI');
	is_deeply(App::Syslogd->parse_message('<192>no'), { facility => 1, severity => 5, message => '<192>no', valid => 0 }, 'PRI too big');
	is_deeply(App::Syslogd->parse_message('plain'), { facility => 1, severity => 5, message => 'plain', valid => 0 }, 'no PRI');
	is_deeply(App::Syslogd->parse_message('<0>'), { facility => 0, severity => 0, message => '', valid => 1 }, 'PRI 0 with an empty body');
};

# ===========================================================================
# Host: sockaddr -> resolver / cache -> CSV
# ===========================================================================

subtest 'host: a name is defined once per cache entry and reused' => sub {
	# Purpose: the resolved name is stored in the cache and used for later
	# datagrams; with dns_ttl 0 it is never reused
	my $lookups = 0;
	my $g = mock_scoped('App::Syslogd::getnameinfo' => sub {
		my (undef, $flags) = @_;
		return ('', $CONFIG{peer_ip}) if($flags & Socket::NI_NUMERICHOST());
		$lookups++;
		return ('', $CONFIG{peer_name});
	});

	my $file = new_path();
	my $server = App::Syslogd->new(file => $file)->reopen_log();
	$server->process("<13>$_", $PEER) foreach(1 .. 3);
	is($lookups, 1, 'looked up once, then used from the cache');
	is_deeply([map { $_->[0] } @{read_csv($file)}[1 .. 3]], [($CONFIG{peer_name}) x 3], 'every row has the name');

	$lookups = 0;
	my $fresh = App::Syslogd->new(file => new_path(), dns_ttl => 0)->reopen_log();
	$fresh->process("<13>$_", $PEER) foreach(1 .. 2);
	cmp_ok($lookups, '>=', 1, 'dns_ttl 0: looked up');
};

# ===========================================================================
# The log file handle: open -> write -> close
# ===========================================================================

subtest 'log handle: open, reopen and close leave nothing open' => sub {
	# Purpose: reopen_log() closes the old handle before opening the new
	# one; a server that is freed closes its handle
	my $file = new_path();
	my $server = App::Syslogd->new(file => $file, resolve => 0);
	my $baseline = open_fds();

	$server->reopen_log();
	my $first = $server->{fh};
	ok(defined(fileno($first)), 'opened');
	$server->reopen_log();
	ok(!defined(fileno($first)), 'reopening closes the old handle');
	SKIP: {
		skip('this system does not list open descriptors', 1) unless(defined($baseline));
		is(open_fds(), $baseline + 1, 'exactly one descriptor open after reopening twice');
	}

	no_fd_leak(sub {
		my $short_lived = App::Syslogd->new(file => new_path(), resolve => 0)->reopen_log();
		$short_lived->process('<13>x', $PEER);
		my $weak = $short_lived;
		weaken($weak);
		undef $short_lived;
		ok(!defined($weak), 'the server is freed');
	}, 'a server that goes out of scope');
};

subtest 'regression: a refused or failed log open closes its handle' => sub {
	# Purpose: when _open_log refuses a file after opening it (a hard
	# link), or cannot write the header, the handle is closed at once,
	# not left for the garbage collector (an O~ anomaly)
	my $closed;
	my $g = mock_scoped('App::Syslogd::_discard' => do {
		my $real = \&App::Syslogd::_discard;
		sub { $closed++; return $real->(@_) };
	});

	SKIP: {
		my $target = new_path();
		open(my $fh, '>', $target) or die;
		close($fh);
		my $hard = new_path();
		skip("cannot make a hard link: $!", 3) unless(eval { link($target, $hard) });
		skip('this system does not report link counts', 3) unless((stat $hard)[3] == 2);
		$closed = 0;
		my $error = no_fd_leak(sub { App::Syslogd->new(file => $hard)->reopen_log() }, 'a hard link');
		like($error, qr/\ARefusing to log to /, 'refused');
		is($closed, 1, 'the handle was closed before the error was raised');
	}

	$closed = 0;
	local $SYSWRITE_MODE = 'full';
	my $new_file = new_path();
	my $error = no_fd_leak(sub { App::Syslogd->new(file => $new_file)->reopen_log() }, 'a header that cannot be written');
	like($error, exact("Could not write to log file $new_file: " . errno_text(ENOSPC)), 'the header error is passed on');
	is($closed, 1, 'the handle was closed before the error was raised');
};

subtest 'log handle: failures mid-flight leave nothing open' => sub {
	# Purpose: a write failure, a refused file and a missing directory
	# never leave a descriptor behind
	my ($server, $file) = (undef, new_path());
	$server = App::Syslogd->new(file => $file, resolve => 0)->reopen_log();
	{
		local $SYSWRITE_MODE = 'full';
		local $SIG{__WARN__} = sub { };
		no_fd_leak(sub { $server->process('<13>lost', $PEER) }, 'a failed write');
	}
	no_fd_leak(sub { App::Syslogd->new(file => $dir)->reopen_log() }, 'a directory');
	no_fd_leak(sub { App::Syslogd->new(file => File::Spec->catfile($dir, 'no', 'dir', 'x.csv'))->reopen_log() }, 'a missing directory');
	SKIP: {
		skip('no /dev/null here', 1) unless(-e '/dev/null');
		no_fd_leak(sub { App::Syslogd->new(file => '/dev/null')->reopen_log() }, 'a device');
	}
};

subtest 'regression: a write that makes no progress reports a real reason' => sub {
	# Purpose: when syswrite returns 0 it sets no error, so $! held a
	# stale value from some earlier call (a ~U anomaly).  The message must
	# say what happened instead.
	my $file = new_path();
	my $server = App::Syslogd->new(file => $file, resolve => 0)->reopen_log();
	my @warnings;
	{
		local $SYSWRITE_MODE = 'stuck';
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		$! = EADDRINUSE;	# a stale error that must not be reported
		$server->process('<13>stuck', $PEER);
	}
	is(scalar(@warnings), 1, 'one warning');
	like($warnings[0] // '', exact("Could not write to log file $file: the system accepted no data"), 'with the real reason');
};

# ===========================================================================
# The socket: open -> receive -> shut down
# ===========================================================================

subtest 'socket: opened once, closed once, by run()' => sub {
	# Purpose: open_socket() creates the socket only once; run() closes
	# it (and the log) exactly once when it returns
	my $created = 0;
	my $socket;
	my $server;
	my $g = mock_scoped('IO::Socket::IP::new' => sub {
		$created++;
		return $socket = CountingSocket->new(steps => [sub { $server->stop(); $! = EINTR; return undef }]);
	});

	$server = App::Syslogd->new(file => new_path(), resolve => 0);
	$server->open_socket()->open_socket();
	is($created, 1, 'opened once');
	$server->run();
	is($socket->{closed}, 1, 'closed once by run()');
	ok(!$server->{socket}, 'and forgotten');
	ok(!$server->{fh}, 'the log is closed too');
};

subtest 'regression: a socket that dies on close still lets the log close' => sub {
	# Purpose: if closing the socket dies, the log used to stay open (an
	# O~ anomaly on the error path).  Both must be released and the error
	# passed on.
	my $server;
	my $socket = CountingSocket->new(close_dies => "socket close failed\n",
		steps => [sub { $server->stop(); $! = EINTR; return undef }]);
	$server = App::Syslogd->new(file => new_path(), resolve => 0, socket => $socket);
	my $error = no_fd_leak(sub { $server->run() }, 'run() when close() dies');
	is($error, "socket close failed\n", 'the close error is passed on');
	is($socket->{closed}, 1, 'the socket close was attempted');
	ok(!$server->{fh}, 'the log handle is closed');
	ok(!$server->{socket}, 'the socket is forgotten');
};

subtest 'socket: an exception mid-run leaves resources owned, then freed' => sub {
	# Purpose: if recv() dies, run() passes the error on.  As documented,
	# the socket and log stay with the object (so it can run again), and
	# freeing the object releases them.
	no_fd_leak(sub {
		my $socket = CountingSocket->new(steps => [sub { die "connection dropped\n" }]);
		my $server = App::Syslogd->new(file => new_path(), resolve => 0, socket => $socket);
		throws_ok { $server->run() } qr/\Aconnection dropped\n\z/, 'the error is passed on';
		ok($server->{fh} && defined(fileno($server->{fh})), 'the log is still open, owned by the object');
		ok(!$server->{running}, 'the running flag is cleared');
		undef $server;
	}, 'an object freed after a failed run()');
};

subtest 'regression: errors come from the failing call, not an older one' => sub {
	# Purpose: $IO::Socket::errstr is a global; if the constructor failed
	# without setting it, an older failure's text was reported (a ~U
	# anomaly).  The caller's value must also be left alone.
	local $IO::Socket::errstr = $CONFIG{stale_error};
	my $g = mock_scoped('IO::Socket::IP::new' => sub { $! = EADDRINUSE; return undef });
	throws_ok { App::Syslogd->new(port => $CONFIG{unprivileged_port})->open_socket() }
		exact("Could not create a UDP socket on 0.0.0.0 port $CONFIG{unprivileged_port}: " . errno_text(EADDRINUSE)),
		'the real reason, not the stale one';
	is($IO::Socket::errstr, $CONFIG{stale_error}, "the caller's \$IO::Socket::errstr is restored");
};

# ===========================================================================
# Flags: running and reopen_requested
# ===========================================================================

subtest 'regression: run() flags never outlive run()' => sub {
	# Purpose: a SIGHUP that arrives together with the stop signal used
	# to leave reopen_requested set after run() returned (a D~ anomaly),
	# so the next run() reopened the log for no reason
	my $socket = CountingSocket->new(steps => [sub { $SIG{HUP}->('HUP'); $SIG{TERM}->("TERM"); $! = Errno::EINTR(); return undef }]);
	my $server = App::Syslogd->new(file => new_path(), resolve => 0, socket => $socket);
	$server->run();
	ok(!$server->{reopen_requested}, 'reopen_requested is not left set');
	ok(!$server->{running}, 'running is not left set');

	# The next run() opens the log once, not twice
	my $spy = spy('App::Syslogd::reopen_log');
	$server->{socket} = CountingSocket->new(steps => [sub { $server->stop(); $! = EINTR; return undef }]);
	$server->run();
	is(scalar(my @calls = $spy->()), 1, 'the next run() opens the log exactly once');
	restore_all();
};

# ===========================================================================
# Messages: values -> catalogue -> text
# ===========================================================================

subtest 'messages: values are read, never changed' => sub {
	# Purpose: text() only reads the values hash; each server keeps its
	# own language handle
	my $values = { file => 'F', error => 'E' };
	my %snapshot = %{$values};
	my $lh = App::Syslogd::I18N->handle('en');
	returns_ok($lh->text('open_failed', $values), { type => 'string' }, 'a string');
	is_deeply($values, \%snapshot, 'the values hash is not changed');
	$lh->text('open_failed', {});
	is_deeply($values, \%snapshot, 'nor by a later call with missing values');

	foreach ('read-only') {
		lives_ok { $lh->text('listening', { address => 'a', port => 1 }) } '$_ is not modified';
	}
};

done_testing();
