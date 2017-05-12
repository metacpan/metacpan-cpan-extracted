use strict;
use warnings;
use Test::Most;
use DBIx::SchemaChecksum;
use File::Spec;
use lib qw(t);
use MakeTmpDb;

my $sc = DBIx::SchemaChecksum->new( dbh => MakeTmpDb->dbh, sqlsnippetdir=>'t/dbs/snippets' );

my $update = $sc->_update_path;
is( int keys %$update, 2, '2 updates' );
is(
    $update->{'660d1e9b6aec2ac84c2ff6b1acb5fe3450fdd013'}->[1],
    'e63a31c18566148984a317006dad897b75d8bdbe',
    'first sum link'
);
is(
    $update->{'e63a31c18566148984a317006dad897b75d8bdbe'}->[1],
    'b1387d808800a5969f0aa9bcae2d89a0d0b4620b',
    'second sum link'
);
is( $update->{'b1387d808800a5969f0aa9bcae2d89a0d0b4620b'},
    undef, 'end of chain' );

cmp_deeply(
    [File::Spec->splitdir($update->{'660d1e9b6aec2ac84c2ff6b1acb5fe3450fdd013'}->[0])],
    [qw(t dbs snippets first_change.sql)],
    'first snippet'
);
cmp_deeply(
    [File::Spec->splitdir($update->{'e63a31c18566148984a317006dad897b75d8bdbe'}->[0])],
    [qw(t dbs snippets another_change.sql)],
    'second snippet'
);

# corner cases
my $sc2 = DBIx::SchemaChecksum->new(
    dbh => MakeTmpDb->dbh,
    sqlsnippetdir => 't/dbs/no_snippets',
);
my $path = $sc2->_update_path;
is($path,undef,'no snippets found, so update_path is empty');

eval {
    my $sc3 = DBIx::SchemaChecksum->new(
        dbh => MakeTmpDb->dbh,
        sqlsnippetdir => 't/no_snippts_here',
    );
    $sc3->_update_path;
};
like($@,qr/Cannot find sqlsnippetdir/i,'no snippet dir');

eval {
    my $sc4 = DBIx::SchemaChecksum->new(
        dbh => MakeTmpDb->dbh,
        sqlsnippetdir => 't/build_update_path.t',
    );
    $sc4->_update_path;
};
like($@,qr/cannot find sqlsnippetdir/i,'no snippet dir');

done_testing();

