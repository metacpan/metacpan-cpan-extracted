use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

catch_run("[format-dot]");

tzset('Europe/Moscow');

subtest 'parse' => sub {
    subtest 'DD.MM.YYYY' => sub {
        my $d = date("05.12.2019");
        ok !$d->error;
        is $d->epoch, 1575493200;
    };
    
    subtest 'bad' => sub {
        ok date("2019.12.05")->error;
        ok date("20.12.05")->error;
    };
};

subtest 'stringify' => sub {
    is date_ymd(2019, 12, 9, 1, 1, 1)->to_string(Date::FORMAT_DOT), "09.12.2019";
};

done_testing();
