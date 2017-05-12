use strict;
use warnings;

use Test::More;
use Data::Dumper;
use DBI;
use DBIx::TextIndex;

if (defined $ENV{DBIX_TEXTINDEX_DSN}) {
    plan tests => 7;
}
else {
    plan skip_all => '$ENV{DBIX_TEXTINDEX_DSN} must be defined to run tests.';
}

my $dbh = DBI->connect($ENV{DBIX_TEXTINDEX_DSN}, $ENV{DBIX_TEXTINDEX_USER}, $ENV{DBIX_TEXTINDEX_PASS},
        { RaiseError => 1, PrintError => 0, AutoCommit => 1,
          ShowErrorStatement => 1 });

ok( defined $dbh && $dbh->ping, 'Connected to database' );

my $dbd = $dbh->{Driver}->{Name};

if ($dbd eq 'mysql' or $dbd eq 'SQLite' or $dbd eq 'Pg') {
    my @tables = $dbh->tables(undef, undef, 'test_doc', 'table');
    my $table_exists = 0;
    foreach my $table (@tables) {
        if ($table =~ m/^.*\.?[\"\`]?test_doc[\"\`]?$/) {
            $table_exists = 1;
            last;
        }
    }
    if ($table_exists) {
        ok( defined($dbh->do('DROP TABLE test_doc')),
            'Dropped test_doc table'
       );
    }
    else {
        ok(1, 'Did not need to drop test_doc table');
    }
    ok( defined($dbh->do(<<END) ), 'Created test_doc table' );
CREATE TABLE test_doc(
doc_id INT NOT NULL PRIMARY KEY,
doc TEXT)
END

}
else {
    print "Bail out! Unsupported DBD driver: $dbd\n";
}

my $sth = $dbh->prepare(<<END);
INSERT INTO test_doc (doc_id, doc) VALUES (?, ?)
END

$sth->execute(1, q(a bunch of words));
$sth->execute(2, q(a bunch of different words));

my $index_with_stoplist = DBIx::TextIndex->new({
    index_dbh => $dbh,
    doc_dbh => $dbh,
    doc_table => 'test_doc',
    doc_fields => ['doc'],
    doc_id_field => 'doc_id',
    collection => 'encantadas_with_stoplist',
    doc_fields => ['doc'],
    update_commit_interval => 500,
    proximity_index => 0,
    stoplist => ['en'],
});

is( ref($index_with_stoplist->initialize), 'DBIx::TextIndex',
        'initialize() returns instance' );

is( $index_with_stoplist->add_doc(1, 2), 2, 'Added two docs to index' );

my $results;
eval {
    $results = $index_with_stoplist->search({ doc => 'a' });
};
like($@, qr/These common words were not included in the search: a/,
    'Stoplisted terms threw correct error');

ok( defined($dbh->do('DROP TABLE test_doc')), 'Dropped test_doc table' );

$index_with_stoplist->delete();
