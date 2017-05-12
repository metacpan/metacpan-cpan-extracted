# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('Compress::Zopfli') };

is(ZOPFLI_FORMAT_GZIP, 0, "Constant: ZOPFLI_FORMAT_GZIP");
is(ZOPFLI_FORMAT_ZLIB, 1, "Constant: ZOPFLI_FORMAT_ZLIB");
is(ZOPFLI_FORMAT_DEFLATE, 2, "Constant: ZOPFLI_FORMAT_DEFLATE");