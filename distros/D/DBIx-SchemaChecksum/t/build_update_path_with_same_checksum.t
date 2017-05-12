use strict;
use warnings;
use Test::Most;
use DBIx::SchemaChecksum;
use File::Spec;
use lib qw(t);
use MakeTmpDb;

my $sc = DBIx::SchemaChecksum->new(
    dbh => MakeTmpDb->dbh,
    sqlsnippetdir => 't/dbs/snippets2',
);

my $update = $sc->_update_path;
is( int keys %$update, 3, '3 updates' );
is(
    $update->{'660d1e9b6aec2ac84c2ff6b1acb5fe3450fdd013'}->[1],
    'e63a31c18566148984a317006dad897b75d8bdbe',
    'first sum link'
);
is(
    $update->{'e63a31c18566148984a317006dad897b75d8bdbe'}->[0],
    'SAME_CHECKSUM','same_checksum');
is(
    $update->{'e63a31c18566148984a317006dad897b75d8bdbe'}->[2],'e63a31c18566148984a317006dad897b75d8bdbe','has same checksum');
is(
    $update->{'e63a31c18566148984a317006dad897b75d8bdbe'}->[4],'b1387d808800a5969f0aa9bcae2d89a0d0b4620b','second sum link'
);
is( $update->{'55df89fd956a03d637b52d13281bc252896f602f'},
    undef, 'end of chain' );


done_testing();
