#!/usr/bin/env perl

# White-box function tests: one subtest group per function, for every
# function in lib/, including the private and protected helpers.
#
# Strategy
#	* Each function is tested on its own.  Everything it calls that is not
#	  a Perl builtin is replaced with a mock (Test::Mockingbird), including
#	  other functions of the same module, so a failure points at exactly
#	  one function.  Mocks are scoped (mock_scoped) and vanish at the end
#	  of each block.
#	* Return values are checked against the API SPECIFICATION schemas in
#	  the POD (Test::Returns).
#	* Objects are checked for reference cycles and for being freed when
#	  the last reference goes (Test::Memory::Cycle, weak references).
#	* Each function is called with $_ and $@ set to known values, to prove
#	  it does not change the caller's globals.
#	* The tests describe the intended behaviour from the POD, not whatever
#	  the code happens to do.
#
# Files are processed one at a time, in this order:
#	1. lib/App/Syslogd.pm
#	2. lib/App/Syslogd/I18N.pm
#	3. lib/App/Syslogd/I18N/en.pm

use strict;
use warnings;

use Errno qw(EINTR EBADF ENOENT ENOSPC);
use File::Temp qw(tempdir);
use Readonly;
use Scalar::Util qw(weaken);
use Socket qw(pack_sockaddr_in inet_aton);
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

use App::Syslogd;
use App::Syslogd::I18N;
use App::Syslogd::I18N::en;

# White-box access: these tests call :Private and :Protected helpers
# directly, which the encapsulation modules allow only when told to
$Sub::Private::BYPASS = $Sub::Protected::BYPASS = 1;

# Every literal the tests depend on, named once
Readonly my %CONFIG => (
	peer_ip => '192.0.2.1',			# RFC 5737 TEST-NET-1: never resolves
	peer_port => 514,
	peer_name => 'sender.example.com',	# RFC 2606 reserved name
	default_port => 514,
	default_address => '0.0.0.0',
	default_file => '/var/log/syslog/syslog.csv',
	default_dns_ttl => 300,
	default_dns_cache_bytes => 262_144,
	recv_buffer => 65_535,			# largest UDP payload
	default_pri_facility => 1,		# user, RFC 3164 4.3.3
	default_pri_severity => 5,		# notice
	log_mode => 0600,
	header => '"Host","facility","severity","msg"',
	sentinel_underscore => 'caller value of $_',
	sentinel_eval_error => 'caller value of $@',
	csv_options => { binary => 1, eol => "\n", always_quote => 1 },
);

# The named values each message key takes, in [_1], [_2] ... order, as
# documented in App::Syslogd::I18N's text() table
Readonly my %ARGUMENT_ORDER => (
	usage => [qw(program)],
	listening => [qw(address port)],
	shutdown => [qw(count)],
	socket_failed => [qw(address port error)],
	open_failed => [qw(file error)],
	unsafe_file => [qw(file)],
	write_failed => [qw(file error)],
	recv_failed => [qw(error)],
	no_log_open => [],
	not_a_datagram => [qw(type)],
	missing_key => [],
	bad_values => [qw(type)],
	no_progress => [],
	not_cgi => [],
	not_a_log => [qw(file)],
	already_running => [],
);

# Output schemas copied from the POD's API SPECIFICATION sections
Readonly my %SCHEMA => (
	server => { type => 'object', isa => 'App::Syslogd' },
	port => { type => 'integer', min => 0, max => 65_535 },
	count => { type => 'integer', min => 0 },
	string => { type => 'string' },
	address => { type => 'string', min => 1 },
	record => {
		type => 'hashref',
		schema => {
			facility => { type => 'integer', min => 0, max => 23 },
			severity => { type => 'integer', min => 0, max => 7 },
			message => { type => 'string', matches => qr/\A[^\x00-\x1F\x7F]*\z/ },
			valid => { type => 'boolean' },
		},
	},
	handle => { type => 'object', isa => 'App::Syslogd::I18N' },
);

Readonly my $PEER => pack_sockaddr_in($CONFIG{peer_port}, inet_aton($CONFIG{peer_ip}));

my $dir = tempdir(CLEANUP => 1);
my $serial = 0;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Show internal state, but only when asked: prove -v sets TEST_VERBOSE
sub verbose_diag { diag(@_) if($ENV{TEST_VERBOSE}); return }

# A new, unused log file name, so tests never share a file
sub new_log { return "$dir/function" . ++$serial . '.csv' }

# The text of an errno, from Perl's own $! (never POSIX::strerror), so it
# is the same string the code under test will embed
sub errno_text { my $errno = shift; local $! = $errno; return "$!" }

# croak and carp append " at FILE line N.\n"; match the message exactly
# and allow only that suffix
sub exact { my $message = shift; return qr/\A\Q$message\E at \S.* line \d+\.?\n?\z/s }

# Read a file into an arrayref of lines without their newlines
sub lines_of {
	my $file = shift;
	open(my $fh, '<', $file) or die "$file: $!";
	chomp(my @lines = <$fh>);
	return \@lines;
}

# Call $code with $_ and $@ holding sentinels and report whether either
# changed.  Returns the code's scalar result.
sub keeps_globals {
	my ($code, $name) = @_;

	local $_ = $CONFIG{sentinel_underscore};
	local $@ = $CONFIG{sentinel_eval_error};
	my $result = $code->();
	is($_, $CONFIG{sentinel_underscore}, "$name leaves \$_ alone");
	is($@, $CONFIG{sentinel_eval_error}, "$name leaves \$\@ alone");
	return $result;
}

# Check that an object has no reference cycles and is really freed when
# the last strong reference is dropped.  The object is built by $builder
# inside this function, so that this is the only reference: an object
# passed in directly would still be held by the caller (or by @_).
sub freed_ok {
	my ($builder, $name) = @_;

	my $object = $builder->();
	memory_cycle_ok($object, "$name has no reference cycles");
	my $weak = $object;
	weaken($weak);
	undef $object;
	ok(!defined($weak), "$name is freed when the last reference goes");
	return;
}

# /dev/full fails every write with ENOSPC, exactly like a full disk, and
# without the extra warnings Perl adds for misused handles.  Linux and
# some BSDs have it; tests that need it skip elsewhere.
Readonly my $FULL_DEVICE => '/dev/full';
sub open_full {
	return unless(-c $FULL_DEVICE && -w _);
	open(my $fh, '>>', $FULL_DEVICE) or return;
	return $fh;
}

# A socket double: hands out queued datagrams, records what it was asked
{
	package FakeSocket;
	sub new {
		my ($class, %args) = @_;
		return bless { queue => $args{queue} || [], calls => [], closed => 0, %args }, $class;
	}
	sub recv {
		my $self = $_[0];
		push @{$self->{calls}}, $_[2];	# the buffer length asked for
		my $next = shift @{$self->{queue}};
		if(!defined($next)) {
			$! = $self->{errno} // Errno::EINTR();
			return undef;
		}
		$_[1] = $next;
		return $self->{peer};
	}
	sub sockport { return $_[0]{port} }
	sub sockhost { return $_[0]{host} }
	sub close { $_[0]{closed}++; return 1 }
}

# A socket double with no sockport/sockhost, like a minimal injected one
{
	package BareSocket;
	sub new { return bless {}, shift }
	sub recv { return undef }
	sub close { return 1 }
}

# A cache double: records compute() calls and runs the code it is given
{
	package FakeCache;
	sub new { return bless { calls => [] }, shift }
	sub compute {
		my ($self, $key, $ttl, $code) = @_;
		push @{$self->{calls}}, [$key, $ttl];
		return $code->();
	}
}

# ===========================================================================
# 1. lib/App/Syslogd.pm
# ===========================================================================

subtest 'App::Syslogd::new' => sub {
	# Purpose: new() validates, applies defaults, and wires up the
	# language handle, the DNS cache and the CSV writer.  Strategy: mock
	# all three collaborators so we see exactly how they are built.
	my (@cache_args, @csv_args, @handle_args);
	my $g = mock_scoped(
		'App::Syslogd::Cache::new' => sub { shift; push @cache_args, {@_}; return FakeCache->new() },
		'Text::CSV::new' => sub { shift; push @csv_args, @_; return bless {}, 'FakeCSV' },
		'App::Syslogd::I18N::handle' => sub { shift; push @handle_args, [@_]; return 'LANGUAGE HANDLE' },
	);

	my $server = keeps_globals(sub { App::Syslogd->new() }, 'new()');
	returns_ok($server, $SCHEMA{server}, 'returns an App::Syslogd');
	verbose_diag(explain({ %{$server}, cache => ref($server->{cache}), csv => ref($server->{csv}) }));

	is($server->{port}, $CONFIG{default_port}, 'default port');
	is($server->{address}, $CONFIG{default_address}, 'default address');
	is($server->{file}, $CONFIG{default_file}, 'default file');
	is($server->{resolve}, 1, 'resolves host names by default');
	is($server->{dns_ttl}, $CONFIG{default_dns_ttl}, 'default DNS TTL');
	is($server->{count}, 0, 'count starts at 0');
	ok(!$server->{socket} && !$server->{fh}, 'nothing opened yet');

	is($server->{lh}, 'LANGUAGE HANDLE', 'language handle stored');
	is_deeply(\@handle_args, [[undef]], 'language taken from the environment when none given');
	is_deeply(\@cache_args, [{ max_bytes => $CONFIG{default_dns_cache_bytes} }],
		'built-in DNS cache sized by dns_cache_bytes');
	is_deeply(\@csv_args, [$CONFIG{csv_options}], 'CSV writer: binary, newline, always quoted');

	# Both calling conventions, and options overriding defaults
	@cache_args = @handle_args = ();
	my $custom = App::Syslogd->new({ port => 5514, language => 'de', dns_cache_bytes => 1024 });
	is($custom->{port}, 5514, 'hashref form accepted');
	is_deeply(\@handle_args, [['de']], 'requested language passed to the handle');
	is($cache_args[0]{max_bytes}, 1024, 'dns_cache_bytes honoured');

	# A supplied cache means no built-in cache is made
	@cache_args = ();
	my $cache = FakeCache->new();
	is(App::Syslogd->new(cache => $cache)->{cache}, $cache, 'supplied cache used');
	is(scalar(@cache_args), 0, 'no built-in cache made when one is supplied');

	# undef means "use the default", never "set to undef"
	my $undef = App::Syslogd->new(port => undef, file => undef, address => undef, resolve => undef, language => undef);
	is($undef->{port}, $CONFIG{default_port}, 'port => undef gives the default');
	is($undef->{file}, $CONFIG{default_file}, 'file => undef gives the default');
	is($undef->{address}, $CONFIG{default_address}, 'address => undef gives the default');
	is($undef->{resolve}, 1, 'resolve => undef gives the default');

	# Boolean words are accepted for resolve
	is(App::Syslogd->new(resolve => 'off')->{resolve}, 0, "resolve => 'off' is false");
	is(App::Syslogd->new(resolve => 'yes')->{resolve}, 1, "resolve => 'yes' is true");

	# A one-level merge: objects are shared, not copied
	my $socket = BareSocket->new();
	is(App::Syslogd->new(socket => $socket)->{socket}, $socket, 'supplied socket is the same object');
};

subtest 'App::Syslogd::new - rejected arguments' => sub {
	# Purpose: every invalid argument dies, naming the parameter.  The
	# validator's own message carries its internal line number, so match
	# the part that is the documented contract.
	my %bad = (
		'unknown parameter' => [{ prot => 514 }, qr/validate_strict: Unknown parameter 'prot'/],
		'port too big' => [{ port => 65_536 }, qr/validate_strict: Parameter 'port' \(65536\) must be no more than 65535/],
		'negative port' => [{ port => -1 }, qr/validate_strict: Parameter 'port' \(-1\) must be at least 0/],
		'port not an integer' => [{ port => '514abc' }, qr/validate_strict: Parameter 'port' \(514abc\) must be an integer/],
		'empty file name' => [{ file => '' }, qr/validate_strict: Parameter 'file'/],
		'resolve not boolean' => [{ resolve => 2 }, qr/validate_strict: Parameter 'resolve' \(2\) must be a boolean/],
		'cache without compute' => [{ cache => BareSocket->new() }, qr/validate_strict: Parameter 'cache'/],
		'socket not an object' => [{ socket => 'eth0' }, qr/validate_strict: Parameter 'socket'/],
	);
	foreach my $case (sort keys %bad) {
		my ($args, $error) = @{$bad{$case}};
		throws_ok { App::Syslogd->new($args) } $error, $case;
	}
};

subtest 'App::Syslogd::new - memory' => sub {
	# Purpose: a server object must not keep itself alive through a cycle
	freed_ok(sub { App::Syslogd->new() }, 'a new server');
};

subtest 'App::Syslogd::open_socket' => sub {
	# Purpose: binds with the configured address and port, keeps an
	# existing socket, and reports failure with the documented message.
	my @ctor_args;
	my $result_socket = FakeSocket->new();
	my $g = mock_scoped('IO::Socket::IP::new' => sub { shift; push @ctor_args, {@_}; return $result_socket });

	my $server = App::Syslogd->new(port => 5514, address => '::1');
	returns_ok(keeps_globals(sub { $server->open_socket() }, 'open_socket()'), $SCHEMA{server}, 'returns $self');
	is_deeply(\@ctor_args, [{ LocalHost => '::1', LocalPort => 5514, Proto => 'udp' }], 'UDP socket on the configured address');
	is($server->{socket}, $result_socket, 'socket stored');

	# Already bound: no second socket
	$server->open_socket();
	is(scalar(@ctor_args), 1, 'a second call does not bind again');

	# An injected socket is never replaced
	@ctor_args = ();
	my $injected = BareSocket->new();
	is(App::Syslogd->new(socket => $injected)->open_socket()->{socket}, $injected, 'injected socket kept');
	is(scalar(@ctor_args), 0, 'no socket created when one was injected');
};

subtest 'App::Syslogd::open_socket - failure' => sub {
	# Purpose: the error names the address and port and carries the
	# system's reason, and nothing is stored
	my $g = mock_scoped('IO::Socket::IP::new' => sub { $IO::Socket::errstr = 'Address already in use'; return undef });

	my $server = App::Syslogd->new(port => 5514, address => '127.0.0.1');
	throws_ok { $server->open_socket() }
		exact('Could not create a UDP socket on 127.0.0.1 port 5514: Address already in use'), 'exact error';
	ok(!$server->{socket}, 'no socket stored after a failure');
};

subtest 'App::Syslogd::port' => sub {
	# Purpose: configured port before binding, the real one after; an
	# injected socket that cannot say falls back to the configured value
	my $server = App::Syslogd->new(port => 0);
	returns_ok(keeps_globals(sub { $server->port() }, 'port()'), $SCHEMA{port}, 'integer in range');
	is($server->port(), 0, 'configured port before binding');

	$server->{socket} = FakeSocket->new(port => 40_000);
	is($server->port(), 40_000, 'the bound port after binding');

	is(App::Syslogd->new(port => 5514, socket => BareSocket->new())->port(), 5514,
		'socket without sockport(): configured port');
};

subtest 'App::Syslogd::address' => sub {
	# Purpose: as port(), for the address
	my $server = App::Syslogd->new(address => '::');
	returns_ok(keeps_globals(sub { $server->address() }, 'address()'), $SCHEMA{address}, 'non-empty string');
	is($server->address(), '::', 'configured address before binding');

	$server->{socket} = FakeSocket->new(host => '::1');
	is($server->address(), '::1', 'the bound address after binding');

	is(App::Syslogd->new(address => '10.0.0.1', socket => BareSocket->new())->address(), '10.0.0.1',
		'socket without sockhost(): configured address');
};

subtest 'App::Syslogd::count' => sub {
	# Purpose: count() reports the counter and never changes it
	my $server = App::Syslogd->new();
	returns_ok(keeps_globals(sub { $server->count() }, 'count()'), $SCHEMA{count}, 'non-negative integer');
	$server->{count} = 7;
	is($server->count(), 7, 'reports the counter');
	is($server->count(), 7, 'reading does not change it');
};

subtest 'App::Syslogd::reopen_log' => sub {
	# Purpose: closes first, then opens, and stores the new handle.
	# Strategy: mock both helpers and record the order they ran in.
	my @order;
	my $g = mock_scoped(
		'App::Syslogd::_close_log' => sub { push @order, 'close'; delete $_[0]{fh}; return $_[0] },
		'App::Syslogd::_open_log' => sub { push @order, 'open'; return 'NEW HANDLE' },
	);

	my $server = App::Syslogd->new();
	$server->{fh} = 'OLD HANDLE';
	returns_ok(keeps_globals(sub { $server->reopen_log() }, 'reopen_log()'), $SCHEMA{server}, 'returns $self');
	is_deeply(\@order, ['close', 'open'], 'closes the old log before opening the new one');
	is($server->{fh}, 'NEW HANDLE', 'new handle stored');
};

subtest 'App::Syslogd::reopen_log - failure' => sub {
	# Purpose: when opening fails the error passes through and no stale
	# handle is left behind to keep writing to a rotated file
	my $g = mock_scoped('App::Syslogd::_open_log' => sub { Carp::croak('open failed') });

	my $server = App::Syslogd->new(file => new_log());
	open(my $old, '>', \my $buffer) or die;
	$server->{fh} = $old;
	throws_ok { $server->reopen_log() } qr/\Aopen failed at /, 'the open error is passed on';
	ok(!$server->{fh}, 'no handle left after a failed reopen');
};

subtest 'App::Syslogd::parse_message - valid PRI' => sub {
	# Purpose: PRI split into facility and severity at every boundary
	my %cases = (
		'<0>a' => [0, 0, 'a'],		# smallest PRI
		'<7>a' => [0, 7, 'a'],		# last severity of facility 0
		'<8>a' => [1, 0, 'a'],		# first severity of facility 1
		'<34>su' => [4, 2, 'su'],	# the RFC 3164 example
		'<191>a' => [23, 7, 'a'],	# largest PRI
		'<13>' => [1, 5, ''],		# PRI only: an empty message
	);
	foreach my $datagram (sort keys %cases) {
		my ($facility, $severity, $message) = @{$cases{$datagram}};
		my $record = keeps_globals(sub { App::Syslogd->parse_message($datagram) }, "parse_message('$datagram')");
		returns_ok($record, $SCHEMA{record}, "'$datagram' matches the record schema");
		is_deeply($record, { facility => $facility, severity => $severity, message => $message, valid => 1 }, "'$datagram'");
	}
};

subtest 'App::Syslogd::parse_message - invalid PRI' => sub {
	# Purpose: anything that is not a canonical PRI of 0-191 is kept whole
	# as user.notice, as RFC 3164 4.3.3 requires
	foreach my $datagram ('no pri', '<192>x', '<013>x', '<00>x', '<1000>x', '<>x', '<-1>x', '<1a>x', ' <13>x', '13>x') {
		my $record = App::Syslogd->parse_message($datagram);
		returns_ok($record, $SCHEMA{record}, "'$datagram' matches the record schema");
		is_deeply($record, {
			facility => $CONFIG{default_pri_facility},
			severity => $CONFIG{default_pri_severity},
			message => $datagram,
			valid => 0,
		}, "'$datagram' becomes user.notice with the whole text");
	}
};

subtest 'App::Syslogd::parse_message - length and terminators' => sub {
	# Purpose: trailing CR, LF and NUL are removed before the length test;
	# fewer than two characters left means "not a message"
	foreach my $datagram (undef, '', 'x', "x\n", "x\r\n", "x\0", "\n\n", "\r\n\0") {
		my $shown = defined($datagram) ? join('', map { sprintf('\\x%02X', ord) } split //, $datagram) : 'undef';
		is(App::Syslogd->parse_message($datagram), undef, "'$shown' is too short");
	}
	is(App::Syslogd->parse_message("<13>end\r\n\0\n")->{message}, 'end', 'every trailing terminator removed');
	is(App::Syslogd->parse_message("<13>\nmid")->{message}, '\x0Amid', 'only trailing ones: a leading newline is escaped');
	is(App::Syslogd->parse_message('xy')->{message}, 'xy', 'two characters is enough');
};

subtest 'App::Syslogd::parse_message - escaping is delegated' => sub {
	# Purpose: the body (and only the body) goes through _escape_controls.
	# Strategy: mock the helper so we see exactly what it receives.
	my @seen;
	my $g = mock_scoped('App::Syslogd::_escape_controls' => sub { push @seen, $_[0]; return 'ESCAPED' });

	is(App::Syslogd->parse_message('<13>body')->{message}, 'ESCAPED', 'helper result used as the message');
	is(App::Syslogd->parse_message('no pri')->{message}, 'ESCAPED', 'also for an invalid PRI');
	is_deeply(\@seen, ['body', 'no pri'], 'the PRI is not passed to the helper');
};

subtest 'App::Syslogd::process' => sub {
	# Purpose: a record is written as [host, facility, severity, message]
	# and counted; a too-short datagram is neither written nor counted.
	# Strategy: mock parse_message, _peer_name and _write_row.
	my (@rows, @peers);
	my $g = mock_scoped(
		'App::Syslogd::parse_message' => sub { return $_[1] eq 'short' ? undef : { facility => 3, severity => 4, message => "M:$_[1]", valid => 1 } },
		'App::Syslogd::_peer_name' => sub { push @peers, $_[1]; return 'HOST' },
		'App::Syslogd::_write_row' => sub { push @rows, $_[1]; return $_[0] },
	);

	my $server = App::Syslogd->new();
	$server->{fh} = 'OPEN';
	returns_ok(keeps_globals(sub { $server->process('data', $PEER) }, 'process()'), $SCHEMA{server}, 'returns $self');
	is_deeply(\@rows, [['HOST', 3, 4, 'M:data']], 'one row in column order');
	is_deeply(\@peers, [$PEER], 'the sender is looked up');
	is($server->count(), 1, 'counted');

	$server->process('short', $PEER);
	is(scalar(@rows), 1, 'a too-short datagram writes nothing');
	is(scalar(@peers), 1, '...and does not look up the sender');
	is($server->count(), 1, '...and is not counted');

	$server->process('again', undef);
	is_deeply($peers[-1], undef, 'an undef sender is passed on, not rejected');
	is($server->count(), 2, 'counted');
};

subtest 'App::Syslogd::process - no log open' => sub {
	# Purpose: calling process() before reopen_log() is a programming
	# error and must say so exactly
	throws_ok { App::Syslogd->new()->process('<13>x', $PEER) }
		exact('process() was called before reopen_log() succeeded'), 'exact error';
};

subtest 'App::Syslogd::run - start-up and loop' => sub {
	# Purpose: run() opens what is missing, processes each datagram,
	# stops on request, shuts down, and returns $self.  Strategy: mock
	# every method it calls, and drive the loop with a scripted _receive.
	my (@calls, @script);
	my $server;
	my $g = mock_scoped(
		'App::Syslogd::open_socket' => sub { push @calls, 'open_socket'; $_[0]{socket} = 'S'; return $_[0] },
		'App::Syslogd::reopen_log' => sub { push @calls, 'reopen_log'; $_[0]{fh} = 'F'; return $_[0] },
		'App::Syslogd::_receive' => sub {
			my ($self, $buffer) = @_;
			my $step = shift(@script);
			return $step->($buffer);
		},
		'App::Syslogd::process' => sub { push @calls, "process:$_[1]"; return $_[0] },
		'App::Syslogd::_shutdown' => sub { push @calls, 'shutdown'; return $_[0] },
	);

	@script = (
		sub { ${$_[0]} = 'one'; return $PEER },
		sub { return undef },		# interrupted or failed: nothing processed
		sub { ${$_[0]} = 'two'; return $PEER },
		sub { $server->stop(); return undef },
	);
	$server = App::Syslogd->new();
	returns_ok(keeps_globals(sub { $server->run() }, 'run()'), $SCHEMA{server}, 'returns $self');
	verbose_diag(explain(\@calls));
	is_deeply(\@calls, ['open_socket', 'reopen_log', 'process:one', 'process:two', 'shutdown'],
		'opens, processes each datagram, then shuts down');
	ok(!$server->{running}, 'not running after it returns');

	# Already open: run() does not reopen the log.  It still calls
	# open_socket(), which does nothing when a socket is open (that is
	# proved against the real open_socket() in t/logic.t)
	@calls = ();
	@script = (sub { $server->stop(); return undef });
	$server->{socket} = 'S';
	$server->{fh} = 'F';
	$server->run();
	is_deeply(\@calls, ['open_socket', 'shutdown'], 'the log is not reopened when it is open');
};

subtest 'App::Syslogd::run - signals' => sub {
	# Purpose: HUP asks for a reopen at the top of the loop; TERM and INT
	# stop; the caller's handlers come back afterwards.  Strategy: call
	# the handlers run() installed, which is portable (no real signals).
	my (@calls, @script);
	my $server;
	my $g = mock_scoped(
		'App::Syslogd::reopen_log' => sub { push @calls, 'reopen_log'; $_[0]{fh} = 'F'; return $_[0] },
		'App::Syslogd::_receive' => sub { my $step = shift(@script); return $step->() },
		'App::Syslogd::_shutdown' => sub { push @calls, 'shutdown'; return $_[0] },
	);

	my $outer_hup = sub { 'caller HUP' };
	my $outer_term = sub { 'caller TERM' };
	local $SIG{HUP} = $outer_hup;
	local $SIG{TERM} = $outer_term;

	foreach my $stop_signal ('TERM', 'INT') {
		@calls = ();
		@script = (
			sub { $SIG{HUP}->('HUP'); return undef },
			sub { $SIG{$stop_signal}->($stop_signal); return undef },
			sub { push @calls, 'read after stop'; return undef },
		);
		$server = App::Syslogd->new(socket => BareSocket->new());
		$server->{fh} = 'F';
		$server->run();
		is_deeply(\@calls, ['reopen_log', 'shutdown'], "HUP reopens once; $stop_signal stops before the next read");
		ok(!$server->{reopen_requested}, 'the reopen request is cleared');
	}

	is($SIG{HUP}, $outer_hup, "the caller's HUP handler is restored");
	is($SIG{TERM}, $outer_term, "the caller's TERM handler is restored");
};

subtest 'App::Syslogd::run - a failed reopen' => sub {
	# Purpose: if SIGHUP's reopen fails, run() dies with that error, the
	# caller's handlers come back, and the object is not left "running"
	my $g = mock_scoped(
		'App::Syslogd::reopen_log' => sub { Carp::croak('reopen failed') },
		'App::Syslogd::_receive' => sub { $SIG{HUP}->('HUP'); return undef },
		'App::Syslogd::_shutdown' => sub { fail('_shutdown must not run after a failure'); return $_[0] },
	);

	my $outer = sub { 'caller HUP' };
	local $SIG{HUP} = $outer;
	my $server = App::Syslogd->new(socket => BareSocket->new());
	$server->{fh} = 'F';

	throws_ok { $server->run() } qr/\Areopen failed at /, 'the reopen error is passed on';
	is($SIG{HUP}, $outer, "the caller's HUP handler is restored");
	ok(!$server->{running}, 'the object is not left marked as running');
};

subtest 'App::Syslogd::run - memory' => sub {
	# Purpose: the signal handlers close over $self; after run() returns
	# they are gone, so the object must still be freeable
	my $g = mock_scoped('App::Syslogd::_receive' => sub {
		my ($self, $buffer) = @_;
		my $peer = $self->{socket}->recv(${$buffer}, $CONFIG{recv_buffer});
		$self->stop() unless(defined($peer));
		return $peer;
	});
	freed_ok(sub {
		my $server = App::Syslogd->new(file => new_log(), resolve => 0,
			socket => FakeSocket->new(queue => ['<13>x'], peer => $PEER));
		return $server->run();
	}, 'a server after run()');
};

subtest 'App::Syslogd::stop' => sub {
	# Purpose: stop() clears the running flag and nothing else
	my $server = App::Syslogd->new();
	@{$server}{qw(running socket fh count)} = (1, 'S', 'F', 3);
	returns_ok(keeps_globals(sub { $server->stop() }, 'stop()'), $SCHEMA{server}, 'returns $self');
	ok(!$server->{running}, 'running flag cleared');
	is_deeply([@{$server}{qw(socket fh count)}], ['S', 'F', 3], 'socket, log and count untouched');
};

subtest 'App::Syslogd::i18n' => sub {
	# Purpose: an object uses its own handle; the class uses a fresh one
	# from the environment.  Strategy: mock the catalogue.
	my (@text_calls, @handle_calls);
	my $g = mock_scoped(
		'App::Syslogd::I18N::text' => sub { push @text_calls, [@_]; return 'RENDERED' },
		'App::Syslogd::I18N::handle' => sub { push @handle_calls, [@_[1 .. $#_]]; return bless {}, 'App::Syslogd::I18N' },
	);

	my $server = App::Syslogd->new();
	my $own_handle = $server->{lh};
	@handle_calls = ();

	my $args = { port => 1 };
	returns_ok(keeps_globals(sub { $server->i18n('listening', $args) }, 'i18n()'), $SCHEMA{string}, 'returns a string');
	is($text_calls[0][0], $own_handle, "object call uses the object's handle");
	is_deeply([@{$text_calls[0]}[1, 2]], ['listening', $args], 'key and values passed through');
	is(scalar(@handle_calls), 0, 'no new handle for an object call');

	is(App::Syslogd->i18n('usage'), 'RENDERED', 'class call works');
	is_deeply(\@handle_calls, [[]], 'class call takes the language from the environment');
};

subtest 'App::Syslogd::_receive' => sub {
	# Purpose: reads with the full UDP buffer size, fills the caller's
	# buffer, and returns the sender
	my $server = App::Syslogd->new(socket => FakeSocket->new(queue => ['payload'], peer => $PEER));

	my $buffer;
	my $peer = keeps_globals(sub { $server->_receive(\$buffer) }, '_receive()');
	is($peer, $PEER, 'returns the sender');
	is($buffer, 'payload', "fills the caller's buffer");
	is_deeply($server->{socket}{calls}, [$CONFIG{recv_buffer}], 'asks for the largest UDP payload');
};

subtest 'App::Syslogd::_receive - interruptions and errors' => sub {
	# Purpose: EINTR is how signals wake the loop, so it is silent; any
	# other error is a warning with the system's reason
	my $interrupted = App::Syslogd->new(socket => FakeSocket->new(errno => EINTR));
	my $peer;
	warnings_are { $peer = $interrupted->_receive(\my $b) } [], 'EINTR is silent';
	is($peer, undef, '...and returns undef');

	my $failing = App::Syslogd->new(socket => FakeSocket->new(errno => EBADF));
	warning_like { $peer = $failing->_receive(\my $b) }
		exact('Error receiving a datagram: ' . errno_text(EBADF)), 'other errors warn exactly';
	is($peer, undef, '...and return undef');

	# No "no socket" case: run() guarantees the socket exists (see the
	# premises above _receive), so calling it without one breaks its entry
	# condition rather than testing a documented state.
};

subtest 'App::Syslogd::_open_log' => sub {
	# Purpose: creates a private, append-mode file and asks
	# for the header only when the file is empty.  Strategy: real files
	# (open and stat are builtins) with _write_header mocked.
	my @headers;
	my $g = mock_scoped('App::Syslogd::_write_header' => sub { push @headers, $_[1]; return $_[0] });

	my $file = new_log();
	my $server = App::Syslogd->new(file => $file);
	my $fh = keeps_globals(sub { $server->_open_log() }, '_open_log()');
	ok(defined(fileno($fh)), 'returns an open handle');
	ok(-f $file, 'file created');
	is(scalar(@headers), 1, 'header requested for a new, empty file');
	is($headers[0], $fh, '...on the new handle');
	SKIP: {
		skip('no Unix permission bits on Windows', 1) if($^O eq 'MSWin32');
		is((stat $file)[2] & 07777, $CONFIG{log_mode}, 'mode 0600');
	}

	# Append mode: earlier content survives (the file starts with the
	# header, as every log does; anything else is refused, tested below)
	print {$fh} join(',', map { qq{"$_"} } qw(Host facility severity msg)) . "\nexisting\n";
	close($fh);
	my $again = $server->_open_log();
	print {$again} "appended\n";
	close($again);
	is_deeply([@{lines_of($file)}[1, 2]], ['existing', 'appended'], 'appends rather than truncating');
	is(scalar(@headers), 1, 'no header requested for a file that has content');
};

subtest 'App::Syslogd::_open_log - failures' => sub {
	# Purpose: each refusal has its exact documented message
	my $missing = "$dir/no/such/dir/x.csv";
	throws_ok { App::Syslogd->new(file => $missing)->_open_log() }
		exact("Could not open log file $missing: " . errno_text(ENOENT)), 'missing directory: exact error';

	SKIP: {
		my $target = new_log();
		open(my $fh, '>', $target) or die;
		close($fh);
		my $hard = new_log();
		skip("cannot create a hard link: $!", 1) unless(eval { link($target, $hard) });
		skip('this system does not report link counts', 1) unless((stat $hard)[3] == 2);
		throws_ok { App::Syslogd->new(file => $hard)->_open_log() }
			exact("Refusing to log to $hard: it must be a regular file, owned by this user, with exactly one link"),
			'hard link: exact error';
	}
};

subtest 'App::Syslogd::_starts_with_header' => sub {
	# Purpose: recognises one of our logs by its first line (LF or CRLF)
	# and nothing else
	my $server = App::Syslogd->new();
	my $header = join(',', map { qq{"$_"} } qw(Host facility severity msg));
	my %cases = ("$header\n" => 1, "$header\r\nrow\n" => 1, "$header" => 0, "x$header\n" => 0, "\n" => 0);
	foreach my $content (sort keys %cases) {
		my $file = new_log();
		open(my $out, '>:raw', $file) or die;
		print {$out} $content;
		close($out);
		open(my $in, '<', $file) or die;
		(my $shown = $content) =~ s/\r/\\r/g;
		$shown =~ s/\n/\\n/g;
		is(keeps_globals(sub { $server->_starts_with_header($in) }, '_starts_with_header()'), $cases{$content}, "'$shown'");
		close($in);
	}
};

subtest 'App::Syslogd::_write_header' => sub {
	# Purpose: writes exactly one header line; a failed write croaks,
	# because a log that cannot take its first line is useless.
	# Strategy: real files, since the helper writes with syswrite, which
	# in-memory handles do not support; a read-only handle forces failure.
	my $file = new_log();
	my $server = App::Syslogd->new(file => $file);
	open(my $fh, '>>', $file) or die;
	returns_ok(keeps_globals(sub { $server->_write_header($fh) }, '_write_header()'), $SCHEMA{server}, 'returns $self');
	close($fh);
	is_deeply(lines_of($file), [$CONFIG{header}], 'exactly the header line');

	SKIP: {
		my $full = open_full() or skip("$FULL_DEVICE is not available", 2);
		warnings_are {
			throws_ok { $server->_write_header($full) }
				exact("Could not write to log file $file: " . errno_text(ENOSPC)), 'failed write: exact error';
		} [], 'and no other warnings';
	}
};

subtest 'App::Syslogd::_append_line' => sub {
	# Purpose: a whole line is appended and undef returned; on failure
	# the system's error text is returned and nothing is half-written.
	# (A partial write, which needs a full disk, is tested in t/unit.t.)
	my $file = new_log();
	my $server = App::Syslogd->new(file => $file);
	open(my $fh, '>>', $file) or die;
	is(keeps_globals(sub { $server->_append_line($fh, "one\n") }, '_append_line()'), undef, 'success: undef');
	$server->_append_line($fh, "two\n");
	close($fh);
	is_deeply(lines_of($file), ['one', 'two'], 'lines appended in order');

	SKIP: {
		my $full = open_full() or skip("$FULL_DEVICE is not available", 2);
		my $error;
		warnings_are { $error = $server->_append_line($full, "three\n") } [], 'failure is silent: the caller reports it';
		is($error, errno_text(ENOSPC), "failure: the system's error text");
	}
};

subtest 'App::Syslogd::_write_row' => sub {
	# Purpose: one quoted CSV line per row; a failed write warns and
	# returns, because a full disk must not stop the daemon
	my $file = new_log();
	my $server = App::Syslogd->new(file => $file);
	open(my $fh, '>>', $file) or die;
	$server->{fh} = $fh;

	returns_ok(keeps_globals(sub { $server->_write_row(['h', 1, 5, 'say "hi", bye']) }, '_write_row()'),
		$SCHEMA{server}, 'returns $self');
	is_deeply(lines_of($file), ['"h","1","5","say ""hi"", bye"'], 'quoted, quotes doubled, one line');

	SKIP: {
		my $full = open_full() or skip("$FULL_DEVICE is not available", 3);
		$server->{fh} = $full;
		my @warnings;
		{
			local $SIG{__WARN__} = sub { push @warnings, $_[0] };
			lives_ok { $server->_write_row(['h']) } 'a failed write does not die';
		}
		verbose_diag(explain(\@warnings));
		is(scalar(@warnings), 1, 'exactly one warning');
		like($warnings[0], exact("Could not write to log file $file: " . errno_text(ENOSPC)), '...with the exact text');
	}
};

subtest 'App::Syslogd::_close_log' => sub {
	# Purpose: closes and forgets the handle; safe to call twice
	my $server = App::Syslogd->new();
	open(my $fh, '>', \my $buffer) or die;
	$server->{fh} = $fh;

	returns_ok(keeps_globals(sub { $server->_close_log() }, '_close_log()'), $SCHEMA{server}, 'returns $self');
	ok(!exists($server->{fh}), 'handle forgotten');
	ok(!defined(fileno($fh)) && !$fh->opened(), 'handle closed');
	lives_ok { $server->_close_log() } 'a second call does nothing';
};

subtest 'App::Syslogd::_shutdown' => sub {
	# Purpose: closes the socket and the log, forgets both
	my $closed_log = 0;
	my $g = mock_scoped('App::Syslogd::_close_log' => sub { $closed_log++; delete $_[0]{fh}; return $_[0] });

	my $socket = FakeSocket->new();
	my $server = App::Syslogd->new(socket => $socket);
	$server->{fh} = 'F';
	returns_ok(keeps_globals(sub { $server->_shutdown() }, '_shutdown()'), $SCHEMA{server}, 'returns $self');
	is($socket->{closed}, 1, 'socket closed once');
	ok(!exists($server->{socket}), 'socket forgotten');
	is($closed_log, 1, 'log closed');

	lives_ok { $server->_shutdown() } 'a second call does nothing';
	is($socket->{closed}, 1, '...and does not close the socket again');
};

subtest 'App::Syslogd::_peer_name' => sub {
	# Purpose: numeric address when not resolving; the cached name when
	# resolving; the address when the name lookup fails.  Strategy: mock
	# getnameinfo (imported into App::Syslogd) and use a recording cache.
	my @lookups;
	my %answer = (numeric => ['', $CONFIG{peer_ip}], name => ['', $CONFIG{peer_name}]);
	my $g = mock_scoped('App::Syslogd::getnameinfo' => sub {
		my ($sockaddr, $flags) = @_;
		my $kind = ($flags & Socket::NI_NUMERICHOST()) ? 'numeric' : 'name';
		push @lookups, $kind;
		return @{$answer{$kind}};
	});

	my $plain = App::Syslogd->new(resolve => 0);
	is(keeps_globals(sub { $plain->_peer_name($PEER) }, '_peer_name()'), $CONFIG{peer_ip}, 'resolve off: the address');
	is_deeply(\@lookups, ['numeric'], '...with no name lookup');

	@lookups = ();
	my $cache = FakeCache->new();
	my $resolving = App::Syslogd->new(cache => $cache, dns_ttl => 60);
	is($resolving->_peer_name($PEER), $CONFIG{peer_name}, 'resolve on: the name');
	is_deeply(\@lookups, ['numeric', 'name'], '...looked up by address, then by name');
	is_deeply($cache->{calls}, [[$CONFIG{peer_ip}, 60]], '...through the cache, keyed by address, with dns_ttl');

	$answer{name} = ['Name or service not known', undef];
	is($resolving->_peer_name($PEER), $CONFIG{peer_ip}, 'failed name lookup: the address');

	$answer{numeric} = ['Address family not supported', undef];
	@lookups = ();
	is($resolving->_peer_name('garbage'), '', 'undecodable sockaddr: empty host');
	is_deeply(\@lookups, ['numeric'], '...and no name lookup is tried');

	@lookups = ();
	is($resolving->_peer_name(undef), '', 'undef sockaddr: empty host');
	is(scalar(@lookups), 0, '...without calling getnameinfo, which dies on undef');
};

subtest 'App::Syslogd::_escape_controls' => sub {
	# Purpose: exactly the C0 controls and DEL become \xNN (upper case);
	# every other byte, including 0x80-0xFF, is unchanged
	foreach my $code (0 .. 255) {
		my $char = chr($code);
		my $want = ($code < 0x20 || $code == 0x7F) ? sprintf('\\x%02X', $code) : $char;
		next if(App::Syslogd::_escape_controls($char) eq $want);
		fail(sprintf('byte 0x%02X', $code));
	}
	pass('every byte 0x00-0xFF handled as specified');

	my $input = "a\tb\nc";
	is(keeps_globals(sub { App::Syslogd::_escape_controls($input) }, '_escape_controls()'), 'a\x09b\x0Ac', 'mixed text');
	is($input, "a\tb\nc", "the caller's string is not modified");
	is(App::Syslogd::_escape_controls(''), '', 'empty string');
};

# ===========================================================================
# 2. lib/App/Syslogd/I18N.pm
# ===========================================================================

subtest 'App::Syslogd::I18N::handle' => sub {
	# Purpose: passes the tag to Locale::Maketext; falls back to English
	# when nothing matches, so it never returns undef.  Strategy: mock
	# get_handle (inherited from Locale::Maketext) in this package.
	my @requests;
	my @replies;
	my $g = mock_scoped('App::Syslogd::I18N::get_handle' => sub { shift; push @requests, [@_]; return shift(@replies) });

	@replies = ('DE HANDLE');
	is(keeps_globals(sub { App::Syslogd::I18N->handle('de') }, 'handle()'), 'DE HANDLE', 'a matching language');
	is_deeply(\@requests, [['de']], '...asked for by tag');

	@requests = ();
	@replies = (undef, 'EN HANDLE');
	is(App::Syslogd::I18N->handle('xx'), 'EN HANDLE', 'no match: English');
	is_deeply(\@requests, [['xx'], ['en']], '...after asking for the tag');

	@requests = ();
	@replies = ('ENV HANDLE');
	App::Syslogd::I18N->handle();
	is_deeply(\@requests, [[]], 'no tag: Locale::Maketext reads the environment');
};

subtest 'App::Syslogd::I18N::handle - real lexicons' => sub {
	# Purpose: end to end through the real Locale::Maketext
	returns_ok(App::Syslogd::I18N->handle('en'), $SCHEMA{handle}, 'English handle');
	isa_ok(App::Syslogd::I18N->handle('xx-nowhere'), 'App::Syslogd::I18N::en', 'unknown language');
	freed_ok(sub { App::Syslogd::I18N->handle('en') }, 'a language handle');
};

subtest 'App::Syslogd::I18N::text' => sub {
	# Purpose: named values are put in the documented slot order, missing
	# ones become ''; unknown keys come back readable instead of dying.
	# Strategy: mock maketext to see exactly what it is given.
	my @calls;
	my $g = mock_scoped('App::Syslogd::I18N::maketext' => sub { shift; push @calls, [@_]; return 'MADE' });
	my $lh = App::Syslogd::I18N->handle('en');

	is(keeps_globals(sub { $lh->text('socket_failed', { error => 'E', port => 'P', address => 'A' }) }, 'text()'),
		'MADE', 'returns what maketext made');
	is_deeply($calls[-1], ['socket_failed', 'A', 'P', 'E'], 'values in slot order, whatever the hash order');

	$lh->text('open_failed', { file => 'F' });
	is_deeply($calls[-1], ['open_failed', 'F', ''], 'a missing value becomes an empty string');

	$lh->text('open_failed');
	is_deeply($calls[-1], ['open_failed', '', ''], 'no values at all');

	$lh->text('no_log_open', { ignored => 1 });
	is_deeply($calls[-1], ['no_log_open'], 'values a key does not use are ignored');

	@calls = ();
	is($lh->text('no_such_key'), 'no_such_key', 'unknown key, no values: the key');
	is($lh->text('no_such_key', { b => 2, a => undef }), 'no_such_key (a=, b=2)', 'unknown key: sorted values');
	is(scalar(@calls), 0, 'unknown keys never reach maketext');
};

subtest 'App::Syslogd::I18N::text - maketext failure' => sub {
	# Purpose: a translation that does not inherit from English dies with
	# Locale::Maketext's message (documented in MESSAGES)
	{
		package App::Syslogd::I18N::x_orphan;
		our @ISA = ('App::Syslogd::I18N');
		our %Lexicon = (listening => 'x');
	}
	throws_ok { App::Syslogd::I18N::x_orphan->new()->text('shutdown', { count => 1 }) }
		qr/maketext doesn't know how to say:\nshutdown\n/, 'documented failure';
};

subtest 'App::Syslogd::I18N::gender' => sub {
	# Purpose: male and female in any case pick their form; anything else,
	# including undef and abbreviations, picks the neutral form
	my $lh = App::Syslogd::I18N->handle('en');
	my %cases = (
		male => 'M', MALE => 'M', Male => 'M',
		female => 'F', FEMALE => 'F', fEmAlE => 'F',
		m => 'N', f => 'N', other => 'N', '' => 'N',
	);
	foreach my $gender (sort keys %cases) {
		is($lh->gender($gender, 'M', 'F', 'N'), $cases{$gender}, "'$gender'");
	}
	is(keeps_globals(sub { $lh->gender(undef, 'M', 'F', 'N') }, 'gender()'), 'N', 'undef');
	returns_ok($lh->gender('male', 'M', 'F', 'N'), $SCHEMA{string}, 'returns a string');
};

# ===========================================================================
# 3. lib/App/Syslogd/I18N/en.pm
# ===========================================================================

subtest 'App::Syslogd::I18N::en - lexicon' => sub {
	# Purpose: the lexicon has exactly the documented keys, and every
	# value a key takes appears in its English text.  Strategy: render
	# each key with values that are easy to spot.
	no warnings 'once';
	is_deeply([sort keys %App::Syslogd::I18N::en::Lexicon], [sort keys %ARGUMENT_ORDER], 'exactly the documented keys');

	my $lh = App::Syslogd::I18N->handle('en');
	foreach my $key (sort keys %ARGUMENT_ORDER) {
		# A number for count, so [quant] has something to count
		my %values = map { $_ => ($_ eq 'count' ? 3 : "<$_>") } @{$ARGUMENT_ORDER{$key}};
		my $text = $lh->text($key, \%values);
		verbose_diag("$key: $text");
		unlike($text, qr/\A\Q$key\E\b/, "$key is rendered from the lexicon");
		like($text, qr/\A[\x20-\x7E]+\z/, "$key is printable ASCII");
		foreach my $name (@{$ARGUMENT_ORDER{$key}}) {
			my $shown = $values{$name};
			like($text, qr/\Q$shown\E/, "$key shows $name");
		}
	}
};

done_testing();
