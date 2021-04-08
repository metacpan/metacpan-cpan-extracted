use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

catch_run("[format-rfc822_1123]");

tzset('Europe/Moscow');

sub test ($$$$) {
    my ($name, $str, $epoch, $tzabbr) = @_;
    subtest $name => sub {
        my $d = date($str);
        ok !$d->error, "$str: no errors";
        is $d->epoch, $epoch, "$str: epoch";
        is $d->tzabbr, $tzabbr, "$str: tzabbr";
    };
}

subtest 'parse' => sub {
    subtest 'DD Mon YYYY HH:MM ZZZ' => sub {
        test 'Jan', '01 Jan 2019 03:04 GMT', date("2019-01-01 03:04Z")->epoch, 'GMT';
        test 'Feb', '01 Feb 2019 03:04 GMT', date("2019-02-01 03:04Z")->epoch, 'GMT';
        test 'Mar', '01 Mar 2019 03:04 GMT', date("2019-03-01 03:04Z")->epoch, 'GMT';
        test 'Apr', '01 Apr 2019 03:04 GMT', date("2019-04-01 03:04Z")->epoch, 'GMT';
        test 'May', '01 May 2019 03:04 GMT', date("2019-05-01 03:04Z")->epoch, 'GMT';
        test 'Jun', '01 Jun 2019 03:04 GMT', date("2019-06-01 03:04Z")->epoch, 'GMT';
        test 'Jul', '01 Jul 2019 03:04 GMT', date("2019-07-01 03:04Z")->epoch, 'GMT';
        test 'Aug', '01 Aug 2019 03:04 GMT', date("2019-08-01 03:04Z")->epoch, 'GMT';
        test 'Sep', '01 Sep 2019 03:04 GMT', date("2019-09-01 03:04Z")->epoch, 'GMT';
        test 'Oct', '01 Oct 2019 03:04 GMT', date("2019-10-01 03:04Z")->epoch, 'GMT';
        test 'Nov', '01 Nov 2019 03:04 GMT', date("2019-11-01 03:04Z")->epoch, 'GMT';
        test 'Dec', '01 Dec 2019 03:04 GMT', date("2019-12-01 03:04Z")->epoch, 'GMT';
    };
    
    test 'DD Mon YYYY HH:MM:SS ZZZ', '24 Oct 1983 14:20:19 Z', date("1983-10-24 14:20:19Z")->epoch, 'GMT';
    
    subtest 'DD Mon YY HH:MM ZZZ' => sub {
        test '>50', '24 Oct 83 00:00 UT', date("1983-10-24 00:00:00Z")->epoch, 'GMT';
        test '=50', '24 Oct 50 00:00 UT', date("2050-10-24 00:00:00Z")->epoch, 'GMT';
        test '<50', '24 Oct 49 00:00 UT', date("2049-10-24 00:00:00Z")->epoch, 'GMT';
    };
    
    # rfc822 does not support arbitrary tz abbrev, only limited number of values
    subtest 'zones' => sub {
        test 'Z',   '01 Jul 2019 00:00 Z',     date("2019-07-01 00:00Z")->epoch, 'GMT';
        test 'UT',  '01 Jul 2019 00:00 UT',    date("2019-07-01 00:00Z")->epoch, 'GMT';
        test 'GMT', '01 Jul 2019 00:00 GMT',   date("2019-07-01 00:00Z")->epoch, 'GMT';
        test 'EST', '01 Dec 2019 00:00 EST',   date("2019-12-01 00:00", "EST5EDT")->epoch, 'EST';
        test 'EDT', '01 Jul 2019 00:00 EDT',   date("2019-07-01 00:00", "EST5EDT")->epoch, 'EDT';
        test 'CST', '01 Dec 2019 00:00 CST',   date("2019-12-01 00:00", "CST6CDT")->epoch, 'CST';
        test 'CDT', '01 Jul 2019 00:00 CDT',   date("2019-07-01 00:00", "CST6CDT")->epoch, 'CDT';
        test 'MST', '01 Dec 2019 00:00 MST',   date("2019-12-01 00:00", "MST7MDT")->epoch, 'MST';
        test 'MDT', '01 Jul 2019 00:00 MDT',   date("2019-07-01 00:00", "MST7MDT")->epoch, 'MDT';
        test 'PST', '01 Dec 2019 00:00 PST',   date("2019-12-01 00:00", "PST8PDT")->epoch, 'PST';
        test 'PDT', '01 Jul 2019 00:00 PDT',   date("2019-07-01 00:00", "PST8PDT")->epoch, 'PDT';
        test 'A',   '01 Jul 2019 00:00 A',     date("2019-07-01 01:00Z")->epoch, '-01:00';
        test 'M',   '01 Jul 2019 00:00 M',     date("2019-07-01 12:00Z")->epoch, '-12:00';
        test 'N',   '01 Jul 2019 00:00 N',     date("2019-06-30 23:00Z")->epoch, '+01:00';
        test 'Y',   '01 Jul 2019 00:00 Y',     date("2019-06-30 12:00Z")->epoch, '+12:00';
        test '+xx', '01 Jul 2019 00:00 +0101', date("2019-06-30 22:59Z")->epoch, '+01:01';
        test '-xx', '01 Jul 2019 00:00 -0101', date("2019-07-01 01:01Z")->epoch, '-01:01';
    };
    
    subtest 'Wday, DD Mon YYYY HH:MM ZZZ' => sub {
        test 'Mon', 'Mon, 09 Dec 2019 00:00 Z', date("2019-12-09 00:00Z")->epoch, 'GMT';
        test 'Tue', 'Tue, 10 Dec 2019 00:00 Z', date("2019-12-10 00:00Z")->epoch, 'GMT';
        test 'Wed', 'Wed, 11 Dec 2019 00:00 Z', date("2019-12-11 00:00Z")->epoch, 'GMT';
        test 'Thu', 'Thu, 12 Dec 2019 00:00 Z', date("2019-12-12 00:00Z")->epoch, 'GMT';
        test 'Fri', 'Fri, 13 Dec 2019 00:00 Z', date("2019-12-13 00:00Z")->epoch, 'GMT';
        test 'Sat', 'Sat, 14 Dec 2019 00:00 Z', date("2019-12-14 00:00Z")->epoch, 'GMT';
        test 'Sun', 'Sun, 15 Dec 2019 00:00 Z', date("2019-12-15 00:00Z")->epoch, 'GMT';
    };
    
    subtest 'bad' => sub {
        ok date("01 J 2019 00:00:00 GMT")->error, 'unknown month';
        ok date("01 Ja 2019 00:00:00 GMT")->error, 'unknown month';
        ok date("01 Jak 2019 00:00:00 GMT")->error, 'unknown month';
        ok date("01 Jann 2019 00:00:00 GMT")->error, 'unknown month';
        ok date("01 Jan 2019 00:00:00 NAH")->error, 'unparsable zone';
        ok date("01 Jan 2019 00:00:00 +01:30")->error, 'colon between tzoff hour and min';
        ok date("01 Jan 2019 00:00:00 +130")->error, '4-digit required for tzoff';
        ok date('Tue, 09 Dec 2019 00:00 Z')->error, 'wrong wday';
        ok date('Ept, 09 Dec 2019 00:00 Z')->error, 'unknown wday';
        ok date("01 Jan 2019 00 GMT")->error, 'no minutes';
        ok date("01 Jan 201 00:00 GMT")->error, '3-digit year';
    };
};

subtest 'stringify' => sub {
    is date_ymd(2019, 12, 9, 22, 7, 6)->to_string(Date::FORMAT_RFC1123), "Mon, 09 Dec 2019 22:07:06 +0300";
    is date_ymd(2019, 12, 9, 22, 7, 6, 0, "GMT")->to_string(Date::FORMAT_RFC1123), "Mon, 09 Dec 2019 22:07:06 GMT";
};

done_testing();
