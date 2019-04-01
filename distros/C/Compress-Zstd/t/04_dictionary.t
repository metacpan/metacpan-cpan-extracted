use strict;
use warnings;

use Test::More;
use Compress::Zstd;
use Compress::Zstd::CompressionContext;
use Compress::Zstd::DecompressionContext;
use Compress::Zstd::CompressionDictionary;
use Compress::Zstd::DecompressionDictionary;

my $cctx = Compress::Zstd::CompressionContext->new;
my $src = 'Hello, World!';
my $cdict = Compress::Zstd::CompressionDictionary->new_from_file('t/test.dic', 3);
ok my $compressed = $cctx->compress_using_dict($src, $cdict);
isnt $src, $compressed;

my $dctx = Compress::Zstd::DecompressionContext->new;
my $ddict = Compress::Zstd::DecompressionDictionary->new_from_file('t/test.dic');
ok my $decompressed = $dctx->decompress_using_dict($compressed, $ddict);
is $decompressed, $src;

done_testing;

__END__
