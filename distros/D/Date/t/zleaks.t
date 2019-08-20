use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;
use Storable qw/freeze thaw nfreeze dclone/;

plan skip_all => 'set TEST_FULL=1 to enable leaks test' unless $ENV{TEST_FULL};
plan skip_all => 'BSD::Resource required to test for leaks' unless eval { require BSD::Resource; 1 };

my $measure = 200;
my $leak = 0;
my $i = 0;

while (++$i < 10000) {
    tzset('Europe/Moscow');
    tzget('America/New_York');
    #Panda::Time::dump_zones();

    my ($date, $rel, $idate, $ret, @ret, %ret, $scalar);
    $date = new Date(0, 'Europe/Moscow');
    $ret = $date->string.$date->epoch;
    $date = new Date(1000000000, 'Europe/Kiev');
    $ret = $date->string.$date->epoch;
    $date = new Date([2012,02,20,15,16,17], 'America/New_York');
    $ret = $date->string.$date->epoch;
    $date = new Date({year => 2013, month => 06, day => 28, hour => 6, min => 6, sec => 6}, 'Australia/Melbourne');
    $ret = $date->string.$date->epoch;
    $date = new Date("2013-01-26 06:47:29");
    $ret = $date->string.$date->epoch;
    $date = new Date("2013-01-26 06:47:29.345341");
    $ret = $date->string.$date->epoch;
    $ret = $date->epoch;
    $ret = $date->year + $date->_year + $date->yr == 70;
    $ret = $date->month + $date->mon + $date->_month + $date->_mon;
    $ret = $date->day + $date->mday + $date->day_of_month;
    $ret = $date->hour + $date->min + $date->minute + $date->sec + $date->second;
    $ret = $date->to_string;
    $ret = $date->to_string . $date . $date->string . $date->as_string . $date->epoch;
    $ret = $date->to_number + int($date);
    $date = new Date([]);
    $ret = $date->string.$date->epoch;
    $date = new Date({});
    $ret = $date->string.$date->epoch;
    $date = new Date("2013");
    $ret = $date->string.$date->epoch;
    $date = Date->new("2013-03-05 23:45:56");
    $ret = $date->wday + $date->_wday + $date->day_of_week + $date->ewday;
    $ret = $date->yday + $date->day_of_year + $date->_yday;
    $ret = !$date->isdst && !$date->daylight_savings;
    $date = Date->new("2013-09-05 03:04:05");
    $ret = $date->hms . $date->ymd . $date->mdy . $date->dmy . $date->ampm . $date->meridiam;
    $date = Date->new("2013-09-05 23:04:05");
    $ret = $date->ampm . $date->meridiam . $date->gmtoff;
    $date = Date->new("2013-09-05 03:04:05");
    @ret = $date->array;
    $ret = $date->aref;
    @ret = $date->struct;
    $ret = $date->sref;
    %ret = $date->hash;
    $ret = $date->href;
    $ret = $date->month_begin_new;
    $ret = $date->month_end_new;
    $ret = $date->days_in_month;
    $ret = $date->month_begin;
    $ret = $date->month_end;
    $ret = Date::now();
    $ret = $date->string.$date->epoch;
    $ret = Date::today();
    $ret = $date->string.$date->epoch;
    $date = date(0);
    $ret = $date->string.$date->epoch;
    $date = date 1000000000;
    $ret = $date->string.$date->epoch;
    $date = date [2012,02,20,15,16,17];
    $ret = $date->string.$date->epoch;
    $date = date {year => 2013, month => 06, day => 28, hour => 6, min => 6, sec => 6};
    $ret = $date->string.$date->epoch;
    $date = date "2013-01-26 06:47:29.345341";
    $ret = $date->string.$date->epoch;
    $date = date "2013-01-26 06:47:29";
    $ret = $date->truncated;
    $ret = $ret->string.$ret->epoch;
    $ret = $date->truncate;
    $ret = int(date(123456789));
    $ret = $date->set(100);
    $ret = $date->set("2013-01-26 06:47:29.345341");
    $ret = $date->set([1,2,3]);
    $ret = $date->set({year => 1000});
    $ret = $date->clone();
    $ret = $date->clone([-1,1,-1,2,-3,3]);
    $ret = $date->clone({year => 1, month => 2, day => 3, hour => 4, min => 5, sec => 6});
    $ret = $date->clone({year => 1, month => 2, day => 3, hour => 4, min => 5, sec => 6}, 'Europe/Kiev');
    $ret = $date->clone(undef, 'Europe/Moscow');
    $ret = $date->clone(undef, undef);
    $date->tz('Australia/Melbourne');
    $date->to_timezone('Europe/Kiev');
    $ret = $date->tz;
    tzset('America/New_York');


    $date = Date->new("2013-03-05 02:040:6");
    eval{$date->strftime};
    $ret = $date->strftime("");
    $ret = $date->strftime('%Y') . $date->strftime('%Y/%m/%d') . $date->strftime('%H-%M-%S') . $date->strftime('%b %B');
    $ret = $date->monname . $date->monthname . $date->wdayname . $date->day_of_weekname;



    $date = Date->new("2013-03-05 02:04:06");
    $ret = $date->sql;
    $ret = Date::string_format;
    $ret = Date::string_format("%Y%m%d%H%M%S");
    $ret = Date::string_format;
    $ret = $date.'';
    $ret = Date::string_format("%Y/%m/%d");
    $ret = $date.'';
    $ret = Date::string_format(undef);
    $ret = $date.'';


    # OK
    $date = new Date("2010-01-01");
    my $ok;
    $ok = 1 if $date;
    $ret = $date->error;
    $ret = $date->errstr;

    # UNPARSABLE
    $date = new Date("pizdec");
    $ok = 0;
    $ok = 1 if $date;
    $ret = $date->error;
    $ret = $date->errstr;
    $ret = int($date);


    $ret = Date::string_format("%Y-%m-%d");
    $ret = Date::range_check;
    $ret = Date->new("2001-02-31").'';
    $ret = Date::range_check(1);
    $ret = Date::range_check;
    $date = Date->new("2001-02-31");
    $ret = 1 if $date;
    $ret = $date->string;
    $ret = $date->error;
    $ret = $date->errstr;

    Date::string_format(undef);
    Date::range_check(undef);



    $rel = new Date::Rel;
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = 1 if $rel;
    $ret = $rel.''.($rel eq "");

    $rel = new Date::Rel(1000);
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel.''.$rel->string.$rel->to_string.$rel->as_string;
    $ret = $rel->sec + $rel->secs + $rel->second + $rel->seconds;

    $rel = new Date::Rel("1000");
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->string;

    $rel = new Date::Rel [1,2,3,4,5,6];
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year + $rel->to_sec +
           $rel->to_number + int($rel) + $rel->to_min + $rel->to_hour + $rel->to_day + $rel->to_month +
           $rel->to_year + $rel->to_secs + $rel->to_seconds + $rel->to_second + $rel->to_mins + $rel->to_min +
           $rel->to_minutes + $rel->to_minute + $rel->to_hours + $rel->to_hour + $rel->to_days + $rel->to_day +
           $rel->to_months + $rel->to_month + $rel->to_mon + $rel->to_mons + $rel->to_year + $rel->to_years;
    $ret = $rel->string;

    $rel = new Date::Rel {year => 1, month => 2, day => 3, hour => 4, min => 5, sec => 6};
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->string;
    $rel = new Date::Rel "6s";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->string;
    $rel = new Date::Rel "5m";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->string;
    $rel = new Date::Rel "2h";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->string;
    $rel = new Date::Rel "1s 1m 1h";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->string;
    $rel = new Date::Rel "-9999M";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->string;
    $rel = new Date::Rel "12Y";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->string;
    $rel = new Date::Rel "1Y 2M 3D 4h 5m 6s";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->string;
    $rel = new Date::Rel "-1Y -2M -3D 4h 5m 6s";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->string;
    $rel = rdate "1Y 2M 3D 4h 5m 6s";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->string;

    $ret = rdate("2012-03-02 15:47:32", "2013-04-03 16:48:33")->string;
    $ret = rdate("2013-04-03 16:48:33", "2012-03-02 15:47:32")->string;
    $ret = rdate("2012-03-02 15:47:32", "2013-04-03 16:48:33") eq Date::Rel->new("2012-03-02 15:47:32", "2013-04-03 16:48:33");

    $rel->set(1000);
    $ret = $rel->string;
    $rel->set(0);
    $rel->set("1000");
    $rel->set(0);
    $rel->set("1Y 2M 3D 4h 5m 6s");
    $rel->set(0);
    $rel->set([1,2,3,4,5,6]);
    $rel->set(0);
    $rel->set({year => 1, month => 2, day => 3, hour => 4, min => 5, sec => 6});
    $rel->set(0);

    $ret = SEC eq "1s" && MIN eq "1m" && HOUR eq "1h" && DAY eq '1D' && MONTH eq '1M' && YEAR eq '1Y';



    $ret = MONTH + "1D";
    $ret = "1Y" + DAY;
    $ret = YEAR + HOUR;
    $ret = (MONTH + date("2012-01-01"))->string;
    $ret = (DAY + idate("2012-01-01", "2012-06-01"))->string;
    $rel = rdate("1Y 1M");
    $rel += "1M";
    $scalar = "23h";
    $scalar += $rel;
    $ret = $scalar->string;
    $rel += DAY;
    eval { $rel += date(123); 1; };
    eval { $rel += idate(123,123); 1; };
    $ret = MONTH - "1D";
    $ret = "1Y" - DAY;
    $ret = YEAR - HOUR;
    eval { my $a = MONTH - date("2012-01-01"); 1; };
    eval { my $a = DAY - idate(111,111); 1; };
    $rel = rdate("1Y 1M");
    $rel -= "1M";
    $scalar = "23h";
    $scalar -= $rel;
    $rel -= DAY;
    eval { $rel -= date(123); 1; };
    eval { $rel -= idate(123,123); 1; };
    $ret = MONTH*5;
    $ret = 100*DAY;
    eval {my $a = DAY*DAY;1};
    eval {my $a = DAY*date(0);1};
    eval {my $a = DAY*idate(0,0);1};
    $rel = rdate("100Y 2M");
    $rel *= 0.5;
    $scalar = 10;
    $scalar *= $rel;
    eval {$rel *= $rel; 1};
    eval {$rel *= date(0); 1};
    eval {$rel *= idate(0,0); 1};
    $ret = DAY/4;
    eval {my $a = 2/SEC; 1};
    eval {my $a = DAY*DAY; 1};
    eval {my $a = DAY*date(0); 1};
    eval {my $a = DAY*idate(0,0); 1};
    $rel = rdate("100Y 2M");
    $rel /= 0.5;
    $scalar = 10;
    eval {$scalar /= $rel; 1};
    eval {$rel /= $rel; 1};
    eval {$rel /= date(0); 1};
    eval {$rel /= idate(0,0); 1};
    $ret = -rdate("1Y 2M -3D -4h");
    $ret = rdate("1Y")->negate;
    $rel = rdate("1Y 1M");
    $ret = $rel > "1Y" && $rel < "1Y 1M 1s";
    $ret = "1Y" < $rel && "1Y 1M 1s" > $rel;
    $ret = $rel > $rel && $rel < $rel && $rel == $rel && $rel > rdate("1Y") && $rel != rdate("1Y 30M");
    eval {my $a = $rel < date(0); 1};
    eval {my $a = $rel == idate(0,0); 1};



    $idate = new Date::Int(0, 0);
    $ret = $idate->from->string . $idate->till->string;
    $ret = $idate->duration + $idate->sec + $idate->min + $idate->hour + $idate->day + $idate->month + $idate->year;

    $idate = idate(1000000000, 1100000000);
    $ret = $idate->from->string . $idate->till->string;
    $ret = $idate->to_string.$idate.$idate->string.$idate->as_string."$idate";
    $ret = $idate->duration + $idate->sec + $idate->min + $idate->hour + $idate->day + $idate->month + $idate->year;
    $ret = $idate->imin + $idate->imins + $idate->iminute + $idate->iminutes + $idate->min + $idate->mins +
           $idate->minute + $idate->minutes + $idate->ihour + $idate->ihours + $idate->hour + $idate->hours +
           $idate->iday + $idate->idays + $idate->day + $idate->days + $idate->imonth + $idate->imon +
           $idate->imons + $idate->imonths + $idate->month + $idate->months + $idate->mon + $idate->mons +
           $idate->iyear + $idate->iyears + $idate->year + $idate->years;
    $ret = $idate->relative->string;
    $ret = idate("2004-03-09 00:00:00", "2003-09-10")->relative->string;
    $ret = $idate->set("1985-01-02 01:02:03", "1990-02-29 23:23:23");


    $idate = idate("2012-02-01", "2013-02-01");
    $ret = $idate + "1D";
    $ret = "1Y" + $idate;
    $ret = $idate + 28*DAY;
    eval {my $a = $idate + date(0); 1};
    eval {my $a = $idate + $idate; 1};
    $idate = idate("2012-02-01", "2013-02-01");
    $idate += "1D";
    $ret = $idate eq ["2012-02-02", "2013-02-02"];
    $scalar = "1Y";
    $scalar += $idate;
    $ret = $scalar eq ["2013-02-02", "2014-02-02"];
    $idate += HOUR;
    eval { $idate += date(123); 1; };
    eval { $idate += idate(123,123); 1; };
    $idate = idate("2012-02-01", "2013-02-01");
    $ret = $idate - "1D";
    eval {my $a = "1Y" - $idate; 1};
    $ret = $idate - DAY;
    eval { my $a = $idate - date("2012-01-01"); 1; };
    eval { my $a = $idate - idate(111,111); 1; };
    $idate = idate("2012-02-01", "2013-02-01");
    $idate -= "1M";
    $scalar = "23h";
    eval { $scalar -= $idate; 1};
    $idate -= DAY;
    eval { $idate -= date(123); 1; };
    eval { $idate -= idate(123,123); 1; };
    $idate = idate("2012-02-01", "2013-02-01");
    $ret = (-$idate)->duration;
    $idate->negate;
    $ret = $idate->duration;
    $idate = idate("2012-02-01 00:00:00", "2012-02-01 00:00:01");
    $ret = $idate > ["2013-02-01 00:00:00", "2013-02-01 00:00:00"] && $idate < ["2013-02-01 00:00:00", "2013-02-01 00:00:02"];
    $ret = $idate == ["2013-02-01 00:00:00", "2013-02-01 00:00:01"] && $idate ne ["2013-02-01 00:00:00", "2013-02-01 00:00:01"];
    $ret = $idate eq ["2012-02-01 00:00:00", "2012-02-01 00:00:01"];
    $ret = $idate > 0 && $idate < 2 && $idate == 1;
    $ret = ["2013-02-01 00:00:00", "2013-02-01 00:00:00"] < $idate && ["2013-02-01 00:00:00", "2013-02-01 00:00:02"] > $idate;
    $ret = ["2013-02-01 00:00:00", "2013-02-01 00:00:01"] == $idate && ["2013-02-01 00:00:00", "2013-02-01 00:00:01"] ne $idate;
    $ret = ["2012-02-01 00:00:00", "2012-02-01 00:00:01"] eq $idate;
    $ret = 0 < $idate && 2 > $idate && 1 == $idate;
    eval {my $a = $idate > DAY; 1};
    eval {my $a = $idate < date(0); 1};
    $ret = $idate > idate("2013-02-01 00:00:00", "2013-02-01 00:00:00") && $idate < idate("2013-02-01 00:00:00", "2013-02-01 00:00:02");
    $ret = $idate == idate("2013-02-01 00:00:00", "2013-02-01 00:00:01") && $idate ne idate("2013-02-01 00:00:00", "2013-02-01 00:00:01");
    $ret = $idate eq idate("2012-02-01 00:00:00", "2012-02-01 00:00:01");

    $date = date("2012-03-02 15:47:32");
    $ret = $date + "1D";
    $ret = "1Y 1m" + $date;
    $ret = $date + HOUR;
    eval {my $a = $date + date(0); 1};
    eval {my $a = $date + idate(0,0); 1};
    $date = date("2012-03-02 15:47:32");
    $date += "1M";
    $ret = $date->string;
    $scalar = "23h";
    $scalar += $date;
    $date += YEAR;
    eval { $date += date(123); 1; };
    eval { $date += idate(123,123); 1; };
    $date = date("2012-03-02 15:47:32");
    $ret = $date - "1D";
    $ret = $date - "2011-04-03 16:48:33";
    $ret = "2013-04-03 16:48:33" - $date;
    $ret = $date - HOUR;
    $ret = date("2013-04-03 16:48:33") - $date;
    eval { my $a = $date - idate(111,111); 1; };
    $date = date("2012-03-02 15:47:32");
    $date -= "1M";
    $scalar = "2013-04-03 16:48:33";
    $scalar -= $date;
    $date -= DAY;
    eval { $date -= date(123); 1; };
    eval { $date -= idate(123,123); 1; };
    $date = date("2012-03-02 15:47:32");
    $ret = $date > "2012-03-02 15:47:31" && $date < "2012-03-02 15:47:33";
    $ret = $date > 1330688851 && $date < 1330688853 && $date == 1330688852 && $date eq 1330688852;
    $ret = "2012-03-02 15:47:31" < $date && "2012-03-02 15:47:33" > $date;
    $ret = 1330688851 < $date && 1330688853 > $date && 1330688852 == $date && 1330688852 eq $date;
    eval { my $a = $date > MONTH; 1};
    $ret = $date > date(0) && $date < date(2000000000);
    $ret = date(1330688851) < $date && date(1330688853) > $date && date(1330688852) == $date && date(1330688852) eq $date;
    eval {my $a = $date == idate(0,0); 1};

    $ret = Date::today_epoch();

    foreach my $obj (date(1000000000), date(1000000000, 'Europe/Kiev'), rdate("1Y 1M 1D 2h 3m 4s"), idate(date(1000000000), date(1000000000, 'Europe/Kiev'))) {
        $ret = freeze($obj);
        $ret = thaw($ret);
        $ret = thaw(nfreeze $obj);
        $ret = dclone($obj);
    }
}
continue {
    $measure = BSD::Resource::getrusage()->{"maxrss"} if $i == 1000;
}

$leak = BSD::Resource::getrusage()->{"maxrss"} - $measure;
my $leak_ok = $leak < 500;
warn("LEAK DETECTED: ${leak}Kb") unless $leak_ok;
ok($leak_ok);

done_testing();
