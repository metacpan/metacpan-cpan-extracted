use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

catch_run("[strptime]");

sub test ($$$$) {
    my ($str, $fmt, $epoch, $tzabbr) = @_;
    my $d = Date::strptime($str, $fmt);
    is $d->epoch, $epoch, "$str: epoch";
    is $d->tzabbr, $tzabbr, "$str: tzabbr";
}

test '2019-02-03 04:05:06 Europe/Moscow', '%Y-%m-%d %H:%M:%S %Z', 1549155906, 'MSK';

done_testing;
