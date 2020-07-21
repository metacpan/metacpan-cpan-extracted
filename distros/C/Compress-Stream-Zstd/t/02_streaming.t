use strict;
use warnings;

use Test::More;
use Compress::Stream::Zstd;
use Compress::Stream::Zstd::Compressor qw(ZSTD_CSTREAM_IN_SIZE);
use Compress::Stream::Zstd::Decompressor qw(ZSTD_DSTREAM_IN_SIZE);

cmp_ok ZSTD_CSTREAM_IN_SIZE, '>', 0;
cmp_ok ZSTD_DSTREAM_IN_SIZE, '>', 0;

my $compressor = Compress::Stream::Zstd::Compressor->new;
isa_ok $compressor, 'Compress::Stream::Zstd::Compressor';
is $compressor->isError(), 0;
my $output = '';
$output .= $compressor->compress('a');
$output .= $compressor->compress('b');
$output .= $compressor->compress('c');
$output .= $compressor->flush;
$output .= $compressor->end;
ok $output;

my $decompressor = Compress::Stream::Zstd::Decompressor->new;
isa_ok $decompressor, 'Compress::Stream::Zstd::Decompressor';
is $compressor->isError(), 0;
my $result = '';
$result .= $decompressor->decompress(substr($output, 0, 3));
$result .= $decompressor->decompress(substr($output, 3, -1));
is $result, 'abc';

is decompress($output), 'abc';

{
    # Check can uncompress empty zstd buffer
    my $empty = "\x28\xb5\x2f\xfd\x24\x00\x01\x00\x00\x99\xe9\xd8\x51";

    my $decompressor = Compress::Stream::Zstd::Decompressor->new;
    isa_ok $decompressor, 'Compress::Stream::Zstd::Decompressor';
    my $result = '';
    $result .= $decompressor->decompress(substr($empty, 0, 3));
    is $decompressor->isError(), 0;
    ok ! $decompressor->isEndFrame();

    $result .= $decompressor->decompress(substr($empty, 3));

    is $decompressor->isError(), 0;
    ok $decompressor->isEndFrame();

    is $result, '';

    is decompress($empty), '';
}

done_testing;
