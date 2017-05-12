#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

BEGIN {
    use constant PLAN       => 63;
    use Test::More;
    use DR::Tarantool::StartTest;

    unless (DR::Tarantool::StartTest::is_version('1.5.2')) {

        plan skip_all => 'Incorrect tarantool version';
    } else {
        plan tests => PLAN;
    }
}
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Tarantool::LLSyncClient';
    use_ok 'File::Spec::Functions', 'catfile';
    use_ok 'File::Basename', 'dirname';
    use_ok 'DR::Tarantool', ':constant';
}
my $LE = $] > 5.01 ? '<' : '';


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

    my $client = DR::Tarantool::LLSyncClient->connect(
        port                => $tnt->primary_port,
        reconnect_period    => 0.1
    );


    note 'ping';
    ok $client->ping, 'ping';
    close $client->{fh};
    ok !$client->ping, 'ping disconnected';

    note 'call_lua';
    {
        my $res = $client->call_lua('box.dostring', [ 'return "123", "abc"' ]);
        isa_ok $res => 'HASH';
        is $res->{status}, 'ok', 'status';
        is_deeply $res->{tuples}, [[123],['abc']], 'tuples';
        is $res->{code}, 0, 'code';
        is $client->last_code, $res->{code}, 'code';
        is $client->last_error_string, '', 'error';
        is $res->{count}, 2, '2 tuples';
        is $res->{type}, TNT_CALL, 'type';
    }
    {
        my $res = eval {
            $client->call_lua('box.dostring', [ 'error("abc")' ]); ## LINE1
        };
        like $@, qr{Lua error}, 'Error';
    }


    note 'insert';
    {
        for (1 .. 2) {
            my $res = $client->insert(0,
                [ pack("L$LE", 1), 'abc', pack "L$LE", $_ ],
                TNT_FLAG_RETURN
            );
            isa_ok $res => 'HASH';
            is $res->{status}, 'ok', 'status';
            is $res->{type}, TNT_INSERT, 'type';
            is $res->{count}, 1, 'count';
            is_deeply $res->{tuples},
                [[pack("L$LE", 1), 'abc', pack "L$LE", $_]], 'tuples';
        }
        my $res = eval {
            $client->insert(0,
                [ pack("L$LE", 1), 'abc', pack "L$LE", 1234 ],
                TNT_FLAG_RETURN | TNT_FLAG_ADD
            );
        };
        is $res, undef, 'no results';
        like $@, qr{Duplicate key exists}, 'Error message';
        ok $client->last_code, 'last_code';
        like $client->last_error_string, qr{Duplicate key exists},
            'Error message';
    }

    note 'select';
    {
        my $res = $client->select(0, 0, [[ pack("L$LE", 1) ]], 2, 0);
        isa_ok $res => 'HASH';
        is $res->{status}, 'ok', 'status';
        is $res->{type}, TNT_SELECT, 'type';
        is $res->{count}, 1, 'count';
        is_deeply $res->{tuples}, [[pack("L$LE", 1), 'abc', pack "L$LE", 2]],
            'tuples';
    }
    {
        my $res = $client->select(0, 0, [[ pack("L$LE", 2) ]], 2, 0);
        isa_ok $res => 'HASH';
        is $res->{status}, 'ok', 'status';
        is $res->{type}, TNT_SELECT, 'type';
        is $res->{count}, 0, 'count';
        is_deeply $res->{tuples}, [], 'tuples';
    }

    note 'update';
    {
        my $res = $client->update(
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
        );

        is $res->{code}, 0, '* update reply code';
        is $res->{status}, 'ok', 'status';
        is $res->{type}, TNT_UPDATE, 'type';
        is $client->last_code, $res->{code}, 'operation code';
        is $client->last_error_string, $res->{errstr} // '',
            'operation errstr';

        is $res->{tuples}[0][1], 'abeftail',
            'updated tuple 1';
        is $res->{tuples}[0][2], (pack "L$LE", 123),
            'updated tuple 2';
        is $res->{tuples}[0][3], 'third', 'updated tuple 3';
        is $res->{tuples}[0][4], 'fourth', 'updated tuple 4';

        $res = $client->update(
            0,
            [ pack "L$LE", 1 ],
            [
                [ 1 => set => '123' ]
            ]
        );
        is $res->{code}, 0, 'update reply code';
        is $res->{status}, 'ok', 'status';
        is $res->{type}, TNT_UPDATE, 'type';
        is $client->last_code, $res->{code}, 'operation code';
        is $client->last_error_string, $res->{errstr} // '',
            'operation errstr';
        is $res->{count}, 1, 'count';
        is_deeply $res->{tuples}, [], 'no tuples';
    }

    note 'delete';

    {
        my $res = $client->delete(
            0, # ns
            [ pack "L$LE", 1 ], # keys
            TNT_FLAG_RETURN, # flags
        );
        
        is $res->{code}, 0, '* delete reply code';
        is $res->{status}, 'ok', 'status';
        is $res->{type}, TNT_DELETE, 'type';
        is $client->last_code, $res->{code}, 'operation code';
        is $client->last_error_string, $res->{errstr} // '',
            'operation errstr';

        is $res->{tuples}[0][1], '123',
            'deleted tuple[1]';
    }

}
