package Batch::Batchrun::Load;
#######################################################################
#
# Batch::Batchrun::Load.pm 
#
# Used in conjunction with batchrun.pl to provide a way to
# enter a task and steps from a structured file.  
#
#   1.  !TASK: Followed by the name of a task
#   2.  ! Followed by the name of a command
#
# 
# Parameters: 
#
# Revision History
#
# Date  Revision  Author and Reason
#
#  3/97 $Revision: 0.01 Daryl: Rewritten for Batchrun
#######################################################################

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use DBI;
use Batch::Batchrun::Library  qw (load_task_data load_step_array 
                           parms_to_hash get_seq_no 
                           print_execution_map);
use Batch::Batchrun::Dbfunctions  qw (command_logon);

require Exporter;

@ISA     = qw(Exporter);
@EXPORT  = qw(load validate);
$VERSION = '1.03';


# Preloaded methods go here.
#------------------------------------------------------
# Initialize stuff
#------------------------------------------------------

my $dbh;                                            # Database handle
my $linenumber;                                     # Task line number
my $i;                                              # Index subscript
my $fline;                                          # File line data
my $short_desc;                                     # Short Description
my $long_desc;                                      # Long Description
my $step_id;                                        # Step id
my $stepnum;                                        # Step num
my $task_id;                                        # Task id
my $cdb;                                            # Command Data block
my @stepline;                                       # Step line data
my $chk_data;                                       # Check for data
my $chk_parms;                                      # Check for parms
my $taskname;                                       # Task Name
my $taskapp;                                        # Task Application
my $taskshort;                                      # Task Short Description
my $cmdparms;                                       # Command parms
my $cmdname;                                        # Command name
my $cmddata;                                        # Command data
my $cmdtext;                                        # Command text
my $command_insert;                                 # Sql Command for command insert
my $insert_task;                                    # Sql Command for task insert
my $domain           = '';
my $loadfile;


      
#===========================================================
# 
#  S U B R O U T I N E S
#
#===========================================================
#------------------------------------------------------
#  load - load a task from a file
#------------------------------------------------------ 
sub load
  { 
  #------------------------------------------------------
  # Open file containing task(s)
  #------------------------------------------------------
    
  if ($Batch::Batchrun::Counter > 1)
    {
    $loadfile  = $Batch::Batchrun::Control{CONFIG}{TasksDirectory};
    $loadfile .= '/'.lc($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'APP'});
    $loadfile .= '/'.lc($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASK'}).'.task';
    }
  else
    {
    $loadfile = $Batch::Batchrun::Filename;
    }
    
  $linenumber = 0;
  $Batch::Batchrun::Step = 1;
  
  if (not -f $loadfile)
    {
     $Batch::Batchrun::Msg = "$loadfile does not exist!\n";
     return $Batch::Batchrun::ErrorCode;
    }    

  if (! open (TASKFILE, "<$loadfile"))
    {
     $Batch::Batchrun::Msg = "Cannot open file $loadfile for read $!\n";
     return $Batch::Batchrun::ErrorCode;
    }
  else
    {
     #------------------------------------------------------
     # Print Header
     #------------------------------------------------------
     my $ldate = localtime();
     if ($Batch::Batchrun::Output{$Batch::Batchrun::Counter})
       {
       print $Batch::Batchrun::EventSeparator ;
       print "Batch::Batchrun::Load($VERSION) Task File: $loadfile\n";
       print "Start Time: $ldate\n";
       }
     if ( $Batch::Batchrun::Load and $Batch::Batchrun::Output{$Batch::Batchrun::Counter})
       {
       print "Loading into $Batch::Batchrun::Databasetype",':',$Batch::Batchrun::Server;
       print ' Database: ',$Batch::Batchrun::Database if ($Batch::Batchrun::Databasetype !~ /oracle/i);
       }
     elsif ( $Batch::Batchrun::Run and $Batch::Batchrun::Output{$Batch::Batchrun::Counter})
       {
       print "Loading $loadfile into memory for execution.";
       }
     print "\n" if ($Batch::Batchrun::Output{$Batch::Batchrun::Counter});

     #------------------------------------------------------
     # Load file into memory and validate syntax
     #------------------------------------------------------
     
     &get_commands;
     &validate;

     #------------------------------------------------------
     # Setup NumSteps
     #------------------------------------------------------
     my $arraysize = $Batch::Batchrun::CommandName[$Batch::Batchrun::Counter];
     $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'NumSteps'} = $#$arraysize;
     
     if ($Batch::Batchrun::CheckOnly)
       {
       print_execution_map();
       print "===SYNTAX CHECK COMPLETE===\n";
       exit;
       }  
      
     my $loadrc;
     if ( $Batch::Batchrun::Load )
       {
        $loadrc = &load_commands();
       }

     if ( $loadrc != $Batch::Batchrun::NoErrors )
       {
        return $Batch::Batchrun::ErrorCode;
       }

     print $Batch::Batchrun::EventSeparator if ($Batch::Batchrun::Output{$Batch::Batchrun::Counter});
     close (TASKFILE);
    }

  return $Batch::Batchrun::NoErrors;
  } # End of Load



#------------------------------------------------------
#  Get each command, then process it
#------------------------------------------------------ 
sub get_commands
  { 
  my $first = 1;
  my $line  = '';

  foreach $line  (<TASKFILE>)
    {
    $linenumber++;
    next if ($line =~ /^\s*!-/);   # strip Batchrun comments
    next if ($line =~ /^\s*!\s*$/);   # strip Batchrun empty commands
    if ($first and $line =~ /^\s*TASK/)
      {
      $cmdtext .= $line;
      $first = 0;
      next;
      }
    if ($line !~ /^\s*!/)
      {
      $cmdtext .= $line;
      }
    elsif ($line =~ /^\s*!/)
      {
      if ($first)
        {
        $cmdtext .= $line;  
        $first = 0;
        }
      else
        {
        process_command();
        $cmdtext = $line;
        }
      }
    else
      {
      die "Something's wrong, you shouldn't be in this part of the load !\n";
      }

    } #End foreach 
    process_command();  #Process the last command;
  } #End of get_commands subroutine
  
#------------------------------------------------------
#  Process the command
#------------------------------------------------------  
sub process_command
  {
  study $cmdtext;
  $cmdtext =~ s/^\s*!\s*//;  # Get rid of command indicator

  #----------------------------------------------------
  # Look for command match and return the actual 
  # command from $Batch::Batchrun::Commands
  # 12/15/98 Daryl added uc() to cmdname to fix bug
  #          where mixed case if hung forever when executing
  #----------------------------------------------------
  $cmdname = chk_cmd( substr($cmdtext,0,$Batch::Batchrun::Control{'CONFIG'}{'MaxCommandSize'})) 
             or die "Cannot continue load because of syntax error!\n"; 
  $cmdname = uc(substr ($cmdtext, 0, length($cmdname))); 
  $cmdtext     = substr ($cmdtext, length($cmdname)); # strip out command name 

  #----------------------------------------------------
  # Process parms,data,Descriptions,TASKS
  #----------------------------------------------------  
  if ($Batch::Batchrun::Commands{uc($cmdname)}{Parms} and $Batch::Batchrun::Commands{uc($cmdname)}{Data})
    {
    $cmdparms = get_parms();
    $cmddata = $cmdtext;
    }
  elsif ($Batch::Batchrun::Commands{uc($cmdname)}{Parms})
    {
    $cmdparms = $cmdtext;
    $cmdparms =~ s/\s*\\*\n\s*/ /g;
    $cmdparms = uc($cmdparms) if ($cmdname =~/label/i);
    }
  elsif ($Batch::Batchrun::Commands{uc($cmdname)}{Data})
    {
    $cmddata = $cmdtext;
    }
    
  if ($cmdname =~ /^%/ or $cmdname =~ /^SHORT DESC/)
    {
    $short_desc = $cmdparms;
    $cmdparms = '';
    }
  elsif ($cmdname =~ /^TASK/i)
    {
    $cmdparms =~ s/^\s*([^,]+),*\s*//;
    $taskname = uc($1);
    $taskname =~ s/\s*$//;
    if ($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{TASK} and $Batch::Batchrun::Counter == 1)
      {
      print "*** PC $Batch::Batchrun::Counter\n";
      print "*** TASK is already defined! Only 1 TASK per file allowed. ***\n\n";
      exit 1;
      }
    $Batch::Batchrun::Task = $taskname;
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{TASK} = $taskname;
    $taskshort = $short_desc;
    if ( $cmdparms =~ s/^([^,]+),?\s*// )
      {
       $taskapp = uc($1);
      }
    else 
      {
      $taskapp = $Batch::Batchrun::Application;
      }
    $taskapp =~ s/\s*$//;
    my $rc = load_task_data (
                              TASKDESC =>$cmddata,
                              TASKPARMS=>$cmdparms,
                              TASKAPP  =>$taskapp
                            );   
    $short_desc = '';
    $cmddata = '';
    $cmdparms = '';
    $cmdname = '';  
    }
  else
    {    
    my $rc1 = load_step_array (
                               STEPNUMBER => $Batch::Batchrun::Step,
                               DESC       => $short_desc,
                               NAME       => $cmdname,
                               PARM       => $cmdparms,
                               DATA       => $cmddata
                              );
    $Batch::Batchrun::Step++;
    $short_desc = '';
    $cmddata = '';
    $cmdparms = '';
    $cmdname = '';
    }

  } #End of process_command subroutine
  
#------------------------------------------------------
#  Load Commands into database repository
#------------------------------------------------------   
sub load_commands
  {
  #------------------------------------------------------
  # Log onto the Batchrun database repository
  #------------------------------------------------------
  my $logonrc =   command_logon(
                         HANDLE  =>$Batch::Batchrun::DBHInternal , 
                         SERVER  =>$Batch::Batchrun::Server, 
                         DBTYPE  =>$Batch::Batchrun::Databasetype, 
                         USER    =>$Batch::Batchrun::User, 
                         PASSWORD=>$Batch::Batchrun::Password,
                         DATABASE=>$Batch::Batchrun::Database
                       );

  if ( $logonrc != 0 )
    {
     return $Batch::Batchrun::ErrorCode;
    }

  $dbh = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$Batch::Batchrun::DBHInternal}{DBPROC};
 
  my $taskname = '';
  my $arraysize  = $Batch::Batchrun::CommandName[$Batch::Batchrun::Counter];
  
  &insert_task;
        
  $i = 0;
  while ($i < $#$arraysize)
    {
    $i++;
    &insert_step($i);
    }
  $dbh->disconnect;
  
  return $Batch::Batchrun::NoErrors;
  }
  
#------------------------------------------------------
#  Get Parameters
#------------------------------------------------------  
sub get_parms
  {
  my $parms = '';
  my $tmp   = '';
  $cmdtext  =~ s/\s*//;
  
  ($parms,$cmdtext) = split('\n',$cmdtext,2);
  while ( $parms =~ m/[\,]\s*$/ )
    {
    $parms =~ s/\\$//;
    ($tmp,$cmdtext) = split('\n',$cmdtext,2);
    $tmp =~ s/^\s*//;    $tmp =~ s/\s*$//;
    $parms .= $tmp;
    }
  return $parms;
  } 

#------------------------------------------------------
#  Check Command
#------------------------------------------------------ 
sub chk_cmd
  {
  my($cmdtext) = @_;
  my $cmd;
  foreach $cmd ( reverse sort keys(%Batch::Batchrun::Commands) )
    {
    return $cmd if ( $cmdtext =~ /^$cmd/i );
    }
  
  print "Unrecognized command as line $linenumber\n";
  print "Command not processed: $cmdtext\n";
  return 0;
  }

#------------------------------------------------------
#  Insert Step
#------------------------------------------------------
sub insert_step 
  {
  my ($i) = @_;
  
  #----------------------------------------------------
  # Check to insure that the task_id is not 0
  #----------------------------------------------------
  die "Task: must be defined before any step!\n" if ($task_id <= 0);
  
  $step_id++;

  print "$step_id: $Batch::Batchrun::CommandName[$Batch::Batchrun::Counter][$i]\n";   # continuation of the step title

  #----------------------------------------------------
  #Insert the step
  #----------------------------------------------------

  #check for maximum lengths
  
  $Batch::Batchrun::CommandName[$Batch::Batchrun::Counter][$i] = 
      &check_length($Batch::Batchrun::CommandName[$Batch::Batchrun::Counter][$i], 'Command Name', 60);
      
  $Batch::Batchrun::CommandParm[$Batch::Batchrun::Counter][$i]= 
      &check_length($Batch::Batchrun::CommandParm[$Batch::Batchrun::Counter][$i], 'Command Parameters', 2000);
      
  $Batch::Batchrun::CommandDesc[$Batch::Batchrun::Counter][$i] = 
      &check_length($Batch::Batchrun::CommandDesc[$Batch::Batchrun::Counter][$i], 'Short Description', 300);

  $dbh->{PrintError} = 1;
  
  $command_insert = qq{
          INSERT Into ${domain}STEP 
                 (  TASK_ID, STEP_ID, COMMAND_NAME, 
                    COMMAND_PARAMETERS, COMMAND_DATA, SHORT_DESCRIPTION ) 
          Values  ( ?, ?, ?, ?, ?, ? )
          };
  #$command_insert .= $dbh->quote($Batch::Batchrun::CommandName[$Batch::Batchrun::Counter][$i]) . ',';
  #$command_insert .= $dbh->quote($Batch::Batchrun::CommandParm[$Batch::Batchrun::Counter][$i]) . ',';
  #$command_insert .= $dbh->quote($Batch::Batchrun::CommandData[$Batch::Batchrun::Counter][$i]) . ',';
  #$command_insert .= $dbh->quote($Batch::Batchrun::CommandDesc[$Batch::Batchrun::Counter][$i]) . ')';

  my $sth_step = $dbh->prepare ($command_insert);
  
  if (!defined ($sth_step))
    {
     $Batch::Batchrun::Msg = "ERROR: $DBI::err $DBI::errstr\n";
     return $Batch::Batchrun::ErrorCode;
    } 
    
  $sth_step->bind_param(1, $task_id);
  $sth_step->bind_param(2, $step_id);
  $sth_step->bind_param(3, $Batch::Batchrun::CommandName[$Batch::Batchrun::Counter][$i]);
  $sth_step->bind_param(4, $Batch::Batchrun::CommandParm[$Batch::Batchrun::Counter][$i]);
  $sth_step->bind_param(5, $Batch::Batchrun::CommandData[$Batch::Batchrun::Counter][$i]);
  $sth_step->bind_param(6, $Batch::Batchrun::CommandDesc[$Batch::Batchrun::Counter][$i]);
    
  my $rv_step = $sth_step->execute;
  
  if ( $rv_step != 1 )
    {
     $Batch::Batchrun::Msg = "ERROR: $DBI::err $DBI::errstr\n";
     return $Batch::Batchrun::ErrorCode;
    } 
       
  $sth_step->finish;
  
}
  
#------------------------------------------------------
#  check_length:  Check length
#------------------------------------------------------
sub check_length
  {
   my($str,$label,$max_len) = @_;

   if (length($str) > $max_len)
     {
      print "WARNING: $label has a maximum length of $max_len characters.\n";
      print "WARNING: $label truncated.  Truncated version follows...\n";
      $str = substr($str,1,$max_len);
      print "$str\n";
     }
   return $str;
  }

#------------------------------------------------------
#  Insert task
#------------------------------------------------------
sub insert_task
  { 

  $task_id = get_seq_no($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$Batch::Batchrun::DBHInternal}{DBPROC}, 'batchrun');

  $Batch::Batchrun::TaskDescription = 
           &check_length($Batch::Batchrun::TaskDescription, 'Task Description', 2000);

  #----------------------------------------------------
  # Build the insert statement
  #----------------------------------------------------
  $insert_task = qq{ 
           INSERT into ${domain}task 
            (TASK_ID, NAME, APPLICATION, SOURCE_FILE, SHORT_DESCRIPTION, DESCRIPTION,
             PARAMETERS, CREATE_USER, EFFECTIVE_DATE, LAST_ACCESS ) 
           VALUES ( $task_id, 
            };
            
  $insert_task .=$dbh->quote($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASK'}) . ',';
  $insert_task .=$dbh->quote($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'APP'}) . ',';
  $insert_task .=$dbh->quote($loadfile) . ',';
  $insert_task .=$dbh->quote($taskshort) . ',';
  $insert_task .=$dbh->quote($Batch::Batchrun::TaskDescription) . ',';
  $insert_task .=$dbh->quote($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'EXPECTEDPARMS'}) . ',';
            
  if ($Batch::Batchrun::Run and ($Batch::Batchrun::Databasetype =~ /oracle/i))
    {
     $insert_task .= 'user, sysdate, sysdate )';
    }
  elsif ($Batch::Batchrun::Databasetype =~ /oracle/i)
    {
     $insert_task .= 'user, sysdate, Null )';
    }
  elsif ($Batch::Batchrun::Run and ($Batch::Batchrun::Databasetype =~ /sybase/i))
    {
     $insert_task .= 'suser_name(), getdate(), getdate() )';
    }
  elsif ($Batch::Batchrun::Databasetype =~ /sybase/i)
    {
     $insert_task .= 'suser_name(), getdate(), Null )';
    }
  else #ODBC
    {
     my $temptime = localtime();
     my ($dow,$mon,$day,$time,$year) = split ( / /, $temptime );
     $temptime = "$year-$mon-$day $time";
     $insert_task .= "'$Batch::Batchrun::Opsys_user', '$temptime', '$temptime' )" if $Batch::Batchrun::Run;
     $insert_task .= "'$Batch::Batchrun::Opsys_user', '$temptime', Null )" unless $Batch::Batchrun::Run;
    }

  $step_id = 0;
     
  #----------------------------------------
  #  Insert the task into the database
  #----------------------------------------
  
  my $sth = $dbh->prepare($insert_task);
  if (! $sth )
    {
     $Batch::Batchrun::Msg = "ERROR: $DBI::err $DBI::errstr\n";
     return $Batch::Batchrun::ErrorCode;
    }
  
  my $rv = $sth->execute;
  if ( $rv != 1 )  # 1 row inserted
    {
     $Batch::Batchrun::Msg = "ERROR: $DBI::err $DBI::errstr\n";
     return $Batch::Batchrun::ErrorCode;
    }
  $sth->finish;
    
  $task_id = int ($task_id);
  print "Task:$Batch::Batchrun::Task ",
        " Application:$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'APP'} ",
        "Taskid: $task_id\n";

  }
  
#----------------------------------------------------------
# Validate Syntax 
#----------------------------------------------------------  
sub validate
  {
  my $syntax_error = 0;
  #--------------------------------------------------------
  # Check for Task,App definition and valid names 
  #--------------------------------------------------------
  if (not $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASK'})
    {
    warn "*** NO TASK DEFINED! ***\n";
    $syntax_error = 1;
    }
  if ($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASK'} 
      and $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASK'} =~ m/\W+/)
    {
    warn "*** Task Name: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASK'} contains nonalphanumeric characters! ***\n";
    warn "***            Valid characters are letters, numbers and underscore. ***\n";
    $syntax_error = 1;
    }  
  if ($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'APP'} 
      and $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'APP'} =~ m/\W+/)
    {
    warn "*** Task App: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'APP'} contains nonalphanumeric characters! ***\n";
    warn "***            Valid characters are letters, numbers and underscore. ***\n";
    $syntax_error = 1;
    }  
    
  #--------------------------------------------------------
  # Match up IF/ENDIF
  #--------------------------------------------------------
  my $command_array = $Batch::Batchrun::CommandName[$Batch::Batchrun::Counter];
  my $ifcount = grep(/^IF/,@$command_array);
  my $endifcount = grep(/^END IF/,@$command_array);
       
  if ($ifcount != $endifcount)
    {
    warn "The number of IF and ENDIF commands do not match.\n" ;
    $syntax_error = 1;
    }
    
  #--------------------------------------------------------
  # Match up DO/END DO
  #--------------------------------------------------------    
  my $docount = grep(/^DO/,@$command_array);
  my $enddocount = grep(/^END DO/,@$command_array);
  
  if ($docount != $enddocount)
    {
    warn "The number of DO and ENDDO commands do not match.\n" ;
    $syntax_error = 1;
    }
 
  #--------------------------------------------------------
  #
  # match up goto's, and labels 
  #
  #--------------------------------------------------------
  my $arraysize  = $Batch::Batchrun::CommandName[$Batch::Batchrun::Counter];
   
  print "*** Checking goto's and labels...\n" 
     if ($Batch::Batchrun::DebugLevel > 2);
  my $i = 0;
  my @loop=();
  my $command;
  my $parm;
  my $data;
  my %validhash;
  my %tmphash;
  #--------------------------------------------------------
  # Loop through steps in task to check syntax
  #--------------------------------------------------------    
  while ($i < $#$arraysize)
    {
    $i++;
    $command = $Batch::Batchrun::CommandName[$Batch::Batchrun::Counter][$i];
    $parm = $Batch::Batchrun::CommandParm[$Batch::Batchrun::Counter][$i];
    $data = $Batch::Batchrun::CommandData[$Batch::Batchrun::Counter][$i];
    $parm =~ s/^\s*//g;
    $parm =~ s/\s*$//g;
    study $command;
    study $parm;
    study $data;
    
    push(@loop,'1') if ( $command =~ /^DO/i );
    pop(@loop)      if ( $command =~ /^END DO/i );
      
    #------------------------------------------------------
    # Check that NEXT/BREAK occur within loops
    #------------------------------------------------------    
    if ( $command =~ /^NEXT|^BREAK/i and $#loop < 0)
      {
      warn "Command#$i $command is not within a loop. \n";
      $syntax_error = 1; 
      }
      
    #------------------------------------------------------
    # Check that LABEL exists for each GOTO
    #------------------------------------------------------    
    if ($command =~ /^GOTO/i)
      {
      my $labelname = uc($parm);
      $labelname   =~ s/^ *//g;
      $labelname   =~ s/ *$//g;
      print "*** Command: ", $command, " Label: ",$labelname,"\n" 
         if ($Batch::Batchrun::DebugLevel > 2);
      if (not $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{LABEL}{$labelname} )
        {
        warn "Label:$labelname does not exist.\n";
        $syntax_error = 1;
        }
      }
     #------------------------------------------------------
     # Check that each parameter or list of values are
     # predefined as proper syntax in $Batch::Batchrun::Commands
     #------------------------------------------------------    
     if ($Batch::Batchrun::Commands{$command}{'Chkparms'})
       {
       #----------------------------------------------------
       # Check if parameter required
       #----------------------------------------------------    
       if ( $parm =~ /^\s*$/ )
         {
         warn "Command#$i $command -- parameter required\n";
         $syntax_error=1;
         next;
         }
       if ( $Batch::Batchrun::Commands{$command}{'Chkparms'} != 1 and $parm =~ m/=>/)
         {
         %validhash = ();
         %tmphash = ();
         #--------------------------------------------------
         # Check if extra comma at end of passed parameters
         #--------------------------------------------------    
         if ( $parm =~ m/,\s*$/ )
           {
           warn "Command#$i $command -- , at end of command.  Commas should only separate parameters!\n";
           $syntax_error=1;
           }
           
         #--   Create a hash of valid parameters with map command
         %validhash = map {$_,1} split(',',$Batch::Batchrun::Commands{$command}{'Chkparms'});
         %tmphash = parms_to_hash($parm);
         my $key;
         foreach $key (keys(%tmphash))
           {
           #-- Check if valid paramter
           if ( not $validhash{$key} )
             {
             warn "Command#$i $command -- $key not a valid parameter\n";
             $syntax_error=1;
             }
           }
         foreach $key (keys(%validhash))
           {
           #-- Check if a required parameter is missing
           if ( $Batch::Batchrun::Commands{$command}{$key} != 0 and not $tmphash{$key} )
             {
             warn "Command#$i $command -- $key parameter required\n";
             $syntax_error=1;
             } 
           else
             {
             #-- If parameter requires static values, check that it is valid
             if ($Batch::Batchrun::Commands{$command}{$key} !~ m/(0|1)/)
               {
               my %vhash = ();
               my $tmpval = $tmphash{$key};
               $tmpval =~ s/^\s*//;
               $tmpval =~ s/\s*$//;
               %vhash = map {$_,1} split(',',$Batch::Batchrun::Commands{$command}{$key});
                 if (not $vhash{uc($tmpval)})
                   {
                   warn "Command#$i $command -- $tmpval not a valid parameter value for $key\n";
                   $syntax_error=1;
                   } 
               }
             } #End else
           } #End foreach
         } #End 
       #--------------------------------------------------
       # Check for missing = or >
       #--------------------------------------------------                   
       if ( ($parm =~ s/=/=/og) != ($parm =~ s/>/>/og) )
         {
         warn "Command#$i Named parameters are missing an = or > for $command.\n";
         $syntax_error=1;
         }
       }
     elsif ( $Batch::Batchrun::Commands{$command}{'Chkdata'} and $data =~ m/^\s*$/ )
       {
       #----------------------------------------------------
       # Check if data required
       #----------------------------------------------------  
         warn "Command#$i $command -- parameter or data required\n";
         $syntax_error=1;
         next;
       }
     elsif ( $Batch::Batchrun::Commands{$command}{'Chkdata'} and $data =~ m/=>/ )
       {   
       if ( $Batch::Batchrun::Commands{$command}{'Chkdata'} != 1 )
         {
         %validhash = ();
         %tmphash = ();
         #--------------------------------------------------
         # Check if extra comma at end of passed parameters
         #--------------------------------------------------    
         if ( $data =~ m/,\s*$/ )
           {
           warn "Command#$i $command -- , at end of command.  Commas should only separate parameters!\n";
           $syntax_error=1;
           }
         #--   Create a hash of valid parameters with map command
         %validhash = map {$_,1} split(',',$Batch::Batchrun::Commands{$command}{'Chkdata'});
         %tmphash = parms_to_hash($data);
         my $key;
         foreach $key (keys(%tmphash))
           {
           #-- Check if valid paramter
           if ( not $validhash{$key} )
             {
             warn "Command#$i $command -- $key not a valid parameter\n";
             $syntax_error=1;
             }
           }
         foreach $key (keys(%validhash))
           {
           #-- Check if a required parameter is missing
           if ( $Batch::Batchrun::Commands{$command}{$key} != 0 and not $tmphash{$key} )
             {
             warn "Command#$i $command -- $key parameter required\n";
             $syntax_error=1;
             } 
           else
             {
             #-- If parameter requires static values, check that it is valid
             if ($Batch::Batchrun::Commands{$command}{$key} !~ m/(0|1)/)
               {
               my %vhash = ();
               my $tmpval = $tmphash{$key};
               $tmpval =~ s/^\s*//;
               $tmpval =~ s/\s*$//;
               %vhash = map {$_,1} split(',',$Batch::Batchrun::Commands{$command}{$key});
                 if (not $vhash{uc($tmpval)})
                   {
                   warn "Command#$i $command -- $tmpval not a valid parameter value for $key\n";
                   $syntax_error=1;
                   } 
               }
             } #End else
           } #End foreach
         } #End 
       #--------------------------------------------------
       # Check for missing = or >
       #--------------------------------------------------                   
       if ( ($data =~ s/=/=/og) != ($data =~ s/>/>/og) )
         {
         if ( $command =~ /MAIL/ 
              and ($data =~ s/=/=/og) <= ($data =~ s/>/>/og)
              and $data =~ /HTML/ )
           {
           # Everything is probably ok.
           }
         else
           {
           warn "Command#$i Named parameters are missing an = or > for $command.\n";
           $syntax_error=1;
           }
         }
       } 
     elsif ($Batch::Batchrun::Commands{$command}{'Values'})
       {
       if ( $parm eq '' )
         {
         warn "Command#$i $command -- value required\n";
         $syntax_error=1;
         next;
         }
       my %validhash = map {$_,1} split(',',$Batch::Batchrun::Commands{$command}{Values});
       if ( not $validhash{uc($parm)} )
         {
         if ($validhash{NUMBER} and $parm =~ m/\d+/ )
           {
           # All is well
           }
         else
           {
           warn "Command#$i $command -- $parm not a valid value for $command\n";
           $syntax_error=1;       
           }
         } #End if
       } #End elseif
           
    }  #End while
    

  die "*** SYNTAX ERRORS EXIST ***  Cannot continue!\n" if ($syntax_error);
  }
  
1; 
__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Batch::Batchrun::Load - Batchrun extension module.

=head1 SYNOPSIS

  No general usage.  Designed only as a submodule to Batchrun.

=head1 DESCRIPTION

Contains Batchrun subroutines.

=head1 AUTHORS

Daryl Anderson 

Louise Mitchell 

Email: batchrun@pnl.gov

=head1 SEE ALSO

batchrun(1).

=cut


