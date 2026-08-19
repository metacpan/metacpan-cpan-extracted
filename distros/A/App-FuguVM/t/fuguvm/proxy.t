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
	);
	ok( $cache->is_cacheable($_), "cacheable: $_" ) for @cacheable;

	ok( !$cache->is_cacheable('http://example.com/random.html'),
	    'a page outside a release tree is not cacheable' );
	ok( !$cache->is_cacheable('http://cdn.openbsd.org/pub/OpenBSD/README'),
	    'nor a file with no version in its path' );
	ok( !$cache->is_cacheable(
	    'http://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/base78.tgz', 404),
	    'and a 404 never is' );
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
	my $dir   = tempdir( CLEANUP => 1 );
	my $store = Fugu::StateFile->new( path => "$dir/state.json" )->load;

	my $proxy = App::FuguVM::Proxy->new(
	    cache   => App::FuguVM::Proxy::Cache->new($dir),
	    pidfile => Fugu::Pidfile->new( path => "$dir/proxy.pid" ),
	    store   => $store,
	);

	is( $proxy->guest_url, undef, 'no URL before the proxy runs' );

	$store->set( proxy_port => 8080 );
	is( $proxy->guest_url, 'http://10.0.2.2:8080',
	    'the guest URL names the gateway' );
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

done_testing();
