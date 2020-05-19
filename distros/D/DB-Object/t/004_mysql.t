#!/usr/bin/perl

use Test::More tests => 19;
select(($|=1,select(STDERR),$|=1)[1]);
BEGIN
{
	use strict;
	use IO::File;
	use File::Basename;
	use File::Spec;
	use JSON;
};

# BEGIN { use_ok( 'DB::Object::Mysql' ); };

SKIP:
{
	eval
	{
		require DBD::mysql;
	};
	skip( "DBD::mysql is not installed", 19 ) if( $@ );
	use_ok( 'DB::Object::Mysql' );
	
	## Connection parameters are taken from environment variables (DB_NAME, DB_LOGIN, DB_PASSWD, DB_DRIVER, DB_SCHEMA), or from file (DB_CON_FILE) or from uri (DB_CON_URI)
	## DB_CON_URI=http://localhost:5432?database=mysql&login=jack&
	my $con_params =
	{
	'db'		=> 'mysql',
	'host'		=> ( $ENV{DB_HOST} || 'localhost' ),
	'driver'	=> 'mysql',
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
		skip( "Database connection failed, cancelling other tests: $DB::Object::ERROR", 18 );
	}
	
	ok( $dbh1, "Getting DB::Object::Mysql object" );
	isa_ok( $dbh1, 'DB::Object::Mysql', "Checking class of object" );
	$ENV{DB_HOST} ||= 'localhost';
	my @db = $dbh1->databases;
	ok( @db, "Checking available databases" );
	fiag( printf( "Found the databases: %s", join( ", ", @db ) ) );
	if( grep( /^mysql$/, @db ) )
	{
		pass( "mysql database found" );
	}
	else
	{
		fail( "mysql database not found" );
	}

	our $test_db = 'db_object_mysql_test';
	if( scalar( grep( /^$test_db$/, @db ) ) )
	{
		diag( "Switching database to mysql to drop the old test database $test_db" );
		if( !$dbh1->use( 'mysql' ) )
		{
			fail( "Could not switch to database mysql" )
		}
		else
		{
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

	my $schemaFile = File::Spec->catfile( File::Basename::dirname(__FILE__), 'mysql.sql' );
	my $fh = IO::File->new( "<$schemaFile" ) || BAIL_OUT( "Unable to read the mysql schema \"$schemaFile\": $1" );
	$fh->binmode( ':utf8' );
	my $queries = [];
	my $def = {};
	my $sql = '';
	while( defined( my $l = $fh->getline ) )
	{
		if( $l =~ /^\-{2}[[:blank:]]+(\d+)[[:blank:]]+(.*?)$/ )
		{
			if( length( $sql ) )
			{
				push( @$queries, { id => $def->{id}, comment => $def->{comment}, query => $sql } );
			}
			@$def{qw(id comment)} = ( $1, $2 );
			$sql = '';
			next;
		}
		$sql .= $l;
	}
	$fh->close;
	$def->{query} = $sql;
	push( @$queries, $def ) if( length( $sql ) );
	$dbh->begin_work;
	foreach my $ref ( @$queries )
	{
		## diag( "Executing query \#$ref->{id} $ref->{query}" );
		my $rv = $dbh->do( $ref->{query} ) || do
		{
			$dbh->rollback;
			BAIL_OUT( "Unable to execute query \"$ref->{query}\": " . $dbh->error );
		};
		ok( $rv, $ref->{comment} );
	}
	$dbh->commit;

	is( scalar( @{$dbh->tables} ), 3, "Total number of tables expected (3)" );
	is( $dbh->table_exists( 'customers' ), 1, "Checking table_exists with table customers" );
	my $cust = $dbh->customers || fail( "Cannot get customers object." );
	pass( sprintf( "Got customers object: %s", ref( $cust ) ) );
	isa_ok( $cust, 'DB::Object::Mysql::Tables', "Getting customers table object" );
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
	my $cust_sth_ins = $cust->insert(
		first_name => 'Paul',
		last_name => 'Goldman',
		email => 'paul@example.org',
		active => 0,
	) || fail( "Error while create query to add data to table customers: " . $cust->error );
	$result = $cust_sth_ins->as_string;

	my $expected = <<SQL;
INSERT INTO customers (first_name, last_name, email, active) VALUES('Paul', 'Goldman', 'paul\@example.org', '0')
SQL
	chomp( $expected );
	is( $result, $expected, "Checking INSERT statement" );
	$cust->reset;

	## Checking select query
	$cust->where( email => 'john@example.org' );
	$cust->order( 'last_name' );
	$cust->having( email => qr/\@example/ );
	$cust->limit( 10 );
	my $cust_sth_sel = $cust->select || fail( "An error occurred while creating a query to select data frm table customers: " . $cust->error );
	$result = $cust_sth_sel->as_string;
	$expected = <<SQL;
SELECT id, first_name, last_name, email, created, modified, active, UNIX_TIMESTAMP('created') AS created_unixtime, UNIX_TIMESTAMP('modified') AS modified_unixtime, CONCAT(first_name, ' ', last_name) AS name FROM customers WHERE email='john\@example.org' HAVING email REGEXP('\\\@example') ORDER BY last_name LIMIT 10
SQL
	chomp( $expected );
	is( $result, $expected, "Checking SELECT query on customers table" );

	## Checking update query
	$cust->reset;
	$cust->where( email => 'john@example.org' );
	my $cust_sth_upd = $cust->update( active => 0 ) || fail( "An error has occurred while trying to create an update query for table customers: " . $cust->error );
	$result = $cust_sth_upd->as_string;
	$expected = <<SQL;
UPDATE customers SET active='0' WHERE email='john\@example.org'
SQL
	chomp( $expected );
	is( $result, $expected, "Checking UPDATE query on customers table" );
	# diag( "Removing test database $test_db" );
	if( !$dbh->use( 'mysql' ) )
	{
		fail( "Could not switch to database mysql" )
	}
	else
	{
		my $rv = $dbh->do( "DROP DATABASE $test_db" );
		ok( $rv, "Dropping leftover test database $test_db" );
	}
}

END
{
	if( $dbh )
	{
		# diag( "Disconnecting from database $test_db" );
		# $dbh->disconnect();
	}
};

done_testing();


__END__

