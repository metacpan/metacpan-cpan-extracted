use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;
use Date;

catch_run("[basic]");

subtest 'from zero epoch' => sub {
    my $date = Date->new(0);
    is $date->epoch, 0;
    is $date->year, 1970;
    is $date->_year, 70;
    is $date->yr, 70;
    is $date->month, 1;
    is $date->mon, 1;
    is $date->_month, 0;
    is $date->_mon, 0;
    is $date->day, 1;
    is $date->mday, 1;
    is $date->day_of_month, 1;
    is $date->hour, 3;
    is $date->min, 0;
    is $date->minute, 0;
    is $date->sec, 0;
    is $date->second, 0;
    is $date->to_string, "1970-01-01 03:00:00";
};

subtest 'from epoch' => sub {
    my $date = Date->new(1000000000);
    is $date->to_string, "2001-09-09 05:46:40";
    is $date, "2001-09-09 05:46:40";
    is "$date", "2001-09-09 05:46:40";
    is $date->_year, 101;
    is $date->yr, 1;
    is $date, $date->to_string;
    is $date->to_number, 1000000000;
    is int($date), $date->to_number;
};

subtest 'from date' => sub {
    my $date = Date->new(Date->new(1000000000));
    is $date->epoch, 1000000000;
};

subtest 'from foreign object with stringification' => sub {
    {
        package MyDate;
        use overload '""' => sub { "2666-02-03 04:05:06" };
    }
    my $fd = bless {}, 'MyDate';
    my $date = Date->new($fd);
    is_deeply [$date->array], [2666, 2, 3, 4, 5, 6];
};

subtest 'from list' => sub {
    my $date = Date->new_ymd(2012,02,20,15,16,17);
    is $date, "2012-02-20 15:16:17";
    $date = Date->new_ymd(2012,02,20,15,16);
    is $date, "2012-02-20 15:16:00";
    $date = Date->new_ymd(2012,02,20,15);
    is $date, "2012-02-20 15:00:00";
    $date = Date->new_ymd(2012,02,20);
    is $date, "2012-02-20 00:00:00";
    $date = Date->new_ymd(2012,02);
    is $date, "2012-02-01 00:00:00";
    $date = Date->new_ymd(2012);
    is $date, "2012-01-01 00:00:00";
    $date = Date->new_ymd();
    is $date, "1970-01-01 00:00:00";
};

subtest 'from hash-list' => sub {
    my $date = Date->new_ymd(year => 2013, month => 06, day => 28, hour => 6, min => 6, sec => 6);
    is $date, "2013-06-28 06:06:06";
    $date = Date->new_ymd(month => 06, day => 28, hour => 6, min => 6, sec => 6);
    is $date, "1970-06-28 06:06:06";
    $date = Date->new_ymd(month => 06, hour => 6, min => 6, sec => 6);
    is $date, "1970-06-01 06:06:06";
    $date = Date->new_ymd(month => 06, sec => 6);
    is $date, "1970-06-01 00:00:06";
};

subtest 'from string' => sub {
    my $date = Date->new("2013-03-05 23:45:56");
    is $date->wday, 3;
    is $date->_wday, 2;
    is $date->day_of_week, 3;
    is $date->ewday, 2;
    is $date->yday, 64;
    is $date->day_of_year, 64;
    is $date->_yday, 63;
    ok !$date->isdst;
    ok !$date->daylight_savings;
    
    $date = Date->new("2013-03-10 23:45:56");
    is $date->wday, 1;
    is $date->_wday, 0;
    is $date->day_of_week, 1;
    is $date->ewday, 7;
    
    tzset('Europe/Kiev');
    
    $date = Date->new("2013-09-05 23:45:56");
    ok $date->isdst;
    ok $date->daylight_savings;
    is $date->tzabbr, 'EEST';
    
    $date = Date->new("2013-12-05 23:45:56");
    ok !$date->isdst;
    ok !$date->daylight_savings;
    is $date->tzabbr, 'EET';
    
    subtest 'limit formats' => sub {
        ok !date("2013-03-05 23:45:56", undef, INPUT_FORMAT_ALL)->error;
        ok !date("2013-03-05 23:45:56", undef, INPUT_FORMAT_ISO)->error;
        ok !date("2013-03-05 23:45:56", undef, INPUT_FORMAT_ISO | INPUT_FORMAT_ISO8601)->error;
        ok date("2013-03-05 23:45:56", undef, INPUT_FORMAT_ISO8601)->error;
        ok !date("2013-03-05", undef, INPUT_FORMAT_ISO8601)->error;
        ok !date("2013-03-05", undef, INPUT_FORMAT_ISO)->error;
    };
};

done_testing();
