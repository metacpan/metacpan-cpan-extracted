use strict;
use warnings;

use Test::More;
use Compress::Stream::Zstd;
use Compress::Stream::Zstd::CompressionContext;
use Compress::Stream::Zstd::DecompressionContext;

my $cctx = Compress::Stream::Zstd::CompressionContext->new;
my $src = 'Hello, World!';
ok my $compressed = $cctx->compress($src, 3);
isnt $src, $compressed;

my $dctx = Compress::Stream::Zstd::DecompressionContext->new;
ok my $decompressed = $dctx->decompress($compressed);
is $decompressed, $src;

done_testing;

__END__
