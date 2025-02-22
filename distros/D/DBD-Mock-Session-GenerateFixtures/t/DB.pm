package DB;

use strict;
use warnings;

use Rose::DB;
use base qw(Rose::DB);

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

1;
