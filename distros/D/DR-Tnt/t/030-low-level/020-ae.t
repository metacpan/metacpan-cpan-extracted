#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 43;
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
    host            => 'localhost',
    port            => $ti->port,
    user            => 'testrwe',
    password        => 'test',
    connector_class => 'DR::Tnt::LowLevel::Connector::AE',
;
isa_ok $c => DR::Tnt::LowLevel::, 'Low level connector';
is $c->connector_class, 'DR::Tnt::LowLevel::Connector::AE', 'connector_class';
isa_ok $c->connector, DR::Tnt::LowLevel::Connector::AE::, 'connector';

for my $cv (AE::cv) {
    $cv->begin;
    $c->connect(
        sub {
            my ($code, $message, @args) = @_;
            return unless is $code, 'OK', 'connected';
            is $c->connector->state, 'connected', 'state';
            ok $c->connector->fh, 'fh';
            $cv->end;
        }
    );
    $cv->recv;
}
for my $cv (AE::cv) {
    $cv->begin;
    is $c->connector->state, 'connected', 'connected';
    $c->handshake(
        sub {
            my ($code, $message, @args) = @_;
            return unless is $code, 'OK', 'handshake is read';
            is $c->connector->state, 'ready', 'state';
            ok $c->connector->fh, 'fh';
            $cv->end;
        }
    );
    $cv->recv;
}

for my $cv (AE::cv) {
    $cv->begin;
    $c->send_request(ping => sub {
       my ($code, $message, $sync) = @_;
        is $code, 'OK', 'ping was send';
        is $c->connector->state, 'ready', 'state';
        is $sync, 1, 'first request has sync = 1';
        ok exists $c->connector->_active_sync->{$sync}, 'active sync';
        $cv->end;
    });
    $cv->recv;
}


for my $cv (AE::cv) {
    $cv->begin;
    $c->wait_response(1, sub {
        my ($code, $message, $resp) = @_;
        is $code => 'OK', 'ping response';
        isa_ok $resp => 'HASH';
        is $resp->{SYNC}, 1, 'sync';
        is $resp->{CODE}, 0, 'code';
        like $resp->{SCHEMA_ID}, qr{^\d+$}, 'schema_id';
        $cv->end;
    });
    $cv->recv;
}


for my $cv (AE::cv) {
    for ('first auth', 'second auth') {
        $cv->begin;
        note $_ . ' test';
        $c->send_request(auth => undef, sub {
            my ($code, $message, $sync) = @_;
            is $code, 'OK', "$_ was send";
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
    }
    $cv->recv;
}

