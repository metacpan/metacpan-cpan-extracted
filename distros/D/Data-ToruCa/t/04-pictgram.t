use strict;

use Test;
use Data::ToruCa qw(cat2pict);

BEGIN {
    plan tests => 29;
}

ok(cat2pict('0001'), "\xf8\x9f");
ok(cat2pict('005E'), "\xf8\xfc");
ok(cat2pict('005F'), "\xf9\x40");
ok(cat2pict('0068'), "\xf9\x49");
ok(cat2pict('0069'), "\xf9\x72");
ok(cat2pict('0075'), "\xf9\x7e");
ok(cat2pict('0076'), "\xf9\x80");
ok(cat2pict('0086'), "\xf9\x90");
ok(cat2pict('0087'), "\xf9\xb0");
ok(cat2pict('0088'), "\xf9\x91");
ok(cat2pict('00A6'), "\xf9\xaf");
ok(cat2pict('00A7'), "\xf9\x50");
ok(cat2pict('00A9'), "\xf9\x52");
ok(cat2pict('00AA'), "\xf9\x55");
ok(cat2pict('00AC'), "\xf9\x57");
ok(cat2pict('00AD'), "\xf9\x5b");
ok(cat2pict('00B0'), "\xf9\x5e");
ok(cat2pict('00B1'), "\xf9\xb1");
ok(cat2pict('00FC'), "\xf9\xfc");

ok(cat2pict('0010'), "\xf8\xae");
ok(cat2pict('0020'), "\xf8\xbe");
ok(cat2pict('0030'), "\xf8\xce");
ok(cat2pict('0040'), "\xf8\xde");
ok(cat2pict('0050'), "\xf8\xee");
ok(cat2pict('0060'), "\xf9\x41");
ok(cat2pict('0070'), "\xf9\x79");
ok(cat2pict('0080'), "\xf9\x8a");
ok(cat2pict('0090'), "\xf9\x99");
ok(cat2pict('00A0'), "\xf9\xa9");
