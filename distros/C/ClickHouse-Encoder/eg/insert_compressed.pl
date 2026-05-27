#!/usr/bin/env perl
# insert with on-the-wire compression (zstd). ClickHouse honours
# Content-Encoding: zstd | gzip | br | deflate on HTTP requests, so wrapping
# the Native body in zstd typically cuts payload size 3-10x for typical
# event/log data with little extra CPU.
#
#   perl eg/insert_compressed.pl
#
# Requires Compress::Zstd (cpanm Compress::Zstd) or fall back to gzip via
# IO::Compress::Gzip from core.

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use HTTP::Tiny;
use URI::Escape qw(uri_escape);
use ClickHouse::Encoder;

my $base = $ENV{CH_HTTP} // 'http://localhost:8123';

# Pick zstd if available, else gzip (always available via core).
my ($enc_name, $compress);
if (eval { require Compress::Zstd; 1 }) {
    $enc_name = 'zstd';
    $compress = sub { Compress::Zstd::compress(shift) };
} else {
    require IO::Compress::Gzip;
    $enc_name = 'gzip';
    $compress = sub {
        my $in = shift;
        my $out;
        IO::Compress::Gzip::gzip(\$in, \$out)
            or die "gzip failed: $IO::Compress::Gzip::GzipError";
        return $out;
    };
}
print "Using compression: $enc_name\n";

my $http = HTTP::Tiny->new(timeout => 30);
sub run {
    my ($sql, $body) = @_;
    my $url = "$base/?query=" . uri_escape($sql);
    my %hdr = ('content-type' => 'application/octet-stream');
    if (defined $body && length $body) {
        $body = $compress->($body);
        $hdr{'content-encoding'} = $enc_name;
    }
    my $resp = $http->post($url, { content => $body // '', headers => \%hdr });
    die "ClickHouse error (status $resp->{status}): $resp->{content}\n"
        unless $resp->{success};
    return $resp->{content};
}

run('drop table if exists demo_compressed');
run(<<'SQL');
create table demo_compressed (
    id    UInt64,
    user  String,
    score Nullable(Float64),
    stamp DateTime
) engine = MergeTree order by id
SQL

my $enc = ClickHouse::Encoder->new(columns => [
    ['id',    'UInt64'],
    ['user',  'String'],
    ['score', 'Nullable(Float64)'],
    ['stamp', 'DateTime'],
]);

my @rows;
push @rows, [$_, "user_$_", ($_ % 7 ? rand(100) : undef), time() - $_]
    for 1 .. 100_000;

my $body = $enc->encode(\@rows);
my $compressed = $compress->($body);
printf "Native: %.2f MB; %s: %.2f MB (%.1fx smaller)\n",
    length($body) / 1024 / 1024,
    $enc_name, length($compressed) / 1024 / 1024,
    length($body) / length($compressed);

run('insert into demo_compressed format native', $body);

my $count = run('select count() from demo_compressed format tabseparated');
chomp $count;
print "Server reports: $count rows\n";

run('drop table demo_compressed');
