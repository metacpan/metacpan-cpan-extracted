#!/usr/bin/env perl
use Test::More;

use App::RoboBot::Test::Mock;

plan tests => 37;
use_ok('App::RoboBot::Plugin::Types::Map');

my ($bot, $net, $chn, $msg, $plg);
my $rpl = {};

SKIP: {
    skip App::RoboBot::Test::Mock::envset_message(), 1 unless $ENV{'R_DBTEST'};

    ($bot, $net, $chn, $msg) = mock_all("foo");
    $plg = (grep { $_->name eq 'Types::Map' } @{$bot->plugins})[0];

    is(ref($plg), 'App::RoboBot::Plugin::Types::Map', 'plugin class correct');
}

my @ret = App::RoboBot::Plugin::Types::Map::map_assoc(
    $plg, $msg, 'assoc', $rpl, {}, ':foo'
);

ok(scalar(@ret) == 1,               'single keyonly assoc single return value');
is(ref($ret[0]), 'HASH',            'single keyonly assoc map return');
ok(exists $ret[0]{':foo'},          'single keyonly assoc key exists');
ok(!defined $ret[0]{':foo'},        'single keyonly assoc key undefined value');
ok(scalar(keys(%{$ret[0]})) == 1,   'single keyonly assoc no other keys');

@ret = App::RoboBot::Plugin::Types::Map::map_assoc(
    $plg, $msg, 'assoc', $rpl, {}, ':foo', ':bar'
);

ok(scalar(@ret) == 1,                                       'dual keyonly assoc single return value');
is(ref($ret[0]), 'HASH',                                    'dual keyonly assoc map return');
ok(exists $ret[0]{':foo'} && exists $ret[0]{':bar'},        'dual keyonly assoc keys exist');
ok(!defined $ret[0]{':foo'} && !defined $ret[0]{':bar'},    'dual keyonly assoc both keys undefined value');
ok(scalar(keys(%{$ret[0]})) == 2,                           'dual keyonly assoc no other keys');

@ret = App::RoboBot::Plugin::Types::Map::map_assoc(
    $plg, $msg, 'assoc', $rpl, {}, ':foo', 1, ':bar', 2
);

ok(scalar(@ret) == 1,                                   'dual assoc single return value');
is(ref($ret[0]), 'HASH',                                'dual assoc map return');
ok(exists $ret[0]{':foo'} && exists $ret[0]{':bar'},    'dual assoc keys exist');
ok($ret[0]{':foo'} == 1 && $ret[0]{':bar'} == 2,        'dual assoc both keys expected values');
ok(scalar(keys(%{$ret[0]})) == 2,                       'dual assoc no other keys');

@ret = App::RoboBot::Plugin::Types::Map::map_get(
    $plg, $msg, 'get', $rpl, { ':foo' => 'bar' }, ':foo'
);

ok(scalar(@ret) == 1,   'single extant get single return value');
ok(!ref($ret[0]),       'single extant get scalar return');
is($ret[0], 'bar',      'single extant get expected value');

@ret = App::RoboBot::Plugin::Types::Map::map_get(
    $plg, $msg, 'get', $rpl, { ':foo' => 'bar' }, ':baz'
);

ok(scalar(@ret) == 1,   'single non-extant get single return value');
ok(!ref($ret[0]),       'single non-extant get scalar return');
ok(!defined $ret[0],    'single non-extant get expected undefined value');

@ret = App::RoboBot::Plugin::Types::Map::map_get(
    $plg, $msg, 'get', $rpl, { ':foo' => 'bar' }, ':baz', 'argle'
);

ok(scalar(@ret) == 1,   'single non-extant get with default single return value');
ok(!ref($ret[0]),       'single non-extant get with default scalar return');
is($ret[0], 'argle',    'single non-extant get with default expected value');

@ret = App::RoboBot::Plugin::Types::Map::map_get(
    $plg, $msg, 'get', $rpl, { ':foo' => 'bar', ':baz' => 'argle' }, [':baz',':foo']
);

ok(scalar(@ret) == 2,   'dual extant get correct size list return value');
is($ret[0], 'argle',    'dual extant get first expected value');
is($ret[1], 'bar',      'dual extant get second expected value');

@ret = App::RoboBot::Plugin::Types::Map::map_get(
    $plg, $msg, 'get', $rpl, { ':foo' => 'bar', ':baz' => 'argle' }, [':baz',':foo',':bar'], 'wat'
);

ok(scalar(@ret) == 3,   'mixed-extant get with default correct size list return value');
is($ret[0], 'argle',    'mixed-extant get with default first expected value');
is($ret[1], 'bar',      'mixed-extant get with default second expected value');
is($ret[2], 'wat',      'mixed-extant get with default third expected default value');

@ret = App::RoboBot::Plugin::Types::Map::map_keys(
    $plg, $msg, 'keys', $rpl, { ':foo' => 1, ':bar' => 1, ':baz' => 1 }
);

ok(scalar(@ret) == 3,                               'keys correct size list return value');
is_deeply([sort @ret],[sort qw( :foo :bar :baz )],  'keys expected values');

@ret = App::RoboBot::Plugin::Types::Map::map_values(
    $plg, $msg, 'values', $rpl, { ':foo' => 1, ':bar' => 2, ':baz' => 3 }
);

ok(scalar(@ret) == 3,           'values correct size list return value');
is_deeply([sort @ret],[1,2,3],  'values expected values');

