#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require File::Raw };
    plan skip_all => 'File::Raw required for Chandra::Assets tests' if $@;
}

use File::Temp qw(tempdir);
use File::Path qw(mkpath);

use_ok('Chandra::Assets');

# ---- Setup temp asset directory ----

my $dir = tempdir(CLEANUP => 1);
mkpath("$dir/css");
mkpath("$dir/js");
mkpath("$dir/images");

# Create test asset files
_write("$dir/css/style.css",   "body { color: red; }");
_write("$dir/css/reset.css",   "* { margin: 0; }");
_write("$dir/css/theme.css",   ".dark { background: #000; }");
_write("$dir/js/main.js",      "console.log('hello');");
_write("$dir/js/utils.js",     "function add(a,b){ return a+b; }");
_write("$dir/images/logo.txt", "not-a-real-image");  # text stand-in
_write("$dir/index.html",      "<html><body>hi</body></html>");
_write("$dir/data.json",       '{"key":"value"}');

sub _write {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
}

# ---- Construction ----

{
    my $a = Chandra::Assets->new(root => $dir);
    isa_ok($a, 'Chandra::Assets', 'new returns object');
    like($a->root, qr{\Q$dir\E/?$}, 'root() accessor');
    is($a->prefix, 'asset', 'default prefix is asset');
}

{
    my $a = Chandra::Assets->new(root => "$dir/", prefix => 'app');
    is($a->prefix, 'app', 'explicit prefix');
}

{
    my $a = Chandra::Assets->new(root => $dir, prefix => 'myapp://');
    is($a->prefix, 'myapp', 'prefix strips ://');
}

{
    my $a = Chandra::Assets->new(root => $dir, prefix => 'myapp:');
    is($a->prefix, 'myapp', 'prefix strips :');
}

{
    eval { Chandra::Assets->new() };
    like($@, qr/root/, 'new without root croaks');
}

# ---- MIME type detection ----

{
    my $a = Chandra::Assets->new(root => $dir);

    my @cases = (
        ['style.css',   'text/css'],
        ['main.js',     'application/javascript'],
        ['page.html',   'text/html'],
        ['data.json',   'application/json'],
        ['logo.png',    'image/png'],
        ['photo.jpg',   'image/jpeg'],
        ['photo.jpeg',  'image/jpeg'],
        ['icon.gif',    'image/gif'],
        ['icon.svg',    'image/svg+xml'],
        ['icon.ico',    'image/x-icon'],
        ['icon.webp',   'image/webp'],
        ['font.woff',   'font/woff'],
        ['font.woff2',  'font/woff2'],
        ['font.ttf',    'font/ttf'],
        ['font.eot',    'application/vnd.ms-fontobject'],
        ['audio.mp3',   'audio/mpeg'],
        ['video.mp4',   'video/mp4'],
        ['video.webm',  'video/webm'],
        ['STYLE.CSS',   'text/css'],          # case insensitive
        ['noext',       'application/octet-stream'],
    );

    for my $case (@cases) {
        is($a->mime_type($case->[0]), $case->[1], "mime_type($case->[0])");
    }
}

# ---- read ----

{
    my $a = Chandra::Assets->new(root => $dir);

    is($a->read('css/style.css'), "body { color: red; }", 'read css file');
    is($a->read('js/main.js'),    "console.log('hello');", 'read js file');
    is($a->read('index.html'),    "<html><body>hi</body></html>", 'read html');
    is($a->read('data.json'),     '{"key":"value"}', 'read json');
}

# ---- exists ----

{
    my $a = Chandra::Assets->new(root => $dir);

    ok($a->exists('css/style.css'),    'exists: css file');
    ok($a->exists('index.html'),       'exists: html file');
    ok(!$a->exists('nonexistent.txt'), 'exists: missing file');
}

# ---- path traversal protection ----

{
    my $a = Chandra::Assets->new(root => $dir);

    eval { $a->read('../etc/passwd') };
    like($@, qr/traversal/, 'path traversal with .. blocked');

    eval { $a->read('css/../../etc/passwd') };
    like($@, qr/traversal/, 'path traversal mid-path blocked');

    ok(!$a->exists('../etc/passwd'), 'exists returns false for traversal');
}

# ---- list ----

{
    my $a = Chandra::Assets->new(root => $dir);
    my @all = $a->list;
    ok(scalar @all > 0, 'list returns entries');

    # Check that subdirs appear
    my %seen = map { $_ => 1 } @all;
    ok($seen{'css'} || $seen{'index.html'}, 'list includes known entries');
}

{
    my $a = Chandra::Assets->new(root => "$dir/css");
    my @css = $a->list('*.css');
    ok(scalar @css >= 2, 'list with *.css filter');
    for my $f (@css) {
        like($f, qr/\.css$/, "filtered entry ends with .css: $f");
    }
}

# ---- inline_css ----

{
    my $a = Chandra::Assets->new(root => $dir);
    my $tag = $a->inline_css('css/style.css');
    is($tag, '<style>body { color: red; }</style>', 'inline_css wraps in style tags');
}

# ---- inline_js ----

{
    my $a = Chandra::Assets->new(root => $dir);
    my $tag = $a->inline_js('js/main.js');
    is($tag, "<script>console.log('hello');</script>", 'inline_js wraps in script tags');
}

# ---- inline_image ----

{
    my $a = Chandra::Assets->new(root => $dir);
    # Use a known small binary content
    my $img_path = "$dir/images/test.png";
    _write($img_path, "\x89PNG\r\n");

    my $tag = $a->inline_image('images/test.png');
    like($tag, qr/^<img src="data:image\/png;base64,/, 'inline_image starts correctly');
    like($tag, qr/">$/, 'inline_image ends correctly');
}

# ---- bundle ----

{
    my $a = Chandra::Assets->new(root => $dir);
    my $result = $a->bundle(
        css => ['css/reset.css', 'css/style.css'],
        js  => ['js/utils.js', 'js/main.js'],
    );

    ok(ref $result eq 'HASH', 'bundle returns hashref');

    like($result->{css}, qr/^<style>/, 'bundle css starts with <style>');
    like($result->{css}, qr/<\/style>$/, 'bundle css ends with </style>');
    like($result->{css}, qr/margin: 0/, 'bundle css includes reset');
    like($result->{css}, qr/color: red/, 'bundle css includes style');

    like($result->{js}, qr/^<script>/, 'bundle js starts with <script>');
    like($result->{js}, qr/<\/script>$/, 'bundle js ends with </script>');
    like($result->{js}, qr/function add/, 'bundle js includes utils');
    like($result->{js}, qr/console\.log/, 'bundle js includes main');
}

# ---- bundle with 3 CSS files ----

{
    my $a = Chandra::Assets->new(root => $dir);
    my $result = $a->bundle(
        css => ['css/reset.css', 'css/style.css', 'css/theme.css'],
    );
    like($result->{css}, qr/margin: 0/, 'triple bundle includes reset');
    like($result->{css}, qr/color: red/, 'triple bundle includes style');
    like($result->{css}, qr/background: #000/, 'triple bundle includes theme');
}

# ---- bundle error on bad type ----

{
    my $a = Chandra::Assets->new(root => $dir);
    eval { $a->bundle(xml => ['data.json']) };
    like($@, qr/unknown type/, 'bundle rejects unknown type');
}

done_testing;
