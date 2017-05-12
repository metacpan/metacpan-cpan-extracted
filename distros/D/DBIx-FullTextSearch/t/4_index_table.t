
use strict;
use vars qw! $dbh !;

$^W = 1;

require 't/test.lib';

print "1..15\n";

use DBIx::FullTextSearch;
use Benchmark;

print "ok 1\n";


print "We will drop all the tables first\n";
for (qw! _fts_test _fts_test_data _fts_test_words _fts_test_docid 
		_fts_test_the_table !) {
	local $dbh->{'RaiseError'} = 0;
	local $dbh->{'PrintError'} = 0;
	$dbh->do("drop table $_");
	}

print "ok 2\n";


print "We will create the _fts_test_the_table table\n";
$dbh->do('create table _fts_test_the_table (id tinyint not null,
			t_data varchar(255),
			primary key(id))');

print "ok 3\n";

$dbh->do(q!insert into _fts_test_the_table values (2, 'jezek ma bodliny')!);
$dbh->do(q!insert into _fts_test_the_table values (3, 'krtek bodliny nema')!);

my $fts;

print "Creating DBIx::FullTextSearch index with table frontend\n";
$fts = DBIx::FullTextSearch->create($dbh, '_fts_test',
	'frontend' => 'table', 'table_name' => '_fts_test_the_table',
	'column_name' => 't_data')
					or print "$DBIx::FullTextSearch::errstr\nnot ";
print "ok 4\n";

$fts = DBIx::FullTextSearch->open($dbh, '_fts_test') or print "$DBIx::FullTextSearch::errstr\nnot ";
print "ok 5\n";

my (@docs, $expected, @param, $words);

$words = $fts->index_document(2);
print "Indexed 2, got $words words\n";
$words = $fts->index_document(3);
print "Indexed 3, got $words words\n";

@param = 'bodl*';
print "Calling contains(@param)\n";
@docs = sort($fts->contains(@param));
$expected = '2 3';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 6\n";


@param = 'nema';
print "Calling contains(@param)\n";
@docs = sort($fts->contains(@param));
$expected = '3';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 7\n";

$words = $fts->index_document(5);
print "Indexed 5, got $words words\n";

$dbh->do(q!insert into _fts_test_the_table values (5, 'zirafa taky nema bodliny')!);

$words = $fts->index_document(5, 'notindatabase');
print "Indexed 5, got $words words\n";

@param = 'nema';
print "Calling contains(@param)\n";
@docs = sort($fts->contains(@param));
$expected = '3 5';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 8\n";

@param = 'notindatabase';
print "Calling contains(@param)\n";
@docs = sort($fts->contains(@param));
$expected = '5';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 9\n";

print "Drop the DBIx::FullTextSearch index\n";
$fts->drop or print $fts->errstr, "\nnot ";
print "ok 10\n";

print "Drop the _fts_test_the_table table\n";
$dbh->do('drop table _fts_test_the_table');


# Now the section with TableString

print "We will create the _fts_test_the_table table\n";
$dbh->do('create table _fts_test_the_table (name varchar(14) not null,
			t_data varchar(255),
			primary key(name))');

print "ok 11\n";

$dbh->do(q!insert into _fts_test_the_table values ('jezek', 'jezek ma bodliny')!);
$dbh->do(q!insert into _fts_test_the_table values ('krtek', 'krtek bodliny nema')!);

print "Creating DBIx::FullTextSearch index with table frontend against stringed table\n";
$fts = DBIx::FullTextSearch->create($dbh, '_fts_test',
	'frontend' => 'table', 'table_name' => '_fts_test_the_table',
	'column_name' => 't_data')
					or print "$DBIx::FullTextSearch::errstr\nnot ";
print "ok 12\n";

$fts = DBIx::FullTextSearch->open($dbh, '_fts_test') or print "$DBIx::FullTextSearch::errstr\nnot ";
print "ok 13\n";


$words = $fts->index_document('jezek');
print "Indexed jezek, got $words words\n";
$words = $fts->index_document('krtek');
print "Indexed krtek, got $words words\n";

@param = 'bodl*';
print "Calling contains(@param)\n";
@docs = sort($fts->contains(@param));
$expected = 'jezek krtek';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 14\n";


@param = 'nema';
print "Calling contains(@param)\n";
@docs = sort($fts->contains(@param));
$expected = 'krtek';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 15\n";

$fts->drop;


