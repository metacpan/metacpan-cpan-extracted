#!perl -T

=head1 PURPOSE

Setup database schema for the following tests.

=cut

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 5;


# Verify that we have a connection to a database.
my $dbh = LocalTest::ok_database_handle();

# Make sure the database type is supported.
my $database_type = LocalTest::ok_database_type( $dbh );

# Make sure the schema exists for this database type.
my $schema_file = "t/SQL/setup_$database_type.sql";
ok(
	-e $schema_file,
	"The SQL configuration file for '$database_type' exists.",
);

# Load the schema.
my $schema;
lives_ok(
	sub
	{
		open( my $fh, '<', $schema_file )
			|| die "Failed to open $schema_file: $!";

		$schema = do { local $/ = undef; <$fh> };

		close( $fh );
	},
	'Retrieve the SQL schema.',
);

# Break the schema into atomic SQL statements. DBI has an option to allow
# executing several statement at once in do(), but it is unevenly supported
# by the DBD::* drivers.
my $statements =
[
	map { s/(^\s+|\s+$)//g; $_ }
	grep { /\w/ }
	split( /;$/m, $schema )
];

subtest(
	'Run SQL statements.',
	sub
	{
		plan( tests => scalar( @$statements ) );

		foreach my $statement ( @$statements )
		{
			# If the statement begins with -- [something] --, then it indicates
			# a short description of that statement.
			my ( $name, $sql ) = $statement =~ /^--\s+(.*?)\s+--\s*(.*)$/s;
			$name ||= 'Run statement.';
			$sql ||= $statement;

			note( $sql );
			lives_ok(
				sub
				{
					$dbh->do( $sql );
				},
				$name,
			);
		}
	}
);

