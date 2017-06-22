#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 31;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt::FullCb';
    use_ok 'DR::Tnt::Test';
    use_ok 'AE';
    use_ok 'POSIX';
    tarantool_version_check(1.6);
}

my $ti = start_tarantool
    -lua    => 't/040-full/lua/easy.lua';
isa_ok $ti => DR::Tnt::Test::TntInstance::, 'tarantool';

diag $ti->log unless
    ok $ti->is_started, 'test tarantool started';


sub LOGGER {
    my ($level, $message) = @_;
    return unless $ENV{DEBUG};
    my $now = POSIX::strftime '%F %T', localtime;
    note "$now [$level] $message";
}

for (+note 'reconnect_interval is undefined') {
    my $c = new DR::Tnt::FullCb
        driver          => 'sync',
        host            => 'localhost',
        port            => $ti->port,
        user            => 'testrwe',
        password        => 'test',
        lua_dir         => 't/040-full/lua/start',
        logger          => \&LOGGER,
    ;
    isa_ok $c => DR::Tnt::FullCb::, 'connector created';

        
    $c->restart(
        sub {
            my ($code, $message, @args) = @_;
            return unless is $code, 'OK', 'connected';
            is $c->state, 'ready', 'state';
        }
    );

    $c->request(call_lua => 'box.session.storage.rettest', 1, sub {
        is $_[0], 'OK', 'status';
        is_deeply $_[2], [[ test => 2 ] ], 'response';
    });

    $ti->stop;
    $ti->start;
    note 'Tarantool was restarted';
    
    $c->request(select => '_space', 'primary', 280, sub {
        is $_[0], 'ER_SOCKET', 'status';
        is $c->state, 'pause', 'connector is paused';
    });
    
    $c->request(select => '_space', 'primary', 280, sub {
        is $_[0], 'ER_SOCKET', 'status';
        is $c->state, 'pause', 'connector is not ready (reconnect_interval is null)';
    });
}

for (+note 'reconnect_interval is defined') {
    my $c = new DR::Tnt::FullCb
        driver              => 'sync',
        host                => 'localhost',
        port                => $ti->port,
        user                => 'testrwe',
        password            => 'test',
        connector_class     => 'DR::Tnt::LowLevel::Connector::AE',
        lua_dir             => 't/040-full/lua/start',
        logger              => \&LOGGER,
        reconnect_interval  => 0.1,
    ;
    isa_ok $c => DR::Tnt::FullCb::, 'connector created';

    $c->restart(
        sub {
            my ($code, $message, @args) = @_;
            return unless is $code, 'OK', 'connected';
            is $c->state, 'ready', 'state';
        }
    );

    $c->request(call_lua => 'box.session.storage.rettest', 1, sub {
        is $_[0], 'OK', 'status';
        is_deeply $_[2], [[ test => 2 ] ], 'response';
    });

    $ti->stop;
    $ti->start;
    note 'Tarantool was restarted';
    
    $c->request(select => '_space', 'primary', 280, sub {
        is $_[0], 'ER_SOCKET', 'status';
        is $c->state, 'pause', 'connector is paused';
    });

    $c->request(select => '_space', 'primary', 280, sub {
        is $_[0], 'OK', 'status';
        is $c->state, 'ready', 'connector is not ready';

        is_deeply [@{ $_[2][0] }[0,2]], [280, '_space'], 'response';
    });
}

for (+note 'Connect before server started') {
    my $started = Time::HiRes::time;
    my $tip = start_tarantool
        -lua        => 't/040-full/lua/start-pause.lua';
    isa_ok $tip => DR::Tnt::Test::TntInstance::, 'tarantool';

    my $c = new DR::Tnt::FullCb
        driver              => 'sync',
        host                => 'localhost',
        port                => $tip->port,
        user                => 'testrwe',
        password            => 'test',
        lua_dir             => 't/040-full/lua/start',
        logger              => \&LOGGER,
        reconnect_interval  => .1
    ;
    isa_ok $c => DR::Tnt::FullCb::, 'connector created';

    $c->request(ping => sub {
        is $_[0], 'OK', 'ping done';
    });
    
    like $tip->log, qr{entering the event loop}, 'tarantool was really started';
    cmp_ok Time::HiRes::time - $started, '>=', 0.7, 'pause lo';
    cmp_ok Time::HiRes::time - $started, '<=', 1.5, 'pause hi';
}
