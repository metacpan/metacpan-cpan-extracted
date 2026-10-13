#*****************************************************************************
# TESTCASE NAME    : perldutl.pl
# RELEASE          : DB2 UDB V5.2
# LINE ITEM        : DBD::DB2 database driver for Perl
# COMPONENT(S)     : perldb2
# DEVELOPER        : Mike Moran in Austin
# FUNCTION TESTER  : DB2 UDB Precompiler team
# KEYWORDS         :
# PREREQUISITE     : Perl 5.004_04 or later
#                  : DBI module, level 0.93 or later
# PRERUN           : -
# POSTRUN          : -
# APAR FIX         : -
# DEFECT(S)        : -
# SETUP            : AUTOMATED
# DESCRIPTION      : This file contains utility routines.
# EXPECTED RESULTS : -
# MODIFIED BY      :
#
#  DEFECT      WHO        WHEN          DESCRIPTION
# --------  ----------  --------- -------------------------------------------
#  96764    Kelvin Ho    98Aug13  Create the utility
#  95027    L.Huffman    99Jan12  Strip out carriage return in check_value()
# 176348    R. Indrigo   01Jun04  Use index function to check for inclusion
#                                 in check_value
#****************************************************************************/

#
# get_attributes() defines a number of attribute hashes
#
sub get_attributes
{
  use DBD::DB2::Constants;

  # Default attributes
  use DBD::DB2 qw($attrib_int
                  $attrib_char
                  $attrib_float
                  $attrib_date
                  $attrib_ts);

  $attrib_graphic = { 'Ctype' => SQL_C_DBCHAR,
                      'Stype' => SQL_GRAPHIC,
                      'Prec'  => 127,
                      'Scale' => 0
                    };

  $attrib_vargraphic = { 'Ctype' => SQL_C_DBCHAR,
                         'Stype' => SQL_VARGRAPHIC,
                         'Prec'  => 127,
                         'Scale' => 0
                       };

  $attrib_longvargraphic = { 'Ctype' => SQL_C_DBCHAR,
                             'Stype' => SQL_LONGVARGRAPHIC
                           };

  $attrib_varchar = { 'Ctype' => SQL_C_CHAR,
                      'Stype' => SQL_VARCHAR
                    };

  $attrib_longvarchar = { 'Ctype' => SQL_C_CHAR,
                          'Stype' => SQL_LONGVARCHAR
                        };

  $attrib_time = { 'Ctype' => SQL_C_CHAR,
                   'Stype' => SQL_TIME
                 };

  $attrib_numeric = { 'Ctype' => SQL_C_CHAR,
                      'Stype' => SQL_NUMERIC,
                      'Prec'  => 16,
                      'Scale' => 8
                    };

  $attrib_decimal = { 'Ctype' => SQL_C_CHAR,
                      'Stype' => SQL_DECIMAL,
                      'Prec'  => 9,
                      'Scale' => 3
                    };

  $attrib_decfloat = { 'Ctype' => SQL_C_CHAR,
                      'Stype' => SQL_DECFLOAT,
                      'Prec'  => 16,
                      'Scale' => 0
                    };

  $attrib_bigint = { 'Ctype' => SQL_C_CHAR,
                     'Stype' => SQL_BIGINT
                   };

  $attrib_smallint = { 'Ctype' => SQL_C_CHAR,
                       'Stype' => SQL_SMALLINT
                     };

  $attrib_double = { 'Ctype' => SQL_C_CHAR,
                     'Stype' => SQL_DOUBLE
                   };

  $attrib_real = { 'Ctype' => SQL_C_CHAR,
                   'Stype' => SQL_REAL
                 };

  $attrib_binary = { 'Ctype' => SQL_C_CHAR,
                     'Stype' => SQL_BINARY
                   };

  $attrib_varbinary = { 'Ctype' => SQL_C_CHAR,
                        'Stype' => SQL_VARBINARY
                      };
}

#
# print_error() outputs an error message and sets $success to "n"
#
sub print_error
{
  local($errmsg) = @_;
  print("$errmsg\n");
  $success = "n";
}

#
# check_error() checks whetherthe SQLCODE, SQLMSG or SQLSTATE matches
# the expected one. If no expected value is specified, an empty
# string is assumed.
#
sub check_error
{
  local($stmt, $expected, $errType) = @_;
  local($errFound) = 0;

  if ($errType ne ""            &&
      $errType ne "DBI::err"    &&
      $errType ne "DBI::errstr" &&
      $errType ne "DBI::state"   )
  {
    print_error("check_error: Invalid error type: $errType\n");
  }
  else
  {
    $errType = "DBI::err" if ($errType eq "");
    $errFound = 1 if (${$errType} ne $expected);
  }

  if ($errFound || $debug)
  {
    if ($errFound)
    {
      print_error("$stmt failed:");
    }
    else
    {
      print("$stmt:\n");
    }
    $expected = 0 if ($expected eq "") && defined(${$errType});
    print("  Expected $errType = $expected\n");
    print("  Actual   $errType = ${$errType}\n");
    print("  $DBI::errstr") if (defined($DBI::errstr));
    print("\n") if ($DBI::errstr !~ /\n$/);
  }
}

#
# check_value() checks whether a particular variable matches
# the expected value. An option flag is available to specify if
# exact match is required.
#
sub check_value
{
  local($stmt, $var, $expValue, $isExactMatch, $isNumeric) = @_;
  local($errFound) = 0;
  local($checkType) = "";

  $actualValue = eval("\$$var");
# strip out Intel carriage returns to facilitate correct comparison
# between actual and expected messages
  $actualValue =~ s/\r//g;

  if (!defined($isExactMatch) || $isExactMatch =~ /^TRUE$|^1$|^ON$/i )
  {
    $checkType = "Exact Match";
    if ($isNumeric =~ /^TRUE$|^1$|^ON$/i)
    {
      $errFound = 1 if ($actualValue != $expValue);
    }
    else
    {
      $errFound = 1 if ($actualValue ne $expValue);
    }
  }
  else
  {
    $checkType = "Inclusion";
    $errFound = 1 if( index( $actualValue, $expValue ) < 0 );
  }
  if ($errFound || $debug)
  {
    if ($errFound)
    {
      print_error("$stmt failed: No $checkType");
    }
    else
    {
      print("$stmt: Check $checkType\n");
    }
    print("  Expected $var = $expValue\n");
    print("  Actual   $var = $actualValue\n");
  }
}

#
# get_msg() returns the first line from the input file
#
sub get_msg
{
  local($filename) = @_;
  local($msg) = "";

  if (!open(INFILE, "< $filename"))
  {
    print_error("Unable to open $filename");
  }
  $msg = <INFILE>;
  close(INFILE);

  return ($msg);
}

#
# print_result() fetches all the records from the input statement
# handle, and outputs them in an organized manner.
#
sub print_result
{
  local($sth) = @_;
  local(@cell) = ();
  local($i, $j, $numRows, $numColumns);

  #
  # Find out the maximum length of all values in each column,
  # including column names
  #
  $numColumns = $sth->{NUM_OF_FIELDS};
  for ($i=0; $i<$numColumns; $i++)
  {
    $cell[0][$i] = length($sth->{NAME}[$i]);
  }

  #
  # Fetch all the rows
  #
  $i = 0;
  while (@column = $sth->fetchrow_array())
  {
    for ($j=0; $j<$numColumns; $j++)
    {
      $columnLen = length($column[$j]);
      $cell[$i+1][$j] = ($columnLen > $cell[$i][$j] ? $columnLen : $cell[$i][$j]);
      $cell[$i][$j] = ($column[$j] eq ""? "-": $column[$j]);
    }
    $i++;
  }
  $numRows = $i;

  #
  # Print the SQL statement
  #
  print("$sth->{Statement}\n");

  #
  # Print column names
  #
  for ($j=0; $j<$numColumns; $j++)
  {
    $minLen = $cell[$numRows][$j];
    printf "%-${minLen}s  ", $sth->{NAME}[$j];
  }
  print "\n";

  #
  # Print separator between column names and column values
  #
  for ($j=0; $j<$numColumns; $j++)
  {
    $minLen = $cell[$numRows][$j];
    for ($i=0; $i<$minLen; $i++)
    {
      print "-";
    }
    print "  ";
  }
  print "\n";

  #
  # Print column values
  #
  for ($i=0; $i<$numRows; $i++)
  {
    for ($j=0; $j<$numColumns; $j++)
    {
      $minLen = $cell[$numRows][$j];
      printf "%-${minLen}s  ", $cell[$i][$j];
    }
    print "\n";
  }

  #
  # Print number of records
  #
  print("$numRows record(s) selected.\n");

}

#
# get_create_table_stmt() returns an CREATE TABLE statement
#
sub get_create_table_stmt
{
  local($tblname) = @_;
  local(@column) = @{${$tblname}};
  local($stmt) = "CREATE TABLE $tblname (";
  local($i) = 0;

  for($i = 0; $i < @column; $i++)
  {
    $stmt .= "c$i $column[$i]";
    if ($i != $#column)
    {
      $stmt .= ", ";
    }
  }
  $stmt .= ")";

  return($stmt);
}

#
# get_insert_stmt() returns an INSERT statement
#
sub get_insert_stmt
{
  local($tblname, $row, $withParm) = @_;
  local(@column) = @{${$tblname}};
  local($stmt) = "INSERT INTO $tblname (";
  local($q) = "";  # quotation mark
  local($n) = "";  # graphic string indicator
  local($i) = 0;

  #
  # Construct column names
  #
  for($i = 0; $i < @column; $i++)
  {
    $stmt .= "c$i";
    if ($i != $#column)
    {
      $stmt .= ", ";
    }
  }
  $stmt .= ") VALUES (";

  #
  # Construct column values
  #
  for($i = 0; $i < @column; $i++)
  {
    if ($withParm =~ /^TRUE$|^1$|^ON$/i)
    {
      $stmt .= "?";
    }
    else
    {
      $q = "";
      $q = "'" if ($column[$i] =~ /date|time|char|graphic|clob|xml/i);
      $n = "";
      $n = "n" if ($column[$i] =~ /graphic/i);
      $stmt .= "$n$q$real_value{$column[$i]}->[$row]$q";
    }
    if ($i != $#column)
    {
      $stmt .= ", ";
    }
  }
  $stmt .= ")";

  return($stmt);
}

#
# get_values() returns an array of values to be bound
#
sub get_values
{
  local($tblname, $row) = @_;
  local(@column) = @{${$tblname}};
  local(@bind_values) = ();
  local($i) = 0;

  #
  # Construct bind values
  #
  for($i = 0; $i < @column; $i++)
  {
    $bind_values[$i] = $real_value{$column[$i]}->[$row];
  }

  return(@bind_values);
}

sub fvt_begin_testcase
{
  local( $testcaseName ) = @_ ;

  print "\n#####################################################\n\n";
  print("START OF TESTCASE: $testcaseName\n") ;
}

sub fvt_end_testcase
{
  local( $testcaseName, $successFlag ) = @_ ;

  if ( ! defined $successFlag ) {
     print("TESTCASE: $testcaseName ENDED\n");
     $success{$testcaseName} = 0;
  }
  elsif ( $successFlag eq "y" ) {
     print("TESTCASE: $testcaseName SUCCEEDED\n") ;
     $success{$testcaseName} = 1;
  }
  else {
     print("TESTCASE: $testcaseName FAILED\n") ;
     $success{$testcaseName} = -1;
  }
}

sub get_release
{
  $dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD");
  $ver = $dbh->get_info(SQL_DBMS_VER);
  @vers = split(/\./, $ver);
  return $vers[0];
}

sub check_results
{
  local( $sth, $testcase, $mode ) = @_;
  @res = split(/\./, $testcase);
  if( $mode eq "a")
  {
    open(RESULT, ">>res/$res[0].res");
  } else {
    open(RESULT, ">res/$res[0].res");
  }

  $num_fields = $sth->{NUM_OF_FIELDS};
  while(@row = $sth->fetchrow)
  {
    for( $flds = 0; $flds < $num_fields; $flds++)
    {
      print RESULT "$row[$flds] ";
    }
    print RESULT "\n";
  }
  $temp = system("diff -w exp/$res[0].exp res/$res[0].res > err/$res[0].err");

  if( $temp == 0 )
  {
    return "y";
  } else {
    return "n";
  }
  
}

sub fvt_redirect_output
{
   local($file) = @_;

   # Enable redirect/restore to be nested... LJM, Sep. 10/99
   if (! $ENV{'RECURSE'}) { $ENV{'RECURSE'} = 1; }
   else { $ENV{'RECURSE'} = $ENV{'RECURSE'} + 1; }
   $FVT_SAVEOUT = "FVT_SAVEOUT.$ENV{'RECURSE'}";
   $FVT_SAVEERR = "FVT_SAVEERR.$ENV{'RECURSE'}";

   open($FVT_SAVEOUT, ">&STDOUT");
   open($FVT_SAVEERR, ">&STDERR");

   if ($Linux || $Linux390 || $LinuxPPC)
   {
       open(FILE, ">$file") || die "Can't open FILE.\n";
       open(STDOUT, ">&FILE") || die "Can't dup FILE.\n";
       open(STDERR, ">&FILE") || die "Can't dup STDOUT.\n";
       select(FILE); $| = 1; # Make unbuffered
   }
   else
   {
       open(STDOUT, ">$file") || die "Can't redirect STDOUT.";
       open(STDERR, ">&STDOUT") || die "Can't dup STDOUT.";
   }
   select(STDERR); $| = 1;   # Make unbuffered
   select(STDOUT); $| = 1;   # Make unbuffered

}

sub fvt_restore_output
{
    # Enable redirect/restore to be nested... LJM, Sep. 10/99
    $FVT_SAVEOUT = "\>\&FVT_SAVEOUT.$ENV{'RECURSE'}";
    $FVT_SAVEERR = "\>\&FVT_SAVEERR.$ENV{'RECURSE'}";

    if (!$Linux && !$Linux390 && !$LinuxPPC)
    {
        close(STDOUT);
        close(STDERR);
    }

    open(STDOUT, "$FVT_SAVEOUT");
    open(STDERR, "$FVT_SAVEERR");

    if ($Linux || $Linux390 || $LinuxPPC)
    {
        close(FILE);
    }

    select(STDERR); $| = 1;   # Make unbuffered
    select(STDOUT); $| = 1;   # Make unbuffered

    # Enable redirect/restore to be nested... LJM, Sep. 10/99
   if ($ENV{'RECURSE'}) { $ENV{'RECURSE'} = $ENV{'RECURSE'} - 1; }
   else { undef $ENV{'RECURSE'}; }
}

sub rm {
  local($src) = @_ ;

  $src = &sl( $src );
  &fvt_redirect_output("NUL");
  &quiet_system("$rmcmd $src $rmcmdopt");
  &fvt_restore_output();
}

sub quiet_system
{
   local($command) = @_;

   if ($debug_yes_printf || $debug_no_execute ||
   $ENV{DEBUG_YES_PRINTF} || $ENV{DEBUG_NO_EXECUTE} )
   {
      print "$command\n";
   }

   if (!$debug_no_execute && !$ENV{DEBUG_NO_EXECUTE} )
   {
      system $command;
   }

}

sub sl {
  local($src) = @_ ;

  if ( $OS2 || $WIN || $WINT ) { $src =~ tr/\//\\/s ; }
  return($src);
}

sub fvt_removeFileLock
{
  local ( $filename ) = @_ ;

  &rm( $filename );
  return 1;
}

sub fvt_checkFileLock
{
  local ( $filename ) = @_ ;

  if ( -f $filename ) { return 1; }
  else                { return 0; }
}

sub fvt_createFileLock
{
  local( $filename ) = @_ ;

  if ( -f $filename ) { return 0; }
  open (OUT, ">$filename") || die "Can not open $filename \n";
  close(OUT);
}

sub dofetch
{
  local( $sth, $filename ) = @_;
  open(RESULT, ">res/$filename.res");
  
  $sth->execute();
  check_error( 'EXECUTE' );

  # Do a fetch
  my ( $i, $j, @row, @col, $len );

  for( $i = 1; @row = $sth->fetchrow_array(); $i++ )
  {
    check_error( 'FETCH' );

    for( $j = 0; $j < 3; $j++ )
    {
      if( defined( $row[$j] ) )
      {
        $col[$j] = "'$row[$j]'";
        $len = length( $col[$j] );
        if( $len < 12 )  # pad to 12 characters if necessary
        {
          $col[$j] .= " " x (12-$len);
        }
      }
      else
      {
        $col[$j] = "undef       ";
      }
    }
    print RESULT "row $i: CHAR=$col[0] VARCHAR=$col[1] LONGVARCHAR=$col[2]\n";
  }
  $sth->finish();

  $temp = system("diff -w exp/$filename.exp res/$filename.res > err/$res[0].err");

  if( $temp == 0 )
  {
    return "y";
  } else {
    return "n";
  }
  
}

sub is_client_server
{
   if (defined $ENV{CLIENT_SERVER}) {
       return 1;
   }
   else {
       return 0;
   }
}

return 1;
