
use strict;
use vars qw! $dbh !;

$^W = 1;

require 't/test.lib';

print "1..10\n";

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
$fts = DBIx::FullTextSearch->create($dbh, '_fts_test',
	'backend' => 'phrase') or print "$DBIx::FullTextSearch::errstr\nnot ";
print "ok 3\n";


print "Indexing documents\n";
my $t0 = new Benchmark;

$fts->index_document(3, 'krtek leze');
$fts->index_document(5, 'krtek jeste leze, panove');
$fts->index_document(4, 'it is here, krtek with jezek');
$fts->index_document(16, 'here is it all');
$fts->index_document(2, 'krtek with zirafa are friends');

my $t1 = new Benchmark;
print "Indexing took ", timestr(timediff($t1, $t0)), "\n";
print "ok 4\n";


print "We will compare sorted results to solve problem with documents
that have the same number of word occurencies.\n";

my (@docs, $expected, @param);

### print "Pid: $$\n";

@param = 'krtek';
print "Calling contains(@param)\n";
@docs = sort($fts->contains(@param));
$expected = '2 3 4 5';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 5\n";


@param = 'krtek with';
print "Calling contains(@param)\n";
@docs = sort($fts->contains(@param));
$expected = '2 4';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 6\n";



@param = 'genius';
print "Calling contains(@param)\n";
my @notfound = $fts->contains(@param);
print 'not ' if @notfound > 0;
print "ok 7\n";


@param = 'is it';
print "Calling contains(@param)\n";
@docs = $fts->contains(@param);
$expected = '16';
print "Got: @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 8\n";


@param = 'leze';
print "Calling contains(@param)\n";
@docs = sort($fts->contains(@param));
$expected = '3 5';
print "Got: @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 9\n";

@param = 'here and (krtek or here)';
print "Calling search(@param)\n";
@docs = sort($fts->search(@param));
$expected = '16 4';
print "Got: @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 10\n";
