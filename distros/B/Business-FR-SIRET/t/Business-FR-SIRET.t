use Test::More tests => 19;

BEGIN {
	use_ok('Business::FR::SIRET');
};

# Microsoft
my $siret = '327 733 184 001 28';
ok(my $c = Business::FR::SIRET->new($siret));
is($c->siret, '32773318400128');
ok($c->is_valid());

ok($c = Business::FR::SIRET->new());
ok($c->siret($siret));
is($c->siret, '32773318400128');
ok($c->is_valid());

ok($c = Business::FR::SIRET->new());
ok($c->is_valid($siret));
is($c->siret, '32773318400128');

# Not valid
ok($c = Business::FR::SIRET->new('45566'));
is($c->siret, '');

ok($c = Business::FR::SIRET->new());
is($c->siret, '');
ok(!$c->siret('45566'));
is($c->siret, '');

ok($c = Business::FR::SIRET->new('12345678901234'));
ok(!$c->is_valid());
