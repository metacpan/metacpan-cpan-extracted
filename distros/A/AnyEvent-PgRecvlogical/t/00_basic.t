#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use ok 'AnyEvent::PgRecvlogical';

my $recv = new_ok(
    'AnyEvent::PgRecvlogical' => [
        dbname         => 'test',
        host           => 'localhost',
        port           => 15432,
        slot           => 'test',
        do_create_slot => 1,
        slot_exists_ok => 1,
        on_message => sub {},
    ],
    'pg_recvlogical'
);

is $recv->_dsn, 'dbi:Pg:client_encoding=sql_ascii;dbname=test;host=localhost;port=15432;replication=database';

done_testing;
