#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 10;
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
        driver              => 'sync',
        host                => 'localhost',
        port                => $ti->port,
        user                => 'testrwe',
        password            => 'test123',
        lua_dir             => 't/040-full/lua/start',
        logger              => \&LOGGER,
    ;
    isa_ok $c => DR::Tnt::FullCb::, 'connector created';

    $c->request(ping => sub {
        is $_[0], 'ER_BROKEN_PASSWORD', 'ping no done';
    });
}

for (+note 'reconnect_interval is defined') {
    my $c = new DR::Tnt::FullCb
        driver              => 'sync',
        host                => 'localhost',
        port                => $ti->port,
        user                => 'testrwe',
        password            => 'test123',
        lua_dir             => 't/040-full/lua/start',
        logger              => \&LOGGER,
        reconnect_interval  => .1
    ;
    isa_ok $c => DR::Tnt::FullCb::, 'connector created';


    eval {
        alarm 1;
        $SIG{ALRM} = sub { die "alarm\n"; };
        $c->request(ping => sub {
            fail 'ping not reply';
        });
    };

    like $@ => qr{alarm}, 'timeout reached';
}


