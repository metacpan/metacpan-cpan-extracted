#!perl -w
#
#
#      Various (failure-) tests. Many of them *should* fail in order to stress test the internal
#      error handling. Tests that are expected to fail are enclosed by an eval {...}, thus you
#      will see an ok if they indeed fail.
#

$^W = 1;


use DBI qw(:sql_types);
use vars qw($NO_FLAG $COL_NULLABLE $COL_PRIMARY_KEY $verbose);

#
#   Make -w happy
#
$test_dsn = '';
$test_user = '';
$test_password = '';


#
#   Include lib.pl
#

$file = "lib.pl"; 
do $file; 
if ($@) { 
	print "Error while executing lib.pl: $@\n";
	exit 10;
}

$verbose = 0; # set this to 1, to see all the error messages and warnings that DBI raises

@table_def = (
	      ["one",   SQL_INTEGER(),  0,   0, $COL_PRIMARY_KEY], # column name, DBI SQL code, size/precision, scale, flags
	      ["two",   SQL_DATE(),     0,   0, $COL_NULLABLE],
		  ["three", SQL_VARCHAR(),  64,  0, $COL_NULLABLE]
	     );


print "1..25\n\n";

my($dbh, $sth, $p1, $rc);

#
# connect as unknown user, should fail
#


print "try connection as unknown (should fail) ...\n\n" if $verbose;
$dbh = DBI->connect(	$test_dsn, 
						'unknown', 
						'unknown', 
						{AutoCommit => 0, RaiseError => 0, PrintError => $verbose} 
				   ); # will not die, but print an error string

$dbh->disconnect if $dbh; # just in case
$DBI::errstr =~ /ERROR\(dtf_connect\)/ ? print "ok 1\n" : print "not ok 1\n";


#
# connect ok
#
print "\nConnecting to $test_dsn\nas user $test_user (password: $test_password) ...\n\n" if $verbose;

$dbh = DBI->connect(	$test_dsn, 
						$test_user, 
						$test_password, 
						{AutoCommit => 0, RaiseError => 0, PrintError => $verbose} 
					  ) || die "Can't connect to database: " . DBI->errstr; 

print "ok 2\n" if $dbh; # else died


#
# Create a new table
#

$table = FindNewTable($dbh); 
$def = TableDefinition($table, @table_def);
( $dbh->do($def) ) ? print "ok 3\n" : print "not ok 3\n";


# the following should fail
$sth = $dbh->prepare("SELECT * FROM $table");
$sth->execute();
undef $@;
eval { $p1 = $sth->{NUM_OFFIELDS_typo} };
$@ =~ /attribute/ ? print "ok 4\n" : print "not ok 4\n";
print "\n+++\neval error for test 4: \n$@---\n\n" if $verbose;


$sth->{Active} ? print "ok 5\n" : print "not ok 5\n";

$sth->finish ? print "ok 6\n" : print "not ok 6\n";

!$sth->{Active} ? print "ok 7\n" : print "not ok 7\n";



$sth = $dbh->prepare("SELECT * FROM ddrel"); # ddrel is a system table
$sth->execute ? print "ok 8\n" : print "not ok 8\n";

$sth->{Active} ? print "ok 9\n" : print "not ok 9\n";
1 while ($sth->fetch);	# fetch through to end

!$sth->{Active} ? print "ok 10\n" : print "not ok 10\n";


$dbh->{RaiseError} = 1;
# the following should fail
undef $@;
eval {
	$dbh->do("some invalid sql statement");
};
$@ =~ /DBD::DtfSQLmac::db do failed:/ ? print "ok 11\n" : print "not ok 11\n";
print "\n+++\neval error for test 11: \n$@---\n\n" if $verbose;


# create a table, this should fail, because the table name is not valid
undef $@;
eval {
	$rc = $dbh->do("CREATE TABLE #test(one int PRIMARY KEY, two date, three int)");
};
$@ =~ /DBD::DtfSQLmac::db do failed/ ? print "ok 12\n" : print "not ok 12\n";
print "\n+++\neval error for test 12: \n$@---\n\n" if $verbose;


$dbh->{AutoCommit} = 0;

# insert some values
$sth = $dbh->prepare("INSERT INTO $table (one, two, three) VALUES (?, ?, ?)");

# if you execute a statement with parameter values for binding,
# be sure you have called bind_param in before for providing
# type hints

# the following should fail: We have not provided type hints. Thus, all
# parameters will be bound as SQL_VARCHAR, and this will fail when we
# execute the statement

$sth->{Warn} = $verbose; # by default Warn is on

undef $@;
eval {
	$rc = $sth->execute(3, '2001-01-01', '5'); # $rc = $sth->execute(@bind_values);
};
$@ =~ /DBD::DtfSQLmac::st execute failed/ ? print "ok 13\n" : print "not ok 13\n";
print "\n+++\neval error for test 13: \n$@---\n\n" if $verbose;



$sth->bind_param(1, 3, SQL_INTEGER);
$sth->bind_param(2, '2001-01-01', SQL_VARCHAR);
$sth->bind_param(3, '5', SQL_VARCHAR);
$rc = $sth->execute();
$rc ? print "ok 14\n" : print "not ok 14\n";



# for the following calls, we don't need to provide type hints again
$rc = $sth->execute(4, '2000-12-24', '5');
$rc ? print "ok 15\n" : print "not ok 15\n";



$rc = $sth->execute(5, '2000-08-18', '3');
$rc ? print "ok 16\n" : print "not ok 16\n";



# should fail, because the number of parameter values is wrong
undef $@;
eval {
	$rc = $sth->execute(6, '2001-01-18');
};
$@ =~ /DBD::DtfSQLmac::st execute failed/ ? print "ok 17\n" : print "not ok 17\n";
print "\n+++\neval error for test 17: \n$@---\n\n" if $verbose;



# this should work, we don't need to quote "don't" (i.e. 'don''t'), because   
# that's done internally by the driver

$rc = $sth->execute(6, '2001-01-18', q{don't}); 
$rc ? print "ok 18\n" : print "not ok 18\n"; 


# insert a (quoted) question mark, this is not a placeholder !!!
$sth = $dbh->prepare("INSERT INTO $table (one, two, three) VALUES (?, ?, 'ok ?')");
$sth->bind_param(1, 7, SQL_INTEGER);
$sth->bind_param(2, '2001-01-18', SQL_VARCHAR);
$rc = $sth->execute();
$sth = $dbh->prepare("SELECT * FROM $table WHERE one = 7"); # 
$rc = $sth->execute();
my @row_ary = $sth->fetchrow_array;
($row_ary[2] eq 'ok ?') ? print "ok 19\n" : print "not ok 19\n";



$dbh->commit();

# should fail, because the quoting is wrong
undef $@;
eval {
	$rc = $dbh->do("DROP TABLE 'test");
};
$@ =~ /DBD::DtfSQLmac::db do failed/ ? print "ok 20\n" : print "not ok 20\n";
print "\n+++\neval error for test 20: \n$@---\n\n" if $verbose;




$rc = $dbh->do("DROP TABLE $table");
$rc ? print "ok 21\n" : print "not ok 21\n";



$dbh->commit();

undef $@;
eval {
	$rc = $dbh->do("SELECT * FROM $table"); # should fail
};
$@ =~ /DBD::DtfSQLmac::db do failed/ ? print "ok 22\n" : print "not ok 22\n";


#
# disconnect
#

$dbh->ping ? print "ok 23\n" : print "not ok 23\n";

$dbh->disconnect ? print "ok 24\n" : print "not ok 24\n";
$dbh->{RaiseError} = 0;

!$dbh->ping ? print "ok 25\n" : print "not ok 25\n";

