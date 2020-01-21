use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

subtest 'from data' => sub {
    foreach my $file (map {"local$_"} 1,2,3,4,5,6,7) {
        my $data = get_dates($file);
        while (my ($zone, $list) = each %$data) {
            tzset($zone);
            foreach my $row (@$list) {
                my $result = join(',', &localtime($row->[0]));
                is($result, join(',', @{$row->[1]}), "localtime($zone): ".$row->[0]);
            }
        }
    }
};

tzset('Europe/Moscow');

subtest 'scalar context' => sub {
    like(scalar &localtime(1387727619), qr/^\S+ \S+ 22 19:53:39 2013$/);
};

subtest64 'past' => sub {
    is_deeply([&localtime(-2940149821)], [16, 13, 14, 30, 9, 1876, 1, 303, 0]);
};

subtest 'past before first transition' => sub {
    is_deeply([&localtime(-1688265018)], [59, 59, 23, 2, 6, 1916, 0, 183, 0]);
};

subtest 'first transition' => sub {
    is_deeply([&localtime(-1688265017)], [2, 1, 0, 3, 6, 1916, 1, 184, 0]);
    is_deeply([&localtime(-1688265016)], [3, 1, 0, 3, 6, 1916, 1, 184, 0]);
};

subtest 'transition jump forward' => sub {
    is_deeply([&localtime(1206831599)], [59, 59, 1, 30, 2, 2008, 0, 89, 0]);
    is_deeply([&localtime(1206831600)], [0, 0, 3, 30, 2, 2008, 0, 89, 1]);
};

subtest 'non-standart jump forward (DST + change zone, 2hrs)' => sub {
    is_deeply([&localtime(-1627965080)], [59, 59, 21, 31, 4, 1918, 5, 150, 0]);
    is_deeply([&localtime(-1627965079)], [0, 0, 0, 1, 5, 1918, 6, 151, 1]);
};

subtest 'transition jump backward' => sub {
    is_deeply([&localtime(1193525999)], [59, 59, 2, 28, 9, 2007, 0, 300, 1]);
    is_deeply([&localtime(1193526000)], [0, 0, 2, 28, 9, 2007, 0, 300, 0]);
    is_deeply([&localtime(1193529599)], [59, 59, 2, 28, 9, 2007, 0, 300, 0]);
    is_deeply([&localtime(1193529600)], [0, 0, 3, 28, 9, 2007, 0, 300, 0]);
};

subtest 'future static rules' => sub {
    is_deeply([&localtime(1401180400)], [40, 46, 12, 27, 4, 2014, 2, 146, 0]);
};

subtest64 'future dynamic rules for northern hemisphere' => sub {
    tzset('America/New_York');
    subtest 'jump forward' => sub {
        is_deeply([&localtime(3635132399)], [59, 59, 1, 11, 2, 2085, 0, 69, 0]);
        is_deeply([&localtime(3635132400)], [0, 0, 3, 11, 2, 2085, 0, 69, 1]);
    };
    subtest 'jump backward' => sub {
        is_deeply([&localtime(3655691999)], [59, 59, 1, 4, 10, 2085, 0, 307, 1]);
        is_deeply([&localtime(3655692000)], [0, 0, 1, 4, 10, 2085, 0, 307, 0]);
        is_deeply([&localtime(3655695599)], [59, 59, 1, 4, 10, 2085, 0, 307, 0]);
        is_deeply([&localtime(3655695600)], [0, 0, 2, 4, 10, 2085, 0, 307, 0]);
    };
};

subtest64 'future dynamic rules for southern hemisphere' => sub {
    tzset('Australia/Melbourne');
    subtest 'jump backward' => sub {
        is_deeply([&localtime(2563977599)], [59, 59, 2, 2, 3, 2051, 0, 91, 1]);
        is_deeply([&localtime(2563977600)], [0, 0, 2, 2, 3, 2051, 0, 91, 0]);
        is_deeply([&localtime(2563981199)], [59, 59, 2, 2, 3, 2051, 0, 91, 0]);
        is_deeply([&localtime(2563981200)], [0, 0, 3, 2, 3, 2051, 0, 91, 0]);
    };
    subtest 'jump forward' => sub {
        is_deeply([&localtime(2579702399)], [59, 59, 1, 1, 9, 2051, 0, 273, 0]);
        is_deeply([&localtime(2579702400)], [0, 0, 3, 1, 9, 2051, 0, 273, 1]);
    };
};
    
subtest 'virtual zones' => sub {
    tzset('GMT-9');
    is(Date::tzname(), 'GMT-9');
    is_deeply([&localtime(1389860280)], [0, 18, 17, 16, 0, 2014, 4, 15, 0]);
    tzset('GMT9');
    is_deeply([&localtime(1389925080)], [0, 18, 17, 16, 0, 2014, 4, 15, 0]);
    tzset('GMT+9');
    is_deeply([&localtime(1389925080)], [0, 18, 17, 16, 0, 2014, 4, 15, 0]);
};

done_testing();
