# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

my ( $module_name, $number_of_tests, $test_number, $test_description, @variable_data,
	 $variable_data, $variable_name, );

BEGIN {
	$|                =  1;

	#   the heirarchical module name
	$module_name      =  "DBIx::Broker";

	#   how many distinct tests will be performed?
	$number_of_tests  =  3;

	#   enter here a hashref for each variable whose specific value you want
	#   the user to enter.  simply remove the whole array to skip that interactive portion.
	@variable_data    =  ( { 'name'        => 'driver',
							 'description' => "DBI database driver (i.e., the second entry\nin the DBI 'data_source')",
							 'example'     => "mysql" },
						   { 'name'        => 'database',
							 'description' => "name of the database to use",
							 'example'     => "customer_database" },
						   { 'name'        => 'hostname',
							 'description' => "hostname of the database server",
							 'example'     => "db.wild-woobah.net" },
						   { 'name'        => 'port',
							 'description' => "port on which the database is listening",
							 'example'     => "3306" },
						   { 'name'        => 'user',
							 'description' => "database username with which to connect",
							 'example'     => "httpd" },
						   { 'name'        => 'password',
							 'description' => "password for that user (if needed)",
							 'example'     => "f8m;03V" },
						 );
}

END {
	if ( $all_succeeded ) {
		print "\nAll tests completed successfully.\n\nEnjoy your new $module_name module!\n\n";
	}
	else {
		print "\n*** Error: Test $test_number ($test_description) failed.\n\n";
	}
}

print "\n";

&prompt_for_user_data( )  if  ( @variable_data );

print "\nBeginning $module_name tests...\n\n\n";

for ( $test_number = 1; $test_number <= $number_of_tests; $test_number++ ) {
	print "Starting Test $test_number...\n\n";
	&{ "perform_test_$test_number" };
	print "Test $test_number ($test_description) succeeded.\n\n\n";
	sleep( 1 );
}

#   if we made it this far, then

$all_succeeded = 1;

#   and we are done.


#   ==============================================


sub prompt_for_user_data {
	print "\n\n============= $module_name Data Initialization =============\n\n";
	print "Note: not all of the following values may need to be initialized.\n";
	print "You may press <Enter> for any of them, if you would like to leave\ntheir values blank.\n\n";
	foreach $variable_data ( @variable_data ) {
		$variable_name  =  $variable_data->{'name'};
		print "Please enter the $variable_data->{'description'}.\n";
		print "  Example: $variable_data->{'example'}\n\n";
		print "$variable_name: ";
		chomp( $$variable_name  =  <STDIN> );
		print "\n";
	}
}

#   all the testing routines follow -- each named like "perform_test_$test_number"

sub perform_test_1 {
	$test_description  =  "module loading";
	print "use $module_name;\n\n";
	eval( "use $module_name" );
	die $@  if  $@;
}

#   Note: all routines below this point are module-specific and need to be modified
#         for each new module with which you want to use this test.pl script.

sub perform_test_2 {
	$test_description  =  "$module_name object initialization";
	print "DBIx::Broker->new( \$driver, \$database, \$hostname, \$port, \$user, \$password );\n\n";
	$db  =  DBIx::Broker->new( $driver, $database, $hostname, $port, $user, $password );
}

sub perform_test_3 {
	$test_description  =  "simple SELECT statement";
	print "\$db->execute_sql( 'SELECT 13' );\n\n";
	@select_results  =  $db->execute_sql( 'SELECT 13' );
}
