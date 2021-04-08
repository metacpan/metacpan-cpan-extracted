use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

catch_run('[time-strftime]');

subtest 'with list' => sub {
    is Date::strftime("%Y-%m-%d %T", 10, 15, 1, 2, 11, 2020), "2020-12-02 01:15:10";
};

subtest 'with epoch' => sub {
    is Date::strftime("%Y-%m-%d %T", 1606861018), "2020-12-02 01:16:58";
};

subtest 'custom timezone' => sub {
    foreach my $zone ("GMT", tzget("GMT")) {
        is Date::strftime("%s", 0, 0, 3, 1, 0, 1970), "0";
        is Date::strftime("%s", 0, 0, 3, 1, 0, 1970, -1, $zone), "10800";
        is Date::strftime("%T", 61), "03:01:01";
        is Date::strftime("%T", 61, $zone), "00:01:01";
    }
};

done_testing();
