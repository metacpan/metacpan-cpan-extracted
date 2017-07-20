#!/usr/bin/perl
#-I/home/phil/z/perl/cpan/DataTableText/lib
#-------------------------------------------------------------------------------
# Lint xml files in parallel using xmllint and report the failure rate
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------
# podDocumentation

package Data::Edit::Xml::Lint;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Table::Text qw(:all);
use Digest::SHA qw(sha256_hex);
use Encode;
our $VERSION = 2017.717;

#1 Constructor                                                                  # Construct a new linter

sub new                                                                         # Create a new xml linter - call this method statically as in Data::Edit::Xml::Lint::new()

 {bless {}                                                                      # Create xml linter
 }

#2 Attributes                                                                   # Attributes describing a lint

genLValueScalarMethods(qw(file));                                               # File that the xml will be written to and read from
genLValueScalarMethods(qw(catalog));                                            # Optional catalog file containing the locations of the DTDs used to validate the xml
genLValueScalarMethods(qw(dtds));                                               # Optional directory containing the DTDs used to validate the xml
genLValueScalarMethods(qw(errors));                                             # Number of lint errors detected by xmllint
genLValueScalarMethods(qw(linted));                                             # Date the lint was performed
genLValueScalarMethods(qw(project));                                            # Optional project name to allow error counts to be aggregated by project
genLValueScalarMethods(qw(processes));                                          # Maximum number of lint  processes to run in parallel - 8 by default
genLValueScalarMethods(qw(sha256));                                             # String containing the xml to be written or the xml read
genLValueScalarMethods(qw(source));                                             # String containing the xml to be written or the xml read

#1 Lint                                                                         # Lint xml files in parallel

my @pids;

sub lint($@)                                                                    # Store some xml in a file and apply xmllint in parallel
 {my ($lint, %attributes) = @_;                                                 # Linter, attributes to be recorded as xml comments

  if (1)                                                                        # Maximum amount of parallelism
   {my $processes = $lint->processes // 8;                                      # Maximum number of processes
    waitpid(pop @pids, 0) while @pids > $processes;                             # Wait until enough sub processes have completed
   }

  if (my $pid = fork())                                                         # Perform lints in parallel
   {push @pids, $pid;
    return;
   }
  my $x = $lint->source;                                                        # Xml text
  $x or confess "Use the ->source method to provide the source xml";            # Check that we have some source
  $lint->source = $x =~ s/\s+\Z//gsr;                                           # Xml text to be written minus trailing blanks

  my $f = $lint->file;                                                          # File to be written to
  $f or confess "Use the ->file method to provide the target file";             # Check that we have an output file

  my $C = $lint->catalog;                                                       # Catalog to be used to validate xml
  my $d = $lint->dtds;                                                          # Folder containing dtds used to validate xml
  my $P = $lint->project // 'unknown';                                          # Project name

  $attributes{file}    = $f;                                                    # Record attributes
  $attributes{catalog} = $C if $C;
  $attributes{dtds}    = $d if $d;
  $attributes{project} = $P if $P;
  $attributes{sha256} = sha256_hex(encode("ascii", $lint->source));             # Digest of source string

  my $a = sub                                                                   # Attributes to be recorded with the xml
   {my @s;
    for(sort keys %attributes)
     {push @s, "<!--${_}: ".$attributes{$_}." -->";                             # Place attribute inside a comment
     }
    join "\n", @s
   }->();

  my $T = "<!--linted: ".dateStamp." -->\n";                                    # Time stamp marks the start of the added comments

  writeFile($f, my $source = "$x\n$T\n$a");                                     # Write xml to file

  if (my $v = qx(xmllint --version 2>&1))                                       # Check xmllint is present
   {unless ($v =~ m(\Axmllint)is)
     {confess "xmllint missing, install with:\nsudo apt-get xmllint";
     }
   }

  my $c = sub                                                                   # Lint command
   {return "xmllint --path \"$d\" --noout --valid \"$f\" 2>&1" if $d;           # Lint against DTDs
    return qq(xmllint --noout - < '$f' 2>&1) unless $C;                         # Normal lint
    qq(export XML_CATALOG_FILES='$C' && xmllint --noout --valid - < '$f' 2>&1)  # Catalog lint
   }->();

  if (my @errors = qx($c))                                                      # Perform lint and add errors as comments
   {my $s = readFile($f);
    my $e = join '', map {chomp; "<!-- $_ -->\n"} @errors;
    my $n = $lint->errors = int @errors / 3;                                    # Three lines per error message

    my $t = "<!--errors: $n -->";

    writeFile($f, "$source\n$T$e\n$t");                                         # Update xml file with errors
   }
  else                                                                          # No errors detected
   {$lint->errors = 0;
   }
  exit;
 }

sub read($)                                                                     # Reload a linted xml file and extract attributes
 {my ($file) = @_;                                                              # File containing xml
  my $s = readFile($file);                                                      # Read xml from file

  my %a = $s =~ m/<!--(\w+):\s+(.+?)\s+-->/igs;                                 # Get attributes
          $s =~ s/\s+<!--linted:.+\Z//s;                                        # Remove generated comments at end

  my $lint = bless{%a, source=>$s};                                             # Create a matching linter
  $lint->errors //= 0;
  $lint                                                                         # Return a matching linter
 }

sub wait()                                                                      # Wait for all lints to finish

 {waitpid(pop @pids, 0) while @pids;                                            # Wait until sub processes have completed
 }

sub clear($@)                                                                   # Clear the results of a prior run
 {my ($outputDirectory, @fileExtensions) = @_;                                  # Directory to clear, extensions of files to remove
  for my $dir($outputDirectory)                                                 # Directory
   {for my $ext(@fileExtensions)                                                # Extensions
     {unlink $_ for fileList(filePathExt($dir, qq(*), $ext));
     }
   }
 }

#1 Report                                                                       # Methods for reporting the results of linting several files

sub p4($$)                                                                      ## Format a fraction as a percentage to 4 decimal places
 {my ($p, $f) = @_;
  my $n = $p + $f;
  $n > 0 or confess "Division by zero";
  my $r = sprintf("%3.4f", 100 * $p / $n);
  $r =~ s/\.0+\Z//gsr                                                           # Remove trailing zeroes
 }

sub report($@)                                                                  # Analyse the results of prior lints and return a hash reporting various statistics and a printable report
 {my ($outputDirectory, @fileExtensions) = @_;                                  # Directory to clear, types of files to analyze
  my @x;                                                                        # Lints for all files
  for my $dir($outputDirectory)                                                 # Directory
   {for my $ext(@fileExtensions)                                                # Extensions
     {for my $in(fileList(filePathExt($dir, qq(*), $ext)))
       {push @x, Data::Edit::Xml::Lint::read($in);                              # Reload a previously written file
       }
     }
   }

  my %projects;                                                                 # Pass/Fail by project
  my %files;                                                                    # Pass fail by file
  my %filesToProjects;                                                          # Project from file name

  for my $x(@x)                                                                 # Aggregate the results of individual lints
   {my $project = $x->project // 'unknown';
    my $file    = $x->file;
    my $errors  = $x->errors;
    $filesToProjects{$file} = $project;
    my $pf = $errors ? qq(fail) : qq(pass);
    $projects{$project}{$pf}++;
    $files   {$file} = $errors;
   }

  my @project;
  for my $project(sort keys %projects)                                          # Count pass/fail files by project
   {my $p = $projects{$project}{pass} // 0;
    my $f = $projects{$project}{fail} // 0;
    push @project, [$project, $p, $f, p4($p, $f)];
   }
  @project = sort {$a->[3] <=> $b->[3]} @project;

  my $totalNumberOfFails   = scalar grep {$files{$_}  > 0} keys %files;
  my $totalNumberOfPasses  = scalar grep {$files{$_} == 0} keys %files;
  my $totalPassFailPercent = p4($totalNumberOfPasses, $totalNumberOfFails);
  my $ts = dateTimeStamp;
  my $numberOfProjects = keys %projects;
  my $numberOfFiles    = $totalNumberOfPasses + $totalNumberOfFails;

  my @report;
  push @report, <<END;                                                          # Report title
$totalPassFailPercent % success converting $numberOfProjects projects containing $numberOfFiles xml files on $ts

ProjectStatistics
   #  Percent   Pass  Fail  Total  Project
END
  for(1..@project)                                                              # Project statistics
   {my ($project, $pass, $fail, $percent) = @{$project[$_-1]};
    push @report, sprintf("%4d %8.4f   %4d  %4d  %5d  %s\n",
      $_, $percent, $pass, $fail, $pass+$fail, $project);
   }

  my @filesFail = sort {$a->[0] <=> $b->[0]}                                    # Failing files
                  map {[$files{$_}, $filesToProjects{$_}, $_]}
                  grep {$files{$_} > 0}
                  keys %files;

  if (my $filesFail = @filesFail)                                               # Failing files report
   {push @report, <<END;

$filesFail FailingFiles
   #  Errors  Project       File
END
    for(1..@filesFail)
     {push @report, sprintf("%4d  %6d  %-12.12s  %s\n", $_,@{$filesFail[$_-1]});
     }
   }

  return bless                                                                  # Return report
   {passRatePercent  =>$totalPassFailPercent,
    timestamp        =>$ts,
    numberOfProjects =>$numberOfProjects,
    numberOfFiles    =>$numberOfFiles,
    failingFiles     =>[@filesFail],
    print            =>(join '', @report),
   }, 'Data::Edit::Xml::Lint::Report';
 }

#2 Attributes

if (1)
 {package Data::Edit::Xml::Lint::Report;
  use Data::Table::Text qw(:all);
  genLValueScalarMethods(qw(passRatePercent));                                  # Total number of passes as a percentage of all input files
  genLValueScalarMethods(qw(timestamp));                                        # Timestamp of report
  genLValueScalarMethods(qw(numberOfProjects));                                 # Number of projects defined - each project can contain zero or more files
  genLValueScalarMethods(qw(numberOfFiles));                                    # Number of files encountered
  genLValueScalarMethods(qw(failingFiles));                                     # Array of [number of errors, project, file] ordered from least to most errors
  genLValueScalarMethods(qw(print));                                            # A printable report of the above
 }

# Tests and documentation

sub test{eval join('', <Data::Edit::Xml::Lint::DATA>) or die $@}                ## Test

test unless caller;

#extractDocumentation() unless caller();                                        ## podDocumentation

1;

=pod

=encoding utf-8

=head1 Name

Data::Edit::Xml::Lint - Lint xml files in parallel using xmllint and report the
failure rate

=head1 Synopsis

Create some sample xml files, some with errors, lint them in parallel
and retrieve the number of errors and failing files:

  for my $n(1..$N)                                                              # Some projects
   {my $x = Data::Edit::Xml::Lint::new();                                       # New xml file linter

    my $catalog = $x->catalog = catalogName;                                    # Use catalog if possible
    my $project = $x->project = projectName($n);                                # Project name
    my $file    = $x->file    =    fileName($n);                                # Target file

    $x->source = <<END;                                                         # Sample source
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//HPE//DTD HPE DITA Concept//EN" "concept.dtd" []>
<concept id="$project">
 <title>Project $project</title>
 <conbody>
   <p>Body of $project</p>
 </conbody>
</concept>
END

    $x->source =~ s/id="\w+?"//gs if addError($n);                              # Introduce an error into some projects

    $x->lint(foo=>1);                                                           # Write the source to the target file, lint using xmllint, include some attributes to be included as comments at the end of the target file
   }

  Data::Edit::Xml::Lint::wait;                                                  # Wait for lints to complete

  for my $n(1..$N)                                                              # Check each linted file
   {my $x = Data::Edit::Xml::Lint::read(fileName($n));                          # Reload the linted file
    ok $x->{foo}   == 1;                                                        # Check the reloaded attributes
    ok $x->project eq projectName($n);                                          # Check project name for file
    ok $x->errors  == addError($n);                                             # Check errors in file
   }

  my $report = Data::Edit::Xml::Lint::report($outDir, "xml");                   # Report total pass fail rate
  ok $report->passRatePercent  == 50;
  ok $report->numberOfProjects ==  3;
  ok $report->numberOfFiles    == $N;
  say STDERR $report->print;                                                    # Print report
 }

Produces:

 50 % success converting 3 projects containing 10 xml files on 2017-07-13 at 17:43:24

 ProjectStatistics
    #  Percent   Pass  Fail  Total  Project
    1  33.3333      1     2      3  aaa
    2  50.0000      2     2      4  bbb
    3  66.6667      2     1      3  ccc

 FailingFiles
    #  Errors  Project       File
    1       1  ccc           out/ccc5.xml
    2       1  aaa           out/aaa9.xml
    3       1  bbb           out/bbb1.xml
    4       1  bbb           out/bbb7.xml
    5       1  aaa           out/aaa3.xml


=head1 Description

=head2 Constructor

Construct a new linter

=head3 new

Create a new xml linter - call this method statically as in Data::Edit::Xml::Lint::new()


=head3 Attributes

Attributes describing a lint

=head4 file :lvalue

File that the xml will be written to and read from


=head4 catalog :lvalue

Optional catalog file containing the locations of the DTDs used to validate the xml


=head4 dtds :lvalue

Optional directory containing the DTDs used to validate the xml


=head4 errors :lvalue

Number of lint errors detected by xmllint


=head4 linted :lvalue

Date the lint was performed


=head4 project :lvalue

Optional project name to allow error counts to be aggregated by project


=head4 processes :lvalue

Maximum number of lint  processes to run in parallel - 8 by default


=head4 sha256 :lvalue

String containing the xml to be written or the xml read


=head4 source :lvalue

String containing the xml to be written or the xml read


=head2 Lint

Lint xml files in parallel

=head3 lint

Store some xml in a file and apply xmllint in parallel

     Parameter    Description
  1  $lint        Linter
  2  %attributes  Attributes to be recorded as xml comments

=head3 read

Reload a linted xml file and extract attributes

     Parameter  Description
  1  $file      File containing xml

=head3 wait()

Wait for all lints to finish


=head3 clear

Clear the results of a prior run

     Parameter         Description
  1  $outputDirectory  Directory to clear
  2  @fileExtensions   Extensions of files to remove

=head2 Report

Methods for reporting the results of linting several files

=head3 report

Analyse the results of prior lints and return a hash reporting various statistics and a printable report

     Parameter         Description
  1  $outputDirectory  Directory to clear
  2  @fileExtensions   Types of files to analyze

=head3 Attributes

=head4 passRatePercent :lvalue

Total number of passes as a percentage of all input files


=head4 timestamp :lvalue

Timestamp of report


=head4 numberOfProjects :lvalue

Number of projects defined - each project can contain zero or more files


=head4 numberOfFiles :lvalue

Number of files encountered


=head4 failingFiles :lvalue

Array of [number of errors, project, file] ordered from least to most errors


=head4 print :lvalue

A printable report of the above



=head1 Index


L<catalog|/catalog>

L<clear|/clear>

L<dtds|/dtds>

L<errors|/errors>

L<failingFiles|/failingFiles>

L<file|/file>

L<lint|/lint>

L<linted|/linted>

L<new|/new>

L<numberOfFiles|/numberOfFiles>

L<numberOfProjects|/numberOfProjects>

L<passRatePercent|/passRatePercent>

L<print|/print>

L<processes|/processes>

L<project|/project>

L<read|/read>

L<report|/report>

L<sha256|/sha256>

L<source|/source>

L<timestamp|/timestamp>

L<wait()|/wait()>

=head1 Installation

This module is written in 100% Pure Perl and is thus easy to read, use, modify
and install.

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut
# podDocumentation
# pod2html --infile=lib/Data/Edit/Xml/Lint.pm --outfile=zzz.html

__DATA__
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>33;

#Test::More->builder->output("/dev/null");                                      # Show only errors during testing - but this must be commented out for production

my $outDir = "out";                                                             # Output directory

sub projectName($) {(qw(aaa bbb ccc))[$_[0] % 3]}                               # Generate a project name

sub fileName($)                                                                 # Target file
 {my ($n) = @_;
  my $project = projectName($n);
  filePathExt($outDir, $project.$n, qq(xml))
 }

sub addError($) {$_[0] % 2}                                                     # Introduce an error into some projects

sub catalogName {filePathExt(qw(/home phil hp dtd Dtd_2016_07_12 catalog-hpe xml))} # Possible catalog

if (1)
 {my $N      = 10;                                                              # Number of tests
  Data::Edit::Xml::Lint::clear($outDir, "xml");                                 # Remove results of last run

  for my $n(1..$N)                                                              # Some projects
   {my $x = Data::Edit::Xml::Lint::new();                                       # New xml file linter
    my $catalog = $x->catalog = catalogName;                                    # Use catalog if possible
    my $project = $x->project = projectName($n);                                # Project name
    my $file    = $x->file    =    fileName($n);                                # Target file

    $x->source = <<END;                                                         # Sample source
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//HPE//DTD HPE DITA Concept//EN" "concept.dtd" []>
<concept id="$project">
 <title>Project $project</title>
 <conbody>
   <p>Body of $project 𝝰</p>
 </conbody>
</concept>
END

    $x->source =~ s/id="\w+?"//gs if addError($n);                              # Introduce an error into some projects

    $x->lint(foo=>1);                                                           # Write the source to the target file, lint using xmllint, include some attributes to be included as comments at the end of the target file
   }

  Data::Edit::Xml::Lint::wait;                                                  # Wait for lints to complete

  for my $n(1..$N)                                                              # Check each linted file
   {my $x = Data::Edit::Xml::Lint::read(fileName($n));                          # Reload the linted file
    ok $x->{foo}   == 1;                                                        # Check the reloaded attributes
    ok $x->project eq projectName($n);                                          # Check project name for file
    ok $x->errors  == addError($n);                                             # Check errors in file
   }

  my $report = Data::Edit::Xml::Lint::report($outDir, "xml");                   # Report total pass fail rate
  ok $report->passRatePercent  == 50;
  ok $report->numberOfProjects ==  3;
  ok $report->numberOfFiles    == $N;
# say STDERR $report->print;                                                    # Print report

  Data::Edit::Xml::Lint::clear($outDir, "xml");                                 # Remove results of last run
  rmdir $outDir;
 }
