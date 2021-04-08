use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

catch_run("[format-ansi_c]");

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
    test 'Jan', 'Tue Jan 01 03:04:00 2019', date("2019-01-01 03:04")->epoch, 'MSK';
    test 'Feb', 'Fri Feb 01 03:04:00 2019', date("2019-02-01 03:04")->epoch, 'MSK';
    test 'Mar', 'Fri Mar 01 03:04:00 2019', date("2019-03-01 03:04")->epoch, 'MSK';
    test 'Apr', 'Mon Apr 01 03:04:00 2019', date("2019-04-01 03:04")->epoch, 'MSK';
    test 'May', 'Wed May 01 03:04:00 2019', date("2019-05-01 03:04")->epoch, 'MSK';
    test 'Jun', 'Sat Jun 01 03:04:00 2019', date("2019-06-01 03:04")->epoch, 'MSK';
    test 'Jul', 'Mon Jul  1 03:04:00 2019', date("2019-07-01 03:04")->epoch, 'MSK';
    test 'Aug', 'Thu Aug  1 03:04:00 2019', date("2019-08-01 03:04")->epoch, 'MSK';
    test 'Sep', 'Sun Sep  1 03:04:00 2019', date("2019-09-01 03:04")->epoch, 'MSK';
    test 'Oct', 'Tue Oct  1 03:04:00 2019', date("2019-10-01 03:04")->epoch, 'MSK';
    test 'Nov', 'Fri Nov  1 03:04:00 2019', date("2019-11-01 03:04")->epoch, 'MSK';
    test 'Dec', 'Sun Dec  1 03:04:00 2019', date("2019-12-01 03:04")->epoch, 'MSK';
    
    subtest 'bad' => sub {
        ok date("Wed Jan 01 03:04:00 2019")->error, 'wrong wday';
        ok date("Huy Jan 01 03:04:00 2019")->error, 'unknown wday';
        ok date("Tue Jac 01 03:04:00 2019")->error, 'unknown month';
        ok date("Tue Jan 01 03:04:00 201")->error, '3-digit year';
        ok date("Tue Jan 01 03:04 2019")->error, 'no seconds';
        ok date("Jan 01 03:04:00 2019")->error, 'no wday name';
    };
};

subtest 'stringify' => sub {
    is date_ymd(2019, 12, 9, 22, 7, 6)->to_string(Date::FORMAT_ANSI_C), "Mon Dec  9 22:07:06 2019";
};

done_testing();
