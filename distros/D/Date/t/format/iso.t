use 5.012;
use warnings;
use Date;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

catch_run("[format-iso]");

tzset('Europe/Moscow');

sub is_approx ($$;$) {
    my ($testv, $v, $name) = @_;
    if ($testv > $v) {
        cmp_ok $testv, '<', $v + 0.000001, $name;
    } else {
        cmp_ok $testv, '>', $v - 0.000001, $name;
    }
}

sub test ($$$$) {
    my ($oname, $ostr, $epoch, $tzabbr) = @_;
    for my $delim ('-', '/') {
        my $name = $oname;
        my $str  = $ostr;
        for ($name, $str) {
            s/-/$delim/ for 1..2;
        }
        subtest $name => sub {
            my $d = date($str);
            is_approx $d->epoch, $epoch, "$str: epoch";
            is $d->tzabbr, $tzabbr, "$str: tzabbr";
        };
    }
}

subtest 'parse' => sub {
    # all tests for YYYY/MM/DD as well
    test 'YYYY-MM-DD',                  '2019-01-01',                   1546290000,         'MSK';
    test 'YYYY-MM-DD HH:MM',            '2019-02-03 04:05',             1549155900,         'MSK';
    test 'YYYY-MM-DD HH:MM:SS',         '2019-02-03 04:05:06',          1549155906,         'MSK';
    test 'YYYY-MM-DD HH:MM:SS.s',       '2019-02-03 04:05:06.1',        1549155906.1,       'MSK';
    test 'YYYY-MM-DD HH:MM:SS.ss',      '2019-02-03 04:05:06.22',       1549155906.22,      'MSK';
    test 'YYYY-MM-DD HH:MM:SS.sss',     '2019-02-03 04:05:06.333',      1549155906.333,     'MSK';
    test 'YYYY-MM-DD HH:MM:SS.ssss',    '2019-02-03 04:05:06.4444',     1549155906.4444,    'MSK';
    test 'YYYY-MM-DD HH:MM:SS.sssss',   '2019-02-03 04:05:06.55555',    1549155906.55555,   'MSK';
    test 'YYYY-MM-DD HH:MM:SS.ssssss',  '2019-02-03 04:05:06.666666',   1549155906.666666,  'MSK';
    test 'YYYY-MM-DD HH:MM:SS.s+hh',    '2019-02-03 04:05:06.1+01',     1549163106.1,       '+01:00';
    test 'YYYY-MM-DD HH:MM:SS.s-hh',    '2019-02-03 04:05:06.1-01',     1549170306.1,       '-01:00';
    test 'YYYY-MM-DD HH:MM:SS.s+hh:mm', '2019-02-03 04:05:06.1+01:30',  1549161306.1,       '+01:30';
    test 'YYYY-MM-DD HH:MM:SS.s-hh:mm', '2019-02-03 04:05:06.1-01:30',  1549172106.1,       '-01:30';
    test 'YYYY-MM-DD HH:MM:SS.sZ',      '2019-02-03 04:05:06.1Z',       1549166706.1,       'GMT';
    
    subtest 'bad' => sub {
        my $d = new Date("pizdets");
        my $ok = 0;
        $ok = 1 if $d;
        ok !$ok;
        ok !$d;
        is $d->error, Date::Error::parser_error;
        is int($d), 0;
        
        $d = date("2017-07-HELLO");
        ok $d->error;
        is $d->epoch, 0;
        is $d->to_string, undef;
    };
};

subtest 'stringify' => sub {
    my $dateh = date_ymd(2019, 12, 9, 20, 47, 30, 55);
    my $date  = date_ymd(2019, 12, 9, 20, 47, 30);
    
    subtest 'FORMAT_ISO' => sub {
        is $date->to_string(Date::FORMAT_ISO), "2019-12-09 20:47:30";
        is $dateh->to_string(Date::FORMAT_ISO), "2019-12-09 20:47:30.000055";
        is $date->to_string, $date->to_string(Date::FORMAT_ISO), 'this is the default format';
    };
    
    subtest 'FORMAT_ISO_DATE' => sub {
        is $date->to_string(Date::FORMAT_ISO_DATE), "2019-12-09";
    };
    
    subtest 'FORMAT_ISO_TZ' => sub {
        is $date->to_string(Date::FORMAT_ISO_TZ), "2019-12-09 20:47:30+03";
        is $dateh->to_string(Date::FORMAT_ISO_TZ), "2019-12-09 20:47:30.000055+03";
        
        my $date = date_ymd(2019, 12, 9, 20, 47, 30, 0, "GMT+5:30");
        is $date->to_string(Date::FORMAT_ISO_TZ), "2019-12-09 20:47:30-05:30";
    };
    
    subtest 'FORMAT_YMD' => sub {
        is $date->to_string(Date::FORMAT_YMD), '2019/12/09';
    };
    
    subtest 'FORMAT_HMS' => sub {
        is $dateh->to_string(Date::FORMAT_HMS), '20:47:30';
    };
};

done_testing();
