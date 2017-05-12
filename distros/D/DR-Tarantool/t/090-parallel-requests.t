#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

BEGIN {
    use constant PLAN       => 48;
    use Test::More;
    use DR::Tarantool::StartTest;

    unless (DR::Tarantool::StartTest::is_version('1.5.2')) {

        plan skip_all => 'Incorrect tarantool version';
    } else {
        plan tests => PLAN;
    }
}
use Encode qw(decode encode);

my $LE = $] > 5.01 ? '<' : '';

BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Tarantool::LLClient', 'tnt_connect';
    use_ok 'DR::Tarantool', ':constant';
    use_ok 'File::Spec::Functions', 'catfile', 'rel2abs';
    use_ok 'File::Basename', 'dirname', 'basename';
    use_ok 'AnyEvent';
    use_ok 'DR::Tarantool::AsyncClient';
}

my $cfg_dir = catfile dirname(__FILE__), 'test-data';
ok -d $cfg_dir, 'directory with test data';
my $tcfg = catfile $cfg_dir, 'llc-easy2.cfg';
ok -r $tcfg, $tcfg;

my $script_dir = catfile dirname(__FILE__), 'test-data';
my $lua_file = catfile $script_dir, 'init.lua';

ok -d $script_dir, "-d $script_dir";
ok -r $lua_file, "-r $lua_file";

my $tnt = run DR::Tarantool::StartTest(
    cfg => $tcfg,
    script_dir => $script_dir
);

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
                type    => 'NUM',
            },
            {
                name    => 'password',
                type    => 'STR',
            }
        ],
        indexes => {
            0   => 'id',
            1   => 'name',
            2   => { name => 'tidx', fields => [ 'key', 'password' ] },
        },
    }
};



SKIP: {
    unless ($tnt->started and !$ENV{SKIP_TNT}) {
        diag $tnt->log unless $ENV{SKIP_TNT};
        skip "tarantool isn't started", PLAN - 11;
    }

    my $client;

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


    for my $cv (AE::cv) {
        $cv->begin;
        $client->call_lua(test_parallel => [ 0.1, 151274 ], sub {
            my ($ok, $tuple, $error) = @_;

            diag $error unless is $ok, 'ok', "first call test_parallel: status";
            is $tuple->raw(0), 151274, 'return value';
            $cv->end;
        });
        $cv->recv;
    }

    for my $cv (AE::cv) {
        my $started = AnyEvent::now;
        my $max = 0;
        for my $i ( 0 .. 10 ) {
            my $period = .8 * rand;
            $period = substr $period, 0, 5 unless length($period) < 5;
            $cv->begin;
            $client->call_lua(test_parallel => [ $period, $i ], sub {
                my ($ok, $tuple, $error) = @_;

                my $done_time = AnyEvent::now;
                $done_time -= $started;

                my $res = $tuple->raw(0);
                is $i, $res, 'id: ' . $res;
                cmp_ok $done_time, '>=', $period, 'delay minimum';
                cmp_ok $done_time, '<', $period + .1, 'delay maximum';
                $max = $done_time if $max < $done_time;
                $cv->end;
            });

        }
        $cv->recv;
        my $total_time = AnyEvent::now() - $started;
        cmp_ok $max, '<=', $total_time, 'total time';
        cmp_ok $total_time, '<=', 1, 'total time less than 1 second';
    }
}


