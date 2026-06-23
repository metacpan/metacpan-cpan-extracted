use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder;
my $d = 'DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder';

# Build EWKB hex for POINT(1.0, 2.0) SRID=4326 in little-endian
# byte_order=1(LE), type=0x20000001(POINT|SRID_FLAG), srid=4326, x=1.0, y=2.0
my $hex = unpack('H*', pack('C V V d< d<', 1, 0x20000001, 4326, 1.0, 2.0));

my $r = $d->decode_hex($hex);
is $r->{type},     'point', 'type is point';
is $r->{srid},     4326,    'SRID is 4326';
is $r->{coords}[0], 1.0,   'X = 1.0';
is $r->{coords}[1], 2.0,   'Y = 2.0';

# Without SRID
my $hex2 = unpack('H*', pack('C V d< d<', 1, 1, 3.0, 4.0));
my $r2   = $d->decode_hex($hex2);
is $r2->{type},    'point', 'type is point';
is $r2->{srid},    undef,   'no SRID';
is $r2->{coords}[0], 3.0,  'X = 3.0';

done_testing;
