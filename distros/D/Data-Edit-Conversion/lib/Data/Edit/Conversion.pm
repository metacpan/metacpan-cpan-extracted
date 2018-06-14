#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Data::Edit::Conversion - Perform a restartable series of steps in parallel.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018
#-------------------------------------------------------------------------------
package Data::Edit::Conversion;
our $VERSION = "20180610";
require v5.16;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Storable;
use Time::HiRes qw(time);
use utf8;

#1 Methods                                                                      # Specify and run the restartable conversion of zero or more files in parallel

sub defaultMaximumNumberOfProcesses                                             #P Default maximum number of processes to use during the conversion
 {8}

sub defaultOutFileLimit                                                         #P Default maximum number of files to clear art a time.
 {32}

sub new(@)                                                                      #S Create a conversion specification for zero or more files represented by projects.
 {my (@attributes) = @_;                                                        # L</Launch attributes> describing the launch
  my $launch = bless {@attributes};
  ref($launch->projects) &&
  ref($launch->projects) =~ m(\AData::Edit::Conversion::Projects\Z) or          # Convert zero or more projects
    confess "projects=>Data::Edit::Conversion::Projects required";

  ref($launch->convert) or confess "convert=>specification required";
  $launch->save //= q(save);                                                    # Default save folder

  if (my $r = ref $launch->convert)                                             # Conversion specification
   {if ($r =~ m(ARRAY))
     {my @convert = @{$launch->convert};
      for my $stage(@convert)
       {if (ref($stage) and ref($stage) =~ m(ARRAY))
         {@$stage >=  2 or
           confess "name=>sub required for stage, got: ".dump($stage);
          my ($name, $sub) = @$stage;
          ref($name) and
            confess "Scalar required for stage name, got: ". dump($name);
          ref($sub) && ref($sub) =~ m(\ACODE\Z) or
            confess "Code required for stage $name, got: ". dump($sub);
         }
        else
         {confess "[conversion stage name => conversion sub] required, got: ".
                   dump($stage);
         }
       }

      for my $convert(@convert)                                                 # Each conversion step
       {my ($stepName, $sub) = @$convert;                                       # Step name, processing sub

        $launch->stepNumberByName->{$stepName} and                              # Check each step has a unique name
          confess "Duplicate step name: $stepName";
        $launch->stepNumberByName->{$stepName} = @{$launch->stepsByNumber};     # Step number from name

        push @{$launch->stepsByNumber}, sub                                     # Conversion steps
         {my ($launch, $projectName) = @_;
          ref($launch)  =~ m(Data::Edit::Conversion)s or confess;
         !ref($projectName) or confess;
          my $S = time();                                                       # Start time
          my $R = $sub->($launch->projects->{$projectName}, $stepName);
          $launch->projects->{$projectName}->stepTimes->{$stepName} =           # Step processed in float seconds
            time() - $S;
          $launch->saveProject($projectName, $stepName);
          $R                                                                    # Return result of convertion
         };
       }
     }
    else                                                                        # Syntax
     {confess "Convert=>[[conversion stage name => conversion sub], ...]".
              " required, got: ".dump($launch->convert);
     }
   }

  return $launch;                                                               # Launch specification
 }

sub launch($;$$)                                                                # Launch the conversion of several files, each represented by a project, in parallel processes, saving the project state after each step of the conversion so that subsequent conversions can be restarted at later steps to speed up development by bypassing initial processing steps unless they are really needed. The L<data|/data> and L<stepTimes|/stepTimes> are transferred back from each project's sub process to the main calling process so that the main process can further process their results.
 {my ($launch, $title, $restart) = @_;                                          # Launch specification, optional title, optional name of latest step to restart at.
  my $projects = $launch->projects;
  my $mp       = $launch->maximumNumberOfProcesses //                           # Maximum number of simultaneous processes
                 defaultMaximumNumberOfProcesses;

  if (my $out = $launch->out)                                                   # Clear the output area if present
   {my $limit = $launch->outFileLimit // defaultOutFileLimit;
    clearFolder($out, $limit);
   }

  $_->stepTimes = {} for values %$projects;                                     # Reset step times

  if ($mp == 1)                                                                 # Process sequentially
   {for my $projectName(sort keys %$projects)                                   # Convert matching projects
     {$launch->launchProject($projectName, $restart);
     }
   }
  else                                                                          # Process in parallel
   {my $count = 0;
    for my $projectName(sort keys %$projects)                                   # Convert matching projects
     {wait if ++$count > $mp;                                                   # Wait for processes to finish
      $launch->launchProject($projectName, $restart), exit unless fork;         # Convert in parallel
     }
    for(;;) {last if wait == -1}                                                # Wait for conversions to complete

    if (1)                                                                      # Reload last good step to retrieve fully processed data
     {my @steps = reverse @{$launch->convert};                                  # Steps
      for my $projectName(sort keys %$projects)                                 # Projects
       {for my $step(@steps)                                                    # Find latest save file
         {my ($stepName) = @$step;
          my $file = $launch->stepSaveFile($projectName, $stepName);
          if (-e $file)                                                         # Retrive file
           {my $d = retrieve $file;
            $projects->{$projectName}->data      = $d->data;                    # Transfer data back so a good idea to put something meaningful here especially in the last step
            $projects->{$projectName}->stepTimes = $d->stepTimes;               # Transfer list of steps processed
            last;                                                               # Ignore earlier steps
           }
         }
       }
     }
   }
 }

sub restart($$;$)                                                               # Launch the conversion of several files represented by projects in parallel, starting at the specified step: the L<data|/data> from the previous step will be restored unless it does not exist in which case the conversion will be run from the latest step available prior to this step or right from the start.
 {my ($launch, $restart, $title) = @_;                                          # Launch specification, step to restart at, optional title

  defined($restart) or confess "No such step: $restart, choose from: ".         # No such restart step
      dump([sort keys %{$launch->stepNumberByName}]);

  $launch->launch($title // "Restart", $restart);                               # Launch with restart
 }

#1 Launch Attributes                                                            # Use these attributes to configure a launch.

genLValueScalarMethods(q(convert));                                             #I [[step name => sub]...] A list of steps and their associated subs to process that step. At the end of each step the data stored on L<data|/data> is saved to allow for a later restart at the next step.
genLValueScalarMethods(q(maximumNumberOfProcesses));                            #I Maximum number of processes to run in parallel
genLValueScalarMethods(q(out));                                                 #I Optional file output area.  This area will be cleared at the start of each launch.
genLValueScalarMethods(q(outFileLimit));                                        #I Limit on the number of files to be cleared from the L<out|/out> folder at the start of each launch.
genLValueScalarMethods(q(projects));                                            #I A reference to a hash of Data::Edit::Conversion::Project definitions. This can be most easily created by using L<loadProjectsFromFolder|/loadProjectsFromFolder>.
genLValueScalarMethods(q(save));                                                #I Temporary files will be stored in this folder
genLValueScalarMethods(q(stepNumberByName));                                    #O Get the number of a step from its name
genLValueArrayMethods (q(stepsByNumber));                                       #O Array of steps to be performed. The subs in this array call the user supplied subs after approriate set up and then do the required set down after the execution of each step.

sub stepSaveFile($$$)                                                           #P Save file for a project and a step
 {my ($launch, $projectName, $step) = @_;                                       # Launch specification, project, step name
  ref($launch)  =~ m(Data::Edit::Conversion)s or confess;
  !ref($projectName) or confess;
  fpe($launch->save, $projectName, $step, q(data))
 }

sub deleteProject($$$)                                                          #P Delete results before executing a particular step
 {my ($launch, $projectName, $step) = @_;                                       # Launch specification, project, step
  ref($launch)  =~ m(Data::Edit::Conversion)s or confess;
  !ref($projectName) or confess;
  my $file = $launch->stepSaveFile($projectName, $step);
  unlink $file;
 }

sub saveProject($$$)                                                            #P Save project at a particular step
 {my ($launch, $projectName, $step) = @_;                                       # Launch specification, project, step
  ref($launch)  =~ m(Data::Edit::Conversion)s or confess;
  !ref($projectName) or confess;
  my $file = $launch->stepSaveFile($projectName, $step);
  makePath $file;
  my $project = $launch->projects->{$projectName};
  store $project, $file;
 }

sub loadProject($$$)                                                            #P Load a project at a particular step
 {my ($launch, $projectName, $stepNumber) = @_;                                 # Launch specification, project, step to reload
  ref($launch)  =~ m(Data::Edit::Conversion)s or confess;
  !ref($projectName) or confess;
  my $step = $launch->convert->[$stepNumber][0];                                # Step anme from step number
  my $file = $launch->stepSaveFile($projectName, $step);
  -e $file or confess "No such file:\n$file";
  my $p    = retrieve $file;
  $p or confess "Unable to retrieve project save file:\n$file";
  $launch->projects->{$projectName} = $p;
 }

sub launchProject($$;$)                                                         #P Convert a single project in a seperate process
 {my ($launch, $projectName, $restart) = @_;                                    # Launch specification, project to be processed, optional latest step to restart at
  ref($launch)  =~ m(Data::Edit::Conversion)s or confess;
  !ref($projectName) or confess;
  my $projects = $launch->projects;                                             # Projects
  my $project  = $projects->{$projectName};                                     # Project
  $project or confess "No such project: $projectName";
  my $source  = $project->source;
  my $count   = 0;
  my $steps   = $launch->convert;                                               # Conversion steps
  my @steps   = @$steps;                                                        # All the steps for a complete project

  if ($restart)                                                                 # Remove steps we can skip in a restart because we have a restart file for that step
   {my $requested = $launch->stepNumberByName->{$restart};                      # Requested restart step number
    defined($requested) or confess "No such step: $restart, choose from: ".     # Missing step
      dump([sort keys %{$launch->stepNumberByName}]);
    my $actual;                                                                 # Actual restart step number
    for my $step(1..$requested)                                                 # Each possible restart step
     {my $stepName = $launch->convert->[$step-1][0];                            # Step name from step number
      my $save = $launch->stepSaveFile($projectName, $stepName);                # Save file
      last unless -e $save;                                                     # Have to start at the preceeding step if the required start file is missing for this step
      last if fileOutOfDate sub{1}, $save, $source;                             # Have to start at the preceeding step if the source file is newer than the start file
      $actual = $step-1;                                                        # Step we are going to restart at
      shift @steps;                                                             # Consider step as done
     }
    if (defined $actual)                                                        # Overlay saved project
     {$launch->loadProject($projectName, $actual);
      $launch->projects->{$projectName}->stepTimes = {};                        # Steps processed
     }
   }

  for my $step(@steps)                                                          # Remove subsequent save files
   {my ($stepName) = @$step;
    $launch->deleteProject($projectName, $stepName);
   }

  for my $step(@steps)                                                          # Each step in the conversion
   {my ($stepName, $code) = @$step;
    my $stepNumber = $launch->stepNumberByName->{$stepName};
    $launch->stepsByNumber->[$stepNumber]->($launch, $projectName);
   }
 } # launchProject

sub loadProjectsFromFolder($@)                                                  #S Create a project for file in and below the specified folder and return the projects created
 {my ($dir, @extensions) = @_;                                                  # Folder to search, list of file extensions to search for
  my @f = searchDirectoryTreesForMatchingFiles($dir, @extensions);
  my $p = {};                                                                   # Project hash
  for my $file(@f)
   {my (undef, $name, undef) = parseFileName($file);                            # Project name from file name
    $p->{$name} =                                                               # Create project definition
      Data::Edit::Conversion::Project::new(name=>$name, source=>$file);
   }
  bless $p, "Data::Edit::Conversion::Projects";                                 # Return hash of projects
 }

sub projectData($$)                                                             # Get L<data|/data> for a project after a launch has completed
 {my ($launch, $projectName) = @_;                                              # Launch specification, project
  $launch->projects->{$projectName}->data;
 }

sub projectSteps($$)                                                            # Get the L<steps times|/stepTimes> showing the executed time in seconds for each step in a project after a launch has completed. If a step name is not present in this hash then the step was not run.
 {my ($launch, $projectName) = @_;                                              # Launch specification, project
  $launch->projects->{$projectName}->stepTimes;
 }

package Data::Edit::Conversion::Project;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Storable;
use utf8;

my %projects;                                                                   # Prevent duplicate namea and number projects

#1 Project                                                                      # A project is one input file to be converted in one more restartable steps.

#2 Construction                                                                 # Methods used to construct projects

sub new                                                                         #S Create a project to describe the conversion of a source file containing xml representing documentation into one or more L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> topics.
 {my $p = bless{@_};
  $p->number = keys %projects;
  my $n = $p->name;
  my $s = $p->source;

  confess "No name for project\n"            unless $n;
  confess "Duplicate project: $n\n"          if $projects{$n};
  confess "No source file for project: $n\n" unless $s;
  confess "Source file does not exist: $s\n" unless -e $s;

  $projects{$n} = $p;
 }

#2 Attributes                                                                   # Attributes of a project
genLValueScalarMethods(q(name));                                                # Name of project.
genLValueScalarMethods(q(number));                                              # Number of the project.
genLValueScalarMethods(q(source));                                              # Input file containing the source xml.
genLValueScalarMethods(q(data));                                                # Per project data being converted
genLValueScalarMethods(q(stepTimes));                                           # Hash of steps processed during a launch
genLValueScalarMethods(q(test)) ;                                               # Whether this is a test project or not
genLValueScalarMethods(q(title));                                               # Title of the project.
genLValueScalarMethods(q(numberOfFileNamesRequested));                          # Number of files names requested by this project

#2 Methods                                                                      # Methods applicable to a project

my $stringToFileName;                                                           # Number of files created

sub stringToFileName($$$)                                                       # Create a unique file name from a specified string.
 {my ($project, $title, $ext) = @_;                                             # Project, string, desired extension - defaults to .dita
  my $N = $project->number;                                                     # Project number
  my $n = $project->numberOfFileNamesRequested++;                               # File number
  my $t = lc $title;                                                            # Edit out constructs that would produce annoying file names
     $t =~ s/\s+//gs;
     $t =~ s/&lt;.+?&gt;//gs;
     $t =~ s/<.+?>//gs;
     $t =~ s/[^a-zA-Z]//gs;                                                     # Readable ascii
  fpe(qq($t$N).qq(_$n), $ext);                                                  # Project numnber makes each file unique despite use of separate processes to run conversions
 }

package Data::Edit::Conversion;

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT_OK    = qw(
);
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Data::Edit::Conversion - Perform a restartable series of steps in parallel.

=head1 Synopsis

Launch the conversion of several files, each represented by a project, in
parallel processes, saving the project state after each step of the conversion
so that subsequent conversions can be restarted at later steps to speed up
development by bypassing initial processing steps unless they are really
needed. The L<data|/data> and L<stepTimes|/stepTimes> are transferred back
from each project's sub process to the main calling process so that the main
process can further process their results.

  use warnings FATAL=>qw(all);
  use strict;
  use Test::More tests=>90;
  use File::Touch;
  use Data::Edit::Conversion;

  my $N = 8;                                                                    # Number of test files == projects per launch

  makePath(my $inDir = q(in)); clearFolder($inDir, 20);                         # Create and clear folders

  my $tAge = File::Touch->new(mtime=>int time - 100);                           # Age file
     $tAge->touch(writeFile(fpe($inDir, $_, q(xml)), <<END)) for 1..$N;         # Create and age $N test files
  $_
  END

  my $convert = sub {my ($p) = @_; $p->data = $p->data =~ s(\s) ()gsr x 2};     # Convert one project

  my $l = Data::Edit::Conversion::new                                           # Convert $N projects in parallel
   (projects => Data::Edit::Conversion::loadProjectsFromFolder($inDir,qw(xml)),
    convert  =>
     [[load  => sub {my ($p) = @_; $p->data = readFile($p->source)}],           # Load a project
      [c1    => $convert],
      [c2    => $convert],
      [c3    => $convert],
     ],
    maximumNumberOfProcesses => $N,
   );

  my $verify = sub                                                              # Verify launch results
   {my (@stepsExecuted) = @_;                                                   # Steps that should have been executed
    ok $l->projectData($_) eq $_ x 8 for 1..$N;                                 # Check result of each conversion
    is_deeply [sort keys %{$l->projectSteps($_)}], [@stepsExecuted] for 1..$N;  # Check expected steps have been executed
   };

  $l->launch;           &$verify(qw(c1 c2 c3 load));                            # Full run
  $l->restart(q(load)); &$verify(qw(c1 c2 c3 load));                            # Restart the launch at various points
  $l->restart(q(c1));   &$verify(qw(c1 c2 c3));
  $l->restart(q(c2));   &$verify(qw(c2 c3));
  $l->restart(q(c3));   &$verify(qw(c3));

  File::Touch->new(mtime=>int time + 100)->touch(qq($inDir/1.xml));             # Renew source file to force all the steps to be redone despite requesting a restart
  $l->restart(q(c2), "After touch");
  ok $l->projectData($_) eq $_ x 8 for 1..$N;
  is_deeply [sort keys %{$l->projectSteps(1)}], [qw(c1 c2 c3 load)];
  is_deeply [sort keys %{$l->projectSteps(2)}], [qw(c2 c3)];

=head1 Description


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Methods

Specify and run the restartable conversion of zero or more files in parallel

=head2 new(@)

Create a conversion specification for zero or more files represented by projects.

     Parameter    Description
  1  @attributes  L</Launch attributes> describing the launch

This is a static method and so should be invoked as:

  Data::Edit::Conversion::new


=head2 launch($$$)

Launch the conversion of several files represented by projects in parallel

     Parameter  Description
  1  $launch    Launch specification
  2  $title     Optional title
  3  $restart   Optional name of latest step to restart at.

=head2 restart($$$)

Launch the conversion of several files represented by projects in parallel, starting at the specified step: the L<data|/data> from the previous step will be restored unless it does not exist in which case the conversion will be run from the latest step available prior to this step or right from the start.

     Parameter  Description
  1  $launch    Launch specification
  2  $restart   Step to restart at
  3  $title     Optional title

=head1 Launch Attributes

Use these attributes to configure a launch.

=head2 convert :lvalue

I [[step name => sub]...] A list of steps and their associated subs to process that step. At the end of each step the data stored on L<data|/data> is saved to allow for a later restart at the next step.


=head2 maximumNumberOfProcesses :lvalue

I Maximum number of processes to run in parallel


=head2 out :lvalue

I Optional file output area.  This area will be cleared at the start of each launch.


=head2 outFileLimit :lvalue

I Limit on the number of files to be cleared from the L<out|/out> folder at the start of each launch.


=head2 projects :lvalue

I A reference to a hash of Data::Edit::Conversion::Project definitions. This can be most easily created by using L<loadProjectsFromFolder|/loadProjectsFromFolder>.


=head2 save :lvalue

I Temporary files will be stored in this folder


=head2 stepNumberByName :lvalue

O Get the number of a step from its name


=head2 stepsByNumber :lvalue

O Array of steps to be performed. The subs in this array call the user supplied subs after approriate set up and then do the required set down after the execution of each step.


=head2 loadProjectsFromFolder($@)

Create a project for file in and below the specified folder and return the projects created

     Parameter    Description
  1  $dir         Folder to search
  2  @extensions  List of file extensions to search for

This is a static method and so should be invoked as:

  Data::Edit::Conversion::loadProjectsFromFolder


=head2 projectData($$)

Get L<data|/data> for a project after a launch has completed

     Parameter     Description
  1  $launch       Launch specification
  2  $projectName  Project

=head2 projectSteps($$)

Get the L<steps times|/stepTimes> showing the executed time in seconds for each step in a project after a launch has completed. If a step name is not present in this hash then the step was not run.

     Parameter     Description
  1  $launch       Launch specification
  2  $projectName  Project

=head1 Project

A project is one input file to be converted in one more restartable steps.

=head2 new()

Create a project to describe the conversion of a source file containing xml representing documentation into one or more L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> topics.


This is a static method and so should be invoked as:

  Data::Edit::Conversion::new


=head2 name :lvalue

I Name of project.


=head2 number :lvalue

I Number of the project.


=head2 source :lvalue

I Input file containing the source xml.


=head2 data :lvalue

O Per project data being converted


=head2 stepTimes :lvalue

O Hash of steps processed during a launch


=head2 title :lvalue

I Title of the project.



=head1 Private Methods

=head2 defaultMaximumNumberOfProcesses()

Default maximum number of processes to use during the conversion


=head2 defaultOutFileLimit()

Default maximum number of files to clear art a time.


=head2 stepSaveFile($$$)

Save file for a project and a step

     Parameter     Description
  1  $launch       Launch specification
  2  $projectName  Project
  3  $step         Step name

=head2 deleteProject($$$)

Delete results before executing a particular step

     Parameter     Description
  1  $launch       Launch specification
  2  $projectName  Project
  3  $step         Step

=head2 saveProject($$$)

Save project at a particular step

     Parameter     Description
  1  $launch       Launch specification
  2  $projectName  Project
  3  $step         Step

=head2 loadProject($$$)

Load a project at a particular step

     Parameter     Description
  1  $launch       Launch specification
  2  $projectName  Project
  3  $stepNumber   Step to reload

=head2 launchProject($$$)

Convert a single project in a seperate process

     Parameter     Description
  1  $launch       Launch specification
  2  $projectName  Project to be processed
  3  $restart      Optional latest step to restart at


=head1 Index


1 L<convert|/convert>

2 L<data|/data>

3 L<defaultMaximumNumberOfProcesses|/defaultMaximumNumberOfProcesses>

4 L<defaultOutFileLimit|/defaultOutFileLimit>

5 L<deleteProject|/deleteProject>

6 L<launch|/launch>

7 L<launchProject|/launchProject>

8 L<loadProject|/loadProject>

9 L<loadProjectsFromFolder|/loadProjectsFromFolder>

10 L<maximumNumberOfProcesses|/maximumNumberOfProcesses>

11 L<name|/name>

12 L<new|/new>

13 L<number|/number>

14 L<out|/out>

15 L<outFileLimit|/outFileLimit>

16 L<projectData|/projectData>

17 L<projects|/projects>

18 L<projectSteps|/projectSteps>

19 L<restart|/restart>

20 L<save|/save>

21 L<saveProject|/saveProject>

22 L<source|/source>

23 L<stepNumberByName|/stepNumberByName>

24 L<stepSaveFile|/stepSaveFile>

25 L<stepsByNumber|/stepsByNumber>

26 L<stepTimes|/stepTimes>

27 L<title|/title>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Data::Edit::Conversion

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2018 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;

1;
# podDocumentation
__DATA__
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>94;
use File::Touch;
#use Data::Edit::Conversion;

my $N = 8;                                                                      # Number of test files == projects per launch

makePath(my $inDir = q(in)); clearFolder($inDir, 20);                           # Create and clear folders

my $tAge = File::Touch->new(mtime=>int time - 100);                             # Age file
   $tAge->touch(writeFile(fpe($inDir, $_, q(xml)), <<END)) for 1..$N;           # Create and age $N test files
$_
END

my $convert = sub {my ($p) = @_; $p->data = $p->data =~ s(\s) ()gsr x 2};       # Convert one project

my $l = Data::Edit::Conversion::new                                             # Convert $N projects in parallel
 (projects => Data::Edit::Conversion::loadProjectsFromFolder($inDir,qw(xml)),
  convert  =>
   [[load  => sub {my ($p) = @_; $p->data = readFile($p->source)}],             # Load a project
    [c1    => $convert],
    [c2    => $convert],
    [c3    => $convert],
   ],
  maximumNumberOfProcesses => $N,
 );

my $verify = sub                                                                # Verify launch results
 {my (@stepsExecuted) = @_;                                                     # Steps that should have been executed
  ok $l->projectData($_) eq $_ x 8 for 1..$N;                                   # Check result of each conversion
  is_deeply [sort keys %{$l->projectSteps($_)}], [@stepsExecuted] for 1..$N;    # Check expected steps have been executed
 };

$l->launch;           &$verify(qw(c1 c2 c3 load));                              # Full run
$l->restart(q(load)); &$verify(qw(c1 c2 c3 load));                              # Restart the launch at various points
$l->restart(q(c1));   &$verify(qw(c1 c2 c3));
$l->restart(q(c2));   &$verify(qw(c2 c3));
$l->restart(q(c3));   &$verify(qw(c3));

File::Touch->new(mtime=>int time + 100)->touch(qq($inDir/1.xml));               # Renew source file to force all the steps to be redone despite requesting a restart
$l->restart(q(c2), "After touch");
ok $l->projectData($_) eq $_ x 8 for 1..$N;
is_deeply [sort keys %{$l->projectSteps(1)}], [qw(c1 c2 c3 load)];
is_deeply [sort keys %{$l->projectSteps(2)}], [qw(c2 c3)];

ok $l->projects->{1}->stringToFileName(qw(aaa xml)) eq q(aaa0_0.xml);           # Test string to file name
ok $l->projects->{2}->stringToFileName(qw(aaa xml)) eq q(aaa1_0.xml);
ok $l->projects->{1}->stringToFileName(qw(aaa xml)) eq q(aaa0_1.xml);
ok $l->projects->{2}->stringToFileName(qw(aaa xml)) eq q(aaa1_1.xml);
