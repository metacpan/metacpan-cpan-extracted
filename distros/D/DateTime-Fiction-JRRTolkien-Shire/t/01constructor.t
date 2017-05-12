use strict;
use warnings;

use Test::More tests => 17;
use DateTime;
use DateTime::Fiction::JRRTolkien::Shire;
use Time::Local;

my $shire1 = DateTime::Fiction::JRRTolkien::Shire->new(year => 1420,
						       holiday => '2 Yule');
my $shire2 = DateTime::Fiction::JRRTolkien::Shire->new(year => 7467,
						       month => 10,
						       day => 4,
						       hour => 10,
						       minute => 30,
						       time_zone => 'floating');
my $dt2 = DateTime->new(year => 2003,
			month => 9,
			day => 26,
			hour => 10,
			minute => 30,
			time_zone => 'floating');
my $shire3 = DateTime::Fiction::JRRTolkien::Shire->new(year => 7467,
						       month => 'Solmath');
my $shire4 = DateTime::Fiction::JRRTolkien::Shire->last_day_of_month(year => 7557,
								     month => 10);
my $shire5 = DateTime::Fiction::JRRTolkien::Shire->new(year => 7557,
						       month => 10,
						       day => 30);
my $shire6 = DateTime::Fiction::JRRTolkien::Shire->from_day_of_year(year => 7465,
								    day_of_year => 187);
my $shire7 = DateTime::Fiction::JRRTolkien::Shire->new(year => 7420,
						       holiday => 4);

# Not timelocal, because DateTime->from_epoch() produces an object with
# zone 'UTC', not 'floating'.
my $shire8 = DateTime::Fiction::JRRTolkien::Shire->from_epoch(epoch => timegm(0, 0, 0, 17, 11, 2003));

is($shire1->holiday, 1);
is(($shire2->utc_rd_values)[0], ($dt2->utc_rd_values)[0]);
is(($shire2->utc_rd_values)[1], ($dt2->utc_rd_values)[1]);
is(($shire2->utc_rd_values)[2], ($dt2->utc_rd_values)[2]);
ok(DateTime::Fiction::JRRTolkien::Shire->from_object(object => $dt2) == $shire2);
is($shire3->month, 2);
is($shire3->day, 1);
ok(DateTime::Fiction::JRRTolkien::Shire->now);
ok(DateTime::Fiction::JRRTolkien::Shire->today);
is($shire4->day, 30);
is($shire4->utc_rd_as_seconds, $shire5->utc_rd_as_seconds);
is($shire6->month, 7);
is($shire6->day, 3);
is($shire7->holiday, 4);
is($shire8->year, 7467);
is($shire8->month, 12);
is($shire8->day, 26);
