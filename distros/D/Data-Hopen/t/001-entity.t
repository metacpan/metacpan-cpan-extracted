#!perl
# 001-entity.t: test Entity
use rlib 'lib';
use HopenTest;
use Test::Fatal;

use Data::Hopen::G::Entity;     # abort if we can't

# Basics
my $e = Data::Hopen::G::Entity->new(name=>'foo');
isa_ok($e, 'Data::Hopen::G::Entity');
is($e->name, 'foo', 'Name was set by constructor');
$e->name('bar');
is($e->name, 'bar', 'Name was set by accessor');

# Error conditions
like exception { Data::Hopen::G::Entity::name(); },
    qr/Need an instance/, 'name() throws absent instance';

# Misc., for coverage
$e = Data::Hopen::G::Entity->new();
like $e->name, qr/Entity.*HASH/, 'Anonymous entity stringifies as ref';

done_testing();
