#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 11;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Tnt::Proto';
    use_ok 'DR::Tnt::Test';


    use_ok 'IO::Socket::INET';
    tarantool_version_check(1.6);
}

my $tnt = start_tarantool
    -port   => free_port,
    -lua    => 't/020-proto/lua/server.lua';
diag $tnt->log
    unless ok $tnt->is_started, 'started';

for (+ note 'greating') {
    my $fh = IO::Socket::INET->new(
            PeerHost => '127.0.0.1',
            PeerPort => $tnt->port,
            Proto    => 'tcp',
        );
    ok $fh, 'connected';

    my $grstr;
    is read($fh, $grstr, 128), 128, '128 bytes greating read';

    my $gp = DR::Tnt::Proto::parse_greeting $grstr;
    isa_ok $gp => 'HASH';
    like $gp->{proto} => qr{binary}i, 'proto';
    is length $gp->{salt}, 20, 'len of salt';
    like $gp->{title}, qr{tarantool}i, 'title';
    like $gp->{uuid}, qr/^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i, 'uuid';
}
