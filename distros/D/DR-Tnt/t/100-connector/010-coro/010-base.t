#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib t/lib);

use Test::More tests    => 35;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt::Client::Coro';
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

my $c = DR::Tnt::Client::Coro->new(
    host            => 'localhost',
    port            => $ti->port,
    user            => 'testrwe',
    password        => 'test',
    logger          => \&LOGGER,
    hashify_tuples  => 1,
);
isa_ok $c => DR::Tnt::Client::Coro::, 'connector created';
for (+note 'ping') {
    is $c->ping, 1, 'ping';
}

for (+note 'select and get') {
    for my $tuple ($c->get('_space', 'primary', 280)) {
        isa_ok $tuple => 'HASH', 'tuple received';
        is $tuple->{id}, 280, 'id';
        is $tuple->{name}, '_space', 'name';
    }
    
    for my $tuples ($c->select('_space', 'primary', 280)) {
        isa_ok $tuples => 'ARRAY', 'tuples received';
        is @$tuples, 1, 'one tuple';
        is $tuples->[0]{id}, 280, 'id';
        is $tuples->[0]{name}, '_space', 'name';
    }
}

for (+note 'insert') {
    my $tuple = $c->insert('test', [ 'ivan', 'petrov' ]);
    isa_ok $tuple => 'HASH', 'tuple inserted';
    is_deeply $tuple => { name => 'ivan', value => 'petrov', tail => [] },
        'tuple';
}


for (+note 'replace') {
    my $tuple = $c->replace('test', [ 'ivan', 'sidorov', 123 ]);
    isa_ok $tuple => 'HASH', 'tuple replaced';
    is_deeply $tuple => { name => 'ivan', value => 'sidorov', tail => [123] },
        'tuple';
    
    $tuple = $c->replace('test', [ 'vasya', 'sidorov' ]);
    isa_ok $tuple => 'HASH', 'tuple replaced';
    is_deeply $tuple => { name => 'vasya', value => 'sidorov', tail => [] },
        'tuple';
    
    for my $tuple ($c->get('test', 'name', 'vasya')) {
        isa_ok $tuple => 'HASH', 'tuple received';
        is_deeply $tuple => { name => 'vasya', value => 'sidorov', tail => [] },
            'tuple';
    }
}

for (+note 'update') {
    my $tuple = $c->update('test', 'ivan', [ [ '=', 1, 'ivanov' ] ]);
    isa_ok $tuple => 'HASH', 'tuple updated';
    is_deeply $tuple => { name => 'ivan', value => 'ivanov', tail => [123] },
        'tuple';
    
    for my $tuple ($c->get('test', 'name', 'ivan')) {
        isa_ok $tuple => 'HASH', 'tuple received';
        is_deeply $tuple => { name => 'ivan', value => 'ivanov', tail => [123] },
            'tuple';
    }
}


for (+note 'call_lua') {
    my $tuples = $c->call_lua('rettest');

    isa_ok $tuples => 'ARRAY', 'tuple returned';
    is_deeply $tuples => [[ 'test' ]], 'tuples';
    
    
    $tuples = $c->call_lua(['rettest' => 'test']);

    isa_ok $tuples => 'ARRAY', 'tuple returned';
    is_deeply $tuples => [{ name => 'test', value => undef, tail => [] }], 'tuples';
    
    isnt eval { $c->call_lua(['rettest' => 'test123']); 1 }, 1, 'unknown space';
    is $c->last_error->[0], 'ER_NOSPACE', 'ERROR CODE';
}

for (+ note 'eval lua') {
    my $tuples = $c->eval_lua('return {"abc"}');
    isa_ok $tuples => 'ARRAY', 'tuple returned';
    is_deeply $tuples => [[ 'abc' ]], 'tuples';
    
    $tuples = $c->eval_lua(['return {"abc"}' => 'test']);
    isa_ok $tuples => 'ARRAY', 'tuple returned';
    is_deeply $tuples => [{ name => 'abc', value => undef, tail => [] }], 'tuples';
}
