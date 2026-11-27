#!/usr/bin/env perl

# Data-flow tests: follow each value and each handle from where it is defined,
# through where it is used, to where it is destroyed.
#
#   values   a caller's arguments, constructor list, results, secrets and
#            options: not changed, not shared, not silently thrown away
#   handles  token files, sockets, lock files, logs: closed on success and on
#            every failure, with permissions revoked part way where possible
#   races    something else changes a file between the check and the use
#
# The races are made to happen deterministically: mkdir and sysopen are
# wrapped before the code is compiled, so a test can act at that exact moment.
#
# Set TEST_VERBOSE=1 to see the state the subtests print with diag.

use strict;
use warnings;

# Set by a subtest to interfere just before the real call runs.
our %HOOK;

BEGIN {
	*CORE::GLOBAL::mkdir = sub (_;$) {
		$main::HOOK{mkdir}->($_[0]) if $main::HOOK{mkdir};
		return @_ > 1 ? CORE::mkdir($_[0], $_[1]) : CORE::mkdir($_[0]);
	};
	*CORE::GLOBAL::sysopen = sub (*$$;$) {
		$main::HOOK{sysopen}->($_[1]) if $main::HOOK{sysopen};
		return CORE::sysopen($_[0], $_[1], $_[2], @_ > 3 ? $_[3] : 0666);
	};
}

use Test::Most;
use Test::Needs;

BEGIN {
	test_needs 'Test::Mockingbird', 'Test::Returns', 'Test::Permissions';

	require Class::Shared;
	plan skip_all => 'a backend needs unix sockets in an owner-only directory, which this perl cannot provide'
		unless Class::Shared::_has_unix_sockets() && Test::Permissions::can_revoke_create();

	Test::Mockingbird->import;
	Test::Returns->import;
	Test::Permissions->import(qw(:revoke :guard :report));
}

use Fcntl qw(:flock O_RDWR O_CREAT);
use File::Spec ();
use File::Temp qw(tempdir);
use IO::Socket::UNIX ();
use POSIX ();
use Socket qw(SOCK_STREAM);
use Storable ();

use lib 'lib', 't/lib';
use Class::Shared::Backend ();
use Class::Shared::Frontend ();
use Class::Shared::Protocol ();
use Shared::Reaper ();

my %config = (
	class        => 'Shared::Counter',
	secret       => 's3cret',
	start_wait   => 15,
	quick        => 8,
	busy_seconds => 5,        # how long a call keeps a backend busy
	short        => 1,        # a frontend timeout shorter than that
	repeats      => 50,       # enough failures to show a leaked handle
	watchdog     => 240,
);

my $VERBOSE = $ENV{TEST_VERBOSE};

$SIG{ALRM} = sub { BAIL_OUT("t/data-flow.t ran for more than $config{watchdog} seconds") };
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

sub write_file {
	my ($path, $text) = @_;
	open(my $fh, '>:raw', $path) or die "$path: $!";
	print {$fh} $text;
	close($fh);
	return $path;
}

sub slurp {
	my ($path) = @_;
	open(my $fh, '<', $path) or return '';
	local $/;
	my $text = <$fh>;
	close($fh);
	return defined $text ? $text : '';
}

# How many descriptors this process holds; undef where that cannot be seen.
sub open_handles {
	return undef unless -d "/proc/$$/fd";
	my @fds = glob("/proc/$$/fd/*");
	return scalar @fds;
}

# True if nobody holds a lock on $path.
sub lock_is_free {
	my ($path) = @_;
	CORE::sysopen(my $fh, $path, O_RDWR | O_CREAT, 0600) or die "$path: $!";
	my $free = flock($fh, LOCK_EX | LOCK_NB) ? 1 : 0;
	close($fh);
	return $free;
}

my $reaper = Shared::Reaper->new(File::Spec->catfile(private_dir(), 'pids'));
my $test_pid = $$;
my @children;

END {
	local $?;
	if (defined $test_pid && $$ == $test_pid) {
		kill 'KILL', @children if @children;
		waitpid($_, 0) for @children;
		$reaper->dismiss if $reaper;
	}
}

sub start_backend {
	my (%option) = @_;
	my $dir = private_dir();
	my $b = { dir => $dir, socket => File::Spec->catfile($dir, 'class-shared.sock') };
	$b->{log} = "$b->{socket}.log";

	my $pid = fork() // die "fork: $!";
	if (!$pid) {
		eval { Class::Shared::Backend->new(socket => $b->{socket}, log => $b->{log}, %option)->run };
		POSIX::_exit(0);
	}
	push @children, $reaper->add($pid);
	$b->{pid} = $pid;

	my $until = time + $config{start_wait};
	select(undef, undef, undef, 0.05) until -S $b->{socket} || time > $until;
	BAIL_OUT('no backend: ' . slurp($b->{log})) unless -S $b->{socket};

	return $b;
}

sub frontend {
	my ($b, %option) = @_;
	return Class::Shared::Frontend->new($config{class}, socket => $b->{socket}, autostart => 0, %option);
}

# ===========================================================================
# Values
# ===========================================================================

# define: the caller builds a structure.  use: it crosses to the backend and
# back.  The caller's copy must be as it was, and what comes back must be a
# copy that the object does not share.
subtest 'a caller\'s data is copied, not changed or shared' => sub {
	my $b = start_backend();
	my @ctor = (start => 5, tag => { list => [1, 2] });
	my $ctor_before = Storable::dclone(\@ctor);
	my $f = frontend($b, ctor => \@ctor);
	is_deeply(\@ctor, $ctor_before, 'the constructor list is not changed');

	my $tag = $f->tag;
	push @{ $tag->{list} }, 99;
	is_deeply($f->tag, { list => [1, 2] }, 'changing a result does not change the object');

	my @args = ([1, 2], { k => 'v' });
	my $args_before = Storable::dclone(\@args);
	my @echo = $f->echo_list(@args);
	is_deeply(\@args, $args_before, 'the arguments are not changed');
	is_deeply(\@echo, $args_before, 'and arrive whole');
	isnt($echo[0], $args[0], 'as a copy');
	returns_ok($f->shared_status, { type => 'hashref' }, 'status is a hash reference');

	# The globals a data transformation might borrow.
	local $_ = 'topic';
	local $@ = 'error';
	$f->echo_list('x');
	$f->can('inc');
	$f->isa('Shared::Counter');
	is($_, 'topic', '$_ is not changed by calls');
	is($@, 'error', 'nor $@');
	$f->shared_close;
};

subtest 'a message is defined, framed, consumed and gone' => sub {
	my $message = { op => 'x', data => [ { deep => 'value' } ] };
	my $before = Storable::dclone($message);

	foreach my $secret (undef, $config{secret}) {
		my ($bytes) = Class::Shared::Protocol::encode_frame($message, $secret);
		is_deeply($message, $before, 'framing does not change the message');

		my $buffer = $bytes . 'next';
		my (undef, $back) = Class::Shared::Protocol::take_frame(\$buffer, $secret);
		is_deeply($back, $before, 'the same data comes out');
		is($buffer, 'next', 'the frame is consumed, and only the frame');
	}

	my %options = (cert => 'c', key => 'k', ca => 'a');
	my %copy = %options;
	subtest 'with IO::Socket::SSL' => sub {
		test_needs 'IO::Socket::SSL';
		Class::Shared::client_tls_options(%options);
		is_deeply(\%options, \%copy, 'TLS option building does not change its input');
	};
};

# A value the caller defined must be the value that is used, even when it is
# false in Perl.
subtest 'options the caller gives are used, not replaced' => sub {
	my $dir = private_dir();
	my $path = File::Spec->catfile($dir, 's.sock');
	my $listen = IO::Socket::UNIX->new(Type => SOCK_STREAM, Local => $path, Listen => 4) or die;

	my %seen;
	mock('Class::Shared::Frontend::_connect' => sub { %seen = %{ $_[0] }; return $_[0] });

	Class::Shared::Frontend->new($config{class}, socket => $path, log => '0');
	is($seen{log}, '0', 'a log file called "0" is kept');

	Class::Shared::Frontend->new($config{class}, socket => '0', log => 'l');
	is($seen{socket_path}, '0', 'a socket called "0" is kept');

	Class::Shared::Frontend->new($config{class}, socket => $path);
	is($seen{log}, "$path.log", 'with no log given it is the socket path with .log');

	# A TCP frontend never starts a backend, so it has no use for a unix path,
	# and must not fail because one could not be worked out.
	local $ENV{CLASS_SHARED_DIR} = '/' . ('x' x 120);
	lives_ok {
		Class::Shared::Frontend->new($config{class}, host => 'h', port => 1, tls_cert => 'c', tls_key => 'k', tls_ca => 'a', token => 't');
	} 'a TCP frontend does not depend on the unix directory';
	restore_all();
};

# ===========================================================================
# Handles: open, use, close
# ===========================================================================

subtest 'a token file is closed on success and on every failure' => sub {
	plan skip_all => 'open handles cannot be counted here' unless defined open_handles();

	my $dir = private_dir();
	my $good = write_file(File::Spec->catfile($dir, 'good'), "$config{secret}\n");
	my $empty = write_file(File::Spec->catfile($dir, 'empty'), '');
	my $big = write_file(File::Spec->catfile($dir, 'big'), 'x' x ($Class::Shared::MAX_SECRET + 1));

	my $before = open_handles();
	for (1 .. $config{repeats}) {
		Class::Shared::read_secret($good);
		eval { Class::Shared::read_secret($_) } for $empty, $big, $dir, "$dir/missing";
	}
	is(open_handles(), $before, 'no handle is left open');

	SKIP: {
		skip 'a file cannot be made unreadable here', 1 unless can_revoke_read($dir);
		with_revoked(read => $good, sub {
			eval { Class::Shared::read_secret($good) } for 1 .. $config{repeats};
		});
		is(open_handles(), $before, 'nor when access is refused (EACCES)');
	}
};

subtest 'a frontend that fails leaves no socket or lock behind' => sub {
	my $dir = private_dir();
	my $path = File::Spec->catfile($dir, 'class-shared.sock');
	my $listen = IO::Socket::UNIX->new(Type => SOCK_STREAM, Local => $path, Listen => 128) or die;
	my $before = open_handles();

	# The write fails with a permission error after the socket is open.
	mock('Class::Shared::Protocol::write_all' => sub { return (0, 'write failed: Operation not permitted') });
	for (1 .. $config{repeats}) {
		eval { Class::Shared::Frontend->new($config{class}, socket => $path, autostart => 0) };
		$listen->accept;
	}
	like($@, qr/handshake failed: write failed: Operation not permitted/, 'EPERM is reported');
	is(open_handles(), $before, 'and the sockets are closed') if defined $before;
	restore_all();

	# The directory stops accepting new files before the start lock is made.
	SKIP: {
		my $locked = private_dir();
		skip 'a directory cannot refuse new files here', 3 unless can_revoke_create($locked);
		with_revoked(create => $locked, sub {
			throws_ok { Class::Shared::Frontend->new($config{class}, dir => $locked) }
				qr/could not start a backend: cannot open \Q$locked\E\/class-shared\.sock\.spawn: Permission denied/,
				'the start lock cannot be made: a clear failure';
			my $count = open_handles();
			eval { Class::Shared::Frontend->new($config{class}, dir => $locked) } for 1 .. 5;
			is(open_handles(), $count, 'and nothing is left open') if defined $count;
		});
		ok(!-e File::Spec->catfile($locked, 'class-shared.sock'), 'no socket was made');
	}
};

# One secret, one definition: two would leave one of them silently unused.
subtest 'token and token_file together are refused' => sub {
	my $file = write_file(File::Spec->catfile(private_dir(), 'token'), "$config{secret}\n");
	my @tcp = (host => 'h', port => 1, tls_cert => 'c', tls_key => 'k', tls_ca => 'a');

	my $read = 0;
	mock('Class::Shared::read_secret' => sub { $read++; return $config{secret} });
	throws_ok { Class::Shared::Frontend->new($config{class}, @tcp, token => $config{secret}, token_file => $file) }
		qr/\AClass::Shared::Frontend->new: give token or token_file, not both\n\z/, 'refused';
	is($read, 0, 'before the file is read');
	restore_all();
};

# define: the connection.  use: a call.  kill: close.  Every field that came
# from the connection must be gone, and so must the object in the backend.
subtest 'a frontend\'s connection is defined, used and destroyed' => sub {
	my $b = start_backend();
	my $watch = frontend($b);

	my $f = frontend($b);
	ok($f->shared_pid && $f->shared_id && $f->shared_connected, 'defined on connect');
	is($f->inc, 1, 'used');
	$f->shared_close;
	is_deeply([$f->shared_pid, $f->shared_id, $f->shared_connected], [undef, undef, 0], 'killed on close');
	throws_ok { $f->inc } qr/its object is gone/, 'and cannot be used afterwards';

	{
		my $scoped = frontend($b);
		is($watch->shared_status->{objects}, 2, 'an object in scope');
	}
	my $until = time + $config{quick};
	select(undef, undef, undef, 0.05) while $watch->shared_status->{objects} > 1 && time < $until;
	is($watch->shared_status->{objects}, 1, 'leaving the scope destroys it in the backend');
};

# A start that fails must give back what it took, even if the caller keeps the
# backend object.
subtest 'a failed backend start releases its lock and socket' => sub {
	my $dir = private_dir();
	my $socket = File::Spec->catfile($dir, 'b.sock');
	write_file($socket, 'not a socket');

	my $failed = Class::Shared::Backend->new(socket => $socket, log => "$socket.log");
	throws_ok { $failed->run } qr/exists and is not a socket/, 'the start fails';
	ok(lock_is_free("$socket.owner"), 'the lock is released although the object lives');

	# The socket is made, then cannot be given its permissions.
	unlink $socket;
	my $other = Class::Shared::Backend->new(socket => $socket, log => "$socket.log");
	mock('Class::Shared::Backend::_setup_unix' => sub {
		my $self = shift;
		$self->{listener} = IO::Socket::UNIX->new(Type => SOCK_STREAM, Local => $self->{socket}, Listen => 1) or die;
		$self->{owns_socket} = 1;
		die "cannot set permissions on $self->{socket}: Operation not permitted\n";
	});
	throws_ok { $other->run } qr/Operation not permitted/, 'EPERM part way through the start';
	restore_all();
	ok(!-e $socket, 'the half-made socket is removed');
	ok(lock_is_free("$socket.owner"), 'and the lock released');
	is($other->{listener}, undef, 'and the listener closed');

	# The one that loses the race for the lock must not touch the winner's files.
	my $b = start_backend();
	my $second = Class::Shared::Backend->new(socket => $b->{socket}, log => $b->{log}, start_timeout => 0);
	throws_ok { $second->run } qr/\Aanother backend is already serving/, 'flock is enforced';
	ok(-S $b->{socket} && -e "$b->{socket}.pid", 'the winner keeps its socket and pid file');
	ok(!lock_is_free("$b->{socket}.owner"), 'and its lock');
};

# define: the token.  An empty one is "none", and must not become a key.
subtest 'an empty token given to a unix backend is no token' => sub {
	my $b = start_backend(token => '');
	my $f = eval { frontend($b, timeout => $config{quick}) };
	is($@, '', 'a frontend with no token connects');
	is($f->inc, 1, 'and calls') if $f;
};

# The log is opened, written, trimmed.  Permission can go away in between.
subtest 'a log that stops being writable does not stop the backend' => sub {
	my $b = start_backend(max_log_size => 200);
	my $f = frontend($b);

	SKIP: {
		skip 'a file cannot be made unwritable here', 2 unless can_revoke_write($b->{dir});
		with_revoked(write => $b->{log}, sub {
			for (1 .. 5) { frontend($b)->shared_close }
			is($f->inc, 1, 'the backend serves while its log cannot be written');
		});
		is(kill(0, $b->{pid}), 1, 'and is still running');
	}
};

# ===========================================================================
# Races: the world changes between the check and the use
# ===========================================================================

# A backend busy with another client's method answers late.  Late is not dead:
# its socket must not be taken for a leftover and removed, or every client
# would lose it and its objects.
subtest 'a busy backend is not mistaken for a stale socket' => sub {
	my $b = start_backend();
	my $holder = frontend($b);
	my $inode = (stat $b->{socket})[1];

	my $hog = fork() // die;
	if (!$hog) {
		eval { $holder->sleepy($config{busy_seconds}) };
		POSIX::_exit(0);
	}
	push @children, $hog;
	select(undef, undef, undef, 0.5);

	# autostart is on, which is the default.
	throws_ok {
		Class::Shared::Frontend->new($config{class}, socket => $b->{socket}, timeout => $config{short});
	} qr/\AClass::Shared: could not start a backend: a backend is running at \Q$b->{socket}\E but did not answer: .*busy/,
		'the new client is told that the backend is there but busy';

	waitpid($hog, 0);
	ok(-S $b->{socket}, 'the socket is still there');
	is((stat $b->{socket})[1], $inode, 'and is the same one');
	is(frontend($b)->shared_status->{pid}, $b->{pid}, 'new clients still reach the same backend');
};

# Check, then use: the socket goes between the two.
subtest 'a socket removed just before the connect fails cleanly' => sub {
	my $b = start_backend();
	my $before = open_handles();

	mock('Class::Shared::_check_endpoint' => sub { unlink $b->{socket}; return (1, undef) });
	throws_ok { frontend($b) } qr/\AClass::Shared: cannot reach a backend at \Q$b->{socket}\E: cannot connect to .*No such file/,
		'the failure names what happened';
	restore_all();
	is(open_handles(), $before, 'and no socket is left open') if defined $before;
};

# Two clients make the same directory at once: losing is not a failure.
subtest 'another process creates the directory first' => sub {
	my $dir = File::Spec->catdir(private_dir(), 'new');

	local $HOOK{mkdir} = sub { CORE::mkdir($dir, 0700) if $_[0] eq $dir };
	is_deeply([Class::Shared::ensure_dir($dir)], [1, undef], 'the directory the other made is used');

	# But what the other made is still checked.
	my $unsafe = File::Spec->catdir(private_dir(), 'new');
	local $HOOK{mkdir} = sub { CORE::mkdir($unsafe); chmod 0777, $unsafe };
	my ($ok, $why) = Class::Shared::ensure_dir($unsafe);
	is($ok, 0, 'a directory made unsafe by someone else is refused');
	like($why, qr/writable by group or others/, 'with the reason');
};

# The log is looked at, then trimmed.  If it is swapped for a link in between,
# the file the link points at must not be emptied.
subtest 'a log swapped for a link while it is trimmed' => sub {
	my $dir = private_dir();
	my $victim = write_file(File::Spec->catfile($dir, 'victim'), 'precious' x 100);
	my $log = write_file(File::Spec->catfile($dir, 'log'), 'line' x 100);
	my $backend = Class::Shared::Backend->new(socket => File::Spec->catfile($dir, 's'), log => $log, max_log_size => 10);

	my $swapped = 0;
	{
		local $HOOK{sysopen} = sub {
			return unless $_[0] eq "$log.1" && !$swapped++;
			rename $log, "$log.moved" or die;
			symlink($victim, $log) or die;
		};
		$backend->_trim_log;
	}
	ok($swapped, 'the swap happened during the trim');
	is(-s $victim, 800, 'the file the link points to is untouched');
};

alarm 0;
done_testing();
