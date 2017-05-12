package Batch::Batchrun;

# The Batchrun software is being made available to the public by the
# Pacific Northwest National Laboratory (PNNL).  You may use the software, or
# modify or make derivative works of the software, but such use, modifications
# or derivatives will not be supported by PNNL.  You recognize that the
# software is provided by PNNL on an as-is basis without support.  The
# foregoing statement shall be included in any copies of the code that you
# distribute to others with the requirement that they do the same."
# 
# DISCLAIMER
# 
# This material was prepared as an account of work sponsored by an agency of
# the United States Government.  Neither the United States Government nor the
# United States Department of Energy, nor Battelle, nor any of their
# employees, makes any warranty, express or implied, or assumes any legal
# liability or responsibility for the accuracy, completeness, or usefulness of
# any information, apparatus, product, software or process disclosed, or
# represents that its use would not infringe privately owned rights.
# 
# ACKNOWLEDGMENT
# 
# This software and its documentation were produced with Government support
# under contract Number DE-AC06-76RLO1830 awarded by the United States
# Department of Energy.  The Government retains a paid-up, non-exclusive,
# irrevocable, worldwide license to reproduce, prepare derivative works,
# perform publicly and display publicly by or for the Government, including
# the right to distribute to other Government contractors.


use strict;
no strict 'vars';
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA        = qw(Exporter);
@EXPORT     = qw(run_task );

$VERSION = '1.03';

# Preloaded methods go here.
use Batch::Batchrun::Initialize    qw (initialize);
use Batch::Batchrun::Load          qw (load validate);
use Batch::Batchrun::BuildFile     qw (buildfile buildallfiles);
use Batch::Batchrun::ProcessSteps  qw (process_steps);
use Batch::Batchrun::Library       qw (print_execution_map);
use Batch::Batchrun::Extract       qw (extract_task);


sub new 
  {
    my $type = {};
    bless $type;
    return $type;
  }



sub build
  {
   my $buildrc;
   $buildrc = buildfile();
   if ( $buildrc != $Batch::Batchrun::NoErrors )
     {
     die "Batchrun build file failed!\n";
     }
   print "\nBatchrun - Build file successful!\n";
   exit $Batch::Batchrun::NoErrors;
  }

sub buildall
  {
   my $buildrc;
   $buildrc = buildallfiles();
   if ( $buildrc != $Batch::Batchrun::NoErrors )
     {
     die "Batchrun build all files failed!\n";
     }
   print "\nBatchrun - Build all files successful!\n";
   exit $Batch::Batchrun::NoErrors;
  }
  
sub run_task
  { 
   initialize();
   my $line;
   #foreach $line (values(%INC)) {print $line,"\n";};
   my $loadrc;
   build() if ( $Batch::Batchrun::Build );
   buildall() if ( $Batch::Batchrun::BuildAll );
   $loadrc = load() if ( $Batch::Batchrun::Load );
   $loadrc = load() if ( !$Batch::Batchrun::Load and $Batch::Batchrun::Filename );

   if ( $loadrc != $Batch::Batchrun::NoErrors )
        {
         print $Batch::Batchrun::ErrorSeparator . "** $Batch::Batchrun::Msg \n" . $Batch::Batchrun::ErrorSeparator;
         exit $loadrc;
        }

   if ( $Batch::Batchrun::Run )
     {
      $Batch::Batchrun::TaskStartTime = time;
      $rc = execute();
      EndOfTaskReport();
      if ( $Batch::Batchrun::DBHTMM{DBPROC} )
        {
         $Batch::Batchrun::DBHTMM{DBPROC}->disconnect;
        }
      exit $rc;
     }
   else
     {
     exit $Batch::Batchrun::NoErrors;
     }
  }
  
sub execute 
  {

    my $rca =extract_task();
    if ($rca != $Batch::Batchrun::NoErrors) 
      {
       print $Batch::Batchrun::ErrorSeparator . "** $Batch::Batchrun::Msg \n" . $Batch::Batchrun::ErrorSeparator;
       return $rca;
      }

    if ( $Batch::Batchrun::Counter == 1 )
      {
       my $rcd = print_execution_map();
      }
         
    if ($Batch::Batchrun::CheckOnly)
      {
       validate();
       print "===SYNTAX CHECK COMPLETE===\n";
       exit;
      }  
        
    my $rcb = process_steps();
    return $rcb;
  }
  
sub EndOfTaskReport 
  {

   $Batch::Batchrun::TaskEndTime = time;

   my $TimeDiff = $Batch::Batchrun::TaskEndTime
                - $Batch::Batchrun::TaskStartTime;

   $Batch::Batchrun::TotalTaskTime   = $TimeDiff;
    
   my($hours) = int($TimeDiff/3600);
   my($minutes) = int(($TimeDiff - ($hours * 3600))/60);
   my($seconds) = int (($TimeDiff - ($hours * 3600) - ($minutes * 60)));
   my $time_date = 
      sprintf("%2.2d:%2.2d:%2.2d",$hours,$minutes,$seconds);
   my $timestr = localtime();

   my $steparray;
   my $stepnum = 0;
   my $i;my $j;
   my $connect;
   my $cpu;
   my $iterations;
   my $status;
   my $cmd;
   print $Batch::Batchrun::EventSeparator;
   print "\n";
   print "     ######################################################################\n";
   print "     ####                      END OF TASK REPORT                      ####\n";
   print "     ####                   ( In order of execution )                  ####\n";
   print "     ######################################################################\n";
   print "                Command           Connect    CPU                        \n",
         "     Step#      Name              Time       Time       Iterations  Status \n";
   print "     ----------------------------------------------------------------------\n";  
              
eval <<'____END_OF_PLAIN_STUFF';    
format STDOUT =
     @<<<<<<<<  @<<<<<<<<<<<<<<   @<<<<<<<   @<<<<<<<<<<     @<<<<  @<<<<<<
$stepnum,$cmd,$connect,$cpu,$iterations,$status
.
   
____END_OF_PLAIN_STUFF


   my %seen;
   foreach $num ( @Batch::Batchrun::StatsOrder )
     {

     $stepnum = $num;
     $iterations =  $Batch::Batchrun::Stats{$stepnum}{'Iterations'};
     next if $seen{$stepnum};
     $seen{$stepnum} = 1;
      if ($iterations > 0)
        {
        ($hours) = int($Batch::Batchrun::Stats{$stepnum}{StepTimes}/3600);
        ($minutes) = int(($Batch::Batchrun::Stats{$stepnum}{StepTimes} - ($hours * 3600))/60);
        ($seconds) = int (($Batch::Batchrun::Stats{$stepnum}{StepTimes} - ($hours * 3600) - ($minutes * 60)));
        $connect = sprintf("%2.2d:%2.2d:%2.2d",$hours,$minutes,$seconds);
        ($hours) = int($Batch::Batchrun::Stats{$stepnum}{StepCPUTimes}/3600);
        ($minutes) = int(($Batch::Batchrun::Stats{$stepnum}{StepCPUTimes} - ($hours * 3600))/60);
        ($seconds) = ($Batch::Batchrun::Stats{$stepnum}{StepCPUTimes} - ($hours * 3600) - ($minutes * 60));
        ($hundreds) = ($Batch::Batchrun::Stats{$stepnum}{StepCPUTimes} - ($hours * 3600) - ($minutes * 60) - $seconds);

        $cpu = sprintf("%2.2d:%2.2d:%04.2f",$hours,$minutes,$seconds);
        $status = $Batch::Batchrun::Stats{$stepnum}{Status};
        $status = 'Success' if ($status == $Batch::Batchrun::NoErrors);
        $status = 'Error  ' if ($status == $Batch::Batchrun::ErrorCode);
        $status = 'Warning' if ($status == $Batch::Batchrun::WarningCode);
        $cmd = $Batch::Batchrun::Stats{$stepnum}{'CommandName'};
        if ($cmd =~ /^DO|^GOSUB/io)
          {
          #$iterations = $Batch::Batchrun::Stats{$stepnum}{'LoopIterations'};
          $iterations-- if $iterations > 1;
          }
        $iterations = '' if $iterations < 2;
        #else
         # {
         # $iterations = '';
         # }

        write;
        }

     }
   print "     ----------------------------------------------------------------------\n"; 
   print "     Task: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASK'} ",
             " Application: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'APP'} \n";
   print "     Total Task Time: $time_date     Completed: $timestr \n";
   print "     ######################################################################\n";      

}
        
1;
__END__

# Autoload methods go after =cut, and are processed by the autosplit program.

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Batch::Batchrun - Batch Control language

=head1 SYNOPSIS

  use Batch::Batchrun;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Batch::Batchrun was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut

