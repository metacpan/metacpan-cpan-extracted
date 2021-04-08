use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

catch_run('[time-gmtime]');

subtest 'list context' => sub {
    is_deeply([&gmtime(1606860695)], [35, 11, 22, 1, 11, 2020, 2, 335, 0]);
};

subtest 'scalar context' => sub {
    like(scalar Date::gmtime(1387727619), qr/^\S+ \S+ 22 15:53:39 2013$/);
};

done_testing();
