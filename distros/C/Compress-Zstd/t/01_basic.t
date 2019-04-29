use strict;
use warnings;

use Test::More;
use Compress::Zstd;

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

is ZSTD_VERSION_NUMBER, 10400;
is ZSTD_VERSION_STRING, '1.4.0';
is ZSTD_MAX_CLEVEL, 22;

done_testing;
