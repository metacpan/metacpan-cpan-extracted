use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

catch_run("[format-rfc850]");

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
    test 'Jan', 'Tuesday, 01-Jan-19 03:04:00 GMT', date("2019-01-01 03:04Z")->epoch, 'GMT';
    test 'Feb', 'Friday, 01-Feb-19 03:04:00 GMT', date("2019-02-01 03:04Z")->epoch, 'GMT';
    test 'Mar', 'Friday, 01-Mar-19 03:04:00 GMT', date("2019-03-01 03:04Z")->epoch, 'GMT';
    test 'Apr', 'Monday, 01-Apr-19 03:04:00 GMT', date("2019-04-01 03:04Z")->epoch, 'GMT';
    test 'May', 'Wednesday, 01-May-19 03:04:00 GMT', date("2019-05-01 03:04Z")->epoch, 'GMT';
    test 'Jun', 'Saturday, 01-Jun-19 03:04:00 GMT', date("2019-06-01 03:04Z")->epoch, 'GMT';
    test 'Jul', 'Monday, 01-Jul-19 03:04:00 GMT', date("2019-07-01 03:04Z")->epoch, 'GMT';
    test 'Aug', 'Thursday, 01-Aug-19 03:04:00 GMT', date("2019-08-01 03:04Z")->epoch, 'GMT';
    test 'Sep', 'Sunday, 01-Sep-19 03:04:00 GMT', date("2019-09-01 03:04Z")->epoch, 'GMT';
    test 'Oct', 'Tuesday, 01-Oct-19 03:04:00 GMT', date("2019-10-01 03:04Z")->epoch, 'GMT';
    test 'Nov', 'Friday, 01-Nov-19 03:04:00 GMT', date("2019-11-01 03:04Z")->epoch, 'GMT';
    test 'Dec', 'Sunday, 01-Dec-19 03:04:00 GMT', date("2019-12-01 03:04Z")->epoch, 'GMT';
    
    
    subtest 'bad' => sub {
        ok date("Monday, 01-Jan-19 03:04:00 GMT")->error, 'wrong wday';
        ok date("Epta, 01-Jan-19 03:04:00 GMT")->error, 'unknown wday';
        ok date("Tuesday, 01-J-2019 00:00:00 GMT")->error, 'unknown month';
        ok date("Tuesday, 01-Ja-2019 00:00:00 GMT")->error, 'unknown month';
        ok date("Tuesday, 01-Jak-2019 00:00:00 GMT")->error, 'unknown month';
        ok date("Tuesday, 01-Jann-2019 00:00:00 GMT")->error, 'unknown month';
        ok date("Tuesday, 01-Jan-2019 03:04:00 GMT")->error, '4-digit year';
        ok date("Tuesday, 01-Jan-19 03:04 GMT")->error, 'no seconds';
        ok date("01-Jan-2019 03:04:00 GMT")->error, 'no wday name';
    };
};

subtest 'stringify' => sub {
    is date_ymd(2019, 12, 9, 22, 7, 6)->to_string(Date::FORMAT_RFC850), "Monday, 09-Dec-19 22:07:06 +0300";
    is date_ymd(2019, 12, 9, 22, 7, 6, 0, "GMT")->to_string(Date::FORMAT_RFC850), "Monday, 09-Dec-19 22:07:06 GMT";
};

done_testing();
