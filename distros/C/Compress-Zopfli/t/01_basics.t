# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('Compress::Zopfli') };

ok(Compress::Zopfli::compress("test", ZOPFLI_FORMAT_GZIP, {}), "GZIP test");
ok(Compress::Zopfli::compress("test", ZOPFLI_FORMAT_ZLIB, {}), "ZLIB test");
ok(Compress::Zopfli::compress("test", ZOPFLI_FORMAT_DEFLATE, {}), "Deflate test");
