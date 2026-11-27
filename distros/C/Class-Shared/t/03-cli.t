use strict;
use warnings;

use Test::More;
use Test::Needs;
use Class::Shared ();

# The commands talk to a backend over a unix socket in an owner-only directory:
# whether this perl can make the socket is asked of the module, and whether a
# directory here can really be made owner-only is asked of Test::Permissions,
# which tries chmod rather than guessing from the platform's name.
BEGIN {
	test_needs 'Test::Permissions';

	plan skip_all => 'the command line admin talks to a backend over a unix '
		. 'socket in an owner-only directory, which this perl cannot provide '
		. '(Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();
}

use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use Socket qw(SOCK_STREAM);
use lib 't/lib';

use Class::Shared::Frontend;
use Class::Shared::Protocol;

my $dir = tempdir(CLEANUP => 1);

my $frontend = Class::Shared::Frontend->new(
	'Shared::Counter',
	ctor => [start => 3],
	dir  => $dir,
);

END {
	eval { $frontend->shared_shutdown } if $frontend && $frontend->shared_connected;
}

my $cli = "$^X -Ilib -It/lib bin/class-shared";

chomp(my $path = `$cli path --dir $dir 2>&1`);
is($?, 0, 'path exits successfully') or diag $path;
is($path, $frontend->shared_socket_path, 'path prints the socket in use');

my $status = `$cli status --dir $dir 2>&1`;
is($?, 0, 'status exits successfully') or diag $status;
like($status, qr/^pid \d+/m, 'status names the backend pid');
like($status, qr/^classes: Shared::Counter$/m, 'and the class it has loaded');
like($status, qr/\d+ object\(s\)/, 'status counts the objects');
like($status, qr/address: .*\.sock/, 'status names the address');

# The queue is what the memory bound is holding, so status reports it as a
# number against the ceiling: none while nothing waits, and a real one while an
# unread reply sits there.
my ($idle_queued, $ceiling) = $status =~ /^queued:\s+(\d+) of (\d+) byte\(s\)$/m;

is($idle_queued, 0, 'status counts the queued bytes, and nothing is waiting');
cmp_ok($ceiling // 0, '>', 1024 * 1024,
	'and names the ceiling those bytes are held against');

my $raw = IO::Socket::UNIX->new(Type => SOCK_STREAM, Peer => $frontend->shared_socket_path);
ok($raw, 'a raw client can ask for a reply it will not read');

if ($raw) {
	my $ask = sub {
		my ($message) = @_;

		my ($bytes) = Class::Shared::Protocol::encode_frame($message);
		return unless defined $bytes;
		return unless Class::Shared::Protocol::write_all($raw, $bytes);

		my ($reply) = Class::Shared::Protocol::read_frame($raw, 5);
		return $reply;
	};

	my $hello = $ask->({
		op    => 'hello',
		proto => $Class::Shared::PROTOCOL_VERSION,
		class => 'Shared::Counter',
	});
	my $object = $hello && $hello->{ok} ? $ask->({ op => 'new', args => [] }) : undef;

	ok($object && $object->{ok}, 'and has an object of its own');

	if ($object) {
		# 4 MiB fits the queue and not the socket, so most of it waits.
		my ($call) = Class::Shared::Protocol::encode_frame({
			op     => 'call',
			id     => $object->{id},
			method => 'blob',
			args   => [4 * 1024 * 1024],
			want   => 'scalar',
		});
		Class::Shared::Protocol::write_all($raw, $call) if defined $call;

		my $busy_status = '';
		my $queued;
		for (1 .. 40) {
			$busy_status = `$cli status --dir $dir 2>&1`;
			($queued) = $busy_status =~ /^queued:\s+(\d+) of \d+ byte\(s\)$/m;
			last if defined $queued && $queued > 0;
			select(undef, undef, undef, 0.05);
		}

		is($?, 0, 'status answers while a reply is waiting') or diag $busy_status;
		cmp_ok($queued // 0, '>', 0,
			'and the queued bytes include the reply that has not gone out');
		cmp_ok($queued // 0, '<', $ceiling // 0,
			'and they are below the ceiling it names');

		close $raw;

		my $after = '';
		for (1 .. 40) {
			$after = `$cli status --dir $dir 2>&1`;
			last if $after =~ /^queued:\s+0 of /m;
			select(undef, undef, undef, 0.05);
		}

		like($after, qr/^queued:\s+0 of \d+ byte\(s\)$/m,
			'and back to none when that client goes');
	}
}

my $token_file = "$dir/token";
open(my $token_fh, '>', $token_file) or die "cannot write $token_file: $!";
print {$token_fh} "s3cret\n";
close $token_fh;

my $tokenised = `$cli status --dir $dir --token-file $token_file 2>&1`;
isnt($?, 0, 'status refuses a token on a unix socket');
like($tokenised, qr/a unix socket needs no token/,
	'and says the 0600 socket already decides who may connect');

# The class is loaded when a client asks for it, so asking for one that is not
# installed fails at the handshake, with the module named.
my $missing = `$^X -Ilib -It/lib -MClass::Shared::Frontend -e '
	Class::Shared::Frontend->new("Shared::Absent", dir => shift, autostart => 0)
		->shared_connect' $dir 2>&1`;
isnt($?, 0, 'a frontend whose class cannot be loaded fails');
like($missing, qr/cannot load Shared::Absent/, 'and names the module it could not load');

my $stopped = `$cli stop --dir $dir 2>&1`;
is($?, 0, 'stop exits successfully') or diag $stopped;
like($stopped, qr/^stopped$/m, 'stop says it stopped');
ok(!-e $frontend->shared_socket_path, 'the socket is gone after stop');

my $help = `$cli help 2>&1`;
is($?, 0, 'help exits successfully');
like($help, qr/usage: class-shared/, 'help explains itself');

# The command that starts a backend is "start", the opposite of "stop", as
# with systemctl.  Its old name, "serve", is not kept as an alias.
like($help, qr/^  start +run the backend/m, 'help lists start as the command that runs the backend');
unlike($help, qr/^  serve /m, 'and no longer lists serve');

my $old = `$cli serve --dir $dir 2>&1`;
is($? >> 8, 2, 'serve is now an unknown command: usage error');
like($old, qr/unknown command 'serve'/, 'and says so');

done_testing();
