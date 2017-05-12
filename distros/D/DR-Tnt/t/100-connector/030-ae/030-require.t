#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 6;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt::Test';
    tarantool_version_check(1.6);
    require_ok 'DR::Tnt';
}

my $ti = start_tarantool
    -lua    => 't/100-connector/lua/easy.lua';
isa_ok $ti => DR::Tnt::Test::TntInstance::, 'tarantool';

diag $ti->log unless
    ok $ti->is_started, 'test tarantool started';

my $c = DR::Tnt::tarantool
            host            => 'localhost',
            port            => $ti->port,
            user            => 'testrwe',
            password        => 'test',
            hashify_tuples  => 1,
            driver          => 'ae',
;

isa_ok $c => 'DR::Tnt::Client::AE';



for my $cv (AnyEvent->condvar) {
    $cv->begin;
    $c->ping(sub {
        ok $_[0], 'ping';
        $cv->end;
    });

    $cv->recv;
}
