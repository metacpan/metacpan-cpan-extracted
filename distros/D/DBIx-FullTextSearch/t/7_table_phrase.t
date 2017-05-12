use strict;
$^W = 1;
use vars qw! $dbh !;

require 't/test.lib';
use Test::More tests => 2;
use DBIx::FullTextSearch;

drop_all_tables();

$dbh->do(qq{
CREATE TABLE _fts_test_table_phrase_src (
  UID int(20) NOT NULL,
  Text1 mediumtext,
  Text2 mediumtext,
  PRIMARY KEY (UID)
)});

while ( my $sql = <DATA> ) {
    $dbh->do($sql) or die $dbh->errstr;
}

my $fts = eval {
  DBIx::FullTextSearch->create($dbh, '_fts_test_table_phrase',
        frontend => 'table', backend => 'phrase',
        table_name => '_fts_test_table_phrase_src',
        column_name => ['Text1', 'Text2'],
        column_id_name => 'UID');
};
is( $@, "", "Can create a table FTS with phrase backend" );

foreach my $uid (qw(1 2)) {
    $fts->index_document($uid);
}

my @found = $fts->contains("antique furniture");
is_deeply( \@found, [2], "phrases don't overlap between columns" );
print "# Found: " . join(", ", @found) . "\n";

drop_all_tables();

sub drop_all_tables {
	for my $tableref (@{$dbh->selectall_arrayref('show tables')}) {
		next unless $tableref->[0] =~ /^_fts_test/;
		print "# Dropping $tableref->[0]\n";
		$dbh->do("drop table $tableref->[0]");
		}
}

__DATA__
INSERT INTO _fts_test_table_phrase_src (UID, Text1, Text2) VALUES (1, "Acme Antique", "Furniture - 18th century")
INSERT INTO _fts_test_table_phrase_src (UID, Text1, Text2) VALUES (2, "Antique Furniture", "18th century furniture")
INSERT INTO _fts_test_table_phrase_src (UID, Text1, Text2) VALUES (3, "Acme Antique", "18th century furniture")
