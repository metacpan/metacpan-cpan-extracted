#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 14;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt';
    use_ok 'DR::Tnt::Test';
    tarantool_version_check(1.6);
}


my $ti = start_tarantool
    -lua    => 't/100-connector/lua/easy.lua';
isa_ok $ti => DR::Tnt::Test::TntInstance::, 'tarantool';

diag $ti->log unless
    ok $ti->is_started, 'test tarantool started';

sub LOGGER {
    my ($level, $message) = @_;
    return unless $ENV{DEBUG};
    my $now = POSIX::strftime '%F %T', localtime;
    note "$now [$level] $message";
}

my $tntu = tarantool
                host    => 'localhost',
                port    => $ti->port,
                user            => 'testrwe',
                password        => 'test',
                logger          => \&LOGGER,
                hashify_tuples  => 1,
                driver          => 'coro',
                utf8            => 1,
;

isa_ok $tntu => 'DR::Tnt::Client::Coro', 'connector created';
ok $tntu->ping, 'ping';
for my $t ($tntu->insert(test => [ 'Вася', 'Пупкин' ])) {
    isa_ok $t => 'HASH', 'inserted';
    is $t->{name} => 'Вася', 'name';
    is $t->{value} => 'Пупкин', 'value';
}

my $tntnu = tarantool
                host    => 'localhost',
                port    => $ti->port,
                user            => 'testrwe',
                password        => 'test',
                logger          => \&LOGGER,
                hashify_tuples  => 1,
                driver          => 'coro',
                utf8            => 0,
;

isa_ok $tntnu => 'DR::Tnt::Client::Coro', 'connector created';
ok $tntnu->ping, 'ping';
for my $t ($tntnu->get(test => 'name', [ 'Вася' ])) {
    isa_ok $t => 'HASH', 'got tuple';
    is $t->{name} => encode(utf8 => 'Вася'), 'name';
    is $t->{value} => encode(utf8 => 'Пупкин'), 'value';
}
