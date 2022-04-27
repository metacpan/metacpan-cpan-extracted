use strict;
use warnings;

use Test::More;
use Compress::Stream::Zstd::Compressor qw(ZSTD_c_windowLog);
use Compress::Stream::Zstd::Decompressor qw(ZSTD_d_windowLogMax);

cmp_ok ZSTD_c_windowLog, '>', 0;
cmp_ok ZSTD_d_windowLogMax, '>', 0;

my $compressor = Compress::Stream::Zstd::Compressor->new;
$compressor->set_parameter( ZSTD_c_windowLog, 10 );

my $output = '';
$output .= $compressor->compress('a');
$output .= $compressor->compress('b');
$output .= $compressor->compress('c');
$output .= $compressor->flush;
$output .= $compressor->end;
ok $output;

my $decompressor = Compress::Stream::Zstd::Decompressor->new;
$decompressor->set_parameter( ZSTD_d_windowLogMax, 10);

my $result = '';
$result .= $decompressor->decompress(substr($output, 0, 3));
$result .= $decompressor->decompress(substr($output, 3, -1));
is $result, 'abc';

done_testing;
