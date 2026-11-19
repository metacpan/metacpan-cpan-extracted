#!/usr/bin/env perl

# One subtest per bug fixed in the 0.001.1 review.  Each states the old
# behaviour, so a failure here says which regression came back.

use strict;
use warnings;

use Digest::SHA ();
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;
use Test::Permissions qw(:revoke :guard);

use lib 't/lib';
use TestSync;
use App::FileSync::Admin;
use App::FileSync::Args;
use App::FileSync::CLI;
use App::FileSync::Client;
use App::FileSync::Config;
use App::FileSync::Delta;
use App::FileSync::I18N qw(strip_location);
use App::FileSync::Ignore;
use App::FileSync::Merge;
use App::FileSync::Process;
use App::FileSync::Protocol;
use App::FileSync::Scan;
use App::FileSync::Server;
use App::FileSync::Settings;
use App::FileSync::Store;
use App::FileSync::Transport::Local;
use App::FileSync::Transport::SSH;
use App::FileSync::Trash;
use App::FileSync::Verify;

my $T0 = 1_700_000_000;

# --- helpers ----------------------------------------------------------------

# Open a raw session as the env's client, send the client tree's manifest and
# ask for a plan.  Returns { transport, conn, plan => { path => action } }.
# The server's stderr goes to a temporary file: these sessions end abruptly
# on purpose and its "connection closed" diagnostics are expected, but when a
# call finds the server gone, call() shows what it said.
sub session {
	my ($env) = @_;

	my $log = File::Spec->catfile(tempdir(CLEANUP => 1), 'server.err');
	open my $saved, '>&', \*STDERR or die "dup stderr: $!";
	open STDERR, '>', $log or die "stderr to $log: $!";
	my $transport = App::FileSync::Transport::Local->new(root => $env->{server}, repo => 'docs', client => 'test-1');
	open STDERR, '>&', $saved or die "restore stderr: $!";

	my $conn = App::FileSync::Protocol->new(in => $transport->reader(), out => $transport->writer());
	$conn->send({
		cmd => 'hello', proto => 2, client => 'test-1', host => 'test', os => $^O,
		role => 'client', repo => 'docs', case_insensitive => 0, now => time,
	});
	my $hello = $conn->recv();
	die 'session refused' unless $hello->{ok};

	# Scan with the server's own ignore list, as the real client does.
	my $ignore = App::FileSync::Ignore->new(patterns => $hello->{policy}{ignore});
	my $manifest = App::FileSync::Scan::scan(root => $env->{client}, ignore => $ignore)->{manifest};
	$conn->send({ cmd => 'manifest', part => 0, of => 1, entries => [ map { { p => $_, %{ $manifest->{$_} } } } sort keys %{$manifest} ] });
	die 'manifest refused' unless $conn->recv()->{ok};

	$conn->send({ cmd => 'plan' });
	my $plan = $conn->recv();
	die 'no plan' unless $plan->{ok};

	return { transport => $transport, conn => $conn, log => $log, plan => { map { $_->{p} => $_ } @{ $plan->{actions} } } };
}

# Send one message (with optional data) and return the reply.  If the
# connection fails, the server's stderr is shown before the error is rethrown.
sub call {
	my ($session, $message, $bytes) = @_;

	my $reply = eval {
		defined $bytes ? $session->{conn}->send_data($message, $bytes) : $session->{conn}->send($message);
		$session->{conn}->recv();
	};
	return $reply if $reply;

	my $error = $@;
	if (open my $fh, '<', $session->{log}) {
		local $/;
		my $said = <$fh>;
		diag("the server's stderr:\n$said") if defined $said && length $said;
	}
	die $error;
}

sub sha256_hex {
	my ($bytes) = @_;
	return Digest::SHA::sha256_hex($bytes);
}

# An env whose a.txt was synced, then changed on both sides: the client's
# copy is newer, so the plan is a conflict the client wins.
sub conflict_env {
	my $env = TestSync->new_env();
	$env->write_file('client', 'a.txt', "v0\n", $T0);
	$env->sync();
	$env->write_file('server', 'a.txt', "server\n", $T0 + 10);
	$env->write_file('client', 'a.txt', "client\n", $T0 + 20);
	return $env;
}

# --- Ignore -----------------------------------------------------------------

subtest 'Ignore: the caller\'s pattern list is not modified' => sub {
	# Old: new() stripped the "!" in place, so the next Ignore built from the
	# same list ignored keep.tmp - and a later sync deleted it remotely.
	my @patterns = ('*.tmp', '!keep.tmp');
	App::FileSync::Ignore->new(patterns => \@patterns);
	is_deeply(\@patterns, [ '*.tmp', '!keep.tmp' ], 'list unchanged');
	ok(!App::FileSync::Ignore->new(patterns => \@patterns)->match('keep.tmp'), 'a second object still re-includes');
};

subtest 'Ignore: anchors and trailing slashes' => sub {
	my $ignore = App::FileSync::Ignore->new(patterns => [ '/top', 'build/' ]);
	ok($ignore->match('top'), '/top matches at the root');
	ok(!$ignore->match('sub/top'), '/top does not match deeper (old: it matched anywhere)');
	ok($ignore->match('build'), 'build/ matches build');
	ok($ignore->match('src/build'), 'build/ matches at any depth');
	ok($ignore->match('src/build/x.o'), 'and everything inside it');
};

# --- Trash ------------------------------------------------------------------

subtest 'Trash: same-day versions sort numerically, past .99' => sub {
	my $root = tempdir(CLEANUP => 1);
	my $src = tempdir(CLEANUP => 1);
	my @made;
	for my $n (0 .. 101) {
		my $file = File::Spec->catfile($src, 'a.txt');
		open my $fh, '>', $file or die $!;
		print {$fh} "version $n\n";
		close $fh;
		push @made, App::FileSync::Trash::move_to_trash(src => $file, rel => 'a.txt', root => $root, epoch => $T0);
	}
	like($made[-1], qr/a\.txt\.101\z/, 'the 102nd copy is .101 (old: capped at .99)');

	my $versions = App::FileSync::Trash::versions(root => $root, rel => 'a.txt');
	is(scalar @{$versions}, 102, 'every version is listed');
	like($versions->[0], qr/\.101\z/, 'newest first');
	my ($nine) = grep { $versions->[$_] =~ /\.9\z/ } 0 .. $#{$versions};
	my ($ten)  = grep { $versions->[$_] =~ /\.10\z/ } 0 .. $#{$versions};
	ok($ten < $nine, '.10 is newer than .9 (old: string order)');
	unlike($versions->[-1], qr/\.\d+\z/, 'the unsuffixed original is oldest');
};

# --- Server: a hostile client talking the protocol directly ----------------

subtest 'Server: conflict copy is kept even without conflict_name' => sub {
	my $env = conflict_env();
	my $s = session($env);
	my $action = $s->{plan}{'a.txt'};
	is($action->{a}, 'conflict', 'a.txt is a conflict');
	is($action->{winner}, 'client', 'the client wins');

	# Old: the server only preserved the master's copy when the client named
	# it, so a client that left the field out silently destroyed it.
	my $content = "client\n";
	my $reply = call($s, { cmd => 'put', p => 'a.txt', s => length $content, h => sha256_hex($content), m => $T0 + 20, mode => 0644 });
	ok($reply->{ok}, 'put accepted');
	is($env->read_file('server', $action->{loser_name}), "server\n", 'the master copy is preserved under the planned name');
	$s->{transport}->close();
};

subtest 'Server: a conflict_name other than the planned one is refused' => sub {
	my $env = conflict_env();
	my $s = session($env);
	my $content = "client\n";
	my $reply = call($s, {
		cmd => 'put', p => 'a.txt', s => length $content, h => sha256_hex($content), m => $T0 + 20, mode => 0644,
		conflict_name => '../../escape.txt',
	});
	ok(!$reply->{ok}, 'refused');
	like($reply->{error}, qr/must be named '\Q$s->{plan}{'a.txt'}{loser_name}\E'/, 'and names the planned copy');
	unlike($reply->{error}, qr/ line \d+/, 'no Perl location reaches the client');
	ok(!-e File::Spec->catfile($env->{server}, 'escape.txt'), 'nothing written outside');
	$s->{transport}->close();
};

subtest 'Server: each request is refused for every planned action it does not serve' => sub {
	# One path for each kind of planned action.  Two of the four synced files
	# are deleted, so the percentage guard is switched off.
	my $env = TestSync->new_env();
	my $policy = App::FileSync::Config::load_repo($env->{server}, 'docs');
	$policy->{max_delete_percent} = 0;
	App::FileSync::Config::save_repo($env->{server}, 'docs', $policy);

	$env->write_file('client', $_, "v0\n", $T0) for qw(gone-there.txt gone-here.txt client-wins.txt master-wins.txt);
	$env->sync();
	$env->write_file('server', 'new-there.txt', "new\n", $T0 + 10);
	$env->write_file('client', 'new-here.txt', "new\n", $T0 + 10);
	unlink $env->server_path('gone-there.txt') or die $!;
	unlink $env->client_path('gone-here.txt') or die $!;
	$env->write_file('server', 'client-wins.txt', "server\n", $T0 + 10);
	$env->write_file('client', 'client-wins.txt', "client\n", $T0 + 20);
	$env->write_file('client', 'master-wins.txt', "client\n", $T0 + 10);
	$env->write_file('server', 'master-wins.txt', "server\n", $T0 + 20);

	my %path = (
		pull              => 'new-there.txt',
		push              => 'new-here.txt',
		delete_local      => 'gone-there.txt',
		delete_remote     => 'gone-here.txt',
		'conflict:client' => 'client-wins.txt',
		'conflict:remote' => 'master-wins.txt',
	);
	my $s = session($env);
	my %planned = map {
		my $action = $s->{plan}{ $path{$_} } || {};
		($_ => ($action->{a} // '') eq 'conflict' ? "conflict:$action->{winner}" : $action->{a} // '')
	} keys %path;
	is_deeply(\%planned, { map { $_ => $_ } keys %path }, 'the plan has one path for each kind of action');
	$s->{transport}->close();

	# The request each kind of _expect gate serves, and the actions it may
	# serve.  Every other pairing must be refused at the gate, before the
	# server looks at anything else in the request.
	my %request = (
		get  => [ 'read',   qw(pull conflict:remote) ],
		put  => [ 'write',  qw(push conflict:client) ],
		sig  => [ 'delta',  qw(push) ],
		dsig => [ 'pull',   qw(pull) ],
		mkdir => [ 'mkdir', qw(push) ],
		del  => [ 'delete', qw(delete_remote) ],
		ack  => [ 'ack',    qw(pull delete_local conflict:remote) ],
	);
	for my $cmd (sort keys %request) {
		my ($kind, @may) = @{ $request{$cmd} };
		my %may = map { $_ => 1 } @may;
		for my $action (sort grep { !$may{$_} } keys %path) {
			my $session = session($env);
			my $reply = call($session, { cmd => $cmd, p => $path{$action} });
			ok(!$reply->{ok}, "$cmd ($kind) of a planned $action is refused");
			like($reply->{error}, qr/\A\S.* of '\Q$path{$action}\E' is not in the plan\z/, '... at the plan gate');
			$session->{transport}->close();
		}
	}
	ok($env->exists_in('server', 'gone-here.txt'), 'and the refused requests changed nothing on the master');
	ok(!$env->exists_in('server', 'new-here.txt'), 'nothing was created there either');
};

subtest 'Server: filesync-server exits 0 after a good session and 1 after a failed one' => sub {
	# ssh hands the server's exit status back to the client, so it must say
	# whether the session worked.  Nothing checked it, and Server::run could
	# have reported success as failure unnoticed.
	my $env = TestSync->new_env();
	my $exit = sub {
		my ($repo, @messages) = @_;
		open my $saved, '>&', \*STDERR or die "dup stderr: $!";
		open STDERR, '>', File::Spec->devnull() or die "null stderr: $!";
		my $child = App::FileSync::Process::spawn(command => [
			$^X, '-Ilib', 'bin/filesync-server',
			'--root', $env->{server}, '--repo', $repo, '--client', 'test-1', '--role', 'client',
		], stderr => fileno(STDERR));
		open STDERR, '>&', $saved or die "restore stderr: $!";

		my $conn = App::FileSync::Protocol->new(in => $child->{reader}, out => $child->{writer});
		my @replies;
		for my $message (@messages) {
			$conn->send($message);
			push @replies, $conn->recv();
			last unless $replies[-1]{ok};
		}
		close $child->{writer};
		close $child->{reader};
		return (App::FileSync::Process::reap(pid => $child->{pid})->{status}, \@replies);
	};
	my %hello = (
		cmd => 'hello', proto => 2, client => 'test-1', host => 'test', os => $^O,
		role => 'client', repo => 'docs', case_insensitive => 0, now => time,
	);

	my ($status, $replies) = $exit->('docs',
		\%hello, { cmd => 'manifest', part => 0, of => 1, entries => [] }, { cmd => 'plan' }, { cmd => 'done' });
	is(scalar(grep { $_->{ok} } @{$replies}), 4, 'a whole session is served');
	is($status, 0, 'and the server exits 0');

	($status, $replies) = $exit->('no-such-repo', { %hello, repo => 'no-such-repo' });
	ok(!$replies->[0]{ok}, 'a session for a missing repo is refused');
	is($status, 1, 'and the server exits 1');
};

subtest 'Server: ack is accepted only for actions the client applies' => sub {
	my $env = TestSync->new_env();
	$env->write_file('client', 'new.txt', "push me\n", $T0);
	my $s = session($env);
	is($s->{plan}{'new.txt'}{a}, 'push', 'new.txt is a push');

	# Old: any planned path could be acked, so a push could be marked done
	# without its content ever being sent.
	my $reply = call($s, { cmd => 'ack', p => 'new.txt', h => sha256_hex("push me\n"), s => 8, m => $T0 });
	ok(!$reply->{ok}, 'ack of a push is refused');
	like($reply->{error}, qr/not in the plan/, 'with the plan error');
	$s->{transport}->close();

	$env = TestSync->new_env();
	$env->write_file('server', 'pull.txt', "pull me\n", $T0);
	$s = session($env);
	is($s->{plan}{'pull.txt'}{a}, 'pull', 'pull.txt is a pull');
	$reply = call($s, { cmd => 'ack', p => 'pull.txt', deleted => 1 });
	ok(!$reply->{ok}, 'a "deleted" ack for a pull is refused');
	like($reply->{error}, qr/does not match its planned action/, 'with server.bad_ack');
	$s->{transport}->close();
};

subtest 'Server: get validates offset and size' => sub {
	my $env = TestSync->new_env();
	$env->write_file('server', 'pull.txt', "0123456789", $T0);

	my $s = session($env);
	my $reply = call($s, { cmd => 'get', p => 'pull.txt', off => 0, max => 4 });
	ok($reply->{ok}, 'a normal get works');
	is($s->{conn}->read_data($reply), '0123', 'and honours max');
	ok(!$reply->{eof}, 'not at the end');

	$reply = call($s, { cmd => 'get', p => 'pull.txt', off => 0, max => 1e12 });
	ok($reply->{ok}, 'a huge max is clamped, not obeyed or refused');
	is($s->{conn}->read_data($reply), '0123456789', 'the whole (small) file');
	$s->{transport}->close();

	for my $bad ([ off => 11 ], [ off => -1 ], [ off => 'x' ], [ max => '1e3' ]) {
		my $session = session($env);
		$reply = call($session, { cmd => 'get', p => 'pull.txt', off => 0, @{$bad} });
		ok(!$reply->{ok}, "$bad->[0] => $bad->[1] is refused");
		like($reply->{error}, qr/Bad '$bad->[0]'/, 'naming the field');
		$session->{transport}->close();
	}
};

subtest 'Server: a pull signature is accepted up to its limits and refused past them' => sub {
	# A client's signature for a delta pull is bounded so it cannot make the
	# server hold or hash an unreasonable amount: at most 16384 blocks, each
	# 1 KiB to 1 MiB.  The limits themselves are allowed.
	my $env = TestSync->new_env();
	$env->write_file('server', 'pull.txt', "pull me\n", $T0);
	my $record = "\0" x 36;	# a 4-byte weak and a 32-byte strong checksum

	for my $case (
		[ 'the most blocks',      16_384, 1_024,         1 ],
		[ 'one block too many',   16_385, 1_024,         0 ],
		[ 'the smallest block',   1,      1_024,         1 ],
		[ 'a block too small',    1,      1_023,         0 ],
		[ 'the largest block',    1,      1_048_576,     1 ],
		[ 'a block too large',    1,      1_048_577,     0 ],
	) {
		my ($name, $count, $block, $accepted) = @{$case};
		my $s = session($env);
		is($s->{plan}{'pull.txt'}{a}, 'pull', "$name: pull.txt is a pull");
		my $reply = call($s, { cmd => 'dsig', p => 'pull.txt', n => $count, b => $block }, $record x $count);
		if ($accepted) {
			ok($reply->{ok}, "$name ($count x $block) is accepted");
			is($reply->{delta}, 0, '... and a file this small is sent whole');
		} else {
			ok(!$reply->{ok}, "$name ($count x $block) is refused");
			like($reply->{error}, qr/\ABad signature for 'pull\.txt'\z/, '... as a bad signature');
		}
		$s->{transport}->close();
	}
};

subtest 'Server: a refused request still reads its payload, so the client gets the reason' => sub {
	# Old: the server refused a dsig on its header and exited without reading
	# the signature after it.  A client still writing that payload got a
	# broken pipe instead of the refusal - always on Windows, where the
	# server usually won the race, and here once the server has had time.
	local $SIG{PIPE} = 'IGNORE';
	my $env = TestSync->new_env();
	$env->write_file('server', 'pull.txt', "pull me\n", $T0);

	my $s = session($env);
	is($s->{plan}{'pull.txt'}{a}, 'pull', 'pull.txt is a pull');
	my $payload = "\0" x 36;
	$s->{conn}->send({ cmd => 'dsig', p => 'pull.txt', n => 1, b => 1_023, len => length $payload });
	sleep 1;	# long enough for the old server to refuse and exit
	my $reply = eval { $s->{conn}->send_bytes($payload); $s->{conn}->recv() };
	ok($reply, 'the payload is written and a reply comes back') or diag($@);
	ok($reply && !$reply->{ok}, 'the reply is a refusal');
	like($reply && $reply->{error}, qr/\ABad signature for 'pull\.txt'\z/, 'which gives the reason');
	$s->{transport}->close();
};

subtest 'Server: a delta pull no smaller than the file is not sent' => sub {
	# The server estimates a delta's size as its literal bytes plus 12 bytes a
	# record plus 64, and sends the file whole unless that is smaller.  This
	# file makes the estimate exactly its size: the client's signature matches
	# only its first 1 KiB block, and the rest (one repeated byte the block
	# never matches) goes as 79 literal records of $LITERAL bytes, so the
	# estimate is 79 * $LITERAL + 12 * 80 + 64 = 1024 + 79 * $LITERAL.
	#
	# No smaller file will do: a 1 KiB block is the least the server accepts,
	# so the 80 records must cover about 20 MB, held in memory and written
	# to disk twice.  That is too much to ask of every CPAN smoker, so it
	# runs on GitHub Actions (where the mutation workflow needs it to kill the
	# boundary mutant in Server's delta check) or with EXTENDED_TESTING.
	plan skip_all => 'builds a 20 MB file: set EXTENDED_TESTING to run it'
		unless $ENV{EXTENDED_TESTING} || $ENV{GITHUB_ACTIONS};
	my $env = TestSync->new_env();
	srand 23;
	my $head = join '', map { chr int rand 256 } 1 .. 1_024;
	my $content = $head . ('a' x (79 * $App::FileSync::Delta::LITERAL));
	$env->write_file('server', 'big.bin', $content, $T0);
	my $signature = App::FileSync::Delta::signature($env->server_path('big.bin'), 1_024);
	my $first = App::FileSync::Delta::encode_signature({ blocks => [ $signature->{blocks}[0] ] });

	my $s = session($env);
	is($s->{plan}{'big.bin'}{a}, 'pull', 'big.bin is a pull');
	my $reply = call($s, { cmd => 'dsig', p => 'big.bin', n => 1, b => 1_024 }, $first);
	ok($reply->{ok}, 'the signature is accepted');
	is($reply->{delta}, 0, 'a delta estimated at exactly the file size is not sent');
	$s->{transport}->close();

	# Matching the second block too ("a" x 1024) turns the run of "a"s into
	# copies: the delta is far smaller, and is sent.
	$s = session($env);
	my $two = App::FileSync::Delta::encode_signature({ blocks => [ @{ $signature->{blocks} }[ 0, 1 ] ] });
	$reply = call($s, { cmd => 'dsig', p => 'big.bin', n => 2, b => 1_024 }, $two);
	is($reply->{delta}, 1, 'a smaller delta is sent');
	$s->{transport}->close();
};

subtest 'Server: an upload larger than announced is refused and discarded' => sub {
	my $env = TestSync->new_env();
	$env->write_file('client', 'new.txt', "abc", $T0);
	my $s = session($env);
	ok(call($s, { cmd => 'put', p => 'new.txt', s => 3, h => sha256_hex('abc'), m => $T0, mode => 0644 })->{ok}, 'put accepted');

	# Old: the server appended whatever arrived and only noticed at the end,
	# so a client could fill the disk under a small announced size.
	my $reply = call($s, { cmd => 'chunk', p => 'new.txt' }, 'abcdefgh');
	ok(!$reply->{ok}, 'the oversized chunk is refused');
	like($reply->{error}, qr/larger than announced/, 'with server.overflow');
	$s->{transport}->close();

	# tree() takes a directory: this check used to pass 'server', which
	# listed nothing, so a temporary file left behind went unnoticed.
	ok(!$env->exists_in('server', 'new.txt'), 'nothing was committed');
	my $temps = sub { [ grep { /filesync-tmp/ } @{ $env->tree($env->{server}) } ] };
	is_deeply($temps->(), [], 'and no temporary file is left');

	# A client that goes away mid-upload: the failed session discards it.
	$s = session($env);
	ok(call($s, { cmd => 'put', p => 'new.txt', s => 3, h => sha256_hex('abc'), m => $T0, mode => 0644 })->{ok}, 'another put');
	$s->{conn}->send_data({ cmd => 'chunk', p => 'new.txt' }, 'a');
	ok($s->{conn}->recv()->{ok}, 'and part of it arrives');
	is(scalar @{ $temps->() }, 1, 'into a temporary file');
	$s->{transport}->close();
	is_deeply($temps->(), [], 'which is removed when the client goes away');
};

subtest 'Server: unfinished actions are listed in order' => sub {
	my $env = TestSync->new_env();
	$env->write_file('server', $_, "$_\n", $T0) for qw(z.txt c.txt m.txt);
	my $s = session($env);
	my $reply = call($s, { cmd => 'done' });
	ok(!$reply->{ok}, 'done before the work is refused');
	like($reply->{error}, qr/c\.txt, m\.txt, z\.txt/, 'paths are sorted (old: hash order)');
	$s->{transport}->close();
};

# --- Store and Admin: names that become paths -------------------------------

subtest 'Store and Admin reject names that would escape the root' => sub {
	my $env = TestSync->new_env();
	throws_ok { App::FileSync::Store->new(root => $env->{server}, repo => '../etc') } qr/repo/i, 'Store: ../etc';

	my $admin = App::FileSync::Admin->new(root => $env->{server});
	throws_ok { $admin->client_forget(repo => 'docs', client => '../x') } qr/client/i, 'client_forget ../x';
	throws_ok { $admin->client_allow(repo => 'docs', client => 'a' x 65) } qr/client/i, 'a 65-character id';
	lives_ok { $admin->client_allow(repo => 'docs', client => 'a' x 64) } 'a 64-character id is fine';
	throws_ok { $admin->client_allow(repo => 'nope', client => 'x') } qr/nope/, 'an unknown repo';
};

subtest 'Admin: repo create says how to fix an unwritable root' => sub {
	my $parent = tempdir(CLEANUP => 1);

	# Test::Permissions finds out whether chmod can really stop new files
	# here (not as root, under fakeroot, on Windows or on a filesystem that
	# ignores modes), and with_revoked restores each mode even if a test dies.
	plan skip_all => why_not('create', $parent) unless can_revoke_create($parent);

	my $root = File::Spec->catdir($parent, 'filesync');
	make_path($root);
	my $admin = App::FileSync::Admin->new(root => $root);

	# Old: make_path reported "Cannot create directory .../master/docs:
	# Permission denied", naming a path below the root the caller passed.
	with_revoked(create => $root, sub {
		throws_ok { $admin->repo_create(name => 'docs') }
			qr/not writable by this account .*chown/s, 'the root and the remedy are named';
	});

	# The same mistake one level down: the root is ours, its master is not.
	my $master = File::Spec->catdir($root, 'master');
	make_path($master);
	with_revoked(create => $master, sub {
		throws_ok { $admin->repo_create(name => 'docs') }
			qr/not writable by this account \(\Q$master\E\)/, 'an unwritable master directory is named';
	});

	lives_ok { $admin->repo_create(name => 'docs') } 'a writable root still creates the repo';
};

subtest 'Admin: journal_read works under a root containing spaces' => sub {
	my $parent = tempdir(CLEANUP => 1);
	my $root = File::Spec->catdir($parent, 'with some spaces');
	make_path($root);
	my $admin = App::FileSync::Admin->new(root => $root);
	$admin->repo_create(name => 'docs');
	App::FileSync::Store->new(root => $root, repo => 'docs')->journal({ action => 'restore', client => 'c1', path => 'x' });

	# Old: glob split the root into words and found no journal at all.
	my $events = $admin->journal_read(repo => 'docs');
	is(scalar @{$events}, 1, 'the event is read');
	is($events->[0]{action}, 'restore', 'and parsed');
};

subtest 'Admin: restore --date picks that day, and checks the format' => sub {
	my $env = TestSync->new_env();
	my $store = App::FileSync::Store->new(root => $env->{server}, repo => 'docs');
	my $src = tempdir(CLEANUP => 1);
	my %day = (old => $T0, new => $T0 + 3 * 86_400);
	my %where;
	for my $which (sort keys %day) {
		my $file = File::Spec->catfile($src, 'a.txt');
		open my $fh, '>', $file or die $!;
		print {$fh} "$which\n";
		close $fh;
		$where{$which} = App::FileSync::Trash::move_to_trash(src => $file, rel => 'a.txt', root => $store->trash_dir(), epoch => $day{$which});
	}

	my $admin = App::FileSync::Admin->new(root => $env->{server});
	my $list = $admin->restore(repo => 'docs', path => 'a.txt', list => 1);
	is(scalar @{ $list->{versions} }, 2, 'both versions listed');

	# Without --date the newest wins; with it, that day's version.
	my $old_date = App::FileSync::Trash::date_of($where{old});
	my $done = $admin->restore(repo => 'docs', path => 'a.txt', to => tempdir(CLEANUP => 1), date => $old_date);
	is(do { open my $fh, '<', $done->{to} or die $!; local $/; <$fh> }, "old\n", 'the older version was chosen');

	throws_ok { $admin->restore(repo => 'docs', path => 'a.txt', to => tempdir(CLEANUP => 1), date => 'yesterday') }
		qr/yesterday/, 'a malformed date is refused';
	throws_ok { $admin->restore(repo => 'docs', path => 'a.txt', to => tempdir(CLEANUP => 1), date => '1999-01-01') }
		qr/1999-01-01/, 'a date with no version is refused';
};

subtest 'Store: trash_days 0 keeps the server trash forever, as on the client' => sub {
	my $root = tempdir(CLEANUP => 1);
	my $admin = App::FileSync::Admin->new(root => $root);
	$admin->repo_create(name => 'forever', trash_days => 0);
	$admin->repo_create(name => 'default');

	my $src = tempdir(CLEANUP => 1);
	for my $repo (qw(forever default)) {
		my $store = App::FileSync::Store->new(root => $root, repo => $repo);
		my $file = File::Spec->catfile($src, "$repo.txt");
		open my $fh, '>', $file or die $!;
		print {$fh} "old\n";
		close $fh;
		App::FileSync::Trash::move_to_trash(src => $file, rel => 'a.txt', root => $store->trash_dir(), epoch => $T0);
	}

	# Old: "||" turned the 0 into the 30-day default, so the server
	# pruned a bucket the policy said to keep.
	my $forever = App::FileSync::Store->new(root => $root, repo => 'forever');
	is($forever->{config}{trash_days}, 0, 'the policy records 0');
	is_deeply($forever->prune_trash(), [], 'nothing is pruned with trash_days 0');
	is(scalar @{ App::FileSync::Trash::versions(root => $forever->trash_dir(), rel => 'a.txt') }, 1, 'the old version is still there');

	my $default = App::FileSync::Store->new(root => $root, repo => 'default');
	is(scalar @{ $default->prune_trash() }, 1, 'the 30-day default still prunes the old bucket');

	# The client already read 0 this way; Trash::prune is the shared rule.
	is_deeply(App::FileSync::Trash::prune(root => $forever->trash_dir(), days => 0), [], 'Trash::prune keeps everything at 0 days');

	# Old: "repo show" printed "trash: 0 days" for a repo that keeps
	# everything.
	my $show = sub { my $repo = shift; scalar `$^X -Ilib bin/filesync-admin --root "$root" repo show $repo 2>&1` };
	like($show->('forever'), qr/^trash:\s+kept forever$/m, 'repo show says kept forever');
	like($show->('default'), qr/^trash:\s+kept 30 days$/m, 'and the default in days');

	# A policy with no trash_days prunes at the default, so it is not "forever".
	my $policy = App::FileSync::Config::load_repo($root, 'default');
	delete $policy->{trash_days};
	App::FileSync::Config::save_repo($root, 'default', $policy);
	like($show->('default'), qr/^trash:\s+kept 30 days$/m, 'a policy without trash_days shows the default');
};

subtest 'CLI: repo show says when a deletion limit is switched off' => sub {
	my $root = tempdir(CLEANUP => 1);
	my $admin = App::FileSync::Admin->new(root => $root);
	my %repos = (
		defaults => [ {}, qr{200 files / 10%} ],
		one      => [ { max_deletes => 1 }, qr{1 file / 10%} ],
		nofiles  => [ { max_deletes => 0 }, qr{no file limit / 10%} ],
		nopct    => [ { max_delete_percent => 0 }, qr{200 files / no percentage limit} ],
		none     => [ { max_deletes => 0, max_delete_percent => 0 }, qr{none \(any number of deletions\)} ],
	);

	# Old: both limits at 0 printed "limits:  0 files / 0%", which reads as
	# "nothing may be deleted" when it means "anything may".
	for my $repo (sort keys %repos) {
		my ($limits, $expected) = @{ $repos{$repo} };
		$admin->repo_create(name => $repo, %{$limits});
		my $out = `$^X -Ilib bin/filesync-admin --root "$root" repo show $repo 2>&1`;
		like($out, qr/^limits:\s+$expected$/m, "$repo: the limits line");
	}

	# A policy missing both limits is checked at the defaults, so says so.
	my $policy = App::FileSync::Config::load_repo($root, 'none');
	delete @{$policy}{qw(max_deletes max_delete_percent)};
	App::FileSync::Config::save_repo($root, 'none', $policy);
	like(scalar `$^X -Ilib bin/filesync-admin --root "$root" repo show none 2>&1`,
		qr{^limits:\s+200 files / 10%$}m, 'missing limits show the defaults');
};

subtest 'Admin: --max-delete-percent is at most 100' => sub {
	my $root = tempdir(CLEANUP => 1);
	my $admin = App::FileSync::Admin->new(root => $root);

	# Old: 150 was accepted and stored, a percentage of more than the repo.
	throws_ok { $admin->repo_create(name => 'over', max_delete_percent => 150) }
		qr/max_delete_percent.*no more than 100/, '150 is refused';
	throws_ok { $admin->repo_create(name => 'over', max_delete_percent => 101) }
		qr/no more than 100/, '101 is refused';
	ok(!-e App::FileSync::Config::repo_config_path($root, 'over'), 'and no repo is created');

	lives_ok { $admin->repo_create(name => 'full', max_delete_percent => 100) } '100 is accepted';
	is(App::FileSync::Config::load_repo($root, 'full')->{max_delete_percent}, 100, 'and stored');

	my $out = `$^X -Ilib bin/filesync-admin --root "$root" repo create cli --max-delete-percent 150 2>&1`;
	isnt($? >> 8, 0, 'the CLI exits non-zero');
	like($out, qr/no more than 100/, 'and says why');
};

subtest 'Args: validation failures are catalogued and name the option' => sub {
	my $schema = {
		count => { type => 'integer', min => 0, max => 10, optional => 1 },
		ratio => { type => 'number', optional => 1 },
		name  => { type => 'string', min => 2, max => 4, optional => 1 },
		list  => { type => 'arrayref', min => 1, optional => 1 },
		role  => { type => 'string', memberof => [ 'client', 'replica' ], optional => 1 },
		date  => { type => 'string', matches => qr/\A\d{4}\z/, optional => 1 },
		need  => { type => 'string' },
	};
	my $call = sub { App::FileSync::Args::named([ need => 'x', @_ ], $schema, 'Test::routine') };

	# Old: the validator's own English, naming the parameter, such as
	# "Parameter 'count' (11) must be no more than 10".
	my %expect = (
		'count 11'   => [ [ count => 11 ],         qr/\ATest::routine: 'count' must be no more than 10, not 11$/m ],
		'count -1'   => [ [ count => -1 ],         qr/'count' must be at least 0, not -1$/m ],
		'count 1.5'  => [ [ count => 1.5 ],        qr/'count' must be a whole number, not '1\.5'$/m ],
		'count x'    => [ [ count => 'x' ],        qr/'count' must be a whole number, not 'x'$/m ],
		'ratio x'    => [ [ ratio => 'x' ],        qr/'ratio' must be a number, not 'x'$/m ],
		'name short' => [ [ name => 'a' ],         qr/'name' must be at least 2 characters long$/m ],
		'name long'  => [ [ name => 'abcde' ],     qr/'name' must be at most 4 characters long$/m ],
		'list empty' => [ [ list => [] ],          qr/'list' must have at least 1 entry$/m ],
		'role'       => [ [ role => 'boss' ],      qr/'role' must be one of client, replica, not 'boss'$/m ],
		'date'       => [ [ date => 'May' ],       qr/'date' is not in the expected form: 'May'$/m ],
		'unknown'    => [ [ bogus => 1 ],          qr/'bogus' is not a known argument$/m ],
	);
	for my $case (sort keys %expect) {
		my ($args, $error) = @{ $expect{$case} };
		throws_ok { $call->(@{$args}) } $error, $case;
	}
	throws_ok { App::FileSync::Args::named([], $schema, 'Test::routine') }
		qr/'need' is required$/m, 'missing';

	# A failure it cannot name keeps the validator's text, without its location.
	throws_ok { $call->(list => 'x') } qr/\ATest::routine: Parameter 'list' must be an arrayref/, 'a wrong reference type falls back';

	# Inside with_options the option is named instead; outside, the parameter again.
	throws_ok { App::FileSync::Args::with_options({ count => '--count' }, sub { $call->(count => 11) }) }
		qr/\A--count must be no more than 10, not 11$/m, 'with_options names the option';
	throws_ok { $call->(count => 11) } qr/\ATest::routine: 'count'/, 'and is undone after a failure';
	is(App::FileSync::Args::with_options({ count => '--count' }, sub { $call->(count => 3)->{count} }), 3,
		'with_options returns what the code returns');

	# Through the program: the option the user typed.
	my $root = tempdir(CLEANUP => 1);
	my $out = `$^X -Ilib bin/filesync-admin --root "$root" repo create docs --trash-days -1 2>&1`;
	isnt($? >> 8, 0, 'repo create --trash-days -1 fails');
	like($out, qr/^ERROR: --trash-days must be at least 0, not -1$/m, 'naming --trash-days');
	unlike($out, qr/trash_days|Admin::repo_create/, 'not the parameter or the routine');
};

subtest 'Merge: max_delete_percent above 100 is refused' => sub {
	# Old: the policy check accepted any percentage.
	throws_ok { App::FileSync::Merge::check_delete_limit(deletions => 1, base_size => 10, max_delete_percent => 150) }
		qr/'max_delete_percent' must be no more than 100, not 150/, '150 is refused';
	lives_ok { App::FileSync::Merge::check_delete_limit(deletions => 1, base_size => 10, max_delete_percent => 100) }
		'100 is accepted';
};

subtest 'Sync: a directory holding ignored files can become a file' => sub {
	# Old: the sync deleted the directory's listed files, then install_file
	# found it still holding an ignored .DS_Store and refused with "Cannot
	# replace non-empty directory", on this and every later sync.
	# The trashed directory is a version of x (x/y went to the trash first, so
	# it is usually x.1) that holds the .DS_Store.
	my $ds_store = sub {
		my $root = shift;
		return [ grep { -f File::Spec->catfile($_, '.DS_Store') } @{ App::FileSync::Trash::versions(root => $root, rel => 'x') } ];
	};

	# Pushed: the master's x/ holds the ignored file.
	{
		my $env = TestSync->new_env();
		$env->write_file('client', 'x/y', "inside\n", $T0);
		$env->sync();
		$env->write_file('server', 'x/.DS_Store', "finder\n", $T0);
		File::Path::remove_tree($env->client_path('x'));
		$env->write_file('client', 'x', "now a file\n", $T0 + 5);

		my $result = $env->sync();
		is($result->{exit}, 0, 'push: the sync succeeds');
		is($env->read_file('server', 'x'), "now a file\n", 'push: the master has the file');
		my $store = App::FileSync::Store->new(root => $env->{server}, repo => 'docs');
		is(scalar @{ $ds_store->($store->trash_dir()) }, 1, 'push: the ignored file is in the server trash');
		my ($event) = grep { ($_->{reason} // '') eq 'replaced by a file' }
			@{ App::FileSync::Admin->new(root => $env->{server})->journal_read(repo => 'docs') };
		is($event && $event->{path}, 'x', 'push: the journal records the directory going to the trash');
		is($env->sync()->{exit}, 0, 'push: and the next sync is clean');
	}

	# Pulled: the client's x/ holds the ignored file.
	{
		my $env = TestSync->new_env();
		$env->write_file('client', 'x/y', "inside\n", $T0);
		$env->sync();
		$env->write_file('client', 'x/.DS_Store', "finder\n", $T0);
		File::Path::remove_tree($env->server_path('x'));
		$env->write_file('server', 'x', "now a file\n", $T0 + 5);
		App::FileSync::Admin->new(root => $env->{server})->reindex(repo => 'docs');

		my $result = do { local $SIG{__WARN__} = sub {}; $env->sync() };
		is($result->{exit}, 0, 'pull: the sync succeeds');
		is($env->read_file('client', 'x'), "now a file\n", 'pull: the client has the file');
		my $trash = File::Spec->catdir($env->{home}, 'trash', 'repos', 'docs');
		is(scalar @{ $ds_store->($trash) }, 1, 'pull: the ignored file is in the local trash');
		is($env->sync()->{exit}, 0, 'pull: and the next sync is clean');
	}
};

subtest 'Server: errors sent to the client name no server paths' => sub {
	# Old: the client was sent the server's absolute paths, such as "Cannot
	# replace non-empty directory /srv/filesync/master/docs/x".

	# The rewriting itself, on a server rooted at /srv/filesync.
	my $server = sub {
		App::FileSync::Server->new(root => shift, repo => 'docs', client => 'c1', role => 'client', connection => bless({}, 'Stand::In'));
	};
	my $for_client = sub { my ($root, $text) = @_; $server->($root)->_for_client($text) };
	my $master = File::Spec->catdir('/srv/filesync', 'master', 'docs');
	my $meta = File::Spec->catfile('/srv/filesync', '.filesync', 'repos', 'docs', 'master.json');
	my $elsewhere = File::Spec->catfile('/srv/filesyncdata', 'x');
	my %cases = (
		'a path in the master is relative to the repo' =>
			[ '/srv/filesync', "Cannot replace non-empty directory $master/sub/x", 'Cannot replace non-empty directory sub/x' ],
		'every one of them' =>
			[ '/srv/filesync', "Cannot move $master/.filesync-tmp-1 to $master/a.txt: denied", 'Cannot move .filesync-tmp-1 to a.txt: denied' ],
		'another server path keeps only its place under the root' =>
			[ '/srv/filesync', "Cannot write $meta: full", 'Cannot write [server root]/.filesync/repos/docs/master.json: full' ],
		'the root on its own' =>
			[ '/srv/filesync', q{No such repo 'x' under /srv/filesync (run filesync-admin repo create)}, q{No such repo 'x' under [server root] (run filesync-admin repo create)} ],
		'a root given with a trailing slash' =>
			[ '/srv/filesync/', "Cannot replace non-empty directory $master/x", 'Cannot replace non-empty directory x' ],
		'a longer name that only starts with the root is left alone' =>
			[ '/srv/filesync', "Cannot read $elsewhere", "Cannot read $elsewhere" ],
	);
	for my $case (sort keys %cases) {
		my ($root, $text, $expected) = @{ $cases{$case} };
		is($for_client->($root, $text), $expected, $case);
	}

	# Through a real session: a master directory that refuses new files stops
	# the upload's temporary file, and the error names that directory.
	my $env = TestSync->new_env();
	plan skip_all => why_not('create', $env->{server}) unless can_revoke_create($env->{server});
	$env->write_file('client', 'sub/a.txt', "one\n", $T0);
	$env->sync();
	$env->write_file('client', 'sub/b.txt', "two\n", $T0 + 5);

	# The local server shares our stderr, as an ssh server's reaches the
	# client: catch it to see the server's log line.
	my $error;
	my $log = File::Spec->catfile(tempdir(CLEANUP => 1), 'server.err');
	with_revoked(create => $env->server_path('sub'), sub {
		open my $saved, '>&', \*STDERR or die "dup stderr: $!";
		open STDERR, '>', $log or die "Cannot write $log: $!";
		eval { $env->sync(); 1 } or $error = $@;
		open STDERR, '>&', $saved or die "restore stderr: $!";
	});
	like($error, qr/Cannot create a temporary file in sub: /, 'the client is told the repo path');
	unlike($error, qr/\Q$env->{server}\E/, 'and not where the server keeps it');
	my $logged = do { open my $fh, '<', $log or die "Cannot read $log: $!"; local $/; <$fh> };
	like($logged, qr/Cannot create a temporary file in sub: /, 'the server logs the same text');
	unlike($logged, qr/\Q$env->{server}\E/, 'so its stderr carries no server path either');

	my ($event) = grep { ($_->{action} // '') eq 'session' && ($_->{result} // '') eq 'error' }
		@{ App::FileSync::Admin->new(root => $env->{server})->journal_read(repo => 'docs') };
	like($event->{error}, qr/\Q$env->{server}\E/, 'the server journal keeps the absolute path');
};

# --- Client -----------------------------------------------------------------

subtest 'Client: each repo has its own local trash' => sub {
	my $env = TestSync->new_env();
	$env->write_file('client', 'a.txt', "a\n", $T0);
	$env->sync();
	unlink $env->server_path('a.txt') or die $!;
	$env->sync();
	ok(!$env->exists_in('client', 'a.txt'), 'the remote delete reached the client');

	my $own = File::Spec->catdir($env->{home}, 'trash', 'repos', 'docs');
	ok(-d $own, 'the deleted file went to this repo\'s trash');

	# Old: every repo shared home/trash, so another repo's restore found
	# (and prune expired) this repo's files.
	my $config = App::FileSync::Config::load_client($env->{config_path});
	$config->{repos}{other} = { %{ $config->{repos}{docs} }, root => tempdir(CLEANUP => 1) };
	my $other = App::FileSync::Client->new(config => $config, name => 'other');
	my $found = $other->restore(path => 'a.txt', list => 1);
	is_deeply($found->{versions}, [], 'another repo does not see it');

	my $restored = $env->restore(path => 'a.txt');
	is($env->read_file('client', 'a.txt'), "a\n", 'this repo restores it');
};

subtest 'Client: restore still finds files in the old shared trash' => sub {
	my $env = TestSync->new_env();
	my $src = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($src, 'legacy.txt');
	# Raw: in text mode Windows writes "legacy\r\n", and restore copies bytes.
	open my $fh, '>:raw', $file or die $!;
	print {$fh} "legacy\n";
	close $fh;
	App::FileSync::Trash::move_to_trash(src => $file, rel => 'legacy.txt', root => File::Spec->catdir($env->{home}, 'trash'));

	$env->restore(path => 'legacy.txt');
	is($env->read_file('client', 'legacy.txt'), "legacy\n", 'restored from the legacy location');
};

subtest 'Client: a repo name that is not a plain id is refused' => sub {
	my $env = TestSync->new_env();
	my $config = App::FileSync::Config::load_client($env->{config_path});
	for my $name ('../x', '', 'a/b') {
		throws_ok { App::FileSync::Client->new(config => $config, name => $name) } qr/./, "name '$name'";
	}
};

# --- I18N -------------------------------------------------------------------

subtest 'strip_location removes same-line locations' => sub {
	is(strip_location("Can't open 'x': No such file or directory at lib/X.pm line 12.\n"),
		q{Can't open 'x': No such file or directory}, 'autodie style');
	is(strip_location("Cannot read 'f'\n at lib/X.pm line 3.\n"), q{Cannot read 'f'}, 'croak style');
	is(strip_location("Path 'a at b line 3' is fine\n"), q{Path 'a at b line 3' is fine}, 'a path that merely looks like a location stays');
	is(strip_location(undef), '', 'undef');
};

# --- CLI --------------------------------------------------------------------

subtest 'CLI: default client id is a valid id' => sub {
	no warnings 'redefine';
	my %cases = (
		'Laptop.example.com' => 'laptop',
		'--evil'             => 'evil',
		('x' x 80)           => 'x' x 64,
		'...'                => 'client',
		'My Host'            => 'my-host',
	);
	for my $host (sort keys %cases) {
		local *Sys::Hostname::hostname = sub { $host };
		is(App::FileSync::CLI::_default_client_id(), $cases{$host}, "hostname '$host'");
	}
};

subtest 'CLI: sync --quiet says nothing when nothing happened' => sub {
	# It used to print "docs: pulled 0, pushed 0, deleted 0, conflicts 0" and
	# a zero transfer line on every run, so a cron job mailed noise each time.
	my $filesync = File::Spec->catfile('bin', 'filesync');
	my $env = TestSync->new_env();
	$env->write_file('client', 'a.txt', "alpha\n", 1_700_000_000);

	my $output = `$^X -Ilib $filesync sync --repo docs --quiet 2>&1`;
	is($?, 0, 'the first sync exits 0');
	like($output, qr/docs: pulled 0, pushed 1/, '--quiet still reports a sync that did something');

	$output = `$^X -Ilib $filesync sync --repo docs --quiet 2>&1`;
	is($?, 0, 'an idle sync exits 0');
	is($output, '', '--quiet prints nothing for an idle sync');

	$output = `$^X -Ilib $filesync sync --repo docs --quiet --dry-run 2>&1`;
	is($output, '', 'nor for an idle dry run');

	$output = `$^X -Ilib $filesync sync --repo docs 2>&1`;
	like($output, qr/docs: pulled 0, pushed 0, deleted 0, conflicts 0/, 'without --quiet an idle sync is still reported');

	$env->write_file('client', 'b.txt', "beta\n", 1_700_000_100);
	$output = `$^X -Ilib $filesync sync --repo docs --quiet --dry-run 2>&1`;
	like($output, qr/would push b\.txt/, '--quiet --dry-run still lists what it would do');
};

subtest 'json_decode: non-ASCII hash keys come back as bytes' => sub {
	# json_decode downgraded values but not hash keys, and manifests are keyed
	# by path.  A key such as "h\xc3\xa9llo.txt" kept the UTF-8 flag, so a
	# file test on it looked for a differently-encoded name: verify's random
	# sample silently skipped every non-ASCII file (sampled 1 of 2 here).
	my $root = tempdir(CLEANUP => 1);
	for my $name ("h\xc3\xa9llo.txt", 'plain.txt') {
		open my $fh, '>:raw', File::Spec->catfile($root, $name) or die "Cannot write $name: $!";
		print {$fh} "x\n";
		close $fh;
	}
	my $manifest = App::FileSync::Scan::scan(root => $root)->{manifest};
	my $entries = App::FileSync::json_decode(App::FileSync::json_encode($manifest));

	my ($key) = grep { /[^\x00-\x7f]/ } keys %{$entries};
	ok(!utf8::is_utf8($key), 'the decoded key carries no UTF-8 flag');
	ok(-e File::Spec->catfile($root, $key), 'and names the file on disk');

	my $result = App::FileSync::Verify::verify(root => $root, entries => $entries, sample => 10);
	is($result->{sampled}, 2, 'verify samples the non-ASCII file too');
};

# --- Transports: closing a session part-way ---------------------------------

subtest 'Transport::Local: closing mid-session lets the server exit by itself' => sub {
	# Old: on Windows the server inherited the client's end of its own stdin
	# pipe, so closing it never gave the server end of file, and close()
	# waited for it forever.  Every Windows CI run hung here.
	local $App::FileSync::Process::GRACE_SECONDS = 10;
	my $env = conflict_env();
	my $s = session($env);
	my $content = "client\n";
	ok(call($s, { cmd => 'put', p => 'a.txt', s => length $content, h => sha256_hex($content), m => $T0 + 20, mode => 0644 })->{ok},
		'put accepted; the server now waits for the data');
	$s->{transport}->close();
	is($s->{transport}{end}{killed}, 0, 'the server saw end of file and exited without being stopped');
};

subtest 'Process: reap stops a child that will not exit' => sub {
	my $child = App::FileSync::Process::spawn(command => [ $^X, '-e', 'sleep 300' ], stderr => fileno(STDERR));
	close $child->{writer};
	close $child->{reader};
	my $started = time;
	my $end = App::FileSync::Process::reap(pid => $child->{pid}, grace => 0.2);
	is($end->{killed}, 1, 'it was stopped');
	cmp_ok(time - $started, '<', 30, 'promptly (old: waitpid with no limit)');
	SKIP: {
		# Windows waitpid() falls back to OpenProcess() for a pid that is no
		# longer its child, so asking again can return the pid.
		skip 'waitpid on a reaped pid is not -1 on Windows', 1 if $^O eq 'MSWin32';
		is(waitpid($child->{pid}, 0), -1, 'and reaped');
	}

	$child = App::FileSync::Process::spawn(command => [ $^X, '-e', 'exit 7' ], stderr => fileno(STDERR));
	$end = App::FileSync::Process::reap(pid => $child->{pid}, grace => 10);
	is_deeply($end, { status => 7, signal => 0, killed => 0 }, 'a child that exits keeps its status');
};

subtest 'Process: a program that cannot start is named' => sub {
	my $missing = File::Spec->catfile(tempdir(CLEANUP => 1), 'no-such-program');
	if ($^O eq 'MSWin32') {
		# Perl on Windows retries a program it cannot start through cmd.exe,
		# so the start succeeds and the failure is cmd.exe's exit status.
		open my $null, '>', File::Spec->devnull() or die "null: $!";
		my $child = App::FileSync::Process::spawn(command => [ $missing ], stderr => fileno($null));
		close $child->{writer};
		close $child->{reader};
		isnt(App::FileSync::Process::reap(pid => $child->{pid}, grace => 30)->{status}, 0, 'the child reports failure');
		return;
	}
	throws_ok { App::FileSync::Process::spawn(command => [ $missing ], stderr => fileno(STDERR)) }
		qr/Cannot start '\Q$missing\E'/, 'process.spawn';
};

subtest 'Transport::SSH: an ssh that has to be stopped is a failed close' => sub {
	plan skip_all => 'the stand-in ssh is a #! script' if $^O eq 'MSWin32';
	local $App::FileSync::Process::GRACE_SECONDS = 0.2;

	my $fake = File::Spec->catfile(tempdir(CLEANUP => 1), 'stuck-ssh');
	open my $fh, '>', $fake or die "Cannot write $fake: $!";
	print {$fh} "#!$^X\nsleep 300;\n";
	close $fh;
	chmod 0755, $fake or die "chmod: $!";

	my $ssh = App::FileSync::Transport::SSH->new(server => 'host', repo => 'docs', client => 'test-1', command => $fake);
	is($ssh->close(), 0, 'close reports the failure (old: it would have waited for ssh forever)');
	ok($ssh->{killed}, 'and records that ssh was stopped');
};

# --- Settings ---------------------------------------------------------------

subtest 'Settings: an environment variable is named as the environment spells it' => sub {
	# Old: _env_key asked "exists $ENV{name}" first.  On Windows that lookup
	# ignores case, so "filesync settings" named App__FileSync__ssh_identity
	# when the environment holds APP__FILESYNC__SSH_IDENTITY.  A tied %ENV
	# whose exists() ignores case stands in for Windows here.
	{
		package CaseBlindEnv;
		require Tie::Hash;
		our @ISA = ('Tie::StdHash');
		sub EXISTS { my ($self, $key) = @_; return scalar grep { lc $_ eq lc $key } keys %{$self} }
	}
	# Keep the real variables: HARNESS_ACTIVE lets the test call a :Private sub.
	my %real = map { $_ => $ENV{$_} } grep { !/\Aapp__filesync__/i } keys %ENV;
	local *ENV;
	tie %ENV, 'CaseBlindEnv';
	%ENV = (%real, APP__FILESYNC__SSH_IDENTITY => '/tmp/id');
	is(App::FileSync::Settings::_env_key('App__FileSync__ssh_identity'), 'APP__FILESYNC__SSH_IDENTITY', 'the stored spelling');
	is(App::FileSync::Settings::_env_key('APP__FILESYNC__SSH_IDENTITY'), 'APP__FILESYNC__SSH_IDENTITY', 'an exact match');
	is(App::FileSync::Settings::_env_key('App__FileSync__log_level'), undef, 'an unset variable');
};

subtest 'Sub::Private is enforced outside the test harness' => sub {
	local $Sub::Private::config{harness_bypass} = 0;
	throws_ok { App::FileSync::CLI::_default_client_id() } qr/private/i, 'a private sub called from outside its package';
};

done_testing();
