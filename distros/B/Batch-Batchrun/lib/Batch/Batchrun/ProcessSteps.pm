package Batch::Batchrun::ProcessSteps;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Batch::Batchrun::RunCommand qw(run_command);
use Batch::Batchrun::Library    qw(substitution check_taskparms);

require Exporter;

@ISA     = qw(Exporter);
@EXPORT  = qw(process_steps);
$VERSION = '1.03';


# Preloaded methods go here.
 
sub process_steps
   {
     #****************************
     #  Housekeeping
     #****************************
     $Batch::Batchrun::Control{ResetStepData} = $Batch::Batchrun::True;

     if ( $Batch::Batchrun::Rerun  and $Batch::Batchrun::Counter == 1)
       {
        $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{Index} = $Batch::Batchrun::Rerun;
       }
     else
       {
        $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{Index} = 1;
       }


     #*****************************************
     #  Setup TASKPARAMPAIRS, if there are any
     #*****************************************

     &check_taskparms();

     #****************************
     #  Main processing loop
     #****************************
     PROCESS_STEPS: while ($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{Index} <= $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{NumSteps})
       { 
        #**************************************
        #   Reset Error Msg and number
        #**************************************
        $Batch::Batchrun::Msg = '';
        $Batch::Batchrun::Error = $Batch::Batchrun::NoErrors;
        $Batch::Batchrun::NewIndex = undef;

        #***************************************
        #  get command, parm, and data
        #***************************************
        if ($Batch::Batchrun::Control{ResetStepData})
          {

           my $i = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{Index};
           $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandName} = $Batch::Batchrun::CommandName[$Batch::Batchrun::Counter][$i];
           $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandParm} = $Batch::Batchrun::CommandParm[$Batch::Batchrun::Counter][$i];
           $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData} = $Batch::Batchrun::CommandData[$Batch::Batchrun::Counter][$i];
           $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandDesc} = $Batch::Batchrun::CommandDesc[$Batch::Batchrun::Counter][$i];
           #***************************
           #  Construct step number 
           #***************************
           $Batch::Batchrun::Control{StepNumber} = construct_step_number($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{Index});

          }
        $Batch::Batchrun::Control{ResetStepData}      = $Batch::Batchrun::True;


        #********************************
        #  Print step info / save stats  
        #********************************
        step_start();

        #*************************************************
        #   Need to add code to handle restarts/reruns
        #    ie, skip some steps if needed
        #*************************************************

        #**************************************************
        #  Do substitutions for PARM and DATA from TASKPARAMPAIRS
        #**************************************************
        if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{TASKPARAMPAIRS} 
             and $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandName} !~ m/^(SET|UNSET)/i ) 
         {
              #************************************************************************************************
              #  Do substitution if there is a Task level OR if this is not the same step that set the params
              #************************************************************************************************
                  $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandParm} 
                      = substitution($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandParm});

                  $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData} 
                       = substitution($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData});
          }


        #**********************************
        #  Run the command -- 'Just Do It'
        #**********************************
        #my $print_sw;
        if ( $Batch::Batchrun::Error == $Batch::Batchrun::NoErrors )
          {
           $Batch::Batchrun::Error = run_command ( COMMAND=>$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandName},
                                                         PARM   =>$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandParm},
                                                         DATA   =>$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData},
                                                         DESC   =>$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandDesc} );
          }

        #**********************************
        #   Save Step stats
        #**********************************
        
        step_stats();



        #********************************************************
        #   Process RETURN or EXIT command
        #********************************************************
        if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandName} =~ /RETURN/i  or 
             $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandName} =~ /EXIT/i )
          {
           return $Batch::Batchrun::Error;
          }
          
        #********************************************************
        #  Process errors - check error code and act accordingly
        #*********************************************************
        my $rc = handle_errors();
        if ($rc == $Batch::Batchrun::ErrorCode )
          {
           return $rc;
          }

        if ( defined($Batch::Batchrun::NewIndex) )
          {
           $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{Index} = $Batch::Batchrun::NewIndex;
           next PROCESS_STEPS;
          }

        if ( $Batch::Batchrun::Error != $Batch::Batchrun::ErrorCode and $Batch::Batchrun::Error != $Batch::Batchrun::WarningCode )
          {
           $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{Index}++;
          }
         
       }   # end of process loop

    if ( $Batch::Batchrun::Counter == 1 )
      {
       print "*** FINISHED processing commands *** \n";
      }
    return $Batch::Batchrun::NoErrors;
 }

#********************************
sub construct_step_number
#********************************
{
 my $sn = shift;
 my $cnt; my $ssnn;
 if ( $Batch::Batchrun::Counter > 1 )
   {
    #foreach($cnt=$Batch::Batchrun::Counter-1;$cnt>=1;--$cnt)
    foreach($cnt=1;$cnt < $Batch::Batchrun::Counter;$cnt++)
      {
       $ssnn .= "$Batch::Batchrun::Control{$cnt}{Index}\.";
      }
    $ssnn .= $sn;
   }
 else
   {
    $ssnn = $sn;
   }
 return $ssnn;
}

#********************************
sub step_start
#********************************
  {
   if (not $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{CommandName})
     {
      $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{CommandName} 
        = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandName};
     }
     
   $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{StartStepTime} = time;
   $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{StartStepCPUTime} = (times)[0];
   $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{Iterations}++;
   $Batch::Batchrun::StatsStep++;
   push(@Batch::Batchrun::StatsOrder,$Batch::Batchrun::Control{StepNumber});
   $Batch::Batchrun::StatsMap{$Batch::Batchrun::StatsStep} = $Batch::Batchrun::Control{StepNumber};

  }

#********************************
sub step_stats
#********************************
  {

   $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{StopStepTime} = time;
   $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{StopStepCPUTime} = (times)[0];
   
   my $TimeDiff = $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{StopStepTime}
                - $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{StartStepTime};

   my $TimeDiff2 = $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{StopStepCPUTime}
                - $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{StartStepCPUTime};
   my $i = $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{Index};
   $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{StepTimes}   += $TimeDiff;
   $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{StepCPUTimes}   += $TimeDiff2;
   #$Batch::Batchrun::StepErr[$Batch::Batchrun::Counter][$i]     = $Batch::Batchrun::Error;
   #$Batch::Batchrun::StepMessage[$Batch::Batchrun::Counter][$i] = $Batch::Batchrun::Msg;

   
   my($hours) = int($TimeDiff/3600);
   my($minutes) = int(($TimeDiff - ($hours * 3600))/60);
   my($seconds) = int (($TimeDiff - ($hours * 3600) - ($minutes * 60)));
   my $time_date = 
      sprintf("%2.2d:%2.2d:%2.2d",$hours,$minutes,$seconds);
   my $timestr = localtime();

   if ( $Batch::Batchrun::PrintSw{$Batch::Batchrun::Counter} )
     {
      print "$Batch::Batchrun::Tabs" . "Total Step Time: $time_date   Completed: $timestr \n";
     }
}
        
#********************************
sub handle_errors
#********************************
{
 #*****************************************************
 #   Handle NoErrors
 #*****************************************************
 if ( $Batch::Batchrun::Error == $Batch::Batchrun::NoErrors )
   {
    return $Batch::Batchrun::NoErrors;            
   }

 #*****************************************************
 #   Handle WARNINGS 
 #*****************************************************
 if ( $Batch::Batchrun::Error == $Batch::Batchrun::WarningCode )  #Warning
   {
    $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{Status} = $Batch::Batchrun::WarningCode;

    if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnWarning} == $Batch::Batchrun::True )
      {
       if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnWarningCommand} !~ /ABORT/i )
         {
          # reset step data and continue
           if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnWarningCommand} =~ /^GOTO/i )
             {
              $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnWarningCommand} =~ s/^GOTO(:*)(.*)/$2/i;
              $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandName} = 'GOTO';
              $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandParm} = 
                  $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnWarningCommand};
             }
           else
             {
              $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandName} =
                  $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnWarningCommand};
             }
          
          $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData} = '';
          $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandParm} =~ s/^\s*//g;
          $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandParm} =~ s/\s*$//g;
          $Batch::Batchrun::Control{StepNumber} = 'OnWarn';
          $Batch::Batchrun::Control{ResetStepData} = $Batch::Batchrun::False;
          # if ON WARNING is a GOTO, reset to CONTINUE in case of an error in the gone-to section
          if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandName} =~ /GOTO/i )
            {
             delete $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnWarning};
            }
          return $Batch::Batchrun::NoErrors;
         }
       else
         { # ABORT behavior
           return $Batch::Batchrun::ErrorCode;
         }
      }
    else
      {
       #************************************
       #   Default and CONTINUE behavior
       #************************************
       if ( ! $Batch::Batchrun::Output{$Batch::Batchrun::Counter} 
           and $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnWarningCommand} !~ /CONTINUE/i)
         {
         # If output is off and continue specified then don't show it
         }
       else
         {
         print "$Batch::Batchrun::ErrorSeparator WARNING: Step $Batch::Batchrun::Control{StepNumber} \n $Batch::Batchrun::ErrorSeparator";
         print "$Batch::Batchrun::Msg\n";
         }
       push ( @Batch::Batchrun::WarningSteps, $Batch::Batchrun::Control{StepNumber} );
       $Batch::Batchrun::TotalWarnings++;
       $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{Index}++;
       return $Batch::Batchrun::NoErrors;
   }
  }
 #*****************************************************
 #   Handle ERRORS
 #*****************************************************
 if ( $Batch::Batchrun::Error == $Batch::Batchrun::ErrorCode ) #Error
   {
    $Batch::Batchrun::Stats{$Batch::Batchrun::Control{StepNumber}}{Status} = $Batch::Batchrun::ErrorCode;
    print "$Batch::Batchrun::ErrorSeparator ERROR: Step $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{Index} \n$Batch::Batchrun::ErrorSeparator ";
    print "$Batch::Batchrun::Msg\n";
    if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnError} == $Batch::Batchrun::True )
      {
       if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnErrorCommand} !~ /CONTINUE/i )
         {
            if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{LoopCtr}}{InALoop} )
              {
               print "*** Setting LoopCleanupSw to true *** \n";
               $Batch::Batchrun::LoopCleanupSw = $Batch::Batchrun::True;
               print "*** LoopCleanupSw: $Batch::Batchrun::LoopCleanupSw \n";
              }
            if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnErrorCommand} =~ /^GOTO/i )
              {
               $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnErrorCommand} =~ s/^GOTO(:*)(.*)/$2/i;
               $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandName} = 'GOTO';
               $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandParm} = 
                   $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnErrorCommand};

              }
            else
              {
               $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandName} =
                   $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnErrorCommand};
              }
          
            $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandData} = '';
            $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandParm} =~ s/^\s*//og;
            $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandParm} =~ s/\s*$//og;
            $Batch::Batchrun::Control{ResetStepData} = $Batch::Batchrun::False;
            $Batch::Batchrun::Control{StepNumber} = 'OnError';
            # if ONERROR is a GOTO, reset to ABORT in case of an error in the gone-to section
            if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{CurrentCommandName} =~ /GOTO/i )
              {
                $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{OnErrorCommand} = 'ABORT';
              }
            return $Batch::Batchrun::NoErrors;
         }
       else # CONTINUE behavior
         {
          print "ERROR: Step $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{Index} \n";
          $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{Index}++;
          print "$Batch::Batchrun::Msg\n";
          return $Batch::Batchrun::NoErrors;
         }
      }
    else   #  OnError false -- Default Error behavior
      {
       return $Batch::Batchrun::ErrorCode;
      }
   }
 if ( $Batch::Batchrun::Error == $Batch::Batchrun::FatalCode ) #Fatal
   {
     print "FATAL:  Aborting \n";
     die;
   }
}
1;

__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Batch::Batchrun::ProcessSteps - Batchrun extension module.

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


