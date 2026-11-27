use strict;
use warnings;

use Test::More;
use Test::Needs;
use Class::Shared ();

# Regression tests for the findings of the security audit.  Each one is named
# for the attack it stops, and each is run against the attack itself, so that
# a change that lets it through again fails here.
BEGIN {
	test_needs 'Test::Permissions';

	plan skip_all => 'a backend needs unix sockets in an owner-only directory, '
		. 'which this perl cannot provide (Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();
}

use File::Spec ();
use File::Temp qw(tempdir);
use IO::Select;
use IO::Socket::UNIX;
use Socket qw(SOCK_STREAM);
use lib 't/lib';

use Class::Shared::Backend ();
use Class::Shared::Frontend;
use Class::Shared::Protocol ();
use Shared::Command qw(run_command);

# A client that is let through to a server that never answers would wait for
# ever (a call has no time limit).  The alarm turns that hang into a failure.
$SIG{ALRM} = sub { BAIL_OUT("a test waited more than 30 seconds: a client is stuck") };
alarm 30;

my $dir = tempdir(CLEANUP => 1);
chmod(0700, $dir) or BAIL_OUT("cannot make $dir owner-only: $!");

sub slurp {
	my ($path) = @_;

	open(my $fh, '<', $path) or BAIL_OUT("cannot read $path: $!");
	my $text = do { local $/; <$fh> };
	close($fh) or BAIL_OUT("cannot close $path: $!");

	return $text;
}

# ------------------------------------------- a socket that is not ours (audit 1)

# Another user's server in a directory they can write to.  The client must not
# connect to it, because it would send that server every argument it has and
# thaw whatever the server sent back.  The server notes any connection it gets,
# so "refused" means it was never reached and not merely that the answer was
# not liked.
my $open_dir = File::Spec->catdir($dir, 'open');
mkdir($open_dir, 0777) or BAIL_OUT("cannot make $open_dir: $!");
chmod(0777, $open_dir) or BAIL_OUT("cannot open up $open_dir: $!");

my $fake_socket = File::Spec->catfile($open_dir, 'class-shared.sock');
my $fake_seen = File::Spec->catfile($dir, 'fake-saw-a-client');

my $listener = IO::Socket::UNIX->new(Type => SOCK_STREAM, Local => $fake_socket, Listen => 5)
	or BAIL_OUT("cannot make the fake backend: $!");

my $fake = fork;
BAIL_OUT("cannot fork: $!") unless defined $fake;

if ($fake == 0) {
	# The fake backend: if anyone connects, say so, and answer nothing.
	my $select = IO::Select->new($listener);

	if ($select->can_read(20)) {
		open(my $fh, '>', $fake_seen) or exit 1;
		close($fh) or exit 1;
	}

	exit 0;
}

{
	my $got = eval { Class::Shared::Frontend->new('Shared::Counter', dir => $open_dir, autostart => 0); 1 };

	ok(!$got, 'a frontend does not connect to a socket in a directory others can write to');
	like($@, qr/will not connect to \S+: \S+ is writable by group or others/, '  and says why');

	select(undef, undef, undef, 0.3);
	ok(!-e $fake_seen, '  and the server there was never reached');
}

{
	my ($status, $text) = run_command(25, $^X, '-Ilib', '-It/lib', 'bin/class-shared', 'status', '--dir', $open_dir);

	is($status, 1, 'the command does not connect either: exit 1');
	like($text, qr/will not connect: \S+ is writable by group or others/, '  and says why');

	select(undef, undef, undef, 0.3);
	ok(!-e $fake_seen, '  and the server there was never reached');
}

kill('TERM', $fake);
waitpid($fake, 0);

# The check itself, one case for each way a path can be refused or accepted.
{
	my $mine = File::Spec->catdir($dir, 'mine');
	mkdir($mine, 0700) or BAIL_OUT("cannot make $mine: $!");
	my $path = File::Spec->catfile($mine, 'x.sock');

	my $good = IO::Socket::UNIX->new(Type => SOCK_STREAM, Local => $path, Listen => 1)
		or BAIL_OUT("cannot make a socket: $!");

	is_deeply([Class::Shared::_check_endpoint($path)], [1, undef], 'a socket of ours in a directory of ours is accepted');

	my $plain = File::Spec->catfile($mine, 'plain');
	open(my $fh, '>', $plain) or BAIL_OUT("cannot write $plain: $!");
	close($fh) or BAIL_OUT("cannot close $plain: $!");

	my ($ok, $why) = Class::Shared::_check_endpoint($plain);
	is($ok, 0, 'a file that is not a socket is refused');
	like($why, qr/is not a socket/, '  and says why');

	chmod(0770, $mine) or BAIL_OUT("cannot open up $mine: $!");
	($ok, $why) = Class::Shared::_check_endpoint($path);
	is($ok, 0, 'a directory the group can write to is refused');
	like($why, qr/writable by group or others/, '  and says why');

	chmod(0700, $mine) or BAIL_OUT("cannot close up $mine: $!");
	($ok, $why) = Class::Shared::_check_endpoint(File::Spec->catfile($mine, 'missing.sock'));
	is($ok, 0, 'a path that is not there is refused');
	like($why, qr/cannot stat/, '  and says why');
}

# ------------------------------------------- qualified method names (audit 2)

# $object->Package::function is a call to that function with the object as its
# first argument.  Storable::nstore($object, $file) writes the object to any
# file the backend may write, so it is the proof that the name was used.
{
	my $safe = File::Spec->catdir($dir, 'methods');
	my $frontend = Class::Shared::Frontend->new('Shared::Counter', dir => $safe);

	my $victim = File::Spec->catfile($dir, 'must-not-exist');

	for my $case (
		['a package-qualified method',  'Shared::Counter::value',   []],
		['a function of another module', 'Storable::nstore',         [$victim]],
		['SUPER',                       'SUPER::value',             []],
		['an old-style package name',   "Shared'Counter'value",     []],
		['a leading digit',             '1value',                   []],
		['a trailing new line',         "value\n",                  []],
	) {
		my ($what, $method, $args) = @{$case};

		ok(!eval { $frontend->shared_call($method, @{$args}); 1 }, "$what is refused");
		like($@, qr/is not a plain method name/, '  with the reason');
	}

	ok(!-e $victim, 'and the file the function would have written does not exist');
	is($frontend->value, 0, 'a plain method still works');
	is($frontend->can('value') ? 1 : 0, 1, 'and so does can');

	$frontend->shared_shutdown;
}

# ---------------------------------------- only a socket is removed (audit 3)

{
	my $nest = File::Spec->catdir($dir, 'stale');
	mkdir($nest, 0700) or BAIL_OUT("cannot make $nest: $!");

	my $important = File::Spec->catfile($nest, 'important.txt');
	open(my $fh, '>', $important) or BAIL_OUT("cannot write $important: $!");
	print {$fh} "keep me\n" or BAIL_OUT("cannot write $important: $!");
	close($fh) or BAIL_OUT("cannot close $important: $!");

	my $backend = Class::Shared::Backend->new(socket => $important, log => File::Spec->catfile($nest, 'b.log'));

	ok(!eval { $backend->run; 1 }, 'a backend asked to listen where a file is does not start');
	like($@, qr/important\.txt exists and is not a socket; refusing to remove it/, '  and says why');
	is(slurp($important), "keep me\n", '  and the file is untouched');

	# The same through a frontend that would have started the backend.
	my $victim = File::Spec->catfile($nest, 'class-shared.sock');
	open($fh, '>', $victim) or BAIL_OUT("cannot write $victim: $!");
	print {$fh} "keep me too\n" or BAIL_OUT("cannot write $victim: $!");
	close($fh) or BAIL_OUT("cannot close $victim: $!");

	ok(!eval { Class::Shared::Frontend->new('Shared::Counter', dir => $nest); 1 }, 'a frontend does not delete a file to make room for a socket');
	like($@, qr/class-shared\.sock exists and is not a socket; refusing to remove it/, '  and says why');
	is(slurp($victim), "keep me too\n", '  and the file is untouched');
}

# ------------------------------------------------- the socket's mode (audit 7)

{
	my $nest = File::Spec->catdir($dir, 'mode');
	my $old = umask 0000;    # the loosest, so that only the code can make it tight
	my $frontend = Class::Shared::Frontend->new('Shared::Counter', dir => $nest);
	umask $old;

	is(sprintf('%04o', (stat $frontend->shared_socket_path)[2] & 07777), '0600',
		'the socket is for its owner alone even when the umask allows more');

	$frontend->shared_shutdown;
}

# --------------------------------------------------------- taint mode (audit 5)

{
	my $nest = File::Spec->catdir($dir, 'taint');
	local $ENV{CLASS_SHARED_DIR} = $nest;

	# The programs are files, not -e arguments, so that no shell quoting is
	# between the test and what perl runs.
	my $script = File::Spec->catfile($dir, 'taint.pl');
	open(my $out, '>', $script) or BAIL_OUT("cannot write $script: $!");
	print {$out} <<'PROGRAM' or BAIL_OUT("cannot write $script: $!");
use strict; use warnings;
use Scalar::Util ();
use Class::Shared::Frontend;

# The class name and the PATH come from the environment, as input does.  The
# PATH is set here and not by the test, which needs its own to run the shell.
$ENV{PATH} = $ENV{CS_PATH};
my $f = Class::Shared::Frontend->new($ENV{CS_CLASS});
print 'tainted=', (Scalar::Util::tainted(Class::Shared::validate_class($ENV{CS_CLASS})) ? 1 : 0), "\n";
print 'inc=', $f->inc(2), "\n";
$f->shared_shutdown;
PROGRAM
	close($out) or BAIL_OUT("cannot close $script: $!");

	# A runner's PATH usually names a directory others can write to, and perl
	# will not exec while it does.  Each way a PATH can be unsafe is its own
	# case, with otherwise good entries after it.  They must not be run
	# together: an empty or relative entry makes a PATH that is checked as a
	# whole fail early, and would hide a world-writable directory next to it.
	my $loose = File::Spec->catdir($dir, 'loose-bin');
	mkdir($loose, 0700) or BAIL_OUT("cannot make $loose: $!");
	chmod(0777, $loose) or BAIL_OUT("cannot open up $loose: $!");

	my $group = File::Spec->catdir($dir, 'group-bin');
	mkdir($group, 0700) or BAIL_OUT("cannot make $group: $!");
	chmod(0775, $group) or BAIL_OUT("cannot open up $group: $!");

	my $good = $ENV{PATH};   # the test's own, which is clean enough to find perl and timeout

	for my $case (
		['a clean PATH',                      $good],
		['a world-writable directory first',  "$loose:$good"],
		['a group-writable directory first',  "$group:$good"],
		['an empty and a relative entry',     ":.:$good"],
		['a directory that is not there',     File::Spec->catdir($dir, 'no-such-bin') . ":$good"],
		['nothing usable at all',             "$loose:$group:."],
	) {
		my ($what, $path) = @{$case};

		local $ENV{CS_PATH} = $path;
		local $ENV{CS_CLASS} = 'Shared::Counter';
		my ($status, $text) = run_command(25, $^X, '-T', '-Ilib', '-It/lib', $script);

		is($status, 0, "under -T a frontend starts a backend and uses it, with $what");
		like($text, qr/^tainted=0$/m, '  the class name that was checked is untainted');
		like($text, qr/^inc=2$/m, '  and the object works');
	}

	my $nul_script = File::Spec->catfile($dir, 'nul.pl');
	open($out, '>', $nul_script) or BAIL_OUT("cannot write $nul_script: $!");
	print {$out} qq{use Class::Shared; eval { Class::Shared::default_dir(dir => "a\\0b") }; print \$@;\n}
		or BAIL_OUT("cannot write $nul_script: $!");
	close($out) or BAIL_OUT("cannot close $nul_script: $!");

	my (undef, $nul) = run_command(25, $^X, '-T', '-Ilib', $nul_script);
	like($nul, qr/may not contain a NUL byte/, 'a directory name with a NUL byte is refused, not truncated');
}

# ---------------------------------------------------- TLS versions (audit 4)

subtest 'with IO::Socket::SSL' => sub {
	test_needs 'IO::Socket::SSL';

	my %options = Class::Shared::client_tls_options(cert => 'c', key => 'k', ca => 'a');

	is($options{SSL_version}, $Class::Shared::TLS_VERSIONS, 'the client asks for the permitted TLS versions');
	unlike($options{SSL_version}, qr/(?<![!\w])TLSv1(?:_1)?(?!\w)/, '  none of which is TLS 1.0 or 1.1');
	like($options{SSL_version}, qr/!SSLv3.*!TLSv1:!TLSv1_1/, '  and the old ones are switched off by name');
};

# ----------------------------------------------------- the log (audit 6)

{
	my $log = File::Spec->catfile($dir, 'escape.log');
	my $backend = Class::Shared::Backend->new(socket => File::Spec->catfile($dir, 'escape.sock'), log => $log);

	$backend->_log("red \e[31mtext\e[0m and a bell \a and a null \0 done");
	$backend->_log("two\nlines\tand a tab");

	my $text = slurp($log);

	unlike($text, qr/[\x00-\x08\x0B-\x1F\x7F]/, 'no control character reaches the log, except new line and tab');
	like($text, qr/red\s+\[31mtext\s+\[0m and a bell\s+and a null\s+done/, '  and each run of them became spaces');
	like($text, qr/two\n\tlines\tand a tab/, '  and a new line and a tab are kept, the line after a new line indented');
}

done_testing();
