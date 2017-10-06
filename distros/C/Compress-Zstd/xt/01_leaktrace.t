use strict;
use warnings;

use Test::More;
use Compress::Zstd;

eval 'use Test::LeakTrace 0.08';
plan skip_all => "Test::LeakTrace 0.08 required for testing leak trace" if $@;
plan tests => 1;

no_leaks_ok(sub {
    my $blah = decompress(compress('blah blah'));
    decompress(1); # error. returns undef

    my $compressor = Compress::Zstd::Compressor->new;
    my $res = $compressor->compress('abc');
    $res .= $compressor->flush;
    $res .= $compressor->end;
    my $decompressor = Compress::Zstd::Decompressor->new;
    my $out = $decompressor->decompress($res);
});
