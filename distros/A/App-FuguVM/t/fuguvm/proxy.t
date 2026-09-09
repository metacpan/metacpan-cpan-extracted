#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The OpenBSD mirror policy of App::FuguVM::Proxy. The generic proxy, its
# cache and its metadata table are proven in t/fugu/proxy.t.

use v5.36;
use Test::More;
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Fugu::Log;
use Fugu::Pidfile;
use Fugu::StateFile;

use_ok('App::FuguVM::Proxy');
use_ok('App::FuguVM::State');

Fugu::Log->set_default( Fugu::Log->new( mode => 'quiet' ) );

# Which URL is worth keeping is the whole of the mirror policy. Every
# pattern is version-scoped, and that is what makes prune safe.
{
	my $cache = App::FuguVM::Proxy::Cache->new( tempdir( CLEANUP => 1 ) );

	my @cacheable = (
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/base78.tgz',
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/packages/amd64/vim-9.0.tgz',
	    'http://cdn.openbsd.org/pub/OpenBSD/syspatch/7.8/amd64/syspatch78-001.tgz',
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/SHA256',
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/SHA256.sig',
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/miniroot78.img',
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/bsd.rd',
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/BUILDINFO',
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/index.txt',
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/ports.tar.gz',
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/src.tar.gz',
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/sys.tar.gz',
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/xenocara.tar.gz',
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/SHA256',
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/SHA256.sig',
	);
	ok( $cache->is_cacheable($_), "cacheable: $_" ) for @cacheable;

	ok( !$cache->is_cacheable('http://example.com/random.html'),
	    'a page outside a release tree is not cacheable' );
	ok( !$cache->is_cacheable('http://cdn.openbsd.org/pub/OpenBSD/README'),
	    'nor a file with no version in its path' );
	ok( !$cache->is_cacheable(
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/base78.tgz', 404),
	    'and a 404 never is' );
	ok( !$cache->is_cacheable(
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/other.tar.gz'),
	    'the source tarballs are named, so an other tarball is not' );
}

# The distfile pattern is conditional on the cap: a cache that grows
# with no bound in a home directory is the failure that the default
# of 0 avoids.
{
	my $distfile =
	    'http://cdn.openbsd.org/pub/OpenBSD/distfiles/gmake-4.4.1.tar.gz';
	my $nested =
	    'http://cdn.openbsd.org/pub/OpenBSD/distfiles/by_cipher/'
	    . 'sha256/aa/gmake.tar.gz';

	my $off = App::FuguVM::Proxy::Cache->new( tempdir( CLEANUP => 1 ) );
	ok( !$off->is_cacheable($distfile),
	    'a distfile is not cacheable with a cap of 0' );
	is( $off->distfile_limit, 0, 'and the default cap is 0' );

	my $on =
	    App::FuguVM::Proxy::Cache->new( tempdir( CLEANUP => 1 ), 4096 );
	ok( $on->is_cacheable($distfile),
	    'a distfile is cacheable with a cap above 0' );
	ok( $on->is_cacheable($nested),
	    'a distfile in a subdirectory is cacheable' );
	ok( !$on->is_cacheable(
		'http://cdn.openbsd.org/pub/OpenBSD/distfiles/'),
	    'a directory listing with a trailing solidus is not' );
	is( $on->distfile_limit, 4096, 'the cap is on the object' );
}

# A kernel has no extension, so the generic content-type table cannot
# name it. The policy adds that entry.
{
	my $cache = App::FuguVM::Proxy::Cache->new( tempdir( CLEANUP => 1 ) );

	is( $cache->content_type('/pub/OpenBSD/7.8/arm64/bsd'),
	    'application/octet-stream', 'a kernel is bytes' );
	is( $cache->content_type('/pub/OpenBSD/7.8/arm64/base78.tgz'),
	    'application/x-gzip', 'and the generic table still applies' );
}

# The guest reaches the host through the QEMU gateway, and no other
# address gets out of the SLIRP network.
{
	my $dir     = tempdir( CLEANUP => 1 );
	my $store   = Fugu::StateFile->new( path => "$dir/state.json" )->load;
	my $pidfile = Fugu::Pidfile->new( path => "$dir/proxy.pid" );

	my $proxy = App::FuguVM::Proxy->new(
	    cache   => App::FuguVM::Proxy::Cache->new($dir),
	    pidfile => $pidfile,
	    store   => $store,
	);

	is( $proxy->guest_url, undef, 'no URL before the proxy runs' );

	# A recorded port without a live child is not a reachable
	# proxy, so the URL stays absent.
	$store->set( proxy_port => 8080 );
	is( $proxy->guest_url, undef,
	    'a stale port without a live child gives no URL' );

	# This test process stands in for the live child.
	$pidfile->write_pid($$);
	is( $proxy->guest_url, 'http://10.0.2.2:8080',
	    'the guest URL names the gateway while the proxy runs' );
}


# _seed($tmpdir, $relative_path, $bytes):
#	Write a cached file of $bytes bytes. Also create its tree.
sub _seed
{
	my ($tmpdir, $rel, $bytes) = @_;
	my $path = "$tmpdir/proxy/$rel";

	$path =~ m{\A(.*)/} and make_path($1);
	open my $fh, '>', $path or die "open $path: $!";
	print $fh 'x' x $bytes;
	close $fh;

	return $path;
}

my $MIRROR = 'cdn.openbsd.org/pub/OpenBSD';

# A version bump left the whole previous version's file sets behind
# permanently. They were unreadable afterwards, because every
# is_cacheable() pattern is version-scoped. Every copy of the
# directory that a CI cache made still carried them.
{
	my $tmpdir = tempdir(CLEANUP => 1);
	my $cache = App::FuguVM::Proxy::Cache->new($tmpdir);

	_seed($tmpdir, "$MIRROR/7.8/arm64/base78.tgz", 100);
	_seed($tmpdir, "$MIRROR/7.8/arm64/SHA256", 10);
	_seed($tmpdir, "$MIRROR/7.7/arm64/base77.tgz", 200);
	_seed($tmpdir, "$MIRROR/syspatch/7.7/arm64/001_x.tgz", 50);

	# The path holds no version, so prune must leave it. A cache
	# under $HOME is the wrong place to delete on a guess.
	_seed($tmpdir, 'example.com/loose.txt', 5);

	is($cache->size, 365, 'four versioned files and one loose one');

	my $removed = $cache->prune('7.8');
	is(scalar @$removed, 2, 'both 7.7 trees pruned');

	# Two trees, both 7.7: the release sets and the syspatch sets
	is_deeply([sort map { $_->{version} } @$removed], ['7.7', '7.7'],
	    'each names the version it held');
	is_deeply([sort { $a <=> $b } map { $_->{size} } @$removed],
	    [50, 200], 'and the bytes it freed');

	my @left = sort map { $_->{url} } @{$cache->list};
	is_deeply(\@left,
	    [
		"http://$MIRROR/7.8/arm64/SHA256",
		"http://$MIRROR/7.8/arm64/base78.tgz",
		'http://example.com/loose.txt',
	    ],
	    'the kept version and the unversioned file survive');
	is($cache->size, 115, 'and the freed bytes are gone');

	# The directory itself must be gone, not only its files. The
	# tree is what a CI cache uploads and downloads on every key
	# rotation.
	ok(!-e "$tmpdir/proxy/$MIRROR/7.7",
	    'the pruned release directory is gone');
	ok(!-e "$tmpdir/proxy/$MIRROR/syspatch/7.7",
	    'the pruned syspatch directory is gone');
	ok(-d "$tmpdir/proxy/$MIRROR/7.8",
	    'the kept version directory remains');

	is_deeply($cache->prune('7.8'), [], 'pruning twice removes nothing');
}

# Several versions kept at once, and a host that has nothing under
# pub/OpenBSD at all
{
	my $tmpdir = tempdir(CLEANUP => 1);
	my $cache = App::FuguVM::Proxy::Cache->new($tmpdir);

	_seed($tmpdir, "$MIRROR/7.6/arm64/base76.tgz", 10);
	_seed($tmpdir, "$MIRROR/7.7/arm64/base77.tgz", 20);
	_seed($tmpdir, "$MIRROR/7.8/arm64/base78.tgz", 40);
	_seed($tmpdir, 'ftp.example.org/elsewhere/file.tgz', 80);

	my $removed = $cache->prune('7.7', '7.8');
	is_deeply([map { $_->{version} } @$removed], ['7.6'],
	    'only the version named by neither is pruned');
	is($cache->size, 140, 'the other host is untouched');
}

# A prune that keeps only an absent version removes everything present
{
	my $tmpdir = tempdir(CLEANUP => 1);
	my $cache = App::FuguVM::Proxy::Cache->new($tmpdir);

	_seed($tmpdir, "$MIRROR/7.7/arm64/base77.tgz", 30);

	is(scalar @{$cache->prune('7.9')}, 1,
	    'an absent version keeps nothing');
	is($cache->size, 0, 'the cache is empty');
}

# The cache never received a write. Thus proxy/ holds no host
# directories at all.
{
	my $tmpdir = tempdir(CLEANUP => 1);
	my $cache = App::FuguVM::Proxy::Cache->new($tmpdir);

	is_deeply($cache->prune('7.8'), [],
	    'prune on an empty cache is a no-op');
}

# prune and the source tarballs: the tarball sits inside the version
# directory, so a version bump takes it. The distfile tree carries no
# version, so prune leaves every byte of it.
{
	my $tmpdir = tempdir(CLEANUP => 1);
	my $cache = App::FuguVM::Proxy::Cache->new($tmpdir, 4096);

	_seed($tmpdir, "$MIRROR/7.7/ports.tar.gz", 100);
	_seed($tmpdir, "$MIRROR/distfiles/gmake-4.4.1.tar.gz", 30);
	_seed($tmpdir, "$MIRROR/distfiles/by_dir/curl/curl-8.tar.gz", 20);

	my $removed = $cache->prune('7.8');
	is(scalar @$removed, 1, 'prune removes the stale version tree');
	ok(!-e "$tmpdir/proxy/$MIRROR/7.7",
	    'and ports.tar.gz went with it');

	ok(-d "$tmpdir/proxy/$MIRROR/distfiles", 'prune leaves the distfiles');
	is($cache->distfile_size, 50, 'and the tree keeps every byte');
}

# The eviction: oldest first by modification time, stop at the cap,
# report each removed file, and leave the release tree alone.
{
	my $tmpdir = tempdir(CLEANUP => 1);
	my $cache = App::FuguVM::Proxy::Cache->new($tmpdir, 45);

	my $old = _seed($tmpdir, "$MIRROR/distfiles/old.tar.gz", 30);
	my $mid = _seed($tmpdir, "$MIRROR/distfiles/mid.tar.gz", 20);
	my $new = _seed($tmpdir, "$MIRROR/distfiles/new.tar.gz", 10);
	my $set = _seed($tmpdir, "$MIRROR/7.8/arm64/base78.tgz", 500);

	# The store times decide the order, so the test sets them.
	utime 1000, 1000, $old;
	utime 2000, 2000, $mid;
	utime 3000, 3000, $new;

	my $removed = $cache->trim_distfiles;
	is_deeply($removed, [ { path => $old, size => 30 } ],
	    'trim removes the oldest file first and reports it');
	is($cache->distfile_size, 30, 'and stops when the tree fits');
	ok(-f $set, 'the release tree keeps its bytes');

	is_deeply($cache->trim_distfiles, [],
	    'a tree under the cap loses nothing');

	# A cap of 0 means the operator turned the cache off
	my $off = App::FuguVM::Proxy::Cache->new($tmpdir);
	my $emptied = $off->trim_distfiles;
	is(scalar @$emptied, 2, 'a cap of 0 empties the tree');
	is($off->distfile_size, 0, 'and no distfile byte stays');
	ok(-f $set, 'while the release tree still keeps its bytes');
}

# store trims after a distfile store, and only then: a set store must
# not walk the distfile tree.
{
	my $tmpdir = tempdir(CLEANUP => 1);
	my $cache = App::FuguVM::Proxy::Cache->new($tmpdir, 25);

	my $old = _seed($tmpdir, "$MIRROR/distfiles/old.tar.gz", 20);
	utime 1000, 1000, $old;

	my $stored = $cache->store(
	    "http://$MIRROR/distfiles/new.tar.gz", 'x' x 10);
	ok(defined $stored, 'store admits a distfile under a cap');
	ok(!-f $old, 'and the store evicts the oldest file over the cap');
	is($cache->distfile_size, 10, 'the tree fits the cap');

	# Refill over the cap, then store a file set: the set store
	# leaves the over-cap tree alone.
	my $again = _seed($tmpdir, "$MIRROR/distfiles/again.tar.gz", 40);
	ok(defined $cache->store(
		"http://$MIRROR/7.8/arm64/base78.tgz", 'x' x 100),
	    'a set store succeeds beside an over-cap tree');
	ok(-f $again, 'and it walks no distfile');
}

# distfile_size counts the tree over every cached host
{
	my $tmpdir = tempdir(CLEANUP => 1);
	my $cache = App::FuguVM::Proxy::Cache->new($tmpdir, 4096);

	_seed($tmpdir, "$MIRROR/distfiles/one.tar.gz", 10);
	_seed($tmpdir, 'mirror.example.org/pub/OpenBSD/distfiles/two.tar.gz',
	    15);

	is($cache->distfile_size, 25, 'the size covers every cached host');
}

# A metadata entry of an evicted file reads as absent, so an eviction
# in the child needs no invalidation.
{
	my $tmpdir = tempdir(CLEANUP => 1);
	my $cache = App::FuguVM::Proxy::Cache->new($tmpdir, 25);
	my $meta = Fugu::Proxy::Meta->new;

	my $old = _seed($tmpdir, "$MIRROR/distfiles/old.tar.gz", 20);
	utime 1000, 1000, $old;
	my $url = "http://$MIRROR/distfiles/old.tar.gz";
	ok(defined $meta->store($url, $old, $cache), 'the entry exists');

	$cache->store("http://$MIRROR/distfiles/new.tar.gz", 'x' x 10);
	is($meta->lookup($url), undef,
	    'the entry of the evicted file reads as absent');
}

done_testing();
