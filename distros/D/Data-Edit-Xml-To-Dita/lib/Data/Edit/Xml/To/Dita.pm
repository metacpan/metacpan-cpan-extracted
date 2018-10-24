#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Data::Edit::Xml::To::Dita - Convert multiple Xml documents in parallel to Dita
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018
#-------------------------------------------------------------------------------
# podDocumentation

package Data::Edit::Xml::To::Dita;
our $VERSION = "2018-10-04+111";
require v5.16;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Edit::Xml;
use Data::Edit::Xml::Lint;
use Data::Edit::Xml::Xref;
use Data::Table::Text qw(:all);
use Flip::Flop;
use Scalar::Util qw(blessed);
use utf8;

#D1 Convert Xml to the Dita standard.                                           # Convert Xml to the Dita standard.

sub testDocuments  {qw()}                                                       # List of production documents to test in development or () for normal testing locally or normal production if on Aws.

sub upload         {!&develop}                                                  # Upload to S3 if true.
sub download       {!&develop}                                                  # Download from S3 if true.
sub unicode        {1}                                                          # Convert to utf8 if true.
sub convert        {1}                                                          # Convert documents to dita if true.
sub lint           {1}                                                          # Lint output xml if true or write directly if false.

sub catalog        {q(/home/phil/r/dita/dita-ot-3.1/catalog-dita.xml)}          # Dita catalog to be used for linting.
sub clearCount     {&develop ? 1e3 : 1e6}                                       # Limit on number of files to clear from each output folder.
sub develop        {-e q(/home/ubuntu/) ? 0 : 1}                                # Production run if this file folder is detected otherwise development.
sub devShm         {fpd(qw(/dev shm))}                                          # Shared memory folder for output files.
sub devShmOrHome   {develop ? &home : devShm}                                   # Shared memory folder or home folder.
sub downloads      {fpd(devShmOrHome, q(download))}                             # Downloads folder.
sub inputExt       {qw(.xml .dita)}                                             # Extension of input files.
sub gathered       {fpd(devShmOrHome, q(gathered))}                             # Folder containing saved parse trees after initial parse and information gathering.
sub home           {&getHome}                                                   # Home folder containing all the other folders
sub in             {fpd(devShmOrHome, q(in))}                                   # Input documents folder.
sub out            {fpd(devShmOrHome, q(out))}                                  # Converted documents output folder.
sub parseCache     {fpd(devShmOrHome, q(parseCache))}                           # Cached parse trees
sub process        {fpd(devShmOrHome, q(process))}                              # Process data folder used to communicate results between processes.
sub reports        {fpd(devShmOrHome, q(reports))}                              # Reports folder.
sub s3Bucket       {undef}                                                      # Bucket on S3 holding documents to convert and the converted results.
sub s3FolderIn     {q(in)}                                                      # Folder on S3 containing original documents.
sub s3FolderUp     {q(out)}                                                     # Folder on S3 containing results of conversion.
sub s3Parms        {q(--quiet --delete)}                                        # Additional S3 parameters for uploads and downloads.
sub summaryFile    {fpe(reports, qw(summary txt))}                              # Summary report file.
sub tests          {in}                                                         # Folder containing test files.
sub testResults    {fpd(home, qw(testResults))}                                 # Folder containing test results expected.

my $startTime      = time;                                                      # Start time.
my $endTime;                                                                    # End time value.
my $runTime;                                                                    # Run time value.
sub startTime      {$startTime}                                                 # Start time of run in seconds since the epoch.
sub endTime        {$endTime}                                                   # End time of run in seconds since the epoch.
sub runTime        {$runTime}                                                   # Elapsed run time in seconds.

sub maximimumNumberOfProcesses {develop ? 16 : 256}                             # Maximum number of processes to run in parallel.
sub maximumFileFromTitleLength {50}                                             # Maximum amount of title to use in constructing output file names.

my  $projects;                                                                  # Projects == documents to convert
our $project;                                                                   # Visible, thus loggable

my $home;
sub getHome                                                                     #P Compute home directory once
 {return $home if $home;
  my $c = currentDirectory;
  return $home = $c if $c =~ m(\A/home/phil/perl/cpan/)s;
  $home = sumAbsAndRel($c, "../");
 }

#D2 Methods                                                                     # Methods defined in this package.

sub lll(@)                                                                      #r Log messages including the project name if available
 {my (@m) = @_;                                                                 # Messages
  my $m = join '', dateTimeStamp, " ", @_;                                      # Time stamp each message
     $m =~ s(\s+) ( )gs;
  if ($project)
   {$m .= " in project $project";
   }
  my ($p, $f, $l) = caller();
  $m .= " at $f line $l\n";

  say STDERR $m;
 }

sub downloadFromS3                                                              #r Download documents from S3 to the L<downloads|/downloads> folder.
 {if (download)                                                                 # Download if requested
   {lll "Download from S3";
    clearFolder(downloads, clearCount);
    makePath(downloads);
    my $b = s3Bucket;
    my $d = downloads;
    my $f = s3FolderIn;
    my $p = s3Parms;
    my $c = qq(aws s3 sync s3://$b/$f $d $p);
    xxx $c;
    Flip::Flop::download();
   }
  else
   {lll "Download from S3 not requested";
   }
 }

sub convertToUTF8                                                               #r Convert the encoding of documents in L<downloads|/downloads> to utf8 equivalents in folder L<in|/in>.
 {my $n = 0;
  if (unicode)
   {lll "Unicode conversion";
    my $d = downloads;
    my $i = in;
    clearFolder(in, clearCount);
    for my $source(searchDirectoryTreesForMatchingFiles(downloads, inputExt))
     {my $target = swapFilePrefix($source, downloads, in);
      makePath($target);
      my $type = trim(qx(enca -iL none "$source"));
      my $c    = qx(iconv -f $type -t UTF8 -o "$target" "$source");
      ++$n;
      if (1)                                                                    # Change encoding
       {my $s = readFile($target);
        my $S = $s =~ s(encoding="[^"]{3,16}") (encoding="UTF-8")r;
        owf($target, $S) unless $S eq $s;
       }
     }
    lll "Unicode conversion applied to $n files";
   }
  else
   {lll "Unicode conversion not requested";
   }

  Flip::Flop::unicode();
  $n
 }

sub projectCount()                                                              #r Number of projects to process.
 {scalar keys %$projects
 }

sub Project                                                                     #r Project details including at a minimum the name of the project and its source file.
 {my ($name, $source) = @_;                                                     # Project name, source file

  confess "No name for project\n"          unless $name;
  confess "No source for project: $name\n" unless $source;
  if (my $q = $$projects{$name})
   {my $Q = $q->source;
    confess "Duplicate project: $name\n$source\n$Q\n";
   }
  confess "Source file does not exist:\n$source\n" unless -e $source;

  my $p = genHash(q(Project),                                                   # Project definition
    id         => undef,                                                        # Id attribute value from outermost tag
    isMap      => undef,                                                        # Map
    name       => $name,                                                        # Name of project
    number     => projectCount + 1,                                             # Number of project
    outputFile => undef,                                                        # Output file
    source     => $source,                                                      # Input file
    title      => undef,                                                        # Title for project
    topicId    => undef,                                                        # Topic id for project - collected during gather
   );

  $projects->{$p->name} = $p;                                                   # Save project definition
 }

sub loadProjects                                                                #r Locate documents to convert from folder L<in|/in>.
 {my @p = searchDirectoryTreesForMatchingFiles(in,    inputExt);                # Production documents
  my @t = searchDirectoryTreesForMatchingFiles(tests, inputExt);                # Test documents
  if (my %t = map {$_=>1} testDocuments)                                        # Locate documents to be tested
   {for my $file(@p, @t)                                                        # Favor production over test because test is easier to run in bulk
     {my $name = fn $file;
      next unless $t{$name};                                                    # Skip unless name matches
      next if $projects->{$name};                                               # Skip if we already have a document to test
      Project($name, $file);
     }
   }
  else                                                                          # Choose documents in bulk
   {for my $file(develop ? @t : @p, inputExt)
     {my $name  = fn $file;
      Project($name, $file);
     }
   }
 }

sub Project::by($$$)                                                            # Process parse tree with checks to confirm features
 {my ($project, $x, $sub) = @_;                                                 # Project, node, sub
  $x->by($sub);
 }

sub Project::formatXml($$)                                                      # Output file for a document
 {my ($project, $x) = @_;                                                       # Project, parse tree
  $x->prettyStringDitaHeaders;
 }

sub stringToFileName($)                                                         #r Convert a title string to a file name
 {my ($string) = @_;                                                            # String
  $string =~ s(\.\.\.)        (_)gs;
  $string =~ s([%@#*?“'"|,.]) (_)gs;
  $string =~ s([&\+~\/\\:=])  (-)gs;
  $string =~ s([<\[])         (\x28)gs;
  $string =~ s([>\]])         (\x29)gs;
  $string =~ s(\s+)           (_)gs;

  my $r = lc firstNChars $string, maximumFileFromTitleLength;
  $r
 }

sub md5Sum($)                                                                   #P Md5 sum for a file
 {my ($file) = @_;                                                              # File
  my $s = qx(md5sum $file);
  (split /\s+/, $s)[0];
 }

sub Project::parseCacheFile($)                                                  #P Name of the file in which to cache parse trees
 {my ($project) = @_;                                                           # Project
  my $s = $project->source;
  my $m = md5Sum($s);
  fpe(parseCache, $m, q(data));
 }

sub Project::parse($)                                                           #P Parse a project.
 {my ($project) = @_;                                                           # Project
  my $projectName = $project->name;

  my $c = $project->parseCacheFile;                                             # Cache parse file name

  if (-e $c)                                                                    # Reuse cached parse if available
   {return retrieveFile($c);
   }

  my $x = eval {Data::Edit::Xml::new($project->source)};                        # Parse the source
  if ($@)
   {confess join '', "Failed to parse $projectName\n",
            $project->source, "\n", $@, "\n";
   }

  storeFile($c, $x);                                                            # Cache parse

  $x
 }

sub gatheredFile($)                                                             #r Save file for parse tree after initial parse and gather
 {my ($project) = @_;                                                           # Project == document to convert
  fpe(gathered, $project->number, q(data))
 }

sub gatherProject($)                                                            #r Gather some information from each project
 {my ($project) = @_;                                                           # Project == document to convert
  my $projectName = $project->name;
  lll "Gather";                                                                 # Title of each conversion

  my $x = $project->parse;                                                      # Parse file
  $project->isMap   = $x->tag =~ m(map\Z)is;                                    # Map file
  $project->topicId = $x->id;                                                   # Topic Id

  $x->by(sub                                                                    # Locate title and hence output file
   {my ($t) = @_;
    if ($t->at_title)
     {my $T = $project->title = $t->stringContent;
      $project->outputFile = stringToFileName($T);
     }
   });

  storeFile gatheredFile($project), $x;                                         # Save parse tree - separately because it is large.

  $project                                                                      # Gathered information about a project
 }

sub numberOutputFiles                                                           #r Add deduplicating numbers to output files names that would otherwise be the same.
 {my %o;
  for my $P(sort keys %$projects)
   {my $p = $projects->{$P};
    if (my $o = $p->outputFile)
     {if (my $n = $o{$o}++)
       {$p->outputFile .= q(_).$n;
       }
     }
    else
     {confess "No output file for project source:\n", $p->source, "\n";
     }
   }
 }

sub convertDocument($$)                                                         #r Convert one document.
 {my ($project, $x) = @_;                                                       # Project == document to convert, parse tree.
 }

sub convertProject($)                                                           #r Convert one document held in folder L<in|/in> into topic files held in L<out|/out>.
 {my ($project) = @_;                                                           # Project == document to convert
  my $projectName = $project->name;

  lll "Convert";                                                                # Title of each conversion

  my $x = retrieveFile(gatheredFile $project);                                  # Reload parse into this process

  convertDocument($project, $x);                                                # Convert document

  my $o = fpe(out, $project->outputFile, q(dita));                              # File to write to

  if (lint)                                                                     # Lint
   {my $l = Data::Edit::Xml::Lint::new();                                       # Write and lint topic
    $l->project = $project->name;                                               # Project name
    $l->catalog = catalog;                                                      # Catalog
    $l->file    = $o;                                                           # File to write to
    $l->source  = $project->formatXml($x);                                      # Format source and add headers
    $l->lintNOP;                                                                # Lint
   }
  else                                                                          # Write without lint
   {my $f = $project->outputFile;
    writeFile($o, $project->formatXml($x));
   }

  $project                                                                      # Conversion succeeded for project
 }

sub lintResults                                                                 #r Lint results held in folder L<out|/out>and write reports to folder L<reports|/reports>.
 {if (lint)                                                                     # Only if lint requested
   {lll "Lint results";
    clearFolder(reports, clearCount);                                           # Clear prior run

    my $xref = Data::Edit::Xml::Xref::xref(inputFolder=>out, reports=>reports); # Check any cross references
    if (my $report = Data::Edit::Xml::Lint::report(out, qr(dita|ditamap|xml)))
     {my $r = $report->print;
      my $d = dateTimeStamp;
      my $h = home;
      my $b = s3Bucket;
      my $B = $b && upload ?
        qq(\n\nPlease see: aws s3 sync s3://$b ?\n\n) :
        qq();
      my $x =                                                                   # Include xref results
      ˢ{my $s = $xref->statusLine;
        return "\n\n$s"  if $s;
        q()
       };

      my $s = <<END;                                                            # rrrr
Summary of passing and failing projects on $d.\t\tVersion: $VERSION$B

$r
$x
END
      say STDERR $s;
      writeFile(summaryFile, $s);
      Flip::Flop::lint();
     }
    else
     {lll "No Lint report available";
     }
   }
  else
   {lll "Lint report not requested";
   }
 }

sub uploadToS3                                                                  #r Send results to S3 from folder L<out|/out>.
 {if (upload)
   {lll "Upload to S3";
    my $h = home;
    my $b = s3Bucket;
    my $f = s3FolderUp;
    my $p = s3Parms;
    my $c = qq(aws s3 sync $h $b/$f $p);
    say STDERR $c;
    print STDERR $_ for qx($c);
    say STDERR qq(Please see:  aws s3 sync $b/$f ?);
    Flip::Flop::uploadToS3();                                                   # Reset upload flip flop
   }
  else
   {lll "Upload to S3 not requested";
   }
 }

my @failedTests;                                                                # Failing tests
my @passedTests;                                                                # Passed tests
my @availableTests;                                                             # Available Tests

sub runTests                                                                    #r Run tests by comparing files in folder L<out|/out> with corresponding files in L<testResults|/testResults>.
 {if (develop)                                                                  # Run tests if developing
   {&checkResults;
    my $F = join " ", @failedTests;
    my $f = @failedTests;
    my $p = @passedTests;
    my $a = @availableTests;
    say STDERR "Failed tests: $F" if @failedTests;
    $p + $f == $a or warn "Passing plus failing tests".
     " not equal to tests available: $p + $f != $a";
    say STDERR "Tests: $p+$f == $a pass+fail==avail";
   }
 }

sub nwsc($)                                                                     #r Normalize white space and remove comments
 {my ($string) = @_;                                                            # Text to normalize
  $string =~ s(<\?.*?\?>)  ()gs;
  $string =~ s(<!--.*?-->) ()gs;
  $string =~ s(<!DOCTYPE.+?>)  ()gs;
  $string =~ s( (props|id)="[^"]*") ()gs;
  nws($string);
 }

sub testResult($$$)                                                             #r Evaluate the results of a test
 {my ($file, $got, $expected) = @_;                                             # File, what we got, what we expected result
  my $f = fpe(tests, $file, q(dita));                                           # Actual result
  my $g = nwsc($got);
  my $e = nwsc($expected);

  if ($e !~ m(\S)s)                                                             # Blank test file
   {confess "Test $file is all blank";
   }

  if ($g eq $e)                                                                 # Compare got with expected and pass
   {push @passedTests, $file;
    return 1;
   }
  else                                                                          # Not as expected
   {push @failedTests, $file;
    my @g = grep {!/\A\s*(<!|<\?)/} split /\n/, readFile($f);
    my @e = grep {!/\A\s*(<!|<\?)/} split /\n/, $expected;
    shift @g, shift @e while @g and @e and nwsc($g[0]) eq nwsc($e[0]);
    cluck "Got/expected in test $file:\n".
          "Got:\n". $g[0].
          "\nExpected:\n". $e[0]. "\n";
    return 0;
   }
 }

sub checkResults                                                                #r Send results to S3 from folder L<out|/out>.
 {for my $expected(searchDirectoryTreesForMatchingFiles(testResults))
   {my $got  = swapFilePrefix($expected, testResults, out);
    my $test = fn $expected;
    push @availableTests, $test;
    if (-e $got)
     {testResult($test, readFile($got), readFile($expected));
     }
   }
 }

sub gatherSelectedProjects                                                      #r Gather information from the selected project by reading their source files held in the L<in|/in>.
 {lll "Gather selected projects";
  my $ps = newProcessStarter(maximimumNumberOfProcesses, process);              # Process starter

  for(sort keys %$projects)                                                     # Gather information from each project
   {$ps->start(sub{gatherProject($projects->{$_})});
   }

  if (my @results = $ps->finish)                                                # Consolidate results
   {reloadHashes(\@results);                                                    # Recreate attribute methods
    my %togather = %$projects;
    for my $project(@results)                                                   # Each result
     {my $projectName = $project->name;                                         # Project name
      if (my $p = $$projects{$projectName})                                     # Find project
       {$$projects{$projectName} = $project;                                    # Consolidate information gathered
        delete $togather{$projectName};                                         # Mark project as gathered
       }
      else                                                                      # Confess to invalid project
       {confess "Unknown gathered project $projectName";
       }
     }
    if (my @f = sort keys %togather)                                            # Confess to projects that failed to gather
     {confess "The following projects failed to gather:\n", join (' ', @f);
     }
   }
 }

sub convertSelectedProjects                                                     #r Convert the selected documents by reading their source in L<in|/in>, converting them and writing the resulting topics to L<out|/out>.
 {lll "Converted selected projects";
  my $ps = newProcessStarter(maximimumNumberOfProcesses, process);              # Process starter

  for $project(sort keys %$projects)                                            # Convert projects
   {$ps->start(sub{convertProject($projects->{$project})});                     # Convert each project in a separate process
   }

  if (my @results = $ps->finish)                                                # Consolidate results
   {reloadHashes(\@results);                                                    # Recreate attribute methods
    my %toConvert = %$projects;
    for my $project(@results)                                                   # Each result
     {my $projectName = $project->name;                                         # Converted project name
      if (my $p = $$projects{$projectName})                                     # Find project
       {$$projects{$projectName} = $project;                                    # Consolidate information gathered
        delete $toConvert{$projectName};                                        # Mark project as converted
       }
      else                                                                      # Confess to invalid project
       {confess "Unknown converted project $projectName";
       }
     }
    if (my @f = sort keys %toConvert)                                           # Confess to projects that failed to convert
     {confess "The following projects failed to convert:\n", join (' ', @f);
     }
   }
 }

sub convertProjects                                                             #r Convert the selected documents.
 {if (convert)                                                                  # Convert the documents if requested.
   {lll "Convert documents";
    clearFolder($_, clearCount) for out, process;                               # Clear output folders
    loadProjects;                                                               # Projects to run
    gatherSelectedProjects;                                                     # Gather information about each project
    numberOutputFiles;                                                          # Deduplicate output file names
    my @r = convertSelectedProjects                                             # Convert selected projects
    Flip::Flop::convert();                                                      # Reset conversion flip flop
    return @r;                                                                  # Return results of conversions
   }
  else
   {lll "Convert documents not requested";
   }

  ()
 }

sub replaceableMethods                                                          #P Replaceable methods
 {qw(Project checkResults convertDocument convertProject convertProjects
convertSelectedProjects convertToUTF8 downloadFromS3 gatherProject
gatherSelectedProjects gatheredFile lintResults lll loadProjects
numberOutputFiles nwsc projectCount runTests testResult stringToFileName
uploadToS3);
 }

sub attributeMethods                                                            #P Attribute methods
 {qw(catalog clearCount convert devShm devShmOrHome develop download downloads
endTime gathered home in inputExt lint maximimumNumberOfProcesses
maximumFileFromTitleLength out parseCache process reports runTime s3Bucket
s3FolderIn s3FolderUp s3Parms startTime summaryFile testDocuments testResults
tests unicode upload)
 }

my $packagesMerged;                                                             # Merge packages only once
sub mergePackages(;$)                                                           #P Merge packages
 {my ($package) = @_;                                                           # Name of package to be merged defaulting to that of the caller.
  my ($p) = caller();                                                           # Default package if none supplied
  $package //= $p;                                                              # Supply default package if none supplied
  return if $packagesMerged++;                                                  # Merge packages only once
  mergePackageMethods($package, __PACKAGE__,
    replaceableMethods, attributeMethods);
 }

sub convertXmlToDita                                                            #r Perform all the conversion projects.
 {my ($package) = caller;

  mergePackages($package);

  for my $phase(qw(downloadFromS3 convertToUTF8 convertProjects
                   lintResults runTests uploadToS3))
   {no strict;
#   lll "Phase: ", $phase;
    &{$phase};
   }

  $endTime = time;                                                              # Run time statistics
  $runTime = $endTime - $startTime;
 }

sub createSampleInputFiles                                                      #P Create sample input files for testing. The attribute B<inputFolder> supplies the name of the folder in which to create the sample files.
 {my ($p) = caller();                                                           # Default package if none supplied
  mergePackages($p);

  my $f = fpe(downloads, qw(1 dita));
  owf($f, <<END);
<concept id="c1">
  <title id="title">Hello World</title>
  <conbody/>
</concept>
END
  owf(fpe(downloads, qw(2 dita)), <<END);
<concept id="c2">
  <title id="title">Good Bye</title>
  <conbody/>
</concept>
END
 }

#D0
# podDocumentation

=pod

=encoding utf-8

=head1 Name

Data::Edit::Xml::To::Dita - Convert multiple Xml documents in parallel to Dita.

=head1 Synopsis

A framework for converting multiple Xml documents in parallel to Dita:

  use Data::Edit::Xml::To::Dita;

  sub convertDocument($$)
   {my ($project, $x) = @_;                   # use sumAbsRel to get default home

    $x->by(sub
     {my ($c) = @_;
      if ($c->at_conbody)
       {$c->putFirst($c->new(<<END));
<p>Hello world!</p>
END
       }
     });
   }

  Data::Edit::Xml::To::Dita::createSampleInputFiles;
  Data::Edit::Xml::To::Dita::convertXmlToDita;

Evaluate the results of the conversion by reading the summary file in the
B<reports/> folder:

  use Data::Table::Text qw(fpe readFile);

  if (lint) # Lint report if available
   {my $s = readFile(&summaryFile);
    $s =~ s(\s+on.*) ()ig;
    my $S = <<END;

  Summary of passing and failing projects

  100 % success. Projects: 0+1=1.  Files: 0+1=1. Errors: 0,0

  CompressedErrorMessagesByCount (at the end of this file):        0

  FailingFiles   :         0
  PassingFiles   :         1

  FailingProjects:         0
  PassingProjects:         1


  FailingProjects:         0
     #  Percent   Pass  Fail  Total  Project
                                               # use sumAbsRel to get default home


  PassingProjects:         1
     #   Files  Project
     1       1  1


  DocumentTypes: 1

  Document  Count
  concept       1


  100 % success. Projects: 0+1=1.  Files: 0+1=1. Errors: 0,0

  END

    ok $s eq $S;
   }

See the converted files in the B<out/> folder:

  if (1) # Converted file
   {my $s = nwsc(readFile(fpe(&out, qw(hello_world dita))));
    my $S = nwsc(<<END);

  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []>
  <concept id="c1">
    <title id="title">Hello World</title>
    <conbody>
      <p>Hello world!</p>
    </conbody>
  </concept>
  END

    ok $S eq $s;
   }

=head1 Description

Convert multiple Xml documents in parallel to Dita.


Version "2018-10-04+111".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Convert Xml to the Dita standard.

Convert Xml to the Dita standard.

=head2 Methods

Methods defined in this package.

=head3 lll(@)

Log messages including the project name if available

     Parameter  Description
  1  @m         Messages

B<Example:>


  sub 𝗹𝗹𝗹(@)                                                                     
   {my (@m) = @_;                                                                 # Messages
    my $m = join '', dateTimeStamp, " ", @_;                                      # Time stamp each message
       $m =~ s(\s+) ( )gs;
    if ($project)
     {$m .= " in project $project";
     }
    my ($p, $f, $l) = caller();
    $m .= " at $f line $l
";
  
    say STDERR $m;
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub lll {...}

if you wish to override the default processing supplied by this method.



=head3 downloadFromS3()

Download documents from S3 to the L<downloads|/downloads> folder.


B<Example:>


  sub 𝗱𝗼𝘄𝗻𝗹𝗼𝗮𝗱𝗙𝗿𝗼𝗺𝗦𝟯                                                             
   {if (download)                                                                 # Download if requested
     {lll "Download from S3";
      clearFolder(downloads, clearCount);
      makePath(downloads);
      my $b = s3Bucket;
      my $d = downloads;
      my $f = s3FolderIn;
      my $p = s3Parms;
      my $c = qq(aws s3 sync s3://$b/$f $d $p);
      xxx $c;
      Flip::Flop::download();
     }
    else
     {lll "Download from S3 not requested";
     }
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub downloadFromS3 {...}

if you wish to override the default processing supplied by this method.



=head3 convertToUTF8()

Convert the encoding of documents in L<downloads|/downloads> to utf8 equivalents in folder L<in|/in>.


B<Example:>


  sub 𝗰𝗼𝗻𝘃𝗲𝗿𝘁𝗧𝗼𝗨𝗧𝗙𝟴                                                              
   {my $n = 0;
    if (unicode)
     {lll "Unicode conversion";
      my $d = downloads;
      my $i = in;
      clearFolder(in, clearCount);
      for my $source(searchDirectoryTreesForMatchingFiles(downloads, inputExt))
       {my $target = swapFilePrefix($source, downloads, in);
        makePath($target);
        my $type = trim(qx(enca -iL none "$source"));
        my $c    = qx(iconv -f $type -t UTF8 -o "$target" "$source");
        ++$n;
        if (1)                                                                    # Change encoding
         {my $s = readFile($target);
          my $S = $s =~ s(encoding="[^"]{3,16}") (encoding="UTF-8")r;
          owf($target, $S) unless $S eq $s;
         }
       }
      lll "Unicode conversion applied to $n files";
     }
    else
     {lll "Unicode conversion not requested";
     }
  
    Flip::Flop::unicode();
    $n
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub convertToUTF8 {...}

if you wish to override the default processing supplied by this method.



=head3 projectCount()

Number of projects to process.


B<Example:>


  sub 𝗽𝗿𝗼𝗷𝗲𝗰𝘁𝗖𝗼𝘂𝗻𝘁()                                                             
   {scalar keys %$projects
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub projectCount {...}

if you wish to override the default processing supplied by this method.



=head3 Project()

Project details including at a minimum the name of the project and its source file.


B<Example:>


  sub 𝗣𝗿𝗼𝗷𝗲𝗰𝘁                                                                    
   {my ($name, $source) = @_;                                                     # 𝗣𝗿𝗼𝗷𝗲𝗰𝘁 name, source file
  
    confess "No name for project
"          unless $name;
    confess "No source for project: $name
" unless $source;
    if (my $q = $$projects{$name})
     {my $Q = $q->source;
      confess "Duplicate project: $name
$source
$Q
";
     }
    confess "Source file does not exist:
$source
" unless -e $source;
  
    my $p = genHash(q(𝗣𝗿𝗼𝗷𝗲𝗰𝘁),                                                   # 𝗣𝗿𝗼𝗷𝗲𝗰𝘁 definition
      id         => undef,                                                        # Id attribute value from outermost tag
      isMap      => undef,                                                        # Map
      name       => $name,                                                        # Name of project
      number     => projectCount + 1,                                             # Number of project
      outputFile => undef,                                                        # Output file
      source     => $source,                                                      # Input file
      title      => undef,                                                        # Title for project
      topicId    => undef,                                                        # Topic id for project - collected during gather
     );
  
    $projects->{$p->name} = $p;                                                   # Save project definition
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub Project {...}

if you wish to override the default processing supplied by this method.



=head3 loadProjects()

Locate documents to convert from folder L<in|/in>.


B<Example:>


  sub 𝗹𝗼𝗮𝗱𝗣𝗿𝗼𝗷𝗲𝗰𝘁𝘀                                                               
   {my @p = searchDirectoryTreesForMatchingFiles(in,    inputExt);                # Production documents
    my @t = searchDirectoryTreesForMatchingFiles(tests, inputExt);                # Test documents
    if (my %t = map {$_=>1} testDocuments)                                        # Locate documents to be tested
     {for my $file(@p, @t)                                                        # Favor production over test because test is easier to run in bulk
       {my $name = fn $file;
        next unless $t{$name};                                                    # Skip unless name matches
        next if $projects->{$name};                                               # Skip if we already have a document to test
        Project($name, $file);
       }
     }
    else                                                                          # Choose documents in bulk
     {for my $file(develop ? @t : @p, inputExt)
       {my $name  = fn $file;
        Project($name, $file);
       }
     }
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub loadProjects {...}

if you wish to override the default processing supplied by this method.



=head3 Project::by($$$)

Process parse tree with checks to confirm features

     Parameter  Description
  1  $project   Project
  2  $x         Node
  3  $sub       Sub

=head3 Project::formatXml($$)

Output file for a document

     Parameter  Description
  1  $project   Project
  2  $x         Parse tree

=head3 stringToFileName($)

Convert a title string to a file name

     Parameter  Description
  1  $string    String

B<Example:>


  sub 𝘀𝘁𝗿𝗶𝗻𝗴𝗧𝗼𝗙𝗶𝗹𝗲𝗡𝗮𝗺𝗲($)                                                        
   {my ($string) = @_;                                                            # String
    $string =~ s(\.\.\.)        (_)gs;
    $string =~ s([%@#*?“'"|,.]) (_)gs;
    $string =~ s([&\+~\/\\:=])  (-)gs;
    $string =~ s([<\[])         (28)gs;
    $string =~ s([>\]])         (29)gs;
    $string =~ s(\s+)           (_)gs;
  
    my $r = lc firstNChars $string, maximumFileFromTitleLength;
    $r
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub stringToFileName {...}

if you wish to override the default processing supplied by this method.



=head3 gatheredFile($)

Save file for parse tree after initial parse and gather

     Parameter  Description
  1  $project   Project == document to convert

B<Example:>


  sub 𝗴𝗮𝘁𝗵𝗲𝗿𝗲𝗱𝗙𝗶𝗹𝗲($)                                                            
   {my ($project) = @_;                                                           # Project == document to convert
    fpe(gathered, $project->number, q(data))
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub gatheredFile {...}

if you wish to override the default processing supplied by this method.



=head3 gatherProject($)

Gather some information from each project

     Parameter  Description
  1  $project   Project == document to convert

B<Example:>


  sub 𝗴𝗮𝘁𝗵𝗲𝗿𝗣𝗿𝗼𝗷𝗲𝗰𝘁($)                                                           
   {my ($project) = @_;                                                           # Project == document to convert
    my $projectName = $project->name;
    lll "Gather";                                                                 # Title of each conversion
  
    my $x = $project->parse;                                                      # Parse file
    $project->isMap   = $x->tag =~ m(map\Z)is;                                    # Map file
    $project->topicId = $x->id;                                                   # Topic Id
  
    $x->by(sub                                                                    # Locate title and hence output file
     {my ($t) = @_;
      if ($t->at_title)
       {my $T = $project->title = $t->stringContent;
        $project->outputFile = stringToFileName($T);
       }
     });
  
    storeFile gatheredFile($project), $x;                                         # Save parse tree - separately because it is large.
  
    $project                                                                      # Gathered information about a project
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub gatherProject {...}

if you wish to override the default processing supplied by this method.



=head3 numberOutputFiles()

Add deduplicating numbers to output files names that would otherwise be the same.


B<Example:>


  sub 𝗻𝘂𝗺𝗯𝗲𝗿𝗢𝘂𝘁𝗽𝘂𝘁𝗙𝗶𝗹𝗲𝘀                                                          
   {my %o;
    for my $P(sort keys %$projects)
     {my $p = $projects->{$P};
      if (my $o = $p->outputFile)
       {if (my $n = $o{$o}++)
         {$p->outputFile .= q(_).$n;
         }
       }
      else
       {confess "No output file for project source:
", $p->source, "
";
       }
     }
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub numberOutputFiles {...}

if you wish to override the default processing supplied by this method.



=head3 convertDocument($$)

Convert one document.

     Parameter  Description
  1  $project   Project == document to convert
  2  $x         Parse tree.

B<Example:>


  sub 𝗰𝗼𝗻𝘃𝗲𝗿𝘁𝗗𝗼𝗰𝘂𝗺𝗲𝗻𝘁($$)                                                        
   {my ($project, $x) = @_;                                                       # Project == document to convert, parse tree.
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub convertDocument {...}

if you wish to override the default processing supplied by this method.



=head3 convertProject($)

Convert one document held in folder L<in|/in> into topic files held in L<out|/out>.

     Parameter  Description
  1  $project   Project == document to convert

B<Example:>


  sub 𝗰𝗼𝗻𝘃𝗲𝗿𝘁𝗣𝗿𝗼𝗷𝗲𝗰𝘁($)                                                          
   {my ($project) = @_;                                                           # Project == document to convert
    my $projectName = $project->name;
  
    lll "Convert";                                                                # Title of each conversion
  
    my $x = retrieveFile(gatheredFile $project);                                  # Reload parse into this process
  
    convertDocument($project, $x);                                                # Convert document
  
    my $o = fpe(out, $project->outputFile, q(dita));                              # File to write to
  
    if (lint)                                                                     # Lint
     {my $l = Data::Edit::Xml::Lint::new();                                       # Write and lint topic
      $l->project = $project->name;                                               # Project name
      $l->catalog = catalog;                                                      # Catalog
      $l->file    = $o;                                                           # File to write to
      $l->source  = $project->formatXml($x);                                      # Format source and add headers
      $l->lintNOP;                                                                # Lint
     }
    else                                                                          # Write without lint
     {my $f = $project->outputFile;
      writeFile($o, $project->formatXml($x));
     }
  
    $project                                                                      # Conversion succeeded for project
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub convertProject {...}

if you wish to override the default processing supplied by this method.



=head3 lintResults()

Lint results held in folder L<out|/out>and write reports to folder L<reports|/reports>.


B<Example:>


  sub 𝗹𝗶𝗻𝘁𝗥𝗲𝘀𝘂𝗹𝘁𝘀                                                                
   {if (lint)                                                                     # Only if lint requested
     {lll "Lint results";
      clearFolder(reports, clearCount);                                           # Clear prior run
  
      my $xref = Data::Edit::Xml::Xref::xref(inputFolder=>out, reports=>reports); # Check any cross references
      if (my $report = Data::Edit::Xml::Lint::report(out, qr(dita|ditamap|xml)))
       {my $r = $report->print;
        my $d = dateTimeStamp;
        my $h = home;
        my $b = s3Bucket;
        my $B = $b && upload ?
          qq(

Please see: aws s3 sync s3://$b ?

) :
          qq();
        my $x =                                                                   # Include xref results
        ˢ{my $s = $xref->statusLine;
          return "

$s"  if $s;
          q()
         };
  
        my $s = <<END;                                                            # rrrr
  Summary of passing and failing projects on $d.\t\tVersion: $VERSION$B
  
  $r
  $x
  END
        say STDERR $s;
        writeFile(summaryFile, $s);
        Flip::Flop::lint();
       }
      else
       {lll "No Lint report available";
       }
     }
    else
     {lll "Lint report not requested";
     }
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub lintResults {...}

if you wish to override the default processing supplied by this method.



=head3 uploadToS3()

Send results to S3 from folder L<out|/out>.


B<Example:>


  sub 𝘂𝗽𝗹𝗼𝗮𝗱𝗧𝗼𝗦𝟯                                                                 
   {if (upload)
     {lll "Upload to S3";
      my $h = home;
      my $b = s3Bucket;
      my $f = s3FolderUp;
      my $p = s3Parms;
      my $c = qq(aws s3 sync $h $b/$f $p);
      say STDERR $c;
      print STDERR $_ for qx($c);
      say STDERR qq(Please see:  aws s3 sync $b/$f ?);
      Flip::Flop::𝘂𝗽𝗹𝗼𝗮𝗱𝗧𝗼𝗦𝟯();                                                   # Reset upload flip flop
     }
    else
     {lll "Upload to S3 not requested";
     }
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub uploadToS3 {...}

if you wish to override the default processing supplied by this method.



=head3 runTests()

Run tests by comparing files in folder L<out|/out> with corresponding files in L<testResults|/testResults>.


B<Example:>


  sub 𝗿𝘂𝗻𝗧𝗲𝘀𝘁𝘀                                                                   
   {if (develop)                                                                  # Run tests if developing
     {&checkResults;
      my $F = join " ", @failedTests;
      my $f = @failedTests;
      my $p = @passedTests;
      my $a = @availableTests;
      say STDERR "Failed tests: $F" if @failedTests;
      $p + $f == $a or warn "Passing plus failing tests".
       " not equal to tests available: $p + $f != $a";
      say STDERR "Tests: $p+$f == $a pass+fail==avail";
     }
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub runTests {...}

if you wish to override the default processing supplied by this method.



=head3 nwsc($)

Normalize white space and remove comments

     Parameter  Description
  1  $string    Text to normalize

B<Example:>


  sub 𝗻𝘄𝘀𝗰($)                                                                    
   {my ($string) = @_;                                                            # Text to normalize
    $string =~ s(<\?.*?\?>)  ()gs;
    $string =~ s(<!--.*?-->) ()gs;
    $string =~ s(<!DOCTYPE.+?>)  ()gs;
    $string =~ s( (props|id)="[^"]*") ()gs;
    nws($string);
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub nwsc {...}

if you wish to override the default processing supplied by this method.



=head3 testResult($$$)

Evaluate the results of a test

     Parameter  Description
  1  $file      File
  2  $got       What we got
  3  $expected  What we expected result

B<Example:>


  sub 𝘁𝗲𝘀𝘁𝗥𝗲𝘀𝘂𝗹𝘁($$$)                                                            
   {my ($file, $got, $expected) = @_;                                             # File, what we got, what we expected result
    my $f = fpe(tests, $file, q(dita));                                           # Actual result
    my $g = nwsc($got);
    my $e = nwsc($expected);
  
    if ($e !~ m(\S)s)                                                             # Blank test file
     {confess "Test $file is all blank";
     }
  
    if ($g eq $e)                                                                 # Compare got with expected and pass
     {push @passedTests, $file;
      return 1;
     }
    else                                                                          # Not as expected
     {push @failedTests, $file;
      my @g = grep {!/\A\s*(<!|<\?)/} split /
/, readFile($f);
      my @e = grep {!/\A\s*(<!|<\?)/} split /
/, $expected;
      shift @g, shift @e while @g and @e and nwsc($g[0]) eq nwsc($e[0]);
      cluck "Got/expected in test $file:
".
            "Got:
". $g[0].
            "
Expected:
". $e[0]. "
";
      return 0;
     }
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub testResult {...}

if you wish to override the default processing supplied by this method.



=head3 checkResults()

Send results to S3 from folder L<out|/out>.


B<Example:>


  sub 𝗰𝗵𝗲𝗰𝗸𝗥𝗲𝘀𝘂𝗹𝘁𝘀                                                               
   {for my $expected(searchDirectoryTreesForMatchingFiles(testResults))
     {my $got  = swapFilePrefix($expected, testResults, out);
      my $test = fn $expected;
      push @availableTests, $test;
      if (-e $got)
       {testResult($test, readFile($got), readFile($expected));
       }
     }
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub checkResults {...}

if you wish to override the default processing supplied by this method.



=head3 gatherSelectedProjects()

Gather information from the selected project by reading their source files held in the L<in|/in>.


B<Example:>


  sub 𝗴𝗮𝘁𝗵𝗲𝗿𝗦𝗲𝗹𝗲𝗰𝘁𝗲𝗱𝗣𝗿𝗼𝗷𝗲𝗰𝘁𝘀                                                     
   {lll "Gather selected projects";
    my $ps = newProcessStarter(maximimumNumberOfProcesses, process);              # Process starter
  
    for(sort keys %$projects)                                                     # Gather information from each project
     {$ps->start(sub{gatherProject($projects->{$_})});
     }
  
    if (my @results = $ps->finish)                                                # Consolidate results
     {reloadHashes(\@results);                                                    # Recreate attribute methods
      my %togather = %$projects;
      for my $project(@results)                                                   # Each result
       {my $projectName = $project->name;                                         # Project name
        if (my $p = $$projects{$projectName})                                     # Find project
         {$$projects{$projectName} = $project;                                    # Consolidate information gathered
          delete $togather{$projectName};                                         # Mark project as gathered
         }
        else                                                                      # Confess to invalid project
         {confess "Unknown gathered project $projectName";
         }
       }
      if (my @f = sort keys %togather)                                            # Confess to projects that failed to gather
       {confess "The following projects failed to gather:
", join (' ', @f);
       }
     }
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub gatherSelectedProjects {...}

if you wish to override the default processing supplied by this method.



=head3 convertSelectedProjects()

Convert the selected documents by reading their source in L<in|/in>, converting them and writing the resulting topics to L<out|/out>.


B<Example:>


  sub 𝗰𝗼𝗻𝘃𝗲𝗿𝘁𝗦𝗲𝗹𝗲𝗰𝘁𝗲𝗱𝗣𝗿𝗼𝗷𝗲𝗰𝘁𝘀                                                    
   {lll "Converted selected projects";
    my $ps = newProcessStarter(maximimumNumberOfProcesses, process);              # Process starter
  
    for $project(sort keys %$projects)                                            # Convert projects
     {$ps->start(sub{convertProject($projects->{$project})});                     # Convert each project in a separate process
     }
  
    if (my @results = $ps->finish)                                                # Consolidate results
     {reloadHashes(\@results);                                                    # Recreate attribute methods
      my %toConvert = %$projects;
      for my $project(@results)                                                   # Each result
       {my $projectName = $project->name;                                         # Converted project name
        if (my $p = $$projects{$projectName})                                     # Find project
         {$$projects{$projectName} = $project;                                    # Consolidate information gathered
          delete $toConvert{$projectName};                                        # Mark project as converted
         }
        else                                                                      # Confess to invalid project
         {confess "Unknown converted project $projectName";
         }
       }
      if (my @f = sort keys %toConvert)                                           # Confess to projects that failed to convert
       {confess "The following projects failed to convert:
", join (' ', @f);
       }
     }
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub convertSelectedProjects {...}

if you wish to override the default processing supplied by this method.



=head3 convertProjects()

Convert the selected documents.


B<Example:>


  sub 𝗰𝗼𝗻𝘃𝗲𝗿𝘁𝗣𝗿𝗼𝗷𝗲𝗰𝘁𝘀                                                            
   {if (convert)                                                                  # Convert the documents if requested.
     {lll "Convert documents";
      clearFolder($_, clearCount) for out, process;                               # Clear output folders
      loadProjects;                                                               # Projects to run
      gatherSelectedProjects;                                                     # Gather information about each project
      numberOutputFiles;                                                          # Deduplicate output file names
      my @r = convertSelectedProjects                                             # Convert selected projects
      Flip::Flop::convert();                                                      # Reset conversion flip flop
      return @r;                                                                  # Return results of conversions
     }
    else
     {lll "Convert documents not requested";
     }
  
    ()
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub convertProjects {...}

if you wish to override the default processing supplied by this method.



=head3 convertXmlToDita()

Perform all the conversion projects.


B<Example:>


  sub 𝗰𝗼𝗻𝘃𝗲𝗿𝘁𝗫𝗺𝗹𝗧𝗼𝗗𝗶𝘁𝗮                                                           
   {my ($package) = caller;
  
    mergePackages($package);
  
    for my $phase(qw(downloadFromS3 convertToUTF8 convertProjects
                     lintResults runTests uploadToS3))
     {no strict;
  #   lll "Phase: ", $phase;
      &{$phase};
     }
  
    $endTime = time;                                                              # Run time statistics
    $runTime = $endTime - $startTime;
   }
  

You can provide you own implementation of this method in your calling package
via:

  sub convertXmlToDita {...}

if you wish to override the default processing supplied by this method.




=head1 Hash Definitions




=head2 Project Definition


Project definition


B<id> - Id attribute value from outermost tag

B<isMap> - Map

B<name> - Name of project

B<number> - Number of project

B<outputFile> - Output file

B<source> - Input file

B<title> - Title for project

B<topicId> - Topic id for project - collected during gather



=head2 𝗣𝗿𝗼𝗷𝗲𝗰𝘁 Definition


𝗣𝗿𝗼𝗷𝗲𝗰𝘁 definition


B<id> - Id attribute value from outermost tag

B<isMap> - Map

B<name> - Name of project

B<number> - Number of project

B<outputFile> - Output file

B<source> - Input file

B<title> - Title for project

B<topicId> - Topic id for project - collected during gather



=head1 Attributes


The following is a list of all the attributes in this package.  A method coded
with the same name in your package will over ride the method of the same name
in this package and thus provide your value for the attribute in place of the
default value supplied for this attribute by this package.

=head2 Replaceable Attribute List


catalog clearCount convert devShm devShmOrHome develop download downloads endTime gathered home in inputExt lint maximimumNumberOfProcesses maximumFileFromTitleLength out parseCache process reports runTime s3Bucket s3FolderIn s3FolderUp s3Parms startTime summaryFile testDocuments testResults tests unicode upload 


=head2 catalog

Dita catalog to be used for linting.


=head2 clearCount

Limit on number of files to clear from each output folder.


=head2 convert

Convert documents to dita if true.


=head2 devShm

Shared memory folder for output files.


=head2 devShmOrHome

Shared memory folder or home folder.


=head2 develop

Production run if this file folder is detected otherwise development.


=head2 download

Download from S3 if true.


=head2 downloads

Downloads folder.


=head2 endTime

End time of run in seconds since the epoch.


=head2 gathered

Folder containing saved parse trees after initial parse and information gathering.


=head2 home

Home folder containing all the other folders


=head2 in

Input documents folder.


=head2 inputExt

Extension of input files.


=head2 lint

Lint output xml if true or write directly if false.


=head2 maximimumNumberOfProcesses

Maximum number of processes to run in parallel.


=head2 maximumFileFromTitleLength

Maximum amount of title to use in constructing output file names.


=head2 out

Converted documents output folder.


=head2 parseCache

Cached parse trees


=head2 process

Process data folder used to communicate results between processes.


=head2 reports

Reports folder.


=head2 runTime

Elapsed run time in seconds.


=head2 s3Bucket

Bucket on S3 holding documents to convert and the converted results.


=head2 s3FolderIn

Folder on S3 containing original documents.


=head2 s3FolderUp

Folder on S3 containing results of conversion.


=head2 s3Parms

Additional S3 parameters for uploads and downloads.


=head2 startTime

Start time of run in seconds since the epoch.


=head2 summaryFile

Summary report file.


=head2 testDocuments

List of production documents to test in development or () for normal testing locally or normal production if on Aws.


=head2 testResults

Folder containing test results expected.


=head2 tests

Folder containing test files.


=head2 unicode

Convert to utf8 if true.


=head2 upload

Upload to S3 if true.




=head1 Optional Replace Methods

The following is a list of all the optionally replaceable methods in this
package.  A method coded with the same name in your package will over ride the
method of the same name in this package providing your preferred processing for
the replaced method in place of the default processing supplied by this
package. If you do not supply such an over riding method, the existing method
in this package will be used instead.

=head2 Replaceable Method List


Project checkResults convertDocument convertProject convertProjects convertSelectedProjects convertToUTF8 convertXmlToDita downloadFromS3 gatherProject gatherSelectedProjects gatheredFile lintResults lll loadProjects numberOutputFiles nwsc projectCount runTests stringToFileName testResult uploadToS3 




=head1 Private Methods

=head2 getHome()

Compute home directory once


=head2 md5Sum($)

Md5 sum for a file

     Parameter  Description
  1  $file      File

=head2 Project::parseCacheFile($)

Name of the file in which to cache parse trees

     Parameter  Description
  1  $project   Project

=head2 Project::parse($)

Parse a project.

     Parameter  Description
  1  $project   Project

=head2 replaceableMethods()

Replaceable methods


=head2 attributeMethods()

Attribute methods


=head2 mergePackages($)

Merge packages

     Parameter  Description
  1  $package   Name of package to be merged defaulting to that of the caller.

=head2 createSampleInputFiles()

Create sample input files for testing. The attribute B<inputFolder> supplies the name of the folder in which to create the sample files.



=head1 Index


1 L<attributeMethods|/attributeMethods> - Attribute methods

2 L<checkResults|/checkResults> - Send results to S3 from folder L<out|/out>.

3 L<convertDocument|/convertDocument> - Convert one document.

4 L<convertProject|/convertProject> - Convert one document held in folder L<in|/in> into topic files held in L<out|/out>.

5 L<convertProjects|/convertProjects> - Convert the selected documents.

6 L<convertSelectedProjects|/convertSelectedProjects> - Convert the selected documents by reading their source in L<in|/in>, converting them and writing the resulting topics to L<out|/out>.

7 L<convertToUTF8|/convertToUTF8> - Convert the encoding of documents in L<downloads|/downloads> to utf8 equivalents in folder L<in|/in>.

8 L<convertXmlToDita|/convertXmlToDita> - Perform all the conversion projects.

9 L<createSampleInputFiles|/createSampleInputFiles> - Create sample input files for testing.

10 L<downloadFromS3|/downloadFromS3> - Download documents from S3 to the L<downloads|/downloads> folder.

11 L<gatheredFile|/gatheredFile> - Save file for parse tree after initial parse and gather

12 L<gatherProject|/gatherProject> - Gather some information from each project

13 L<gatherSelectedProjects|/gatherSelectedProjects> - Gather information from the selected project by reading their source files held in the L<in|/in>.

14 L<getHome|/getHome> - Compute home directory once

15 L<lintResults|/lintResults> - Lint results held in folder L<out|/out>and write reports to folder L<reports|/reports>.

16 L<lll|/lll> - Log messages including the project name if available

17 L<loadProjects|/loadProjects> - Locate documents to convert from folder L<in|/in>.

18 L<md5Sum|/md5Sum> - Md5 sum for a file

19 L<mergePackages|/mergePackages> - Merge packages

20 L<numberOutputFiles|/numberOutputFiles> - Add deduplicating numbers to output files names that would otherwise be the same.

21 L<nwsc|/nwsc> - Normalize white space and remove comments

22 L<Project|/Project> - Project details including at a minimum the name of the project and its source file.

23 L<Project::by|/Project::by> - Process parse tree with checks to confirm features

24 L<Project::formatXml|/Project::formatXml> - Output file for a document

25 L<Project::parse|/Project::parse> - Parse a project.

26 L<Project::parseCacheFile|/Project::parseCacheFile> - Name of the file in which to cache parse trees

27 L<projectCount|/projectCount> - Number of projects to process.

28 L<replaceableMethods|/replaceableMethods> - Replaceable methods

29 L<runTests|/runTests> - Run tests by comparing files in folder L<out|/out> with corresponding files in L<testResults|/testResults>.

30 L<stringToFileName|/stringToFileName> - Convert a title string to a file name

31 L<testResult|/testResult> - Evaluate the results of a test

32 L<uploadToS3|/uploadToS3> - Send results to S3 from folder L<out|/out>.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Data::Edit::Xml::To::Dita

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
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
Test::More->builder->output("/dev/null")                                        # Reduce number of confirmation messages during testing
  if ((caller(1))[0]//'Data::Table::Text') eq "Data::Table::Text";

use Test::More tests=>1;

ok 1;
