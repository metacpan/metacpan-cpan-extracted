use 5.012;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib'; use MyTest;

catch_run("[operations]");

my $date;

subtest 'compare' => sub { 
    my $date = date(1000);
    cmp_ok($date, '>', 0);
    cmp_ok($date, '>', 999);
    cmp_ok($date, '>=', 1000);
    cmp_ok($date, '<', 1001);
    cmp_ok($date, '>', "1970-01-01 03:16:00");
    cmp_ok($date, '<', "1970-01-01 03:17:00");
    cmp_ok($date, '==', "1970-01-01 03:16:40");
    is($date, "1970-01-01 03:16:40");
    cmp_ok(date("2013-05-06 01:02:03"), '<', date("2013-05-06 01:02:04"));
    cmp_ok("2013-05-06 01:02:03", '<', date("2013-05-06 01:02:04"));
    cmp_ok(date("2013-05-06 01:02:03"), '<', "2013-05-06 01:02:04");
    cmp_ok("2013-05-06 01:02:04", '==', date("2013-05-06 01:02:04"));
    cmp_ok(date("2001-09-09 05:46:40"), '==', 1000000000);
    cmp_ok(date("2001-09-09 05:46:40"), '<', 1000000001);
    cmp_ok(date("2001-09-09 05:46:40"), '>', 999999999);
    cmp_ok(1000000000, '==', date("2001-09-09 05:46:40"));
    cmp_ok(1000000001, '>', date("2001-09-09 05:46:40"));
    cmp_ok(999999999, '<', date("2001-09-09 05:46:40"));
};

subtest 'add relative date' => sub {
    my $date = date("2013-01-01");
    
    my $reldate = rdate(0);
    cmp_ok($date + $reldate, '==', $date);
    
    $reldate = rdate(10);
    cmp_ok($date + $reldate, '==', "2013-01-01 00:00:10");
    cmp_ok($date + "15m 60s", '==', "2013-01-01 00:15:60");
    cmp_ok($date + "23h 15m 60s", '==', "2013-01-01 23:15:60");
    cmp_ok($date + "24h 15m 60s", '==', "2013-01-02 00:15:60");
    cmp_ok($date + 10*DAY, '==', "2013-01-11");
    cmp_ok($date + MONTH, '==', "2013-02-01");
    cmp_ok($date + 2000*YEAR, '==', "4013-01-01");
    
    $date += "1M";
    cmp_ok($date, '==', "2013-02-01");
    $date += 27*DAY;
    cmp_ok($date, '==', "2013-02-28");
    $date += DAY;
    cmp_ok($date, '==', "2013-03-01");
};

subtest 'check ops table' => sub {
    subtest '"+"' => sub {
        my $date = date("2012-03-02 15:47:32");
        cmp_ok($date + "1D", '==', "2012-03-03 15:47:32"); # $date $scalar
        cmp_ok("1Y 1m" + $date, '==', "2013-03-02 15:48:32"); # $scalar $date
        cmp_ok($date + HOUR, '==', "2012-03-02 16:47:32"); # $date $rel
        dies_ok { $date + date(0) }; # $date $date
    };
    subtest '"+="' => sub {
        # $date $scalar
        my $date = date("2012-03-02 15:47:32");
        $date += "1M";
        is($date, "2012-04-02 15:47:32");
        # $scalar $date
        my $scalar = "23h";
        $scalar += $date;
        is($date, "2012-04-02 15:47:32");
        is($scalar, "2012-04-03 14:47:32");
        # $date $rel
        $date += YEAR;
        is($date, "2013-04-02 15:47:32");
        is(YEAR, "1Y");
        # $date $date
        dies_ok { $date += date(123) };
    };
    subtest '"-"' => sub {
        my $date = date("2012-03-02 15:47:32");
        cmp_ok($date - "1D", '==', "2012-03-01 15:47:32"); # $date $scalar-rel
        cmp_ok($date - HOUR, '==', "2012-03-02 14:47:32"); # $date $rel
        is(date("2013-04-03 16:48:33") - $date, rdate("2012-03-02 15:47:32", "2013-04-03 16:48:33")); # $date $date
    };
    subtest '"-="' => sub {
        # $date $scalar
        my $date = date("2012-03-02 15:47:32");
        $date -= "1M";
        is($date, "2012-02-02 15:47:32");
        is($date+1, "2012-02-02 15:47:33");
        is($date-1, "2012-02-02 15:47:31");
        # $date $rel
        $date -= DAY;
        is($date, "2012-02-01 15:47:32");
        # $date $date
        dies_ok { $date -= date(123) };
    };
    subtest '"<=>"' => sub {
        my $date = date("2012-03-02 15:47:32");
        # $date $scalar
        cmp_ok($date, '>', "2012-03-02 15:47:31");
        cmp_ok($date, '<', "2012-03-02 15:47:33");
        cmp_ok($date, '>', 1330688851);
        cmp_ok($date, '<', 1330688853);
        cmp_ok($date, '==', 1330688852);
        # $scalar $date
        cmp_ok("2012-03-02 15:47:31", '<', $date);
        cmp_ok("2012-03-02 15:47:33", '>', $date);
        cmp_ok(1330688851, '<', $date);
        cmp_ok(1330688853, '>', $date);
        cmp_ok(1330688852, '==', $date);
        # $date $rel
        # $date $date
        cmp_ok($date, '>', date(0));
        cmp_ok($date, '<', date(2000000000));
        cmp_ok(date(1330688851), '<', $date);
        cmp_ok(date(1330688853), '>', $date);
        cmp_ok(date(1330688852), '==', $date);
    };
    subtest '"eq"' => sub {
        my $date = date("2012-03-02 15:47:32");
        # $date $scalar
        ok !($date eq "2012-03-02 15:47:31");
        ok $date ne "2012-03-02 15:47:31";
        ok $date eq 1330688852;
        ok !($date ne 1330688852);
        # $scalar $date
        ok !("2012-03-02 15:47:31" eq $date);
        ok "2012-03-02 15:47:31" ne $date;
        ok 1330688852 eq $date;
        ok !(1330688852 ne $date);
        # $date $rel
        dies_ok { $date eq MONTH };
        # $date $date
        ok !($date eq date(0));
        ok $date ne date(0);
        ok date(1330688852) eq $date;
        ok !(date(1330688852) ne $date);
        # accepts reference to primitive (to workaround using as inflate/deflate in DBIx::Class)
        ok !($date eq \"epta");
        ok $date ne \"epta";
    };
};

subtest "check that rdates haven't been changed" => sub {
    is(SEC, '1s');
    is(MIN, '1m');
    is(HOUR, '1h');
    is(DAY, '1D');
    is(MONTH, '1M');
    is(YEAR, '1Y');
};

done_testing();
