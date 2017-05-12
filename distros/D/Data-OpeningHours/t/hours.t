use Test::More;
use Data::OpeningHours::Hours;

my $h = Data::OpeningHours::Hours->new([['10:00', '12:00']]);

ok($h->is_open_between('11:00'));
ok($h->is_open_between('11:59'));
ok($h->is_open_between('10:00'));
ok(!$h->is_open_between('12:00'));
ok(!$h->is_open_between('09:00'));
ok(!$h->is_open_between('09:59'));

done_testing();

