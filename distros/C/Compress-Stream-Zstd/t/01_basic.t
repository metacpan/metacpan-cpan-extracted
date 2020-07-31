use strict;
use warnings;

use Test::More;
use Compress::Stream::Zstd;

diag "\n";
diag "Compress::Stream::Zstd Version $Compress::Stream::Zstd::VERSION\n";
diag "ZSTD_VERSION_NUMBER            " . ZSTD_VERSION_NUMBER . "\n";
diag "ZSTD_VERSION_STRING            " . ZSTD_VERSION_STRING . "\n";
diag "ZSTD_MAX_CLEVEL                " . ZSTD_MAX_CLEVEL . "\n";
diag "ZSTD_MIN_CLEVEL                " . ZSTD_MIN_CLEVEL . "\n";
diag "\n";

my $src = 'Hello, World!';
ok my $compressed = compress($src, 42);
isnt $src, $compressed;
ok my $decompressed = decompress($compressed);
is uncompress($compressed), $decompressed, 'alias';
isnt $compressed, $decompressed;
is $decompressed, $src;

is decompress(\compress(\$src)), $src, 'ScalarRef';

is decompress(compress_mt($src, 2)), $src, 'Multi Thread';
is decompress(compress_mt(\$src, 2)), $src, 'Multi Thread ScalarRef';

decompress("1");

is ZSTD_VERSION_NUMBER, 10403;
is ZSTD_VERSION_STRING, '1.4.3';
is ZSTD_MAX_CLEVEL, 22;
is ZSTD_MIN_CLEVEL, -131072;

{
    # Test an empty string
    my $src = "";
    ok my $compressed = compress($src, 42);
    isnt $src, $compressed;
    my $decompressed = decompress($compressed);
    is uncompress($compressed), $decompressed, 'alias';
    isnt $compressed, $decompressed;
    is $decompressed, $src;
}

done_testing;
