use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;
use Storable qw/freeze nfreeze dclone thaw/;

tzset("Europe/Moscow");

subtest 'date' => sub {
    my $date = date("2012-01-01 15:16:17");
    my $dts = $date->epoch;
    subtest 'local tz' => sub {
        my $date_cloned = thaw(freeze $date);
        is($date_cloned->to_string, "2012-01-01 15:16:17");
        ok($date_cloned->tz->is_local);
    };
    subtest 'custom tz' => sub {
        my $date_cloned = thaw(nfreeze $date->clone(tz => "Europe/Kiev"));
        is($date_cloned->to_string, "2012-01-01 15:16:17");
        is($date_cloned->tzname, 'Europe/Kiev');
        is($date_cloned->tzabbr, 'EET');
        is($date_cloned->timezone->name, 'Europe/Kiev');
        ok(!$date_cloned->tzlocal);
    };
    subtest 'dclone' => sub {
        my $date_cloned = dclone $date->clone(tz => "Europe/Moscow");
        is($date_cloned->to_string, "2012-01-01 15:16:17");
        is($date_cloned->zone->name, 'Europe/Moscow');
        ok($date_cloned->tz->is_local);
    };
    subtest 'change local zone while serialized' => sub {
        my $frozen = freeze $date;
        tzset('Europe/Kiev');
        my $date_cloned = thaw($frozen);
        is($date_cloned->epoch, $dts);
        isnt($date_cloned.'', $date.'');
        ok($date_cloned->tzlocal);
        is($date_cloned->tzname, 'Europe/Kiev');
        tzset('Europe/Moscow');
    };
};

subtest 'relative' => sub {
    subtest 'without date' => sub {
        my $rdate_cloned = thaw(freeze rdate("1Y 1M"));
        is($rdate_cloned->to_string, "1Y 1M");
        $rdate_cloned = thaw(nfreeze rdate("1Y 1M"));
        is($rdate_cloned->to_string, "1Y 1M");
        $rdate_cloned = dclone rdate("1Y 1M");
        is($rdate_cloned->to_string, "1Y 1M");
    };
    subtest 'with date' => sub {
        my $rdate = rdate("2012-01-01 15:16:17", "2013-01-01 15:16:17");
        my $rdate_cloned = thaw(freeze $rdate);
        is $rdate_cloned->to_string(Date::Rel::FORMAT_ISO8601I), "2012-01-01T15:16:17+04/P1Y";
    };
};

subtest 'regressions' => sub {
    subtest 'bug with dclone+newfrom' => sub {
        my $time = time();
        my $date = date($time);
        my $date_cloned = dclone($date);
        is(date($date_cloned)->epoch, $time);
    };
};

done_testing();
