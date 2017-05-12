#!/usr/bin/perl

no utf8;
no encoding;
use strict;
use Test::Simple tests => 3;

use Convert::EastAsianWidth;
ok($Convert::EastAsianWidth::VERSION) if $Convert::EastAsianWidth::VERSION or 1;

ok(
    to_fullwidth('相對論：E = M(C**2)', 'big5'),
    '相對論：Ｅ　＝　Ｍ（Ｃ＊＊２）',
);

ok(
    to_halfwidth('相對論：Ｅ　＝　Ｍ（Ｃ＊＊２）', 'big5'),
    '相對論:E = M(C**2)',
);
