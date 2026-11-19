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
    $update->{'ee3a4db19fc06296306738ee6d4cdfd1204adf8c'}->[1],
    '8f6643a8fc8b4e47caa30c70da5635f366075ea1',
    'first sum link'
);
is(
    $update->{'8f6643a8fc8b4e47caa30c70da5635f366075ea1'}->[1],
    'b96b98d2a80eb1c812a4f1d29a43e40eb4928078',
    'second sum link'
);
is( $update->{'b96b98d2a80eb1c812a4f1d29a43e40eb4928078'},
    undef, 'end of chain' );

cmp_deeply(
    [File::Spec->splitdir($update->{'ee3a4db19fc06296306738ee6d4cdfd1204adf8c'}->[0])],
    [qw(t dbs snippets first_change.sql)],
    'first snippet'
);
cmp_deeply(
    [File::Spec->splitdir($update->{'8f6643a8fc8b4e47caa30c70da5635f366075ea1'}->[0])],
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

