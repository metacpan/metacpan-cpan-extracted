
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
$fts = DBIx::FullTextSearch->create($dbh, '_fts_test',
	'frontend' => 'string') or print "$DBIx::FullTextSearch::errstr\nnot ";
print "ok 3\n";


print "Indexing documents\n";
my $t0 = new Benchmark;

$fts->index_document('krtek', 'krtek leze');
$fts->index_document('jezek', 'jezek leze taky');
$fts->index_document('zirafa', 'zirafa ma dlouhej krk');
$fts->index_document('jezek', 'jezek leze a ma bodliny');
$fts->index_document('slon', 'slon mava chobotem');
$fts->index_document('slon_krtek', 'slon mava s krtkem');

my $t1 = new Benchmark;
print "Indexing took ", timestr(timediff($t1, $t0)), "\n";
print "ok 4\n";


my (@docs, $expected);


print "Calling contains('krtek')\n";
@docs = sort($fts->contains('krt*'));
$expected = 'krtek slon_krtek';
print "Documents containing `krt*': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 5\n";

print "Calling contains('ma')\n";
@docs = sort($fts->contains('ma'));
$expected = 'jezek zirafa';
print "Documents containing `ma': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 6\n";

print "Calling contains('genius')\n";
my @notfound = $fts->contains('genius');
print 'not ' if @notfound > 0;
print "ok 7\n";

