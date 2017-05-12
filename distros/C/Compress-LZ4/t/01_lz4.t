use strict;
use warnings;
use Test::More;
use Compress::LZ4;
use Config;

for (qw(compress compress_hc decompress uncompress)) {
    ok eval "defined &$_", "$_() is exported";
    ok eval "defined &lz4_$_", "lz4_$_() is exported";
}

{
    no warnings 'uninitialized';
    my $compressed = compress(undef);
    my $decompressed = decompress($compressed);
    is $decompressed, '', 'undef';
}

for my $len (0 .. 1_024) {
    my $in = '0' x $len;
    my $compressed = compress($in);
    my $decompressed = decompress($compressed);
    is $decompressed, $in, "rountrip- length: $len";
    is compress_hc($in, 4), $compressed, "compress_hc- length: $len";
}

{
    my $scalar = '0' x 1_024;
    ok compress($scalar) eq compress(\$scalar), 'scalar ref';
}

{
    package TrimmedString;
    sub new { bless(\"$_[1]", $_[0]) }
    use overload q("") => \&str;
    sub str { s/^\s+//, s/\s+$// for $_ = "${$_[0]}"; $_ }

    package main;
    my $scalar = TrimmedString->new('  string  ');
    ok compress($scalar) eq compress('string'), 'blessed scalar ref';
}

{
    my $compressed = compress('string');
    ok compress(substr 'string', 0) eq $compressed,
        'compressing magical substr lvalue';
    ok uncompress(substr $compressed, 0) eq uncompress($compressed),
        'uncompressing magical substr lvalue';
}

{
    my $in = 'testtesttest';
    my $len = length $in;
    my $compressed = compress($in);
    my $compressed_raw = lz4_compress($in);
    is length($compressed_raw), length($compressed) - 4, 'raw length';
    is $compressed_raw, substr($compressed, 4), 'raw data';
    is lz4_decompress($compressed_raw, $len), decompress($compressed),
        'raw decompressed';
}

# https://rt.cpan.org/Public/Bug/Display.html?id=75624
SKIP: {
    skip 'not AMD64', 1
        unless $Config{archname} =~ /(?:x86_|amd)64/;
    # Remove the length header.
    my $data = unpack "x4 a*", compress('0' x 14);
    cmp_ok $data, 'eq', "\0240\001\0P00000", 'AMD64 bug';
}

# https://rt.cpan.org/Public/Bug/Display.html?id=120991
decompress("\0"x5);

done_testing;
