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

    my ($date, $rel, $ret, @ret, %ret, $scalar);
    $date = new Date(0, 'Europe/Moscow');
    $ret = $date->to_string.$date->epoch;
    $date = new Date(1000000000, 'Europe/Kiev');
    $ret = $date->to_string.$date->epoch;
    $date = Date->new_ymd(2012,02,20,15,16,17,0, 'America/New_York');
    $ret = $date->to_string.$date->epoch;
    $date = Date->new_ymd(year => 2013, month => 06, day => 28, hour => 6, min => 6, sec => 6, tz => 'Australia/Melbourne');
    $ret = $date->to_string.$date->epoch;
    $date = new Date("2013-01-26 06:47:29");
    $ret = $date->to_string.$date->epoch;
    $date = new Date("2013-01-26 06:47:29.345341");
    $ret = $date->to_string.$date->epoch;
    $ret = $date->epoch;
    $ret = $date->year + $date->_year + $date->yr == 70;
    $ret = $date->month + $date->mon + $date->_month + $date->_mon;
    $ret = $date->day + $date->mday + $date->day_of_month;
    $ret = $date->hour + $date->min + $date->minute + $date->sec + $date->second;
    $ret = $date->to_string;
    $ret = $date->to_string . $date . $date->epoch;
    $ret = $date->to_number + int($date);
    $date = new Date();
    $ret = $date->to_string.$date->epoch;
    $date = Date->new_ymd();
    $ret = $date->to_string.$date->epoch;
    $date = new Date("2013");
    $ret = $date->to_string.$date->epoch;
    $date = Date->new("2013-03-05 23:45:56");
    $ret = $date->wday + $date->_wday + $date->day_of_week + $date->ewday;
    $ret = $date->yday + $date->day_of_year + $date->_yday;
    $ret = !$date->isdst && !$date->daylight_savings;
    $date = Date->new("2013-09-05 03:04:05");
    $ret = $date->to_string(Date::FORMAT_HMS) . $date->to_string(Date::FORMAT_YMD);
    $date = Date->new("2013-09-05 23:04:05");
    $ret = $date->gmtoff;
    $date = Date->new("2013-09-05 03:04:05");
    @ret = $date->array;
    @ret = $date->struct;
    $ret = $date->month_begin_new;
    $ret = $date->month_end_new;
    $ret = $date->days_in_month;
    $ret = $date->month_begin;
    $ret = $date->month_end;
    $ret = Date::now();
    $ret = $date->to_string.$date->epoch;
    $ret = Date::today();
    $ret = $date->to_string.$date->epoch;
    $date = date(0);
    $ret = $date->to_string.$date->epoch;
    $date = date 1000000000;
    $ret = $date->to_string.$date->epoch;
    $date = date_ymd(2012,02,20,15,16,17);
    $ret = $date->to_string.$date->epoch;
    $date = date_ymd(year => 2013, month => 06, day => 28, hour => 6, min => 6, sec => 6);
    $ret = $date->to_string.$date->epoch;
    $date = date "2013-01-26 06:47:29.345341";
    $ret = $date->to_string.$date->epoch;
    $date = date "2013-01-26 06:47:29";
    $ret = $date->truncated;
    $ret = $ret->to_string.$ret->epoch;
    $ret = $date->truncate;
    $ret = int(date(123456789));
    $ret = $date->set(100);
    $ret = $date->set("2013-01-26 06:47:29.345341");
    $ret = $date->set_ymd(1,2,3);
    $ret = $date->set_ymd(year => 1000);
    $ret = $date->clone();
    $ret = $date->clone(-1,1,-1,2,-3,3);
    $ret = $date->clone(year => 1, month => 2, day => 3, hour => 4, min => 5, sec => 6);
    $ret = $date->clone(year => 1, month => 2, day => 3, hour => 4, min => 5, sec => 6, tz => 'Europe/Kiev');
    $ret = $date->clone(tz => 'Europe/Moscow');
    $date->tz('Australia/Melbourne');
    $date->to_timezone('Europe/Kiev');
    $ret = $date->tz;
    tzset('America/New_York');


    $date = Date->new("2013-03-05 02:040:6");
    eval{$date->strftime};
    $ret = $date->strftime("");
    $ret = $date->strftime('%Y') . $date->strftime('%Y/%m/%d') . $date->strftime('%H-%M-%S') . $date->strftime('%b %B');
    $ret = $date->monname . $date->monthname . $date->wdayname . $date->day_of_weekname;



    # OK
    $date = new Date("2010-01-01");
    my $ok;
    $ok = 1 if $date;
    $ret = $date->error;

    # UNPARSABLE
    $date = new Date("pizdec");
    $ok = 0;
    $ok = 1 if $date;
    $ret = $date->error;
    $ret = int($date);


    $ret = Date::range_check;
    $ret = Date->new("2001-02-31").'';
    $ret = Date::range_check(1);
    $ret = Date::range_check;
    $date = Date->new("2001-02-31");
    $ret = 1 if $date;
    $ret = $date->to_string;
    $ret = $date->error;
    Date::range_check(undef);
    

    $rel = new Date::Rel;
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = 1 if $rel;
    $ret = $rel.''.($rel eq "");

    $rel = new Date::Rel(1000);
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel.''.$rel->to_string;

    $rel = new Date::Rel("1000");
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->to_string;

    $rel = Date::Rel->new_ymd(1,2,3,4,5,6);
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year + $rel->to_secs +
           $rel->to_number + int($rel) + $rel->to_mins + $rel->to_hours + $rel->to_days + $rel->to_months +
           $rel->to_years;
    $ret = $rel->to_string;

    $rel = Date::Rel->new_ymd(year => 1, month => 2, day => 3, hour => 4, min => 5, sec => 6);
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->to_string;
    $rel = new Date::Rel "6s";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->to_string;
    $rel = new Date::Rel "5m";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->to_string;
    $rel = new Date::Rel "2h";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->to_string;
    $rel = new Date::Rel "1s 1m 1h";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->to_string;
    $rel = new Date::Rel "-9999M";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->to_string;
    $rel = new Date::Rel "12Y";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->to_string;
    $rel = new Date::Rel "1Y 2M 3D 4h 5m 6s";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->to_string;
    $rel = new Date::Rel "-1Y -2M -3D 4h 5m 6s";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->to_string;
    $rel = rdate "1Y 2M 3D 4h 5m 6s";
    $ret = $rel->sec + $rel->min + $rel->hour + $rel->day + $rel->month + $rel->year;
    $ret = $rel->to_string;

    $ret = rdate("2012-03-02 15:47:32", "2013-04-03 16:48:33")->to_string;
    $ret = rdate("2013-04-03 16:48:33", "2012-03-02 15:47:32")->to_string;
    $ret = rdate("2012-03-02 15:47:32", "2013-04-03 16:48:33") eq Date::Rel->new("2012-03-02 15:47:32", "2013-04-03 16:48:33");

    $rel->set(1000);
    $ret = $rel->to_string;
    $rel->set(0);
    $rel->set("1000");
    $rel->set(0);
    $rel->set("1Y 2M 3D 4h 5m 6s");
    $rel->set(0);
    $rel->set_ymd(1,2,3,4,5,6);
    $rel->set(0);
    $rel->set_ymd(year => 1, month => 2, day => 3, hour => 4, min => 5, sec => 6);
    $rel->set(0);

    $ret = SEC eq "1s" && MIN eq "1m" && HOUR eq "1h" && DAY eq '1D' && MONTH eq '1M' && YEAR eq '1Y';



    $ret = MONTH + "1D";
    $ret = "1Y" + DAY;
    $ret = YEAR + HOUR;
    $ret = (MONTH + date("2012-01-01"))->to_string;
    $rel = rdate("1Y 1M");
    $rel += "1M";
    $scalar = "23h";
    $scalar += $rel;
    $ret = $scalar->to_string;
    $rel += DAY;
    eval { $rel += date(123); 1; };
    $ret = MONTH - "1D";
    $ret = "1Y" - DAY;
    $ret = YEAR - HOUR;
    eval { my $a = MONTH - date("2012-01-01"); 1; };
    $rel = rdate("1Y 1M");
    $rel -= "1M";
    $scalar = "23h";
    $scalar -= $rel;
    $rel -= DAY;
    eval { $rel -= date(123); 1; };
    $ret = MONTH*5;
    $ret = 100*DAY;
    eval {my $a = DAY*DAY;1};
    eval {my $a = DAY*date(0);1};
    $rel = rdate("100Y 2M");
    $rel *= 0.5;
    $scalar = 10;
    $scalar *= $rel;
    eval {$rel *= $rel; 1};
    eval {$rel *= date(0); 1};
    $ret = DAY/4;
    eval {my $a = 2/SEC; 1};
    eval {my $a = DAY*DAY; 1};
    eval {my $a = DAY*date(0); 1};
    $rel = rdate("100Y 2M");
    $rel /= 0.5;
    $scalar = 10;
    eval {$scalar /= $rel; 1};
    eval {$rel /= $rel; 1};
    eval {$rel /= date(0); 1};
    $ret = -rdate("1Y 2M -3D -4h");
    $ret = rdate("1Y")->negate;
    $rel = rdate("1Y 1M");
    $ret = $rel > "1Y" && $rel < "1Y 1M 1s";
    $ret = "1Y" < $rel && "1Y 1M 1s" > $rel;
    $ret = $rel > $rel && $rel < $rel && $rel == $rel && $rel > rdate("1Y") && $rel != rdate("1Y 30M");
    eval {my $a = $rel < date(0); 1};



    $date = date("2012-03-02 15:47:32");
    $ret = $date + "1D";
    $ret = "1Y 1m" + $date;
    $ret = $date + HOUR;
    eval {my $a = $date + date(0); 1};
    $date = date("2012-03-02 15:47:32");
    $date += "1M";
    $ret = $date->to_string;
    $scalar = "23h";
    $scalar += $date;
    $date += YEAR;
    eval { $date += date(123); 1; };
    $date = date("2012-03-02 15:47:32");
    $ret = $date - "1D";
    $ret = $date - "2011-04-03 16:48:33";
    $ret = date("2013-04-03 16:48:33") - $date;
    $ret = $date - HOUR;
    $ret = date("2013-04-03 16:48:33") - $date;
    $date = date("2012-03-02 15:47:32");
    $date -= "1M";
    $scalar = "2013-04-03 16:48:33";
    $date -= DAY;
    eval { $date -= date(123); 1; };
    $date = date("2012-03-02 15:47:32");
    $ret = $date > "2012-03-02 15:47:31" && $date < "2012-03-02 15:47:33";
    $ret = $date > 1330688851 && $date < 1330688853 && $date == 1330688852 && $date eq 1330688852;
    $ret = "2012-03-02 15:47:31" < $date && "2012-03-02 15:47:33" > $date;
    $ret = 1330688851 < $date && 1330688853 > $date && 1330688852 == $date && 1330688852 eq $date;
    eval { my $a = $date > MONTH; 1};
    $ret = $date > date(0) && $date < date(2000000000);
    $ret = date(1330688851) < $date && date(1330688853) > $date && date(1330688852) == $date && date(1330688852) eq $date;

    $ret = Date::today_epoch();

    foreach my $obj (date(1000000000), date(1000000000, 'Europe/Kiev'), rdate("1Y 1M 1D 2h 3m 4s"), date(1000000000, 'Europe/Kiev')) {
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
