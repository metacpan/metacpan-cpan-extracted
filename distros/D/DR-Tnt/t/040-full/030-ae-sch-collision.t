#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 20;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt::FullCb';
    use_ok 'DR::Tnt::Test';
    use_ok 'AE';
    use_ok 'POSIX';
    tarantool_version_check(1.6);
}

my $log = '';

sub LOGGER {
    my ($level, $message) = @_;
    my $now = POSIX::strftime '%F %T', localtime;
    my $msg = "$now [$level] $message";
    note $msg if $ENV{DEBUG};
    $log .= $msg;
}

my $ti = start_tarantool
    -lua    => 't/040-full/lua/easy.lua';
isa_ok $ti => DR::Tnt::Test::TntInstance::, 'tarantool';

diag $ti->log unless
    ok $ti->is_started, 'test tarantool started';

for (+note 'easy connect') {
    my $c = new DR::Tnt::FullCb
        driver          => 'async',
        host            => 'localhost',
        port            => $ti->port,
        user            => 'testrwe',
        password        => 'test',
        logger          => \&LOGGER,
    ;
    isa_ok $c => DR::Tnt::FullCb::, 'connector created';

    for my $cv (AE::cv) {
        $cv->begin;
        $c->restart(
            sub {
                my ($code, $message, @args) = @_;
                return unless is $code, 'OK', 'connected';
                is $c->state, 'ready', 'state';
                $cv->end;
            }
        );

        my $timer;
        $timer = AE::timer 2, 0, sub {
            $cv->send;
            fail 'timeout is unreached';
            diag $ti->log;
        };

        $cv->recv;
        undef $timer;
    }
}

for (+note 'lua_dir is present') {
    my $c = new DR::Tnt::FullCb
        driver          => 'async',
        host            => 'localhost',
        port            => $ti->port,
        user            => 'testrwe',
        password        => 'test',
        lua_dir         => 't/040-full/lua/start',
        logger          => \&LOGGER,
    ;
    isa_ok $c => DR::Tnt::FullCb::, 'connector created';

    for my $cv (AE::cv) {
        $cv->begin;
        my $timer = AE::timer 0.5, 0, sub {
            pass 'pause done';
            $cv->end;
        };
        
        
        $cv->begin;
        $c->restart(
            sub {
                my ($code, $message, @args) = @_;
                return unless is $code, 'OK', 'connected';
                is $c->state, 'ready', 'state';
                $cv->end;
            }
        );
        $cv->recv;
    }

    for my $cv (AE::cv) {
        $cv->begin;
        $c->request(call_lua => 'box.session.storage.rettest', 1, sub {
            is $_[0], 'OK', 'status';
            is_deeply $_[2], [[ test => 2 ] ], 'response';
            $cv->end;
        });
        $cv->recv;
    }
    
    $c->_set_last_schema($c->last_schema - 1);
    
    for my $cv (AE::cv) {
        $cv->begin;
        $c->request(select => '_space', 'primary', 280, sub {
            is $_[0], 'OK', 'status';
            is_deeply [ @{ $_[2][0] }[0,2] ], [ 280, '_space'], 'response';

            $cv->end;
        });
        $cv->recv;
    }

    like $log => qr(Detected schema collision), 'Detected schema collision';
    
    for my $cv (AE::cv) {
        $cv->begin;
        $c->request(select => '_space', 'primary1', 280, sub {
            is $_[0], 'ER_NOINDEX', 'status';
            $cv->end;
        });
        $cv->recv;
    }

    for my $cv (AE::cv) {
        $cv->begin;
        $c->request(select => '_spacei1', 'primary', 280, sub {
            is $_[0], 'ER_NOSPACE', 'status';
            $cv->end;
        });
        $cv->recv;
    }
}

