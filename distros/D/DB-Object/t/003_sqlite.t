#!/usr/local/bin/perl
use Test::More qw( no_plan );

BEGIN
{
	use strict;
	use File::Basename;
	use DateTime;
	use DateTime::TimeZone;
	use DateTime::Format::Strptime;
	use IO::File;
	use URI;
};

SKIP:
{
	eval
	{
		require DBD::SQLite;
	};
	skip( "DBD::SQLite is not installed", 63 ) if( $@ );
	use_ok( 'DB::Object::SQLite' );
    use_ok( "DB::Object::SQLite::Query" );
    use_ok( "DB::Object::SQLite::Statement" );
    use_ok( "DB::Object::SQLite::Tables" );
	
	my( $test_file, $path, $suf ) = File::Basename::fileparse( __FILE__, qr/\.[^\.]+$/ );
	
	our $test_db = 'db_object_test.sqlite';
	unlink( "$path/$test_db" ) if( -e( "$path/$test_db" ) );
	our $con_uri = $ENV{DB_CON_URI} = URI->new( "file:${path}/$test_db" );
	my $sql = DB::Object::SQLite->new;
	# $sql->debug( 3 );
	ok( $sql, "Getting DB::Object::SQLite object" );
	isa_ok( $sql, 'DB::Object::SQLite', "Checking class of object" );
	my @db = $sql->databases;
	ok( @db, "Checking available databases" );
	diag( sprintf( "Found the databases: %s\n", join( ", ", @db ) ) );
	if( grep( /^main$/, @db ) )
	{
		pass( "Main test database found" );
	}
	else
	{
		fail( "Main test database not found" );
	}
	
	# diag( "Testing private functions" );
	is( $sql->_ceiling( 45.5 ), 46, "Checking ceil()" );
	is( $sql->_concat( 'Well, ', 'hello ', 'world' ), 'Well, hello world', "Checking concat()" );
	my $tz = DateTime::TimeZone->new( name => 'local' );
	my $fmt = DateTime::Format::Strptime->new(
		locale => 'en_GB',
		time_zone => $tz->name,
		pattern => '%Y-%m-%dT%T%z',
	);
	my $dt = DateTime->from_epoch( epoch => time(), time_zone => $tz );
	$dt->set_formatter( $fmt );
	# diag( "Will be using this timestamp as a reference: $dt" );
	my $date = $dt->ymd( '-' );
	is( $sql->_curdate, "$date", "Checking curdate()" );
	my $time = $dt->hms( ':' );
	like( $sql->_curtime, qr/\d{2}\:\d{2}\:\d{2}/, "Checking curtime()" );
	is( $sql->_dayname( "$dt" ), $dt->day_name, "Checking dayname()" );
	is( $sql->_dayofmonth( "$dt" ), $dt->day, "Checking dayofmonth()" );
	is( $sql->_dayofweek( "$dt" ), $dt->day_of_week, "Checking dayofweek()" );
	is( $sql->_dayofyear( "$dt" ), $dt->day_of_year, "Checking dayofyear()" );
	my @coordinates = qw( 35.7132311 139.7174027 35.68117 139.7327573 );
	is( CORE::sprintf( "%.12f", $sql->_distance_miles( @coordinates ) ), 2.377034154241, "Checking distance_miles()" );
	my $check_t = DateTime->new(
		year => 1970,
		month => 3,
		day => 31,
		hour => 0,
		minute => 0,
		second => 0,
		time_zone => 'GMT',
	);
	$check_t->set_time_zone( 'local' );
	## e.g. 1970-03-31T09:00:00
	is( $sql->_from_days(719617 ), "$check_t", "Checking from_days()" );
	is( $sql->_from_unixtime( $dt->epoch ), $dt->strftime( '%Y-%m-%d %T%z' ), "Checking from unix_time()" );
	is( $sql->_hour( "$dt" ), $dt->hour, "Checking hour()" );
	is( $sql->_lcase( "CamEl WRiTing" ), 'camel writing', "Checking lcase()" );
	is( $sql->_left( 'Awesome', 3 ), 'Awe', "Checking left()" );
	is( $sql->_locate( 'hello@deguest.jp', '@' ), 5, "Checking locate()" );
	is( $sql->_log10( 1000 ), 3, "Checking log10()" );
	is( $sql->_minute( "$dt" ), $dt->minute, "Checking minute()" );
	is( $sql->_month( "$dt" ), $dt->month, "Checking month()" );
	is( $sql->_monthname( "$dt" ), $dt->month_name, "Checking monthname()" );
	is( $sql->_number_format( 1000, ',', '.', 2 ), '1,000.00', "Checking number_format()" );
	is( $sql->_power( 2, 3 ), 8, "Checking power()" );
	is( $sql->_quarter( "$dt" ), $dt->quarter, "Checking quarter()" );
	my $random_number = $sql->_rand;
	pass( "Random number generated: $random_number" );
	is( $sql->_replace( 'Hello John!', 'John', 'Jacques' ), 'Hello Jacques!', "Checking replace()" );
	is( $sql->_right( 'Wonderful', 3 ), 'ful', "Checking right()" );
	is( $sql->_second( "$dt" ), $dt->second, "Checking second()" );
	is( $sql->_space( 7 ), '       ', "Checking space()" );
	is( $sql->_sprintf( "There are '%d' petals to this flower", 3 ), "There are '3' petals to this flower", "Checking sprintf()" );
	is( $sql->_to_days( '2016-06-29' ), 736509, "Checking to_days()" );
	is( $sql->_ucase( "CamEl WRiTing" ), 'CAMEL WRITING', "Checking lcase()" );
	is( $sql->_unix_timestamp( "$dt" ), $dt->epoch, "Checking unix_timestamp()" );
	is( $sql->_week( "$dt" ), $dt->week_number, "Checking week()" );
	is( $sql->_weekday( "$dt" ), $dt->day_of_week, "Checking weekday()" );
	is( $sql->_year( "$dt" ), $dt->year, "Checking year()" );
	is( $sql->_regexp( '\@example\..*$', 'job@example.org' ), 1, "Checking regexp()" );

	my $dbh = DB::Object->connect(
	'uri'		=> $con_uri,
	## 'host'		=> 'localhost',
	'driver'	=> 'SQLite',
	## 'login'		=> 'n',
	## 'passwd'	=> '',
	# 'debug'		=> 3,
	) || die( $DB::Object::ERROR );
	$dbh->verbose( 0 );
	#$dbh->quiet( 1 );
	# $dbh->debug( 3 );
	ok( $dbh, "Testing connection" );
	isa_ok( $dbh, 'DB::Object::SQLite', "Checking object class ownership" );
	
	## Load schema
	my $schemaFile = File::Spec->catdir( File::Basename::dirname(__FILE__), 'sqlite.sql' );
	my $fh = IO::File->new( "<$schemaFile" ) || BAIL_OUT( "Unable to read the sqlite schema \"$schemaFile\": $1" );
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
	BAIL_OUT( sprintf( "Total nuber of tables set up is %d", scalar( @{$dbh->tables} ) ) ) if( scalar( @{$dbh->tables} ) != 3 );
	is( $dbh->table_exists( 'customers' ), 1, "Checking table_exists with table test" );
	my $tbl = $dbh->customers || fail( "Cannot get test object." );
	ok( $tbl, sprintf( "Got customers object: %s", ref( $tbl ) ) );
	isa_ok( $tbl, 'DB::Object::SQLite::Tables', "Getting test table object" );
	is( $tbl->name, 'customers', "Checking customers table name" );
	# diag( "Table object is '$tbl." );
	
	$tbl->where( email => qr/\@example\..*$/ );
	my $test_sql = $tbl->select->as_string;
	is( $test_sql, "SELECT id, first_name, last_name, email, created, modified, active, STRFTIME('%s','created') AS created_unixtime, STRFTIME('%s','modified') AS modified_unixtime, CONCAT(first_name, ' ', last_name) AS name FROM customers WHERE email REGEXP('\\\@example\\\..*\$')", "Checking regular expression" );
	
	# $tbl->debug( 3 );
	$tbl->where( 'email' => 'john@example.org' );
	my $sth = $tbl->delete;
	diag( "Error found: ", $tbl->error ) if( !$sth );
	## diag( "Received the sth '$sth'." );
	my $str = $sth->as_string;
	#my $str = $tbl->delete->as_string;
	is( $str, "DELETE FROM customers WHERE email='john\@example.org'", "Checking DELETE query" );
	
	{
		local $SIG{__WARN__} = sub{};
		my $fake_tbl = $dbh->table( 'plop' );
		is( $fake_tbl, undef(), "Checking fake table 'plop'" );
	}

	my $tbl_exists = $dbh->table_exists( 'customers' );
	if( !defined( $tbl_exists ) )
	{
		fail( "Error checking if table \"customers\" exists: " . $dbh->error );
	}
	else
	{
		is( $tbl_exists, 1, "Checking existence of table customers with table_exists()" );
	}
	$str = $tbl->insert(
	first_name => 'Paul',
	last_name => 'Goldman',
	email => 'paul@example.org',
	active => 0,
	)->as_string;
	my $expected = <<SQL;
INSERT INTO customers (first_name, last_name, email, active) VALUES('Paul', 'Goldman', 'paul\@example.org', '0')
SQL
	chomp( $expected );
	is( $str, $expected, "Checking INSERT statement" );
	
	## Checking select query
	$tbl->reset;
	$tbl->where( email => 'john@example.org' );
	$tbl->order( 'last_name' );
	$tbl->group( 'email' );
	$tbl->having( email => qr/\@example/ );
	$tbl->limit( 10 );
	my $cust_sth_sel = $tbl->select || fail( "An error occurred while creating a query to select data frm table customers: " . $tbl->error );
	$result = $cust_sth_sel->as_string;
	$expected = <<SQL;
SELECT id, first_name, last_name, email, created, modified, active, STRFTIME('%s','created') AS created_unixtime, STRFTIME('%s','modified') AS modified_unixtime, CONCAT(first_name, ' ', last_name) AS name FROM customers WHERE email='john\@example.org' GROUP BY email HAVING email REGEXP('\\\@example') ORDER BY last_name LIMIT 10
SQL
	chomp( $expected );
	is( $result, $expected, "Checking SELECT query on customers table" );
	
	## Checking update query
	$tbl->reset;
	$tbl->where( email => 'john@example.org' );
	my $cust_sth_upd = $tbl->update( active => 0 ) || fail( "An error has occurred while trying to create an update query for table customers: " . $tbl->error );
	$result = $cust_sth_upd->as_string;
	$expected = <<SQL;
UPDATE customers SET active='0' WHERE email='john\@example.org'
SQL
	chomp( $expected );
	is( $result, $expected, "Checking UPDATE query on customers table using ONLY clause" );
}

done_testing();

__END__
