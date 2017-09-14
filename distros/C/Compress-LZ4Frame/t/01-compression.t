#!/usr/bin/env perl

use 5.010_001;
use strict;
use warnings;

use constant PKG => 'Compress::LZ4Frame';

use Test::More tests => 12;

# try using
BEGIN { use_ok(PKG, ':all') };

# check interface
can_ok(PKG, 'compress');
can_ok(PKG, 'compress_checksum');
can_ok(PKG, 'decompress');
can_ok(PKG, 'looks_like_lz4frame');

# try some simple compression
my @data = map { $_ => rand } (1..50000);
my $input = pack 'd*', @data;
my $compressed = compress $input;
my $decompressed = decompress $compressed;
is($decompressed, $input, 'decompressing compressed data yields original');
ok(length $compressed < length $input, 'compressed data is smaller than original');

# check the checker
ok(looks_like_lz4frame($compressed), 'compressed data should be detected as such');
ok(!looks_like_lz4frame($decompressed), 'uncompressed data should be detected as such');

# check decompressing concatenated data
my $catted_compressed = $compressed . $compressed;
my $catted_original = $input . $input;
my $catted_decompressed = decompress $catted_compressed;
is($catted_decompressed, $catted_original, 'decompressing concatenated frames yields concatenated original');

# check decompressing data without size info
sub load_test_file {
    local $@;
    my $content;
    eval {
        use autodie ':io';
        open my $fh, '<', $_[0];
        binmode $fh if $_[0] =~ m/[.]lz4$/;
        $content = do { local $/; <$fh> };
        close $fh;
    };
    return $content;
}
my $lorem_original   = load_test_file 't/lorem.txt';
my $lorem_compressed = load_test_file 't/lorem.txt.lz4';

SKIP: {
    skip 'could not load test files', 1 unless $lorem_original && $lorem_compressed;

    $lorem_original =~ s/\r//g; # fix windows line endings
    my $lorem_decompressed = decompress $lorem_compressed;
    is($lorem_decompressed, $lorem_original, 'decompressing frames where size header is 0 should work');
}

my $bad_file = load_test_file 't/lz4_of_doom.lz4';
SKIP: {
    skip 'could not load test file', 1 unless $bad_file;

    my $bad_content = decompress $bad_file;
    is($bad_content, undef, 'decompressing bad data yields undef');
}
