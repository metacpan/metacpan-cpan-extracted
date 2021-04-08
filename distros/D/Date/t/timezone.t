use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

catch_run("[timezone]");

my ($date, $date2, $date3);

subtest 'local' => sub {
    foreach my $date (date('2014-01-01 00:00:00'), date('2014-01-01 00:00:00', undef), date('2014-01-01 00:00:00', '')) {
        ok $date->tz->is_local;
        ok $date->zone->is_local;
        ok $date->timezone->is_local;
        ok $date->tzlocal;
        is $date->tzname, tzget()->name;
    }
};

subtest 'with zone' => sub {
    foreach my $zone ('America/New_York', tzget('America/New_York')) {
        my $date = date('2014-01-01 00:00:00', $zone);
        say $date->epoch;
        ok !$date->tzlocal;
        is $date->tzname, 'America/New_York';
        is $date->zone->name, $date->tzname;
        my $b = date('2014-01-01 00:00:00');
        say $b->epoch;
        cmp_ok $date->epoch, '>', $b->epoch;
        cmp_ok $date, '>', $b;
        isnt $date, $b;
        is $date->to_string, $b->to_string;
    }
};

subtest 'clone with tz' => sub {
    my $src = date('2014-01-01 00:00:00', 'America/New_York');
    subtest 'with local' => sub {
        foreach my $zone (undef, "") {
            my $date = $src->clone(tz => $zone);
            ok $date->tzlocal;
            is $date->tzname, tzget()->name;
            cmp_ok $date, '==', date('2014-01-01 00:00:00');
            cmp_ok $date, '!=', $src;
            is $date, date('2014-01-01 00:00:00');
            is $date->to_string, '2014-01-01 00:00:00';
            isnt $date, $src;
        }
    };
    subtest 'with other' => sub {
        foreach my $zone ("Europe/Kiev", tzget("Europe/Kiev")) {
            my $date = $src->clone(tz => $zone);
            is $date->tzname, "Europe/Kiev";
            is $date->to_string(Date::FORMAT_ISO8601), '2014-01-01T00:00:00+02';
        }
    };
};

subtest 'to_timezone' => sub {
    subtest 'local' => sub {
        my $src  = date('2014-01-01 00:00:00', 'America/New_York');
        my $date = $src->clone;
        $date->to_timezone("");
        ok $date->tzlocal;
        is $date->epoch, $src->epoch;
    };
    subtest 'other' => sub {
        for my $zone ('Australia/Melbourne', tzget('Australia/Melbourne')) {
            my $src  = date('2014-01-01 00:00:00', 'America/New_York');
            my $date = $src->clone;
            $date->to_timezone($zone);
            is $date->epoch, $src->epoch;
            isnt $date->to_string, $src->to_string;
        }
    };
};

subtest 'tz()' => sub {
    for my $zone ('Australia/Melbourne', tzget('Australia/Melbourne')) {
        my $src  = date('2014-01-01 00:00:00', 'America/New_York');
        my $date = $src->clone;
        $date->tz($zone);
        isnt $date->epoch, $src->epoch;
        is $date->to_string, $src->to_string;
    }
};

done_testing();
