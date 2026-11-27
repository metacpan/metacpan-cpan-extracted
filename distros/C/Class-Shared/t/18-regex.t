use strict;
use warnings;

use Test::More;
use Test::Needs;
use Class::Shared ();

# The regular expressions that stand between a stranger's text and the rest of
# the code: the class name, the object id and the --listen address.  Each is
# checked on both sides of its boundary, and on input built to make a bad
# pattern take for ever.  A pattern that backtracks badly shows as a hang, so
# every hostile case runs under an alarm.
BEGIN {
	test_needs 'Test::Permissions';

	plan skip_all => 'a backend needs unix sockets in an owner-only directory, '
		. 'which this perl cannot provide (Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();
}

use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use Socket qw(SOCK_STREAM);
use Time::HiRes ();
use lib 't/lib';

use Class::Shared::Frontend;
use Class::Shared::Protocol ();
use Shared::Command qw(run_command);

my $TIME_LIMIT = 10;    # seconds a refusal may take: tens of milliseconds are usual

# Run $code and report how long it took, failing the test if it hangs.
sub timed {
	my ($code) = @_;

	my $start = Time::HiRes::time();
	my $lived = eval {
		local $SIG{ALRM} = sub { die "HANG\n" };
		alarm $TIME_LIMIT;
		$code->();
		alarm 0;
		1;
	};
	alarm 0;

	return ($lived ? '' : $@, Time::HiRes::time() - $start);
}

# ----------------------------------------------------------------- class names

# One of each kind stands for its partition: the first character, the joiner,
# the end, and the characters that look right but are not.
for my $name ('A', '_', 'a1', 'Foo::Bar', '_x::y_1', 'a::b::c::d') {
	is(eval { Class::Shared::validate_class($name) }, $name, "'$name' is a class name");
}

for my $case (
	['an empty part at the end',   'A::'],
	['an empty part at the start', '::A'],
	['three colons',               'A:::B'],
	['one colon',                  'A:B'],
	['a digit first',              '1A'],
	['a digit first after ::',     'A::1'],
	['a space',                    'A B'],
	['a dash',                     'A-B'],
	['a dot',                      'A.B'],
	['a trailing new line',        "A::B\n"],
	['a Latin-1 letter',           "A\x{e9}"],
	['a letter from another script', "A\x{3b1}"],
) {
	my ($what, $name) = @{$case};

	ok(!eval { Class::Shared::validate_class($name); 1 }, "$what is refused");
	like($@, qr/is not a valid class name/, '  with the reason');
}

# Long bad names: the refusal must cost about as much as reading the name.
for my $case (
	['a million "a::" then "!"',   sub { ('a::' x 1_000_000) . '!' }],
	['a million letters then "!"', sub { ('a' x 3_000_000) . '!' }],
	['a million "::"',             sub { 'a' . ('::' x 1_000_000) }],
	['a million colons',           sub { ':' x 3_000_000 }],
) {
	my ($what, $build) = @{$case};
	my $name = $build->();

	my ($died, $took) = timed(sub { Class::Shared::validate_class($name) });

	like($died, qr/is not a valid class name/, "$what: refused");
	cmp_ok($took, '<', $TIME_LIMIT / 2, '  in good time');
}

# A very long name that is valid is still valid: there is no limit in the POD.
{
	my $long = join '::', ('Part') x 100_000;

	my ($died) = timed(sub { Class::Shared::validate_class($long) });

	is($died, '', 'a name of a hundred thousand parts is accepted, as the POD sets no limit');
}

# -------------------------------------------------------------- the object id

# The backend reads the id as ASCII digits.  A digit from another script is
# not one: \d would have let it through to the object lookup, where it is
# refused later and for a different reason.
my $dir = tempdir(CLEANUP => 1);
my $frontend = Class::Shared::Frontend->new('Shared::Counter', dir => $dir);

sub raw_call {
	my ($id) = @_;

	my $sock = IO::Socket::UNIX->new(Type => SOCK_STREAM, Peer => $frontend->shared_socket_path)
		or BAIL_OUT("cannot connect to the backend: $!");

	my @exchange = (
		{ op => 'hello', proto => $Class::Shared::PROTOCOL_VERSION, class => 'Shared::Counter' },
		{ op => 'call', id => $id, method => 'value', args => [], want => 'scalar' },
	);

	my $reply;
	for my $message (@exchange) {
		my ($bytes) = Class::Shared::Protocol::encode_frame($message);
		my ($ok, $why) = Class::Shared::Protocol::write_all($sock, $bytes);
		BAIL_OUT("cannot write to the backend: $why") unless $ok;

		($reply) = Class::Shared::Protocol::read_frame($sock, 10);
		BAIL_OUT('the backend did not answer') unless ref $reply;
	}

	return $reply;
}

is(raw_call('12345')->{kind}, 'unknown_object', 'an ASCII id that names nothing reaches the object lookup');
is(raw_call("\x{661}\x{662}")->{kind}, 'protocol', 'an id in Arabic-Indic digits is refused as not an id');
like(raw_call("\x{661}\x{662}")->{error}, qr/no object id/, '  with the reason');
is(raw_call('')->{kind}, 'protocol', 'an empty id is refused as not an id');
is(raw_call("1\n")->{kind}, 'protocol', 'an id with a new line after it is refused (\z, not $)');

$frontend->shared_shutdown;

# ------------------------------------------------------------ --listen address

# -CA decodes the arguments, which is when \d would take a digit of another
# script.  The bytes are the UTF-8 of two Arabic-Indic digits.
my $arabic = "\xd9\xa8\xd9\xa0";

my ($start_status, $text) = run_command(25, $^X, '-CA', '-Ilib', '-It/lib', 'bin/class-shared',
	'start', '--listen', "tcp:host:$arabic", '--dir', "$dir/l");

is($start_status, 1, 'a port in other digits makes start exit 1');
like($text, qr/--listen wants tcp:HOST:PORT or unix:PATH/, '  saying what an address looks like');
ok(!-e "$dir/l", '  and nothing was made');

done_testing();
