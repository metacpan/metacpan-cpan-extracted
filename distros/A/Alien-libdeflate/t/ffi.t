# -*- mode: perl; -*-

use strict;
use warnings;
use Test::More;
use Test::Alien qw{alien_ok ffi_ok};
use Alien::libdeflate;

alien_ok 'Alien::libdeflate';

ffi_ok {
    symbols => [
        qw{
libdeflate_alloc_compressor
libdeflate_deflate_compress
libdeflate_deflate_compress_bound
libdeflate_zlib_compress
libdeflate_zlib_compress_bound
libdeflate_gzip_compress
libdeflate_gzip_compress_bound
libdeflate_free_compressor
}] };

done_testing;
