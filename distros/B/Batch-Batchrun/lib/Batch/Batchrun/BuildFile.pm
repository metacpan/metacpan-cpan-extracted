#!/apps/perl5/bin/perl

package Batch::Batchrun::BuildFile;

use strict;
use vars qw($g_FALSE $VERSION @ISA @EXPORT @EXPORT_OK);
use DBI;

require Exporter;

@ISA     = qw(Exporter);
@EXPORT  = qw(buildfile buildallfiles);
$VERSION = '1.03';


# Preloaded methods go here.
use Batch::Batchrun::Extract       qw(extract_task);
use Batch::Batchrun::Initialize    qw(initialize);
use Batch::Batchrun::Library       qw(parms_to_hash);
use Batch::Batchrun::Dbfunctions   qw(command_logon command_logoff);
use File::Path;
    

sub buildfile 
  {
    my $rc = extract_task();
                      
    if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASK'}
         and $rc == $Batch::Batchrun::NoErrors )
      {
      my $path;
      if ($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'APP'})
        {
        $path  = $Batch::Batchrun::Control{CONFIG}{TasksDirectory};
        $path .= '/'.lc($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'APP'});
        if (not -d $path)
          {
          print "Creating directory: $path\n";
          mkpath($path, 0, 0755);
          }
        }
      my $filename = $path;
      $filename   .= '/'.lc($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASK'}).'.task';
      open(BUILDFILE, ">$filename") or die "Couldn't open $filename for build!\n";
      my $i = 0;
      my $numtabs = 0;
      my $indent  = '';
      my $arraysize = $Batch::Batchrun::CommandName[1];
      print BUILDFILE "!------------------------------------------\n";
      print BUILDFILE "!TASK: $Batch::Batchrun::Task, ", $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'APP'};
      if ($Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'EXPECTEDPARMS'} =~ m/\w/)
        {
        print BUILDFILE ", ",$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'EXPECTEDPARMS'}," \n";
        }
      else
        {
        print BUILDFILE "\n";
        }
      print BUILDFILE "!------------------------------------------\n";

      if ($Batch::Batchrun::TaskDescription)
        {
        print BUILDFILE "$Batch::Batchrun::TaskDescription" ;
        print BUILDFILE "\n" if ($Batch::Batchrun::TaskDescription !~ m/\n$/);
        }
        
      print BUILDFILE "!-\n!-\n" ;

      for ($i=1;$i <= $#$arraysize;$i++)
        {
        $numtabs-- if($Batch::Batchrun::CommandName[1][$i] =~ /else/i);
        $indent = '    ' x $numtabs;
        print BUILDFILE $indent,"!% ",$Batch::Batchrun::CommandDesc[1][$i],"\n" 
                        if ($Batch::Batchrun::CommandDesc[1][$i]);
        print BUILDFILE $indent,"!",$Batch::Batchrun::CommandName[1][$i];
        print BUILDFILE "  ",$Batch::Batchrun::CommandParm[1][$i];
        print BUILDFILE "\n" if (not $Batch::Batchrun::CommandData[1][$i]);
        if ($Batch::Batchrun::CommandData[1][$i])
          {
          print BUILDFILE "\n" if ($Batch::Batchrun::CommandData[1][$i] !~ m/^\s*\n/ );
          print BUILDFILE $Batch::Batchrun::CommandData[1][$i];
          print BUILDFILE "\n" if ($Batch::Batchrun::CommandData[1][$i] !~ m/\n$/);
          }
        $numtabs++ if($Batch::Batchrun::CommandName[1][$i] =~ /^if|^do|^else/i);
        $numtabs-- if($Batch::Batchrun::CommandName[1][$i] =~ /^end/i);
        print BUILDFILE $indent,"!-\n",$indent,"!-\n" if ($Batch::Batchrun::CommandData[1][$i]);
        }
      print BUILDFILE "!------------------------------------------\n";
      close(BUILDFILE);
      return $Batch::Batchrun::NoErrors;
      }
    else
      {
      die "Extract failed!\n";
      }
  }

sub buildallfiles
  {
  #*************************************************************
  #   Logon to Server
  #*************************************************************

  my $rc = command_logon(
                   HANDLE  =>$Batch::Batchrun::DBHInternal , 
                   SERVER  =>$Batch::Batchrun::Server, 
                   DBTYPE  =>$Batch::Batchrun::Databasetype, 
                   USER    =>$Batch::Batchrun::User, 
                   PASSWORD=>$Batch::Batchrun::Password,
                   DATABASE=>$Batch::Batchrun::Database
                );

  if ($rc != $Batch::Batchrun::NoErrors)
    {
     print  $Batch::Batchrun::Msg;
     return $Batch::Batchrun::False;
    }

  my $GetTaskQuery = 
       "Select  distinct name, application 
          From  task "; 
          
  #*************************************************************
  #  Prepare TASK query
  #*************************************************************

  $Batch::Batchrun::Control{$Batch::Batchrun::DBHInternal }{'STMT'} = 
                  $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{$Batch::Batchrun::DBHInternal }{DBPROC}->prepare($GetTaskQuery);

  if (!defined ($Batch::Batchrun::Control{$Batch::Batchrun::DBHInternal }{'STMT'}))
    {
     $Batch::Batchrun::Msg = "ERROR: Prepare for $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASK'} " .
                    "failed because $DBI::errstr\n This is an unrecoverable error \n";
     return $Batch::Batchrun::False;
    }
 
  #*************************************************************
  #  Execute TASK query - passing bind variables ( see question marks in $GetStepQuery )
  #*************************************************************

  $rc = $Batch::Batchrun::Control{$Batch::Batchrun::DBHInternal }{'STMT'}->execute ();
  if ( undef($rc) )
    {
    print "*** ERROR: Couldnt execute query for task: $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASK'} \n";
    return $Batch::Batchrun::False;
    }

  my ( @tasks,@tasklist,@applist) = ();
  while(@tasks = $Batch::Batchrun::Control{$Batch::Batchrun::DBHInternal }{'STMT'}->fetchrow_array)
    { 
    push(@tasklist,$tasks[0]);
    push(@applist,$tasks[1]);
    }
  
  $Batch::Batchrun::Control{$Batch::Batchrun::DBHInternal }{'STMT'}->finish;
  delete ($Batch::Batchrun::Control{$Batch::Batchrun::DBHInternal }{'STMT'});

  $rc = command_logoff ( HANDLE=>$Batch::Batchrun::DBHInternal );
  if ( $rc != $Batch::Batchrun::NoErrors )
    {
     $Batch::Batchrun::Msg = "* ERROR disconnecting for DBHInternal in Buildfile.pm because $DBI::errstr\n";
     return $Batch::Batchrun::False;
  }
  
  my $task;
  my $i;
  while ($i <= $#tasklist)
    {
    $Batch::Batchrun::Task = $tasklist[$i];
    $Batch::Batchrun::Application = $applist[$i];
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASK'} = $Batch::Batchrun::Task;
    $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'APP'} = $Batch::Batchrun::Application;
    $Batch::Batchrun::Step = 1;
    $Batch::Batchrun::CommandName[1]=();
    $Batch::Batchrun::CommandDesc[1]=();
    $Batch::Batchrun::CommandParm[1]=();
    $Batch::Batchrun::CommandData[1]=();
    
    print "Building file for Application: $Batch::Batchrun::Application  Task:$Batch::Batchrun::Task\n";
    &buildfile();
    $i++;
    }
    

   
      
  }
  

1;

__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Batch::Batchrun::Buildfile - Batchrun extension to extract tasks from a database
                             repository to files.

=head1 SYNOPSIS

  batchrun [-b] [-B] -T TASKNAME -a APPLICATION

=head1 DESCRIPTION

This module is specific to batchrun in that it extracts tasks from a 
database repository.  It uses information passed in environment variables or
the command line to determine what task to retrieve.  

=head2 OPTIONAL PARAMETERS

=over 4

=item B<b>

extracts one task and puts it in {TasksDirectory}/APPLICATION/TASKNAME

=item B<B>

extracts latest version of every task and puts them in
{TasksDirectory}/APPLICATION/TASKNAME

=head1 AUTHOR

Daryl Anderson  

Louise Mitchell 

=head1 SEE ALSO

batchrun(1).

=cut

