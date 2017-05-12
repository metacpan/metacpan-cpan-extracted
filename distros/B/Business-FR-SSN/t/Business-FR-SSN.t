use strict;
use Test::More tests => 20;

BEGIN {
	use_ok('Business::FR::SSN')
};

my $ssn = '1591075118104';
my $key = 97 - ($ssn % 97);
$ssn .= $key;

ok(my $c = Business::FR::SSN->new($ssn));
is($c->ssn, $ssn);
ok($c->is_valid());

ok($c = Business::FR::SSN->new());
ok($c->is_valid($ssn));

ok($c = Business::FR::SSN->new());
is($c->ssn, '');
$c->ssn($ssn);
is($c->ssn, $ssn);
ok($c->is_valid());

is($c->get_sex, 1);
is($c->get_birth_year, 59);
is($c->get_birth_month, 10);
is($c->get_birth_department, 75);

ok($c = Business::FR::SSN->new('123106789012345'));
ok(!$c->is_valid());

ok($c = Business::FR::SSN->new('123106789'));
is($c->ssn, '');
$c->ssn('aaaa');
is($c->ssn, '');
$c->ssn('123456789012345');
is($c->ssn, '');
