use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

my $date = Date->new("2013-03-05 02:04:06");
ok(!eval{$date->strftime; 1;});
ok(!$date->strftime(""));
is($date->strftime('%Y'), '2013');
is($date->strftime('%Y/%m/%d'), '2013/03/05');
is($date->strftime('%H-%M-%S'), '02-04-06');

Time::XS::tzset('Europe/Kiev');
$date = Date->new("2013-03-05 02:04:06");
say $date->strftime("%Y/%m/%d %H-%M-%S %Z");

like($date->strftime('%b %B'), qr/^\S+ \S+$/);
like($date->monname, qr/^\S+$/);
is($date->monthname, $date->monname);
like($date->wdayname, qr/^\S+$/);
is($date->wdayname, $date->day_of_weekname);

done_testing();
