package Batch::Batchrun::Extract;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA     = qw(Exporter);
@EXPORT  = qw();
@EXPORT_OK  = qw(extract_task);
$VERSION = '1.03';

# Preloaded methods go here.
use DBI;
use Batch::Batchrun::Dbfunctions qw (command_logon command_logoff);
use Batch::Batchrun::Library     qw (load_task_data load_step_array GetLargeData);
use Batch::Batchrun::Load        qw (load);
 
sub extract_task
   {
    if ( $Batch::Batchrun::Filename ne '' )
      {
       #  If filename and counter is one then task is already loaded.
       return if $Batch::Batchrun::Counter == 1;
       my $rc = load();
       if ( $rc != $Batch::Batchrun::NoErrors )
         {
         return $Batch::Batchrun::ErrorCode;
         }
       else
         {
         return $Batch::Batchrun::NoErrors;
         }
      }

    #*************************************************************
    #  Housekeeping
    #*************************************************************

    $Batch::Batchrun::IfCounter{$Batch::Batchrun::Counter} = 0;

    #*************************************************************
    #   Logon to Server
    #*************************************************************
 
    my $logonrc = command_logon(
                    HANDLE    =>$Batch::Batchrun::DBHInternal , 
                    SERVER    =>$Batch::Batchrun::Server, 
                    SECONDARY =>$Batch::Batchrun::Secondary,
                    DBTYPE    =>$Batch::Batchrun::Databasetype, 
                    USER      =>$Batch::Batchrun::User, 
                    PASSWORD  =>$Batch::Batchrun::Password,
                    DATABASE  =>$Batch::Batchrun::Database
                  );

    if ( $logonrc != $Batch::Batchrun::NoErrors )
      {
       print "**ERROR: $Batch::Batchrun::Msg \n";
       return $Batch::Batchrun::ErrorCode;
      }

    #*************************************************************
    #  Prepare TASK query
    #*************************************************************

    my $GetTaskQuery = qq{
          Select  a.parameters, 
                  a.task_id, 
                  a.application, 
                  a.description
            From  task a
           Where  a.name = '$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{TASK}'
             And  a.application = '$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{APP}'
             And  a.effective_date =
                    ( Select Max(Effective_Date) 
                      From   task
                      Where  name = '$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{TASK}'
                        And  application = '$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{APP}' )
        }; 
        
    my $sth_task = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$Batch::Batchrun::DBHInternal }{DBPROC}->prepare($GetTaskQuery);

    if (! $sth_task )
      {
       $Batch::Batchrun::Msg = "ERROR: Prepare for $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{TASK} " .
                      "failed because $DBI::errstr\n This is an unrecoverable error \n";
       return $Batch::Batchrun::ErrorCode;
      }

    #*************************************************************
    #  Execute TASK query - passing bind variables ( see question marks in $GetStepQuery )
    #*************************************************************
    
    my $rc = $sth_task->execute;
    
    if ( ! $rc )
      {
      print "*** ERROR: Couldn't execute query for task: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{TASK} \n";
      return $Batch::Batchrun::ErrorCode;
      }

    my ( @taskdat ) = ();
    
    @taskdat = $sth_task->fetchrow_array;

    if ($#taskdat  < 0)
      {
       $Batch::Batchrun::Msg = "*** ERROR: TASK NOT FOUND **** \n" . 
                        "Task: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{TASK}" .
                        "\n App: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{APP} \n" ;
       return $Batch::Batchrun::ErrorCode;
      }

    my $task_id =  $taskdat[1];

    load_task_data  (
                      TASKID   =>$taskdat[1],
                      TASKDESC =>$taskdat[3],
                      TASKPARMS=>$taskdat[0],
                      TASKAPP  =>$taskdat[2] 
                    );

    #************************************
    #  wrap up the statement
    #************************************
    $sth_task->finish;
    
    #********************************************************************
    #  Update TASK.LAST_ACCESS if $Batch::Batchrun::Run or $Batch::Batchrun::Rerun
    #********************************************************************
     
    if ($Batch::Batchrun::Run or $Batch::Batchrun::Rerun)
      {
       my $current_date;

       if ($Batch::Batchrun::Databasetype =~ /oracle/i )
         {
          $current_date = 'SYSDATE';
         }
       elsif ($Batch::Batchrun::Databasetype =~ /sybase/i )
         {
          $current_date = 'getdate()';
         }
       else #ODBC
         {
          my $temptime = localtime();
          my ($dow,$mon,$day,$time,$year) = split ( / /, $temptime );
          $current_date = "$year-$mon-$day $time";
         }

       my $UpdateAccess = "Update TASK
                              Set LAST_ACCESS = $current_date
                            Where TASK_ID = $task_id";

       my $rc = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$Batch::Batchrun::DBHInternal}{DBPROC}->do($UpdateAccess);

       if ($DBI::err)
         {
          $Batch::Batchrun::Msg = $DBI::errstr;
          return $Batch::Batchrun::ErrorCode;
         }
      }

    #********************************************************************
    #  Prepare STEP query
    #********************************************************************
     
    my $GetStepQuery =
            "Select a.command_name, 
                    a.command_parameters, 
                    a.command_data,
                    a.short_description 
              From  step a
             Where  a.task_id = $task_id
           Order By a.step_id"; 

    my $sth_step = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$Batch::Batchrun::DBHInternal }{DBPROC}->prepare($GetStepQuery);

    if (! $sth_step )
      {
       $Batch::Batchrun::Msg = "ERROR: Prepare for $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{TASK} " .
                      "failed because $DBI::errstr\n This is an unrecoverable error \n";
       return $Batch::Batchrun::ErrorCode;
      }

    #********************************************************************
    #  Execute STEP query - passing bind variables ( see question marks in $GetStepQuery )
    #********************************************************************
    
    my $rc2 = $sth_step->execute;

    if (! $rc2 )
      {
      print "*** ERROR: $DBI::err $DBI::errstr \n";
      return $Batch::Batchrun::ErrorCode;
      }

    my($StepNumber) = 1;
    if ($Batch::Batchrun::DebugLevel > 2) {print "*** DEBUG: Extract - STMT: $Batch::Batchrun::Control{$Batch::Batchrun::DBHInternal}{STMT} \n";}
    my ( @dat ) = ();
    
    #****************************************************************************
    #   Main Loop
    #****************************************************************************
    while ((@dat = $sth_step->fetchrow_array))
      {
       my $command_data;

       if ( $Batch::Batchrun::Databasetype =~ /oracle/i )
         {
          $command_data = GetLargeData($sth_step,$Batch::Batchrun::DBHInternal,2);
         }
       else
         {
          $command_data = $dat[2];
         }
      # $dat[3]   =~ s/^ *//g;
      # $dat[3]   =~ s/ *$//g;
       
       my $rc1 = load_step_array (
                                   STEPNUMBER    =>   $StepNumber,
                                   NAME          =>   $dat[0],
                                   PARM          =>   $dat[1],
                                   DATA          =>   $command_data,
                                   DESC          =>   $dat[3]
                                 );

       $StepNumber++;   
    }

    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{NumSteps} = $StepNumber - 1;

    $sth_step->finish;

    my $rcy = command_logoff ( HANDLE=>$Batch::Batchrun::DBHInternal );
    if ( $rcy != 0 )
      {
       $Batch::Batchrun::Msg = "* ERROR disconnecting for DBHInternal in Extract.pm because $DBI::errstr\n";
       return $Batch::Batchrun::ErrorCode;
      }

      # If nothing returned then 
      if ($StepNumber == 0)
        {
         print  $Batch::Batchrun::ErrorSeparator;
         print  "* ERROR - Task entitled " . $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{TASK} ;
         print  " cannot be found\n";
         print  "* This is an unrecoverable error.\n";
         print  $Batch::Batchrun::ErrorSeparator;
         $Batch::Batchrun::Error = $Batch::Batchrun::ErrorCode;
         return $Batch::Batchrun::ErrorCode;
       }
       

    return $Batch::Batchrun::NoErrors;
   }

sub print_arrays
  {
   my $num_steps;
   $num_steps = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{NumSteps};

   print "**** NUMBER OF STEPS: $num_steps \n";
   my ( $i ) = 0;
   for ( $i=0; $i<$num_steps; $i++ )
     {
      print "********************************\n";
      print "** Command Name: $Batch::Batchrun::CommandName[$Batch::Batchrun::Counter][$i] \n";
      print "** Command Data: $Batch::Batchrun::CommandData[$Batch::Batchrun::Counter][$i] \n";
      print "** Command Parm: $Batch::Batchrun::CommandParm[$Batch::Batchrun::Counter][$i] \n";
     }

  }




1;

__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Batch::Batchrun::Extract - Batchrun extension module.

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

