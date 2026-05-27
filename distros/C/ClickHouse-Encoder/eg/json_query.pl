#!/usr/bin/env perl
# json_query.pl - run a select against a JSON column, decode rows via
# decode_blocks, walk the decoded objects in Perl.
#
# Usage:
#   json_query.pl --table events --where "j.user.id = 42"
#
# Demonstrates:
#   - HTTP select format native returns a concatenated stream of blocks;
#     decode_blocks() walks them
#   - The decoded JSON values are nested Perl hashrefs (dotted paths
#     auto-unflattened on the way back)
use strict;
use warnings;
use Getopt::Long;
use HTTP::Tiny;
use ClickHouse::Encoder;

my ($host, $port, $table, $col, $where, $limit) =
    ('127.0.0.1', 8123, 'events', 'j', '', 10);
GetOptions(
    'host=s'  => \$host,
    'port=i'  => \$port,
    'table=s' => \$table,
    'col=s'   => \$col,
    'where=s' => \$where,
    'limit=i' => \$limit,
) or die "bad options\n";

# Validate identifiers; --where is intentionally pass-through (it's
# the whole point of this example), so document that you should not
# accept it from untrusted input in production.
$table =~ /\A[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?\z/
    or die "Bad --table '$table': expected [db.]name\n";
$col =~ /\A[A-Za-z_]\w*\z/
    or die "Bad --col '$col': expected identifier\n";

my $sql = "select $col from $table"
        . ($where ne '' ? " where $where" : '')
        . " limit $limit format native";

require Encode;
my $esc = sub {
    my $s = Encode::encode('UTF-8', $_[0], 0);
    $s =~ s/([^A-Za-z0-9\-_.~])/sprintf('%%%02X', ord($1))/ge;
    $s;
};
my $url = "http://$host:$port/?query=" . $esc->($sql)
        . "&enable_json_type=1";

my $resp = HTTP::Tiny->new(timeout => 60)->get($url);
die "select failed (status $resp->{status}): $resp->{content}\n"
    unless $resp->{success};

my $blocks = ClickHouse::Encoder->decode_blocks($resp->{content});
my $total = 0;
for my $blk (@$blocks) {
    my $vals = $blk->{columns}[0]{values};
    for my $row (@$vals) {
        $total++;
        # $row is a nested hashref (dotted paths unflattened).
        print "row $total: ", _short_describe($row), "\n";
    }
}
print STDERR "Total rows: $total in ", scalar(@$blocks), " blocks\n";

sub _short_describe {
    my $h = shift;
    return ref $h eq 'HASH'
        ? '{' . join(', ',
            map { "$_=" . _short_describe($h->{$_}) } sort keys %$h) . '}'
        : ref $h eq 'ARRAY'
        ? '[' . join(',', map _short_describe($_), @$h) . ']'
        : defined $h ? $h
        : 'null';
}
