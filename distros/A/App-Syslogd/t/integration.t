#!/usr/bin/env perl

# Integration tests: whole workflows across App::Syslogd,
# App::Syslogd::I18N, App::Syslogd::I18N::en and the etc/syslogd program,
# exactly as the POD describes them.
#
# Strategy
#	* Real objects, real files and real UDP sockets on the loopback
#	  interface.  Mocking is kept to a minimum: spy() checks that the
#	  resolver is called (and called with the right arguments), and an
#	  after() hook on process() ends run() once the expected datagrams
#	  have arrived, which is portable where signals are not.
#	* Several independent servers run in one process to prove they do not
#	  interfere.
#	* Child processes test what one process cannot: loading the module
#	  at compile time and at run time, the command-line program with real
#	  signals, and every combination of Text::CSV's optional backends
#	  (hidden with Test::Without::Module).

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use App::Syslogd::Cache;
use Errno qw(EINTR ENOENT);
use File::Spec;
use File::Temp qw(tempdir);
use IO::Socket::IP;
use IPC::Open3 qw(open3);
use Readonly;
use Socket qw(pack_sockaddr_in inet_aton getnameinfo NI_NUMERICHOST NI_NAMEREQD NIx_NOSERV);
use Symbol qw(gensym);
use Test::Mockingbird;
use Test::Most;
use Test::Returns;
use Text::CSV;
use Time::HiRes qw(sleep time);

BEGIN {
	use_ok('App::Syslogd');
	use_ok('App::Syslogd::I18N');
	use_ok('App::Syslogd::I18N::en');
}

Readonly my %CONFIG => (
	loopback => '127.0.0.1',
	any_port => 0,				# the kernel chooses
	test_net_ip => '192.0.2.1',		# RFC 5737: never resolves
	header => [qw(Host facility severity msg)],
	big_message_bytes => 3000,		# beyond the old 1024-byte buffer
	poll_interval => 0.05,			# seconds between checks
	poll_timeout => 10,			# seconds before giving up
	program => File::Spec->catfile($Bin, File::Spec->updir(), 'etc', 'syslogd'),
	lib => File::Spec->catdir($Bin, File::Spec->updir(), 'lib'),
	csv_backends => [qw(Text::CSV_XS Text::CSV_PP)],
);

# Datagrams covering each documented case, with the row each must become
# (host column left out: it depends on the sender)
Readonly my @CORPUS => (
	["<34>su: 'su root' failed\n", [4, 2, "su: 'su root' failed"]],	# POD example
	['<0>kernel', [0, 0, 'kernel']],					# smallest PRI
	['<191>local7', [23, 7, 'local7']],					# largest PRI
	['no pri at all', [1, 5, 'no pri at all']],				# RFC 3164 4.3.3
	['<192>too big', [1, 5, '<192>too big']],
	["<13>tab\there", [1, 5, 'tab\x09here']],				# escaped
	["<13>caf\xC3\xA9 \xF0\x9F\x98\x80", [1, 5, "caf\xC3\xA9 \xF0\x9F\x98\x80"]],	# UTF-8 and emoji bytes
	['<13>said "hi", left', [1, 5, 'said "hi", left']],			# CSV quoting
	['x', undef],								# too short: ignored
);

my $dir = tempdir(CLEANUP => 1);
my $serial = 0;
my $WINDOWS = ($^O eq 'MSWin32');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub verbose_diag { diag(@_) if($ENV{TEST_VERBOSE}); return }

sub new_path { my $stem = shift // 'log'; return File::Spec->catfile($dir, $stem . ++$serial . '.csv') }

# The datagrams of @CORPUS that must be recorded, and their rows
sub recorded_corpus { return grep { defined($_->[1]) } @CORPUS }

# Read a log back with a real CSV parser: the header row, then the rows
sub read_csv {
	my $file = shift;
	# decode_utf8 => 0: compare bytes, as the module writes them (Text::CSV_XS
	# would otherwise decode UTF-8 on reading)
	my $csv = Text::CSV->new({ binary => 1, decode_utf8 => 0 });
	open(my $fh, '<', $file) or die "$file: $!";
	my $rows = $csv->getline_all($fh);
	close($fh);
	return $rows;
}

# Wait until $test returns true, or the timeout passes
sub wait_for {
	my $test = shift;
	my $deadline = time() + $CONFIG{poll_timeout};
	while(time() < $deadline) {
		return 1 if($test->());
		sleep($CONFIG{poll_interval});
	}
	return 0;
}

# Run perl with @args in a child, return (exit code, stdout, stderr).
# IPC::Open3 with a list: no shell quoting, and it works on Windows.
# The child writes to files, not pipes: reading one pipe to the end while
# the child fills the other can deadlock.  Line endings are made "\n",
# because a child on Windows writes "\r\n".
sub run_perl {
	my @args = @_;
	my ($out_path, $err_path) = map { File::Spec->catfile($dir, "child$serial.$_") } qw(out err);
	$serial++;
	open(my $out, '>', $out_path) or die "$out_path: $!";
	open(my $err, '>', $err_path) or die "$err_path: $!";
	my $pid = open3(my $in, '>&' . fileno($out), '>&' . fileno($err), $^X, @args);
	close($in);
	waitpid($pid, 0);
	my $exit = $? >> 8;
	close($out);
	close($err);

	my ($stdout, $stderr) = map { slurp_text($_) } ($out_path, $err_path);
	verbose_diag("child: @args\nstdout: $stdout\nstderr: $stderr");
	return ($exit, $stdout, $stderr);
}

# A child's text output, with "\r\n" (Windows) turned into "\n"
sub slurp_text {
	my $path = shift;
	open(my $fh, '<:raw', $path) or die "$path: $!";
	my $text = do { local $/; <$fh> } // '';
	close($fh);
	$text =~ s/\r\n/\n/g;
	return $text;
}

# Write Perl code to a script file for a child process.  Code is never
# passed with -e: on Windows the arguments are joined into one command
# line, and quotes and newlines inside them are mangled.
sub script_file {
	my $code = shift;
	my $path = File::Spec->catfile($dir, 'child' . ++$serial . '.pl');
	open(my $fh, '>', $path) or die "$path: $!";
	print {$fh} "$code\n";
	close($fh) or die "$path: $!";
	return $path;
}

# Write datagrams to a file, one per line in hex, so that any bytes
# (quotes, newlines, UTF-8) reach the child unchanged on every platform
sub datagram_file {
	my @datagrams = @_;
	my $path = File::Spec->catfile($dir, 'datagrams' . ++$serial . '.hex');
	open(my $fh, '>', $path) or die "$path: $!";
	print {$fh} map { unpack('H*', $_) . "\n" } @datagrams;
	close($fh) or die "$path: $!";
	return $path;
}

# Send datagrams to a port on the loopback interface
sub send_datagrams {
	my ($port, @datagrams) = @_;
	my $client = IO::Socket::IP->new(PeerHost => $CONFIG{loopback}, PeerPort => $port, Proto => 'udp')
		or die "client: $IO::Socket::errstr";
	$client->send($_) foreach(@datagrams);
	return;
}

# Make run() return once $count more datagrams have been processed.  An
# after() hook rather than a signal, so it works on every platform.
sub stop_after {
	my ($server, $count) = @_;
	my $seen = 0;
	return mock_scoped('App::Syslogd::process' => do {
		my $real = \&App::Syslogd::process;
		sub {
			my $result = $real->(@_);
			$_[0]->stop() if($_[0] == $server && ++$seen >= $count);
			return $result;
		};
	});
}

# A socket double for the documented socket => argument of new(): it
# serves queued datagrams; a code ref in the queue is run instead
{
	package QueueSocket;
	sub new { my ($class, @queue) = @_; return bless { queue => [@queue], closed => 0 }, $class }
	sub recv {
		my $self = $_[0];
		my $next = shift(@{$self->{queue}});
		if(ref($next) eq 'CODE') {
			$next->();
			$! = Errno::EINTR();
			return undef;
		}
		return undef unless(defined($next));
		$_[1] = $next;
		return Socket::pack_sockaddr_in(514, Socket::inet_aton('192.0.2.1'));
	}
	sub close { $_[0]{closed}++; return 1 }
}

# A test-only language, to prove two servers keep their own languages.
# Private-use tags allow at most 8 characters after "x-".
{
	package App::Syslogd::I18N::x_intg;
	use parent -norequire, 'App::Syslogd::I18N::en';
	our %Lexicon = (shutdown => 'Fin apres [quant,_1,message,messages]');
	$INC{'App/Syslogd/I18N/x_intg.pm'} = __FILE__;
}

# ===========================================================================
# Workflows
# ===========================================================================

subtest 'construct the documented objects' => sub {
	# Purpose: the constructors named in the POD give the documented types
	my $server = new_ok('App::Syslogd' => [port => $CONFIG{any_port}, resolve => 0]);
	returns_ok($server, { type => 'object', isa => 'App::Syslogd' }, 'App::Syslogd object');
	my $lh = new_ok('App::Syslogd::I18N::en');
	returns_ok(App::Syslogd::I18N->handle('en'), { type => 'object', isa => 'App::Syslogd::I18N' }, 'language handle');
	isa_ok($lh, 'App::Syslogd::I18N', 'the English lexicon is an App::Syslogd::I18N');
};

subtest 'receive over UDP, decode, write CSV, report' => sub {
	# Purpose: the main workflow end to end, with real sockets.
	# open_socket -> reopen_log -> run (recv, parse, resolve, write) ->
	# shutdown message from the i18n catalogue.
	my $file = new_path();
	my $server = App::Syslogd->new(address => $CONFIG{loopback}, port => $CONFIG{any_port}, file => $file, resolve => 0);
	$server->open_socket()->reopen_log();
	my $port = $server->port();
	cmp_ok($port, '>', 0, "bound to a real port ($port)");
	is($server->i18n('listening', { address => $server->address(), port => $port }),
		"Syslog server listening on $CONFIG{loopback} UDP port $port", 'start-up message');

	my @recorded = recorded_corpus();
	my $big = '<13>' . ('b' x $CONFIG{big_message_bytes});
	send_datagrams($port, (map { $_->[0] } @CORPUS), $big);

	{
		my $guard = stop_after($server, scalar(@CORPUS) + 1);
		returns_ok($server->run(), { type => 'object', isa => 'App::Syslogd' }, 'run() returns the server');
	}

	my $rows = read_csv($file);
	verbose_diag(explain($rows));
	is_deeply($rows->[0], $CONFIG{header}, 'header row');
	my @data = @{$rows}[1 .. $#{$rows}];
	is(scalar(@data), scalar(@recorded) + 1, 'every recordable datagram written; the short one ignored');
	foreach my $i (0 .. $#recorded) {
		is_deeply($data[$i], [$CONFIG{loopback}, @{$recorded[$i][1]}], "row $i");
	}
	is(length($data[-1][3]), $CONFIG{big_message_bytes}, 'a large datagram is not truncated');
	is($server->count(), scalar(@recorded) + 1, 'count() matches the rows');
	is($server->i18n('shutdown', { count => $server->count() }),
		'Syslog server shutting down after recording ' . $server->count() . ' messages', 'shutdown message');
};

subtest 'parse_message and process agree' => sub {
	# Purpose: what process() writes is exactly what parse_message()
	# returns, for every case in the corpus
	my $file = new_path();
	my $server = App::Syslogd->new(file => $file, resolve => 0)->reopen_log();
	my $peer = pack_sockaddr_in(514, inet_aton($CONFIG{test_net_ip}));
	my @expected;
	foreach my $case (@CORPUS) {
		$server->process($case->[0], $peer);
		my $record = App::Syslogd->parse_message($case->[0]) or next;
		push @expected, [$CONFIG{test_net_ip}, @{$record}{qw(facility severity message)}];
	}
	my $rows = read_csv($file);
	is_deeply([@{$rows}[1 .. $#{$rows}]], \@expected, 'rows match parse_message()');
};

subtest 'host names: resolver calls and the cache' => sub {
	# Purpose: process() asks the resolver for the address of every
	# datagram but for the name only once per cache; servers with their
	# own caches look names up separately, and a shared cache is shared.
	# Strategy: spy on getnameinfo (it still runs for real).
	my $peer = pack_sockaddr_in(514, inet_aton($CONFIG{loopback}));
	my (undef, $expected_name) = getnameinfo($peer, NI_NAMEREQD, NIx_NOSERV);
	$expected_name //= $CONFIG{loopback};

	my $spy = spy('App::Syslogd::getnameinfo');
	my $count_lookups = sub {
		my %kind = (numeric => 0, name => 0);
		foreach my $call ($spy->()) {
			my (undef, $sockaddr, $flags) = @{$call};
			is($sockaddr, $peer, 'the sender address is passed') unless($kind{numeric} + $kind{name});
			$kind{($flags & NI_NUMERICHOST) ? 'numeric' : 'name'}++;
		}
		return \%kind;
	};

	my $file = new_path();
	my $server = App::Syslogd->new(file => $file)->reopen_log();
	$server->process("<13>$_", $peer) foreach(1 .. 3);
	my $lookups = $count_lookups->();
	verbose_diag(explain($lookups));
	is($lookups->{numeric}, 3, 'address decoded for every datagram');
	is($lookups->{name}, 1, 'name looked up once: the cache answers the rest');
	is(read_csv($file)->[1][0], $expected_name, "logged as the resolver's name");
	restore_all();

	# Two servers, each with its own cache: each looks the name up
	$spy = spy('App::Syslogd::getnameinfo');
	my @separate = map { App::Syslogd->new(file => new_path())->reopen_log() } (1, 2);
	$_->process('<13>x', $peer) foreach(@separate);
	is($count_lookups->()->{name}, 2, 'separate caches: one name lookup each');
	restore_all();

	# Two servers sharing one cache object (documented: objects are shared)
	$spy = spy('App::Syslogd::getnameinfo');
	my $shared_cache = App::Syslogd::Cache->new();
	my @sharing = map { App::Syslogd->new(file => new_path(), cache => $shared_cache)->reopen_log() } (1, 2);
	$_->process('<13>x', $peer) foreach(@sharing);
	is($count_lookups->()->{name}, 1, 'shared cache: one name lookup for both servers');
	restore_all();

	# A CHI cache passed in still works (CHI is optional, so skip without it)
	SKIP: {
		skip('CHI is not installed', 2) unless(eval { require CHI; 1 });
		$spy = spy('App::Syslogd::getnameinfo');
		my $chi = CHI->new(driver => 'Memory', datastore => {});
		my @chi_servers = map { App::Syslogd->new(file => new_path(), cache => $chi)->reopen_log() } (1, 2);
		$_->process('<13>x', $peer) foreach(@chi_servers);
		is($count_lookups->()->{name}, 1, 'a shared CHI cache: one name lookup for both servers');
		ok(defined($chi->get($CONFIG{loopback})), 'the name is stored in the CHI cache');
		restore_all();
	}

	# Resolution off: the resolver is only asked for the address
	$spy = spy('App::Syslogd::getnameinfo');
	App::Syslogd->new(file => new_path(), resolve => 0)->reopen_log()->process('<13>x', $peer);
	is_deeply($count_lookups->(), { numeric => 1, name => 0 }, 'resolve => 0: no name lookup');
	restore_all();
};

subtest 'independent servers in one process' => sub {
	# Purpose: several servers at once keep their own sockets, files,
	# counts, languages and running state.  Strategy: server A's loop runs
	# server B's whole loop in the middle (nested run()), and stopping B
	# must not stop A.
	my ($first_file, $second_file) = (new_path('first'), new_path('second'));
	my ($first, $second);
	my $second_socket = QueueSocket->new('<13>b1', '<13>b2', sub { $second->stop() });
	my $first_socket = QueueSocket->new('<13>a1', sub { $second->run() }, '<13>a2', sub { $first->stop() });
	$first = App::Syslogd->new(file => $first_file, resolve => 0, socket => $first_socket, language => 'en');
	$second = App::Syslogd->new(file => $second_file, resolve => 0, socket => $second_socket, language => 'x-intg');

	local $SIG{TERM} = 'DEFAULT';
	$first->run();

	is_deeply([map { $_->[3] } @{read_csv($first_file)}[1 .. 2]], ['a1', 'a2'], "A's file has only A's datagrams");
	is_deeply([map { $_->[3] } @{read_csv($second_file)}[1 .. 2]], ['b1', 'b2'], "B's file has only B's datagrams");
	is($first->count(), 2, "A's count");
	is($second->count(), 2, "B's count");
	is($first_socket->{closed}, 1, "A closed its own socket");
	is($second_socket->{closed}, 1, "B closed its own socket");
	is($SIG{TERM}, 'DEFAULT', 'signal handlers restored after both loops');

	like($first->i18n('shutdown', { count => 2 }), qr/^Syslog server shutting down/, 'A speaks English');
	is($second->i18n('shutdown', { count => 2 }), 'Fin apres 2 messages', 'B speaks its own language');

	# Two real sockets at once get different ports and their own traffic
	my @files = map { new_path('udp') } (1, 2);
	my @servers = map {
		App::Syslogd->new(address => $CONFIG{loopback}, port => $CONFIG{any_port}, file => $_, resolve => 0)
			->open_socket()->reopen_log()
	} @files;
	isnt($servers[0]->port(), $servers[1]->port(), 'two servers, two ports');
	send_datagrams($servers[$_]->port(), "<13>for server $_") foreach(0, 1);
	foreach my $i (0, 1) {
		my $guard = stop_after($servers[$i], 1);
		$servers[$i]->run();
		is(read_csv($files[$i])->[1][3], "for server $i", "server $i received only its own datagram");
	}
};

subtest 'life cycle: run twice, recover from a bad log path' => sub {
	# Purpose: run() can be called again after it returns (it reopens
	# everything; the file keeps one header and the count carries on), and
	# a failed reopen_log() can be retried once the problem is fixed
	my $file = new_path();
	my $server;
	my $make_socket = sub { my @queue = @_; return QueueSocket->new(@queue, sub { $server->stop() }) };
	$server = App::Syslogd->new(file => $file, resolve => 0, socket => $make_socket->('<13>first'));
	$server->run();
	$server = App::Syslogd->new(file => $file, resolve => 0, socket => $make_socket->('<13>second'));
	$server->run();
	my $rows = read_csv($file);
	is_deeply([map { $_->[3] } @{$rows}], ['msg', 'first', 'second'], 'one header, rows from both runs');

	# The same object run twice: run() reopens the socket and the log
	my $created = 0;
	my $g = mock_scoped('IO::Socket::IP::new' => sub { $created++; return $make_socket->("<13>run $created") });
	my $again_file = new_path();
	my $again = App::Syslogd->new(file => $again_file, resolve => 0);
	$server = $again;
	$again->run();
	$again->run();
	is($created, 2, 'each run() opens a new socket');
	is($again->count(), 2, 'the count carries on across runs');
	is_deeply([map { $_->[3] } @{read_csv($again_file)}], ['msg', 'run 1', 'run 2'], 'one header, both runs');
	undef $g;

	# A missing directory: fails with the catalogue's message, then works
	my $subdir = File::Spec->catdir($dir, 'later' . ++$serial);
	my $late_file = File::Spec->catfile($subdir, 'log.csv');
	my $late = App::Syslogd->new(file => $late_file, resolve => 0);
	my $expected = $late->i18n('open_failed', { file => $late_file, error => do { local $! = ENOENT; "$!" } });
	throws_ok { $late->reopen_log() } qr/\A\Q$expected\E at /, 'the error is the catalogue message';
	mkdir($subdir) or die "$subdir: $!";
	lives_ok { $late->reopen_log()->process('<13>after the fix', undef) } 'works once the directory exists';
	is(read_csv($late_file)->[1][3], 'after the fix', 'and records normally');
};

subtest 'messages: the server and the catalogue agree' => sub {
	# Purpose: each message the server produces is the catalogue's text
	# for that key, whether reached through App::Syslogd::i18n(),
	# App::Syslogd::I18N::text() or an English handle made directly
	my $server = App::Syslogd->new(language => 'en');
	my $lh = App::Syslogd::I18N->handle('en');
	my $direct = App::Syslogd::I18N::en->new();
	foreach my $case (
		['listening', { address => '::', port => 514 }],
		['shutdown', { count => 1 }],
		['open_failed', { file => 'F', error => 'E' }],
		['no_log_open', {}],
	) {
		my ($key, $values) = @{$case};
		my $text = $lh->text($key, $values);
		is($server->i18n($key, $values), $text, "$key: App::Syslogd::i18n() matches the catalogue");
		is($direct->text($key, $values), $text, "$key: a directly made English handle matches");
	}

	my $no_log = $server->i18n('no_log_open');
	throws_ok { $server->process('<13>x', undef) } qr/\A\Q$no_log\E at /, 'the croak uses the catalogue text';
};

# ===========================================================================
# Child processes
# ===========================================================================

subtest 'loading at compile time and at run time' => sub {
	# Purpose: however the module is loaded, it loads silently, works, and
	# keeps its helpers private.  (A run-time require used to warn "Too
	# late to run CHECK block" and leave the helpers unprotected.)
	my $check = join("\n",
		'my $s = App::Syslogd->new();',
		'print eval { $s->_close_log(); 1 } ? "private: callable\n" : "private: blocked\n";',
		'print eval { App::Syslogd::_escape_controls("x"); 1 } ? "function: callable\n" : "function: blocked\n";',
		'print App::Syslogd->parse_message("<13>ok")->{message}, "\n";',
	);
	my %loaders = (
		'use at compile time' => 'use App::Syslogd;',
		'require at run time' => 'require App::Syslogd;',
		'require after the encapsulation modules' => 'BEGIN { require Sub::Private; require Sub::Protected } require App::Syslogd;',
	);
	foreach my $how (sort keys %loaders) {
		local $ENV{HARNESS_ACTIVE};	# the harness bypass would hide enforcement
		delete $ENV{HARNESS_ACTIVE};
		my ($exit, $stdout, $stderr) = run_perl("-I$CONFIG{lib}", script_file("$loaders{$how}\n$check"));
		is($exit, 0, "$how: exits cleanly");
		is($stderr, '', "$how: no warnings");
		is($stdout, "private: blocked\nfunction: blocked\nok\n", "$how: works, helpers protected");
	}
};

subtest 'optional Text::CSV backends, in every combination' => sub {
	# Purpose: Text::CSV uses Text::CSV_XS when it can and falls back to
	# Text::CSV_PP.  The log must be byte-for-byte the same with either
	# backend; with neither, loading must fail loudly, not silently.
	# Strategy: Test::Without::Module in a child, for each combination.
	# What to expect depends on which backends are really installed:
	# Text::CSV_XS is optional and is often missing (as on CI runners).
	my $script = join("\n",
		'use App::Syslogd;',
		'my $s = App::Syslogd->new(file => $ARGV[0], resolve => 0)->reopen_log();',
		'open(my $in, "<", $ARGV[1]) or die "$ARGV[1]: $!";',
		'while(my $hex = <$in>) { chomp($hex); $s->process(pack("H*", $hex), undef) }',
		'print Text::CSV->backend(), "\n";',
	);
	my $script_path = script_file($script);
	my $datagram_path = datagram_file(map { $_->[0] } @CORPUS);
	my @backends = @{$CONFIG{csv_backends}};	# in Text::CSV's order of preference
	my %installed = map { $_ => (eval "require $_; 1" ? 1 : 0) } @backends;
	note('installed backends: ', join(', ', grep { $installed{$_} } @backends) || 'none');

	my %reference;
	foreach my $mask (0 .. (2 ** @backends) - 1) {
		my @hidden = map { $backends[$_] } grep { $mask & (1 << $_) } 0 .. $#backends;
		my %is_hidden = map { $_ => 1 } @hidden;
		my @usable = grep { $installed{$_} && !$is_hidden{$_} } @backends;
		my $name = @hidden ? 'without ' . join(' and ', @hidden) : 'with every backend';
		my $file = new_path('csv');
		my ($exit, $stdout, $stderr) = run_perl("-I$CONFIG{lib}", (map { "-MTest::Without::Module=$_" } @hidden),
			$script_path, $file, $datagram_path);

		if(!@usable) {
			isnt($exit, 0, "$name: loading fails (no backend left)");
			like($stderr, qr/Can't locate Text\/CSV_PP\.pm/, "$name: and says what is missing");
			next;
		}
		is($exit, 0, "$name: works");
		is($stderr, '', "$name: no warnings");
		chomp(my $backend = $stdout);
		is($backend, $usable[0], "$name: uses $usable[0]");

		# Compare the logs; a child that failed has already been reported
		next unless(-s $file);
		my $content = do { local $/; open(my $fh, '<:raw', $file) or die "$file: $!"; <$fh> };
		$reference{$backend} //= $content;
		my ($first) = sort keys %reference;
		is($content, $reference{$first}, "$name: the log is identical to the $first one");
	}
	note('only one backend is installed, so only that one was compared') if(keys(%reference) < 2);
};

subtest 'the etc/syslogd program' => sub {
	# Purpose: the documented command line, end to end: start-up message,
	# datagrams written, SIGHUP rotation, SIGTERM shutdown message and a
	# clean exit.  Real signals, so not on Windows.
	plan(skip_all => 'Windows cannot send SIGHUP or SIGTERM') if($WINDOWS);

	my $file = new_path('cli');
	my $rotated = "$file.1";
	my $err = gensym();
	my $pid = open3(my $in, my $out, $err, $^X, "-I$CONFIG{lib}", $CONFIG{program},
		'--port', $CONFIG{any_port}, '--address', $CONFIG{loopback}, '--file', $file, '--no-resolve', '--language', 'en');
	close($in);

	# A time limit on each read: a program that does not flush its output
	# would otherwise hang the test suite here
	my $read_line = sub {
		local $SIG{ALRM} = sub { die "timed out\n" };
		alarm($CONFIG{poll_timeout});
		my $line = eval { scalar(<$out>) };
		alarm(0);
		return $line // '';
	};
	my $listening = $read_line->();
	verbose_diag("program said: $listening");
	like($listening, qr/\ASyslog server listening on \Q$CONFIG{loopback}\E UDP port (\d+)\n\z/, 'start-up message');
	my ($port) = $listening =~ /UDP port (\d+)/;

	send_datagrams($port, '<13>before rotation', 'x');
	ok(wait_for(sub { -s $file && @{read_csv($file)} == 2 }), 'the datagram is written');

	rename($file, $rotated) or die "rename: $!";
	kill('HUP', $pid);
	ok(wait_for(sub { -e $file }), 'SIGHUP: a new file is started');
	send_datagrams($port, '<13>after rotation');
	ok(wait_for(sub { -s $file && @{read_csv($file)} == 2 }), 'new datagrams go to the new file');

	kill('TERM', $pid);
	my $shutdown = $read_line->();
	waitpid($pid, 0);
	is($? >> 8, 0, 'SIGTERM: a clean exit');
	is($shutdown, "Syslog server shutting down after recording 2 messages\n", 'shutdown message counts both files');
	is_deeply(read_csv($rotated), [$CONFIG{header}, [$CONFIG{loopback}, 1, 5, 'before rotation']], 'rotated file');
	is_deeply(read_csv($file), [$CONFIG{header}, [$CONFIG{loopback}, 1, 5, 'after rotation']], 'new file');
	my $stderr = do { local $/; <$err> } // '';
	is($stderr, '', 'nothing on standard error');
};

subtest 'the etc/syslogd program: bad option' => sub {
	# Purpose: an unknown option prints the catalogue's usage message and
	# exits with an error, without starting
	my ($exit, $stdout, $stderr) = run_perl("-I$CONFIG{lib}", $CONFIG{program}, '--bogus');
	isnt($exit, 0, 'exits with an error');
	like($stderr, qr/^Unknown option: bogus$/m, "Getopt::Long names the option");
	my $usage = App::Syslogd->i18n('usage', { program => $CONFIG{program} });
	like($stderr, qr/^\Q$usage\E$/m, 'the usage message from the catalogue');
	is($stdout, '', 'nothing on standard output: it did not start');
};

done_testing();
