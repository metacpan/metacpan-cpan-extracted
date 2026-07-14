#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp;

use lib 't/lib';

use TestSchema;
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

my $loop           = IO::Async::Loop->new;
my ($fh, $db_file) = File::Temp::tempfile(UNLINK => 1);
my $schema         = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file", undef, undef, {},
    {
        workers      => 2,
        schema_class => 'TestSchema',
        async_loop   => $loop,
    }
);

$schema->await($schema->deploy({ add_drop_table => 1 }));

$schema->await(
    $schema->resultset('Interface')->create({ id => 1, name => 'eth0' })
);

$schema->await(
    $schema->resultset('Maintenance')->populate([
        {
            id             => 1,
            fk_interface   => 1,
            label          => 'ACTIVE',
            datetime_start => '2000-01-01 00:00:00',
            datetime_end   => '2999-12-31 23:59:59',
        },
        {
            id             => 2,
            fk_interface   => 1,
            label          => 'EXPIRED',
            datetime_start => '2000-01-01 00:00:00',
            datetime_end   => '2000-01-02 00:00:00',
        },
    ])
);

# Test 1: accessor without prefetch
# The where condition IS applied - expect only ACTIVE
my $iface = $schema->await(
    $schema->resultset('Interface')->find(1)
);

my $via_accessor = $schema->await(
    $iface->currently_in_maintenance->all
);

isa_ok($via_accessor, 'ARRAY', 'accessor: returns arrayref');
is(scalar @$via_accessor, 1, 'accessor: only 1 active window returned');
is($via_accessor->[0]->label, 'ACTIVE', 'accessor: correct window returned');

# Test 2: prefetch
# The where condition is silently dropped during prefetch,
# so EXPIRED leaks through and we get 2 rows instead of 1.
# These tests FAIL with the buggy where form, proving the issue.
my $rs = $schema->resultset('Interface')
                ->search(
                    { 'me.id'  => 1 },
                    { prefetch => 'currently_in_maintenance' });

my $iface_prefetched = $schema->await($rs->single_future);
my $via_prefetch     = $schema->await(
    $iface_prefetched->currently_in_maintenance->all);

isa_ok($via_prefetch, 'ARRAY', 'prefetch: returns arrayref');
is(scalar @$via_prefetch, 1, 'prefetch: only 1 active window returned');
is($via_prefetch->[0]->label, 'ACTIVE', 'prefetch: correct window returned');
isnt(scalar @$via_prefetch, 2, 'prefetch: EXPIRED absent, where was not silently dropped');

done_testing;
