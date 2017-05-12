#!perl
use strict;
use warnings;
use Test::More tests => 9;
use Compress::LZMA::External
    qw(compress_fast compress_best compress decompress);

my $data = 'X' x 1000;

foreach my $subroutine (qw(compress_fast compress compress_best)) {
    my $compressed;
    {
        no strict 'refs';
        $compressed = &{$subroutine}($data);
    }
    ok( length($compressed) < 1000, "$subroutine compresses" );

    my $uncompressed = decompress($compressed);
    is( length($uncompressed), 1000,
        "decompressed $subroutine-compressed data has correct length" );
    is( $uncompressed, $data,
        "decompressed $subroutine-compressed data has correct data" );
}

