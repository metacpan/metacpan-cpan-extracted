#!/usr/local/bin/perl

use strict;

use DBI;

my $FILENAME = '../testdata/encantadas.txt';
my $DB = 'DBI:mysql:test';
my $DBAUTH = ':';

my $dbh = DBI->connect($DB, split(':', $DBAUTH, 2)) or die $DBI::errstr;

# Remove the 'if exists' clause if your version of MySQL does not support it
$dbh->do('drop table if exists textindex_doc');

$dbh->do(<<SQL);
create table textindex_doc(
doc_id int unsigned not null,
doc text,
primary key (doc_id)
)
SQL


$/ = "\n\n";

open F, $FILENAME or die "open file error $FILENAME: $!, stopped";

my $sth = $dbh->prepare(<<SQL);
insert into textindex_doc (doc_id, doc) values (?, ?)
SQL

my $doc_id = 1;
while (<F>) {
    $sth->execute($doc_id, $_);
    $doc_id++;
}
close F;

$sth->finish;

$dbh->disconnect;




