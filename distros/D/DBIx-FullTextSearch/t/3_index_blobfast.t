
use strict;
use vars qw! $dbh !;

$^W = 1;

require 't/test.lib';

print "1..9\n";

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
$fts = DBIx::FullTextSearch->create($dbh, '_fts_test', 'backend' => 'blobfast') or print "$DBIx::FullTextSearch::errstr\nnot ";
$fts = DBIx::FullTextSearch->open($dbh, '_fts_test') or print "$DBIx::FullTextSearch::errstr\nnot ";
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


print "We will compare sorted results to solve problem with documents
that have the same number of word occurencies.\n";

my (@docs, $expected, @param);

@param = 'krtek';
print "Calling contains(@param)\n";
@docs = sort($fts->contains(@param));
$expected = '3 4 5';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 5\n";


@param = 'is';
print "Calling contains(@param)\n";
@docs = sort($fts->contains(@param));
$expected = '16 2 4';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 6\n";



@param = 'genius';
print "Calling contains(@param)\n";
my @notfound = $fts->contains(@param);
print 'not ' if @notfound > 0;
print "ok 7\n";


@param = qw!+krt* -rulez +is!;
print "Calling econtains(@param)\n";
@docs = $fts->econtains(@param);
$expected = '4';
print "Got: @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 8\n";


@param = qw!krt* -all is -rulez!;
print "Calling econtains(@param)\n";
@docs = sort($fts->econtains(@param));
$expected = '3 4';
print "Got: @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 9\n";

