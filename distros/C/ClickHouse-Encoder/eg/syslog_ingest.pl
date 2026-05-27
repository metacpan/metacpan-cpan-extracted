#!/usr/bin/env perl
# Ingest RFC 5424 syslog lines (the format journald emits, and most
# modern syslog daemons forward) into a ClickHouse table. Reads from
# STDIN; intended use is being piped to from `journalctl -o cat -f` or
# `tail -F /var/log/syslog` etc.
#
# Schema:
#     create table syslog (
#         ts        DateTime64(6),
#         host      LowCardinality(String),
#         app       LowCardinality(String),
#         pid       Nullable(UInt32),
#         severity  LowCardinality(String),
#         msg       String
#     ) engine = MergeTree() order by (host, app, ts);
#
# Usage:
#     journalctl -o cat -f \
#         | CH_PORT=8123 perl eg/syslog_ingest.pl syslog
#
# RFC 5424 line shape:
#     <PRI>VERSION TIMESTAMP HOSTNAME APP-NAME PROCID MSGID STRUCTURED-DATA MSG
# We only parse what's typical for journald: PRI, ISO 8601 timestamp,
# hostname, app[pid], message.

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use HTTP::Tiny;
use Time::HiRes qw(time);

my $table = shift @ARGV or die "Usage: journalctl ... | $0 <table>\n";
my $port  = $ENV{CH_PORT} // 8123;
my $batch = $ENV{BATCH}   // 1000;

# RFC 5424 severity codes (PRI low 3 bits).
my @severities = qw(emerg alert crit err warn notice info debug);

my $enc = ClickHouse::Encoder->new(columns => [
    ['ts',       'DateTime64(6)'],
    ['host',     'LowCardinality(String)'],
    ['app',      'LowCardinality(String)'],
    ['pid',      'Nullable(UInt32)'],
    ['severity', 'LowCardinality(String)'],
    ['msg',      'String'],
]);

my $http = HTTP::Tiny->new(timeout => 30);
my $url  = "http://localhost:$port/?query="
         . _esc("insert into $table format native");
my $writer = sub {
    my $resp = $http->post($url, {
        content => $_[0],
        headers => { 'Content-Type' => 'application/octet-stream' },
    });
    die "insert failed (status $resp->{status}): $resp->{content}"
        unless $resp->{success};
};

my $st = $enc->streamer($writer, batch_size => $batch);

# Match the typical RFC 5424 / journald-cat shape leniently. Anything
# we can't parse goes in with msg = the raw line and best-effort
# defaults, so the pipeline never drops data.
my $rfc5424 = qr{
    \A
    (?:<(\d+)>)?              # PRI
    \s*
    (\d+\s+)?                 # optional VERSION
    (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+\-]\d{2}:?\d{2})?)?  # timestamp
    \s*
    (\S+)?                    # hostname
    \s*
    (\S+?)?                   # app
    (?:\[(\d+)\])?            # [pid]
    :?\s*
    (.*)                      # msg
    \z
}x;

while (defined(my $line = <STDIN>)) {
    chomp $line;
    next if $line eq '';

    my ($pri, undef, $iso_ts, $host, $app, $pid, $msg) = $line =~ $rfc5424;
    my $sev = defined $pri ? $severities[$pri & 7] : 'info';

    $st->push_row([
        $iso_ts // sprintf('%.6f', time()),
        $host   // '-',
        $app    // '-',
        $pid,
        $sev,
        $msg    // $line,
    ]);
}
$st->finish;

sub _esc {
    (my $s = $_[0]) =~ s/([^A-Za-z0-9\-_.~])/sprintf('%%%02X', ord($1))/ge;
    $s;
}
