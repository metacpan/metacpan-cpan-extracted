#!/usr/bin/env perl
# ex:ts=8 sw=4:

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);
use File::Path qw(make_path);

use_ok('App::FuguVM::Miniroot');

# Test constants
is(App::FuguVM::Miniroot::CDN_HOST(), 'cdn.openbsd.org',
    'CDN_HOST is correct');
is(App::FuguVM::Miniroot::ARCH(), 'arm64',
    'ARCH is correct');

# download() only warns when the helper is missing. Thus a rename
# degrades silently to "no download" instead of a failure. Assert
# that the path still resolves.
ok(-f App::FuguVM::Miniroot::_ftp_script(),
    'the ftp helper resolves to a file');

# Test object creation
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $image = App::FuguVM::Miniroot->new($tmpdir);
    ok(defined $image, 'Image object created');
}

# Test url generation
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $image = App::FuguVM::Miniroot->new($tmpdir);
    
    my $url = $image->url('7.8');
    is($url, 'https://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/miniroot78.img',
       'URL generated correctly');
}

# Test image filename generation
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $image = App::FuguVM::Miniroot->new($tmpdir);
    
    my $filename = $image->_image_filename('7.8');
    is($filename, 'miniroot78.img', 'Image filename generated correctly');
}

# Test path returns undef for missing image
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $image = App::FuguVM::Miniroot->new($tmpdir);
    
    my $path = $image->path('7.8');
    is($path, undef, 'path returns undef for missing image');
}

# Test path returns path for cached image
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $image = App::FuguVM::Miniroot->new($tmpdir);
    
    # Create a fake cached image in the proxy cache structure
    my $cache_path = "$tmpdir/proxy/cdn.openbsd.org/pub/OpenBSD/7.8/arm64";
    make_path($cache_path);
    open my $fh, '>', "$cache_path/miniroot78.img";
    print $fh "fake image content";
    close $fh;
    
    my $path = $image->path('7.8');
    ok(defined $path, 'path returns path for cached image');
    like($path, qr/miniroot78\.img$/, 'path ends with correct filename');
}

done_testing();
