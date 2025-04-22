package DB;

use strict;
use warnings;

use Rose::DB;
use base qw(Rose::DB);
use Data::Dumper;

# Use a private registry for this class
__PACKAGE__->use_private_registry;


# Register your lone data source using the default type and domain
__PACKAGE__->register_db(
	domain          => 'development',
	type            => 'main',
	driver          => 'sqlite',
	database        => 't/rose_test_db',
	connect_options => {
		RaiseError   => 1,
		AutoCommit   => 1,
		PrintError   => 0,
		sqlite_trace => 1,
	}
);

my $mysqld_check = system("which mysqld > /dev/null 2>&1");
my $mysql_config_check = system("which mysql_config > /dev/null 2>&1");

if ($mysqld_check == 0 && $mysql_config_check == 0) {
	require Test::mysqld;

	our $mysqld = Test::mysqld->new(
		my_cnf => {
			'skip-networking' => '',
			'user'            => $ENV{USER} // 'root',
		}
	) or die "Failed to start Test::mysqld";


	__PACKAGE__->register_db(
		domain          => 'mysql_test',
		type            => 'mysql_test',
		driver          => 'mysql',
		dsn             => $mysqld->dsn(dbname => 'test'),
		username        => 'root',
		password        => '',
		connect_options => {
			RaiseError => 1,
			AutoCommit => 1,
			PrintError => 0,
		}
	);

}

1;
