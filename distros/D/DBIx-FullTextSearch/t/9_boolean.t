
use strict;
use vars qw! $dbh !;

$^W = 1;

require 't/test.lib';

print "1..18\n";

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

$fts->index_document(1, 'the rain in spain falls mostly in the plains');
$fts->index_document(2, 'rain rain go away');
$fts->index_document(3, 'plains blains bbbb foo bar');
$fts->index_document(4, 'foo bar baz caz baz ddd');
$fts->index_document(5, 'rain falls mostly here there anywhere mcdonalds');
$fts->index_document(6, 'DBIx::FullTextSearch is a Perl module to index documents');
$fts->index_document(7, 'DBIx::FullTextSearch is available on CPAN');
$fts->index_document(8, 'There are many Perl modules available on CPAN');
$fts->index_document(9, 'Perl has one of the largest collections of open source libraries');
$fts->index_document(10, 'Lucene is probably one of the best indexing solutions, available for Java');
$fts->index_document(11, 'foo perl probably many baz ddd');
$fts->index_document(12, 'aaa bbb ccc ddd eee bar');

my $t1 = new Benchmark;
print "Indexing took ", timestr(timediff($t1, $t0)), "\n";
print "ok 4\n";

print "We will compare sorted results to solve problem with documents
that have the same number of word occurencies.\n";

my (@docs, $expected, @param);

my $i = 5;

test_search('DBIx::FullTextSearch','6 7');
test_search('(CPAN or DBIx::FullTextSearch) and Perl','6 8');
test_search('Perl AND (CPAN or DBIx::FullTextSearch)','6 8');
test_search('(rain OR Perl) AND (largest OR mostly)','1 5 9');
test_search('baz OR (plains AND bbbb)','11 3 4');
test_search('foo or bar','11 12 3 4');
test_search('foo and bar','3 4');
sub test_search {
  my ($param, $expected) = @_;
  print "Calling search($param)\n";
  @docs = sort($fts->search($param));
  print "Got: @docs\n";
  print "Expected $expected\nnot " unless "@docs" eq $expected;
  print "ok $i\n";
  $i++;
  @docs = sort(keys %{$fts->search_hashref($param)});
  print "Got: @docs\n";
  print "Expected $expected\nnot " unless "@docs" eq $expected;
  print "ok $i\n";
  $i++;
}
