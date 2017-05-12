
use strict;
use vars qw! $dbh !;

$^W = 1;

require 't/test.lib';

print "1..7\n";

use DBIx::FullTextSearch;
use Benchmark;

print "ok 1\n";


print "We will drop all the tables first\n";
for (qw! _fts_test _fts_test_data _fts_test_words _fts_test_docid !) {
	local $dbh->{'RaiseError'} = 0;
	local $dbh->{'PrintError'} = 0;
	$dbh->do("drop table $_");
	}

print "ok 2\n";

my $fts;


print "Creating default DBIx::FullTextSearch index\n";
$fts = DBIx::FullTextSearch->create($dbh, '_fts_test', 'backend' => 'column')
				or print "$DBIx::FullTextSearch::errstr\nnot ";
$fts = DBIx::FullTextSearch->open($dbh, '_fts_test')
				or print "$DBIx::FullTextSearch::errstr\nnot ";
print "ok 3\n";


print "Indexing documents\n";
my $t0 = new Benchmark;

$fts->index_document(3, 'krtek leze');
$fts->index_document(5, 'krtek is here, guys');
$fts->index_document(4, 'it is here, krtek');
$fts->index_document(16, 'here is it all');
$fts->index_document(2, 'all I want is here');
$fts->index_document(5, 'krtek rulez here, krtek rules there');

my $t1 = new Benchmark;
print "Indexing took ", timestr(timediff($t1, $t0)), "\n";
print "ok 4\n";


my (@docs, $expected);


print "Calling contains('krtek')\n";
@docs = sort($fts->contains('krtek'));
$expected = '3 4 5';
print "Documents containing `krtek': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 5\n";

print "Calling contains('is')\n";
@docs = sort($fts->contains('is'));
$expected = '16 2 4';
print "Documents containing `is': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 6\n";

print "Calling contains('genius')\n";
my @notfound = $fts->contains('genius');
print 'not ' if @notfound > 0;
print "ok 7\n";

