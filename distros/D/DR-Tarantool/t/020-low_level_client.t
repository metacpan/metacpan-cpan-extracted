#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

BEGIN {
    use constant PLAN       => 100;
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
    use_ok 'File::Spec::Functions', 'catfile';
    use_ok 'File::Basename', 'dirname', 'basename';
    use_ok 'AnyEvent';
}


my $cfg_dir = catfile dirname(__FILE__), 'test-data';
ok -d $cfg_dir, 'directory with test data';
my $tcfg = catfile $cfg_dir, 'llc-easy.cfg';
ok -r $tcfg, $tcfg;

my $tnt = run DR::Tarantool::StartTest( cfg => $tcfg );

SKIP: {
    unless ($tnt->started and !$ENV{SKIP_TNT}) {
        diag $tnt->log unless $ENV{SKIP_TNT};
        skip "tarantool isn't started", PLAN - 7;
    }

    my $client;

    # connect
    for my $cv (condvar AnyEvent) {
        DR::Tarantool::LLClient->connect(
            port                    => $tnt->primary_port,
            reconnect_period        => 0.1,
            cb      => sub {
                $client = shift;
                $cv->send;
            }
        );

        $cv->recv;
    }
    unless ( isa_ok $client => 'DR::Tarantool::LLClient' ) {
        diag eval { decode utf8 => $client } || $client;
        last;
    }

    # ping
    for my $cv (condvar AnyEvent) {
        $client->ping(
            sub {
                my ($res) = @_;
                is $res->{code}, 0, '* ping reply code';
                is $res->{status}, 'ok', 'status';
                is $res->{type}, TNT_PING, 'type';
                is $client->last_code, 0, 'operation code';
                is $client->last_error_string, undef, 'operation errstr';
                $cv->send;
            }
        );
        $cv->recv;
    }

    # insert
    for my $cv (condvar AnyEvent) {
        my $cnt = 3;
        $client->insert(
            0,
            [ pack("L$LE", 1), 'abc', pack "L$LE", 1234 ],
            TNT_FLAG_RETURN,
            sub {
                my ($res) = @_;
                is $res->{code}, 0, '* insert reply code';
                is $res->{status}, 'ok', 'status';
                is $client->last_code, 0, 'operation code';
                is $client->last_error_string, undef, 'operation errstr';
                is $res->{type}, TNT_INSERT, 'type';

                is $res->{tuples}[0][0], pack("L$LE", 1), 'key';
                is $res->{tuples}[0][1], 'abc', 'f1';

                $cv->send if --$cnt == 0;

            }
        );

        $client->insert(
            0,
            [ pack("L$LE", 2), 'cde', pack "L$LE", 4567 ],
            TNT_FLAG_RETURN,
            sub {
                my ($res) = @_;
                is $res->{code}, 0, 'insert reply code';
                is $client->last_code, 0, 'operation code';
                is $client->last_error_string, undef, 'operation code';
                is $res->{status}, 'ok', 'status';
                is $res->{type}, TNT_INSERT, 'type';

                is $res->{tuples}[0][0], pack("L$LE", 2), 'key';
                is $res->{tuples}[0][1], 'cde', 'f1';

                $cv->send if --$cnt == 0;

            }
        );
        $client->insert(
            0,
            [ pack("L$LE", 1), 'aaa', pack "L$LE", 1234 ],
            TNT_FLAG_RETURN | TNT_FLAG_ADD,
            sub {
                my ($res) = @_;
                is $res->{code} & 0x00002002, 0x00002002,
                    'insert reply code (already exists)';
                is $client->last_code, $res->{code}, 'operation code';
                is $client->last_error_string, $res->{errstr},
                    'operation errstr';
                
                is $res->{status}, 'error', 'status';
                is $res->{type}, TNT_INSERT, 'type';
                like $res->{errstr},
                    qr{Duplicate key exists|Tuple already exists}, 'errstr';
                $cv->send if --$cnt == 0;
            }
        );
        $cv->recv;
    }


    # select
    for my $cv (condvar AnyEvent) {
        my $cnt = 2;
        $client->select(
            0, # ns
            0, # idx
            [ [ pack "L$LE", 1 ], [ pack "L$LE", 2 ] ],
            2, # limit
            0, # offset
            sub {
                my ($res) = @_;
                is $res->{code}, 0, '* select reply code';
                is $res->{status}, 'ok', 'status';
                is $res->{type}, TNT_SELECT, 'type';
                is $client->last_code, $res->{code}, 'operation code';
                is $client->last_error_string, $res->{errstr},
                    'operation errstr';

                is
                    scalar(grep { $_->[1] and $_->[1] eq 'abc' }
                                                    @{ $res->{tuples} }),
                    1,
                    'first tuple'
                ;
                is
                    scalar(grep { $_->[1] and $_->[1] eq 'cde' }
                                                    @{ $res->{tuples} }),
                    1,
                    'second tuple'
                ;
                $cv->send if --$cnt == 0;
            }
        );

        $client->select(
            0, #ns
            0, #idx
            [ [ pack "L$LE", 3 ], [ pack "L$LE", 4 ] ],
            sub {
                my ($res) = @_;
                is $res->{code}, 0, 'select reply code';
                is $res->{status}, 'ok', 'status';
                is $res->{type}, TNT_SELECT, 'type';
                is $client->last_code, $res->{code}, 'operation code';
                is $client->last_error_string, $res->{errstr},
                    'operation errstr';

                ok !@{ $res->{tuples} }, 'empty response';
                $cv->send if --$cnt == 0;
            }
        );
        $cv->recv;
    }

    # update
    for my $cv (condvar AnyEvent) {
        my $cnt = 2;
        $client->update(
            0, # ns
            [ pack "L$LE", 1 ], # keys
            [
                [ 1 => set      => 'abcdef' ],
                [ 1 => substr   => 2, 2, ],
                [ 1 => substr   => 100, 1, 'tail' ],
                [ 2 => 'delete' ],
                [ 2 => insert   => pack "L$LE" => 123 ],
                [ 3 => insert   => 'third' ],
                [ 4 => insert   => 'fourth' ],
            ],
            TNT_FLAG_RETURN, # flags
            sub {
                my ($res) = @_;
                is $res->{code}, 0, '* update reply code';
                is $res->{status}, 'ok', 'status';
                is $res->{type}, TNT_UPDATE, 'type';
                is $client->last_code, $res->{code}, 'operation code';
                is $client->last_error_string, $res->{errstr},
                    'operation errstr';

                is $res->{tuples}[0][1], 'abeftail',
                    'updated tuple 1';
                is $res->{tuples}[0][2], (pack "L$LE", 123),
                    'updated tuple 2';
                is $res->{tuples}[0][3], 'third', 'updated tuple 3';
                is $res->{tuples}[0][4], 'fourth', 'updated tuple 4';
                $cv->send if --$cnt == 0;
            }
        );

        $client->update(
            0, # ns
            [ pack "L$LE", 2 ], # keys
            [
                [ 1 => set      => 'abcdef' ],
                [ 2 => or       => pack "L$LE", 23 ],
                [ 2 => and      => pack "L$LE", 345 ],
                [ 2 => xor      => pack "L$LE", 744 ],
            ],
            TNT_FLAG_RETURN, # flags
            sub {
                my ($res) = @_;
                is $res->{code}, 0, '* update reply code';
                is $res->{status}, 'ok', 'status';
                is $res->{type}, TNT_UPDATE, 'type';
                is $client->last_code, $res->{code}, 'operation code';
                is $client->last_error_string, $res->{errstr},
                    'operation errstr';

                is $res->{tuples}[0][1], 'abcdef',
                    'updated tuple 1';
                is
                    $res->{tuples}[0][2],
                    (pack "L$LE", ( (4567 | 23) & 345 ) ^ 744 ),
                    'updated tuple 2'
                ;
                $cv->send if --$cnt == 0;
            }
        );

        $cv->recv;

    }



    # delete
    for my $cv (condvar AnyEvent) {
        my $cnt = 2;
        $client->delete(
            0, # ns
            [ pack "L$LE", 1 ], # keys
            TNT_FLAG_RETURN, # flags
            sub {
                my ($res) = @_;
                is $res->{code}, 0, '* delete reply code';
                is $res->{status}, 'ok', 'status';
                is $res->{type}, TNT_DELETE, 'type';
                is $client->last_code, $res->{code}, 'operation code';
                is $client->last_error_string, $res->{errstr},
                    'operation errstr';

                SKIP: {
                    skip 'Old version of delete', 4 unless TNT_DELETE == 21;
                    is $res->{tuples}[0][1], 'abeftail',
                        'deleted tuple 1';
                    is $res->{tuples}[0][2], (pack "L$LE", 123),
                        'deleted tuple 2';
                    is $res->{tuples}[0][3], 'third',
                        'deleted tuple 3';
                    is $res->{tuples}[0][4], 'fourth',
                        'deleted tuple 4';
                }

                $cv->send if --$cnt == 0;
            }
        );

        $client->select(
            0, # ns
            0, # idx
            [ [ pack "L$LE", 1 ], [ pack "L$LE", 1 ] ],
            sub {
                my ($res) = @_;
                is $res->{code}, 0, '* select reply code';
                is $res->{status}, 'ok', 'status';
                is $res->{type}, TNT_SELECT, 'type';
                is $client->last_code, $res->{code}, 'operation code';
                is $client->last_error_string, $res->{errstr},
                    'operation errstr';

                ok !@{ $res->{tuples} }, 'really removed';
                $cv->send if --$cnt == 0;
            }
        );

        $cv->recv;
    }

    # call
    for my $cv (condvar AnyEvent) {
        my $cnt = 1;
        $client->call_lua(
            'box.select' => [ 0, 0, pack "L$LE", 2 ],
            0,
            sub {
                my ($res) = @_;

                is $res->{code}, 0, '* call reply code';
                is $res->{status}, 'ok', 'status';
                is $res->{type}, TNT_CALL, 'type';
                is $res->{tuples}[0][1], 'abcdef',
                    'updated tuple 1';
                is $client->last_code, $res->{code}, 'operation code';
                is $client->last_error_string, $res->{errstr},
                    'operation errstr';
                is
                    $res->{tuples}[0][2],
                    (pack "L$LE", ( (4567 | 23) & 345 ) ^ 744 ),
                    'updated tuple 2'
                ;
                $cv->send if --$cnt == 0;
            }
        );
        $cv->recv;
    }

    # memory leak (You have touse external tool to watch memory)
    if ($ENV{LEAK_TEST}) {
        for my $cv (condvar AnyEvent) {

            my $cnt = 1000000;

            my $tmr;
            $tmr = AE::timer 0.0001, 0.0001 => sub {
                $client->call_lua(
                    'box.select' => [ 0, 0, pack "L$LE", 2 ],
                    0,
                    sub {
                        if (--$cnt == 0) {
                            $cv->send;
                            undef $tmr;
                        }
                    }
                );


                DR::Tarantool::LLClient->connect(
                    port                    => $tnt->primary_port,
                    reconnect_period        => 100,
                    cb      => sub {
                        if (--$cnt == 0) {
                            $cv->send;
                            undef $tmr;
                        }
                    }
                );
            };

            $cv->recv;
        }
    }

    $client->_fatal_error('abc');
    ok !$client->is_connected, 'disconnected';
    for my $cv (condvar AnyEvent) {
        my $tmr;
        $tmr = AE::timer 0.5, 0, sub { undef $tmr; $cv->send };
        $cv->recv;
    }

    ok $client->is_connected, 'reconnected';

    # call after reconnect
    for my $cv (condvar AnyEvent) {
        my $cnt = 1;
        $client->call_lua(
            'box.select' => [ 0, 0, pack "L$LE", 2 ],
            0,
            sub {
                my ($res) = @_;

                is $res->{code}, 0, '* call after reconnect code';
                is $res->{status}, 'ok', 'status';
                is $res->{type}, TNT_CALL, 'type';
                is $res->{tuples}[0][1], 'abcdef', 'tuple 1';
                $cv->send if --$cnt == 0;
            }
        );
        $cv->recv;
    }


    for my $cv (condvar AnyEvent) {
        my $timer;
        $timer = AE::timer 0, .5, sub {
            undef $timer;
            $cv->send;
        };
        $cv->recv;
    }


    $tnt->kill;

    # socket error
    for my $cv (condvar AnyEvent) {
        my $cnt = 1;
        $client->call_lua(
            'box.select' => [ 0, 0, pack "L$LE", 2 ],
            0,
            sub {
                my ($res) = @_;
                is $res->{status}, 'fatal', '* fatal status';
                like $res->{errstr} => qr{Socket error}, 'Error string';

                is $res->{errstr}, $client->last_error_string,
                    'last_error_string';
                ok $client->last_code, 'last_code';
                $cv->send if --$cnt == 0;
            }
        );

        $cv->recv;
    }
    
    $tnt->restart;
    
    for my $cv (condvar AnyEvent) {
        my $cnt = 1;
        $client->call_lua(
            'box.select' => [ 0, 0, pack "L$LE", 2 ],
            0,
            sub {
                my ($res) = @_;
                is $res->{status}, 'ok', 'request after reconnect was ok';
                is $res->{tuples}[0][1], 'abcdef', 'tuple 1';
                is $client->last_code, 0, 'last_code';
                $cv->send if --$cnt == 0;
            }
        );

        $cv->recv;
    }

    $tnt->kill;


    # connect to shotdowned tarantool
    for my $cv (condvar AnyEvent) {
        DR::Tarantool::LLClient->connect(
            port                    => $tnt->primary_port,
            reconnect_period        => 0,
            cb      => sub {
                $client = shift;
                $cv->send;
            }
        );

        $cv->recv;
    }
    ok !ref $client, 'First unsuccessful connect';

    for my $cv (condvar AnyEvent) {
        DR::Tarantool::LLClient->connect(
            port                    => $tnt->primary_port,
            reconnect_period        => 100,
            cb      => sub {
                $client = shift;
                $cv->send;
            }
        );

        $cv->recv;
    }
    ok !ref $client, 'First unsuccessful connect without repeats';

    {
        my $done_reconnect = 0;
        for my $cv (condvar AnyEvent) {
            DR::Tarantool::LLClient->connect(
                port                    => $tnt->primary_port,
                reconnect_period        => .1,
                reconnect_always        => 1,
                cb      => sub {
                    $done_reconnect++;
                }
            );

            my $timer;
            $timer = AE::timer .5, 0 => sub {
                undef $timer;
                $cv->send;
            };

            $cv->recv;
        }
        ok !$done_reconnect, 'reconnect_always option';
    }

#     note $tnt->log;
}
