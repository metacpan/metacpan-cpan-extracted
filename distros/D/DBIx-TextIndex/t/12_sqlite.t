use strict;
use warnings;

use Test::More;
use DBI;
use DBIx::TextIndex;

use Data::Dumper;

my $have_sqlite;
BEGIN {
    eval { require DBD::SQLite; };
    $have_sqlite = $@ ? 0 : 1;
}

if ($have_sqlite) {
    plan tests => 9;
}
else {
    plan skip_all => 'DBD::SQLite must be installed to run tests.';
}

my $dbh = DBI->connect('DBI:SQLite:dbname=./t/test12.db', '', '',
                       { RaiseError => 1, PrintError => 0, AutoCommit => 1,
                         ShowErrorStatement => 1 });

ok( defined $dbh && $dbh->ping, 'Connected to database' );

my $dbd = $dbh->{Driver}->{Name};

# Even though this test file is meant to catch previous SQLite bugs,
# other drivers should be able to pass the tests
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

my @test_docs = (
    'foo ist bar und das ist wunderbar',
    'und jetzt wollte ich noch einmal sage, das ich foobar finde!',
    'questions that besieged us in live are testaments of our helplessness',
    'Der Sinn, der sich aussprechen FOO!',
    'und und und und und',
);

my $sth = $dbh->prepare(<<END);
INSERT INTO test_doc (doc_id, doc) values (?, ?)
END

my $doc_id = 1;
foreach my $doc (@test_docs) {
    $sth->execute($doc_id, $doc);
    $doc_id++;
}

my $index = DBIx::TextIndex->new({
    doc_dbh => $dbh,
    doc_table => 'test_doc',
    doc_fields => ['doc'],
    doc_id_field => 'doc_id',
    index_dbh => $dbh,
    collection => 'test_doc',
    update_commit_interval => 15,
    proximity_index => 1,
});
$index->initialize;
$index->add_doc( [ 1 .. 5 ] );

my $results = $index->search({ doc => 'und' });
my @result_ids = sort {$a <=> $b} keys %$results;
is_deeply(\@result_ids, [1, 2, 5], 'Search 1 returned expected');

$dbh->do(<<END, undef, 1, qq(wie ist und das und lahaha luhuhu foo bar), 1);
UPDATE test_doc set doc_id = ?, doc = ? WHERE doc_id = ?
END
$index->add_doc( [ 1 ] );

$results = $index->search({ doc => 'und' });
@result_ids = sort {$a <=> $b} keys %$results;
is_deeply(\@result_ids, [1, 2, 5], 'Search 2 returned expected');

$dbh->do(<<END, undef, 1, qq('foo ist bar und das ist wunderbar'), 1);
UPDATE test_doc set doc_id = ?, doc = ? WHERE doc_id = ?
END
$index->add_doc( [ 1 ] );

$results = $index->search({ doc => 'und' });
@result_ids = sort {$a <=> $b} keys %$results;
is_deeply(\@result_ids, [1, 2, 5], 'Search 3 returned expected');

$dbh->do(<<END, undef, 1, qq(unverfaenglicher Text mit dem Wort und), 1);
UPDATE test_doc set doc_id = ?, doc = ? WHERE doc_id = ?
END
$index->add_doc( [ 1 ] );

$results = $index->search({ doc => 'und' });
@result_ids = sort {$a <=> $b} keys %$results;
is_deeply(\@result_ids, [1, 2, 5], 'Search 4 returned expected');

$dbh->do(<<END, undef, 1, qq(unverfänglicher Text mit dem Wort und), 1);
UPDATE test_doc set doc_id = ?, doc = ? WHERE doc_id = ?
END
$index->add_doc( [ 1 ] );

$results = $index->search({ doc => 'und' });
@result_ids = sort {$a <=> $b} keys %$results;
is_deeply(\@result_ids, [1, 2, 5], 'Search 5 returned expected');

$dbh->do(<<END, undef, 1, qq(Text mit dem Wort), 1);
UPDATE test_doc set doc_id = ?, doc = ? WHERE doc_id = ?
END
$index->add_doc( [ 1 ] );

$results = $index->search({ doc => 'und' });
@result_ids = sort {$a <=> $b} keys %$results;
is_deeply(\@result_ids, [2, 5], 'Search 6 returned expected');

unlink('./t/test12.db');
