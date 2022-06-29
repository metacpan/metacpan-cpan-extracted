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
	our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

# BEGIN { use_ok( 'DB::Object::Postgres' ); };

SKIP:
{
	eval
	{
		require DBD::Pg;
	};
	skip( "DBD::Pg is not installed", 25 ) if( $@ );
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
	
	# Checking sub-query in field operation
	my $orders_tbl = $dbh->orders || fail( 'Cantot get the orders table' );
	$cust->reset;
	$cust->where( $cust->fo->last_name == '?' );
	my $sub_sth = $cust->select( 'id' );
	$orders_tbl->where(
	    $dbh->AND(
	        $orders_tbl->fo->id == '?',
	        $orders_tbl->fo->cust_id == $sub_sth
	    )
	);
	my $order_sth_del = $orders_tbl->delete || fail( "An error has occurred while trying to create a delete query for table orders: " . $orders_tbl->error );
	pass( "Orders delete query object" );
	$result = $order_sth_del->as_string;
	diag( "delete query with sub-query in field operation is: $result" ) if( $DEBUG );
	$expected = <<SQL;
DELETE FROM orders WHERE id = ? AND cust_id = (SELECT id FROM customers WHERE last_name = ?)
SQL
	chomp( $expected );
	is( $result, $expected, "Checking DELETE query on orders table using sub-query" );
	
	$orders_tbl->reset;
	my $P = $dbh->placeholder( type => 'inet' );
    $orders_tbl->where( $dbh->OR( $orders_tbl->fo->ip_addr == "inet $P", "inet $P" << $orders_tbl->fo->ip_addr ) );
    my $order_ip_sth = $orders_tbl->select( 'id' ) || fail( "An error has occurred while trying to create a select by ip query for table orders: " . $orders_tbl->error );
	pass( "Orders select by ip query object" );
	$result = $order_ip_sth->as_string;
	diag( "select by ip query in field operation is: $result" ) if( $DEBUG );
	$expected = <<SQL;
SELECT id FROM orders WHERE ip_addr = inet ? OR inet ? << ip_addr
SQL
	chomp( $expected );
	is( $result, $expected, "Checking SELECT by ip query on orders table" );
	
	
    my $no_trigger_sth = $orders_tbl->disable_trigger || fail( "An error has occurred while trying to create a query to disable trigger: " . $orders_tbl->error );
    pass( "Disable trigger query object" );
	$result = $no_trigger_sth->as_string;
	diag( "disable trigger query is: $result" ) if( $DEBUG );
	$expected = <<SQL;
ALTER TABLE orders DISABLE TRIGGER USER
SQL
	chomp( $expected );
	is( $result, $expected, "Checking disable trigger query on orders table" );

    my $no_triggers_sth = $orders_tbl->disable_trigger( all => 1 ) || fail( "An error has occurred while trying to create a query to disable all triggers: " . $orders_tbl->error );
    pass( "Disable all triggers query object" );
	$result = $no_triggers_sth->as_string;
	diag( "disable all triggers query is: $result" ) if( $DEBUG );
	$expected = <<SQL;
ALTER TABLE orders DISABLE TRIGGER ALL
SQL
	chomp( $expected );
	is( $result, $expected, "Checking disable all triggers query on orders table" );

    my $no_trigger_name_sth = $orders_tbl->disable_trigger( name => 'my_trigger' ) || fail( "An error has occurred while trying to create a query to disable trigger by name: " . $orders_tbl->error );
    pass( "Disable trigger by name query object" );
	$result = $no_trigger_name_sth->as_string;
	diag( "disable trigger by name query is: $result" ) if( $DEBUG );
	$expected = <<SQL;
ALTER TABLE orders DISABLE TRIGGER my_trigger
SQL
	chomp( $expected );
	is( $result, $expected, "Checking disable trigger by name query on orders table" );
	
	my $temp_disable_trigger_sth = $order_sth_del->disable_trigger || fail( "An error has occurred while trying to update the query to temporarily disable triggers: " . $orders_tbl->error );
    pass( "Temporarily disable trigger query object" );
	$result = $temp_disable_trigger_sth->as_string;
	diag( "Temporarily disable trigger query is: $result" ) if( $DEBUG );
	$expected = <<SQL;
ALTER TABLE orders DISABLE TRIGGER USER; DELETE FROM orders WHERE id = ? AND cust_id = (SELECT id FROM customers WHERE last_name = ?); ALTER TABLE orders ENABLE TRIGGER USER;
SQL
	chomp( $expected );
	is( $result, $expected, "Checking temporarily disable trigger query on orders table" );
	
	diag( "Testing asynchronous query." ) if( $DEBUG );
	subtest 'asynchronous query' => sub
	{
	    my $sth = $dbh->prepare( "SELECT pg_sleep(?)" ) || fail( "An error occurred while preparing a pg_sleep query: " . $dbh->error );
	    pass( "Test pg_sleep query" );
	    use Promise::Me;
	    my @results = ();
	    share( @results );
	    my $p = $sth->promise(3)->then(sub
	    {
	        push( @results, 'A' );
	    })->catch(sub
	    {
	        fail( "Error executing asynchronous query: " . join( '', @_ ) );
	    });
	    push( @results, 'B' );
	    await( $p );
	    is( "@results", 'B A', 'asynchronous query result' );
	};

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
	is( $dbh->get_sql_type( 'bytea' ), 17, 'get_sql_type' );
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

