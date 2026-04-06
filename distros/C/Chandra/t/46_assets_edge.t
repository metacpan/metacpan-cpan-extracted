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

my $dir = tempdir(CLEANUP => 1);
mkpath("$dir/sub/deep");

sub _write {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
}

_write("$dir/file.txt",          "hello");
_write("$dir/empty.css",         "");
_write("$dir/sub/nested.js",     "var x = 1;");
_write("$dir/sub/deep/a.css",    "a {}");
_write("$dir/binary.bin",        "\x00\x01\x02\x03");
_write("$dir/has spaces.txt",    "spaced");
_write("$dir/UPPER.CSS",         "upper");

# ---- Path traversal attempts ----

{
    my $a = Chandra::Assets->new(root => $dir);

    my @bad_paths = (
        '../etc/passwd',
        '../../root/.ssh/id_rsa',
        'sub/../../etc/shadow',
        'sub/../../../outside',
    );

    for my $bad (@bad_paths) {
        eval { $a->read($bad) };
        like($@, qr/traversal/i, "blocked: $bad");
    }
}

# ---- Backslash rejection ----

{
    my $a = Chandra::Assets->new(root => $dir);

    eval { $a->read('sub\\nested.js') };
    like($@, qr/traversal/i, 'backslash path rejected');
}

# ---- Empty file ----

{
    my $a = Chandra::Assets->new(root => $dir);

    my $content = $a->read('empty.css');
    is($content, '', 'read empty file returns empty string');

    my $tag = $a->inline_css('empty.css');
    is($tag, '<style></style>', 'inline_css on empty file');
}

# ---- Binary file read ----

{
    my $a = Chandra::Assets->new(root => $dir);
    my $content = $a->read('binary.bin');
    ok(defined $content, 'read binary file');
    is(length($content), 4, 'binary content correct length');
}

# ---- Missing file ----

{
    my $a = Chandra::Assets->new(root => $dir);

    ok(!$a->exists('nonexistent.xyz'), 'missing file not found');

    eval { $a->inline_css('nonexistent.css') };
    like($@, qr/Cannot read/, 'inline_css on missing file croaks');

    eval { $a->inline_js('nonexistent.js') };
    like($@, qr/Cannot read/, 'inline_js on missing file croaks');

    eval { $a->inline_image('nonexistent.png') };
    like($@, qr/Cannot read/, 'inline_image on missing file croaks');
}

# ---- Unicode filename ----

{
    my $a = Chandra::Assets->new(root => $dir);
    my $uname = "caf\xc3\xa9.txt";  # UTF-8 bytes for café
    eval { _write("$dir/$uname", "unicode content") };

    SKIP: {
        skip "filesystem doesn't support unicode", 2 if $@ || !-f "$dir/$uname";
        ok($a->exists($uname), 'unicode filename exists');
        is($a->read($uname), "unicode content", 'read unicode filename');
    }
}

# ---- Deeply nested path ----

{
    my $a = Chandra::Assets->new(root => $dir);
    is($a->read('sub/deep/a.css'), 'a {}', 'read deeply nested file');
    ok($a->exists('sub/deep/a.css'), 'deeply nested file exists');
}

# ---- Unknown extension MIME ----

{
    my $a = Chandra::Assets->new(root => $dir);
    is($a->mime_type('file.xyz123'), 'application/octet-stream', 'unknown ext');
    is($a->mime_type('no-dot'), 'application/octet-stream', 'no extension');
    is($a->mime_type('.hidden'), 'application/octet-stream', 'dot-only name');
}

# ---- Large MIME type coverage ----

{
    my $a = Chandra::Assets->new(root => $dir);

    my @extra = (
        ['file.htm',   'text/html'],
        ['file.xml',   'application/xml'],
        ['file.csv',   'text/csv'],
        ['file.md',    'text/markdown'],
        ['file.bmp',   'image/bmp'],
        ['file.otf',   'font/otf'],
        ['file.ogg',   'audio/ogg'],
        ['file.wav',   'audio/wav'],
        ['file.wasm',  'application/wasm'],
        ['file.pdf',   'application/pdf'],
        ['file.zip',   'application/zip'],
        ['file.mjs',   'application/javascript'],
    );

    for my $case (@extra) {
        is($a->mime_type($case->[0]), $case->[1], "mime: $case->[0]");
    }
}

# ---- Multiple roots (separate instances) ----

{
    my $dir2 = tempdir(CLEANUP => 1);
    _write("$dir2/other.txt", "other content");

    my $a1 = Chandra::Assets->new(root => $dir);
    my $a2 = Chandra::Assets->new(root => $dir2);

    ok($a1->exists('file.txt'),    'a1 has its file');
    ok(!$a1->exists('other.txt'),  'a1 does not have a2 file');
    ok($a2->exists('other.txt'),   'a2 has its file');
    ok(!$a2->exists('file.txt'),   'a2 does not have a1 file');
}

# ---- inline_image with actual binary ----

{
    my $a = Chandra::Assets->new(root => $dir);
    _write("$dir/test.gif", "GIF89a\x01\x00\x01\x00\x80\x00\x00");

    my $tag = $a->inline_image('test.gif');
    like($tag, qr/^<img src="data:image\/gif;base64,/, 'gif inline data uri');
    like($tag, qr/">$/, 'gif inline ends properly');
    # Verify it's valid base64 (no line breaks)
    unlike($tag, qr/\n/, 'inline_image has no newlines in base64');
}

# ---- Concurrent reads (same instance) ----

{
    my $a = Chandra::Assets->new(root => $dir);
    my @results;
    for (1..10) {
        push @results, $a->read('file.txt');
    }
    is_deeply(\@results, [('hello') x 10], 'repeated reads consistent');
}

# ---- bundle with single file ----

{
    my $a = Chandra::Assets->new(root => $dir);
    my $r = $a->bundle(css => ['sub/deep/a.css']);
    is($r->{css}, '<style>a {}</style>', 'single-file bundle');
}

# ---- bundle error: not an arrayref ----

{
    my $a = Chandra::Assets->new(root => $dir);
    eval { $a->bundle(css => 'not-an-array') };
    like($@, qr/arrayref/, 'bundle with non-arrayref croaks');
}

done_testing;
