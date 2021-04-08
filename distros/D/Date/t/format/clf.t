use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

catch_run("[format-clf]");

tzset('Europe/Moscow');

subtest 'parse' => sub {
    subtest 'comman log format' => sub {
        subtest 'with brackets' => sub {
            my $d = date("[10/Oct/1999:21:15:05 +0500]");
            ok(!$d->error) or diag $d->error;
            is $d->epoch, 939572105;
        };

        subtest 'without brackets' => sub {
            my $d = date("10/Oct/1999:21:15:05 +0500");
            ok(!$d->error) or diag $d->error;
            is $d->epoch, 939572105;
        };
    };
};

subtest 'stringify' => sub {
    is date_ymd(1999, 10, 10, 21, 15, 5, 0, "GMT-5:00")->to_string(Date::FORMAT_CLF), "10/Oct/1999:21:15:05 +0500";
    is date_ymd(1999, 10, 10, 21, 15, 5, 0, "GMT-5:00")->to_string(Date::FORMAT_CLF_BRACKETS), "[10/Oct/1999:21:15:05 +0500]";
};

done_testing();
