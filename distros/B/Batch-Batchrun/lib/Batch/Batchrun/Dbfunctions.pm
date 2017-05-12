package Batch::Batchrun::Dbfunctions;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA     = qw(Exporter);
@EXPORT  = qw(
              isql
              command_sqlplus 
              command_sql_report
              command_sql_select
              command_sql_immediate
              command_sqlldr
              command_isql
              command_bcp
              command_autocommit
              command_commit
              command_rollback
              command_sqr
              command_logon
              command_logoff
              );
$VERSION = '1.03';

# Preloaded methods go here.

use Batch::Batchrun::Commands;
use Batch::Batchrun::Library;
use Batch::Batchrun::Pwlookup;
use Batch::Batchrun::Mail;
use File::Basename; 
 
$SIG{__WARN__} = \&handle_warning;

sub handle_warning
{
  $Batch::Batchrun::Msg = "@_";
  print STDERR $Batch::Batchrun::Msg;
}

#****************************************
sub command_sqlplus
#****************************************
  {
   my ($user, $server, $password, $file, $commanddata, $tmpfile);
   if ( ref ( $Batch::Batchrun::Control{'CurrentCommandParm'}) eq "HASH" )
     {
      my %tmphash = %{$Batch::Batchrun::Control{'CurrentCommandParm'}};
      $user = $tmphash{USER};
      $server = $tmphash{SERVER};
      $password = $tmphash{PASSWORD};
      $file = $tmphash{FILE}; # optional
     }
   else
     {
      ( $user, $server, $password, $file ) = split (/,/,$Batch::Batchrun::Control{'CurrentCommandParm'});
     }

   #****************************************************
   #   Figure out which program to run
   #****************************************************
   my $program = 'sqlplus';
   
   #***************************************************
   #  Get a password, if necessary
   #***************************************************
   $user =~ s/^\s*//o;
   $user =~ s/\s*^//o;
   $server =~ s/^\s*//o;
   $server =~ s/\s*$//o;
   if ( $password eq '' or $password =~ /lookup/i )
     {
      $password = dbpwdlookup ( $server, $user );
     }
   $password =~ s/^\s*//o;
   $password =~ s/\s*$//o;
   if ( !$password or $password eq ' ' )
     {
      $Batch::Batchrun::Msg = 'Unable to run sqlplus because no password supplied or looked up';
      return $Batch::Batchrun::ErrorCode;
     }

   #***************************************************
   #  Escape $'s in the username
   #***************************************************
   $user =~ s/\$/\\\$/;

   #*************************************************************
   #  Build the command file using file parameter or command data
   #*************************************************************
   if ( $^O !~ /win/i )
     {
     $tmpfile = '/tmp/'.$$.'sqlplus.sql';
     }
   else
     {
     $tmpfile = 'c:\temp\\'.$$.'sqlplus.sql';
     }   
   open ( CMDFILE, ">$tmpfile" ) or die "** cant open $tmpfile because $!";
   print CMDFILE "Set TERMOUT Off\nWhenever OSERROR Exit 1\nWhenever SQLERROR Exit 2\n";

   if ($file) # verify $file and read into $tmpfile
     {
      if (!(-e $file))
        {
         $Batch::Batchrun::Msg = "The sql input file [$file] does NOT exist.";
         return $Batch::Batchrun::ErrorCode;
        }
      elsif (-z $file)
        {
         $Batch::Batchrun::Msg = "The sql input file [$file] is EMPTY.";
         return $Batch::Batchrun::ErrorCode;
        }
      elsif (-B $file)
        {
         $Batch::Batchrun::Msg = "The sql input file [$file] is a BINARY file.";
         return $Batch::Batchrun::ErrorCode;
        }
      elsif (!(-r $file))
        {
         $Batch::Batchrun::Msg = "The sql input file [$file] is NOT readable.";
         return $Batch::Batchrun::ErrorCode;
        }
      else # read $file into $tmpfile
        {
        open(DATA, "<$file") or warn "Could not open the sql input file [$file] $!\n";
        foreach (<DATA>)
          {
          print CMDFILE $_;
          }
        close(DATA);
        }
     }
   else # write command data to $tmpfile
     {
      $commanddata = $Batch::Batchrun::Control{CurrentCommandData};
      print CMDFILE "$commanddata";
     }
   close (CMDFILE);
    
   #***************************************************
   #   Build the command
   #***************************************************
 
      my $connect_string = "$user/$password\@$server";
      my $command;

      if ( $^O !~ /win/i )
       {
        $command = "$program -s <<ENDOFINPUT
$connect_string
\@$tmpfile
ENDOFINPUT";
       }
      else
       {
        $command = "$program $connect_string \@$tmpfile"; 
       }

      ## print "***\n$command\n***\n";

      my $rc = exec_system($command);
      unlink($tmpfile);
      return $rc;  
  }



#******************************
sub isql
#******************************
  {

   my %tmphash =  %{$Batch::Batchrun::Control{'CurrentCommandData'}};

   # Required
   my $sql_file         = $tmphash{SQL_FILE};
   my $output_file      = $tmphash{OUTPUT_FILE};
   my $user             = $tmphash{USER};
   my $server           = $tmphash{SERVER};

   # optional
   my $password         = $tmphash{PASSWORD};
     
   #****************************************************
   #   Check the file status of $sql_file
   #****************************************************
   if (!(-e $sql_file))
     {
      $Batch::Batchrun::Msg = 'The isql input file [$sql_file] does not exist.';
      return $Batch::Batchrun::ErrorCode;
     }
   elsif (-z $sql_file)
     {
      $Batch::Batchrun::Msg = 'The isql input file [$sql_file] is empty.';
      return $Batch::Batchrun::ErrorCode;
     }
   elsif (-B $sql_file)
     {
      $Batch::Batchrun::Msg = 'The isql input file [$sql_file] is a binary file.';
      return $Batch::Batchrun::ErrorCode;
     }
   elsif (!(-r $sql_file))
     {
      $Batch::Batchrun::Msg = 'The isql input file [$sql_file] is not readable.';
      return $Batch::Batchrun::ErrorCode;
     }
  
   #****************************************************
   #   Check the file status of $output_file
   #****************************************************
   my $isql_output_dir = dirname($output_file);
   $isql_output_dir = '.' unless $isql_output_dir;

   if ((-e $output_file) and !(-w $output_file))
     {
      $Batch::Batchrun::Msg = "The isql output file [$output_file] exists and is not writable.";
      return $Batch::Batchrun::ErrorCode;
     }
   elsif (!(-e $isql_output_dir))
     {
      $Batch::Batchrun::Msg = "The isql output directory [$isql_output_dir] does not exist.";
      return $Batch::Batchrun::ErrorCode;
     }
   elsif (!(-w $isql_output_dir))
     {
      $Batch::Batchrun::Msg = "The isql output directory [$isql_output_dir] is not writable.";
      return $Batch::Batchrun::ErrorCode;
     }

   #****************************************************
   #   Figure out which program to run
   #****************************************************
   my $program;
   if ( $^O =~ /win/i )
     { 
      $program = $Batch::Batchrun::Control{CONFIG}{ScriptProgram}{ms_isql};
     }
   else
     { 
      $program = $Batch::Batchrun::Control{CONFIG}{ScriptProgram}{sybase_isql};
     }
   $program = 'isql' if ( $program eq '' );

   #***************************************************
   #   Do a little checking of values
   #***************************************************
   #if ( $direction !~ /in|out/i ) or
   #   ( substr($mode,0,1) !~ /c|n/i ) or
   #***************************************************
   #  Get a password, if necessary
   #***************************************************
    $user =~ s/^\s*//o;
    $user =~ s/\s*^//o;
    $server =~ s/^\s*//o;
    $server =~ s/\s*$//o;
    if ( $password eq '' or $password =~ /lookup/i )
      {
       $password = dbpwdlookup ( $server, $user );
      }
   $password =~ s/^\s*//o;
   $password =~ s/\s*$//o;
   if ( $password eq ' ' )
     {
      $Batch::Batchrun::Msg = 'Unable to run isql because no password supplied or looked up';
      return $Batch::Batchrun::ErrorCode;
     }

   #***************************************************
   #   Build the command
   #***************************************************
   
   my $command  = $program . ' ';
      $command .= '-U' . $user . ' ';
      $command .= '-S' . $server . ' ';
     
      $command .= "-i$sql_file " if ( $sql_file ne '' );
      $command .= "-o$output_file " if ( $output_file ne '' );
      
      print " ISQL command to execute (except password): $command \n" if ($Batch::Batchrun::Output{$Batch::Batchrun::Counter});
      
   if ( $^O !~ /win/i )
     {
      $command .= "<<INPUT
$password
INPUT";
     }
   else
     {
      $command .= '-P' . $password . ' ';
     }

      my $rc = exec_system($command);
      return $rc;  
  }
  
#*******************************************************
#  SQL REPORT
#*******************************************************
sub command_sql_report
  {
   #******************************************
   #  Housekeeping
   #******************************************
   my ( $sql    )  = $Batch::Batchrun::Control{'CurrentCommandData'};
   
   my $handle; my $file;

   my %tmphash = %{$Batch::Batchrun::Control{'CurrentCommandParm'}};
   $handle = $tmphash{HANDLE};
   $handle =~ s/^\s*//;
   $file = $tmphash{FILE};

   #******************************************
   #   Check the connection
   #******************************************
   if ( !defined($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC})) 
     {
      $Batch::Batchrun::Msg = "No valid connection for $handle";   
      return $Batch::Batchrun::ErrorCode;
     }
   #******************************************
   #   Prepare the statement
   #******************************************
   my $sth = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}->prepare($sql);
   if ( !defined($sth) )
     {
      $Batch::Batchrun::Msg = "ERROR: Not able to prepare statement: $sql for handle: $handle because $DBI::errstr\n";
      return $Batch::Batchrun::ErrorCode;
     }
   #******************************************
   #   Execute the statement
   #******************************************
   my $rc = $sth->execute; 
   if ( !defined($rc) )
     {
      $Batch::Batchrun::Msg = "ERROR: Not able to execute statement $sql because: $DBI::errstr \n";
      return $Batch::Batchrun::ErrorCode;
     }

   #******************************************
   #   Alter the FORMAT and other print setup
   #******************************************
   my($numcols) = $sth->{NUM_OF_FIELDS};
   my(@ColName) = @{$sth->{NAME}};

   my @col_data=();
   #  alter the format with the col_data
   if ( defined($Batch::Batchrun::Control{FORMAT}) )
     {
      if ( $file )  
        {
         $Batch::Batchrun::Control{FORMAT} =~ s/format/format OUTFILE/; 
        }
      my $i;
      $Batch::Batchrun::Control{FORMAT} .= "\n";
      foreach ($i=0;$i<$numcols;$i++)
        {
         $Batch::Batchrun::Control{FORMAT} .=
                "\$col_data[$i] ";
         if ( $i < $numcols - 1 ) { $Batch::Batchrun::Control{FORMAT} .= ','; }
        }
      $Batch::Batchrun::Control{FORMAT} .= "\n\.";
      #print "***$Batch::Batchrun::Control{FORMAT}***\n";
      eval $Batch::Batchrun::Control{FORMAT};
     }

    #**************************************************************
    #  Begin OUTPUT, handle FILE
    #**************************************************************

    if ( $file ne '' )
      {
       open ( OUTFILE, ">$file" ) 
          or  $Batch::Batchrun::Msg = $!, return $Batch::Batchrun::ErrorCode;
       select OUTFILE; $|=1;
      }

     if ( $Batch::Batchrun::Output{$Batch::Batchrun::Counter} )
       {
        print "\n\n**** Printing data for the following columns: \n   @ColName \n\n" ;
       }

    #*********************************************************
    #  Write out the rows
    #**********************************************************
    my @dat = ();
    while ( 1 )
      {
       @dat = $sth->fetchrow_array;

       if ( $DBI::errstr ne '' )
         {
           $Batch::Batchrun::Msg = $DBI::errstr;
           return $Batch::Batchrun::ErrorCode;
         }
       last unless @dat; 

       if (!defined($Batch::Batchrun::Control{FORMAT}))
         {
          my $col;
          foreach $col ( @dat )
            {
              print " $col ";
            }
          print " \n";
         }
       else
         {
          @col_data = @dat; 
          write;
         }
       } 
     $Batch::Batchrun::Control{FORMAT} = undef;
     if ( $file ) { close ( OUTFILE ); }
     select STDOUT;
     return $Batch::Batchrun::NoErrors;

  }  #  End of SQL Report

#*******************************************************
#  AUTOCOMMIT
#*******************************************************
sub command_autocommit
  {
   #******************************************
   #  Housekeeping
   #******************************************
   
   my ( $handle, $state );

   my %tmphash = %{$Batch::Batchrun::Control{'CurrentCommandParm'}};
   $handle = $tmphash{HANDLE};
   $state  = $tmphash{STATE};

   $handle =~ s/^\s*//;         #  Remove leading whitespace characters
   $handle =~ s/\s*$//;         #  Remove trailing whitespace characters
   $state =~ s/^\s*//;         #  Remove leading whitespace characters
   $state =~ s/\s*$//;         #  Remove trailing whitespace characters

   if ( ! ref($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}) )
     {
      $Batch::Batchrun::Msg = "There is no valid handle: $handle \n"; 
      return $Batch::Batchrun::ErrorCode;
     }

   if ( $state =~ /off/i )
     {
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}->{AutoCommit} = 0;
     }
   elsif ( $state =~ /on/i )
     {
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}->{AutoCommit} = 1;
     }

   return $Batch::Batchrun::NoErrors;

  }


#*******************************************************
#  COMMIT
#*******************************************************
sub command_commit
  {
   #******************************************
   #  Housekeeping
   #******************************************
   
   my ( $handle,$rc );

   my %tmphash = %{$Batch::Batchrun::Control{'CurrentCommandParm'}};
   $handle = $tmphash{HANDLE};

   $handle =~ s/^\s*//;         #  Remove leading whitespace characters
   $handle =~ s/\s*$//;         #  Remove trailing whitespace characters

   if ( ! ref($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}) )
     {
      $Batch::Batchrun::Msg = "There is no valid handle: $handle \n";
      return $Batch::Batchrun::ErrorCode;
     }

   $rc = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}->commit;

   if ( ! $rc )
    {
     $Batch::Batchrun::Msg = "**  Commit failed! \n ** $DBI::errstr \n";
     return $Batch::Batchrun::ErrorCode;
    }
   else
    {
     return $Batch::Batchrun::NoErrors;
    }

  }


#*******************************************************
#  ROLLBACK
#*******************************************************
sub command_rollback
  {
   #******************************************
   #  Housekeeping
   #******************************************
   
   my ( $handle,$rc );

   my %tmphash = %{$Batch::Batchrun::Control{'CurrentCommandParm'}};
   $handle = $tmphash{HANDLE};

   $handle =~ s/^\s*//;         #  Remove leading whitespace characters
   $handle =~ s/\s*$//;         #  Remove trailing whitespace characters

   if ( ! ref($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}) )
     {
      $Batch::Batchrun::Msg = "There is no valid handle: $handle \n";
      return $Batch::Batchrun::ErrorCode;
     }

   $rc = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}->rollback;


   if ( ! $rc )
    {
     $Batch::Batchrun::Msg = "**  Rollback failed! \n ** $DBI::errstr \n";
     return $Batch::Batchrun::ErrorCode;
    }

   #******************************************************
   #  If ROLLBACK was issued, but Autocommit was ON,
   #  DBI issues 'warn' with message about 'ineffective rollback
   #  operation'.  The warning handler at the top grabs the 
   #  message and puts it into $Batch::Batchrun::Msg, so here
   #  we check for it and if it has a message, we set
   #  the warning level
   #******************************************************

   if ( $Batch::Batchrun::Msg =~ /rollback ineffective/i )
     {
      return $Batch::Batchrun::WarningCode;
     }

   return $Batch::Batchrun::NoErrors;

  }

#*******************************************************
#  SQL SELECT
#*******************************************************
sub command_sql_select
  {
   #******************************************
   #  Housekeeping
   #******************************************
   my ( $sql )      = $Batch::Batchrun::Control{'CurrentCommandData'};
   
   my $handle; my @bind_vars;

   if ( ref ( $Batch::Batchrun::Control{'CurrentCommandParm'}) eq "HASH" )
     {
      my %tmphash = %{$Batch::Batchrun::Control{'CurrentCommandParm'}};
      $handle = $tmphash{HANDLE};
      @bind_vars = split ( /,/ , $tmphash{BIND_VARS});
     }
   else
     {
      ( $handle, @bind_vars ) = split ( /,/, $Batch::Batchrun::Control{'CurrentCommandParm'} ); 
     }

   $handle =~ s/^\s*//;         #  Remove leading whitespace characters

   #******************************************
   #   Check the connection
   #******************************************
   if ( !defined($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC})) 
     {
      $Batch::Batchrun::Msg = "No valid connection for $handle";   
      return $Batch::Batchrun::ErrorCode;
     }
   #******************************************
   #   Prepare the statement
   #******************************************
   my $sth = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}->prepare($sql);
   if ( !defined($sth) )
     {
      $Batch::Batchrun::Msg = "ERROR: Not able to prepare statement: $sql for handle: $handle because $DBI::errstr\n";
      return $Batch::Batchrun::ErrorCode;
     }
   #******************************************
   #   Execute the statement
   #******************************************
   my $rc = $sth->execute; 
   if ( !defined($rc) )
     {
      $Batch::Batchrun::Msg = "ERROR: Not able to execute statement $sql because: $DBI::errstr \n";
      return $Batch::Batchrun::ErrorCode;
     }
   #******************************************
   #   Fetch the row
   #******************************************
   my @dat = $sth->fetchrow_array;
   if ($#dat < 0 )
     {
      $Batch::Batchrun::Msg = "WARNING: No row returned when one expected for sql statement:\n $sql handle: $handle \n";
      #  Add code here to UNBIND any bv's that exist.  LMM 3/1/99
      my $i = 0;
      my $bind_var = '';
      foreach $bind_var ( @bind_vars )
        {
         $bind_var =~ s/^\s*//og;
         $bind_var =~ s/\s*$//g;
         $bind_var = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'Index'} . "^" . $bind_var;
         undef $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASKPARAMPAIRS'}{$bind_var};
         $i++;
        }
      return $Batch::Batchrun::WarningCode;
     }
   #******************************************
   #   Finish the statement
   #******************************************
   $sth->finish;
   #******************************************
   #   If bind vars specified, put values in parampairs hash
   #******************************************
   if ( $#bind_vars >= 0 )
     {
      if ( $#bind_vars != $#dat )
        {
         $Batch::Batchrun::Msg = "ERROR: Number of bind variables declared doesn't match SQL statement\n";
         return $Batch::Batchrun::ErrorCode;
        }
      my $i = 0;
      my $bind_var = '';
      foreach $bind_var ( @bind_vars )
        {
         $bind_var =~ s/^\s*//og;
         $bind_var =~ s/\s*$//g;
         $bind_var = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'Index'} . "^" . $bind_var;
         $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASKPARAMPAIRS'}{$bind_var}=$dat[$i];
         $i++;
        }
     }  
  }  #  End of SQL Select 


#*******************************************************
#  SQL IMMEDIATE
#*******************************************************
sub command_sql_immediate
  {
   #******************************************
   #  Housekeeping
   #******************************************
   my ( $sql )      = $Batch::Batchrun::Control{'CurrentCommandData'};
   
   my $handle;

   if ( ref ( $Batch::Batchrun::Control{'CurrentCommandParm'}) eq "HASH" )
     {
      my %tmphash = %{$Batch::Batchrun::Control{'CurrentCommandParm'}};
      $handle = $tmphash{HANDLE};
     }
   else
     {
      $handle   = $Batch::Batchrun::Control{'CurrentCommandParm'};
     }

   $handle =~ s/^\s*//;         #  Remove leading whitespace characters

   #******************************************
   #   Check the connection
   #******************************************
   if ( !defined($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC})) 
    {
         $Batch::Batchrun::Msg = "No valid connection for $handle";   
         return $Batch::Batchrun::ErrorCode;
        }

   if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBTYPE} =~ /oracle|odbc/i )
     {
      #*************************************************
      #  DO  for ORACLE or ODBC
      #*************************************************
      my $rows = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}->do($sql);
      my $stringrows = sprintf("%s",$rows);

      #  7/17/98 if ( $DBI::errstr )
      if ( $DBI::err )
        {
         $Batch::Batchrun::Msg = "\nThe following error occured: \nErrorCode: $DBI::err " .
                          "\n$DBI::errstr\n\nwhile processing the SQL stmt: \n$sql\n\n";
         return $Batch::Batchrun::ErrorCode; 
        }
      
      if ( $Batch::Batchrun::PrintSw{$Batch::Batchrun::Counter} and $Batch::Batchrun::Output{$Batch::Batchrun::Counter} )
        { 
         if ( $rows == 0 or $rows == -1)
           {  
            print "Command completed successfully\n"; 
            print "Zero rows affected\n";
           }
         else
           {  
            print "$rows rows affected\n";
           }
        }
      #********************************************
      #  Get any output from the dbms_output(ORACLE), if there is any
      #                          LM 9/29/98
      #********************************************
      if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBTYPE} =~ /oracle/i )
       {
        foreach ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}->func("dbms_output_get") )
         {
          print "$_\n";
         }
       }
     }   #**  End DO for ORACLE or ODBC  ***

   elsif ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBTYPE} =~ /sybase/i )
     {
     #*****************************************
     #  DO for SYBASE  ( a little different )
     #*****************************************
     my $dbh = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC};
     #**************************
     #   Prepare    
     #**************************
     my $sth = $dbh->prepare($sql);
     if ( !defined($sth) )
       {
        $Batch::Batchrun::Msg = "ERROR: Not able to prepare statement: $sql for handle: $handle because $DBI::errstr\n";
        return $Batch::Batchrun::ErrorCode;
       }
     #*************************
     #  Execute
     #*************************
     my $rc = $sth->execute;
     if ( !defined($rc) )
       {
        $Batch::Batchrun::Msg = "ERROR: Not able to execute statement $sql because: $DBI::errstr \n";
        return $Batch::Batchrun::ErrorCode;
       }
     #*************************
     #  Fetch loop
     #*************************
     my @holdthis = ();
     
     if ( defined $sth->{syb_more_results} )
       {
        do {
            while ( @holdthis = $sth->fetchrow_array )
             {
               if ( $DBI::err )
                 { 
                  $Batch::Batchrun::Msg = "ERROR: Not able to execute statement $sql because: $DBI::errstr \n";
                  return $Batch::Batchrun::ErrorCode;
                 }
               if ( @holdthis )
                   { print "@holdthis \n"; }
             }
          } while ( $sth->{syb_more_results});
       }
     $sth->finish;
     }  #***  End of DO for SYBASE
   else
     {
      $Batch::Batchrun::Msg = "***  Never should get here **** Undefined DBTYPE\n";
      return $Batch::Batchrun::ErrorCode;
     }

   return $Batch::Batchrun::NoErrors;
  }


#****************************************
sub command_sqlldr
#****************************************
  {
   
   #*******************************************
   # Valid Keywords:
   #
   #      user=>    ORACLE username/password@sqlnet_string 
   #    server=>    sqlnet_string
   #  password=>    password
   #   control=>    Control file name                  
   #       log=>    Log file name                      
   #       bad=>    Bad file name                      
   #      data=>    Data file name                     
   #   discard=>    Discard file name                  
   #discardmax=>    Number of discards to allow          (Default all)
   #      skip=>    Number of logical records to skip    (Default 0)
   #      load=>    Number of logical records to load    (Default all)
   #    errors=>    Number of errors to allow            (Default 50)
   #      rows=>    Number of rows in conventional path bind array 
   #               or between direct path data saves
   #               (Default: Conventional path 64, Direct path all)
   #  bindsize=>    Size of conventional path bind array in bytes  (Default 65536)
   #    silent=>    Suppress messages during run (header,feedback,errors,discards)
   #    direct=>    use direct path                      (Default FALSE)
   #   parfile=>    parameter file: name of file that contains parameter specifications
   #  parallel=>    do parallel load                     (Default FALSE)
   #      file=>    File to allocate extents from      
   #
   #***************************************************
   #  Check for required fields
   #*****************************************************
   if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData} =~ /control/i    and
        $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData} =~ /user/i       and
        $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData} =~ /server/i  ) 
     {
      #my $sqlldr_rc = sqlldr();
      #return $sqlldr_rc;
     }
   else
     {
      $Batch::Batchrun::Msg = 'Missing one or more required parameters for sqlldr';
      return $Batch::Batchrun::ErrorCode;
     }

   my %tmphash;
   if ( ref ( $Batch::Batchrun::Control{'CurrentCommandData'}) eq "HASH" )
     {
      %tmphash = %{$Batch::Batchrun::Control{'CurrentCommandData'}};
     }
   else
     {
       # This should happen when command_logon called from another command
       # within batchrun.  A named parameter hash is passed as the argument
      %tmphash = @_;
     }


   # Required
   my $control          = $tmphash{CONTROL};
   my $user             = $tmphash{USER};
   my $server           = $tmphash{SERVER};
   my $data             = $tmphash{DATA};

   # optional
   my $password         = $tmphash{PASSWORD};
   my $log              = $tmphash{LOG};
   my $bad              = $tmphash{BAD};
   my $discard          = $tmphash{DISCARD};
   my $discardmax       = $tmphash{DISCARDMAX};
   my $skip             = $tmphash{SKIP};
   my $load             = $tmphash{LOAD};
   my $errors           = $tmphash{ERRORS};
   my $rows             = $tmphash{ROWS};
   my $bindsize         = $tmphash{BINDSIZE};
   my $silent           = $tmphash{SILENT};
   my $direct           = $tmphash{DIRECT};
   my $parfile          = $tmphash{PARFILE};
   my $parallel         = $tmphash{PARALLEL};
   my $file             = $tmphash{FILE};
   
   # Batchrun only options
   my $ignore_errors    = $tmphash{IGNORE_ERRORS};
   my $show_errors      = $tmphash{SHOW_ERRORS};
   

   #****************************************************
   #   Figure out which program to run
   #****************************************************
   my $program = 'sqlldr';
   
   #***************************************************
   #   Do a little checking of values
   #***************************************************
   #if ( $direction !~ /in|out/i ) or
   #   ( substr($mode,0,1) !~ /c|n/i ) or
   #***************************************************
   #  Get a password, if necessary
   #***************************************************
   $user =~ s/^\s*//o;
   $user =~ s/\s*^//o;
   $server =~ s/^\s*//o;
   $server =~ s/\s*$//o;
   if ( $password eq '' or $password =~ /lookup/i )
     {
      $password = dbpwdlookup ( $server, $user );
     }
   $password =~ s/^\s*//o;
   $password =~ s/\s*$//o;
   if ( $password eq ' ' )
     {
      $Batch::Batchrun::Msg = 'Unable to run SQLLDR because no password supplied or looked up';
      return $Batch::Batchrun::ErrorCode;
     }

   #***************************************************
   #   Build the command
   #***************************************************
   $user =~ s/ops\$/ops\\\$/ if $user =~ /ops\$/;
 
   my $connect_string = "$user/$password\@$server";
   my $logtemp;
   
   if ( $log eq '' and $Batch::Batchrun::Output{$Batch::Batchrun::Counter})
     {
     $logtemp = 1;
     if ( $^O =~ /win/i )
       {
       $log = $ENV{TEMP} . "\\" . $$ . "ldr.log";
       }
     else
       {
       $log = '/tmp/' . $$ . 'ldr.log';
       }
     }
   if ( $bad eq '' )
     {
     if ( $^O =~ /win/i )
       {
       $log = $ENV{TEMP} . "\\" . $$ . "bad.dat";
       }
     else
       {
       $log = '/tmp/' . $$ . 'bad.dat';
       }     
     }
     
   my $command .= "control=$control ";
      $command .= "log=$log " if ( $log ne '' );
      $command .= "bad=$bad " if ( $bad ne '' );
      $command .= "data=$data " if ( $data ne '' );
      $command .= "discard=$discard " if ( $discard ne '' );
      $command .= "discardmax=$discardmax " if ( $discardmax ne '' );
      $command .= "skip=$skip " if ( $skip ne '' );
      $command .= "load=$load " if ( $load ne '' );
      $command .= "errors=$errors " if ( $errors ne '' );
      $command .= "rows=$rows " if ( $rows ne '' );
      $command .= "bindsize=$bindsize " if ( $bindsize ne '' );
      $command .= "silent=$silent " if ( $silent ne '' );
      $command .= "direct=$direct " if ( $direct ne '' ); 
      $command .= "parfile=$parfile " if ( $parfile ne '' );
      $command .= "parallel=$parallel " if ( $parallel ne '' );
      $command .= "file=$file " if ( $file ne '' );
      
      #print " SQLLDR command to execute (except password):",
      #       "$program $user\@$server $command \n" 
      #       if ($Batch::Batchrun::Output{$Batch::Batchrun::Counter});
      #------------------------------------------------------------------------
      # If the bad file already exists then remove it.  It must be remaining from
      # a previous run and will cause problems with checking errors this time
      #-------------------------------------------------------------------------
      if ( -e $bad)
        {
        warn("\nRemoving existing badfile:$bad\n\n");
        unlink($bad);
        }  
        
      if ( $^O !~ /win/i )
       {
        $command = "$program $command <<INPUT\n$connect_string\nINPUT";
       }
     else
       {
        $command = "$program $connect_string $command";
       }

      ## print "**** COMMAND:$command****\n";
      my $rc = exec_system($command);
      my $max_exceeded = 0;
      my $warnings_found = 0;
      
      open(LDRLOG, "<$log") or warn "Could not open $log for input $!\n";
      foreach (<LDRLOG>)
        {
        $max_exceeded = 1 if m/MAXIMUM ERROR COUNT EXCEEDED/io;
        $warnings_found = 1  if m/Error on table/io;
        $warnings_found = 1  if m/\sORA-/o;
        print $_ if ($Batch::Batchrun::Output{$Batch::Batchrun::Counter});
        }
      close(LDRLOG);
      
      if (($show_errors =~ /yes|true/io) and $Batch::Batchrun::Output{$Batch::Batchrun::Counter})
        {
        print "\n%%%%%%%%%%%  Bad File Contents  %%%%%%%%%%%\n";
        open(BADFILE, "<$bad") or warn "Could not open $bad for input $!\n";
        foreach (<BADFILE>)
          {
          print $_;
          }
        close(BADFILE);
        print "\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
        }
      
      if ($logtemp)
        {
        unlink($log);
        }      
      
      if ($rc == $Batch::Batchrun::ErrorCode)
        {
        return $Batch::Batchrun::ErrorCode;
        }
      elsif ($warnings_found)
        {
        $Batch::Batchrun::Msg = 'SQLLOAD Warnings found in log file!';
        return $Batch::Batchrun::WarningCode;
        }      
      elsif ($max_exceeded)
        {
        $Batch::Batchrun::Msg = 'ERROR - MAXIMUM ERROR COUNT EXCEEDED!';
        return $Batch::Batchrun::ErrorCode;
        }     
      elsif ( -s $bad and ($ignore_errors !~ /yes|true/i))
        {
        $Batch::Batchrun::Msg = 'SQLLOADER - Some records not loaded';
        return $Batch::Batchrun::ErrorCode;
        }
      elsif ( -s $bad and ($ignore_errors =~ /yes|true/i))
        {
        $Batch::Batchrun::Msg = 'SQLLOADER - Some records not loaded';
        return $Batch::Batchrun::WarningCode;    
        }
      else
        {
        return $Batch::Batchrun::NoErrors;
        }
  }
  
sub command_isql
  {
   
   #    !ISQL
   #    sql_file=>           file containing sql statements
   #    output_file=>        output file
   #    user=>               database user
   #    server=>             server name
   #    password=>           (optional) actual password or LOOKUP
   #
   
   #****************************************************
   #  Check for required fields
   #*****************************************************
   if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData} =~ /sql_file/i    and
        $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData} =~ /output_file/i  and
        $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData} =~ /user/i       and
        $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData} =~ /server/i  ) 
     {
      my $isql_rc = isql();
      return $isql_rc;
     }
   else
     {
      $Batch::Batchrun::Msg = 'Missing one or more required parameters for isql';
      return $Batch::Batchrun::ErrorCode;
     }
  }
  
 sub command_bcp
   {
    #    !BCP
    #    table=>              database..table_name
    #    direction=>          in|out
    #    data_file=>          fully qualified table name
    #    user=>               database user
    #    server=>             server name
    #    password=>           (optional) actual password or LOOKUP
    #    mode=>               n(ative) or c(haracter) mode
    #    format_file=>        fully qualified format file name
    #    error_file=>         fully qualified error file name
    #    field_terminator=>   unquoted field terminator
    #    row_terminator=>     unquoted row terminator - default is newline
    #    packetsize=>         network packet size
    #    batchsize=>          number of rows to process before commit
    #    max_errors=>         max number of errors before aborting the process
    #
    #****************************************************
    #  Check for required fields
    #*****************************************************

   #
   ##  Shouldn't do this because of Microsoft names with spaces
   #   I think parms_to_hash handles this.  Check with D.  9/1/98
   # Must do this for now... -Daryl-

   my %tmphash =  %{$Batch::Batchrun::Control{'CurrentCommandData'}};
   my $x;

    if ( ! ( $tmphash{TABLE}      and
             $tmphash{DIRECTION}  and
             $tmphash{DATA_FILE}  and
             $tmphash{USER}       and
             $tmphash{SERVER}  )  )
      {
       $Batch::Batchrun::Msg = 'Missing one or more required parameters for bcp';
       return $Batch::Batchrun::ErrorCode;
      }

   my $table            = $tmphash{TABLE};
   my $direction        = $tmphash{DIRECTION};
   my $data_file        = $tmphash{DATA_FILE};
   my $user             = $tmphash{USER};
   my $server           = $tmphash{SERVER};

   # optional
   my $password         = $tmphash{PASSWORD};
   my $mode             = $tmphash{MODE};
   my $format_file      = $tmphash{FORMAT_FILE};
   my $error_file       = $tmphash{ERROR_FILE};
   my $field_terminator = $tmphash{FIELD_TERMINATOR};
   my $row_terminator   = $tmphash{ROW_TERMINATOR};
   my $packetsize       = $tmphash{PACKETSIZE};
   my $batchsize        = $tmphash{BATCHSIZE};
   my $max_errors       = $tmphash{MAX_ERRORS};
   my $ignore_errors    = $tmphash{IGNORE_ERRORS};
   my $show_errors      = $tmphash{SHOW_ERRORS};
   
   #***************************************************
   #   Do a little checking of values
   #***************************************************
   if ( $format_file and $mode )
      {
       $Batch::Batchrun::Msg = 'Choose either format file or mode, not both';
       return $Batch::Batchrun::ErrorCode;
      }

   #****************************************************
   #   Check the file status of $format_file
   #****************************************************
   if ($format_file)
     {
      if (!(-e $format_file))
        {
         $Batch::Batchrun::Msg = "The bcp format file [$format_file] does not exist.";
         return $Batch::Batchrun::ErrorCode;
        }
      elsif (-z $format_file)
        {
         $Batch::Batchrun::Msg = 'The bcp format file [$format_file] is empty.';
         return $Batch::Batchrun::ErrorCode;
        }
      elsif (-B $format_file)
        {
         $Batch::Batchrun::Msg = 'The bcp format file [$format_file] is a binary file.';
         return $Batch::Batchrun::ErrorCode;
        }
      elsif (!(-r $format_file))
        {
         $Batch::Batchrun::Msg = "The bcp format file [$format_file] is not readable.";
         return $Batch::Batchrun::ErrorCode;
        }
     }

   #****************************************************
   #   Check the file status of $data_file
   #****************************************************
   my $bcp_data_dir = dirname($data_file);
   $bcp_data_dir = '.' unless $bcp_data_dir;

   if ((-e $data_file) and !(-w $data_file))
     {
      $Batch::Batchrun::Msg = "The bcp data file [$data_file] exists and is not writable.";
      return $Batch::Batchrun::ErrorCode;
     }
   elsif (!(-e $bcp_data_dir))
     {
      $Batch::Batchrun::Msg = "The bcp data directory [$bcp_data_dir] does not exist.";
      return $Batch::Batchrun::ErrorCode;
     }
   elsif (!(-w $bcp_data_dir))
     {
      $Batch::Batchrun::Msg = "The bcp data directory [$bcp_data_dir] is not writable.";
      return $Batch::Batchrun::ErrorCode;
     }

   #****************************************************
   #   Figure out which program to run and errorfile to build
   #****************************************************
   my $program;
   if ( $^O =~ /win/i )
     { 
      $program = $Batch::Batchrun::Control{CONFIG}{ScriptProgram}{ms_bcp};
      $error_file = $ENV{TEMP} . '\bcperrors.tmp' if (not $error_file);
     }
   else
     { 
      $program = $Batch::Batchrun::Control{CONFIG}{ScriptProgram}{sybase_bcp};
      $error_file = '/tmp/bcperrors.tmp' if (not $error_file);
     }
   #
   # If error_file is specified. Remove it so we know the contents are
   # for this run.  If the unlink fails then print a warning and create
   # a unique file with similar name.
   #
   if ( $tmphash{ERROR_FILE} and -s $tmphash{ERROR_FILE} )
     {
     if (! unlink($tmphash{ERROR_FILE}) and $Batch::Batchrun::Output{$Batch::Batchrun::Counter} )
       {
       print "Unable to remove old error file:$tmphash{ERROR_FILE}\n";
       print "A unique file with a similar name will be created!\n";
       }
     }
   #
   # Make sure error file is unique.  If the error file was passed,
   # then assume it's ok to overwrite, otherwise make it unique.
   #
   
   if (-e $error_file and (not $tmphash{ERROR_FILE} or -s $tmphash{ERROR_FILE}) )
     {
     #print "$error_file exists\n";
     my $tmpnum = 1;
     $error_file .= $tmpnum;
     while ( -e $error_file)
       {
       #print "while before: $error_file\n";
       $tmpnum++;
       $error_file =~ s/\d+$/$tmpnum/;
       #print "while after: $error_file\n";
       if ($tmpnum > 1000)
         {
         print "Caught in infinite loop!!!!!\n";
         last;
         }
       }
     }
     
   $program = 'bcp' if ( $program eq '' );

   #***************************************************
   #  Get a password, if necessary
   #***************************************************
   $user =~ s/^\s*//o;
   $user =~ s/\s*^//o;
   $server =~ s/^\s*//o;
   $server =~ s/\s*$//o;
   if ( $password eq '' or $password =~ /lookup/i )
     {
      $password = dbpwdlookup ( $server, $user );
     }
   $password =~ s/^\s*//o;
   $password =~ s/\s*$//o;
   if ( $password eq ' ' )
     {
      $Batch::Batchrun::Msg = 'Unable to run bcp because no password supplied or looked up';
      return $Batch::Batchrun::ErrorCode;
     }

   #***************************************************
   #   Build the command
   #***************************************************
   my $command  = $program . ' ';
      $command .= $table . ' ';
      $command .= $direction . ' ';
      $command .= $data_file . ' ';
      $command .= '-U' . $user . ' ';
      $command .= '-S' . $server . ' ';
      #  $command .= '-P' . $password . ' ';
      $mode = lc(substr($mode,0,1));
      $command .= "\-$mode " if ( $mode ne '' );
      $command .= "-f" . "$format_file " if ( $format_file ne '' );
      $command .= "-e" . "$error_file " if ( $error_file ne '' );
      $command .= "-t'$field_terminator' " if ( $field_terminator ne '' );
      $command .= "-r'$row_terminator' " if ( $row_terminator ne '' );
      $command .= "-b'$batchsize' " if ( $batchsize ne '' );
      $command .= "-m'$max_errors' " if ( $max_errors ne '' );
      
      if ( $packetsize ne '' )
        {
         if ( $^O =~ /win/i )
           {
            $command .= "-A$packetsize ";
           }
        else
           {
            $command .= "-a$packetsize ";
           }
       }

      my $logtemp;

      if ( $^O =~ /win/i )
        {
        $logtemp = $ENV{TEMP} . "\\" . $$ . "bcp.log";
        }
      else
        {
        $logtemp = '/tmp/' . $$ . 'bcp.log';
        }

      $command =~ s%^%>$logtemp 2>&1 %; 
      
      print " BCP command to execute (except password): $command \n" if ($Batch::Batchrun::Output{$Batch::Batchrun::Counter});
     
      if ( $^O !~ /win/i )
       {
        $command .= "<<INPUT\n$password\nINPUT";
       }
     else
       {
        $command .= '-P' . $password . ' ';
       }  
      
      my $rc = exec_system($command);
      
      my $errors_found = 0;   
      my $line;
      
      open(BCPLOG,"<$logtemp") or warn "Could not open bcp logfile:$logtemp\n";
      foreach $line (<BCPLOG>)
        {
        $errors_found++ if ($line =~ m%^\s*Msg\s+\d+,\s+Level%io);
        $errors_found++ if ($line =~ m%^\s*DB-LIBRARY\s+error%io);
        print $line if ($Batch::Batchrun::Output{$Batch::Batchrun::Counter});
        }
      close(BCPLOG);
      unlink($logtemp);
      
      if ($show_errors !~ /no|false/i and -s $error_file)
        {
        $line = '';
        print "\n%%%%%%%%%%%  Error File Contents  %%%%%%%%%%%\n";
        open(BCPERROR,"<$error_file") or warn "Could not open bcp error file: $error_file\n";
        foreach $line (<BCPERROR>) { print $line; }
        print "\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
        close(BCPERROR);
        }
        
      #----------------------------------------------------------------------------
      # 1. Check to see if error msg in log file, if found, fail
      # 2. Check to see if the error file has any size to it. If it's size is greater
      #    than zero then there was an error.  If ignore_errors is not true, then fail 
      #    If it is true then exit with a warning.
      #----------------------------------------------------------------------------
      if ($errors_found)
        {
        $Batch::Batchrun::Msg = 'BCP Error found in log file!';
        return $Batch::Batchrun::ErrorCode;
        }
      elsif ( -s $error_file and ($ignore_errors !~ /yes|true/i))
        {
        $Batch::Batchrun::Msg = 'BCP Error found in log file or Error file';
        return $Batch::Batchrun::ErrorCode;
        }
      elsif ( -s $error_file and ($ignore_errors =~ /yes|true/i))
        {
        $Batch::Batchrun::Msg = 'BCP Error found in log file or Error file';
        return $Batch::Batchrun::WarningCode;
        }
      else
        {
        return $rc;
        }

   }  ###  end  command_bcp


#****************************************
sub command_sqr
#****************************************
  {
   if (not defined($ENV{SQRDIR}))
     {
     $Batch::Batchrun::Msg = 'SQRDIR environment variable missing! It must be defined.';
     return $Batch::Batchrun::ErrorCode;
     }
   #SQR [program] [username/password] [-flags...] [pars...] [@file...]
   #
   #where
   #      program = Report filename
   #     username = Database username
   #     password = Database password
   #           -A = Append to existing output file
   #          -Bn = Fetch n rows at a time
   #  -Burst:{xx} = Generate .LIS using specified burst mode (S,T or P)
   #          -Dn = Display report while processing, pause every n lines
   #     -DEBUGxx = Compile #DEBUG[x] lines
   #    -DNT:{xx} = Set the default numeric type (Decimal,Integer,Float)
   #     -E[file] = Direct errors to {program}.ERR or specified file
   # -F[dir/file] = Use [dir]{program}.LIS or specified file for output
   #   -Idir_list = Directory list to be searched for include files
   #          -ID = Display copyright banner
   #        -KEEP = Keep the .SPF file(s) after program run
   #-LL{s|d}{c|i} = Load-Lookup: S=SQR, D=DB, C=Case Sensitive, I=Insensitive
   #       -Mfile = Maximum sizes declared in file
   #       -NOLIS = Do not generate .LIS file(s) from .SPF file(s)
   #     -O[file] = Direct log messages to console or specified file
   #-PRINTER:{xx} = Force listing files to be for HT, LP, HP or PS printers
   #          -RS = Save run time file in {program}.sqt
   #          -RT = Use run time file (skip compile)
   #           -S = Display cursor status at end of run
   #          -Tn = Test report for n pages, ignore 'order by's
   #          -XB = Do not display the program banner
   #          -XI = Do not allow user interaction during program run
   #          -XL = Do not logon to database (no SQL in program)
   #         -XTB = Do not trim blanks from LP .LIS files
   #        -XNAV = Do not put navigation bar into .HTM file
   #        -XTOC = Do not generate Table Of Contents
   #   -ZIF[file] = Complete pathname of the initialization file to use
   #   -ZMF[file] = Complete pathname of the message file to use
   #         pars = Report parameters for ASK and INPUT commands
   #        @file = File containing report parameters, one per line

   #***************************************************
   #  Check for required fields
   #*****************************************************
   
   if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandParm} !~ /program/i    and
        $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandParm} !~ /user/i       and
        $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandParm} !~ /server/i  ) 
     {
      $Batch::Batchrun::Msg = 'Missing one or more required parameters for sqr';
      return $Batch::Batchrun::ErrorCode;
     }

   my %tmphash =  %{$Batch::Batchrun::Control{'CurrentCommandParm'}};

   # Required
   my $program          = $tmphash{PROGRAM};
   my $user             = $tmphash{USER};
   my $server           = $tmphash{SERVER};

   # optional
   my $password         = $tmphash{PASSWORD};
   my $log              = $tmphash{LOG};
   my $errors           = $tmphash{ERRORS};
   my $output           = $tmphash{OUTPUT};
   my $flags            = $tmphash{FLAGS};
   my $parameters       = $tmphash{PARAMETERS};
   my $parfile          = $tmphash{PARFILE};
   
   $log =~ s/^\s*//o;
   $errors =~ s/^\s*//o;
   $output =~ s/^\s*//o;
   $flags =~ s/^\s*//o;
   $parameters =~ s/^\s*//o;
   $parfile =~ s/^\s*//o;
   
   # Batchrun only options
   #my $ignore_errors    = $tmphash{IGNORE_ERRORS};
   my $show_errors      = $tmphash{SHOW_ERRORS};
  
   print "PROGRAM: $program\n";
   print "USER:    $user\n";
   print "SERVER:  $server\n";
   print "LOG:     $log\n";
   print "ERRORS:  $errors\n";
   print "OUTPUT:  $output\n";            
            
   #****************************************************
   #   Figure out which program to run
   #****************************************************
   my $sqr_program = $ENV{SQRDIR} . '/sqr';
   
   #***************************************************
   #  Get a password, if necessary
   #***************************************************
   $user =~ s/^\s*//o;
   $user =~ s/\s*^//o;
   $server =~ s/^\s*//o;
   $server =~ s/\s*$//o;
   if ( $password eq '' or $password =~ /lookup/i )
     {
      $password = dbpwdlookup ( $server, $user );
     }
   $password =~ s/^\s*//o;
   $password =~ s/\s*$//o;
   if ( $password eq ' ' )
     {
      $Batch::Batchrun::Msg = 'Unable to run SQR because no password supplied or looked up';
      return $Batch::Batchrun::ErrorCode;
     }

   #***************************************************
   #   Build the command
   #***************************************************
   $user =~ s/ops\$/ops\\\$/ if $user =~ /ops\$/;
 
   my $connect_string = "$user/$password\@$server";
   my $logtemp;
   
   if ( $log eq '' and $Batch::Batchrun::Output{$Batch::Batchrun::Counter})
     {
     $logtemp = 1;
     if ( $^O =~ /win/i )
       {
       $log = $ENV{TEMP} . "\\" . $$ . "sqr.log";
       }
     else
       {
       $log = '/tmp/' . $$ . 'sqr.log';
       }
     }
   if ( $errors eq '' )
     {
     if ( $^O =~ /win/i )
       {
       $log = $ENV{TEMP} . "\\" . $$ . "errors.dat";
       }
     else
       {
       $log = '/tmp/' . $$ . 'errors.dat';
       }     
     }
     
   my $command = "-O$log " if ( $log ne '' );
      $command .= "-E$errors " if ( $errors ne '' );
      $command .= "-F$output " if ( $output ne '' );
      $command .= " $flags " if ( $flags ne '' );
      $command .= " $parameters " if ( $parameters ne '' );
      $command .= " \@$parfile " if ( $parfile ne '' );

      
      #print " SQR command to execute (except password):",
      #       "$sqr_program $program $user\@$server $command \n" 
      #       if ($Batch::Batchrun::Output{$Batch::Batchrun::Counter});
      #------------------------------------------------------------------------
      # If the errors file already exists then remove it.  It must be remaining from
      # a previous run and will cause problems with checking errors this time
      #-------------------------------------------------------------------------
      if ( -e $errors)
        {
        unlink($errors);
        }  
        
      if ( $^O !~ /win/i )
       {
        print "Command: $sqr_program $program  $command\n";
        $command = "$sqr_program $program  $command <<EOINPUT\n$connect_string\nEOINPUT";          
        }
     else
       {
        print "Command: $sqr_program $program $command\n";
        $command = "$sqr_program $program $connect_string $command";
       }

      my $rc = exec_system($command);
      my $max_exceeded = 0;
      my $errors_found = 0;
 
      open(SQRLOG, "<$log") or warn "Could not open $log for input $!\n";
      foreach (<SQRLOG>)
        {
        #$max_exceeded = 1 if m/MAXIMUM ERROR COUNT EXCEEDED/io;
        #$errors_found = 1  if m/Error on table/io;
        #$errors_found = 1  if m/\sORA-/o;
        print $_ if ($Batch::Batchrun::Output{$Batch::Batchrun::Counter});
        }
      close(SQRLOG);
      
      if (($show_errors =~ /yes|true/io) and $Batch::Batchrun::Output{$Batch::Batchrun::Counter})
        {
        print "\n%%%%%%%%%%%  Error File Contents  %%%%%%%%%%%\n";
        open(BADFILE, "<$errors") or warn "Could not open $errors for input $!\n";
        foreach (<BADFILE>)
          {
          print $_;
          }
        close(BADFILE);
        print "\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
        }
      
      if ($logtemp)
        {
        unlink($log);
        }      
      
      if ($rc == $Batch::Batchrun::ErrorCode)
        {
        return $Batch::Batchrun::ErrorCode;
        }
      elsif ($errors_found)
        {
        $Batch::Batchrun::Msg = 'SQR Error found in log file!';
        return $Batch::Batchrun::ErrorCode;
        }
      else
        {
        return $Batch::Batchrun::NoErrors;
        }
  }

#****************************************
sub command_logon
#****************************************
  {

   my %LogonParams = ();
   
   #
   # This should happen when LOGON command used from task
   #   else... should happen if we call it from somewhere else
   #                LMM  7/20/99
   #

    if ( @_ )
      {  
        %LogonParams = @_; 
      }
    else
      { %LogonParams = %{$Batch::Batchrun::Control{'CurrentCommandParm'}}; }

    my($ServerHandle) = $LogonParams{'HANDLE'};

    #******************************************************************
    #  !!NOTE!!  The variables below need $Batch::Batchrun::Counter added!
    #                               LMM  5/8/99
    #  Done -- 6/15/1999  LMM
    #******************************************************************

    #******************************************************************
    #  If ServerHandle is BRDefault, take Global params for logon 
    #******************************************************************
    if ( $ServerHandle eq 'BRDefault' )
      {
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE}     = $Batch::Batchrun::Databasetype;
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SERVER}     = $Batch::Batchrun::Server;
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SECONDARY}  = $Batch::Batchrun::Secondary;
       # no default for this one
       #  $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{AUTOCOMMIT} = $Batch::Batchrun::Autocommit;
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{USER}       = $Batch::Batchrun::Username;
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{PASSWORD}   = $Batch::Batchrun::Password;
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DATABASE}   = $Batch::Batchrun::Database;
      }
    ##  Otherwise, get from passed array 
    else
      {
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE}     = $LogonParams{DBTYPE};
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SERVER}     = $LogonParams{SERVER};
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SECONDARY}  = $LogonParams{SECONDARY};
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{AUTOCOMMIT} = $LogonParams{AUTOCOMMIT};
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{USER}       = $LogonParams{USER};
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{PASSWORD}   = $LogonParams{PASSWORD};
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DATABASE}   = $LogonParams{DATABASE};
      }

    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{USER}     =~ s/^\s*//g;
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SERVER}   =~ s/^\s*//g;
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SECONDARY}   =~ s/^\s*//g;
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{AUTOCOMMIT}   =~ s/^\s*//g;
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{PASSWORD} =~ s/^\s*//g;
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE}   =~ s/^\s*//g;
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DATABASE} =~ s/^\s*//g;

    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{USER}     =~ s/\s*$//g;
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SERVER}   =~ s/\s*$//g;
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SECONDARY}   =~ s/\s*$//g;
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{AUTOCOMMIT}   =~ s/\s*$//g;
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{PASSWORD} =~ s/\s*$//g;
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE}   =~ s/\s*$//g;
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DATABASE} =~ s/\s*$//g;

    #******************************************************************
    ##  LOOKUP PASSWORD if necessary - dont err if none found.
    ##                            could be no pwd or logon will fail
    #******************************************************************
    if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{PASSWORD} eq ''           or
         $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{PASSWORD} =~ /lookup/i )
      {
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{PASSWORD} =
                   dbpwdlookup($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SERVER},
                               $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{USER});
       #debug
          #print "**server:$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SERVER}***\n";
          #print "**user:$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{USER}***\n";
          #print "**pwd:$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{PASSWORD}**\n";
      }

    #****************************************
    #  Do a little checking of values 
    #****************************************

    if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{AUTOCOMMIT} )
      {
        if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{AUTOCOMMIT} !~ /on|off/i )
          {
            $Batch::Batchrun::Msg .= "*** AUTOCOMMIT parameter accepts only ON or OFF as values ***\n";
            return $Batch::Batchrun::ErrorCode;
          }
      }
 

    #****************************************
    #  massage DBType
    #****************************************

    my $lcdbtype 
             = lc( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE} );
    
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE} 
            = $Batch::Batchrun::Control{'CONFIG'}{'ValidDbTypes'}{$lcdbtype};

    if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE} eq '' )
      {
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE} = 'Oracle';
      }

    if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE} =~ /sybase/i )
      {
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SERVER} 
            = 'server=' . $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SERVER};
      }

    my( $first_param ) = 'dbi:' . $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE} . ':' .
                                  $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SERVER};

    #************************************************************************
    #   CONNECT
    #************************************************************************
   
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBPROC}
       = DBI->connect ( $first_param,
                        $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{USER} ,
                        $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{PASSWORD} );
   
    
    if ( !defined($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBPROC} ) )
      {
       if ( ! $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SECONDARY} )
         {
           $Batch::Batchrun::Msg = "ERROR in Logon - Cannot connect to the following: \n" .
                        " SERVER: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SERVER} \n" .
                        " SECONDARY: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SECONDARY} \n" .
                        " USER: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{USER} \n" .
                        " DBTYPE: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE} \n" .
                        " DATABASE: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DATABASE} \n" .
                        " HANDLE: $ServerHandle \n because $DBI::errstr\n";
           $Batch::Batchrun::Msg .= "*** NO PASSWORD WAS FOUND ***\n" 
                       if ( ! $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{PASSWORD});
           return $Batch::Batchrun::ErrorCode;
         }
       else   #  Secondary defined 
         {
          #*******************
          #  Try the secondary
          #*******************

          $first_param  = 'dbi:' . $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE} . ':' .
                                   $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SECONDARY};
          $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{PASSWORD} =
                      dbpwdlookup($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SECONDARY},
                               $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{USER});
          $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBPROC}
                    = DBI->connect ( $first_param,
                                     $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{USER} ,
                                     $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{PASSWORD} );
          if ( !defined($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBPROC} ) )
            {
             $Batch::Batchrun::Msg = "ERROR in Logon - Cannot connect to the following: \n" .
                        " SECONDARY SERVER: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SECONDARY} \n" .
           $Batch::Batchrun::Msg .= "*** NO PASSWORD WAS FOUND ***\n" 
                       if ( ! $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{PASSWORD});
                        " USER: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{USER} \n" .
                        " PASSWORD: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{PASSWORD} \n" .
                        " HANDLE: $ServerHandle \n because $DBI::errstr\n";
             return $Batch::Batchrun::ErrorCode;
            }
          else
            {
             print "*****************************************************\n";
             print "*  WARNING:  Failing over to secondary server: " . 
                       "$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SECONDARY}\n";
             print "*****************************************************\n";
             my $msg = "Automated Failover to secondary server: " . 
                          "$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{SECONDARY}\n";
             $msg .= "\n TASK:$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASK'}\n";
             mail( ADDRESS=>$Batch::Batchrun::Control{CONFIG}{BRMail}, 
                   SUBJECT=>'Batchrun Notice', 
                   MESSAGE=>$msg, 
                   PRIORITY=>'Urgent', 
                   FROM=>'Daryl.Anderson@pnl.gov' 
                 );            }
         }
       }

       #************************************************
       #   Settings if connection is okay
       #************************************************
       my $dbh = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBPROC}; 
       $dbh->{LongTruncOk} = $Batch::Batchrun::Control{'CONFIG'}{LongTruncOk};
       $dbh->{LongReadLen} = $Batch::Batchrun::Control{'CONFIG'}{LongReadLen};
       $dbh->{PrintError}  = $Batch::Batchrun::False;

       #
       ##  Do we need to add RaiseError??
       #           LMM  6/15/99

       #****************************************************
       #  Setup AUTOCOMMIT
       #  Autocommit _DEFAULTS_ to _ON_, so don't change unless
       #  parameter is set to /off/i.
       #                               LMM  5/8/99
       #****************************************************
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBPROC}->{AutoCommit} = 0
                    if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{AUTOCOMMIT} =~ /off/i );

       my $tmpvar = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBPROC}->{AutoCommit};
  

    #*******************************************************************
    #  If ORACLE, then quit now
    #*******************************************************************
    if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE} =~ /oracle/i )
      {
       ###  Enable output ... for SQL_IMMEDIATE mostly **** LM 9/29/98
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBPROC}->func("dbms_output_enable");
       return $Batch::Batchrun::NoErrors;
      }
     
   #*************************************************************************
   #  Don't know what type of ODBC DSN we're dealing with so try some things
   #  This is a very UNELEGANT solution
   #*************************************************************************
   #  First, try to figure out if this is a Sybase or MS SQL Server DSN by
   #  doing a select db_name().  It if succeeds, then this must be a Sybase or
   #  Microsoft SQL Server and we should do the steps following.
   #*************************************************************************
   my ( $sth_odbc, $dbh_odbc, $rc_odbc, $ms_or_sybase_dsn );
   $ms_or_sybase_dsn = $Batch::Batchrun::False;
   if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE} =~ /odbc/i )
     {
      #   1.  prepare  ( select db_name() )
      #   2.  execute
      #   3.  if execute successful, then MS or Sybase
      
      $dbh_odbc = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBPROC};
      my $odbc_stmt = 'select db_name()';
      $sth_odbc = $dbh_odbc->prepare($odbc_stmt);
      if ( ! $sth_odbc )
        {
         return $Batch::Batchrun::NoErrors;
        }
      $rc_odbc = $sth_odbc->execute;
      if ( defined($rc_odbc) )
        {
         $ms_or_sybase_dsn = $Batch::Batchrun::True;
        }
      $sth_odbc->finish;
     }
          
    #*******************************************************
    #   Special Sybase checking 
    #******************************************************
    if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBTYPE} =~ /sybase/i or
         $ms_or_sybase_dsn                                           )
      {
       #***********************************************************
       #  If the login was successful, but the user didn't wind up
       #  in their default db, then they are not a valid user in 
       #  their default db, and so we KICK THEM OUT!
       #***********************************************************
       #  Define the statement
       #***********************************************************
       my $dbh; my $rc1;
       $dbh = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DBPROC};
       my $statement = qq( select  db_name(), a.dbname
                             from  master..syslogins a
                            where  name = '$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{USER}'
                         );

       #***********************************************************
       #  Select the row
       #***********************************************************
       my @dat = $dbh->selectrow_array($statement);

       if ( $DBI::err  )
         {
          $Batch::Batchrun::Msg = $DBI::err . $DBI::errstr;
          return $Batch::Batchrun::ErrorCode;
         }

       #***********************************************************
       #  If no row, ERROR 
       #***********************************************************
       if ( ! @dat )
         {
          $Batch::Batchrun::Msg = "User $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{USER} not found in syslogins?";
          return $Batch::Batchrun::ErrorCode;
         }

       #***********************************************************
       #  Compare DB that user is IN vs. Default DB
       #  If not the same, ERROR  
       #***********************************************************
       if ( uc($dat[0]) ne uc($dat[1]) )
         {
          $Batch::Batchrun::Msg = "Login failed.  User does not have access to their default DB";
          $dbh->disconnect;
          return $Batch::Batchrun::ErrorCode
         }
       #***********************************************************
       #  Not done yet :-)
       #  If database is passed, do a USE and make sure you are
       #  actually there.
       #***********************************************************

       if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DATABASE} eq '' )
         {
          return $Batch::Batchrun::NoErrors;
         }

       $statement = "use $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DATABASE}";

       #***********************************************************
       #  Do the statement
       #***********************************************************
       my $rc = $dbh->do($statement);
       if ( ! $rc )
         {
          $Batch::Batchrun::Msg = "$DBI::err $DBI::errstr";
          return $Batch::Batchrun::ErrorCode;
         }
 
       #***********************************************************
       #  Check which DB the User is actually in
       #***********************************************************
       $statement = qq( Select '$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$ServerHandle}{DATABASE}', db_name());

       #***********************************************************
       #  Fetch the row 
       #***********************************************************
       @dat = $dbh->selectrow_array($statement);
       if ( $DBI::errstr )
         {
          $Batch::Batchrun::Msg = "$DBI::err $DBI::errstr";
          return $Batch::Batchrun::ErrorCode;
         }

       #***********************************************************
       #  If no row, ERROR 
       #***********************************************************
       if ( ! @dat )
         {
          $Batch::Batchrun::Msg = "Something has gone wrong here!!  -- $DBI::errstr";
          return $Batch::Batchrun::ErrorCode;
         }

       #***********************************************************
       #  Compare DB that user is IN vs. Default DB
       #  If not the same, ERROR  
       #***********************************************************
       if ( uc($dat[0]) ne uc($dat[1]) )
         {
          $Batch::Batchrun::Msg = "Use of database failed.  User does not have access to this DB";
          $dbh->disconnect;
          return $Batch::Batchrun::ErrorCode
         }
      }
    
     return $Batch::Batchrun::NoErrors;
 
  }


sub command_logoff
  {

   my %tmphash;

    if ( @_ )
      { 
        %tmphash = @_;
      }
    else
      {
        %tmphash = %{$Batch::Batchrun::Control{'CurrentCommandParm'}};
      }

   my $handle = $tmphash{HANDLE};
   
   $Batch::Batchrun::Error = $Batch::Batchrun::NoErrors;

   $handle =~ s/^\s*//;
   $handle =~ s/\s*$//;

   if ( defined ($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{'STMT'}))
     {
      $Batch::Batchrun::Msg = "LOGOFF: Pending results are being ignored for connection '$handle'";
      $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{'STMT'}->finish;
      delete ($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{'STMT'});
     }

    #************************************************************
    #  Check for valid handle
    #************************************************************

   if (! ref($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}))
     {
      $Batch::Batchrun::Msg = "Handle - $handle - NOT DEFINED - so cannot LOGOFF";
      return $Batch::Batchrun::WarningCode;
     }

   my($rc) = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}->disconnect;
   delete ($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC});

   if (!$rc)
     {
      $Batch::Batchrun::Msg = "LOGOFF: Cannot logoff \n" .  "$DBI::errstr";
      return $Batch::Batchrun::ErrorCode;
     }

   return $Batch::Batchrun::NoErrors;
}

1;

__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Batch::Batchrun::Dbfunctions - Batchrun extension module.

=head1 SYNOPSIS

  No general usage.  Designed only as a submodule to Batchrun.

=head1 DESCRIPTION

Contains Batchrun subroutines.

=head1 AUTHOR

Daryl Anderson 

Louise Mitchell 

Email: batchrun@pnl.gov

=head1 SEE ALSO

batchrun(1).

=cut


