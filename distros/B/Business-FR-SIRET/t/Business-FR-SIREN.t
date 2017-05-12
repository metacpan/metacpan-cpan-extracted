use Test::More tests => 19;

BEGIN {
	use_ok('Business::FR::SIREN');
};

# Microsoft
my $siren = '327 733 184';
ok(my $c = Business::FR::SIREN->new($siren));
is($c->siren, '327733184');
ok($c->is_valid());

ok($c = Business::FR::SIREN->new());
ok($c->siren($siren));
is($c->siren, '327733184');
ok($c->is_valid());

ok($c = Business::FR::SIREN->new());
ok($c->is_valid($siren));
is($c->siren, '327733184');

# Not valid
ok($c = Business::FR::SIREN->new('45566'));
is($c->siren, '');

ok($c = Business::FR::SIREN->new());
is($c->siren, '');
ok(!$c->siren('45566'));
is($c->siren, '');

ok($c = Business::FR::SIREN->new('123456789'));
ok(!$c->is_valid());
