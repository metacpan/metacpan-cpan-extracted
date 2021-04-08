use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

catch_run("[advanced]");

sub test ($&);

my $date;

$date = Date->new("2013-09-05 03:04:05");

test 'to_string' => sub {
    my $date = Date->new("2013-09-05 13:14:15.123456+02");
    is($date->to_string(Date::FORMAT_HMS), '13:14:15');
};

test 'mksec' => sub {
    my $date = Date->new("2013-09-05 13:14:15.123456+02");
    is($date->mksec, '123456');
};

test 'gmtoff' => sub {
    my $date = Date->new("2013-09-05 13:14:15.123456+02");
    is($date->gmtoff, 2 * 3600);
    
    $date = Date->new("2013-09-05 23:04:05");
    is($date->gmtoff, 14400);
    
    tzset('America/New_York');
    $date = Date->new("2013-09-05 23:45:56");
    is($date->gmtoff, -14400);
};

test 'array' => sub {
    my $date = Date->new("2013-09-05 03:04:05");
    is_deeply [$date->array], [2013,9,5,3,4,5];
};

test 'struct' => sub {
    my $date = Date->new("2012-09-05 03:04:05");
    is_deeply [$date->struct], [5,4,3,5,8,112,3,248,0];
};

test 'month days' => sub {
    my $date = Date->new("2013-09-05 03:04:05");
    is($date->month_begin_new, "2013-09-01 03:04:05");
    is($date->month_end_new, "2013-09-30 03:04:05");
    is($date->days_in_month, 30);
    
    $date = Date->new("2013-08-05 03:04:05");
    is($date->month_begin_new, "2013-08-01 03:04:05");
    is($date, "2013-08-05 03:04:05");
    is($date->month_end_new, "2013-08-31 03:04:05");
    is($date, "2013-08-05 03:04:05");
    is($date->days_in_month, 31);
    $date->month_begin;
    is($date, "2013-08-01 03:04:05");
    $date->month_end;
    is($date, "2013-08-31 03:04:05");
    
    $date = Date->new("2013-02-05 03:04:05");
    is($date->month_begin_new, "2013-02-01 03:04:05");
    is($date->month_end_new, "2013-02-28 03:04:05");
    is($date->days_in_month, 28);
    
    $date = Date->new("2012-02-05 03:04:05");
    is($date->month_begin_new, "2012-02-01 03:04:05");
    is($date->month_end_new, "2012-02-29 03:04:05");
    is($date->days_in_month, 29);
};


test 'now' => sub {
    my $now = Date::now();
    ok(abs($now->epoch - time) <= 1);
};

test 'today' => sub {
    my $now = Date::now();
    my $date = Date::today();
    is($date->year, $now->year);
    is($date->month, $now->month);
    is($date->day, $now->day);
    is($date->hour, 0);
    is($date->min, 0);
    is($date->sec, 0);
};

test 'today_epoch' => sub {
    ok(abs(Date::today_epoch() - Date::today()->epoch) <= 1);
};

test 'date' => sub {
    my $date = date(0);
    is($date, "1970-01-01 03:00:00");
    $date = date(1000000000);
    is($date, "2001-09-09 05:46:40");
    $date = Date::date_ymd(2012,02,20,15,16,17);
    is($date, "2012-02-20 15:16:17", "line: ".__LINE__);
    $date = Date::date_ymd(year => 2013, month => 06, day => 28, hour => 6, min => 6, sec => 6);
    is($date, "2013-06-28 06:06:06");
};

test 'truncate' => sub {
    my $date = Date::date "2013-01-26 06:47:29";
    my $date2 = $date->truncated;
    is($date, "2013-01-26 06:47:29");
    is($date2, "2013-01-26 00:00:00");
    $date->truncate;
    is($date, "2013-01-26 00:00:00");
};

test 'to_number' => sub {
    is(int(date(123456789)), 123456789);
};

test 'set' => sub {
    my $date = date(0);
    $date->set(10);
    is($date, "1970-01-01 03:00:10");
    $date->set("2970-01-01 03:00:10");
    is($date, "2970-01-01 03:00:10");
    $date->set_ymd(2010,5,6,7,8,9);
    is($date, "2010-05-06 07:08:09", "line: ".__LINE__);
    $date->set_ymd(year => 2013, hour => 23);
    is($date, "2013-01-01 23:00:00");
};

test 'dont core dump on bad values' => sub {
    my $date = eval { date([]); 1 };
    is($date, undef, "line: ".__LINE__);
    $date = eval { date(\1); 1 };
    is($date, undef, "line: ".__LINE__);
    $date = eval { date({}); 1 };
    is($date, undef, "line: ".__LINE__);
};

test 'strftime' => sub {
    my $date = date(10);
    is $date->strftime("%Y:%S"), "1970:10";
};

test 'week_of_month' => sub {
    # Mon Tue Wed Thu Fri Sat Sun
    #                       1   2
    #   3   4   5   6   7   8   9
    #  10  11  12  13  14  15  16
    #  17  18  19  20  21  22  23
    #  24  25  26  27  28  29  30
    #  31
    my $date = date("2020-08-01");
    is $date->week_of_month, 0;
    $date->mday(2);
    is $date->week_of_month, 0;
    $date->mday(3);
    is $date->week_of_month, 1;
    $date->mday(9);
    is $date->week_of_month, 1;
    $date->mday(10);
    is $date->week_of_month, 2;
    $date->mday(16);
    is $date->week_of_month, 2;
    $date->mday(17);
    is $date->week_of_month, 3;
    $date->mday(23);
    is $date->week_of_month, 3;
    $date->mday(24);
    is $date->week_of_month, 4;
    $date->mday(30);
    is $date->week_of_month, 4;
    $date->mday(31);
    is $date->week_of_month, 5;
};

test 'weeks_in_year' => sub {
    my $date = date("2020-01-01");
    is $date->weeks_in_year, 53;
    $date->year(2019);
    is $date->weeks_in_year, 52;
    $date->year(2018);
    is $date->weeks_in_year, 52;
    $date->year(2017);
    is $date->weeks_in_year, 52;
    $date->year(2016);
    is $date->weeks_in_year, 52;
    $date->year(2015);
    is $date->weeks_in_year, 53;
    $date->year(2048);
    is $date->weeks_in_year, 53;
    $date->year(1998);
    is $date->weeks_in_year, 53;
};

test 'week_of_year' => sub {
    my $date = date("2020-06-19");
    is_deeply [$date->week_of_year], [2020, 25];
    is scalar($date->week_of_year), 25;
    $date = date("2020-01-01");
    is_deeply [$date->week_of_year], [2020, 1];
    is scalar($date->week_of_year), 1;
    $date = date("2020-12-31");
    is_deeply [$date->week_of_year], [2020, 53];
    is scalar($date->week_of_year), 53;
    
    $date = date("2019-06-19");
    is_deeply [$date->week_of_year], [2019, 25];
    is scalar($date->week_of_year), 25;
    $date = date("2019-01-01");
    is_deeply [$date->week_of_year], [2019, 1];
    is scalar($date->week_of_year), 1;
    $date = date("2019-12-31");
    is_deeply [$date->week_of_year], [2020, 1];
    is scalar($date->week_of_year), 1;
    
    $date = date("2017-01-01");
    is_deeply [$date->week_of_year], [2016, 52];
    is scalar($date->week_of_year), 52;
    $date = date("2017-12-31");
    is_deeply [$date->week_of_year], [2017, 52];
    is scalar($date->week_of_year), 52;
};

done_testing();

sub test ($&) {
    my ($name, $sub) = @_;
    tzset('Europe/Moscow');
    subtest $name => $sub;
}