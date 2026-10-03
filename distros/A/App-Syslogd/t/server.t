#!/usr/bin/env perl

# App::Syslogd: construction, parsing, recording, log safety, the
# receive loop (with a fake socket and with a real one), signals and
# encapsulation.  White-box: private helpers are called directly, which
# Sub::Private and Sub::Protected allow under the test harness.

use strict;
use warnings;

use Config;
use Errno qw(EINTR);
use Fcntl ();
use File::Temp qw(tempdir);
use IO::Socket::IP;
use Socket qw(pack_sockaddr_in inet_aton);
use Test::Most;

use_ok('App::Syslogd');

# White-box access to :Private / :Protected helpers, even outside prove
$Sub::Private::BYPASS = $Sub::Protected::BYPASS = 1;

# Windows has no Unix permission bits, no O_NOFOLLOW, no SIGHUP from
# outside, and does not let a signal interrupt a blocking recv()
my $WINDOWS = ($^O eq 'MSWin32');
# Use the value: where O_NOFOLLOW exists Perl inlines it as a constant,
# and a constant in void context draws a "Useless use" warning.  Where it
# does not exist the call dies, and eval gives undef.
my $HAVE_NOFOLLOW = defined(eval { Fcntl::O_NOFOLLOW() });

my $dir = tempdir(CLEANUP => 1);
my $serial = 0;

# A fresh log path for each test, so tests cannot see each other's rows
sub new_log { return "$dir/log" . ++$serial . '.csv' }

# Slurp a file into an arrayref of lines without their newlines
sub lines_of {
	my $file = shift;
	open(my $fh, '<', $file) or die "$file: $!";
	chomp(my @lines = <$fh>);
	return \@lines;
}

# A sockaddr for a documentation address (RFC 5737), never resolvable
my $PEER = pack_sockaddr_in(514, inet_aton('192.0.2.1'));
my $HEADER = '"Host","facility","severity","msg"';

# Stands in for a socket: hands out queued datagrams, then stops the server
{
	package FakeSocket;
	sub new { my ($class, %a) = @_; return bless { queue => $a{queue}, on_empty => $a{on_empty} }, $class }
	sub recv {
		my $self = $_[0];
		my $next = shift @{$self->{queue}};
		if(ref($next) eq 'CODE') {
			$next->();
			$! = Errno::EINTR();
			return undef;
		}
		if(!defined($next)) {
			$self->{on_empty}->();
			$! = Errno::EINTR();
			return undef;
		}
		$_[1] = $next;
		return $PEER;
	}
	sub close { $_[0]{closed} = 1; return 1 }
}

# Wraps a real socket and stops the server after N datagrams
{
	package StopAfter;
	sub new { my ($class, $socket, $limit, $server) = @_; return bless { socket => $socket, limit => $limit, server => $server }, $class }
	sub recv {
		my $self = $_[0];
		my $peer = $self->{socket}->recv($_[1], $_[2]);
		$self->{server}->stop() if(--$self->{limit} <= 0);
		return $peer;
	}
	sub close { return $_[0]{socket}->close() }
}

subtest 'new() validates its arguments' => sub {
	my $s = new_ok('App::Syslogd');
	is($s->port(), 514, 'default port');
	is($s->address(), '0.0.0.0', 'default address');
	is($s->count(), 0, 'nothing recorded yet');

	is(App::Syslogd->new({ port => 5514 })->port(), 5514, 'hashref form');
	is(App::Syslogd->new(port => 0)->port(), 0, 'port 0 (kernel chooses) allowed');

	throws_ok { App::Syslogd->new(port => 65_536) } qr/port/, 'port above 65535 rejected';
	throws_ok { App::Syslogd->new(port => -1) } qr/port/, 'negative port rejected';
	throws_ok { App::Syslogd->new(prot => 514) } qr/Unknown parameter 'prot'/, 'misspelt argument rejected';
	throws_ok { App::Syslogd->new(file => '') } qr/file/, 'empty file name rejected';
	throws_ok { App::Syslogd->new(cache => 'x') } qr/cache/, 'cache must be an object';

	# undef means "use the default", never "set to undef"
	my $u = App::Syslogd->new(port => undef, file => undef, address => undef, resolve => undef);
	is($u->port(), 514, 'port => undef gives the default port');
	is($u->address(), '0.0.0.0', 'address => undef gives the default address');
	is($u->{file}, '/var/log/syslog/syslog.csv', 'file => undef gives the default file');
	is($u->{resolve}, 1, 'resolve => undef gives the default');
};

subtest 'parse_message(): valid PRI' => sub {
	my $p = sub { App::Syslogd->parse_message(@_) };

	is_deeply($p->('<34>su: failed'), { facility => 4, severity => 2, message => 'su: failed', valid => 1 }, 'auth.crit');
	is_deeply($p->('<0>x'), { facility => 0, severity => 0, message => 'x', valid => 1 }, 'PRI 0 (kern.emerg)');
	is_deeply($p->('<191>x'), { facility => 23, severity => 7, message => 'x', valid => 1 }, 'PRI 191 (local7.debug) is the maximum');
	is($p->("<13>trailing\r\n\0")->{message}, 'trailing', 'trailing CR, LF and NUL stripped');
	is($p->('<13>')->{message}, '', 'empty body after a valid PRI is still a record');
};

subtest 'parse_message(): invalid PRI becomes user.notice (RFC 3164 4.3.3)' => sub {
	foreach my $bad ('no pri', '<192>too big', '<013>leading zero', '<1000>four digits', '<>empty', '<-1>negative', '13>no open') {
		my $r = App::Syslogd->parse_message($bad);
		is_deeply($r, { facility => 1, severity => 5, message => $bad, valid => 0 }, "'$bad'");
	}
};

subtest 'parse_message(): boundaries and escaping' => sub {
	is(App::Syslogd->parse_message(undef), undef, 'undef ignored');
	is(App::Syslogd->parse_message(''), undef, 'empty ignored');
	is(App::Syslogd->parse_message('x'), undef, 'one character ignored');
	is(App::Syslogd->parse_message("x\n"), undef, 'one character plus newline ignored');
	ok(App::Syslogd->parse_message('xy'), 'two characters recorded');

	is(App::Syslogd->parse_message("<13>a\nb\tc\x7Fd")->{message}, 'a\x0Ab\x09c\x7Fd', 'control characters escaped');
	is(App::Syslogd->parse_message("<13>caf\xC3\xA9")->{message}, "caf\xC3\xA9", 'high-bit bytes kept');
	is(App::Syslogd->parse_message("<13>\0mid")->{message}, '\x00mid', 'embedded NUL escaped');
};

subtest 'reopen_log() creates a private file with one header' => sub {
	my $file = new_log();
	my $s = App::Syslogd->new(file => $file, resolve => 0);

	is($s->reopen_log(), $s, 'returns $self');
	ok(-f $file, 'file created');
	SKIP: {
		skip('no Unix permission bits on Windows', 1) if($WINDOWS);
		is((stat $file)[2] & 07777, 0600, 'mode 0600');
	}
	is_deeply(lines_of($file), [$HEADER], 'header written');

	$s->reopen_log()->reopen_log();
	is_deeply(lines_of($file), [$HEADER], 'reopening does not add a second header');

	SKIP: {
		skip('no Unix permission bits on Windows', 1) if($WINDOWS);
		# Same test as the code: without fchmod an open file cannot be
		# changed, so the server leaves it alone
		skip('this Perl has no fchmod', 1) unless($Config{d_fchmod});
		chmod(0644, $file);
		$s->reopen_log();
		is((stat $file)[2] & 07777, 0600, 'loose permissions on an existing file are tightened');
	}
};

subtest 'reopen_log() refuses unsafe files' => sub {
	my $target = new_log();
	open(my $fh, '>', $target) or die;
	close $fh;

	SKIP: {
		# Without O_NOFOLLOW (Windows) the server cannot refuse symlinks
		skip('O_NOFOLLOW is not available on this system', 1) unless($HAVE_NOFOLLOW);
		my $link = new_log();
		skip("cannot create a symlink: $!", 1) unless(eval { symlink($target, $link) });
		throws_ok { App::Syslogd->new(file => $link)->reopen_log() } qr/Could not open log file \Q$link\E/, 'symlink refused';
	}

	SKIP: {
		my $hard = new_log();
		skip("cannot create a hard link: $!", 1) unless(eval { link($target, $hard) });
		# Some systems (older Perls on Windows) do not report link counts
		skip('this system does not report link counts', 1) unless((stat $hard)[3] == 2);
		throws_ok { App::Syslogd->new(file => $hard)->reopen_log() } qr/Refusing to log to \Q$hard\E/, 'hard link refused';
	}

	throws_ok { App::Syslogd->new(file => $dir)->reopen_log() } qr/\Q$dir\E/, 'directory refused';
	throws_ok { App::Syslogd->new(file => "$dir/no/such/dir/x.csv")->reopen_log() } qr/Could not open log file/, 'missing directory reported';
};

subtest 'process() writes well-formed CSV' => sub {
	my $file = new_log();
	my $s = App::Syslogd->new(file => $file, resolve => 0)->reopen_log();

	is($s->process('<34>said "hi", then left', $PEER), $s, 'returns $self');
	$s->process("<13>two\nlines", $PEER);
	$s->process('x', $PEER);	# ignored
	$s->process('=cmd|calc', $PEER);

	is($s->count(), 3, 'three recorded, the one-character datagram ignored');
	is_deeply(lines_of($file), [
		$HEADER,
		'"192.0.2.1","4","2","said ""hi"", then left"',
		'"192.0.2.1","1","5","two\x0Alines"',
		'"192.0.2.1","1","5","=cmd|calc"',
	], 'quotes doubled, commas quoted, newline escaped, one record per line');

	# Round trip through a real CSV parser
	require Text::CSV;
	my $csv = Text::CSV->new({ binary => 1 });
	open(my $fh, '<', $file) or die;
	my $rows = $csv->getline_all($fh);
	is($rows->[1][3], 'said "hi", then left', 'Text::CSV reads the message back unchanged');
	is(scalar(@{$rows}), 4, 'Text::CSV sees four rows');
};

subtest 'process() before reopen_log()' => sub {
	throws_ok { App::Syslogd->new()->process('<13>x', $PEER) } qr/before reopen_log\(\)/, 'croaks';
};

subtest 'host name resolution and its cache' => sub {
	my $file = new_log();

	# A cache that records what it is asked for, then defers to the code
	{
		package CountingCache;
		sub new { return bless { seen => {}, calls => {} }, shift }
		sub compute { my ($self, $key, $ttl, $code) = @_; $self->{calls}{$key}++; return $self->{seen}{$key} //= $code->() }
	}
	my $cache = CountingCache->new();

	my $s = App::Syslogd->new(file => $file, cache => $cache)->reopen_log();
	my $localhost = pack_sockaddr_in(514, inet_aton('127.0.0.1'));
	$s->process('<13>a', $localhost)->process('<13>b', $localhost)->process('<13>c', $PEER);

	my $lines = lines_of($file);
	# Not every test machine can reverse-resolve 127.0.0.1, so ask the
	# resolver what the right answer is rather than assuming "localhost"
	my ($error, $name) = Socket::getnameinfo($localhost, Socket::NI_NAMEREQD(), Socket::NIx_NOSERV());
	my $expected = $error ? '127.0.0.1' : $name;
	like($lines->[1], qr/\A"\Q$expected\E"/, "127.0.0.1 logged as $expected");
	like($lines->[3], qr/\A"192\.0\.2\.1"/, 'unresolvable address logged numerically');
	is($cache->{calls}{'127.0.0.1'}, 2, 'cache consulted per datagram');

	is(App::Syslogd->new(resolve => 0)->_peer_name($localhost), '127.0.0.1', '--no-resolve logs the address');
	is(App::Syslogd->new(resolve => 1)->_peer_name('garbage'), '', 'an undecodable sockaddr does not die');
	is(App::Syslogd->new(resolve => 1)->_peer_name(undef), '', 'an undef sockaddr does not die');

	# process() with no peer still records the message, with an empty host
	my $nopeer = new_log();
	App::Syslogd->new(file => $nopeer)->reopen_log()->process('<13>no peer', undef);
	is(lines_of($nopeer)->[1], '"","1","5","no peer"', 'undef peer logged as an empty host');
};

subtest 'run() with a fake socket' => sub {
	my $file = new_log();
	my $s;
	my $socket = FakeSocket->new(
		queue => ['<13>one', 'x', '<14>two'],
		on_empty => sub { $s->stop() },
	);
	$s = App::Syslogd->new(file => $file, resolve => 0, socket => $socket);

	is($s->run(), $s, 'run() returns $self after stop()');
	is($s->count(), 2, 'two datagrams recorded');
	ok($socket->{closed}, 'socket closed on return');
	ok(!$s->{fh}, 'log closed on return');
	is(scalar(@{lines_of($file)}), 3, 'header and two rows');
};

subtest 'SIGHUP reopens the log; SIGTERM stops' => sub {
	# Windows cannot deliver SIGHUP or SIGTERM to the running process this
	# way, and cannot rename a file that is open
	plan(skip_all => 'Unix signals') if($WINDOWS);

	my $file = new_log();
	my $rotated = "$file.1";
	my $socket = FakeSocket->new(
		queue => [
			'<13>before',
			sub { rename($file, $rotated) or die; kill('HUP', $$) },
			'<13>after',
			sub { kill('TERM', $$) },
			'<13>never read',
		],
	);
	my $outer = 0;
	local $SIG{HUP} = sub { $outer++ };

	my $s = App::Syslogd->new(file => $file, resolve => 0, socket => $socket);
	$s->run();

	is_deeply(lines_of($rotated), [$HEADER, '"192.0.2.1","1","5","before"'], 'rotated file keeps old rows');
	is_deeply(lines_of($file), [$HEADER, '"192.0.2.1","1","5","after"'], 'new file has a header and new rows');
	is($s->count(), 2, 'TERM stopped the loop before the last datagram');
	is($outer, 0, 'run() handled HUP itself');

	kill('HUP', $$);
	is($outer, 1, "caller's HUP handler restored after run()");
};

subtest 'recv() errors are reported, EINTR is not' => sub {
	my $s;
	my $socket = bless {}, 'ErrSocket';
	{
		no warnings 'once';
		my $calls = 0;
		*ErrSocket::recv = sub { $calls++; $! = $calls == 1 ? Errno::EBADF() : Errno::EINTR(); $s->stop() if($calls > 1); return undef };
		*ErrSocket::close = sub { 1 };
	}
	$s = App::Syslogd->new(file => new_log(), socket => $socket);

	warnings_like { $s->run() } [qr/Error receiving a datagram/], 'one warning, for EBADF only';
};

subtest 'write failures warn and do not die' => sub {
	SKIP: {
		skip('/dev/full is Linux-specific', 2) unless(-c '/dev/full' && -w '/dev/full');

		my $s = App::Syslogd->new(file => new_log(), resolve => 0)->reopen_log();
		open(my $full, '>>', '/dev/full') or skip("/dev/full: $!", 2);
		$full->autoflush(1);
		$s->{fh} = $full;

		warnings_like { $s->process('<13>lost', $PEER) } [qr/Could not write to log file/], 'carps once, nothing else';
		warnings_like { lives_ok { $s->process('<13>lost again', $PEER) } 'keeps going' } [qr/Could not write/], 'and carps again';

		# Detach /dev/full before it is closed, or close() warns too
		$s->{fh} = undef;
		{ no warnings 'io'; close($full) }
	}
};

subtest 'run() over a real UDP socket' => sub {
	my $file = new_log();
	my $s = App::Syslogd->new(port => 0, address => '127.0.0.1', file => $file, resolve => 0);

	is($s->open_socket(), $s, 'open_socket() returns $self');
	my $port = $s->port();
	cmp_ok($port, '>', 0, "kernel chose port $port");
	is($s->address(), '127.0.0.1', 'bound address reported');

	my $client = IO::Socket::IP->new(PeerHost => '127.0.0.1', PeerPort => $port, Proto => 'udp') or die $@;
	$client->send($_) foreach('<13>first', '<165>second ' . ('x' x 3000));

	# Stop after the second datagram.  A wrapper rather than alarm():
	# on Windows a signal does not interrupt a blocking recv(), so an
	# alarm would never end the loop
	$s->{socket} = StopAfter->new($s->{socket}, 2, $s);
	$s->run();

	my $lines = lines_of($file);
	is(scalar(@{$lines}), 3, 'both datagrams recorded');
	like($lines->[2], qr/\A"127\.0\.0\.1","20","5","second x{3000}"\z/, 'a 3000-byte message is not truncated');
};

subtest 'open_socket() failure' => sub {
	my $first = App::Syslogd->new(port => 0, address => '127.0.0.1')->open_socket();
	my $port = $first->port();

	throws_ok { App::Syslogd->new(port => $port, address => '127.0.0.1')->open_socket() }
		qr/Could not create a UDP socket on 127\.0\.0\.1 port $port/, 'port in use';
	throws_ok { App::Syslogd->new(port => 0, address => 'no.such.host.invalid')->open_socket() }
		qr/Could not create a UDP socket on no\.such\.host\.invalid/, 'bad address';
};

subtest 'encapsulation is enforced outside the test harness' => sub {
	local $Sub::Private::BYPASS = 0;
	local $Sub::Protected::BYPASS = 0;
	local $Sub::Private::config{harness_bypass} = 0;
	local $Sub::Protected::config{harness_bypass} = 0;

	my $s = App::Syslogd->new(file => new_log());
	foreach my $private (qw(_open_log _close_log _write_header _write_row _receive _shutdown)) {
		throws_ok { $s->$private() } qr/private/, "$private is private";
	}
	throws_ok { App::Syslogd::_escape_controls('x') } qr/private/, '_escape_controls is private';
	throws_ok { $s->_peer_name($PEER) } qr/protected/, '_peer_name is protected';

	# ...but a subclass may override or call the protected one
	{
		package My::Server;
		our @ISA = ('App::Syslogd');
		sub name_of { my ($self, $peer) = @_; return 'sub:' . $self->_peer_name($peer) }
	}
	is(My::Server->new(resolve => 0)->name_of($PEER), 'sub:192.0.2.1', 'subclass can call _peer_name');

	# Public methods still work with enforcement on
	lives_ok { $s->reopen_log()->process('<13>x', $PEER) } 'public API unaffected';
};

done_testing();
