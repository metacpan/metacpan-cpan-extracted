#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

BEGIN {
    use constant PLAN       => 19;
    use Test::More;
    use DR::Tarantool::StartTest;

    unless (DR::Tarantool::StartTest::is_version('1.6', 2)) {

        plan skip_all => 'tarantool 1.6 is not found';
    } else {
        plan tests => PLAN;
    }
}

use File::Spec::Functions 'catfile', 'rel2abs';
use File::Basename 'dirname';
use Encode qw(decode encode);
use lib qw(lib ../lib ../../lib);
use lib qw(blib/lib blib/arch ../blib/lib
    ../blib/arch ../../blib/lib ../../blib/arch);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Tarantool::MsgPack::SyncClient';
    use_ok 'AnyEvent';
}

my $cfg = catfile dirname(__FILE__), 'data', 'll.lua';
my $cfgg = catfile dirname(__FILE__), 'data', 'll-grant.lua';

ok -r $cfg, "-r config file ($cfg)";
ok -r $cfgg, "-r config file ($cfgg)";


my $t = DR::Tarantool::StartTest->run(
    family  => 2,
    cfg     => $cfg,


);

ok $t->started, 'tarantool was started';

$t->admin(q[ box.schema.user.create('user1', { password = 'password' }) ]);
$t->admin(q[ box.schema.user.grant('user1', 'read,write,execute', 'universe')]);
$t->admin(q[ box.schema.create_space('test', { id = 7 }).n]);
$t->admin(q[ box.space.test:create_index('pk', { type = 'tree' })]);

my $tnt = DR::Tarantool::MsgPack::SyncClient->connect(
    port => $t->primary_port,
    user        => 'user1',
    password    => 'password',
    spaces      => {
        7 => {
            name => 'name_in_script',
            fields => [ 'id', 'name', 'age' ],
            indexes => {
                0  => { name => 'id', fields => [ 'id' ] }
            }
        },

    },
);

isa_ok $tnt => 'DR::Tarantool::MsgPack::SyncClient', 'client is created';
ok $tnt->ping, 'ping';

is_deeply
    $tnt->insert('name_in_script', [ 1, 'вася', 21 ])->raw,
    [ 1, 'вася', 21 ],
    'insert';

is eval { $tnt->insert('name_in_script', [ 1, 'вася', 21 ]) }, undef, 'repeat';
like $@ => qr{Duplicate key exists}, 'error message';
isnt $tnt->last_code, 0, 'last_code';
like $tnt->last_error_string => qr{Duplicate key}, 'last_error_string';

is_deeply
    $tnt->replace('name_in_script', [ 1, 'вася', 23 ])->raw,
    [ 1, 'вася', 23 ],
    'insert';
is_deeply
    $tnt->replace('name_in_script', [ 2, 'петя', 23 ])->raw,
    [ 2, 'петя', 23 ],
    'insert';

is_deeply
    $tnt->delete('name_in_script', 1)->raw,
    [ 1, 'вася', 23 ],
    'delete';

is_deeply
    $tnt->select('name_in_script', 0, 1),
    undef,
    'select';
is_deeply
    $tnt->select('name_in_script', 0, 2)->raw,
    [ 2, 'петя', 23 ],
    'select';

is_deeply
    $tnt->call_lua('box.space.test.index.pk:select', 2)->raw,
    [2, 'петя', 23],
    'call_lua';

is $tnt->last_code, 0, 'last code';
