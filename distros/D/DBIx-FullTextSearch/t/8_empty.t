
use strict;
use vars qw! $dbh !;

$^W = 1;

require 't/test.lib';

print "1..6\n";

use DBIx::FullTextSearch;

print "ok 1\n";

print "We will drop all the tables first\n";
for (qw! _fts_test _fts_test_data _fts_test_words _fts_test_docid !) {
	local $dbh->{'RaiseError'} = 0;
	local $dbh->{'PrintError'} = 0;
	$dbh->do("drop table $_");
	}
my $fts;
my @tables;

print "Creating default DBIx::FullTextSearch index\n";
$fts = DBIx::FullTextSearch->create($dbh, '_fts_test') or print "$DBIx::FullTextSearch::errstr\nnot ";
print "ok 2\n";

$fts->index_document(3, 'krtek leze');

my ($max_doc_id) = $dbh->selectrow_array("select value from _fts_test where param='max_doc_id'");
print "max_doc_id = $max_doc_id, expected 1\nnot " unless $max_doc_id == 3;
print "ok 3\n";

print "Now we will empty the index\n";
$fts->empty or print $fts->errstr, "\nnot ";
print "ok 4\n";

($max_doc_id) = $dbh->selectrow_array("select value from _fts_test where param='max_doc_id'");
print "max_doc_id = $max_doc_id, expected 0\nnot " unless $max_doc_id == 0;
print "ok 5\n";

my ($count) = $dbh->selectrow_array("select count(*) from _fts_test_data");
print "count = $count, expected 0\nnot " unless $count == 0;
print "ok 6\n";
