#!/usr/bin/env perl
# Ingest geometry given as Well-Known-Text (WKT) into ClickHouse Geo
# columns. parse_wkt turns a WKT string into the nested-arrayref shape
# the Point / LineString / Polygon / ... encoders expect, so a feed of
# WKT from PostGIS, a shapefile converter, or a GeoJSON-to-WKT step
# drops straight into an insert.
#
# Usage:
#     perl eg/geo_from_wkt.pl --host=db --port=8123 --table=places

use strict;
use warnings;
use Getopt::Long;
use ClickHouse::Encoder;

my ($host, $port, $table) = ('127.0.0.1', 8123, 'places');
GetOptions('host=s' => \$host, 'port=i' => \$port, 'table=s' => \$table)
    or die "bad options\n";

# Source records: a name plus geometries as WKT strings.
my @source = (
    { name => 'origin',  loc => 'POINT(0 0)',
      area => 'POLYGON((0 0, 4 0, 4 4, 0 4, 0 0))' },
    { name => 'harbour', loc => 'POINT(13.4 52.5)',
      area => 'POLYGON((10 50, 14 50, 14 53, 10 53, 10 50),'
            .         '(11 51, 12 51, 12 52, 11 52, 11 51))' },
);

my $enc = ClickHouse::Encoder->new(columns => [
    ['name', 'String'],
    ['loc',  'Point'],
    ['area', 'Polygon'],
]);

# parse_wkt does the WKT -> arrayref conversion; the encoder does the
# rest. A malformed WKT string croaks with the offending geometry named.
my @rows = map {
    [ $_->{name},
      ClickHouse::Encoder->parse_wkt($_->{loc}),
      ClickHouse::Encoder->parse_wkt($_->{area}) ]
} @source;

my $resp = ClickHouse::Encoder->insert_http(
    host => $host, port => $port, table => $table,
    encoder => $enc, rows => \@rows,
);
die "insert failed (status $resp->{status}): $resp->{content}\n"
    unless $resp->{success};
print "inserted ", scalar(@rows), " geo rows from WKT\n";
