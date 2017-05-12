#!/usr/bin/perl
use Test::More tests => 24;
use Test::Deep;
use lib qw(lib t ..);

BEGIN
{
    use_ok( 'Ambrosia::Utils::Container' ); #test #1
}

my $container = new Ambrosia::Utils::Container;

ok($container->set(name => 'John') eq 'John', 'set');

ok($container->put(name => 'Jack') eq 'John', 'put');
ok($container->put(age => 33) == 33, 'put');

ok($container->set(name => 'John', age => 33) eq 'John,33', 'set multiply');

ok($container->get('name') eq 'John', 'get');

ok($container->exists('name'), 'exists true');
ok(!$container->exists('Name'), 'exists false');

ok($container->dump() =~ /^\^Storable/, 'dump');

ok($container->size() == 2, 'size');

cmp_deeply([$container->list()], bag('name','age'), 'list');

my $info = $container->info();
ok($info && $info eq $container->info_dump(), 'info and info_dump');

cmp_deeply($container->as_hash(), {name => 'John', age => 33}, 'as_hash');

cmp_deeply($container->clone()->as_hash(), {name => 'John', age => 33}, 'clone and as_hash');

$container->delete('name');
cmp_deeply($container->as_hash(), {age => 33}, 'delete');

$container->set(name => 'John');
ok($container->remove('name') eq 'John', 'delete');

$container->clear();
ok($container->size() == 0, 'clear');

################################################################################
use Data::Dumper;
$container->set(name => deferred::call {{a => 1}});
cmp_deeply({%{$container->get('name')}}, {a => 1}, 'defered call return hash');

$container->set(name => deferred::call {['a', 1]});
cmp_deeply([@{$container->get('name')}], bag('a', 1), 'defered call return array');

$container->set(name => deferred::call {1});
ok($container->get('name') == 1, 'defered call return bool');

$container->set(name => deferred::call {1});
ok($container->get('name') + 2 == 3, 'defered call return number');

$container->set(name => deferred::call {'abcd'});
ok($container->get('name') eq 'abcd', 'defered call return string');

$container->set(name => deferred::call { new Ambrosia::Utils::Container(__data => {a => 42})->as_hash() });
cmp_deeply(
    {%{$container->get('name')}},
    Ambrosia::Utils::Container->new(__data => {a => 42})->as_hash(),
    'defered call return other container 1');

$container->clear();
$container->set(name => deferred::call { new Ambrosia::Utils::Container(__data => {a => 42}) });
cmp_deeply(
    $container->get('name')->as_hash(),
    Ambrosia::Utils::Container->new(__data => {a => 42})->as_hash(),
    'defered call return other container 2');

