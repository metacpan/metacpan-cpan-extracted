package Music::DBI;

use strict;
use base qw(Class::DBI);
use Class::DBI::Plugin::MultiDatabases;


my @database = qw(testdb1 testdb2);


Music::DBI->set_connections(
	$database[0] => ["dbi:SQLite:dbname=$database[0]", '', ''],
	$database[1] => ["dbi:SQLite:dbname=$database[1]", '', ''],
);

sub databases {
	return @database;
}

sub has_databases {
	return (-e "./$database[0]" and -e "./$database[1]");
}

sub skip_message {
	return "This test suite require DBD::SQLite.";
}

1;
