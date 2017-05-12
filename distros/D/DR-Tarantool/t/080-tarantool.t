#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

use constant PLAN       => 33;
use Encode qw(decode encode);

BEGIN {
    use Test::More;
    use DR::Tarantool::StartTest;

    unless (DR::Tarantool::StartTest::is_version('1.5.2')) {

        plan skip_all => 'Incorrect tarantool version';
    } else {
        plan tests => PLAN;
    }
}

BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Tarantool::LLClient', 'tnt_connect';
    use_ok 'DR::Tarantool::StartTest';
    use_ok 'DR::Tarantool', ':all';
    use_ok 'File::Spec::Functions', 'catfile';
    use_ok 'File::Basename', 'dirname', 'basename';
    use_ok 'AnyEvent';
    use_ok 'DR::Tarantool::SyncClient';
}

my $cfg_dir = catfile dirname(__FILE__), 'test-data';
ok -d $cfg_dir, 'directory with test data';
my $tcfg = catfile $cfg_dir, 'llc-easy2.cfg';
ok -r $tcfg, $tcfg;

my $tnt = run DR::Tarantool::StartTest( cfg => $tcfg );

my $spaces = {
    0   => {
        name            => 'first_space',
        fields  => [
            {
                name    => 'id',
                type    => 'NUM',
            },
            {
                name    => 'name',
                type    => 'UTF8STR',
            },
            {
                name    => 'key',
                type    => 'INT',
            },
            {
                name    => 'password',
                type    => 'STR',
            },
            {
                name    => 'balance',
                type    => 'MONEY',
            }
        ],
        indexes => {
            0   => 'id',
            1   => 'name',
            2   => [ 'key', 'password' ],
        },
    }
};

SKIP: {
    unless ($tnt->started and !$ENV{SKIP_TNT}) {
        diag $tnt->log unless $ENV{SKIP_TNT};
        skip "tarantool isn't started", PLAN - 9;
    }

    my $client = tarantool(
        port    => $tnt->primary_port,
        spaces  => $spaces
    );

    isa_ok $client => 'DR::Tarantool::SyncClient';
    ok $client->ping, '* tarantool ping';

    my $t = $client->insert(
        first_space => [1, 'привет', 11, 'password', '1.23'],
        TNT_FLAG_RETURN
    );
    isa_ok $t => 'DR::Tarantool::Tuple';
    is $t->balance, '1.23', 'money(1.23)';
    is $t->key, 11, 'key(11)';

    $t = $client->update(first_space => 1 =>
        [
            [ balance => add => '1.12' ],
            [ key     => add => 101 ],
        ],
        TNT_FLAG_RETURN
    );

    isa_ok $t => 'DR::Tarantool::Tuple';
    is $t->balance, '2.35', 'money(2.35)';
    is $t->key, 112, 'key(112)';
    $t = $client->update(first_space => 1 =>
        [
            [ balance => add => '-3.17' ],
            [ key     => add => -222 ],
        ],
        TNT_FLAG_RETURN
    );

    isa_ok $t => 'DR::Tarantool::Tuple';
    is $t->balance, '-0.82', 'money(-0.82)';
    is $t->key, -110, 'key(-110)';

    # second key
    $t = $client->insert(
        first_space => [2, 'привет2', -121, 'password2', '-2.34'],
        TNT_FLAG_RETURN
    );
    isa_ok $t => 'DR::Tarantool::Tuple';
    is $t->key, '-121', 'key(-121)';
    is $t->balance, '-2.34', 'money(-2.34)';
    $t = $client->update(first_space => 2 =>
        [
            [ balance => add => '-1.12' ],
            [ key     => add => -101 ],
        ],
        TNT_FLAG_RETURN
    );
    isa_ok $t => 'DR::Tarantool::Tuple';
    is $t->key, '-222', 'key(-222)';
    is $t->balance, '-3.46', 'money(-3.46)';
    $t = $client->update(first_space => 2 =>
        [
            [ balance => add => '5.17' ],
            [ key     => add => 777 ],
        ],
        TNT_FLAG_RETURN
    );
    isa_ok $t => 'DR::Tarantool::Tuple';
    is $t->key, '555', 'key(555)';
    is $t->balance, '1.71', 'money(1.71)';



    # connect
    for my $cv (condvar AnyEvent) {
        DR::Tarantool::AsyncClient->connect(
            port                    => $tnt->primary_port,
            reconnect_period        => 0.1,
            spaces                  => $spaces,
            cb      => sub {
                $client = shift;
                $cv->send;
            }
        );

        $cv->recv;
    }
    unless ( isa_ok $client => 'DR::Tarantool::AsyncClient' ) {
        diag eval { decode utf8 => $client } || $client;
        last;
    }


    # ping
    for my $cv (condvar AnyEvent) {
        $client->ping(
            sub {
                my ($status) = @_;
                is $status, 'ok', '* async_tarantool ping';
                $cv->send;
            }
        );
        $cv->recv;
    }

    eval "require Coro";
    skip "Coro isn't installed", 2 if $@;
    $client = coro_tarantool
        port    => $tnt->primary_port,
        spaces  => $spaces
    ;
    isa_ok $client => 'DR::Tarantool::CoroClient';
    ok $client->ping, '* coro_tarantool ping';
}

