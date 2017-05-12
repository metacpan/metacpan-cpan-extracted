#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 93;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt::LowLevel';
    use_ok 'DR::Tnt::LowLevel::Connector::AE';

    use_ok 'DR::Tnt::Test';
    use_ok 'AE';
    tarantool_version_check(1.6);
}

my $ti = start_tarantool
    -lua    => 't/030-low-level/lua/easy.lua';
isa_ok $ti => DR::Tnt::Test::TntInstance::, 'tarantool';

diag $ti->log unless
    ok $ti->is_started, 'test tarantool started';

my $c = new DR::Tnt::LowLevel
    host                => 'localhost',
    port                => $ti->port,
    user                => 'testrwe',
    password            => 'test',
    connector_class     => 'DR::Tnt::LowLevel::Connector::AE',
;
isa_ok $c => DR::Tnt::LowLevel::, 'Low level connector';
is $c->connector_class, 'DR::Tnt::LowLevel::Connector::AE', 'connector_class';
isa_ok $c->connector, DR::Tnt::LowLevel::Connector::AE::, 'connector';

sub ping_test($$;$) {
    my ($c, $cv,$sync_should) = @_;
    $cv->begin;
    $c->send_request(ping => sub {
       my ($code, $message, $sync) = @_;
        is $code, 'OK', 'ping was ready';
        is $c->connector->state, 'ready', 'state';
        is $sync, $sync_should, 'sync should be ' . $sync_should
            if $sync_should;
        ok exists $c->connector->_active_sync->{$sync}, 'active sync';
        $c->wait_response($sync, sub {
            my ($code, $message, $resp) = @_;
            is $code => 'OK', 'ping response';
            isa_ok $resp => 'HASH';
            is $resp->{SYNC}, $sync, 'sync';
            is $resp->{CODE}, 0, 'code';
            like $resp->{SCHEMA_ID}, qr{^\d+$}, 'schema_id';
            $cv->end;
        });
    });
}

for my $cv (AE::cv) {
    note 'connect test';

    ping_test $c => $cv, 1;

    $cv->begin;
    $c->connect(
        sub {
            my ($code, $message, @args) = @_;
            return unless is $code, 'OK', 'connected';
            is $c->connector->state, 'connected', 'state';
            ok $c->connector->fh, 'fh';
            $c->handshake(
                sub {
                    my ($code, $message, @args) = @_;
                    return unless is $code, 'OK', 'handshake is read';
                    is $c->connector->state, 'ready', 'state';
                    ok $c->connector->fh, 'fh';
                    $cv->end;
                }
            );
        }
    );
    $cv->recv;
}

for my $cv (AE::cv) {
    ping_test $c => $cv;
    $cv->recv;
}

for my $cv (AE::cv) {
    $cv->begin;
    note 'auth test';
    $c->send_request(auth => undef, sub {
        my ($code, $message, $sync) = @_;
        is $code, 'OK', "auth was sent";
        is $c->connector->state, 'ready', 'state';
        isnt $sync, 1, 'next_sync';
        ok exists $c->connector->_active_sync->{$sync}, 'active sync';

        $c->wait_response($sync, sub {
            my ($code, $message, $resp) = @_;
            is $code => 'OK', 'auth response';

            isa_ok $resp => 'HASH';
            is $resp->{SYNC}, $sync, 'sync';
            is $resp->{CODE}, 0, 'auth passed';
            like $resp->{SCHEMA_ID}, qr{^\d+$}, 'schema_id';

            $cv->end;
        });
    });
    $cv->recv;
}

for my $cv (AE::cv) {
    $cv->begin;
    note 'lua test';
    my $started = AnyEvent::now();
    $c->send_request(call_lua => undef, sleep => 0.3, sub {
        my ($code, $message, $sync) = @_;
        is $code, 'OK', "lua call was sent";
        is $c->connector->state, 'ready', 'state';
        isnt $sync, 1, 'next_sync';
        ok exists $c->connector->_active_sync->{$sync}, 'active sync';

        $c->wait_response($sync, sub {
            my ($code, $message, $resp) = @_;
            is $code => 'OK', 'auth response';

            isa_ok $resp => 'HASH';
            is $resp->{SYNC}, $sync, 'sync';
            is $resp->{CODE}, 0, 'call passed';
            like $resp->{SCHEMA_ID}, qr{^\d+$}, 'schema_id';

            my $now = AnyEvent::now();
            cmp_ok $now - $started, '>=', 0.3, 'sleep more than 0.3';
            cmp_ok $now - $started, '<', 0.4, 'sleep less than 0.4';
            $cv->end;
        });
    });
    $cv->recv;
}

$ti->stop;
$ti->start;

for my $cv (AE::cv) {
    note 'ping server';
    $cv->begin;
    my $timer;
    $timer = AE::timer 2, 0, sub {
        fail 'timeout reached';
        diag $ti->log;
        $cv->end;
    };

    $c->send_request(ping => sub {
       my ($code, $message, $sync) = @_;
        is $code, 'OK', 'ping was send';
        is $c->connector->state, 'ready', 'state';
        ok exists $c->connector->_active_sync->{$sync}, 'active sync';
        $c->wait_response($sync, sub {
            my ($code, $message, $resp) = @_;
            is $code => 'ER_SOCKET', 'ping response (error)';
            $cv->end;
        });
    });
    $cv->recv;
    undef $timer;

    is $c->connector->state, 'error', 'connector is error';
}

for my $cv (AE::cv) {
    $cv->begin;
    $c->send_request(ping => sub {
       my ($code, $message) = @_;
        is $code, 'ER_SOCKET', 'ping was not send (ping error)';
        is $c->connector->state, 'error', 'state';
        $cv->end;
    });
    $cv->recv;
}

for my $cv (AE::cv) {
    note 'RE-connect test';

    $cv->begin;
    $c->connect(
        sub {
            my ($code, $message, @args) = @_;
            return unless is $code, 'OK', 'connected';
            is $c->connector->state, 'connected', 'state';
            ok $c->connector->fh, 'fh';
            ping_test $c, $cv;
            $c->handshake(
                sub {
                    my ($code, $message, @args) = @_;
                    return unless is $code, 'OK', 'handshake is read';
                    is $c->connector->state, 'ready', 'state';
                    ok $c->connector->fh, 'fh';
                    $cv->end;
                }
            );
        }
    );
    
    
    is $c->connector->state, 'connecting', 'connectin again';
    ping_test $c, $cv;
    
    $cv->recv;
}


##############################################################################
$ti->stop;
$c = new DR::Tnt::LowLevel
    host                => 'localhost',
    port                => $ti->port,
    user                => 'testrwe',
    password            => 'test',
    connector_class     => 'DR::Tnt::LowLevel::Connector::AE',
;
isa_ok $c => DR::Tnt::LowLevel::, 'Low level connector';
is $c->connector_class, 'DR::Tnt::LowLevel::Connector::AE', 'connector_class';
isa_ok $c->connector, DR::Tnt::LowLevel::Connector::AE::, 'connector';

for my $cv (AE::cv) {
    note 'connect to closed port';

    $cv->begin;
    $c->send_request(ping => sub {
       my ($code, $message, $sync) = @_;
        is $code, 'ER_CONNECT', 'ping before connect was send';
        is $c->connector->state, 'error', 'state';
        $cv->end;
    });

    $cv->begin;
    $c->connect(
        sub {
            my ($code, $message, @args) = @_;
            return unless is $code, 'ER_CONNECT', 'connected';
            is $c->connector->state, 'error', 'state';
            ok !$c->connector->fh, 'fh';
            $c->handshake(
                sub {
                    my ($code, $message, @args) = @_;
                    return unless is $code, 'ER_CONNECT', 'handshake is not read';
                    is $c->connector->state, 'error', 'state';
                    ok !$c->connector->fh, 'fh';
                    $cv->end;
                }
            );
            
        }
    );
    $cv->recv;
}
