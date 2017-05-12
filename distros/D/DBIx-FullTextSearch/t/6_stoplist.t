
use strict;
use vars qw! $dbh !;

$^W = 1;

require 't/test.lib';

print "1..10\n";

use DBIx::FullTextSearch::StopList;

print "ok 1\n";

print "We will drop all the tables first\n";
for (qw! _sl_test_stoplist !) {
	local $dbh->{'RaiseError'} = 0;
	local $dbh->{'PrintError'} = 0;
	$dbh->do("drop table $_");
}

print "ok 2\n";

print "We will create an empty index and insert a few words into it\n";

my $sl = DBIx::FullTextSearch::StopList->create_empty($dbh, '_sl_test');
$sl->add_stop_word(['the','a','on']);

print "Stop word 'the' not in index\nnot " unless $sl->is_stop_word('the');
print "ok 3\n";

print "Stop word 'a' not in index\nnot " unless $sl->is_stop_word('a');
print "ok 4\n";

$sl->remove_stop_word(['on','the']);

print "Stop word 'the' in index\nnot " if $sl->is_stop_word('the');
print "ok 5\n";

$sl->drop;

print "Stop word 'a' in index\nnot " if $sl->is_stop_word('a');
print "ok 6\n";

print "We will create a stoplist with the default english stop words and delete a few words\n";

$sl = DBIx::FullTextSearch::StopList->create_default($dbh, '_sl_test', 'english');
$sl->add_stop_word(['process']);

print "Stop word 'because' not in index\nnot " unless $sl->is_stop_word('because');
print "ok 7\n";

print "Stop word 'process' not in index\nnot " unless $sl->is_stop_word('process');
print "ok 8\n";

$sl->remove_stop_word(['but','by']);

print "Stop word 'by' in index\nnot " if $sl->is_stop_word('by');
print "ok 9\n";

$sl->empty;

print "Stop word 'a' in index\nnot " if $sl->is_stop_word('a');
print "ok 10\n";
