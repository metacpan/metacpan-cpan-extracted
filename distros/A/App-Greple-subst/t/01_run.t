use v5.14;
use warnings;
use Encode;
use utf8;

use Test::More;
use Data::Dumper;

use lib 't';
use Util;

my $has_devfd = -r sprintf "/dev/fd/%d", DATA->fileno;

is(subst(qw(--dict t/JA.dict t/JA-bad.txt))->run->{result}, 0);

line(subst(qw(--dict t/JA.dict t/JA-bad.txt))
     ->run->{stdout}, 9, "--dict");
line(subst(qw(--dict t/JA.dict t/JA-bad.txt --stat))
     ->run->{stdout}, 11, "--stat");
line(subst(qw(--dict t/JA.dict t/JA-bad.txt --with-stat))
     ->run->{stdout}, 20, "--with-stat");
line(subst(qw(--dict t/JA.dict t/JA-bad.txt --with-stat --stat-item dict=1))
     ->run->{stdout}, 21, "dict=1");

line(subst(qw(--dict t/JA.dict t/JA-bad.txt --diff))
     ->run->{stdout}, 28, "--diff");

SKIP: {
    skip("/dev/fd is not available", 1) unless $has_devfd;
    line(subst(qw(--dict t/JA.dict --diff))
	 ->setstdin(slurp('t/JA-bad.txt'))
	 ->run->{stdout}, 28, "--diff (stdin)");
}

line(subst('--dictdata', <<'END', 't/JA-bad.txt')->run->{stdout}, 2, "--dictdata");
イ[エー]ハトー?([ヴブボ]ォ?)	イーハトーヴォ
END

line(subst('--dictdata', <<'END', 't/JA-bad.txt')->run->{stdout}, 3, "--dictdata");
イ[エー]ハトー?([ヴブボ]ォ?)	イーハトーヴォ
デストゥ?パーゴ			デストゥパーゴ
END

is(subst(qw(--dict t/JA.dict t/JA-bad.txt --subst --all --no-color))
   ->run->{stdout},
   slurp("t/JA.txt"), "--subst");

SKIP: {
    skip("/dev/fd is not available", 1) unless $has_devfd;
    is(subst(qw(--dict t/JA.dict --subst --all --no-color))
       ->setstdin(slurp('t/JA-bad.txt'))
       ->run->{stdout},
       slurp("t/JA.txt"), "--subst (stdin)");
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

