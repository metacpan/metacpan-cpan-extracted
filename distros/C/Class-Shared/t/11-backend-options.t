use strict;
use warnings;

use Test::More;
use File::Spec ();
use File::Temp qw(tempdir);

use Class::Shared::Backend ();

# How Class::Shared::Backend->new gets its options: Params::Get accepts the
# argument styles, Params::Validate::Strict checks them, and Object::Configure
# supplies site defaults from the environment and from a config file.  Only
# constructing the object is tested, so no socket is made or needed.

my $dir = tempdir(CLEANUP => 1);
my $socket = "$dir/b.sock";

sub backend { return Class::Shared::Backend->new(socket => $socket, @_) }

sub refused {
	my ($code) = @_;

	my $made = eval { $code->(); 1 };

	return $made ? undef : $@;
}

# ---------------------------------------------------------- calling styles

{
	my $pairs   = Class::Shared::Backend->new(socket => $socket, max_clients => 3);
	my $hashref = Class::Shared::Backend->new({ socket => $socket, max_clients => 3 });

	is($pairs->{socket}, $socket, 'new(key => value, ...) is accepted');
	is($hashref->{socket}, $socket, 'new(\%options) is accepted');
	is($hashref->{max_clients}, 3, 'and gives the same options');

	local $ENV{CLASS_SHARED_DIR} = $dir;
	local $ENV{XDG_RUNTIME_DIR};
	SKIP: {
		skip 'this perl has no unix sockets, which the default path needs', 1
			unless Class::Shared::_has_unix_sockets();

		my $none = Class::Shared::Backend->new();
		# Built with File::Spec, as the module builds it: a hard-coded "/" would
		# not match the path it returns on Windows.
		is($none->{socket}, File::Spec->catfile($dir, 'class-shared.sock'),
			'new() with no arguments uses the default socket');
	}
}

# ------------------------------------------------------------ checked options

like(refused(sub { backend(bogus => 1) }),
	qr/\AClass::Shared::Backend->new: an argument is not valid: Unknown parameter 'bogus'\n\z/,
	'an unknown option is refused, by name, in the usual form');

# class was never an option: the clients choose the class.
like(refused(sub { backend(class => 'Shared::Counter') }),
	qr/Unknown parameter 'class'/, 'class is not an option');

for my $case (
	['port that is not a number',  [host => '127.0.0.1', port => 'x'],  qr/'port'.*integer/],
	['port of zero',               [host => '127.0.0.1', port => 0],    qr/'port'/],
	['port above 65535',           [host => '127.0.0.1', port => 70000], qr/'port'/],
	['max_clients of zero',        [max_clients => 0],                  qr/'max_clients'/],
	['max_objects that is text',   [max_objects => 'many'],             qr/'max_objects'/],
	['negative write_timeout',     [write_timeout => -1],               qr/'write_timeout'/],
	['start_timeout that is text', [start_timeout => 'soon'],           qr/'start_timeout'/],
	['empty log name',             [log => ''],                         qr/'log'/],
	['token with a non-ASCII char', [token => "caf\x{e9}"],             qr/'token'/],
	['config_dirs that is a string', [config_dirs => '/etc'],           qr/'config_dirs'/],
) {
	my ($name, $args, $pattern) = @{$case};

	like(refused(sub { backend(@{$args}) }), $pattern, "refused: $name");
}

# Values that should be fine, including ones given as text.
{
	my $b = backend(max_clients => '12', write_timeout => '0.5', start_timeout => 0, daemonize => 1);

	is($b->{max_clients}, 12, 'a number given as text is accepted');
	is($b->{write_timeout}, 0.5, 'a fractional timeout is accepted');
	is($b->{start_timeout}, 0, 'a start_timeout of 0 is accepted (it means do not wait)');
	is($b->{daemonize}, 1, 'daemonize is a boolean');
}

# undef means "not given": bin/class-shared passes undef for what it has nothing for.
{
	my $b = backend(host => undef, port => undef, token => undef, log => undef, dir => undef);

	ok(!defined $b->{host} && !defined $b->{port}, 'undef host and port leave it a unix backend');
	is($b->{log}, "$socket.log", 'an undef log falls back to the default');
}

# ------------------------------------------- the rules that need several options

like(refused(sub { Class::Shared::Backend->new(host => '127.0.0.1') }),
	qr/needs both host and port/, 'host without port is still refused');

like(refused(sub { backend(token => 's3cret') }),
	qr/a unix socket needs no token/, 'a token on a unix socket is still refused');

like(refused(sub { Class::Shared::Backend->new(host => '127.0.0.1', port => 7000) }),
	qr/needs a token/, 'a TCP listener without a token is still refused');

SKIP: {
	# A TCP backend keeps its lock and log where the default socket would be.
	skip 'this perl has no unix sockets, which the default path needs', 1
		unless Class::Shared::_has_unix_sockets();

	my $tcp = Class::Shared::Backend->new(
		host => '127.0.0.1', port => 7000, token => 's3cret',
		tls_cert => 'c.pem', tls_key => 'k.pem', tls_ca => 'ca.pem',
	);

	is($tcp->{port}, 7000, 'a complete TCP listener is accepted');
}

# ---------------------------------------------------------------- environment

{
	local $ENV{Class__Shared__Backend__max_clients} = '5';

	is(backend()->{max_clients}, 5, 'an environment variable supplies a default');
	is(backend(max_clients => 9)->{max_clients}, 9, 'and what the caller passed wins over it');
	is(backend(max_clients => undef)->{max_clients}, 5, 'an undef argument does not hide it');
}

{
	local $ENV{Class__Shared__Backend__max_clients} = 'lots';

	like(refused(sub { backend() }),
		qr/a configured value is not valid: .*'max_clients'/,
		'a bad value from the environment is reported as configuration, not as an argument');
}

# An environment variable cannot give a unix socket a token, any more than a caller can.
{
	local $ENV{Class__Shared__Backend__token} = 'fromenv';

	like(refused(sub { backend() }),
		qr/a unix socket needs no token/,
		'a token from the environment is held to the same rules');
}

# ------------------------------------------------------------------ config file

{
	my $file = "$dir/class-shared-backend.yml";

	open(my $fh, '>', $file) or BAIL_OUT("cannot write $file: $!");
	print {$fh} "---\nClass__Shared__Backend:\n  max_objects: 77\n  max_clients: 11\n"
		or BAIL_OUT("cannot write $file: $!");
	close($fh) or BAIL_OUT("cannot close $file: $!");

	my $b = backend(config_file => $file);

	is($b->{max_objects}, 77, 'a config file supplies a default');
	is(backend(config_file => $file, max_objects => 5)->{max_objects}, 5,
		'and what the caller passed wins over it');
	ok(!exists $b->{config_file}, 'the config_file option is not kept in the object');
}

done_testing();
