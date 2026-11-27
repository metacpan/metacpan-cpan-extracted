#!/usr/bin/env perl

# White-box tests of every function in lib/, including the private helpers,
# taken one module at a time.  What is tested is what the POD and the comments
# above each function say it does, not what it happens to do today.
#
# Most subtests here try to break something: a hostile argument, a peer that
# misbehaves half way through, a limit pushed past its edge, a dependency that
# fails.  Functions that call each other are tested with the callee mocked, so
# a failure points at the function under test and not at one it relies on.
#
# Set TEST_VERBOSE=1 to see the internal state the subtests print with diag.
# Set FUNCTION_ONLY to a pattern to run only the subtests whose name matches it,
# for example FUNCTION_ONLY=_loop prove -l t/function.t

use strict;
use warnings;

use Test::Most;

# Much of this file needs what only a Unix-like system has.  Windows perls can
# say they have unix sockets, so the directory is asked about as well.
BEGIN {
	require Test::Needs;
	Test::Needs::test_needs('Test::Permissions');
	require Class::Shared;

	plan skip_all => 'a backend needs unix sockets in an owner-only directory, '
		. 'which this perl cannot provide (Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();
}
use Test::Needs;

BEGIN {
	# These are test-only tools that the distribution does not otherwise
	# need, so their absence skips this file instead of failing an install.
	test_needs 'Test::Mockingbird', 'Test::Returns', 'Test::Memory::Cycle';

	Test::Mockingbird->import;
	Test::Returns->import;
	Test::Memory::Cycle->import;
}

# Lets one function be tested alone while it is being worked on.
if (defined $ENV{FUNCTION_ONLY} && length $ENV{FUNCTION_ONLY}) {
	my $real_subtest = \&Test::More::subtest;
	no warnings 'redefine';
	*main::subtest = sub {
		my ($name, @rest) = @_;
		return 1 unless $name =~ /$ENV{FUNCTION_ONLY}/;
		return $real_subtest->($name, @rest);
	};
}

use File::Spec ();
use File::Temp qw(tempdir);
use Socket qw(AF_UNIX SOCK_STREAM pack_sockaddr_un);
use Time::HiRes ();

use lib 'lib';
use Class::Shared ();
use Class::Shared::Protocol ();
use Class::Shared::Frontend ();
use Class::Shared::Backend ();
use Cwd ();
use Fcntl ();
use IO::Handle ();
use IO::Socket::UNIX ();
use POSIX ();

# Every number and string the subtests depend on is named here, once.
my %config = (
	secret          => 'a shared secret',
	other_secret    => 'a different secret',
	digest_size     => 32,
	frame_header    => 4,
	socket_limit    => 100,
	long_name_parts => 40_000,        # past the 32766 repeat limit of perl 5.26
	poll_slack      => 0.01,          # the clock may run a little fast
	wait            => 0.2,           # a "timed out" case must not wait for long
	# RFC 4231, test case 2.
	hmac_key        => 'Jefe',
	hmac_data       => 'what do ya want for nothing?',
	hmac_hex        => '5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843',
	fingerprint     => 'AB' x 32,
);

my $VERBOSE = $ENV{TEST_VERBOSE};
my $IS_ROOT = $> == 0;

# Print internal state, but only when asked.
sub state_of {
	diag(@_) if $VERBOSE;
	return;
}

# A directory only this user can use, removed when the test ends.
sub private_dir {
	my $dir = tempdir(CLEANUP => 1);
	chmod 0700, $dir;
	return $dir;
}

# Run $code with $_ set to a marker, and say whether it was left alone.  A
# helper that modifies $_ without "local" would corrupt its caller's loop.
sub leaves_topic_alone {
	my ($code) = @_;

	my $marker = 'topic marker';
	local $_ = $marker;
	$code->();

	return defined $_ && $_ eq $marker;
}

# Make a unix socket that is listening at $path, and hand back the handle that
# keeps it alive.
sub listening_socket {
	my ($path) = @_;

	# A real IO::Socket::UNIX, because the backend calls ->accept on its listener.
	my $sock = IO::Socket::UNIX->new(Type => SOCK_STREAM, Local => $path, Listen => 16)
		or die "listen on $path: $!";

	return $sock;
}

# A handle whose writes and reads do what a subtest says, so that the half
# failures of a real socket can be reproduced exactly.
{
	package Test::ScriptedHandle;

	sub TIEHANDLE { my ($class, @steps) = @_; return bless { steps => [@steps], calls => 0 }, $class }

	sub WRITE {
		my ($self, $buffer, $length, $offset) = @_;
		$self->{calls}++;
		my $step = shift @{ $self->{steps} };
		$step = $length unless defined $step;
		if (ref $step eq 'ARRAY') {
			$! = $step->[0];
			return undef;
		}
		return $step > $length ? $length : $step;
	}
}

# A handle that claims to hold decrypted bytes the way an IO::Socket::SSL
# object can, so the "pending" branch of _read_exact can be driven.
{
	package Test::PendingHandle;

	our $PENDING_CALLS = 0;
	our $PENDING_ANSWER = 1;

	sub pending { $PENDING_CALLS++; return $PENDING_ANSWER }
}

# ===========================================================================
# Class::Shared
# ===========================================================================

# ---------------------------------------------------------------- validate_class
subtest 'Class::Shared::validate_class' => sub {
	my @good = ('Foo', 'Foo::Bar', '_Private', 'A1::b_2::C', 'a', 'X' x 500);
	foreach my $name (@good) {
		is(Class::Shared::validate_class($name), $name, 'accepts ' . substr($name, 0, 20));
	}

	returns_ok(Class::Shared::validate_class('Foo::Bar'), { type => 'string' },
		'returns a string');

	# Each of these is a way of smuggling something other than a class name
	# into "require": path separators, code, a second part with no name, ...
	my @bad = (
		'1Foo', 'Foo::', '::Foo', 'Foo:::Bar', 'Foo:Bar', 'Foo Bar', 'Foo-Bar',
		"Foo\n", "\nFoo", "Foo\0", 'Foo/Bar', '../Foo', 'Foo.pm', 'Foo;system',
		'Foo::1Bar', 'Foo::::Bar', ':', '::', "Caf\x{e9}", "Foo\x{660}",
		'Foo::Bar()', q{Foo'Bar}, '-e', ' Foo', 'Foo ',
	);
	foreach my $name (@bad) {
		throws_ok { Class::Shared::validate_class($name) }
			qr/\AClass::Shared: '.*' is not a valid class name\n\z/s,
			'refuses ' . join('', map { $_ lt ' ' || $_ gt '~' ? sprintf('\\x{%x}', ord) : $_ } split //, $name);
	}

	throws_ok { Class::Shared::validate_class(undef) }
		qr/\AClass::Shared: no class name given\n\z/, 'undef is refused';
	throws_ok { Class::Shared::validate_class('') }
		qr/\AClass::Shared: no class name given\n\z/, 'an empty name is refused';
	throws_ok { Class::Shared::validate_class([]) }
		qr/is not a valid class name/, 'a reference is not a name';

	# A long valid name must not hit the regex engine's repeat limit.
	my $long = join '::', ('Part') x $config{long_name_parts};
	lives_ok { Class::Shared::validate_class($long) } 'a name of many parts is accepted';

	# The returned text is a copy, so changing it cannot change the caller's.
	my $given = 'Foo::Bar';
	my $back = Class::Shared::validate_class($given);
	$back .= 'X';
	is($given, 'Foo::Bar', 'the argument is not altered through the result');

	ok(leaves_topic_alone(sub { Class::Shared::validate_class('Foo::Bar') }),
		'$_ is left alone');
};

# ------------------------------------------------------------------ read_secret
subtest 'Class::Shared::read_secret' => sub {
	my $dir = private_dir();

	my $write = sub {
		my ($name, $text) = @_;
		my $path = File::Spec->catfile($dir, $name);
		open(my $fh, '>', $path) or die "$path: $!";
		print {$fh} $text;
		close($fh) or die "$path: $!";
		return $path;
	};

	is(Class::Shared::read_secret($write->('plain', 'abc')), 'abc', 'a plain secret');
	is(Class::Shared::read_secret($write->('newline', "abc\n")), 'abc', 'the trailing new line goes');
	is(Class::Shared::read_secret($write->('crlf', "abc\r\n\t \n")), 'abc', 'all trailing white space goes');
	is(Class::Shared::read_secret($write->('lead', "  abc")), '  abc', 'leading white space is part of the secret');
	is(Class::Shared::read_secret($write->('inner', "a b\nc\n")), "a b\nc", 'inner white space is kept');

	returns_ok(Class::Shared::read_secret($write->('r', 'x')), { type => 'string', min => 1 },
		'returns a non-empty string');

	throws_ok { Class::Shared::read_secret($write->('empty', '')) }
		qr/\AClass::Shared: .*empty is empty\n\z/, 'an empty file is refused';
	throws_ok { Class::Shared::read_secret($write->('blank', " \n\t\n")) }
		qr/ is empty\n\z/, 'a file of only white space is refused';

	throws_ok { Class::Shared::read_secret(undef) }
		qr/\AClass::Shared: no token file given\n\z/, 'undef is refused';
	throws_ok { Class::Shared::read_secret('') }
		qr/\AClass::Shared: no token file given\n\z/, 'an empty name is refused';

	my $missing = File::Spec->catfile($dir, 'not-there');
	throws_ok { Class::Shared::read_secret($missing) }
		qr/\AClass::Shared: cannot read \Q$missing\E: No such file or directory\n\z/,
		'a missing file is refused with the system reason';

	# A directory can be opened on some systems, and only the read fails.
	throws_ok { Class::Shared::read_secret($dir) }
		qr/\AClass::Shared: cannot read \Q$dir\E: /, 'a directory is refused';

	SKIP: {
		skip 'root can read any file', 1 if $IS_ROOT;
		my $locked = $write->('locked', 'abc');
		chmod 0000, $locked;
		throws_ok { Class::Shared::read_secret($locked) }
			qr/cannot read \Q$locked\E: Permission denied/, 'an unreadable file is refused';
		chmod 0600, $locked;
	}

	ok(leaves_topic_alone(sub { Class::Shared::read_secret($write->('t', 'x')) }),
		'$_ is left alone');

	# $/ must be restored: a slurp that leaked would break the caller's reads.
	local $/ = "\n";
	Class::Shared::read_secret($write->('rs', 'x'));
	is($/, "\n", '$/ is restored');
};

# ------------------------------------------------------- normalise_fingerprint
subtest 'Class::Shared::normalise_fingerprint' => sub {
	my $hex = $config{fingerprint};
	my $colons = join ':', ($hex =~ /(..)/g);
	my $want = 'sha256$' . lc $hex;

	is(Class::Shared::normalise_fingerprint($hex), $want, 'bare hex');
	is(Class::Shared::normalise_fingerprint($colons), $want, 'colon separated');
	is(Class::Shared::normalise_fingerprint("sha256\$$hex"), $want, 'with the prefix');
	is(Class::Shared::normalise_fingerprint("sha256\$$colons"), $want, 'prefix and colons');
	is(Class::Shared::normalise_fingerprint(lc $colons), $want, 'lower case in');
	returns_ok($want, { type => 'string', matches => qr/\Asha256\$[0-9a-f]{64}\z/ }, 'shape of the result');

	my @bad = (
		substr($hex, 0, 63), $hex . 'A', ('G' x 64), "$hex\n", " $hex",
		"SHA256\$$hex", "sha1\$$hex", 'sha256$', ':' x 63,
		join(':', ($hex =~ /(..)/g), 'AB'), join(':', ($hex =~ /(..)/g))  . ':',
		substr($colons, 0, -1) . ' ', ($hex =~ s/^../AB:/r),
	);
	foreach my $value (@bad) {
		throws_ok { Class::Shared::normalise_fingerprint($value) }
			qr/is not a SHA-256 certificate fingerprint: give 64 hexadecimal digits/,
			'refuses ' . substr($value =~ s/\n/\\n/gr, 0, 30);
	}

	throws_ok { Class::Shared::normalise_fingerprint(undef) }
		qr/\AClass::Shared: no TLS fingerprint given\n\z/, 'undef is refused';
	throws_ok { Class::Shared::normalise_fingerprint('') }
		qr/\AClass::Shared: no TLS fingerprint given\n\z/, 'an empty value is refused';

	ok(leaves_topic_alone(sub { Class::Shared::normalise_fingerprint($hex) }), '$_ is left alone');
};

# ------------------------------------------------------------ client_tls_options
subtest 'Class::Shared::client_tls_options' => sub {
	test_needs 'IO::Socket::SSL';

	my %with_ca = Class::Shared::client_tls_options(cert => 'c.pem', key => 'k.pem', ca => 'ca.pem');
	state_of('with CA: ' . join(',', map { "$_=$with_ca{$_}" } sort keys %with_ca));

	is($with_ca{SSL_cert_file}, 'c.pem', 'client certificate');
	is($with_ca{SSL_key_file}, 'k.pem', 'client key');
	is($with_ca{SSL_ca_file}, 'ca.pem', 'trusted CA');
	is($with_ca{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(), 'the server is always verified');
	is($with_ca{SSL_version}, $Class::Shared::TLS_VERSIONS, 'old protocol versions are off');
	ok(!exists $with_ca{SSL_fingerprint}, 'no pin without a fingerprint');
	ok(!exists $with_ca{SSL_force_fingerprint}, 'and the pin is not forced');

	my %pinned = Class::Shared::client_tls_options(
		cert => 'c.pem', key => 'k.pem', ca => 'ca.pem', fingerprint => 'sha256$ab');
	is($pinned{SSL_fingerprint}, 'sha256$ab', 'the pin is passed on');
	is($pinned{SSL_force_fingerprint}, 1, 'the pin is the only thing that can accept the peer');
	is($pinned{SSL_verifycn_scheme}, 'none', 'a pin stands in for the name check');
	ok(!exists $pinned{SSL_ca_file}, 'a pin replaces the CA');
	is($pinned{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(), 'a pin does not switch verification off');

	# Even with nothing at all the verification must stay on: a caller who
	# forgets an option must get a failed connection, not an unverified one.
	my %bare = Class::Shared::client_tls_options();
	is($bare{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(), 'verification stays on with no options');

	# Unknown options are ignored, never forwarded to the TLS library.
	my %extra = Class::Shared::client_tls_options(SSL_verify_mode => 0, bogus => 1);
	is($extra{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(), 'a caller cannot turn verification off');
	ok(!exists $extra{bogus}, 'unknown options are not forwarded');

	memory_cycle_ok(\%pinned, 'no cycles in the options');
};

# ------------------------------------------------------------------------ dir_of
subtest 'Class::Shared::dir_of' => sub {
	is(Class::Shared::dir_of('/a/b/c.sock'), '/a/b', 'the directory of a path');
	is(Class::Shared::dir_of('/c.sock'), '/', 'a file at the root');
	is(Class::Shared::dir_of('c.sock'), '.', 'a bare name is in the current directory');
	is(Class::Shared::dir_of('/a/b/'), '/a', 'a trailing slash names the parent');

	# dirname answering with nothing must not become an empty path, which a
	# caller would treat as "no directory".
	mock('File::Basename::dirname' => sub { '' });
	is(Class::Shared::dir_of('x'), '/', 'an empty answer becomes the root');
	restore_all();

	ok(leaves_topic_alone(sub { Class::Shared::dir_of('/a/b') }), '$_ is left alone');
};

# -------------------------------------------------------------------- poll_pause
subtest 'Class::Shared::poll_pause' => sub {
	local $Class::Shared::POLL_INTERVAL = 0.05;

	my $start = Time::HiRes::time();
	my @result = Class::Shared::poll_pause();
	my $elapsed = Time::HiRes::time() - $start;
	state_of("poll_pause took $elapsed");

	cmp_ok($elapsed, '>=', 0.05 - $config{poll_slack}, 'sleeps for one interval');
	cmp_ok($elapsed, '<', 1, 'and only one');
	is_deeply(\@result, [], 'returns an empty list');

	# The interval is read each time, so one change moves every wait.
	local $Class::Shared::POLL_INTERVAL = 0;
	my $fast = Time::HiRes::time();
	Class::Shared::poll_pause();
	cmp_ok(Time::HiRes::time() - $fast, '<', 0.04, 'an interval of zero does not sleep');
};

# --------------------------------------------------- detach_standard_streams
# This reopens STDIN, STDOUT and STDERR, so it is only ever run in a child.
subtest 'Class::Shared::detach_standard_streams' => sub {
	my $dir = private_dir();

	# Run $code in a child; the child reports through a file because its own
	# standard streams are the thing under test.
	my $in_child = sub {
		my ($code) = @_;
		my $report = File::Spec->catfile($dir, 'report' . int(rand(1e9)));
		my $pid = fork();
		die "fork: $!" unless defined $pid;
		if (!$pid) {
			my @answer = $code->();
			open(my $out, '>', $report) or POSIX::_exit(2);
			print {$out} join("\n", map { defined $_ ? $_ : '(undef)' } @answer), "\n";
			close($out);
			POSIX::_exit(0);
		}
		waitpid($pid, 0);
		open(my $in, '<', $report) or return ();
		chomp(my @lines = <$in>);
		return @lines;
	};
	require POSIX;

	my $log = File::Spec->catfile($dir, 'backend.log');
	my @got = $in_child->(sub {
		my @r = Class::Shared::detach_standard_streams($log);
		print STDOUT "to stdout\n";
		print STDERR "to stderr\n";
		my $line = <STDIN>;
		return (@r, defined $line ? 'stdin has data' : 'stdin at eof');
	});
	is_deeply(\@got, [1, '(undef)', 'stdin at eof'], 'returns (1, undef) and STDIN is the null device');

	open(my $fh, '<', $log) or BAIL_OUT("no log: $!");
	my $logged = do { local $/; <$fh> };
	close($fh);
	like($logged, qr/to stdout\n/, 'STDOUT goes to the log');
	like($logged, qr/to stderr\n/, 'STDERR goes to the log');

	# Appending, not truncating: an earlier run's lines are evidence.
	$in_child->(sub { Class::Shared::detach_standard_streams($log); print STDOUT "second\n"; () });
	open($fh, '<', $log) or BAIL_OUT("no log: $!");
	$logged = do { local $/; <$fh> };
	close($fh);
	like($logged, qr/to stdout\n.*second\n/s, 'a second run appends');

	# A backend that cannot log should still run.
	my $unwritable = File::Spec->catfile($dir, 'no-such-dir', 'x.log');
	@got = $in_child->(sub {
		my @r = Class::Shared::detach_standard_streams($unwritable);
		print STDOUT "lost\n";
		return @r;
	});
	is_deeply(\@got, [1, '(undef)'], 'an unwritable log is not fatal');
	ok(!-e $unwritable, 'and nothing is created there');

	ok(leaves_topic_alone(sub { $in_child->(sub { Class::Shared::detach_standard_streams($log) }) }),
		'$_ is left alone');
};

# ------------------------------------------------------------------- default_dir
subtest 'Class::Shared::default_dir' => sub {
	my $dir = private_dir();

	local %ENV = %ENV;
	delete @ENV{qw(CLASS_SHARED_DIR XDG_RUNTIME_DIR)};

	is(Class::Shared::default_dir(dir => '/explicit'), '/explicit', 'an argument wins');

	$ENV{CLASS_SHARED_DIR} = '/from-env';
	is(Class::Shared::default_dir(), '/from-env', 'then the environment');
	is(Class::Shared::default_dir(dir => '/explicit'), '/explicit', 'the argument still wins');
	is(Class::Shared::default_dir(dir => ''), '/from-env', 'an empty argument is no argument');
	is(Class::Shared::default_dir(dir => undef), '/from-env', 'undef is no argument');

	$ENV{CLASS_SHARED_DIR} = '';
	$ENV{XDG_RUNTIME_DIR} = $dir;
	is(Class::Shared::default_dir(), File::Spec->catdir($dir, 'class-shared'),
		'an empty CLASS_SHARED_DIR is ignored; XDG_RUNTIME_DIR is next');

	# XDG_RUNTIME_DIR that is not there must not be used: nothing could be
	# created inside it.
	$ENV{XDG_RUNTIME_DIR} = File::Spec->catdir($dir, 'not-there');
	unlike(Class::Shared::default_dir(), qr/not-there/, 'a missing XDG_RUNTIME_DIR is skipped');

	delete $ENV{XDG_RUNTIME_DIR};
	my $fallback = Class::Shared::default_dir();
	my $expected = -d "/run/user/$>"
		? "/run/user/$>/class-shared"
		: File::Spec->catdir(File::Spec->tmpdir, "class-shared-$>");
	is($fallback, $expected, 'the last choice is per user');
	like($fallback, qr/\Q$>\E/, 'and the user id is in it, or in the path above it');

	returns_ok($fallback, { type => 'string', min => 1 }, 'returns a non-empty string');

	# A NUL byte would end the name early in the system call, so it names a
	# different place from the one that was checked.
	throws_ok { Class::Shared::default_dir(dir => "/tmp/a\0b") }
		qr/\AClass::Shared: a directory name may not contain a NUL byte\n\z/, 'NUL in an argument';
	$ENV{CLASS_SHARED_DIR} = "/tmp/a\0b";
	throws_ok { Class::Shared::default_dir() }
		qr/may not contain a NUL byte/, 'NUL in the environment';

	# Nothing is created: choosing a place is not the same as making it.
	delete $ENV{CLASS_SHARED_DIR};
	my $new = File::Spec->catdir($dir, 'made-up');
	Class::Shared::default_dir(dir => $new);
	ok(!-e $new, 'the directory is not created');

	ok(leaves_topic_alone(sub { Class::Shared::default_dir(dir => '/x') }), '$_ is left alone');
};

# ------------------------------------------------------------ _has_unix_sockets
subtest 'Class::Shared::_has_unix_sockets' => sub {
	{
		local $Class::Shared::UNIX_SOCKETS = 1;
		is(Class::Shared::_has_unix_sockets(), 1, 'a cached yes is returned');
	}
	{
		# Defined-but-false must be believed too: "0" is an answer.
		local $Class::Shared::UNIX_SOCKETS = 0;
		is(Class::Shared::_has_unix_sockets(), 0, 'a cached no is returned, not asked again');
	}
	{
		local $Class::Shared::UNIX_SOCKETS;
		my $probed = Class::Shared::_has_unix_sockets();
		is($probed, 1, 'probing on this platform says yes');
		is($Class::Shared::UNIX_SOCKETS, 1, 'and the answer is remembered');
	}

	ok(leaves_topic_alone(sub { local $Class::Shared::UNIX_SOCKETS; Class::Shared::_has_unix_sockets() }),
		'$_ is left alone');
};

# ---------------------------------------------------------- _require_unix_sockets
subtest 'Class::Shared::_require_unix_sockets' => sub {
	my @none = Class::Shared::_require_unix_sockets('a thing', 1);
	is_deeply(\@none, [], 'returns nothing when sockets exist');

	throws_ok { Class::Shared::_require_unix_sockets('a thing', 0) }
		qr/\AClass::Shared: a thing is not available here: this perl has no unix domain sockets/,
		'refuses when they do not, naming what was asked for';
	throws_ok { Class::Shared::_require_unix_sockets('a thing', 0) }
		qr/Unix-only \(see PLATFORMS\)\n\z/, 'and points the reader at PLATFORMS';

	# With no answer given the function asks _has_unix_sockets.
	mock('Class::Shared::_has_unix_sockets' => sub { 0 });
	throws_ok { Class::Shared::_require_unix_sockets('x') } qr/not available here/,
		'asks _has_unix_sockets when not told';
	restore_all();

	my $asked = 0;
	mock('Class::Shared::_has_unix_sockets' => sub { $asked++; 1 });
	Class::Shared::_require_unix_sockets('x', 0 + 1);
	is($asked, 0, 'does not ask when it was told');
	restore_all();
};

# -------------------------------------------------------------------- ensure_dir
subtest 'Class::Shared::ensure_dir' => sub {
	my $base = private_dir();

	throws_ok { Class::Shared::ensure_dir(undef) } qr/\AClass::Shared: no directory given\n\z/, 'undef';
	throws_ok { Class::Shared::ensure_dir('') } qr/\AClass::Shared: no directory given\n\z/, 'empty';

	# The platform check comes before anything touches the disk.
	my $target = File::Spec->catdir($base, 'new');
	mock('Class::Shared::_has_unix_sockets' => sub { 0 });
	throws_ok { Class::Shared::ensure_dir($target) } qr/no unix domain sockets/, 'no unix sockets';
	ok(!-e $target, 'nothing was created when the platform is refused');
	restore_all();

	my ($ok, $why) = Class::Shared::ensure_dir($target);
	is($ok, 1, 'a missing directory is created');
	is($why, undef, 'with no complaint');
	is(sprintf('%04o', (stat $target)[2] & 07777), '0700', 'closed to everyone else');

	($ok, $why) = Class::Shared::ensure_dir($target);
	is($ok, 1, 'an existing safe directory is accepted');

	# Open to others: somebody else could drop a socket in it.
	chmod 0777, $target;
	($ok, $why) = Class::Shared::ensure_dir($target);
	is($ok, 0, 'a directory writable by others is refused');
	like($why, qr/\Q$target\E is writable by group or others; refusing to use it/, 'with the reason');
	chmod 0770, $target;
	($ok, $why) = Class::Shared::ensure_dir($target);
	is($ok, 0, 'group-writable is refused as well');
	chmod 0700, $target;

	# mkdir failing is reported, not died on: the caller decides.
	my $deep = File::Spec->catdir($base, 'absent', 'child');
	($ok, $why) = Class::Shared::ensure_dir($deep);
	is($ok, 0, 'a missing parent is refused');
	like($why, qr/\Acannot create \Q$deep\E: No such file or directory\z/, 'with the system reason');
	ok(!-e $deep, 'and nothing is created');

	# A file in the way is not a directory we can use.
	my $file = File::Spec->catfile($base, 'plain');
	open(my $fh, '>', $file) or die; close($fh);
	($ok, $why) = Class::Shared::ensure_dir($file);
	is($ok, 0, 'a file in the way is refused');
	state_of("file in the way: $why");

	# It hands the final decision to _check_dir.
	my @seen;
	mock('Class::Shared::_check_dir' => sub { push @seen, @_; return (0, 'mocked why') });
	($ok, $why) = Class::Shared::ensure_dir($target);
	is_deeply([$ok, $why, \@seen], [0, 'mocked why', [$target]], 'the verdict comes from _check_dir');
	restore_all();

	ok(leaves_topic_alone(sub { Class::Shared::ensure_dir($target) }), '$_ is left alone');
};

# -------------------------------------------------------------------- _check_dir
subtest 'Class::Shared::_check_dir' => sub {
	my $base = private_dir();

	my ($ok, $why) = Class::Shared::_check_dir($base);
	is_deeply([$ok, $why], [1, undef], 'our own closed directory is safe');

	chmod 0755, $base;
	($ok) = Class::Shared::_check_dir($base);
	is($ok, 1, 'readable by others is fine: they still cannot add to it');

	foreach my $mode (0720, 0702, 0777, 0770, 0707) {
		chmod $mode, $base;
		($ok, $why) = Class::Shared::_check_dir($base);
		is($ok, 0, sprintf('mode %04o is refused', $mode));
		like($why, qr/is writable by group or others; refusing to use it\z/, '  with the reason');
	}
	chmod 0700, $base;

	my $missing = File::Spec->catdir($base, 'nope');
	($ok, $why) = Class::Shared::_check_dir($missing);
	is($ok, 0, 'a missing directory is not safe');
	like($why, qr/\Acannot stat \Q$missing\E: No such file or directory\z/, 'with the system reason');

	SKIP: {
		skip 'as root every directory is ours', 2 if $IS_ROOT;
		($ok, $why) = Class::Shared::_check_dir('/');
		is($ok, 0, "a directory owned by someone else is refused");
		like($why, qr{\A/ is owned by uid 0, not by uid \Q$>\E\z}, 'naming both users');
	}

	# The owner check comes first: a root-owned writable directory must be
	# reported as foreign, not as merely writable.
	state_of("checked $base");
	ok(leaves_topic_alone(sub { Class::Shared::_check_dir($base) }), '$_ is left alone');
};

# ------------------------------------------------------------- _check_endpoint
subtest 'Class::Shared::_check_endpoint' => sub {
	my $base = private_dir();
	my $path = File::Spec->catfile($base, 's.sock');
	my $sock = listening_socket($path);

	my ($ok, $why) = Class::Shared::_check_endpoint($path);
	is_deeply([$ok, $why], [1, undef], 'our socket in our directory is trusted');

	# A regular file where a socket should be.
	my $plain = File::Spec->catfile($base, 'plain');
	open(my $fh, '>', $plain) or die; close($fh);
	($ok, $why) = Class::Shared::_check_endpoint($plain);
	is($ok, 0, 'a regular file is not an endpoint');
	like($why, qr/\Q$plain\E is not a socket\z/, 'and says so');

	my $missing = File::Spec->catfile($base, 'gone');
	($ok, $why) = Class::Shared::_check_endpoint($missing);
	is($ok, 0, 'a missing path is refused');
	like($why, qr/\Acannot stat \Q$missing\E: /, 'with the system reason');

	# A directory in the socket's place.
	my $dir_as_path = File::Spec->catdir($base, 'adir');
	mkdir $dir_as_path or die;
	($ok, $why) = Class::Shared::_check_endpoint($dir_as_path);
	like($why, qr/is not a socket/, 'a directory is not a socket either');

	# The directory is judged first, so a socket in an open directory is not
	# trusted however well it is owned.
	chmod 0777, $base;
	($ok, $why) = Class::Shared::_check_endpoint($path);
	is($ok, 0, 'a socket in a writable directory is refused');
	like($why, qr/writable by group or others/, 'with the directory reason');
	chmod 0700, $base;

	# It asks _check_dir about the directory of the path, no other.
	my @asked;
	mock('Class::Shared::_check_dir' => sub { push @asked, @_; return (0, 'dir said no') });
	($ok, $why) = Class::Shared::_check_endpoint($path);
	is_deeply([$ok, $why, \@asked], [0, 'dir said no', [$base]], 'the verdict on the directory is passed up');
	restore_all();

	SKIP: {
		skip 'as root the socket below is ours too', 2 if $IS_ROOT;
		# A real socket owned by someone else: a system one, if there is one.
		my ($foreign) = grep { -S $_ && (stat _)[4] != $> } '/var/run/docker.sock', '/run/systemd/private/io.systemd.Manager', '/dev/log';
		skip 'no foreign socket to check on this host', 2 unless defined $foreign;
		mock('Class::Shared::_check_dir' => sub { (1, undef) });
		($ok, $why) = Class::Shared::_check_endpoint($foreign);
		is($ok, 0, 'a socket owned by another user is refused');
		like($why, qr/is owned by uid \d+, not by uid \Q$>\E/, 'naming both users');
		restore_all();
	}

	close($sock);
	ok(leaves_topic_alone(sub { Class::Shared::_check_endpoint($path) }), '$_ is left alone');
};

# ------------------------------------------------------------------ socket_path
subtest 'Class::Shared::socket_path' => sub {
	my $base = private_dir();

	is(Class::Shared::socket_path($base), File::Spec->catfile($base, 'class-shared.sock'),
		'one fixed name inside the directory');
	returns_ok(Class::Shared::socket_path($base), { type => 'string' }, 'returns a string');

	# It does not create anything.
	my $absent = File::Spec->catdir($base, 'later');
	Class::Shared::socket_path($absent);
	ok(!-e $absent, 'choosing a path does not create the directory');

	# Each helper is given the right input and its answer is used.
	my (@dir_args, @check_args);
	mock('Class::Shared::default_dir' => sub { @dir_args = @_; return '/chosen' });
	mock('Class::Shared::check_socket_path' => sub { @check_args = @_; return 'checked-path' });
	is(Class::Shared::socket_path('/given'), 'checked-path', 'the checked path is what comes back');
	is_deeply(\@dir_args, [dir => '/given'], 'the directory is chosen from the argument');
	is_deeply(\@check_args, [File::Spec->catfile('/chosen', 'class-shared.sock')], 'and the whole path is checked');
	restore_all();

	# A path that is too long is refused, and so is a platform without sockets.
	my $long = File::Spec->catdir($base, 'x' x $config{socket_limit});
	throws_ok { Class::Shared::socket_path($long) } qr/is \d+ characters, more than the \d+ allowed/,
		'too long is refused';

	mock('Class::Shared::_has_unix_sockets' => sub { 0 });
	throws_ok { Class::Shared::socket_path($base) } qr/a unix socket is not available here/,
		'no unix sockets is refused first';
	restore_all();

	throws_ok { Class::Shared::socket_path("$base/a\0b") } qr/NUL byte/, 'a NUL byte is refused';

	ok(leaves_topic_alone(sub { Class::Shared::socket_path($base) }), '$_ is left alone');
};

# ------------------------------------------------------------ check_socket_path
subtest 'Class::Shared::check_socket_path' => sub {
	my $limit = $config{socket_limit};
	local $Class::Shared::MAX_SOCKET_PATH = $limit;

	my $exact = '/' . ('a' x ($limit - 1));
	is(Class::Shared::check_socket_path($exact), $exact, 'exactly the limit is accepted');
	is(Class::Shared::check_socket_path('/a'), '/a', 'a short path is returned as it is');

	my $over = $exact . 'a';
	throws_ok { Class::Shared::check_socket_path($over) }
		qr/\AClass::Shared: socket path '\Q$over\E' is \Q@{[$limit + 1]}\E characters, more than the \Q$limit\E allowed; set CLASS_SHARED_DIR or pass dir => to a shorter directory\n\z/,
		'one past the limit is refused with the exact message';

	# The limit is read when the function runs.
	local $Class::Shared::MAX_SOCKET_PATH = 5;
	throws_ok { Class::Shared::check_socket_path('/abcdef') } qr/more than the 5 allowed/, 'the limit is the variable';

	# Multi-byte characters count as characters here, as the POD says.
	local $Class::Shared::MAX_SOCKET_PATH = 100;
	is(Class::Shared::check_socket_path("/" . ("\x{e9}" x 50)), "/" . ("\x{e9}" x 50), 'length is counted in characters');

	ok(leaves_topic_alone(sub { Class::Shared::check_socket_path('/a') }), '$_ is left alone');
};

# ===========================================================================
# Class::Shared::Protocol
# ===========================================================================

# A pipe that already holds $bytes, closed at the write end so that a read
# past them sees the end of the stream.
sub pipe_with_writer {
	my ($bytes, $keep_open) = @_;

	pipe(my $reader, my $writer) or die "pipe: $!";
	syswrite($writer, $bytes) if length $bytes;
	close($writer) unless $keep_open;

	return ($reader, $writer);
}

# Just the reading end, always one value, so it is safe inside an argument list.
sub pipe_holding {
	my ($bytes) = @_;

	my ($reader) = pipe_with_writer($bytes);

	return $reader;
}

# ----------------------------------------------------------------- encode_frame
subtest 'Class::Shared::Protocol::encode_frame' => sub {
	my $message = { op => 'ping', list => [1, 2, 3] };

	my $frame = Class::Shared::Protocol::encode_frame($message);
	my $length = unpack('N', substr($frame, 0, 4));
	is($length, length($frame) - 4, 'the header holds the length of what follows');
	is_deeply(Storable::thaw(substr($frame, 4)), $message, 'the body is the message');

	my $signed = Class::Shared::Protocol::encode_frame($message, $config{secret});
	my $signed_length = unpack('N', substr($signed, 0, 4));
	is($signed_length, length($signed) - 4, 'the header counts the digest too');
	is($signed_length, $length + $config{digest_size}, 'by exactly one digest');
	is(substr($signed, 4 + $config{digest_size}), substr($frame, 4), 'the body is the same');

	# The secret '0' is a secret: it must not be mistaken for "none".
	my $zero = Class::Shared::Protocol::encode_frame($message, '0');
	is(unpack('N', substr($zero, 0, 4)), $length + $config{digest_size}, 'a secret of "0" still signs');

	my $empty_secret = Class::Shared::Protocol::encode_frame($message, '');
	is(unpack('N', substr($empty_secret, 0, 4)), $length + $config{digest_size},
		'an empty secret still signs: only undef means none');

	# Each signed frame carries a digest that really does depend on the key.
	isnt(substr($signed, 4, $config{digest_size}),
		substr(Class::Shared::Protocol::encode_frame($message, $config{other_secret}), 4, $config{digest_size}),
		'another secret gives another digest');

	# Something Storable cannot freeze: reported, not died on.
	my ($frame_or_undef, $error) = Class::Shared::Protocol::encode_frame({ code => sub { 1 } });
	is($frame_or_undef, undef, 'a code reference cannot be sent');
	like($error, qr/\Acannot serialise message: .+\S\z/s, 'with the reason, trimmed');
	unlike($error, qr/\s\z/, 'and no trailing white space');

	# A message beyond the limit is refused whatever else is true.
	{
		local $Class::Shared::Protocol::MAX_FRAME = 10;
		($frame_or_undef, $error) = Class::Shared::Protocol::encode_frame({ data => 'x' x 100 });
		is($frame_or_undef, undef, 'a message over the limit is refused');
		like($error, qr/\Amessage is too large \(\d+ bytes, limit is 10\)\z/, 'with both numbers');

		($frame_or_undef, $error) = Class::Shared::Protocol::encode_frame({ data => 'x' x 100 }, $config{secret});
		is($frame_or_undef, undef, 'a signed one too');
	}

	# At the limit exactly the message is still sent; one byte more is not.
	{
		my $size = length(Storable::nfreeze($message));
		local $Class::Shared::Protocol::MAX_FRAME = $size;
		($frame_or_undef) = Class::Shared::Protocol::encode_frame($message);
		ok(defined $frame_or_undef, 'exactly at the limit is accepted');
		local $Class::Shared::Protocol::MAX_FRAME = $size - 1;
		($frame_or_undef) = Class::Shared::Protocol::encode_frame($message);
		ok(!defined $frame_or_undef, 'one byte over is refused');
	}

	# The digest comes from _digest, over the body and with the secret.
	my @digest_args;
	mock('Class::Shared::Protocol::_digest' => sub { @digest_args = @_; return 'D' x 32 });
	my $mocked = Class::Shared::Protocol::encode_frame($message, 'key');
	is_deeply([$digest_args[0], $digest_args[1] eq Storable::nfreeze($message)], ['key', 1], '_digest gets the secret and the body');
	is(substr($mocked, 4, 32), 'D' x 32, 'and what it returns is the digest');
	restore_all();

	# A digest of the wrong size would make every frame unreadable.
	mock('Class::Shared::Protocol::_digest' => sub { 'short' });
	my $odd = Class::Shared::Protocol::encode_frame($message, 'key');
	is(unpack('N', substr($odd, 0, 4)), length($odd) - 4, 'the header follows whatever digest came back');
	restore_all();

	memory_cycle_ok($message, 'the message is not wrapped in anything that loops');
	ok(leaves_topic_alone(sub { Class::Shared::Protocol::encode_frame($message, 'k') }), '$_ is left alone');
};

# ----------------------------------------------------------------- take_payload
subtest 'Class::Shared::Protocol::take_payload' => sub {
	my $message = { a => [1, { b => 2 }], c => 'text' };
	my ($got, $error) = Class::Shared::Protocol::take_payload(Storable::nfreeze($message));
	is_deeply($got, $message, 'a frozen message comes back');
	is($error, undef, 'with no error');

	foreach my $garbage ('', 'not storable', "\0" x 20, "pst0\xff\xff\xff", substr(Storable::nfreeze($message), 0, 5)) {
		($got, $error) = Class::Shared::Protocol::take_payload($garbage);
		is($got, undef, 'garbage gives no message: ' . (length $garbage ? substr($garbage =~ s/\W/?/gr, 0, 12) : '(empty)'));
		like($error, qr/\Acannot deserialise message: /, '  and an error');
	}

	# The error text is tidied so that it fits on one log line.
	unlike($error, qr/\s\z/, 'no trailing white space in the error');

	# Storable::thaw failing in an unexpected way must still be reported.
	mock('Storable::thaw' => sub { die "boom\n" });
	($got, $error) = Class::Shared::Protocol::take_payload('anything');
	is_deeply([$got, $error], [undef, 'cannot deserialise message: boom'], 'a dying thaw is reported');
	restore_all();

	# A caller's $@ must not decide the outcome: a stale error is not ours.
	local $@ = 'stale';
	($got, $error) = Class::Shared::Protocol::take_payload(Storable::nfreeze({ x => 1 }));
	is_deeply($got, { x => 1 }, 'a stale $@ does not matter');

	ok(leaves_topic_alone(sub { Class::Shared::Protocol::take_payload(Storable::nfreeze({})) }), '$_ is left alone');
};

# -------------------------------------------------------------------- write_all
subtest 'Class::Shared::Protocol::write_all' => sub {
	pipe(my $reader, my $writer) or die;
	my @r = Class::Shared::Protocol::write_all($writer, 'hello');
	is_deeply(\@r, [1], 'success is (1)');
	sysread($reader, my $buffer, 100);
	is($buffer, 'hello', 'every byte arrived');

	@r = Class::Shared::Protocol::write_all($writer, '');
	is_deeply(\@r, [1], 'writing nothing succeeds');

	# A large write has to be made in more than one piece on a pipe, so this
	# is the loop's only real test: every byte, in order, no repeats.
	my $big = join '', map { chr(65 + $_ % 26) } 0 .. 200_000;
	my $pid = fork() // die "fork: $!";
	if (!$pid) {
		close($writer);
		my $seen = '';
		while (sysread($reader, my $chunk, 65536)) { $seen .= $chunk }
		POSIX::_exit($seen eq 'x' . $big ? 0 : 1);
	}
	require POSIX;
	my @big = Class::Shared::Protocol::write_all($writer, 'x' . $big);
	close($writer);
	waitpid($pid, 0);
	is_deeply([\@big, $? >> 8], [[1], 0], 'a write bigger than the pipe arrives whole');

	# A reader that has gone away: an error, and no signal for the caller.
	pipe(my $r2, my $w2) or die;
	close($r2);
	my $signalled = 0;
	local $SIG{PIPE} = sub { $signalled++ };
	@r = Class::Shared::Protocol::write_all($w2, 'data');
	is($r[0], 0, 'a closed peer is a failure');
	like($r[1], qr/\Awrite failed: Broken pipe\z/, 'with the system reason');
	is($signalled, 0, 'and SIGPIPE does not reach the caller');
	is(ref $SIG{PIPE}, 'CODE', 'the caller\'s own handler is back afterwards');

	# Short writes are continued from the right place.
	tie(*SCRIPTED, 'Test::ScriptedHandle', 2, 2, 100);
	@r = Class::Shared::Protocol::write_all(\*SCRIPTED, 'abcde');
	is_deeply(\@r, [1], 'writes of 2, 2 and then the rest complete');
	is(tied(*SCRIPTED)->{calls}, 3, 'in three calls');
	untie(*SCRIPTED);

	# A write that makes no progress must not loop for ever.
	tie(*SCRIPTED, 'Test::ScriptedHandle', 0);
	@r = Class::Shared::Protocol::write_all(\*SCRIPTED, 'abc');
	is_deeply(\@r, [0, 'write failed: peer closed the connection'], 'a write of zero bytes ends the attempt');
	untie(*SCRIPTED);

	# A failure after some bytes went out is still a failure.
	tie(*SCRIPTED, 'Test::ScriptedHandle', 1, [5]);
	@r = Class::Shared::Protocol::write_all(\*SCRIPTED, 'abc');
	is($r[0], 0, 'an error part way is a failure');
	like($r[1], qr/\Awrite failed: /, 'with a reason');
	untie(*SCRIPTED);
};

# --------------------------------------------------------------------- _read_exact
subtest 'Class::Shared::Protocol::_read_exact' => sub {
	my $fh = pipe_holding('abcdef');
	my ($got, $error) = Class::Shared::Protocol::_read_exact($fh, 4);
	is_deeply([$got, $error], ['abcd', undef], 'exactly the bytes asked for');
	($got, $error) = Class::Shared::Protocol::_read_exact($fh, 2);
	is($got, 'ef', 'the rest is still there for the next call');

	($got, $error) = Class::Shared::Protocol::_read_exact($fh, 1);
	is_deeply([$got, $error], [undef, 'connection closed by peer'], 'the end of the stream is an error');

	$fh = pipe_holding('ab');
	($got, $error) = Class::Shared::Protocol::_read_exact($fh, 5);
	is_deeply([$got, $error], [undef, 'connection closed by peer'], 'a stream that ends early is an error');

	$fh = pipe_holding('');
	($got, $error) = Class::Shared::Protocol::_read_exact($fh, 0);
	is_deeply([$got, $error], ['', undef], 'zero bytes is an empty string, not an error');

	# A peer that sends nothing must not hold the reader for ever.
	my ($r, $w) = pipe_with_writer('', 1);
	my $start = Time::HiRes::time();
	($got, $error) = Class::Shared::Protocol::_read_exact($r, 1, $config{wait});
	is_deeply([$got, $error], [undef, 'timed out waiting for a reply'], 'silence is a timeout');
	cmp_ok(Time::HiRes::time() - $start, '<', $config{wait} + 2, 'and it is not much later than asked');

	# A peer that sends part and then stalls.
	syswrite($w, 'ab');
	($got, $error) = Class::Shared::Protocol::_read_exact($r, 5, $config{wait});
	is_deeply([$got, $error], [undef, 'timed out waiting for a reply'], 'a stall part way is a timeout too');

	# With no timeout the data that is there is read.
	syswrite($w, 'cde');
	($got) = Class::Shared::Protocol::_read_exact($r, 3);
	ok(defined $got, 'no timeout means no select');

	# Reading from something that is not a readable handle.
	pipe(my $r2, my $w2) or die;
	{
		# perl warns that the handle is write-only; that is the point.
		local $SIG{__WARN__} = sub { };
		($got, $error) = Class::Shared::Protocol::_read_exact($w2, 1);
	}
	is($got, undef, 'a write-only handle cannot be read');
	like($error, qr/\Aread failed: /, 'with a reason');

	# Decrypted bytes held inside a TLS object are taken before waiting.
	{
		package Test::PendingPipe;
		our @ISA = ('Test::PendingHandle');
	}
	my $reader = pipe_holding('xyz');
	bless $reader, 'Test::PendingPipe';
	$Test::PendingHandle::PENDING_CALLS = 0;
	$Test::PendingHandle::PENDING_ANSWER = 1;
	($got) = Class::Shared::Protocol::_read_exact($reader, 3, $config{wait});
	is($got, 'xyz', 'an object that has pending bytes is read');
	ok($Test::PendingHandle::PENDING_CALLS > 0, 'and it was asked');

	$reader = pipe_holding('');
	bless $reader, 'Test::PendingPipe';
	($got, $error) = Class::Shared::Protocol::_read_exact($reader, 1, $config{wait});
	is_deeply([$got, $error], [undef, 'connection closed by peer'], 'pending bytes that turn out to be the end of the stream');

	# A plain handle is never asked, so Perl does not load IO::File to answer.
	{
		my $asked = 0;
		no warnings 'once';
		local *IO::Handle::pending = sub { $asked++; 0 };
		my $plain = pipe_holding('q');
		Class::Shared::Protocol::_read_exact($plain, 1, $config{wait});
		is($asked, 0, 'a plain handle is not asked whether anything is pending');
	}

	ok(leaves_topic_alone(sub { Class::Shared::Protocol::_read_exact(scalar(pipe_holding('a')), 1) }), '$_ is left alone');
};

# -------------------------------------------------------------------- read_frame
subtest 'Class::Shared::Protocol::read_frame' => sub {
	my $message = { op => 'ping', n => [1, 2, 3] };

	my $frame = Class::Shared::Protocol::encode_frame($message);
	my ($got, $error) = Class::Shared::Protocol::read_frame(pipe_holding($frame));
	is_deeply([$got, $error], [$message, undef], 'a frame is read back');

	# Two frames back to back: the second must not be eaten by the first.
	my $two = pipe_holding($frame . Class::Shared::Protocol::encode_frame({ second => 1 }));
	Class::Shared::Protocol::read_frame($two);
	($got) = Class::Shared::Protocol::read_frame($two);
	is_deeply($got, { second => 1 }, 'the next frame is untouched');

	my $signed = Class::Shared::Protocol::encode_frame($message, $config{secret});
	($got, $error) = Class::Shared::Protocol::read_frame(pipe_holding($signed), undef, $config{secret});
	is_deeply($got, $message, 'a signed frame is read with the secret');

	# Authentication fails before Storable sees the body.
	my $thawed = 0;
	mock('Storable::thaw' => sub { $thawed++; return {} });
	($got, $error) = Class::Shared::Protocol::read_frame(pipe_holding($signed), undef, $config{other_secret});
	is_deeply([$got, $error], [undef, 'frame failed authentication'], 'the wrong secret is refused');
	is($thawed, 0, 'and nothing was thawed');

	# An unsigned frame is not accepted where a signature is required.
	($got, $error) = Class::Shared::Protocol::read_frame(pipe_holding($frame), undef, $config{secret});
	is($got, undef, 'an unsigned frame is refused when a secret is set');
	like($error, qr/\Aframe (?:is too short to be authenticated|failed authentication)\z/, 'with an authentication reason');
	is($thawed, 0, 'still nothing thawed');
	restore_all();

	# And a signed frame is not accepted without the secret: it cannot be parsed.
	($got, $error) = Class::Shared::Protocol::read_frame(pipe_holding($signed));
	is($got, undef, 'a signed frame is refused when no secret is set');
	like($error, qr/\Acannot deserialise message/, 'as garbage');

	# The size limit is checked from the header alone, before the body is
	# read, so a hostile length cannot make the reader allocate or wait.
	foreach my $length (64 * 1024 * 1024 + 1, 0xFFFFFFFF) {
		($got, $error) = Class::Shared::Protocol::read_frame(pipe_holding(pack('N', $length)));
		is($got, undef, "a header of $length is refused");
		like($error, qr/\Aframe of $length bytes exceeds the limit of 67108864\z/, '  with both numbers');
	}
	($got, $error) = Class::Shared::Protocol::read_frame(pipe_holding(pack('N', 64 * 1024 * 1024 + $config{digest_size} + 1)), undef, $config{secret});
	is($got, undef, 'with a secret the limit is one digest higher, and this is over it');
	like($error, qr/exceeds the limit of 67108896\z/, 'by exactly one digest');
	($got) = Class::Shared::Protocol::read_frame(pipe_holding(pack('N', 64 * 1024 * 1024 + $config{digest_size})), undef, $config{secret});
	is($got, undef, 'a length of exactly that is read, and fails later');
	{
		# At the limit the length is accepted and the read goes on.
		local $Class::Shared::Protocol::MAX_FRAME = 8;
		($got, $error) = Class::Shared::Protocol::read_frame(pipe_holding(pack('N', 8) . 'abcdefgh'));
		like($error, qr/\Acannot deserialise/, 'a length at the limit is read');
		($got, $error) = Class::Shared::Protocol::read_frame(pipe_holding(pack('N', 9) . 'abcdefghi'));
		like($error, qr/exceeds the limit of 8\z/, 'one more is not');
	}

	# Streams that end or stall at each point.
	($got, $error) = Class::Shared::Protocol::read_frame(pipe_holding(''));
	is_deeply([$got, $error], [undef, 'connection closed by peer'], 'nothing at all');
	($got, $error) = Class::Shared::Protocol::read_frame(pipe_holding("\0\0"));
	is_deeply([$got, $error], [undef, 'connection closed by peer'], 'half a header');
	($got, $error) = Class::Shared::Protocol::read_frame(pipe_holding(substr($frame, 0, -1)));
	is_deeply([$got, $error], [undef, 'connection closed by peer'], 'a body that is one byte short');
	my ($r, $still_open) = pipe_with_writer(substr($frame, 0, 6), 1);
	($got, $error) = Class::Shared::Protocol::read_frame($r, $config{wait});
	is_deeply([$got, $error], [undef, 'timed out waiting for a reply'], 'a body that stalls');

	# Zero length: a frame with nothing in it is garbage, not a message.
	($got, $error) = Class::Shared::Protocol::read_frame(pipe_holding(pack('N', 0)));
	is($got, undef, 'a frame of length zero is not a message');
	like($error, qr/\Acannot deserialise/, 'and says so');

	# The pieces are each other's responsibility: errors are passed through.
	my @script = ([undef, 'header failed'], ['x']);
	mock('Class::Shared::Protocol::_read_exact' => sub { return @{ shift @script } });
	($got, $error) = Class::Shared::Protocol::read_frame(\*STDIN);
	is_deeply([$got, $error], [undef, 'header failed'], 'a header error is passed up');
	restore_all();

	@script = ([pack('N', 3)], [undef, 'body failed']);
	mock('Class::Shared::Protocol::_read_exact' => sub { return @{ shift @script } });
	($got, $error) = Class::Shared::Protocol::read_frame(\*STDIN);
	is_deeply([$got, $error], [undef, 'body failed'], 'a body error is passed up');
	restore_all();

	memory_cycle_ok($message, 'no cycles in what was read');
	ok(leaves_topic_alone(sub { Class::Shared::Protocol::read_frame(pipe_holding($frame)) }), '$_ is left alone');
};

# -------------------------------------------------------------------- take_frame
subtest 'Class::Shared::Protocol::take_frame' => sub {
	my $message = { op => 'x' };
	my $frame = Class::Shared::Protocol::encode_frame($message);

	my $buffer = '';
	is_deeply([Class::Shared::Protocol::take_frame(\$buffer)], [0, undef, undef], 'an empty buffer needs more');
	$buffer = substr($frame, 0, 3);
	is_deeply([Class::Shared::Protocol::take_frame(\$buffer)], [0, undef, undef], 'half a header needs more');
	is($buffer, substr($frame, 0, 3), 'and is left as it was');

	$buffer = substr($frame, 0, -1);
	is_deeply([Class::Shared::Protocol::take_frame(\$buffer)], [0, undef, undef], 'a short body needs more');
	is($buffer, substr($frame, 0, -1), 'and is left as it was');

	$buffer = $frame;
	my @r = Class::Shared::Protocol::take_frame(\$buffer);
	is_deeply(\@r, [1, $message, undef], 'a whole frame is taken');
	is($buffer, '', 'and removed from the buffer');

	# Frames that arrive together are taken one at a time, in order.
	$buffer = $frame . Class::Shared::Protocol::encode_frame({ op => 'y' }) . 'tail';
	@r = Class::Shared::Protocol::take_frame(\$buffer);
	is($r[1]{op}, 'x', 'the first frame comes first');
	@r = Class::Shared::Protocol::take_frame(\$buffer);
	is($r[1]{op}, 'y', 'then the second');
	is($buffer, 'tail', 'and what follows is kept');

	# An oversize header ends the connection, and does not wait for the body.
	$buffer = pack('N', $Class::Shared::Protocol::MAX_FRAME + 1);
	@r = Class::Shared::Protocol::take_frame(\$buffer);
	is($r[0], -1, 'an oversize header is fatal');
	like($r[2], qr/\Aframe of \d+ bytes exceeds the limit of 67108864\z/, 'with the numbers');

	$buffer = pack('N', 0xFFFFFFFF) . 'x';
	@r = Class::Shared::Protocol::take_frame(\$buffer);
	is($r[0], -1, 'the largest possible length is fatal');

	# A signed stream.
	my $signed = Class::Shared::Protocol::encode_frame($message, $config{secret});
	$buffer = $signed;
	@r = Class::Shared::Protocol::take_frame(\$buffer, $config{secret});
	is_deeply(\@r, [1, $message, undef], 'a signed frame is taken with the secret');

	$buffer = $signed;
	@r = Class::Shared::Protocol::take_frame(\$buffer, $config{other_secret});
	is_deeply([@r[0, 1]], [-1, undef], 'the wrong secret is fatal');
	is($r[2], 'frame failed authentication', 'with the reason');
	is($buffer, '', 'the bad frame is not left in the buffer to be tried again');

	# One flipped bit anywhere in a signed frame is caught.
	foreach my $position (4, 20, length($signed) - 1) {
		my $tampered = $signed;
		substr($tampered, $position, 1) = chr(ord(substr($tampered, $position, 1)) ^ 1);
		@r = Class::Shared::Protocol::take_frame(\$tampered, $config{secret});
		is($r[0], -1, "a flipped bit at byte $position is caught");
	}

	# A frame too small to hold a digest.
	$buffer = pack('N', 5) . 'abcde';
	@r = Class::Shared::Protocol::take_frame(\$buffer, $config{secret});
	is_deeply([@r[0, 2]], [-1, 'frame is too short to be authenticated'], 'too short to carry a digest');

	# Garbage with a good length.
	$buffer = pack('N', 4) . 'junk';
	@r = Class::Shared::Protocol::take_frame(\$buffer);
	is($r[0], -1, 'an unreadable body is fatal');
	like($r[2], qr/\Acannot deserialise message/, 'with the reason');

	# The decision comes from _decode and the limit from the header.
	my @decoded;
	mock('Class::Shared::Protocol::_decode' => sub { @decoded = @_; return ('msg', undef) });
	$buffer = pack('N', 3) . 'abc';
	@r = Class::Shared::Protocol::take_frame(\$buffer, 'key');
	is_deeply([@r, @decoded], [1, 'msg', undef, 'abc', 'key', undef], '_decode is given the payload, the secret and no check');
	restore_all();

	ok(leaves_topic_alone(sub { my $b = $frame; Class::Shared::Protocol::take_frame(\$b) }), '$_ is left alone');
};

# ----------------------------------------------------------------------- _decode
subtest 'Class::Shared::Protocol::_decode' => sub {
	my $message = { k => 'v' };
	my $body = Storable::nfreeze($message);
	my $digest = Class::Shared::Protocol::_digest($config{secret}, $body);

	is_deeply([Class::Shared::Protocol::_decode($body)], [$message, undef], 'no secret: the payload is the body');
	is_deeply([Class::Shared::Protocol::_decode($digest . $body, $config{secret})], [$message, undef],
		'a secret: the digest is checked and removed');

	my $thawed = 0;
	mock('Class::Shared::Protocol::take_payload' => sub { $thawed++; return ({}, undef) });

	is_deeply([Class::Shared::Protocol::_decode($digest . $body, $config{other_secret})],
		[undef, 'frame failed authentication'], 'the wrong secret');
	is_deeply([Class::Shared::Protocol::_decode(substr($digest . $body, 0, 31), $config{secret})],
		[undef, 'frame is too short to be authenticated'], 'one byte too short for a digest');
	is_deeply([Class::Shared::Protocol::_decode('', $config{secret})],
		[undef, 'frame is too short to be authenticated'], 'an empty payload');
	is($thawed, 0, 'a payload that fails the check never reaches take_payload');

	# Exactly a digest and no body: authentic only if the digest is of ''.
	my $empty_digest = Class::Shared::Protocol::_digest($config{secret}, '');
	Class::Shared::Protocol::_decode($empty_digest, $config{secret});
	is($thawed, 1, 'a digest of an empty body is checked and passed on');

	# Without a secret, no authentication is attempted at all.
	my $authenticated = 0;
	mock('Class::Shared::Protocol::_authentic' => sub { $authenticated++; 1 });
	Class::Shared::Protocol::_decode('abc');
	is($authenticated, 0, 'no secret, no check');
	Class::Shared::Protocol::_decode($digest . $body, $config{secret});
	is($authenticated, 1, 'a secret means a check');
	restore_all();

	# A secret of "0" is still a secret.
	is_deeply([Class::Shared::Protocol::_decode($digest . $body, '0')], [undef, 'frame failed authentication'],
		'a secret of "0" is checked');

	ok(leaves_topic_alone(sub { Class::Shared::Protocol::_decode($body) }), '$_ is left alone');
};

# ----------------------------------------------------------------------- _digest
subtest 'Class::Shared::Protocol::_digest' => sub {
	is(unpack('H*', Class::Shared::Protocol::_digest($config{hmac_key}, $config{hmac_data})),
		$config{hmac_hex}, 'matches the published HMAC-SHA-256 test vector');

	my $digest = Class::Shared::Protocol::_digest('k', 'body');
	is(length $digest, $config{digest_size}, 'is the size the protocol expects');
	is($digest, Class::Shared::Protocol::_digest('k', 'body'), 'is repeatable');
	isnt($digest, Class::Shared::Protocol::_digest('K', 'body'), 'depends on the secret');
	isnt($digest, Class::Shared::Protocol::_digest('k', 'Body'), 'depends on the body');
	isnt(Class::Shared::Protocol::_digest('k', ''), Class::Shared::Protocol::_digest('k', "\0"),
		'an empty body differs from a NUL');
	is(length Class::Shared::Protocol::_digest('', ''), $config{digest_size}, 'even empty input gives a full digest');

	# The argument order is (secret, body); a swap would still "work" but
	# against the wrong key.
	isnt(Class::Shared::Protocol::_digest('a', 'b'), Class::Shared::Protocol::_digest('b', 'a'), 'the order matters');

	# Wide characters cannot be digested: this must fail loudly rather than
	# hash something other than what was meant.
	dies_ok { Class::Shared::Protocol::_digest('k', "\x{263a}") } 'a wide character is refused';

	ok(leaves_topic_alone(sub { Class::Shared::Protocol::_digest('k', 'b') }), '$_ is left alone');
};

# -------------------------------------------------------------------- _authentic
subtest 'Class::Shared::Protocol::_authentic' => sub {
	my $body = 'some body';
	my $digest = Class::Shared::Protocol::_digest($config{secret}, $body);

	is(Class::Shared::Protocol::_authentic($config{secret}, $body, $digest), 1, 'the right digest');
	is(Class::Shared::Protocol::_authentic($config{other_secret}, $body, $digest), 0, 'the wrong secret');
	is(Class::Shared::Protocol::_authentic($config{secret}, 'other body', $digest), 0, 'the wrong body');

	# One bit wrong in any byte, first to last.
	foreach my $position (0, 15, $config{digest_size} - 1) {
		my $bad = $digest;
		substr($bad, $position, 1) = chr(ord(substr($bad, $position, 1)) ^ 0x80);
		is(Class::Shared::Protocol::_authentic($config{secret}, $body, $bad), 0, "a changed byte $position");
	}

	# A digest of the wrong length is no digest, and must not match by
	# being a prefix.
	is(Class::Shared::Protocol::_authentic($config{secret}, $body, substr($digest, 0, 31)), 0, 'a digest one byte short');
	is(Class::Shared::Protocol::_authentic($config{secret}, $body, $digest . "\0"), 0, 'a digest one byte long');
	is(Class::Shared::Protocol::_authentic($config{secret}, $body, ''), 0, 'an empty digest');
	is(Class::Shared::Protocol::_authentic($config{secret}, $body, "\0" x 32), 0, 'a digest of zeros');

	# Every byte is looked at even when the first one is already wrong: the
	# comparison must not stop early, or its timing would leak the match.
	my @ords;
	{
		my $real = \&Class::Shared::Protocol::_digest;
		mock('Class::Shared::Protocol::_digest' => sub { return "A" x 32 });
		is(Class::Shared::Protocol::_authentic('k', 'b', 'B' . ('A' x 31)), 0, 'wrong in the first byte only');
		is(Class::Shared::Protocol::_authentic('k', 'b', ('A' x 31) . 'B'), 0, 'wrong in the last byte only');
		is(Class::Shared::Protocol::_authentic('k', 'b', 'A' x 32), 1, 'right in every byte');
		restore_all();
	}

	# It asks _digest for the expected value, with the secret and the body.
	my @args;
	mock('Class::Shared::Protocol::_digest' => sub { @args = @_; return $digest });
	Class::Shared::Protocol::_authentic('S', 'B', $digest);
	is_deeply(\@args, ['S', 'B'], '_digest is called with the secret, then the body');
	restore_all();

	ok(leaves_topic_alone(sub { Class::Shared::Protocol::_authentic('k', 'b', 'd') }), '$_ is left alone');
};

# ===========================================================================
# Class::Shared::Frontend
# ===========================================================================

# Helpers for the frontend: an object that never touched a backend, and a
# connected pair of sockets standing in for the backend.

# A frontend filled in by hand, so a function can be tested without the
# connection that new would make.  %field overrides any default.
sub bare_frontend {
	my (%field) = @_;

	return bless {
		class       => 'Some::Class',
		transport   => 'unix',
		socket_path => '/nonexistent/class-shared.sock',
		host        => undef,
		port        => undef,
		token       => undef,
		ctor        => [],
		autostart   => 1,
		timeout     => 1,
		log         => '/nonexistent/class-shared.sock.log',
		sock        => undef,
		pid         => undef,
		id          => undef,
		last_error  => undef,
		%field,
	}, 'Class::Shared::Frontend';
}

# Two ends of one connection: the first goes in the frontend, the second is
# the test, playing the backend.
sub connection_pair {
	socketpair(my $near, my $far, AF_UNIX, SOCK_STREAM, 0) or die "socketpair: $!";
	return ($near, $far);
}

# Put replies on the backend end of a pair, ready for the frontend to read.
sub peer_replies {
	my ($far, $secret, @messages) = @_;

	foreach my $message (@messages) {
		my ($bytes) = Class::Shared::Protocol::encode_frame($message, $secret);
		Class::Shared::Protocol::write_all($far, $bytes);
	}

	return;
}

# What the frontend sent, as the backend would see it.
sub peer_request {
	my ($far, $secret) = @_;

	my ($message, $error) = Class::Shared::Protocol::read_frame($far, 1, $secret);

	return $message;
}

# Replace $SIG{__WARN__} for one block and give back what was warned.
sub warnings_from {
	my ($code) = @_;

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	$code->();

	return @warnings;
}

# ------------------------------------------------------------------------- new
subtest 'Class::Shared::Frontend::new' => sub {
	my $dir = private_dir();
	my $socket = File::Spec->catfile($dir, 's.sock');

	# Everything below is about checking the arguments; connecting is
	# replaced so that no backend is wanted.
	my @connected;
	mock('Class::Shared::Frontend::_connect' => sub { push @connected, $_[0]; return $_[0] });

	my $make = sub { Class::Shared::Frontend->new(@_) };
	my $new_dies = sub {
		my ($pattern, $name, @args) = @_;
		throws_ok { Class::Shared::Frontend->new(@args) } $pattern, $name;
	};
	my $prefix = qr/\AClass::Shared::Frontend->new: /;

	# --- the ways of giving the arguments
	my $by_name = $make->('Some::Class', socket => $socket);
	is($by_name->shared_class, 'Some::Class', 'class name first');
	is($by_name->shared_socket_path, $socket, 'and a socket');
	isa_ok($by_name, 'Class::Shared::Frontend');
	is(scalar(@connected), 1, 'one connection is made');
	is($connected[0], $by_name, 'by the object itself');

	is($make->(class => 'Other::Class', socket => $socket)->shared_class, 'Other::Class', 'class as an option');
	is($make->({ class => 'Hash::Class', socket => $socket })->shared_class, 'Hash::Class', 'options as a hash reference');
	is($make->('First::Class', { socket => $socket })->shared_class, 'First::Class', 'name and a hash reference');
	is($make->('Name::Wins', class => 'Option::Loses', socket => $socket)->shared_class, 'Option::Loses',
		'the class option is the one used when both are given');

	# --- the defaults
	my $defaults = $make->('Some::Class', socket => $socket);
	is_deeply($defaults->{ctor}, [], 'the constructor arguments default to none');
	is($defaults->{autostart}, 1, 'a backend is started when absent');
	is($defaults->{timeout}, $Class::Shared::Frontend::DEFAULT_TIMEOUT, 'the default timeout');
	is($defaults->{log}, "$socket.log", 'the log sits beside the socket');
	is($defaults->{transport}, 'unix', 'unix by default');
	is($defaults->{sock}, undef, 'not connected until _connect says so');

	my $chosen = $make->('Some::Class', socket => $socket, autostart => 0, timeout => 0, log => '/x/log', ctor => [1, 2]);
	is($chosen->{autostart}, 0, 'autostart 0 is kept, not replaced by the default');
	is($chosen->{timeout}, 0, 'timeout 0 is kept, not replaced by the default');
	is($chosen->{log}, '/x/log', 'a log path is used');
	is_deeply($chosen->{ctor}, [1, 2], 'constructor arguments are kept');

	my $by_dir = $make->('Some::Class', dir => $dir);
	is($by_dir->shared_socket_path, File::Spec->catfile($dir, 'class-shared.sock'), 'dir gives the one socket name');

	# --- the class name
	$new_dies->(qr/${prefix}no class name given\n\z/, 'no arguments at all');
	$new_dies->(qr/${prefix}no class name given\n\z/, 'undef is no class name', undef);
	$new_dies->(qr/${prefix}no class name given\n\z/, 'an empty class name', '');
	$new_dies->(qr/${prefix}no class name given\n\z/, 'options but no class', socket => $socket);
	is_deeply([warnings_from(sub { eval { Class::Shared::Frontend->new(undef) } })], [], 'undef gives no warning');

	foreach my $bad ('Bad Name', '1Bad', 'Bad::', '../Bad', "Bad\n", 'Bad;system') {
		$new_dies->(qr/is not a valid class name/, 'refuses the class name ' . ($bad =~ s/\n/\\n/gr), $bad, socket => $socket);
	}
	$new_dies->(qr/is not a valid class name/, 'a bad class option', class => 'Bad Name', socket => $socket);

	# --- the options
	$new_dies->(qr/${prefix}expected key\/value options\n\z/, 'an odd option list', 'Some::Class', 'socket');
	$new_dies->(qr/${prefix}unknown option 'bogus'\n\z/, 'an unknown option', 'Some::Class', bogus => 1);
	$new_dies->(qr/${prefix}unknown option 'Socket'\n\z/, 'option names are case sensitive', 'Some::Class', Socket => $socket);
	$new_dies->(qr/${prefix}unknown option 'a'\n/, 'the unknown options are reported in order, first one first',
		'Some::Class', b => 1, a => 1);
	$new_dies->(qr/${prefix}ctor must be an array ref\n\z/, 'a ctor that is a string', 'Some::Class', socket => $socket, ctor => 'x');
	$new_dies->(qr/${prefix}ctor must be an array ref\n\z/, 'a ctor that is a hash', 'Some::Class', socket => $socket, ctor => {});

	# --- a unix socket carries no token and no TLS
	$new_dies->(qr/${prefix}a unix socket needs no token: its mode 0600 file already decides who may connect\n\z/,
		'a token on a unix socket', 'Some::Class', socket => $socket, token => 'x');
	$new_dies->(qr/a unix socket needs no token/, 'a token file on a unix socket', 'Some::Class', socket => $socket, token_file => '/x');
	$new_dies->(qr/a unix socket needs no token/, 'even an empty token', 'Some::Class', socket => $socket, token => '');
	foreach my $option (qw(tls_cert tls_key tls_ca tls_fingerprint)) {
		$new_dies->(qr/${prefix}a unix socket needs no TLS: /, "$option on a unix socket", 'Some::Class', socket => $socket, $option => 'x');
	}
	lives_ok { $make->('Some::Class', socket => $socket, tls_cert => '') } 'an empty TLS option is no option';

	# --- a TCP backend needs everything, and says which part is missing
	my %tcp = (host => 'h.example', port => 7777, tls_cert => 'c', tls_key => 'k', tls_ca => 'ca');
	my $tcp = $make->('Some::Class', %tcp);
	is($tcp->{transport}, 'tcp', 'a host and port make a TCP frontend');
	is($tcp->shared_address, 'h.example:7777', 'whose address is host:port');
	is($tcp->shared_socket_path, undef, 'with no socket path');

	$new_dies->(qr/${prefix}a TCP backend needs both host and port\n\z/, 'host without port', 'Some::Class', %tcp, port => undef);
	$new_dies->(qr/a TCP backend needs both host and port/, 'port without host', 'Some::Class', %tcp, host => undef);
	$new_dies->(qr/use either socket or host\/port, not both/, 'socket and host together', 'Some::Class', %tcp, socket => $socket);
	foreach my $missing (qw(tls_cert tls_key)) {
		$new_dies->(qr/a TCP backend needs tls_cert and tls_key: the backend will not accept a client it cannot verify\n\z/,
			"no $missing", 'Some::Class', %tcp, $missing => undef);
		$new_dies->(qr/needs tls_cert and tls_key/, "an empty $missing", 'Some::Class', %tcp, $missing => '');
	}
	$new_dies->(qr/needs tls_ca or tls_fingerprint: without one it cannot verify the backend/, 'neither a CA nor a pin',
		'Some::Class', %tcp, tls_ca => undef);
	$new_dies->(qr/needs tls_ca or tls_fingerprint/, 'an empty CA and no pin', 'Some::Class', %tcp, tls_ca => '');
	$new_dies->(qr/give tls_ca or tls_fingerprint, not both: a CA and a pin are alternatives/, 'a CA and a pin',
		'Some::Class', %tcp, tls_fingerprint => $config{fingerprint});
	$new_dies->(qr/is not a SHA-256 certificate fingerprint/, 'a pin that is not a fingerprint',
		'Some::Class', %tcp, tls_ca => undef, tls_fingerprint => 'not-a-fingerprint');

	my $pinned = $make->('Some::Class', %tcp, tls_ca => undef, tls_fingerprint => join(':', ($config{fingerprint} =~ /(..)/g)));
	is($pinned->{tls_fingerprint}, 'sha256$' . lc $config{fingerprint}, 'a pin is stored in the normal form');

	# The token comes from the option or from the file, never both.
	my $token_file = File::Spec->catfile($dir, 'token');
	open(my $fh, '>', $token_file) or die; print {$fh} "from file\n"; close($fh);
	is($make->('Some::Class', %tcp, token => 'direct')->{token}, 'direct', 'a token option');
	is($make->('Some::Class', %tcp, token_file => $token_file)->{token}, 'from file', 'a token file');
	$new_dies->(qr/${prefix}give token or token_file, not both\n\z/, 'both together',
		'Some::Class', %tcp, token => 'direct', token_file => $token_file);
	is($make->('Some::Class', %tcp, token => 'direct', token_file => undef)->{token}, 'direct', 'an undef token file is not given');
	$new_dies->(qr/cannot read \Q$dir\E\/no-such-token/, 'a missing token file', 'Some::Class', %tcp, token_file => "$dir/no-such-token");

	# --- the socket path
	my $too_long = File::Spec->catfile($dir, 'x' x $config{socket_limit});
	$new_dies->(qr/socket path .* is \d+ characters, more than the \d+ allowed/, 'a socket path that is too long',
		'Some::Class', socket => $too_long);

	# --- the checks come before any connection, and none is made on failure
	@connected = ();
	eval { Class::Shared::Frontend->new('Bad Name', socket => $socket) };
	eval { Class::Shared::Frontend->new('Some::Class', socket => $socket, bogus => 1) };
	is(scalar(@connected), 0, 'nothing connects when an argument is wrong');

	# The caller's own option hash is not changed.
	my %given = (class => 'Hash::Class', socket => $socket);
	$make->(\%given);
	is_deeply(\%given, { class => 'Hash::Class', socket => $socket }, 'the options hash passed in is left as it was');

	memory_cycle_ok($by_name, 'a frontend holds no reference loop');
	restore_all();

	ok(leaves_topic_alone(sub { mock('Class::Shared::Frontend::_connect' => sub { $_[0] }); Class::Shared::Frontend->new('X', socket => $socket); restore_all() }),
		'$_ is left alone');
};

# -------------------------------------------------------------------- accessors
subtest 'Class::Shared::Frontend accessors' => sub {
	my $unix = bare_frontend(class => 'A::B', socket_path => '/s/x.sock', pid => 42, id => 7, last_error => 'oops');

	is($unix->shared_class, 'A::B', 'shared_class');
	is($unix->shared_socket_path, '/s/x.sock', 'shared_socket_path');
	is($unix->shared_address, '/s/x.sock', 'a unix address is the path');
	is($unix->shared_pid, 42, 'shared_pid');
	is($unix->shared_id, 7, 'shared_id');
	is($unix->shared_last_error, 'oops', 'shared_last_error');
	is($unix->shared_connected, 0, 'no socket, not connected');

	my ($near, $far) = connection_pair();
	$unix->{sock} = $near;
	is($unix->shared_connected, 1, 'a socket, connected');
	is(ref(\$unix->shared_connected), 'SCALAR', 'a plain number, not a handle');

	my $tcp = bare_frontend(transport => 'tcp', socket_path => undef, host => 'h', port => 99);
	is($tcp->shared_address, 'h:99', 'a TCP address is host:port');
	is($tcp->shared_socket_path, undef, 'with no socket path');

	# A fresh frontend has none of the facts a connection supplies.
	my $fresh = bare_frontend();
	is_deeply([map { $fresh->$_ } qw(shared_pid shared_id shared_last_error)], [undef, undef, undef],
		'unknown facts are undef, not empty or zero');

	# The accessors only read: asking does not touch the connection.
	my $before = join ',', map { $unix->{$_} // '-' } sort keys %$unix;
	$unix->$_ foreach qw(shared_class shared_socket_path shared_address shared_pid shared_id shared_connected shared_last_error);
	is(join(',', map { $unix->{$_} // '-' } sort keys %$unix), $before, 'no accessor changes the object');

	$unix->{sock} = undef;
};

# ------------------------------------------------------------------ shared_call
subtest 'Class::Shared::Frontend::shared_call' => sub {
	my $frontend = bare_frontend();

	throws_ok { $frontend->shared_call() }
		qr/\AClass::Shared::Frontend->shared_call: no method name given\n\z/, 'no method name';
	throws_ok { $frontend->shared_call(undef, 1) } qr/no method name given/, 'undef method name';
	throws_ok { $frontend->shared_call('', 1) } qr/no method name given/, 'empty method name';

	# A method called "0" is a name, and must not be taken for "none".
	my @seen;
	mock('Class::Shared::Frontend::_invoke' => sub { shift; @seen = @_; return ['r1', 'r2'] });
	my @list = $frontend->shared_call('0', 'a', 'b');
	is_deeply(\@seen, ['0', ['a', 'b'], 'list'], 'the name and arguments are passed on, in list context');
	is_deeply(\@list, ['r1', 'r2'], 'list context returns every result');

	my $scalar = $frontend->shared_call('m');
	is($seen[2], 'scalar', 'scalar context is passed on');
	is($scalar, 'r1', 'scalar context returns the first result');

	$frontend->shared_call('m');
	my $void_context = sub { $frontend->shared_call('m'); return };
	$void_context->();
	is($seen[2], 'void', 'void context is passed on');

	$frontend->shared_call('m', undef, '', 0);
	is_deeply($seen[1], [undef, '', 0], 'arguments that are false are all passed');

	$frontend->shared_call('m', 'x');
	my $args = $seen[1];
	push @$args, 'changed';
	restore_all();

	# The arguments are copied: the caller's array is not shared with the call.
	my @mine = (1, 2);
	my $captured;
	mock('Class::Shared::Frontend::_invoke' => sub { $captured = $_[2]; return [] });
	$frontend->shared_call('m', @mine);
	push @$captured, 3;
	is_deeply(\@mine, [1, 2], 'the caller\'s array is not changed');
	restore_all();

	# An error from the backend reaches the caller unchanged.
	mock('Class::Shared::Frontend::_invoke' => sub { die "the backend said no\n" });
	throws_ok { $frontend->shared_call('m') } qr/\Athe backend said no\n\z/, 'errors pass through';
	restore_all();
};

# ----------------------------------------------------------------- shared_status
subtest 'Class::Shared::Frontend::shared_status' => sub {
	my $frontend = bare_frontend();

	my @sent;
	mock('Class::Shared::Frontend::_request' => sub { shift; @sent = @_; return { ok => 1, pid => 5 } });
	is_deeply($frontend->shared_status, { ok => 1, pid => 5 }, 'the answer to a ping is returned');
	is_deeply(\@sent, [{ op => 'ping' }], 'a ping is sent, and nothing else');
	restore_all();

	throws_ok { $frontend->shared_status }
		qr/\AClass::Shared: this frontend has no connection to a backend for 'Some::Class'; its object is gone\n\z/,
		'without a connection it dies, and says which class';

	mock('Class::Shared::Frontend::_request' => sub { die "lost it\n" });
	throws_ok { $frontend->shared_status } qr/\Alost it\n\z/, 'a failure is not hidden';
	restore_all();
};

# ----------------------------------------------------------------- shared_close
subtest 'Class::Shared::Frontend::shared_close' => sub {
	is(bare_frontend()->shared_close, 0, 'nothing to close returns 0');

	my ($near, $far) = connection_pair();
	my $frontend = bare_frontend(sock => $near, id => 3, pid => 4);
	is($frontend->shared_close, 1, 'closing returns 1');
	is_deeply([@{$frontend}{qw(sock id pid)}], [undef, undef, undef], 'the connection state is cleared');
	ok(!defined fileno($near), 'and the handle really is closed');
	is($frontend->shared_close, 0, 'a second close does nothing and says so');

	# The peer sees the end of the stream: that is how the backend learns to
	# destroy this connection's objects.
	my $got = sysread($far, my $buffer, 1);
	is($got, 0, 'the other end sees the connection close');

	# A failed close must not leave a half-open frontend behind.
	($near, $far) = connection_pair();
	$frontend = bare_frontend(sock => $near, id => 3, pid => 4);
	mock('Class::Shared::Frontend::_close' => sub { 0 });
	is($frontend->shared_close, 1, 'a close that reports failure still returns 1');
	is_deeply([@{$frontend}{qw(sock id pid)}], [undef, undef, undef], 'and the state is cleared anyway');
	restore_all();

	# It names the handle and the purpose when it asks for the close.
	($near, $far) = connection_pair();
	$frontend = bare_frontend(sock => $near);
	my @args;
	mock('Class::Shared::Frontend::_close' => sub { shift; @args = @_; 1 });
	$frontend->shared_close;
	is($args[1], 'the connection to the backend', 'the close says what it is closing');
	restore_all();

	# The state is cleared before the handle is closed.  A failed close carps,
	# and Carp calls can() on every object in the stack; can() asks the
	# backend, so a half-cleared frontend would write to the dying handle.
	($near, $far) = connection_pair();
	$frontend = bare_frontend(sock => $near, id => 1);
	my $state_during_close;
	mock('Class::Shared::Frontend::_close' => sub { $state_during_close = [@{$_[0]}{qw(sock id)}]; 1 });
	$frontend->shared_close;
	is_deeply($state_during_close, [undef, undef], 'the connection is already forgotten when the close happens');
	restore_all();

	($near, $far) = connection_pair();
	$frontend = bare_frontend(sock => $near, id => 1);
	close($near);    # so that the close inside shared_close fails and carps
	my @warnings = warnings_from(sub { $frontend->shared_close });
	is(scalar(@warnings), 1, 'a failed close warns once');
	my $rin = '';
	vec($rin, fileno($far), 1) = 1;
	is(select(my $rout = $rin, undef, undef, 0.05), 1, 'the peer sees the end of the stream');
	is(sysread($far, my $sent, 1), 0, 'and nothing was sent down the handle on the way');

	ok(leaves_topic_alone(sub { bare_frontend()->shared_close }), '$_ is left alone');
};

# ---------------------------------------------------------------------- DESTROY
subtest 'Class::Shared::Frontend::DESTROY' => sub {
	my $closed = 0;
	mock('Class::Shared::Frontend::shared_close' => sub { $closed++; 1 });

	{
		my ($near, $far) = connection_pair();
		my $frontend = bare_frontend(sock => $near);
	}
	is($closed, 1, 'a connected frontend closes when it goes away');

	$closed = 0;
	{ my $idle = bare_frontend(); }
	is($closed, 0, 'an unconnected one has nothing to close');
	restore_all();

	# DESTROY must not disturb an exception that is already on its way.
	my ($near, $far) = connection_pair();
	eval {
		my $doomed = bare_frontend(sock => $near);
		die "original error\n";
	};
	is($@, "original error\n", 'the error in flight survives the destruction');

	# And it must be callable by hand, and return nothing.
	my @r = bare_frontend()->DESTROY;
	is_deeply(\@r, [], 'DESTROY returns nothing');

	# The same, at global destruction time, is not testable here; what can be
	# said is that DESTROY does not run user code that could loop: it is
	# not routed through AUTOLOAD.
	my $called = 0;
	mock('Class::Shared::Frontend::AUTOLOAD' => sub { $called++ });
	{ my $f = bare_frontend(); }
	is($called, 0, 'DESTROY is a real method, not routed through AUTOLOAD');
	restore_all();
};

# -------------------------------------------------------------- shared_shutdown
subtest 'Class::Shared::Frontend::shared_shutdown' => sub {
	is(bare_frontend()->shared_shutdown, 0, 'nothing to shut down without a connection');

	my $dir = private_dir();
	my $path = File::Spec->catfile($dir, 'gone.sock');   # does not exist

	my ($near, $far) = connection_pair();
	my $frontend = bare_frontend(sock => $near, socket_path => $path);
	my (@sent, $closed);
	mock('Class::Shared::Frontend::_request' => sub { shift; push @sent, @_; return { ok => 1 } });
	mock('Class::Shared::Frontend::shared_close' => sub { $closed++; 1 });

	is($frontend->shared_shutdown, 1, 'an accepted shutdown returns 1');
	is_deeply(\@sent, [{ op => 'shutdown' }], 'the shutdown request is sent');
	is($closed, 1, 'and the connection is closed afterwards');

	# A refusal is 0, not an error.
	mock('Class::Shared::Frontend::_request' => sub { return { ok => 0 } });
	$frontend->{sock} = $near;
	is($frontend->shared_shutdown, 0, 'a refused shutdown returns 0');

	# It waits for the socket to go, but not for ever.
	open(my $fh, '>', $path) or die; close($fh);
	local $Class::Shared::Frontend::SHUTDOWN_WAIT = 1;
	local $Class::Shared::POLL_INTERVAL = 0.01;
	mock('Class::Shared::Frontend::_request' => sub { return { ok => 1 } });
	$frontend->{sock} = $near;
	my $start = time;
	is($frontend->shared_shutdown, 1, 'a socket that never disappears does not change the answer');
	cmp_ok(time - $start, '<=', 3, 'but it stops waiting after SHUTDOWN_WAIT');

	# A socket that disappears while we wait ends the wait early.
	my $pause_calls = 0;
	mock('Class::Shared::poll_pause' => sub { $pause_calls++; unlink $path; return });
	open($fh, '>', $path) or die; close($fh);
	local $Class::Shared::Frontend::SHUTDOWN_WAIT = 30;
	$frontend->{sock} = $near;
	$start = time;
	$frontend->shared_shutdown;
	cmp_ok(time - $start, '<=', 2, 'the wait ends when the socket is gone');
	is($pause_calls, 1, 'after one look');
	restore_all();

	# TCP: there is no file to wait for.
	my $tcp = bare_frontend(transport => 'tcp', socket_path => undef, host => 'h', port => 1, sock => $near);
	mock('Class::Shared::Frontend::_request' => sub { return { ok => 1 } });
	mock('Class::Shared::Frontend::shared_close' => sub { 1 });
	mock('Class::Shared::poll_pause' => sub { fail('a TCP shutdown must not wait for a file') });
	is($tcp->shared_shutdown, 1, 'TCP: no waiting');
	restore_all();

	# A lost connection is reported, but only after the cleanup.
	$frontend = bare_frontend(sock => $near, socket_path => $path);
	unlink $path;
	my $closed_before_error = 0;
	mock('Class::Shared::Frontend::_request' => sub { die "lost the backend\n" });
	mock('Class::Shared::Frontend::shared_close' => sub { $closed_before_error++; 1 });
	throws_ok { $frontend->shared_shutdown } qr/\Alost the backend\n\z/, 'a request that dies is rethrown';
	is($closed_before_error, 1, 'after the connection was closed');
	restore_all();

	$frontend->{sock} = undef;
	$tcp->{sock} = undef;
};

# ---------------------------------------------------------------------- AUTOLOAD
subtest 'Class::Shared::Frontend::AUTOLOAD' => sub {
	my $frontend = bare_frontend();

	my @seen;
	mock('Class::Shared::Frontend::_invoke' => sub { shift; @seen = @_; return ['result'] });

	is($frontend->some_method(1, 2), 'result', 'an unknown method is sent to the backend');
	is_deeply(\@seen, ['some_method', [1, 2], 'scalar'], 'with its name, arguments and context');

	my @list = $frontend->another();
	is_deeply([\@list, $seen[2]], [['result'], 'list'], 'list context is kept');

	# Names that look like something else are still just names.
	$frontend->A0();
	is($seen[0], 'A0', 'a name with a digit');
	$frontend->_private();
	is($seen[0], '_private', 'a name with a leading underscore');

	# DESTROY is never sent to the backend.
	@seen = ();
	{
		local $Class::Shared::Frontend::AUTOLOAD = 'Class::Shared::Frontend::DESTROY';
		my @r = Class::Shared::Frontend::AUTOLOAD($frontend);
		is_deeply([\@r, \@seen], [[], []], 'DESTROY is swallowed');
	}

	# A function call, or a class method, has no object to speak for.
	throws_ok { Class::Shared::Frontend->some_method }
		qr/\AClass::Shared::Frontend: 'some_method' called on something that is not a Class::Shared::Frontend object\n\z/,
		'a class method call is refused, naming the method';
	throws_ok { Class::Shared::Frontend::no_such_function() }
		qr/'no_such_function' called on something that is not/, 'a plain function call is refused';

	# The name is taken from after the last "::", so a qualified call gives
	# the backend a plain name, which it checks again.
	{
		local $Class::Shared::Frontend::AUTOLOAD = 'Storable::nstore';
		Class::Shared::Frontend::AUTOLOAD($frontend, 1);
		is($seen[0], 'nstore', 'only the last part of a qualified name is used');
	}

	restore_all();
	mock('Class::Shared::Frontend::_invoke' => sub { die "backend refused\n" });
	throws_ok { $frontend->anything } qr/\Abackend refused\n\z/, 'errors from the call reach the caller';
	restore_all();
};

# ------------------------------------------------------------------------- can
subtest 'Class::Shared::Frontend::can' => sub {
	my $frontend = bare_frontend();

	# Class-method use is the normal Perl answer.
	ok(Class::Shared::Frontend->can('new'), 'the class can new');
	ok(!Class::Shared::Frontend->can('no_such_thing'), 'and cannot do what it cannot');
	ok(Class::Shared::Frontend::can('Class::Shared::Frontend', 'shared_call'), 'called as a function too');

	is($frontend->can(undef), undef, 'undef method: undef, and no request');

	# Its own methods are answered without asking the backend.
	my $asked = 0;
	mock('Class::Shared::Frontend::_request' => sub { $asked++; return { ok => 1, result => [1] } });
	is($frontend->can('shared_call'), \&Class::Shared::Frontend::shared_call, 'its own method, honestly');
	is($asked, 0, 'without a round trip');

	# Anything else is asked of the real object.
	my @sent;
	mock('Class::Shared::Frontend::_request' => sub { shift; @sent = @_; return { ok => 1, result => [1] } });
	my $code = $frontend->can('remote_method');
	is(ref $code, 'CODE', 'a method the object has gives code');
	is_deeply(\@sent, [{ op => 'call', method => 'can', args => ['remote_method'], want => 'scalar' }],
		'the backend is asked can, with the name');

	my @invoked;
	mock('Class::Shared::Frontend::_invoke_as_called' => sub { shift; @invoked = @_; return 'called' });
	is($code->($frontend, 'x'), 'called', 'the code calls the method');
	is_deeply(\@invoked, ['remote_method', ['x']], 'with the object taken off the front');
	$code->('a', 'b');
	is_deeply(\@invoked, ['remote_method', ['a', 'b']], 'a first argument that is not this object is kept');
	$code->(bare_frontend(), 'z');
	is(scalar(@{ $invoked[1] }), 2, 'a different frontend object is an argument, not the invocant');
	$code->();
	is_deeply(\@invoked, ['remote_method', []], 'no arguments at all is fine');
	restore_all();

	# Every way for the answer to be no.
	my %no = (
		'not ok'              => { ok => 0, error => 'x' },
		'no result'           => { ok => 1 },
		'result not a list'   => { ok => 1, result => 'yes' },
		'first result false'  => { ok => 1, result => [0] },
		'empty result list'   => { ok => 1, result => [] },
		'undef first result'  => { ok => 1, result => [undef] },
	);
	foreach my $case (sort keys %no) {
		mock('Class::Shared::Frontend::_request' => sub { $no{$case} });
		is($frontend->can('remote_method'), undef, "$case gives undef");
		restore_all();
	}

	mock('Class::Shared::Frontend::_request' => sub { die "no connection\n" });
	is($frontend->can('remote_method'), undef, 'a dead connection gives undef, not an exception');
	restore_all();

	ok(leaves_topic_alone(sub { $frontend->can('shared_call') }), '$_ is left alone');
};

# ------------------------------------------------------------------------- isa
subtest 'Class::Shared::Frontend::isa' => sub {
	my $frontend = bare_frontend();

	ok(Class::Shared::Frontend->isa('Class::Shared::Frontend'), 'the class is itself');
	ok(!Class::Shared::Frontend->isa('Nothing'), 'and is nothing else');
	ok(Class::Shared::Frontend::isa('Class::Shared::Frontend', 'UNIVERSAL'), 'as a function too');

	my $asked = 0;
	mock('Class::Shared::Frontend::_request' => sub { $asked++; return { ok => 1, result => [1] } });
	is($frontend->isa('Class::Shared::Frontend'), 1, 'it is a frontend');
	is($frontend->isa('UNIVERSAL'), 1, 'and a UNIVERSAL');
	is($asked, 0, 'neither needs the backend');

	my @sent;
	mock('Class::Shared::Frontend::_request' => sub { shift; @sent = @_; return { ok => 1, result => [1] } });
	is($frontend->isa('Base::Class'), 1, 'the real class is asked');
	is_deeply(\@sent, [{ op => 'call', method => 'isa', args => ['Base::Class'], want => 'scalar' }], 'with isa and the name');

	my %answer = (
		'is a'          => [{ ok => 1, result => ['yes'] }, 1],
		'is not'        => [{ ok => 1, result => [''] },    0],
		'zero'          => [{ ok => 1, result => [0] },     0],
		'not ok'        => [{ ok => 0 },                    0],
		'no result'     => [{ ok => 1 },                    0],
		'result a string' => [{ ok => 1, result => 'x' },   0],
		'empty result'  => [{ ok => 1, result => [] },      0],
	);
	foreach my $case (sort keys %answer) {
		my ($response, $want) = @{ $answer{$case} };
		mock('Class::Shared::Frontend::_request' => sub { $response });
		is($frontend->isa('Base::Class'), $want, "$case gives $want");
		restore_all();
	}

	mock('Class::Shared::Frontend::_request' => sub { die "gone\n" });
	is($frontend->isa('Base::Class'), 0, 'a dead connection is "no", not an exception');
	restore_all();

	# No class: the normal Perl answer, with no round trip and no warning.
	mock('Class::Shared::Frontend::_request' => sub { fail('undef class must not reach the backend'); { ok => 1 } });
	my @warnings = warnings_from(sub { $frontend->isa(undef) });
	is_deeply(\@warnings, [], 'isa(undef) gives no warning');
	ok(!$frontend->isa(undef), 'and is false');
	restore_all();
};

# ------------------------------------------------------------ _invoke_as_called
subtest 'Class::Shared::Frontend::_invoke_as_called' => sub {
	my $frontend = bare_frontend();

	my @seen;
	mock('Class::Shared::Frontend::_invoke' => sub { shift; @seen = @_; return [qw(a b c)] });

	my @list = $frontend->_invoke_as_called('m', [1]);
	is_deeply(\@list, [qw(a b c)], 'list context gives every result');
	is($seen[2], 'list', 'and says list');

	my $scalar = $frontend->_invoke_as_called('m', [1]);
	is($scalar, 'a', 'scalar context gives the first');
	is($seen[2], 'scalar', 'and says scalar');

	my @void_result = (sub { $frontend->_invoke_as_called('m', [1]); return })->();
	is($seen[2], 'void', 'void context says void');

	is_deeply($seen[1], [1], 'the arguments go through');

	mock('Class::Shared::Frontend::_invoke' => sub { return [] });
	my @none = $frontend->_invoke_as_called('m', []);
	is_deeply(\@none, [], 'no results in list context is an empty list, not (undef)');
	my $nothing = $frontend->_invoke_as_called('m', []);
	is($nothing, undef, 'no results in scalar context is undef');

	# A result that is empty in a void call must not be turned into a value.
	my @in_void = (sub { $frontend->_invoke_as_called('m', []); () })->();
	is_deeply(\@in_void, [], 'void leaves nothing behind');
	restore_all();
};

# ---------------------------------------------------------------------- _invoke
subtest 'Class::Shared::Frontend::_invoke' => sub {
	my $frontend = bare_frontend(id => 12);

	my @sent;
	mock('Class::Shared::Frontend::_request' => sub { shift; @sent = @_; return { ok => 1, result => ['x'] } });
	is_deeply($frontend->_invoke('m', [1, 2], 'list'), ['x'], 'the result list is returned');
	is_deeply(\@sent, [{ op => 'call', method => 'm', args => [1, 2], want => 'list' }], 'the request has every field');

	mock('Class::Shared::Frontend::_request' => sub { { ok => 1 } });
	is_deeply($frontend->_invoke('m', [], 'scalar'), [], 'a missing result is an empty list');
	mock('Class::Shared::Frontend::_request' => sub { { ok => 1, result => 'not a list' } });
	is_deeply($frontend->_invoke('m', [], 'scalar'), [], 'a result that is not a list is an empty list');
	mock('Class::Shared::Frontend::_request' => sub { { ok => 1, result => { a => 1 } } });
	is_deeply($frontend->_invoke('m', [], 'scalar'), [], 'a hash result is an empty list');

	mock('Class::Shared::Frontend::_request' => sub { { ok => 0, error => 'it broke' } });
	throws_ok { $frontend->_invoke('m', [], 'scalar') } qr/\Ait broke\n\z/, 'the backend\'s error is the exception, with its own text';

	foreach my $empty (undef, '') {
		mock('Class::Shared::Frontend::_request' => sub { { ok => 0, error => $empty } });
		throws_ok { $frontend->_invoke('m', [], 'scalar') }
			qr/\AClass::Shared: the backend for 'Some::Class' rejected 'm'\n\z/,
			'an error with no text is given one naming class and method';
	}

	mock('Class::Shared::Frontend::_request' => sub { {} });
	throws_ok { $frontend->_invoke('m', [], 'scalar') } qr/rejected 'm'/, 'a response without ok is a refusal';
	restore_all();
};

# --------------------------------------------------------------------- _connect
subtest 'Class::Shared::Frontend::_connect' => sub {
	my $frontend = bare_frontend(autostart => 0, socket_path => '/s/x.sock');
	my ($near, $far) = connection_pair();

	my @steps;
	mock('Class::Shared::Frontend::_create_object' => sub { push @steps, 'create'; return $_[0] });

	# A backend already there.
	mock('Class::Shared::Frontend::_greet' => sub { push @steps, 'greet'; return $near });
	mock('Class::Shared::Frontend::_spawn_backend' => sub { push @steps, 'spawn'; return undef });
	is($frontend->_connect, $frontend, 'returns the frontend');
	is($frontend->{sock}, $near, 'the socket is kept');
	is_deeply(\@steps, ['greet', 'create'], 'greet, then make the object, and no spawn');
	$frontend->{sock} = undef;
	@steps = ();

	# None there, and no permission to start one.
	mock('Class::Shared::Frontend::_greet' => sub { $_[0]{last_error} = 'no socket at /s/x.sock'; return undef });
	throws_ok { $frontend->_connect }
		qr{\AClass::Shared: cannot reach a backend at /s/x\.sock: no socket at /s/x\.sock\n\z},
		'refuses to start one when autostart is off';
	is_deeply(\@steps, [], 'and neither spawns nor creates');

	mock('Class::Shared::Frontend::_greet' => sub { $_[0]{last_error} = undef; return undef });
	throws_ok { $frontend->_connect } qr/: no backend\n\z/, 'a missing reason is "no backend"';

	# TCP never starts a backend, whatever autostart says.
	my $tcp = bare_frontend(transport => 'tcp', socket_path => undef, host => 'h', port => 5, autostart => 1);
	throws_ok { $tcp->_connect } qr/cannot reach a backend at h:5: no backend\n\z/, 'TCP does not autostart';
	is_deeply(\@steps, [], 'and does not spawn');

	# Autostart: spawn, and use what it gives.
	my $starting = bare_frontend(autostart => 1, socket_path => '/s/x.sock', log => '/s/x.log');
	mock('Class::Shared::Frontend::_spawn_backend' => sub { push @steps, 'spawn'; return $near });
	$starting->_connect;
	is_deeply(\@steps, ['spawn', 'create'], 'a missing backend is started, then used');
	is($starting->{sock}, $near, 'on the socket the spawn gave');
	$starting->{sock} = undef;
	@steps = ();

	# The spawn fails: the reason and the places to look are in the message.
	mock('Class::Shared::Frontend::_spawn_backend' => sub { $_[0]{last_error} = 'no room'; return undef });
	throws_ok { $starting->_connect }
		qr{\AClass::Shared: could not start a backend: no room \(socket /s/x\.sock, log /s/x\.log\)\n\z},
		'a failed start names the reason, the socket and the log';
	mock('Class::Shared::Frontend::_spawn_backend' => sub { $_[0]{last_error} = undef; return undef });
	throws_ok { $starting->_connect } qr/could not start a backend: timed out \(/, 'no reason means "timed out"';
	is($starting->{sock}, undef, 'and no socket is kept');
	is_deeply(\@steps, [], 'no object is made without a connection');
	restore_all();
};

# ------------------------------------------------------------------------ _open
subtest 'Class::Shared::Frontend::_open' => sub {
	my $dir = private_dir();
	my $path = File::Spec->catfile($dir, 's.sock');
	my $frontend = bare_frontend(socket_path => $path);

	is($frontend->_open, undef, 'no socket: nothing to open');
	is($frontend->{last_error}, "no socket at $path", 'and says where it looked');

	open(my $fh, '>', $path) or die; close($fh);
	is($frontend->_open, undef, 'a plain file is not opened as a socket');
	is($frontend->{last_error}, "no socket at $path", 'and is not called a socket');
	unlink $path;

	# A socket nobody listens on any more.
	my $listener = listening_socket($path);
	close($listener);
	is($frontend->_open, undef, 'a socket with no listener is refused');
	like($frontend->{last_error}, qr/\Acannot connect to \Q$path\E: /, 'with the system reason');
	unlink $path;

	# A live one.
	$listener = listening_socket($path);
	my $sock = $frontend->_open;
	ok(defined $sock && defined fileno($sock), 'a live socket gives a handle');
	ok(accept(my $accepted, $listener), 'and the other end sees the connection');
	close($sock);

	# The directory decides: a socket in an open directory is not trusted.
	chmod 0777, $dir;
	my $unsafe = $frontend->_open;
	is($unsafe, undef, 'a socket in a directory others can write to is not used');
	like($frontend->{last_error}, qr/\Awill not connect to \Q$path\E: .*writable by group or others/, 'with the reason');
	chmod 0700, $dir;

	# It asks _check_endpoint, and takes its answer.
	my @asked;
	mock('Class::Shared::_check_endpoint' => sub { push @asked, @_; return (0, 'mock says no') });
	is($frontend->_open, undef, 'the verdict of _check_endpoint is final');
	is_deeply(\@asked, [$path], 'it was asked about this path');
	is($frontend->{last_error}, "will not connect to $path: mock says no", 'and its reason is used');
	restore_all();

	# TCP, with the TLS layer replaced.
	subtest 'with IO::Socket::SSL' => sub {
		test_needs 'IO::Socket::SSL';

		my $tcp = bare_frontend(
			transport => 'tcp', socket_path => undef, host => 'h.example', port => 7777, timeout => 3,
			tls_cert => 'c.pem', tls_key => 'k.pem', tls_ca => 'ca.pem',
		);

		my %args;
		mock('IO::Socket::SSL::new' => sub { shift; %args = @_; return undef });
		mock('IO::Socket::SSL::errstr' => sub { 'certificate verify failed' });
		is($tcp->_open, undef, 'a failed TLS connection gives undef');
		is($tcp->{last_error}, 'cannot connect to h.example:7777 over TLS: certificate verify failed', 'with the TLS reason');
		is_deeply([@args{qw(PeerAddr PeerPort Proto Timeout)}], ['h.example', 7777, 'tcp', 3], 'to the right place');
		is($args{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(), 'with verification on');
		is($args{SSL_ca_file}, 'ca.pem', 'against the CA');
		is($args{SSL_cert_file}, 'c.pem', 'presenting the client certificate');

		# With no TLS message the system error is used instead.
		mock('IO::Socket::SSL::errstr' => sub { '' });
		local $! = 111;
		$tcp->_open;
		like($tcp->{last_error}, qr/over TLS: .+\z/, 'an empty TLS reason falls back to the system error');
		mock('IO::Socket::SSL::errstr' => sub { undef });
		$tcp->_open;
		like($tcp->{last_error}, qr/over TLS: .+\z/, 'so does an undefined one');
		restore_all();

		# A pin replaces the CA.
		$tcp->{tls_fingerprint} = 'sha256$ab';
		$tcp->{tls_ca} = undef;
		mock('IO::Socket::SSL::new' => sub { shift; %args = @_; return undef });
		mock('IO::Socket::SSL::errstr' => sub { 'x' });
		$tcp->_open;
		is($args{SSL_fingerprint}, 'sha256$ab', 'a pin is passed on');
		ok(!exists $args{SSL_ca_file}, 'and the CA is not');
		restore_all();
	};
};

# ----------------------------------------------------------------------- _greet
subtest 'Class::Shared::Frontend::_greet' => sub {
	my ($near, $far) = connection_pair();
	my $frontend = bare_frontend(last_error => 'old problem');

	mock('Class::Shared::Frontend::_open' => sub { undef });
	my $roundtrips = 0;
	mock('Class::Shared::Frontend::_roundtrip' => sub { $roundtrips++; return ({ ok => 1 }) });
	is($frontend->_greet, undef, 'no connection: nothing to greet');
	is($roundtrips, 0, 'and nothing is sent');

	# The greeting says who is calling and what is wanted.
	my @sent;
	my @closed;
	mock('Class::Shared::Frontend::_open' => sub { $near });
	mock('Class::Shared::Frontend::_roundtrip' => sub { shift; @sent = @_; return ({ ok => 1, pid => 999 }) });
	is($frontend->_greet, $near, 'a good answer gives the socket');
	is_deeply($sent[1], { op => 'hello', proto => $Class::Shared::PROTOCOL_VERSION, class => 'Some::Class', pid => $$ },
		'the hello carries protocol version, class and pid');
	is($sent[0], $near, 'sent on that socket');
	is($frontend->shared_pid, 999, 'the backend pid is kept');
	is($frontend->shared_last_error, undef, 'the old error is cleared');

	# No answer: closed, and the reason explained.
	($near, $far) = connection_pair();
	mock('Class::Shared::Frontend::_open' => sub { $near });
	mock('Class::Shared::Frontend::_roundtrip' => sub { return (undef, 'connection closed by peer') });
	is($frontend->_greet, undef, 'no answer gives undef');
	ok(!defined fileno($near), 'and the socket is closed');
	is($frontend->{last_error}, 'handshake failed: connection closed by peer (this backend may require a token)',
		'with a hint for a unix socket');

	# A refusal is an exception, with the backend's own words.
	($near, $far) = connection_pair();
	mock('Class::Shared::Frontend::_open' => sub { $near });
	mock('Class::Shared::Frontend::_roundtrip' => sub { return ({ ok => 0, error => 'protocol mismatch' }) });
	throws_ok { $frontend->_greet } qr/\AClass::Shared: protocol mismatch\n\z/, 'a refused hello dies with the reason';
	ok(!defined fileno($near), 'and the socket is closed');

	($near, $far) = connection_pair();
	mock('Class::Shared::Frontend::_open' => sub { $near });
	foreach my $empty (undef, '') {
		mock('Class::Shared::Frontend::_roundtrip' => sub { return ({ ok => 0, error => $empty }) });
		throws_ok { $frontend->_greet } qr/\AClass::Shared: the backend refused the handshake\n\z/, 'a refusal with no words gets some';
		($near, $far) = connection_pair();
		mock('Class::Shared::Frontend::_open' => sub { $near });
	}
	restore_all();
};

# ------------------------------------------------------- _first_exchange_failed
subtest 'Class::Shared::Frontend::_first_exchange_failed' => sub {
	my $unix = bare_frontend();
	my $tcp = bare_frontend(transport => 'tcp');
	my $tcp_token = bare_frontend(transport => 'tcp', token => 'secret');
	my $unix_token = bare_frontend(token => 'secret');

	is($unix->_first_exchange_failed('boom'), 'boom (this backend may require a token)', 'unix, no token: the hint');
	is($unix_token->_first_exchange_failed('boom'), 'boom', 'with a token the hint is not repeated');

	foreach my $closing ('connection closed by peer', 'read failed: x', 'write failed: y') {
		my $said = $tcp->_first_exchange_failed($closing);
		like($said, qr/\Athe backend refused this client's certificate: check that tls_cert and tls_key are a certificate it accepts, and that tls_ca holds the CA it trusts for clients \(detail: \Q$closing\E\)\z/,
			"TCP: '$closing' points at the certificate");
		is($tcp_token->_first_exchange_failed($closing), $said, '  and a token does not change that');
	}

	is($tcp->_first_exchange_failed('frame failed authentication'), 'frame failed authentication (this backend may require a token)',
		'TCP: another failure keeps the token wording');
	is($tcp_token->_first_exchange_failed('frame failed authentication'), 'frame failed authentication',
		'TCP with a token: just the error');

	# Wording for a unix socket is never about certificates.
	unlike($unix->_first_exchange_failed('connection closed by peer'), qr/certificate/, 'unix: not about certificates');

	# No error text at all must not warn.
	my @warnings = warnings_from(sub { $unix->_first_exchange_failed(undef); $tcp->_first_exchange_failed(undef) });
	is_deeply(\@warnings, [], 'an undefined error gives no warning');
};

# -------------------------------------------------------------- _create_object
subtest 'Class::Shared::Frontend::_create_object' => sub {
	my $frontend = bare_frontend(ctor => ['a', 'b']);

	my @sent;
	mock('Class::Shared::Frontend::_request' => sub { shift; @sent = @_; return { ok => 1, id => 17 } });
	is($frontend->_create_object, $frontend, 'returns the frontend');
	is($frontend->shared_id, 17, 'the object id is kept');
	is_deeply(\@sent, [{ op => 'new', args => ['a', 'b'] }, $frontend->{timeout}], 'the constructor arguments are sent, with the frontend\'s timeout as the wait');

	# A failure ends the connection too: a half-made object is not kept.
	my $closed = 0;
	mock('Class::Shared::Frontend::shared_close' => sub { $closed++; 1 });
	mock('Class::Shared::Frontend::_request' => sub { { ok => 0, error => 'cannot construct' } });
	$frontend->{id} = undef;
	throws_ok { $frontend->_create_object } qr/\AClass::Shared: could not construct Some::Class: cannot construct\n\z/,
		'a failed constructor dies with the reason';
	is($closed, 1, 'after closing the connection');
	is($frontend->shared_id, undef, 'and no id is kept');

	foreach my $empty (undef, '', 0) {
		mock('Class::Shared::Frontend::_request' => sub { { ok => 0, error => $empty } });
		throws_ok { $frontend->_create_object } qr/: the backend gave no reason\n\z/, 'no reason gets some';
	}

	mock('Class::Shared::Frontend::_request' => sub { die "lost the backend\n" });
	throws_ok { $frontend->_create_object } qr/\Alost the backend\n\z/, 'a lost connection passes through';
	restore_all();
};

# --------------------------------------------------------------------- _request
subtest 'Class::Shared::Frontend::_request' => sub {
	my ($near, $far) = connection_pair();
	my $frontend = bare_frontend(sock => $near, id => 21);

	my @args;
	mock('Class::Shared::Frontend::_roundtrip' => sub { shift; @args = @_; return ({ ok => 1, via => 'mock' }) });

	is_deeply($frontend->_request({ op => 'call', method => 'm' }), { ok => 1, via => 'mock' }, 'the response is returned');
	is($args[0], $near, 'sent on the connection');
	is($args[1]{id}, 21, 'a call carries the object id');

	$frontend->_request({ op => 'ping' });
	ok(!exists $args[1]{id}, 'a ping does not');
	$frontend->_request({ op => 'new' });
	ok(!exists $args[1]{id}, 'neither does a new');
	$frontend->_request({});
	ok(!exists $args[1]{id}, 'nor a message with no op');
	$frontend->_request({ op => 'call', id => 999 });
	is($args[1]{id}, 21, 'a call cannot choose its own object');

	# A failed exchange ends the connection: its state is unknown.
	mock('Class::Shared::Frontend::_roundtrip' => sub { return (undef, 'connection closed by peer') });
	throws_ok { $frontend->_request({ op => 'ping' }) }
		qr/\AClass::Shared: lost the backend for 'Some::Class': connection closed by peer\n\z/, 'a failed exchange dies with the reason';
	is($frontend->shared_connected, 0, 'and the connection is closed');
	is($frontend->shared_last_error, 'connection closed by peer', 'and the reason is kept');
	restore_all();

	# Without a connection nothing is attempted.
	my $tried = 0;
	mock('Class::Shared::Frontend::_roundtrip' => sub { $tried++; ({ ok => 1 }) });
	throws_ok { $frontend->_request({ op => 'ping' }) }
		qr/\AClass::Shared: this frontend has no connection to a backend for 'Some::Class'; its object is gone\n\z/,
		'a closed frontend says so';
	is($tried, 0, 'and sends nothing');
	restore_all();

	ok(leaves_topic_alone(sub {
		my ($n, $f) = connection_pair();
		peer_replies($f, undef, { ok => 1 });
		bare_frontend(sock => $n)->_request({ op => 'ping' });
	}), '$_ is left alone');
};

# ------------------------------------------------------------------- _roundtrip
subtest 'Class::Shared::Frontend::_roundtrip' => sub {
	my ($near, $far) = connection_pair();
	my $frontend = bare_frontend();

	peer_replies($far, undef, { ok => 1, n => 1 });
	my @r = $frontend->_roundtrip($near, { op => 'ping' });
	is_deeply(\@r, [{ ok => 1, n => 1 }], 'the response is returned alone');
	is_deeply(peer_request($far), { op => 'ping' }, 'and the request went out');

	# With a token both directions are signed.
	my $signed = bare_frontend(token => $config{secret});
	peer_replies($far, $config{secret}, { ok => 1 });
	@r = $signed->_roundtrip($near, { op => 'ping' });
	is_deeply(\@r, [{ ok => 1 }], 'a signed reply is accepted');
	is_deeply(peer_request($far, $config{secret}), { op => 'ping' }, 'the request was signed');

	peer_replies($far, $config{other_secret}, { ok => 1 });
	@r = $signed->_roundtrip($near, { op => 'ping' });
	is_deeply(\@r, [undef, 'frame failed authentication'], 'a reply signed with another secret is refused');
	peer_request($far, $config{secret});

	# Nothing is sent if the message cannot be encoded.
	@r = $frontend->_roundtrip($near, { op => 'call', args => [sub { 1 }] });
	is($r[0], undef, 'an argument that cannot be sent is refused');
	like($r[1], qr/\Acannot serialise message: /, 'with the reason');
	{
		my $rin = '';
		vec($rin, fileno($far), 1) = 1;
		is(select(my $rout = $rin, undef, undef, 0), 0, 'and nothing was written');
	}

	# A message over the limit is refused before it is written.
	{
		local $Class::Shared::Protocol::MAX_FRAME = 16;
		@r = $frontend->_roundtrip($near, { op => 'call', args => ['x' x 100] });
		like($r[1], qr/\Amessage is too large/, 'an oversize request is refused');
	}

	# A reply that is not a hash.
	peer_replies($far, undef, ['not', 'a', 'hash']);
	@r = $frontend->_roundtrip($near, { op => 'ping' });
	is_deeply(\@r, [undef, 'malformed response from the backend'], 'a list reply is malformed');
	peer_request($far);
	peer_replies($far, undef, \'scalar ref');
	@r = $frontend->_roundtrip($near, { op => 'ping' });
	is_deeply(\@r, [undef, 'malformed response from the backend'], 'a scalar reference reply is malformed');
	peer_request($far);

	# The peer goes away at each point.
	close($far);
	@r = $frontend->_roundtrip($near, { op => 'ping' });
	is($r[0], undef, 'a closed peer is a failure');
	like($r[1], qr/\A(?:write failed|connection closed by peer|read failed)/, 'with a reason');
};

# ----------------------------------------------------------------------- _close
subtest 'Class::Shared::Frontend::_close' => sub {
	my $frontend = bare_frontend();
	my ($near, $far) = connection_pair();

	my @warnings = warnings_from(sub { is($frontend->_close($near, 'a socket'), 1, 'closing an open handle returns 1') });
	is_deeply(\@warnings, [], 'and says nothing');

	@warnings = warnings_from(sub { is($frontend->_close($near, 'a socket'), 0, 'closing a closed handle returns 0') });
	is(scalar(@warnings), 1, 'with one warning');
	like($warnings[0], qr/\AClass::Shared::Frontend: cannot close a socket: .+ at /, 'naming what it was closing');
	like($warnings[0], qr/function\.t line \d+/, 'at the caller\'s line, as carp does');

};

# ------------------------------------------------------------- _spawn_backend
subtest 'Class::Shared::Frontend::_spawn_backend' => sub {
	my $base = private_dir();
	my $socket_path = File::Spec->catfile($base, 'sp.sock');
	my $frontend = bare_frontend(socket_path => $socket_path, timeout => 1, log => "$socket_path.log");

	# The directory is made safe first; if it cannot be, nothing else happens.
	my @made;
	mock('Class::Shared::ensure_dir' => sub { @made = @_; return (0, 'the directory is no good') });
	my $forked = 0;
	mock('Class::Shared::Frontend::_exec_backend' => sub { $forked++; POSIX::_exit(0) });
	is($frontend->_spawn_backend, undef, 'an unsafe directory gives no backend');
	is($frontend->{last_error}, 'the directory is no good', 'with the reason');
	is_deeply(\@made, [$base], 'ensure_dir was asked about the socket\'s directory');
	ok(!-e "$socket_path.spawn", 'and no lock file was made');
	restore_all();

	# A lock file that cannot be created.
	my $missing_dir = File::Spec->catdir($base, 'no-such');
	my $orphan = bare_frontend(socket_path => File::Spec->catfile($missing_dir, 's.sock'), timeout => 1);
	mock('Class::Shared::ensure_dir' => sub { (1, undef) });
	is($orphan->_spawn_backend, undef, 'a lock that cannot be opened gives no backend');
	like($orphan->{last_error}, qr/\Acannot open \Q$missing_dir\E\/s\.sock\.spawn: No such file or directory\z/, 'with the reason');
	restore_all();

	# Somebody else started one while we waited: it is used, nothing is forked.
	my ($near, $far) = connection_pair();
	my $exec_calls = 0;
	mock('Class::Shared::Frontend::_exec_backend' => sub { $exec_calls++; POSIX::_exit(0) });
	mock('Class::Shared::Frontend::_greet' => sub { $near });
	is($frontend->_spawn_backend, $near, 'a backend that answers once the lock is held is used');
	is($exec_calls, 0, 'and no second one is started');
	restore_all();

	# The lock is released afterwards, whatever the outcome.
	open(my $probe, '+>>', "$socket_path.spawn") or die;
	ok(flock($probe, Fcntl::LOCK_EX() | Fcntl::LOCK_NB()), 'the lock is free again');
	close($probe);

	# Something that is not a socket is never removed to make room.
	open(my $keep, '>', $socket_path) or die; print {$keep} "precious\n"; close($keep);
	mock('Class::Shared::Frontend::_greet' => sub { undef });
	mock('Class::Shared::Frontend::_exec_backend' => sub { $exec_calls++; POSIX::_exit(0) });
	is($frontend->_spawn_backend, undef, 'a file in the socket\'s place stops the start');
	is($frontend->{last_error}, "$socket_path exists and is not a socket; refusing to remove it", 'with the exact reason');
	ok(-f $socket_path, 'and the file is still there');
	is($exec_calls, 0, 'and nothing was forked');
	unlink $socket_path;
	restore_all();

	# A stale socket is removed, and a backend is waited for.
	my $stale = listening_socket($socket_path);
	close($stale);
	ok(-S $socket_path, 'a stale socket is in place');
	my $greets = 0;
	mock('Class::Shared::Frontend::_greet' => sub { $greets++; return $greets > 1 ? $near : undef });
	mock('Class::Shared::Frontend::_exec_backend' => sub { $exec_calls++; POSIX::_exit(0) });
	is($frontend->_spawn_backend, $near, 'a backend that answers after the start is used');
	ok(!-e $socket_path, 'the stale socket was removed first');
	restore_all();

	# A start that never produces a backend gives up at the timeout.
	my $slow = bare_frontend(socket_path => $socket_path, timeout => 1, log => "$socket_path.log");
	mock('Class::Shared::Frontend::_greet' => sub { undef });
	mock('Class::Shared::Frontend::_exec_backend' => sub { POSIX::_exit(0) });
	local $Class::Shared::POLL_INTERVAL = 0.01;
	my $start = time;
	is($slow->_spawn_backend, undef, 'no answer by the deadline gives undef');
	cmp_ok(time - $start, '<=', 4, 'within about the timeout');
	restore_all();

	# The child that only forks the daemon is collected, not left a zombie.
	is(waitpid(-1, 1), -1, 'no child process is left over');

	# A handshake that a running backend refuses is its final answer: it is thrown
	# as it is (the POD lists "cannot load CLASS" as a message of its own), and the
	# start lock is released so that the next client is not kept waiting.
	mock('Class::Shared::Frontend::_greet' => sub { my $self = shift; die "Class::Shared: version mismatch\n" if $self->{polled}++; undef });
	mock('Class::Shared::Frontend::_exec_backend' => sub { POSIX::_exit(0) });
	my $refused = bare_frontend(socket_path => $socket_path, timeout => 0, log => "$socket_path.log");
	throws_ok { $refused->_spawn_backend } qr/\AClass::Shared: version mismatch\n\z/, 'a refusal while waiting is thrown as it is';
	restore_all();
	my $probe_lock;
	ok(open($probe_lock, '>>', "$socket_path.spawn") && flock($probe_lock, Fcntl::LOCK_EX() | Fcntl::LOCK_NB()), 'and the start lock was released');
	close($probe_lock) if $probe_lock;

	# A stale socket that cannot be removed: the directory is read-only.
	SKIP: {
		skip 'root can remove files from any directory', 3 if $IS_ROOT;
		my $locked = private_dir();
		my $locked_path = File::Spec->catfile($locked, 'l.sock');
		my $l = listening_socket($locked_path);
		close($l);
		my $victim = bare_frontend(socket_path => $locked_path, timeout => 1);
		mock('Class::Shared::Frontend::_greet' => sub { undef });
		mock('Class::Shared::Frontend::_exec_backend' => sub { $exec_calls++; POSIX::_exit(0) });
		mock('Class::Shared::ensure_dir' => sub { (1, undef) });
		# The lock files have to be openable, so make them first (a dead backend
		# leaves its .owner behind), then close the directory.
		for my $suffix (qw(spawn owner)) {
			open(my $pre, '>', "$locked_path.$suffix") or die; close($pre);
		}
		chmod 0500, $locked;
		is($victim->_spawn_backend, undef, 'a stale socket that cannot be removed gives no backend');
		like($victim->{last_error}, qr/\Acannot remove the stale socket \Q$locked_path\E: Permission denied\z/, 'with the reason');
		ok(-S $locked_path, 'and it is still there');
		chmod 0700, $locked;
		restore_all();
	}
};

# --------------------------------------------------------------- _exec_backend
# The function replaces the process, so it runs in a grandchild and the
# program it runs is a script that writes down what it was given.
subtest 'Class::Shared::Frontend::_exec_backend' => sub {
	require POSIX;
	my $dir = private_dir();
	my $report = File::Spec->catfile($dir, 'report');
	my $log = File::Spec->catfile($dir, 'backend.log');
	my $socket = File::Spec->catfile($dir, 'b.sock');

	my $stand_in = File::Spec->catfile($dir, 'fake-perl');
	open(my $script, '>', $stand_in) or die;
	print {$script} <<"SH";
#!/bin/sh
{
	for argument in "\$@"; do printf 'arg:%s\\n' "\$argument"; done
	if [ -d /proc/\$\$/fd ]; then
		for descriptor in /proc/\$\$/fd/*; do printf 'fd:%s\\n' "\${descriptor##*/}"; done
	fi
} > '$report.tmp'
mv '$report.tmp' '$report'
SH
	close($script);
	chmod 0755, $stand_in;

	my $frontend = bare_frontend(socket_path => $socket, log => $log);

	# Start it in a child so that this process is not replaced.
	my $run = sub {
		my ($perl, $lock) = @_;
		unlink $report;
		my $pid = fork() // die "fork: $!";
		if (!$pid) {
			$^X = $perl;
			# A descriptor that belongs to the client and must not leak.
			open(my $leak, '<', $0) or POSIX::_exit(99);
			POSIX::dup2(fileno($leak), 200);
			$frontend->_exec_backend($lock);
			POSIX::_exit(98);
		}
		waitpid($pid, 0);
		my $waited = 0;
		while (!-e $report && $waited++ < 100) { select(undef, undef, undef, 0.05) }
		return $? >> 8;
	};

	is($run->($stand_in), 0, 'the first child exits at once, successfully: the daemon is a grandchild');

	my @lines;
	if (open(my $in, '<', $report)) { chomp(@lines = <$in>) }
	state_of("exec_backend report:\n" . join("\n", @lines));
	my @arguments = map { s/\Aarg://r } grep { /\Aarg:/ } @lines;

	ok(@arguments >= 4, 'the program was run') or BAIL_OUT('exec_backend did not run the stand-in program');
	is_deeply([@arguments[-5 .. -3]], ['-MClass::Shared::Backend', '-e', 'Class::Shared::Backend->new(socket => $ARGV[0], log => $ARGV[1])->run()'],
		'it loads the backend and runs it');
	is_deeply([@arguments[-2, -1]], [$socket, $log], 'with the socket and log as its arguments');

	my @includes = @arguments[0 .. $#arguments - 5];
	my @paired = grep { $includes[$_] eq '-I' } 0 .. $#includes;
	ok(scalar(@paired) > 0, 'the include path is passed on');
	is_deeply([map { $includes[$_ + 1] } @paired], [grep { defined && !ref && length } @INC],
		'exactly the plain directories of @INC, in order');

	SKIP: {
		my @descriptors = map { s/\Afd://r } grep { /\Afd:/ } @lines;
		skip 'no /proc to list the descriptors', 2 unless @descriptors;
		ok(!(grep { $_ == 200 } @descriptors), 'a descriptor the client held is not inherited');
		is_deeply([sort { $a <=> $b } grep { $_ < 3 } @descriptors], [0, 1, 2], 'only the standard streams remain below 3');
	}

	# The daemon's output goes to the log, and its input is the null device.
	ok(-e $log, 'the log was opened');

	# A perl that cannot be run must end the child and leave nothing behind.
	unlink $report;
	is($run->(File::Spec->catfile($dir, 'no-such-perl')), 0, 'an unusable perl still returns control to the parent');
	ok(!-e $report, 'and no backend ran');

	# A lock handle that is open is closed in the child.
	open(my $lock, '>', File::Spec->catfile($dir, 'lock')) or die;
	is($run->($stand_in, $lock), 0, 'a lock is accepted');
	close($lock);
};

# ===========================================================================
# Class::Shared::Backend
# ===========================================================================

# A class for the backend to hold objects of: it counts, remembers when it is
# destroyed, and can be told to fail.
{
	package Test::Held;

	our @DESTROYED;
	our $AUTOLOADED = 0;

	sub new {
		my ($class, @args) = @_;
		die "refused to construct\n" if @args && $args[0] eq 'die';
		return 'not an object' if @args && $args[0] eq 'scalar';
		return bless { n => 0, args => [@args] }, $class;
	}
	sub add     { $_[0]{n} += $_[1] // 1; return $_[0]{n} }
	sub list    { return (1, 2, 3) }
	sub nothing { return }
	sub undef_  { return undef }
	sub context { return wantarray ? 'list' : defined(wantarray) ? 'scalar' : 'void' }
	sub boom    { die "it broke\n" }
	sub DESTROY { push @DESTROYED, $_[0]{n} }
}

# A class that answers every method by AUTOLOAD, to see that the backend
# does not refuse a method only because it cannot be seen with can.
{
	package Test::Dynamic;

	sub new      { return bless {}, shift }
	sub AUTOLOAD { our $AUTOLOAD; return 'dynamic:' . ($AUTOLOAD =~ s/\A.*:://r) }
	sub DESTROY  { }
}

# A backend that has not started: its options are checked and its fields are
# set, nothing is bound or opened.  The log is in a directory of its own.
sub make_backend {
	my (%option) = @_;

	my $dir = $option{dir_for_files} // private_dir();
	delete $option{dir_for_files};

	my %defaults = (socket => File::Spec->catfile($dir, 'b.sock'), log => File::Spec->catfile($dir, 'b.log'));
	my $backend = Class::Shared::Backend->new(%defaults, %option);
	$backend->{_test_dir} = $dir;

	return $backend;
}

# A client record the way _accept makes one, around a socket the test holds
# the other end of.
sub make_client {
	my (%field) = @_;

	my ($near, $far) = connection_pair();

	my $client = {
		fh      => $near,
		buffer  => '',
		outbuf  => '',
		greeted => 0,
		serial  => 1,
		objects => {},
		closed  => 0,
		%field,
	};

	return ($client, $far);
}

# What a method wrote to the log, read back.
sub log_text {
	my ($backend) = @_;

	open(my $fh, '<', $backend->{log}) or return '';
	my $text = do { local $/; <$fh> };
	close($fh);

	return defined $text ? $text : '';
}

# Collect what _log was asked to write, without a logger.
sub capture_log {
	my ($backend) = @_;

	my @lines;
	mock('Class::Shared::Backend::_log' => sub { push @lines, [@_[1, 2]]; return 1 });

	return \@lines;
}

# ------------------------------------------------------------------------- new
subtest 'Class::Shared::Backend::new' => sub {
	my $dir = private_dir();
	my $socket = File::Spec->catfile($dir, 'b.sock');
	my $prefix = qr/\AClass::Shared::Backend->new: /;
	my %tcp = (host => '127.0.0.1', port => 7777, token => 'secret', tls_cert => 'c', tls_key => 'k', tls_ca => 'ca');

	my $backend = Class::Shared::Backend->new(socket => $socket);
	isa_ok($backend, 'Class::Shared::Backend');
	is($backend->{socket}, $socket, 'the socket is kept');
	is($backend->{control}, $socket, 'and is the control path');
	is($backend->{log}, "$socket.log", 'the log defaults to beside it');
	is_deeply([@{$backend}{qw(max_clients max_objects daemonize)}], [128, 4096, 0], 'the usual limits');
	is($backend->{max_queued}, $Class::Shared::Backend::MAX_QUEUED, 'one frame may be queued');
	is($backend->{max_queued_total}, 4 * $backend->{max_queued}, 'and four times that in all');
	is_deeply([@{$backend}{qw(write_timeout handshake_timeout start_timeout)}], [30, 5, 2], 'the usual timeouts');
	is_deeply([@{$backend}{qw(clients objects classes)}], [{}, {}, {}], 'nothing is held yet');
	is_deeply([@{$backend}{qw(queued next_id next_serial calls constructed stop cleaned owns_socket)}], [0, 1, 1, 0, 0, 0, 0, 0],
		'every counter starts at its start');
	is_deeply([@{$backend}{qw(listener lock logger address)}], [undef, undef, undef, undef], 'nothing is open');

	# Ways of passing the arguments.
	is(Class::Shared::Backend->new({ socket => $socket, max_clients => 3 })->{max_clients}, 3, 'a hash reference');
	is(Class::Shared::Backend->new(socket => $socket, max_clients => '3')->{max_clients}, 3, 'a number given as text');
	is(Class::Shared::Backend->new(socket => $socket, max_clients => undef)->{max_clients}, 128, 'undef is "not given"');
	lives_ok { Class::Shared::Backend->new(dir => $dir) } 'a directory alone is enough';
	is(Class::Shared::Backend->new(dir => $dir)->{socket}, File::Spec->catfile($dir, 'class-shared.sock'), 'it names the one socket');

	# Defaults are read when new runs, so a program can set them first.
	{
		local $Class::Shared::Backend::DEFAULT_MAX_CLIENTS = 9;
		local $Class::Shared::Backend::WRITE_TIMEOUT = 11;
		my $b = Class::Shared::Backend->new(socket => $socket);
		is_deeply([@{$b}{qw(max_clients write_timeout)}], [9, 11], 'package defaults are read at call time');
		is(Class::Shared::Backend->new(socket => $socket, max_clients => 2)->{max_clients}, 2, 'an argument still wins');
	}

	# A log called "0" is a name, not "no log".
	is(Class::Shared::Backend->new(socket => $socket, log => '0')->{log}, '0', 'a log named 0 is kept');

	# Values that are not allowed.
	my %bad = (
		'an unknown option'        => [bogus => 1],
		'a zero port'              => [%tcp, port => 0],
		'a port that is too big'   => [%tcp, port => 65536],
		'a port that is text'      => [%tcp, port => 'http'],
		'a fractional port'        => [%tcp, port => 80.5],
		'zero clients'             => [max_clients => 0],
		'negative objects'         => [max_objects => -1],
		'a text count'             => [max_clients => 'many'],
		'a negative timeout'       => [write_timeout => -1],
		'an empty socket'          => [socket => ''],
		'a token with a new line'  => [%tcp, token => "a\nb"],
		'a token with a wide char' => [%tcp, token => "caf\x{e9}"],
		'a hash as the socket'     => [socket => {}],
	);
	foreach my $name (sort keys %bad) {
		throws_ok { Class::Shared::Backend->new(socket => $socket, @{ $bad{$name} }) } qr/${prefix}an argument is not valid: /, "refuses $name";
	}

	# Rules that need more than one option.
	my %refused = (
		'a host without a port'  => [qr/a TCP listener needs both host and port\n\z/, %tcp, port => undef],
		'a port without a host'  => [qr/a TCP listener needs both host and port\n\z/, %tcp, host => undef],
		'a socket and a host'    => [qr/use either socket or host\/port, not both\n\z/, %tcp, socket => $socket],
		'TCP with no token'      => [qr/a TCP listener needs a token: without one it would thaw whatever arrives\n\z/, %tcp, token => undef],
		'TCP with an empty token' => [qr/a TCP listener needs a token/, %tcp, token => ''],
		'TCP with no certificate' => [qr/needs tls_cert, tls_key and tls_ca: without them the traffic would be readable to anyone who can route to it\n\z/, %tcp, tls_cert => undef],
		'TCP with no key'        => [qr/needs tls_cert, tls_key and tls_ca/, %tcp, tls_key => undef],
		'TCP with no CA'         => [qr/needs tls_cert, tls_key and tls_ca/, %tcp, tls_ca => undef],
		'TCP with an empty CA'   => [qr/needs tls_cert, tls_key and tls_ca/, %tcp, tls_ca => ''],
		'a unix token'           => [qr/a unix socket needs no token: its mode 0600 file already decides who may connect\n\z/, socket => $socket, token => 'x'],
		'a unix TLS file'        => [qr/a unix socket needs no TLS: /, socket => $socket, tls_ca => 'x'],
	);
	foreach my $name (sort keys %refused) {
		my ($pattern, @args) = @{ $refused{$name} };
		throws_ok { Class::Shared::Backend->new(@args) } $pattern, "refuses $name";
	}
	lives_ok { Class::Shared::Backend->new(socket => $socket, token => '') } 'an empty token on a unix socket is "no token"';

	# A TCP listener keeps its control files where a socket would have been.
	my $tcp_backend = Class::Shared::Backend->new(%tcp, dir => $dir);
	is($tcp_backend->{control}, File::Spec->catfile($dir, 'class-shared.sock'), 'TCP: the control path is the default socket name');
	is($tcp_backend->{log}, File::Spec->catfile($dir, 'class-shared.sock.log'), 'and the log is beside it');
	is($tcp_backend->{socket}, undef, 'TCP: there is no socket');
	is($tcp_backend->{address}, undef, 'and no address before setup');

	# The environment sits between the caller and the site, and the caller wins.
	{
		local $ENV{Class__Shared__Backend__max_clients} = 5;
		is(Class::Shared::Backend->new(socket => $socket)->{max_clients}, 5, 'the environment can set an option');
		is(Class::Shared::Backend->new(socket => $socket, max_clients => 6)->{max_clients}, 6, 'but the caller wins');
	}
	{
		local $ENV{Class__Shared__Backend__max_clients} = 'lots';
		throws_ok { Class::Shared::Backend->new(socket => $socket) } qr/${prefix}a configured value is not valid: /,
			'a bad configured value is named as configured';
	}

	# The caller's hash is not changed.
	my %given = (socket => $socket, max_clients => '4');
	Class::Shared::Backend->new(\%given);
	is_deeply(\%given, { socket => $socket, max_clients => '4' }, 'the options hash is left as it was');

	memory_cycle_ok($backend, 'a new backend holds no loop');
	ok(leaves_topic_alone(sub { Class::Shared::Backend->new(socket => $socket) }), '$_ is left alone');
};

# --------------------------------------------------------------------- _refuse
subtest 'Class::Shared::Backend::_refuse' => sub {
	throws_ok { Class::Shared::Backend::_refuse('a reason') }
		qr/\AClass::Shared::Backend->new: a reason\n\z/, 'prefix, reason, and one line break';
	throws_ok { Class::Shared::Backend::_refuse('') } qr/\AClass::Shared::Backend->new: \n\z/, 'an empty reason is still in the form';

	# The line break means die adds no file and line.
	eval { Class::Shared::Backend::_refuse('x') };
	unlike($@, qr/ at .* line \d+/, 'no file and line in the message');
};

# ------------------------------------------------------------------- _validate
subtest 'Class::Shared::Backend::_validate' => sub {
	my $valid = Class::Shared::Backend::_validate({ max_clients => '7', daemonize => 1 }, 'an argument');
	is($valid->{max_clients}, 7, 'a number given as text is a number');
	is(ref $valid, 'HASH', 'a hash reference comes back');
	is_deeply(Class::Shared::Backend::_validate({}, 'an argument'), {}, 'no options is fine, every option being optional');

	foreach my $source ('an argument', 'a configured value') {
		throws_ok { Class::Shared::Backend::_validate({ max_clients => 0 }, $source) }
			qr/\AClass::Shared::Backend->new: \Q$source\E is not valid: /, "the source '$source' is in the message";
	}

	# The validator's own source file and line are no help to a person.
	eval { Class::Shared::Backend::_validate({ bogus => 1 }, 'an argument') };
	like($@, qr/bogus/, 'the offending option is named');
	unlike($@, qr/Params::Validate::Strict line \d+/, 'the validator\'s location is removed');
	unlike($@, qr/ at \S+ line \d+\.?\s*\z/, 'and so is the trailing location');
	like($@, qr/\n\z/, 'the message is one line');
	unlike($@, qr/\n.*\n/s, 'and only one');

	# A validator that dies without text still gives an explanation.
	mock('Params::Validate::Strict::validate_strict' => sub { die '' });
	throws_ok { Class::Shared::Backend::_validate({}, 'an argument') } qr/is not valid: (?:invalid options|Died)/, 'an empty failure is explained';
	mock('Params::Validate::Strict::validate_strict' => sub { return undef });
	throws_ok { Class::Shared::Backend::_validate({}, 'an argument') } qr/is not valid: /, 'a validator that returns nothing is a refusal';
	restore_all();

	ok(leaves_topic_alone(sub { Class::Shared::Backend::_validate({}, 'x') }), '$_ is left alone');
};

# -------------------------------------------------------------------- _options
subtest 'Class::Shared::Backend::_options' => sub {
	my $class = 'Class::Shared::Backend';

	is_deeply($class->can('_options')->($class, undef), {}, 'no arguments, no settings: nothing');
	is_deeply($class->can('_options')->($class, {}), {}, 'an empty hash too');
	is_deeply($class->can('_options')->($class, { max_clients => 3 }), { max_clients => 3 }, 'what was given');
	is_deeply($class->can('_options')->($class, { max_clients => 3, max_objects => undef }), { max_clients => 3 }, 'undef is not given');

	# Site settings come through Object::Configure, with the caller's values
	# kept out of it so that they cannot be outranked.
	my @configure_args;
	mock('Object::Configure::configure' => sub {
		@configure_args = @_;
		return { max_clients => 7, max_objects => 8, token => undef, logger => 'x', config_path => '/y', junk => 1 };
	});
	is_deeply($class->can('_options')->($class, { max_clients => 3 }), { max_clients => 3, max_objects => 8 },
		'the caller wins over the site, and the rest of the site is added');
	is_deeply($class->can('_options')->($class, {}), { max_clients => 7, max_objects => 8 },
		'site settings alone: only the options this class knows, and only those that are set');
	is($configure_args[0], $class, 'configure is told which class');
	is($configure_args[1]{logger}, 'NULL', 'and that no logger is wanted');
	ok(!exists $configure_args[1]{max_clients}, 'the caller\'s own values are not handed to it');

	# The two locators go to configure and are not kept.
	is_deeply($class->can('_options')->($class, { config_file => 'x.yml', config_dirs => ['/d'], max_clients => 1 }),
		{ max_clients => 1, max_objects => 8 }, 'config_file and config_dirs are not options of the backend');
	is($configure_args[1]{config_file}, 'x.yml', 'config_file is passed to configure');
	is_deeply($configure_args[1]{config_dirs}, ['/d'], 'config_dirs is passed to configure');

	# A configured value is checked the same way.
	mock('Object::Configure::configure' => sub { { max_clients => 'lots' } });
	throws_ok { $class->can('_options')->($class, {}) } qr/a configured value is not valid/, 'a bad site value is refused';

	# What the caller passed is checked first, so a typo is theirs.
	mock('Object::Configure::configure' => sub { { max_clients => 'lots' } });
	throws_ok { $class->can('_options')->($class, { bogus => 1 }) } qr/an argument is not valid: .*bogus/s, 'a bad argument is reported before a bad site value';
	restore_all();

	# configure is not asked when the caller's arguments are already wrong.
	my $asked = 0;
	mock('Object::Configure::configure' => sub { $asked++; {} });
	eval { $class->can('_options')->($class, { bogus => 1 }) };
	is($asked, 0, 'the site is not consulted for a call that is refused anyway');
	restore_all();
};

# ------------------------------------------------------------------------- run
subtest 'Class::Shared::Backend::run' => sub {
	my $backend = make_backend();
	my @steps;
	my $logged = capture_log($backend);
	mock('Class::Shared::Backend::_daemonize' => sub { push @steps, 'daemonize' });
	mock('Class::Shared::Backend::_setup'     => sub { push @steps, 'setup'; $_[0]{address} = '/the/socket'; 1 });
	mock('Class::Shared::Backend::_loop'      => sub { push @steps, 'loop' });
	mock('Class::Shared::Backend::_cleanup'   => sub { push @steps, 'cleanup' });

	is($backend->run, 0, 'a clean run returns 0');
	is_deeply(\@steps, ['setup', 'loop', 'cleanup'], 'set up, serve, clean up, and no daemonizing unless asked');
	like($logged->[0][0], qr{\Aserving on /the/socket \(pid \d+\)\z}, 'it says where it serves');
	is($logged->[-1][0], 'stopped', 'and that it stopped');

	# Token and TLS are mentioned so that the log shows what was asked for.
	@steps = ();
	$backend->{token} = 'x';
	$backend->{host} = 'h';
	@$logged = ();
	$backend->run;
	like($logged->[0][0], qr/\(pid \d+, token required, TLS with client certificates\)\z/, 'the log says token and TLS were required');
	$backend->{token} = undef;
	$backend->{host} = undef;

	$backend->{daemonize} = 1;
	@steps = ();
	$backend->run;
	is($steps[0], 'daemonize', 'with daemonize, that comes first');
	$backend->{daemonize} = 0;

	# A failure to start is logged, and thrown when there is nobody to tell.
	@steps = ();
	@$logged = ();
	mock('Class::Shared::Backend::_setup' => sub { die "cannot bind\n" });
	throws_ok { $backend->run } qr/\Acannot bind\n\z/, 'a failed setup is rethrown with its own text';
	is_deeply($logged->[0], ["fatal: cannot bind\n", 'error'], 'after being logged as an error');
	is_deeply(\@steps, ['cleanup'], 'and only what the start had taken is given back');

	mock('Class::Shared::Backend::_setup' => sub { die });
	throws_ok { $backend->run } qr/Died/, 'a setup that dies with no text still dies';

	# A daemon has nobody to throw to: it exits with status 1.
	my $pid = fork() // die "fork: $!";
	if (!$pid) {
		$backend->{daemonize} = 1;
		mock('Class::Shared::Backend::_daemonize' => sub { 1 });
		mock('Class::Shared::Backend::_setup' => sub { die "cannot bind\n" });
		$backend->run;
		POSIX::_exit(77);     # not reached: run exits
	}
	require POSIX;
	waitpid($pid, 0);
	is($? >> 8, 1, 'a daemon that cannot start exits with status 1');
	restore_all();
};

# --------------------------------------------------------------------- DESTROY
subtest 'Class::Shared::Backend::DESTROY' => sub {
	my $dir = private_dir();
	my $path = File::Spec->catfile($dir, 'owned.sock');

	# The socket this backend bound is removed with it.
	{
		my $listener = listening_socket($path);
		my $backend = make_backend(socket => $path);
		$backend->{owns_socket} = 1;
		close($listener);
		ok(-S $path, 'the socket exists');
		undef $backend;
	}
	ok(!-e $path, 'an owned socket is removed when the backend goes');

	# A socket that belongs to someone else is not touched.
	{
		my $listener = listening_socket($path);
		my $backend = make_backend(socket => $path);
		$backend->{owns_socket} = 0;
		undef $backend;
		ok(-S $path, 'a socket this backend did not bind is left alone');
		close($listener);
		unlink $path;
	}

	# Only once.
	{
		my $listener = listening_socket($path);
		my $backend = make_backend(socket => $path);
		@{$backend}{qw(owns_socket cleaned)} = (1, 1);
		undef $backend;
		ok(-S $path, 'after _cleanup has run nothing is removed again');
		close($listener);
		unlink $path;
	}

	# The caller's $@ and $! are not disturbed by the destruction.
	{
		my $backend = make_backend(socket => File::Spec->catfile($dir, 'absent.sock'));
		$backend->{owns_socket} = 1;
		local ($@, $!) = ('kept error', 7);
		undef $backend;
		is($@, 'kept error', '$@ survives');
		is($! + 0, 7, '$! survives');
	}

	# A socket that cannot be removed is reported, not fatal.
	SKIP: {
		skip 'root can remove files from any directory', 2 if $IS_ROOT;
		my $locked = private_dir();
		my $locked_path = File::Spec->catfile($locked, 'l.sock');
		my $listener = listening_socket($locked_path);
		my $backend = make_backend(socket => $locked_path);
		$backend->{owns_socket} = 1;
		chmod 0500, $locked;
		my @warnings = warnings_from(sub { undef $backend });
		like($warnings[0], qr/\AClass::Shared::Backend: cannot remove \Q$locked_path\E: Permission denied/, 'a failed removal warns');
		ok(-S $locked_path, 'and the socket is still there');
		chmod 0700, $locked;
		close($listener);
	}

	is_deeply([make_backend()->DESTROY], [], 'DESTROY returns nothing');
};

# ----------------------------------------------------------------- _load_class
subtest 'Class::Shared::Backend::_load_class' => sub {
	my $backend = make_backend();
	my $libdir = private_dir();

	my $write = sub {
		my ($name, $code) = @_;
		my $file = File::Spec->catfile($libdir, split /::/, $name) . '.pm';
		my $parent = File::Spec->catpath((File::Spec->splitpath($file))[0, 1], '');
		File::Path::make_path($parent);
		open(my $fh, '>', $file) or die "$file: $!";
		print {$fh} $code;
		close($fh);
		return $file;
	};
	require File::Path;
	local @INC = ($libdir, @INC);

	$write->('FnTest::Plain', "package FnTest::Plain; our \$IMPORTED = 0; sub import { \$IMPORTED++ } sub new { bless {}, shift } 1;\n");
	my @r = $backend->_load_class('FnTest::Plain');
	is_deeply(\@r, [1], 'a class that is there loads');
	is($backend->{classes}{'FnTest::Plain'}, 1, 'and is remembered');
	is($FnTest::Plain::IMPORTED, 1, 'with its import called, as use would');

	# Once however many ask: the file may even be gone.
	unlink File::Spec->catfile($libdir, 'FnTest', 'Plain.pm');
	@r = $backend->_load_class('FnTest::Plain');
	is_deeply(\@r, [1], 'a class that is held is not loaded again');
	is($FnTest::Plain::IMPORTED, 1, 'nor imported again');

	# A class with no import is fine.
	$write->('FnTest::NoImport', "package FnTest::NoImport; sub new { bless {}, shift } 1;\n");
	$backend->_load_class('FnTest::NoImport');
	is($backend->{classes}{'FnTest::NoImport'}, 1, 'no import method is fine');

	# Nothing there.
	@r = $backend->_load_class('FnTest::Missing');
	is($r[0], 0, 'a class that is not installed fails');
	like($r[1], qr/\Acannot load FnTest::Missing: Can't locate FnTest\/Missing\.pm in \@INC/, 'with perl\'s reason');
	ok(!$backend->{classes}{'FnTest::Missing'}, 'and is not remembered as loaded');

	# A file that does not compile.
	$write->('FnTest::Broken', "package FnTest::Broken; sub new { \n");
	@r = $backend->_load_class('FnTest::Broken');
	is($r[0], 0, 'a class with a syntax error fails');
	like($r[1], qr/\Acannot load FnTest::Broken: /, 'with a reason');

	# A file that returns false.
	$write->('FnTest::False', "package FnTest::False; sub new { } 0;\n");
	@r = $backend->_load_class('FnTest::False');
	is($r[0], 0, 'a file that does not end true fails');

	# An import that dies: the class is loaded but not usable.
	$write->('FnTest::BadImport', "package FnTest::BadImport; sub import { die \"no import for you\\n\" } sub new { bless {}, shift } 1;\n");
	@r = $backend->_load_class('FnTest::BadImport');
	is_deeply(\@r, [0, "cannot import FnTest::BadImport: no import for you\n"], 'a failing import is reported as such');
	ok(!$backend->{classes}{'FnTest::BadImport'}, 'and is not remembered');

	# $@ from a successful load does not leak into the answer.
	{
		local $@ = 'stale';
		$write->('FnTest::Clean', "package FnTest::Clean; 1;\n");
		@r = $backend->_load_class('FnTest::Clean');
		is_deeply(\@r, [1], 'a stale $@ is not read as a failure');
	}

	ok(leaves_topic_alone(sub { $backend->_load_class('FnTest::Clean') }), '$_ is left alone');
};

# ---------------------------------------------------------------------- _setup
subtest 'Class::Shared::Backend::_setup' => sub {
	my $dir = private_dir();
	my $socket = File::Spec->catfile($dir, 'setup.sock');
	my $backend = make_backend(socket => $socket, start_timeout => 0, dir_for_files => $dir);
	my @which;
	mock('Class::Shared::Backend::_setup_unix' => sub { push @which, 'unix'; $_[0]{listener} = listening_socket($socket); 1 });
	mock('Class::Shared::Backend::_setup_tcp'  => sub { push @which, 'tcp'; 1 });

	is($backend->_setup, 1, 'returns 1');
	is_deeply(\@which, ['unix'], 'a socket means a unix listener');
	ok(-e "$socket.owner", 'the lock file exists');
	is(sprintf('%04o', (stat "$socket.owner")[2] & 07777), '0600', 'and is private');
	ok($backend->{lock}, 'the lock is held');
	open(my $pidfh, '<', "$socket.pid") or die;
	chomp(my $pid_text = <$pidfh>);
	close($pidfh);
	is($pid_text, $$, 'the pid file holds this pid');

	# A second backend on the same control path is refused while the first holds the lock.
	my $second = make_backend(socket => $socket, start_timeout => 0, dir_for_files => $dir);
	throws_ok { $second->_setup }
		qr/\Aanother backend is already serving \(\Q$socket\E\.owner is locked\)\n\z/, 'a second backend is refused';
	is($second->{lock}, undef, 'and does not keep a lock');
	is(scalar(@which), 1, 'and never got as far as binding');

	# The wait for a lock that is about to be released is bounded.
	my $patient = make_backend(socket => $socket, start_timeout => 1, dir_for_files => $dir);
	local $Class::Shared::POLL_INTERVAL = 0.01;
	my $start = time;
	throws_ok { $patient->_setup } qr/another backend is already serving/, 'it gives up after the timeout';
	cmp_ok(time - $start, '<=', 4, 'in about the time given');

	# TCP goes the other way.
	@which = ();
	my $tcp = make_backend(dir_for_files => private_dir());
	@{$tcp}{qw(socket host port)} = (undef, '127.0.0.1', 1);
	$tcp->{control} = File::Spec->catfile($tcp->{_test_dir}, 'c.sock');
	$tcp->{listener} = undef;
	mock('Class::Shared::Backend::_setup_tcp' => sub { push @which, 'tcp'; $_[0]{listener} = listening_socket(File::Spec->catfile($_[0]{_test_dir}, 'tcp-l.sock')); 1 });
	$tcp->_setup;
	is_deeply(\@which, ['tcp'], 'no socket means a TCP listener');
	restore_all();

	# The directory is made safe first.
	my $unsafe = private_dir();
	chmod 0777, $unsafe;
	my $refused = make_backend(socket => File::Spec->catfile($unsafe, 's.sock'), dir_for_files => $unsafe);
	throws_ok { $refused->_setup } qr/\A.*is writable by group or others; refusing to use it\n\z/, 'an unsafe directory stops the start';
	ok(!-e File::Spec->catfile($unsafe, 's.sock.owner'), 'before any file is made there');
	chmod 0700, $unsafe;

	# A lock file that cannot be opened.
	my $absent = make_backend(socket => File::Spec->catfile($dir, 'missing', 's.sock'));
	mock('Class::Shared::ensure_dir' => sub { (1, undef) });
	throws_ok { $absent->_setup } qr/\Acannot open \Q$dir\E\/missing\/s\.sock\.owner: No such file or directory\n\z/, 'an unopenable lock is reported';
	restore_all();

	# A pid file that cannot be written is logged, not fatal.
	my $pid_dir = private_dir();
	my $pid_socket = File::Spec->catfile($pid_dir, 'p.sock');
	my $nopid = make_backend(socket => $pid_socket, start_timeout => 0, dir_for_files => $pid_dir);
	mkdir "$pid_socket.pid" or die;
	mock('Class::Shared::Backend::_setup_unix' => sub { $_[0]{listener} = listening_socket($pid_socket); 1 });
	my $logged = capture_log($nopid);
	lives_ok { $nopid->_setup } 'a pid file that cannot be written does not stop the start';
	like($logged->[0][0], qr/\Acannot write \Q$pid_socket\E\.pid: /, 'but is logged');
	is($logged->[0][1], 'error', 'as an error');
	restore_all();

	$backend->{listener} = undef;
};

# ----------------------------------------------------------------- _setup_unix
subtest 'Class::Shared::Backend::_setup_unix' => sub {
	my $dir = private_dir();
	my $socket = File::Spec->catfile($dir, 'u.sock');

	my $backend = make_backend(socket => $socket, dir_for_files => $dir);
	my $umask = umask;
	is($backend->_setup_unix, 1, 'returns 1');
	is(umask, $umask, 'the umask is put back');
	ok(-S $socket, 'a socket is made');
	is(sprintf('%04o', (stat $socket)[2] & 07777), '0600', 'closed to everyone else');
	is($backend->{address}, $socket, 'its address is the path');
	is($backend->{owns_socket}, 1, 'and it is this backend\'s to remove');
	ok(defined fileno($backend->{listener}), 'with a listener');

	# Whatever the caller's umask, nobody else can reach it, not even for a moment.
	close($backend->{listener});
	unlink $socket;
	umask 0;
	my $loose = make_backend(socket => $socket, dir_for_files => $dir);
	$loose->_setup_unix;
	is(sprintf('%04o', (stat $socket)[2] & 07777), '0600', 'a loose umask does not open it');
	umask $umask;
	close($loose->{listener});
	unlink $socket;

	# A path that is not a socket is never removed to make room.
	open(my $keep, '>', $socket) or die; print {$keep} "mine\n"; close($keep);
	my $victim = make_backend(socket => $socket, dir_for_files => $dir);
	throws_ok { $victim->_setup_unix } qr/\A\Q$socket\E exists and is not a socket; refusing to remove it\n\z/, 'a file in the way is refused';
	ok(-f $socket, 'and left as it was');
	is($victim->{owns_socket}, 0, 'and not claimed');
	unlink $socket;

	# A backend that is still listening there.
	my $live = listening_socket($socket);
	throws_ok { make_backend(socket => $socket, dir_for_files => $dir)->_setup_unix }
		qr/\Aa backend is already listening on \Q$socket\E\n\z/, 'a live listener is not replaced';
	ok(-S $socket, 'and its socket is still there');
	close($live);

	# A stale one is replaced.
	my $stale_backend = make_backend(socket => $socket, dir_for_files => $dir);
	lives_ok { $stale_backend->_setup_unix } 'a stale socket is replaced';
	is($stale_backend->{owns_socket}, 1, 'and owned');
	close($stale_backend->{listener});
	unlink $socket;

	# A path that cannot be bound.
	my $nowhere = make_backend(socket => File::Spec->catfile($dir, 'no-such-dir', 'x.sock'));
	throws_ok { $nowhere->_setup_unix } qr/\Acannot listen on \Q$dir\E\/no-such-dir\/x\.sock: No such file or directory\n\z/,
		'a path that cannot be bound is reported with the system reason';
	is($nowhere->{owns_socket}, 0, 'and not claimed');
	is(umask, $umask, 'and the umask is still put back');

	# A stale socket that cannot be removed.
	SKIP: {
		skip 'root can remove files from any directory', 2 if $IS_ROOT;
		my $locked = private_dir();
		my $path = File::Spec->catfile($locked, 'l.sock');
		my $l = listening_socket($path);
		close($l);
		chmod 0500, $locked;
		throws_ok { make_backend(socket => $path)->_setup_unix } qr/\Acannot remove the stale socket \Q$path\E: Permission denied\n\z/,
			'a stale socket that cannot be removed is reported';
		ok(-S $path, 'and is still there');
		chmod 0700, $locked;
	}
};

# ----------------------------------------------------------------- _setup_tcp
subtest 'Class::Shared::Backend::_setup_tcp' => sub {
	test_needs 'IO::Socket::SSL';
	my $certs = 't/certs';
	plan skip_all => 'the test certificates are not here' unless -r "$certs/server.pem" && -r "$certs/ca.pem";

	my $backend = make_backend();
	@{$backend}{qw(socket host port tls_cert tls_key tls_ca)} = (undef, '127.0.0.1', 0, "$certs/server.pem", "$certs/server-key.pem", "$certs/ca.pem");

	# Nothing configured.
	my $none = make_backend();
	throws_ok { $none->_setup_tcp } qr/\AClass::Shared::Backend: no TCP address configured\n\z/, 'no address is refused';
	@{$none}{qw(host)} = ('127.0.0.1');
	throws_ok { $none->_setup_tcp } qr/no TCP address configured/, 'a host without a port is refused too';

	is($backend->_setup_tcp, 1, 'returns 1');
	ok(defined fileno($backend->{listener}), 'a listener is open');
	like($backend->{address}, qr/\A127\.0\.0\.1:0\z/, 'the address is host:port');
	isa_ok($backend->{tls_context}, 'IO::Socket::SSL::SSL_Context');
	my $port = $backend->{listener}->sockport;
	cmp_ok($port, '>', 0, 'it is listening on a port');

	# The same address cannot be used by two listeners at once.
	my $again = make_backend();
	@{$again}{qw(socket host port tls_cert tls_key tls_ca)} = (undef, '127.0.0.1', $port, "$certs/server.pem", "$certs/server-key.pem", "$certs/ca.pem");
	throws_ok { $again->_setup_tcp } qr/\Acannot listen on 127\.0\.0\.1:\Q$port\E: Address already in use\n\z/,
		'a port that is already being listened on is reported with the system reason';

	# A certificate that is not there.
	my $bad = make_backend();
	@{$bad}{qw(socket host port tls_cert tls_key tls_ca)} = (undef, '127.0.0.1', 0, "$certs/not-there.pem", "$certs/server-key.pem", "$certs/ca.pem");
	throws_ok { $bad->_setup_tcp } qr/\Acannot set up TLS for 127\.0\.0\.1:0: .+\n\z/, 'an unusable certificate is reported';
	is($bad->{listener}, undef, 'and no listener is opened');

	# A key that does not belong to the certificate.
	my $mismatch = make_backend();
	@{$mismatch}{qw(socket host port tls_cert tls_key tls_ca)} = (undef, '127.0.0.1', 0, "$certs/server.pem", "$certs/other-server-key.pem", "$certs/ca.pem");
	throws_ok { $mismatch->_setup_tcp } qr/\Acannot set up TLS for /, 'a key that does not match is refused';

	# The versions allowed are the ones the module names.
	my %context_args;
	mock('IO::Socket::SSL::SSL_Context::new' => sub { shift; %context_args = @_; return undef });
	my $versions = make_backend();
	@{$versions}{qw(socket host port tls_cert tls_key tls_ca)} = (undef, '127.0.0.1', 0, 'c', 'k', 'ca');
	eval { $versions->_setup_tcp };
	is($context_args{SSL_version}, $Class::Shared::TLS_VERSIONS, 'old TLS versions are off');
	is($context_args{SSL_server}, 1, 'as a server');
	is($context_args{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER() | IO::Socket::SSL::SSL_VERIFY_FAIL_IF_NO_PEER_CERT(),
		'a client without a certificate is refused');
	restore_all();
};

# A TLS-like handle for the handshake and would-block tests: it answers the
# questions the backend asks of a socket, with answers a subtest chooses.
{
	package Test::FakeTLS;

	our $SSL_ERROR_ANSWER;

	sub new         { my ($class, %answer) = @_; return bless { %answer }, $class }
	sub accept_SSL  { my $self = shift; $IO::Socket::SSL::SSL_ERROR = $self->{error}; return $self->{accept} }
	sub want_read   { $_[0]{want_read} }
	sub want_write  { $_[0]{want_write} }
}

# ----------------------------------------------------------------------- _loop
subtest 'Class::Shared::Backend::_loop' => sub {
	my $dir = private_dir();
	my $path = File::Spec->catfile($dir, 'loop.sock');
	my $backend = make_backend(socket => $path, dir_for_files => $dir);
	$backend->{listener} = listening_socket($path);

	# One connection is waiting, so the listener is readable and _accept runs.
	socket(my $visitor, AF_UNIX, SOCK_STREAM, 0) or die;
	connect($visitor, pack_sockaddr_un($path)) or die "connect: $!";

	my $accepted = 0;
	mock('Class::Shared::Backend::_accept' => sub { $accepted++; $_[0]{stop} = 1; return });
	is($backend->_loop, 1, 'returns 1 when told to stop');
	is($accepted, 1, 'a waiting connection is accepted');
	restore_all();

	# It stops at once when asked to before it starts.
	$backend->{stop} = 1;
	is($backend->_loop, 1, 'a loop that is already stopped does nothing');
	$backend->{stop} = 0;

	# A signal asks it to stop, and the handlers go away with it.
	my $outer_term = $SIG{TERM};
	mock('Class::Shared::Backend::_accept' => sub { kill 'TERM', $$; return });
	socket(my $second_visitor, AF_UNIX, SOCK_STREAM, 0) or die;
	connect($second_visitor, pack_sockaddr_un($path)) or die;
	$backend->_loop;
	is($backend->{stop}, 1, 'SIGTERM stops it');
	is($SIG{TERM}, $outer_term, 'and the caller\'s handler is back');
	restore_all();

	$backend->{stop} = 0;
	mock('Class::Shared::Backend::_accept' => sub { kill 'INT', $$; return });
	socket(my $third_visitor, AF_UNIX, SOCK_STREAM, 0) or die;
	connect($third_visitor, pack_sockaddr_un($path)) or die;
	$backend->_loop;
	is($backend->{stop}, 1, 'SIGINT stops it');
	restore_all();

	# A readable client is served; the loop does not wait on others.
	$backend->{stop} = 0;
	my ($client, $far) = make_client(serial => 5);
	$backend->{clients}{ fileno($client->{fh}) } = $client;
	syswrite($far, 'x');
	my @served;
	mock('Class::Shared::Backend::_serve_client' => sub { push @served, $_[1]; $_[0]{stop} = 1 });
	$backend->_loop;
	is_deeply(\@served, [$client], 'a client with data is served');
	restore_all();

	# A queued reply makes the client writable; it is flushed.
	$backend->{stop} = 0;
	$client->{outbuf} = 'queued';
	# What the far end sent is still unread, so the client stays readable;
	# _serve_client is real again here and consumes it.
	my @flushed;
	mock('Class::Shared::Backend::_flush' => sub { push @flushed, $_[1]; $_[0]{stop} = 1 });
	$backend->_loop;
	is_deeply(\@flushed, [$client], 'a client with something queued is flushed');
	restore_all();
	$client->{outbuf} = '';

	# A handshake in progress is continued, and timed.
	$backend->{stop} = 0;
	$client->{handshaking} = 1;
	$client->{want_write} = 0;
	syswrite($far, 'x');
	my ($continued, $expired) = (0, 0);
	mock('Class::Shared::Backend::_continue_tls' => sub { $continued++; $_[0]{stop} = 1 });
	mock('Class::Shared::Backend::_expire_handshakes' => sub { $expired++ });
	$backend->_loop;
	is($continued, 1, 'a handshaking client is continued, not served');
	ok($expired >= 1, 'and the handshake deadlines are looked at');
	restore_all();

	# A stalled queue wakes the loop in time to expire it.
	$backend->{stop} = 0;
	$client->{handshaking} = 0;
	$client->{outbuf} = 'waiting';
	$client->{stalled_since} = Time::HiRes::time() - 1000;
	my $expired_writes = 0;
	mock('Class::Shared::Backend::_expire_writes' => sub { $expired_writes++; $_[0]{stop} = 1 });
	mock('Class::Shared::Backend::_flush' => sub { });
	my $start = Time::HiRes::time();
	$backend->_loop;
	ok($expired_writes >= 1, 'a queue past its deadline is expired');
	cmp_ok(Time::HiRes::time() - $start, '<', 2, 'without waiting for something else to happen');
	restore_all();

	# A client whose handle has gone is skipped, not an error.
	$backend->{stop} = 0;
	my ($dead, $dead_far) = make_client();
	close($dead->{fh});
	$backend->{clients}{99} = $dead;
	$client->{outbuf} = '';
	socket(my $fourth, AF_UNIX, SOCK_STREAM, 0) or die;
	connect($fourth, pack_sockaddr_un($path)) or die;
	mock('Class::Shared::Backend::_accept' => sub { $_[0]{stop} = 1; return });
	lives_ok { $backend->_loop } 'a client with a closed handle does not break the loop';
	restore_all();

	# SIGPIPE is ignored while serving, and put back after.
	local $SIG{PIPE} = 'DEFAULT';
	$backend->{stop} = 0;
	my $pipe_during;
	socket(my $fifth, AF_UNIX, SOCK_STREAM, 0) or die;
	connect($fifth, pack_sockaddr_un($path)) or die;
	mock('Class::Shared::Backend::_accept' => sub { $pipe_during = $SIG{PIPE}; $_[0]{stop} = 1; return });
	$backend->_loop;
	is($pipe_during, 'IGNORE', 'a write to a closed client cannot kill the backend');
	is($SIG{PIPE}, 'DEFAULT', 'and the setting is restored');
	restore_all();

	%{ $backend->{clients} } = ();
	close($backend->{listener});
};

# ------------------------------------------------------------ _expire_handshakes
subtest 'Class::Shared::Backend::_expire_handshakes' => sub {
	my $backend = make_backend();
	my @dropped;
	mock('Class::Shared::Backend::_drop_client' => sub { push @dropped, [$_[1]{name}, $_[2]] });

	$backend->{clients} = {
		1 => { name => 'late',     handshaking => 1, deadline => time - 100 },
		2 => { name => 'early',    handshaking => 1, deadline => time + 100 },
		3 => { name => 'ordinary', handshaking => 0, deadline => time - 100 },
		4 => { name => 'no flag',                    deadline => time - 100 },
	};
	is($backend->_expire_handshakes, 1, 'returns 1');
	is_deeply(\@dropped, [['late', 'TLS handshake timed out']], 'only the handshake that has run out of time is dropped');

	@dropped = ();
	$backend->{clients} = {};
	$backend->_expire_handshakes;
	is_deeply(\@dropped, [], 'no clients, no drops');
	restore_all();
};

# ---------------------------------------------------------------- _expire_writes
subtest 'Class::Shared::Backend::_expire_writes' => sub {
	my $backend = make_backend(write_timeout => 10);
	my @dropped;
	mock('Class::Shared::Backend::_drop_client' => sub { push @dropped, [$_[1]{name}, $_[2]] });

	my $now = Time::HiRes::time();
	$backend->{clients} = {
		1 => { name => 'stuck',    closed => 0, outbuf => 'abcde', stalled_since => $now - 100 },
		2 => { name => 'fresh',    closed => 0, outbuf => 'abcde', stalled_since => $now - 1 },
		3 => { name => 'empty',    closed => 0, outbuf => '',      stalled_since => $now - 100 },
		4 => { name => 'closed',   closed => 1, outbuf => 'abcde', stalled_since => $now - 100 },
		5 => { name => 'no clock', closed => 0, outbuf => 'abcde', stalled_since => undef },
	};
	is($backend->_expire_writes, 1, 'returns 1');
	is_deeply(\@dropped, [['stuck', 'a queued reply of 5 bytes made no progress for 10 second(s)']],
		'only a queue that is waiting, open, started and out of time is dropped');

	# The clock is fractional: a half second over is over.
	@dropped = ();
	$backend->{clients} = { 1 => { name => 'just over', closed => 0, outbuf => 'x', stalled_since => $now - 10.5 } };
	$backend->_expire_writes;
	is(scalar(@dropped), 1, 'a deadline passed by half a second counts');

	@dropped = ();
	$backend->{clients} = { 1 => { name => 'just inside', closed => 0, outbuf => 'x', stalled_since => $now - 9 } };
	$backend->_expire_writes;
	is(scalar(@dropped), 0, 'a deadline not yet reached does not');
	restore_all();
};

# ---------------------------------------------------------------------- _accept
subtest 'Class::Shared::Backend::_accept' => sub {
	my $dir = private_dir();
	my $path = File::Spec->catfile($dir, 'acc.sock');
	my $backend = make_backend(socket => $path, dir_for_files => $dir, max_clients => 2);
	$backend->{listener} = listening_socket($path);
	$backend->{listener}->blocking(0);

	# Nobody is waiting.
	is($backend->_accept, undef, 'no connection waiting gives nothing');
	is(scalar(keys %{ $backend->{clients} }), 0, 'and records nothing');

	my @visitors;
	my $visit = sub {
		socket(my $v, AF_UNIX, SOCK_STREAM, 0) or die;
		connect($v, pack_sockaddr_un($path)) or die "connect: $!";
		push @visitors, $v;
		return $v;
	};

	$visit->();
	is($backend->_accept, 1, 'a waiting connection is accepted');
	my ($client) = values %{ $backend->{clients} };
	is_deeply([@{$client}{qw(buffer outbuf greeted serial closed)}], ['', '', 0, 1, 0], 'its record starts empty');
	is_deeply($client->{objects}, {}, 'with no objects');
	is($backend->{clients}{ fileno($client->{fh}) }, $client, 'it is held under its descriptor');
	is($backend->{next_serial}, 2, 'and the next one will be numbered after it');
	ok(!exists $client->{handshaking}, 'a unix client has no handshake');

	# Never blocking, and never inherited by a child.
	is($client->{fh}->blocking, 0, 'the socket does not block the loop');
	my $flags = fcntl($client->{fh}, Fcntl::F_GETFD(), 0);
	ok(defined $flags, 'its flags can be read');
	is($flags & Fcntl::FD_CLOEXEC(), Fcntl::FD_CLOEXEC(), 'and it is not passed to a child that is exec\'d');

	$visit->();
	$backend->_accept;
	is(scalar(keys %{ $backend->{clients} }), 2, 'up to the limit');
	my $serials = join ',', sort map { $_->{serial} } values %{ $backend->{clients} };
	is($serials, '1,2', 'every client has its own serial');

	# One over the limit is told so, and closed.
	my $extra = $visit->();
	is($backend->_accept, undef, 'one over the limit is refused');
	is(scalar(keys %{ $backend->{clients} }), 2, 'and not added');
	my ($busy, $error) = Class::Shared::Protocol::read_frame($extra, 1);
	is($busy->{ok}, 0, 'the refused client is told it was refused');
	is($busy->{kind}, 'busy', 'as busy');
	like($busy->{error}, qr/\Abackend is serving too many clients \(2\)\z/, 'with the limit');
	is(sysread($extra, my $rest, 1), 0, 'and then the connection is closed');

	# With a token the refusal is signed like any other frame.
	$backend->{token} = $config{secret};
	my $signed_extra = $visit->();
	$backend->_accept;
	($busy) = Class::Shared::Protocol::read_frame($signed_extra, 1, $config{secret});
	is($busy->{kind}, 'busy', 'a signed refusal can be read with the secret');
	$backend->{token} = undef;

	# A TCP client is closed without a word: no session exists to sign one.
	$backend->{host} = 'h';
	my $tcp_extra = $visit->();
	$backend->_accept;
	is(sysread($tcp_extra, my $nothing, 1), 0, 'a TCP client over the limit is closed with no frame');
	$backend->{host} = undef;

	# A socket that cannot be prepared is refused, and the reason logged.
	%{ $backend->{clients} } = ();
	my $logged = capture_log($backend);
	mock('IO::Socket::UNIX::blocking' => sub { return undef });
	my $unprepared = $visit->();
	is($backend->_accept, undef, 'a socket that cannot be made non-blocking is refused');
	is(scalar(keys %{ $backend->{clients} }), 0, 'and not kept');
	like($logged->[0][0], qr/\Arefused a connection: cannot prepare its socket: /, 'with a reason in the log');
	is($logged->[0][1], 'warn', 'as a warning');
	is(sysread($unprepared, $nothing, 1), 0, 'and closed');
	restore_all();

	# A TLS client starts a handshake but does not finish it here.
	$logged = capture_log($backend);
	$backend->{host} = 'h';
	my $fake = Test::FakeTLS->new();
	open(my $dup, '<&', \*STDIN) or die;
	mock('Class::Shared::Backend::_start_tls' => sub { return $_[1] });
	$visit->();
	my $before = time;
	is($backend->_accept, 1, 'a TLS client is accepted');
	my ($tls) = values %{ $backend->{clients} };
	is_deeply([@{$tls}{qw(handshaking want_write)}], [1, 0], 'and is in the middle of its handshake');
	cmp_ok($tls->{deadline}, '>=', $before + $backend->{handshake_timeout}, 'with a deadline');
	cmp_ok($tls->{deadline}, '<=', time + $backend->{handshake_timeout}, 'that is the handshake timeout from now');
	%{ $backend->{clients} } = ();

	subtest 'with IO::Socket::SSL' => sub {
		test_needs 'IO::Socket::SSL';

		# A TLS layer that will not start refuses the connection.
		mock('Class::Shared::Backend::_start_tls' => sub { return undef });
		mock('IO::Socket::SSL::errstr' => sub { 'no ciphers' });
		my $refused = $visit->();
		is($backend->_accept, undef, 'a TLS layer that will not start refuses the client');
		like($logged->[-1][0] // '', qr/\Arefused a TLS connection: no ciphers\z/, 'saying why');
		is($logged->[-1][1], 'warn', 'as a warning');
		is(sysread($refused, $nothing, 1), 0, 'and closes it');
		restore_all();
	};
	$backend->{host} = undef;
};

# ------------------------------------------------------------------ _start_tls
subtest 'Class::Shared::Backend::_start_tls' => sub {
	test_needs 'IO::Socket::SSL';

	my $backend = make_backend();
	$backend->{tls_context} = 'the shared context';

	my @args;
	mock('IO::Socket::SSL::start_SSL' => sub { shift; @args = @_; return 'upgraded' });
	is($backend->_start_tls('plain handle'), 'upgraded', 'the upgraded handle is returned');
	is($args[0], 'plain handle', 'the plain handle is what is upgraded');
	my %opt = @args[1 .. $#args];
	is($opt{SSL_server}, 1, 'as a server');
	is($opt{SSL_startHandshake}, 0, 'with the handshake left for the loop');
	is($opt{SSL_reuse_ctx}, 'the shared context', 'and the one context that was read at start');

	mock('IO::Socket::SSL::start_SSL' => sub { return undef });
	is($backend->_start_tls('x'), undef, 'a failure is passed on');
	restore_all();
};

# ---------------------------------------------------------------- _continue_tls
subtest 'Class::Shared::Backend::_continue_tls' => sub {
	test_needs 'IO::Socket::SSL';

	my $backend = make_backend();
	my $logged = capture_log($backend);
	my @dropped;
	mock('Class::Shared::Backend::_drop_client' => sub { push @dropped, $_[2] });

	my $client = { fh => Test::FakeTLS->new(accept => 1), handshaking => 1, want_write => 1, deadline => 5 };
	is($backend->_continue_tls($client), 1, 'a finished handshake returns 1');
	is_deeply([@{$client}{qw(handshaking want_write)}], [0, 0], 'and the client is an ordinary one');
	ok(!exists $client->{deadline}, 'with no deadline left');
	is_deeply(\@dropped, [], 'and not dropped');

	foreach my $wait ([IO::Socket::SSL::SSL_WANT_READ(), 0, 'wants to read'], [IO::Socket::SSL::SSL_WANT_WRITE(), 1, 'wants to write']) {
		my ($code, $want_write, $name) = @$wait;
		$client = { fh => Test::FakeTLS->new(accept => 0, error => $code), handshaking => 1, want_write => 0, deadline => 5 };
		is($backend->_continue_tls($client), 1, "a handshake that $name returns 1");
		is($client->{handshaking}, 1, '  and is still going');
		is($client->{want_write}, $want_write, "  and want_write is $want_write");
		is($client->{deadline}, 5, '  with its deadline');
	}

	# A read wait clears an earlier write wait.
	$client = { fh => Test::FakeTLS->new(accept => 0, error => IO::Socket::SSL::SSL_WANT_READ()), handshaking => 1, want_write => 1 };
	$backend->_continue_tls($client);
	is($client->{want_write}, 0, 'wanting to read again clears the write wait');

	# Anything else is a failure.
	mock('IO::Socket::SSL::errstr' => sub { 'bad certificate' });
	@$logged = ();
	foreach my $error (undef, 0, 1, 999) {
		@dropped = ();
		$client = { fh => Test::FakeTLS->new(accept => 0, error => $error), handshaking => 1 };
		my @r = $backend->_continue_tls($client);
		is_deeply(\@r, [], 'a failed handshake returns nothing: ' . ($error // 'undef'));
		is_deeply(\@dropped, ['TLS handshake failed'], '  and the client is dropped');
	}
	is($logged->[0][0], 'refused a TLS connection: bad certificate', 'the TLS reason is logged');
	is($logged->[0][1], 'warn', 'as a warning');

	mock('IO::Socket::SSL::errstr' => sub { '' });
	@$logged = ();
	$backend->_continue_tls({ fh => Test::FakeTLS->new(accept => 0), handshaking => 1 });
	is($logged->[0][0], 'refused a TLS connection: handshake failed', 'with no reason from TLS, a general one');
	restore_all();
};

# ---------------------------------------------------------------- _would_block
subtest 'Class::Shared::Backend::_would_block' => sub {
	my $backend = make_backend();
	my $plain = Test::FakeTLS->new();

	foreach my $errno (POSIX::EAGAIN(), POSIX::EWOULDBLOCK()) {
		local $! = $errno;
		is($backend->_would_block($plain), 1, "errno $errno means not yet");
		is($backend->_would_block($plain, 'write'), 1, '  for a write too');
	}

	{
		local $! = POSIX::EPIPE();
		is($backend->_would_block($plain), 0, 'a broken pipe is not "not yet"');
	}
	{
		local $! = POSIX::ECONNRESET();
		is($backend->_would_block($plain), 0, 'nor is a reset');
	}
	{
		local $! = 0;
		is($backend->_would_block($plain), 0, 'no error and no TLS wait is not "not yet"');
	}

	# A TLS layer that is waiting.
	local $! = 0;
	is($backend->_would_block(Test::FakeTLS->new(want_read => 1)), 1, 'TLS wants to read: a read is not yet');
	is($backend->_would_block(Test::FakeTLS->new(want_read => 1), 'write'), 1, 'and a write waits for that read');
	is($backend->_would_block(Test::FakeTLS->new(want_write => 1), 'write'), 1, 'TLS wants to write: a write is not yet');
	is($backend->_would_block(Test::FakeTLS->new(want_write => 1)), 0, 'but that does not make a read "not yet"');
	is($backend->_would_block(Test::FakeTLS->new(want_read => 1, want_write => 1), 'read'), 1, 'a read waiting on read');

	# The default direction is a read.
	is($backend->_would_block(Test::FakeTLS->new(want_read => 1), undef), 1, 'an undefined direction means read');
	is($backend->_would_block(Test::FakeTLS->new(want_write => 1), undef), 0, 'and does not look at the write wait');

	# A handle that is not TLS has no such questions to answer.
	pipe(my $r, my $w) or die;
	is($backend->_would_block($r), 0, 'a plain handle has no TLS wait');
	is($backend->_would_block($r, 'write'), 0, 'in either direction');

	# An unknown direction is a read of nothing, not a die.
	lives_ok { $backend->_would_block($plain, 'sideways') } 'an unknown direction does not die';
};

# --------------------------------------------------------------- _serve_client
subtest 'Class::Shared::Backend::_serve_client' => sub {
	my $backend = make_backend();
	my $logged = capture_log($backend);

	my (@dispatched, @sent, @dropped);
	mock('Class::Shared::Backend::_dispatch' => sub { push @dispatched, $_[2]; return { ok => 1, seen => $_[2]{n} } });
	mock('Class::Shared::Backend::_send' => sub { push @sent, $_[2] });
	mock('Class::Shared::Backend::_drop_client' => sub { push @dropped, $_[2]; $_[1]{closed} = 1 });

	my $frame = sub { my ($n) = @_; my ($b) = Class::Shared::Protocol::encode_frame({ n => $n }, $_[1]); return $b };
	my $reset = sub { @dispatched = @sent = @dropped = (); @$logged = () };

	# One frame.
	my ($client, $far) = make_client();
	syswrite($far, $frame->(1));
	is($backend->_serve_client($client), 1, 'returns 1');
	is_deeply(\@dispatched, [{ n => 1 }], 'a frame is dispatched');
	is_deeply(\@sent, [{ ok => 1, seen => 1 }], 'and its answer sent');
	is($client->{buffer}, '', 'the buffer is empty after');

	# Two frames in one read, in order.
	$reset->();
	syswrite($far, $frame->(1) . $frame->(2));
	$backend->_serve_client($client);
	is_deeply([map { $_->{n} } @dispatched], [1, 2], 'two frames that arrive together are both served, in order');

	# A frame in two halves.
	$reset->();
	my $whole = $frame->(3);
	syswrite($far, substr($whole, 0, 5));
	$backend->_serve_client($client);
	is_deeply(\@dispatched, [], 'half a frame is not dispatched');
	is(length $client->{buffer}, 5, 'it waits in the buffer');
	syswrite($far, substr($whole, 5));
	$backend->_serve_client($client);
	is_deeply([map { $_->{n} } @dispatched], [3], 'the rest completes it');

	# A read limited to one chunk.
	$reset->();
	{
		local $Class::Shared::Backend::READ_CHUNK = 4;
		syswrite($far, $frame->(4));
		$backend->_serve_client($client);
		is(length $client->{buffer}, 4, 'one read takes at most READ_CHUNK bytes');
		is_deeply(\@dispatched, [], 'and a frame cut short by that waits');
	}
	$client->{buffer} = '';

	# A frame whose answer is nothing sends nothing.
	($client, $far) = make_client();
	$reset->();
	mock('Class::Shared::Backend::_dispatch' => sub { push @dispatched, $_[2]; return undef });
	syswrite($far, $frame->(5));
	$backend->_serve_client($client);
	is_deeply(\@sent, [], 'no response, nothing sent');
	mock('Class::Shared::Backend::_dispatch' => sub { push @dispatched, $_[2]; return { ok => 1, seen => $_[2]{n} } });

	# The peer closes.
	($client, $far) = make_client();
	$reset->();
	close($far);
	is($backend->_serve_client($client), undef, 'a closed peer returns nothing');
	is_deeply(\@dropped, ['client disconnected'], 'and the client is dropped');

	# Nothing to read on a non-blocking socket is not a fault.
	($client, $far) = make_client();
	$reset->();
	$client->{fh}->blocking(0) if $client->{fh}->can('blocking') || require IO::Handle;
	IO::Handle::blocking($client->{fh}, 0);
	is($backend->_serve_client($client), 1, 'nothing to read yet returns 1');
	is_deeply(\@dropped, [], 'and the client is kept');

	# A real read error drops.
	$reset->();
	close($client->{fh});
	my @read_warnings = warnings_from(sub { is($backend->_serve_client($client), undef, 'a failed read returns nothing') });
	like($read_warnings[0] // '', qr/sysread\(\) on closed filehandle/, 'perl\'s warning about the closed handle is the only noise');
	like($dropped[0] // '', qr/\Aread error: /, 'with the reason');

	# A bad frame: told, then dropped.
	($client, $far) = make_client();
	$reset->();
	syswrite($far, pack('N', 0xFFFFFFFF) . 'x');
	$backend->_serve_client($client);
	is($sent[0]{kind}, 'protocol', 'a frame that is too big is answered as a protocol error');
	like($sent[0]{error}, qr/exceeds the limit/, 'with the reason');
	like($dropped[0], qr/exceeds the limit/, 'and the client is dropped for it');
	is(scalar(@dispatched), 0, 'nothing was dispatched');

	# With a token, a frame signed with another secret never reaches dispatch.
	($client, $far) = make_client();
	$reset->();
	$backend->{token} = $config{secret};
	my ($forged) = Class::Shared::Protocol::encode_frame({ n => 9 }, $config{other_secret});
	syswrite($far, $forged);
	$backend->_serve_client($client);
	is(scalar(@dispatched), 0, 'a frame with the wrong signature is not dispatched');
	is($dropped[0], 'frame failed authentication', 'the client is dropped for it');
	$backend->{token} = undef;

	# A request that makes the dispatcher die is an internal error, not a dead backend.
	($client, $far) = make_client();
	$reset->();
	mock('Class::Shared::Backend::_dispatch' => sub { die "oops\n" });
	syswrite($far, $frame->(6));
	lives_ok { $backend->_serve_client($client) } 'a dispatcher that dies does not kill the loop';
	is($sent[0]{kind}, 'internal', 'the client is told it was internal');
	is($sent[0]{error}, 'oops', 'with the reason, trimmed');
	like($logged->[0][0], qr/\Ainternal error while handling a request: oops\z/, 'and it is logged');
	is($logged->[0][1], 'error', 'as an error');

	# $@ left over from earlier is not an error of this request.
	($client, $far) = make_client();
	$reset->();
	mock('Class::Shared::Backend::_dispatch' => sub { push @dispatched, $_[2]; { ok => 1 } });
	{
		local $@ = 'stale';
		syswrite($far, $frame->(7));
		$backend->_serve_client($client);
	}
	is($sent[0]{ok}, 1, 'a stale $@ does not turn a good answer into a failure');

	# A frame that closes the client ends the loop over the buffer.
	($client, $far) = make_client();
	$reset->();
	mock('Class::Shared::Backend::_dispatch' => sub { push @dispatched, $_[2]; $_[1]{closed} = 1; { ok => 1 } });
	syswrite($far, $frame->(8) . $frame->(9));
	$backend->_serve_client($client);
	is(scalar(@dispatched), 1, 'frames after one that closed the client are not served');

	# A stop request ends it too.
	($client, $far) = make_client();
	$reset->();
	mock('Class::Shared::Backend::_dispatch' => sub { push @dispatched, $_[2]; $_[0]{stop} = 1; { ok => 1 } });
	syswrite($far, $frame->(10) . $frame->(11));
	$backend->_serve_client($client);
	is(scalar(@dispatched), 1, 'frames after a stop request are not served');
	$backend->{stop} = 0;
	restore_all();
};

# ---------------------------------------------------------------- _drop_client
subtest 'Class::Shared::Backend::_drop_client' => sub {
	my $backend = make_backend();
	my $logged = capture_log($backend);

	my ($client, $far) = make_client(serial => 3, outbuf => 'abcdef', stalled_since => 5);
	my $fd = fileno($client->{fh});
	$backend->{clients}{$fd} = $client;
	$backend->{queued} = 10;
	$backend->{objects} = { 1 => { owner => 3 }, 2 => { owner => 4 }, 3 => { owner => 3 } };
	$client->{objects} = { 1 => 1, 3 => 1 };

	is($backend->_drop_client($client, 'the reason'), 1, 'returns 1');
	is($client->{closed}, 1, 'the client is marked closed');
	is($client->{outbuf}, '', 'its queue is dropped');
	is($client->{stalled_since}, undef, 'and its clock stopped');
	is($backend->{queued}, 4, 'the backend\'s count of queued bytes shrinks by the queue');
	is_deeply([sort keys %{ $backend->{objects} }], [2], 'its objects are destroyed, and another client\'s are not');
	is_deeply($client->{objects}, {}, 'it holds none');
	ok(!exists $backend->{clients}{$fd}, 'it is no longer listed');
	ok(!defined fileno($client->{fh}), 'its socket is closed');
	is(sysread($far, my $x, 1), 0, 'the peer sees the end');
	is_deeply($logged->[0], ['dropped a client: the reason', 'warn'], 'the reason is logged as a warning');

	# Once only.
	@$logged = ();
	is($backend->_drop_client($client, 'again'), 1, 'a second drop returns 1');
	is(scalar(@$logged), 0, 'and does nothing, not even a second log line');

	# Reasons that are not text.
	foreach my $reason (undef, '') {
		my ($c, $f) = make_client();
		@$logged = ();
		$backend->_drop_client($c, $reason);
		is($logged->[0][0], 'dropped a client: no reason given', 'a missing reason is said so');
	}

	# The queued count cannot go below zero, whatever the books say.
	($client, $far) = make_client(outbuf => 'abcdef');
	$backend->{queued} = 2;
	$backend->_drop_client($client, 'x');
	is($backend->{queued}, 0, 'the count never goes negative');

	# An object that is destroyed is destroyed once, when its client goes.
	@Test::Held::DESTROYED = ();
	($client, $far) = make_client(serial => 8);
	$backend->{objects} = { 20 => { owner => 8, object => Test::Held->new } };
	$client->{objects} = { 20 => 1 };
	$backend->_drop_client($client, 'x');
	is(scalar(@Test::Held::DESTROYED), 1, 'the object\'s destructor ran');

	# A client with no object table at all.
	($client, $far) = make_client();
	delete $client->{objects};
	lives_ok { $backend->_drop_client($client, 'x') } 'a record with no objects entry is fine';

	# A close that fails is logged, and the client is gone regardless.
	($client, $far) = make_client();
	$backend->{clients}{ fileno($client->{fh}) } = $client;
	mock('Class::Shared::Backend::_close' => sub { 0 });
	$backend->_drop_client($client, 'x');
	is($client->{closed}, 1, 'a failed close still leaves the client closed');
	restore_all();
};

# ----------------------------------------------------------------------- _send
subtest 'Class::Shared::Backend::_send' => sub {
	my $backend = make_backend(max_queued => 1000, max_queued_total => 1500);
	my $logged = capture_log($backend);
	my (@flushed, @dropped);
	mock('Class::Shared::Backend::_flush' => sub { push @flushed, $_[1] });
	mock('Class::Shared::Backend::_drop_client' => sub { push @dropped, $_[2]; $_[1]{closed} = 1 });

	my ($client, $far) = make_client();
	my ($expected) = Class::Shared::Protocol::encode_frame({ ok => 1 });

	my @r = $backend->_send($client, { ok => 1 });
	is_deeply(\@r, [], 'returns nothing');
	is($client->{outbuf}, $expected, 'the encoded frame is queued');
	is($backend->{queued}, length $expected, 'and counted');
	is_deeply(\@flushed, [$client], 'and a write is tried at once');
	ok(defined $client->{stalled_since}, 'the stall clock starts with the queue');
	my $first_clock = $client->{stalled_since};

	# A second reply joins the queue and does not give it a fresh deadline.
	select(undef, undef, undef, 0.02);
	$backend->_send($client, { ok => 1 });
	is($client->{outbuf}, $expected . $expected, 'a second reply is appended');
	is($client->{stalled_since}, $first_clock, 'and the clock is not restarted');
	is($backend->{queued}, 2 * length $expected, 'the total counts both');

	# A closed client is sent nothing.
	my ($closed, $closed_far) = make_client(closed => 1);
	@flushed = ();
	$backend->_send($closed, { ok => 1 });
	is($closed->{outbuf}, '', 'a closed client is sent nothing');
	is_deeply(\@flushed, [], 'and not flushed');

	# Over one client's limit.
	my ($greedy, $greedy_far) = make_client();
	@dropped = ();
	$backend->_send($greedy, { data => 'x' x 2000 });
	is(scalar(@dropped), 1, 'a reply over the per-client limit drops the client');
	like($dropped[0], qr/\Aa reply of \d+ bytes leaves \d+ waiting to be written, more than the 1000 a client may hold\z/, 'with both numbers and the limit');
	is($greedy->{outbuf}, '', 'and queues nothing');

	# Over the total.
	$backend->{queued} = 1400;
	my ($late, $late_far) = make_client();
	@dropped = ();
	$backend->_send($late, { data => 'x' x 200 });
	like($dropped[0] // '', qr/\Aa reply of \d+ bytes would leave \d+ queued across all clients, more than the 1500 the backend may hold\z/,
		'a reply that would take the whole backend over its total drops the client');
	is($backend->{queued}, 1400, 'and the total is unchanged');

	# Exactly at the per-client limit is allowed; one more is not.
	$backend->{queued} = 0;
	my ($edge, $edge_far) = make_client();
	my $payload = 'x' x 100;
	my ($frame) = Class::Shared::Protocol::encode_frame({ d => $payload });
	$backend->{max_queued} = length $frame;
	@dropped = ();
	$backend->_send($edge, { d => $payload });
	is(scalar(@dropped), 0, 'a queue exactly at the limit is allowed');
	$backend->{max_queued} = length($frame) - 1;
	my ($edge2, $edge2_far) = make_client();
	$backend->_send($edge2, { d => $payload });
	is(scalar(@dropped), 1, 'one byte over is not');
	$backend->{max_queued} = 1000;

	# A reply that cannot be encoded is replaced by an error that can.
	($client, $far) = make_client();
	$backend->{queued} = 0;
	$backend->_send($client, { code => sub { 1 } });
	my ($thawed) = Class::Shared::Protocol::take_payload(substr($client->{outbuf}, 4));
	is($thawed->{kind}, 'protocol', 'an unsendable reply becomes a protocol error');
	like($thawed->{error}, qr/\Acannot serialise message: /, 'with the reason');

	# And if even that cannot be encoded, it is logged and nothing is queued.
	($client, $far) = make_client();
	@$logged = ();
	mock('Class::Shared::Protocol::encode_frame' => sub { return (undef, 'it is hopeless') });
	$backend->_send($client, { ok => 1 });
	is($client->{outbuf}, '', 'nothing is queued');
	is_deeply($logged->[0], ['cannot encode a reply: it is hopeless', 'error'], 'and the failure is logged');
	mock('Class::Shared::Protocol::encode_frame' => sub { return (undef, undef) });
	@$logged = ();
	$backend->_send($client, { ok => 1 });
	is($logged->[0][0], 'cannot encode a reply: unknown error', 'with no reason it still says something');
	restore_all();
};

# ---------------------------------------------------------------------- _flush
subtest 'Class::Shared::Backend::_flush' => sub {
	my $backend = make_backend();
	my $logged = capture_log($backend);
	my @dropped;
	mock('Class::Shared::Backend::_drop_client' => sub { push @dropped, $_[2]; $_[1]{closed} = 1 });
	local $SIG{PIPE} = 'IGNORE';

	# Nothing to do.
	my ($client, $far) = make_client();
	is_deeply([$backend->_flush($client)], [], 'an empty queue returns nothing');
	my ($closed, $closed_far) = make_client(closed => 1, outbuf => 'abc');
	$backend->_flush($closed);
	is($closed->{outbuf}, 'abc', 'a closed client is left alone');

	# All of it goes.
	($client, $far) = make_client(outbuf => 'hello', stalled_since => 1);
	$backend->{queued} = 5;
	$backend->_flush($client);
	sysread($far, my $got, 100);
	is($got, 'hello', 'the queue is written');
	is($client->{outbuf}, '', 'and emptied');
	is($backend->{queued}, 0, 'and uncounted');
	is($client->{stalled_since}, undef, 'with the clock stopped');

	# Only part goes: a socket whose buffer is full.
	($client, $far) = make_client();
	IO::Handle::blocking($client->{fh}, 0);
	$client->{outbuf} = 'x' x (8 * 1024 * 1024);
	$client->{stalled_since} = 1;
	$backend->{queued} = length $client->{outbuf};
	$backend->_flush($client);
	cmp_ok(length $client->{outbuf}, '<', 8 * 1024 * 1024, 'part was written');
	cmp_ok(length $client->{outbuf}, '>', 0, 'and part is left to wait');
	is($backend->{queued}, length $client->{outbuf}, 'the total counts only what is left');
	cmp_ok($client->{stalled_since}, '>', 1, 'progress restarts the clock');

	# Nothing can be written now: the clock does not move.
	my $clock = $client->{stalled_since} = 12345;
	$backend->_flush($client);
	is($client->{stalled_since}, $clock, 'a flush that makes no progress leaves the deadline where it was');
	is_deeply(\@dropped, [], 'and does not drop the client');

	# The peer is gone.
	($client, $far) = make_client(outbuf => 'x');
	$backend->{queued} = 1;
	close($far);
	$backend->_flush($client);
	like($dropped[-1] // '', qr/\Awrite error: /, 'a write to a closed peer drops the client');

	# A write that takes nothing and reports nothing would spin the loop.
	@dropped = ();
	tie(*ZERO, 'Test::ScriptedHandle', 0);
	$client = { fh => \*ZERO, outbuf => 'abc', closed => 0, stalled_since => 1 };
	$backend->_flush($client);
	is_deeply(\@dropped, ['write error: peer closed the connection'], 'a write of zero bytes drops the client');
	untie(*ZERO);

	# A write error with no errno still says something.
	@dropped = ();
	{
		package Test::SilentFailure;
		sub TIEHANDLE { bless {}, shift }
		sub WRITE { $! = 0; return undef }
	}
	tie(*SILENT, 'Test::SilentFailure');
	$client = { fh => \*SILENT, outbuf => 'abc', closed => 0 };
	$backend->_flush($client);
	is_deeply(\@dropped, ['write error: unknown error'], 'an error without an errno is "unknown error"');
	untie(*SILENT);

	# A TLS layer that needs to read first is "not yet", not an error.
	@dropped = ();
	{
		package Test::WantsRead;
		sub TIEHANDLE { bless {}, shift }
		sub WRITE { $! = 0; return undef }
		sub want_read { 1 }
	}
	my $obj = bless {}, 'Test::WantsRead';
	$client = { fh => $obj, outbuf => 'abc', closed => 0, stalled_since => 7 };
	$backend->{queued} = 3;
	{
		no warnings;
		local *Test::WantsRead::syswrite_override = sub { };
	}
	mock('Class::Shared::Backend::_would_block' => sub { 1 });
	tie(*WANTS, 'Test::SilentFailure');
	$client->{fh} = \*WANTS;
	$backend->_flush($client);
	is_deeply(\@dropped, [], 'a write that is only waiting does not drop the client');
	is($client->{outbuf}, 'abc', 'and the queue is kept');
	is($client->{stalled_since}, 7, 'and the clock is unchanged');
	untie(*WANTS);
	restore_all();
};

# -------------------------------------------------------------------- _failure
subtest 'Class::Shared::Backend::_failure' => sub {
	is_deeply(Class::Shared::Backend::_failure('busy', 'too many'), { ok => 0, kind => 'busy', error => 'too many' }, 'the shape of a failure');
	is_deeply(Class::Shared::Backend::_failure('x', ''), { ok => 0, kind => 'x', error => '' }, 'an empty text is kept as it is');
	is_deeply(Class::Shared::Backend::_failure(undef, undef), { ok => 0, kind => undef, error => undef }, 'undef is kept, not filled in');

	my $one = Class::Shared::Backend::_failure('a', 'b');
	my $two = Class::Shared::Backend::_failure('a', 'b');
	isnt($one, $two, 'each call gives a new hash, so one caller cannot change another\'s');
	is_deeply([sort keys %$one], [qw(error kind ok)], 'with exactly three keys');
};

# ------------------------------------------------------------------- _dispatch
subtest 'Class::Shared::Backend::_dispatch' => sub {
	my $backend = make_backend();
	my @called;
	foreach my $op (qw(hello new call ping shutdown)) {
		mock("Class::Shared::Backend::_op_$op" => sub { push @called, $op; return { ok => 1, op => $op } });
	}
	my $greeted = { greeted => 1 };
	my $fresh = { greeted => 0 };

	foreach my $bad (undef, 'text', [], \'x', sub { 1 }) {
		my $r = $backend->_dispatch($greeted, $bad);
		is_deeply($r, { ok => 0, kind => 'protocol', error => 'request is not a hash reference' }, 'refuses ' . (defined $bad ? ref($bad) || 'text' : 'undef'));
	}
	is_deeply(\@called, [], 'and runs nothing for them');

	# A hello is the only thing a client that has not greeted may send.
	is($backend->_dispatch($fresh, { op => 'hello' })->{op}, 'hello', 'hello is routed');
	foreach my $op (qw(new call ping shutdown anything)) {
		my $r = $backend->_dispatch($fresh, { op => $op });
		is_deeply($r, { ok => 0, kind => 'protocol', error => 'handshake required' }, "$op before hello is refused");
	}
	is_deeply(\@called, ['hello'], 'and none of them ran');

	foreach my $op (qw(hello new call ping shutdown)) {
		is($backend->_dispatch($greeted, { op => $op })->{op}, $op, "$op is routed once greeted");
	}

	# Unknown operations, including ones that look like known ones.
	foreach my $op ('', 'NEW', 'Call', ' ping', 'ping ', 'ping\n', '../x', 'hello2') {
		my $r = $backend->_dispatch($greeted, { op => $op });
		is_deeply($r, { ok => 0, kind => 'protocol', error => "unknown operation '$op'" }, 'unknown operation: "' . $op . '"');
	}
	is($backend->_dispatch($greeted, {})->{error}, "unknown operation ''", 'no op at all');
	is($backend->_dispatch($greeted, { op => undef })->{error}, "unknown operation ''", 'an undef op');
	is($backend->_dispatch($fresh, {})->{error}, 'handshake required', 'no op before the hello asks for the hello');

	# The message and client are passed on as they came.
	my @args;
	mock('Class::Shared::Backend::_op_call' => sub { shift; @args = @_; return { ok => 1 } });
	my $message = { op => 'call', n => 1 };
	$backend->_dispatch($greeted, $message);
	is($args[0], $greeted, 'the client is passed on');
	is($args[1], $message, 'and the message');
	restore_all();
};

# -------------------------------------------------------------------- _op_hello
subtest 'Class::Shared::Backend::_op_hello' => sub {
	my $backend = make_backend();
	my $version = $Class::Shared::PROTOCOL_VERSION;

	my @loaded;
	mock('Class::Shared::Backend::_load_class' => sub { push @loaded, $_[1]; return (1) });

	my $client = { greeted => 0 };
	my $r = $backend->_op_hello($client, { proto => $version, class => 'Some::Class' });
	is($r->{ok}, 1, 'a good hello is answered');
	is_deeply([@{$r}{qw(class pid proto version)}], ['Some::Class', $$, $version, $Class::Shared::VERSION], 'with class, pid, protocol and version');
	is($client->{greeted}, 1, 'and the client is greeted');
	is($client->{class}, 'Some::Class', 'with its class');
	is_deeply(\@loaded, ['Some::Class'], 'which was loaded');

	# Without a class: the admin commands.
	@loaded = ();
	$client = { greeted => 0 };
	$r = $backend->_op_hello($client, { proto => $version });
	is($r->{ok}, 1, 'a hello with no class is accepted');
	is($r->{class}, undef, 'and has no class');
	is($client->{greeted}, 1, 'and is greeted');
	ok(!exists $client->{class}, 'with none set');
	$backend->_op_hello($client, { proto => $version, class => '' });
	is_deeply(\@loaded, [], 'an empty class is no class, and nothing is loaded');

	# The protocol version.
	foreach my $wrong (undef, 0, 1, $version + 1, -1, 'x', '', '2x', '2.0', ' 2', '2 ', "2\n", '0x2', '2e0', '02', [$version], {}) {
		$client = { greeted => 0 };
		my @warned = warnings_from(sub { $r = $backend->_op_hello($client, { proto => $wrong, class => 'Some::Class' }) });
		my $name = !defined $wrong ? 'undef' : ref $wrong ? ref $wrong : "'" . ($wrong =~ s/\n/\\n/gr) . "'";
		is($r->{ok}, 0, "protocol $name is refused");
		is($client->{greeted}, 0, '  and the client is not greeted');
		is_deeply(\@warned, [], '  with no warning');
	}
	$r = $backend->_op_hello({}, { proto => 1, class => 'Some::Class' });
	like($r->{error}, qr/\Aprotocol version mismatch: client speaks 1, this backend speaks \Q$version\E\z/, 'the mismatch names both versions');
	is($r->{kind}, 'protocol', 'as a protocol failure');
	$r = $backend->_op_hello({}, {});
	like($r->{error}, qr/client speaks 0,/, 'no version is version 0');

	# The class name is checked before anything is loaded.
	@loaded = ();
	foreach my $bad ('Bad Name', '../Evil', 'Foo::', "Foo\n", '1Foo', 'Foo;system("x")', '::Foo') {
		$client = { greeted => 0 };
		$r = $backend->_op_hello($client, { proto => $version, class => $bad });
		is($r->{ok}, 0, 'refuses the class ' . ($bad =~ s/\n/\\n/gr));
		is($r->{kind}, 'protocol', '  as a protocol failure');
		like($r->{error}, qr/is not a valid class name\z/, '  with the reason, trimmed');
		is($client->{greeted}, 0, '  and does not greet');
	}
	is_deeply(\@loaded, [], 'and none of them was loaded');

	# A class that cannot be loaded.
	mock('Class::Shared::Backend::_load_class' => sub { return (0, 'cannot load X: gone') });
	$client = { greeted => 0 };
	$r = $backend->_op_hello($client, { proto => $version, class => 'X::Y' });
	is_deeply($r, { ok => 0, kind => 'unknown_class', error => 'cannot load X: gone' }, 'a class that will not load is an unknown_class');
	is($client->{greeted}, 0, 'and the client is not greeted');
	ok(!exists $client->{class}, 'and no class is set');

	# A client's class is not replaced by a later hello that fails.
	$client = { greeted => 1, class => 'Kept::Class' };
	$backend->_op_hello($client, { proto => $version, class => 'X::Y' });
	is($client->{class}, 'Kept::Class', 'a failed hello leaves the earlier class');
	restore_all();
};

# ---------------------------------------------------------------------- _op_new
subtest 'Class::Shared::Backend::_op_new' => sub {
	my $backend = make_backend(max_objects => 3);
	@Test::Held::DESTROYED = ();

	my $client = { class => 'Test::Held', serial => 4, objects => {} };

	my $r = $backend->_op_new($client, { args => ['a', 'b'] });
	is_deeply([@{$r}{qw(ok id class)}], [1, 1, 'Test::Held'], 'an object is made, with the next id');
	is($backend->{objects}{1}{object}{args}[0], 'a', 'from the constructor arguments');
	is($backend->{objects}{1}{owner}, 4, 'owned by the client');
	is_deeply($client->{objects}, { 1 => 1 }, 'and listed by it');
	is($backend->{constructed}, 1, 'and counted');
	is($backend->{next_id}, 2, 'the next id moves on');

	$r = $backend->_op_new($client, {});
	is($r->{id}, 2, 'ids never repeat');
	is_deeply($backend->{objects}{2}{object}{args}, [], 'no args means none');
	$backend->_op_new($client, { args => undef });
	is(scalar(keys %{ $backend->{objects} }), 3, 'an undef args is none, too');

	# The limit.
	$r = $backend->_op_new($client, {});
	is($r->{kind}, 'busy', 'at the limit the backend is busy');
	like($r->{error}, qr/\Athis backend already holds 3 objects, its limit\z/, 'saying how many');
	is($backend->{constructed}, 3, 'and nothing more was built');

	# Refusals, with nothing built.
	delete $backend->{objects}{$_} for keys %{ $backend->{objects} };
	$backend->{constructed} = 0;
	is_deeply($backend->_op_new({ serial => 1 }, {}), { ok => 0, kind => 'protocol', error => $Class::Shared::Backend::NO_CLASS_ERROR },
		'no class named in the hello');
	foreach my $bad ('text', {}, \'x', 5) {
		$r = $backend->_op_new($client, { args => $bad });
		is_deeply($r, { ok => 0, kind => 'protocol', error => 'new: args must be an array reference' }, 'args that are ' . (ref $bad || 'text') . ' are refused');
	}

	$r = $backend->_op_new($client, { args => ['die'] });
	is_deeply($r, { ok => 0, kind => 'die', error => "refused to construct\n" }, 'a constructor that dies is a die, with its words');
	$r = $backend->_op_new($client, { args => ['scalar'] });
	is_deeply($r, { ok => 0, kind => 'protocol', error => 'Test::Held->new did not return an object' }, 'a constructor that returns no object is refused');
	is(scalar(keys %{ $backend->{objects} }), 0, 'and neither is kept');
	is($backend->{constructed}, 0, 'or counted');

	# A refused construction takes no slot: a backend with room for one object
	# still accepts the next one, under the first id.
	{
		my $limited = make_backend(max_objects => 1);
		my $limited_client = { class => 'Test::Held', serial => 9, objects => {} };

		is($limited->_op_new($limited_client, { args => ['die'] })->{ok}, 0,
			'a constructor that dies does not take the one object there is room for');

		my $accepted = $limited->_op_new($limited_client, {});
		is_deeply([@{$accepted}{qw(ok id)}], [1, 1],
			'so the next construction still gets the first object id');
		is_deeply([sort { $a <=> $b } keys %{ $limited->{objects} }], [1],
			'and only that object is held');
	}

	# $@ left over from earlier is not a failure of this constructor.
	{
		local $@ = 'stale';
		$r = $backend->_op_new($client, {});
		is($r->{ok}, 1, 'a stale $@ does not fail a good constructor');
	}

	# The caller's argument array is not kept or changed.
	my $args = ['x'];
	$backend->_op_new($client, { args => $args });
	is_deeply($args, ['x'], 'the argument list is not changed');
};

# ---------------------------------------------------------------------- _op_call
subtest 'Class::Shared::Backend::_op_call' => sub {
	my $backend = make_backend();
	my $object = Test::Held->new;
	$backend->{objects}{5} = { object => $object, owner => 2 };
	$backend->{objects}{6} = { object => Test::Held->new, owner => 3 };
	my $client = { class => 'Test::Held', serial => 2 };
	my $call = sub { $backend->_op_call($client, { id => 5, method => 'add', args => [3], want => 'scalar', @_ }) };

	# The way it works.
	my $r = $call->();
	is_deeply($r, { ok => 1, result => [3] }, 'a call returns its result in a list');
	is($backend->{calls}, 1, 'and is counted');
	is_deeply($call->(args => [4])->{result}, [7], 'the object keeps its state');

	# Context.
	is_deeply($call->(method => 'list', want => 'list')->{result}, [1, 2, 3], 'list context');
	is_deeply($call->(method => 'list', want => 'scalar')->{result}, [3], 'scalar context of a list-returning method is perl\'s own: the last');
	is_deeply($call->(method => 'nothing', want => 'list')->{result}, [], 'a method returning nothing gives no results');
	is_deeply($call->(method => 'nothing', want => 'scalar')->{result}, [undef], 'and one undef in scalar context');
	is_deeply($call->(method => 'undef_', want => 'list')->{result}, [undef], 'returning undef gives that undef in list context');
	is_deeply($call->(method => 'list', want => 'void')->{result}, [], 'void gives nothing back');
	is_deeply($call->(method => 'context', want => 'list')->{result}, ['list'], 'the method sees list context');
	is_deeply($call->(method => 'context', want => 'scalar')->{result}, ['scalar'], 'the method sees scalar context');
	{
		my $seen;
		no warnings 'redefine';
		local *Test::Held::context = sub { $seen = wantarray; return 'x' };
		$call->(method => 'context', want => 'void');
		ok(defined $seen ? 0 : 1, 'the method sees void context');
	}
	is_deeply($backend->_op_call($client, { id => 5, method => 'add' })->{result}, [8], 'no want is scalar, no args is none');
	is_deeply($backend->_op_call($client, { id => 5, method => 'add', args => undef, want => undef })->{result}, [9], 'undef want and args are the same');

	# Everything that must be refused, in the order it is checked.
	my %refusals = (
		'no class'             => [{ id => 5, method => 'add' }, { serial => 2 }, 'protocol', $Class::Shared::Backend::NO_CLASS_ERROR],
		'no id'                => [{ method => 'add' }, $client, 'protocol', 'call: no object id'],
		'an undef id'          => [{ id => undef, method => 'add' }, $client, 'protocol', 'call: no object id'],
		'an id with a letter'  => [{ id => '5a', method => 'add' }, $client, 'protocol', 'call: no object id'],
		'a negative id'        => [{ id => '-5', method => 'add' }, $client, 'protocol', 'call: no object id'],
		'an empty id'          => [{ id => '', method => 'add' }, $client, 'protocol', 'call: no object id'],
		'an id with a new line' => [{ id => "5\n", method => 'add' }, $client, 'protocol', 'call: no object id'],
		'an id of Arabic digits' => [{ id => "\x{665}", method => 'add' }, $client, 'protocol', 'call: no object id'],
		'a decimal id'         => [{ id => '5.0', method => 'add' }, $client, 'protocol', 'call: no object id'],
		'an id that is a list' => [{ id => [5], method => 'add' }, $client, 'protocol', 'call: no object id'],
		'an object that is not there' => [{ id => 99, method => 'add' }, $client, 'unknown_object', 'no object #99 here; it may have been released or its client has gone'],
		'an id with a leading zero' => [{ id => '05', method => 'add' }, $client, 'unknown_object', 'no object #05 here; it may have been released or its client has gone'],
		'another client\'s object' => [{ id => 6, method => 'add' }, $client, 'forbidden', 'object #6 belongs to another connection'],
		'no method'            => [{ id => 5 }, $client, 'protocol', 'call: no method name'],
		'an empty method'      => [{ id => 5, method => '' }, $client, 'protocol', 'call: no method name'],
		'args not a list'      => [{ id => 5, method => 'add', args => 'x' }, $client, 'protocol', 'call: args must be an array reference'],
		'args a hash'          => [{ id => 5, method => 'add', args => {} }, $client, 'protocol', 'call: args must be an array reference'],
		'a context that is made up' => [{ id => 5, method => 'add', want => 'array' }, $client, 'protocol', "call: unknown calling context 'array'"],
		'a context in capitals' => [{ id => 5, method => 'add', want => 'LIST' }, $client, 'protocol', "call: unknown calling context 'LIST'"],
		'a context with a new line' => [{ id => 5, method => 'add', want => "list\n" }, $client, 'protocol', "call: unknown calling context 'list\n'"],
		'a context that is empty' => [{ id => 5, method => 'add', want => '' }, $client, 'protocol', "call: unknown calling context ''"],
		'a qualified method'   => [{ id => 5, method => 'Storable::nstore' }, $client, 'forbidden', "call: 'Storable::nstore' is not a plain method name"],
		'a method with a dash' => [{ id => 5, method => 'a-b' }, $client, 'forbidden', "call: 'a-b' is not a plain method name"],
		'a method with a space' => [{ id => 5, method => 'a b' }, $client, 'forbidden', "call: 'a b' is not a plain method name"],
		'a method with a new line' => [{ id => 5, method => "add\n" }, $client, 'forbidden', "call: 'add\n' is not a plain method name"],
		'a method with a digit first' => [{ id => 5, method => '1add' }, $client, 'forbidden', "call: '1add' is not a plain method name"],
		'a method with a tick' => [{ id => 5, method => "Foo'bar" }, $client, 'forbidden', "call: 'Foo'bar' is not a plain method name"],
		'a method that is a code string' => [{ id => 5, method => 'add(1);system("x")' }, $client, 'forbidden', "call: 'add(1);system(\"x\")' is not a plain method name"],
		'new'                  => [{ id => 5, method => 'new' }, $client, 'forbidden', 'cannot call new() through Class::Shared'],
		'DESTROY'              => [{ id => 5, method => 'DESTROY' }, $client, 'forbidden', 'cannot call DESTROY() through Class::Shared'],
		'AUTOLOAD'             => [{ id => 5, method => 'AUTOLOAD' }, $client, 'forbidden', 'cannot call AUTOLOAD() through Class::Shared'],
		'a method that is not there' => [{ id => 5, method => 'no_such' }, $client, 'unknown_method', "Test::Held has no method 'no_such'"],
	);
	foreach my $name (sort keys %refusals) {
		my ($message, $who, $kind, $error) = @{ $refusals{$name} };
		my $calls = $backend->{calls};
		my @warned = warnings_from(sub { $r = $backend->_op_call($who, $message) });
		is_deeply($r, { ok => 0, kind => $kind, error => $error }, "refuses $name");
		is($backend->{calls}, $calls, '  and does not count it');
		is_deeply(\@warned, [], '  and does not warn') if $name =~ /id/;
	}

	# A method that dies.
	my $calls_before_boom = $backend->{calls};
	$r = $call->(method => 'boom');
	is_deeply($r, { ok => 0, kind => 'die', error => "it broke\n" }, 'a method that dies is a die, with its words');
	is($backend->{calls}, $calls_before_boom, 'and is not counted as a call that worked');

	# can and isa are answered as yes or no, and nothing crosses the wire as code.
	is_deeply($call->(method => 'can', args => ['add'])->{result}, [1], 'can says yes as 1');
	is_deeply($call->(method => 'can', args => ['nothing_like_it'])->{result}, [0], 'and no as 0');
	is_deeply($call->(method => 'isa', args => ['Test::Held'])->{result}, [1], 'isa says yes');
	is_deeply($call->(method => 'isa', args => ['Other'])->{result}, [0], 'and no');
	my @can_warnings = warnings_from(sub {
		is_deeply($call->(method => 'can', args => [])->{result}, [0], 'can with no name is no, not an error');
	});
	is_deeply(\@can_warnings, [], 'and perl has nothing to warn about');
	is($call->(method => 'can', args => ['add'], want => 'list')->{ok}, 1, 'whatever the context');

	# A class that answers everything with AUTOLOAD is not refused for lacking can().
	my $dynamic = { class => 'Test::Dynamic', serial => 2 };
	$backend->{objects}{7} = { object => Test::Dynamic->new, owner => 2 };
	is_deeply($backend->_op_call($dynamic, { id => 7, method => 'anything' })->{result}, ['dynamic:anything'], 'an AUTOLOAD class answers any plain name');

	# The count of calls only counts calls that ran.
	my $before = $backend->{calls};
	$call->(method => 'no_such');
	is($backend->{calls}, $before, 'a refused call is not a call');
	$call->();
	is($backend->{calls}, $before + 1, 'a good one is');

	# $@ left over is not a failure of this call.
	{
		local $@ = 'stale';
		is($call->()->{ok}, 1, 'a stale $@ does not fail a good call');
	}

	# The result is a copy: changing it does not change the object.
	$r = $call->(method => 'list', want => 'list');
	push @{ $r->{result} }, 4;
	is_deeply($call->(method => 'list', want => 'list')->{result}, [1, 2, 3], 'the result list is the caller\'s own');

	memory_cycle_ok($backend, 'the backend and its objects hold no loop');
};

# ------------------------------------------------------------ _limited, _timed_out
# _limited is what keeps one call that does not return from holding every
# client.  Each case checks the result triple, and that no timer or handler is
# left behind for the next request.
subtest 'Class::Shared::Backend::_limited and _timed_out' => sub {
	my $backend = make_backend(call_timeout => 1);

	# A call that returns: ok, no error, no timeout; the timer is off.
	local $SIG{ALRM} = 'DEFAULT';
	is_deeply([$backend->_limited(sub { 1 })], [1, '', 0], 'a call that returns');
	is(alarm(0), 0, 'no timer is left running');
	is($SIG{ALRM}, 'DEFAULT', 'and the caller\'s handler is back');

	# A call that dies: ok is false, the text is kept, it is not a timeout.
	is_deeply([$backend->_limited(sub { die "bad\n" })], [0, "bad\n", 0], 'a call that dies');
	is(alarm(0), 0, 'the timer is off after a die as well');

	# A call that overruns, by sleeping and by looping.
	my $start = time;
	my ($ok, $error, $timed_out) = $backend->_limited(sub { select(undef, undef, undef, 10) });
	is_deeply([$ok, $timed_out], [0, 1], 'a call that sleeps past the limit is stopped');
	cmp_ok(time - $start, '<=', 3, 'in about the limit');
	# Bounded, so that a broken limit fails the test instead of spinning for ever.
	($ok, $error, $timed_out) = $backend->_limited(sub { my $end = time + 10; 1 while time < $end });
	is_deeply([$ok, $timed_out], [0, 1], 'a busy loop is stopped too');

	# A target that catches the exception has still overrun.
	($ok, $error, $timed_out) = $backend->_limited(sub { eval { select(undef, undef, undef, 10) }; 'carried on' });
	is_deeply([$ok, $timed_out], [0, 1], 'a call that catches the exception and carries on is still reported as timed out');

	# No limit at all.
	my $free = make_backend(call_timeout => 0);
	is_deeply([$free->_limited(sub { select(undef, undef, undef, 1.2); 1 })], [1, '', 0], 'call_timeout 0 sets no timer');

	# $@ of the caller is not used.
	{
		local $@ = 'mine';
		$backend->_limited(sub { die "inner\n" });
		is($@, 'mine', '$@ is left as the caller had it');
	}

	# The reply for a stopped call.
	my $logged;
	mock('Class::Shared::Backend::_log' => sub { shift; $logged = shift; 1 });
	my $reply = $backend->_timed_out('inc');
	restore_all();
	is_deeply($reply, { ok => 0, kind => 'timeout', error => 'inc took longer than call_timeout (1 seconds) and was stopped' }, 'the reply is kind timeout with the documented text');
	is($logged, 'inc took longer than call_timeout (1 seconds) and was stopped', 'and the same text is logged');
};

# ---------------------------------------------------------------------- _op_ping
subtest 'Class::Shared::Backend::_op_ping' => sub {
	my $backend = make_backend();
	$backend->{classes} = { 'Zed' => 1, 'Alpha' => 1 };
	$backend->{objects} = { 1 => {}, 2 => {} };
	$backend->{clients} = { 3 => {}, 4 => {}, 5 => {} };
	@{$backend}{qw(queued calls constructed address)} = (12, 7, 9, '/the/socket');
	$backend->{started} = time - 100;

	my $r = $backend->_op_ping;
	is($r->{ok}, 1, 'ok');
	is_deeply($r->{classes}, ['Alpha', 'Zed'], 'the classes, sorted');
	is_deeply([@{$r}{qw(queued calls objects constructed clients address)}], [12, 7, 2, 9, 3, '/the/socket'], 'the counts');
	is_deeply([@{$r}{qw(pid proto version)}], [$$, $Class::Shared::PROTOCOL_VERSION, $Class::Shared::VERSION], 'identity');
	cmp_ok($r->{uptime}, '>=', 100, 'uptime counts from the start');
	cmp_ok($r->{uptime}, '<', 110, 'and not much more');
	is($r->{started}, $backend->{started}, 'with the start time');
	is($r->{max_queued_total}, $backend->{max_queued_total}, 'and the total queue limit');

	# Counted as they are, not as they were: asking does not change them.
	my $again = $backend->_op_ping;
	is_deeply([@{$again}{qw(calls objects clients)}], [7, 2, 3], 'a ping changes nothing');

	# An empty backend.
	my $empty = make_backend();
	my $e = $empty->_op_ping;
	is_deeply([$e->{classes}, @{$e}{qw(objects clients calls constructed queued)}], [[], 0, 0, 0, 0, 0], 'an empty backend counts zero, not undef');

	# What is returned is the caller's own: the backend's lists are not shared.
	push @{ $r->{classes} }, 'Extra';
	is_deeply([sort keys %{ $backend->{classes} }], ['Alpha', 'Zed'], 'changing the answer does not change the backend');
	is_deeply([$backend->_op_ping(1, 2, 3)->{ok}], [1], 'extra arguments are ignored');
};

# ------------------------------------------------------------------ _op_shutdown
subtest 'Class::Shared::Backend::_op_shutdown' => sub {
	my $backend = make_backend();
	my $logged = capture_log($backend);

	is_deeply($backend->_op_shutdown, { ok => 1, message => 'shutting down' }, 'the answer says so');
	is($backend->{stop}, 1, 'the loop is told to stop');
	is_deeply($logged->[0], ['shutdown requested', undef], 'and it is logged at the usual level');

	$backend->_op_shutdown;
	is($backend->{stop}, 1, 'asking twice is the same as once');
	restore_all();
};

# -------------------------------------------------------------------- _cleanup
subtest 'Class::Shared::Backend::_cleanup' => sub {
	my $dir = private_dir();
	my $socket = File::Spec->catfile($dir, 'c.sock');
	my $backend = make_backend(socket => $socket, start_timeout => 0, dir_for_files => $dir);
	$backend->_setup;
	ok(-S $socket && -e "$socket.pid" && -e "$socket.owner", 'a started backend has its three files');

	@Test::Held::DESTROYED = ();
	my ($client, $far) = make_client(serial => 1, outbuf => 'last words');
	$backend->{clients}{ fileno($client->{fh}) } = $client;
	$backend->{queued} = length $client->{outbuf};
	$backend->{objects}{1} = { object => Test::Held->new, owner => 1 };

	is($backend->_cleanup, 1, 'returns 1');
	is($backend->{cleaned}, 1, 'and marks itself done');
	ok(!-e $socket, 'the socket is removed');
	ok(!-e "$socket.pid", 'and the pid file');
	ok(-e "$socket.owner", 'the lock file stays, as it is how the next backend knows');
	is($backend->{listener}, undef, 'the listener is gone');
	is($backend->{lock}, undef, 'the lock is released');
	sysread($far, my $last, 100);
	is($last, 'last words', 'a reply that was waiting gets one last try');
	is(sysread($far, my $x, 1), 0, 'and then the client is closed');
	is_deeply([$backend->{objects}, $backend->{clients}], [{}, {}], 'every object and client is forgotten');
	is(scalar(@Test::Held::DESTROYED), 1, 'and every object destroyed, here and once');

	# The lock really is free for the next backend.
	open(my $probe, '+>>', "$socket.owner") or die;
	ok(flock($probe, Fcntl::LOCK_EX() | Fcntl::LOCK_NB()), 'another process could now take the lock');
	close($probe);

	# Only once, and DESTROY after it does nothing more.
	my @calls;
	mock('Class::Shared::Backend::_unlink' => sub { push @calls, $_[1] });
	is_deeply([$backend->_cleanup], [], 'a second cleanup returns nothing');
	is_deeply(\@calls, [], 'and removes nothing');
	restore_all();

	# A socket that was not bound here is not removed.
	my $other = make_backend(socket => File::Spec->catfile($dir, 'not-mine.sock'), dir_for_files => $dir);
	my $held = listening_socket(File::Spec->catfile($dir, 'not-mine.sock'));
	$other->_cleanup;
	ok(-S File::Spec->catfile($dir, 'not-mine.sock'), 'a socket that this backend does not own is left');
	close($held);

	# A client that is already closed is not closed again.
	my $third = make_backend(dir_for_files => $dir, socket => File::Spec->catfile($dir, 'third.sock'));
	my ($done, $done_far) = make_client(closed => 1);
	$third->{clients}{9} = $done;
	my $closes = 0;
	mock('Class::Shared::Backend::_close' => sub { $closes++; 1 });
	$third->_cleanup;
	is($closes, 0, 'a closed client is not closed twice');
	restore_all();

	# A lock that will not release is logged.
	my $fourth = make_backend(dir_for_files => $dir, socket => File::Spec->catfile($dir, 'fourth.sock'));
	open($fourth->{lock}, '<', $0) or die;
	close($fourth->{lock});
	my $lock_log = capture_log($fourth);
	my @lock_warnings = warnings_from(sub { $fourth->_cleanup });
	like($lock_log->[0][0] // '', qr/\Acannot release the lock: /, 'a lock that cannot be released is logged');
	is($lock_log->[0][1], 'error', 'as an error');
	like($lock_warnings[0] // '', qr/flock\(\) on closed filehandle/, 'perl\'s own warning is the only other noise');
	is($fourth->{lock}, undef, 'and is forgotten either way');
	restore_all();
};

# ------------------------------------------------------------------ _daemonize
subtest 'Class::Shared::Backend::_daemonize' => sub {
	my $dir = private_dir();
	my $report = File::Spec->catfile($dir, 'daemon-report');
	my $log = File::Spec->catfile($dir, 'daemon.log');
	my $backend = make_backend(log => $log, dir_for_files => $dir);
	$backend->{logger} = 'a logger from before the fork';

	# The process that calls it exits, so it is run in a child; the daemon it
	# leaves behind writes down what it finds.
	my $pid = fork() // die "fork: $!";
	if (!$pid) {
		$backend->_daemonize;
		# After the second fork the daemon is not the leader of its group, so
		# it could never take a terminal for itself even if it opened one.
		my $leads_group = POSIX::getpgrp() == $$ ? 'leader' : 'not leader';
		my $terminal = open(my $tty, '<', '/dev/tty') ? 'has terminal' : 'no terminal';
		open(my $out, '>', "$report.tmp") or POSIX::_exit(2);
		print {$out} join("\n", "$leads_group,$terminal", defined $backend->{logger} ? 'logger kept' : 'logger cleared', sprintf('%04o', umask)), "\n";
		print {$out} "unused\n";
		close($out);
		rename "$report.tmp", $report;
		print STDOUT "daemon says hello\n";
		print STDERR "daemon says hello on stderr\n";
		my $line = <STDIN>;
		open(my $in_report, '>>', $report) or POSIX::_exit(3);
		print {$in_report} defined $line ? "stdin has data\n" : "stdin at eof\n";
		close($in_report);
		POSIX::_exit(0);
	}
	waitpid($pid, 0);
	is($? >> 8, 0, 'the process that called it exits with 0');

	my $waited = 0;
	while (!-e $report && $waited++ < 100) { select(undef, undef, undef, 0.05) }
	ok(-e $report, 'the daemon ran') or BAIL_OUT('no daemon report');
	select(undef, undef, undef, 0.3);
	open(my $in, '<', $report) or die;
	chomp(my @lines = <$in>);
	close($in);

	is($lines[0], 'not leader,no terminal', 'the daemon has no terminal and cannot take one');
	is($lines[1], 'logger cleared', 'the logger made before the fork is dropped, as it names the wrong process');
	is($lines[2], '0077', 'files it makes are private');
	is($lines[-1], 'stdin at eof', 'its input is the null device');
	like(do { open(my $l, '<', $log) or die; local $/; <$l> }, qr/daemon says hello\ndaemon says hello on stderr\n/, 'its output and errors are in the log');

	# A fork that fails is reported to the caller.
	mock('Class::Shared::Backend::_daemonize' => sub { die "cannot fork: Resource temporarily unavailable\n" });
	throws_ok { $backend->_daemonize } qr/\Acannot fork: /, 'the message form is the module\'s own';
	restore_all();
};

# ---------------------------------------------------------------------- _close
subtest 'Class::Shared::Backend::_close' => sub {
	my $backend = make_backend();
	my $logged = capture_log($backend);

	my ($near, $far) = connection_pair();
	is($backend->_close($near, 'a socket'), 1, 'closing returns 1');
	is(scalar(@$logged), 0, 'and logs nothing');

	is($backend->_close($near, 'a socket'), 0, 'closing a closed handle returns 0');
	is($logged->[0][1], 'error', 'logged as an error');
	like($logged->[0][0], qr/\Acannot close a socket: .+/, 'naming what was being closed');

	restore_all();
};

# --------------------------------------------------------------------- _unlink
subtest 'Class::Shared::Backend::_unlink' => sub {
	my $dir = private_dir();
	my $backend = make_backend(dir_for_files => $dir);
	my $logged = capture_log($backend);

	my $file = File::Spec->catfile($dir, 'victim');
	open(my $fh, '>', $file) or die; close($fh);
	is($backend->_unlink($file), 1, 'a file that is there is removed');
	ok(!-e $file, 'it is gone');

	is($backend->_unlink($file), 1, 'a file that is already gone is what was wanted');
	is(scalar(@$logged), 0, 'and nothing is logged for it');

	# A directory cannot be unlinked, and says so.
	my $subdir = File::Spec->catdir($dir, 'sub');
	mkdir $subdir or die;
	is($backend->_unlink($subdir), 0, 'a path that cannot be removed returns 0');
	like($logged->[0][0], qr/\Acannot remove \Q$subdir\E: /, 'and is logged with the reason');
	is($logged->[0][1], 'error', 'as an error');

	# A stale errno from before must not read as "already gone".
	@$logged = ();
	local $! = POSIX::ENOENT();
	is($backend->_unlink($subdir), 0, 'an ENOENT left over from earlier does not hide a real failure');
	restore_all();
};

# ------------------------------------------------------------------------ _log
subtest 'Class::Shared::Backend::_log' => sub {
	my $dir = private_dir();
	my $backend = make_backend(dir_for_files => $dir, log => File::Spec->catfile($dir, 'x.log'));

	is($backend->_log('first line'), 1, 'returns 1 when the line was handed over');
	like(log_text($backend), qr/\A\[$$\] \S.* first line\n\z/, 'a line is the pid, a time and the message');
	ok(defined $backend->{logger}, 'the logger is made on first use');
	is($backend->{logger_pid}, $$, 'for this process');
	my $logger = $backend->{logger};
	$backend->_log('second line');
	is($backend->{logger}, $logger, 'and reused after that');

	# Levels.
	foreach my $level (qw(info warn error)) {
		is($backend->_log("a $level", $level), 1, "the level $level is accepted");
	}
	like(log_text($backend), qr/a warn\n.*a error\n/s, 'and logged');

	# A level the logger does not have does not break the caller.
	my @r;
	lives_ok { @r = $backend->_log('x', 'no_such_level') } 'an unknown level does not die';
	is_deeply(\@r, [0], 'it reports that nothing was logged');

	# Control characters cannot reach the log.
	$backend->_log("esc\e[31mred\x00nul\x07bell\x7Fdel");
	my $text = log_text($backend);
	unlike($text, qr/[\x00-\x08\x0B-\x1F\x7F]/s, 'no control character is written, apart from the line break and tab');
	like($text, qr/esc \[31mred nul bell del\n/, 'each run of them becomes one space');
	$backend->_log("two\nlines\tand tab");
	like(log_text($backend), qr/two\n\tlines\tand tab\n/, 'a line break and a tab are kept, the logger indenting the second line');

	# A forged line: the new line is followed by a tab, so it is not an entry of its own.
	$backend->_log("innocent\n[1] fake entry");
	unlike(log_text($backend), qr/^\[1\] fake/m, 'text cannot pass itself off as a new entry');

	# A different process makes its own logger: the pid is part of every line.
	$backend->{logger_pid} = $$ + 1;
	$backend->_log('after a fork');
	is($backend->{logger_pid}, $$, 'a logger from another process is replaced');
	isnt($backend->{logger}, $logger, 'with a new one');

	# A relative path means the same file after a chdir.
	my $relative = make_backend(dir_for_files => $dir, log => 'relative.log');
	my $cwd = Cwd::getcwd();
	chdir $dir or die;
	$relative->_log('relative');
	chdir $cwd or die;
	ok(-e File::Spec->catfile($dir, 'relative.log'), 'a relative path is made absolute when the logger is made');
	unlink 'relative.log';

	# A log called "0" is a file, not "no log".
	my $zero = make_backend(dir_for_files => $dir, log => '0');
	chdir $dir or die;
	is($zero->_log('zero'), 1, 'a log named 0 works');
	chdir $cwd or die;
	ok(-e File::Spec->catfile($dir, '0'), 'and is the file named 0');

	# No logger: nothing is logged and nothing dies.
	my $broken = make_backend(dir_for_files => $dir);
	mock('Log::Abstraction::new' => sub { die "cannot make a logger\n" });
	my $result;
	lives_ok { $result = $broken->_log('x') } 'a logger that cannot be made does not stop the backend';
	is($result, 0, 'and 0 says nothing was logged');
	restore_all();

	# A logger that fails when used.
	my $failing = make_backend(dir_for_files => $dir);
	$failing->_log('prime');
	mock('Log::Abstraction::info' => sub { die "disk full\n" });
	is($failing->_log('x'), 0, 'a write that fails is 0, not an exception');
	restore_all();

	# No message at all.
	my $none = make_backend(dir_for_files => $dir);
	my @warned = warnings_from(sub { $none->_log(undef) });
	is(scalar(grep { /uninitialized/ } @warned), 0, 'an undefined message gives no warning from here');

	ok(leaves_topic_alone(sub { $backend->_log('topic') }), '$_ is left alone');
};



done_testing();
