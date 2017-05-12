package Batch::Batchrun::TableFunctions;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA     = qw(Exporter);
@EXPORT  = qw(command_table
              command_tmm
              );
$VERSION = '0.01';

# Preloaded methods go here.

use Batch::Batchrun::Library;
use Batch::Batchrun::Pwlookup;

#******************************
sub command_tmm
#******************************
  {
   my ( $sql, $order_num, $sql_text, $handle, $server, $action, $table_name, $table_owner,
        $object_name, $object_owner, $object_type, $constraint_type,$grantee, $exp_date, $sql_text );

   #$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData}  =~ s/^\s*//og;
   #$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData}  =~ s/\s*$//og;

   my %tmphash =  %{ $Batch::Batchrun::Control{CurrentCommandData} };

   $server       = uc($tmphash{SERVER});
   $action       = uc($tmphash{ACTION});
   $table_owner  = uc($tmphash{TABLE_OWNER});
   $table_name   = uc($tmphash{TABLE_NAME});
   $object_owner = uc($tmphash{OBJECT_OWNER});
   $object_name  = uc($tmphash{OBJECT_NAME});
   $object_type  = uc($tmphash{OBJECT_TYPE});
   $constraint_type  = uc($tmphash{CONSTRAINT_TYPE});
   $grantee      = uc($tmphash{GRANTEE});
   $order_num    = uc($tmphash{ORDER_NUM});
   $exp_date     = $tmphash{EXP_DATE};
   $sql_text     = $tmphash{SQL_TEXT};

   #**********************************************************************
   #  Check for commas or the word ALL in any parameter - not allowed
   #**********************************************************************
   my $all_flag = 0;
   if ( (    $object_type   =~ /,/   ) or
        ( uc($object_type)  eq 'ALL' ) or
        (    $object_name   =~ /,/   ) or
        ( uc($object_name)  eq 'ALL' ) or
        (    $object_owner  =~ /,/   ) or
        ( uc($object_owner) eq 'ALL' ) or
        (    $table_name    =~ /,/   ) or
        ( uc($table_name)   eq 'ALL' ) or
        (    $constraint_type    =~ /,/   ) or
        ( uc($constraint_type)   eq 'ALL' ) or
        (    $grantee       =~ /,/   ) or
        ( uc($grantee)      eq 'ALL' ) or
        (    $table_owner   =~ /,/   ) or
        ( uc($table_owner)  eq 'ALL' )     )
     {
      $all_flag = 1;
     }

   if ( $all_flag and $action =~ /insert/i )
     {
      $Batch::Batchrun::Msg = "Cannot CREATE more than one TMM entry at a time with this facility.\n " .
                       "Please speak to the Batchrun administrator(s) if mass entries are needed.\n";
      return $Batch::Batchrun::ErrorCode;
     }
   #**********************************************************************
   #  Connect to the TMM repository
   #**********************************************************************
   my $tmmrc = connect_to_tmm(0);
   if ( $tmmrc )
     {
      return $tmmrc;
     }

   #*****************************************************
   #  set up some of the parameters
   #*****************************************************
   if ( $action =~ /insert/i )
     { if ( $exp_date eq '' )
        { $exp_date = 'NULL'; }
      else
        { $exp_date = "to_date('$exp_date','YYYY-MM-DD')"; }
     }
   else   # action = expire
     { if ( $exp_date eq '' )
         { $exp_date = 'sysdate'; }
       else
         { $exp_date = "to_date('$exp_date','YYYY-MM-DD')"; }
     }

   if ( $order_num eq '' )
     {
      $order_num = 'Null';
     }

   if ( $object_owner eq '' )
     {  $object_owner = $table_owner; }

   #********************************************************
   #  Check for required parameters
   #********************************************************
   #  Need to make the following statement more efficient
   #               LMM  7/12/99
   #********************************************************
     if ( $action =~ /insert/i )
       {
        if ( $server and $table_owner and $table_name and
             $sql_text and $object_type and $object_name )
          { # all is well
          }
        else
          {
           $Batch::Batchrun::Msg = "All of the required parameters of TMM were not supplied!\n";
           return $Batch::Batchrun::ErrorCode;
          }
      }
    else
      {
       if ( $server and $table_owner )
         { #all is well
         }
       else
         {
          $Batch::Batchrun::Msg = "All of the required parameters of TMM were not supplied! \n";
          return $Batch::Batchrun::ErrorCode;
         }
      }

   #******************************************************
   #  Build DML statement
   #******************************************************
   if ( $action =~ /insert/i )
     {

      $sql = qq {  Insert Into TABLE_MAINT_METADATA
                     (
                        SERVER,
                TABLE_OWNER,
                TABLE_NAME,
                OBJECT_OWNER,
                OBJECT_NAME ,
                OBJECT_TYPE,
                        CONSTRAINT_TYPE,
                GRANTEE,
                CREATE_ORDER_NUM,
                EXP_DATE,
                CREATE_USER,
                CREATE_DATE,
                SQL_TEXT
            )
        Values
            (
                        '$server',
                '$table_owner',
                '$table_name',
                '$object_owner',
                '$object_name',
                '$object_type',
                        '$constraint_type',
                 '$grantee',
                 $order_num,
                         $exp_date,
                         user,
                         sysdate,
                         '$sql_text'
                    )
                };

       # print "*** SQL for insert is: $sql \n";
     }
   else   # Expire
     {
       $sql =    "Update TABLE_MAINT_METADATA";
       $sql .= "\n   Set exp_date = $exp_date";
       $sql .= "\n where server      = '$server'";

       if ( $table_owner ne 'ALL' and $table_owner ne '' )
         {
          my $fmt_in_clause = &format_csv( uc($table_owner),'a','table_owner');
          $sql .= "     And  $fmt_in_clause \n";
         }

       $sql .= "\n   and exp_date is NULL";

       if ( $table_name ne 'ALL' and $table_name ne '' )
         {
          my $fmt_in_clause = &format_csv( uc($table_name),'a','table_name');
          $sql .= "     And  $fmt_in_clause \n";
         }

       if ( $object_type ne 'ALL' and $object_type ne '' )
         {
          my $fmt_in_clause = &format_csv( uc($object_type),'a','object_type');
          $sql .= "     And  $fmt_in_clause \n";
         }

       if ( $object_name ne 'ALL' and $object_name ne '' )
         {
          my $fmt_in_clause = &format_csv( uc($object_name),'a','object_name');
          $sql .= "     And  $fmt_in_clause \n";
         }

       if ( $constraint_type ne 'ALL' and $constraint_type ne '' )
         {
          my $fmt_in_clause = &format_csv( uc($constraint_type),'a','constraint_type');
          $sql .= "     And  $fmt_in_clause \n";
         }

       if ( $grantee ne 'ALL' and $grantee ne '' )
         {
          my $fmt_in_clause = &format_csv( uc($grantee),'a','grantee');
          $sql .= "     And  $fmt_in_clause \n";
         }

       # print "*** sql for expire is: $sql \n";
     }

   #**********************************************
   #   DO IT
   #**********************************************
   my $rows = $Batch::Batchrun::DBHTMM{DBPROC}->do($sql);

   if ( $DBI::errstr eq '' )
     {
      if ( $Batch::Batchrun::PrintSw{$Batch::Batchrun::Counter}  and $Batch::Batchrun::Output{$Batch::Batchrun::Counter} )
        {
         print "$rows rows affected.\n";
        }
      return $Batch::Batchrun::NoErrors;
     }
   else
     {
      $Batch::Batchrun::Msg = $DBI::errstr;
      return $Batch::Batchrun::ErrorCode;
     }

  } # end of command_tmm


#******************************
sub command_table
#******************************
  {
   my ( $handle, $server, $action, $object_type, $table_owner, $table_name, 
        $object_owner, $object_name, $constraint_type, $grantee);

   #$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData}  =~ s/^\s*//og;
   #$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData}  =~ s/\s*$//og;

   my %tmphash =  %{ $Batch::Batchrun::Control{CurrentCommandData} };
   $handle       = $tmphash{HANDLE};
   $server       = $tmphash{SERVER};
   $action       = uc($tmphash{ACTION});
   $table_owner  = uc($tmphash{TABLE_OWNER});
   $table_name   = uc($tmphash{TABLE_NAME});
   $object_owner = uc($tmphash{OBJECT_OWNER});
   $object_name  = uc($tmphash{OBJECT_NAME});
   $object_type  = uc($tmphash{OBJECT_TYPE});
   $constraint_type = uc($tmphash{CONSTRAINT_TYPE});
   $grantee      = uc($tmphash{GRANTEE});

   if ( $object_owner eq '' ) { $object_owner = $table_owner; }
   ## if ( $object_name  eq '' ) { $object_name = $table_name; }

   #*********************************************************************
   #  Check for required fields
   #*********************************************************************
   if ( $action =~ /create/i )
     {
      if ( $handle and $server and $table_owner and $object_type )
        {  #all is well
        }
      else
        {
         $Batch::Batchrun::Msg = "All required parameters for command TABLE, action CREATE have not been passed \n";
         return $Batch::Batchrun::ErrorCode;
        }
     }
   else
     {
      if ( $handle and $table_owner and $table_name and $object_type )
        { #all is well
        }
      else
        {
         $Batch::Batchrun::Msg = "All required parameters for command TABLE, action DROP have not been passed \n";
         return $Batch::Batchrun::ErrorCode;
        }
     }

   #**********************************************************************
   #  Connect to the TMM repository if action = 'create'
   #**********************************************************************
   if ( $action =~ /create/i )
     {
      my $tmmrc = connect_to_tmm(1);
      if ( $tmmrc )
        {
         return $tmmrc;
        }
     }

   #**********************************************************************
   #  Main logic
   #**********************************************************************

   my $table_rc;
   my $dbtype = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBTYPE};

   if ( $action =~ /create/i )
     {
      $table_rc = create_dbms_object($handle,$server,$object_type,$table_owner, $table_name, $object_owner, $object_name,$grantee);
     }
   else
     {
      $table_rc = drop_dbms_object($dbtype,$handle,$object_type,$table_owner,$table_name,$object_owner,$object_name,$grantee);
     }
   return $table_rc;
  }

#********************************
sub create_dbms_object
#********************************
  {
   my ($handle,$server,$object_type,$table_owner,$table_name,$object_owner,$object_name,$constraint_type,$grantee) = @_;
   if ( $object_owner eq '' ) { $object_owner = $table_owner; }

   $server = uc($server);

   my($tmmdbtype) = ($Batch::Batchrun::Control{CONFIG}{TMMDbtype} || 'Oracle');

   my $sql = qq{
          Select  a.sql_text, a.object_name, a.grantee, a.table_name
            From  table_maint_metadata a
           Where  a.server      = '$server'
             And  a.table_owner = '$table_owner'
             And  a.object_type = '$object_type'
        };

   if ( $tmmdbtype eq 'Oracle' )
     {
      $sql .= "     And  trunc(nvl(a.exp_date,sysdate+1)) > trunc(sysdate) \n";
     }
   else
     {
      $sql .= "     And  datediff(day, sysdate, isnull(a.exp_date,sysdate+1)) > 0 \n";
     }

   if ( $table_name ne 'ALL' and $table_name ne '' )
     {
      my $fmt_in_clause = &format_csv( uc($table_name),'a','a.table_name');
      $sql .= "     And  $fmt_in_clause \n";
     }

   if ( $object_name ne 'ALL' and $object_name ne '' )
     {
      my $fmt_in_clause = &format_csv( uc($object_name),'a','a.object_name');
      $sql .= "     And  $fmt_in_clause \n";
     }

   if ( $constraint_type ne 'ALL' and $constraint_type ne '' )
     {
      my $fmt_in_clause = &format_csv( uc($constraint_type),'a','a.constraint_type');
      $sql .= "     And  $fmt_in_clause \n";
     }

   if ( $grantee ne 'ALL' and $grantee ne '' )
     {
      my $fmt_in_clause = &format_csv( uc($grantee),'a','a.grantee');
      $sql .= "     And  $fmt_in_clause \n";
     }

   $object_owner = uc($object_owner);

   $sql .= "    And  a.object_owner = '$object_owner'\n";
   $sql .= '  Order  by a.create_order_num';

   # print "**** SQL stmt to get things to be created from TMM is: $sql \n";
  #************************************************
  #  prepare, execute, and loop through results
  #  keep going, even if errors are encountered
  #  just report them.
  #************************************************
   #******************************************
   #   Prepare the statement
   #******************************************
   my $sth = $Batch::Batchrun::DBHTMM{DBPROC}->prepare($sql);

   if ( !defined($sth) )
     {
      $Batch::Batchrun::Msg = "ERROR: Not able to prepare statement: $sql for handle: DBHTMM because $DBI::errstr\n";
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
   #   Loop through the rows
   #******************************************

    my $cum_rc = $Batch::Batchrun::NoErrors;
    my $tmm_object_name;
    my $tmm_grantee;
    my $tmm_table_name;
    my @dat = ();
    my $numrows = 0;
    while ((@dat = $sth->fetchrow_array))
      {
       $numrows++;
       $Batch::Batchrun::CurrentSql = GetLargeData($sth,$handle,0);
       $tmm_object_name = $dat[1];
       $tmm_grantee = $dat[2];
       $tmm_table_name = $dat[3];

       if ( $Batch::Batchrun::PrintSw{$Batch::Batchrun::Counter}  and $Batch::Batchrun::Output{$Batch::Batchrun::Counter} )
         {
          print "Creating $object_type: $tmm_object_name $tmm_grantee for table: $table_owner.$tmm_table_name\n";
         }
          my  $create_rc = do_sql($handle, $table_owner, $table_name);

       if ( $create_rc == $Batch::Batchrun::ErrorCode )
         { $cum_rc = $Batch::Batchrun::ErrorCode;  }

       if ( $create_rc == $Batch::Batchrun::WarningCode and $cum_rc != $Batch::Batchrun::ErrorCode )
         { $cum_rc = $Batch::Batchrun::WarningCode; }

      }  #  End of While Loop

    $sth->finish;
    if ( $numrows == 0 )
      {
        $Batch::Batchrun::Msg = "NO OBJECTS TO CREATE THAT MEET THE QUALIFICATIONS\n   NO ACTION TAKEN \n";
        return $Batch::Batchrun::WarningCode;
      }

       return $cum_rc;
  }

#********************************
sub drop_dbms_object
#********************************
  {
   my ($dbtype,$handle,$object_type,$table_owner,$table_name,$object_owner,$object_name,$grantee) = @_;

   #*****************************************************************************
   #  build array of drop statements that meet the criteria of the TABLE command
   #*****************************************************************************
   my $status = build_drop_array($dbtype,$handle,$object_type,$table_owner,$table_name,$object_owner,$object_name,$grantee);

   if ( $status == $Batch::Batchrun::ErrorCode )
     {
      return $Batch::Batchrun::ErrorCode;
     }

   if ( !@Batch::Batchrun::DropArray )
     {
      $Batch::Batchrun::Msg = "NO OBJECTS TO DROP THAT MEET THE QUALIFICATIONS\n   NO ACTION TAKEN \n";
      return $Batch::Batchrun::WarningCode;
     }

   #************************************************
   #  loop through array and execute drop statements
   #************************************************
   my $cum_rc = $Batch::Batchrun::NoErrors;
   foreach $Batch::Batchrun::CurrentSql ( @Batch::Batchrun::DropArray )
     {
      print "Executing: $Batch::Batchrun::CurrentSql\n";
      my $drop_rc = do_sql($handle, $table_owner, $table_name);
      if ( $drop_rc == $Batch::Batchrun::ErrorCode )
        { $cum_rc = $Batch::Batchrun::ErrorCode; }
      if ( $drop_rc == $Batch::Batchrun::WarningCode and $cum_rc != $Batch::Batchrun::ErrorCode )
        { $cum_rc = $Batch::Batchrun::WarningCode; }
     }
  
   return $cum_rc;
  }

#********************************
sub build_drop_array
#********************************
  {
   my ($dbtype,$handle,$object_type,$table_owner,$table_name,$object_owner,$object_name,$grantee) = @_;
   my $sql_query;

   #*****************************************************************************
   #  Create the appropriate query to query the Data Dictionary
   #*****************************************************************************
   if (( $dbtype =~ /oracle/i ) and ( $object_type eq 'CONSTRAINT' ))
     {
      $sql_query = build_oracle_constraint_query($table_owner,$table_name,$object_name);
     }
   elsif (( $dbtype =~ /oracle/i ) and ( $object_type eq 'INDEX' ))
     {
      $sql_query = build_oracle_index_query($table_owner,$table_name,$object_owner,$object_name);
     }
   elsif (( $dbtype =~ /oracle/i ) and ( $object_type eq 'PERMISSION' ))
     {
      $sql_query = build_oracle_permission_query($table_owner,$table_name,$object_name,$grantee);
     }
   elsif (( $dbtype =~ /sybase/i ) and ( $object_type eq 'CONSTRAINT' ))
     {
      $sql_query = build_sybase_constraint_query($table_owner,$table_name,$object_name);
     }
   elsif (( $dbtype =~ /sybase/i ) and ( $object_type eq 'INDEX' ))
     {
      $sql_query = build_sybase_index_query($table_owner,$table_name,$object_name);
     }
   elsif (( $dbtype =~ /sybase/i ) and ( $object_type eq 'PERMISSION' ))
     {
      $sql_query = build_sybase_permission_query($table_owner,$table_name,$object_owner,$object_name,$grantee);
     }
   else
     {
      $Batch::Batchrun::Msg = "ERROR: Not able to build Data Dictionary query for $dbtype $object_type.\n";
      return $Batch::Batchrun::ErrorCode;
     }

   #******************************************
   #   Prepare the Data Dictionary query
   #******************************************
   my $sth = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}->prepare($sql_query);
   if ( !defined($sth) )
     {
      $Batch::Batchrun::Msg = "ERROR: Not able to prepare statement: $sql_query for handle: $handle because $DBI::errstr\n";
      return $Batch::Batchrun::ErrorCode;
     }

   #******************************************
   #   Execute the Data Dictionary query
   #******************************************
   my $rc = $sth->execute;
   if ( !defined($rc) )
     {
      $Batch::Batchrun::Msg = "ERROR: Not able to execute statement $sql_query because: $DBI::errstr \n";
      return $Batch::Batchrun::ErrorCode;
     }

   #***************************************************
   #   Build the drop statements by looping through the
   #   query results; push them onto the drop array
   #***************************************************
   @Batch::Batchrun::DropArray =();
   my @dat = ();
   while ((@dat = $sth->fetchrow_array))
     {
      my $sql_drop_stmt;
      if (( $object_type eq 'CONSTRAINT' ) and ( $dbtype eq 'Oracle' ))
        {
         $sql_drop_stmt = "alter table $table_owner.$table_name drop constraint $dat[0]";
        }
      elsif ( $object_type eq 'CONSTRAINT' )
        {
         $sql_drop_stmt = "alter table $table_name drop constraint $dat[0]";
        }
      elsif (( $object_type eq 'INDEX' ) and ( $dbtype eq 'Oracle' ))
        {
         $sql_drop_stmt = "drop index $dat[0]";
        }
      elsif ( $object_type eq 'INDEX' )
        {
         $sql_drop_stmt = "drop index $table_name.$dat[0]";
        }
      elsif ( $object_type eq 'PERMISSION' )
        {
         $sql_drop_stmt = "revoke $dat[1] on $table_owner.$table_name from $dat[0]";
        }
      push ( @Batch::Batchrun::DropArray, $sql_drop_stmt);
     }

   $sth->finish;
   return 1;
  }

sub do_sql
  {
   my $handle  = shift;
   my $table_owner = shift;
   my $table_name = shift;
   my ( $sql ) = $Batch::Batchrun::CurrentSql;

   #******************************************
   #   DO the sql statement, ie, prepare, execute, and finish
   #  NOTE:  Originally, I had a sth->do, however
   #         Sybase didn't like executing a do on the same handle that had a stmt pending
   #******************************************

   if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBTYPE} =~ /oracle|odbc/i )
     {
      #*************************************************
      #  DO  for ORACLE or ODBC
      #*************************************************
      my $rows = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$handle}{DBPROC}->do($sql);

      if ( $DBI::err )
        {
         print "ERROR encountered executing: $sql \n $DBI::err $DBI::errstr \n\n";
         return $Batch::Batchrun::ErrorCode;
        }
      else
        { return $Batch::Batchrun::NoErrors; }
     }
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
                  $Batch::Batchrun::Msg = "ERROR: Not able to execute statement $sql because: $DBI::errstr
\n";
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

#********************************
sub build_oracle_constraint_query
#********************************
  {
   my ($table_owner,$table_name,$object_name) = @_;

   my $sql_query = qq{
          Select  a.constraint_name
            From  dba_constraints a,
                  dba_indexes b
           Where  a.owner = '$table_owner'
             And  a.table_name = '$table_name'
             And  a.owner = b.table_owner
             And  a.constraint_name = b.index_name
         };

   if ( $object_name ne 'ALL' and $object_name ne '' )
     {
      my $fmt_in_clause = &format_csv($object_name,'a','a.constraint_name');
      $sql_query .= "    And  $fmt_in_clause  \n";
     }

   $sql_query .= "  Union
          Select  a.constraint_name
            From  dba_constraints a
           Where  a.owner = '$table_owner'
             And  a.table_name = '$table_name'
             And  a.constraint_type = 'R' \n";

   return $sql_query;
  }

#********************************
sub build_oracle_index_query
#********************************
  {
   my ($table_owner,$table_name,$object_owner,$object_name) = @_;

   my $sql_query = qq{
          Select  a.index_name
            From  dba_indexes a
           Where  a.table_owner = '$table_owner'
             And  a.table_name = '$table_name'
             And  a.owner = '$object_owner'
         };

   if ( $object_name ne 'ALL' and $object_name ne '' )
     {
      my $fmt_in_clause = &format_csv($object_name,'a','a.index_name');
      $sql_query .= "    And  $fmt_in_clause  \n";
     }

   $sql_query .= "    And  Not Exists
                      ( Select  1
                          From  dba_constraints b
                         Where  b.owner = '$table_owner'
                           And  b.constraint_name = a.index_name
                      ) \n";

   return $sql_query;
  }

#********************************
sub build_oracle_permission_query
#********************************
  {
   my ($table_owner,$table_name,$object_name,$grantee) = @_;

   my $sql_query = qq{
          Select  a.grantee, a.privilege
            From  dba_tab_privs a
           Where  a.owner = '$table_owner'
             And  a.table_name = '$table_name'
         };

   if ( $object_name ne 'ALL' and $object_name ne '')
     {
      my $fmt_in_clause = &format_csv($object_name,'a','a.privilege');
      $sql_query .= "    And  $fmt_in_clause  \n";
     }
   else
     {
      $sql_query .= "    And  a.privilege in ( 'UPDATE','SELECT','INSERT','DELETE' ) \n";
     }

   if ( $grantee ne 'ALL' and $grantee ne '')
     {
      my $fmt_in_clause = &format_csv($grantee,'a','a.grantee');
      $sql_query .= "    And  $fmt_in_clause  \n";
     }

   return $sql_query;
  }

#********************************
sub build_sybase_constraint_query
#********************************
  {
   my ($table_owner,$table_name,$object_name) = @_;
   my $fmt_in_clause;

   #**************************************
   # get referential and check constraints
   #**************************************
   my $sql_query = qq{
          Select  o1.name
            From  sysconstraints c,
                  sysobjects o1,
                  sysobjects o2,
                  sysusers u
           Where  c.constrid = o1.id
             And  c.tableid = o2.id
             And  o2.name = '$table_name'
             And  o2.uid = u.uid
             And  u.name = '$table_owner'
         };

   if ( $object_name ne 'ALL' and $object_name ne '' )
     {
      $fmt_in_clause = &format_csv($object_name,'a', 'o1.name');
      $sql_query .= "    And  $fmt_in_clause \n";
     }

   #**********************************************
   # get key constraints (indexes w/status2 = 1,2
   # and indid != 0)
   #**********************************************
   $sql_query .= "  Union
          Select  i.name
            From  sysindexes i,
                  sysobjects o,
                  sysusers u
           Where  o.name = '$table_name'
             And  i.id = o.id
             And  i.indid != 0
             And  i.status2 != 0
             And  u.name = '$table_owner'
             And  o.uid = u.uid \n";

   if ( $object_name ne 'ALL' and $object_name ne '' )
     {
      $sql_query .= "             And  i.name $fmt_in_clause \n";
     }

   return $sql_query;
  }

#********************************
sub build_sybase_index_query
#********************************
  {
   my ($table_owner,$table_name,$object_name) = @_;

   #*****************************************************
   # get indexes; exclude key constraints (status2 = 1,2)
   # and "dummy" row for the table itself (indid = 0)
   #*****************************************************
   my $sql_query = qq{
          Select  i.name
            From  sysindexes i,
                  sysobjects o,
                  sysusers u
           Where  o.name = '$table_name'
             And  i.id = o.id
             And  i.indid != 0
             And  i.indid != 255
             And  i.status2 = 0
             And  u.name = '$table_owner'
             And  o.uid = u.uid
         };

   if ( $object_name ne 'ALL' and $object_name ne '' )
     {
      my $fmt_in_clause = &format_csv($object_name,'a','i.name');
      $sql_query .= "    And  $fmt_in_clause \n";
     }

   return $sql_query;
  }

#********************************
sub build_sybase_permission_query
#********************************
  {
   my ($table_owner,$table_name,$object_owner,$object_name,$grantee) = @_;

   my $sql_query = qq{
          Select  u3.name grantee,
                  v.name permission
            From  sysprotects p,
                  sysobjects o,
                  sysusers u1,
                  sysusers u2,
                  sysusers u3,
                  master..spt_values v
           Where  u1.name = '$object_owner'
             And  u2.name = '$table_owner'
             And  o.name = '$table_name'
             And  o.uid = u2.uid
             And  p.id = o.id
             And  p.grantor = u1.uid
             And  p.uid = u3.uid
             And  p.action = v.number
             And  v.type = 'T'
         };

   if ( $grantee ne 'ALL' and $grantee ne '' )
     {
      my $fmt_in_clause = &format_csv($grantee,'a','upper(u3.name)');
      $sql_query .= "    And  $fmt_in_clause \n";
     }

   if ( $object_name ne 'ALL' and $object_name ne '' )
     {
      my $fmt_in_clause = &format_csv($object_name,'a','upper(v.name)');
      $sql_query .= "    And  $fmt_in_clause \n";
     }
   else
     {
      $sql_query .= "    And  upper(v.name) in ( 'UPDATE','SELECT','INSERT','DELETE' ) \n";
     }

   return $sql_query;
  }

1;

__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Batch::Batchrun::TableFunctions - Batchrun extension module.

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



