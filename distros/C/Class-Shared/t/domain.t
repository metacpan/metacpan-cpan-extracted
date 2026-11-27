#!/usr/bin/env perl

# Domain tests for Class::Shared, Class::Shared::Frontend and
# Class::Shared::Protocol.
#
# Every parameter is analysed as a domain: the valid and invalid classes are
# found by equivalence partitioning, and each class boundary is probed at
# minimum - 1, minimum, the typical value, maximum and maximum + 1.  Each
# parameter gets its own subtest, so a failure names the domain it came from.
#
# The data covers the character domain too: non-ASCII letters, emoji, a ZWJ
# emoji sequence, Zalgo combining marks and a right-to-left override.  The
# file itself is ASCII only; every non-ASCII code point is written as a
# \x{...} escape, so the tests say exactly which characters they mean.
#
# Nothing here connects to a backend: the validation domains are all decided
# before a connection is made.  The two calls that replace a process's
# standard streams are made in a forked child, so the test process keeps its
# own STDOUT and STDERR even when they fail.

use strict;
use warnings;

use Cwd ();
use Encode ();
use File::Spec ();
use File::Temp ();
use IO::Socket::SSL ();
use POSIX ();
use Time::HiRes ();

use Test::Most;
use Test::Needs;

use Class::Shared;
use Class::Shared::Frontend;
use Class::Shared::Protocol;

# Like the rest of the suite, these need a unix socket in a directory only its
# owner can write to.
BEGIN {
	test_needs 'Test::Permissions';

	plan skip_all => 'a backend needs unix sockets in an owner-only directory, '
		. 'which this perl cannot provide (Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();
}

# Nothing below repeats a limit, a mode or a message: the numbers the tests
# probe come from here, and the module's own variables are asserted against
# them in "documented limits and process state".
my %config = (
	max_socket_path  => 100,
	max_secret       => 65_536,
	max_frame        => 64 * 1024 * 1024,
	digest_size      => 32,
	sha256_bytes     => 32,
	poll_interval    => 0.02,
	poll_tolerance   => 0.5,
	timing_ceiling   => 5,
	socket_name      => 'class-shared.sock',
	sha256_prefix    => 'sha256$',
	colon_separator  => ':',
	pin_byte         => 'ab',
	dir_mode         => 0700,
	open_mode        => 0755,
	private_mode     => 0700,
	evil_modes       => [ 0777, 0770, 0702 ],
	beyond_limit     => 40_000,
	repeat_limit     => 32_766,
	port_min         => 1,
	port_max         => 65_535,
	zalgo_repeats    => 5,
	utf8_secret      => "Gr\xc3\xbc\xc3\x9fe \xf0\x9f\x98\x80\n",
	err              => {
		no_class        => 'Class::Shared: no class name given',
		bad_class       => q{Class::Shared: '%s' is not a valid class name},
		no_token_file   => 'Class::Shared: no token file given',
		cannot_read     => 'Class::Shared: cannot read %s: ',
		token_too_large => 'Class::Shared: %s is too large to be a secret (more than %d bytes)',
		token_empty     => 'Class::Shared: %s is empty',
		no_fingerprint  => 'Class::Shared: no TLS fingerprint given',
		bad_fingerprint => q{Class::Shared: '%s' is not a SHA-256 certificate fingerprint: }
			. 'give 64 hexadecimal digits, optionally colon-separated',
		nul_dir       => 'Class::Shared: a directory name may not contain a NUL byte',
		no_dir        => 'Class::Shared: no directory given',
		no_socket     => 'Class::Shared: no socket path given',
		socket_long   => q{Class::Shared: socket path '%s' is %d characters, more than the %d allowed; }
			. 'set CLASS_SHARED_DIR or pass dir => to a shorter directory',
		dir_unsafe    => '%s is writable by group or others; refusing to use it',
		create_failed => 'cannot create %s: ',
		fe_odd        => 'Class::Shared::Frontend->new: expected key/value options',
		fe_unknown    => q{Class::Shared::Frontend->new: unknown option '%s'},
		fe_no_class   => 'Class::Shared::Frontend->new: no class name given',
		fe_ctor       => 'Class::Shared::Frontend->new: ctor must be an array ref',
		fe_port       => 'Class::Shared::Frontend->new: port must be a whole number from 1 to 65535',
		fe_unix_token => 'Class::Shared::Frontend->new: a unix socket needs no token: '
			. $Class::Shared::UNIX_TRUST_REASON,
		fe_unix_tls => 'Class::Shared::Frontend->new: a unix socket needs no TLS: '
			. $Class::Shared::UNIX_TRUST_REASON,
		fe_two_tokens => 'Class::Shared::Frontend->new: give token or token_file, not both',
		fe_tcp_both   => 'Class::Shared::Frontend->new: a TCP backend needs both host and port',
		fe_socket_both => 'Class::Shared::Frontend->new: use either socket or host/port, not both',
		fe_tls_pair    => 'Class::Shared::Frontend->new: a TCP backend needs tls_cert and tls_key: '
			. 'the backend will not accept a client it cannot verify',
		fe_tls_trust => 'Class::Shared::Frontend->new: a TCP backend needs tls_ca or tls_fingerprint: '
			. 'without one it cannot verify the backend',
		fe_tls_both => 'Class::Shared::Frontend->new: give tls_ca or tls_fingerprint, not both: '
			. 'a CA and a pin are alternatives',
		frame_limit    => 'frame of %d bytes exceeds the limit of %d',
		short_digest   => 'frame is too short to be authenticated',
		failed_digest  => 'frame failed authentication',
		timeout        => 'timed out waiting for a reply',
		closed         => 'connection closed by peer',
		write_failed   => 'write failed: ',
		serialise      => 'cannot serialise message: ',
		deserialise    => 'cannot deserialise message: ',
	},
);

$config{cwd}          = Cwd::getcwd();
$config{env_dir}      = $ENV{CLASS_SHARED_DIR};
$config{env_xdg}      = $ENV{XDG_RUNTIME_DIR};
# The device and inode of STDOUT, which change if it is redirected.
$config{stdout_id}    = join(':', (stat(STDOUT))[0, 1]);

my $tmp = File::Temp->newdir('class-shared-domain-XXXXXX', TMPDIR => 1, CLEANUP => 1);

# A declared failure: the exact documented text, plus the new line every
# message ends with.
sub dies_with {
	my ($code, $expected, $name) = @_;

	throws_ok { $code->() } qr/\A\Q$expected\E\n\z/, $name;

	return;
}

# A declared failure whose text contains something the system chooses, such
# as the strerror text after a colon.
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

sub read_mode {
	my ($path) = @_;
	my @stat = stat($path) or return;

	return $stat[2] & 07777;
}

# Run detach_standard_streams in a child, which is the only safe place for a
# call that replaces STDIN, STDOUT and STDERR.  POSIX::_exit skips the END
# blocks, so the child cannot print a second TAP plan.
sub detach_in_child {
	my ($log) = @_;

	my $pid = fork();
	return unless defined $pid;

	if (!$pid) {
		my ($ok) = Class::Shared::detach_standard_streams($log);
		POSIX::_exit($ok ? 0 : 1);
	}

	waitpid($pid, 0);

	return $? >> 8;
}

my $hex64 = join('', map { sprintf '%02x', $_ } 1 .. $config{sha256_bytes});
my @pairs = $hex64 =~ /(..)/g;
my $colon64 = join($config{colon_separator}, @pairs);
my $normalised = $config{sha256_prefix} . $hex64;

subtest 'validate_class: length boundaries' => sub {
	my $err = $config{err};

	dies_with(sub { Class::Shared::validate_class(undef) },
		$err->{no_class}, 'undef is outside the domain');
	dies_with(sub { Class::Shared::validate_class('') },
		$err->{no_class}, 'the empty string is outside the domain (length 0)');

	is(Class::Shared::validate_class('A'), 'A', 'length 1, the minimum, is accepted');
	is(Class::Shared::validate_class('_'), '_', 'a lone underscore at the minimum is accepted');

	dies_with(sub { Class::Shared::validate_class('1') },
		sprintf($err->{bad_class}, '1'), 'a digit at length 1 is outside the domain');

	my $long = 'A' x $config{beyond_limit};
	my $got = Class::Shared::validate_class($long);
	is(length($got), $config{beyond_limit},
		"a $config{beyond_limit} character name is accepted: the check has no repeat limit");
	cmp_ok($config{beyond_limit}, '>', $config{repeat_limit},
		'the accepted name is longer than perl 5.26\'s repeated group limit');

	my $too_long_with_empty_part = $long . '::';
	dies_like(sub { Class::Shared::validate_class($too_long_with_empty_part) },
		qr/\A\QClass::Shared: \E.*\Qis not a valid class name\E\n\z/,
		'a long name ending in an empty part is still refused');
};

subtest 'validate_class: structural partitions' => sub {
	my $err = $config{err};

	my @valid = (
		[ 'one word',             'Foo' ],
		[ 'several words',        'Foo::Bar' ],
		[ 'three words',          'Foo::Bar::Baz' ],
		[ 'underscores',          'My_Class2' ],
		[ 'leading underscore',   '_private' ],
		[ 'digit inside a part',  'A1' ],
		[ 'underscore part',      'A::_2' ],
	);

	for my $case (@valid) {
		my ($name, $value) = @{$case};
		is(Class::Shared::validate_class($value), $value, "$name is in the valid partition");
	}

	my @invalid = (
		[ 'leading digit',        '2Foo' ],
		[ 'trailing separator',   'Foo::' ],
		[ 'leading separator',    '::Foo' ],
		[ 'empty middle part',    'A:::B' ],
		[ 'hyphen',               'Foo-Bar' ],
		[ 'space',                'Foo Bar' ],
		[ 'dot',                  'Foo.Bar' ],
		[ 'digit first in part',  'Foo::2Bar' ],
		[ 'leading space',        ' Foo' ],
		[ 'trailing new line',    "Foo\n" ],
		[ 'trailing separator x2', 'Foo::Bar::' ],
	);

	for my $case (@invalid) {
		my ($name, $value) = @{$case};
		dies_with(sub { Class::Shared::validate_class($value) },
			sprintf($err->{bad_class}, $value), "$name is outside the domain");
	}
};

subtest 'validate_class: multibyte and character-domain partitions' => sub {
	my $err = $config{err};

	my @invalid = (
		[ 'Latin-1 umlaut',        "M\x{fc}ller" ],
		[ 'sharp s',               "Stra\x{df}e" ],
		[ 'emoji',                 "A\x{1F600}B" ],
		[ 'ZWJ emoji sequence',    "A\x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F467}B" ],
		[ 'Zalgo combining marks', 'Za' . ("\x{0336}\x{0337}\x{0316}" x $config{zalgo_repeats}) . 'lgo' ],
		[ 'right-to-left override', "A\x{202E}B" ],
		[ 'right-to-left mark',    "A\x{200F}B" ],
		[ 'zero width non-joiner', "A\x{200C}B" ],
		[ 'non-breaking space',    "A\x{00A0}B" ],
		[ 'Arabic-Indic digit',    "A\x{0661}B" ],
		[ 'fullwidth letter',      "\x{FF21}" ],
		[ 'combining diaeresis',   "Mu\x{0308}ller" ],
	);

	for my $case (@invalid) {
		my ($name, $value) = @{$case};
		dies_with(sub { Class::Shared::validate_class($value) },
			sprintf($err->{bad_class}, $value),
			"$name is outside the ASCII class-name domain, and is echoed unchanged");
	}
};

subtest 'normalise_fingerprint: format partitions' => sub {
	my $err = $config{err};

	my $zeroes = '0' x ($config{sha256_bytes} * 2);
	my $letters = 'a' x ($config{sha256_bytes} * 2);

	my @valid = (
		[ '64 lower case hex digits',        $hex64,                          $normalised ],
		[ '64 upper case hex digits',        uc $hex64,                       $normalised ],
		[ '32 colon separated pairs',        $colon64,                        $normalised ],
		[ '32 colon separated pairs, upper', uc $colon64,                     $normalised ],
		[ 'sha256$ and 64 digits',           $config{sha256_prefix} . $hex64,  $normalised ],
		[ 'sha256$ and 32 pairs',            $config{sha256_prefix} . $colon64, $normalised ],
		[ 'digits only',                     $zeroes,  $config{sha256_prefix} . $zeroes ],
		[ 'letters only',                    $letters, $config{sha256_prefix} . $letters ],
	);

	for my $case (@valid) {
		my ($name, $value, $expected) = @{$case};
		is(Class::Shared::normalise_fingerprint($value), $expected,
			"$name is in the valid partition and normalises to sha256\$ + lower case");
	}

	my @invalid = (
		[ '63 digits',             substr($hex64, 0, 63) ],
		[ '65 digits',             $hex64 . '0' ],
		[ '31 pairs',              join($config{colon_separator}, @pairs[0 .. 30]) ],
		[ '33 pairs',              join($config{colon_separator}, @pairs, $config{pin_byte}) ],
		[ 'a short pair',          join($config{colon_separator}, @pairs[0 .. 30]) . ':a' ],
		[ 'upper case prefix',     'SHA256$' . $hex64 ],
		[ 'upper case mixed prefix', 'Sha256$' . $hex64 ],
		[ 'prefix with no digest', $config{sha256_prefix} ],
		[ 'a non-hex letter',      'g' . substr($hex64, 1) ],
		[ 'spaces as separators',  join(' ', @pairs) ],
		[ 'hyphens as separators', join('-', @pairs) ],
		[ 'leading space',         ' ' . $hex64 ],
		[ 'trailing space',        $hex64 . ' ' ],
		[ 'trailing colon',        $colon64 . ':' ],
	);

	for my $case (@invalid) {
		my ($name, $value) = @{$case};
		dies_with(sub { Class::Shared::normalise_fingerprint($value) },
			sprintf($err->{bad_fingerprint}, $value), "$name is outside the format domain");
	}

	dies_with(sub { Class::Shared::normalise_fingerprint(undef) },
		$err->{no_fingerprint}, 'undef is outside the domain');
	dies_with(sub { Class::Shared::normalise_fingerprint('') },
		$err->{no_fingerprint}, 'the empty string (length 0) is outside the domain');
};

subtest 'normalise_fingerprint: length boundaries' => sub {
	my $err = $config{err};

	my $colon_length = length $colon64;
	is($colon_length, $config{sha256_bytes} * 3 - 1, 'the colon form is 95 characters');

	dies_with(sub { Class::Shared::normalise_fingerprint(substr($colon64, 0, $colon_length - 1)) },
		sprintf($err->{bad_fingerprint}, substr($colon64, 0, $colon_length - 1)),
		'maximum - 1 character (94) is outside the domain');
	is(Class::Shared::normalise_fingerprint($colon64), $normalised,
		'maximum (95) is inside the domain');

	dies_with(sub { Class::Shared::normalise_fingerprint($colon64 . '0') },
		sprintf($err->{bad_fingerprint}, $colon64 . '0'),
		'maximum + 1 character (96) is outside the domain');

	is(Class::Shared::normalise_fingerprint($hex64), $normalised,
		'the 64 character form is exactly at its maximum');
};

subtest 'normalise_fingerprint: multibyte partitions' => sub {
	my $err = $config{err};

	my @invalid = (
		[ 'umlaut for a digit',    substr($hex64, 0, 62) . "\x{fc}\x{fc}" ],
		[ 'sharp s for a digit',   substr($hex64, 0, 63) . "\x{df}" ],
		[ 'emoji at the end',      substr($hex64, 0, 60) . "\x{1F600}" ],
		[ 'RTL override inside',   substr($hex64, 0, 32) . "\x{202E}" . substr($hex64, 32) ],
		[ 'Zalgo before a digit',  'a' . ("\x{0336}" x $config{zalgo_repeats}) . substr($hex64, 1) ],
		[ 'fullwidth hex digits',  "\x{FF11}" x 64 ],
	);

	for my $case (@invalid) {
		my ($name, $value) = @{$case};
		dies_with(sub { Class::Shared::normalise_fingerprint($value) },
			sprintf($err->{bad_fingerprint}, $value),
			"$name is refused without character corruption in the message");
	}
};

subtest 'dir_of: path partitions' => sub {
	my @cases = (
		[ 'a bare file name',        'x.sock',   '.' ],
		[ 'a file in the root',      '/x.sock',  '/' ],
		[ 'a nested file',           '/a/b/c',   '/a/b' ],
		[ 'a trailing slash',        'a/b/',     'a' ],
		[ 'the empty path',          '',         '.' ],
		[ 'a doubled root',          '//',       '/' ],
		[ 'a doubled separator',     'a//b',     'a' ],
		[ 'a relative directory',    'a/b/c',    'a/b' ],
	);

	for my $case (@cases) {
		my ($name, $path, $expected) = @{$case};
		is(Class::Shared::dir_of($path), $expected, "$name gives $expected");
	}

	my $wide = "dir\x{fc}/x.sock";
	is(Class::Shared::dir_of($wide), "dir\x{fc}", 'a multibyte directory part is returned unchanged');
};

subtest 'check_socket_path: length boundaries' => sub {
	my $err = $config{err};
	my $max = $Class::Shared::MAX_SOCKET_PATH;

	my $at_max = '/' . ('p' x ($max - 1));
	my $below  = '/' . ('p' x ($max - 2));

	is(length($below), $max - 1, 'the path below the maximum is one character shorter');
	is(Class::Shared::check_socket_path($below), $below, 'maximum - 1 is accepted');
	is(Class::Shared::check_socket_path($at_max), $at_max, 'the maximum (100) is accepted');

	for my $over ($max + 1, $max + 2) {
		my $path = '/' . ('p' x ($over - 1));
		dies_with(sub { Class::Shared::check_socket_path($path) },
			sprintf($err->{socket_long}, $path, $over, $max),
			"socket path of $over characters (maximum + " . ($over - $max) . ') is refused');
	}

	dies_with(sub { Class::Shared::check_socket_path(undef) },
		$err->{no_socket}, 'undef is outside the domain');
	dies_with(sub { Class::Shared::check_socket_path('') },
		$err->{no_socket}, 'the empty path (length 0) is outside the domain');

	my $wide = '/' . ("\x{fc}" x ($max - 1));
	is(length($wide), $max, 'a multibyte path at the character limit');
	is(Class::Shared::check_socket_path($wide), $wide,
		'a multibyte path at the character limit is returned unchanged');
};

subtest 'socket_path: composed length boundaries' => sub {
	my $err  = $config{err};
	my $name = $config{socket_name};
	my $max  = $Class::Shared::MAX_SOCKET_PATH;

	like(Class::Shared::socket_path(), qr/\A.*\Q$name\E\z/,
		'the default socket always ends in the documented file name');

	is(Class::Shared::socket_path('/tmp'), File::Spec->catfile('/tmp', $name),
		'a directory gives one socket inside it');

	my $fits = $max - 1 - length($name);
	my $fits_dir = '/' . ('d' x ($fits - 1));
	my $path = Class::Shared::socket_path($fits_dir);
	is(length($path), $max,
		"a directory of $fits characters gives a socket path of exactly $max characters");

	my $too_long_dir = '/' . ('d' x $fits);
	my $too_long_path = File::Spec->catfile($too_long_dir, $name);
	dies_with(sub { Class::Shared::socket_path($too_long_dir) },
		sprintf($err->{socket_long}, $too_long_path, length($too_long_path), $max),
		'one more character in the directory is refused');

	my $wide_dir = File::Spec->catdir("$tmp", "\x{fc}");
	like(Class::Shared::socket_path($wide_dir), qr/\A\Q$wide_dir\E/, 
		'a multibyte directory is used unchanged');
};

subtest 'default_dir: precedence partitions' => sub {
	my $err = $config{err};

	{
		local $ENV{CLASS_SHARED_DIR} = File::Spec->catdir("$tmp", 'from-env');

		is(Class::Shared::default_dir(), $ENV{CLASS_SHARED_DIR},
			'CLASS_SHARED_DIR is used when no directory is given');
		is(Class::Shared::default_dir(dir => File::Spec->catdir("$tmp", 'from-caller')),
			File::Spec->catdir("$tmp", 'from-caller'),
			'an explicit directory beats the environment');
		is(Class::Shared::default_dir(dir => ''), $ENV{CLASS_SHARED_DIR},
			'the empty string (length 0) falls through to the environment');
	}

	{
		my $xdg = File::Spec->catdir("$tmp", 'xdg');
		mkdir($xdg, $config{dir_mode}) or die "cannot make $xdg: $!";

		local $ENV{CLASS_SHARED_DIR} = '';
		local $ENV{XDG_RUNTIME_DIR} = $xdg;

		is(Class::Shared::default_dir(), File::Spec->catdir($xdg, 'class-shared'),
			'an XDG_RUNTIME_DIR that exists is used, with class-shared appended');
	}

	{
		my $absent = File::Spec->catdir("$tmp", 'absent-xdg');

		local $ENV{CLASS_SHARED_DIR} = '';
		local $ENV{XDG_RUNTIME_DIR} = $absent;

		my $got = Class::Shared::default_dir();
		unlike($got, qr/\A\Q$absent\E/, 'an XDG_RUNTIME_DIR that does not exist is not used');
		ok(length $got, 'a fallback directory is still returned');
	}

	dies_with(sub { Class::Shared::default_dir(dir => "$tmp/a\0b") },
		$err->{nul_dir}, 'a NUL byte anywhere in the name is outside the domain');

	is(Class::Shared::default_dir(dir => File::Spec->catdir("$tmp", "\x{fc}\x{df}")),
		File::Spec->catdir("$tmp", "\x{fc}\x{df}"),
		'a multibyte directory is returned unchanged');
};

subtest 'ensure_dir: permission boundaries' => sub {
	my $err = $config{err};

	my $fresh = File::Spec->catdir("$tmp", 'fresh');
	my ($ok, $why) = Class::Shared::ensure_dir($fresh);
	is($ok, 1, 'a directory that does not exist is created');
	is($why, undef, 'and there is no reason to report');
	ok(-d $fresh, 'it exists afterwards');
	is(read_mode($fresh), $config{dir_mode}, 'it is created with mode 0700');

	my $private = File::Spec->catdir("$tmp", 'private');
	mkdir($private, $config{private_mode}) or die "cannot make $private: $!";
	chmod($config{private_mode}, $private);
	($ok, $why) = Class::Shared::ensure_dir($private);
	is($ok, 1, 'an existing directory at the minimum permissions is accepted');
	is($why, undef, 'and there is no reason to report');

	my $open = File::Spec->catdir("$tmp", 'open');
	mkdir($open, $config{open_mode}) or die "cannot make $open: $!";
	chmod($config{open_mode}, $open);
	($ok, $why) = Class::Shared::ensure_dir($open);
	is($ok, 1, 'a 0755 directory is accepted: group and others cannot write to it');

	for my $mode (@{ $config{evil_modes} }) {
		my $dir = File::Spec->catdir("$tmp", "writable-$mode");
		mkdir($dir, $mode) or die "cannot make $dir: $!";
		chmod($mode, $dir);

		($ok, $why) = Class::Shared::ensure_dir($dir);
		is($ok, 0, sprintf('mode %04o is refused', $mode));
		is($why, sprintf($err->{dir_unsafe}, $dir),
			sprintf('mode %04o gives the documented reason', $mode));
	}

	# Given as UTF-8 bytes: macOS refuses a file name that is not valid UTF-8.
	my $wide = File::Spec->catdir("$tmp", "\xc3\xbc\xc3\x9f");
	($ok, $why) = Class::Shared::ensure_dir($wide);
	is($ok, 1, 'a multibyte directory name is created');
	ok(-d $wide, 'and exists without character corruption');
};

subtest 'ensure_dir: failure partitions' => sub {
	my $err = $config{err};

	my $file = write_bytes('plain-file', 'not a directory');
	my ($ok, $why) = Class::Shared::ensure_dir($file);
	is($ok, 0, 'a path that is a plain file is refused');
	like($why, qr/\Acannot create \Q$file\E: /, 'the reason names the file and the system error');

	my $orphan = File::Spec->catdir("$tmp", 'absent', 'child');
	($ok, $why) = Class::Shared::ensure_dir($orphan);
	is($ok, 0, 'a missing parent is refused: only the last part is created');
	like($why, qr/\Acannot create \Q$orphan\E: /, 'the reason names the directory it could not create');

	dies_with(sub { Class::Shared::ensure_dir('') },
		$err->{no_dir}, 'the empty string (length 0) is outside the domain');
	dies_with(sub { Class::Shared::ensure_dir(undef) },
		$err->{no_dir}, 'undef is outside the domain');
};

subtest 'read_secret: size boundaries' => sub {
	my $err = $config{err};
	my $max = $Class::Shared::MAX_SECRET;

	my $empty = write_bytes('secret-empty', '');
	dies_with(sub { Class::Shared::read_secret($empty) },
		sprintf($err->{token_empty}, $empty), '0 bytes is outside the domain');

	my $one = write_bytes('secret-one', 'a');
	is(Class::Shared::read_secret($one), 'a', '1 byte, the minimum, is accepted');

	my $below = write_bytes('secret-below', 'b' x ($max - 1));
	is(length(Class::Shared::read_secret($below)), $max - 1, 'maximum - 1 bytes is accepted');

	my $at_max = write_bytes('secret-max', 'c' x $max);
	is(length(Class::Shared::read_secret($at_max)), $max, 'the maximum is accepted in full');

	my $over = write_bytes('secret-over', 'd' x ($max + 1));
	dies_with(sub { Class::Shared::read_secret($over) },
		sprintf($err->{token_too_large}, $over, $max),
		'maximum + 1 bytes is refused with the documented message');
};

subtest 'read_secret: whitespace partitions' => sub {
	my $err = $config{err};

	my $trimmed = write_bytes('secret-trim', "  secret \t\r\n\n");
	is(Class::Shared::read_secret($trimmed), '  secret',
		'trailing white space and new lines are removed, leading white space is kept');

	my $crlf = write_bytes('secret-crlf', "secret\r\n");
	is(Class::Shared::read_secret($crlf), 'secret', 'a CRLF ending is removed');

	my $blank = write_bytes('secret-blank', "\n\t \r\n");
	dies_with(sub { Class::Shared::read_secret($blank) },
		sprintf($err->{token_empty}, $blank),
		'a whitespace-only file is empty after trimming and is refused');

	my $at_max = write_bytes('secret-blank-max', ' ' x $Class::Shared::MAX_SECRET);
	dies_with(sub { Class::Shared::read_secret($at_max) },
		sprintf($err->{token_empty}, $at_max),
		'maximum size with minimum content is still refused as empty');
};

subtest 'read_secret: content and multibyte partitions' => sub {
	my $word = "Gr\xc3\xbc\xc3\x9fe \xf0\x9f\x98\x80";
	my $path = write_bytes('secret-utf8', $config{utf8_secret});
	my $secret = Class::Shared::read_secret($path);

	is($secret, $word, 'UTF-8 bytes, including an emoji, are returned exactly');
	is(length($secret), length($word), 'the length is the byte length of the file');
	ok(!utf8::is_utf8($secret), 'the secret stays a byte string, not a character string');

	my $nul = write_bytes('secret-nul', "a\0b");
	is(Class::Shared::read_secret($nul), "a\0b", 'an embedded NUL is just another byte');
	is(length(Class::Shared::read_secret($nul)), 3, 'and it is not trimmed');

	my $max = $Class::Shared::MAX_SECRET;
	my $wide = "\xc3\xbc" x ($max / 2);
	is(length($wide), $max, 'a multibyte secret fills exactly the maximum in bytes');
	is(length(Class::Shared::read_secret(write_bytes('secret-wide-max', $wide))), $max,
		'a multibyte secret at the maximum is read in full, not truncated by character length');
};

subtest 'read_secret: path failure partitions' => sub {
	my $err = $config{err};

	my $missing = File::Spec->catfile("$tmp", 'no-such-secret');
	dies_like(sub { Class::Shared::read_secret($missing) },
		qr/\A\QClass::Shared: cannot read \E\Q$missing\E: /,
		'a file that does not exist is refused, naming it');

	dies_like(sub { Class::Shared::read_secret("$tmp") },
		qr/\A\QClass::Shared: cannot read \E\Q$tmp\E: /,
		'a directory is refused, naming it');

	dies_with(sub { Class::Shared::read_secret('') },
		$err->{no_token_file}, 'the empty path (length 0) is outside the domain');
	dies_with(sub { Class::Shared::read_secret(undef) },
		$err->{no_token_file}, 'undef is outside the domain');
};

subtest 'poll_pause: return and duration' => sub {
	my $start = Time::HiRes::time();
	my @returned = Class::Shared::poll_pause();
	my $elapsed = Time::HiRes::time() - $start;

	is(scalar @returned, 0, 'it returns nothing');
	cmp_ok($elapsed, '>=', $config{poll_interval} * $config{poll_tolerance},
		'it waits about one polling interval');
	cmp_ok($elapsed, '<', $config{timing_ceiling}, 'and does not wait for long');
};

subtest 'client_tls_options: ca partition' => sub {
	my %options = Class::Shared::client_tls_options(
		cert => 'client.pem',
		key  => 'client-key.pem',
		ca   => 'ca.pem',
	);

	is_deeply([ sort keys %options ],
		[ sort qw(SSL_ca_file SSL_cert_file SSL_key_file SSL_verify_mode SSL_version) ],
		'a CA gives exactly the five documented options');

	is($options{SSL_cert_file}, 'client.pem', 'the client certificate is passed through');
	is($options{SSL_key_file}, 'client-key.pem', 'the client key is passed through');
	is($options{SSL_ca_file}, 'ca.pem', 'the CA is used when there is no pin');
	is($options{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(),
		'the peer is always verified');
	is($options{SSL_version}, $Class::Shared::TLS_VERSIONS,
		'both ends offer the same TLS versions');
	ok(!exists $options{SSL_fingerprint}, 'no pin is set');
	ok(!exists $options{SSL_force_fingerprint}, 'a pin is not forced');

	my @flat = Class::Shared::client_tls_options(cert => 'c.pem', key => 'k.pem', ca => 'ca.pem');
	is(scalar(@flat) % 2, 0, 'the answer is a flat list of name and value pairs');
};

subtest 'client_tls_options: pin partition' => sub {
	my $pin = $config{sha256_prefix} . ($config{pin_byte} x $config{sha256_bytes});

	my %options = Class::Shared::client_tls_options(
		cert        => 'client.pem',
		key         => 'client-key.pem',
		fingerprint => $pin,
	);

	is_deeply([ sort keys %options ], [ sort qw(
		SSL_cert_file SSL_fingerprint SSL_force_fingerprint
		SSL_key_file SSL_verify_mode SSL_verifycn_scheme SSL_version
	) ], 'a pin gives exactly the seven documented options');

	is($options{SSL_fingerprint}, $pin, 'the pin is used as given');
	ok($options{SSL_force_fingerprint}, 'the fingerprint is forced');
	is($options{SSL_verifycn_scheme}, 'none', 'the certificate name is not checked: the pin names it');
	ok(!exists $options{SSL_ca_file}, 'no CA is set when a pin is used');

	my %both = Class::Shared::client_tls_options(
		cert        => 'client.pem',
		key         => 'client-key.pem',
		ca          => 'ca.pem',
		fingerprint => $pin,
	);
	ok(!exists $both{SSL_ca_file},
		'when both are given the pin wins, as documented: the caller is warned by the frontend');
	is($both{SSL_fingerprint}, $pin, 'and the pin is still the one used');

	my %bare = Class::Shared::client_tls_options(cert => 'c.pem', key => 'k.pem');
	ok(!defined $bare{SSL_ca_file},
		'no CA and no pin is accepted by this function, leaving SSL_ca_file undefined');
	ok(!exists $bare{SSL_fingerprint}, 'and no pin is invented');
	is($bare{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(),
		'verification is on even when no trust anchor is given');

	my $wide = "/etc/\x{fc}/\x{1F600}/client.pem";
	my %wide_options = Class::Shared::client_tls_options(cert => $wide, key => 'k.pem', ca => 'ca.pem');
	is($wide_options{SSL_cert_file}, $wide, 'a multibyte certificate path is passed through unchanged');
};

subtest 'Protocol: multibyte and character domains' => sub {
	my $text = "Gr\x{fc}\x{df}e \x{1F600}\x{1F525} "
		. ("\x{0336}\x{0337}\x{0316}" x $config{zalgo_repeats})
		. " \x{202E}rtl\x{202C} \x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F467}";
	my $message = {
		text            => $text,
		"\x{fc}nicode"  => "\x{1F4A9}",
		nested          => [ "\x{00E9}", { "\x{05D0}" => "\x{05D1}" } ],
	};

	my ($bytes, $encode_error) = Class::Shared::Protocol::encode_frame($message);
	ok(defined $bytes, 'a message full of multibyte text encodes');
	is($encode_error, undef, 'without an error');

	my ($back, $decode_error) = Class::Shared::Protocol::take_payload(substr($bytes, 4));
	is($decode_error, undef, 'and decodes without an error');
	is_deeply($back, $message, 'every character, key and nested value survives exactly');
	is($back->{text}, $text, 'the text is identical, not merely similar');

	my $char_length = length $text;
	my $byte_length = length Encode::encode_utf8($text);
	cmp_ok($byte_length, '>', $char_length, 'the UTF-8 form needs more bytes than characters');
	is(length($back->{text}), $char_length, 'length still counts characters after the round trip');
	ok(utf8::is_utf8($back->{text}), 'the round trip does not downgrade the character string');
	cmp_ok(length($bytes) - 4, '>', $byte_length, 'the frame carries the bytes plus Storable overhead');
};

subtest 'Protocol: frame size boundaries' => sub {
	my $err = $config{err};
	my $max = $Class::Shared::Protocol::MAX_FRAME;
	my $digest = $Class::Shared::Protocol::DIGEST_SIZE;

	my $padding = 'x' x 8;
	my $at_max = pack('N', $max) . $padding;
	my @taken = Class::Shared::Protocol::take_frame(\$at_max);
	is($taken[0], 0, 'a body of exactly the maximum is inside the limit and waits for its bytes');
	is($taken[2], undef, 'with no error');

	my $over = pack('N', $max + 1) . $padding;
	@taken = Class::Shared::Protocol::take_frame(\$over);
	is($taken[0], -1, 'maximum + 1 is refused');
	is($taken[2], sprintf($err->{frame_limit}, $max + 1, $max),
		'with the documented limit message');

	my $secret = 'a shared secret';
	my $room = $max + $digest;
	my $with_digest = pack('N', $room) . $padding;
	@taken = Class::Shared::Protocol::take_frame(\$with_digest, $secret);
	is($taken[0], 0, 'with a secret the body may be exactly the maximum plus the digest');

	my $over_digest = pack('N', $room + 1) . $padding;
	@taken = Class::Shared::Protocol::take_frame(\$over_digest, $secret);
	is($taken[0], -1, 'one byte more than the maximum plus the digest is refused');
	is($taken[2], sprintf($err->{frame_limit}, $room + 1, $room),
		'and the limit in the message includes the digest');

	for my $length (0 .. 3) {
		my $buffer = 'x' x $length;
		my @short = Class::Shared::Protocol::take_frame(\$buffer);
		is($short[0], 0, "a header of $length bytes asks for more");
		is($buffer, 'x' x $length, 'and the partial header is kept');
	}
};

subtest 'Protocol: authentication and body boundaries' => sub {
	my $err = $config{err};
	my $digest = $Class::Shared::Protocol::DIGEST_SIZE;

	my $empty = pack('N', 0);
	my @taken = Class::Shared::Protocol::take_frame(\$empty);
	is($taken[0], -1, 'a frame with no body is not a Storable image');
	like($taken[2], qr/\A\Q$err->{deserialise}\E/, 'and says it cannot deserialise it');

	my $short = pack('N', $digest - 1) . ('x' x ($digest - 1));
	@taken = Class::Shared::Protocol::take_frame(\$short, 'secret');
	is($taken[0], -1, 'a payload shorter than the digest is refused');
	is($taken[2], $err->{short_digest}, 'with the documented message');

	my $zero_digest = pack('N', $digest) . ("\0" x $digest);
	@taken = Class::Shared::Protocol::take_frame(\$zero_digest, 'secret');
	is($taken[0], -1, 'a digest of the wrong value is refused');
	is($taken[2], $err->{failed_digest}, 'with the documented message');

	my ($bytes) = Class::Shared::Protocol::encode_frame({ op => 'ping' }, 'right secret');
	my $wrong = $bytes;
	@taken = Class::Shared::Protocol::take_frame(\$wrong, 'wrong secret');
	is($taken[0], -1, 'a frame signed with another secret is refused');
	is($taken[2], $err->{failed_digest}, 'with the documented message');
	is($wrong, '', 'the bytes are discarded, not left to be thawed');

	my $good = $bytes;
	@taken = Class::Shared::Protocol::take_frame(\$good, 'right secret');
	is($taken[0], 1, 'the same frame with the right secret is accepted');
	is_deeply($taken[1], { op => 'ping' }, 'and carries the message');
};

subtest 'Protocol: read_frame boundaries' => sub {
	my $err = $config{err};
	my $max = $Class::Shared::Protocol::MAX_FRAME;

	my ($bytes) = Class::Shared::Protocol::encode_frame({ op => 'ping' });
	my $file = write_bytes('frame', $bytes);
	open(my $fh, '<:raw', $file) or die "cannot read $file: $!";
	my ($message, $error) = Class::Shared::Protocol::read_frame($fh);
	close($fh);
	is($error, undef, 'a whole frame is read without an error');
	is_deeply($message, { op => 'ping' }, 'and is the message that was written');

	my $at_max = write_bytes('frame-at-max', pack('N', $max));
	open(my $limit_fh, '<:raw', $at_max) or die "cannot read $at_max: $!";
	my ($none, $limit_error) = Class::Shared::Protocol::read_frame($limit_fh, 0);
	close($limit_fh);
	is($none, undef, 'a header at exactly the maximum is accepted as a length');
	is($limit_error, $err->{closed}, 'and fails only because the body is missing');

	my $over_max = write_bytes('frame-over-max', pack('N', $max + 1));
	open(my $over_fh, '<:raw', $over_max) or die "cannot read $over_max: $!";
	($none, $limit_error) = Class::Shared::Protocol::read_frame($over_fh, 0);
	close($over_fh);
	is($limit_error, sprintf($err->{frame_limit}, $max + 1, $max),
		'a header of maximum + 1 is refused before any body is read');

	pipe(my $reader, my $writer) or die "cannot make a pipe: $!";
	($none, $error) = Class::Shared::Protocol::read_frame($reader, 0);
	is($none, undef, 'a timeout is not a message');
	is($error, $err->{timeout}, 'a timeout of 0 with no data gives the documented message');

	close($writer);
	($none, $error) = Class::Shared::Protocol::read_frame($reader, 0);
	is($error, $err->{closed}, 'a closed peer gives the documented message');
	close($reader);
};

subtest 'Protocol: write_all domains' => sub {
	my $err = $config{err};

	pipe(my $reader, my $writer) or die "cannot make a pipe: $!";
	my ($ok) = Class::Shared::Protocol::write_all($writer, 'hello');
	is($ok, 1, 'a writable handle accepts the bytes');

	my $got = '';
	my $read = sysread($reader, $got, 5);
	is($read, 5, 'every byte was written');
	is($got, 'hello', 'and they are the bytes that were given');

	my ($empty_ok) = Class::Shared::Protocol::write_all($writer, '');
	is($empty_ok, 1, 'an empty string (length 0) is a successful write of nothing');

	close($reader);
	my ($closed_ok, $closed_error) = Class::Shared::Protocol::write_all($writer, 'x');
	is($closed_ok, 0, 'a peer that has gone away is a failure, not a signal');
	like($closed_error, qr/\A\Q$err->{write_failed}\E/, 'with the documented prefix');
	close($writer);
};

subtest 'Protocol: serialisation failure partitions' => sub {
	my $err = $config{err};

	my ($bytes, $error) = Class::Shared::Protocol::encode_frame({ callback => sub { 1 } });
	is($bytes, undef, 'a code reference cannot be sent');
	like($error, qr/\A\Q$err->{serialise}\E/, 'with the documented prefix');

	($bytes, $error) = Class::Shared::Protocol::encode_frame('a plain string');
	is($bytes, undef, 'a message that is not a reference is refused');
	like($error, qr/\A\Q$err->{serialise}\E/, 'with the documented prefix');

	($bytes, $error) = Class::Shared::Protocol::encode_frame(undef);
	is($bytes, undef, 'undef is outside the message domain');
	like($error, qr/\A\Q$err->{serialise}\E/, 'and is reported, not ignored');

	my ($message, $decode_error) = Class::Shared::Protocol::take_payload('not a storable image');
	is($message, undef, 'garbage is not a message');
	like($decode_error, qr/\A\Q$err->{deserialise}\E/, 'with the documented prefix');

	my ($good) = Class::Shared::Protocol::encode_frame({ op => 'ping' });
	($message, $decode_error) = Class::Shared::Protocol::take_payload(substr($good, 4, length($good) - 5));
	is($message, undef, 'a truncated image is not a message');
	like($decode_error, qr/\A\Q$err->{deserialise}\E/, 'and is reported as one that cannot be read');
};

subtest 'Frontend->new: option name domain' => sub {
	my $err = $config{err};

	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', bogus => 1) },
		sprintf($err->{fe_unknown}, 'bogus'), 'an unknown option is refused by name');
	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', 'odd') },
		$err->{fe_odd}, 'an odd number of arguments is refused');
	dies_with(sub { Class::Shared::Frontend->new({ class => 'Class::Simple', bogus => 1 }) },
		sprintf($err->{fe_unknown}, 'bogus'), 'the hash reference form is checked too');
};

subtest 'Frontend->new: class and ctor domains' => sub {
	my $err = $config{err};

	dies_with(sub { Class::Shared::Frontend->new() },
		$err->{fe_no_class}, 'no class is outside the domain');
	dies_with(sub { Class::Shared::Frontend->new('') },
		$err->{fe_no_class}, 'the empty class name (length 0) is outside the domain');
	dies_with(sub { Class::Shared::Frontend->new(undef) },
		$err->{fe_no_class}, 'undef is outside the domain');

	dies_with(sub { Class::Shared::Frontend->new('2Bad') },
		sprintf($err->{bad_class}, '2Bad'), 'a leading digit is refused by validate_class');
	dies_with(sub { Class::Shared::Frontend->new('Foo::') },
		sprintf($err->{bad_class}, 'Foo::'), 'a trailing separator is refused');
	dies_with(sub { Class::Shared::Frontend->new("M\x{fc}ller") },
		sprintf($err->{bad_class}, "M\x{fc}ller"), 'a multibyte class name is refused unchanged');

	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', ctor => 'not-an-array') },
		$err->{fe_ctor}, 'a string ctor is refused');
	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', ctor => {}) },
		$err->{fe_ctor}, 'a hash reference ctor is refused');
};

subtest 'Frontend->new: transport combination domain' => sub {
	my $err = $config{err};

	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', token => 'secret') },
		$err->{fe_unix_token}, 'a token on a unix socket is refused: the mode already authenticates');
	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', token_file => '/tmp/token') },
		$err->{fe_unix_token}, 'a token file on a unix socket is refused');

	for my $option (qw(tls_cert tls_key tls_ca tls_fingerprint)) {
		dies_with(sub { Class::Shared::Frontend->new('Class::Simple', $option => 'value') },
			$err->{fe_unix_tls}, "$option on a unix socket is refused");
	}

	dies_with(sub {
		Class::Shared::Frontend->new('Class::Simple',
			host => 'example.test', port => $config{port_min},
			token => 'a', token_file => '/tmp/token');
	}, $err->{fe_two_tokens}, 'a token and a token file are mutually exclusive');

	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', host => 'example.test') },
		$err->{fe_tcp_both}, 'a host without a port is refused');
	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', port => $config{port_min}) },
		$err->{fe_tcp_both}, 'a port without a host is refused');

	dies_with(sub {
		Class::Shared::Frontend->new('Class::Simple',
			host => 'example.test', port => $config{port_min}, socket => '/tmp/s');
	}, $err->{fe_socket_both}, 'a socket together with host and port is refused');

	dies_with(sub {
		Class::Shared::Frontend->new('Class::Simple',
			host => 'example.test', port => $config{port_min});
	}, $err->{fe_tls_pair}, 'TCP without a client certificate and key is refused');
	dies_with(sub {
		Class::Shared::Frontend->new('Class::Simple',
			host => 'example.test', port => $config{port_min}, tls_cert => 'c.pem');
	}, $err->{fe_tls_pair}, 'TCP without a key is refused');
	dies_with(sub {
		Class::Shared::Frontend->new('Class::Simple',
			host => 'example.test', port => $config{port_min}, tls_cert => '', tls_key => 'k.pem');
	}, $err->{fe_tls_pair}, 'an empty certificate (length 0) is outside the domain');

	dies_with(sub {
		Class::Shared::Frontend->new('Class::Simple',
			host => 'example.test', port => $config{port_min},
			tls_cert => 'c.pem', tls_key => 'k.pem');
	}, $err->{fe_tls_trust}, 'TCP without a CA or a pin cannot verify the backend');

	dies_with(sub {
		Class::Shared::Frontend->new('Class::Simple',
			host => 'example.test', port => $config{port_min},
			tls_cert => 'c.pem', tls_key => 'k.pem', tls_ca => '');
	}, $err->{fe_tls_trust}, 'an empty CA (length 0) is outside the domain');

	my $pin = $config{sha256_prefix} . ($config{pin_byte} x $config{sha256_bytes});
	dies_with(sub {
		Class::Shared::Frontend->new('Class::Simple',
			host => 'example.test', port => $config{port_min},
			tls_cert => 'c.pem', tls_key => 'k.pem',
			tls_ca => 'ca.pem', tls_fingerprint => $pin);
	}, $err->{fe_tls_both}, 'a CA and a pin are alternatives, not both');
};

subtest 'Frontend->new: port domain' => sub {
	my $err = $config{err};

	my @outside = ('', 0, -1, $config{port_max} + 1, 'eighty', '80x', ' 80', '80.0', "\x{fc}");
	for my $port (@outside) {
		my $shown = $port =~ /\A[0-9]+\z/ ? $port : "'$port'";
		dies_with(sub {
			Class::Shared::Frontend->new('Class::Simple', host => 'example.test', port => $port);
		}, $err->{fe_port}, "port $shown is outside 1 .. $config{port_max}");
	}

	is($config{port_max}, 65_535, 'the documented maximum port is 65535');

	for my $port ($config{port_min}, $config{port_max}, '0080') {
		dies_with(sub {
			Class::Shared::Frontend->new('Class::Simple', host => 'example.test', port => $port);
		}, $err->{fe_tls_pair},
			"port $port is inside the domain and passes to the next missing option");
	}

	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', host => 'h', port => 0) },
		$err->{fe_port}, 'a port below the minimum is refused once a host is present');

	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', port => $config{port_max} + 1) },
		$err->{fe_tcp_both}, 'a missing host is reported before the port is checked');
};

subtest 'detach_standard_streams: log domain' => sub {
	my $log = File::Spec->catfile("$tmp", 'backend.log');

	my $status = detach_in_child($log);
	plan skip_all => 'cannot fork on this platform' unless defined $status;
	is($status, 0, 'a writable log returns success');
	ok(-e $log, 'and the log file was created');

	my $absent = File::Spec->catfile("$tmp", 'absent', 'backend.log');
	is(detach_in_child($absent), 0,
		'a log that cannot be opened still succeeds, sending the streams to the null device');
};

subtest 'documented limits and process state' => sub {
	is($Class::Shared::MAX_SOCKET_PATH, $config{max_socket_path},
		'the socket path limit is 100 characters');
	is($Class::Shared::MAX_SECRET, $config{max_secret},
		'the secret limit is 65536 bytes');
	is($Class::Shared::POLL_INTERVAL, $config{poll_interval},
		'the polling interval is 0.02 seconds');
	is($Class::Shared::Protocol::MAX_FRAME, $config{max_frame},
		'the frame limit is 64 MiB');
	is($Class::Shared::Protocol::DIGEST_SIZE, $config{digest_size},
		'the digest is 32 bytes');

	is(Cwd::getcwd(), $config{cwd}, 'the working directory is unchanged by any failure above');
	is($ENV{CLASS_SHARED_DIR}, $config{env_dir}, 'CLASS_SHARED_DIR is restored');
	is($ENV{XDG_RUNTIME_DIR}, $config{env_xdg}, 'XDG_RUNTIME_DIR is restored');

	ok(-d "$tmp", 'no failure removed the temporary directory');
	is(join(':', (stat(STDOUT))[0, 1]), $config{stdout_id},
		'STDOUT still belongs to the test process: only the children detached theirs');
};

done_testing();
