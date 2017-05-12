#!/usr/bin/perl

use utf8;
use encoding 'utf8';
use strict;
use Test::Simple tests => 3;

use Convert::EastAsianWidth;
ok($Convert::EastAsianWidth::VERSION) if $Convert::EastAsianWidth::VERSION or 1;

ok(
    to_fullwidth('相對論：E = M(C**2)'),
    '相對論：Ｅ　＝　Ｍ（Ｃ＊＊２）',
);

ok(
    to_halfwidth('相對論：Ｅ　＝　Ｍ（Ｃ＊＊２）'),
    '相對論:E = M(C**2)',
);
