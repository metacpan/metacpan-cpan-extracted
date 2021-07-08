use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

catch_run("[format-iso8601");

tzset('Europe/Moscow');

subtest 'parse' => sub {
    subtest 'YYYY-MM-DDTHH:MM:SS+hh:mm' => sub {
        my $a = date("2017-08-28T13:49:35+01:00");
        ok(!$a->error);
        cmp_deeply([$a->year, $a->month, $a->day, $a->hour, $a->minute, $a->second], [2017, 8, 28, 13, 49, 35]);
        is($a->epoch, 1503924575);
        is($a->tzabbr, "+01:00");
    };
    
    subtest 'YYYY-MM-DD' => sub {
        my $a = date("2017-02-01");
        ok(!$a->error);
        is_deeply [$a->year, $a->month, $a->day, $a->hour, $a->minute, $a->second], [2017, 2, 1, 0, 0, 0];
        
        $a = date("2017-14-99");
        ok(!$a->error);
    };
    
    subtest 'YYYYMMDDTHHMMSS+hhmm' => sub {
        my $d = date("20170828T134935+0100");
        is($d->epoch, 1503924575);
        is($d->tzabbr, "+01:00");
    };
    
    subtest 'YYYY-MM-DDTHH:MM:SSZ' => sub {
        my $d = date("2017-08-28T13:49:35Z");
        ok(!$d->error);
        cmp_deeply([$d->year, $d->month, $d->day, $d->hour, $d->minute, $d->second], [2017, 8, 28, 13, 49, 35]);
        is($d->epoch, 1503928175);
        is($d->tzabbr, "GMT");
    };
    
    subtest 'YYYY-MM' => sub {
        my $d = date("2017-02");
        ok(!$d->error);
        cmp_deeply([$d->year, $d->month], [2017, 2]);
        is($d->tzabbr, "MSK");
    };
    
    subtest 'YYYY-MM-DDTHH:MM:SS' => sub {
        my $d = date("2017-01-02T03:04:05");
        ok(!$d->error);
        cmp_deeply([$d->year, $d->month, $d->day, $d->hour, $d->minute, $d->second], [2017, 1, 2, 3, 4, 5]);
        is($d->epoch, 1483315445);
    };
    
    subtest 'YYYYMMDDTHHMMSSZ' => sub {
        my $d = date("20170828T134935Z");
        ok(!$d->error);
        cmp_deeply([$d->year, $d->month, $d->day, $d->hour, $d->minute, $d->second], [2017, 8, 28, 13, 49, 35]);
        is($d->epoch, 1503928175);
    };
    
    subtest 'YYYY-Wnn' => sub {
        my $d = date("2017-W06");
        ok(!$d->error);
        cmp_deeply([$d->year, $d->month, $d->day], [2017, 2, 6]);
        
        $d = date("2014-W06");
        ok(!$d->error);
        cmp_deeply([$d->year, $d->month, $d->day], [2014, 2, 3]);
        
        $d = date("2017-W01");
        ok(!$d->error);
        cmp_deeply([$d->year, $d->month, $d->day], [2017, 1, 2]);
        
        $d = date("2014-W01");
        cmp_deeply([$d->year, $d->month, $d->day], [2013, 12, 29]);
    };
    
    subtest 'YYYY-Wnn-n' => sub {
        my $d = date("2017-W35-3");
        ok(!$d->error);
        cmp_deeply([$d->year, $d->month, $d->day], [2017, 8, 30]);
    
        $d = date("2014-W45-5");
        ok(!$d->error);
        cmp_deeply([$d->year, $d->month, $d->day], [2014, 11, 7]);
    
        $d = date("2017-W01-5");
        ok(!$d->error);
        cmp_deeply([$d->year, $d->month, $d->day], [2017, 1, 6]);
    
        $d = date("2014-W01-2");
        cmp_deeply([$d->year, $d->month, $d->day], [2013, 12, 30]);
    };
    
    subtest 'loyality for wrong delimiters in offset' => sub {
        subtest 'no delimiter in non-void variant' => sub {
            my $d = date("2017-08-28T13:49:35+0100");
            is($d->epoch, 1503924575);
            is($d->tzabbr, "+01:00");
        };
        subtest 'delimiter in void variant' => sub {
            my $d = date("20170828T134935+01:00");
            is($d->epoch, 1503924575);
            is($d->tzabbr, "+01:00");
        };
    };
};

subtest 'stringify' => sub {
    my $d = date_ymd(2017, 8, 28, 13, 49, 35, 123456);
    subtest 'FORMAT_ISO8601' => sub {
        is $d->to_string(Date::FORMAT_ISO8601), "2017-08-28T13:49:35.123456+03";
    };
    subtest 'FORMAT_ISO8601_NOTZ' => sub {
        is $d->to_string(Date::FORMAT_ISO8601_NOTZ), "2017-08-28T13:49:35.123456";
    };
};

done_testing();
