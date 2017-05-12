#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

BEGIN {
    use constant PLAN       => 17;
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

    use_ok 'DR::Tarantool', 'tarantool';
    use_ok 'DR::Tarantool', ':constant';
    use_ok 'File::Spec::Functions', 'catfile', 'rel2abs';
    use_ok 'File::Basename', 'dirname', 'basename';
    use_ok 'AnyEvent';
    use_ok 'DR::Tarantool::AsyncClient';
}

my $cfg_dir = catfile dirname(__FILE__), 'test-data';
ok -d $cfg_dir, 'directory with test data';
my $tcfg = catfile $cfg_dir, 'llc-easy.cfg';
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
    1   => {
        name            => 'test_space',
        fields  => [
            {
                name    => 'id',
                type    => 'STR',
            },
        ],
        indexes => {
            0   => 'id',
        },
    },
};



SKIP: {
    unless ($tnt->started and !$ENV{SKIP_TNT}) {
        diag $tnt->log unless $ENV{SKIP_TNT};
        skip "tarantool isn't started", PLAN - 11;
    }

    my $client = tarantool port => $tnt->primary_port, spaces => $spaces;
    ok $client, 'Connected';


    $client->insert(test_space => [ 1 .. 10 ]);

    my $tuple = $client->select(test_space => 1);

    is_deeply $tuple->raw, [ 1 .. 10 ], 'tuple was written';

    $tuple = $client->call_lua('box.dostring', [
            "return box.select(1, 0, '1')"
        ] => 'test_space'
    );
    is_deeply $tuple->raw, [ 1 .. 10 ], 'tuple was read by dostring';


    $tuple = $client->call_lua('box.dostring', [
            "local tuple = box.select(1, 0, '1'); return tuple"
        ] => 'test_space'
    );
    is_deeply [$tuple->raw], [[ 1 .. 10 ]], 'tuple was read by dostring';

    $tuple = $client->call_lua('box.dostring', [
            q^
                local tuple = box.select(1, 0, '1')
                tuple = tuple:transform( #tuple, 0, ... )
                tuple = tuple:transform( 1, 1 )
                return { tuple:unpack() }
            ^,
            11,
            12,
            13,
            14
        ] => 'test_space'
    );

    diag explain $tuple->raw unless
    is_deeply [$tuple->raw], [[ 1, 3 .. 14 ]], 'tuple was read by dostring';

    $tuple = eval { $client->call_lua('box.dostring', [
                q^
                    local tuple = box.select(1, 0, '1')
                    tuple = tuple:transform( #tuple, 0, ... )
                    tuple = tuple:transform( 1, 1 )
                    return tuple
                ^,
                11,
                12,
                13,
                14
            ] => 'test_space'
        );
    };

    diag explain eval { $tuple->raw } unless
    is_deeply [eval { $tuple->raw }], [[ 1, 3 .. 14 ]], 'tuple was read';

    ok !$tnt->is_dead, 'Tarantool is still working';
}


