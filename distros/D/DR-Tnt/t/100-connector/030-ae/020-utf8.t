#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 15;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt';
    use_ok 'DR::Tnt::Test';
    use_ok 'AnyEvent';
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
                driver          => 'ae',
                utf8            => 1,
;
isa_ok $tntu => 'DR::Tnt::Client::AE', 'connector created';

for my $cv (AE::cv) {
    $cv->begin;
    $tntu->ping(sub {
        my ($v) = @_;
        ok $v => 'ping ok';
        $cv->end;
    });


    $cv->begin;
    $tntu->insert(test => [ 'Вася', 'Пупкин' ], sub {
        my ($t) = @_;
        isa_ok $t => 'HASH', 'inserted';
        is $t->{name} => 'Вася', 'name';
        is $t->{value} => 'Пупкин', 'value';
        $cv->end;
    });

    $cv->recv;

}
my $tntnu = tarantool
                host    => 'localhost',
                port    => $ti->port,
                user            => 'testrwe',
                password        => 'test',
                logger          => \&LOGGER,
                hashify_tuples  => 1,
                driver          => 'ae',
                utf8            => 0,
;

isa_ok $tntnu => 'DR::Tnt::Client::AE', 'connector created';
for my $cv (AE::cv) {
    $cv->begin;
    $tntnu->ping(sub {
        my ($v) = @_;
        ok $v => 'ping ok';
        $cv->end;
    });


    $cv->begin;
    $tntnu->get(test => 'name', [ 'Вася' ], sub {
        my ($t) = @_;
        isa_ok $t => 'HASH', 'inserted';
        is $t->{name} => encode(utf8 => 'Вася'), 'name';
        is $t->{value} => encode(utf8 => 'Пупкин'), 'value';
        $cv->end;
    });

    $cv->recv;
}
