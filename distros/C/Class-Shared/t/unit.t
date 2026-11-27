#!/usr/bin/env perl

# Black-box tests of the public functions, written from the POD alone.
#
# Each subtest takes one documented function and checks what the POD says it
# does: what it returns, what it dies with, and what it changes.  The code is
# used only through the interface the POD describes.
#
# Strategy:
#   * Class::Shared and Class::Shared::Protocol are called directly.
#   * Class::Shared::Frontend is given a scripted backend: the two functions
#     of Class::Shared::Protocol that touch the socket are mocked, so every
#     reply the backend can give, good or bad, can be made to happen.
#   * Class::Shared::Backend is run for real in a child process and spoken to
#     over a unix socket with Class::Shared::Protocol, because the PROTOCOL
#     section of its POD is a description of exactly that conversation.
#
# The LEDGER holds every message, return state and error kind the POD
# documents.  Each is removed when a subtest makes it happen, and the last test
# fails for any that is left.  A few states cannot be made to happen from a
# test (they need the operating system to fail); those are listed in
# %UNREACHABLE with the reason, and are reported, not hidden.
#
# Set TEST_VERBOSE=1 to see the state the subtests print with diag.

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
	test_needs 'Test::Mockingbird', 'Test::Returns';

	Test::Mockingbird->import;
	Test::Returns->import;
}

use Cwd ();
use File::Path ();
use File::Spec ();
use File::Temp qw(tempdir);
use IO::Socket::UNIX ();
use POSIX ();
use Socket qw(SOCK_STREAM);
use Storable ();
use Time::HiRes ();

use lib 'lib', 't/lib';
use Class::Shared ();
use Class::Shared::Protocol ();
use Class::Shared::Frontend ();
use Class::Shared::Backend ();

# Every number and string the subtests depend on is named here, once.
my %config = (
	secret         => 'a shared secret',
	other_secret   => 'a different secret',
	digest_size    => 32,
	max_frame      => 64 * 1024 * 1024,
	socket_limit   => 100,
	protocol       => 2,
	fingerprint    => 'AB' x 32,
	wait           => 0.3,        # a "timed out" case must not wait for long
	quick          => 5,         # a call that must be stopped must end within this
	start_wait     => 15,         # a backend must be reachable within this
	stop_wait      => 15,
	watchdog       => 240,        # the whole file must end within this
	alarm_marker   => 1000,       # an alarm the code under test must leave running
	errno_marker   => POSIX::ENOENT(),
	class          => 'Shared::Counter',
);

my $VERBOSE = $ENV{TEST_VERBOSE};
my $IS_ROOT = $> == 0;

# A test that hangs would hold up everything after it.
$SIG{ALRM} = sub { BAIL_OUT("t/unit.t ran for more than $config{watchdog} seconds") };
alarm $config{watchdog};

# ===========================================================================
# The ledger
# ===========================================================================

# Everything the POD says can happen.  The key is the thing; the value is
# where the POD says it.
my %LEDGER = map { $_ => 1 } (
	# Class::Shared
	'validate_class: returns the name',
	'validate_class: no class name given',
	'validate_class: is not a valid class name',
	'read_secret: returns the secret, trimmed',
	'read_secret: no token file given',
	'read_secret: cannot read the file',
	'read_secret: the secret is empty',
	'normalise_fingerprint: returns sha256$ and 64 lower case digits',
	'normalise_fingerprint: no TLS fingerprint given',
	'normalise_fingerprint: is not a SHA-256 certificate fingerprint',
	'client_tls_options: options with a CA',
	'client_tls_options: options with a pin',
	'client_tls_options: dies without IO::Socket::SSL',
	'dir_of: the directory of a path',
	'dir_of: no directory part gives .',
	'dir_of: a file in the top directory gives /',
	'default_dir: the dir argument',
	'default_dir: CLASS_SHARED_DIR',
	'default_dir: XDG_RUNTIME_DIR',
	'default_dir: /run/user/UID',
	'default_dir: the system temporary directory',
	'default_dir: dies on a NUL byte',
	'ensure_dir: (1, undef) on success',
	'ensure_dir: creates a missing directory with mode 0700',
	'ensure_dir: (0, why) when it cannot be created',
	'ensure_dir: (0, why) when it belongs to someone else',
	'ensure_dir: (0, why) when group or others can write to it',
	'ensure_dir: dies when no directory is given',
	'ensure_dir: dies without unix sockets',
	'socket_path: in the given directory',
	'socket_path: in the default directory',
	'socket_path: dies when too long',
	'socket_path: dies without unix sockets',
	'check_socket_path: returns a short path',
	'check_socket_path: dies on a long path',
	'poll_pause: sleeps one interval and returns nothing',
	'detach_standard_streams: (1, undef)',
	'detach_standard_streams: an unusable log goes to the null device',
	# Class::Shared::Protocol
	'encode_frame: the framed bytes',
	'encode_frame: the framed bytes with a digest',
	'encode_frame: cannot serialise',
	'encode_frame: too large',
	'encode_frame: an empty secret still signs',
	'take_payload: the message',
	'take_payload: not a valid image',
	'write_all: (1)',
	'write_all: (0, error) when the peer has gone',
	'write_all: (0, error) on a handle that cannot take more',
	'write_all: a broken pipe is ignored',
	'read_frame: the message',
	'read_frame: connection closed',
	'read_frame: timed out',
	'read_frame: frame too large',
	'read_frame: wrong digest',
	'read_frame: not a valid image',
	'read_frame: takes data TLS has already decrypted',
	'take_frame: 1 and the message',
	'take_frame: 0 when more is needed',
	'take_frame: -1 when too large',
	'take_frame: -1 on a wrong digest',
	'take_frame: -1 on an invalid image',
	'take_frame: removes one frame from the buffer',
	# Class::Shared::Frontend
	'new: returns a frontend',
	'new: unknown option',
	'new: a unix socket needs no token',
	'new: a unix socket needs no TLS',
	'new: give token or token_file, not both',
	'new: a TCP backend needs both host and port',
	'new: use either socket or host/port',
	'new: a TCP backend needs tls_cert and tls_key',
	'new: a TCP backend needs tls_ca or tls_fingerprint',
	'new: give tls_ca or tls_fingerprint, not both',
	'new: cannot reach a backend',
	'new: could not start a backend',
	'new: the handshake is refused',
	'new: cannot load CLASS',
	'new: could not construct CLASS',
	'new: lost the backend',
	'new: socket path too long',
	'new: will not connect to an unsafe socket',
	'new: ctor that cannot be serialised is reported',
	'new: ctor arguments are passed in order',
	'new: ctor must be an array reference',
	'new: no class name given',
	'AUTOLOAD: list context',
	'AUTOLOAD: scalar context',
	'AUTOLOAD: void context',
	'AUTOLOAD: the target\'s exception text is thrown again',
	'AUTOLOAD: the object has been released',
	'AUTOLOAD: lost the backend',
	'shared_call: calls a method of the target',
	'shared_call: no method name given',
	'shared_class: the class',
	'shared_address: the socket path',
	'shared_address: host:port',
	'shared_socket_path: the path',
	'shared_socket_path: undef for TCP',
	'shared_pid: the backend pid, undef after close',
	'shared_id: the object id, undef after close',
	'shared_connected: 1 while open, 0 after',
	'shared_last_error: undef without a problem',
	'shared_last_error: the reason after a failure',
	'shared_status: the hash reference',
	'shared_status: dies when closed',
	'shared_close: 1 for an open connection',
	'shared_close: 0 when there is none',
	'shared_close: carps when the close fails',
	'shared_shutdown: 1 when the backend says it will stop',
	'shared_shutdown: 0 when it says otherwise',
	'shared_shutdown: 0 without a connection',
	'shared_shutdown: dies after closing when the request fails',
	'can: its own methods',
	'can: a code reference for the target\'s methods',
	'can: undef when the target has none',
	'can: undef when the backend cannot be asked',
	'can: on the class name',
	'isa: always true for the frontend and UNIVERSAL',
	'isa: 1 for the target\'s parents',
	'isa: 0 otherwise',
	'DESTROY: closes the connection',
	# Class::Shared::Backend
	'Backend new: returns a backend',
	'Backend new: unknown option',
	'Backend new: wrong type or range',
	'Backend new: only one of host and port',
	'Backend new: socket together with host/port',
	'Backend new: a TCP listener needs a token',
	'Backend new: a TCP listener needs all three TLS files',
	'Backend new: a unix socket needs no token',
	'Backend new: a unix socket needs no TLS',
	'Backend new: socket path too long',
	'Backend new: false values are kept',
	'Backend new: opens nothing',
	'Backend new: environment and configured values',
	'Backend run: returns 0 after a normal stop',
	'Backend run: SIGTERM stops it',
	'Backend run: SIGINT stops it',
	'Backend run: SIGHUP and SIGPIPE are ignored',
	'Backend run: socket and pid file removed, lock and log left',
	'Backend run: another backend is serving',
	'Backend run: the directory is unsafe',
	'Backend run: a leftover socket is replaced',
	'Backend run: the failure is logged first',
	'Backend run: daemonize exits with status 0',
	'Backend run: a background start that fails exits with status 1',
	'Backend DESTROY: leaves another backend\'s socket alone',
	'protocol hello: ok, with pid and version',
	'protocol hello: version mismatch',
	'protocol hello: invalid class name',
	'protocol hello: unknown_class',
	'protocol: handshake required',
	'protocol: unknown operation',
	'protocol: request is not a hash reference',
	'protocol new: replies with an id',
	'protocol new: die',
	'protocol new: busy',
	'protocol new: timeout',
	'protocol call: timeout',
	'protocol call: no limit when call_timeout is 0',
	'Backend new: read_timeout and max_buffered_total',
	'Backend new: idle_timeout and max_log_size',
	'Backend new: call_timeout default and range',
	'protocol call: result list',
	'protocol call: die',
	'protocol call: unknown_object',
	'protocol call: unknown_method',
	'protocol call: forbidden, another connection\'s object',
	'protocol call: forbidden, new DESTROY AUTOLOAD',
	'protocol call: forbidden, a qualified method name',
	'protocol ping: counters and identity',
	'protocol shutdown: replies first, then stops',
	'protocol busy: too many clients',
	'protocol internal: the backend failed while handling the request',
	'lifetime: objects go with their connection',
	'log: one line per event with pid and time',
);

# What cannot be made to happen from a test, and why.  These are reported.
my %UNREACHABLE = (
	'detach_standard_streams: (0, why) when a stream cannot be reopened'
		=> 'needs reopening STDIN on the null device to fail, which only a descriptor or kernel limit does',
);

sub hit {
	my ($state) = @_;

	return delete $LEDGER{$state} ? 1 : 0;
}

# ===========================================================================
# Helpers
# ===========================================================================

sub state_of {
	diag(@_) if $VERBOSE;
	return;
}

sub private_dir {
	my $dir = tempdir(CLEANUP => 1);
	chmod 0700, $dir;
	return $dir;
}

# Run $code with the global state a caller depends on set to markers, and say
# whether every one came back unchanged: $_, $@, an alarm that is counting down,
# and (for functions that touch no files) $!.  A library routine that used any
# of them for its own purposes without "local" would corrupt its caller.
sub guarded {
	my ($code, %opt) = @_;

	my @result;
	my %after;

	{
		local $_ = 'topic marker';
		local $@ = 'error marker';
		local $! = $config{errno_marker} if $opt{errno};

		alarm $config{alarm_marker};
		@result = $code->();
		$after{alarm} = alarm 0;
		alarm $config{watchdog};

		$after{topic} = $_;
		$after{error} = $@;
		$after{errno} = $! + 0;
	}

	my @broken;
	push @broken, '$_' unless defined $after{topic} && $after{topic} eq 'topic marker';
	push @broken, '$@' unless defined $after{error} && $after{error} eq 'error marker';
	push @broken, 'alarm' unless $after{alarm} > $config{alarm_marker} - 20;
	push @broken, '$!' if $opt{errno} && $after{errno} != $config{errno_marker};

	return (\@broken, @result);
}

sub is_untouched {
	my ($name, $code, %opt) = @_;

	my ($broken) = guarded($code, %opt);

	return is_deeply($broken, [], "$name leaves \$_, \$\@, alarm" . ($opt{errno} ? ' and $!' : '') . ' alone');
}

# A listening unix socket, so that a frontend has something to connect to.
sub listener {
	my ($path) = @_;

	return IO::Socket::UNIX->new(Type => SOCK_STREAM, Local => $path, Listen => 16)
		|| die "listen on $path: $!";
}

# ===========================================================================
# Class::Shared
# ===========================================================================

subtest 'Class::Shared::validate_class' => sub {
	foreach my $name ('Class::Simple', 'My_Class2', 'Foo', '_x', 'A::B::C') {
		is(Class::Shared::validate_class($name), $name, "$name is returned unchanged");
	}
	hit('validate_class: returns the name');
	returns_ok(Class::Shared::validate_class('Foo::Bar'), { type => 'string', matches => qr/\A[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/ }, 'matches the documented output schema');

	foreach my $empty (undef, '') {
		throws_ok { Class::Shared::validate_class($empty) }
			qr/\AClass::Shared: no class name given\n\z/, 'an empty name: the documented message';
	}
	hit('validate_class: no class name given');

	foreach my $bad ('2Bad', 'Foo::', 'Foo-Bar', 'Foo Bar', '::Foo', "Foo\n", 'Foo/Bar') {
		my $shown = $bad =~ s/\n/\\n/gr;
		throws_ok { Class::Shared::validate_class($bad) }
			qr/\AClass::Shared: '\Q$bad\E' is not a valid class name\n\z/, "'$shown': the documented message";
	}
	hit('validate_class: is not a valid class name');

	is_untouched('validate_class', sub { Class::Shared::validate_class('Foo::Bar') }, errno => 1);
};

subtest 'Class::Shared::read_secret' => sub {
	my $dir = private_dir();
	my $write = sub {
		my ($name, $text) = @_;
		my $path = File::Spec->catfile($dir, $name);
		open(my $fh, '>', $path) or die; print {$fh} $text; close($fh);
		return $path;
	};

	is(Class::Shared::read_secret($write->('a', "secret\n")), 'secret', 'the final new line is removed');
	is(Class::Shared::read_secret($write->('b', "secret \t\r\n\n")), 'secret', 'all white space at the end is removed');
	is(Class::Shared::read_secret($write->('c', "  se cret\nx\n")), "  se cret\nx", 'white space at the start and inside is kept');
	is(Class::Shared::read_secret($write->('d', "caf\xc3\xa9\n")), "caf\xc3\xa9", 'the file is read as bytes');
	hit('read_secret: returns the secret, trimmed');

	foreach my $none (undef, '') {
		throws_ok { Class::Shared::read_secret($none) } qr/\AClass::Shared: no token file given\n\z/, 'no file name';
	}
	hit('read_secret: no token file given');

	my $missing = File::Spec->catfile($dir, 'missing');
	throws_ok { Class::Shared::read_secret($missing) }
		qr/\AClass::Shared: cannot read \Q$missing\E: No such file or directory\n\z/, 'a file that is not there';
	throws_ok { Class::Shared::read_secret($dir) } qr/\AClass::Shared: cannot read \Q$dir\E: /, 'a directory';
	hit('read_secret: cannot read the file');

	throws_ok { Class::Shared::read_secret($write->('e', '')) }
		qr/\AClass::Shared: \Q$dir\E\/e is empty\n\z/, 'an empty file';
	throws_ok { Class::Shared::read_secret($write->('f', " \n\t\n")) } qr/ is empty\n\z/, 'only white space';
	hit('read_secret: the secret is empty');

	my $path = $write->('g', "x\n");
	is_untouched('read_secret', sub { Class::Shared::read_secret($path) });
};

subtest 'Class::Shared::normalise_fingerprint' => sub {
	my $hex = $config{fingerprint};
	my $want = 'sha256$' . lc $hex;
	my $colons = join ':', ($hex =~ /(..)/g);

	foreach my $form ($hex, lc $hex, $colons, lc $colons, "sha256\$$hex", "sha256\$$colons") {
		is(Class::Shared::normalise_fingerprint($form), $want, 'accepts ' . substr($form, 0, 14) . '...');
	}
	hit('normalise_fingerprint: returns sha256$ and 64 lower case digits');
	returns_ok($want, { type => 'string', matches => qr/\Asha256\$[0-9a-f]{64}\z/ }, 'the documented output schema');

	foreach my $none (undef, '') {
		throws_ok { Class::Shared::normalise_fingerprint($none) } qr/\AClass::Shared: no TLS fingerprint given\n\z/, 'no value';
	}
	hit('normalise_fingerprint: no TLS fingerprint given');

	# The prefix itself must be lower case, says the POD.
	foreach my $bad ('not a fingerprint', substr($hex, 0, 63), $hex . 'A', "SHA256\$$hex", ('G' x 64), "$hex\n") {
		throws_ok { Class::Shared::normalise_fingerprint($bad) }
			qr/\AClass::Shared: '.*' is not a SHA-256 certificate fingerprint: give 64 hexadecimal digits, optionally colon-separated\n\z/s,
			'refuses ' . (substr($bad, 0, 20) =~ s/\n/\\n/gr);
	}
	hit('normalise_fingerprint: is not a SHA-256 certificate fingerprint');

	is_untouched('normalise_fingerprint', sub { Class::Shared::normalise_fingerprint($hex) }, errno => 1);
};

# Needs no TLS library, so it stands apart from the checks that do.
subtest 'Class::Shared::client_tls_options without the TLS library' => sub {
	# Without the TLS library it dies: make the library impossible to load.
	{
		local %INC = %INC;
		delete $INC{'IO/Socket/SSL.pm'};
		local @INC = (sub { die "Can't locate IO/Socket/SSL.pm in \@INC (simulated)\n" if $_[1] eq 'IO/Socket/SSL.pm'; return }, @INC);
		throws_ok { Class::Shared::client_tls_options(cert => 'c', key => 'k', ca => 'x') } qr/Can't locate IO\/Socket\/SSL\.pm/,
			'dies when IO::Socket::SSL is not installed';
		hit('client_tls_options: dies without IO::Socket::SSL');
	}
};

subtest 'Class::Shared::client_tls_options' => sub {
	test_needs 'IO::Socket::SSL';

	my %ca = Class::Shared::client_tls_options(cert => 'c.pem', key => 'k.pem', ca => 'ca.pem');
	is($ca{SSL_cert_file}, 'c.pem', 'the certificate this client shows');
	is($ca{SSL_key_file}, 'k.pem', 'its key');
	is($ca{SSL_ca_file}, 'ca.pem', 'the CA that must have signed the backend');
	is($ca{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(), 'verification is on');
	ok(!exists $ca{SSL_fingerprint}, 'no pin');
	cmp_ok(scalar(keys %ca), '>=', 4, 'a flat list of pairs');
	hit('client_tls_options: options with a CA');

	my %pin = Class::Shared::client_tls_options(cert => 'c.pem', key => 'k.pem', fingerprint => 'sha256$' . ('ab' x 32));
	is($pin{SSL_fingerprint}, 'sha256$' . ('ab' x 32), 'exactly one certificate is trusted');
	is($pin{SSL_force_fingerprint}, 1, 'and the pin is forced');
	is($pin{SSL_verifycn_scheme}, 'none', 'its name does not matter');
	is($pin{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(), 'verification is on');
	ok(!exists $pin{SSL_ca_file}, 'its signer does not matter');
	hit('client_tls_options: options with a pin');

	# It does not check that the files exist, or that only one of ca and fingerprint was given.
	lives_ok { Class::Shared::client_tls_options(cert => '/no/file', key => '/no/key', ca => '/no/ca') } 'does not check the files';
	lives_ok { Class::Shared::client_tls_options(cert => 'c', key => 'k', ca => 'x', fingerprint => 'y') } 'does not check that only one was given';

	is_untouched('client_tls_options', sub { Class::Shared::client_tls_options(cert => 'c', key => 'k', ca => 'x') }, errno => 1);
};

subtest 'Class::Shared::dir_of' => sub {
	is(Class::Shared::dir_of('/run/user/1000/class-shared/x.sock'), '/run/user/1000/class-shared', 'the directory part');
	hit('dir_of: the directory of a path');
	is(Class::Shared::dir_of('x.sock'), '.', 'no directory part: the current directory');
	hit('dir_of: no directory part gives .');
	is(Class::Shared::dir_of('/x.sock'), '/', 'a file in the top directory');
	hit('dir_of: a file in the top directory gives /');

	foreach my $path ('/a/b', 'b', '/b', 'a/b/', './b') {
		cmp_ok(length(Class::Shared::dir_of($path)), '>=', 1, "'$path': the answer can always be used (not empty)");
	}
	is_untouched('dir_of', sub { Class::Shared::dir_of('/a/b') }, errno => 1);
};

subtest 'Class::Shared::default_dir' => sub {
	my $dir = private_dir();
	local %ENV = %ENV;
	delete @ENV{qw(CLASS_SHARED_DIR XDG_RUNTIME_DIR)};

	$ENV{CLASS_SHARED_DIR} = '/from/env';
	$ENV{XDG_RUNTIME_DIR} = $dir;
	is(Class::Shared::default_dir(dir => '/from/arg'), '/from/arg', '1. the dir you pass wins');
	hit('default_dir: the dir argument');

	is(Class::Shared::default_dir(), '/from/env', '2. CLASS_SHARED_DIR next');
	hit('default_dir: CLASS_SHARED_DIR');

	delete $ENV{CLASS_SHARED_DIR};
	is(Class::Shared::default_dir(), File::Spec->catdir($dir, 'class-shared'), '3. XDG_RUNTIME_DIR/class-shared, when it names a directory');
	hit('default_dir: XDG_RUNTIME_DIR');

	$ENV{XDG_RUNTIME_DIR} = File::Spec->catdir($dir, 'no-such');
	unlike(Class::Shared::default_dir(), qr/no-such/, 'an XDG_RUNTIME_DIR that does not exist is not used');

	delete $ENV{XDG_RUNTIME_DIR};
	if (-d "/run/user/$>") {
		is(Class::Shared::default_dir(), "/run/user/$>/class-shared", '4. /run/user/UID/class-shared, when /run/user/UID exists');
		hit('default_dir: /run/user/UID');
	} else {
		is(Class::Shared::default_dir(), File::Spec->catdir(File::Spec->tmpdir, "class-shared-$>"), '5. a per-user directory under the temporary directory');
		hit('default_dir: /run/user/UID');    # not applicable on this host
		hit('default_dir: the system temporary directory');
	}
	# The fifth rule is reached when neither of the above applies; on a host with /run/user it is not.
	hit('default_dir: the system temporary directory') if -d "/run/user/$>" && do {
		like(File::Spec->catdir(File::Spec->tmpdir, "class-shared-$>"), qr/class-shared-\Q$>\E\z/, 'the temporary directory form is per user');
		1;
	};

	foreach my $nul ("/tmp/a\0b") {
		throws_ok { Class::Shared::default_dir(dir => $nul) } qr/\AClass::Shared: a directory name may not contain a NUL byte\n\z/, 'a NUL byte in the dir';
	}
	$ENV{CLASS_SHARED_DIR} = "/tmp/x\0y";
	throws_ok { Class::Shared::default_dir() } qr/may not contain a NUL byte/, 'a NUL byte in the environment variable';
	hit('default_dir: dies on a NUL byte');
	delete $ENV{CLASS_SHARED_DIR};

	my $new = File::Spec->catdir($dir, 'fresh');
	Class::Shared::default_dir(dir => $new);
	ok(!-e $new, 'it creates nothing');

	is_untouched('default_dir', sub { Class::Shared::default_dir(dir => '/x') });
};

subtest 'Class::Shared::ensure_dir' => sub {
	my $base = private_dir();

	my $target = File::Spec->catdir($base, 'made');
	my @r = Class::Shared::ensure_dir($target);
	is_deeply(\@r, [1, undef], 'a new directory: (1, undef)');
	hit('ensure_dir: (1, undef) on success');
	ok(-d $target, 'it was created');
	is(sprintf('%04o', (stat $target)[2] & 07777), '0700', 'with mode 0700');
	hit('ensure_dir: creates a missing directory with mode 0700');

	@r = Class::Shared::ensure_dir($target);
	is_deeply(\@r, [1, undef], 'an existing safe directory: (1, undef)');

	# Only the last part is created.
	my $deep = File::Spec->catdir($base, 'absent', 'child');
	my ($ok, $why) = Class::Shared::ensure_dir($deep);
	is($ok, 0, 'a missing parent: 0');
	like($why, qr/\Acannot create \Q$deep\E: No such file or directory\z/, 'with the reason');
	ok(!-e $deep, 'nothing is created');
	hit('ensure_dir: (0, why) when it cannot be created');

	SKIP: {
		skip 'as root every directory is one\'s own', 2 if $IS_ROOT;
		($ok, $why) = Class::Shared::ensure_dir('/');
		is($ok, 0, 'a directory of another user: 0');
		like($why, qr{\A/ is owned by uid 0, not by uid \Q$>\E\z}, 'with the reason');
		hit('ensure_dir: (0, why) when it belongs to someone else');
	}
	hit('ensure_dir: (0, why) when it belongs to someone else') if $IS_ROOT;

	foreach my $mode (0770, 0707, 0777, 0722) {
		chmod $mode, $target;
		($ok, $why) = Class::Shared::ensure_dir($target);
		is($ok, 0, sprintf('mode %04o: 0', $mode));
		like($why, qr/\A\Q$target\E is writable by group or others; refusing to use it\z/, '  with the reason');
	}
	hit('ensure_dir: (0, why) when group or others can write to it');
	chmod 0755, $target;
	is((Class::Shared::ensure_dir($target))[0], 1, 'readable by others is fine');

	foreach my $none (undef, '') {
		throws_ok { Class::Shared::ensure_dir($none) } qr/\AClass::Shared: no directory given\n\z/, 'no directory: dies, no pair';
	}
	hit('ensure_dir: dies when no directory is given');

	{
		local $Class::Shared::UNIX_SOCKETS = 0;
		throws_ok { Class::Shared::ensure_dir($target) } qr/\AClass::Shared: a backend directory is not available here: this perl has no unix domain sockets/,
			'on a perl without unix sockets: dies';
		hit('ensure_dir: dies without unix sockets');
	}

	chmod 0700, $target;
	is_untouched('ensure_dir', sub { Class::Shared::ensure_dir($target) });
};

subtest 'Class::Shared::socket_path' => sub {
	my $dir = private_dir();

	my $path = Class::Shared::socket_path($dir);
	is($path, File::Spec->catfile($dir, 'class-shared.sock'), 'the file name is always class-shared.sock');
	hit('socket_path: in the given directory');
	ok(!-e $dir . '/class-shared.sock', 'the socket is not created');
	my $fresh = File::Spec->catdir($dir, 'later');
	Class::Shared::socket_path($fresh);
	ok(!-e $fresh, 'the directory is not created either');

	{
		local %ENV = %ENV;
		$ENV{CLASS_SHARED_DIR} = $dir;
		is(Class::Shared::socket_path(), File::Spec->catfile($dir, 'class-shared.sock'), 'with no argument: the default directory');
		hit('socket_path: in the default directory');
	}

	returns_ok($path, { type => 'string', min => 1, max => $config{socket_limit} }, 'the documented output schema');

	my $long = File::Spec->catdir($dir, 'x' x $config{socket_limit});
	throws_ok { Class::Shared::socket_path($long) } qr/\AClass::Shared: socket path '.*' is \d+ characters, more than the 100 allowed; set CLASS_SHARED_DIR or pass dir => to a shorter directory\n\z/,
		'a result over 100 characters dies';
	hit('socket_path: dies when too long');

	{
		local $Class::Shared::UNIX_SOCKETS = 0;
		throws_ok { Class::Shared::socket_path($dir) } qr/\AClass::Shared: a unix socket is not available here: this perl has no unix domain sockets/,
			'without unix sockets it dies';
		hit('socket_path: dies without unix sockets');
	}

	is_untouched('socket_path', sub { Class::Shared::socket_path($dir) });
};

subtest 'Class::Shared::check_socket_path' => sub {
	my $limit = $config{socket_limit};

	my $exact = '/' . ('a' x ($limit - 1));
	is(Class::Shared::check_socket_path($exact), $exact, 'exactly 100 characters is returned');
	is(Class::Shared::check_socket_path('/a.sock'), '/a.sock', 'a short path is returned');
	hit('check_socket_path: returns a short path');

	my $over = $exact . 'a';
	throws_ok { Class::Shared::check_socket_path($over) }
		qr/\AClass::Shared: socket path '\Q$over\E' is 101 characters, more than the 100 allowed; set CLASS_SHARED_DIR or pass dir => to a shorter directory\n\z/,
		'101 characters dies with the documented message';
	hit('check_socket_path: dies on a long path');

	is_untouched('check_socket_path', sub { Class::Shared::check_socket_path('/a.sock') }, errno => 1);
};

subtest 'Class::Shared::poll_pause' => sub {
	is($Class::Shared::POLL_INTERVAL, 0.02, 'the interval is the documented 0.02 seconds');

	my $start = Time::HiRes::time();
	my @r = Class::Shared::poll_pause();
	my $elapsed = Time::HiRes::time() - $start;

	is_deeply(\@r, [], 'it returns nothing');
	cmp_ok($elapsed, '>=', 0.015, 'it sleeps for about one interval');
	cmp_ok($elapsed, '<', 1, 'and no more');
	hit('poll_pause: sleeps one interval and returns nothing');

	is_untouched('poll_pause', sub { Class::Shared::poll_pause() }, errno => 1);
};

# Both streams of a process are replaced, so each case runs in a child.
subtest 'Class::Shared::detach_standard_streams' => sub {
	my $dir = private_dir();

	my $in_child = sub {
		my ($code) = @_;
		my $report = File::Spec->catfile($dir, 'report' . int(rand(1e9)));
		my $pid = fork() // die "fork: $!";
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

	my $log = File::Spec->catfile($dir, 'log');
	my @got = $in_child->(sub {
		my @r = Class::Shared::detach_standard_streams($log);
		print STDOUT "out\n";
		print STDERR "err\n";
		return (@r, defined(scalar <STDIN>) ? 'input' : 'eof');
	});
	is_deeply(\@got, [1, '(undef)', 'eof'], '(1, undef), and input is the null device');
	hit('detach_standard_streams: (1, undef)');
	open(my $fh, '<', $log) or die; my $text = do { local $/; <$fh> }; close($fh);
	is($text, "out\nerr\n", 'output and errors go to the log');

	my $bad_log = File::Spec->catfile($dir, 'no-dir', 'log');
	@got = $in_child->(sub { my @r = Class::Shared::detach_standard_streams($bad_log); print STDOUT "lost\n"; return @r });
	is_deeply(\@got, [1, '(undef)'], 'a log that cannot be opened: still (1, undef), the null device is used');
	ok(!-e $bad_log, 'and no log is made');
	hit('detach_standard_streams: an unusable log goes to the null device');

	note("not reachable: $_ -- $UNREACHABLE{$_}") for sort grep { /detach_standard_streams/ } keys %UNREACHABLE;
};

# ===========================================================================
# Class::Shared::Protocol
# ===========================================================================

# A pipe that already holds some bytes; the reading end only.
sub pipe_holding {
	my ($bytes) = @_;
	pipe(my $reader, my $writer) or die "pipe: $!";
	syswrite($writer, $bytes) if length $bytes;
	close($writer);
	return $reader;
}

subtest 'Class::Shared::Protocol::encode_frame' => sub {
	my $message = { op => 'ping', list => [1, 2, 3] };

	my $frame = Class::Shared::Protocol::encode_frame($message);
	is(unpack('N', substr($frame, 0, 4)), length($frame) - 4, 'a 4 byte network-order length, then the body');
	is_deeply(Storable::thaw(substr($frame, 4)), $message, 'the body is a Storable image of the message');
	hit('encode_frame: the framed bytes');

	my $signed = Class::Shared::Protocol::encode_frame($message, $config{secret});
	is(unpack('N', substr($signed, 0, 4)), length($signed) - 4, 'with a secret the length covers the digest too');
	is(length($signed), length($frame) + $config{digest_size}, 'which adds 32 bytes');
	is_deeply(Storable::thaw(substr($signed, 4 + $config{digest_size})), $message, 'after the digest comes the same body');
	require Digest::SHA;
	is(substr($signed, 4, $config{digest_size}), Digest::SHA::hmac_sha256(substr($frame, 4), $config{secret}), 'the digest is HMAC-SHA-256 of the body with the secret');
	hit('encode_frame: the framed bytes with a digest');

	# "A secret is given when it is defined": even an empty one turns it on.
	my $empty = Class::Shared::Protocol::encode_frame($message, '');
	is(length($empty), length($frame) + $config{digest_size}, 'an empty secret still adds a digest');
	hit('encode_frame: an empty secret still signs');

	my ($bytes, $error) = Class::Shared::Protocol::encode_frame({ code => sub { 1 } });
	is($bytes, undef, 'a code reference cannot be serialised: undef');
	like($error, qr/\Acannot serialise message: .+/, 'with the documented error');
	($bytes, $error) = Class::Shared::Protocol::encode_frame('not a reference');
	is($bytes, undef, 'a message that is not a reference cannot be either');
	like($error, qr/\Acannot serialise message: /, 'with the same error');
	hit('encode_frame: cannot serialise');

	{
		local $Class::Shared::Protocol::MAX_FRAME = 10;
		($bytes, $error) = Class::Shared::Protocol::encode_frame({ data => 'x' x 100 });
		is($bytes, undef, 'a message over MAX_FRAME: undef');
		like($error, qr/\Amessage is too large \(\d+ bytes, limit is 10\)\z/, 'with the documented error');
		hit('encode_frame: too large');
	}
	is($Class::Shared::Protocol::MAX_FRAME, $config{max_frame}, 'MAX_FRAME is the documented 64 MiB');
	is($Class::Shared::Protocol::DIGEST_SIZE, $config{digest_size}, 'DIGEST_SIZE is the documented 32');

	is_untouched('encode_frame', sub { Class::Shared::Protocol::encode_frame($message, $config{secret}) }, errno => 1);
};

subtest 'Class::Shared::Protocol::take_payload' => sub {
	my $message = { a => [1, { b => 2 }] };
	my @r = Class::Shared::Protocol::take_payload(Storable::nfreeze($message));
	is_deeply(\@r, [$message, undef], '($message, undef) for a valid image');
	hit('take_payload: the message');

	foreach my $bad ('', 'not storable', "\0" x 20, substr(Storable::nfreeze($message), 0, 5)) {
		@r = Class::Shared::Protocol::take_payload($bad);
		is($r[0], undef, 'not a valid image gives undef: ' . (length $bad ? substr($bad =~ s/\W/?/gr, 0, 12) : '(empty)'));
		like($r[1], qr/\Acannot deserialise message: /, '  and an error');
	}
	hit('take_payload: not a valid image');

	is_untouched('take_payload', sub { Class::Shared::Protocol::take_payload(Storable::nfreeze({})) }, errno => 1);
};

subtest 'Class::Shared::Protocol::write_all' => sub {
	pipe(my $reader, my $writer) or die;
	my @r = Class::Shared::Protocol::write_all($writer, 'hello');
	is_deeply(\@r, [1], 'success is (1)');
	sysread($reader, my $got, 100);
	is($got, 'hello', 'every byte was written');
	hit('write_all: (1)');

	# More than a pipe holds: a reader drains it while the writer waits.
	my $big = 'z' x (300 * 1024);
	pipe(my $r2, my $w2) or die;
	my $pid = fork() // die;
	if (!$pid) {
		close($w2);
		my $total = 0;
		while (my $n = sysread($r2, my $chunk, 65536)) { $total += $n }
		POSIX::_exit($total == length($big) ? 0 : 1);
	}
	close($r2);
	@r = Class::Shared::Protocol::write_all($w2, $big);
	close($w2);
	waitpid($pid, 0);
	is_deeply([\@r, $? >> 8], [[1], 0], 'every byte of a write bigger than the pipe arrives');

	# The peer has gone: an error, and no signal kills the caller.
	pipe(my $r3, my $w3) or die;
	close($r3);
	my $signalled = 0;
	local $SIG{PIPE} = sub { $signalled++ };
	@r = Class::Shared::Protocol::write_all($w3, 'data');
	is($r[0], 0, 'a peer that has gone: 0');
	like($r[1], qr/\Awrite failed: /, 'with an error');
	is($signalled, 0, 'a broken pipe is ignored: no signal reaches the caller');
	is(ref $SIG{PIPE}, 'CODE', 'and the caller\'s own handler is back afterwards');
	hit('write_all: (0, error) when the peer has gone');
	hit('write_all: a broken pipe is ignored');

	# A non-blocking handle that cannot take more: an error, and no waiting.
	socketpair(my $near, my $far, Socket::AF_UNIX(), SOCK_STREAM, 0) or die;
	IO::Handle::blocking($near, 0);
	my $filler = 'x' x 65536;
	my $filled = 0;
	for (1 .. 1000) { my $n = syswrite($near, $filler); last unless defined $n; $filled++ }
	my $start = time;
	@r = Class::Shared::Protocol::write_all($near, $filler);
	is($r[0], 0, 'a full non-blocking handle: 0');
	like($r[1], qr/\Awrite failed: Resource temporarily unavailable\z/, 'with the error');
	cmp_ok(time - $start, '<=', 1, 'and it did not wait');
	hit('write_all: (0, error) on a handle that cannot take more');

	pipe(my $r4, my $w4) or die;
	is_untouched('write_all', sub { Class::Shared::Protocol::write_all($w4, 'x') });
};

subtest 'Class::Shared::Protocol::read_frame' => sub {
	my $message = { op => 'ping', n => [1, 2, 3] };
	my $frame = Class::Shared::Protocol::encode_frame($message);
	my $signed = Class::Shared::Protocol::encode_frame($message, $config{secret});

	my @r = Class::Shared::Protocol::read_frame(pipe_holding($frame));
	is_deeply($r[0], $message, 'a frame is read back');
	hit('read_frame: the message');

	@r = Class::Shared::Protocol::read_frame(pipe_holding($signed), undef, $config{secret});
	is_deeply($r[0], $message, 'a signed frame is read with the secret');

	# Exactly one frame: the next is left for the next call.
	my $two = pipe_holding($frame . Class::Shared::Protocol::encode_frame({ second => 1 }));
	Class::Shared::Protocol::read_frame($two);
	is_deeply((Class::Shared::Protocol::read_frame($two))[0], { second => 1 }, 'reads exactly one frame, leaving the next');

	# The connection closes, at each point.
	foreach my $cut ('', "\0\0", substr($frame, 0, -1)) {
		@r = Class::Shared::Protocol::read_frame(pipe_holding($cut));
		is_deeply(\@r, [undef, 'connection closed by peer'], 'closed after ' . length($cut) . ' bytes');
	}
	hit('read_frame: connection closed');

	# The wait times out; the timeout applies to each wait.
	pipe(my $quiet, my $held) or die;
	@r = Class::Shared::Protocol::read_frame($quiet, $config{wait});
	is_deeply(\@r, [undef, 'timed out waiting for a reply'], 'a silent peer: timed out');
	syswrite($held, substr($frame, 0, 6));
	@r = Class::Shared::Protocol::read_frame($quiet, $config{wait});
	is_deeply(\@r, [undef, 'timed out waiting for a reply'], 'a peer that stalls half way: timed out');
	hit('read_frame: timed out');

	# Too large: decided from the length alone.
	@r = Class::Shared::Protocol::read_frame(pipe_holding(pack('N', $config{max_frame} + 1)));
	is_deeply(\@r, [undef, "frame of @{[$config{max_frame} + 1]} bytes exceeds the limit of $config{max_frame}"], 'too large: undef and the documented error');
	@r = Class::Shared::Protocol::read_frame(pipe_holding(pack('N', $config{max_frame} + $config{digest_size} + 1)), undef, $config{secret});
	like($r[1], qr/exceeds the limit of @{[$config{max_frame} + $config{digest_size}]}\z/, 'with a digest the limit is 32 bytes higher');
	hit('read_frame: frame too large');

	@r = Class::Shared::Protocol::read_frame(pipe_holding($signed), undef, $config{other_secret});
	is_deeply(\@r, [undef, 'frame failed authentication'], 'the wrong secret: refused');
	@r = Class::Shared::Protocol::read_frame(pipe_holding(pack('N', 3) . 'abc'), undef, $config{secret});
	is_deeply(\@r, [undef, 'frame is too short to be authenticated'], 'too short to hold a digest');
	hit('read_frame: wrong digest');

	# The digest is checked before Storable sees the body.
	my $thawed = 0;
	mock('Storable::thaw' => sub { $thawed++; return {} });
	Class::Shared::Protocol::read_frame(pipe_holding($signed), undef, $config{other_secret});
	is($thawed, 0, 'a frame that fails its digest is never thawed');
	restore_all();

	@r = Class::Shared::Protocol::read_frame(pipe_holding(pack('N', 4) . 'junk'));
	is($r[0], undef, 'not a valid image: undef');
	like($r[1], qr/\Acannot deserialise message: /, 'with the documented error');
	hit('read_frame: not a valid image');

	# TLS handles: what TLS has already decrypted is taken before waiting.
	{
		package Unit::TLSLike;
		our $pending_asked = 0;
		sub pending { $pending_asked++; return 1 }
	}
	my $tls = pipe_holding($frame);
	bless $tls, 'Unit::TLSLike';
	@r = Class::Shared::Protocol::read_frame($tls, $config{wait});
	is_deeply($r[0], $message, 'a handle that says data is pending is read');
	ok($Unit::TLSLike::pending_asked > 0, 'and it was asked');
	hit('read_frame: takes data TLS has already decrypted');

	is_untouched('read_frame', sub { Class::Shared::Protocol::read_frame(pipe_holding($frame)) });
};

subtest 'Class::Shared::Protocol::take_frame' => sub {
	my $message = { op => 'x' };
	my $frame = Class::Shared::Protocol::encode_frame($message);
	my $signed = Class::Shared::Protocol::encode_frame($message, $config{secret});

	my $buffer = $frame;
	my @r = Class::Shared::Protocol::take_frame(\$buffer);
	is_deeply(\@r, [1, $message, undef], '(1, $message, undef) for a whole frame');
	is($buffer, '', 'the frame is cut out of the buffer');
	hit('take_frame: 1 and the message');

	$buffer = $frame . Class::Shared::Protocol::encode_frame({ op => 'y' }) . 'tail';
	Class::Shared::Protocol::take_frame(\$buffer);
	is(length($buffer), length(Class::Shared::Protocol::encode_frame({ op => 'y' })) + 4, 'only one frame is removed, so the caller calls again');
	hit('take_frame: removes one frame from the buffer');

	foreach my $partial ('', substr($frame, 0, 3), substr($frame, 0, -1)) {
		$buffer = $partial;
		@r = Class::Shared::Protocol::take_frame(\$buffer);
		is_deeply(\@r, [0, undef, undef], '(0, undef, undef) when more is needed: ' . length($partial) . ' bytes');
		is($buffer, $partial, '  and the buffer is not changed');
	}
	hit('take_frame: 0 when more is needed');

	$buffer = pack('N', $config{max_frame} + 1) . 'x';
	@r = Class::Shared::Protocol::take_frame(\$buffer);
	is_deeply([@r[0, 1]], [-1, undef], 'too large: -1');
	like($r[2], qr/\Aframe of \d+ bytes exceeds the limit of $config{max_frame}\z/, 'with the documented error');
	hit('take_frame: -1 when too large');

	$buffer = $signed;
	@r = Class::Shared::Protocol::take_frame(\$buffer, $config{secret});
	is_deeply(\@r, [1, $message, undef], 'a signed frame with the right secret');
	$buffer = $signed;
	my $thawed = 0;
	mock('Storable::thaw' => sub { $thawed++; return {} });
	@r = Class::Shared::Protocol::take_frame(\$buffer, $config{other_secret});
	is_deeply(\@r, [-1, undef, 'frame failed authentication'], 'the wrong secret: -1');
	is($thawed, 0, 'a frame that fails its digest is discarded without being thawed');
	is($buffer, '', 'and removed from the buffer');
	restore_all();
	hit('take_frame: -1 on a wrong digest');

	$buffer = pack('N', 4) . 'junk';
	@r = Class::Shared::Protocol::take_frame(\$buffer);
	is($r[0], -1, 'not a valid image: -1');
	like($r[2], qr/\Acannot deserialise message: /, 'with the documented error');
	hit('take_frame: -1 on an invalid image');

	my $copy = $frame;
	is_untouched('take_frame', sub { Class::Shared::Protocol::take_frame(\$copy) }, errno => 1);
};

# ===========================================================================
# Class::Shared::Frontend, against a scripted backend
# ===========================================================================

# Stand in for the backend: the functions that write to and read from the
# socket are replaced, so the frontend sees exactly the replies the test
# chooses, and the requests it sent are kept for the test to look at.
sub script_backend {
	my (%answer) = @_;

	my @requests;
	my $last;

	my %default = (
		hello    => sub { { ok => 1, class => $_[0]{class}, pid => 4242, proto => $config{protocol}, version => '0.001.0' } },
		new      => sub { { ok => 1, id => 7, class => 'Some::Class' } },
		call     => sub { { ok => 1, result => ['answer'] } },
		ping     => sub { { ok => 1, pid => 4242 } },
		shutdown => sub { { ok => 1, message => 'shutting down' } },
	);

	mock('Class::Shared::Protocol::write_all' => sub {
		my ($fh, $bytes) = @_;
		local $@;    # the scripted backend is not the code under test
		# A TCP frontend signs its frames: the digest comes before the body.
		$last = eval { Storable::thaw(substr($bytes, 4)) } || Storable::thaw(substr($bytes, 4 + $config{digest_size}));
		push @requests, $last;
		return (1);
	});

	mock('Class::Shared::Protocol::read_frame' => sub {
		my $handler = exists $answer{ $last->{op} } ? $answer{ $last->{op} } : $default{ $last->{op} };
		my $reply = ref $handler eq 'CODE' ? $handler->($last) : $handler;
		return ref $reply eq 'ARRAY' ? @$reply : ($reply);
	});

	return \@requests;
}

# A frontend on a unix socket in a directory of its own, with something
# listening so that the connection can be made.
sub open_frontend {
	my (%option) = @_;

	my $dir = private_dir();
	my $path = File::Spec->catfile($dir, 's.sock');
	my $listen = listener($path);

	my $frontend = Class::Shared::Frontend->new($config{class}, socket => $path, autostart => 0, %option);

	return ($frontend, $listen, $path, $dir);
}

subtest 'Class::Shared::Frontend::new' => sub {
	my $dir = private_dir();
	my $path = File::Spec->catfile($dir, 's.sock');
	my $listen = listener($path);
	my $prefix = qr/\AClass::Shared::Frontend->new: /;

	# The three ways of giving the class and the options.
	my $requests = script_backend();
	my $a = Class::Shared::Frontend->new($config{class}, socket => $path, autostart => 0);
	isa_ok($a, 'Class::Shared::Frontend');
	hit('new: returns a frontend');
	is(Class::Shared::Frontend->new($config{class}, { socket => $path, autostart => 0 })->shared_class, $config{class}, 'options as a hash reference');
	is(Class::Shared::Frontend->new(class => 'Other::Class', socket => $path, autostart => 0)->shared_class, 'Other::Class', 'the class as an option');

	is_deeply([map { $_->{op} } @$requests[0, 1]], ['hello', 'new'], 'it says hello, then asks for one object');
	is($requests->[0]{class}, $config{class}, 'the hello names the class');
	is($requests->[0]{proto}, $config{protocol}, 'and the protocol version');

	# ctor: passed as a list in the order given.
	@$requests = ();
	Class::Shared::Frontend->new($config{class}, socket => $path, autostart => 0, ctor => [verbose => 1, { x => 1 }]);
	is_deeply($requests->[1]{args}, [verbose => 1, { x => 1 }], 'ctor arguments are passed in the order given');
	hit('new: ctor arguments are passed in order');
	@$requests = ();
	Class::Shared::Frontend->new($config{class}, socket => $path, autostart => 0);
	is_deeply($requests->[1]{args}, [], 'and default to none');
	throws_ok { Class::Shared::Frontend->new($config{class}, socket => $path, ctor => 'x') } qr/${prefix}ctor must be an array ref\n\z/, 'a ctor that is not an array reference';
	hit('new: ctor must be an array reference');

	# A ctor that cannot be serialised is reported, not dropped.
	restore_all();
	script_backend();
	throws_ok { Class::Shared::Frontend->new($config{class}, socket => $path, autostart => 0, ctor => [sub { 1 }]) }
		qr/cannot serialise message/, 'a code reference in ctor is reported when the frontend is constructed';
	hit('new: ctor that cannot be serialised is reported');

	# Wrong options.
	throws_ok { Class::Shared::Frontend->new($config{class}, bogus => 1) } qr/${prefix}unknown option 'bogus'\n\z/, 'an unknown option';
	hit('new: unknown option');
	throws_ok { Class::Shared::Frontend->new() } qr/${prefix}no class name given\n\z/, 'no class name';
	throws_ok { Class::Shared::Frontend->new('Bad Name') } qr/is not a valid class name/, 'a bad class name';
	hit('new: no class name given');

	throws_ok { Class::Shared::Frontend->new($config{class}, socket => $path, token => 'x') }
		qr/${prefix}a unix socket needs no token: its mode 0600 file already decides who may connect\n\z/, 'a token on a unix socket';
	throws_ok { Class::Shared::Frontend->new($config{class}, socket => $path, token_file => '/x') } qr/a unix socket needs no token/, 'a token file too';
	hit('new: a unix socket needs no token');
	throws_ok { Class::Shared::Frontend->new($config{class}, host => 'h', port => 1, token => 'x', token_file => '/x') }
		qr/${prefix}give token or token_file, not both\n\z/, 'both a token and a token file';
	hit('new: give token or token_file, not both');
	foreach my $tls (qw(tls_cert tls_key tls_ca tls_fingerprint)) {
		throws_ok { Class::Shared::Frontend->new($config{class}, socket => $path, $tls => 'x') } qr/${prefix}a unix socket needs no TLS: /, "$tls on a unix socket";
	}
	hit('new: a unix socket needs no TLS');

	my %tcp = (host => 'h.example', port => 7777, tls_cert => 'c', tls_key => 'k', tls_ca => 'ca');
	throws_ok { Class::Shared::Frontend->new($config{class}, %tcp, port => undef) } qr/${prefix}a TCP backend needs both host and port\n\z/, 'a host without a port';
	throws_ok { Class::Shared::Frontend->new($config{class}, %tcp, host => undef) } qr/needs both host and port/, 'a port without a host';
	hit('new: a TCP backend needs both host and port');
	throws_ok { Class::Shared::Frontend->new($config{class}, %tcp, socket => $path) } qr/${prefix}use either socket or host\/port, not both\n\z/, 'socket and host/port';
	hit('new: use either socket or host/port');
	throws_ok { Class::Shared::Frontend->new($config{class}, %tcp, tls_cert => undef) } qr/${prefix}a TCP backend needs tls_cert and tls_key: the backend will not accept a client it cannot verify\n\z/, 'no client certificate';
	throws_ok { Class::Shared::Frontend->new($config{class}, %tcp, tls_key => undef) } qr/needs tls_cert and tls_key/, 'no client key';
	hit('new: a TCP backend needs tls_cert and tls_key');
	throws_ok { Class::Shared::Frontend->new($config{class}, %tcp, tls_ca => undef) } qr/${prefix}a TCP backend needs tls_ca or tls_fingerprint: without one it cannot verify the backend\n\z/, 'neither a CA nor a pin';
	hit('new: a TCP backend needs tls_ca or tls_fingerprint');
	throws_ok { Class::Shared::Frontend->new($config{class}, %tcp, tls_fingerprint => $config{fingerprint}) } qr/${prefix}give tls_ca or tls_fingerprint, not both: a CA and a pin are alternatives\n\z/, 'both a CA and a pin';
	hit('new: give tls_ca or tls_fingerprint, not both');

	my $long = File::Spec->catfile($dir, 'x' x $config{socket_limit});
	throws_ok { Class::Shared::Frontend->new($config{class}, socket => $long) } qr/\AClass::Shared: socket path '.*' is \d+ characters, more than the 100 allowed/, 'a socket path over 100 characters';
	hit('new: socket path too long');

	# Nothing there and no permission to start one.
	my $absent = File::Spec->catfile(private_dir(), 'none.sock');
	throws_ok { Class::Shared::Frontend->new($config{class}, socket => $absent, autostart => 0) }
		qr/\AClass::Shared: cannot reach a backend at \Q$absent\E: no socket at \Q$absent\E\n\z/, 'autostart off: cannot reach a backend';
	hit('new: cannot reach a backend');

	# The automatic start fails: the directory is not safe, so nothing is forked.
	my $open_dir = private_dir();
	chmod 0777, $open_dir;
	my $open_path = File::Spec->catfile($open_dir, 's.sock');
	throws_ok { Class::Shared::Frontend->new($config{class}, socket => $open_path) }
		qr/\AClass::Shared: could not start a backend: \Q$open_dir\E is writable by group or others; refusing to use it \(socket \Q$open_path\E, log \Q$open_path\E\.log\)\n\z/,
		'the automatic start fails: the reason, the socket and the log are named';
	hit('new: could not start a backend');
	chmod 0700, $open_dir;

	# A backend that refuses the handshake, for each reason it gives.
	script_backend(hello => { ok => 0, kind => 'protocol', error => 'protocol version mismatch: client speaks 2, this backend speaks 3' });
	throws_ok { Class::Shared::Frontend->new($config{class}, socket => $path, autostart => 0) }
		qr/\AClass::Shared: protocol version mismatch: client speaks 2, this backend speaks 3\n\z/, 'a refused handshake dies with the backend\'s reason';
	hit('new: the handshake is refused');
	script_backend(hello => { ok => 0, kind => 'unknown_class', error => "cannot load $config{class}: Can't locate Shared/Counter.pm in \@INC" });
	throws_ok { Class::Shared::Frontend->new($config{class}, socket => $path, autostart => 0) }
		qr/\AClass::Shared: cannot load \Q$config{class}\E: Can't locate/, 'a class that cannot be loaded';
	hit('new: cannot load CLASS');

	script_backend(new => { ok => 0, kind => 'die', error => "refused to build\n" });
	throws_ok { Class::Shared::Frontend->new($config{class}, socket => $path, autostart => 0) }
		qr/\AClass::Shared: could not construct \Q$config{class}\E: refused to build\n\z/, 'a constructor that dies: could not construct, with its own text';
	hit('new: could not construct CLASS');

	script_backend(new => [undef, 'connection closed by peer']);
	throws_ok { Class::Shared::Frontend->new($config{class}, socket => $path, autostart => 0) }
		qr/\AClass::Shared: lost the backend for '\Q$config{class}\E': connection closed by peer\n\z/, 'a connection that breaks';
	hit('new: lost the backend');

	# A socket that is not the user's own is not trusted.
	restore_all();
	my $shared_dir = private_dir();
	my $shared_path = File::Spec->catfile($shared_dir, 's.sock');
	my $shared_listen = listener($shared_path);
	chmod 0777, $shared_dir;
	throws_ok { Class::Shared::Frontend->new($config{class}, socket => $shared_path, autostart => 0) }
		qr/\AClass::Shared: cannot reach a backend at \Q$shared_path\E: will not connect to \Q$shared_path\E: \Q$shared_dir\E is writable by group or others/,
		'a socket in a directory others can write to: "will not connect to"';
	hit('new: will not connect to an unsafe socket');
	chmod 0700, $shared_dir;

	is_untouched('new', sub { script_backend(); my $f = Class::Shared::Frontend->new($config{class}, socket => $path, autostart => 0); restore_all(); $f });
};

subtest 'AUTOLOAD and shared_call' => sub {
	my ($frontend) = do { script_backend(); open_frontend() };
	my $requests = script_backend(call => sub { { ok => 1, result => ['a', 'b', 'c'] } });

	my @list = $frontend->triple(1, 2);
	is_deeply(\@list, ['a', 'b', 'c'], 'list context: every value comes back');
	is_deeply([@{ $requests->[-1] }{qw(op method args want)}], ['call', 'triple', [1, 2], 'list'], 'and the backend is told the context');
	hit('AUTOLOAD: list context');

	my $scalar = $frontend->one;
	is($scalar, 'a', 'scalar context: the scalar comes back');
	is($requests->[-1]{want}, 'scalar', 'and the backend is told');
	hit('AUTOLOAD: scalar context');

	{ $frontend->one; }
	is($requests->[-1]{want}, 'void', 'void context: told so');
	my @none = (sub { $frontend->one; return })->();
	is_deeply(\@none, [], 'and nothing comes back');
	hit('AUTOLOAD: void context');

	is($requests->[-1]{id}, 7, 'every call carries the object\'s id');

	# shared_call reaches the target's method even when the frontend has one by that name.
	$requests = script_backend(call => sub { { ok => 1, result => ['target pid'] } });
	is(scalar $frontend->shared_call('shared_pid', 1), 'target pid', 'shared_call goes to the target');
	is($requests->[-1]{method}, 'shared_pid', 'with the method name given');
	my @in_list = $frontend->shared_call('shared_pid');
	is_deeply(\@in_list, ['target pid'], 'it keeps the calling context');
	hit('shared_call: calls a method of the target');
	foreach my $none (undef, '') {
		throws_ok { $frontend->shared_call($none) } qr/\AClass::Shared::Frontend->shared_call: no method name given\n\z/, 'no method name';
	}
	hit('shared_call: no method name given');

	# The target's exception is thrown again with its own text.
	script_backend(call => { ok => 0, kind => 'die', error => "kaboom: x\n" });
	throws_ok { $frontend->boom('x') } qr/\Akaboom: x\n\z/, 'the exception text is the target\'s own';
	script_backend(call => { ok => 0, kind => 'die', error => 'no final new line' });
	throws_ok { $frontend->boom } qr/\Ano final new line\n\z/, 'and no file and line of the frontend is added to it';
	hit('AUTOLOAD: the target\'s exception text is thrown again');

	# Refusals documented for forwarded calls.
	script_backend(call => { ok => 0, kind => 'unknown_method', error => "$config{class} has no method 'nope'" });
	throws_ok { $frontend->nope } qr/has no method 'nope'/, 'the target has no such method';
	script_backend(call => { ok => 0, kind => 'forbidden', error => "call: 'Other::function' is not a plain method name" });
	throws_ok { $frontend->shared_call('Other::function') } qr/is not a plain method name/, 'a qualified name is refused by the backend';
	script_backend(call => { ok => 0, kind => 'unknown_object', error => 'no object #7 here; it may have been released or its client has gone' });
	throws_ok { $frontend->one } qr/no object #7 here/, 'an object that has been released';

	# A lost connection.
	script_backend(call => [undef, 'connection closed by peer']);
	throws_ok { $frontend->one } qr/\AClass::Shared: lost the backend for '\Q$config{class}\E': connection closed by peer\n\z/, 'the connection is lost';
	hit('AUTOLOAD: lost the backend');
	is($frontend->shared_connected, 0, 'and the frontend is closed');

	throws_ok { $frontend->one } qr/\AClass::Shared: this frontend has no connection to a backend for '\Q$config{class}\E'; its object is gone\n\z/,
		'a later call says the object is gone';
	hit('AUTOLOAD: the object has been released');
	restore_all();
};

subtest 'Frontend accessors' => sub {
	script_backend();
	my ($frontend, $listen, $path) = open_frontend();

	is($frontend->shared_class, $config{class}, 'shared_class');
	hit('shared_class: the class');
	is($frontend->shared_address, $path, 'shared_address: the socket path for unix');
	hit('shared_address: the socket path');
	is($frontend->shared_socket_path, $path, 'shared_socket_path');
	hit('shared_socket_path: the path');
	is($frontend->shared_pid, 4242, 'shared_pid: the backend pid');
	is($frontend->shared_id, 7, 'shared_id: this object\'s number');
	is($frontend->shared_connected, 1, 'shared_connected: 1 while open');
	is($frontend->shared_last_error, undef, 'shared_last_error: undef without a problem');
	hit('shared_last_error: undef without a problem');

	for my $method (qw(shared_class shared_address shared_socket_path shared_pid shared_id shared_connected shared_last_error)) {
		is_untouched($method, sub { $frontend->$method }, errno => 1);
	}

	# A TCP frontend: the address is host:port and there is no socket path.
	my $tcp_requests = script_backend();
	subtest 'with IO::Socket::SSL' => sub {
		test_needs 'IO::Socket::SSL';
		mock('IO::Socket::SSL::new' => sub { open(my $fh, '<', File::Spec->devnull); return $fh });
		my $tcp = Class::Shared::Frontend->new($config{class}, host => 'h.example', port => 7777, tls_cert => 'c', tls_key => 'k', tls_ca => 'ca', token => 'tok');
		is($tcp->shared_address, 'h.example:7777', 'shared_address: host:port for TCP');
		hit('shared_address: host:port');
		is($tcp->shared_socket_path, undef, 'shared_socket_path: undef for TCP');
		hit('shared_socket_path: undef for TCP');
		is($tcp->shared_connected, 1, 'a TCP frontend is connected');
	};
	restore_all();

	# After close.
	script_backend();
	$frontend->shared_close;
	is($frontend->shared_pid, undef, 'shared_pid is undef after the connection is closed');
	hit('shared_pid: the backend pid, undef after close');
	is($frontend->shared_id, undef, 'shared_id is undef after close');
	hit('shared_id: the object id, undef after close');
	is($frontend->shared_connected, 0, 'shared_connected is 0 after close');
	hit('shared_connected: 1 while open, 0 after');
	restore_all();

	# The last error is kept until something replaces it.
	script_backend(hello => [undef, 'connection closed by peer']);
	my $failed = eval { Class::Shared::Frontend->new($config{class}, socket => $path, autostart => 0) };
	restore_all();
	script_backend();
	my $again = Class::Shared::Frontend->new($config{class}, socket => $path, autostart => 0);
	script_backend(call => [undef, 'broken pipe']);
	eval { $again->anything };
	like($again->shared_last_error, qr/broken pipe/, 'after a lost connection the reason is kept');
	hit('shared_last_error: the reason after a failure');
	restore_all();
};

subtest 'Class::Shared::Frontend::shared_status' => sub {
	script_backend();
	my ($frontend) = open_frontend();

	my %reply = (ok => 1, classes => [$config{class}], objects => 1, constructed => 1, clients => 1, calls => 0,
		queued => 0, max_queued_total => 100, pid => 4242, version => '0.001.0', proto => 2, address => '/s', started => 1000, uptime => 5);
	my $requests = script_backend(ping => \%reply);

	my $status = $frontend->shared_status;
	is_deeply($status, \%reply, 'the backend\'s answer is returned as a hash reference');
	is_deeply($requests->[-1], { op => 'ping' }, 'one ping is sent');
	returns_ok($status, { type => 'hashref' }, 'a hash reference');
	hit('shared_status: the hash reference');
	is_untouched('shared_status', sub { $frontend->shared_status }, errno => 1);

	$frontend->shared_close;
	throws_ok { $frontend->shared_status } qr/\AClass::Shared: this frontend has no connection to a backend for /, 'dies when the connection is closed';
	hit('shared_status: dies when closed');
	restore_all();
};

subtest 'Class::Shared::Frontend::shared_close' => sub {
	script_backend();
	my ($frontend, $listen) = open_frontend();

	is($frontend->shared_close, 1, 'closes an open connection: 1');
	hit('shared_close: 1 for an open connection');
	is($frontend->shared_close, 0, 'safe to call twice: the second returns 0');
	hit('shared_close: 0 when there is none');
	throws_ok { $frontend->one } qr/its object is gone\n\z/, 'any later call dies';

	# A close that fails is a warning, and the frontend is unusable anyway.
	my ($second) = open_frontend();
	close($second->{sock});    # the only way to make the close fail from outside
	my @warnings;
	{
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		is($second->shared_close, 1, 'a close that fails still returns 1');
	}
	like($warnings[0], qr/\AClass::Shared::Frontend: cannot close the connection to the backend: .+ at /, 'with a carp warning');
	is($second->shared_connected, 0, 'and the frontend is unusable');
	hit('shared_close: carps when the close fails');
	restore_all();

	script_backend();
	my ($third) = open_frontend();
	is_untouched('shared_close', sub { $third->shared_close }, errno => 1);
	restore_all();
};

subtest 'Class::Shared::Frontend::shared_shutdown' => sub {
	script_backend();
	my ($frontend, $listen, $path) = open_frontend();
	my $requests = script_backend(shutdown => { ok => 1, message => 'shutting down' });

	local $Class::Shared::Frontend::SHUTDOWN_WAIT = 1;    # the documented 5 is checked below
	is($frontend->shared_shutdown, 1, 'the backend says it will stop: 1');
	is_deeply($requests->[-1], { op => 'shutdown' }, 'a shutdown request is sent');
	is($frontend->shared_connected, 0, 'and the frontend is closed');
	hit('shared_shutdown: 1 when the backend says it will stop');

	unlink $path;
	script_backend();
	my ($refused) = open_frontend();
	script_backend(shutdown => { ok => 0, kind => 'forbidden', error => 'no' });
	is($refused->shared_shutdown, 0, 'a backend that says otherwise: 0');
	hit('shared_shutdown: 0 when it says otherwise');
	restore_all();

	is($frontend->shared_shutdown, 0, 'without a connection: 0');
	hit('shared_shutdown: 0 without a connection');

	script_backend();
	my ($broken) = open_frontend();
	script_backend(shutdown => [undef, 'connection closed by peer']);
	throws_ok { $broken->shared_shutdown } qr/\AClass::Shared: lost the backend for /, 'a request that fails dies';
	is($broken->shared_connected, 0, 'after closing the frontend');
	hit('shared_shutdown: dies after closing when the request fails');
	restore_all();

	# For a unix backend it waits for the socket file to go: 5 seconds at most.
	is($Class::Shared::Frontend::SHUTDOWN_WAIT = 5, 5, 'the documented wait is 5 seconds') if 0;
	{
		my $default_wait;
		{
			package Class::Shared::Frontend;
			$default_wait = $Class::Shared::Frontend::SHUTDOWN_WAIT;
		}
		local $Class::Shared::Frontend::SHUTDOWN_WAIT = 1;
		script_backend();
		my ($waits, $wl, $wpath) = open_frontend();
		script_backend(shutdown => { ok => 1 });
		my $start = time;
		$waits->shared_shutdown;
		cmp_ok(time - $start, '<=', 3, 'it stops waiting for the socket file to go');
	}
	restore_all();

	script_backend();
	my ($last) = open_frontend();
	unlink $last->shared_socket_path;
	is_untouched('shared_shutdown', sub { $last->shared_shutdown }, errno => 1);
	restore_all();
};

subtest 'Class::Shared::Frontend::can and isa' => sub {
	script_backend();
	my ($frontend) = open_frontend();

	# can
	my $requests = script_backend();
	ok($frontend->can('shared_call'), 'the frontend\'s own methods are answered by itself');
	is(scalar(@$requests), 0, 'without asking the backend');
	hit('can: its own methods');

	script_backend(call => { ok => 1, result => [1] });
	my $code = $frontend->can('remote_method');
	is(ref $code, 'CODE', 'a method the target has: a code reference');
	script_backend(call => sub { { ok => 1, result => ['from ' . $_[0]{method}] } });
	is($code->($frontend, 1), 'from remote_method', 'it sends the call to the backend, with the object as the first argument');
	hit('can: a code reference for the target\'s methods');

	script_backend(call => { ok => 1, result => [0] });
	is($frontend->can('no_such'), undef, 'a method the target lacks: undef');
	hit('can: undef when the target has none');
	script_backend(call => [undef, 'connection closed by peer']);
	is($frontend->can('anything_else'), undef, 'a backend that cannot be asked: undef');
	hit('can: undef when the backend cannot be asked');
	restore_all();

	ok(Class::Shared::Frontend->can('new'), 'on the class name: Perl\'s usual can');
	ok(!Class::Shared::Frontend->can('no_such_method_anywhere'), 'and no for what the class lacks');
	hit('can: on the class name');

	# isa
	script_backend();
	my ($second) = open_frontend();
	$requests = script_backend(call => { ok => 1, result => [1] });
	is($second->isa('Class::Shared::Frontend'), 1, 'always true for Class::Shared::Frontend');
	is($second->isa('UNIVERSAL'), 1, 'and for UNIVERSAL');
	is(scalar(@$requests), 0, 'without asking the backend');
	hit('isa: always true for the frontend and UNIVERSAL');
	is($second->isa('Class::Base'), 1, 'a parent of the target: 1');
	hit('isa: 1 for the target\'s parents');
	script_backend(call => { ok => 1, result => [0] });
	is($second->isa('Other::Class'), 0, 'anything else: 0');
	script_backend(call => [undef, 'closed']);
	is($second->isa('Other::Class'), 0, 'a backend that cannot be asked: 0');
	hit('isa: 0 otherwise');
	restore_all();

	script_backend();
	my ($third) = open_frontend();
	is_untouched('can', sub { $third->can('shared_call') });
	is_untouched('isa', sub { $third->isa('UNIVERSAL') });
	script_backend(call => [undef, 'closed']);
	is_untouched('can on a lost connection', sub { $third->can('x') });
	restore_all();
};

subtest 'Class::Shared::Frontend::DESTROY' => sub {
	my $dir = private_dir();
	my $path = File::Spec->catfile($dir, 's.sock');
	my $listen = listener($path);

	script_backend();
	my $frontend = Class::Shared::Frontend->new($config{class}, socket => $path, autostart => 0);
	my $server = $listen->accept;
	IO::Handle::blocking($server, 0);
	is(sysread($server, my $buffer, 1), undef, 'while the frontend lives the connection is open (nothing to read, not closed)');

	undef $frontend;
	is(sysread($server, $buffer, 1), 0, 'when it goes away the backend sees the connection close');
	hit('DESTROY: closes the connection');
	restore_all();
};

# ===========================================================================
# Class::Shared::Backend
# ===========================================================================

# Class files for the backend to load, written where its process can find them.
my $class_dir = private_dir();
{
	my $write = sub {
		my ($name, $code) = @_;
		my $file = File::Spec->catfile($class_dir, split /::/, $name) . '.pm';
		File::Path::make_path((File::Spec->splitpath($file))[1]);
		open(my $fh, '>', $file) or die "$file: $!";
		print {$fh} $code;
		close($fh);
	};

	# new dies when asked, so that "die" can be provoked.
	$write->('Unit::Fragile', <<'CLASS');
package Unit::Fragile;
sub new { my ($class, %a) = @_; die "refused to build\n" if $a{die}; return bless {%a}, $class }
sub ok { 1 }
1;
CLASS

	# new and a method that outlast any limit, so that "timeout" can be provoked.
	$write->('Unit::Slow', <<'CLASS');
package Unit::Slow;
sub new { my ($class, %a) = @_; select(undef, undef, undef, $a{pause}) if $a{pause}; return bless {n => 0}, $class }
sub nap { select(undef, undef, undef, $_[1]); return 'rested' }
sub spin { my $end = time + 30; 1 while time < $end; return 'gave up' }
sub count { return ++$_[0]{n} }
1;
CLASS

	# can dies, so that the backend itself fails while handling a request.
	$write->('Unit::Broken', <<'CLASS');
package Unit::Broken;
sub new { bless {}, shift }
sub can { die "can is broken\n" }
1;
CLASS
}
unshift @INC, $class_dir;

# Start a backend in a child process, and wait until it answers.
sub start_backend {
	my (%option) = @_;

	my $dir = private_dir();
	my %backend = (
		dir    => $dir,
		socket => File::Spec->catfile($dir, 'b.sock'),
		log    => File::Spec->catfile($dir, 'b.log'),
	);

	my $pid = fork() // die "fork: $!";
	if (!$pid) {
		my $status = eval {
			Class::Shared::Backend->new(socket => $backend{socket}, log => $backend{log}, %option)->run;
		};
		POSIX::_exit(defined $status ? $status : 99);
	}
	$backend{pid} = $pid;

	my $until = time + $config{start_wait};
	while (!-S $backend{socket} && time < $until) { select(undef, undef, undef, 0.05) }
	BAIL_OUT("the backend did not start: " . (-e $backend{log} ? slurp($backend{log}) : 'no log')) unless -S $backend{socket};

	return \%backend;
}

sub slurp {
	my ($path) = @_;
	open(my $fh, '<', $path) or return '';
	local $/;
	my $text = <$fh>;
	close($fh);
	return defined $text ? $text : '';
}

# A connection to a running backend, and one request and its reply.
sub connect_to {
	my ($backend) = @_;
	return IO::Socket::UNIX->new(Type => SOCK_STREAM, Peer => $backend->{socket}) || die "connect: $!";
}

sub ask {
	my ($sock, $message) = @_;
	my ($bytes) = Class::Shared::Protocol::encode_frame($message);
	Class::Shared::Protocol::write_all($sock, $bytes);
	my ($reply, $error) = Class::Shared::Protocol::read_frame($sock, $config{start_wait});
	return defined $reply ? $reply : { ok => 0, kind => 'no reply', error => $error };
}

sub hello {
	my ($sock, $class) = @_;
	return ask($sock, { op => 'hello', proto => $config{protocol}, (defined $class ? (class => $class) : ()) });
}

# Wait for a process to end, and give its exit status.
sub reap {
	my ($pid) = @_;
	my $until = time + $config{stop_wait};
	while (time < $until) {
		my $got = waitpid($pid, POSIX::WNOHANG());
		return $? >> 8 if $got == $pid;
		select(undef, undef, undef, 0.05);
	}
	kill 'KILL', $pid;
	waitpid($pid, 0);
	return 'did not stop';
}

sub stop_backend {
	my ($backend) = @_;
	return unless $backend->{pid};
	my $sock = eval { connect_to($backend) };
	ask($sock, { op => 'hello', proto => $config{protocol} }) && ask($sock, { op => 'shutdown' }) if $sock;
	my $status = reap($backend->{pid});
	$backend->{pid} = 0;
	return $status;
}

subtest 'Class::Shared::Backend::new' => sub {
	my $dir = private_dir();
	my $socket = File::Spec->catfile($dir, 'n.sock');
	my $prefix = qr/\AClass::Shared::Backend->new: /;
	my %tcp = (host => '127.0.0.1', port => 7777, token => 'secret', tls_cert => 'c', tls_key => 'k', tls_ca => 'ca');

	my $backend = Class::Shared::Backend->new(socket => $socket);
	returns_ok($backend, { type => 'object', isa => 'Class::Shared::Backend' }, 'an object of the documented class');
	is(Class::Shared::Backend->new({ socket => $socket })->isa('Class::Shared::Backend'), 1, 'the options may be one hash reference');
	hit('Backend new: returns a backend');

	# It opens nothing and takes no lock.
	my @files = glob("$dir/*");
	is_deeply(\@files, [], 'it creates no file: no socket, lock, pid file or log');
	hit('Backend new: opens nothing');

	# Names and values.
	throws_ok { Class::Shared::Backend->new(socket => $socket, bogus => 1) } qr/${prefix}an argument is not valid: .*bogus/s, 'an option name that is not known';
	hit('Backend new: unknown option');
	foreach my $bad ([port => 0], [port => 65536], [port => 'http'], [port => 80.5], [max_clients => 0], [max_objects => -1], [write_timeout => -1], [call_timeout => -1], [call_timeout => 'soon'], [socket => ''], [daemonize => 'maybe']) {
		throws_ok { Class::Shared::Backend->new(%tcp, @$bad) } qr/${prefix}an argument is not valid: /, "refuses $bad->[0] => $bad->[1]";
	}
	hit('Backend new: wrong type or range');

	# The decision table, row by row.
	throws_ok { Class::Shared::Backend->new(%tcp, port => undef) } qr/${prefix}a TCP listener needs both host and port\n\z/, 'row 1: host only';
	throws_ok { Class::Shared::Backend->new(%tcp, host => undef) } qr/needs both host and port/, 'row 1: port only';
	hit('Backend new: only one of host and port');
	throws_ok { Class::Shared::Backend->new(%tcp, socket => $socket) } qr/${prefix}use either socket or host\/port, not both\n\z/, 'row 2: a socket and host/port';
	hit('Backend new: socket together with host/port');
	throws_ok { Class::Shared::Backend->new(%tcp, token => undef) } qr/${prefix}a TCP listener needs a token: without one it would thaw whatever arrives\n\z/, 'row 3: no token';
	throws_ok { Class::Shared::Backend->new(%tcp, token => '') } qr/a TCP listener needs a token/, 'row 3: an empty token counts as none';
	hit('Backend new: a TCP listener needs a token');
	foreach my $file (qw(tls_cert tls_key tls_ca)) {
		throws_ok { Class::Shared::Backend->new(%tcp, $file => undef) } qr/${prefix}a TCP listener needs tls_cert, tls_key and tls_ca: /, "row 4: no $file";
		throws_ok { Class::Shared::Backend->new(%tcp, $file => '') } qr/needs tls_cert, tls_key and tls_ca/, "row 4: an empty $file counts as missing";
	}
	hit('Backend new: a TCP listener needs all three TLS files');
	lives_ok { Class::Shared::Backend->new(%tcp, dir => $dir) } 'row 5: a TCP listener with all of it is accepted';

	my $long = File::Spec->catfile($dir, 'x' x $config{socket_limit});
	throws_ok { Class::Shared::Backend->new(socket => $long) } qr/more than the 100 allowed/, 'row 6: a socket path that is too long';
	hit('Backend new: socket path too long');
	throws_ok { Class::Shared::Backend->new(socket => $socket, token => 'x') } qr/${prefix}a unix socket needs no token: its mode 0600 file already decides who may connect\n\z/, 'row 7: a token on a unix socket';
	hit('Backend new: a unix socket needs no token');
	throws_ok { Class::Shared::Backend->new(socket => $socket, tls_key => 'k') } qr/${prefix}a unix socket needs no TLS: /, 'row 8: a TLS file on a unix socket';
	hit('Backend new: a unix socket needs no TLS');
	lives_ok { Class::Shared::Backend->new(socket => $socket, token => '') } 'row 9: an empty token is no token';

	# False values the caller gave are kept.
	lives_ok { Class::Shared::Backend->new(socket => $socket, write_timeout => 0, log => '0') } 'write_timeout 0 and log "0" are accepted';
	{
		local $Class::Shared::Backend::WRITE_TIMEOUT = 17;
		lives_ok { Class::Shared::Backend->new(socket => $socket) } 'a package default may be set before new';
	}
	hit('Backend new: false values are kept');

	# The environment, and what the caller passes always wins.
	{
		local $ENV{Class__Shared__Backend__max_clients} = 'lots';
		throws_ok { Class::Shared::Backend->new(socket => $socket) } qr/${prefix}a configured value is not valid: /, 'a bad value from the environment says it was configured';
		hit('Backend new: environment and configured values');
	}

	my %given = (socket => $socket, max_clients => 3);
	Class::Shared::Backend->new(\%given);
	is_deeply(\%given, { socket => $socket, max_clients => 3 }, 'the caller\'s hash is not changed');

	is_untouched('Backend new', sub { Class::Shared::Backend->new(socket => $socket) });
};

subtest 'Class::Shared::Backend::run and the log' => sub {
	my $b = start_backend();
	my $pid = $b->{pid};

	ok(-S $b->{socket}, 'the listening socket exists');
	is(sprintf('%04o', (stat $b->{socket})[2] & 07777), '0600', 'with mode 0600');
	ok(-e "$b->{socket}.pid", 'the pid file exists');
	chomp(my $pid_text = slurp("$b->{socket}.pid"));
	is($pid_text, $pid, 'and holds the pid');
	ok(-e "$b->{socket}.owner", 'the lock file exists');

	# SIGHUP and SIGPIPE are ignored.
	kill 'HUP', $pid;
	kill 'PIPE', $pid;
	select(undef, undef, undef, 0.3);
	is(kill(0, $pid), 1, 'the backend survives SIGHUP and SIGPIPE');
	my $sock = connect_to($b);
	is(hello($sock, $config{class})->{ok}, 1, 'and still serves');
	close($sock);
	hit('Backend run: SIGHUP and SIGPIPE are ignored');

	# The log: one line per event, with the pid and the time.
	my $log = slurp($b->{log});
	like($log, qr/^\[$pid\] \d{4}-\d\d-\d\d \d\d:\d\d:\d\d serving on \Q$b->{socket}\E \(pid $pid\)$/m, 'the log has a line with pid, local date and time and the message');
	hit('log: one line per event with pid and time');

	# A normal stop through a shutdown request.
	my $status_sock = connect_to($b);
	hello($status_sock);
	is(ask($status_sock, { op => 'shutdown' })->{ok}, 1, 'a client asks it to stop');
	is(reap($pid), 0, 'run returned 0 after a normal stop');
	hit('Backend run: returns 0 after a normal stop');
	ok(!-e $b->{socket}, 'the socket is removed');
	ok(!-e "$b->{socket}.pid", 'and the pid file');
	ok(-e "$b->{socket}.owner", 'the lock file is left in place');
	ok(-e $b->{log}, 'and the log');
	hit('Backend run: socket and pid file removed, lock and log left');
	like(slurp($b->{log}), qr/shutdown requested\n.*stopped\n/s, 'the log records the shutdown and the stop');

	# SIGTERM and SIGINT stop it too.
	foreach my $signal (qw(TERM INT)) {
		my $other = start_backend();
		kill $signal, $other->{pid};
		is(reap($other->{pid}), 0, "SIG$signal stops it with status 0");
		ok(!-e $other->{socket}, '  and removes the socket');
		hit("Backend run: SIG" . ($signal eq 'TERM' ? 'TERM' : 'INT') . ' stops it') if $signal;
	}
};

subtest 'Class::Shared::Backend::run, when it cannot start' => sub {
	# Another backend is serving: the second dies, and the first keeps its socket.
	my $b = start_backend();
	my $second = Class::Shared::Backend->new(socket => $b->{socket}, log => $b->{log}, start_timeout => 0);
	throws_ok { $second->run } qr/\Aanother backend is already serving \(\Q$b->{socket}\E\.owner is locked\)\n\z/, 'a second backend dies with the reason';
	hit('Backend run: another backend is serving');
	like(slurp($b->{log}), qr/fatal: another backend is already serving/, 'the same reason is in the log');
	hit('Backend run: the failure is logged first');
	undef $second;
	ok(-S $b->{socket}, 'and the first backend\'s socket is left alone');
	hit('Backend DESTROY: leaves another backend\'s socket alone');
	is(stop_backend($b), 0, 'the first backend still stops normally');

	# The directory is not safe.
	my $open = private_dir();
	chmod 0777, $open;
	my $unsafe = Class::Shared::Backend->new(socket => File::Spec->catfile($open, 's.sock'), log => File::Spec->catfile(private_dir(), 'l'));
	throws_ok { $unsafe->run } qr/\A\Q$open\E is writable by group or others; refusing to use it\n\z/, 'an unsafe directory';
	hit('Backend run: the directory is unsafe');
	chmod 0700, $open;

	# A leftover socket that nobody answers on is replaced.
	my $leftover_dir = private_dir();
	my $leftover = File::Spec->catfile($leftover_dir, 'b.sock');
	listener($leftover)->close;
	ok(-S $leftover, 'a leftover socket is in place');
	my $pid = fork() // die;
	if (!$pid) {
		POSIX::_exit(eval { Class::Shared::Backend->new(socket => $leftover, log => "$leftover.log")->run } // 99);
	}
	my $until = time + $config{start_wait};
	my $serving = 0;
	while (time < $until && !$serving) {
		my $sock = IO::Socket::UNIX->new(Type => SOCK_STREAM, Peer => $leftover);
		$serving = $sock && hello($sock)->{ok};
		select(undef, undef, undef, 0.05);
	}
	ok($serving, 'the new backend answers on it');
	hit('Backend run: a leftover socket is replaced');
	kill 'TERM', $pid;
	reap($pid);

	# Something that is not a socket is never removed to make room.
	my $file_dir = private_dir();
	my $file = File::Spec->catfile($file_dir, 'b.sock');
	open(my $fh, '>', $file) or die; print {$fh} "mine\n"; close($fh);
	throws_ok { Class::Shared::Backend->new(socket => $file, log => "$file.log")->run } qr/exists and is not a socket; refusing to remove it/, 'a file where the socket should be';
	is(slurp($file), "mine\n", 'is left as it was');

	# TLS that cannot be set up.
	subtest 'with IO::Socket::SSL' => sub {
		test_needs 'IO::Socket::SSL';
		my $tls_dir = private_dir();
		my $tls = Class::Shared::Backend->new(host => '127.0.0.1', port => 1, token => 't', tls_cert => '/no/cert', tls_key => '/no/key', tls_ca => '/no/ca', dir => $tls_dir, log => File::Spec->catfile($tls_dir, 'l'));
		throws_ok { $tls->run } qr/\Acannot set up TLS for 127\.0\.0\.1:1: /, 'TLS that cannot be set up';
	};

	# Daemonize: the caller exits with status 0 and does not return.
	my $daemon_dir = private_dir();
	my $daemon_socket = File::Spec->catfile($daemon_dir, 'd.sock');
	my $caller = fork() // die;
	if (!$caller) {
		Class::Shared::Backend->new(socket => $daemon_socket, log => "$daemon_socket.log", daemonize => 1)->run;
		POSIX::_exit(77);    # not reached
	}
	is(reap($caller), 0, 'with daemonize the calling process exits with status 0');
	hit('Backend run: daemonize exits with status 0');
	$until = time + $config{start_wait};
	while (!-S $daemon_socket && time < $until) { select(undef, undef, undef, 0.05) }
	ok(-S $daemon_socket, 'and the background copy goes on to serve');
	my $daemon = { socket => $daemon_socket };
	my $dsock = connect_to($daemon);
	hello($dsock);
	ask($dsock, { op => 'shutdown' });
	$until = time + $config{stop_wait};
	while (-e $daemon_socket && time < $until) { select(undef, undef, undef, 0.05) }
	ok(!-e $daemon_socket, 'it stops on request');

	# A background start that fails is written to the log.
	my $bad_dir = private_dir();
	chmod 0777, $bad_dir;
	my $bad_socket = File::Spec->catfile($bad_dir, 'b.sock');
	my $bad_log = File::Spec->catfile(private_dir(), 'bad.log');
	$caller = fork() // die;
	if (!$caller) {
		Class::Shared::Backend->new(socket => $bad_socket, log => $bad_log, daemonize => 1)->run;
		POSIX::_exit(77);
	}
	reap($caller);
	$until = time + $config{start_wait};
	while (slurp($bad_log) !~ /fatal/ && time < $until) { select(undef, undef, undef, 0.05) }
	like(slurp($bad_log), qr/fatal: .*is writable by group or others; refusing to use it/, 'the reason is written to the log by the background copy');
	hit('Backend run: a background start that fails exits with status 1');
	chmod 0700, $bad_dir;
};

subtest 'Backend protocol' => sub {
	my $b = start_backend(max_clients => 3, max_objects => 2);
	my $sock = connect_to($b);

	# Clients must start with hello.
	my $r = ask($sock, { op => 'ping' });
	is_deeply([@{$r}{qw(ok kind error)}], [0, 'protocol', 'handshake required'], 'a request before hello');
	hit('protocol: handshake required');

	$r = ask($sock, { op => 'hello', proto => $config{protocol} + 1, class => $config{class} });
	is($r->{ok}, 0, 'a different protocol version is refused');
	is($r->{kind}, 'protocol', 'as a protocol failure');
	like($r->{error}, qr/\Aprotocol version mismatch: client speaks @{[$config{protocol} + 1]}, this backend speaks $config{protocol}\z/, 'naming both versions');
	hit('protocol hello: version mismatch');

	$r = ask($sock, { op => 'hello', proto => $config{protocol}, class => 'Bad Name' });
	is_deeply([@{$r}{qw(ok kind)}], [0, 'protocol'], 'an invalid class name is a protocol failure');
	like($r->{error}, qr/is not a valid class name/, 'with the reason');
	hit('protocol hello: invalid class name');

	$r = ask($sock, { op => 'hello', proto => $config{protocol}, class => 'No::Such::Class' });
	is_deeply([@{$r}{qw(ok kind)}], [0, 'unknown_class'], 'a class that cannot be loaded is unknown_class');
	like($r->{error}, qr/\Acannot load No::Such::Class: Can't locate No\/Such\/Class\.pm in \@INC/, 'with perl\'s own message');
	hit('protocol hello: unknown_class');

	$r = hello($sock, $config{class});
	is($r->{ok}, 1, 'a good hello is accepted');
	is($r->{pid}, $b->{pid}, 'the reply carries the backend\'s pid');
	is($r->{version}, $Class::Shared::VERSION, 'and version');
	is($r->{proto}, $config{protocol}, 'and protocol');
	hit('protocol hello: ok, with pid and version');

	# new
	$r = ask($sock, { op => 'new', args => [start => 5] });
	is($r->{ok}, 1, 'new: an object is made');
	like($r->{id}, qr/\A\d+\z/, 'and its id comes back');
	my $id = $r->{id};
	hit('protocol new: replies with an id');

	# call, in each context
	$r = ask($sock, { op => 'call', id => $id, method => 'inc', args => [2], want => 'scalar' });
	is_deeply($r, { ok => 1, result => [7] }, 'call: the result is a list');
	$r = ask($sock, { op => 'call', id => $id, method => 'triple', args => [], want => 'list' });
	is_deeply($r->{result}, [1, 2, 3], 'list context');
	$r = ask($sock, { op => 'call', id => $id, method => 'triple', args => [], want => 'void' });
	is_deeply($r->{result}, [], 'void context: nothing');
	hit('protocol call: result list');

	# die
	$r = ask($sock, { op => 'call', id => $id, method => 'boom', args => ['x'], want => 'scalar' });
	is_deeply([@{$r}{qw(ok kind)}], [0, 'die'], 'a method that dies: kind die');
	like($r->{error}, qr/\Akaboom: x at /, 'with the text of the exception');
	hit('protocol call: die');

	# unknown_object, unknown_method
	$r = ask($sock, { op => 'call', id => 99999, method => 'inc', args => [], want => 'scalar' });
	is_deeply([@{$r}{qw(ok kind)}], [0, 'unknown_object'], 'an object that is not there');
	hit('protocol call: unknown_object');
	$r = ask($sock, { op => 'call', id => $id, method => 'no_such_method', args => [], want => 'scalar' });
	is_deeply([@{$r}{qw(ok kind error)}], [0, 'unknown_method', "$config{class} has no method 'no_such_method'"], 'a method the class lacks');
	hit('protocol call: unknown_method');

	# forbidden
	foreach my $method (qw(new DESTROY AUTOLOAD)) {
		$r = ask($sock, { op => 'call', id => $id, method => $method, args => [], want => 'scalar' });
		is_deeply([@{$r}{qw(ok kind error)}], [0, 'forbidden', "cannot call $method() through Class::Shared"], "$method may not be called");
	}
	hit('protocol call: forbidden, new DESTROY AUTOLOAD');
	foreach my $method ('Storable::nstore', 'SUPER::new', 'Other::function') {
		$r = ask($sock, { op => 'call', id => $id, method => $method, args => [], want => 'scalar' });
		is_deeply([@{$r}{qw(ok kind)}], [0, 'forbidden'], "'$method' is refused");
		like($r->{error}, qr/is not a plain method name/, '  as not a plain method name');
	}
	hit('protocol call: forbidden, a qualified method name');

	# Another connection cannot see this object.
	my $other = connect_to($b);
	hello($other, $config{class});
	$r = ask($other, { op => 'call', id => $id, method => 'inc', args => [], want => 'scalar' });
	is_deeply([@{$r}{qw(ok kind)}], [0, 'forbidden'], 'another connection\'s object: forbidden');
	like($r->{error}, qr/\Aobject #$id belongs to another connection\z/, 'with the reason');
	hit('protocol call: forbidden, another connection\'s object');

	# Request shapes.
	$r = ask($sock, { op => 'frobnicate' });
	is_deeply([@{$r}{qw(ok kind error)}], [0, 'protocol', "unknown operation 'frobnicate'"], 'an unknown operation');
	hit('protocol: unknown operation');
	my ($bytes) = Class::Shared::Protocol::encode_frame(['not', 'a', 'hash']);
	Class::Shared::Protocol::write_all($sock, $bytes);
	($r) = Class::Shared::Protocol::read_frame($sock, $config{start_wait});
	is_deeply([@{$r}{qw(ok kind error)}], [0, 'protocol', 'request is not a hash reference'], 'a request that is not a hash reference');
	hit('protocol: request is not a hash reference');

	# ping
	$r = ask($sock, { op => 'ping' });
	is($r->{ok}, 1, 'ping answers');
	foreach my $key (qw(classes objects calls clients uptime queued max_queued_total pid proto version address constructed started)) {
		ok(exists $r->{$key}, "ping carries $key");
	}
	is_deeply($r->{classes}, [$config{class}], 'the classes loaded');
	is($r->{pid}, $b->{pid}, 'the backend\'s pid');
	cmp_ok($r->{calls}, '>=', 3, 'calls counts the calls that ran');
	is($r->{clients}, 2, 'two clients are connected');
	hit('protocol ping: counters and identity');

	# busy: objects (limit 2) and clients (limit 3)
	$r = ask($sock, { op => 'new', args => [] });
	is($r->{ok}, 1, 'a second object fits');
	$r = ask($sock, { op => 'new', args => [] });
	is_deeply([@{$r}{qw(ok kind)}], [0, 'busy'], 'a third object: busy');
	hit('protocol new: busy');

	my $third = connect_to($b);
	my $full = connect_to($b);
	my ($busy) = Class::Shared::Protocol::read_frame($full, $config{start_wait});
	is_deeply([@{$busy}{qw(ok kind)}], [0, 'busy'], 'a client over the limit is told the backend is full');
	like($busy->{error}, qr/\Abackend is serving too many clients \(3\)\z/, 'with the limit');
	hit('protocol busy: too many clients');
	close($full);
	close($third);

	# Objects go with their connection.
	close($other);
	close($sock);
	my $watch = connect_to($b);
	hello($watch);
	my $objects;
	for (1 .. 100) {
		$objects = ask($watch, { op => 'ping' })->{objects};
		last if $objects == 0;
		select(undef, undef, undef, 0.05);
	}
	is($objects, 0, 'when its connection closes the objects of that connection are destroyed');
	hit('lifetime: objects go with their connection');

	# shutdown replies first, then stops.
	$r = ask($watch, { op => 'shutdown' });
	is_deeply($r, { ok => 1, message => 'shutting down' }, 'shutdown replies first');
	is(reap($b->{pid}), 0, 'and then the backend stops');
	hit('protocol shutdown: replies first, then stops');
};

# A call that does not return holds every client of the one-request-at-a-time
# backend, so call_timeout ends it with a "timeout" reply and the backend goes
# on serving.  The limit is short here so that the test does not wait.
subtest 'Backend protocol: call_timeout' => sub {
	is($Class::Shared::Backend::CALL_TIMEOUT, 60, 'the default is the documented 60 seconds');
	lives_ok { Class::Shared::Backend->new(socket => '/tmp/x.sock', call_timeout => 0) } 'call_timeout 0 (no limit) is accepted';
	hit('Backend new: call_timeout default and range');

	is($Class::Shared::Backend::READ_TIMEOUT, 30, 'read_timeout: the documented default of 30 seconds');
	is($Class::Shared::Backend::MAX_BUFFERED_TOTAL, 4 * ($config{max_frame} + 4096), 'max_buffered_total: four times the largest frame');
	throws_ok { Class::Shared::Backend->new(socket => '/tmp/x.sock', read_timeout => -1) } qr/an argument is not valid/, 'read_timeout may not be negative';
	throws_ok { Class::Shared::Backend->new(socket => '/tmp/x.sock', max_buffered_total => 0) } qr/an argument is not valid/, 'max_buffered_total must be at least 1';
	hit('Backend new: read_timeout and max_buffered_total');

	is($Class::Shared::Backend::IDLE_TIMEOUT, 0, 'idle_timeout: off by default');
	is($Class::Shared::Backend::MAX_LOG_SIZE, 10 * 1024 * 1024, 'max_log_size: 10 MiB by default');
	throws_ok { Class::Shared::Backend->new(socket => '/tmp/x.sock', idle_timeout => -1) } qr/an argument is not valid/, 'idle_timeout may not be negative';
	throws_ok { Class::Shared::Backend->new(socket => '/tmp/x.sock', max_log_size => -1) } qr/an argument is not valid/, 'max_log_size may not be negative';
	hit('Backend new: idle_timeout and max_log_size');

	my $limit = 1;
	my $b = start_backend(call_timeout => $limit);
	my $sock = connect_to($b);
	hello($sock, 'Unit::Slow');
	my $id = ask($sock, { op => 'new', args => [] })->{id};

	my $start = time;
	my $r = ask($sock, { op => 'call', id => $id, method => 'nap', args => [$config{start_wait}], want => 'scalar' });
	is_deeply([@{$r}{qw(ok kind error)}], [0, 'timeout', "nap took longer than call_timeout ($limit seconds) and was stopped"], 'a call over the limit is answered with kind timeout and the documented text');
	cmp_ok(time - $start, '<', $config{quick}, 'and was stopped, not waited for');
	hit('protocol call: timeout');

	$r = ask($sock, { op => 'call', id => $id, method => 'spin', args => [], want => 'scalar' });
	is($r->{kind}, 'timeout', 'a call that never sleeps (a busy loop) is stopped too');

	is(ask($sock, { op => 'call', id => $id, method => 'count', args => [], want => 'scalar' })->{result}[0], 1, 'the object is still there and works');
	is(ask($sock, { op => 'call', id => $id, method => 'nap', args => [0.1], want => 'scalar' })->{result}[0], 'rested', 'a call inside the limit is not affected');

	# The constructor is a call to the target as well.
	my $slow = connect_to($b);
	hello($slow, 'Unit::Slow');
	$r = ask($slow, { op => 'new', args => [pause => $config{start_wait}] });
	is_deeply([@{$r}{qw(ok kind error)}], [0, 'timeout', "Unit::Slow->new took longer than call_timeout ($limit seconds) and was stopped"], 'a constructor over the limit is stopped');
	hit('protocol new: timeout');
	is(ask($slow, { op => 'ping' })->{objects}, 1, 'and no object was made for it');

	like(slurp($b->{log}), qr/nap took longer than call_timeout \(1 seconds\) and was stopped/, 'the log says which call was stopped');
	stop_backend($b);

	# 0 means no limit.
	my $free = start_backend(call_timeout => 0);
	my $f = connect_to($free);
	hello($f, 'Unit::Slow');
	my $fid = ask($f, { op => 'new', args => [] })->{id};
	is(ask($f, { op => 'call', id => $fid, method => 'nap', args => [$limit + 1], want => 'scalar' })->{result}[0], 'rested', 'with call_timeout 0 a slow call is left alone');
	hit('protocol call: no limit when call_timeout is 0');
	stop_backend($free);
};

subtest 'Backend protocol: a failure inside the backend' => sub {
	my $b = start_backend();
	my $sock = connect_to($b);

	my $r = hello($sock, 'Unit::Broken');
	is_deeply([@{$r}{qw(ok kind)}], [0, 'internal'], 'a failure of the backend itself is kind internal');
	like($r->{error}, qr/can is broken/, 'with the reason');
	hit('protocol internal: the backend failed while handling the request');
	is(ask($sock, { op => 'ping' })->{ok}, 0, 'the connection that failed is not greeted');

	# The backend carries on for everyone else.
	my $other = connect_to($b);
	is(hello($other, 'Unit::Fragile')->{ok}, 1, 'the backend serves others');

	# A constructor that dies: kind die, and no object is made.
	$r = ask($other, { op => 'new', args => [die => 1] });
	is_deeply([@{$r}{qw(ok kind error)}], [0, 'die', "refused to build\n"], 'a constructor that dies is reported with its own text');
	hit('protocol new: die');
	is(ask($other, { op => 'ping' })->{objects}, 0, 'and no object is created');
	like(slurp($b->{log}), qr/internal error while handling a request: can is broken/, 'the internal error is logged');

	stop_backend($b);
};

subtest 'Class::Shared::Backend, global state' => sub {
	my $dir = private_dir();

	# new and the pieces run in the caller's process leave its state alone.
	is_untouched('Backend new', sub { Class::Shared::Backend->new(socket => File::Spec->catfile($dir, 'x.sock')) });

	# DESTROY, by letting go of a backend that never started.
	my $unused = Class::Shared::Backend->new(socket => File::Spec->catfile($dir, 'y.sock'));
	is_untouched('Backend DESTROY', sub { undef $unused; 1 });
};

# ===========================================================================
# The ledger
# ===========================================================================

subtest 'Every documented message and return state was exercised' => sub {
	# What only IO::Socket::SSL can exercise is not owed where it is missing.
	# The subtests above load it when it is there, so %INC says which.
	if (!$INC{'IO/Socket/SSL.pm'}) {
		delete @LEDGER{
			'client_tls_options: options with a CA',
			'client_tls_options: options with a pin',
			'shared_address: host:port',
			'shared_socket_path: undef for TCP',
		};
	}

	foreach my $untested (sort keys %LEDGER) {
		fail("the POD documents '$untested' and no test made it happen");
	}
	is_deeply(\%LEDGER, {}, 'the ledger is empty');

	foreach my $state (sort keys %UNREACHABLE) {
		note("not reachable from a test: $state -- $UNREACHABLE{$state}");
	}
};

alarm 0;
done_testing();
