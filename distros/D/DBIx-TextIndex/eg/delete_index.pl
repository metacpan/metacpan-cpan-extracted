#!/usr/local/bin/perl

use strict;

use DBI;
use DBIx::TextIndex;

my $DB = 'DBI:mysql:test';
my $DBAUTH = ':';

my $doc_dbh = DBI->connect($DB, split(':', $DBAUTH, 2)) or die $DBI::errstr;
my $index_dbh = DBI->connect($DB, split(':', $DBAUTH, 2)) or die $DBI::errstr;

my $index = DBIx::TextIndex->new({
    doc_dbh => $doc_dbh,
    index_dbh => $index_dbh,
    collection => 'encantadas',
});

$index->delete;

$index_dbh->disconnect;
$doc_dbh->disconnect;
