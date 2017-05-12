#
#   lib.pl is the file where database specific things should live,
#   whereever possible. For example, you define certain constants
#   here and the like.
#

require 5.004;
use DBI 1.08 qw(:sql_types);
use Mac::DtfSQL qw(:all);
use strict;
use vars qw($mdriver $test_dsn $test_user $test_password);


$mdriver = "DtfSQLmac";

my $curdir = `pwd`;
chomp $curdir;
$curdir =~ s/:$// ; # get rid of trailing colon
my $db_name = $curdir . ':TestDB_delete_me.dtf';

createTestDB($db_name) unless (-e $db_name); # creates a test db, if not exist


#
#   DSN being used
#
$test_dsn      = "dbi:DtfSQLmac:$db_name";
$test_user     = "dtfadm";
$test_password = "dtfadm";

$::NO_FLAG = 0;
$::COL_NULLABLE = 1;
$::COL_PRIMARY_KEY = 2;


#
#   The Testing() function builds the frame of the test; it can be called
#   in many ways, see below.
#
#   Usually there's no need for you to modify this function.
#
#       Testing() (without arguments) indicates the beginning of the
#           main loop; it will return, if the main loop should be
#           entered (which will happen twice, once with $state = 1 and
#           once with $state = 0)
#       Testing('off') disables any further tests until the loop ends
#       Testing('group') indicates the begin of a group of tests; you
#           may use this, for example, if there's a certain test within
#           the group that should make all other tests fail.
#       Testing('disable') disables further tests within the group; must
#           not be called without a preceding Testing('group'); by default
#           tests are enabled
#       Testing('enabled') reenables tests after calling Testing('disable')
#       Testing('finish') terminates a group; any Testing('group') must
#           be paired with Testing('finish')
#
#   You may nest test groups.
#
{
    # Note the use of the pairing {} in order to get local, but static,
    # variables.
    my (@stateStack, $count, $off);

    $count = 0;

    sub Testing {
	my ($command) = shift;
	if (!defined($command)) {
	    @stateStack = ();
	    $off = 0;
	    if ($count == 0) {
		++$count;
		$::state = 1;
	    } elsif ($count == 1) {
		my($d);
		if ($off) {
		    print "1..0\n";
		    exit 0;
		}
		++$count;
		$::state = 0;
		print "1..$::numTests\n";
	    } else {
		return 0;
	    }
	    if ($off) {
		$::state = 1;
	    }
	    $::numTests = 0;
	} elsif ($command eq 'off') {
	    $off = 1;
	    $::state = 0;
	} elsif ($command eq 'group') {
	    push(@stateStack, $::state);
	} elsif ($command eq 'disable') {
	    $::state = 0;
	} elsif ($command eq 'enable') {
	    if ($off) {
		$::state = 0;
	    } else {
		my $s;
		$::state = 1;
		foreach $s (@stateStack) {
		    if (!$s) {
			$::state = 0;
			last;
		    }
		}
	    }
	    return;
	} elsif ($command eq 'finish') {
	    $::state = pop(@stateStack);
	} else {
	    die("Testing: Unknown argument\n");
	}
	return 1;
    }


#
#   Read a single test result
#
    sub Test {
	my($result, $error, $diag) = @_;
	++$::numTests;
	if ($count == 2) {
	    if (defined($diag)) {
	        printf("$diag%s", (($diag =~ /\n$/) ? "" : "\n"));
	    }
	    if ($::state || $result) {
		print "ok $::numTests\n";
		return 1;
	    } else {
		printf("not ok $::numTests%s\n",
			(defined($error) ? " $error" : ""));
		return 0;
	    }
	}
	return 1;
    }
}


#
#   Print a DBI error message
#
sub DbiError {
    my($rc, $err) = @_;
    $rc ||= 0;
    $err ||= '';
    print "Test $::numTests: DBI error $rc, $err\n";
}


#
#   This function generates a list of tables associated to a
#   given DSN. Highly DBMS specific, EDIT THIS!
#
sub ListTables(@) {
    my($dbh) = shift;
    my(@tables);

    @tables = $dbh->tables;
    if ($dbh->errstr) {
	die "Cannot create table list: " . $dbh->errstr;
    }
    @tables;
}

#
#   This functions generates a list of possible DSN's aka
#   databases and returns a possible table name for a new
#   table being created.
#

{
    use vars qw($listTablesHook);

    my(@tables, $testtable, $listed);

    $testtable = "testaa";
    $listed = 0;

    sub FindNewTable {
	my($dbh) = @_;

	if (!$listed) {
	    if (defined($listTablesHook)) {
		@tables = &$listTablesHook($dbh);
	    } elsif (defined(&ListTables)) {
		@tables = &ListTables($dbh);
	    } else {
		die "Fatal: ListTables not implemented.\n";
	    }
	    $listed = 1;
	}

	# A small loop to find a free test table we can use to mangle stuff in
	# and out of. This starts at testaa and loops until testaz, then testba
	# - testbz and so on until testzz.
	my $foundtesttable = 1;
	my $table;
	while ($foundtesttable) {
	    $foundtesttable = 0;
	    foreach $table (@tables) {
		if ($table eq $testtable) {
		    $testtable++;
		    $foundtesttable = 1;
		}
	    }
	}
	$table = $testtable;
	$testtable++;
	$table;
    }
}


sub ErrMsg  { print (@_); }
sub ErrMsgF  { printf (@_); }



#   This function generates a mapping of DBI SQL type names/codes to
#   database specific type names; it is called by TableDefinition().
#
sub DBITypeToDb {
    my ($type, $size, $scale) = @_;
	
	return "CHAR" 					if  ( $type == DBI::SQL_TINYINT() );
	return "SMALLINT" 				if  ( $type == DBI::SQL_SMALLINT() );
	return "INTEGER" 				if  ( $type == DBI::SQL_INTEGER() );
	return "FLOAT"	 				if  ( $type == DBI::SQL_DOUBLE() );
	return "CHARACTER($size)"		if  ( $type == DBI::SQL_CHAR() );
	return "VARCHAR($size)"	 		if  ( $type == DBI::SQL_VARCHAR() );
	return "DATE"			 		if  ( $type == DBI::SQL_DATE() );
	return "TIME"			 		if  ( $type == DBI::SQL_TIME() );
	return "TIMESTAMP"				if  ( $type == DBI::SQL_TIMESTAMP() );
	return "DECIMAL($size,$scale)"	if  ( $type == DBI::SQL_DECIMAL() );

	# else 
	warn "Unknown DBI SQL type code $type\n";
	return undef;
}


#
#   This function generates a table definition based on an
#   input list. The input list consists of references, each
#   reference referring to a single column. The column
#   reference consists of column name, type, size and a bitmask of
#   certain flags, namely
#
#       $COL_NULLABLE - true, if this column may contain NULL's
#       $COL_PRIMARY_KEY - true, if this column is part of the table's
#           primary key
#
#   Hopefully there's no big need for you to modify this function,
#   if your database conforms to ANSI specifications.
#

sub TableDefinition {
    my($tablename, @cols) = @_;
    my($def);

    #
    #   Should be acceptable for most ANSI conformant databases;
    #
    #
    my($col, @keys, @colDefs, $keyDef);

    #
    #   Count number of keys
    #
    @keys = ();
    foreach $col (@cols) {
		if ($col->[4] & $::COL_PRIMARY_KEY) {
	    	push(@keys, $col->[0]);
		}
    }
    
	# $::NO_FLAG = 0;
	# $::COL_NULLABLE = 1;
	# $::COL_PRIMARY_KEY = 2;
	# col_ref:  ["id", SQL_INTEGER(), 0, 0, 0], # column name, DBI SQL code, size/precision, scale, flags
    
	foreach $col (@cols) {
		my $colDef = $col->[0] . " " . DBITypeToDb($col->[1], $col->[2], $col->[3]); 
	    if (!($col->[4] & $::COL_NULLABLE)) {
	    	$colDef .= " NOT NULL";
		}
		push(@colDefs, $colDef);
    }
    if (@keys) {
		$keyDef = ", PRIMARY KEY (" . join(", ", @keys) . ")";
    } else {
		$keyDef = "";
    }
    $def = sprintf("CREATE TABLE %s (%s%s)", $tablename,
		   join(", ", @colDefs), $keyDef);
}


#
#   Return a string for checking, whether a given column is NULL.
#
sub IsNull {
    my($var) = @_;

    "$var IS NULL";
}


#
#   Return TRUE, if database supports transactions
#
sub HaveTransactions () {
    1;
}





# creates the sample database 'TestDB_delete_me.dtf' in the current folder, 
# user 'dtfadm' , password 'dtfadm'

sub createTestDB {
	my $dsn = shift @_ ; 		# Data Source Name DSN
	
	my $henv = DTFHANDLE_NULL; 	# environment handle
  	my $hcon = DTFHANDLE_NULL; 	# connection handle
  	my $htra = DTFHANDLE_NULL; 	# transaction handle

  	my $err = DTF_ERR_OK;		# error code
  	my $errstr = '';			# error string  



		

  	#  First, we create all needed handles:
  	#  an environment and a connection handle (but do not connect).


  	if ( ($err = DtfEnvCreate($henv) ) != DTF_ERR_OK) {
  		die "\n# ERROR: Can't create environment [errcode: $err]";
  	}

  	#print "Ok, environment handle created ...\n";

  	#  When the environment handle (henv) was created successfully,  a connection handle
  	#  can be created as the environment handle's *dependent* handle.
  	#
  	#  Note: The function DtfConCreateDatabase is correctly implemented only in the single-user version of
  	#  dtF/SQL.
  
  	if (DtfConCreate($henv, $dsn, DTF_CF_FILENAME, $hcon) != DTF_ERR_OK) {
    	die "\n# ERROR: Can't create a connection handle";
  	}

  	#print "Ok, connection handle created ...\n";
  
  	#  This function queries some information about the just established connection

  	my $connected = NULL;
  	my $dbExists = not_NULL; # not NULL is important
  	my $dbConsistent = not_NULL;	# not NULL is important
  
  	if ( ($err = DtfConQueryStatus($hcon, NULL, $dbExists, NULL) ) != DTF_ERR_OK) {
    	die "\n# ERROR: Can't query connection status [errcode: $err]";
  	}

  	my $indexSize = 0;
 	my $relationSize = 0;
  
  	if ($dbExists) {
  		die "ERROR: Database " . $dsn . " does already exist";
  	} else {
  		if ( ($err = DtfConCreateDatabase(	$hcon,
                             				"dtfadm",
                             				"dtfadm",
                              				0,        			# default index/relation ratio (25:75)
                             				DTF_MAX_MAXSIZE, 	# maximum database file size
                              				$indexSize,   		# resulting index size [KB]
                              				$relationSize    	# resulting relation size [KB]
                              			 ) ) != DTF_ERR_OK)
        {
          	die "ERROR: Can't create database [errcode: $err]";
		}#if
		
  	}#if
  		
	#
	# now, disconnect from the database
	#

	($err, $errstr) = dtf_disconnect ($henv, $hcon, $htra); # $htra == 0 (not used)
	if ($err) {
		die $errstr;
	}	
	#print "Ok, disconnected.\n";
		
  	print "\n# A test database was created successfully.\n",
          "#   Space for index      data: " . $indexSize . " KB\n",
          "#   Space for relational data: " . $relationSize . " KB\n\n",
		  "# You can safely delete it after you've finished testing. \n\n";

}


1;