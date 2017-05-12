#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

BEGIN {
    use constant PLAN       => 62;
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

    use_ok 'DR::Tarantool::MsgPack::AsyncClient';
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

my $tnt;

sub wait_cv_ok($;$) {
    my ($cv, $timeout) = @_;
    $timeout ||= .5;
    my $tmr;
    $tmr = AE::timer $timeout, 0, sub {
        undef $tmr;
        undef $timeout;
        $cv->end;
    };
    $cv->recv;
    ok $timeout, 'timeout not exceeded';
    undef $tmr;
}

for my $cv (AE::cv) {
    $cv->begin;
    DR::Tarantool::MsgPack::AsyncClient->connect(
        port        => $t->primary_port,
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
        sub {
            ($tnt) = @_;
            $cv->end;
        }
    );

    wait_cv_ok $cv;
    ok $tnt => 'connection established';
}

note 'ping';
for my $cv (AE::cv) {
    $cv->begin;
    $tnt->ping(sub {
        $cv->end;
        is $_[0] => 'ok', 'status';
        is $_[1] => undef, 'no tuples';
        is $_[2] => 0, 'code';
    });
    wait_cv_ok $cv;
}

note 'insert';
for my $cv (AE::cv) {
    $cv->begin;
    $tnt->insert(7, [1,'вася',3], sub {
        is $_[0] => 'ok', 'status';
        is_deeply $_[1]->raw => [1, 'вася', 3], 'tuples';
        is $_[2] => 0, 'code';
        $cv->end;
    });
    
    $cv->begin;
    $tnt->insert('name_in_script', [2,'петя',3], sub {
        is $_[0] => 'ok', 'status';
        isa_ok $_[1] => 'DR::Tarantool::Tuple';
        is_deeply $_[1]->raw => [2,'петя',3], 'tuple';
        is $_[2] => 0, 'code';
        $cv->end;
    });

    wait_cv_ok $cv;
}

note 'replace';
for my $cv (AE::cv) {
    $cv->begin;
    $tnt->replace(7, [1,'васяня',31], sub {
        is $_[0] => 'ok', 'status';
        is_deeply $_[1]->raw => [1, 'васяня', 31], 'tuples';
        is $_[2] => 0, 'code';
        $cv->end;
    });
    
    $cv->begin;
    $tnt->replace('name_in_script', [2,'петюня',32], sub {
        is $_[0] => 'ok', 'status';
        isa_ok $_[1] => 'DR::Tarantool::Tuple';
        is_deeply $_[1]->raw => [2,'петюня',32], 'tuple';
        is $_[2] => 0, 'code';
        is $_[1]->id => 2, 'id';
        is $_[1]->name => 'петюня', 'name';
        is $_[1]->age => 32, 'age';
        $cv->end;
    });
    
    $cv->begin;
    $tnt->replace('name_in_script', [3,'масяня',32], sub {
        is $_[0] => 'ok', 'status';
        isa_ok $_[1] => 'DR::Tarantool::Tuple';
        is_deeply $_[1]->raw => [3,'масяня',32], 'tuple';
        is $_[2] => 0, 'code';
        $cv->end;
    });

    wait_cv_ok $cv;
}

note 'delete';
for my $cv (AE::cv) {
    $cv->begin;
    $tnt->delete('name_in_script' => 11, sub {
        $cv->end;
        is $_[0] => 'ok', 'status';
        is $_[1] => undef, 'not exists tuple';
    });

    $cv->begin;
    $tnt->delete('name_in_script' => 1, sub {
        $cv->end;
        is $_[0] => 'ok', 'status';
        is_deeply $_[1]->raw => [1, 'васяня', 31], 'exists tuple';
    });

    wait_cv_ok $cv;
}
for my $cv (AE::cv) {
    $cv->begin;
    $tnt->delete('name_in_script' => 1, sub {
        $cv->end;
        is $_[0] => 'ok', 'status';
        is $_[1] => undef, 'really removed';
    });

    wait_cv_ok $cv;
}


note 'select';
for my $cv (AE::cv) {
    $cv->begin;
    $tnt->select('name_in_script', 'id', 1, sub {
        is $_[0] => 'ok', 'status';
        is $_[1] => undef, 'tuple (deleted)';
        is $_[2] => 0, 'code';
        $cv->end;
    });
    
    $tnt->select('name_in_script', 'id', 2, sub {
        is $_[0] => 'ok', 'status';
        is_deeply $_[1]->raw => [2, 'петюня', 32], 'tuple';
        is $_[1]->iter->count, 1, 'count of tuples';
        is $_[2] => 0, 'code';
        $cv->end;
    });
    $tnt->select('name_in_script', 'id', 2, limit => 20, iterator => 'GE', sub {
        is $_[0] => 'ok', 'status';
        is_deeply $_[1]->raw => [2, 'петюня', 32], 'tuple (deleted)';
        SKIP: {
            skip 'tarantool has bug #273', 1;
            is $_[1]->iter->count, 2, 'count of tuples';
        };
        is $_[2] => 0, 'code';
        $cv->end;
    });

    wait_cv_ok $cv;
}

note 'update';
for my $cv (AE::cv) {
    $cv->begin;
    $tnt->update(
        'name_in_script',
        2,
        [ [ '+' => 2, 2 ] ],
        sub {
            $cv->end;
            is $_[0] => 'ok', 'status';
            is_deeply $_[1]->raw => [2, 'петюня', 34], 'tuple';
            is $_[2] => 0, 'code';
        }
    );

    wait_cv_ok $cv;
}
for my $cv (AE::cv) {
    $cv->begin;
    $tnt->update(
        'name_in_script',
        2,
        [ [ '+' => 'age', 2 ] ],
        sub {
            $cv->end;
            is $_[0] => 'ok', 'status';
            is_deeply $_[1]->raw => [2, 'петюня', 36], 'tuple';
            is $_[2] => 0, 'code';
        }
    );

    wait_cv_ok $cv;
}
