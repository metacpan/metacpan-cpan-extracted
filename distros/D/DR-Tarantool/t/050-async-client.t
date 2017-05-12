#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

use constant PLAN       => 80;
use Encode qw(decode encode);

my $LE = $] > 5.01 ? '<' : '';

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
    use_ok 'DR::Tarantool', ':constant';
    use_ok 'File::Spec::Functions', 'catfile';
    use_ok 'File::Basename', 'dirname', 'basename';
    use_ok 'AnyEvent';
    use_ok 'DR::Tarantool::AsyncClient';
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
        skip "tarantool isn't started", PLAN - 9;
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



    # ping
    for my $cv (condvar AnyEvent) {
        $client->ping(
            sub {
                my ($status) = @_;
                is $status, 'ok', '* ping';
                $cv->send;
            }
        );
        $cv->recv;
    }

    # insert
    for my $cv (condvar AnyEvent) {
        $cv->begin;
        $client->insert(
            'first_space',
            [
                10,
                'user',
                11,
                'password'
            ],
            TNT_FLAG_RETURN,
            sub {
                my ($status, $res) = @_;
                is $status, 'ok', '* insert status';
                is $res->id, 10, 'id';
                is $res->name, 'user', 'name';
                is $res->key, 11, 'key';
                is $res->password, 'password', 'password';
                $cv->end;
            }
        );

        $cv->begin;
        $client->insert(
            'first_space',
            [
                111,
                'user2',
                13,
                'password2'
            ],
            TNT_FLAG_RETURN,
            sub {
                my ($status, $res) = @_;
                is $status, 'ok', '* insert status';
                is $res->id, 111, 'id';
                is $res->name, 'user2', 'name';
                is $res->key, 13, 'key';
                is $res->password, 'password2', 'password';
                $cv->end;
            }
        );

        $cv->begin;
        $client->insert(
            'first_space',
            [
                10,
                'user',
                11,
                'password'
            ],
            TNT_FLAG_RETURN | TNT_FLAG_ADD,
            sub {
                my ($status, $code, $error) = @_;
                is $status, 'error', 'status';
                ok $code, 'code';
                like $error, qr{exists}, 'tuple already exists';
                $cv->end;
            }
        );
        $cv->recv;
    }

    # call lua
    for my $cv (condvar AnyEvent) {
        $cv->begin;
        $client->call_lua(
            'box.select' => [ 0, 0, 10 ],
            fields  => [
                { type => 'NUM', name => 'a' },
                'b',
                { type => 'NUM', name => 'c'},
                'd'
            ],
            args    => [ 's', 'i', { type => 'NUM' } ],
            sub {
                my ($status, $tuple) = @_;
                is $status, 'ok', '* call status';
                isa_ok $tuple => 'DR::Tarantool::Tuple', 'tuple packed';
                is $tuple->a, 10, 'id';
                is $tuple->b, 'user', 'name';
                is $tuple->c, 11, 'key';
                $cv->end;
            }
        );

        $cv->begin;
        $client->call_lua(
            'box.select' => [ 0, 0, 10 ],
            space => 'first_space',
            args    => [ 's', 'i', { type => 'NUM' } ],
            sub {
                my ($status, $tuple) = @_;
                is $status, 'ok', 'status';
                isa_ok $tuple => 'DR::Tarantool::Tuple', 'tuple packed';
                is $tuple->id, 10, 'id';
                is $tuple->name, 'user', 'name';
                is $tuple->key, 11, 'key';
                is $tuple->password, 'password', 'password';
                $cv->end;
            }
        );

        $cv->begin;
        $client->call_lua(
            'box.select' => [ 0, 0, 10 ],
            args    => [ 's', 'i', { type => 'NUM' } ],
            sub {
                my ($status, $tuple) = @_;
                is $status, 'ok', 'status';
                isa_ok $tuple => 'DR::Tarantool::Tuple', 'tuple packed';
                SKIP: {
                    skip 'there is no tuple', 4 unless $tuple;
                    is unpack("L$LE", $tuple->raw(0)), 10, 'id';
                    is $tuple->raw(1), 'user', 'name';
                    is unpack("L$LE", $tuple->raw(2)), 11, 'key';
                    is $tuple->raw(3), 'password', 'password';
                }
                $cv->end;
            }
        );

        $cv->begin;
        $client->call_lua(
            'box.select' => [ 0, 0, pack "L$LE" => 10 ],
            'first_space',
            sub {
                my ($status, $tuple) = @_;
                is $status, 'ok', 'status';
                isa_ok $tuple => 'DR::Tarantool::Tuple', 'tuple packed';
                is $tuple->id, 10, 'id';
                is $tuple->name, 'user', 'name';
                is $tuple->key, 11, 'key';
                is $tuple->password, 'password', 'password';
                $cv->end;
            }
        );

        $cv->begin;
        $client->call_lua(
            'box.select' => [ 0, 0, pack "L$LE" => 11 ],
            'first_space',
            sub {
                my ($status, $tuple) = @_;
                is $status, 'ok', 'status';
                is $tuple, undef, 'there is no tuple';
                $cv->end;
            }
        );

        $cv->begin;
        $client->call_lua(
            'unknown_function_name' => [ ],
            'first_space',
            sub {
                my ($status, $code, $errstr) = @_;
                is $status, 'error', 'status';
                cmp_ok $code, '>', 0, 'code';
                like $errstr, qr{Procedure .* is not defined}, 'errstr';
                $cv->end;
            }
        );

        $cv->recv;
    }

    # select
    for my $cv (condvar AnyEvent) {
        $cv->begin;
        $client->select(first_space => [[10], [11], [111]], 'i0', sub {
            my ($status, $tuple) = @_;
            is $status, 'ok', '* select status';
            my $iter = $tuple->iter;
            is $iter->count, 2, 'count of elements';
            is $tuple->id, 10, 'tuple(0)->id';
            is $iter->next->id, 10, 'tuple(0)->id';
            is $tuple->next->id, 111, 'tuple(1}->id';
            is $iter->next->id, 111, 'tuple(1)->id';

            $cv->end;
        });

        $cv->begin;
        $client->select(
            first_space => [[10], [11], [111]],
            limit   => 1,
            index   => 'i0',
            sub {
                my ($status, $tuple) = @_;
                is $status, 'ok', 'select (limit) status';
                my $iter = $tuple->iter;
                is $iter->count, 1, 'count of elements';
                is $tuple->id, 10, 'tuple(0)->id';
                is $iter->next->id, 10, 'tuple(0)->id';

                $cv->end;
            }
        );

        $cv->begin;
        $client->select(
            first_space => [[10], [11], [111]],
            limit   => 1,
            offset  => 1,
            index   => 'i0',
            sub {
                my ($status, $tuple) = @_;
                is $status, 'ok', 'select (limit) status';
                my $iter = $tuple->iter;
                is $iter->count, 1, 'count of elements';
                is $tuple->id, 111, 'tuple(0)->id';
                is $iter->next->id, 111, 'tuple(0)->id';

                $cv->end;
            }
        );

        $cv->begin;
        $client->select(first_space => [[11, 'password']], 'tidx', sub {
            my ($status, $tuple) = @_;
            is $status, 'ok', 'select status (not primary index)';
            my $iter = $tuple->iter;
            is $iter->count, 1, 'count of elements';
            is $tuple->id, 10, 'tuple(0)->id';
            $cv->end;
        });

        $cv->recv;
    }


    # delete
    for my $cv (condvar AnyEvent) {
        $cv->begin;
        $client->delete(first_space => 10, sub {
            my ($status, $tuple) = @_;
            is $status, 'ok', '* delete status';
            $cv->end;
        });

        $cv->begin;
        $client->select(first_space => 10, sub {
            my ($status, $tuple) = @_;
            is $status, 'ok', 'select deleted status';
            is $tuple, undef, 'there is no tuple';
            $cv->end;
        });

        $cv->recv;
    }

    # update
    for my $cv (condvar AnyEvent) {
        $cv->begin;
        $client->update(first_space => 111, [ name => set => 'привет1' ], sub {
            my ($status, $tuple) = @_;
            is $status, 'ok', '* update status';
            is $tuple, undef, 'tuple';
            $cv->end;
        });

        $cv->begin;
        $client->update(first_space =>
                        111, [ name => set => 'привет' ], TNT_FLAG_RETURN, sub {
            my ($status, $tuple) = @_;
            is $status, 'ok', '* update status';
            isa_ok $tuple => 'DR::Tarantool::Tuple', 'tuple was selected';
            is $tuple->name, 'привет', 'field was updated';
            $cv->end;
        });

        $cv->begin;
        $client->select(first_space => 111, sub {
            my ($status, $tuple) = @_;
            is $status, 'ok', 'select deleted status';
            isa_ok $tuple => 'DR::Tarantool::Tuple', 'tuple was selected';
            is $tuple->name, 'привет', 'field was updated';
            $cv->end;
        });

        $cv->recv;
    }
}


