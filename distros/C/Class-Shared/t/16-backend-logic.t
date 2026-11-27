use strict;
use warnings;

use Test::Most;
use File::Spec ();
use File::Temp qw(tempdir);

use Class::Shared ();
use Class::Shared::Backend ();

# The rules that decide whether Class::Shared::Backend->new accepts its options,
# and what it fills in for the options that are not given.  Each case below is
# one class of inputs that the code treats alike, placed on the edge that
# separates it from its neighbour, so that no class is tried twice.
#
# Major premises, from the POD:
#   M1. A listener is TCP when it has a host or a port, and a unix one otherwise.
#   M2. A TCP listener needs both, and no socket, a token, and all three TLS files.
#   M3. A unix listener has no token and no TLS file.
#   M4. A value that is empty counts as not set.
#   M5. An option that is not given has a default; an option that is given, even
#       as 0, keeps its value.

plan skip_all => 'a backend works out its default paths for a unix socket, '
	. 'which this perl cannot provide (Class::Shared is Unix-only)'
	unless Class::Shared::_has_unix_sockets();

my $dir = tempdir(CLEANUP => 1);
my $socket = File::Spec->catfile($dir, 'b.sock');

# A path longer than a socket address can hold.
my $too_long = File::Spec->catfile($dir, ('x' x 120) . '.sock');

my %tls = (tls_cert => 'c.pem', tls_key => 'k.pem', tls_ca => 'ca.pem');
my %tcp = (host => '127.0.0.1', port => 7000);

# The usual form of every refusal: said once, in one line, with no source
# location, because it is meant for a person.
my $REFUSAL = qr/\AClass::Shared::Backend->new: [^\n]+\n\z/;

# ------------------------------------------------------------ what is refused

# Each is refused, with the reason that comes first.  Where several rules would
# refuse the same input, the case shows which one speaks: the earliest.
my @refused = (
	['M2: a host alone',                         { host => 'h' },                                          qr/needs both host and port/],
	['M2: a port alone',                         { port => 7000 },                                         qr/needs both host and port/],
	['M2: both are needed before anything else', { host => 'h', socket => $socket },                       qr/needs both host and port/],
	['M2: and a socket as well is refused',      { %tcp, socket => $socket },                              qr/either socket or host\/port/],
	['M2: a socket is refused before a token',   { %tcp, socket => $socket, token => 't', %tls },          qr/either socket or host\/port/],
	['M2: no token',                             { %tcp, %tls },                                           qr/needs a token/],
	['M4: an empty token is no token',           { %tcp, %tls, token => '' },                              qr/needs a token/],
	['M2: a token is refused before TLS',        { %tcp },                                                 qr/needs a token/],
	['M2: one TLS file missing of three',        { %tcp, token => 't', %tls, tls_ca => undef },            qr/needs tls_cert, tls_key and tls_ca/],
	['M4: an empty TLS file is a missing one',   { %tcp, token => 't', %tls, tls_key => '' },              qr/needs tls_cert, tls_key and tls_ca/],
	['M3: a token on a unix socket',             { socket => $socket, token => 't' },                      qr/a unix socket needs no token/],
	['M3: one TLS file on a unix socket',        { socket => $socket, tls_ca => 'ca.pem' },                qr/a unix socket needs no TLS/],
	['M3: a token is refused before TLS',        { socket => $socket, token => 't', %tls },                qr/a unix socket needs no token/],
	['a path too long is refused before M3',     { socket => $too_long, token => 't' },                    qr/more than the \d+ allowed/],
);

for my $case (@refused) {
	my ($name, $args, $reason) = @{$case};

	throws_ok { Class::Shared::Backend->new(dir => $dir, %{$args}) } $reason, $name;

	# One premise covers every refusal that new() makes itself, so one pair of
	# assertions does: the form, and that it carries no source location.  (The
	# path that is too long is refused by Class::Shared, in that module's form.)
	next if $reason =~ /more than the/;

	like($@, $REFUSAL, '  and it is in the usual form');
	unlike($@, qr/ at \S+ line \d+/, '  and carries no source location');
}

# ------------------------------------------------------------- what is accepted

# The edges on the accepting side of the same rules.
{
	lives_ok { Class::Shared::Backend->new(socket => $socket) } 'M1: neither host nor port: a unix listener';

	lives_ok { Class::Shared::Backend->new(socket => $socket, token => '', tls_cert => '', tls_key => '', tls_ca => '') }
		'M4: empty values are not set, so a unix listener may have them';

	lives_ok { Class::Shared::Backend->new(dir => $dir, %tcp, token => 't', %tls) }
		'M2: all of it together is a TCP listener';
}

# --------------------------------------------- invariants of what is built

# Post-conditions that hold whichever way the listener was made.
{
	my $unix = Class::Shared::Backend->new(socket => $socket);

	is($unix->{socket}, $socket, 'a unix listener keeps the socket it was given');
	is($unix->{control}, $unix->{socket}, 'and its control path is that socket');
	is($unix->{log}, "$socket.log", 'and its log is beside it');

	my $default = Class::Shared::Backend->new(dir => $dir);

	is($default->{socket}, File::Spec->catfile($dir, 'class-shared.sock'), 'without a socket it takes the default one');
	is($default->{control}, $default->{socket}, 'which is its control path');

	my $over_tcp = Class::Shared::Backend->new(dir => $dir, %tcp, token => 't', %tls);

	is($over_tcp->{socket}, undef, 'a TCP listener has no socket');
	is($over_tcp->{control}, File::Spec->catfile($dir, 'class-shared.sock'), 'but keeps its lock and log where one would be');
	is($over_tcp->{log}, "$over_tcp->{control}.log", 'so its log is there');
}

# -------------------------------------------------------------------- defaults

# M5.  Nothing given: every limit is the package's, read when new is called.
{
	my $b = Class::Shared::Backend->new(socket => $socket);

	is($b->{max_clients}, $Class::Shared::Backend::DEFAULT_MAX_CLIENTS, 'max_clients takes its default');
	is($b->{max_objects}, $Class::Shared::Backend::DEFAULT_MAX_OBJECTS, 'max_objects takes its default');
	is($b->{max_queued}, $Class::Shared::Backend::MAX_QUEUED, 'max_queued takes its default');
	is($b->{max_queued_total}, 4 * $b->{max_queued}, 'and the total is four times it');
	is($b->{write_timeout}, $Class::Shared::Backend::WRITE_TIMEOUT, 'write_timeout takes its default');
	is($b->{handshake_timeout}, $Class::Shared::Backend::HANDSHAKE_TIMEOUT, 'handshake_timeout takes its default');
	is($b->{start_timeout}, $Class::Shared::Backend::DEFAULT_START_TIMEOUT, 'start_timeout takes its default');
	is($b->{daemonize}, 0, 'daemonize is off');
}

# The default is read when new is called, not when the module is loaded, because
# a program may set the variable before it makes a backend.
{
	local $Class::Shared::Backend::WRITE_TIMEOUT = 7;

	is(Class::Shared::Backend->new(socket => $socket)->{write_timeout}, 7, 'a default changed before new is the one used');
}

# M5, on the edge: 0 is a value, and is kept; the total follows what was given.
{
	my $b = Class::Shared::Backend->new(socket => $socket, write_timeout => 0, handshake_timeout => 0, start_timeout => 0);

	is_deeply([@{$b}{qw(write_timeout handshake_timeout start_timeout)}], [0, 0, 0], 'a timeout of 0 is kept, not replaced by the default');

	is(Class::Shared::Backend->new(socket => $socket, max_queued => 10)->{max_queued_total}, 40, 'the total follows the bound that was given');
	is(Class::Shared::Backend->new(socket => $socket, max_queued => 10, max_queued_total => 7)->{max_queued_total}, 7, 'unless it was given too');
}

# A boolean is 0 or 1 whatever it was written as, and 0 when absent.
is(Class::Shared::Backend->new(socket => $socket, daemonize => 'yes')->{daemonize}, 1, 'a true word is 1');
is(Class::Shared::Backend->new(socket => $socket, daemonize => 'off')->{daemonize}, 0, 'a false word is 0');

# --------------------------------------------------------------- a log named 0

# The only input where "x || default" and "x // default" give different answers:
# the string "0" is a file name, and the POD says the default is used when no
# log is given, not when the name looks false.
{
	is(Class::Shared::Backend->new(socket => $socket, log => '0')->{log}, '0', 'a log called 0 is the log');
	is(Class::Shared::Backend->new(socket => $socket, log => undef)->{log}, "$socket.log", 'an undef log is not given');

	# And it is the file that is written, not the default beside the socket.
	require Cwd;
	my $here = Cwd::getcwd();

	chdir($dir) or BAIL_OUT("cannot change to $dir: $!");

	my $b = Class::Shared::Backend->new(socket => $socket, log => '0');
	$b->_log('written to a file called 0');
	undef $b;

	chdir($here) or BAIL_OUT("cannot change back to $here: $!");

	ok(-s File::Spec->catfile($dir, '0'), 'the log called 0 was written');
	ok(!-e "$socket.log", 'and the default log was not');
}

done_testing();
