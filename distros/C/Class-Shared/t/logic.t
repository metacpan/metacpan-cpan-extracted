#!/usr/bin/env perl

# Logic proofs for Class::Shared, Class::Shared::Frontend and
# Class::Shared::Protocol, derived from the Z schemas in their POD.
#
# Each subtest is one logical rule:
#
#   * a schema's pre- and postcondition, proved as an equivalence over a
#     generated domain (not a sample): "out! = value(x) <=> P(x)";
#   * a truth table, with every combination of the boolean inputs;
#   * an invariant, asserted before, during and after the operation;
#   * a contradiction: a state the documentation calls impossible, which a
#     guard clause must reject before anything is done.
#
# The file is ASCII only.  Non-ASCII test data is written with \x{...}.
# Package variables that a proof changes are changed with "local", so a
# failing proof cannot change the next one.

use strict;
use warnings;

use Config ();
use Cwd ();
use Digest::SHA ();
use File::Basename ();
use File::Spec ();
use File::Temp ();
use IO::Socket::SSL ();
use Storable ();
use Test::Most;

use lib 't/lib';

use Class::Shared;
use Class::Shared::Frontend;
use Class::Shared::Protocol;

# Some proofs need a unix socket, and the directory ones need it in a directory
# only its owner can write to.  Those subtests ask here and skip in place, one
# at a time, so a perl the module cannot be used on still proves everything that
# does not touch the platform: class names, fingerprints, frames and Storable.
my $has_unix_sockets = Class::Shared::_has_unix_sockets();
my $owner_only_dir = eval {
	require Test::Permissions;
	Test::Permissions::can_revoke_create();
} ? 1 : 0;

my %config = (
	# Limits, copied from the Z basic types; the module's own variables are
	# asserted against these in the last subtest.
	max_socket_path => 100,
	max_secret      => 65_536,
	digest_size     => 32,
	sha256_bytes    => 32,
	class_probe_max => 4,
	class_alphabet  => [ 'A', '_', ':', '1' ],
	group_write_bit => 0020,
	other_write_bit => 0002,
	owner_write_bit => 0200,
	base_mode       => 0500,
	create_mode     => 0700,
	timing_ceiling  => 5,
	socket_name     => 'class-shared.sock',
	sha256_prefix   => 'sha256$',
	colon_separator => ':',
	pin_byte        => 'ab',
	err             => {
		no_class        => 'Class::Shared: no class name given',
		bad_class       => q{Class::Shared: '%s' is not a valid class name},
		no_fingerprint  => 'Class::Shared: no TLS fingerprint given',
		bad_fingerprint => q{Class::Shared: '%s' is not a SHA-256 certificate fingerprint: }
			. 'give 64 hexadecimal digits, optionally colon-separated',
		no_socket    => 'Class::Shared: no socket path given',
		socket_long  => q{Class::Shared: socket path '%s' is %d characters, more than the %d allowed; }
			. 'set CLASS_SHARED_DIR or pass dir => to a shorter directory',
		no_dir       => 'Class::Shared: no directory given',
		dir_unsafe   => '%s is writable by group or others; refusing to use it',
		no_token     => 'Class::Shared: no token file given',
		token_empty  => 'Class::Shared: %s is empty',
		token_large  => 'Class::Shared: %s is too large to be a secret (more than %d bytes)',
		unix_missing => 'Class::Shared: %s is not available here: this perl has no unix '
			. 'domain sockets, so a backend could neither be reached nor started.  '
			. 'This distribution is Unix-only (see PLATFORMS)',
		nul_dir       => 'Class::Shared: a directory name may not contain a NUL byte',
		frame_limit   => 'frame of %d bytes exceeds the limit of %d',
		message_large => 'message is too large (%d bytes, limit is %d)',
		failed_digest => 'frame failed authentication',
		short_digest  => 'frame is too short to be authenticated',
		serialise     => 'cannot serialise message: ',
		deserialise   => 'cannot deserialise message: ',
		fe_unknown    => q{Class::Shared::Frontend->new: unknown option '%s'},
		fe_no_class   => 'Class::Shared::Frontend->new: no class name given',
		fe_unix_token => 'Class::Shared::Frontend->new: a unix socket needs no token: '
			. $Class::Shared::UNIX_TRUST_REASON,
		fe_unix_tls => 'Class::Shared::Frontend->new: a unix socket needs no TLS: '
			. $Class::Shared::UNIX_TRUST_REASON,
		fe_two_tokens  => 'Class::Shared::Frontend->new: give token or token_file, not both',
		fe_tcp_both    => 'Class::Shared::Frontend->new: a TCP backend needs both host and port',
		fe_socket_both => 'Class::Shared::Frontend->new: use either socket or host/port, not both',
		fe_tls_pair    => 'Class::Shared::Frontend->new: a TCP backend needs tls_cert and tls_key: '
			. 'the backend will not accept a client it cannot verify',
		fe_tls_trust => 'Class::Shared::Frontend->new: a TCP backend needs tls_ca or tls_fingerprint: '
			. 'without one it cannot verify the backend',
		fe_tls_both => 'Class::Shared::Frontend->new: give tls_ca or tls_fingerprint, not both: '
			. 'a CA and a pin are alternatives',
	},
);

$config{class_name_re} = qr/\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/;
$config{fingerprint_re} = qr/\A(?:sha256\$)?(?:(?:[0-9A-Fa-f]{2}:){31}[0-9A-Fa-f]{2}|[0-9A-Fa-f]{64})\z/;
$config{cwd}      = Cwd::getcwd();
$config{env_dir}  = $ENV{CLASS_SHARED_DIR};
$config{env_xdg}  = $ENV{XDG_RUNTIME_DIR};
$config{max_frame} = $Class::Shared::Protocol::MAX_FRAME;

my $tmp = File::Temp->newdir('class-shared-logic-XXXXXX', TMPDIR => 1, CLEANUP => 1);

my $hex64 = join('', map { sprintf '%02x', $_ } 1 .. $config{sha256_bytes});
my @pairs = $hex64 =~ /(..)/g;
my $colon64 = join($config{colon_separator}, @pairs);
my $pin = $config{sha256_prefix} . ($config{pin_byte} x $config{sha256_bytes});

# ---------------------------------------------------------------- helpers

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

sub read_mode {
	my ($path) = @_;
	my @stat = stat($path) or return;

	return $stat[2] & 07777;
}

sub make_dir_with_mode {
	my ($name, $mode) = @_;
	my $dir = File::Spec->catdir("$tmp", $name);

	mkdir($dir, $config{create_mode}) or die "cannot make $dir: $!";
	chmod($mode, $dir) or die "cannot chmod $dir: $!";

	return $dir;
}

# The Z grammar for CLASSNAME, used as a separate oracle: the code checks the
# characters and then each word, so agreement on every short string shows the
# two-step check computes the same set.
sub class_oracle {
	my ($value) = @_;

	return $value =~ $config{class_name_re} ? 1 : 0;
}

sub fingerprint_oracle_value {
	my ($value) = @_;

	my $rest = $value =~ /\Asha256\$(.*)\z/s ? $1 : $value;
	$rest =~ s/://g;

	return $config{sha256_prefix} . lc $rest;
}

# TakeFrame's status algebra: one of -1, 0, 1; a message exactly when 1, an
# error exactly when -1.
sub assert_take_law {
	my ($status, $message, $error, $label) = @_;

	ok($status == -1 || $status == 0 || $status == 1, "$label: status is in {-1, 0, 1}");
	is(defined($message) ? 1 : 0, $status == 1 ? 1 : 0, "$label: a message iff status 1");
	is(defined($error) ? 1 : 0, $status == -1 ? 1 : 0, "$label: an error iff status -1");

	return;
}

sub frame_for {
	my ($body, $secret) = @_;

	return defined $secret
		? pack('N', $config{digest_size} + length $body)
			. Digest::SHA::hmac_sha256($body, $secret) . $body
		: pack('N', length $body) . $body;
}

# A proof that needs the platform asks first and returns at once when the
# answer is no: plan skip_all says why, and the return stops the proof before
# it touches anything, so nothing after the 1..0 line can run.
sub skipped_without_unix {
	my ($what) = @_;

	return 0 if $has_unix_sockets;

	plan skip_all => "the $what proof needs a unix socket, which this perl "
		. 'cannot make (Class::Shared is Unix-only)';

	return 1;
}

sub skipped_without_owner_only_dir {
	my ($what) = @_;

	return 0 if $has_unix_sockets && $owner_only_dir;

	plan skip_all => "the $what proof needs a unix socket in a directory only "
		. 'its owner can write to, which this perl cannot provide '
		. '(Class::Shared is Unix-only)';

	return 1;
}

# ---------------------------------------------------------------- subtests

subtest 'Syllogism: a class name is valid iff its characters and every word are' => sub {
	# Major premise: CLASSNAME == words over IDENT joined by "::".  The code
	# checks the character set first and the word grammar second, so the
	# conjunction must agree with the one-regex grammar on every string.
	local $@;

	my $alphabet = $config{class_alphabet};
	for my $length (1 .. $config{class_probe_max}) {
		my $total = (scalar @{$alphabet}) ** $length;
		my $agree = 0;
		my @wrong;

		for my $n (0 .. $total - 1) {
			my ($value, $x) = ('', $n);
			for (1 .. $length) {
				$value .= $alphabet->[ $x % @{$alphabet} ];
				$x = int($x / @{$alphabet});
			}

			my $expected = class_oracle($value);
			my $accepted = defined eval { Class::Shared::validate_class($value); 1 } ? 1 : 0;
			$agree++ if $accepted == $expected;
			push @wrong, $value if $accepted != $expected;
		}

		is($agree, $total,
			"all $total strings of length $length agree with the CLASSNAME grammar");
		is_deeply(\@wrong, [], "no counterexample of length $length") if @wrong;
	}

	# The longer strings, outside the generated set, against the same oracle.
	for my $value ('A', '_', 'A::B', 'A::_2', 'A::', '::A', 'A:::B', '2Foo', 'A-B', 'A B') {
		my $expected = class_oracle($value);
		my $accepted = defined eval { Class::Shared::validate_class($value); 1 } ? 1 : 0;
		is($accepted, $expected, "code and grammar agree on '$value'");
		is(Class::Shared::validate_class($value), $value, "'$value' is returned unchanged")
			if $expected;
	}

	# Length 0 is the only string the oracle cannot see: the code names it
	# separately, with its own message.
	dies_with(sub { Class::Shared::validate_class('') },
		$config{err}{no_class}, 'length 0 is refused as "no name", not as a bad name');

	# Idempotence: validating an already-valid name is the identity.
	my $valid = Class::Shared::validate_class('A::B');
	is(Class::Shared::validate_class($valid), $valid, 'validate_class is idempotent');
};

subtest 'Syllogism: rejection means a bad character or an empty word, never both' => sub {
	my $err = $config{err};

	# Strings whose characters are all allowed but whose words are not: only
	# the second step can reject them, so they prove the second step runs.
	my @bad_words = ('::A', 'A:::B', ':A', 'A::');
	for my $value (@bad_words) {
		my $chars_ok = $value =~ /\A[A-Za-z0-9_:]+\z/ ? 1 : 0;
		is($chars_ok, 1, "'$value' passes the character predicate");
		dies_with(sub { Class::Shared::validate_class($value) },
			sprintf($err->{bad_class}, $value),
			"'$value' is rejected by the word predicate alone");
	}

	# Strings that fail the character predicate, so the first step rejects
	# them before any word is looked at.  The labels stay ASCII: a test name
	# with a wide character would corrupt the TAP stream.
	my @bad_chars = (
		[ 'hyphen',  'A-B' ],
		[ 'space',   'A B' ],
		[ 'umlaut',  "A\x{fc}" ],
		[ 'emoji',   "A\x{1F600}" ],
		[ 'newline', "A\n" ],
		[ 'dot',     'A.B' ],
	);
	for my $case (@bad_chars) {
		my ($label, $value) = @{$case};
		my $chars_ok = $value =~ /\A[A-Za-z0-9_:]+\z/ ? 1 : 0;
		is($chars_ok, 0, "$label: fails the character predicate");
		dies_with(sub { Class::Shared::validate_class($value) },
			sprintf($err->{bad_class}, $value),
			"$label: the same message, so there is one error surface for two causes");
	}
};

subtest 'NormaliseFingerprint: value in FP <=> sha256$ + lower(strip_colons(value))' => sub {
	my $err = $config{err};
	my $prefix = $config{sha256_prefix};

	my @cases = (
		[ '64 lower hex',              $hex64 ],
		[ '64 upper hex',              uc $hex64 ],
		[ '32 colon pairs',            $colon64 ],
		[ '32 colon pairs upper',      uc $colon64 ],
		[ 'prefix and 64 hex',         $prefix . $hex64 ],
		[ 'prefix and 32 pairs',       $prefix . $colon64 ],
		[ '63 hex',                    substr($hex64, 0, 63) ],
		[ '65 hex',                    $hex64 . '0' ],
		[ '31 pairs',                  join($config{colon_separator}, @pairs[0 .. 30]) ],
		[ '33 pairs',                  join($config{colon_separator}, @pairs, $config{pin_byte}) ],
		[ 'upper case prefix',         'SHA256$' . $hex64 ],
		[ 'prefix alone',              $prefix ],
		[ 'spaces',                    join(' ', @pairs) ],
		[ 'empty',                     '' ],
		[ 'umlaut',                    substr($hex64, 0, 62) . "\x{fc}\x{fc}" ],
	);

	for my $case (@cases) {
		my ($name, $value) = @{$case};
		my $in_domain = $value =~ $config{fingerprint_re} ? 1 : 0;

		if ($in_domain) {
			my $got = Class::Shared::normalise_fingerprint($value);
			is($got, fingerprint_oracle_value($value),
				"$name: out! = sha256\$ + lower(strip_colons(value))");
			like($got, qr/\Asha256\$[0-9a-f]{64}\z/,
				"$name: the result is a normalised fingerprint");
			is(Class::Shared::normalise_fingerprint($got), $got,
				"$name: normalising twice is the same as once");
		} else {
			dies_with(sub { Class::Shared::normalise_fingerprint($value) },
				length($value)
					? sprintf($err->{bad_fingerprint}, $value)
					: $err->{no_fingerprint},
				"$name: outside FP, so out! = dies(_)");
		}
	}
};

subtest 'ReadSecret: out! = value(trim(file)) and files are unchanged' => sub {
	my $err = $config{err};

	my @cases = (
		[ 'one byte',        'a' ],
		[ 'one line',        "a\n" ],
		[ 'trailing blanks', "  a \t\r\n" ],
		[ 'leading blanks',  '  a' ],
		[ 'blank file',      "\n\t \r\n" ],
		[ 'empty file',      '' ],
		[ 'embedded NUL',    "a\0b" ],
		[ 'utf8 bytes',      "Gr\xc3\xbc\xc3\x9fe\n" ],
		[ 'at the maximum',  'x' x $config{max_secret} ],
		[ 'over the maximum', 'x' x ($config{max_secret} + 1) ],
	);

	for my $case (@cases) {
		my ($name, $content) = @{$case};
		my $path = write_bytes("logic-secret-$name", $content);

		my $trimmed = $content;
		$trimmed =~ s/\s+\z//;
		my $in_domain = length($content) <= $config{max_secret} && length $trimmed;

		if ($in_domain) {
			my $secret = Class::Shared::read_secret($path);
			is($secret, $trimmed, "$name: out! = trim(file)");
			unlike($secret, qr/\s\z/, "$name: the result has no trailing white space");
			cmp_ok(length($secret), '>=', 1, "$name: the result is not empty");
			cmp_ok(length($secret), '<=', $config{max_secret}, "$name: the result is within the maximum");
		} else {
			my $expected = length($content) > $config{max_secret}
				? sprintf($err->{token_large}, $path, $config{max_secret})
				: sprintf($err->{token_empty}, $path);
			dies_with(sub { Class::Shared::read_secret($path) }, $expected,
				"$name: outside the domain, so out! = dies(_)");
		}

		# The schema says files' = files: the file is still what it was.
		open(my $fh, '<:raw', $path) or die "cannot re-read $path: $!";
		local $/;
		my $after = <$fh>;
		close($fh);
		is($after, $content, "$name: the file is unchanged (files' = files)");
	}
};

subtest 'DirOf: dir! = dirname(path?) and dir! is never empty' => sub {
	my @paths = ('x.sock', '/x.sock', '/a/b/c', 'a/b/', '', '//', 'a//b', "dir\x{fc}/x.sock", '/');

	for my $path (@paths) {
		my $dir = Class::Shared::dir_of($path);
		is($dir, File::Basename::dirname($path), "dirname('$path')");
		ok(length $dir, "the answer for '$path' is not the empty string (dir! != <>)");
	}

	is(Class::Shared::dir_of('x.sock'), '.', 'no directory part gives .');
	is(Class::Shared::dir_of('/x.sock'), '/', 'a file in the root gives /');
};

subtest 'CheckSocketPath: 0 < #path <= MAXPATH <=> out! = value(path)' => sub {
	my $err = $config{err};
	my $max = $config{max_socket_path};

	my $agree = 0;
	for my $length (1 .. $max + 2) {
		my $path = '/' . ('p' x ($length - 1));
		my $expected = $length <= $max ? 1 : 0;
		my $accepted = defined eval { Class::Shared::check_socket_path($path); 1 } ? 1 : 0;

		$agree++ if $accepted == $expected;
		is(Class::Shared::check_socket_path($path), $path, "length $length is returned unchanged")
			if $expected;
	}

	is($agree, $max + 2, 'every length from 1 to MAXPATH + 2 agrees with the bound');

	dies_with(sub { Class::Shared::check_socket_path('') },
		$err->{no_socket}, 'length 0 is the other side of 0 < #path');
	dies_with(sub { Class::Shared::check_socket_path(undef) },
		$err->{no_socket}, 'bottom is outside the domain too');

	my $over = '/' . ('p' x $max);
	dies_with(sub { Class::Shared::check_socket_path($over) },
		sprintf($err->{socket_long}, $over, $max + 1, $max),
		'MAXPATH + 1 fails with the bound in the message');

	my $short = '/a';
	is(Class::Shared::check_socket_path($short), $short, 'a short path is the identity');
	is(Class::Shared::check_socket_path(Class::Shared::check_socket_path($short)), $short,
		'checking an accepted path twice changes nothing');
};

subtest 'SocketPath: #(default_dir / socket_name) <= MAXPATH <=> out! = value' => sub {
	return if skipped_without_unix('socket path');

	my $err = $config{err};
	my $name = $config{socket_name};
	my $max = $config{max_socket_path};

	my $agree = 0;
	my $probes = 0;
	for my $dir_length (60 .. $max) {
		my $dir = '/' . ('d' x ($dir_length - 1));
		my $path = File::Spec->catfile($dir, $name);
		my $expected = length($path) <= $max ? 1 : 0;
		my $accepted = defined eval { Class::Shared::socket_path($dir); 1 } ? 1 : 0;
		$probes++;
		$agree++ if $accepted == $expected;

		if ($expected) {
			is(Class::Shared::socket_path($dir), $path, "dir of $dir_length gives the composed path");
		} else {
			dies_with(sub { Class::Shared::socket_path($dir) },
				sprintf($err->{socket_long}, $path, length($path), $max),
				"dir of $dir_length exceeds the bound and dies");
		}
	}

	is($agree, $probes, 'every directory length agrees with #path <= MAXPATH');
	like(Class::Shared::socket_path('/tmp'), qr/\Q$name\E\z/, 'the socket name is fixed');
};

subtest 'EnsureDir: owner = euid and mode /\ 8#022 = 0 <=> SAFE' => sub {
	return if skipped_without_owner_only_dir('directory mode');

	my $err = $config{err};

	my ($accepted, $refused) = (0, 0);
	for my $owner_write (0, 1) {
		for my $group_write (0, 1) {
			for my $other_write (0, 1) {
				my $mode = $config{base_mode};
				$mode |= $config{owner_write_bit} if $owner_write;
				$mode |= $config{group_write_bit} if $group_write;
				$mode |= $config{other_write_bit} if $other_write;

				my $label = sprintf('mode %04o', $mode);
				my $dir = make_dir_with_mode("mode-$mode", $mode);
				my ($ok, $why) = Class::Shared::ensure_dir($dir);

				# The premise: safe means the write bits 0022 are clear.  The
				# owner's write bit must not matter.
				my $expected = ($mode & ($config{group_write_bit} | $config{other_write_bit})) ? 0 : 1;

				is($ok, $expected, "$label: SAFE iff group and other cannot write");
				if ($expected) {
					$accepted++;
					is($why, undef, "$label: true carries no reason");
					is(read_mode($dir), $mode, "$label: an existing mode is not changed");
				} else {
					$refused++;
					is($why, sprintf($err->{dir_unsafe}, $dir),
						"$label: false carries the documented reason");
				}
			}
		}
	}

	is($accepted, 2, 'the truth table has two accepting rows: owner write is irrelevant');
	is($refused, 6, 'and six refusing rows: the two write bits give 2 x 2 x 2 - 2');

	# De Morgan: refused <=> group-writable OR other-writable.
	my $gw = make_dir_with_mode('de-morgan-g', $config{create_mode} | $config{group_write_bit});
	my $ow = make_dir_with_mode('de-morgan-o', $config{create_mode} | $config{other_write_bit});
	my ($ok_g) = Class::Shared::ensure_dir($gw);
	my ($ok_o) = Class::Shared::ensure_dir($ow);
	is($ok_g, 0, 'group-writable alone is refused');
	is($ok_o, 0, 'other-writable alone is refused');
	is($ok_g && $ok_o, 0, 'refused <=> (group-writable OR other-writable)');
};

subtest 'EnsureDir state machine: MISSING -> PRESENT -> SAFE | REFUSED' => sub {
	return if skipped_without_owner_only_dir('directory state');

	my $err = $config{err};

	my $missing = File::Spec->catdir("$tmp", 'state-missing');
	ok(!-d $missing, 'MISSING: the directory does not exist before the call');
	my ($ok, $why) = Class::Shared::ensure_dir($missing);
	is($ok, 1, 'MISSING -> PRESENT -> SAFE returns true');
	ok(-d $missing, 'PRESENT: the transition created it');
	is(read_mode($missing), $config{create_mode}, 'PRESENT: it was created with mode 0700');

	my ($second) = Class::Shared::ensure_dir($missing);
	is($second, 1, 'PRESENT -> SAFE is idempotent');

	my $unsafe = make_dir_with_mode('state-unsafe', $config{create_mode} | $config{other_write_bit});
	my ($bad, $bad_why) = Class::Shared::ensure_dir($unsafe);
	is($bad, 0, 'PRESENT -> REFUSED returns false');
	ok(-d $unsafe, 'REFUSED: the directory is not removed');
	is($bad_why, sprintf($err->{dir_unsafe}, $unsafe), 'REFUSED: with the reason');

	my $orphan = File::Spec->catdir("$tmp", 'state-absent', 'child');
	my ($none, $none_why) = Class::Shared::ensure_dir($orphan);
	is($none, 0, 'MISSING with a missing parent -> REFUSED');
	ok(!-e $orphan, 'REFUSED: nothing partial was created');
	like($none_why, qr/\Acannot create /, 'REFUSED: the reason says what failed');

	my $file = write_bytes('state-file', 'not a directory');
	my ($not_dir, $not_dir_why) = Class::Shared::ensure_dir($file);
	is($not_dir, 0, 'a plain file is REFUSED');
	ok(-f $file, 'and the file is left alone');
	like($not_dir_why, qr/\Acannot create /, 'with the reason');
};

subtest 'EnsureDir output: a pair whose second part is undef iff the first is true' => sub {
	return if skipped_without_owner_only_dir('directory output');

	my @dirs = (
		File::Spec->catdir("$tmp", 'pair-fresh'),
		File::Spec->catdir("$tmp", 'state-missing'),
		make_dir_with_mode('pair-unsafe', $config{create_mode} | $config{group_write_bit}),
		File::Spec->catdir("$tmp", 'pair-absent', 'child'),
	);

	for my $dir (@dirs) {
		my @result = Class::Shared::ensure_dir($dir);
		is(scalar @result, 2, "exactly two values for '$dir'");
		ok($result[0] == 0 || $result[0] == 1, 'the first is a boolean');
		is(defined($result[1]) ? 1 : 0, $result[0] ? 0 : 1,
			'the second is undef exactly when the first is true');
		ok($result[0] || (defined $result[1] && length $result[1]),
			'a false result always explains itself');
	}
};

# The cache is a package variable, so both sides of it are proved by setting
# it: no platform is asked, and the NO_UNIX refusals are exercised on a
# machine that has sockets as well as on one that has not.
subtest 'UnixSocketProbe: the cache decides, without asking the platform' => sub {
	my $err = $config{err};

	my $first = Class::Shared::_has_unix_sockets();

	{
		local $Class::Shared::UNIX_SOCKETS = 0;

		is(Class::Shared::_has_unix_sockets(), 0, 'NO_UNIX: a cached answer is returned as it stands');

		# NO_UNIX: every entry point that needs sockets dies, and says why.
		dies_with(sub { Class::Shared::socket_path('/tmp') },
			sprintf($err->{unix_missing}, 'a unix socket'), 'NO_UNIX: socket_path dies');
		dies_with(sub { Class::Shared::ensure_dir(File::Spec->catdir("$tmp", 'no-unix')) },
			sprintf($err->{unix_missing}, 'a backend directory'), 'NO_UNIX: ensure_dir dies');
		ok(!-e File::Spec->catdir("$tmp", 'no-unix'), 'NO_UNIX: nothing is created first');
	}

	{
		local $Class::Shared::UNIX_SOCKETS = 1;

		is(Class::Shared::_has_unix_sockets(), 1, 'UNIX_OK: a cached answer is returned as it stands');
		is(Class::Shared::socket_path('/tmp'), File::Spec->catfile('/tmp', $config{socket_name}),
			'UNIX_OK: socket_path works when the cache says it can');
	}

	# An unknown cache is the one case that asks the platform: whatever the
	# answer is, it is kept for the rest of the run.
	{
		local $Class::Shared::UNIX_SOCKETS = undef;

		my $answer = Class::Shared::_has_unix_sockets();
		ok($answer == 0 || $answer == 1, 'an unknown cache is filled with a boolean');
		is($Class::Shared::UNIX_SOCKETS, $answer, 'and the answer is cached, so it is asked once');
	}

	# The proofs above must not leave the cache changed.
	is(Class::Shared::_has_unix_sockets(), $first, 'the cache is restored after the proofs');
};

# The cached answer is judged against the platform itself, which is the one
# thing here that cannot be faked: without sockets there is no answer to
# compare with, so this is where the socket gate belongs.
subtest 'UnixSocketProbe: the cache agrees with a real socketpair' => sub {
	return if skipped_without_unix('socket probe');

	my $first = Class::Shared::_has_unix_sockets();
	my $second = Class::Shared::_has_unix_sockets();
	is($second, $first, 'a later call returns the cached answer');

	# The cached answer is the truth: try the probe again from scratch.
	my $probe = 0;
	eval {
		require Socket;
		$probe = socketpair(my $r, my $w, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0) ? 1 : 0;
		1;
	};
	is($first, $probe, 'the cache agrees with a fresh socketpair probe');
};

subtest 'DefaultDir: five ranked premises, the first true one wins' => sub {
	my $err = $config{err};

	my $xdg = File::Spec->catdir("$tmp", 'rank-xdg');
	mkdir($xdg, $config{create_mode}) or die "cannot make $xdg: $!";
	my $env = File::Spec->catdir("$tmp", 'rank-env');
	my $given = File::Spec->catdir("$tmp", 'rank-given');

	{
		local $ENV{CLASS_SHARED_DIR} = $env;
		local $ENV{XDG_RUNTIME_DIR} = $xdg;

		# Rank 1 true: the argument wins over both environment variables.
		is(Class::Shared::default_dir(dir => $given), $given, 'rank 1: dir given wins');
		# Rank 2 true, rank 1 false: the environment wins over XDG.
		is(Class::Shared::default_dir(dir => ''), $env, 'rank 2: CLASS_SHARED_DIR wins when dir is empty');
		is(Class::Shared::default_dir(dir => undef), $env, 'rank 2: undef is the same as not given');
	}

	{
		local $ENV{CLASS_SHARED_DIR} = '';
		local $ENV{XDG_RUNTIME_DIR} = $xdg;
		is(Class::Shared::default_dir(), File::Spec->catdir($xdg, 'class-shared'),
			'rank 3: an existing XDG_RUNTIME_DIR is used');
	}

	{
		local $ENV{CLASS_SHARED_DIR} = '';
		local $ENV{XDG_RUNTIME_DIR} = File::Spec->catdir("$tmp", 'rank-absent');

		my $got = Class::Shared::default_dir();
		unlike($got, qr/rank-absent/, 'rank 3 is false for a directory that does not exist');
		is(Class::Shared::default_dir(), $got, 'the fallback is deterministic');
		ok(length $got, 'a rank 4 or 5 directory is still returned');
	}

	# Invariant: the answer is always usable, and never names a truncated path.
	for my $dir ($given, $env, $xdg) {
		my $got = Class::Shared::default_dir(dir => $dir);
		ok(length $got, 'the default directory is never empty');
		unlike($got, qr/\0/, 'and never contains a NUL byte');
	}

	# Contradiction: a NUL byte is a name the system call cannot carry.
	dies_with(sub { Class::Shared::default_dir(dir => "$tmp/a\0b") },
		$err->{nul_dir}, 'a NUL byte in the name is a guarded contradiction');
};

subtest 'ClientTlsOptions: fingerprint != bottom <=> the pin branch' => sub {
	my @cases = (
		[ 'ca only',      { ca => 'ca.pem' },                 'ca' ],
		[ 'pin only',     { fingerprint => $pin },            'pin' ],
		[ 'both',         { ca => 'ca.pem', fingerprint => $pin }, 'pin' ],
		[ 'neither',      {},                                 'ca' ],
		[ 'empty pin',    { fingerprint => '' },              'pin' ],
	);

	for my $case (@cases) {
		my ($name, $opt, $branch) = @{$case};
		my %tls = Class::Shared::client_tls_options(cert => 'c.pem', key => 'k.pem', %{$opt});

		# The schema's biconditional, in terms of the keys produced.
		my $has_pin = exists $tls{SSL_fingerprint} ? 1 : 0;
		my $has_ca  = exists $tls{SSL_ca_file} ? 1 : 0;
		is($has_pin ^ $has_ca, 1, "$name: exactly one trust anchor is produced");
		is($has_pin, $branch eq 'pin' ? 1 : 0, "$name: the pin branch iff fingerprint is not bottom");
		is(exists($tls{SSL_force_fingerprint}) ? 1 : 0, $has_pin,
			"$name: forcing the fingerprint iff the pin branch");
		is($tls{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(),
			"$name: verification is on in every branch");
		is($tls{SSL_version}, $Class::Shared::TLS_VERSIONS,
			"$name: the same TLS versions in every branch");
	}

	# "Defined" is the test, so the empty string takes the pin branch: bottom
	# (undef) is the boundary, not falseness.
	my %undef_pin = Class::Shared::client_tls_options(cert => 'c', key => 'k', fingerprint => undef, ca => 'ca.pem');
	ok(!exists $undef_pin{SSL_fingerprint}, 'an undef fingerprint is bottom: the CA branch');
};

subtest 'EncodeFrame: out! = be32(#freeze) ^ freeze (byte identity)' => sub {
	my $digest_size = $config{digest_size};
	my $secret = 'proof secret';

	my @messages = (
		{ op => 'ping' },
		{ op => 'call', args => [ 1, [2, 3], { four => 5 }, undef, 'six' ] },
		[ 1, 2, 3 ],
		\"scalar reference",
		{ "\x{fc}nicode" => "Gr\x{fc}\x{df}e \x{1F600}" },
	);

	for my $message (@messages) {
		my $frozen = Storable::nfreeze($message);
		my $label = ref($message) eq 'HASH' ? 'hash' : ref($message);

		my ($bytes, $error) = Class::Shared::Protocol::encode_frame($message);
		is($error, undef, "$label: no error");
		is(length($bytes), 4 + length($frozen), "$label: #out = 4 + #freeze");
		is(unpack('N', substr($bytes, 0, 4)), length($frozen), "$label: be32(#freeze) is the header");
		is(substr($bytes, 4), $frozen, "$label: the body is exactly freeze(m)");

		my ($again) = Class::Shared::Protocol::encode_frame($message);
		is($again, $bytes, "$label: encoding is deterministic");

		my ($signed) = Class::Shared::Protocol::encode_frame($message, $secret);
		is(length($signed), 4 + $digest_size + length($frozen), "$label: with a secret, #out = 4 + 32 + #freeze");
		is(unpack('N', substr($signed, 0, 4)), $digest_size + length($frozen),
			"$label: the header counts the digest");
		is(substr($signed, 4, $digest_size), Digest::SHA::hmac_sha256($frozen, $secret),
			"$label: the digest is hmac(secret, freeze(m))");
		is(substr($signed, 4 + $digest_size), $frozen, "$label: the body follows the digest");
	}
};

subtest 'EncodeFrame: out! = (bottom, e) <=> #freeze > MAXFRAME' => sub {
	my $err = $config{err};
	my $message = { payload => 'x' x 40 };
	my $frozen_length = length Storable::nfreeze($message);

	{
		# The limit is a package variable, so the boundary can be proved
		# exactly, without allocating 64 MiB.
		local $Class::Shared::Protocol::MAX_FRAME = $frozen_length - 1;
		my ($bytes, $error) = Class::Shared::Protocol::encode_frame($message);
		is($bytes, undef, 'one byte over the limit returns no bytes');
		is($error, sprintf($err->{message_large}, $frozen_length, $frozen_length - 1),
			'with the size and the limit in the message');

		my ($signed, $signed_error) = Class::Shared::Protocol::encode_frame($message, 'k');
		is($signed, undef, 'the same limit applies with a secret');
		is($signed_error, sprintf($err->{message_large}, $frozen_length, $frozen_length - 1),
			'the limit counts the body, not the digest');
	}

	{
		local $Class::Shared::Protocol::MAX_FRAME = $frozen_length;
		my ($bytes, $error) = Class::Shared::Protocol::encode_frame($message);
		is($error, undef, 'exactly the limit is accepted');
		is(length($bytes), 4 + $frozen_length, 'and is framed in full');
	}

	# Contradictions: not in the domain of freeze at all.
	for my $case ( [ 'code reference', { cb => sub { 1 } } ], [ 'plain string', 'text' ], [ 'undef', undef ] ) {
		my ($name, $message) = @{$case};
		my ($bytes, $error) = Class::Shared::Protocol::encode_frame($message);
		is($bytes, undef, "$name: no frame is produced");
		like($error, qr/\A\Q$err->{serialise}\E/, "$name: the error names serialisation");
	}
};

subtest 'TakePayload: body in ran(freeze) <=> (thaw(body), bottom)' => sub {
	my $err = $config{err};

	my @messages = ( { op => 'ping' }, [ 1, undef, 'three' ], { a => { b => [ 3, 4 ] } } );
	for my $message (@messages) {
		my $body = Storable::nfreeze($message);
		my ($got, $error) = Class::Shared::Protocol::take_payload($body);
		is($error, undef, 'a frozen image decodes without an error');
		is_deeply($got, $message, 'thaw(freeze(m)) = m');
	}

	my $valid = Storable::nfreeze({ op => 'ping' });
	for my $case ( [ 'empty', '' ], [ 'text', 'not an image' ], [ 'truncated', substr($valid, 0, length($valid) - 1) ] ) {
		my ($name, $body) = @{$case};
		my ($got, $error) = Class::Shared::Protocol::take_payload($body);
		is($got, undef, "$name: not in ran(freeze), so no message");
		like($error, qr/\A\Q$err->{deserialise}\E/, "$name: and the error says deserialisation");
	}
};

subtest 'TakeFrame: status in {-1,0,1} and the buffer law' => sub {
	my $err = $config{err};
	my $digest_size = $config{digest_size};

	# Row 1: fewer than four bytes is not a header.  The buffer is untouched.
	for my $length (0 .. 3) {
		my $buffer = 'h' x $length;
		my @taken = Class::Shared::Protocol::take_frame(\$buffer);
		assert_take_law(@taken, "header of $length bytes");
		is($taken[0], 0, "header of $length bytes asks for more");
		is($buffer, 'h' x $length, 'and the buffer is not changed');
	}

	{
		local $Class::Shared::Protocol::MAX_FRAME = 10;

		# Row 2: a length above the room is refused before the body arrives,
		# and the buffer is left alone.
		my $too_long = pack('N', 11) . ('x' x 3);
		my $before = $too_long;
		my @taken = Class::Shared::Protocol::take_frame(\$too_long);
		assert_take_law(@taken, 'length above the limit');
		is($taken[2], sprintf($err->{frame_limit}, 11, 10), 'the refusal names the limit');
		is($too_long, $before, 'the buffer is not changed (buf\' = buf)');

		# Row 3: the body is not all here yet.
		my $partial = pack('N', 10) . ('x' x 5);
		$before = $partial;
		@taken = Class::Shared::Protocol::take_frame(\$partial);
		assert_take_law(@taken, 'partial body');
		is($taken[0], 0, 'a partial body asks for more');
		is($partial, $before, 'and the buffer is not changed');

		# With a secret the room is the limit plus the digest.
		my $partial_signed = pack('N', 10 + $digest_size) . ('x' x 5);
		@taken = Class::Shared::Protocol::take_frame(\$partial_signed, 'k');
		assert_take_law(@taken, 'partial signed body');
		is($taken[0], 0, 'limit + 32 is inside the room');

		my $over_signed = pack('N', 10 + $digest_size + 1) . ('x' x 3);
		@taken = Class::Shared::Protocol::take_frame(\$over_signed, 'k');
		is($taken[0], -1, 'limit + 33 is outside the room');
		is($taken[2], sprintf($err->{frame_limit}, 10 + $digest_size + 1, 10 + $digest_size),
			'and the message shows the room includes the digest');
	}

	# Row 4: a whole valid frame is taken, and the buffer drops exactly 4 + n.
	my ($bytes) = Class::Shared::Protocol::encode_frame({ op => 'ping' });
	my $complete = $bytes . 'tail';
	my @taken = Class::Shared::Protocol::take_frame(\$complete);
	assert_take_law(@taken, 'complete frame');
	is($taken[0], 1, 'a whole frame gives status 1');
	is_deeply($taken[1], { op => 'ping' }, 'with the message');
	is($complete, 'tail', 'and the frame is removed, leaving the bytes after it');

	# Row 5: a complete frame that is not a valid image: status -1, and the
	# bytes are consumed so the stream cannot loop on them.
	my $garbage = pack('N', 4) . 'abcd';
	@taken = Class::Shared::Protocol::take_frame(\$garbage);
	assert_take_law(@taken, 'complete invalid frame');
	is($taken[0], -1, 'an invalid image gives status -1');
	is($garbage, '', 'and the frame is removed from the buffer');
};

subtest 'TakeFrame: the digest is checked before the body is thawed' => sub {
	my $err = $config{err};
	my $digest_size = $config{digest_size};
	my $secret = 'ordering secret';

	my ($bytes) = Class::Shared::Protocol::encode_frame({ op => 'ping' }, $secret);

	# Every byte after the header is protected: flipping any one of them must
	# fail authentication, so no byte of the digest or the body is unchecked.
	my $flipped_all = 1;
	for my $offset (4 .. length($bytes) - 1) {
		my $copy = $bytes;
		substr($copy, $offset, 1) = chr(ord(substr($copy, $offset, 1)) ^ 0xFF);

		my @taken = Class::Shared::Protocol::take_frame(\$copy, $secret);
		$flipped_all = 0 unless $taken[0] == -1 && $taken[2] eq $err->{failed_digest};
	}

	ok($flipped_all, 'flipping any single protected byte fails authentication');

	# The ordering lemma: the same garbage body gives two different errors
	# depending only on its digest.  A deserialisation error therefore implies
	# the digest was already accepted, and an authentication error is reported
	# without the body ever reaching Storable.
	my $garbage = 'this is not a Storable image';
	my $honest = frame_for($garbage, $secret);
	my @taken = Class::Shared::Protocol::take_frame(\$honest, $secret);
	is($taken[0], -1, 'garbage with the right digest is refused');
	like($taken[2], qr/\A\Q$err->{deserialise}\E/,
		'and the error is deserialisation: authentication had already passed');

	# Rebuild the frame: take_frame consumed the copy above, as the schema says.
	my $dishonest = frame_for($garbage, $secret);
	substr($dishonest, 4, 1) = chr(ord(substr($dishonest, 4, 1)) ^ 0xFF);
	@taken = Class::Shared::Protocol::take_frame(\$dishonest, $secret);
	is($taken[2], $err->{failed_digest},
		'the same body with a bad digest is stopped at authentication, before thaw');

	# A payload shorter than a digest cannot even be authenticated.
	my $short = pack('N', $digest_size - 1) . ('x' x ($digest_size - 1));
	@taken = Class::Shared::Protocol::take_frame(\$short, $secret);
	is($taken[0], -1, 'a payload shorter than the digest is refused');
	is($taken[2], $err->{short_digest}, 'with the documented reason');
};

subtest 'ReadFrame: room = MAXFRAME + (32 if secret != bottom)' => sub {
	my $err = $config{err};
	my $digest_size = $config{digest_size};
	my $limit = 64;

	my @cases = (
		[ 'at the limit, no secret',        $limit,                 undef,
			qr/\A\Q$err->{deserialise}\E/, 'the limit is a length, not a refusal' ],
		[ 'over the limit, no secret',      $limit + 1,             undef,
			qr/\Aframe of \d+ bytes exceeds the limit of \d+\z/, 'limit + 1 is refused' ],
		[ 'at the room, with a secret',     $limit + $digest_size,  'k',
			qr/\A\Q$err->{failed_digest}\E/, 'the room includes the digest' ],
		[ 'over the room, with a secret',   $limit + $digest_size + 1, 'k',
			qr/\Aframe of \d+ bytes exceeds the limit of \d+\z/, 'room + 1 is refused' ],
	);

	local $Class::Shared::Protocol::MAX_FRAME = $limit;

	for my $case (@cases) {
		my ($name, $length, $secret, $pattern) = @{$case};

		my $stream = pack('N', $length) . ('x' x $length);
		my $path = write_bytes("readframe-" . ($length), $stream);
		open(my $fh, '<:raw', $path) or die "cannot read $path: $!";
		my ($message, $error) = Class::Shared::Protocol::read_frame($fh, 0, $secret);
		close($fh);

		is($message, undef, "$name: no message");
		like($error, $pattern, "$name: the expected error");

		if ($length > $limit + (defined $secret ? $digest_size : 0)) {
			is($error,
				sprintf($err->{frame_limit}, $length, $limit + (defined $secret ? $digest_size : 0)),
				"$name: the message gives the length and the room");
		}
	}
};

subtest 'WriteAll: every write succeeds <=> (true, bottom)' => sub {
	my $err = $config{err};

	pipe(my $reader, my $writer) or die "cannot make a pipe: $!";
	my ($ok, $error) = Class::Shared::Protocol::write_all($writer, 'hello');
	is($ok, 1, 'a writable handle returns true');
	is($error, undef, 'with no error');

	my $got = '';
	sysread($reader, $got, 5);
	is($got, 'hello', "sent' = sent ^ bytes: every byte arrived");

	my ($empty_ok, $empty_error) = Class::Shared::Protocol::write_all($writer, '');
	is($empty_ok, 1, 'zero bytes is the identity write: true');
	is($empty_error, undef, 'and has no error');

	close($reader);
	my ($closed_ok, $closed_error) = Class::Shared::Protocol::write_all($writer, 'x');
	is($closed_ok, 0, 'a closed peer returns false');
	like($closed_error, qr/\Awrite failed: /, 'with the documented prefix');
	close($writer);

	# The schema promises SIGPIPE is ignored for the duration and restored
	# afterwards: a handler set by the caller must survive the call.
	{
		local $SIG{PIPE} = 'DEFAULT';
		pipe(my $r, my $w) or die "cannot make a pipe: $!";
		close($r);
		Class::Shared::Protocol::write_all($w, 'x');
		is($SIG{PIPE}, 'DEFAULT', 'SIGPIPE is restored to what the caller had');
		close($w);
	}
};

subtest 'EncodeFrame and TakePayload leave the caller\'s $@ alone' => sub {
	# The code localises $@ around its own eval; this proves the invariant for
	# both the failure and the success path.
	{
		local $@ = 'sentinel';
		my @result = Class::Shared::Protocol::encode_frame({ cb => sub { 1 } });
		is($@, 'sentinel', 'a serialisation failure does not overwrite $@');
	}

	{
		local $@ = 'sentinel';
		my @result = Class::Shared::Protocol::take_payload('not an image');
		is($@, 'sentinel', 'a deserialisation failure does not overwrite $@');
	}

	{
		local $@ = 'sentinel';
		my @result = Class::Shared::Protocol::encode_frame({ op => 'ping' });
		is($@, 'sentinel', 'success does not overwrite $@ either');
	}
};

subtest 'Frontend transport: tcp <=> host or port is given' => sub {
	return if skipped_without_unix('transport');

	my $err = $config{err};
	my $socket = File::Spec->catfile("$tmp", 'transport.sock');

	# (host, port) with neither: unix, proved by the unix-only refusal of a
	# token, and by reaching the unix socket path.
	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', token => 'secret') },
		$err->{fe_unix_token}, 'no host, no port: the transport is unix');
	dies_like(sub { Class::Shared::Frontend->new('Class::Simple', dir => "$tmp", autostart => 0) },
		qr/\AClass::Shared: cannot reach a backend at /, 'no host, no port: a unix socket is tried');

	# Exactly one of host and port: the transport is tcp, and the pair is a
	# precondition, so the missing half is named.
	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', host => '127.0.0.1') },
		$err->{fe_tcp_both}, 'host without port: tcp, missing port');
	dies_with(sub { Class::Shared::Frontend->new('Class::Simple', port => 1) },
		$err->{fe_tcp_both}, 'port without host: tcp, missing host');

	# Both: tcp, and the next missing premise is TLS.
	dies_with(sub {
		Class::Shared::Frontend->new('Class::Simple', host => '127.0.0.1', port => 1);
	}, $err->{fe_tls_pair}, 'host and port: tcp, so TLS is required');

	# The biconditional in one table.
	my @table = (
		[ 0, 0, 'unix' ],
		[ 1, 0, 'tcp' ],
		[ 0, 1, 'tcp' ],
		[ 1, 1, 'tcp' ],
	);
	my $unix_rows = grep { $_->[2] eq 'unix' } @table;
	my $tcp_rows = grep { $_->[2] eq 'tcp' } @table;
	is($unix_rows, 1, 'only one of the four combinations is unix');
	is($tcp_rows, 3, 'and three are tcp: transport <=> host or port');
};

subtest 'Frontend exclusive options: 11 is a contradiction, 00/01/10 are not' => sub {
	return if skipped_without_unix('exclusive option');

	my $err = $config{err};
	my $token_file = write_bytes('frontend-token', "token\n");
	my $cert = File::Spec->catfile('t', 'certs', 'client.pem');
	my $key  = File::Spec->catfile('t', 'certs', 'client-key.pem');
	my $ca   = File::Spec->catfile('t', 'certs', 'ca.pem');

	# token / token_file: XOR.  The three non-contradictory rows reach the
	# TLS premise, which is the next guard; the contradictory row is stopped
	# before either is read.
	my @token_rows = (
		[ 0, 0, $err->{fe_tls_pair} ],
		[ 1, 0, $err->{fe_tls_pair} ],
		[ 0, 1, $err->{fe_tls_pair} ],
		[ 1, 1, $err->{fe_two_tokens} ],
	);
	for my $row (@token_rows) {
		my ($token, $file, $expected) = @{$row};
		my %opt = (
			host => '127.0.0.1', port => 1,
			($token ? (token => 'tok') : ()),
			($file ? (token_file => $token_file) : ()),
		);
		dies_with(sub { Class::Shared::Frontend->new('Class::Simple', %opt) },
			$expected, sprintf('token=%d token_file=%d', $token, $file));
	}

	# tls_ca / tls_fingerprint: XOR.  Both pass the guard and fail to reach
	# the backend, which is how we know the guard let them through.
	my @trust_rows = (
		[ 0, 0, $err->{fe_tls_trust} ],
		[ 1, 0, 'cannot reach' ],
		[ 0, 1, 'cannot reach' ],
		[ 1, 1, $err->{fe_tls_both} ],
	);
	for my $row (@trust_rows) {
		my ($has_ca, $has_pin, $expected) = @{$row};
		my %opt = (
			host => '127.0.0.1', port => 1, tls_cert => $cert, tls_key => $key,
			($has_ca  ? (tls_ca => $ca) : ()),
			($has_pin ? (tls_fingerprint => $pin) : ()),
		);
		my $code = sub { Class::Shared::Frontend->new('Class::Simple', %opt) };
		if ($expected eq 'cannot reach') {
						dies_like($code, qr/\AClass::Shared: cannot reach a backend at 127\.0\.0\.1:1/,
				sprintf('ca=%d pin=%d: the exclusivity guard let it through', $has_ca, $has_pin));
		} else {
			dies_with($code, $expected, sprintf('ca=%d pin=%d', $has_ca, $has_pin));
		}
	}

	# socket / (host and port): XOR.
	my @socket_rows = (
		[ 0, 0, 'cannot reach' ],
		[ 1, 0, 'cannot reach' ],
		[ 0, 1, $err->{fe_tls_pair} ],
		[ 1, 1, $err->{fe_socket_both} ],
	);
	for my $row (@socket_rows) {
		my ($has_socket, $has_tcp, $expected) = @{$row};
		my %opt = (
			autostart => 0,
			($has_socket ? (socket => File::Spec->catfile("$tmp", 'exclusive.sock')) : ()),
			($has_tcp    ? (host => '127.0.0.1', port => 1) : ()),
		);
		$opt{dir} = "$tmp" unless $has_socket;
		my $code = sub { Class::Shared::Frontend->new('Class::Simple', %opt) };
		if ($expected eq 'cannot reach') {
			dies_like($code, qr/\AClass::Shared: cannot reach a backend at /,
				sprintf('socket=%d tcp=%d: the exclusivity guard let it through', $has_socket, $has_tcp));
		} else {
			dies_with($code, $expected, sprintf('socket=%d tcp=%d', $has_socket, $has_tcp));
		}
	}
};

subtest 'Frontend: unix => no token, no token_file, no TLS (and the converse)' => sub {
	my $err = $config{err};
	my $token_file = write_bytes('converse-token', "token\n");

	my @forbidden = (
		[ 'token',         $err->{fe_unix_token} ],
		[ 'token_file',    $err->{fe_unix_token} ],
		[ 'tls_cert',      $err->{fe_unix_tls} ],
		[ 'tls_key',       $err->{fe_unix_tls} ],
		[ 'tls_ca',        $err->{fe_unix_tls} ],
		[ 'tls_fingerprint', $err->{fe_unix_tls} ],
	);

	for my $case (@forbidden) {
		my ($option, $expected) = @{$case};
		my $value = $option eq 'token_file' ? $token_file : 'value';

		dies_with(sub { Class::Shared::Frontend->new('Class::Simple', $option => $value) },
			$expected, "unix and $option cannot both be true");

		# Converse: on tcp the same option is allowed, so the refusal really
		# is about the unix transport and not about the option's value.
		dies_with(sub {
			Class::Shared::Frontend->new('Class::Simple',
				host => '127.0.0.1', port => 1, $option => $value);
		}, $err->{fe_tls_pair}, "tcp and $option: the unix guard does not fire");
	}
};

subtest 'Frontend State: conn = open <=> id != bottom and pid != bottom' => sub {
	my $can_fork = $Config::Config{d_fork};
	my $permissions = eval {
		require Test::Permissions;
		Test::Permissions::can_revoke_create();
	};

	plan skip_all => 'the state proof needs a unix socket in an owner-only directory and fork'
		unless Class::Shared::_has_unix_sockets() && $can_fork && $permissions;

	my $dir = File::Spec->catdir("$tmp", 'state');
	my $frontend = Class::Shared::Frontend->new('Shared::Counter', dir => $dir, ctor => [ start => 5 ]);

	# Before any data manipulation: the invariant of the State schema.
	my $open = $frontend->shared_connected ? 1 : 0;
	my $id   = $frontend->shared_id;
	my $pid  = $frontend->shared_pid;

	is($open, 1, 'a new frontend is open');
	is(defined($id) ? 1 : 0, $open, 'open => id != bottom');
	is(defined($pid) ? 1 : 0, $open, 'open => pid != bottom');
	cmp_ok($id, '>', 0, 'the id is a positive number');
	cmp_ok($pid, '>', 0, 'the pid is a positive number');

	# During data manipulation the invariant still holds, and the identity of
	# the object does not change.
	is($frontend->value, 5, 'the object holds its constructor value');
	is($frontend->inc(7), 12, 'a call changes the object');
	is($frontend->shared_connected, 1, 'the connection is still open after a call');
	is($frontend->shared_id, $id, 'and the object id is unchanged');

	# shared_close: conn = closed => id = bottom and pid = bottom.
	my $closed = $frontend->shared_close;
	is($closed, 1, 'closing an open frontend returns 1');
	my $after = $frontend->shared_connected ? 1 : 0;
	is($after, 0, 'the frontend is closed afterwards');
	is($frontend->shared_id, undef, 'closed => id = bottom');
	is($frontend->shared_pid, undef, 'closed => pid = bottom');

	# Contradiction: using an object that no longer exists.
	dies_with(sub { $frontend->value },
		q{Class::Shared: this frontend has no connection to a backend for 'Shared::Counter'; its object is gone},
		'a call on a closed frontend is refused by the guard, not sent');

	# Stop the backend this proof started, so it outlives nothing.
	my $second = Class::Shared::Frontend->new('Shared::Counter', dir => $dir);
	eval { $second->shared_shutdown };
};

subtest 'No proof polluted the global state' => sub {
	is($Class::Shared::Protocol::MAX_FRAME, $config{max_frame}, 'MAX_FRAME is restored');
	is($Class::Shared::MAX_SOCKET_PATH, $config{max_socket_path}, 'MAX_SOCKET_PATH is unchanged');
	is($Class::Shared::MAX_SECRET, $config{max_secret}, 'MAX_SECRET is unchanged');
	ok(defined $Class::Shared::UNIX_SOCKETS, 'the socket cache was asked, and is still set');
	is($Class::Shared::UNIX_SOCKETS, Class::Shared::_has_unix_sockets(),
		'and its value is stable');

	is(Cwd::getcwd(), $config{cwd}, 'the working directory is unchanged');
	is($ENV{CLASS_SHARED_DIR}, $config{env_dir}, 'CLASS_SHARED_DIR is restored');
	is($ENV{XDG_RUNTIME_DIR}, $config{env_xdg}, 'XDG_RUNTIME_DIR is restored');
	cmp_ok(fileno(STDOUT), '>=', 0, 'STDOUT still belongs to the test process');
};

done_testing();
