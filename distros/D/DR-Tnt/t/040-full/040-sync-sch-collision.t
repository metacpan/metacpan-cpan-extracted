#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 24;
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
        driver          => 'sync',
        host            => 'localhost',
        port            => $ti->port,
        user            => 'testrwe',
        password        => 'test',
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

}
for (+note 'lua_dir is present') {
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

    $c->_set_last_schema($c->last_schema - 10);

    $c->request(select => '_space', 'primary', 280, sub {
        is $_[0], 'OK', 'status';
        is_deeply [ @{ $_[2][0] }[0,2] ], [ 280, '_space'], 'response';
    });

    like $log, qr{Detected schema collision}, 'Detected schema collision';

    $c->request(select => '_space', 'primary1', 280, sub {
        is $_[0], 'ER_NOINDEX', 'status';
    });

    $c->request(select => '_spacei1', 'primary', 280, sub {
        is $_[0], 'ER_NOSPACE', 'status';
    });

    $c->request('select', '_vspace', 'primary', 281, sub {
        is $_[0], 'OK', 'status';
    });


    my $schema_id = $c->last_schema;
    $log = '';
    $c->request(call_lua => 'box.session.storage.create_space', 'test_space', sub {
        diag explain \@_ unless
            is $_[0] => 'OK', 'space created';

        SKIP: {
            skip 'see https://github.com/tarantool/tarantool/issues/1959', 1;
            isnt $c->last_schema, $schema_id, 'schema_id was changed';
        }

    });

    $c->request(ping => sub {
        diag explain \@_ unless
            is $_[0] => 'OK', 'ping';
        isnt $c->last_schema, $schema_id, 'schemaid was changed';
    });

}

