#! perl -w

#
# This is the browser.c example rewritten in Perl with some enhancements.
#
# The browser is an interactive shell accepting SQL commands for data retrieval
# and manipulation of a dtF/SQL database.
#
# Author: Thomas Wegner 
# Date: 2000-Nov-08
#

  use strict;
  use Mac::DtfSQL qw(:all);

  $| = 1; # no line buffering


  my $henv = DTFHANDLE_NULL; 	# environment handle
  my $hcon = DTFHANDLE_NULL; 	# connection handle
  my $htra = DTFHANDLE_NULL; 	# transaction handle
  my $hres = DTFHANDLE_NULL; 	# result handle
  
  my $err = 0;					# error code
  my $errstr = '';				# error message

  my $cwd = `pwd`;
  chomp $cwd;
  $cwd =~ s/:$//; # get rid of trailing colon
  
  die "The sample database 'SampleDB.dtf' doesn't exist in the current directory.\n# Run createSampleDB.pl first" unless (-e "$cwd:SampleDB.dtf");


  print "\n",
        "dtF/SQL - Browser Sample\n",
        "------------------------\n",
        "\n";
  print "Cwd: ". $cwd . ":\n";

  ($henv, $hcon, $htra, $err, $errstr ) = dtf_connect ("$cwd:SampleDB.dtf", "dtfadm", "dtfadm"); # hardcoded
  
  # check error
  
  if ($err != DTF_ERR_OK) {
  	die $errstr;
  }

  print "OK, connected to DB ':SampleDB.dtf' as user 'dtfadm'. \nWelcome.\n\n";

  # set auto commit mode, ignore error
 
  $err = DtfHdlSetAttribute ($htra, DTF_TAT_AUTOCOMMIT, AUTO_COMMIT_OFF); 
  
  # check the auto commit mode and display it to the user

  my $false_or_true;
  DtfHdlQueryAttribute($htra, DTF_TAT_AUTOCOMMIT, $false_or_true);
  print "Auto-Commit = $false_or_true.\n\n";
						
  print  "You may now enter SQL requests.\n",
         "In order to quit, enter \"exit\" or \"quit\".\n",
         "\n";

  while (1) { # loop forever
   
   	print "SQL> ";


    #  We retrieve one line of user input from stdin.
    #  When the string was empty, we just wait for the next
    #  line of input.
    #  When the string was "exit" or "quit", we leave the input loop,
    #  ending the script.
    #  In any other case, the string will be sent to the
    #  dtF/SQL database engine, any results are displayed in
    #  the console.

    my $sql = <STDIN>;
    chomp $sql;
    	
	$sql =~ s/^SQL> //; 	# under MPW, the whole line including the prompt is the input, so get 
						# rid of the prompt
	
	if (  ($sql =~ /QUIT/i) || ($sql =~ /EXIT/i) ) {
	    ($err, $errstr) = dtf_disconnect($henv, $hcon, $htra); # clean up is extremly important, 
															   # otherwise the DB gets damaged
		if ($err != DTF_ERR_OK) {
			die "\n# " . $errstr;
		}
	    last;
 	}
	next if ($sql =~ /^\s*$/) ; 	#  empty string or only white chars as input 
      							    #  --> get next request.

    #  Now we have a proper SQL string, so send it to
    #  the database engine using the function DtfTraExecute()
    #  which is typically used for sending SQL requests which
    #  are unknown to the program developer (browsers).
    #  Note that, other than with DtfTraExecuteQuery(), the
    #  parameter "restype" is missing. Instead, the default
    #  result type, modifiable with DtfHdlSetAttribute(),
    #  will be assumed.
    
    # After the function DtfTraExecute returns, $reqClass will contain the SQL request’s class
	# if the request was executed successfully; $reqClass will be one of the following values:

	# DTF_RC_ROWS_AFFECTED (= 0)
	#		The statement was of a modifying kind (insert, update, delete statements), and affected
	#		0 or more records (check $nrAffectedRecords).
			
	# DTF_RC_RESULT_AVAILABLE (= 1)
	#		The statement was of a querying kind (select, show statements), and returned 0 or more 
	#		rows of data ($hres is valid (!= 0), $nrAffectedRecords = row count).

	# DTF_RC_OTHER (= 2)
	#		The statment was of a different kind than the above, for example a create, drop, grant,
	#		and revoke statement.
 
   
  	my $reqClass;					# request class, see above
  	my $affectedRecords;			# no. of affected records

    if (DtfTraExecute($htra , $sql, $reqClass, $affectedRecords, $hres) != DTF_ERR_OK) {
      #  Any errors resulted from the SQL request
      #  will be displayed here.

	  if ($hres != DTFHANDLE_NULL) { # dispose the result handle
    		DtfResDestroy($hres);
  	  }
      my $code;     # error code
      my $msg; 		# error message
      my $grp;  	# error group
      my $errpos;   # error position within the SQL request

      if (DtfHdlGetError($htra, $code, $msg, $grp, $errpos) != DTF_ERR_OK) {
	  	# cleanup handles and die
		($err, $errstr) = dtf_disconnect($henv, $hcon, $htra);
        die "ERROR: Can't query transaction error";
      }

      printf("ERR(%x): %s: %s.\n%s\n\n", $code, $grp, $msg, $sql);
      next;
    }#if


	# now, handle the result
	
	if ($reqClass == DTF_RC_OTHER) {
      print "OK.\n";
    } elsif ($reqClass == DTF_RC_RESULT_AVAILABLE) {
        
      #  We have a result table.
      #  Display column information and the actual result data.

      my $rows;
      my $cols;
      my $i;
      my $j;
      my $hcol = DTFHANDLE_NULL; # column handle
      my $def; # attribut definition string

      printf("OK, retrieved %lu record%s.\n", $affectedRecords, $affectedRecords == 1 ? "" : "s");

      $cols = DtfResColumnCount($hres);
      $rows = $affectedRecords;

      #  Step 1: Display Column Information

      print "  ";

      for ($i = 0; $i < $cols; ++$i) {
      	#  Create a column handle from the current result set.

       	if (DtfColCreate($hres, $i, $hcol) == DTF_ERR_OK) {
        	#  The attribute "definition" returns a null-terminated
            #  character string as specified in the "create" statement
            #  for the corresponding column. 

            DtfHdlQueryAttribute($hcol, DTF_LAT_DEFINITION, $def);
			
            #  The most commonly retrieved attributes, the column name
            #  and the column's table name can be retrieved with
            #  functions in addition to the DtfHdlQueryAttribute() function:

            printf("%s.%s(%s)", DtfColTableName($hcol), DtfColName($hcol), $def);

            if ($i < ($cols - 1)) {
                printf(",");
            } else {
                printf("\n");
            }#if

            #  Do not forget to destroy the column handle
            #  after processing it.

            DtfColDestroy($hcol);
        }#if
      }#for

      #  Step 2: Display Record Contents

      DtfResMoveToFirstRow($hres);

      for ($j = 0; $j < $rows; ++$j) {
         &DisplayCurrentRecord($hres);
         DtfResMoveToNextRow($hres);
      }#for

      #  Do not forget to destroy the result
      #  after processing it.

      DtfResDestroy($hres);
      
 	} elsif ($reqClass == DTF_RC_ROWS_AFFECTED) {
      printf("OK, affected %lu record%s.\n", $affectedRecords, $affectedRecords == 1 ? "" : "s");
    }#if
 

 }#end while(1) 
 
print "\nHave a nice day.\n";



#
# SUB(s)
#


sub DisplayCurrentRecord {
  my $hres = shift;
  
  my $cols;		# number of columns
  my $c;		# column index
  my $field;	# field buffer
  my $isNull;	# null indicator

  if (($cols = DtfResColumnCount($hres)) > 0) {
    print "  ";

    for ($c = 0; $c < $cols; ++$c)
    {
      #  Regardless of the column's actual datatype, we always
      #  retrieve a field as SQL-string, which is a null-terminated
      #  character string in a format which easily lets you use
      #  the string as part of a new SQL request, i.e. string, date,
      #  and time fields are placed within single quotes.

      if (DtfResGetField($hres, $c, DTF_CT_SQLSTRING, $field, $isNull, 0) == DTF_ERR_OK) {
        if ($isNull) {
          print "NULL";
        } else {
          printf("%s", $field);
        }#if
      } else {
        print "ERR!";
      }#if

      if ($c < ($cols -1))
      {
        printf(",");
      }#if
    }#for

    print "\n";
  }#if
}#sub



  
