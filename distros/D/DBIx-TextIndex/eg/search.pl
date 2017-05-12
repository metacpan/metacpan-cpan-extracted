#!/usr/local/bin/perl

use strict;

use DBI;
use DBIx::TextIndex;

my $DB = 'DBI:mysql:test';
my $DBAUTH = ':';

my $DEBUG = 0;

my $doc_dbh = DBI->connect($DB, split(':', $DBAUTH, 2)) or die $DBI::errstr;
my $index_dbh = DBI->connect($DB, split(':', $DBAUTH, 2)) or die $DBI::errstr;

my $index = DBIx::TextIndex->new({
    doc_dbh => $doc_dbh,
    index_dbh => $index_dbh,
    collection => 'encantadas',
    print_activity => $DEBUG,
});

print "Enter a search string: ";

my $query = <STDIN>;

chomp $query;

my $results;
eval {
    $results = $index->search({doc => $query});
};
if ($@) {
    if ($@->isa('DBIx::TextIndex::Exception::Query')) {
	print "\n" . $@->error . "\n\n";
    } else {
	print $@->error . "\n\n" . $@->trace . "\n";
    }
} else {
    foreach my $doc_id (sort {$$results{$b} <=> $$results{$a}} keys %$results)
    {
	print "Paragraph: $doc_id  Score: $$results{$doc_id}\n";
    }
}

$index_dbh->disconnect;
$doc_dbh->disconnect;
