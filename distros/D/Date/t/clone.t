use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

subtest 'clone()' => sub {
    my $date = Date::date('2014-01-01 00:00:00');
    ok($date->tzlocal);
    is($date->tzname, tzget()->name);

    my $date2 = $date->clone;
    is($date2, $date);
    ok($date2->tzlocal);
    is($date2->tzname, tzget()->name);

    $date2 = $date->clone(undef, 'Australia/Melbourne');
    isnt($date2->epoch, $date->epoch);
    is($date2.'', $date.'');
    ok(!$date2->tzlocal);
    is($date2->tzname, 'Australia/Melbourne');

    my $date3 = $date2->clone([-1, -1, -1, 1, 2, 3]);
    is($date3, "2014-01-01 01:02:03");
    is($date3->tzname, $date2->tzname);

    $date3 = $date3->clone({year => 2013, day => 10});
    is($date3, "2013-01-10 01:02:03");
    is($date3->tzname, $date2->tzname);

    $date3 = $date3->clone({month => 2}, "");
    is($date3, "2013-02-10 01:02:03");
    isnt($date3->tzname, $date2->tzname);
    ok($date3->tzlocal);
    is($date3->tzname, tzget()->name);

    $date2 = $date->clone({year => 1700, tz => 'Europe/Kiev'});
    is($date2, "1700-01-01");
    ok(!$date2->tzlocal);
    is($date2->tzname, 'Europe/Kiev');
};

subtest 'newfrom (change zones)' => sub {
    my $date = Date::date('2014-01-01 00:00:00', "America/New_York");
    my $date2 = Date::date($date); # must not change timezone
    is($date2->epoch, $date->epoch);
    is("$date2", "$date");
    is($date2->tzname, $date->tzname);
    $date2 = Date::date($date, "Australia/Melbourne"); # change timezone preserving YMDHMS (epoch must change)
    ok($date2->epoch < $date->epoch);
    is("$date2", "$date");
    is($date2->tzname, "Australia/Melbourne");
    $date2 = Date::date($date, undef); # change timezone to local preserving YMDHMS
    ok($date2->tzlocal());
    is("$date2", "$date");
};

done_testing();
