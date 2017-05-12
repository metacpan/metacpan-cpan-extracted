use strict;
use warnings;

use Test::More;
use DBI;
use DBIx::TextIndex;

if (defined $ENV{DBIX_TEXTINDEX_DSN}) {
    plan tests => 2;
} else {
    plan skip_all => '$ENV{DBIX_TEXTINDEX_DSN} must be defined to run tests.';
}

my $dbh = DBI->connect($ENV{DBIX_TEXTINDEX_DSN}, $ENV{DBIX_TEXTINDEX_USER}, $ENV{DBIX_TEXTINDEX_PASS}, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

ok( defined $dbh && $dbh->ping );

my $index = DBIx::TextIndex->new({
    doc_dbh => $dbh,
    index_dbh => $dbh,
    collection => 'encantadas',
});

ok( ref $index eq 'DBIx::TextIndex' );

$index->delete;

$dbh->disconnect;
