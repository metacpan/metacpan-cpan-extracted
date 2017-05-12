use warnings;
use strict;
use utf8;
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
BEGIN { use_ok('Date::Qreki') };
use Date::Qreki ':all';

check ([1966, 3, 16], [1966, 0, 2, 25], 3);
check ([1996, 10, 17], [1996, 0, 9, 6], 3);
check ([996, 1, 17], [995, 0, 12, 19], 1);
# Date of changeover to Gregorian calendar in Japan.
# According to http://ja.wikipedia.org/wiki/%E6%97%A7%E6%9A%A6.
check ([1873, 1, 1], [1872, 0, 12, 3], 3);

my $rokuyou = rokuyou_unicode (2017, 1, 31);
is ($rokuyou, '仏滅');
# http://eco.mtk.nao.ac.jp/koyomi/yoko/2017/rekiyou172.html
my $sekki1 = check_24sekki (2017,1,05);
is ($sekki1, '小寒');
my $sekki2 = check_24sekki (2017,1,06);
is ($sekki2, '');

done_testing ();

sub check
{
    my ($dates, $expect, $expect_rokuyou) = @_;
    my @kyureki = calc_kyureki (@$dates);
    is_deeply (\@kyureki, $expect, "Test kyureki");
    my $rokuyou = get_rokuyou (@$dates);
    is ($rokuyou, $expect_rokuyou, "Test rokuyou");
}

# Local variables:
# mode: perl
# End:
