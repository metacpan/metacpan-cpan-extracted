
use strict;
use vars qw! $dbh !;

$^W = 1;

require 't/test.lib';

print "1..9\n";

use DBIx::FullTextSearch;

print "ok 1\n";


sub get_tables_list {
	return grep /^_fts_test(?!_the_table$)/,
		map { $_->[0] } @{ $dbh->selectall_arrayref('show tables') };
	}

print "We will drop all the tables first\n";
for (qw! _fts_test _fts_test_data _fts_test_words _fts_test_docid !) {
	local $dbh->{'RaiseError'} = 0;
	local $dbh->{'PrintError'} = 0;
	$dbh->do("drop table $_");
	}
my $fts;
my @tables;

print "Now check that everything was dropped\n";

@tables = get_tables_list();
if (@tables) {
	print "The following tables were not dropped: @tables\nnot ";
	}
print "ok 2\n";


print "Creating default DBIx::FullTextSearch index\n";
$fts = DBIx::FullTextSearch->create($dbh, '_fts_test') or print "$DBIx::FullTextSearch::errstr\nnot ";
print "ok 3\n";


@tables = get_tables_list();
if ("@tables" ne '_fts_test _fts_test_data') {
	print "After the index was created, @tables were found\nnot ";
	}
print "ok 4\n";


print "Now we will drop the index\n";
$fts->drop or print $fts->errstr, "\nnot ";
print "ok 5\n";

@tables = get_tables_list();
if (@tables) {
	print "The following tables were not dropped: @tables\nnot ";
	}
print "ok 6\n";


print "Creating DBIx::FullTextSearch index with blob backend and file frontend\n";
$fts = DBIx::FullTextSearch->create($dbh, '_fts_test', 'backend' => 'blob',
		'frontend' => 'file') or print "$DBIx::FullTextSearch::errstr\nnot ";
print "ok 7\n";


print "Now we will drop the index\n";
$fts->drop or print $fts->errstr, "\nnot ";
print "ok 8\n";

@tables = get_tables_list();
if (@tables) {
	print "The following tables were not dropped: @tables\nnot ";
	}
print "ok 9\n";

