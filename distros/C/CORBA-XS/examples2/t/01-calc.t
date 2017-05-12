
use strict;
use warnings;

use Test::More  tests => 4;

use CalcCplx;

my $calc = new CalcCplx();
my $c1 = { re => 1, im => 3 };
my $c2 = { re => 2, im => -1 };
my $result;

$result = $calc->Add($c1, $c2);
ok($result->{re} == 3, 'Add (re)');
ok($result->{im} == 2, 'Add (im)');

$result = $calc->Sub($c1, $c2);
ok($result->{re} == -1, 'Sub (re)');
ok($result->{im} == 4, 'Sub (im)');

