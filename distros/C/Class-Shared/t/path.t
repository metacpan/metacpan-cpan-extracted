#!/usr/bin/perl

# Path coverage for Class::Shared and its three modules.
#
# Every subtest is one routine.  Inside it, one case per unique path through
# that routine: each guard clause (both sides), each branch of each boolean,
# each iteration boundary of each loop, and each error exit.  The names say
# which path a case takes, so a failure names the edge of the graph that broke.
#
# A path that cannot be reached from this harness is called out in a comment
# where it would have been tested, and the reason is given there.
#
# Routines that need a live backend or a fork -- _connect, _open,
# _create_object, _spawn_backend, detach_standard_streams and the backend's
# select loop -- are covered by the end-to-end suites, which start a real
# backend.  This file does not mock a whole backend into existence.
#
# The file is ASCII only.  Non-ASCII test data is written with \x{...}.

use strict;
use warnings;

use Digest::SHA ();
use Errno ();
use File::Spec ();
use File::Temp ();
use IO::Socket::SSL ();
use Fcntl ();
use Socket ();
use Time::HiRes ();
use Storable ();
use Test::Mockingbird;
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
use Test::Returns;

use lib 't/lib';

use Class::Shared;
use Class::Shared::Backend ();
use Class::Shared::Frontend;
use Class::Shared::Protocol;

my %config = (
	# Limits and modes, from the Z basic types and the POD.
	max_secret         => 65_536,
	max_socket_path    => 100,
	sha256_bytes       => 32,
	digest_size        => 32,
	create_mode        => 0700,
	group_write_bit    => 0020,
	other_write_bit    => 0002,
	socket_name        => 'class-shared.sock',
	fingerprint_prefix => 'sha256$',
	poll_interval      => $Class::Shared::POLL_INTERVAL,
	err => {
		no_class        => 'Class::Shared: no class name given',
		bad_class       => q{Class::Shared: '%s' is not a valid class name},
		no_token        => 'Class::Shared: no token file given',
		token_empty     => 'Class::Shared: %s is empty',
		token_large     => 'Class::Shared: %s is too large to be a secret (more than %d bytes)',
		no_fingerprint  => 'Class::Shared: no TLS fingerprint given',
		bad_fingerprint => q{Class::Shared: '%s' is not a SHA-256 certificate fingerprint: }
			. 'give 64 hexadecimal digits, optionally colon-separated',
		no_socket    => 'Class::Shared: no socket path given',
		socket_long  => q{Class::Shared: socket path '%s' is %d characters, more than the %d allowed; }
			. 'set CLASS_SHARED_DIR or pass dir => to a shorter directory',
		no_dir       => 'Class::Shared: no directory given',
		dir_unsafe   => '%s is writable by group or others; refusing to use it',
		unix_missing => 'Class::Shared: %s is not available here: this perl has no unix '
			. 'domain sockets, so a backend could neither be reached nor started.  '
			. 'This distribution is Unix-only (see PLATFORMS)',
		nul_dir => 'Class::Shared: a directory name may not contain a NUL byte',
	},
);

$config{class_name_re} = qr/\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/;

my $tmp = File::Temp->newdir('class-shared-path-XXXXXX', TMPDIR => 1, CLEANUP => 1);

my $hex64   = join('', map { sprintf '%02x', $_ } 1 .. $config{sha256_bytes});
my @pairs   = $hex64 =~ /(..)/g;
my $colon64 = join(':', @pairs);
my $pin     = $config{fingerprint_prefix} . ('ab' x $config{sha256_bytes});

# ---------------------------------------------------------------- helpers

# A path that is expected to die with exactly this text, once.
sub dies_with {
	my ($code, $expected, $name) = @_;

	throws_ok { $code->() } qr/\A\Q$expected\E\n\z/, $name;

	return;
}

sub dies_like {
	my ($code, $pattern, $name) = @_;

	throws_ok { $code->() } $pattern, $name;

	return;
}

sub write_bytes {
	my ($name, $content) = @_;
	my $path = File::Spec->catfile("$tmp", $name);

	open(my $fh, '>:raw', $path) or die "cannot write $path: $!";
	print {$fh} $content or die "cannot write $path: $!";
	close($fh) or die "cannot write $path: $!";

	return $path;
}

sub make_dir {
	my ($name, $mode) = @_;
	my $dir = File::Spec->catdir("$tmp", $name);

	mkdir($dir, $config{create_mode}) or die "cannot make $dir: $!";
	chmod($mode, $dir) or die "cannot chmod $dir: $!";

	return $dir;
}

sub read_mode {
	my ($path) = @_;
	my @stat = stat($path) or return;

	return $stat[2] & 07777;
}

# A unix socket that is listening, for the endpoint proof.
sub listening_socket {
	my ($path) = @_;

	require IO::Socket::UNIX;

	return IO::Socket::UNIX->new(Type => Socket::SOCK_STREAM(), Local => $path, Listen => 1);
}

# ---------------------------------------------------------------- Class::Shared

subtest 'Class::Shared::validate_class: every guard, both ways' => sub {
	my $err = $config{err};

	# Path 1: undef, by the first guard.
	dies_with(sub { Class::Shared::validate_class(undef) }, $err->{no_class},
		'undef: no class name given');

	# Path 2: the empty string, by the same guard.
	dies_with(sub { Class::Shared::validate_class('') }, $err->{no_class},
		'the empty string: the same guard');

	# Path 3: characters match, words match: the identity.
	for my $valid ('A', '_', 'Foo', 'Foo::Bar2::_x', 'My_Class2') {
		is(Class::Shared::validate_class($valid), $valid, "'$valid' is returned unchanged");
	}

	# Path 4: the character guard refuses; the word loop is never reached.
	for my $invalid ('2Foo', 'Foo-Bar', 'Foo Bar', 'Foo.Bar') {
		dies_with(sub { Class::Shared::validate_class($invalid) },
			sprintf($err->{bad_class}, $invalid), "'$invalid' is refused by the character guard");
	}

	# Path 5: the characters pass and the word loop refuses (an empty word).
	for my $empty_word ('Foo::', '::Foo', 'A:::B', '::') {
		dies_with(sub { Class::Shared::validate_class($empty_word) },
			sprintf($err->{bad_class}, $empty_word),
			"'$empty_word' has an empty word: the loop is what refuses it");
	}

	# The same guard for text that has no ASCII form.  The name of the test is
	# ASCII and the data is the data: TAP prints the name, and a wide character
	# in it warns.
	my @wide = (
		[ "M\x{fc}ller", 'a umlaut' ],
		[ "\x{1F600}x",  'an emoji' ],
		[ "\x{202E}x",   'a right-to-left override' ],
	);
	for my $case (@wide) {
		my ($value, $label) = @{$case};
		dies_with(sub { Class::Shared::validate_class($value) },
			sprintf($err->{bad_class}, $value), "$label is refused by the character guard");
	}

	# Invariant: accepting is the same as the documented pattern.
	my $agree = 0;
	my @alphabet = ('A', 'a', '1', '_', ':', '-');
	for my $length (1 .. 3) {
		for my $number (0 .. @alphabet**$length - 1) {
			my $value = '';
			my $n = $number;
			for (1 .. $length) {
				$value .= $alphabet[$n % @alphabet];
				$n = int($n / @alphabet);
			}
			my $accepted = defined eval { Class::Shared::validate_class($value); 1 } ? 1 : 0;
			my $expected = $value =~ $config{class_name_re} ? 1 : 0;
			$agree++ if $accepted == $expected;
		}
	}

	my $strings = 0;
	$strings += @alphabet**$_ for 1 .. 3;

	is($agree, $strings, 'accepting agrees with the documented pattern on every string of length 1 to 3');

	returns_ok(Class::Shared::validate_class('Foo'), { type => 'string' },
		'the output is a string, as the API specification says');
};

subtest 'Class::Shared::read_secret: every exit' => sub {
	my $err   = $config{err};
	my $max   = $config{max_secret};
	my $empty = write_bytes('secret-empty', '');
	my $space = write_bytes('secret-space', " \n\t\r\n");
	my $pad   = write_bytes('secret-pad', "secret \r\n");
	my $lead  = write_bytes('secret-lead', '  secret');
	my $nul   = write_bytes('secret-nul', "a\0b\n");
	my $full  = write_bytes('secret-full', 'a' x $max);
	my $over  = write_bytes('secret-over', 'b' x ($max + 1));

	# Path 1 and 2: no name.
	dies_with(sub { Class::Shared::read_secret(undef) }, $err->{no_token}, 'undef: no token file given');
	dies_with(sub { Class::Shared::read_secret('') }, $err->{no_token}, 'the empty path: the same guard');

	# Path 3: open fails.  A directory is a path that cannot be opened for
	# reading, so the failure is at open and not at read.
	my $dir = File::Spec->catdir("$tmp", 'secret-dir');
	mkdir($dir, $config{create_mode}) or die "cannot make $dir: $!";
	dies_like(sub { Class::Shared::read_secret($dir) }, qr/\AClass::Shared: cannot read /,
		'a directory: open fails, the read loop is never entered');

	dies_like(sub { Class::Shared::read_secret(File::Spec->catfile("$tmp", 'absent')) },
		qr/\AClass::Shared: cannot read /, 'a missing file: open fails');

	# Path 4: the first read returns end of file, the trim leaves nothing.
	dies_with(sub { Class::Shared::read_secret($empty) }, sprintf($err->{token_empty}, $empty),
		'0 bytes: empty after the trim');
	dies_with(sub { Class::Shared::read_secret($space) }, sprintf($err->{token_empty}, $space),
		'white space only: empty after the trim');

	# Path 5: a whole secret, with trailing white space trimmed.
	is(Class::Shared::read_secret($pad), 'secret', 'trailing white space is removed');
	is(Class::Shared::read_secret($lead), '  secret', 'leading white space and inner bytes are kept');
	is(Class::Shared::read_secret($nul), "a\0b", 'an embedded NUL is just a byte');

	# Path 6: exactly the limit.  The loop runs twice here: the first read
	# fills the buffer, the second is the one that sees end of file.
	my $at_limit = Class::Shared::read_secret($full);
	is(length($at_limit), $max, "the loop takes exactly $max bytes");

	# Path 7: one byte over the limit, which the loop reaches in one read.
	dies_with(sub { Class::Shared::read_secret($over) }, sprintf($err->{token_large}, $over, $max),
		'one byte over the limit dies with the limit in the message');

	# Path 8: an endless file.  The loop stops asking at the limit instead of
	# reading for ever.
	SKIP: {
		skip 'no /dev/zero here', 1 unless -c '/dev/zero';

		dies_with(sub { Class::Shared::read_secret('/dev/zero') },
			sprintf($err->{token_large}, '/dev/zero', $max),
			'/dev/zero: the loop is bounded by the limit');
	}

	returns_ok(Class::Shared::read_secret($pad), { type => 'string', min => 1 },
		'the output is a non-empty string, as the API specification says');
};

subtest 'Class::Shared::normalise_fingerprint: every guard, both ways' => sub {
	my $canonical = $config{fingerprint_prefix} . $hex64;
	my $err = $config{err};

	dies_with(sub { Class::Shared::normalise_fingerprint(undef) }, $err->{no_fingerprint},
		'undef: no fingerprint given');
	dies_with(sub { Class::Shared::normalise_fingerprint('') }, $err->{no_fingerprint},
		'the empty string: the same guard');

	dies_with(sub { Class::Shared::normalise_fingerprint('zz') },
		sprintf($err->{bad_fingerprint}, 'zz'), 'not hexadecimal: the pattern refuses it');
	dies_with(sub { Class::Shared::normalise_fingerprint($hex64 . '00') },
		sprintf($err->{bad_fingerprint}, $hex64 . '00'), '65 digits: one too many');
	dies_with(sub { Class::Shared::normalise_fingerprint('SHA256$' . $hex64) },
		sprintf($err->{bad_fingerprint}, 'SHA256$' . $hex64),
		'an upper case prefix is refused: the prefix itself is case sensitive');
	dies_with(sub { Class::Shared::normalise_fingerprint(join(':', @pairs, 'ab')) },
		sprintf($err->{bad_fingerprint}, join(':', @pairs, 'ab')), '33 pairs: one too many');

	is(Class::Shared::normalise_fingerprint($hex64), $canonical, '64 plain digits: the prefix is added, lower cased');
	is(Class::Shared::normalise_fingerprint(uc $hex64), $canonical, 'upper case digits are lower cased');
	is(Class::Shared::normalise_fingerprint(uc $colon64), $canonical, 'the colon-separated form is accepted');
	is(Class::Shared::normalise_fingerprint($config{fingerprint_prefix} . $colon64), $canonical,
		'the prefix is accepted and not doubled');
	is(Class::Shared::normalise_fingerprint($pin), $pin, 'normalising an answer again changes nothing');

	returns_ok(Class::Shared::normalise_fingerprint($hex64), { type => 'string', min => 1 },
		'the output is a string, as the API specification says');
};

subtest 'Class::Shared::client_tls_options: the pin branch and the CA branch' => sub {
	my %ca = Class::Shared::client_tls_options(cert => 'c.pem', key => 'k.pem', ca => 'ca.pem');

	is($ca{SSL_ca_file}, 'ca.pem', 'no fingerprint: the CA branch sets SSL_ca_file');
	ok(!exists $ca{SSL_fingerprint}, 'no fingerprint: no pin');
	ok(!exists $ca{SSL_force_fingerprint}, 'no fingerprint: nothing to force');
	ok(!exists $ca{SSL_verifycn_scheme}, 'no fingerprint: the name check is left alone');

	my %pinned = Class::Shared::client_tls_options(
		cert => 'c.pem', key => 'k.pem', ca => 'ca.pem', fingerprint => $pin);

	is($pinned{SSL_fingerprint}, $pin, 'a fingerprint: the pin branch sets SSL_fingerprint');
	is($pinned{SSL_force_fingerprint}, 1, 'a fingerprint: the digest is the only thing that can accept the peer');
	is($pinned{SSL_verifycn_scheme}, 'none', 'a fingerprint: the name is not checked, the pin stands in for it');
	ok(!exists $pinned{SSL_ca_file}, 'a fingerprint wins over a CA: the branches are exclusive');

	for my $option (\%ca, \%pinned) {
		is($option->{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(),
			'verification is on in both branches');
		is($option->{SSL_version}, $Class::Shared::TLS_VERSIONS,
			'the TLS versions are the same in both branches');
	}

	# The branch is chosen by definedness, not by truth: the empty string is a
	# fingerprint that is present (and is refused later by the pin itself).
	my %empty = Class::Shared::client_tls_options(cert => 'c', key => 'k', fingerprint => '');
	ok(exists $empty{SSL_fingerprint}, 'the empty string takes the pin branch: defined, not true, is the test');
	my %undef_pin = Class::Shared::client_tls_options(cert => 'c', key => 'k', ca => 'ca.pem', fingerprint => undef);
	ok(!exists $undef_pin{SSL_fingerprint}, 'undef takes the CA branch');
};

subtest 'Class::Shared::dir_of and poll_pause' => sub {
	is(Class::Shared::dir_of('x.sock'), '.', 'no directory part: .');
	is(Class::Shared::dir_of('/x.sock'), '/', 'the root: /');
	is(Class::Shared::dir_of('/a/b/c'), '/a/b', 'a directory part: the part before the last slash');
	is(Class::Shared::dir_of('a/b/'), 'a', 'a trailing slash is not part of the name');
	is(Class::Shared::dir_of('//'), '/', 'slashes only: never the empty string');

	# The empty name has no directory part, and dirname says "." rather than "".
	is(Class::Shared::dir_of(''), '.', 'the empty string still gives a directory');

	# poll_pause always returns nothing and always pauses.
	my $started = Time::HiRes::time();
	my @result = Class::Shared::poll_pause();
	my $elapsed = Time::HiRes::time() - $started;
	is(scalar @result, 0, 'poll_pause returns nothing in list context');
	cmp_ok($elapsed, '>=', $config{poll_interval},
		'poll_pause waited for the poll interval, not for nothing');

	is(Class::Shared::poll_pause(), undef, 'poll_pause returns nothing in scalar context');
};

subtest 'Class::Shared::default_dir: five ranked premises' => sub {
	my $err = $config{err};
	my $xdg = File::Spec->catdir("$tmp", 'rank-xdg');
	mkdir($xdg, $config{create_mode}) or die "cannot make $xdg: $!";

	# Rank 1: the argument is true, so nothing else is looked at.
	is(Class::Shared::default_dir(dir => '/rank/one'), '/rank/one', 'rank 1: dir given wins');

	# Rank 2: the argument is empty, so the environment variable decides.
	{
		local $ENV{CLASS_SHARED_DIR} = '/rank/two';
		local $ENV{XDG_RUNTIME_DIR} = $xdg;

		is(Class::Shared::default_dir(dir => ''), '/rank/two',
			'rank 2: an empty dir falls through to CLASS_SHARED_DIR');
		is(Class::Shared::default_dir(dir => undef), '/rank/two',
			'rank 2: undef is the same as not given');
		is(Class::Shared::default_dir(), '/rank/two', 'rank 2: no argument at all');
	}

	# Rank 3: the environment variable is empty and XDG names a directory.
	{
		local $ENV{CLASS_SHARED_DIR} = '';
		local $ENV{XDG_RUNTIME_DIR} = $xdg;

		is(Class::Shared::default_dir(), File::Spec->catdir($xdg, 'class-shared'),
			'rank 3: an existing XDG_RUNTIME_DIR is used');
	}

	# Rank 3 false: XDG names something that is not a directory.
	{
		local $ENV{CLASS_SHARED_DIR} = '';
		local $ENV{XDG_RUNTIME_DIR} = File::Spec->catdir("$tmp", 'rank-absent');

		my $got = Class::Shared::default_dir();
		unlike($got, qr/rank-absent/, 'rank 3 is false for a directory that does not exist');

		# Rank 4 or 5, whichever this machine has.
		my $run_user = "/run/user/$>";
		my $expected = -d $run_user
			? File::Spec->catdir($run_user, 'class-shared')
			: File::Spec->catdir(File::Spec->tmpdir, "class-shared-$>");
		is($got, $expected, -d $run_user ? 'rank 4: /run/user/UID exists' : 'rank 5: the system temporary directory');
	}

	# The NUL guard: the name would end early in the system call.
	dies_with(sub { Class::Shared::default_dir(dir => "$tmp/a\0b") }, $err->{nul_dir},
		'a NUL byte in the argument is refused');
	dies_with(sub { local $ENV{CLASS_SHARED_DIR} = "/bad\0dir"; Class::Shared::default_dir() },
		$err->{nul_dir}, 'a NUL byte from the environment is refused the same way');

	returns_ok(Class::Shared::default_dir(dir => '/x'), { type => 'string', min => 1 },
		'the output is a non-empty string, as the API specification says');
};

subtest 'Class::Shared::_has_unix_sockets and _require_unix_sockets' => sub {
	my $err = $config{err};

	# Path 1: the cache is set, so the probe is not run again.
	{
		local $Class::Shared::UNIX_SOCKETS = 7;
		is(Class::Shared::_has_unix_sockets(), 7, 'a cached answer is returned as it stands');
	}

	# Path 2: the cache is unknown, so the probe runs and caches its answer.
	{
		local $Class::Shared::UNIX_SOCKETS = undef;
		my $answer = Class::Shared::_has_unix_sockets();
		ok($answer == 0 || $answer == 1, 'an uncached probe gives a boolean');
		is($Class::Shared::UNIX_SOCKETS, $answer, 'and caches it');
	}

	# Path 3: the premise is given and true: no die, no probe.
	ok(!defined Class::Shared::_require_unix_sockets('a socket', 1),
		'a true premise returns nothing');

	# Path 4: the premise is given and false: it dies, naming the thing asked for.
	dies_with(sub { Class::Shared::_require_unix_sockets('a socket', 0) },
		sprintf($err->{unix_missing}, 'a socket'), 'a false premise dies with the name in the message');

	# Path 5: the premise is not given, so it is asked for.
	{
		local $Class::Shared::UNIX_SOCKETS = 1;
		ok(!defined Class::Shared::_require_unix_sockets('a socket'),
			'an absent premise is taken from the cache: true is silent');
	}

	{
		local $Class::Shared::UNIX_SOCKETS = 0;
		dies_with(sub { Class::Shared::_require_unix_sockets('a directory') },
			sprintf($err->{unix_missing}, 'a directory'), 'an absent premise is taken from the cache: false dies');
	}
};

subtest 'Class::Shared::ensure_dir: every guard and every mkdir outcome' => sub {
	my $err = $config{err};

	# Path 1: no directory name.
	dies_with(sub { Class::Shared::ensure_dir(undef) }, $err->{no_dir}, 'undef: no directory given');
	dies_with(sub { Class::Shared::ensure_dir('') }, $err->{no_dir}, 'the empty string: the same guard');

	# Path 2: no unix sockets.
	{
		local $Class::Shared::UNIX_SOCKETS = 0;
		dies_with(sub { Class::Shared::ensure_dir("$tmp/no-sockets") },
			sprintf($err->{unix_missing}, 'a backend directory'), 'no unix sockets: refused before mkdir');
		ok(!-e "$tmp/no-sockets", 'and nothing was created first');
	}

	SKIP: {
		skip 'no unix sockets here', 8 unless Class::Shared::_has_unix_sockets();

		# Path 3: the directory does not exist and mkdir succeeds.
		my $fresh = File::Spec->catdir("$tmp", 'ensure-fresh');
		my @fresh = Class::Shared::ensure_dir($fresh);
		is($fresh[0], 1, 'MISSING: mkdir succeeds, so the answer is true');
		is($fresh[1], undef, 'and carries no reason');
		ok(-d $fresh, 'the directory exists');
		is(read_mode($fresh), $config{create_mode}, 'made 0700');

		# Path 4: it already exists and is safe.
		my @again = Class::Shared::ensure_dir($fresh);
		is($again[0], 1, 'PRESENT and safe: true, without touching it');

		# Path 5: it exists and group or others can write to it.
		my $unsafe = make_dir('ensure-unsafe', $config{create_mode} | $config{group_write_bit});
		my ($ok, $why) = Class::Shared::ensure_dir($unsafe);
		is($ok, 0, 'PRESENT and unsafe: false');
		is($why, sprintf($err->{dir_unsafe}, $unsafe), 'with the documented reason');

		# Path 6: mkdir fails and the directory is still not there.
		my $orphan = File::Spec->catdir("$tmp", 'ensure-absent', 'child');
		my ($none, $none_why) = Class::Shared::ensure_dir($orphan);
		is($none, 0, 'mkdir fails with a missing parent: false');
		like($none_why, qr/\Acannot create /, 'the reason says what failed');
		ok(!-e $orphan, 'and nothing partial was left behind');

		# Path 7: the name is taken by a file, so mkdir fails and it is no directory.
		my $file = write_bytes('ensure-file', 'not a directory');
		my ($not_dir) = Class::Shared::ensure_dir($file);
		is($not_dir, 0, 'a plain file: false');

		# The one path not taken here is the race in
		# "return (0, ...) unless -d $dir" after a failed mkdir: another process
		# must create the directory between the -d test and the mkdir.  Covering
		# it needs a second process winning a race, which no test can force
		# deterministically; the line is exercised by construction, not by test.
	}
};

subtest 'Class::Shared::_check_dir: every guard, in order' => sub {
	my $err = $config{err};

	my ($missing, $why_missing) = Class::Shared::_check_dir(File::Spec->catdir("$tmp", 'dir-absent'));
	is($missing, 0, 'stat fails: false');
	like($why_missing, qr/\Acannot stat /, 'the reason says stat failed');
	like($why_missing, qr/: /, 'and carries the system message');

	my $unsafe = make_dir('check-unsafe', $config{create_mode} | $config{other_write_bit});
	my ($ok, $why) = Class::Shared::_check_dir($unsafe);
	is($ok, 0, 'other-writable: false');
	is($why, sprintf($err->{dir_unsafe}, $unsafe), 'with the documented reason');

	my $safe = make_dir('check-safe', $config{create_mode});
	is_deeply([ Class::Shared::_check_dir($safe) ], [ 1, undef ], 'safe: (1, undef)');

	# The owner guard (uid != $>) needs a directory owned by somebody else,
	# which needs a second account; it is not reachable from an unprivileged
	# test, so the guard is asserted for its place in the order by reading it
	# as documentation rather than by forcing it here.
};

subtest 'Class::Shared::_check_endpoint: every guard, in order' => sub {
	my $err = $config{err};

	# Path 1: the directory is unsafe, so nothing else is looked at.
	my $unsafe_dir = make_dir('endpoint-unsafe', $config{create_mode} | $config{group_write_bit});
	my $inside = File::Spec->catfile($unsafe_dir, 'x.sock');
	my ($bad_dir, $why_dir) = Class::Shared::_check_endpoint($inside);
	is($bad_dir, 0, 'an unsafe directory: false before the socket is even looked at');
	is($why_dir, sprintf($err->{dir_unsafe}, $unsafe_dir), 'with the directory reason');

	# Path 2: the directory is safe and the path does not exist.
	my $absent = File::Spec->catfile("$tmp", 'endpoint-absent.sock');
	my ($missing, $why_missing) = Class::Shared::_check_endpoint($absent);
	is($missing, 0, 'a missing path: false');
	like($why_missing, qr/\Acannot stat /, 'the reason says stat failed');

	# Path 3: the path is not a socket.
	my $file = write_bytes('endpoint-file', 'x');
	my ($not_socket, $why_not_socket) = Class::Shared::_check_endpoint($file);
	is($not_socket, 0, 'a plain file: false');
	is($why_not_socket, "$file is not a socket", 'the reason says it is not a socket');

	SKIP: {
		skip 'no unix sockets here', 2 unless Class::Shared::_has_unix_sockets();

		# Path 4: a socket in a safe directory, owned by this user.
		my $path = File::Spec->catfile("$tmp", 'endpoint.sock');
		my $listener = listening_socket($path);
		if (!$listener) {
			skip "cannot listen on $path: $!", 2;
		}
		is_deeply([ Class::Shared::_check_endpoint($path) ], [ 1, undef ],
			'a socket of ours in a safe directory: (1, undef)');
		close($listener);

		# The owner guard (a socket owned by another user) needs a second
		# account, so it is not reachable from here; see _check_dir.
		skip 'the foreign-owner socket needs a second account', 1;
	}
};

subtest 'Class::Shared::socket_path and check_socket_path: every guard' => sub {
	my $err = $config{err};
	my $max = $config{max_socket_path};

	{
		local $Class::Shared::UNIX_SOCKETS = 0;
		dies_with(sub { Class::Shared::socket_path('/tmp') },
			sprintf($err->{unix_missing}, 'a unix socket'), 'socket_path: no unix sockets dies');
	}

	SKIP: {
		skip 'no unix sockets here', 4 unless Class::Shared::_has_unix_sockets();

		is(Class::Shared::socket_path('/tmp'), File::Spec->catfile('/tmp', $config{socket_name}),
			'socket_path: the name is fixed and the directory is used as given');

		# The built path is passed through the length guard, so a long
		# directory is refused here rather than by the kernel.
		my $long_dir = '/' . ('d' x $max);
		my $expected = File::Spec->catfile($long_dir, $config{socket_name});
		dies_with(sub { Class::Shared::socket_path($long_dir) },
			sprintf($err->{socket_long}, $expected, length $expected, $max),
			'socket_path: a directory that makes the path too long dies in the length guard');
	}

	dies_with(sub { Class::Shared::check_socket_path(undef) }, $err->{no_socket}, 'undef: no socket path given');
	dies_with(sub { Class::Shared::check_socket_path('') }, $err->{no_socket}, 'the empty string: the same guard');

	my $at_limit = '/' . ('p' x ($max - 1));
	is(Class::Shared::check_socket_path($at_limit), $at_limit, "MAXPATH ($max) is accepted");

	my $over = '/' . ('p' x $max);
	dies_with(sub { Class::Shared::check_socket_path($over) },
		sprintf($err->{socket_long}, $over, $max + 1, $max), 'MAXPATH + 1 dies with both numbers in the message');
};

# ---------------------------------------------------------------- Protocol

sub socket_pair {
	my ($reader, $writer);

	socketpair($reader, $writer, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0)
		or die "cannot make a socketpair: $!";

	return ($reader, $writer);
}

# A handle that says how much decrypted data it is holding, as a TLS socket
# can.  The handle itself is the blessed glob, so sysread still works on it.
{
	package FakeTLS;

	our $holding = 0;

	sub pending { $holding }

	$INC{'FakeTLS.pm'} = __FILE__;
}

# A plain handle: the want_* methods exist and answer no.
{
	package FakeHandle;

	sub want_read  { 0 }
	sub want_write { 0 }

	$INC{'FakeHandle.pm'} = __FILE__;
}

# A TLS handle: it says which direction it is waiting on.
{
	package FakeTLSHandle;

	sub want_read  { $_[0]->{want_read} }
	sub want_write { $_[0]->{want_write} }

	$INC{'FakeTLSHandle.pm'} = __FILE__;
}

sub tls_handle {
	my ($fh, $holding) = @_;

	$FakeTLS::holding = $holding;

	return bless(\*{$fh}, 'FakeTLS');
}

sub frame_bytes {
	my ($body, $secret) = @_;

	return defined $secret
		? pack('N', $config{digest_size} + length $body)
			. Digest::SHA::hmac_sha256($body, $secret) . $body
		: pack('N', length $body) . $body;
}

subtest 'Class::Shared::Protocol::encode_frame: every exit' => sub {
	my $message = { op => 'ping' };
	my $frozen  = Storable::nfreeze($message);

	# Path 1: no secret.
	my ($plain, $plain_error) = Class::Shared::Protocol::encode_frame($message);
	is($plain_error, undef, 'no secret: no error');
	is(unpack('N', substr($plain, 0, 4)), length $frozen, 'no secret: the header is #freeze');
	is(substr($plain, 4), $frozen, 'no secret: the body is freeze(message)');

	# Path 2: a secret.
	my ($signed, $signed_error) = Class::Shared::Protocol::encode_frame($message, 'secret');
	is($signed_error, undef, 'a secret: no error');
	is(unpack('N', substr($signed, 0, 4)), $config{digest_size} + length $frozen,
		'a secret: the header counts the digest');
	is(substr($signed, 4, $config{digest_size}), Digest::SHA::hmac_sha256($frozen, 'secret'),
		'a secret: the digest comes first');
	is(substr($signed, 4 + $config{digest_size}), $frozen, 'a secret: the body follows the digest');

	# Path 3: freeze fails.  A code reference cannot be serialised.
	my ($bad, $bad_error) = Class::Shared::Protocol::encode_frame(sub { 1 });
	is($bad, undef, 'a code reference: no bytes');
	like($bad_error, qr/\Acannot serialise message: /, 'a code reference: the failure is reported');

	# Path 4: the message is too large.  The limit is a package variable, so
	# the boundary is proved without allocating 64 MiB.
	{
		local $Class::Shared::Protocol::MAX_FRAME = length($frozen) - 1;
		my ($too_big, $too_big_error) = Class::Shared::Protocol::encode_frame($message);
		is($too_big, undef, 'one byte over the limit: no bytes');
		is($too_big_error, 'message is too large (' . length($frozen) . ' bytes, limit is '
			. (length($frozen) - 1) . ')', 'one byte over the limit: the message names both numbers');
	}

	{
		local $Class::Shared::Protocol::MAX_FRAME = length $frozen;
		my ($exactly) = Class::Shared::Protocol::encode_frame($message);
		ok(defined $exactly, 'exactly at the limit: accepted, so the test is > and not >=');
	}

	# Path 5: the depth guard, which runs only where Storable cannot.
	{
		local $Class::Shared::Protocol::CHECK_DEPTH = 1;
		local $Class::Shared::Protocol::MAX_DEPTH = 3;

		my $deep = 'x';
		$deep = [$deep] for 1 .. 5;

		my ($too_deep, $too_deep_error) = Class::Shared::Protocol::encode_frame($deep);
		is($too_deep, undef, 'too deep: no bytes');
		is($too_deep_error, 'cannot serialise message: it is nested more than 3 deep',
			'too deep: the message names the limit');

		# The same data is accepted when the guard is off, which is the case on
		# a Storable that has its own limit.
		local $Class::Shared::Protocol::CHECK_DEPTH = 0;
		my ($allowed) = Class::Shared::Protocol::encode_frame($deep);
		ok(defined $allowed, 'the guard off: the same data is serialised');
	}

	returns_ok($plain, { type => 'string', min => 4 }, 'the output is a string, as the API specification says');
};

subtest 'Class::Shared::Protocol::take_payload: every exit' => sub {
	my $image = Storable::nfreeze({ op => 'ping' });

	my ($message, $error) = Class::Shared::Protocol::take_payload($image);
	is_deeply($message, { op => 'ping' }, 'a whole image: the message comes back');
	is($error, undef, 'a whole image: no error');

	# The image is not a Storable image at all: thaw dies.
	my ($garbage, $garbage_error) = Class::Shared::Protocol::take_payload('not an image');
	is($garbage, undef, 'garbage: no message');
	like($garbage_error, qr/\Acannot deserialise message: /, 'garbage: the thaw error is reported');

	# An image that is cut short: thaw returns nothing, without dying.  Real
	# Storable never does that -- it dies on every image it cannot read -- so
	# the branch is reached by mocking thaw, which is the only way to force it.
	my ($nothing, $nothing_error);
	mock 'Storable::thaw' => sub { undef };
	($nothing, $nothing_error) = Class::Shared::Protocol::take_payload($image);
	restore_all();

	is($nothing, undef, 'thaw returns nothing: no message');
	is($nothing_error, 'cannot deserialise message: the image is incomplete',
		'thaw returns nothing: reported as incomplete rather than as success');

	# $@ belongs to the caller.
	{
		local $@ = 'sentinel';
		Class::Shared::Protocol::take_payload($image);
		is($@, 'sentinel', 'a successful thaw does not overwrite $@');
	}
	{
		local $@ = 'sentinel';
		Class::Shared::Protocol::take_payload('not an image');
		is($@, 'sentinel', 'a failed thaw does not overwrite $@ either');
	}
};

subtest 'Class::Shared::Protocol::write_all: every exit' => sub {
	my ($reader, $writer) = socket_pair();

	my ($ok, $error) = Class::Shared::Protocol::write_all($writer, 'hello');
	is($ok, 1, 'one whole write: true');
	is($error, undef, 'one whole write: no error');

	my $got = '';
	my $read = sysread($reader, $got, 5);
	is($read, 5, 'the bytes arrived');
	is($got, 'hello', 'and they are the bytes that were written');

	# The loop's second iteration: a non-blocking socket that cannot take the
	# whole buffer at once.  The first syswrite takes part of it, the next
	# reports that it would block, and that is the error exit.
	{
		my ($big_reader, $big_writer) = socket_pair();
		my $flags = fcntl($big_writer, Fcntl::F_GETFL(), 0);
		fcntl($big_writer, Fcntl::F_SETFL(), $flags | Fcntl::O_NONBLOCK());

		my ($partial, $partial_error) = Class::Shared::Protocol::write_all($big_writer, 'x' x (4 * 1024 * 1024));
		is($partial, 0, 'a buffer that fills: the call reports failure');
		like($partial_error, qr/\Awrite failed: /, 'a buffer that fills: with the system message');
		close($big_reader);
		close($big_writer);
	}

	# A read end that has gone away: the write fails, and SIGPIPE does not kill
	# the process (that is what the local $SIG{PIPE} in write_all is for).
	{
		my ($gone_reader, $gone_writer) = socket_pair();
		close($gone_reader);
		my ($closed, $closed_error) = Class::Shared::Protocol::write_all($gone_writer, 'x' x 100);
		is($closed, 0, 'a closed peer: the call reports failure');
		like($closed_error, qr/\Awrite failed: /, 'a closed peer: with the system message');
		close($gone_writer);
	}

	close($reader);
	close($writer);

	# The EINTR retry and the zero-length syswrite are the two edges left.  A
	# signal can only be delivered while the process is blocked in syswrite,
	# which a single-process test cannot arrange deterministically; and POSIX
	# write() returns 0 only for a zero-byte request, which this loop never
	# makes (it stops when $offset == $length).
};

subtest 'Class::Shared::Protocol::_read_exact: every exit' => sub {
	# Path 1: everything is there in one read.
	{
		my ($reader, $writer) = socket_pair();
		syswrite($writer, 'abcd');
		my ($buffer, $error) = Class::Shared::Protocol::_read_exact($reader, 4, 1);
		is($buffer, 'abcd', 'four bytes in one read');
		is($error, undef, 'no error');
		close($reader);
		close($writer);
	}

	# Path 2: the peer closes before enough has arrived.
	{
		my ($reader, $writer) = socket_pair();
		syswrite($writer, 'ab');
		close($writer);
		my ($buffer, $error) = Class::Shared::Protocol::_read_exact($reader, 4, 1);
		is($buffer, undef, 'a short read: no buffer');
		is($error, 'connection closed by peer', 'a short read: the documented reason');
		close($reader);
	}

	# Path 3: the time runs out before anything arrives.
	{
		my ($reader, $writer) = socket_pair();
		my $started = Time::HiRes::time();
		my ($buffer, $error) = Class::Shared::Protocol::_read_exact($reader, 4, 0.05);
		my $elapsed = Time::HiRes::time() - $started;
		is($buffer, undef, 'no data in time: no buffer');
		is($error, 'timed out waiting for a reply', 'no data in time: the documented reason');
		cmp_ok($elapsed, '>=', 0.04, 'and it waited for the timeout');
		close($reader);
		close($writer);
	}

	# Path 4: the pending branch is taken before any waiting.  The socket has
	# nothing to give and would block, so a read that went to select first
	# would wait out the timeout; the branch reads at once instead, and the
	# answer is the read error.
	{
		my ($reader, $writer) = socket_pair();
		my $flags = fcntl($reader, Fcntl::F_GETFL(), 0);
		fcntl($reader, Fcntl::F_SETFL(), $flags | Fcntl::O_NONBLOCK());

		my $handle = tls_handle($reader, 1);
		my $started = Time::HiRes::time();
		my ($buffer, $error) = Class::Shared::Protocol::_read_exact($handle, 4, 1);
		is($buffer, undef, 'pending and nothing to give: no buffer');
		like($error, qr/\Aread failed: /,
			'pending: the read is tried first, so the answer is the read error');
		cmp_ok(Time::HiRes::time() - $started, '<', 1, 'and the timeout was never waited for');
		$FakeTLS::holding = 0;
		close($reader);
		close($writer);
	}

	# Path 5: a handle that has the method but is holding nothing falls
	# through to the ordinary wait, and the bytes are read there.
	{
		my ($reader, $writer) = socket_pair();
		syswrite($writer, 'wxyz');
		my $handle = tls_handle($reader, 0);
		my ($buffer, $error) = Class::Shared::Protocol::_read_exact($handle, 4, 1);
		is($buffer, 'wxyz', 'nothing pending: the ordinary read still gets the bytes');
		is($error, undef, 'and no error');
		close($reader);
		close($writer);
	}
};

subtest 'Class::Shared::Protocol::_wait_readable: both answers' => sub {
	{
		my ($reader, $writer) = socket_pair();
		syswrite($writer, 'x');
		is(Class::Shared::Protocol::_wait_readable($reader, 1), 1, 'data ready: 1');
		close($reader);
		close($writer);
	}

	{
		my ($reader, $writer) = socket_pair();
		my $started = Time::HiRes::time();
		is(Class::Shared::Protocol::_wait_readable($reader, 0.05), 0, 'nothing to read: 0');
		cmp_ok(Time::HiRes::time() - $started, '>=', 0.04, 'after waiting for the timeout');
		close($reader);
		close($writer);
	}
};

subtest 'Class::Shared::Protocol::read_frame: every exit' => sub {
	my $message = { op => 'ping' };
	my $body    = Storable::nfreeze($message);

	# Path 1: the header itself is short.
	{
		my ($reader, $writer) = socket_pair();
		syswrite($writer, 'ab');
		close($writer);
		my ($frame, $error) = Class::Shared::Protocol::read_frame($reader, 1);
		is($frame, undef, 'a short header: no frame');
		is($error, 'connection closed by peer', 'a short header: the read error is passed on');
		close($reader);
	}

	# Path 2: the length is over the limit.
	{
		local $Class::Shared::Protocol::MAX_FRAME = 16;
		my ($reader, $writer) = socket_pair();
		syswrite($writer, pack('N', 17));
		my ($frame, $error) = Class::Shared::Protocol::read_frame($reader, 1);
		is($frame, undef, 'a frame over the limit: no frame');
		is($error, 'frame of 17 bytes exceeds the limit of 16', 'a frame over the limit: both numbers');
		close($reader);
		close($writer);
	}

	# Path 3: the header is fine and the body is short.
	{
		my ($reader, $writer) = socket_pair();
		syswrite($writer, pack('N', 100) . 'short');
		close($writer);
		my ($frame, $error) = Class::Shared::Protocol::read_frame($reader, 1);
		is($frame, undef, 'a short body: no frame');
		is($error, 'connection closed by peer', 'a short body: the read error is passed on');
		close($reader);
	}

	# Path 4: a whole frame, no secret.
	{
		my ($reader, $writer) = socket_pair();
		syswrite($writer, frame_bytes($body));
		my ($frame, $error) = Class::Shared::Protocol::read_frame($reader, 1);
		is_deeply($frame, $message, 'a whole frame: the message comes back');
		is($error, undef, 'a whole frame: no error');
		close($reader);
		close($writer);
	}

	# Path 5: no data at all before the timeout.
	{
		my ($reader, $writer) = socket_pair();
		my ($frame, $error) = Class::Shared::Protocol::read_frame($reader, 0.05);
		is($frame, undef, 'nothing arrives: no frame');
		is($error, 'timed out waiting for a reply', 'nothing arrives: the timeout is reported');
		close($reader);
		close($writer);
	}

	# Path 6: a whole frame with a secret, which moves the limit by the digest.
	{
		my ($reader, $writer) = socket_pair();
		syswrite($writer, frame_bytes($body, 'secret'));
		my ($frame) = Class::Shared::Protocol::read_frame($reader, 1, 'secret');
		is_deeply($frame, $message, 'a signed frame: the message comes back');
		close($reader);
		close($writer);

		local $Class::Shared::Protocol::MAX_FRAME = 16;
		my $room = 16 + $config{digest_size};
		my ($over_reader, $over_writer) = socket_pair();
		syswrite($over_writer, pack('N', $room + 1));
		my ($none, $over_error) = Class::Shared::Protocol::read_frame($over_reader, 1, 'secret');
		is($none, undef, 'with a secret the room is larger by the digest, and this is over it');
		is($over_error, "frame of " . ($room + 1) . " bytes exceeds the limit of $room",
			'and the limit in the message counts the digest');
		close($over_reader);
		close($over_writer);
	}
};

subtest 'Class::Shared::Protocol::take_frame: every exit' => sub {
	my $message = { op => 'ping' };
	my $body    = Storable::nfreeze($message);

	# Path 1: fewer than four bytes: more are needed, not an error.
	{
		my $buffer = 'abc';
		is_deeply([ Class::Shared::Protocol::take_frame(\$buffer) ], [ 0, undef, undef ],
			'a short header: take nothing, no error');
		is($buffer, 'abc', 'and the buffer is untouched');
	}

	# Path 2: the length is over the limit: the stream is unusable.
	{
		local $Class::Shared::Protocol::MAX_FRAME = 16;
		my $buffer = pack('N', 17);
		my ($status, $taken, $error) = Class::Shared::Protocol::take_frame(\$buffer);
		is($status, -1, 'over the limit: -1');
		is($taken, undef, 'over the limit: no message');
		is($error, 'frame of 17 bytes exceeds the limit of 16', 'over the limit: both numbers');
	}

	# Path 3: the header is whole and the body is not: more are needed.
	{
		my $buffer = pack('N', 100) . 'short';
		is_deeply([ Class::Shared::Protocol::take_frame(\$buffer) ], [ 0, undef, undef ],
			'a short body: take nothing, no error');
	}

	# Path 4: a whole frame is taken out and the buffer keeps what follows.
	{
		my $buffer = frame_bytes($body) . 'tail';
		my ($status, $taken, $error) = Class::Shared::Protocol::take_frame(\$buffer);
		is($status, 1, 'a whole frame: 1');
		is_deeply($taken, $message, 'a whole frame: the message');
		is($error, undef, 'a whole frame: no error');
		is($buffer, 'tail', 'the frame is removed and the rest is kept');
	}

	# Path 5: the body cannot be decoded.
	{
		my $buffer = pack('N', 5) . 'nope!';
		my ($status, $taken, $error) = Class::Shared::Protocol::take_frame(\$buffer);
		is($status, -1, 'a body that cannot be thawed: -1');
		is($taken, undef, 'a body that cannot be thawed: no message');
		like($error, qr/\Acannot deserialise message: /, 'a body that cannot be thawed: the reason');
	}

	# Path 6: with a secret, a body shorter than the digest.
	{
		my $buffer = pack('N', 4) . 'abcd';
		my ($status, $taken, $error) = Class::Shared::Protocol::take_frame(\$buffer, 'secret');
		is($status, -1, 'a body shorter than the digest: -1');
		is($error, 'frame is too short to be authenticated', 'a body shorter than the digest: the reason');
	}

	# Path 7: with a secret, a digest that does not match.
	{
		my $buffer = frame_bytes($body, 'secret');
		substr($buffer, 4, 1) = chr(ord(substr($buffer, 4, 1)) ^ 1);
		my ($status, $taken, $error) = Class::Shared::Protocol::take_frame(\$buffer, 'secret');
		is($status, -1, 'a bad digest: -1');
		is($taken, undef, 'a bad digest: no message');
		is($error, 'frame failed authentication', 'a bad digest: the reason');
	}

	# Path 8: with a secret, a good digest.
	{
		my $buffer = frame_bytes($body, 'secret');
		my ($status, $taken, $error) = Class::Shared::Protocol::take_frame(\$buffer, 'secret');
		is($status, 1, 'a good digest: 1');
		is_deeply($taken, $message, 'a good digest: the message');
		is($error, undef, 'a good digest: no error');
	}

	# Path 9: the depth check refuses the body before it is thawed.
	{
		my $buffer = frame_bytes($body);
		my $check = sub { 0 };
		my ($status, $taken, $error) = Class::Shared::Protocol::take_frame(\$buffer, undef, $check);
		is($status, -1, 'the check says no: -1');
		is($error, 'cannot deserialise message: reading it would crash the process',
			'the check says no: the documented reason');
	}

	# Path 10: the check says yes, so the body is thawed.
	{
		my $buffer = frame_bytes($body);
		my $check = sub { 1 };
		my ($status, $taken) = Class::Shared::Protocol::take_frame(\$buffer, undef, $check);
		is($status, 1, 'the check says yes: 1');
		is_deeply($taken, $message, 'the check says yes: the message');
	}
};

subtest 'Class::Shared::Protocol::_too_deep: every exit' => sub {
	{
		local $Class::Shared::Protocol::MAX_DEPTH = 3;

		is(Class::Shared::Protocol::_too_deep('scalar'), 0, 'a scalar is not deep');
		is(Class::Shared::Protocol::_too_deep([]), 0, 'an empty array is depth 1');
		is(Class::Shared::Protocol::_too_deep([ 1, [ 2, [ 3 ] ] ]), 0, 'depth 3 is not more than 3');
		is(Class::Shared::Protocol::_too_deep([ 1, [ 2, [ 3, [ 4 ] ] ] ]), 1, 'depth 4 is more than 3');
		is(Class::Shared::Protocol::_too_deep({ a => { b => { c => 1 } } }), 0, 'hashes count the same way');
		is(Class::Shared::Protocol::_too_deep({ a => { b => { c => { d => 1 } } } }), 1,
			'a hash 4 deep is more than 3');
		my $scalar = 1;
		is(Class::Shared::Protocol::_too_deep(\$scalar), 0, 'a scalar reference is followed');
	}

	# A cycle would loop for ever without the seen set.
	{
		local $Class::Shared::Protocol::MAX_DEPTH = 5;
		my $a = [];
		my $b = [$a];
		push @{$a}, $b;
		is(Class::Shared::Protocol::_too_deep($a), 0, 'a cycle ends');
	}

	# The default limit is the module's; 10,000 levels of a plain array is more
	# than this test should build, so the boundary is proved at a small one.
};

subtest 'Class::Shared::Protocol::_digest and _authentic: every exit' => sub {
	my $body   = 'the body';
	my $secret = 'the secret';

	is(Class::Shared::Protocol::_digest($secret, $body),
		Digest::SHA::hmac_sha256($body, $secret), '_digest is HMAC-SHA-256 of the body');

	my $digest = Class::Shared::Protocol::_digest($secret, $body);
	is(Class::Shared::Protocol::_authentic($secret, $body, $digest), 1, 'the right digest: 1');

	my $one_off = $digest;
	substr($one_off, -1, 1) = chr(ord(substr($one_off, -1, 1)) ^ 1);
	is(Class::Shared::Protocol::_authentic($secret, $body, $one_off), 0,
		'a digest that differs in one bit: 0');

	is(Class::Shared::Protocol::_authentic($secret, $body, substr($digest, 0, 8)), 0,
		'a digest of the wrong length: 0');

	is(Class::Shared::Protocol::_authentic('another secret', $body, $digest), 0,
		'the right digest for another secret: 0');
};

# ---------------------------------------------------------------- Frontend

# A frontend with the state new() would have built, and no connection, so that
# a single method can be exercised without a backend.
sub frontend_in_state {
	my (%over) = @_;

	if (defined $over{sock} && !ref $over{sock}) {
		my ($reader) = socket_pair();
		$over{sock} = $reader;
	}

	return bless {
		class       => 'Shared::Fake',
		transport   => 'unix',
		socket_path => File::Spec->catfile("$tmp", 'frontend.sock'),
		host        => undef,
		port        => undef,
		token       => undef,
		tls_cert    => undef,
		tls_key     => undef,
		tls_ca      => undef,
		tls_fingerprint => undef,
		ctor        => [],
		autostart   => 0,
		timeout     => 1,
		log         => undef,
		sock        => undef,
		pid         => undef,
		id          => undef,
		last_error  => undef,
		%over,
	}, 'Class::Shared::Frontend';
}

# new() with _connect replaced: the guards run, the transport does not.
sub new_offline {
	my (@args) = @_;

	mock 'Class::Shared::Frontend::_connect' => sub { $_[0] };
	my $frontend = eval { Class::Shared::Frontend->new(@args) };
	my $error = $@;
	restore_all();

	die $error if $error;

	return $frontend;
}

subtest 'Class::Shared::Frontend->new: every guard, both ways' => sub {
	my $token_file = write_bytes('front-token', "tok\n");
	my $cert = File::Spec->catfile('t', 'certs', 'client.pem');
	my $key  = File::Spec->catfile('t', 'certs', 'client-key.pem');
	my $ca   = File::Spec->catfile('t', 'certs', 'ca.pem');

	# Option parsing.
	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', nonsense => 1) },
		q{Class::Shared::Frontend->new: unknown option 'nonsense'}, 'an unknown option is refused by name');
	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', 'dir') },
		'Class::Shared::Frontend->new: expected key/value options', 'an odd list is refused');
	dies_with(sub { Class::Shared::Frontend->new() },
		'Class::Shared::Frontend->new: no class name given', 'no class name: refused');
	dies_with(sub { Class::Shared::Frontend->new(undef) },
		'Class::Shared::Frontend->new: no class name given', 'undef as the target: refused');
	dies_with(sub { Class::Shared::Frontend->new('') },
		'Class::Shared::Frontend->new: no class name given', 'the empty target: refused');
	dies_with(sub { Class::Shared::Frontend->new('2Foo') },
		q{Class::Shared: '2Foo' is not a valid class name}, 'an invalid class: refused by validate_class');
	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', ctor => 'not an array') },
		'Class::Shared::Frontend->new: ctor must be an array ref', 'a scalar ctor: refused');
	dies_with(sub { Class::Shared::Frontend->new(class => undef) },
		'Class::Shared::Frontend->new: no class name given', 'class => undef is no class name');

	# The unix transport, and the things it does not need.
	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', token => 'secret') },
		'Class::Shared::Frontend->new: a unix socket needs no token: '
			. $Class::Shared::UNIX_TRUST_REASON, 'unix and a token: refused');
	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', token_file => $token_file) },
		'Class::Shared::Frontend->new: a unix socket needs no token: '
			. $Class::Shared::UNIX_TRUST_REASON, 'unix and a token file: the same guard');

	for my $option (qw(tls_cert tls_key tls_ca tls_fingerprint)) {
		dies_with(sub { Class::Shared::Frontend->new('Class::Simple', $option => 'value') },
			'Class::Shared::Frontend->new: a unix socket needs no TLS: '
				. $Class::Shared::UNIX_TRUST_REASON, "unix and $option: refused");
	}

	# An empty TLS value is not a TLS value: the guard tests length as well as
	# definedness, so this gets past it and fails later, at the socket.
	dies_like(sub { Class::Shared::Frontend->new('Class::Simple', dir => "$tmp", tls_cert => '', autostart => 0) },
		qr/\AClass::Shared: cannot reach a backend at /,
		'unix with an empty tls_cert: the TLS guard does not fire');

	# Two sources of one secret.
	dies_with(sub {
		Class::Shared::Frontend->new('Class::Simple', host => '127.0.0.1', port => 1,
			token => 'a', token_file => $token_file);
	}, 'Class::Shared::Frontend->new: give token or token_file, not both', 'token and token_file: refused');

	# The tcp transport, and its preconditions.
	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', host => '127.0.0.1') },
		'Class::Shared::Frontend->new: a TCP backend needs both host and port', 'host without port: refused');
	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', port => 1) },
		'Class::Shared::Frontend->new: a TCP backend needs both host and port', 'port without host: refused');

	for my $port (0, 65_536, 'abc', 1.5, -1) {
		dies_with(sub { Class::Shared::Frontend->new('Class::Simple', host => '127.0.0.1', port => $port) },
			'Class::Shared::Frontend->new: port must be a whole number from 1 to 65535',
			"port $port: outside the range, refused before anything is read");
	}

	dies_with(sub {
		Class::Shared::Frontend->new('Class::Simple', host => '127.0.0.1', port => 1,
			socket => "$tmp/x.sock");
	}, 'Class::Shared::Frontend->new: use either socket or host/port, not both',
		'a tcp backend with a socket: refused');

	dies_with(sub {
		Class::Shared::Frontend->new('Class::Simple', host => '127.0.0.1', port => 1, tls_cert => $cert);
	}, 'Class::Shared::Frontend->new: a TCP backend needs tls_cert and tls_key: '
		. 'the backend will not accept a client it cannot verify', 'tls_cert without tls_key: refused');

	dies_with(sub {
		Class::Shared::Frontend->new('Class::Simple', host => '127.0.0.1', port => 1,
			tls_cert => $cert, tls_key => $key);
	}, 'Class::Shared::Frontend->new: a TCP backend needs tls_ca or tls_fingerprint: '
		. 'without one it cannot verify the backend', 'no trust anchor: refused');

	dies_with(sub {
		Class::Shared::Frontend->new('Class::Simple', host => '127.0.0.1', port => 1,
			tls_cert => $cert, tls_key => $key, tls_ca => $ca, tls_fingerprint => $pin);
	}, 'Class::Shared::Frontend->new: give tls_ca or tls_fingerprint, not both: '
		. 'a CA and a pin are alternatives', 'a CA and a pin: refused');

	# Every guard passed: the object is built, and the fields are what the
	# guards promised.
	{
		my $frontend = new_offline('Class::Simple', host => '127.0.0.1', port => 4_443,
			tls_cert => $cert, tls_key => $key, token => 'tok', tls_ca => $ca, timeout => 7);

		is($frontend->shared_class, 'Class::Simple', 'the class is kept');
		is($frontend->{transport}, 'tcp', 'host and port: the tcp transport');
		is($frontend->shared_socket_path, undef, 'tcp has no socket path');
		is($frontend->shared_address, '127.0.0.1:4443', 'the address is host:port');
		is($frontend->{timeout}, 7, 'the timeout is kept');
		is($frontend->{autostart}, 1, 'autostart defaults to true');
		is_deeply($frontend->{ctor}, [], 'the constructor defaults to no arguments');
		is($frontend->{log}, undef, 'a tcp frontend has no log by default');
	}

	{
		my $frontend = new_offline('Class::Simple', host => '127.0.0.1', port => 4_443,
			tls_cert => $cert, tls_key => $key, tls_fingerprint => uc $colon64);

		is($frontend->{tls_fingerprint}, $config{fingerprint_prefix} . $hex64,
			'a fingerprint is normalised when it is stored');
	}

	{
		my $frontend = new_offline('Class::Simple', host => '127.0.0.1', port => 4_443,
			tls_cert => $cert, tls_key => $key, tls_fingerprint => '', tls_ca => $ca);

		is($frontend->{tls_fingerprint}, undef, 'an empty fingerprint is stored as bottom');
		is($frontend->{tls_ca}, $ca, 'so the CA is the trust anchor');
	}

	{
		my $frontend = new_offline('Class::Simple', host => '127.0.0.1', port => 4_443,
			tls_cert => $cert, tls_key => $key, tls_ca => $ca, autostart => 0, ctor => [ 1, 2 ]);

		is($frontend->{autostart}, 0, 'autostart => 0 is kept');
		is_deeply($frontend->{ctor}, [ 1, 2 ], 'the constructor arguments are kept');
	}

	SKIP: {
		skip 'no unix sockets here', 6 unless Class::Shared::_has_unix_sockets();

		my $frontend = new_offline('Class::Simple', dir => "$tmp");
		is($frontend->{transport}, 'unix', 'no host and no port: the unix transport');
		is($frontend->shared_socket_path, File::Spec->catfile("$tmp", $config{socket_name}),
			'the socket path is the default name in the directory');
		is($frontend->{log}, File::Spec->catfile("$tmp", $config{socket_name}) . '.log',
			'a unix frontend logs beside its socket');

		my $explicit = new_offline('Class::Simple', socket => "$tmp/given.sock");
		is($explicit->shared_socket_path, "$tmp/given.sock", 'a socket given as a path is used as given');

		my $long = '/' . ('s' x $config{max_socket_path});
		dies_with(sub { Class::Shared::Frontend->new('Class::Simple', socket => $long) },
			sprintf($config{err}{socket_long}, $long, length $long, $config{max_socket_path}),
			'a socket path over the limit: refused by check_socket_path');
	}
};

subtest 'Class::Shared::Frontend accessors and shared_call' => sub {
	my $frontend = frontend_in_state(id => 3, pid => 4, sock => 1);

	is($frontend->shared_class, 'Shared::Fake', 'shared_class');
	is($frontend->shared_socket_path, File::Spec->catfile("$tmp", 'frontend.sock'), 'shared_socket_path');
	is($frontend->shared_id, 3, 'shared_id');
	is($frontend->shared_pid, 4, 'shared_pid');
	is($frontend->shared_connected, 1, 'shared_connected: a socket means open');
	is(frontend_in_state()->shared_connected, 0, 'shared_connected: no socket means closed');
	is($frontend->shared_last_error, undef, 'shared_last_error');

	my $tcp = frontend_in_state(transport => 'tcp', host => '127.0.0.1', port => 9, socket_path => undef);
	is($tcp->shared_address, '127.0.0.1:9', 'shared_address for tcp');
	is($frontend->shared_address, File::Spec->catfile("$tmp", 'frontend.sock'),
		'shared_address for unix');

	dies_with(sub { $frontend->shared_call() },
		'Class::Shared::Frontend->shared_call: no method name given', 'shared_call without a name: refused');
	dies_with(sub { $frontend->shared_call('') },
		'Class::Shared::Frontend->shared_call: no method name given', 'shared_call with the empty name: refused');

	mock 'Class::Shared::Frontend::_invoke_as_called' => sub {
		my ($self, $method, $args) = @_;
		return wantarray ? ( $method, @{$args} ) : $method;
	};
	is_deeply([ $frontend->shared_call('m', 1, 2) ], [ 'm', 1, 2 ],
		'shared_call passes the name and the arguments through');
	is($frontend->shared_call('m'), 'm', 'shared_call in scalar context returns what it was given');
	restore_all();

	mock 'Class::Shared::Frontend::_request' => sub { $_[1] };
	is_deeply($frontend->shared_status(), { op => 'ping' },
		'shared_status sends a ping, and answers with what came back');
	restore_all();

	is_deeply($frontend->{ctor}, [], 'the state is unchanged by the calls');
};

subtest 'Class::Shared::Frontend: AUTOLOAD, can and isa' => sub {
	my $frontend = frontend_in_state(sock => 1, id => 1);

	# AUTOLOAD: a method the package does not have.
	mock 'Class::Shared::Frontend::_invoke_as_called' => sub { 'dispatched' };
	is($frontend->anything(1), 'dispatched', 'an unknown method is dispatched to the backend');
	restore_all();

	# AUTOLOAD on something that is not an object: a plain function call.
	{
		local $Class::Shared::Frontend::AUTOLOAD = 'Class::Shared::Frontend::anything';
		dies_with(sub { Class::Shared::Frontend::AUTOLOAD('not an object') },
			"Class::Shared::Frontend: 'anything' called on something that is not a Class::Shared::Frontend object",
			'AUTOLOAD with a non-reference: refused by name');
	}

	# can(): the class itself, answered by UNIVERSAL.
	ok(Class::Shared::Frontend->can('new'), 'can() on the class is answered locally');

	# can() with no method name.
	is($frontend->can(undef), undef, 'can(undef) is not a method');

	# can() for a method of the frontend itself.
	ok($frontend->can('shared_call'), 'can() for a local method does not ask the backend');

	# can() for a method of the target: the backend answers.
	mock 'Class::Shared::Frontend::_request' => sub { { ok => 1, result => [ 1 ] } };
	my $code = $frontend->can('remote_method');
	is(ref $code, 'CODE', 'can() for a remote method answers with something callable');
	restore_all();

	# The callable it answers with dispatches to the same object.
	{
		mock 'Class::Shared::Frontend::_invoke_as_called' => sub { 'from the backend' };
		is($code->($frontend, 1), 'from the backend', 'the callable accepts the object first');
		is($code->(1), 'from the backend', 'or the first argument only');
		restore_all();
	}

	# The backend says no.
	mock 'Class::Shared::Frontend::_request' => sub { { ok => 0 } };
	is($frontend->can('remote_method'), undef, 'the backend says no: undef');
	restore_all();

	mock 'Class::Shared::Frontend::_request' => sub { { ok => 1, result => [] } };
	is($frontend->can('remote_method'), undef, 'an empty answer: undef');
	restore_all();

	mock 'Class::Shared::Frontend::_request' => sub { { ok => 1, result => 'not an array' } };
	is($frontend->can('remote_method'), undef, 'an answer that is not an array: undef');
	restore_all();

	mock 'Class::Shared::Frontend::_request' => sub { die "no backend\n" };
	is($frontend->can('remote_method'), undef, 'a failed request is swallowed, not propagated');
	restore_all();

	# isa(): the class itself.
	ok(Class::Shared::Frontend->isa('Class::Shared::Frontend'), 'isa() on the class is answered locally');
	is($frontend->isa(undef), 0, 'isa(undef) is false, without a warning');
	is($frontend->isa('Class::Shared::Frontend'), 1, 'isa(this class) is true locally');
	is($frontend->isa('UNIVERSAL'), 1, 'isa(UNIVERSAL) is true locally');

	mock 'Class::Shared::Frontend::_request' => sub { { ok => 1, result => [ 1 ] } };
	is($frontend->isa('Shared::Fake'), 1, 'the backend says yes: true');
	restore_all();

	mock 'Class::Shared::Frontend::_request' => sub { { ok => 1, result => [ 0 ] } };
	is($frontend->isa('Shared::Fake'), 0, 'the backend says no: false');
	restore_all();

	mock 'Class::Shared::Frontend::_request' => sub { { ok => 1, result => 'no' } };
	is($frontend->isa('Shared::Fake'), 0, 'an answer that is not an array: false');
	restore_all();

	mock 'Class::Shared::Frontend::_request' => sub { { ok => 0 } };
	is($frontend->isa('Shared::Fake'), 0, 'a refused request: false');
	restore_all();

	mock 'Class::Shared::Frontend::_request' => sub { die "no backend\n" };
	is($frontend->isa('Shared::Fake'), 0, 'a failed request is swallowed');
	restore_all();
};

subtest 'Class::Shared::Frontend::_invoke_as_called: the three contexts' => sub {
	my $frontend = frontend_in_state(sock => 1, id => 1);

	my @seen;
	mock 'Class::Shared::Frontend::_invoke' => sub {
		my ($self, $method, $args, $context) = @_;
		push @seen, $context;

		return [ 'a', 'b' ];
	};

	# A statement is void context; assigning to an array would be list context,
	# which is the distinction this proof is about.
	Class::Shared::Frontend::_invoke_as_called($frontend, 'm', []);
	my @list = Class::Shared::Frontend::_invoke_as_called($frontend, 'm', []);
	my $scalar = Class::Shared::Frontend::_invoke_as_called($frontend, 'm', []);

	restore_all();

	is_deeply(\@list, [ 'a', 'b' ], 'list context: every result');
	is($scalar, 'a', 'scalar context: the first result');
	is_deeply(\@seen, [ 'void', 'list', 'scalar' ],
		'each call said which context it was made in: void is not list');
};

subtest 'Class::Shared::Frontend::_invoke: every exit' => sub {
	my $frontend = frontend_in_state(sock => 1, id => 1);

	mock 'Class::Shared::Frontend::_request' => sub { { ok => 1, result => [ 1, 2 ] } };
	is_deeply($frontend->_invoke('m', [], 'list'), [ 1, 2 ], 'a result array: returned as it stands');
	restore_all();

	mock 'Class::Shared::Frontend::_request' => sub { { ok => 1, result => 'scalar' } };
	is_deeply($frontend->_invoke('m', [], 'list'), [], 'a result that is not an array: nothing');
	restore_all();

	mock 'Class::Shared::Frontend::_request' => sub { { ok => 0 } };
	dies_with(sub { $frontend->_invoke('m', [], 'list') },
		"Class::Shared: the backend for 'Shared::Fake' rejected 'm'", 'no error given: the default message');
	restore_all();

	mock 'Class::Shared::Frontend::_request' => sub { { ok => 0, error => 'it broke' } };
	dies_with(sub { $frontend->_invoke('m', [], 'list') }, 'it broke', 'an error without a new line gets one');
	restore_all();

	mock 'Class::Shared::Frontend::_request' => sub { { ok => 0, error => "it broke\n" } };
	dies_with(sub { $frontend->_invoke('m', [], 'list') }, 'it broke', 'an error that ends in a new line is not doubled');
	restore_all();

	mock 'Class::Shared::Frontend::_request' => sub { { ok => 0, error => '' } };
	dies_with(sub { $frontend->_invoke('m', [], 'list') },
		"Class::Shared: the backend for 'Shared::Fake' rejected 'm'", 'an empty error is no error');
	restore_all();
};

subtest 'Class::Shared::Frontend::_request and _roundtrip: every exit' => sub {
	my $frontend = frontend_in_state();

	dies_with(sub { $frontend->_request({ op => 'ping' }) },
		"Class::Shared: this frontend has no connection to a backend for 'Shared::Fake'; its object is gone",
		'no socket: refused before anything is written');

	# _roundtrip: cannot encode.
	{
		my ($reader) = socket_pair();
		my ($response, $error) = $frontend->_roundtrip($reader, sub { 1 });
		is($response, undef, 'a message that cannot be serialised: no response');
		like($error, qr/\Acannot serialise message: /, 'and the encode error is passed on');
		close($reader);
	}

	# _roundtrip: cannot write.
	{
		my ($reader, $writer) = socket_pair();
		close($reader);
		my ($response, $error) = $frontend->_roundtrip($writer, { op => 'ping' });
		is($response, undef, 'a closed peer: no response');
		like($error, qr/\Awrite failed: /, 'and the write error is passed on');
		close($writer);
	}

	# _roundtrip: cannot read.
	{
		my ($reader, $writer) = socket_pair();
		shutdown($writer, 1);
		my ($response, $error) = $frontend->_roundtrip($reader, { op => 'ping' });
		is($response, undef, 'a peer that closes before answering: no response');
		is($error, 'connection closed by peer', 'and the read error is passed on');
		close($reader);
		close($writer);
	}

	# _roundtrip: a response that is not a hash.
	{
		my ($reader, $writer) = socket_pair();
		syswrite($writer, frame_bytes(Storable::nfreeze([ 1, 2 ])));
		my ($response, $error) = $frontend->_roundtrip($reader, { op => 'ping' });
		is($response, undef, 'a response that is not a hash: no response');
		is($error, 'malformed response from the backend', 'and the failure is named');
		close($reader);
		close($writer);
	}

	# _roundtrip: a whole exchange.
	{
		my ($reader, $writer) = socket_pair();
		syswrite($writer, frame_bytes(Storable::nfreeze({ ok => 1, result => 'yes' })));
		my ($response, $error) = $frontend->_roundtrip($reader, { op => 'ping' });
		is_deeply($response, { ok => 1, result => 'yes' }, 'a whole exchange: the response');
		is($error, undef, 'a whole exchange: no error');
		close($reader);
		close($writer);
	}

	# _request: the connection is lost.
	{
		my $lost = frontend_in_state(sock => 1);
		mock 'Class::Shared::Frontend::_roundtrip' => sub { ( undef, 'gone' ) };
		dies_with(sub { $lost->_request({ op => 'ping' }) },
			"Class::Shared: lost the backend for 'Shared::Fake': gone", 'a lost connection is reported');
		restore_all();
		is($lost->shared_connected, 0, 'and the frontend is closed');
		is($lost->shared_last_error, 'gone', 'and the reason is kept');
	}

	# _request: no reason is given.
	{
		my $lost = frontend_in_state(sock => 1);
		mock 'Class::Shared::Frontend::_roundtrip' => sub { ( undef, undef ) };
		dies_with(sub { $lost->_request({ op => 'ping' }) },
			"Class::Shared: lost the backend for 'Shared::Fake': no reason was given",
			'no reason given: the default reason');
		restore_all();
	}

	# _request: the answer, and the id that only a call carries.
	{
		my $open = frontend_in_state(sock => 1, id => 9);
		my $sent;
		mock 'Class::Shared::Frontend::_roundtrip' => sub { $sent = $_[2]; return { ok => 1 } };

		is_deeply($open->_request({ op => 'ping' }), { ok => 1 }, 'a response is returned as it stands');
		ok(!exists $sent->{id}, 'a ping names no object');

		$open->_request({ op => 'call', method => 'm' });
		is($sent->{id}, 9, 'a call carries the id of the object it is for');
		restore_all();
	}
};

subtest 'Class::Shared::Frontend::_greet and _first_exchange_failed' => sub {
	my $frontend = frontend_in_state(transport => 'unix');

	# _greet: the socket cannot be opened.
	mock 'Class::Shared::Frontend::_open' => sub { undef };
	is($frontend->_greet(), undef, '_open fails: _greet returns nothing');
	restore_all();

	# _greet: the handshake fails.
	{
		my ($reader, $writer) = socket_pair();
		mock 'Class::Shared::Frontend::_open' => sub { $reader };
		mock 'Class::Shared::Frontend::_roundtrip' => sub { ( undef, 'closed by peer' ) };

		is($frontend->_greet(), undef, 'a failed handshake: nothing');
		is($frontend->shared_last_error,
			'handshake failed: closed by peer (this backend may require a token)',
			'and the reason is explained');
		restore_all();
		close($reader);
		close($writer);
	}

	# _greet: the handshake is refused.
	{
		my ($reader, $writer) = socket_pair();
		mock 'Class::Shared::Frontend::_open' => sub { $reader };
		mock 'Class::Shared::Frontend::_roundtrip' => sub { ({ ok => 0, error => 'not allowed' }) };

		dies_with(sub { $frontend->_greet() }, 'Class::Shared: not allowed',
			'a refused handshake: dies with the backend reason');
		restore_all();
		close($reader);
		close($writer);
	}

	{
		my ($reader, $writer) = socket_pair();
		mock 'Class::Shared::Frontend::_open' => sub { $reader };
		mock 'Class::Shared::Frontend::_roundtrip' => sub { ({ ok => 0 }) };

		dies_with(sub { $frontend->_greet() }, 'Class::Shared: the backend refused the handshake',
			'a refused handshake with no reason: the default reason');
		restore_all();
		close($reader);
		close($writer);
	}

	# _greet: the handshake is accepted.
	{
		my ($reader, $writer) = socket_pair();
		mock 'Class::Shared::Frontend::_open' => sub { $reader };
		mock 'Class::Shared::Frontend::_roundtrip' => sub { ({ ok => 1, pid => 4242 }) };

		is($frontend->_greet(), $reader, 'an accepted handshake: the socket');
		is($frontend->shared_pid, 4242, 'and the backend pid is kept');
		is($frontend->shared_last_error, undef, 'and the old reason is cleared');
		restore_all();
		close($reader);
		close($writer);
	}

	# _first_exchange_failed: every branch, called directly.
	is($frontend->_first_exchange_failed(undef),
		'no reason was given (this backend may require a token)',
		'no reason: the default, with the token hint');

	my $tcp = frontend_in_state(transport => 'tcp');
	like($tcp->_first_exchange_failed('connection closed by peer'),
		qr/\Athe backend refused this client's certificate: .* \(detail: connection closed by peer\)\z/,
		'tcp and a closed stream: the certificate hint');
	like($tcp->_first_exchange_failed('read failed: timeout'),
		qr/\Athe backend refused this client's certificate: /, 'tcp and a read failure: the same hint');
	like($tcp->_first_exchange_failed('timed out waiting for a reply'),
		qr/may be busy running another client's method/, 'a timeout: the busy hint');
	is($frontend->_first_exchange_failed('timed out waiting for a reply'),
		"timed out waiting for a reply (the backend may be busy running another client's method; "
			. 'try again, or raise timeout)', 'a timeout on unix: the busy hint, without the token text');

	my $with_token = frontend_in_state(token => 'tok');
	is($with_token->_first_exchange_failed('some other failure'), 'some other failure',
		'a token is in use: no token hint');
	is($frontend->_first_exchange_failed('some other failure'),
		'some other failure (this backend may require a token)', 'no token: the hint');
};

subtest 'Class::Shared::Frontend: shared_close, DESTROY and shared_shutdown' => sub {
	# shared_close: nothing to close.
	is(frontend_in_state()->shared_close(), 0, 'no socket: 0');

	# shared_close: a socket, and the state goes with it.
	{
		my ($reader, $writer) = socket_pair();
		my $frontend = frontend_in_state(sock => $reader, id => 5, pid => 6);

		is($frontend->shared_close(), 1, 'a socket: 1');
		is($frontend->shared_connected, 0, 'the socket is cleared');
		is($frontend->shared_id, undef, 'the object id is cleared');
		is($frontend->shared_pid, undef, 'the backend pid is cleared');
		close($writer);
	}

	# DESTROY: no socket is nothing to do.
	{
		my $frontend = frontend_in_state();
		is($frontend->DESTROY(), undef, 'DESTROY with no socket returns nothing and does not die');
	}

	# DESTROY: a socket is closed.
	{
		my ($reader, $writer) = socket_pair();
		my $frontend = frontend_in_state(sock => $reader);
		$frontend->DESTROY();
		is($frontend->{sock}, undef, 'DESTROY closes the socket');
		close($writer);
	}

	# shared_shutdown: nothing to shut down.
	is(frontend_in_state()->shared_shutdown(), 0, 'no socket: 0');

	# shared_shutdown: tcp, accepted.
	{
		my ($reader, $writer) = socket_pair();
		my $frontend = frontend_in_state(sock => $reader, transport => 'tcp', id => 1);
		mock 'Class::Shared::Frontend::_request' => sub { { ok => 1 } };

		is($frontend->shared_shutdown(), 1, 'tcp: the answer is returned');
		is($frontend->shared_connected, 0, 'and the connection is closed');
		restore_all();
		close($writer);
	}

	# shared_shutdown: tcp, refused.
	{
		my ($reader, $writer) = socket_pair();
		my $frontend = frontend_in_state(sock => $reader, transport => 'tcp');
		mock 'Class::Shared::Frontend::_request' => sub { { ok => 0 } };

		is($frontend->shared_shutdown(), 0, 'tcp, refused: 0');
		restore_all();
		close($writer);
	}

	# shared_shutdown: the request fails, so the error is raised after closing.
	{
		my ($reader, $writer) = socket_pair();
		my $frontend = frontend_in_state(sock => $reader, transport => 'tcp');
		mock 'Class::Shared::Frontend::_request' => sub { die "no backend\n" };

		dies_with(sub { $frontend->shared_shutdown() }, 'no backend',
			'a failed shutdown: the error is raised');
		is($frontend->shared_connected, 0, 'and the connection is closed first');
		restore_all();
		close($writer);
	}

	# shared_shutdown on unix waits for the socket to go, which it never does
	# here, so the wait is bounded by SHUTDOWN_WAIT.
	{
		my ($reader, $writer) = socket_pair();
		my $path = File::Spec->catfile("$tmp", 'shutdown.sock');
		my $frontend = frontend_in_state(sock => $reader, socket_path => $path);
		mock 'Class::Shared::Frontend::_request' => sub { { ok => 1 } };

		my $started = Time::HiRes::time();
		is($frontend->shared_shutdown(), 1, 'unix: the answer is returned');
		ok(Time::HiRes::time() - $started < $Class::Shared::Frontend::SHUTDOWN_WAIT + 1,
			'the wait for the socket to go is bounded');
		restore_all();
		close($writer);
	}
};

subtest 'Class::Shared::Frontend::_close: both answers' => sub {
	my $frontend = frontend_in_state();

	my ($reader, $writer) = socket_pair();
	is($frontend->_close($reader, 'the test socket'), 1, 'an open handle: 1');

	my $warnings = '';
	{
		local $SIG{__WARN__} = sub { $warnings .= $_[0] };
		is($frontend->_close($reader, 'the test socket'), 0, 'a handle already closed: 0');
	}
	like($warnings, qr/\AClass::Shared::Frontend: cannot close the test socket: /,
		'and it carps with the name it was given');
	close($writer);
};

# ---------------------------------------------------------------- Backend

sub backend_in_state {
	my (%over) = @_;

	return bless {
		classes => {}, objects => {}, clients => {}, address => 'test',
		queued => 0, calls => 0, constructed => 0, started => time,
		call_timeout => 0, max_queued_total => 0, %over,
	}, 'Class::Shared::Backend';
}

subtest 'Class::Shared::Backend::_refuse and _failure' => sub {
	dies_with(sub { Class::Shared::Backend::_refuse('the reason') },
		'Class::Shared::Backend->new: the reason', '_refuse dies with the prefix and the reason');

	is_deeply(Class::Shared::Backend::_failure('protocol', 'bad'),
		{ ok => 0, kind => 'protocol', error => 'bad' }, '_failure is a refusal of the named kind');
};

subtest 'Class::Shared::Backend::_validate: both answers' => sub {
	my $empty = Class::Shared::Backend::_validate({}, 'an argument');
	is_deeply($empty, {}, 'no options: nothing to check, nothing returned');

	my $valid = Class::Shared::Backend::_validate({ max_clients => 5 }, 'an argument');
	is($valid->{max_clients}, 5, 'a known option: returned, still set');

	dies_like(sub { Class::Shared::Backend::_validate({ nonsense => 1 }, 'an argument') },
		qr/\AClass::Shared::Backend->new: an argument is not valid: /, 'an unknown option: refused');

	dies_like(sub { Class::Shared::Backend::_validate({ max_clients => 'many' }, 'a configured value') },
		qr/\AClass::Shared::Backend->new: a configured value is not valid: /,
		'a value of the wrong type: refused, naming where it came from');

	# The caller's $@ is theirs.
	{
		local $@ = 'sentinel';
		Class::Shared::Backend::_validate({}, 'an argument');
		is($@, 'sentinel', 'a successful check does not overwrite $@');
	}
};

subtest 'Class::Shared::Backend::_load_class: every exit' => sub {
	my $backend = backend_in_state();

	is_deeply([ Class::Shared::Backend::_load_class($backend, 'Class::Shared::Protocol') ], [ 1 ],
		'a module that loads: 1');

	is(Class::Shared::Backend::_load_class($backend, 'Class::Shared::Protocol'), 1,
		'a module already loaded: 1, without loading it again');
	is($backend->{classes}{'Class::Shared::Protocol'}, 1, 'and it is remembered');

	my ($missing, $missing_error)
		= Class::Shared::Backend::_load_class($backend, 'No::Such::Class::At::All');
	is($missing, 0, 'a module that cannot be loaded: 0');
	like($missing_error, qr/\Acannot load No::Such::Class::At::All: /, 'and the reason says which class');

	is_deeply([ Class::Shared::Backend::_load_class($backend, 'Carp') ], [ 1 ],
		'a module with an import: require and import both run');
};

subtest 'Class::Shared::Backend::_would_block: every exit' => sub {
	my $backend = backend_in_state();

	my $plain   = bless {}, 'FakeHandle';
	my $tls     = bless { want_read => 1 }, 'FakeTLSHandle';
	my $writing = bless { want_write => 1 }, 'FakeTLSHandle';

	{
		local $! = Errno::EAGAIN();
		is($backend->_would_block($plain), 1, 'EAGAIN: it would block, whatever the handle says');
	}

	{
		local $! = 0;
		is($backend->_would_block($tls), 1, 'no errno, and the TLS layer wants to read: it would block');
		is($backend->_would_block($tls, 'write'), 1,
			'no errno, and the TLS layer wants to read while writing: it would block');
		is($backend->_would_block($writing, 'write'), 1,
			'no errno, and the TLS layer wants to write: it would block');
		is($backend->_would_block($plain), 0, 'no errno and nothing wanted: it would not block');
		is($backend->_would_block($plain, 'write'), 0, 'the same for a write');
	}

	# A handle that cannot be asked is not blocked: can() is part of the test.
	{
		local $! = 0;
		is($backend->_would_block('not an object'), 0, 'a handle with no want_* methods: not blocked');
	}
};

subtest 'Class::Shared::Backend::_dispatch: every route' => sub {
	my $backend = backend_in_state();
	my $greeted = { greeted => 1 };
	my $new     = { greeted => 0 };

	is_deeply(Class::Shared::Backend::_dispatch($backend, $greeted, 'not a hash'),
		{ ok => 0, kind => 'protocol', error => 'request is not a hash reference' },
		'a request that is not a hash: refused before the operation is looked at');

	mock 'Class::Shared::Backend::_op_hello' => sub { { ok => 1, hello => 1 } };
	is_deeply(Class::Shared::Backend::_dispatch($backend, $new, { op => 'hello' }),
		{ ok => 1, hello => 1 }, 'hello: routed before the handshake guard');
	restore_all();

	is_deeply(Class::Shared::Backend::_dispatch($backend, $new, { op => 'ping' }),
		{ ok => 0, kind => 'protocol', error => 'handshake required' },
		'not greeted: every other operation is refused');

	is_deeply(Class::Shared::Backend::_dispatch($backend, $new, {}),
		{ ok => 0, kind => 'protocol', error => 'handshake required' },
		'no op at all: the empty operation is refused by the same guard');

	mock 'Class::Shared::Backend::_op_new' => sub { 'new' };
	mock 'Class::Shared::Backend::_op_call' => sub { 'call' };
	mock 'Class::Shared::Backend::_op_ping' => sub { 'ping' };
	mock 'Class::Shared::Backend::_op_shutdown' => sub { 'shutdown' };

	is(Class::Shared::Backend::_dispatch($backend, $greeted, { op => 'new' }), 'new', 'new is routed');
	is(Class::Shared::Backend::_dispatch($backend, $greeted, { op => 'call' }), 'call', 'call is routed');
	is(Class::Shared::Backend::_dispatch($backend, $greeted, { op => 'ping' }), 'ping', 'ping is routed');
	is(Class::Shared::Backend::_dispatch($backend, $greeted, { op => 'shutdown' }), 'shutdown',
		'shutdown is routed');
	restore_all();

	is_deeply(Class::Shared::Backend::_dispatch($backend, $greeted, { op => 'nonsense' }),
		{ ok => 0, kind => 'protocol', error => "unknown operation 'nonsense'" },
		'an unknown operation is named in the refusal');
};

done_testing();
