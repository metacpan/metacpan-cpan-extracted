use strict;
use warnings;

use Test::More;
use Test::Needs;
use Class::Shared ();

# A first-time user: no configuration, no hidden state, no knowledge of the
# order the parts are meant to be used in.  They call the public entry points
# with little or nothing, in odd orders, and again and again.  Each flow here
# asserts what the POD promises and that a failure is explicit: it says what
# is wrong in one line, it carries no Perl source location or internal error,
# it raises no warning, and it does not hang.
BEGIN {
	test_needs 'Test::Permissions';

	plan skip_all => 'a backend needs unix sockets in an owner-only directory, '
		. 'which this perl cannot provide (Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();
}

use File::Spec ();
use File::Temp qw(tempdir);
use lib 't/lib';

use Class::Shared::Backend ();
use Class::Shared::Frontend;
use Class::Shared::Protocol ();
use Shared::Command qw(run_command);

my $dir = tempdir(CLEANUP => 1);
my $counter = 'Shared::Counter';

# Run $code, and return what it died with ('' if it did not) and every warning.
# A hang is a failure, not a wait: the alarm turns it into an error.
sub outcome {
	my ($code) = @_;

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	my @result;
	my $lived = eval {
		local $SIG{ALRM} = sub { die "HANG: no answer in 20 seconds\n" };
		alarm 20;
		@result = $code->();
		alarm 0;
		1;
	};
	alarm 0;

	return { died => $lived ? '' : $@, warnings => \@warnings, result => \@result };
}

# A message meant for a person: one line, and no place in the source.
sub explicit {
	my ($outcome, $pattern, $name, %todo) = @_;

	my $message = $outcome->{died};

	like($message, $pattern, $name);

	# A known gap is recorded as TODO, so it is seen on every run without
	# failing the suite for something the POD gives no fix for yet.
	{
		local $TODO = $todo{place} if $todo{place};
		unlike($message, qr/ at \S+ line \d+/, '  names no place in the source');
	}
	{
		local $TODO = $todo{warn} if $todo{warn};
		is_deeply($outcome->{warnings}, [], '  raises no warning');
	}

	return;
}

sub frontend_new {
	my (@args) = @_;

	return outcome(sub { Class::Shared::Frontend->new(@args) });
}

# ---------------------------------------------------- the class name, or none

for my $case (
	['nothing at all',          [],                       qr/no class name given/],
	['undef',                   [undef],                  qr/no class name given/],
	['undef, then options',     [undef, dir => $dir],     qr/no class name given/],
	['an empty string',         [''],                     qr/no class name given/],
	['a space',                 [' '],                    qr/' ' is not a valid class name/],
	['a digit first',           ['1Bad'],                 qr/'1Bad' is not a valid class name/],
	['a trailing ::',           ['Foo::'],                qr/'Foo::' is not a valid class name/],
	['an empty part',           ['Foo::::Bar'],           qr/is not a valid class name/],
	['a file name',             ['Foo/Bar.pm'],           qr/is not a valid class name/],
	['a trailing new line',     ["$counter\n"],           qr/is not a valid class name/],
	['a reference',             [\$counter],              qr/expected key\/value options/],
	['a list of odd length',    [$counter, 'dir'],        qr/expected key\/value options/],
) {
	my ($name, $args, $pattern, @todo) = @{$case};

	explicit(frontend_new(@{$args}), $pattern, "new: $name is refused", @todo);
}

# ------------------------------------------------------------- option values

# Options that cannot work together are refused before anything is connected,
# started or created.  One value stands for each partition: the POD sets no
# range for port or timeout, so no other message is expected of them.
for my $case (
	['host without a port',        [host => 'example.invalid'],               qr/a TCP backend needs both host and port/],
	['port without a host',        [port => 70000],                           qr/a TCP backend needs both host and port/],
	['a token on a unix socket',   [token => 'secret'],                       qr/a unix socket needs no token/],
	['a token file, empty name',   [token_file => ''],                        qr/a unix socket needs no token/],
	['TLS files on a unix socket', [tls_cert => 'c', tls_key => 'k'],         qr/a unix socket needs no TLS/],
	['TCP without TLS files',      [host => 'h', port => 7000],               qr/a TCP backend needs tls_cert and tls_key/],
	['TCP without a CA or pin',    [host => 'h', port => 7000, tls_cert => 'c', tls_key => 'k'], qr/needs tls_ca or tls_fingerprint/],
	['socket and TCP together',    [host => 'h', port => 7000, socket => 's', tls_cert => 'c', tls_key => 'k', tls_ca => 'a'], qr/use either socket or host\/port/],
	['an option nobody has',       [bogus => 1],                              qr/unknown option 'bogus'/],
	['ctor that is not a list',    [ctor => 'x'],                             qr/ctor must be an array ref/],
) {
	my ($name, $options, $pattern) = @{$case};

	explicit(frontend_new($counter, dir => $dir, autostart => 0, @{$options}), $pattern, "new: $name is refused");
}

# Both ways of naming the class are the same class, and the second wins.
{
	my $got = outcome(sub {
		my $f = Class::Shared::Frontend->new($counter, class => 'Shared::Tally', dir => $dir);
		my $name = $f->shared_class;
		$f->shared_shutdown;
		$name;
	});

	is($got->{died}, '', 'a class given twice does not die');
	is($got->{result}[0], 'Shared::Tally', '  and the class option is the one used');
}

# --------------------------------------------------------- nothing set up yet

{
	my $nothing = File::Spec->catdir($dir, 'never-made');

	explicit(frontend_new($counter, dir => $nothing, autostart => 0),
		qr/cannot reach a backend at \S+class-shared\.sock/, 'with no backend and no autostart, the reason is given');
	ok(!-e $nothing, '  and the directory was not made for nothing');

	my $deep = File::Spec->catdir($dir, 'a', 'b', 'c');

	my $got = frontend_new($counter, dir => $deep);

	like($got->{died}, qr/cannot create \S+: No such file or directory/, 'a directory whose parent is missing is explained');
	ok(!-e File::Spec->catdir($dir, 'a'), '  and nothing was made on the way');
}

{
	# One new level is made, owner-only, and a backend is started in it.
	my $fresh = File::Spec->catdir($dir, 'fresh');

	my $got = outcome(sub { Class::Shared::Frontend->new($counter, dir => $fresh) });

	is($got->{died}, '', 'with only the last directory missing, a backend is started');
	is_deeply($got->{warnings}, [], '  without a warning');
	is(sprintf('%04o', (stat $fresh)[2] & 07777), '0700', '  in a directory that only its owner can use');

	my $frontend = $got->{result}[0];

	is($frontend->value, 0, '  and it answers');
	$frontend->shared_shutdown;
}

# A class that cannot be loaded is explained, and the user is not left with a
# connection that cannot be used.
{
	my $got = frontend_new('No::Such::Class', dir => $dir);

	like($got->{died}, qr/cannot load No::Such::Class: Can't locate No\/Such\/Class\.pm/, 'a class that is not installed is named');
	is_deeply($got->{warnings}, [], '  without a warning');

	Class::Shared::Frontend->new($counter, dir => $dir)->shared_shutdown;
}

# --------------------------------------------- a frontend in an unusual order

my $first = Class::Shared::Frontend->new($counter, dir => $dir);

is($first->shared_status->{ok}, 1, 'status is the first thing asked, and it works');
is($first->value, 0, 'an optional argument may be left out');
is($first->inc, 1, 'inc() with no argument adds one');

is($first->shared_close, 1, 'shared_close closes an open connection');
is($first->shared_close, 0, 'and closing again is safe, and says nothing was open');
is($first->shared_connected, 0, 'it is no longer connected');
is($first->shared_pid, undef, 'its backend pid is no longer known');
is($first->shared_class, $counter, 'but it still names its class');
is($first->shared_shutdown, 0, 'shutdown on a closed frontend does nothing');

for my $call (['a method', sub { $first->value }], ['shared_call', sub { $first->shared_call('value') }], ['shared_status', sub { $first->shared_status }]) {
	my ($what, $code) = @{$call};

	explicit(outcome($code), qr/this frontend has no connection to a backend for 'Shared::Counter'; its object is gone/,
		"$what after close: the reason is given");
}

# ----------------------------------------------- odd method names and arguments

my $second = Class::Shared::Frontend->new($counter, dir => $dir);

for my $case (
	['shared_call with no name',         sub { $second->shared_call },                     qr/no method name given/],
	['shared_call(undef)',               sub { $second->shared_call(undef) },              qr/no method name given/],
	['shared_call with an empty name',   sub { $second->shared_call('') },                 qr/no method name given/],
	['a method the class does not have', sub { $second->no_such_method },                  qr/Shared::Counter has no method 'no_such_method'/],
	['a name with a space in it',        sub { $second->shared_call('foo bar') },          qr/'foo bar' is not a plain method name/],
	['the constructor, by name',         sub { $second->shared_call('new') },              qr/cannot call new\(\) through Class::Shared/],
	['the destructor, by name',          sub { $second->shared_call('DESTROY') },          qr/cannot call DESTROY\(\) through Class::Shared/],
) {
	my ($name, $code, $pattern, @todo) = @{$case};

	explicit(outcome($code), $pattern, "$name is refused", @todo);
}

# The class decides what an argument means: Counter adds it, and undef adds 0.
is($second->inc(undef), 0, 'an undef argument reaches the class, which decides what it means');

{
	my @list = $second->value;
	is_deeply(\@list, [0], 'a call in list context returns one value');
	is(scalar($second->value), 0, 'and in scalar context');
}

# --------------------------------------------------- repeated, and across users

{
	my $third = Class::Shared::Frontend->new($counter, dir => $dir);

	$second->inc(5);
	$third->inc(1);

	is($second->value, 5, 'one frontend keeps its own state (5)');
	is($third->value, 1, 'and another keeps its own (1)');
	is($second->shared_pid, $third->shared_pid, 'in one backend');

	is($third->shared_shutdown, 1, 'one of them stops the backend');

	explicit(outcome(sub { $second->value }), qr/lost the backend for 'Shared::Counter'|no connection to a backend/,
		'the others are told, when they next ask');

	my $again = outcome(sub { my $f = Class::Shared::Frontend->new($counter, dir => $dir); my $v = $f->value; $f->shared_shutdown; $v });

	is($again->{died}, '', 'a new frontend after the shutdown starts a new backend');
	is($again->{result}[0], 0, '  with nothing left over from the old one');
}

# ------------------------------------------------- Class::Shared, used raw

for my $case (
	['validate_class()',                  sub { Class::Shared::validate_class() },              qr/no class name given/],
	['read_secret()',                     sub { Class::Shared::read_secret() },                 qr/no token file given/],
	['read_secret(\'\')',                 sub { Class::Shared::read_secret('') },               qr/no token file given/],
	['read_secret(a directory)',          sub { Class::Shared::read_secret($dir) },             qr/cannot read \S+: Is a directory/],
	['normalise_fingerprint()',           sub { Class::Shared::normalise_fingerprint() },       qr/no TLS fingerprint given/],
	['normalise_fingerprint(too short)',  sub { Class::Shared::normalise_fingerprint('abc') },  qr/is not a SHA-256 certificate fingerprint/],
	['ensure_dir()',                      sub { Class::Shared::ensure_dir() },                  qr/no directory given/],
) {
	my ($name, $code, $pattern) = @{$case};

	explicit(outcome($code), $pattern, "$name is refused");
}

{
	my $empty = File::Spec->catfile($dir, 'empty-secret');
	my $lines = File::Spec->catfile($dir, 'only-newlines');

	for my $path ($empty, $lines) {
		open(my $fh, '>', $path) or BAIL_OUT("cannot write $path: $!");
		print {$fh} $path eq $lines ? "\n\n" : '' or BAIL_OUT("cannot write $path: $!");
		close($fh) or BAIL_OUT("cannot close $path: $!");

		explicit(outcome(sub { Class::Shared::read_secret($path) }), qr/is empty/, 'a secret file with nothing in it is refused');
	}

	my ($ok, $why) = Class::Shared::ensure_dir(File::Spec->catdir($dir, 'x', 'y'));

	is($ok, 0, 'ensure_dir does not make a missing parent');
	like($why, qr/cannot create \S+: No such file or directory/, '  and says why');

	my $fingerprint = join ':', ('AB') x 32;

	is(Class::Shared::normalise_fingerprint($fingerprint), 'sha256$' . ('ab' x 32),
		'a fingerprint in capitals with colons is accepted, and made plain');
}

# ------------------------------------------------------------ Protocol, used raw

for my $case (
	['encode_frame()',          sub { Class::Shared::Protocol::encode_frame() }],
	['encode_frame(a string)',  sub { Class::Shared::Protocol::encode_frame('a string') }],
) {
	my ($name, $code) = @{$case};
	my $got = outcome($code);

	is($got->{died}, '', "$name does not die");
	is($got->{result}[0], undef, '  it returns no bytes');
	like($got->{result}[1], qr/cannot serialise message/, '  and says why');
}

{
	open(my $closed, '<', File::Spec->devnull) or BAIL_OUT("cannot open the null device: $!");
	close($closed) or BAIL_OUT("cannot close the null device: $!");

	for my $case (
		['read_frame(a closed handle)', sub { Class::Shared::Protocol::read_frame($closed) },     qr/^read failed/],
		['write_all(a closed handle)', sub { Class::Shared::Protocol::write_all($closed, 'x') },  qr/^write failed/],
	) {
		my ($name, $code, $pattern) = @{$case};
		my $got = outcome($code);

		is($got->{died}, '', "$name does not die");
		like($got->{result}[-1], $pattern, '  and reports the error');

		# Perl itself warns about an I/O call on a closed handle.  The POD does
		# not say whether the warning should be silenced, so it is not asserted.
	}

	# The POD says read_frame returns (undef, $error) when it cannot read, but
	# it does not name an undefined handle.  Protocol.pm line 112 dies on it.
	{
		local $TODO = 'Protocol.pm line 112: read_frame(undef) dies instead of returning (undef, $error)';

		my $got = outcome(sub { Class::Shared::Protocol::read_frame(undef) });

		is($got->{died}, '', 'read_frame(undef) does not die');
	}

	my $buffer = '';

	is_deeply([Class::Shared::Protocol::take_frame(\$buffer)], [0, undef, undef], 'take_frame on an empty buffer asks for more');
}

# ------------------------------------------------------------------ Backend, raw

explicit(outcome(sub { Class::Shared::Backend->new('socket') }), qr/Usage: /, 'Backend->new with an odd list is refused',
	place => 'Backend.pm line 118: the Params::Get usage message has a source location appended');
explicit(outcome(sub { Class::Shared::Backend->new(socket => '') }), qr/an argument is not valid: Parameter 'socket'/, 'Backend->new(socket => \'\') is refused');

# A backend asked for nothing, in each way a new user might say "nothing", is
# built with defaults.  The directory comes from the environment, so no
# argument is needed.
{
	local $ENV{CLASS_SHARED_DIR} = $dir;

	for my $case (['no arguments', []], ['undef', [undef]], ['an empty hash', [{}]]) {
		my ($name, $args) = @{$case};
		my $got = outcome(sub { Class::Shared::Backend->new(@{$args}) });

		is($got->{died}, '', "Backend->new with $name is built with defaults");
	}
}

{
	my $deep = File::Spec->catdir($dir, 'no', 'such');

	my $got = outcome(sub { Class::Shared::Backend->new(dir => $deep, log => File::Spec->catfile($dir, 'run.log'))->run });

	like($got->{died}, qr/cannot create \S+: No such file or directory/, 'run in a directory that cannot be made says so');
	is_deeply($got->{warnings}, [], '  without a warning');
}

# ----------------------------------------------------------------- the command

my @cli = ($^X, '-Ilib', '-It/lib', 'bin/class-shared');
my $life = File::Spec->catdir($dir, 'life');

sub command {
	my ($arguments) = @_;

	my ($status, $text) = run_command(25, @cli, split(' ', $arguments));

	return ($status, $text);
}

for my $case (
	['no arguments',                '',                          0, qr/^usage: class-shared/],
	['help',                        'help',                      0, qr/^usage: class-shared/],
	['an unknown command',          'bogus',                     2, qr/class-shared: unknown command 'bogus'/],
	['an unknown option',           '--bogus',                   2, qr/Unknown option: bogus/],
	['the version',                 '-V',                        0, qr/^class-shared \d/],
	['status, with no backend',     "status --dir $dir/none",    1, qr/class-shared: no backend at \S+: No such file or directory/],
	['stop, with no backend',       "stop --dir $dir/none",      1, qr/class-shared: no backend at \S+: No such file or directory/],
	['a listener without a port',   "start --listen tcp:host --dir $dir/s",  1, qr/--listen wants tcp:HOST:PORT or unix:PATH, not 'tcp:host'/],
	['a listener that is nonsense', "start --listen garbage --dir $dir/s",   1, qr/--listen wants tcp:HOST:PORT or unix:PATH, not 'garbage'/],
	['a port without a host',       "start --port 80 --dir $dir/s",          1, qr/needs both --host and --port/],
	['a token for a unix socket',   "start --token-file $dir/none --dir $dir/s", 1, qr/a unix socket needs no token/],
) {
	my ($name, $arguments, $exit, $pattern) = @{$case};

	my ($status, $text) = command($arguments);

	is($status, $exit, "command: $name exits $exit");
	like($text, $pattern, '  and says why');
}

ok(!-e "$dir/none", 'status and stop did not make a directory for a backend that is not there');
ok(!-e "$dir/s", 'and a refused start did not either');

{
	# Asking for the path does not set anything up, and says the same each time.
	my ($one_status, $one) = command("path --dir $dir/pathonly");
	my ($two_status, $two) = command("path --dir $dir/pathonly");

	is($one_status, 0, 'path exits 0');
	is($one, $two, '  and gives the same answer each time');
	ok(!-e "$dir/pathonly", '  and makes nothing');
}

{
	# The whole life of a backend, with each step repeated.
	my ($start_status) = command("start --dir $life");

	is($start_status, 0, 'start exits 0');

	my ($status_status, $status) = command("status --dir $life");

	is($status_status, 0, 'status finds it');
	like($status, qr/^pid \d+, version \S+, protocol \d+, \d+ object\(s\)/, '  and describes it');

	my ($again_status) = command("start --dir $life");

	is($again_status, 0, 'starting it again exits 0 as well (the second copy gives up in the background)');

	# Findings: a stop sent straight after a redundant start exits 1 with
	# "still there" although the backend does stop, because the second copy is
	# still waiting for the lock.  The POD for stop does not cover this, so the
	# test waits for the second copy to give up (about 3 seconds).
	select(undef, undef, undef, 3.5);

	my ($stop_status, $stop) = command("stop --dir $life");

	is($stop_status, 0, 'stop exits 0');
	like($stop, qr/^stopped$/m, '  and says so');

	my ($stop_again_status, $stop_again) = command("stop --dir $life");

	is($stop_again_status, 1, 'stopping it again exits 1');
	like($stop_again, qr/no backend at/, '  and says there is none');
}

done_testing();
