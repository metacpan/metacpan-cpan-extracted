#!/usr/bin/env perl

# Transaction-flow tests: whole multi-step operations, driven from start
# to end, then broken half way to check what is rolled back.
#
# App::Syslogd has no database; its transactions are:
#	record     parse -> resolve sender -> build CSV line -> append -> count
#	open log   close old -> open -> safety checks -> header check ->
#	           chmod -> header
#	rotate     (rename) -> SIGHUP -> close -> open new
#	server     bind -> open log -> receive loop -> shut down
#	cache      look up -> compute -> evict -> store
#
# For each: the complete sequence, then failures at each step, checking
# the file (no half lines, no extra rows, a refused file untouched), the
# permissions, the open descriptors and the counters; then that running
# the same sequence again works and does not duplicate state.
#
# Failures are injected with Test::Mockingbird; syswrite is replaced with
# mock_core before App::Syslogd is compiled, so that a write can fail half
# way through.

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Errno qw(EINTR ENOSPC);
use File::Spec;
use File::Temp qw(tempdir);
use Readonly;
use Socket qw(pack_sockaddr_in inet_aton);
use Test::Mockingbird;
use Test::Most;
use Test::Returns;
use Text::CSV;

our $SYSWRITE = '';	# '', 'full' (ENOSPC), or 'half' (half a line, then ENOSPC)
BEGIN {
	mock_core('syswrite' => sub {
		my ($real, $fh, $buffer, $length, $offset) = @_;
		$length //= length($buffer);
		$offset //= 0;
		if($main::SYSWRITE eq 'full') { $! = Errno::ENOSPC(); return undef }
		if($main::SYSWRITE eq 'half') { $main::SYSWRITE = 'full'; return $real->($fh, $buffer, int($length / 2), $offset) }
		return $real->($fh, $buffer, $length, $offset);
	});
}

use App::Syslogd;
use App::Syslogd::Cache;

Readonly my %CONFIG => (
	peer_ip => '192.0.2.1',
	peer_name => 'sender.example.com',
	loopback => '127.0.0.1',
	any_port => 0,
	header => [qw(Host facility severity msg)],
	header_line => qq{"Host","facility","severity","msg"\n},
	private_mode => 0600,
	foreign_mode => 0644,
	ttl => 300,
	repeats => 3,
	fd_dirs => ['/proc/self/fd', '/dev/fd'],
);

my $PEER = pack_sockaddr_in(514, inet_aton($CONFIG{peer_ip}));
my $dir = tempdir(CLEANUP => 1);
my $serial = 0;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub verbose_diag { diag(@_) if($ENV{TEST_VERBOSE}); return }

sub new_path { return File::Spec->catfile($dir, 'tx' . ++$serial . '.csv') }

sub slurp { my $file = shift; open(my $fh, '<:raw', $file) or die "$file: $!"; local $/; return scalar(<$fh>) }

sub read_csv {
	my $file = shift;
	my $csv = Text::CSV->new({ binary => 1, decode_utf8 => 0 });
	open(my $fh, '<:raw', $file) or die "$file: $!";
	my $rows = $csv->getline_all($fh);
	close($fh);
	return $rows;
}

# The messages column of a log, header excluded
sub messages_in { my $rows = read_csv(shift); return [map { $_->[3] } @{$rows}[1 .. $#{$rows}]] }

# The file is a well-formed log: the header first, every line complete
sub well_formed {
	my ($file, $name) = @_;
	my $content = slurp($file);
	like($content, qr/\A\Q$CONFIG{header_line}\E/, "$name: starts with the header");
	like($content, qr/\n\z/, "$name: ends with a complete line");
	return;
}

# How many descriptors are open, where the system can say
my ($FD_DIR) = grep { opendir(my $dh, $_) } @{$CONFIG{fd_dirs}};
sub open_fds {
	return undef unless($FD_DIR);
	opendir(my $dh, $FD_DIR) or return undef;
	return scalar(grep { /\A\d+\z/ } readdir($dh));
}
sub fds_back_to {
	my ($before, $name) = @_;
	SKIP: {
		skip('this system does not list open descriptors', 1) unless(defined($before));
		is(open_fds(), $before, "$name: no descriptor left open");
	}
	return;
}

# A resolver double: the address, then a name (or a failure)
sub mock_resolver {
	my $name = shift;
	return mock_scoped('App::Syslogd::getnameinfo' => sub {
		my (undef, $flags) = @_;
		return ('', $CONFIG{peer_ip}) if($flags & Socket::NI_NUMERICHOST());
		return defined($name) ? ('', $name) : ('Temporary failure in name resolution', undef);
	});
}

# A socket double that runs scripted steps
{
	package TxSocket;
	sub new { my ($class, @steps) = @_; return bless { steps => [@steps], closed => 0 }, $class }
	sub recv { my $self = $_[0]; my $step = shift(@{$self->{steps}}) or die "TxSocket: no steps left\n"; return $step->(\$_[1]) }
	sub sockport { return 1 }
	sub sockhost { return '127.0.0.1' }
	sub close { $_[0]{closed}++; return 1 }
}

# ===========================================================================
# Record: parse -> resolve -> CSV -> append -> count
# ===========================================================================

subtest 'record: the complete transaction' => sub {
	# Create -> process -> complete: one datagram becomes one row, the
	# name is cached for the next one, and the count moves by one each time
	my $g = mock_resolver($CONFIG{peer_name});
	my $file = new_path();
	my $cache = App::Syslogd::Cache->new();
	my $server = App::Syslogd->new(file => $file, cache => $cache)->reopen_log();

	returns_ok($server->process('<34>first', $PEER), { type => 'object', isa => 'App::Syslogd' }, 'process() completes');
	is_deeply(read_csv($file)->[1], [$CONFIG{peer_name}, 4, 2, 'first'], 'the row holds every step: name, PRI split, message');
	is($server->count(), 1, 'counted');
	ok($cache->{entries}{$CONFIG{peer_ip}}, 'the name is in the cache');

	$server->process('<34>second', $PEER);
	is_deeply(messages_in($file), ['first', 'second'], 'the next transaction appends after it');
	is($server->count(), 2, 'counted again');
	well_formed($file, 'after two records');
};

subtest 'record: failures half way leave the file consistent' => sub {
	# Break each step in turn.  Whatever fails, the file keeps only whole
	# rows, a failed row leaves no trace, and the next record works.
	my $file = new_path();
	my $server = App::Syslogd->new(file => $file, cache => App::Syslogd::Cache->new())->reopen_log();
	my $before = open_fds();
	my @expected;

	# Step 2, resolve: the resolver times out -> the address is used
	{
		my $g = mock_resolver(undef);
		$server->process('<13>resolver down', $PEER);
		push @expected, 'resolver down';
		is(read_csv($file)->[-1][0], $CONFIG{peer_ip}, 'resolver failure: the row is written with the address');
	}
	# Step 2, resolve: the cache itself dies -> the address is used
	{
		my $dying = bless {}, 'TxDyingCache';
		{ no strict 'refs'; *{'TxDyingCache::compute'} = sub { die "cache down\n" } }
		my $g = mock_resolver($CONFIG{peer_name});
		local $server->{cache} = $dying;
		$server->process('<13>cache down', $PEER);
		push @expected, 'cache down';
		is(read_csv($file)->[-1][0], $CONFIG{peer_ip}, 'cache failure: the row is written with the address');
	}
	# Step 3, the CSV line: refused -> nothing written
	{
		my $g = mock_scoped('Text::CSV::combine' => sub { 0 }, 'Text::CSV::error_diag' => sub { 'refused' });
		local $SIG{__WARN__} = sub { };
		$server->process('<13>csv refused', $PEER);
	}
	# Step 4, append: the disk is full -> nothing written
	{
		local $SYSWRITE = 'full';
		local $SIG{__WARN__} = sub { };
		$server->process('<13>disk full', $PEER);
	}
	# Step 4, append: the disk fills half way -> the half line is removed
	{
		local $SYSWRITE = 'half';
		local $SIG{__WARN__} = sub { };
		$server->process('<13>' . ('h' x 200), $PEER);
	}
	# And the transaction after the failures completes normally
	$server->process('<13>recovered', $PEER);
	push @expected, 'recovered';

	is_deeply(messages_in($file), \@expected, 'only the completed records are in the file, in order');
	well_formed($file, 'after the failures');
	is($server->count(), 6, 'count: every datagram long enough to record (documented: failed writes are counted)');
	fds_back_to($before, 'failed records');
};

# ===========================================================================
# Open log: close -> open -> checks -> header check -> chmod -> header
# ===========================================================================

subtest 'open log: the complete transaction, and repeating it' => sub {
	# A new file: created private with one header.  Reopening it again
	# and again changes nothing (idempotent): still one header.
	my $file = new_path();
	my $server = App::Syslogd->new(file => $file, resolve => 0);
	returns_ok($server->reopen_log(), { type => 'object', isa => 'App::Syslogd' }, 'reopen_log() completes');
	is(slurp($file), $CONFIG{header_line}, 'created with the header');
	SKIP: {
		skip('no Unix permission bits on Windows', 1) if($^O eq 'MSWin32');
		is((stat $file)[2] & 07777, $CONFIG{private_mode}, 'private');
	}
	$server->process('<13>row', $PEER);
	$server->reopen_log() foreach(1 .. $CONFIG{repeats});
	is(slurp($file), $CONFIG{header_line} . qq{"$CONFIG{peer_ip}","1","5","row"\n}, 'repeated reopening: still one header, rows kept');
};

subtest 'open log: refused files are rolled back completely' => sub {
	# A file that is not ours to use must come out exactly as it went in
	# (content and permissions), and no handle may stay open
	plan(skip_all => 'needs Unix permission bits') if($^O eq 'MSWin32');
	my $before = open_fds();

	my $foreign = new_path();
	open(my $out, '>', $foreign) or die;
	print {$out} "someone else's data\n";
	close($out);
	chmod($CONFIG{foreign_mode}, $foreign);
	throws_ok { App::Syslogd->new(file => $foreign)->reopen_log() } qr/\ARefusing to log to /, 'a file that is not a log: refused';
	is(slurp($foreign), "someone else's data\n", '...content untouched');
	is((stat $foreign)[2] & 07777, $CONFIG{foreign_mode}, '...permissions untouched (the chmod comes after the check)');

	SKIP: {
		my $target = new_path();
		open(my $t, '>', $target) or die;
		close($t);
		chmod($CONFIG{foreign_mode}, $target);
		my $hard = new_path();
		skip("cannot make a hard link: $!", 2) unless(eval { link($target, $hard) });
		skip('this system does not report link counts', 2) unless((stat $hard)[3] == 2);
		throws_ok { App::Syslogd->new(file => $hard)->reopen_log() } qr/\ARefusing to log to /, 'a hard link: refused';
		is((stat $target)[2] & 07777, $CONFIG{foreign_mode}, '...permissions untouched');
	}
	fds_back_to($before, 'refused opens');
};

subtest 'open log: a header that cannot be written, then a retry' => sub {
	# The disk fills while the header of a new file is written (all of
	# it, or half).  The open fails, no handle stays open, the file is
	# left empty (not half a header), and the retry writes the header
	# exactly once.
	my $before = open_fds();
	foreach my $mode ('full', 'half') {
		my $file = new_path();
		{
			local $SYSWRITE = $mode;
			throws_ok { App::Syslogd->new(file => $file)->reopen_log() } qr/\ACould not write to log file /, "$mode: the open fails";
		}
		is(slurp($file), '', "$mode: the file is left empty, not half written");
		my $server = App::Syslogd->new(file => $file, resolve => 0);
		lives_ok { $server->reopen_log() } "$mode: the retry succeeds";
		$server->process('<13>after retry', $PEER);
		is(slurp($file), $CONFIG{header_line} . qq{"$CONFIG{peer_ip}","1","5","after retry"\n}, "$mode: one header, then the row");
	}
	fds_back_to($before, 'failed header writes');
};

# ===========================================================================
# Rotation: rename -> SIGHUP -> close -> open
# ===========================================================================

subtest 'rotation: complete, failed half way, and retried' => sub {
	# Rotate twice successfully, then make the third rotation fail (the
	# directory is gone): the old log is closed, nothing is half written,
	# and once the directory is back the next rotation works.
	plan(skip_all => 'Windows cannot rename an open file') if($^O eq 'MSWin32');
	my $logdir = File::Spec->catdir($dir, 'rotating' . ++$serial);
	mkdir($logdir) or die;
	my $file = File::Spec->catfile($logdir, 'log.csv');
	my $server = App::Syslogd->new(file => $file, resolve => 0)->reopen_log();
	my $before = open_fds();

	foreach my $generation (1 .. 2) {
		$server->process("<13>generation $generation", $PEER);
		rename($file, "$file.$generation") or die;
		$server->reopen_log();	# what SIGHUP does inside run()
	}
	$server->process('<13>generation 3', $PEER);
	is_deeply([map { messages_in("$file.$_") } 1, 2], [['generation 1'], ['generation 2']], 'each rotated file holds its own rows');
	is_deeply(messages_in($file), ['generation 3'], 'the live file starts afresh');

	# The rotation fails half way: closed the old file, cannot open the new
	rename($file, "$file.3") or die;
	rename($logdir, "$logdir.moved") or die;
	throws_ok { $server->reopen_log() } qr/\ACould not open log file /, 'the failed rotation reports the error';
	throws_ok { $server->process('<13>lost', $PEER) } qr/\Aprocess\(\) was called before reopen_log\(\) succeeded/,
		'no stale handle: writing is refused, not sent to the old file';
	rename("$logdir.moved", $logdir) or die;
	is_deeply(messages_in("$file.3"), ['generation 3'], 'the rotated file was not touched by the failure');

	lives_ok { $server->reopen_log() } 'the retry succeeds';
	$server->process('<13>generation 4', $PEER);
	is_deeply(messages_in($file), ['generation 4'], 'and logging resumes in a new file');
	fds_back_to($before, 'rotations');
};

# ===========================================================================
# Server: bind -> open log -> loop -> shut down
# ===========================================================================

subtest 'server: the complete lifecycle, run twice' => sub {
	# Bind, open, receive, stop, shut down; then the same again with the
	# same object.  The second run reopens everything, keeps one header
	# and carries the count on.
	my $file = new_path();
	my $server;
	my $created = 0;
	my $g = mock_scoped('IO::Socket::IP::new' => sub {
		$created++;
		return TxSocket->new(sub { ${$_[0]} = "<13>run $created"; return $PEER }, sub { $server->stop(); $! = EINTR; return undef });
	});
	$server = App::Syslogd->new(file => $file, resolve => 0, port => $CONFIG{any_port});
	my $before = open_fds();
	foreach my $run (1, 2) {
		returns_ok($server->run(), { type => 'object', isa => 'App::Syslogd' }, "run $run completes");
		ok(!$server->{socket} && !$server->{fh}, "run $run: socket and log released at the end");
	}
	is($created, 2, 'each run bound its own socket');
	is_deeply(messages_in($file), ['run 1', 'run 2'], 'one header, rows from both runs');
	is($server->count(), 2, 'the count carried on');
	fds_back_to($before, 'two runs');
};

subtest 'server: a start that fails half way is rolled back' => sub {
	# run() binds the socket, then cannot open the log.  The socket it
	# opened must be released (the port is free again); a socket the
	# caller provided must be left alone.  Then the start is retried.
	my $logdir = File::Spec->catdir($dir, 'later' . ++$serial);
	my $file = File::Spec->catfile($logdir, 'log.csv');
	my $before = open_fds();

	my $server = App::Syslogd->new(address => $CONFIG{loopback}, port => $CONFIG{any_port}, file => $file, resolve => 0);
	throws_ok { $server->run() } qr/\ACould not open log file /, 'run() dies: the log cannot be opened';
	ok(!$server->{socket}, 'the socket run() opened is released');
	ok(!$server->{fh}, 'no log is open');
	fds_back_to($before, 'failed start');

	my $given = TxSocket->new();
	my $with_socket = App::Syslogd->new(file => $file, resolve => 0, socket => $given);
	throws_ok { $with_socket->run() } qr/\ACould not open log file /, 'with a socket from the caller: dies the same way';
	is($with_socket->{socket}, $given, "the caller's socket is left open");
	is($given->{closed}, 0, '...and not closed');

	# Fix the cause and start again
	mkdir($logdir) or die;
	$with_socket->{socket} = TxSocket->new(sub { ${$_[0]} = '<13>started'; return $PEER }, sub { $with_socket->stop(); $! = EINTR; return undef });
	lives_ok { $with_socket->run() } 'the retried start succeeds';
	is_deeply(messages_in($file), ['started'], 'and records');
};

# ===========================================================================
# Cache: look up -> compute -> evict -> store
# ===========================================================================

subtest 'cache: a failed fill stores nothing and evicts nothing' => sub {
	# The cache is full.  A lookup whose computation dies must not push
	# anything out (eviction happens only after a successful compute),
	# and the same lookup retried fills it normally.
	my $cache = App::Syslogd::Cache->new(max_bytes => 2 * (length('a') + length('v') + 64));
	$cache->compute($_, $CONFIG{ttl}, sub { 'v' }) foreach(qw(a b));
	my %snapshot = map { $_ => [@{$cache->{entries}{$_}}] } keys %{$cache->{entries}};
	my $bytes = $cache->{bytes};

	throws_ok { $cache->compute('c', $CONFIG{ttl}, sub { die "lookup failed\n" }) } qr/\Alookup failed\n\z/, 'the failure is passed on';
	is_deeply({ map { $_ => [@{$cache->{entries}{$_}}] } keys %{$cache->{entries}} }, \%snapshot, 'no entry was evicted or added');
	is($cache->{bytes}, $bytes, 'the size count is unchanged');

	is($cache->compute('c', $CONFIG{ttl}, sub { 'v' }), 'v', 'the retry succeeds');
	is_deeply([sort keys %{$cache->{entries}}], [qw(b c)], '...evicting the oldest only now');

	# Repeating a completed fill returns the stored value (idempotent)
	my $calls = 0;
	$cache->compute('c', $CONFIG{ttl}, sub { $calls++; 'other' }) foreach(1 .. $CONFIG{repeats});
	is($calls, 0, 'repeated lookups do not compute again');
};

# ===========================================================================
# Idempotency of the setup steps
# ===========================================================================

subtest 'idempotency: repeating setup steps changes nothing' => sub {
	# open_socket, reopen_log and stop may be repeated; datagrams are not
	# idempotent by design (two identical messages are two events)
	my $file = new_path();
	my $created = 0;
	my $g = mock_scoped('IO::Socket::IP::new' => sub { $created++; return TxSocket->new() });
	my $server = App::Syslogd->new(file => $file, resolve => 0);
	$server->open_socket() foreach(1 .. $CONFIG{repeats});
	is($created, 1, 'open_socket() repeated: one socket');
	$server->reopen_log() foreach(1 .. $CONFIG{repeats});
	is(slurp($file), $CONFIG{header_line}, 'reopen_log() repeated: one header');
	$server->stop() foreach(1 .. $CONFIG{repeats});
	ok(!$server->{running}, 'stop() repeated: still stopped');

	$server->process('<13>same', $PEER) foreach(1 .. 2);
	is_deeply(messages_in($file), ['same', 'same'], 'the same datagram twice is two events, both recorded');
};

done_testing();
