#!perl
use Test::More qw( no_plan );
select(($|=1,select(STDERR),$|=1)[1]);
BEGIN
{
	use strict;
	use IO::File;
	use File::Basename;
	use IO::Dir;
	use File::Spec;
	use JSON;
	use version;
	our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? 1 : 0;
};

# BEGIN { use_ok( 'DB::Object::Postgres' ); };

SKIP:
{
	eval
	{
		require DBD::Pg;
	};
	skip( "DBD::Pg is not installed", 24 ) if( $@ );
	use_ok( 'DB::Object::Postgres' );
    use_ok( "DB::Object::Postgres::Query" );
    use_ok( "DB::Object::Postgres::Statement" );
    use_ok( "DB::Object::Postgres::Lo" );
    use_ok( "DB::Object::Postgres::Tables" );
	
	# Connection parameters are taken from environment variables (DB_NAME, DB_LOGIN, DB_PASSWD, DB_DRIVER, DB_SCHEMA), or from file (DB_CON_FILE) or from uri (DB_CON_URI)
	# DB_CON_URI=http://localhost:5432?database=postgres&login=jack&
	my $con_params =
	{
	'db'		=> 'postgres',
	'host'		=> ( $ENV{DB_HOST} || 'localhost' ),
	'driver'	=> 'Pg',
	#'debug'		=> 3,
	};
	if( $^O eq 'MSWin32' )
	{
		$con_params->{login} = ( $ENV{DB_LOGIN} || getlogin ) if( !$ENV{DB_CON_FILE} );
	}
	else
	{
		$con_params->{login} = ( $ENV{DB_LOGIN} || getlogin || (getpwuid( $> ))[0] ) if( !$ENV{DB_CON_FILE} );
	}
	my $dbh1 = DB::Object->connect( $con_params );
	if( !defined( $dbh1 ) )
	{
		skip( "Database connection failed, cancelling other tests: ". DB::Object->error, 17 );
	}

	# $pg->debug( 3 );
	ok( $dbh1, "Getting DB::Object::Postgres object" );
	isa_ok( $dbh1, 'DB::Object::Postgres', "Checking class of object" );
	# should trigger a connection using our shell login id and postgres database
	$ENV{DB_HOST} ||= 'localhost';
	my @db = $dbh1->databases;
	ok( @db, "Checking available databases" );
	diag( sprintf( "Found the databases: %s", join( ", ", @db ) ) );
	if( grep( /^postgres$/, @db ) )
	{
		pass( "postgres availability" );
	}
	else
	{
		fail( "postgres availability" );
	}

	# ok( $dbh, "Testing connection" );
	our $test_db = 'db_object_pg_test';
	if( scalar( grep( /^$test_db$/, @db ) ) )
	{
		diag( "Switching database to template1 to drop the old test database $test_db" );
		if( !$dbh1->use( 'postgres' ) )
		{
			fail( "Could not switch to database postgres" )
		}
		else
		{
			pass( "Switching database" );
			my $rv = $dbh1->do( "DROP DATABASE $test_db" );
			ok( $rv, "Dropping leftover test database $test_db" );
		}
	}
	else
	{
		pass( "No leftover test database $test_db" );
	}

	our $dbh = $dbh1->create_db( $test_db );
	ok( $dbh, "Creating database $test_db" );
	BAIL_OUT( "Unable to create database $test_db: " . $dbh1->error ) if( !$dbh );

	my $schemaFile = File::Spec->catfile( File::Basename::dirname(__FILE__), 'pgsql.sql' );
	my $fh = IO::File->new( "<$schemaFile" ) || BAIL_OUT( "Unable to read the schema file \"$schemaFile\": $!" );
	$fh->binmode( ':utf8' );
	my $sql = join( '', $fh->getlines );
	$fh->close;
	my $rv = $dbh->do( $sql ) || BAIL_OUT( "Unable to load schema file \"$schemaFile\": " . $dbh->errstr );
	ok( $rv, "Loading schema file \"$schemaFile\"" );

	is( scalar( @{$dbh->tables} ), 3, "Total number of tables expected (3)" );
	is( $dbh->table_exists( 'customers' ), 1, "Checking table_exists with table customers" );
	my $cust = $dbh->customers || fail( "Cannot get customers object." );
	pass( sprintf( "Got customers object: %s", ref( $cust ) ) );
	isa_ok( $cust, 'DB::Object::Postgres::Tables', "Getting customers table object" );
	is( $cust->name, 'customers', "Checking customers table name" );
	$cust->where( email => 'john@example.org' );
	my $str = $cust->delete->as_string;
	is( $str, "DELETE FROM customers WHERE email='john\@example.org'", "Checking DELETE query" );

	{
		local $SIG{__WARN__} = sub{};
		my $fake_tbl = $dbh->table( 'plop' );
		is( $fake_tbl, undef(), "Checking fake table 'plop'" );
	}

	my $result;
	if( $dbh->version >= version->declare('9.5') )
	{
	    
        $cust->on_conflict(
            target  => 'on constraint idx_customers',
            action  => 'update',
        );
	}
	my $cust_sth_ins = $cust->insert(
		first_name => 'Paul',
		last_name => 'Goldman',
		email => 'paul@example.org',
		active => 0,
	) || fail( "Error while create query to add data to table customers: " . $cust->error );
	pass( "Customer insert query object" );
	$result = $cust_sth_ins->as_string;
    
    my $expected;
    if( $dbh->version >= version->declare( '9.5' ) )
    {
        diag( "Testing INSERT with ON CONFLICT clause since database version is higher or equal to 9.5" ) if( $DEBUG );
        # <https://www.postgresql.org/docs/9.5/sql-insert.html>
        $expected = <<SQL;
INSERT INTO customers (first_name, last_name, email, active) VALUES('Paul', 'Goldman', 'paul\@example.org', '0') ON CONFLICT ON CONSTRAINT idx_customers DO UPDATE SET first_name='Paul', last_name='Goldman', email='paul\@example.org', active='0'
SQL
    }
    else
    {
        diag( "Testing INSERT withour ON CONFLICT clause since database version is lower than to 9.5" ) if( $DEBUG );
        $expected = <<SQL;
INSERT INTO customers (first_name, last_name, email, active) VALUES('Paul', 'Goldman', 'paul\@example.org', '0')
SQL
    }
	chomp( $expected );
	is( $result, $expected, "Checking INSERT statement" );
	$cust->reset;

	# Checking select query
	$cust->where( email => 'john@example.org' );
	$cust->order( 'last_name' );
	$cust->having( email => qr/\@example/ );
	$cust->limit( 10 );
	my $cust_sth_sel = $cust->select || fail( "An error occurred while creating a query to select data frm table customers: " . $cust->error );
	pass( "Customer select query object" );
	$result = $cust_sth_sel->as_string;
	$expected = <<SQL;
SELECT id, first_name, last_name, email, created, modified, active, EXTRACT( EPOCH FROM created::TIMESTAMP )::INTEGER AS created_unixtime, EXTRACT( EPOCH FROM modified::TIMESTAMP )::INTEGER AS modified_unixtime, CONCAT(first_name, ' ', last_name) AS name FROM customers WHERE email='john\@example.org' HAVING email ~ '\\\@example' ORDER BY last_name LIMIT 10
SQL
	chomp( $expected );
	is( $result, $expected, "Checking SELECT query on customers table" );

	# Checking update query
	$cust->reset;
	$cust->where( email => 'john@example.org' );
	my $cust_sth_upd = $cust->update( active => 0 ) || fail( "An error has occurred while trying to create an update query for table customers: " . $cust->error );
	pass( "Customer update query object" );
	$result = $cust_sth_upd->only->as_string;
	$expected = <<SQL;
UPDATE ONLY customers SET active='0' WHERE email='john\@example.org'
SQL
	chomp( $expected );
	is( $result, $expected, "Checking UPDATE query on customers table using ONLY clause" );

	# diag( "Removing test database $test_db" );
	my $dbh2;
	if( !( $dbh2 = $dbh->use( 'template1' ) ) )
	{
		diag( "Unable to switch to database template1" );
	}
	else
	{
		$dbh->disconnect();
		my $rv = $dbh2->do( "DROP DATABASE $test_db" );
		diag "Dropping leftover test database $test_db " . ( $rv ? 'succeeded' : 'failed' );
	}
}

END
{
	# diag( "Cleaning up using database object $dbh" );
	if( $dbh )
	{
		# diag "Cleaning up. Dropping database $test_db";
		# diag( "Disconnecting from database $test_db" );
		#$dbh->disconnect();
	}
};

# done_testing();

__END__

