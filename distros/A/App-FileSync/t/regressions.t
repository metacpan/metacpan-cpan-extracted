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

use lib 't/lib';
use TestSync;
use App::FileSync::Admin;
use App::FileSync::CLI;
use App::FileSync::Client;
use App::FileSync::Config;
use App::FileSync::I18N qw(strip_location);
use App::FileSync::Ignore;
use App::FileSync::Protocol;
use App::FileSync::Scan;
use App::FileSync::Store;
use App::FileSync::Transport::Local;
use App::FileSync::Trash;

my $T0 = 1_700_000_000;

# --- helpers ----------------------------------------------------------------

# Open a raw session as the env's client, send the client tree's manifest and
# ask for a plan.  Returns { transport, conn, plan => { path => action } }.
# The server's stderr goes to /dev/null: these sessions end abruptly on
# purpose and its "connection closed" diagnostics are expected.
sub session {
	my ($env) = @_;

	open my $saved, '>&', \*STDERR or die "dup stderr: $!";
	open STDERR, '>', File::Spec->devnull() or die "null stderr: $!";
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

	return { transport => $transport, conn => $conn, plan => { map { $_->{p} => $_ } @{ $plan->{actions} } } };
}

# Send one message (with optional data) and return the reply.
sub call {
	my ($session, $message, $bytes) = @_;

	defined $bytes ? $session->{conn}->send_data($message, $bytes) : $session->{conn}->send($message);
	return $session->{conn}->recv();
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

	ok(!$env->exists_in('server', 'new.txt'), 'nothing was committed');
	my @temps = grep { /filesync-tmp/ } @{ $env->tree('server') || [] };
	is_deeply(\@temps, [], 'and no temporary file is left');
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
	plan skip_all => 'permission checks are not enforced here' if $> == 0 || $^O eq 'MSWin32';

	my $parent = tempdir(CLEANUP => 1);
	my $root = File::Spec->catdir($parent, 'filesync');
	make_path($root);
	chmod 0555, $root or die "chmod: $!";

	my $admin = App::FileSync::Admin->new(root => $root);

	# Old: make_path reported "Cannot create directory .../master/docs:
	# Permission denied", naming a path below the root the caller passed.
	throws_ok { $admin->repo_create(name => 'docs') }
		qr/not writable by this account .*chown/s, 'the root and the remedy are named';

	# The same mistake one level down: the root is ours, its master is not.
	chmod 0755, $root or die "chmod: $!";
	my $master = File::Spec->catdir($root, 'master');
	make_path($master);
	chmod 0555, $master or die "chmod: $!";
	throws_ok { $admin->repo_create(name => 'docs') }
		qr/not writable by this account \(\Q$master\E\)/, 'an unwritable master directory is named';
	chmod 0755, $master or die "chmod: $!";

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
	open my $fh, '>', $file or die $!;
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

subtest 'Sub::Private is enforced outside the test harness' => sub {
	local $Sub::Private::config{harness_bypass} = 0;
	throws_ok { App::FileSync::CLI::_default_client_id() } qr/private/i, 'a private sub called from outside its package';
};

done_testing();
