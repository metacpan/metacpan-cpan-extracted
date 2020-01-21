use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

subtest 'via tzset()' => sub {
    tzset('Europe/Moscow');
    is(Date::tzname(), 'Europe/Moscow');

    my $zone = tzget('America/New_York');
    tzset($zone);
    is(Date::tzname(), 'America/New_York');
};

subtest 'via $ENV{TZ}' => sub {
    plan skip_all => "changes to %ENV is not visible to environment on Windows" if $^O eq 'MSWin32';
    $ENV{TZ} = 'Europe/Moscow';
    tzset();
    is(Date::tzname(), 'Europe/Moscow');
    
    $ENV{TZ} = 'America/New_York';
    tzset();
    is(Date::tzname(), 'America/New_York');

    delete $ENV{TZ};
    tzset();
    ok(Date::tzname());
};

done_testing();
