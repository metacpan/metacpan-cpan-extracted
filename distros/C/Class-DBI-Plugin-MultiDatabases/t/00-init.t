use strict;

use Test::More tests => 2;

use lib qw(t/lib);
use DBI;

BEGIN {
	use_ok('Music::DBI');
}

my $dbh;
my @database = Music::DBI->databases;

if(-e "./$database[0]"){
	unlink "./$database[0]" or warn $!;
	unlink "./$database[1]" or warn $!;
}

eval q| require DBD::SQLite |;

SKIP: {
	skip (Music::DBI->skip_message, 1) if($@);

for my $db (@database){
	$dbh = DBI->connect("dbi:SQLite:dbname=$db","","");

	$dbh->do(<<SQL); # Table cd
CREATE TABLE cd (
	cdid   INTEGER PRIMARY KEY,
	artist TEXT,
	title  TEXT,
	year   INTEGER
);
SQL

	$dbh->do(<<SQL); # Table artist
CREATE TABLE artist (
	artistid TEXT PRIMARY KEY,
	name     TEXT
);
SQL

	$dbh->do(<<SQL); # Table liner_notes
CREATE TABLE liner_notes (
	cdid  INTEGER PRIMARY KEY,
	notes TEXT
);
SQL

	for my $i (1..3){
	my $year = 2000 + $i;
	$dbh->do(<<SQL)  or warn $!;
INSERT INTO cd VALUES ($i, 'artist $db-$i', 'title $db-$i', $year)
SQL

	my $name = $db . ' ' . $i x 3;
	$dbh->do(<<SQL)  or warn $!;
INSERT INTO artist VALUES ('artist $db-$i', "$name")
SQL

	$dbh->do(<<SQL)  or warn $!;
INSERT INTO liner_notes VALUES ($i, 'notes $db-$i')
SQL

	}

}

ok(1, "create databases and tables");
}


