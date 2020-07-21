use strict;
use warnings;

use Test::More;
use Compress::Stream::Zstd;
use Compress::Stream::Zstd::CompressionContext;
use Compress::Stream::Zstd::DecompressionContext;
use Compress::Stream::Zstd::CompressionDictionary;
use Compress::Stream::Zstd::DecompressionDictionary;

my $cctx = Compress::Stream::Zstd::CompressionContext->new;
my $src = 'Hello, World!';
my $cdict = Compress::Stream::Zstd::CompressionDictionary->new_from_file('t/test.dic', 3);
ok my $compressed = $cctx->compress_using_dict($src, $cdict);
isnt $src, $compressed;

my $dctx = Compress::Stream::Zstd::DecompressionContext->new;
my $ddict = Compress::Stream::Zstd::DecompressionDictionary->new_from_file('t/test.dic');
ok my $decompressed = $dctx->decompress_using_dict($compressed, $ddict);
is $decompressed, $src;

done_testing;

__END__
