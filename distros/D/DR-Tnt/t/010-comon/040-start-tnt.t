#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 6;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Tnt::Test';
    use_ok 'IO::Socket::INET';
    tarantool_version_check(1.6);
}

for (+note 'lua') {
    my $t = start_tarantool -lua => 't/010-comon/lua/run-test.lua';
    isa_ok $t => DR::Tnt::Test::TntInstance::;
    like $t->log, qr{Hello, world}, 'logfile';
}

for (+note 'make_lua') {
    local $/;
    my $lua = <DATA>;
    my $t = start_tarantool -make_lua => $lua;
    isa_ok $t => DR::Tnt::Test::TntInstance::;
    like $t->log, qr{Hello, world, -make_lua}, 'logfile';
}

__DATA__

print('Hello, world, -make_lua')
os.exit();
