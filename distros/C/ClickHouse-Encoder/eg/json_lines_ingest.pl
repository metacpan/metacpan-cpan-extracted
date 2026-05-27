#!/usr/bin/env perl
# Read NDJSON (one JSON object per line) from STDIN or a file, map each
# object's fields onto a ClickHouse schema, and insert the resulting
# block over HTTP. Handles missing fields per row by emitting null when
# the column is Nullable, croak otherwise.
#
# Usage:
#     perl eg/json_lines_ingest.pl events <events.ndjson
#     curl -s api/events.ndjson | perl eg/json_lines_ingest.pl events
#
# Schema is read from ClickHouse via for_table(), so the same script
# works for any table -- pass the table name as the only argument.

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use HTTP::Tiny;
use JSON::PP;

my $table = shift @ARGV or die "Usage: $0 <table> [<file>]\n";
my $port  = $ENV{CH_PORT} // 8123;

# Discover the schema from the running server.
my $enc = ClickHouse::Encoder->for_table($table,
    via  => 'http',
    port => $port,
);
my @cols = @{ $enc->columns };
my @names = map { $_->[0] } @cols;
my %nullable = map {
    $_->[0] => ($_->[1] =~ /\ANullable\(/ ? 1 : 0)
} @cols;

print STDERR "schema: ", join(', ', map { "$_->[0] $_->[1]" } @cols), "\n";

# Stream NDJSON -> rows.
my $json    = JSON::PP->new->utf8;
my $batch   = $ENV{BATCH} // 5_000;
my $sent    = 0;
my $http    = HTTP::Tiny->new(timeout => 30);
my $url     = "http://localhost:$port/?query="
            . _esc("insert into $table format native");

my $writer = sub {
    my $bytes = shift;
    my $resp = $http->post($url, {
        content => $bytes,
        headers => { 'Content-Type' => 'application/octet-stream' },
    });
    die "insert failed (status $resp->{status}): $resp->{content}"
        unless $resp->{success};
};

my $st = $enc->streamer($writer, batch_size => $batch);

while (defined(my $line = <>)) {
    chomp $line;
    next if $line =~ /\A\s*\z/;
    my $rec = eval { $json->decode($line) };
    if ($@) { warn "skip bad json (line $.): $@"; next }

    my @row;
    for my $name (@names) {
        if (exists $rec->{$name}) {
            push @row, $rec->{$name};
        } elsif ($nullable{$name}) {
            push @row, undef;
        } else {
            die "row $.: missing required column '$name' (not Nullable)";
        }
    }
    $st->push_row(\@row);
    $sent++;
}
$st->finish;

print STDERR "ingested $sent rows into $table\n";

sub _esc {
    (my $s = $_[0]) =~ s/([^A-Za-z0-9\-_.~])/sprintf('%%%02X', ord($1))/ge;
    $s;
}
