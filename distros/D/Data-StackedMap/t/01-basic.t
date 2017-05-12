#!perl

use strict;

use Test::More tests => 20;

BEGIN { use_ok("Data::StackedMap"); }

my $data = Data::StackedMap->new();
isa_ok($data, "Data::StackedMap");

is($data->size, 1);
ok(!$data->exists("foo"));

ok(!defined $data->get("foo"));

$data->push();
is($data->size, 2);
$data->pop();
is($data->size, 1);

$data->set("a" => 10);
is($data->exists("a"), -1);
is($data->get("a"), 10);

$data->set("a" => 20);
is($data->get("a"), 20);

$data->push();
is($data->exists("a"), -2);
$data->set("a" => 30);
is($data->get("a"), 30);
$data->pop();
is($data->get("a"), 20);

$data->delete("a");
is($data->exists("a"), 0);

$data->set("a" => 10);
$data->push();
$data->delete("a");
is($data->exists("a"), -2);
$data->pop();

eval {
    $data->pop();
};
like($@, qr/Can't pop single layer stack/);

$data = Data::StackedMap->new({bar => 1});
is($data->get("bar"), 1);

$data = Data::StackedMap->new({a => 1});
$data->push();
$data->set(b => 2);
$data->set(c => 3);
my @keys = sort $data->keys;
is_deeply(\@keys, ['a', 'b', 'c']);

@keys = sort $data->top_keys;
is_deeply(\@keys, ['b', 'c']);

$data = Data::StackedMap->new();
$data->put(a => 1);
ok($data->exists('a'));
