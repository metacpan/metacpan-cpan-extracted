#!/usr/bin/env perl
# Replicate a PostgreSQL table to ClickHouse: discover the destination
# schema via for_table(), select the matching columns from Pg, and
# stream rows through this encoder's streamer to a chunked HTTP insert.
# Memory is bounded by the batch size, so the script handles tables
# with millions of rows.
#
# This uses plain DBI fetchrow_arrayref. For very large source tables
# you typically also want server-side cursors -- DBD::Pg supports them
# via $dbh->{pg_server_prepare} = 1 and ordinary selects become
# cursor-driven; or use the pg COPY protocol explicitly via
# pg_putcopydata / pg_getcopydata for the lowest per-row overhead.
#
# Usage:
#     PG_DSN='dbi:Pg:host=h;dbname=src' PG_USER=... PG_PASS=...
#     CH_PORT=8123 \
#     perl eg/postgres_to_clickhouse.pl src_schema.events dest_table
#
# Both sides must have the same column order; types must be compatible
# (Pg int4 -> CH Int32, etc.). The script discovers the destination
# schema via for_table() and assumes the source has matching column
# names.

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use DBI;
use HTTP::Tiny;

my ($src_table, $dst_table) = @ARGV;
die "Usage: $0 <pg_table> <ch_table>\n" unless $src_table && $dst_table;

my $port = $ENV{CH_PORT} // 8123;

# Discover the CH side schema; use it to drive the select.
my $enc   = ClickHouse::Encoder->for_table($dst_table, via => 'http', port => $port);
my @cols  = @{ $enc->columns };
my @names = map { $_->[0] } @cols;
print STDERR "destination $dst_table: ", scalar(@cols), " columns: @names\n";

# Pull rows from Postgres.
my $dbh = DBI->connect(
    $ENV{PG_DSN} // 'dbi:Pg:dbname=postgres',
    $ENV{PG_USER}, $ENV{PG_PASS},
    { RaiseError => 1, AutoCommit => 0, pg_server_prepare => 0 },
);
my $cols_sql = join(', ', map { qq{"$_"} } @names);
my $sth = $dbh->prepare("select $cols_sql from $src_table");
$sth->execute;

# CH writer: HTTP insert of each emitted block.
my $http = HTTP::Tiny->new(timeout => 60);
my $url  = "http://localhost:$port/?query="
         . _esc("insert into $dst_table format native");
my $sent_blocks = 0;
my $writer = sub {
    my $bin = shift;
    my $resp = $http->post($url, {
        content => $bin,
        headers => { 'Content-Type' => 'application/octet-stream' },
    });
    die "insert failed: $resp->{content}" unless $resp->{success};
    $sent_blocks++;
};

my $batch = $ENV{BATCH} // 50_000;
my $st    = $enc->streamer($writer, batch_size => $batch);

my $rows = 0;
while (my $row = $sth->fetchrow_arrayref) {
    $st->push_row([@$row]);   # copy: DBI reuses the arrayref
    $rows++;
    print STDERR "  $rows rows...\r" if $rows % 10_000 == 0;
}
$st->finish;
$sth->finish;
$dbh->disconnect;

printf STDERR "done: %d rows in %d block(s) -> $dst_table\n", $rows, $sent_blocks;

sub _esc {
    (my $s = $_[0]) =~ s/([^A-Za-z0-9\-_.~])/sprintf('%%%02X', ord($1))/ge;
    $s;
}
