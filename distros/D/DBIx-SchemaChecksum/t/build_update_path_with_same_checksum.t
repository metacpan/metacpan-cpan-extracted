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
    $update->{'ee3a4db19fc06296306738ee6d4cdfd1204adf8c'}->[1],
    '8f6643a8fc8b4e47caa30c70da5635f366075ea1',
    'first sum link'
);
is(
    $update->{'8f6643a8fc8b4e47caa30c70da5635f366075ea1'}->[0],
    'SAME_CHECKSUM','same_checksum');
is(
    $update->{'8f6643a8fc8b4e47caa30c70da5635f366075ea1'}->[2],'8f6643a8fc8b4e47caa30c70da5635f366075ea1','has same checksum');
is(
    $update->{'8f6643a8fc8b4e47caa30c70da5635f366075ea1'}->[4],'b96b98d2a80eb1c812a4f1d29a43e40eb4928078','second sum link'
);
is( $update->{'dc7198bc9b458194fd6584a090e219d38d9ef6a7'},
    undef, 'end of chain' );


done_testing();
