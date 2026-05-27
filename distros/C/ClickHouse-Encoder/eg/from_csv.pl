#!/usr/bin/env perl
# Read a CSV file, encode each row to ClickHouse Native, and insert via HTTP.
# This is the classic data-engineering workflow: "I have a CSV, get it into
# ClickHouse fast." The encoder converts each typed cell to its proper
# binary representation in one pass, with no per-row format string.
#
#   perl eg/from_csv.pl events.csv events
#
# The CSV is assumed to have a header row whose names match the columns of
# the target table (introspected via for_table).

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use Text::CSV_XS;
use HTTP::Tiny;
use URI::Escape qw(uri_escape);

my ($csv_path, $table) = @ARGV;
$csv_path && $table or die "usage: $0 <file.csv> <db.table>\n";
-r $csv_path or die "Cannot read $csv_path: $!\n";

my $http_base = $ENV{CH_HTTP} // 'http://localhost:8123';

# Introspect the target table to get column types.
my $enc = ClickHouse::Encoder->for_table($table,
    port => $ENV{CH_PORT} // 9000);
my @cols = @{ $enc->columns };
my %col_idx = map { $cols[$_][0] => $_ } 0 .. $#cols;
print "Target table $table has ", scalar @cols, " columns.\n";

# Read CSV, mapping headers to column indices.
my $csv = Text::CSV_XS->new({ binary => 1, auto_diag => 1 });
open my $fh, '<:encoding(utf8)', $csv_path
    or die "open $csv_path: $!";

my $header = $csv->getline($fh);
my @permutation;
for my $h (@$header) {
    defined $col_idx{$h}
        or die "CSV header '$h' has no matching column in $table\n";
    push @permutation, $col_idx{$h};
}

my @rows;
while (my $row = $csv->getline($fh)) {
    my @permuted;
    $permuted[$permutation[$_]] = $row->[$_] for 0 .. $#$row;
    push @rows, \@permuted;
}
close $fh;
print "Loaded ", scalar @rows, " rows from $csv_path.\n";

my $body = $enc->encode(\@rows);
printf "Encoded to Native: %.2f MB\n", length($body) / 1024 / 1024;

my $http = HTTP::Tiny->new(timeout => 30);
my $url  = "$http_base/?query=" . uri_escape("insert into $table format native");
my $resp = $http->post($url, {
    content => $body,
    headers => { 'content-type' => 'application/octet-stream' },
});

if ($resp->{success}) {
    print "Inserted ", scalar @rows, " rows.\n";
} else {
    die "insert failed (status $resp->{status}): $resp->{content}\n";
}
