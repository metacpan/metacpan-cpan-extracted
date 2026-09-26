#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp;
use IO::Async::Loop;
use DBIx::Class::Async;

use lib 't/lib';

my $loop           = IO::Async::Loop->new;
my ($fh, $db_file) = File::Temp::tempfile(SUFFIX => '.db', UNLINK => 1);
my $db             = DBIx::Class::Async->create_async_db(
    schema_class => 'TestSchema',
    connect_info => [ "dbi:SQLite:dbname=$db_file" ],
    workers      => 3,
    async_loop   => $loop,
    health_check => 0,
);

subtest 'Worker handles health_check operation' => sub {
    my $worker = $db->{_workers}[0]{instance};

    my $future = $worker->call(
        args => [
            $db->{_schema_class},
            $db->{_connect_info},
            $db->{_workers_config},
            'health_check',
        ],
        timeout => 5,
    );

    my $res = $future->get;

    is_deeply($res, { success => 1, status => 'pong' },
        'Worker correctly responds to health_check operation')
        or diag explain $res;
};

subtest 'Load balancer skips unhealthy workers' => sub {
    # Mark worker 1 (index 1) as unhealthy
    $db->{_workers}[0]{healthy} = 1;
    $db->{_workers}[1]{healthy} = 0;
    $db->{_workers}[2]{healthy} = 1;

    $db->{_worker_idx} = 0;

    my $w1 = DBIx::Class::Async::_next_worker($db);
    is($w1, $db->{_workers}[0]{instance}, 'First call returns healthy worker 0');

    my $w2 = DBIx::Class::Async::_next_worker($db);
    is($w2, $db->{_workers}[2]{instance}, 'Second call skips unhealthy worker 1 and returns worker 2');

    my $w3 = DBIx::Class::Async::_next_worker($db);
    is($w3, $db->{_workers}[0]{instance}, 'Third call wraps around to healthy worker 0');
};

subtest 'Fallback when all workers are marked unhealthy' => sub {
    $_->{healthy} = 0 for @{ $db->{_workers} };

    $db->{_worker_idx} = 0;

    my $fallback_worker = eval { DBIx::Class::Async::_next_worker($db) };
    ok($fallback_worker, 'Returns a fallback worker instance even if all are unhealthy');
    is($fallback_worker, $db->{_workers}[0]{instance}, 'Fallback picks worker at current index');
};

DBIx::Class::Async::disconnect($db);

done_testing;
