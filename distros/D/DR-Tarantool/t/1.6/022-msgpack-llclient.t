#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);
use lib qw(blib/lib blib/arch ../blib/lib
    ../blib/arch ../../blib/lib ../../blib/arch);

BEGIN {
    use constant PLAN       => 128;
    use Test::More;
    use DR::Tarantool::StartTest;

    unless (DR::Tarantool::StartTest::is_version('1.6', 2)) {

        plan skip_all => 'tarantool 1.6 is not found';
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

    use_ok 'DR::Tarantool';
    use_ok 'File::Spec::Functions', 'catfile', 'rel2abs';
    use_ok 'File::Basename', 'dirname';
    use_ok 'AnyEvent';
    use_ok 'DR::Tarantool::MsgPack::LLClient';
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

my $tnt;

note 'connect';
for my $cv (AE::cv) {
    $cv->begin;
    DR::Tarantool::MsgPack::LLClient->connect(
        host        => '127.0.0.1',
        port        => $t->primary_port,
        cb      => sub {
            ($tnt) = @_;
            ok $tnt, 'connect callback';
            $cv->end;
        }

    );
   
    my $timer;
    $timer = AE::timer 1.5, 0, sub { $cv->end };
    $cv->recv;
    undef $timer;

    ok $tnt => 'connector was saved 1';
}
unless ( isa_ok $tnt => 'DR::Tarantool::MsgPack::LLClient' ) {
    diag eval { decode utf8 => $tnt } || $tnt;
    note $t->log;
    exit;
}


note 'ping';

for my $cv (AE::cv) {
    $cv->begin;
    $tnt->ping(sub {
        my ($r) = @_;
        isa_ok $r => 'HASH', 'ping response';
        ok exists $r->{CODE}, 'ping code';
        ok exists $r->{SYNC}, 'ping sync';
        $cv->end;
    });

    my $timer;
    $timer = AE::timer 1.5, 0, sub { $cv->end };
    $cv->recv;
    undef $timer;
}


note 'call';

for my $cv (AE::cv) {
    $cv->begin;
    $tnt->call_lua('box.session.id', [], sub {
        my ($r) = @_;
        isa_ok $r => 'HASH', 'call response';
        ok exists $r->{CODE}, 'exists code';
        ok exists $r->{SYNC}, 'exists sync';
        ok exists $r->{ERROR}, 'exists error';
        like $r->{ERROR} => qr[Execute access denied], 'error text';
        $cv->end;
    });

    my $timer;
    $timer = AE::timer 1.5, 0, sub { $cv->end };
    $cv->recv;
    undef $timer;
}

note 'auth';


for my $cv (AE::cv) {
    $cv->begin;
    $tnt->auth('user1', 'password1', sub {
        my ($r) = @_;
        isa_ok $r => 'HASH', 'auth response';
        ok exists $r->{CODE}, 'exists code';
        ok exists $r->{SYNC}, 'exists sync';
        ok exists $r->{ERROR}, 'exists error';
        like $r->{ERROR} => qr[User.*is not found], 'error text';
        $cv->end;
    });

    my $timer;
    $timer = AE::timer 1.5, 0, sub { $cv->end };
    $cv->recv;
    undef $timer;
}

note
$t->admin(q[ box.schema.user.create('user1', { password = 'password1' }) ]);

for my $cv (AE::cv) {
    $cv->begin;
    $tnt->auth('user1', 'password2', sub {
        my ($r) = @_;
        isa_ok $r => 'HASH', 'auth response';
        ok exists $r->{CODE}, 'exists code';
        ok exists $r->{SYNC}, 'exists sync';
        ok exists $r->{ERROR}, 'exists error';
        like $r->{ERROR} => qr[Incorrect password supplied], 'error text';
        $cv->end;
    });

    my $timer;
    $timer = AE::timer 1.5, 0, sub { $cv->end };
    $cv->recv;
    undef $timer;

}

note
$t->admin(q[ box.schema.user.grant('user1', 'read,write,execute', 'universe') ]);

for my $cv (AE::cv) {
    $cv->begin;
    $tnt->auth('user1', 'password1', sub {
        my ($r) = @_;
        isa_ok $r => 'HASH', 'auth response';
        ok exists $r->{CODE}, 'exists code';
        ok exists $r->{SYNC}, 'exists sync';
        ok !exists $r->{ERROR}, "existn't error";
        $cv->end;
    });

    my $timer;
    $timer = AE::timer 1.5, 0, sub { $cv->end };
    $cv->recv;
    undef $timer;

}

note 'call again';

for my $cv (AE::cv) {
    $cv->begin;
    $tnt->call_lua('box.session.id', [], sub {
        my ($r) = @_;
        isa_ok $r => 'HASH', 'call response';
        ok exists $r->{CODE}, 'exists code';
        ok exists $r->{SYNC}, 'exists sync';
        ok !exists $r->{ERROR}, 'exists not error';
        isa_ok $r->{DATA} => 'ARRAY', 'extsts data';
        is scalar @{ $r->{DATA} }, 1, 'count of tuples';
        cmp_ok $r->{DATA}[0], '>', 0, 'box.session.id';

        $cv->end;
    });

    my $timer;
    $timer = AE::timer 1.5, 0, sub { $cv->end };
    $cv->recv;
    undef $timer;

}

my $sid;
for my $cv (AE::cv) {
    $cv->begin;
    $tnt->call_lua('box.session.id', sub {
        my ($r) = @_;
        isa_ok $r => 'HASH', 'call response';
        ok exists $r->{CODE}, 'exists code';
        ok exists $r->{SYNC}, 'exists sync';
        ok !exists $r->{ERROR}, 'exists not error';
        isa_ok $r->{DATA} => 'ARRAY', 'extsts data';
        is scalar @{ $r->{DATA} }, 1, 'count of tuples';
        cmp_ok $r->{DATA}[0], '>', 0, 'box.session.id';
        $sid = $r->{DATA}[0];

        $cv->end;
    });

    my $timer;
    $timer = AE::timer 1.5, 0, sub { $cv->end };
    $cv->recv;
    undef $timer;

}

note 'autologin';
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns => $_[0] };

    for my $cv (AE::cv) {
        my $tnt;
        $cv->begin;
        DR::Tarantool::MsgPack::LLClient->connect(
            host        => '127.0.0.1',
            port        => $t->primary_port,
            user        => 'user1',
            password    => 'password2',
            cb      => sub {
                ($tnt) = @_;
                ok $tnt, 'connect callback';
                $cv->end;
            }

        );
       
        my $timer;
        $timer = AE::timer 1.5, 0, sub { $cv->end };
        $cv->recv;
        undef $timer;
        ok $tnt => 'connector was saved';
    }
    is scalar @warns, 1, 'One warning';
    like $warns[0] => qr{Incorrect password}, 'text of warning';
}

for my $cv (AE::cv) {
    my $tnt;
    $cv->begin;
    DR::Tarantool::MsgPack::LLClient->connect(
        host        => '127.0.0.1',
        port        => $t->primary_port,
        user        => 'user1',
        password    => 'password1',
        cb      => sub {
            ($tnt) = @_;
            ok $tnt, 'connect callback';
            $cv->end;
        }

    );
   
    my $timer;
    $timer = AE::timer 1.5, 0, sub { $cv->end };
    $cv->recv;
    undef $timer;

    ok $tnt => 'connector was saved';

    for my $cv (AE::cv) {
        $cv->begin;
        $tnt->call_lua('box.session.id', sub {
            my ($r) = @_;
            isa_ok $r => 'HASH', 'call response';
            ok exists $r->{CODE}, 'exists code';
            ok exists $r->{SYNC}, 'exists sync';
            ok !exists $r->{ERROR}, 'exists not error';
            isa_ok $r->{DATA} => 'ARRAY', 'extsts data';
            is scalar @{ $r->{DATA} }, 1, 'count of tuples';
            cmp_ok $r->{DATA}[0], '>', 0, 'box.session.id';
            isnt $r->{DATA}[0], $sid, 'the other session.id';
            $cv->end;
        });

        my $timer;
        $timer = AE::timer 1.5, 0, sub { $cv->end };
        $cv->recv;
        undef $timer;
    }
}

{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns => $_[0] };

    for my $cv (AE::cv) {
        my $tnt;
        $cv->begin;
        DR::Tarantool::MsgPack::LLClient->connect(
            host        => '127.0.0.1',
            port        => $t->primary_port,
            user        => 'user1',
            password    => 'password2',
            reconnect_period => 1,
            reconnect_always => 1,
            cb      => sub {
                ($tnt) = @_;
                ok $tnt, 'connect callback';
                $cv->end;
            }

        );
       
        my $timer;
        $timer = AE::timer 1.5, 0, sub { $cv->end };
        $cv->recv;
        undef $timer;
    }
    is scalar @warns, 1, 'One warning';
    like $warns[0] => qr{Incorrect password}, 'text of warning';
}

note 'select';

$t->admin(q[box.schema.create_space('test', { id = 7 }).n]);
$t->admin(q[box.space.test:create_index('pk', { type = 'tree' })]);
$t->admin(q[box.space.test:insert({1,2,3})]);
$t->admin(q[box.space.test:insert({2,2,3})]);


{
    for my $cv (AE::cv) {
        $cv->begin;
        $tnt->select(6, 0, 1, sub {
            my ($res) = @_;
            isa_ok $res => 'HASH', 'select response';
            ok $res->{CODE}, 'code != 0';
            like $res->{ERROR} => qr{Space '\#\d+' does not exist}, 'error str';
            $cv->end;
        });
        
        $cv->begin;
        $tnt->select(7, 0, 1, sub {
            my ($res) = @_;
            isa_ok $res => 'HASH', 'select response';
            is $res->{CODE}, 0, 'code == 0';
            is_deeply $res->{DATA}, [[1, 2, 3]], 'tuple';
            $cv->end;
        });
        
        $cv->begin;
        $tnt->select(7, 0, 2, sub {
            my ($res) = @_;
            isa_ok $res => 'HASH', 'select response';
            is $res->{CODE}, 0, 'code == 0';
            is_deeply $res->{DATA}, [[2, 2, 3]], 'tuple';
            $cv->end;
        });
        
        $cv->begin;
        $tnt->select('test', 'pk', [1], 3, 0, 'GT', sub {
            my ($res) = @_;
            isa_ok $res => 'HASH', 'select response';
            is $res->{CODE}, 0, 'code == 0';
            is_deeply $res->{DATA}, [[2, 2, 3]], 'tuple';
            $cv->end;
        });
        
        $cv->begin;
        $tnt->select(7, 0, 3, sub {
            my ($res) = @_;
            isa_ok $res => 'HASH', 'select response';
            is $res->{CODE}, 0, 'code == 0';
            is_deeply $res->{DATA}, [], 'tuple';
            $cv->end;
        });
        
        $cv->begin;
        $tnt->select(7, 11, 1, sub {
            my ($res) = @_;
            isa_ok $res => 'HASH', 'select response';
            ok $res->{CODE}, 'code != 0';
            like $res->{ERROR} => qr{No index.*is defined in space 'test'},
                'error str';
            $cv->end;
        });

        my $timer;
        $timer = AE::timer 1.5, 0, sub { $cv->end };
        $cv->recv;
        undef $timer;
    }
}

note 'insert';
for my $cv (AE::cv) {
    $cv->begin;
    $tnt->insert(6, [ 3, 4, 5 ], sub {
        my ($res) = shift;
        isa_ok $res => 'HASH';
        ok $res->{CODE}, 'CODE is not 0';
        like $res->{ERROR} => qr{Space '\#6' does not exist}, 'error message';

        $cv->end;
    });


    $cv->begin;
    $tnt->insert(7, [ 3, 4, 5 ], sub {
        my ($res) = shift;
        isa_ok $res => 'HASH';
        is_deeply $res->{DATA} => [[3, 4, 5]], 'tuple was inserted';
        is $res->{CODE}, 0, 'code';
        is $res->{status}, 'ok', 'status';
        $cv->end;
    });
    
    $cv->begin;
    $tnt->insert(7, [ 1, 2, 3 ], sub {
        my ($res) = shift;
        isa_ok $res => 'HASH';
        ok $res->{CODE}, 'code';
        like $res->{ERROR} => qr{Duplicate key}, 'error message';
        is $res->{status}, 'error', 'status';
        $cv->end;
    });

    my $timer;
    $timer = AE::timer 1.5, 0, sub { $cv->end };
    $cv->recv;
    undef $timer;
}

note 'replace';
for my $cv (AE::cv) {
    $cv->begin;
    $tnt->replace(6, [ 3, 4, 5 ], sub {
        my ($res) = shift;
        isa_ok $res => 'HASH';
        ok $res->{CODE}, 'CODE is not 0';
        like $res->{ERROR} => qr{Space '\#6' does not exist}, 'error message';

        $cv->end;
    });


    $cv->begin;
    $tnt->replace(7, [ 4, 5 ], sub {
        my ($res) = shift;
        isa_ok $res => 'HASH';
        is_deeply $res->{DATA} => [[4, 5]], 'tuple was inserted';
        is $res->{CODE}, 0, 'code';
        is $res->{status}, 'ok', 'status';
        $cv->end;
    });
    
    $cv->begin;
    $tnt->replace(7, [ 1, 4, 5 ], sub {
        my ($res) = shift;
        isa_ok $res => 'HASH';
        is_deeply $res->{DATA} => [[1, 4, 5]], 'tuple was replaced';
        is $res->{CODE}, 0, 'code';
        is $res->{status}, 'ok', 'status';
        $cv->end;
    });

    my $timer;
    $timer = AE::timer 1.5, 0, sub { $cv->end };
    $cv->recv;
    undef $timer;
}

note 'delete';
for my $cv (AE::cv) {
    $cv->begin;
    $tnt->delete(6, [ 3 ], sub {
        my ($res) = shift;
        isa_ok $res => 'HASH';
        ok $res->{CODE}, 'CODE is not 0';
        like $res->{ERROR} => qr{Space '\#6' does not exist}, 'error message';

        $cv->end;
    });



    $cv->begin;
    $tnt->delete(7, 55, sub {
        my ($res) = shift;
        isa_ok $res => 'HASH';
        is_deeply $res->{DATA} => [], 'tuple was not found';
        is $res->{CODE}, 0, 'code';
        is $res->{status}, 'ok', 'status';
        $cv->end;
    });
    
    $cv->begin;
    $tnt->select(7, 0, 4, sub {
        my ($res) = @_;
        is_deeply $res->{DATA} => [[4,5]], 'tuple exists';

        $tnt->delete(7, [4], sub {
            my ($res) = shift;
            isa_ok $res => 'HASH';
            is_deeply $res->{DATA} => [[4,5]], 'tuple was removed';
            is $res->{CODE}, 0, 'code';
            is $res->{status}, 'ok', 'status';

            $tnt->select(7, 0, 4, sub {
                my ($res) = @_;
                is_deeply $res->{DATA} => [], 'tuple was removed really';
                $cv->end;
            });

        });
    });

    my $timer;
    $timer = AE::timer 1.5, 0, sub { $cv->end };
    $cv->recv;
    undef $timer;
}


note 'update';
for my $cv (AE::cv) {
    $cv->begin;
    $tnt->update(6, 1, [ ], sub {
        my ($res) = shift;
        isa_ok $res => 'HASH';
        ok $res->{CODE}, 'CODE is not 0';
        like $res->{ERROR} => qr{Space '\#6' does not exist}, 'error message';

        $cv->end;
    });



    $cv->begin;
    $tnt->update(7, 55, [['+', 1, 1]], sub {
        my ($res) = shift;
        isa_ok $res => 'HASH';
        is_deeply $res->{DATA} => [], 'tuple was not found';
        is $res->{CODE}, 0, 'code';
        is $res->{status}, 'ok', 'status';
        $cv->end;
    });

    $cv->begin;
    $tnt->select(7, 0, 1, sub {
        my ($res) = @_;
        is_deeply $res->{DATA}, [[1,4,5]], 'data in db';
        $tnt->update(7, 1, [['+', 1, 1], ['-', 2, 1], ['-', 2, 2]], sub {
            my ($res) = @_;
            ok $res->{CODE}, 'code != 0';
            like $res->{ERROR} => qr{double update of the same field},
                'error msg';
            $cv->end;
        });

    });

    $cv->begin;
    $tnt->update(7, 1, [['+', 1, 1], ['-', 2, 3]], sub {
        my ($res) = @_;
        is_deeply $res->{DATA}, [[1,5,2]], 'data after update';
        $cv->end;
    });

    my $timer;
    $timer = AE::timer 1.5, 0, sub { $cv->end };
    $cv->recv;
    undef $timer;
}
