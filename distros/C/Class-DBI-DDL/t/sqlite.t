# vim: set ft=perl :

package MyDBI;
use DBI;
use Test::More;
use base 'Class::DBI::DDL';

if (grep { $_ eq 'SQLite' } DBI->available_drivers) {
	MyDBI->set_db('Main', 'dbi:SQLite:dbname=testdb');

	require 't/tables.pl';
	require 't/tests.pl';
} else {
	plan
		skip_all =>
			"Not testing SQLite driver. It does not appear to be installed. $@"
}
