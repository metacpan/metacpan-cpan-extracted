use strict;
use warnings;

use Test::More;
use Compress::Zstd;
use Compress::Zstd::CompressionContext;
use Compress::Zstd::DecompressionContext;

my $cctx = Compress::Zstd::CompressionContext->new;
my $src = 'Hello, World!';
ok my $compressed = $cctx->compress($src, 3);
isnt $src, $compressed;

my $dctx = Compress::Zstd::DecompressionContext->new;
ok my $decompressed = $dctx->decompress($compressed);
is $decompressed, $src;

done_testing;

__END__
