# vim: set ft=perl :

package MyDBI;
use DBI;
use Test::More;
use base 'Class::DBI::DDL';

if ($ENV{CLASS_DBI_DDL_PG} && grep { $_ eq 'Pg' } DBI->available_drivers) {
	my $database = $ENV{CLASS_DBI_DDL_PG_DATABASE} || 'dbi:Pg:dbname=testdb';
	my $username = $ENV{CLASS_DBI_DDL_PG_USERNAME} || 'testuser';
	my $password = $ENV{CLASS_DBI_DDL_PG_PASSWORD} || 'testpass';
	MyDBI->set_db('Main', $database, $username, $password);

	require 't/tables.pl';
	require 't/tests.pl';
} else {
	plan
		skip_all => 
			"Not testing PostgreSQL driver, please set CLASS_DBI_DDL_PG in the environment and install DBD::Pg. See README for details.";
}
