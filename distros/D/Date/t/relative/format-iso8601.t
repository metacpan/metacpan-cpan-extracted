use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

catch_run("[relative-format-iso8601]");

subtest 'iso8601 duration' => sub {
    my $fmt = Date::Rel::FORMAT_ISO8601D;
    
    subtest 's' => sub {
        my $rel = new Date::Rel "PT6S";
        is($rel->sec, 6);
        is($rel->to_secs, 6);
        cmp_ok(abs($rel->to_mins - 0.1), '<', 0.000001);
        is $rel->to_string($fmt), "PT6S";
    };
    
    subtest 'm' => sub {
        my $rel = new Date::Rel "PT5M";
        is($rel->min, 5);
        is($rel->to_secs, 300);
        is $rel->to_string($fmt), "PT5M";
    };
    
    subtest 'h' => sub {
        my $rel = new Date::Rel "PT2H";
        is($rel->hour, 2);
        is($rel->to_secs, 7200);
        is $rel->to_string($fmt), "PT2H";
    };
    
    subtest 'hms' => sub {
        my $rel = new Date::Rel "PT1H1M1S";
        is($rel->sec, 1);
        is($rel->min, 1);
        is($rel->hour, 1);
        is($rel->to_secs, 3661);
        is $rel->to_string($fmt), "PT1H1M1S";
    };
    
    subtest 'M' => sub {
        my $rel = new Date::Rel "P-9999M";
        is($rel->month, -9999);
        is $rel->to_string($fmt), "P-9999M";
    };
    
    subtest 'Y' => sub {
        my $rel = new Date::Rel "P12Y";
        is($rel->year, 12);
        is $rel->to_string($fmt), "P12Y";
    };
    
    subtest 'YMDhms' => sub {
        my $rel = new Date::Rel "P1Y2M3DT4H5M6S";
        is($rel->sec, 6);
        is($rel->min, 5);
        is($rel->hour, 4);
        is($rel->day, 3);
        is($rel->month, 2);
        is($rel->year, 1);
        is $rel->to_string($fmt), "P1Y2M3DT4H5M6S";
    };
    
    subtest 'negative YMDhms' => sub {
        my $rel = new Date::Rel "P-1Y2M-3DT-4H-5M-6S";
        is($rel->sec, -6);
        is($rel->min, -5);
        is($rel->hour, -4);
        is($rel->day, -3);
        is($rel->month, 2);
        is($rel->year, -1);
        is $rel->to_string($fmt), "P-1Y2M-3DT-4H-5M-6S";
    };
    
    subtest 'does not depend on from date' => sub {
        my $rel = rdate(10);
        $rel->from(time);
        is $rel->to_string($fmt), "PT10S";
    };
};

subtest 'iso8601 interval' => sub {
    my $fmt = Date::Rel::FORMAT_ISO8601I;

    subtest 'normal' => sub {
        my $rel = rdate("2019-12-31T23:59:59/PT10S");
        is $rel->to_string, "10s";
        is $rel->from, "2019-12-31 23:59:59";
        is $rel->to_string(Date::Rel::FORMAT_ISO8601D), "PT10S";
        is $rel->to_string($fmt), "2019-12-31T23:59:59+03/PT10S";
    };
    
    subtest 'fallbacks to duration format when no date' => sub {
        my $rel = rdate(10);
        is $rel->to_string($fmt), "PT10S";
    };
};

done_testing();
