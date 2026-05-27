#!/usr/bin/env perl
# Server-side async insert. With async_insert=1 the server buffers the
# rows and acknowledges immediately; it flushes them to the table in
# the background. wait_for_async_insert=1 makes the call block until
# that flush completes (durable, slower); =0 is fire-and-forget.
#
# No special API is needed - async_insert is just a query setting, so
# it rides the `settings` option that every HTTP entry point accepts.
#
# Usage:
#     perl eg/async_insert.pl --host=db --port=8123 --table=events [--wait]

use strict;
use warnings;
use Getopt::Long;
use ClickHouse::Encoder;

my ($host, $port, $table, $wait) = ('127.0.0.1', 8123, 'events', 0);
GetOptions('host=s' => \$host, 'port=i' => \$port,
           'table=s' => \$table, 'wait!' => \$wait)
    or die "bad options\n";

my @rows = map { [$_, "event-$_", time()] } 1 .. 1000;

my $resp = ClickHouse::Encoder->insert_http(
    host    => $host,
    port    => $port,
    table   => $table,
    columns => [['id', 'UInt64'], ['name', 'String'], ['ts', 'DateTime']],
    rows    => \@rows,
    settings => {
        async_insert          => 1,
        # 1 = block until the background flush is durable; 0 = return
        # as soon as the server has buffered the batch.
        wait_for_async_insert => $wait ? 1 : 0,
    },
);

die "async insert failed (status $resp->{status}): $resp->{content}\n"
    unless $resp->{success};

print "async insert accepted (", scalar(@rows), " rows, ",
      ($wait ? 'waited for flush' : 'fire-and-forget'), ")\n";
print "query id: ", $resp->{ch}{'query-id'}, "\n"
    if $resp->{ch} && $resp->{ch}{'query-id'};
