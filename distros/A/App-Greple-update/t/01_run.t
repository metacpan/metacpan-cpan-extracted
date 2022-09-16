use v5.14;
use warnings;
use Encode;
use utf8;

use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

my $has_devfd = -r sprintf "/dev/fd/%d", DATA->fileno;

line(update(qw(fox --cm sub{uc} --diff t/SAMPLE.txt))
     ->run->{stdout}, 9, "--diff");

SKIP: {
    skip("/dev/fd is not available", 1) unless $has_devfd;
    line(update(qw(fox --cm sub{uc} --diff))
	 ->setstdin(slurp('t/SAMPLE.txt'))
	 ->run->{stdout}, 9, "--diff (stdin)");
}

done_testing;

__DATA__

あのイーハトーヴォのすきとおった風、
夏でも底に冷たさをもつ青いそら、
うつくしい森で飾られたモリーオ市、
郊外のぎらぎらひかる草の波。

またそのなかでいっしょになったたくさんのひとたち、
ファゼーロとロザーロ、羊飼のミーロや、
顔の赤いこどもたち、地主のテーモ、
山猫博士のボーガント・デストゥパーゴなど、
いまこの暗い巨きな石の建物のなかで考えていると、
みんなむかし風のなつかしい青い幻燈のように思われます。

では、わたくしはいつかの小さなみだしをつけながら、
しずかにあの年のイーハトーヴォの五月から十月までを書きつけましょう。

