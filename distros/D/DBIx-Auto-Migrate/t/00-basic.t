use v5.16.3;
use strict;
use warnings;
use Test::More;
use Test::PostgreSQL;
use Test::Exception;
eval { Test::PostgreSQL->new() }
    or plan skip_all => $@;
my $create_index = sub {
	my ($table, $column) = @_;
	if (!$table) {
		die 'Index requires table';
	}
	if (!$column) {
		die 'Index requires column';
	}
	return "CREATE INDEX index_${table}_${column} ON $table ($column)";

};
{
	my $temporal_db = Test::PostgreSQL->new;
	my $dsn = $temporal_db->dsn;
	my $user = 'postgres';
	my $pass = undef; 
	eval "
	package MyCompany::DB {
		use v5.16.3;
		use strict;
		use warnings;

		use DBIx::Auto::Migrate;
		finish_auto_migrate;
	}
	";
	ok $@, 'All the required methods must be defined';
	package MyCompany::DB1 {
		use v5.16.3;
		use strict;
		use warnings;

		use DBIx::Auto::Migrate;

		finish_auto_migrate;

		sub migrations {
			return (
				'CREATE table options (
					id BIGSERIAL PRIMARY KEY,
					name TEXT NOT NULL,
					value TEXT NOT NULL,
					UNIQUE (name),
					UNIQUE (value)
				)',
				$create_index->(qw/options name/),
			);
		}

		sub dsn {
			return $dsn;
		}
		
		sub user {
			return $user;
		}

		sub pass {
			return $pass;
		}
	}
	my $dbh = MyCompany::DB1->connect;
	my $row = $dbh->selectrow_hashref('select * from options where name = ?', undef, 'current_migration');
	is $row->{value}, 2, 'Migration correctly applied';
}
{
	my $temporal_db = Test::PostgreSQL->new;
	my $dsn = $temporal_db->dsn;
	my $user = 'postgres';
	my $pass = undef; 
	package MyCompany::DB2 {
		use v5.16.3;
		use strict;
		use warnings;

		use DBIx::Auto::Migrate;

		finish_auto_migrate;

		sub migrations {
			return (
				'CREATE table options (
					id BIGSERIAL PRIMARY KEY,
					name TEXT NOT NULL,
					value TEXT NOT NULL,
					UNIQUE (name),
					UNIQUE (value)
				)',
				$create_index->(qw/options name/),
				'CREATE TABLE users (
				syntax_error,
				)',
			);
		}

		sub dsn {
			return $dsn;
		}
		
		sub user {
			return $user;
		}

		sub pass {
			return $pass;
		}
	}
	throws_ok {
		my $dbh = MyCompany::DB2->connect;
	} qr/syntax error/, 'Errors in migrations are correctly caught';
}
done_testing;
1;
