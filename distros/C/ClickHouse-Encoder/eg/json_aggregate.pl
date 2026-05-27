#!/usr/bin/env perl
# json_aggregate.pl - server-side JSON-path aggregation example.
# Demonstrates that JSON sub-columns can be queried like normal
# columns (j.user.id, j.event_type, etc.) and aggregated at the
# server, returning a small result set the client decodes via
# decode_block.
#
# Usage:
#   json_aggregate.pl --table events --path 'j.user.id'
#
# This is more useful than dragging full JSON rows over the wire when
# you only need a summary; the server prunes path data it doesn't
# need from the Variant blob.
use strict;
use warnings;
use Getopt::Long;
use HTTP::Tiny;
use Encode;
use ClickHouse::Encoder;

my ($host, $port, $table, $path, $limit) =
    ('127.0.0.1', 8123, 'events', 'j.user.id', 20);
GetOptions(
    'host=s'  => \$host,
    'port=i'  => \$port,
    'table=s' => \$table,
    'path=s'  => \$path,
    'limit=i' => \$limit,
) or die "bad options\n";

$table =~ /\A[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?\z/
    or die "Bad --table\n";
# Path is interpolated into SQL: restrict to alphanumerics + dot.
$path =~ /\A[A-Za-z_][\w.]*\z/
    or die "Bad --path '$path': expected ident.ident...\n";

my $esc = sub {
    my $s = Encode::encode('UTF-8', $_[0], 0);
    $s =~ s/([^A-Za-z0-9\-_.~])/sprintf('%%%02X', ord($1))/ge;
    $s;
};

# Use toString to coerce Dynamic/Variant subcolumns to a uniform key.
my $sql = "select toString($path) as k, count() as c "
        . "from $table group by k order by c DESC limit $limit "
        . "format native";
my $url  = "http://$host:$port/?query=" . $esc->($sql)
         . "&enable_json_type=1";

my $resp = HTTP::Tiny->new(timeout => 60)->get($url);
die "select failed (status $resp->{status}): $resp->{content}\n"
    unless $resp->{success};

my $blocks = ClickHouse::Encoder->decode_blocks($resp->{content});
printf "%-40s %10s\n", $path, "count";
printf "%-40s %10s\n", "-" x 40, "-" x 10;
for my $blk (@$blocks) {
    my $keys   = $blk->{columns}[0]{values};
    my $counts = $blk->{columns}[1]{values};
    for my $i (0 .. $#{ $keys }) {
        printf "%-40s %10d\n", $keys->[$i] // '<null>', $counts->[$i];
    }
}
