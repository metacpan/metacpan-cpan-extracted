# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Bank-Holidays.t'

#########################

use Test::More tests => 10;
use Bank::Holidays;

use_ok('DateTime');
$curr = DateTime->now();
isa_ok($curr, 'DateTime');

# Test simple check, when it is a holiday.
$bank = Bank::Holidays->new(dt => DateTime->new(month => 12, day => 25, year => $curr->year));
ok(ref $bank eq 'Bank::Holidays', "Bank::Holidays object with 'dt' parameter");
ok($bank->is_holiday(), "Holiday 'today' check");

# Test the Tomorrow parameter.
undef $bank;
$bank = Bank::Holidays->new(dt => DateTime->new(month => 12, day => 24, year => $curr->year));
ok($bank->is_holiday(Tomorrow => 1), "Holiday 'tomorrow' check");

# Test the Yesterday parameter
undef $bank;
$bank = Bank::Holidays->new(date => DateTime->new(month => 12, day => 26, year => $curr->year));
ok($bank->is_holiday(Yesterday => 1), "Holiday 'yesterday' check");

# Test with 'date' argument to constructor
undef $bank;
$bank = Bank::Holidays->new(date => DateTime->new(month => 12, day => 25, year => $curr->year));
ok(ref $bank eq 'Bank::Holidays', "Bank::Holidays object with 'date' parameter");
ok($bank->is_holiday(), "Holiday 'today' check");

# Test the Tomorrow parameter
undef $bank;
$bank = Bank::Holidays->new(date => DateTime->new(month => 12, day => 24, year => $curr->year));
ok($bank->is_holiday(Tomorrow => 1), "Holiday 'tomorrow' check");

# Test the Yesterday parameter
undef $bank;
$bank = Bank::Holidays->new(date => DateTime->new(month => 12, day => 26, year => $curr->year));
ok($bank->is_holiday(Yesterday => 1), "Holiday 'yesterday' check");
