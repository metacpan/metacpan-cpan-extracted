#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 17;
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


for (+note 'lua_dir is present') {
    my $c = new DR::Tnt::FullCb
        driver          => 'async',
        host            => 'localhost',
        port            => $ti->port,
        user            => 'testrwe',
        password        => 'test',
        connector_class => 'DR::Tnt::LowLevel::Connector::AE',
        lua_dir         => 't/040-full/lua/start',
        logger          => \&LOGGER,
        hashify_tuples  => 1,
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
    
    for my $cv (AE::cv) {
        $cv->begin;
        $c->request(select => '_space', 'primary', 280, sub {
            is $_[0], 'OK', 'status';
            isa_ok $_[2] => 'ARRAY', 'Array of tuples';
            my $tuple = $_[2][0];
            isa_ok $tuple => 'HASH', 'Tuple is a hash';

            is $tuple->{id} => 280, 'space id';
            is $tuple->{name}, '_space', 'name';

            $cv->end;
        });
        $cv->recv;
    }
}


