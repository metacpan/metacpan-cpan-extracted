#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 346;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt::LowLevel';
    use_ok 'DR::Tnt::LowLevel::Connector::Sync';

    use_ok 'DR::Tnt::Test';
    tarantool_version_check(1.6);
}

my $ti = start_tarantool
    -lua    => 't/025-tnt-specific/lua/easy.lua';
isa_ok $ti => DR::Tnt::Test::TntInstance::, 'tarantool';

diag $ti->log unless
    ok $ti->is_started, 'test tarantool started';

my $c = new DR::Tnt::LowLevel
    host            => 'localhost',
    port            => $ti->port,
    user            => 'testrwe',
    password        => 'test',
    connector_class => 'DR::Tnt::LowLevel::Connector::Sync',
;
isa_ok $c => DR::Tnt::LowLevel::, 'Low level connector';
is $c->connector_class, 'DR::Tnt::LowLevel::Connector::Sync', 'connector_class';
isa_ok $c->connector, DR::Tnt::LowLevel::Connector::Sync::, 'connector';

$c->connect(
    sub {
        my ($code, $message, @args) = @_;
        return unless is $code, 'OK', 'connected';
        is $c->connector->state, 'connected', 'state';
        ok $c->connector->fh, 'fh';
    }
);

is $c->connector->state, 'connected', 'connected';
$c->handshake(
    sub {
        my ($code, $message, @args) = @_;
        return unless is $code, 'OK', 'handshake is read';
        is $c->connector->state, 'ready', 'state';
        ok $c->connector->fh, 'fh';
    }
);

$c->send_request(ping => sub {
   my ($code, $message, $sync) = @_;
    is $code, 'OK', 'ping was send';
    is $c->connector->state, 'ready', 'state';
    is $sync, 1, 'first request has sync = 1';
    ok exists $c->connector->_active_sync->{$sync}, 'active sync';
});


my $schema_id;
$c->wait_response(1, sub {
    my ($code, $message, $resp) = @_;
    is $code => 'OK', 'ping response';
    isa_ok $resp => 'HASH';
    is $resp->{SYNC}, 1, 'sync';
    is $resp->{CODE}, 0, 'code';
    like $resp->{SCHEMA_ID}, qr{^\d+$}, 'schema_id';
    $schema_id = $resp->{SCHEMA_ID};
});


my @requests = (
    [ 0,        'ping' ],
    [ 0x802F,   'auth', 'testrwe', '!test' ],

    [ 0,        'eval_lua', 'return true' ],
    [ 0,        'call_lua', 'box.space.testspace.index.pk:get', 'vasya' ],

    [ 0,        'delete', 1000, 'vasya' ],
    [ 0,        'insert', 1000, [ 'vasya', 'pupkin' ] ],
    [ 0,        'replace', 1000, [ 'vasya', 'pilulkin' ] ],
    [ 0,        'select', 1000, 0, 'vasya', 1, 0, 'EQ' ],
);


for ('UNAUTH', 'AUTH') {
    note "$_ variant";
    for my $r (@requests) {
        note "Testing schema collision for $r->[0]";

        my @r = @$r;

        my $await_code = shift @r;

        # normal schema
        splice @r, 1, 0, $schema_id;
        
        $c->send_request(@r, sub {
            my ($code, $message, $sync) = @_;
            is $code, 'OK', "@{[ uc $r[0] ]} [schema = $r[1]] was send";
            is $c->connector->state, 'ready', 'state';
            like $sync, qr{^\d+$}, 'sync';
            ok exists $c->connector->_active_sync->{$sync}, 'active sync';

            $c->wait_response($sync, sub {
                my ($code, $message, $resp) = @_;
                diag $message unless
                    is $code => 'OK', "{[ us $r[0] ]} response";
                isa_ok $resp => 'HASH';
                is $resp->{SYNC}, $sync, 'sync';
                diag explain $resp unless
                    is $resp->{CODE}, $await_code, 'code of schema error';
                is $resp->{SCHEMA_ID}, $schema_id, 'schema_id';
            });
        });


        # schema collision
        splice @r, 1, 1, $schema_id + 1;
        $c->send_request(@r, sub {
            my ($code, $message, $sync) = @_;
            is $code, 'OK', "@{[ uc $r[0] ]} [schema = $r[1]] was send";
            is $c->connector->state, 'ready', 'state';
            like $sync, qr{^\d+$}, 'sync';
            ok exists $c->connector->_active_sync->{$sync}, 'active sync';

            $c->wait_response($sync, sub {
                my ($code, $message, $resp) = @_;
                diag $message unless
                    is $code => 'OK', "{[ us $r[0] ]} response";
                isa_ok $resp => 'HASH';
                is $resp->{SYNC}, $sync, 'sync';
                diag explain $resp unless
                    isnt $resp->{CODE}, $await_code, 'not waited code';
                is $resp->{CODE}, 0x806D, 'Code of schema error';
                is $resp->{SCHEMA_ID}, $schema_id, 'schema_id';
            });
        });
    }


    note 'Try auth in tarantool';
    $c->send_request('auth', sub {
        my ($code, $message, $sync) = @_;
        is $code, 'OK', "auth was sent";
        is $c->connector->state, 'ready', 'state';
        like $sync, qr{^\d+$}, 'sync';
        ok exists $c->connector->_active_sync->{$sync}, 'active sync';

        $c->wait_response($sync, sub {
            my ($code, $message, $resp) = @_;
            diag $message unless
                is $code => 'OK', "auth response";
            isa_ok $resp => 'HASH';
            is $resp->{SYNC}, $sync, 'sync';
            is $resp->{CODE}, 0, 'result code: no errors';
            is $resp->{SCHEMA_ID}, $schema_id, 'schema_id';
        });
    });
}

