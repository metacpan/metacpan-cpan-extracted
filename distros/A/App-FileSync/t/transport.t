use strict;
use warnings;
use Test::Most;

use File::Spec;
use File::Temp qw(tempdir);

use App::FileSync::Constants qw($PROTOCOL_VERSION);
use App::FileSync::Protocol;
use App::FileSync::Store;
use App::FileSync::Transport::Local;
use App::FileSync::Transport::SSH;

use lib 't/lib';
use TestSync;

my $base = tempdir(CLEANUP => 1);

# --- Protocol::close ---------------------------------------------------------

{
	pipe(my $from_peer, my $to_us) or die "pipe: $!";
	pipe(my $from_us, my $to_peer) or die "pipe: $!";
	my $connection = App::FileSync::Protocol->new(in => $from_peer, out => $to_peer);
	$connection->send({ cmd => 'hello' });

	is($connection->close(), 1, 'close returns 1');
	ok(!defined fileno($from_peer) && !defined fileno($to_peer), 'and closes both handles');
	is(scalar(() = $connection->close()), 0, 'a second close returns nothing');
	throws_ok { $connection->send({ cmd => 'done' }) } qr/\AProtocol: connection is closed$/m,
		'a send after close is protocol.closed';

	# The peer reads what was sent, then end of file.
	close $to_us;
	is(scalar readline($from_us), qq({"cmd":"hello"}\n), 'what was sent before close arrives');
	ok(!defined readline($from_us), 'then the peer sees end of file');
}

# --- Transport::SSH: command and exit_status --------------------------------------

# A stand-in for ssh: write its argv one per line to $FAKE_ARGV, read its
# input to end of file (as ssh does), then exit with $FAKE_EXIT.
my $script = File::Spec->catfile($base, 'exit-ssh.pl');
my $fake = File::Spec->catfile($base, $^O eq 'MSWin32' ? 'exit-ssh.cmd' : 'exit-ssh');
{
	open my $fh, '>', $script or die "Cannot write $script: $!";
	print {$fh} "#!$^X\n", <<'PERL';
open my $out, '>', $ENV{FAKE_ARGV} or die "Cannot write $ENV{FAKE_ARGV}: $!";
print {$out} "$_\n" for @ARGV;
close $out;
1 while <STDIN>;
exit($ENV{FAKE_EXIT} || 0);
PERL
	close $fh;

	if ($^O eq 'MSWin32') {
		# As in t/ssh.t: cmd.exe runs the wrapper, which restores the
		# interpreter and hands every argument on.
		open my $wrapper, '>:raw', $fake or die "Cannot write $fake: $!";
		print {$wrapper} "\@echo off\r\n", qq("$^X" "$script" %*\r\n);
		close $wrapper;
	} else {
		rename $script, $fake or die "Cannot rename $script to $fake: $!";
		chmod 0755, $fake or die "chmod: $!";
	}
}

my $argv_file = File::Spec->catfile($base, 'argv');
local $ENV{FAKE_ARGV} = $argv_file;
my $recorded = sub {
	open my $in, '<', $argv_file or die "Cannot read $argv_file: $!";
	chomp(my @argv = <$in>);
	return \@argv;
};

{
	local $ENV{FAKE_EXIT} = 0;
	my $ssh = App::FileSync::Transport::SSH->new(
		server => 'user@host', repo => 'docs', client => 'laptop', role => 'replica',
		command => $fake, port => 2222, identity => '/keys/id', known_hosts => '/keys/known',
		host_key_checking => 'accept-new',
	);

	my $command = $ssh->command();
	my @tail = (
		'-o', 'StrictHostKeyChecking=accept-new', '-o', 'UserKnownHostsFile=/keys/known',
		'-i', '/keys/id', '-p', 2222,
		'user@host', 'filesync-server', '--repo', 'docs', '--client', 'laptop', '--role', 'replica', '--proto', $PROTOCOL_VERSION,
	);
	my ($at) = grep { $command->[$_] eq $fake } 0 .. $#{$command};
	ok(defined $at, 'command starts with the ssh program (after cmd.exe on Windows)');
	is($command->[$at + 1], '-T', 'then the fixed ssh options');
	is_deeply([ @{$command}[ $#{$command} - $#tail .. $#{$command} ] ], \@tail,
		'then the chosen options, the host and the pinned server command');

	push @{$command}, 'tampered';
	is_deeply($ssh->command(), [ @{$command}[ 0 .. $#{$command} - 1 ] ], 'command returns a copy');

	is($ssh->exit_status(), undef, 'exit_status is undef before close');
	is($ssh->close(), 1, 'an ssh that exits 0 is a good close');
	is($ssh->exit_status(), 0, 'and exit_status is 0');
	is_deeply($recorded->(), [ @{$command}[ $at + 1 .. $#{$command} - 1 ] ], 'ssh was run with exactly that argv');
}

{
	local $ENV{FAKE_EXIT} = 3;
	my $ssh = App::FileSync::Transport::SSH->new(server => 'host', repo => 'docs', client => 'laptop', command => $fake);
	is($ssh->close(), 0, 'an ssh that exits 3 is a failed close');
	is($ssh->exit_status(), 3, 'and exit_status is 3');
	is($ssh->close(), 1, 'a second close returns 1');
	is($ssh->exit_status(), 3, 'and keeps the status');
}


# --- Transport::SSH: extra_args ----------------------------------------------------

# The client config's ssh.extra_args go on the command line just before the
# host.  Each must be a defined, plain string with no NUL or newline: the
# argv is handed to ssh as it is, and the remote end splits a command line.
{
	local $ENV{FAKE_EXIT} = 0;
	my $ssh = App::FileSync::Transport::SSH->new(
		server => 'host', repo => 'docs', client => 'laptop', command => $fake,
		extra_args => [ '-o', 'Compression=yes', '-v', 'with space', '$(not run)' ],
	);
	my $command = $ssh->command();
	my ($host) = grep { $command->[$_] eq 'host' } 0 .. $#{$command};
	is_deeply([ @{$command}[ $host - 5 .. $host - 1 ] ], [ '-o', 'Compression=yes', '-v', 'with space', '$(not run)' ],
		'extra_args go in order, unchanged, just before the host');
	$ssh->close();

	my %bad = (
		'an undefined element' => [ [ '-v', undef ], qr/bad extra_args ''/ ],
		'a reference'          => [ [ [ '-v' ] ], qr/bad extra_args 'ARRAY\(/ ],
		'a newline'            => [ [ "-v\n-oProxyCommand=evil" ], qr/bad extra_args '-v/ ],
		'a NUL'                => [ [ "-v\0x" ], qr/bad extra_args '-v/ ],
	);
	for my $case (sort keys %bad) {
		my ($extra, $error) = @{ $bad{$case} };
		throws_ok {
			App::FileSync::Transport::SSH->new(server => 'host', repo => 'docs', client => 'laptop', command => $fake, extra_args => $extra)
		} qr/\ASSH transport: $error/, "$case is refused";
	}
	throws_ok {
		App::FileSync::Transport::SSH->new(server => 'host', repo => 'docs', client => 'laptop', command => $fake, extra_args => '-v')
	} qr/'extra_args'/, 'extra_args that is not a list is refused';
	my ($at) = grep { $command->[$_] eq $fake } 0 .. $#{$command};
	is_deeply($recorded->(), [ @{$command}[ $at + 1 .. $#{$command} ] ],
		'a refused transport starts no ssh: the last argv recorded is the good one');
}

# --- Transport::Local::error_text ------------------------------------------------

# The local server shares this process's stderr, so the transport has nothing
# of its own to add: error_text is empty before and after a whole session.
{
	my $env = TestSync->new_env();
	my $local = App::FileSync::Transport::Local->new(root => $env->{server}, repo => 'docs', client => 'test-1');
	is($local->error_text(), '', 'error_text is empty while the session runs');

	my $connection = App::FileSync::Protocol->new(in => $local->reader(), out => $local->writer());
	$connection->send({ cmd => 'hello', proto => $PROTOCOL_VERSION, repo => 'docs', client => 'test-1', role => 'client' });
	ok($connection->recv()->{ok}, 'the local server answers');
	$connection->send({ cmd => 'done' });
	$connection->recv();
	is($local->close(), 1, 'the session closes');
	is($local->error_text(), '', 'and error_text is still empty');
}

# --- Store::root and Store::repo ---------------------------------------------------

{
	my $env = TestSync->new_env();
	my $store = App::FileSync::Store->new(root => $env->{server}, repo => 'docs');
	is($store->root(), $env->{server}, 'root is the server root it was given');
	is($store->repo(), 'docs', 'repo is the repo name');
	is($store->master_dir(), File::Spec->catdir($store->root(), 'master', $store->repo()),
		'and the master tree is built from them');
}

done_testing();
