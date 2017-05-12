# vim: set ft=perl :

package MyDBI;
use DBI;
use Test::More;
use base 'Class::DBI::DDL';

if ($ENV{CLASS_DBI_DDL_MYSQL} && grep { $_ eq 'mysql' } DBI->available_drivers) {
	my $database = $ENV{CLASS_DBI_DDL_MYSQL_DATABASE} || 'dbi:mysql:testdb';
	my $username = $ENV{CLASS_DBI_DDL_MYSQL_USERNAME} || 'testuser';
	my $password = $ENV{CLASS_DBI_DDL_MYSQL_PASSWORD} || 'testpass';
	MyDBI->set_db('Main', $database, $username, $password);

	require 't/tables.pl';
	require 't/tests.pl';
} else {
	plan
		skip_all =>
			"Not testing MySQL driver, please set CLASS_DBI_DDL_MYSQL in the environment and install DBD::mysql. See README for details.";
}
