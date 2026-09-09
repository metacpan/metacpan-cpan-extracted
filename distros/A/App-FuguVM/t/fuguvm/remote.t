#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The remote side of one running guest: the argument quoting, the
# local walk, the batching, and the failure shape of put and get.
# No test here opens a real connection: the closed-port tests prove
# the failure path, and a mock SSH object proves the batching.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Fugu::TestLog;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use IO::Socket::INET;
use POSIX      ();

# The module depends on SSH, which requires Net::SSH2
BEGIN {
    eval { require Net::SSH2 };
    if ($@) {
	plan skip_all => 'Net::SSH2 not available';
    }
}

use_ok('App::FuguVM::Remote');

# A mock transport. The batching tests read the commands that put
# would run, without a guest.
package Mock::SSH {
    sub new ($class) {
	return bless { commands => [], writes => [] }, $class;
    }

    sub run_command ($self, $command) {
	push @{ $self->{commands} }, $command;
	return { stdout => '', stderr => '', exit_code => 0 };
    }

    sub write_file ($self, $path, $content, $mode) {
	push @{ $self->{writes} }, [ $path, $mode ];
	return 0;
    }
}

# ============================================================
# quote_argv
# ============================================================

{
    is(App::FuguVM::Remote->quote_argv('word'), "'word'",
	'a plain word gets single quotes');
    is(App::FuguVM::Remote->quote_argv('a b'), "'a b'",
	'a word with a space stays one word');
    is(App::FuguVM::Remote->quote_argv("it's"), "'it'\\''s'",
	"a single quote becomes the '\\'' form");
    is(App::FuguVM::Remote->quote_argv(''), "''",
	"an empty word becomes ''");
    is(App::FuguVM::Remote->quote_argv('a', 'b', 'c'), "'a' 'b' 'c'",
	'several words join with one space');

    # The strongest proof of the rule is a real shell. sh -c parses
    # the quoted string as the remote login shell would, and printf
    # reports each word that arrives.
    my @words = ('*', '$HOME', 'a;b', 'x&y', '`id`', "it's", 'a b', '');
    my $command =
	App::FuguVM::Remote->quote_argv('printf', '%s\n', @words);
    open my $sh, '-|', 'sh', '-c', $command
	or die "Cannot run sh: $!";
    my @lines = <$sh>;
    close $sh;
    chomp @lines;
    is_deeply(\@lines, \@words,
	'a shell splits the string at the word boundaries only,'
	    . ' with no expansion and no globbing');
}

# ============================================================
# new and run
# ============================================================

{
    my $remote = App::FuguVM::Remote->new(host => '127.0.0.1', port => 2299);
    is($remote->{port}, 2299, 'new stores the port');
    is($remote->{host}, '127.0.0.1', 'new stores the host');

    eval { App::FuguVM::Remote->new(host => '127.0.0.1') };
    like($@, qr/needs a port/, 'new dies with no port');

    eval { App::FuguVM::Remote->new(port => 2299) };
    like($@, qr/needs a host/, 'new dies with no host');

    eval { $remote->run() };
    like($@, qr/argument vector/, 'run dies on an empty vector');
}

# ============================================================
# The constants
# ============================================================

{
    is(App::FuguVM::Remote::SSH_TIMEOUT(), 3600,
	'SSH_TIMEOUT holds one hour');
    is(App::FuguVM::Remote::MAX_TRANSFER_SIZE(), 64 * 1024 * 1024,
	'MAX_TRANSFER_SIZE holds 64 MiB');
    is(App::FuguVM::Remote::BATCH_PATHS(), 100,
	'BATCH_PATHS holds 100 paths');
}

# ============================================================
# _entries, the local walk
# ============================================================

my $remote = App::FuguVM::Remote->new(host => '127.0.0.1', port => 2299);

# A single regular file is one entry, with its destination path
{
    my $dir = tempdir(CLEANUP => 1);
    _touch("$dir/one.txt", 0644);

    my $entries = $remote->_entries("$dir/one.txt", '/root/one.txt');
    is(scalar @$entries, 1, 'a single file is one entry');
    is($entries->[0]{type}, 'file', 'of type file');
    is($entries->[0]{dest}, '/root/one.txt', 'with its destination path');
}

# A directory tree arrives sorted, with every directory and every
# file, and with no component for the source directory name
{
    my $dir = tempdir(CLEANUP => 1);
    make_path("$dir/src/b", "$dir/src/a");
    _touch("$dir/src/b/two.txt", 0644);
    _touch("$dir/src/a/one.txt", 0644);
    _touch("$dir/src/zero.txt", 0644);

    my $entries = $remote->_entries("$dir/src", '/root/dst');
    is_deeply([map { $_->{dest} } @$entries],
	['/root/dst', '/root/dst/a', '/root/dst/a/one.txt',
	    '/root/dst/b', '/root/dst/b/two.txt', '/root/dst/zero.txt'],
	'the tree arrives sorted, mapped under the destination');
    is_deeply([map { $_->{type} } @$entries],
	['dir', 'dir', 'file', 'dir', 'file', 'file'],
	'with every directory and every file');
    is(scalar(grep { $_->{dest} =~ m{/src\b} } @$entries), 0,
	'and no entry holds the source directory name');
}

# A symbolic link, a fifo, and an oversized file each fail the walk
{
    my $dir = tempdir(CLEANUP => 1);
    make_path("$dir/src");
    _touch("$dir/src/ok.txt", 0644);
    symlink("$dir/src/ok.txt", "$dir/src/link") or die $!;
    is($remote->_entries("$dir/src", '/root/dst'), undef,
	'a symbolic link fails the whole walk');

    my $fdir = tempdir(CLEANUP => 1);
    make_path("$fdir/src");
    POSIX::mkfifo("$fdir/src/fifo", 0600) or die $!;
    is($remote->_entries("$fdir/src", '/root/dst'), undef,
	'a fifo fails the whole walk');

    my $bdir = tempdir(CLEANUP => 1);
    open my $fh, '>', "$bdir/big" or die $!;
    truncate($fh, App::FuguVM::Remote::MAX_TRANSFER_SIZE() + 1) or die $!;
    close $fh;
    is($remote->_entries("$bdir/big", '/root/big'), undef,
	'a file above MAX_TRANSFER_SIZE fails the walk');

    SKIP: {
	skip 'directory modes do not bind as root', 1 if $< == 0;

	# Fail closed: a directory that the walk cannot enter must
	# not read as a complete copy
	my $pdir = tempdir(CLEANUP => 1);
	make_path("$pdir/src/closed");
	chmod 0000, "$pdir/src/closed" or die $!;
	my $entries = $remote->_entries("$pdir/src", '/root/dst');
	chmod 0755, "$pdir/src/closed";
	is($entries, undef, 'an unreadable directory fails the walk');
    }
}

# The mode: the local permission bits masked with 0777, no setuid
# bit, and the --mode value when the caller gives one
SKIP: {
    skip 'the setuid bit does not survive as root', 4 if $< == 0;

    my $dir = tempdir(CLEANUP => 1);
    _touch("$dir/tool", 0755);
    chmod 04755, "$dir/tool" or die $!;

    my $entries = $remote->_entries("$dir/tool", '/root/tool');
    is($entries->[0]{mode}, 0755, 'the mask drops the setuid bit');

    _touch("$dir/plain", 0640);
    $entries = $remote->_entries("$dir/plain", '/root/plain');
    is($entries->[0]{mode}, 0640, 'the local permission bits arrive');

    $entries = $remote->_entries("$dir/plain", '/root/plain', 0600);
    is($entries->[0]{mode}, 0600, 'the mode argument wins for a file');

    make_path("$dir/src");
    _touch("$dir/src/a", 0644);
    _touch("$dir/src/b", 0755);
    $entries = $remote->_entries("$dir/src", '/root/dst', 0600);
    is_deeply([map { $_->{mode} } grep { $_->{type} eq 'file' } @$entries],
	[0600, 0600], 'the mode argument wins for every file');
}

# ============================================================
# The failure shape of put and get, against a closed port
# ============================================================

{
    my $port = _closed_port();
    my $closed =
	App::FuguVM::Remote->new(host => '127.0.0.1', port => $port);

    my $dir = tempdir(CLEANUP => 1);
    _touch("$dir/one.txt", 0644);

    my $put = eval { $closed->put("$dir/one.txt", '/root/one.txt') };
    is($@, '', 'put does not die on a closed port');
    is($put, undef, 'and it returns undef');

    SKIP: {
	skip 'the installed Fugu::SSH has no read_file', 2
	    unless Fugu::SSH->can('read_file');

	my $get = eval { $closed->get('/root/one.txt', "$dir/out.txt") };
	is($@, '', 'get does not die on a closed port');
	is($get, undef, 'and it returns undef');
    }

    my $got = $closed->get('/root/one.txt', $dir);
    is($got, undef, 'get refuses an existing directory as <local>');
}

# ============================================================
# The batching
# ============================================================

{
    my $dir = tempdir(CLEANUP => 1);
    make_path("$dir/src");
    _touch("$dir/src/f$_", 0644) for 100 .. 219;

    my $batched =
	App::FuguVM::Remote->new(host => '127.0.0.1', port => 2299);
    my $mock = Mock::SSH->new;
    $batched->{ssh} = $mock;

    is($batched->put("$dir/src", '/root/dst'), 1,
	'put succeeds over the mock transport');
    is(scalar @{ $mock->{writes} }, 120, 'and writes every file');

    # No path in this tree holds a space. Thus the word count of a
    # command bounds its path count.
    my $max = App::FuguVM::Remote::BATCH_PATHS();
    for my $command (@{ $mock->{commands} }) {
	my @words = split / /, $command;
	my $paths = scalar grep { m{^'/root/dst} } @words;
	cmp_ok($paths, '<=', $max,
	    'a batched command holds no more than BATCH_PATHS paths');
    }
}

done_testing();

# _touch($path, $mode):
#	One small regular file.
sub _touch
{
    my ($path, $mode) = @_;

    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh "x\n";
    close $fh;
    chmod $mode, $path or die "Cannot chmod $path: $!";

    return;
}

# _closed_port():
#	A port that nothing listens on. The listener closes before
#	the caller connects, so a connect gets a refusal at once.
sub _closed_port
{
    my $sock = IO::Socket::INET->new(
	Listen    => 1,
	LocalAddr => '127.0.0.1',
	LocalPort => 0,
    ) or die "Cannot bind a probe socket: $!";
    my $port = $sock->sockport;
    close $sock;

    return $port;
}
