#!/usr/bin/env perl

# Black-box unit tests: every public function, tested only through its
# documented API (the POD), never through its internals.
#
# Strategy
#	* Only things outside the module are mocked (Test::Mockingbird): the
#	  socket constructor, the resolver (Socket's getnameinfo) and
#	  Locale::Maketext's language lookup.  Sockets, caches and languages
#	  are otherwise supplied through the documented arguments of new().
#	* Write failures that need a full disk are produced for real, in a
#	  child process with a file-size limit (Unix only).
#	* Every documented message and return state is listed in a ledger
#	  below.  Each test crosses off what it proves; the last subtest fails
#	  for anything left over, so nothing documented goes untested.
#	* Every call is checked for leaving the caller's $_, $!, $@ and a
#	  running alarm() alone, as the POD promises.
#
# Files are processed one at a time, in this order:
#	1. lib/App/Syslogd.pm
#	2. lib/App/Syslogd/I18N.pm
#	(lib/App/Syslogd/I18N/en.pm has no functions: it is a lexicon, and is
#	tested through App::Syslogd::i18n() and App::Syslogd::I18N::text())

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Errno qw(EINTR EBADF EPERM ENOENT);
use File::Spec;
use File::Temp qw(tempdir);
use Readonly;
use Scalar::Util ();
use Socket qw(pack_sockaddr_in inet_aton);
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

use App::Syslogd;
use App::Syslogd::I18N;

Readonly my %CONFIG => (
	peer_ip => '192.0.2.1',			# RFC 5737 TEST-NET-1: never resolves
	peer_port => 514,
	peer_name => 'sender.example.com',	# RFC 2606 reserved name
	default_port => 514,
	default_address => '0.0.0.0',
	unprivileged_port => 5514,
	bound_port => 40_000,
	header => '"Host","facility","severity","msg"',
	alarm_seconds => 1000,			# long enough never to fire
	alarm_slack => 5,			# seconds a test may take
	sentinel_underscore => 'caller value of $_',
	sentinel_eval_error => 'caller value of $@',
	sentinel_errno => EPERM,
	no_bytes => 0,				# ulimit -f 0: nothing can be written
	one_block => 1,				# ulimit -f 1: 512 or 1024 bytes
	oversized_message => 'x' x 4096,	# longer than that limit
	usage_text => 'Usage: syslogd [--port <port_number>] [--address <address>] [--file <CSV file>] [--no-resolve] [--language <tag>]',
);

# Output schemas from the POD's API SPECIFICATION sections
Readonly my %SCHEMA => (
	server => { type => 'object', isa => 'App::Syslogd' },
	port => { type => 'integer', min => 0, max => 65_535 },
	address => { type => 'string', min => 1 },
	count => { type => 'integer', min => 0 },
	string => { type => 'string' },
	handle => { type => 'object', isa => 'App::Syslogd::I18N' },
	record => {
		type => 'hashref',
		schema => {
			facility => { type => 'integer', min => 0, max => 23 },
			severity => { type => 'integer', min => 0, max => 7 },
			message => { type => 'string', matches => qr/\A[^\x00-\x1F\x7F]*\z/ },
			valid => { type => 'boolean' },
		},
	},
);

# The ledger: every message (MESSAGES sections and the i18n key table) and
# every return state the POD documents.  Tests delete what they prove.
my %ledger = map { $_ => 1 } (
	# App::Syslogd::new
	'new: returns an object',
	'new: undef means the default',
	'new: message Unknown parameter',
	'new: message must be an integer',
	'new: message out of range',
	'new: message must be a boolean',
	'new: settings from the environment',
	'new: the environment wins over arguments',
	'new: configured settings are validated',
	'new: holds a logger',
	# App::Syslogd::open_socket
	'open_socket: returns $self',
	'open_socket: does nothing when a socket is open',
	'open_socket: message Could not create a UDP socket',
	# App::Syslogd::port and address
	'port: configured before open_socket',
	'port: real port after open_socket',
	'port: configured when the socket has no sockport',
	'address: configured before open_socket',
	'address: real address after open_socket',
	'address: configured when the socket has no sockhost',
	# App::Syslogd::count
	'count: datagrams written',
	'count: failed writes are counted',
	# App::Syslogd::reopen_log
	'reopen_log: returns $self',
	'reopen_log: header only on an empty file',
	'reopen_log: existing file made 0600',
	'reopen_log: message Could not open log file',
	'reopen_log: message Refusing to log to',
	'reopen_log: message not the syslog header',
	'reopen_log: message Could not write (header)',
	'reopen_log: no log left open after a failure',
	# App::Syslogd::parse_message
	'parse_message: undef when too short',
	'parse_message: record with a valid PRI',
	'parse_message: user.notice for an invalid PRI',
	'parse_message: control characters escaped',
	# App::Syslogd::process
	'process: returns $self',
	'process: one line per datagram',
	'process: host name when resolving',
	'process: address when not resolving',
	'process: address when the name is not found',
	'process: short datagram ignored',
	'process: undef sender gives an empty host',
	'process: message process() was called before reopen_log()',
	'process: message Could not write (row)',
	'process: half line removed after a failed write',
	# App::Syslogd::run
	'run: opens socket and log itself',
	'run: returns after stop()',
	'run: returns after SIGTERM',
	'run: returns after SIGINT',
	'run: SIGHUP reopens the log',
	'run: restores the caller signal handlers',
	'run: closes socket and log on return',
	'run: message Error receiving a datagram',
	'run: dies when open_socket fails',
	# App::Syslogd::stop
	'stop: returns $self',
	'stop: before run() has no effect',
	# App::Syslogd::i18n (the key table) and its calling forms
	'i18n: object call',
	'i18n: class call',
	'i18n: unknown key',
	map({ "i18n: key $_" } qw(usage listening shutdown socket_failed open_failed unsafe_file
		write_failed recv_failed no_log_open not_a_datagram missing_key bad_values no_progress not_cgi not_a_log already_running)),
	'parse_message: message A datagram must be a string',
	'process: anything but an address gives an empty host',
	# App::Syslogd::I18N
	'handle: requested language',
	'handle: English fallback',
	'handle: language from the environment',
	'text: values by name',
	'text: missing values are empty',
	'text: unknown key',
	"text: message maketext doesn't know how to say",
	'text: message A message key is needed',
	'text: message Message values must be a hash reference',
	'gender: male form',
	'gender: female form',
	'gender: neutral form',
);

my $PEER = pack_sockaddr_in($CONFIG{peer_port}, inet_aton($CONFIG{peer_ip}));
my $dir = tempdir(CLEANUP => 1);
my $serial = 0;
my $WINDOWS = ($^O eq 'MSWin32');

# Can this Perl say how long a running alarm has left?  On Windows alarm()
# is emulated and alarm(0) always returns 0, so the "alarm still running"
# check cannot be made there; it is skipped rather than failed.
my $ALARM_REPORTS_REMAINING = do {
	local $SIG{ALRM} = sub { };
	alarm($CONFIG{alarm_seconds});
	alarm(0) > 0;
};

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Cross a documented state off the ledger; dying on a typo keeps the
# ledger honest (a misspelt name would otherwise never be crossed off)
sub covered {
	foreach my $state (@_) {
		die "Not in the ledger: '$state'" unless(exists($ledger{$state}));
		delete $ledger{$state};
	}
	return;
}

# Internal state, only when asked
sub verbose_diag { diag(@_) if($ENV{TEST_VERBOSE}); return }

sub new_log { return File::Spec->catfile($dir, 'unit' . ++$serial . '.csv') }

# The text of an errno, from Perl's own $!, as the module embeds it
sub errno_text { my $errno = shift; local $! = $errno; return "$!" }

# croak/carp add " at FILE line N." to a message; match only that suffix
sub exact { my $message = shift; return qr/\A\Q$message\E at \S.* line \d+\.?\n?\z/s }

sub lines_of {
	my $file = shift;
	open(my $fh, '<', $file) or die "$file: $!";
	chomp(my @lines = <$fh>);
	return \@lines;
}

# Run $code with known values in $_, $!, $@ and a running alarm, then
# check the code left all four alone, as the POD promises.  Returns the
# code's result (scalar context).
sub keeps_state {
	my ($code, $name) = @_;

	local $_ = $CONFIG{sentinel_underscore};
	local $@ = $CONFIG{sentinel_eval_error};
	local $SIG{ALRM} = sub { fail("$name: the caller's alarm fired") };
	alarm($CONFIG{alarm_seconds});
	local $! = $CONFIG{sentinel_errno};
	my $result = $code->();
	my $errno = $! + 0;
	my $remaining = alarm(0);

	is($_, $CONFIG{sentinel_underscore}, "$name leaves \$_ alone");
	is($@, $CONFIG{sentinel_eval_error}, "$name leaves \$\@ alone");
	is($errno, $CONFIG{sentinel_errno}, "$name leaves \$! alone");
	SKIP: {
		skip("this Perl's alarm() cannot report the time left", 1) unless($ALARM_REPORTS_REMAINING);
		cmp_ok($remaining, '>=', $CONFIG{alarm_seconds} - $CONFIG{alarm_slack}, "$name leaves the alarm running");
	}
	return $result;
}

# A socket double that serves queued datagrams.  A code ref in the queue
# runs instead (to send a signal, call stop(), ...), and is followed by an
# EINTR return, as when a signal interrupts a real recv().
{
	package QueueSocket;
	sub new {
		my ($class, %args) = @_;
		return bless { queue => [], closed => 0, peer => $PEER, %args }, $class;
	}
	sub recv {
		my $self = $_[0];
		my $next = shift(@{$self->{queue}});
		if(ref($next) eq 'CODE') {
			$next->();
			$! = Errno::EINTR();
			return undef;
		}
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

# A socket double that can only receive, like a minimal injected socket
{
	package MinimalSocket;
	sub new { my ($class, @queue) = @_; return bless { queue => [@queue] }, $class }
	sub recv { return QueueSocket::recv(@_) }
	sub close { return 1 }
}

# A cache double that just runs the lookup, so resolution is not cached
# between tests
{
	package PassThroughCache;
	sub new { return bless {}, shift }
	sub compute { my ($self, $key, $ttl, $code) = @_; return $code->() }
}

# Mock the resolver: numeric lookups give the address, name lookups give
# $name, or fail when $name is undef
sub mock_resolver {
	my $name = shift;
	return mock_scoped('App::Syslogd::getnameinfo' => sub {
		my (undef, $flags) = @_;
		return ('', $CONFIG{peer_ip}) if($flags & Socket::NI_NUMERICHOST());
		return defined($name) ? ('', $name) : ('Name or service not known', undef);
	});
}

# Run the module in a child process whose files may not grow beyond
# $blocks (ulimit -f units), to make writes fail as on a full disk.
# Returns the child's output lines, or undef where this cannot be done.
sub run_size_limited {
	my ($blocks, @script) = @_;

	return if($WINDOWS || !-x '/bin/sh');
	my $script = File::Spec->catfile($dir, 'child' . ++$serial . '.pl');
	open(my $out, '>', $script) or die "$script: $!";
	print {$out} join("\n",
		'use strict;',
		'use warnings;',
		'use App::Syslogd;',
		'use Socket qw(pack_sockaddr_in inet_aton);',
		'$SIG{XFSZ} = "IGNORE";	# fail with EFBIG rather than be killed',
		'$| = 1;',
		'$SIG{__WARN__} = sub { print "WARN: $_[0]" };',
		'my $peer = pack_sockaddr_in(514, inet_aton("192.0.2.1"));',
		@script,
	), "\n";
	close($out) or die "$script: $!";

	# List-form pipe: no shell quoting of the arguments
	open(my $child, '-|', '/bin/sh', '-c', 'ulimit -f "$1" && shift && exec "$@"', 'sh',
		$blocks, $^X, "-I$Bin/../lib", $script) or return;
	my @lines = <$child>;
	close($child);
	verbose_diag("child output:\n", @lines);
	return \@lines;
}

# ===========================================================================
# 1. lib/App/Syslogd.pm
# ===========================================================================

subtest 'new' => sub {
	# Purpose: new() returns an object with the documented defaults, and
	# undef options mean "use the default"
	my $server = keeps_state(sub { App::Syslogd->new() }, 'new()');
	returns_ok($server, $SCHEMA{server}, 'returns an App::Syslogd');
	is($server->port(), $CONFIG{default_port}, 'default port 514');
	is($server->address(), $CONFIG{default_address}, 'default address 0.0.0.0');
	is($server->count(), 0, 'count starts at 0');
	covered('new: returns an object');

	returns_ok(App::Syslogd->new({ port => $CONFIG{unprivileged_port} }), $SCHEMA{server}, 'hashref form');
	is(App::Syslogd->new({ port => $CONFIG{unprivileged_port} })->port(), $CONFIG{unprivileged_port}, 'option honoured');

	my $undef = App::Syslogd->new(port => undef, address => undef, file => undef, resolve => undef, language => undef);
	is($undef->port(), $CONFIG{default_port}, 'port => undef: default');
	is($undef->address(), $CONFIG{default_address}, 'address => undef: default');
	covered('new: undef means the default');
};

subtest 'new - messages' => sub {
	# Purpose: each documented error.  The validator's text carries its own
	# line number, so the documented part is matched.
	throws_ok { App::Syslogd->new(prot => 1) } qr/validate_strict: Unknown parameter 'prot'/, 'Unknown parameter';
	covered('new: message Unknown parameter');

	throws_ok { App::Syslogd->new(port => '5x') } qr/validate_strict: Parameter 'port' \(5x\) must be an integer/, 'not an integer';
	covered('new: message must be an integer');

	throws_ok { App::Syslogd->new(port => 65_536) } qr/validate_strict: Parameter 'port' \(65536\) must be no more than 65535/, 'too big';
	throws_ok { App::Syslogd->new(port => -1) } qr/validate_strict: Parameter 'port' \(-1\) must be at least 0/, 'too small';
	covered('new: message out of range');

	throws_ok { App::Syslogd->new(resolve => 'maybe') } qr/validate_strict: Parameter 'resolve' \(maybe\) must be a boolean/, 'not a boolean';
	covered('new: message must be a boolean');

	# The documented true/false words are accepted
	foreach my $word (qw(1 0 true false yes no on off)) {
		lives_ok { App::Syslogd->new(resolve => $word) } "resolve => '$word' accepted";
	}
};

subtest 'new - settings from Object::Configure' => sub {
	# Purpose: options can also come from App__Syslogd__* environment
	# variables (Object::Configure); those win over the arguments, are
	# checked exactly like arguments, and the object gets a logger
	{
		local $ENV{App__Syslogd__port} = $CONFIG{unprivileged_port};
		is(App::Syslogd->new()->port(), $CONFIG{unprivileged_port}, 'port from the environment');
		covered('new: settings from the environment');
		is(App::Syslogd->new(port => $CONFIG{default_port})->port(), $CONFIG{unprivileged_port},
			'the environment wins over the argument');
		covered('new: the environment wins over arguments');
	}
	is(App::Syslogd->new()->port(), $CONFIG{default_port}, 'the default again once the variable is gone');

	{
		local $ENV{App__Syslogd__port} = 65_536;
		throws_ok { App::Syslogd->new() } qr/validate_strict: Parameter 'port' \(65536\) must be no more than 65535/,
			'an out-of-range port from the environment';
	}
	{
		local $ENV{App__Syslogd__resolve} = 'maybe';
		throws_ok { App::Syslogd->new() } qr/validate_strict: Parameter 'resolve' \(maybe\) must be a boolean/,
			'a non-boolean from the environment';
	}
	covered('new: configured settings are validated');

	my $logger = App::Syslogd->new()->{logger};
	ok(Scalar::Util::blessed($logger) && $logger->can('warn'), 'holds a logger object');
	covered('new: holds a logger');
};

subtest 'open_socket' => sub {
	# Purpose: binds once, returns $self, and reports failure exactly.
	# Strategy: mock the socket constructor (no network).
	my $created = 0;
	my $g = mock_scoped('IO::Socket::IP::new' => sub {
		$created++;
		return QueueSocket->new(port => $CONFIG{bound_port}, host => '127.0.0.1');
	});

	my $server = App::Syslogd->new(port => 0, address => '127.0.0.1');
	is($server->port(), 0, 'port before open_socket: as configured');
	is($server->address(), '127.0.0.1', 'address before open_socket: as configured');
	covered('port: configured before open_socket', 'address: configured before open_socket');

	returns_ok(keeps_state(sub { $server->open_socket() }, 'open_socket()'), $SCHEMA{server}, 'returns $self');
	is($server->open_socket(), $server, 'chains');
	is($created, 1, 'a second call does not bind again');
	covered('open_socket: returns $self', 'open_socket: does nothing when a socket is open');

	returns_ok($server->port(), $SCHEMA{port}, 'port() is an integer in range');
	is($server->port(), $CONFIG{bound_port}, 'port after open_socket: the real one');
	returns_ok($server->address(), $SCHEMA{address}, 'address() is a non-empty string');
	is($server->address(), '127.0.0.1', 'address after open_socket: the real one');
	covered('port: real port after open_socket', 'address: real address after open_socket');

	# A socket given to new() that cannot report its port or address
	my $minimal = App::Syslogd->new(port => 7, address => '10.0.0.7', socket => MinimalSocket->new());
	is($minimal->open_socket()->port(), 7, 'no sockport(): the configured port');
	is($minimal->address(), '10.0.0.7', 'no sockhost(): the configured address');
	is($created, 1, 'a socket given to new() is used, not replaced');
	covered('port: configured when the socket has no sockport', 'address: configured when the socket has no sockhost');
};

subtest 'open_socket - message' => sub {
	# Purpose: the documented failure message, with the system's reason
	my $g = mock_scoped('IO::Socket::IP::new' => sub { $IO::Socket::errstr = 'Address already in use'; return undef });
	throws_ok { App::Syslogd->new(port => $CONFIG{unprivileged_port}, address => '127.0.0.1')->open_socket() }
		exact("Could not create a UDP socket on 127.0.0.1 port $CONFIG{unprivileged_port}: Address already in use"),
		'exact message';
	covered('open_socket: message Could not create a UDP socket');
};

subtest 'reopen_log' => sub {
	# Purpose: creates the file with one header, returns $self, and does
	# not add a second header when reopened
	my $file = new_log();
	my $server = App::Syslogd->new(file => $file);

	returns_ok(keeps_state(sub { $server->reopen_log() }, 'reopen_log()'), $SCHEMA{server}, 'returns $self');
	covered('reopen_log: returns $self');
	is_deeply(lines_of($file), [$CONFIG{header}], 'a new file gets the header');
	$server->reopen_log()->reopen_log();
	is_deeply(lines_of($file), [$CONFIG{header}], 'reopening adds no second header');
	covered('reopen_log: header only on an empty file');

	SKIP: {
		skip('Windows does not use Unix permission bits (see LIMITATIONS)', 2) if($WINDOWS);
		is((stat $file)[2] & 07777, 0600, 'created readable only by its owner');
		chmod(0644, $file);
		$server->reopen_log();
		is((stat $file)[2] & 07777, 0600, 'an existing file is made private');
	}
	covered('reopen_log: existing file made 0600');
};

subtest 'reopen_log - messages' => sub {
	# Purpose: each documented refusal, with its exact text
	my $missing = File::Spec->catfile($dir, 'no', 'such', 'dir', 'log.csv');
	my $server = App::Syslogd->new(file => $missing);
	throws_ok { $server->reopen_log() }
		exact("Could not open log file $missing: " . errno_text(ENOENT)), 'missing directory';
	covered('reopen_log: message Could not open log file');

	# After a failure no log is open, so process() refuses
	throws_ok { $server->process('<13>x', $PEER) } exact('process() was called before reopen_log() succeeded'),
		'no log is open after a failed reopen';
	covered('reopen_log: no log left open after a failure');

	SKIP: {
		my $target = new_log();
		open(my $fh, '>', $target) or die;
		close($fh);
		my $hard = new_log();
		skip("cannot make a hard link here: $!", 1) unless(eval { link($target, $hard) });
		skip('this system does not report link counts', 1) unless((stat $hard)[3] == 2);
		throws_ok { App::Syslogd->new(file => $hard)->reopen_log() }
			exact("Refusing to log to $hard: it must be a regular file, owned by this user, with exactly one link"),
			'hard link refused';
	}
	covered('reopen_log: message Refusing to log to');

	# A file with content that is not one of our logs: refused, untouched
	my $foreign = new_log();
	open(my $out, '>', $foreign) or die;
	print {$out} "not a log\n";
	close($out);
	throws_ok { App::Syslogd->new(file => $foreign)->reopen_log() }
		exact("Refusing to log to $foreign: it is not empty and does not start with the syslog header line"), 'not one of our logs';
	is_deeply(lines_of($foreign), ['not a log'], '...left exactly as it was');
	covered('reopen_log: message not the syslog header');
};

subtest 'reopen_log - header write fails' => sub {
	# Purpose: a new file whose header cannot be written is refused with
	# the documented message and nothing else.  Strategy: a child process
	# that may not write any bytes at all.
	my $file = new_log();
	my $output = run_size_limited($CONFIG{no_bytes},
		"eval { App::Syslogd->new(file => '$file')->reopen_log(); 1 } or print \"DIED: \$\@\";",
	);
	SKIP: {
		skip('needs a Unix shell to limit file sizes', 2) unless($output);
		my @died = grep { /^DIED: / } @{$output};
		like($died[0] // '', qr/\ADIED: \QCould not write to log file $file: File too large\E at /, 'exact message');
		is_deeply([grep { /^WARN: / } @{$output}], [], 'no other warnings');
	}
	covered('reopen_log: message Could not write (header)');
};

subtest 'parse_message' => sub {
	# Purpose: the three documented return states, using the POD's own
	# examples
	my $record = keeps_state(sub { App::Syslogd->parse_message("<34>su: 'su root' failed\n") }, 'parse_message()');
	returns_ok($record, $SCHEMA{record}, 'record schema');
	is_deeply($record, { facility => 4, severity => 2, message => "su: 'su root' failed", valid => 1 }, 'valid PRI');
	is_deeply(App::Syslogd->parse_message('<191>x'), { facility => 23, severity => 7, message => 'x', valid => 1 }, 'largest PRI');
	is_deeply(App::Syslogd->parse_message('<0>x'), { facility => 0, severity => 0, message => 'x', valid => 1 }, 'smallest PRI');
	covered('parse_message: record with a valid PRI');

	foreach my $bad ('no pri', '<192>x', '<013>x') {
		is_deeply(App::Syslogd->parse_message($bad), { facility => 1, severity => 5, message => $bad, valid => 0 },
			"'$bad' is user.notice with the whole text");
	}
	covered('parse_message: user.notice for an invalid PRI');

	is_deeply(App::Syslogd->parse_message("no pri\there"), { facility => 1, severity => 5, message => 'no pri\x09here', valid => 0 },
		'the POD example: a tab is escaped');
	is(App::Syslogd->parse_message("<13>a\nb\x7F")->{message}, 'a\x0Ab\x7F', 'newline and DEL escaped');
	is(App::Syslogd->parse_message("<13>caf\xC3\xA9")->{message}, "caf\xC3\xA9", 'UTF-8 bytes unchanged');
	covered('parse_message: control characters escaped');

	foreach my $short (undef, '', 'x', "x\n", "x\r\n\0") {
		is(App::Syslogd->parse_message($short), undef, 'too short: undef');
	}
	covered('parse_message: undef when too short');

	throws_ok { App::Syslogd->parse_message(['<13>x']) }
		exact('A datagram must be a string (the type given was ARRAY)'), 'a reference is refused';
	covered('parse_message: message A datagram must be a string');
};

subtest 'process' => sub {
	# Purpose: one CSV line per datagram, the host column in each
	# documented form, and short datagrams ignored
	my $file = new_log();
	my $server = App::Syslogd->new(file => $file, cache => PassThroughCache->new())->reopen_log();

	{
		my $g = mock_resolver($CONFIG{peer_name});
		returns_ok(keeps_state(sub { $server->process('<34>said "hi", left', $PEER) }, 'process()'),
			$SCHEMA{server}, 'returns $self');
	}
	covered('process: returns $self');
	{
		my $g = mock_resolver(undef);
		$server->process("<13>two\nlines", $PEER);
	}
	$server->process('<13>no sender', undef);
	$server->process('<13>not an address', [$PEER]);
	$server->process('x', $PEER);

	is_deeply(lines_of($file), [
		$CONFIG{header},
		qq{"$CONFIG{peer_name}","4","2","said ""hi"", left"},
		qq{"$CONFIG{peer_ip}","1","5","two\\x0Alines"},
		'"","1","5","no sender"',
		'"","1","5","not an address"',
	], 'one quoted line per datagram');
	covered('process: one line per datagram', 'process: host name when resolving',
		'process: address when the name is not found', 'process: undef sender gives an empty host',
		'process: short datagram ignored', 'process: anything but an address gives an empty host');
	is($server->count(), 4, 'count: the short one is not counted');
	returns_ok($server->count(), $SCHEMA{count}, 'count() is a non-negative integer');
	covered('count: datagrams written');

	my $plain_file = new_log();
	my $g = mock_resolver($CONFIG{peer_name});
	App::Syslogd->new(file => $plain_file, resolve => 0)->reopen_log()->process('<13>x', $PEER);
	is(lines_of($plain_file)->[1], qq{"$CONFIG{peer_ip}","1","5","x"}, 'resolve => 0: the address');
	covered('process: address when not resolving');
};

subtest 'process - messages' => sub {
	# Purpose: the documented croak, and the documented warning when a
	# line cannot be written (in a size-limited child), after which the
	# file holds no half line and the server carries on
	throws_ok { App::Syslogd->new()->process('<13>x', $PEER) }
		exact('process() was called before reopen_log() succeeded'), 'no log open';
	covered('process: message process() was called before reopen_log()');

	my $file = new_log();
	App::Syslogd->new(file => $file)->reopen_log();	# header, outside the limit
	my $output = run_size_limited($CONFIG{one_block},
		"my \$s = App::Syslogd->new(file => '$file', resolve => 0)->reopen_log();",
		"\$s->process('<13>$CONFIG{oversized_message}', \$peer);",
		'print "COUNT: ", $s->count(), "\n";',
		'eval { $s->reopen_log(); 1 } or print "REOPEN DIED: $@";',
	);
	SKIP: {
		skip('needs a Unix shell to limit file sizes', 5) unless($output);
		my @warnings = grep { /^WARN: / } @{$output};
		is(scalar(@warnings), 1, 'exactly one warning');
		like($warnings[0] // '', qr/\AWARN: \QCould not write to log file $file: File too large\E at /, 'exact message');
		ok((grep { /^COUNT: 1$/ } @{$output}), 'a failed write is still counted');
		is_deeply([grep { /^REOPEN DIED/ } @{$output}], [], 'the log can be reopened after a failed write');
		is_deeply(lines_of($file), [$CONFIG{header}], 'no half line left in the file');
	}
	covered('process: message Could not write (row)', 'count: failed writes are counted',
		'process: half line removed after a failed write');
};

subtest 'run - start, stop and shut down' => sub {
	# Purpose: run() opens what is missing, records datagrams, returns $self
	# after stop(), and closes the socket and the log
	my $file = new_log();
	my $server;
	my $socket = QueueSocket->new(queue => ['<13>one', '<13>two', sub { $server->stop() }]);
	$server = App::Syslogd->new(file => $file, resolve => 0, socket => $socket);

	returns_ok(keeps_state(sub { $server->run() }, 'run()'), $SCHEMA{server}, 'returns $self after stop()');
	covered('run: returns after stop()');
	is_deeply(lines_of($file), [$CONFIG{header}, '"192.0.2.1","1","5","one"', '"192.0.2.1","1","5","two"'],
		'the log was opened and both datagrams written');
	covered('run: opens socket and log itself');
	is($socket->{closed}, 1, 'socket closed on return');
	throws_ok { $server->process('<13>x', $PEER) } exact('process() was called before reopen_log() succeeded'),
		'log closed on return';
	covered('run: closes socket and log on return');

	# run() binds by itself when no socket was given
	my $created = 0;
	my $g = mock_scoped('IO::Socket::IP::new' => sub {
		$created++;
		return QueueSocket->new(queue => [sub { $server->stop() }]);
	});
	$server = App::Syslogd->new(file => new_log(), port => 0);
	$server->run();
	is($created, 1, 'socket opened by run()');
};

subtest 'run - signals' => sub {
	# Purpose: SIGHUP reopens the log; SIGTERM and SIGINT make run()
	# return; the caller's handlers are back afterwards.  Strategy: the
	# socket double sends real signals to this process while run() waits.
	# Windows cannot send these signals to its own process, so there the
	# signal is delivered by calling the handler run() installed for it,
	# which is what Perl does when a signal arrives.
	my $deliver = $WINDOWS
		? sub { my $signal = shift; $SIG{$signal}->($signal) }
		: sub { my $signal = shift; kill($signal, $$) };
	note($WINDOWS ? 'signals delivered by calling the installed handlers' : 'real signals');

	my $outer = sub { fail('the caller handler ran during run()') };
	local $SIG{HUP} = $outer;
	local $SIG{TERM} = $outer;
	local $SIG{INT} = $outer;

	# Windows will not rename a file that is open, so log rotation (rename,
	# then SIGHUP) can only be shown elsewhere.  The reopen itself is shown
	# everywhere by spying on reopen_log() (a spy records the call and
	# lets it run).
	my $can_rotate = !$WINDOWS;

	foreach my $signal ('TERM', 'INT') {
		my $file = new_log();
		my $rotated = "$file.1";
		my $socket = QueueSocket->new(queue => [
			'<13>before',
			sub {
				if($can_rotate) {
					rename($file, $rotated) or die "rename: $!";
				}
				$deliver->('HUP');
			},
			'<13>after',
			sub { $deliver->($signal) },
			'<13>never read',
		]);
		my $server = App::Syslogd->new(file => $file, resolve => 0, socket => $socket);
		my $spy = spy('App::Syslogd::reopen_log');
		$server->run();
		my @reopens = $spy->();
		unmock('App::Syslogd::reopen_log');

		is($server->count(), 2, "returns after SIG$signal, before reading again");
		is(scalar(@reopens), 2, 'SIGHUP: the log is reopened (once at start, once on SIGHUP)');
		if($can_rotate) {
			is_deeply(lines_of($rotated), [$CONFIG{header}, '"192.0.2.1","1","5","before"'], 'SIGHUP: old file keeps its lines');
			is_deeply(lines_of($file), [$CONFIG{header}, '"192.0.2.1","1","5","after"'], 'SIGHUP: a new file is started');
		} else {
			is_deeply(lines_of($file), [$CONFIG{header}, '"192.0.2.1","1","5","before"', '"192.0.2.1","1","5","after"'],
				'SIGHUP: the reopened file carries on, with one header');
		}
	}
	covered('run: returns after SIGTERM', 'run: returns after SIGINT', 'run: SIGHUP reopens the log');

	is($SIG{HUP}, $outer, 'caller HUP handler restored');
	is($SIG{TERM}, $outer, 'caller TERM handler restored');
	is($SIG{INT}, $outer, 'caller INT handler restored');
	covered('run: restores the caller signal handlers');
};

subtest 'run - messages' => sub {
	# Purpose: a receive error other than an interruption is a warning
	# and the loop goes on; a failed start-up dies with open_socket's text
	my $server;
	# The undef entry makes recv() fail with EBADF; the next one stops
	my $socket = QueueSocket->new(errno => EBADF, queue => [undef, sub { $server->stop() }]);
	$server = App::Syslogd->new(file => new_log(), socket => $socket);
	warning_like { $server->run() } exact('Error receiving a datagram: ' . errno_text(EBADF)), 'exact warning';
	covered('run: message Error receiving a datagram');

	my $g = mock_scoped('IO::Socket::IP::new' => sub { $IO::Socket::errstr = 'Permission denied'; return undef });
	throws_ok { App::Syslogd->new(port => $CONFIG{default_port}, file => new_log())->run() }
		exact("Could not create a UDP socket on 0.0.0.0 port $CONFIG{default_port}: Permission denied"), 'start-up failure';
	covered('run: dies when open_socket fails');
};

subtest 'stop' => sub {
	# Purpose: stop() returns $self; before run() it has no effect, because
	# run() sets the running flag itself
	my $server;
	my $socket = QueueSocket->new(queue => ['<13>one', sub { $server->stop() }]);
	$server = App::Syslogd->new(file => new_log(), socket => $socket);

	returns_ok(keeps_state(sub { $server->stop() }, 'stop()'), $SCHEMA{server}, 'returns $self');
	covered('stop: returns $self');

	$server->run();
	is($server->count(), 1, 'the earlier stop() did not prevent run() from working');
	covered('stop: before run() has no effect');
};

subtest 'i18n' => sub {
	# Purpose: every key of the documented table renders its English text;
	# object and class calls both work; an unknown key does not die
	my $server = App::Syslogd->new(language => 'en');
	my %expect = (
		usage => [{ program => 'syslogd' }, $CONFIG{usage_text}],
		listening => [{ address => '::', port => 514 }, 'Syslog server listening on :: UDP port 514'],
		shutdown => [{ count => 1 }, 'Syslog server shutting down after recording 1 message'],
		socket_failed => [{ address => 'A', port => 1, error => 'E' }, 'Could not create a UDP socket on A port 1: E'],
		open_failed => [{ file => 'F', error => 'E' }, 'Could not open log file F: E'],
		unsafe_file => [{ file => 'F' }, 'Refusing to log to F: it must be a regular file, owned by this user, with exactly one link'],
		write_failed => [{ file => 'F', error => 'E' }, 'Could not write to log file F: E'],
		recv_failed => [{ error => 'E' }, 'Error receiving a datagram: E'],
		no_log_open => [{}, 'process() was called before reopen_log() succeeded'],
		not_a_datagram => [{ type => 'ARRAY' }, 'A datagram must be a string (the type given was ARRAY)'],
		missing_key => [{}, 'A message key is needed'],
		bad_values => [{ type => 'SCALAR' }, 'Message values must be a hash reference (the type given was SCALAR)'],
		no_progress => [{}, 'the system accepted no data'],
		not_cgi => [{}, 'This program is a server, not a CGI program: it will not run from a web server'],
		not_a_log => [{ file => 'F' }, 'Refusing to log to F: it is not empty and does not start with the syslog header line'],
		already_running => [{}, 'run() is already running'],
	);
	foreach my $key (sort keys %expect) {
		my ($values, $text) = @{$expect{$key}};
		is($server->i18n($key, $values), $text, $key);
		covered("i18n: key $key");
	}
	is($server->i18n('shutdown', { count => 2 }), 'Syslog server shutting down after recording 2 messages', 'plural');
	returns_ok(keeps_state(sub { $server->i18n('shutdown', { count => 2 }) }, 'i18n()'), $SCHEMA{string}, 'a string');
	covered('i18n: object call');

	{
		local $ENV{LANGUAGE} = 'en';
		is(App::Syslogd->i18n('shutdown', { count => 3 }), 'Syslog server shutting down after recording 3 messages', 'class call');
	}
	covered('i18n: class call');

	is($server->i18n('no_such_key', { a => 1 }), 'no_such_key (a=1)', 'unknown key: the key and its values');
	covered('i18n: unknown key');
};

# ===========================================================================
# 2. lib/App/Syslogd/I18N.pm
# ===========================================================================

subtest 'App::Syslogd::I18N::handle' => sub {
	# Purpose: a requested language, the English fallback, and the
	# environment.  Strategy: the real lexicons, then a mocked
	# Locale::Maketext lookup to force the fallback branch.
	my $en = keeps_state(sub { App::Syslogd::I18N->handle('en') }, 'handle()');
	returns_ok($en, $SCHEMA{handle}, 'a language handle');
	isa_ok($en, 'App::Syslogd::I18N::en', 'the requested language');
	covered('handle: requested language');

	isa_ok(App::Syslogd::I18N->handle('xx-nowhere'), 'App::Syslogd::I18N::en', 'unknown language: English');
	{
		my @asked;
		my $g = mock_scoped('App::Syslogd::I18N::get_handle' => sub { shift; push @asked, [@_]; return @asked == 1 ? undef : 'EN' });
		is(App::Syslogd::I18N->handle('de'), 'EN', 'no lexicon: the English handle');
		is_deeply(\@asked, [['de'], ['en']], 'English asked for after the requested language');
	}
	covered('handle: English fallback');

	{
		local $ENV{LANGUAGE} = 'en';
		local $ENV{LC_ALL} = 'en_US.UTF-8';
		isa_ok(App::Syslogd::I18N->handle(), 'App::Syslogd::I18N::en', 'from the environment');
	}
	covered('handle: language from the environment');
};

subtest 'App::Syslogd::I18N::text' => sub {
	# Purpose: values are placed by name, missing ones are empty, unknown
	# keys come back readable, and the documented maketext failure
	my $lh = App::Syslogd::I18N->handle('en');

	my $text = keeps_state(sub { $lh->text('socket_failed', { error => 'E', port => 'P', address => 'A' }) }, 'text()');
	is($text, 'Could not create a UDP socket on A port P: E', 'values placed by name');
	returns_ok($text, $SCHEMA{string}, 'a string');
	covered('text: values by name');

	warnings_are { is($lh->text('open_failed', {}), 'Could not open log file : ', 'missing values are empty') } [], 'without warnings';
	covered('text: missing values are empty');

	is($lh->text('no_such_key'), 'no_such_key', 'unknown key, no values');
	is($lh->text('no_such_key', { b => 2, a => 1 }), 'no_such_key (a=1, b=2)', 'unknown key, sorted values');
	covered('text: unknown key');

	{
		package App::Syslogd::I18N::x_unit_orphan;
		our @ISA = ('App::Syslogd::I18N');
		our %Lexicon = (listening => 'only this');
	}
	throws_ok { App::Syslogd::I18N::x_unit_orphan->new()->text('shutdown', { count => 1 }) }
		qr/\Amaketext doesn't know how to say:\nshutdown\n/, 'a translation that does not inherit from English';
	covered("text: message maketext doesn't know how to say");

	throws_ok { $lh->text(undef) } exact('A message key is needed'), 'no key';
	throws_ok { $lh->text('') } exact('A message key is needed'), 'an empty key';
	covered('text: message A message key is needed');
	throws_ok { $lh->text('listening', [1]) }
		exact('Message values must be a hash reference (the type given was ARRAY)'), 'values as an array';
	throws_ok { $lh->text('listening', 'port') }
		exact('Message values must be a hash reference (the type given was SCALAR)'), 'values as a plain string';
	covered('text: message Message values must be a hash reference');
};

subtest 'App::Syslogd::I18N::gender' => sub {
	# Purpose: the POD examples and each documented form
	my $lh = App::Syslogd::I18N->handle('en');
	is(keeps_state(sub { $lh->gender('Female', 'his', 'her', 'their') }, 'gender()'), 'her', 'POD example: Female');
	is($lh->gender(undef, 'his', 'her', 'their'), 'their', 'POD example: undef');
	returns_ok($lh->gender('male', 'his', 'her', 'their'), $SCHEMA{string}, 'a string');

	is($lh->gender('MALE', 'his', 'her', 'their'), 'his', 'male, any case');
	covered('gender: male form');
	is($lh->gender('female', 'his', 'her', 'their'), 'her', 'female');
	covered('gender: female form');
	is($lh->gender($_, 'his', 'her', 'their'), 'their', "'$_' is neutral") foreach('m', 'f', 'other', '');
	covered('gender: neutral form');
};

# ===========================================================================
# Ledger
# ===========================================================================

subtest 'every documented message and state was tested' => sub {
	# Purpose: anything still in the ledger is documented but untested
	fail("untested: $_") foreach(sort keys %ledger);
	ok(!%ledger, 'the ledger is empty');
};

done_testing();
