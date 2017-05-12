
use strict;
use warnings;

use Test::More	tests => 7;
use Test::Exception;

use Calc;

my $calc = new Calc();
my $result;
$result = $calc->Add(5, 2);
ok($result == 7, "5 + 2");

$result = $calc->Mul(5, 2);
ok($result == 10, "5 * 2");

$result = $calc->Mul(5, 0);
ok($result == 0, "5 * 0");

$result = $calc->Sub(5, 2);
ok($result == 3, "5 - 2");

$result = $calc->Div(5, 2);
ok($result == 2, "5 / 2");

$result = $calc->Div(0, 2);
ok($result == 0, "0 / 2");

throws_ok { $calc->Div(5, 0); } 'Calc::DivisionByZero', '5 / 0';

