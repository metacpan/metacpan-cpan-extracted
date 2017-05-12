
use Test::More tests => 32;
use DBI;
use strict;

use Acme::BeyondPerl::ToSQL({
	dbi => ["dbi:SQLite:dbname=acme_db","",""],
	debug => 0,
});

my $value = 10;

isa_ok($value, 'Acme::BeyondPerl::ToSQL');
ok(defined $value);
is($value, 10);

$value = $value * 2;

isa_ok($value, 'Acme::BeyondPerl::ToSQL');
is($value, 20);

ok($value == 20);
ok($value != 10);
ok($value > 10);
ok($value < 30);
ok(!($value - 20));

is(1 + 2, 3);
is(1 - 2, -1);
is(2 - 1, 1);
is(2 - 2, 0.0); # not ok is(2 - 1, 0)
is(1.0 - 0.8, 0.2);
is(1.00002 + 1.01, 2.01002);
is(2 * 3, 6);
is(9 / 2, 4.5);
is(9 % 4, 1);

is($value += 10, 30);
is($value -= 10, 20);
is(++$value , 21);

is(1<<1, 2, '<<');
is(4>>2, 1, '>>');
is(1 & 1, 1, '&');
is(1 & 0, 0.0, '&');
# is(17 ^ 5, 20, 'XOR');
is(0 | 1, 1, '|');
is(0 | 0, 0, '|');
is(!1, '');

is(1 . 4, "14");
is(1 x 4, "1111");
like(123, qr/^\d+$/, "regexp");

=pod
ok(abs(log(10) - 2.302) < 0.01);
ok(abs(sqrt(2) - 1.414) < 0.01);
ok(abs(exp(3) - 20.085) < 0.01);
ok(sin(3.141592) < 0.01);
ok(abs(cos(3.141592) + 1) < 0.01);
ok(abs(atan2(1,1) * 4 - 3.1415) < 0.01);
=cut

