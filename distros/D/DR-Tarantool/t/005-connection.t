#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 56;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Tarantool::AEConnection';
    use_ok 'AnyEvent::Socket';
    use_ok 'AnyEvent';
    use_ok 'DR::Tarantool::StartTest';
}

my $port = DR::Tarantool::StartTest::_find_free_port;
ok $port => 'Port is generated ' . $port // 'undef';
my $fh;

note 'connfail';
for my $cv (AE::cv) {
    $cv->begin;

    my $c = DR::Tarantool::AEConnection->new(port => $port);
    isa_ok $c => 'DR::Tarantool::AEConnection';
    is $c->state, 'init', 'state';

    $c->on(connfail => sub {
        my ($self) = @_;
        isa_ok $self => 'DR::Tarantool::AEConnection';
        is $self->state, 'connfail', 'error';
        is $self->errno, 'ECONNREFUSED', 'errno';
        $cv->end;
    });

    $c->connect();

    $cv->recv;

}

note 'connfail timeout';
for my $cv (AE::cv) {
    $cv->begin;

    my $c = DR::Tarantool::AEConnection->new(port => $port, timeout => 0);
    isa_ok $c => 'DR::Tarantool::AEConnection';
    is $c->state, 'init', 'state';

    $c->on(connfail => sub {
        my ($self) = @_;
        isa_ok $self => 'DR::Tarantool::AEConnection';
        is $self->state, 'connfail', 'error';
        is $self->errno, 'ETIMEOUT', 'errno';
        $cv->end;
    });

    $c->connect();

    $cv->recv;

}

note 'reconnect_always';
for my $cv (AE::cv) {
    $cv->begin for 1 .. 10;

    my $c = DR::Tarantool::AEConnection->new(
        port => $port,
        reconnect_always => 1,
        reconnect_period => .1
    );
    
    isa_ok $c => 'DR::Tarantool::AEConnection';
    is $c->state, 'init', 'state';

    $c->on(connfail => sub {
        my ($self) = @_;
        isa_ok $self => 'DR::Tarantool::AEConnection';
        is $self->state, 'connfail', 'error';
        $cv->end;
    });

    $c->connect();

    $cv->recv;
}

note 'reconnect_period';
for my $cv (AE::cv) {
    $cv->begin for 1 .. 2;

    my $c = DR::Tarantool::AEConnection->new(
        port => $port,
        reconnect_period => .1,
    );
    
    isa_ok $c => 'DR::Tarantool::AEConnection';
    is $c->state, 'init', 'state';

    my $cnt = 0;

    my $tmr;
    $c->on(connfail => sub {
        my ($self) = @_;
        isa_ok $self => 'DR::Tarantool::AEConnection';
        is $self->state, 'connfail', 'error';
        undef $tmr unless
            is $cnt, 0, 'only one connfail';
        $cnt++;
        $cv->end;
    });

    $c->connect();


    $tmr = AE::timer .6, 0, sub {
        ok $tmr => 'timeout exceeded';
        $cv->end;
    };


    $cv->recv;
}


note 'test server';
my $server;
for my $cv (AE::cv) {
    $cv->begin;
    $server = tcp_server undef, $port,
        sub {
            syswrite $_[0], 'Hello, world';
        },
        sub {
            ok $_[0] => 'server is created';
            $cv->end;
        }
    ;
    $cv->recv;
}

for my $cv (AE::cv) {
    $cv->begin;

    my $c = DR::Tarantool::AEConnection->new(port => $port);
    isa_ok $c => 'DR::Tarantool::AEConnection';
    is $c->state, 'init', 'state';

    $c->on(connected => sub {
        my ($self) = @_;
        is $self->state, 'connected', 'connected';

        {
            $cv->begin;
            my $io;
            $io = AE::io $self->fh, 0, sub {
                undef $io;
                sysread $self->fh, my $str, 4096;
                is $str => 'Hello, world', 'data received';
                $cv->end;
            };

        }

        $cv->end;
    });

    $c->on(connfail => sub {
        my ($self) = @_;
        fail 'Connet to server';
        $cv->end;
    });

    
    $c->connect();

    $cv->recv;
}

note 'read, set_error, reconnecting';
for my $cv (AE::cv) {
    $cv->begin;
    $cv->begin; # twice

    my $c = DR::Tarantool::AEConnection->new(port => $port,
        reconnect_period => .1);
    isa_ok $c => 'DR::Tarantool::AEConnection';
    is $c->state, 'init', 'state';

    my $count = 0;

    $c->on(connected => sub {
        my ($self) = @_;
        is $self->state, 'connected', 'connected';

        {
            $cv->begin;
            my $io;
            $io = AE::io $self->fh, 0, sub {
                undef $io;
                sysread $self->fh, my $str, 4096;
                is $str => 'Hello, world', 'data received';

                $self->set_error('User error');
                cmp_ok $count, '<', 2, 'reconnects';
                $count++;
                $cv->end;
            };

        }

        $cv->end;
    });

    $c->on(connfail => sub {
        my ($self) = @_;
        fail 'Connet to server';
        $cv->end;
    });

    
    $c->connect();

    $cv->recv;
}

