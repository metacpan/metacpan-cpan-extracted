use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

catch_run("[relative-basic]");

subtest 'ctor' => sub {
    subtest 'empty' => sub {
        my $rel = new Date::Rel;
        is($rel->sec, 0);
        is($rel->min, 0);
        is($rel->hour, 0);
        is($rel->day, 0);
        is($rel->month, 0);
        is($rel->year, 0);
        is($rel, "");
    };
    
    subtest 'from seconds' => sub {
        foreach my $param (1000, "1000") {
            my $rel = Date::Rel->new($param);
            is($rel->sec, 1000);
            is($rel->min, 0);
            is($rel->hour, 0);
            is($rel->day, 0);
            is($rel->month, 0);
            is($rel->year, 0);
            is($rel, "1000s");
            is($rel, $rel->to_string);
        };
    };
    
    subtest 'from array ref' => sub {
        my $rel = Date::Rel->new_ymd(1,2,3,4,5,6);
        is($rel->sec, 6);
        is($rel->min, 5);
        is($rel->hour, 4);
        is($rel->day, 3);
        is($rel->month, 2);
        is($rel->year, 1);
        is($rel, "1Y 2M 3D 4h 5m 6s");
    };
    
    subtest 'copy ctor' => sub {
        my $rel = Date::Rel->new_ymd(1,2,3,4,5,6);
        $rel = Date::Rel->new($rel);
        is($rel, "1Y 2M 3D 4h 5m 6s");
    };
    
    subtest 'from hash ref' => sub {
        my $rel = Date::Rel->new_ymd(year => 6, month => 5, day => 4, hour => 3, min => 2, sec => 1);
        is($rel->sec, 1);
        is($rel->min, 2);
        is($rel->hour, 3);
        is($rel->day, 4);
        is($rel->month, 5);
        is($rel->year, 6);
        is($rel, "6Y 5M 4D 3h 2m 1s");
    };

    subtest 'from date pair' => sub {
        my $rel = rdate("2012-03-02 15:47:32", "2013-04-03 16:48:33");
        is $rel->to_string, "1Y 1M 1D 1h 1m 1s";
        is $rel->duration, 34304461;
        isnt $rel->duration, rdate($rel->to_string)->duration;
        is $rel->from, "2012-03-02 15:47:32";
        is $rel->till, "2013-04-03 16:48:33";
        
        $rel = rdate("2013-04-03 16:48:33", "2012-03-02 15:47:32");
        is $rel->to_string, "-1Y -1M -1D -1h -1m -1s";
        is $rel->duration, -34304461;
        is $rel->from, "2013-04-03 16:48:33";
        is $rel->till, "2012-03-02 15:47:32";
        isnt $rel->duration, rdate($rel->to_string)->duration;
    };

    subtest 'rdate' => sub {
        is(Date::Rel->new(1000), rdate(1000));
    };
};


subtest 'set' => sub {
    subtest 'secs' => sub {
        my $rel = rdate();
        $rel->set(1000);
        is $rel, "1000s";
        $rel->set("1000");
        is $rel, "1000s";
    };
    subtest 'string' => sub {
        my $rel = rdate();
        $rel->set("1Y 2M 3D 4h 5m 6s");
        is $rel, "1Y 2M 3D 4h 5m 6s";
    };
    subtest 'list' => sub {
        my $rel = rdate();
        $rel->set_ymd(1,2,3,4,5,6);
        is $rel, "1Y 2M 3D 4h 5m 6s";
    };
    subtest 'hash list' => sub {
        my $rel = rdate();
        $rel->set_ymd(year => 1, month => 2, day => 3, hour => 4, min => 5, sec => 6);
        is $rel, "1Y 2M 3D 4h 5m 6s";
    };
};

subtest 'duration' => sub {
    subtest 'without date' => sub {
        my $rel = Date::Rel->new_ymd(1,2,3,4,5,6);
        is $rel->to_secs, 37090322;
        ok $rel->to_secs == $rel->duration && int($rel) == $rel->to_secs;
        cmp_ok abs($rel->to_mins   - 618172.033333), '<', 0.000001;
        cmp_ok abs($rel->to_hours  - 10302.867222), '<', 0.000001;
        cmp_ok abs($rel->to_days   - 429.286134), '<', 0.000001;
        cmp_ok abs($rel->to_months - 14.104156), '<', 0.000001;
        cmp_ok abs($rel->to_years  - 1.175346), '<', 0.000001;
        is $rel->to_string, "1Y 2M 3D 4h 5m 6s";
    };
    subtest 'with date' => sub {
        my $rel = rdate(1000000000, 1100000000);
        is $rel->duration, 100000000;
        is $rel->to_secs, $rel->duration;
        cmp_ok abs($rel->to_mins   - 1666666.666666), '<', 0.000001;
        cmp_ok abs($rel->to_hours  - 27777.777777), '<', 0.000001;
        cmp_ok abs($rel->to_days   - 1157.36574), '<', 0.000001;
        cmp_ok abs($rel->to_months - 38.012191), '<', 0.000001;
        cmp_ok abs($rel->to_years  - 3.167682), '<', 0.000001;
        is $rel->to_string, "3Y 2M 8h 46m 40s";
    };    
};

subtest 'includes' => sub {
    my $rel = rdate("2004-09-10", "2004-11-10");
    is $rel->includes(date("2004-09-01")), 1;
    is $rel->includes("2004-09-10"), 0;
    is $rel->includes("2004-10-01"), 0;
    is $rel->includes("2004-11-10"), 0;
    is $rel->includes(1101848400), -1;
    is rdate(100)->includes(123456), 0;
};

subtest 'constants' => sub {
    is(SEC, "1s");
    is(MIN, "1m");
    is(HOUR, "1h");
    is(DAY, '1D');
    is(WEEK, '7D');
    is(MONTH, '1M');
    is(YEAR, '1Y');

    my $rotest = rdate_const("1Y 1M 1D");
    foreach my $const (SEC, MIN, HOUR, DAY, WEEK, MONTH, YEAR, $rotest) {
        my $initial_str = $const->to_string;
        ok(!eval { $const *= 10; 1 }, 'RO-MULS');
        ok(!eval { $const /= 2; 1 }, 'RO-DIVS');
        ok(!eval { $const += '5D'; 1 }, 'RO-ADDS');
        ok(!eval { $const -= '1M'; 1 }, 'RO-MINS');
        ok(!eval { $const->negate; 1 }, 'RO-NEG');
        ok(!eval { $const->sec(0); 1 }, 'RO-SEC');
        ok(!eval { $const->min(0); 1 }, 'RO-MIN');
        ok(!eval { $const->hour(0); 1 }, 'RO-HOUR');
        ok(!eval { $const->day(0); 1 }, 'RO-DAY');
        ok(!eval { $const->month(0); 1 }, 'RO-MON');
        ok(!eval { $const->year(0); 1 }, 'RO-YEAR');
        ok(!eval { $const->set(1024); 1 }, 'RO-SETNUM');
        ok(!eval { $const->set("3h 4m 5s"); 1 }, 'RO-SETSTR');
        ok(!eval { $const->set([1,2,3,4,5,6]); 1 }, 'RO-SETARR');
        ok(!eval { $const->set({year => 1000}); 1 }, 'RO-SETHASH');
        is($const->to_string, $initial_str, 'RO-cmp');
    }
};

done_testing();
