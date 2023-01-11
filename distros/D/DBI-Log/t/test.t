#!/usr/bin/perl
use strict;
use warnings;
use lib "lib";
use Test::More;
use DBI;
use DBI::Log file => "foo.sql";

END {
    unlink "foo.db";
    unlink "foo.sql";
};

my $dbh = DBI->connect("dbi:SQLite:dbname=foo.db", "", "", {RaiseError => 1, PrintError => 0});

my $sth = $dbh->prepare("CREATE TABLE foo (a INT, b INT)");
$sth->execute();
$dbh->do("INSERT INTO foo VALUES (?, ?)", undef, 1, 2);
$dbh->selectcol_arrayref("SELECT * FROM foo");
eval {$dbh->do("INSERT INTO bar VALUES (?, ?)", undef, 1, 2)};

my $output = `cat foo.sql`;
like $output, qr/^-- .*
-- execute .*
CREATE TABLE foo \(a INT, b INT\)

-- .*
-- do .*
INSERT INTO foo VALUES \('1', '2'\)

-- .*
-- selectcol_arrayref .*
SELECT \* FROM foo

-- .*
-- do .*
INSERT INTO bar VALUES \('1', '2'\)
/, "log output";

done_testing();

