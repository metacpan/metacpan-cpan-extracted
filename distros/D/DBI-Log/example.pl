#!/usr/bin/perl
use strict;
use warnings;
use DBI::Log;
use DBI;

END {unlink "foo.db"};

my %params = (RaiseError => 1, PrintError => 0);
my $dbh = DBI->connect("dbi:SQLite:dbname=foo.db", "", "", \%params);

my $sth = $dbh->prepare("CREATE TABLE foo (a INT, b INT)");
$sth->execute();
$dbh->do("INSERT INTO foo VALUES (?, ?)", undef, 1, 2);
$dbh->selectcol_arrayref("SELECT * FROM foo");
$dbh->do("INSERT INTO bar VALUES (?, ?)", undef, 1, 2);

