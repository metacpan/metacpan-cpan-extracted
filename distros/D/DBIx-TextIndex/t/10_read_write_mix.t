use strict;
use warnings;

use Test::More;
use DBI;
use DBIx::TextIndex;

if (defined $ENV{DBIX_TEXTINDEX_DSN}) {
    plan tests => 10;
} else {
    plan skip_all => '$ENV{DBIX_TEXTINDEX_DSN} must be defined to run tests.';
}

my $dbh = DBI->connect($ENV{DBIX_TEXTINDEX_DSN}, $ENV{DBIX_TEXTINDEX_USER}, $ENV{DBIX_TEXTINDEX_PASS}, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

ok( defined $dbh && $dbh->ping );

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
        ok( defined($dbh->do('DROP TABLE test_doc')) );
    } else {
	ok(1);
    }
    ok( defined($dbh->do(<<END) ) );
CREATE TABLE test_doc(
doc_id INT NOT NULL PRIMARY KEY,
doc TEXT)
END

} else {
    print "Bail out! Unsupported DBD driver: $dbd\n";
}

my $sth = $dbh->prepare(<<END);
INSERT INTO test_doc (doc_id, doc) VALUES (?, ?)
END

$sth->execute(1, q(a bunch of words));
$sth->execute(2, q(a bunch of different words));

my $index = DBIx::TextIndex->new({
    doc_dbh => $dbh,
    doc_table => 'test_doc',
    doc_fields => ['doc'],
    doc_id_field => 'doc_id',
    index_dbh => $dbh,
    collection => 'test',
});

ok( ref $index eq 'DBIx::TextIndex' );

ok( ref($index->initialize) eq 'DBIx::TextIndex' );

ok( $index->add_doc(1, 2) == 2 );



my $results;
eval {
    $results = $index->search({ doc => 'words' });
};
if ($@) {
    print "Bail out! Could not search(): $@\n";	
} else {
    my @results = sort keys %$results;
    ok( eq_array(\@results, [1,2]) );
}	


$dbh->do(<<END, undef, 3, qq(a bunch of different words, and more words), 1);
UPDATE test_doc set doc_id = ?, doc = ? WHERE doc_id = ?
END

ok( $index->add_doc(3) == 1 );

eval {
    $results = $index->search({ doc => 'more' });
};
if ($@) {
    print "Bail out! Could not search(): $@\n";	
} else {
    my @results = sort keys %$results;
    ok (eq_array(\@results, [3]) );
}

$index->delete();

ok( defined($dbh->do('DROP TABLE test_doc')) );
