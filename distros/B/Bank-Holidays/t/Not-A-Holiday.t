# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Bank-Holidays.t'

use strict;
use Bank::Holidays;

use Test::More tests => 9;

use_ok("DateTime");

# for legacy reasons, we need to test both 'dt' and 'date'
# as constructors to the `new' method
for my $constructor (qw(dt date)) {
    # Check any old day is not a holiday.
    # March 26th, 1931 was a Thursday, and there are no federal holidays in March
    my $dt = DateTime->new(month => 3, day => 26, year => 1931);
    my $bank = Bank::Holidays->new( $constructor => $dt );
    ok(ref $bank eq 'Bank::Holidays', "Bank::Holidays object with '$constructor' parameter");
    ok(!$bank->is_holiday, "Not a holiday 'Today' check");

    # Check the tomorrow parameter.
    ok(!$bank->is_holiday(Tomorrow => 1), "Not a holiday 'Tomorrow' check");

    # Check the yesterday parameter.
    ok(!$bank->is_holiday(Yesterday => 1), "Not a holiday 'Yesterday' check");
}
