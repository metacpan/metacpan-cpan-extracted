use strict;
use warnings;

use Test::More;

BEGIN {
    if (defined $ENV{DBIX_TEXTINDEX_DSN}) {
        plan tests => 18;
    } else {
        plan skip_all => '$ENV{DBIX_TEXTINDEX_DSN} must be defined to run tests.';
    }

    use_ok qw(DBI);
    use_ok qw(DBIx::TextIndex);
}

my $dbh = DBI->connect($ENV{DBIX_TEXTINDEX_DSN}, $ENV{DBIX_TEXTINDEX_USER}, $ENV{DBIX_TEXTINDEX_PASS}, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

ok( defined $dbh && $dbh->ping, 'Connected to database' );

my ($max_doc_id) = $dbh->selectrow_array(qq(SELECT MAX(doc_id) FROM textindex_doc));

ok( $max_doc_id == 226, 'Test doc table is loaded' );

my $index = DBIx::TextIndex->new({
    doc_dbh => $dbh,
    doc_table => 'textindex_doc',
    doc_fields => ['doc'],
    doc_id_field => 'doc_id',
    index_dbh => $dbh,
    collection => 'encantadas',
    update_commit_interval => 15,
    proximity_index => 1,
});

ok( ref $index eq 'DBIx::TextIndex', 'New instance has correct type' );

ok( ref($index->initialize) eq 'DBIx::TextIndex', 'initialize() returns instance' );

ok( $index->add_doc(1) == 1, 'Added doc 1' );
ok( $index->add_document(2, 3, 4) == 3, 'Added docs 2-4' );
ok( $index->add_doc([5 .. 100]) == 96, 'Added docs 5-100' );
ok( $index->add_doc([101 .. $max_doc_id]) == 126,
    "Added docs 101-$max_doc_id" );

ok( $index->indexed(1), 'Doc 1 is indexed' );
ok( $index->indexed(100), 'Doc 100 is indexed' );
ok( $index->indexed(226), 'Doc 226 is indexed' );

ok( $index->last_indexed_key == 226, 'Last indexed doc is 226' );

is_deeply( [ $index->all_doc_ids ], [1 .. 226], 'Docs 1-226 are in index' );

$dbh->disconnect();

$dbh = DBI->connect($ENV{DBIX_TEXTINDEX_DSN}, $ENV{DBIX_TEXTINDEX_USER}, $ENV{DBIX_TEXTINDEX_PASS}, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

my $named_keys_index = DBIx::TextIndex->new({
    index_dbh => $dbh,
    collection => 'encantadas_named_keys',
    doc_fields => ['doc'],
    update_commit_interval => 15,
    proximity_index => 1,
});

ok( ref($named_keys_index->initialize) eq 'DBIx::TextIndex',
    'initialize() returns instance' );

my $sth = $dbh->prepare(qq(select doc_id, doc from textindex_doc));

$sth->execute;
my @docs;
while (my ($doc_id, $doc) = $sth->fetchrow_array) {
    push @docs, { doc_id => $doc_id, doc => $doc};
}
$sth->finish;

$named_keys_index->begin_add;
foreach my $record (@docs) {
    my $doc_id = $record->{doc_id};
    my $doc = $record->{doc};
    $named_keys_index->add( "doc_$doc_id" => { doc => $doc } );
}
$named_keys_index->commit_add;

ok( $named_keys_index->indexed("doc_1"), 'Doc 1 is indexed' );
ok( $named_keys_index->indexed("doc_226"), 'Doc 226 is indexed' );

$dbh->disconnect;
