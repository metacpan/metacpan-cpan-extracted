use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;
use Cwd;

catch_run("[time-tz]");

subtest 'available timezones' => sub {
    my @zones = Date::available_timezones();
    my $cnt = @zones;
    is($cnt, 1212);
};

subtest 'tzget' => sub {
    my $lzname = Date::tzname();
    my $zone = tzget();
    ok($zone);
    ok($zone->is_local);
    is($zone->name, $lzname);
    is(ref($zone->export->{transitions}), 'ARRAY');
    
    $zone = tzget("Europe/Moscow");
    is($zone->name, "Europe/Moscow");
    is(ref($zone->export->{transitions}), 'ARRAY');
};

subtest 'tzset' => sub {
    tzset('Europe/Moscow');
    is(Date::tzname(), 'Europe/Moscow');

    my $zone = tzget('America/New_York');
    tzset($zone);
    is(Date::tzname(), 'America/New_York');
    
    if ($^O ne 'MSWin32') {
        $ENV{TZ} = 'Europe/Moscow';
        tzset();
        is(Date::tzname(), 'Europe/Moscow');
    
        delete $ENV{TZ};
        tzset();
        ok(Date::tzname());
    }
};

done_testing();
