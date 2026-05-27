#!/usr/bin/env perl
# Classic ETL: read rows from a source database via DBI, encode to ClickHouse
# Native, insert via HTTP. Reuses one encoder across many fetched batches.
#
#   perl eg/etl_dbi.pl 'dbi:mysql:database=src;host=localhost' user pass \
#                      'select id, name, ts from events' my_events
#
# Adjust the source DSN, query, and target table for your case. The encoder
# is built from the target's schema via for_table -> via=>'http', and column
# names are matched between SQL output and the target table.

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use DBI;
use HTTP::Tiny;
use URI::Escape qw(uri_escape);
use ClickHouse::Encoder;

my ($dsn, $user, $pass, $select_sql, $target_table) = @ARGV;
@ARGV == 5
    or die "usage: $0 <dsn> <user> <pass> <select-sql> <target.table>\n"
       . "  pass empty strings for <user>/<pass> if the source DB needs none\n";

my $ch_http = $ENV{CH_HTTP}    // 'http://localhost:8123';
my $batch   = $ENV{ETL_BATCH}  // 5_000;

# 1) Introspect the target schema (no clickhouse-client needed).
my $enc = ClickHouse::Encoder->for_table($target_table,
    via => 'http', host => $ENV{CH_HOST} // 'localhost',
    port => $ENV{CH_PORT} // 8123,
);
print "Target schema:\n";
printf "  %-20s %s\n", $_->[0], $_->[1] for @{ $enc->columns };

# 2) Read source rows.
my $dbh = DBI->connect($dsn, $user, $pass, {
    RaiseError => 1, AutoCommit => 1, mysql_use_result => 1,
});
my $sth = $dbh->prepare($select_sql);
$sth->execute;

# 3) Stream batches into ClickHouse, reusing the encoder.
my $http = HTTP::Tiny->new(timeout => 60);
my $url  = "$ch_http/?query="
         . uri_escape("insert into $target_table format native");
my $total = 0;

my $writer = sub {
    my $body = shift;
    my $resp = $http->post($url, {
        content => $body,
        headers => { 'content-type' => 'application/octet-stream' },
    });
    die "insert failed (status $resp->{status}): $resp->{content}\n"
        unless $resp->{success};
};

my $stream = $enc->streamer($writer, batch_size => $batch);
while (my $row = $sth->fetchrow_arrayref) {
    # DBI returns arrayref; matches encoder's expected row shape directly.
    $stream->push_row([@$row]);   # copy because fetchrow_arrayref reuses the same arrayref
    $total++;
}
$stream->finish;

$dbh->disconnect;
printf "Inserted %d rows into %s\n", $total, $target_table;
