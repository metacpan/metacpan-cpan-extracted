#!/usr/bin/env perl
# ex:ts=8 sw=4:

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Fugu::TestLog;

use_ok('App::FuguVM::Miniroot');
use_ok('App::FuguVM::Mirror');
use_ok('App::FuguVM::Proxy');

# The mirror module holds the mirror facts, so this module names no
# host of its own
ok(!App::FuguVM::Miniroot->can('CDN_HOST'),
    'the CDN_HOST constant lives in the mirror module now');
ok(!App::FuguVM::Miniroot->can('ARCH'),
    'the ARCH constant is gone with the directive');
ok(!App::FuguVM::Miniroot->can('download'),
    'the download moved into the mirror module');

# _miniroot($cache_dir, %mirror_args):
#	A miniroot over a fresh mirror, with the test defaults.
sub _miniroot
{
    my ($cache_dir, %mirror_args) = @_;

    my $mirror = App::FuguVM::Mirror->new(
	cache   => App::FuguVM::Proxy::Cache->new($cache_dir),
	version => '7.8',
	arch    => $mirror_args{arch} // 'arm64',
	%mirror_args,
    );

    return App::FuguVM::Miniroot->new($cache_dir, undef, $mirror);
}

# Test object creation
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $image = _miniroot($tmpdir);
    ok(defined $image, 'Image object created');
}

# A construction without a mirror is a programming error
{
    ok(!eval { App::FuguVM::Miniroot->new('/tmp', undef, undef); 1 },
	'new with no mirror dies');
}

# Test url generation, for each architecture. The mirror builds the
# URL, so the host has one home.
{
    my $tmpdir = tempdir(CLEANUP => 1);

    my $arm64 = _miniroot($tmpdir, arch => 'arm64');
    is($arm64->url,
       'https://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/miniroot78.img',
       'the arm64 URL holds the arm64 path segment');

    my $amd64 = _miniroot($tmpdir, arch => 'amd64');
    is($amd64->url,
       'https://cdn.openbsd.org/pub/OpenBSD/7.8/amd64/miniroot78.img',
       'the amd64 URL holds the amd64 path segment');

    like($arm64->url, qr{/miniroot78\.img$},
       'the file name is the same for both architectures');
    like($amd64->url, qr{/miniroot78\.img$},
       'only the path segment differs');
}

# Test image filename generation
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $image = _miniroot($tmpdir);

    my $filename = $image->_image_filename;
    is($filename, 'miniroot78.img',
	'the filename comes from the mirror version');
}

# Test path returns undef for missing image
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $image = _miniroot($tmpdir);

    my $path = $image->path;
    is($path, undef, 'path returns undef for missing image');
}

# Test path and ensure return the path for a cached image, with no
# fetch and no verification: the proof ran on the way into the cache.
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $image = _miniroot($tmpdir);

    # Create a fake cached image in the proxy cache structure
    my $cache_path = "$tmpdir/proxy/cdn.openbsd.org/pub/OpenBSD/7.8/arm64";
    make_path($cache_path);
    open my $fh, '>', "$cache_path/miniroot78.img";
    print $fh "fake image content";
    close $fh;

    my $path = $image->path;
    ok(defined $path, 'path returns path for cached image');
    like($path, qr/miniroot78\.img$/, 'path ends with correct filename');
    is($image->ensure, $path, 'ensure returns the cached path');
}

# ensure returns undef when the mirror cannot verify, and it stores
# nothing. Version 9.9 has no release key in any directory, so the
# manifest proof stops before any fetch.
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $cache = App::FuguVM::Proxy::Cache->new($tmpdir);
    my $mirror = App::FuguVM::Mirror->new(
	cache    => $cache,
	version  => '9.9',
	arch     => 'arm64',
	keys_dir => tempdir(CLEANUP => 1),
    );
    my $image = App::FuguVM::Miniroot->new($tmpdir, undef, $mirror);

    is($image->ensure, undef,
	'ensure returns undef when the mirror cannot verify');
    like($mirror->error, qr/openbsd-99-base\.pub/,
	'and the mirror error names the missing key');
    is(scalar @{ $cache->list }, 0, 'and the cache stays empty');
}

done_testing();
