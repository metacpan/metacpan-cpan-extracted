use strict;
use warnings;
use Test::More tests => '6';

use utf8;
use Acme::MotorcycleGang;

is( Acme::MotorcycleGang->yorosiku("あい"), "愛");
is( Acme::MotorcycleGang->yorosiku("あいらぶゆう"), "愛羅武勇");
is( Acme::MotorcycleGang->yorosiku("あいらぶゆー"), "愛羅武勇");
is( Acme::MotorcycleGang->yorosiku("アイラブユウ"), "愛羅武勇");
is( Acme::MotorcycleGang->yorosiku("アイラブユー"), "愛羅武勇");

is( Acme::MotorcycleGang->yorosiku("しんじゅく区"), "神呪苦区");

