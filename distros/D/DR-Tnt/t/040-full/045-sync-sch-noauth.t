#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 11;
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

    $c->request(ping => sub {
        is $_[0] => 'OK', 'ping';

        isnt scalar(keys %{ $c->_sch }), 0, 'sch is not empty';
    });

}

