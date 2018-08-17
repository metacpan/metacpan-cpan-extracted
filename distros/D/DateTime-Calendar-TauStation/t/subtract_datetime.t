use strict;
use warnings;
use Test::More tests => 1;
use DateTime::Format::TauStation;

my $dt1 = DateTime::Format::TauStation->parse_datetime('123.02/01:000 GCT');
my $dt2 = DateTime::Format::TauStation->parse_datetime('120.01/00:500 GCT');

my $dur = $dt1->subtract_datetime( $dt2 );

is(
    DateTime::Format::TauStation->format_duration($dur),
    "D3.1/00:500 GCT"
);
