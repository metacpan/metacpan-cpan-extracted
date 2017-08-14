#!/usr/bin/perl
#-I/home/phil/z/perl/cpan/DataEditXml/lib -I/home/phil/z/perl/cpan/DataTableText/lib
#-------------------------------------------------------------------------------
# Lint xml files in parallel using xmllint and report the failure rate
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------
# Report should allow the integration of other statistics into its summary besides the one it produces itself
# Record reused in other project
# podDocumentation

package Data::Edit::Xml::Lint;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Table::Text qw(:all);
use Digest::SHA qw(sha256_hex);
use Encode;
our $VERSION = 20170802;

#1 Constructor                                                                  # Construct a new linter

sub new                                                                         # Create a new xml linter - call this method statically as in L<Data::Edit::Xml::Lint|/new>
 {bless {}                                                                      # Create xml linter
 }

#2 Attributes                                                                   # Attributes describing a lint

genLValueScalarMethods(qw(author));                                             # Optional author of the xml - only needed if you want to generate an SDL file map
genLValueScalarMethods(qw(catalog));                                            # Optional catalog file containing the locations of the DTDs used to validate the xml
genLValueScalarMethods(qw(ditaType));                                           # Optional Dita topic type(concept|task|troubleshooting|reference) of the xml - only needed if you want to generate an SDL file map
genLValueScalarMethods(qw(docType));                                            # The second line: the document type extracted from the L<source|/source>
genLValueScalarMethods(qw(dtds));                                               # Optional directory containing the DTDs used to validate the xml
genLValueScalarMethods(qw(errors));                                             # Number of lint errors detected by xmllint
genLValueScalarMethods(qw(file));                                               # File that the xml will be written to and read from by L<lint|/lint>, L<read|/read> or L<relint|/relint>
genLValueScalarMethods(qw(guid));                                               # Guid for outermost tag - only required if you want to generate an SD file map
genLValueScalarMethods(qw(header));                                             # The first line: the xml header extracted from L<source|/source>
genLValueScalarMethods(qw(idDefs));                                             # {id} = count - the number of times this id is defined in the xml contained in this L<file|/file>
genLValueScalarMethods(qw(labelDefs));                                          # {label or id} = id - the id of the node containing a L<label|Data::Edit::Xml/Labels> defined on the xml
genLValueScalarMethods(qw(labels));                                             # Optional parse tree to supply L<labels|Data::Edit::Xml/Labels> for the current L<source|/source> as the labels are present in the parse tree not in the string representing the parse tree
genLValueScalarMethods(qw(linted));                                             # Date the lint was performed by L<lint|/lint>
genLValueScalarMethods(qw(processes));                                          # Maximum number of xmllint processes to run in parallel - 8 by default
genLValueScalarMethods(qw(project));                                            # Optional L<project|/project> name to allow error counts to be aggregated by L<project|/project> and to allow L<id and labels|Data::Edit::Xml/Labels> to be scoped to the L<files|/file> contained in each L<project|/project>
genLValueArrayMethods(qw(reusedInProject));                                     # List of projects in which this file is reused
genLValueScalarMethods(qw(sha256));                                             # Sha256 hash of the string containing the xml processed by L<lint|/lint> or L<read|/read>
genLValueScalarMethods(qw(source));                                             # The source Xml to be linted
genLValueScalarMethods(qw(title));                                              # Optional title of the xml - only needed if you want to generate an SDL file map

#1 Lint                                                                         # Lint xml L<files|/file> in parallel

my @pids;                                                                       # Lint pids

sub lint($@)                                                                    # Store some xml in a L<files|/file>, apply xmllint in parallel and update the source file with the results
 {my ($lint, %attributes) = @_;                                                 # Linter, attributes to be recorded as xml comments
  &lintOP(1, @_);
 }

sub lintNOP($@)                                                                 # Store some xml in a L<files|/file>, apply xmllint in single and update the source file with the results
 {my ($lint, %attributes) = @_;                                                 # Linter, attributes to be recorded as xml comments
  &lintOP(0, @_);
 }

sub lintOP($$@)                                                                 #P Store some xml in a L<files|/file>, apply xmllint in parallel or single and update the source file with the results
 {my ($inParallel, $lint, %attributes) = @_;                                    # In parallel or not, Linter, attributes to be recorded as xml comments

  $lint->source or confess "Use the source() method to provide the source xml"; # Check that we have some source
  $lint->file or confess "Use the ->file method to provide the target file";    # Check that we have an output file

  if ($inParallel)                                                              # Process in parallel if possible
   {my $processes = $lint->processes // 8;                                      # Maximum number of processes
    &waitProcessing;                                                            # Wait until enough sub processes have completed
    if (my $pid = fork())                                                       # Perform lints in parallel
     {push @pids, $pid;
      return;
     }
   }

  $lint->source = $lint->source =~ s/\s+\Z//gsr;                                # Xml text to be written minus trailing blanks
  my @lines = split /\n/, $lint->source;                                        # Split source into lines

  my $file = $lint->file;                                                       # File to be written to
  confess "File name contains a new line:\n$file\n" if $file =~ m/\n/s;         # Complain if the source file contains a new line

  for(qw(author catalog ditaType dtds file guid project title))                 # Map parameters to attributes
   {my $a = $lint->$_;
    $attributes{$_} = $a if $a;
   }

  $attributes{docType} = $lines[1];                                             # Source details
  $attributes{header}  = $lines[0];
  $attributes{sha256}  = sha256_hex(encode("ascii", $lint->source));            # Digest of source string

  my $time   = "<!--linted: ".dateStamp." -->\n";                               # Time stamp marks the start of the added comments
  my $attr   = &formatAttributes({%attributes});                                # Attributes to be recorded with the xml
  my $labels = sub                                                              # Process any labels in the parse tree
   {return '' unless $lint->labels;
    my $s = '';
    $lint->labels->by(sub                                                       # Search the supplied parse tree for any id or label definitions
     {my ($o) = @_;

      if (my $i = $o->id)                                                       # Id for this node but no labels
       {$s .= "<!--definition: $i -->\n";                                       # Id definition
        my $d = $lint->idDefs //= {};                                           # Id definitions for this file
        $d->{$i} = $i;                                                          # Record id definition
       }

      if (my @labels = $o->getLabels)                                           # Labels for this node
       {my $i = $o->id;                                                         # Id for this node
        $i or confess "No id for node with labels:\n".$o->prettyString;
        $s .= "<!--labels: $i ".join(' ', @labels)." -->\n";
        my $l = $lint->labelDefs //= {};                                        # Labels for this file
        $l->{$_} = $i for @labels;                                              # Link each label to its primary id
       }
     });
    $s
   }->();

  writeFile($file, my $source = $lint->source."\n$time\n$attr\n$labels");       # Write xml to file

  if (my $v = qx(xmllint --version 2>&1))                                       # Check xmllint is present
   {unless ($v =~ m(\Axmllint)is)
     {confess "xmllint missing, install with:\nsudo apt-get xmllint";
     }
   }

  my $c = sub                                                                   # Lint command
   {my $d = $lint->dtds;                                                        # Optional dtd to use
    my $f = $file;                                                              # File name
    return "xmllint --path \"$d\" --noout --valid \"$f\" 2>&1" if $d;           # Lint against DTDs
    my $c = $lint->catalog;                                                     # Optional dtd catalog to use
    return qq(xmllint --noout - < '$f' 2>&1) unless $c;                         # Normal lint
    qq(export XML_CATALOG_FILES='$c' && xmllint --noout --valid - < '$f' 2>&1)  # Catalog lint
   }->();

  if (my @errors = qx($c))                                                      # Perform lint and add errors as comments
   {my $s = readFile($file);
    my $e = join '', map {chomp; "<!-- $_ -->\n"} @errors;
    my $n = $lint->errors = int @errors / 3;                                    # Three lines per error message

    my $t = "<!--errors: $n -->";

    writeFile($file, "$source\n$time$e\n$t");                                   # Update xml file with errors
   }
  else                                                                          # No errors detected
   {$lint->errors = 0;
   }
  exit if $inParallel;
 } # lint

sub nolint($@)                                                                  # Store just the attributes in a file so that they can be retrieved later to process non xml objects referenced in the xml - like images
 {my ($lint, %attributes) = @_;                                                 # Linter, attributes to be recorded as xml comments
  !$lint->source or confess "Source specified for nolint(), use lint()";        # Source not permitted for nolint()
  my $file = $lint->file;                                                       # File to be written to
     $file or confess "Use the ->file method to provide the target file";       # Check that we have an output file

  for(qw(author ditaType file guid project))                                    # Map parameters to attributes
   {my $a = $lint->$_;
    $attributes{$_}  = $a if $a;
   }

  my $time = "<!--linted: ".dateStamp." -->\n";                                 # Time stamp marks the start of the added comments
  my $attr = &formatAttributes({%attributes});                                  # Attributes to be recorded with the xml

  writeFile($file, "\n$time\n$attr");                                           # Write attributes to file
 } # nolint

sub formatAttributes(%)                                                         #P Format the attributes section of the output file
 {my ($attributes) = @_;                                                        # Hash of attributes
  my @s;
  for(sort keys %$attributes)
   {my $v = $attributes->{$_};                                                  # Attribute value
    defined($v) or confess "Attribute $_ has no value";
    $v =~ s/--/__/gs if /title/;                                                # Replace -- with __ as -- will upset the use of xml comments to hold the data in a greppable form - but only for title - for files we need to see an error message
    $v =~ m/--/s and confess "-- in value of $_=>$v";                           # Confess if -- present in attribute value as this will mess up the xml comments
    push @s, "<!--${_}: $v -->";                                                # Place attribute inside a comment
   }
  join "\n", @s
 }

sub read($)                                                                     # Reread a linted xml L<file|/file> and extract the L<attributes|/Attributes> associated with the L<lint|/lint>
 {my ($file) = @_;                                                              # File containing xml
  my $s = readFile($file);                                                      # Read xml from file
  my %a = $s =~ m/<!--(\w+):\s+(.+?)\s+-->/igs;                                 # Get attributes
  my @a = split m/\n/, $s;                                                      # Split into lines

  my $l = {};                                                                   # Reconstructed labels
  for(@a)                                                                       # Each source line
   {if (/<!--labels:\s+(.+?)\s+-->/gs)                                          # Labels line
     {my ($w) = my @w = split /\s+/, $1;                                        # Id, labels
      $l->{$_} = $w for @w;                                                     # Associate each id and label with the id
     }
   }

  my $d = {};                                                                   # Id definitions
  for(@a)                                                                       # Each source line
   {if (/<!--definition:\s+(.+?)\s+-->/gs)                                      # Definition
     {$d->{$1}++;                                                               # Record definition
      $l->{$1} = $1;                                                            # An id also defines a label
     }
   }

  my $r = {};                                                                   # Reused in project
  for(@a)                                                                       # Each source line
   {if (/<!--reusedInProject:\s+(.+?)\s+-->/gs)                                 # Definition
     {$r->{$1}++;                                                               # Record definition
     }
   }

  my $S = $s =~ s/\s+<!--linted:.+\Z//sr;                                       # Remove generated comments at end
  my $lint = bless {%a, source=>$S, header=>$a[0], docType=>$a[1],              # Create a matching linter
     idDefs=>$d, labelDefs=>$l, reusedInProject=>[sort keys %$r]};

  $lint->errors //= 0;
  $lint                                                                         # Return a matching linter
 } # read

sub waitAllProcesses                                                            # Wait for all L<lints|/lint> to finish - this is a static method, call as Data::Edit::Xml::Lint::wait
 {waitpid(shift @pids, 0) while @pids;                                          # Wait until sub processes have completed
 } # wait

sub waitProcessing($)                                                           #P Wait for a processor to become available
 {my ($processes) = @_;                                                         # Maximum number of processes
  waitpid(shift @pids, 0) while @pids > $processes;                             # Wait until enough sub processes have completed
 }

sub clear(@)                                                                    # Clear the results of a prior run
 {my (@foldersAndExtensions) = @_;                                              # Directories to clear and extensions of files to remove
  my @f = &searchDirectoryTreesForMatchingFiles(@_);                            # The matching files
  unlink $_ for @f;                                                             # Unlink the matching files
 } # clear

sub relint($$$@)                                                                # Locate all the L<labels or id|Data::Edit::Xml/Labels> in the specified L<files|/file>, analyze the map of labels and ids with B<analysisSub> parse each L<file|/file>, process each parse with B<processSub>, then L<lint/lint> the reprocessed xml back to the original L<file|/file> - this allows you to reprocess the contents of each L<file|/file> with knowledge of where L<labels or id|Data::Edit::Xml/Labels> are located in the other L<files|/file> associated with a L<project|/project>. The B<analysisSub>(linkmap = {project}{labels or id>}=[file, id]) should return true if the processing of each file is to be performed subsequently. The B<processSub>(parse tree representation of a file, id and label mapping, reloaded linter) should return true if a L<lint|/lint> is required to save the results after each L<file|/file> has been processed else false, L<files|/file> to reprocess
 {my ($processes, $analysisSub, $processSub, @foldersAndExtensions) = @_;       # Maximum number of processes to use, analysis 𝘀𝘂𝗯, Process 𝘀𝘂𝗯, folder containing files to process (recursively), extensions of files to process
  my @files = searchDirectoryTreesForMatchingFiles(@foldersAndExtensions);      # Search for files to relint

  my $links;                                                                    # {project}{label or id} = [file, label or id] : the file containing  each label or id in each project
  my $fileToGuid;                                                               # {file name} to guid
  for my $file(@files)                                                          # Reload each file to reprocess
   {my $lint = Data::Edit::Xml::Lint::read($file);                              # Reconstructed linter

    if (my $g = $lint->guid)                                                    # Record file to guid mapping
     {if (my $lintFile = $lint->file)
       {if (my $G = $fileToGuid->{$lintFile})
         {confess "Guids $g and $G are both used for file $lintFile"
         }
        else
         {$fileToGuid->{$lintFile} = $g;
         }
       }
      else {confess "No file name attribute in $file"}
     }

    if (my $p = $lint->project)                                                 # Save location of labels and ids in all files by L<project|/project>
     {if (my $l = $lint->labelDefs)                                             # Labels and ids defined in this file
       {for my $label(keys %$l)                                                 # Each label or id defined in this file
         {my $target = [$file, $l->{$label}];                                   # [File, leading label == id] for this label
          push @{$links->{$p}{$label}}, $target;                                # Construct a hash of array refs which tell us the locations = [file, id] of every label and id over all the input files in the L<project|/project>
          for my $r(@{$lint->reusedInProject})                                  # Each project that this link is reused in
           {push @{$links->{$r}{$label}}, $target;                              # Copy targets into reused project
           }
         }
       }
     }
   }

  if ($analysisSub->($links, $fileToGuid))                                      # Analyze links and guids
   {for my $file(@files)                                                        # Reload, reparse, process, lint each file
     {my $lint = Data::Edit::Xml::Lint::read($file);                            # Reconstructed linter
      next unless $lint->source;                                                # Files without source are assumed to have been written to store some attributes
      my $x = eval{Data::Edit::Xml::new($lint->source)};                        # Reparse source trapping errors
      $@ and warn "$@\nFailed to parse file:\n$file";                           # Xml file failed to parse
      next if $@ or !$x;

      if (my $links = $lint->labelDefs)                                         # Reload labels
       {my $r;                                                                  # {primary id}[label]
        for my $source(sort keys %$links)                                       # Construct primary id to labels
         {my $target = $links->{$source};
          push @{$r->{$target}}, $source unless $source eq $target;             # No need to reverse the primary id
         }

        $x->by(sub                                                              # Reload labels
         {my ($o) = @_;
          if (defined($o->attr(qw(id))) and my $i = $o->id)                     # Id if defined
           {if (my $labels = $r->{$i})                                          # Labels for this id if present
             {for my $label(@$labels)                                           # Each label for this id
               {$o->addLabels($label);                                          # Add the label
               }
             }
           }
         });
       }
#FORK
      &waitProcessing($processes);                                              # Wait until enough sub processes have completed
      if (my $pid = fork())                                                     # Perform process sub in parallel
       {push @pids, $pid;
#say STDERR "PPPP $$ 1111 $pid", ;
       }
      else
       {if ($processSub->($x, $links->{$lint->project}, $fileToGuid, $lint))    # Call user method to process parse tree with labels in place and the location of all the labels and ids
         {my $l = $lint;                                                        # Shorten name
          $l->source = join "\n", $l->header, $l->docType, $x->prettyString;    # Reconstruct source
          $l->labels = $x;                                                      # Associated parse tree so we can save the labels
          my %a = map {$_=>$l->{$_}} grep{!($l->can($_))} keys %$l;             # Reconstruct attributes as this items which do not have a method attached
          $l->lintNOP(%a);                                                      # Lint reprocessed source
         }
        exit;
       }
     }
   }
  waitAllProcesses();
 } # relint

sub resolveUniqueLink($$)                                                       # Return the unique (file, leading id) of the specified link in the link map or () if no such definition exists
 {my ($linkMap, $link) = @_;                                                    # Link map, label
  my $l = $linkMap->{$link};                                                    # Attempt to resolve link
  return () unless $l;                                                          # No definition
  return () if @$l != 1;                                                        # Too many definitions
  @{$l->[0]}                                                                    # (file, leading id)
 } # resolveUniqueLink


sub countLinkTargets($$)                                                        # Count the number of targets this link resolves to.
 {my ($linkMap, $link) = @_;                                                    # Link map, label
  my $l = $linkMap->{$link};                                                    # Attempt to resolve link
  return 0 unless $l;                                                           # No definition
  scalar @$l;                                                                   # Definition count
 } # countLinkTargets

sub resolveFileToGuid($$)                                                       # Return the unique definition of the specified link in the link map or undef if no such definition exists
 {my ($fileToGuids, $file) = @_;                                                # File to guids map, file
  $fileToGuids->{$file};                                                        # Attempt to resolve file
 } # resolveFileToGuid

sub multipleLabelDefs($)                                                        # Return ([L<project|/project>; L<source label or id|Data::Edit::Xml/Labels>; targets count]*) of all L<labels or id|Data::Edit::Xml/Labels> that have multiple definitions
 {my ($labelDefs) = @_;                                                         # Label and Id definitions
  $labelDefs and ref($labelDefs) =~ /hash/is or                                 # Check definitions have been provided
    confess "No labelDefs provided";
  my @multipleLabelDefs;                                                        # Labels or ids with multiple definitions
  for my $project(sort keys % $labelDefs)                                       # Sub(linkmap = {L<project|/project>}{L<label or id|Data::Edit::Xml/Labels}=[L<file|/file>; id]) returns true if the processing of each L<file|/file> is to be performed after the link mapping has been analyzed at the start,  Sub(L<parse tree representation of a file|Data::Edit::Xml>, linkmap, reloaded L<linter|Data::Edit::Xml::Lint>) returns true if a L<lint|/lint> is required after each L<file|/file> has been processed, L<files|/file> to reprocess
   {for my $label(sort keys %{$labelDefs->{$project}})                          # Each source label or id
     {if (my $l = $labelDefs->{$project}{$label})                               # Source label or id
       {push @multipleLabelDefs, [$project, $label, $l] if @$l > 1;             # Ids or labels with multiple definitions
       }
     }
   }

  @multipleLabelDefs
 } # multipleLabelDefs

sub multipleLabelDefsReport($)                                                  # Return a L<report|/report> showing L<labels and id|Data::Edit::Xml/Labels> with multiple definitions in each L<project|/project> ordered by most defined
 {my ($labelDefs) = @_;                                                         # Label and Id definitions

  if (my @m = Data::Edit::Xml::Lint::multipleLabelDefs                          # Find multiple label or id definitions
                                           ($labelDefs))
   {$_->[2] = scalar(@{$_->[2]}) for @m;                                        # Replace array of multiple definitions with count thereof
    my $m = @m;
    return "MultipleLabelOrIdDefinitions ($m):\n".formatTable                   # Zero multiple label or id definitions
     ([[qw(Project Label Count)],
        sort {$b->[2] <=> $a->[2]} @m                                           # Sort so that the most frequent are first
     ]);
   }
  'No MultipleLabelOrIdDefinitions'                                             # Zero multiple label or id definitions
 } # multipleLabelDefsReport

sub singleLabelDefs($)                                                          # Return ([L<project|/project>; label or id]*) of all labels or ids that have a single definition
 {my ($labelDefs) = @_;                                                         # Label and Id definitions
  $labelDefs and ref($labelDefs) =~ /hash/is or                                 # Check definitions have been provided
    confess "No labelDefs provided";
  my @singleLabelDefs;                                                          # Labels or ids with just one definition
  for my $project(sort keys % $labelDefs)                                       # Sub(linkmap = {L<project/>}{L<label or id|Data::Edit::Xml/Labels>}=[</file>; id]) returns true if the processing of each L<file|/file> is to be performed after the link mapping has been analyzed at the start,  Sub(L<parse tree representation of a file|Data::Edit::Xml>, linkmap, L<reloaded linter|Data::Edit::Xml::Lint>) returns true if a L<lint|/lint> is required after each L<file|/file> has been processed, L<files|/file> to reprocess
   {for my $label(sort keys %{$labelDefs->{$project}})                          # Each source label or id
     {if (my $l = $labelDefs->{$project}{$label})                               # Source label or id
       {push @singleLabelDefs, [$project, $label] if @$l == 1;                  # Ids or labels with just one definition
       }
     }
   }

  @singleLabelDefs
 } # singleLabelDefs

sub singleLabelDefsReport($)                                                    # Return a L<report|/report> showing L<label or id|Data::Edit::Xml/Labels> with just one definitions ordered by L<project|/project>, L<label name|Data::Edit::Xml/Labels>
 {my ($labelDefs) = @_;                                                         # Label and Id definitions

  if (my @s = Data::Edit::Xml::Lint::singleLabelDefs                            # Find single label or id definitions
                                         ($labelDefs))
   {my $s = @s;
    return "SingleLabelOrIdDefinitions ($s):\n".formatTable
     ([[qw(Project Label)],
        sort                                                                    # Sort by project and label
         {my $p = $a->[0] cmp $b->[0];
          my $l = $a->[1] cmp $b->[1];
          return $p if $p;
          $l
         } @s
     ]);
   }
  'No SingleLabelOrIdDefinitions'                                               # Zero multiple label or id definitions
 } # singleOrIdDefinitionsReport


#1 Report                                                                       # Methods for L<reporting|Data::Edit::Xml::Lint/report> the results of L<linting|/lint> several L<files|/file>

sub p4($$)                                                                      #P Format a fraction as a percentage to 4 decimal places
 {my ($p, $f) = @_;                                                             # Pass, fail
  my $n = $p + $f;
  $n > 0 or confess "Division by zero";
  my $r = sprintf("%3.4f", 100 * $p / $n);
  $r =~ s/\.0+\Z//gsr                                                           # Remove trailing zeroes
 }

sub report($@)                                                                  # Analyse the results of prior L<lints|/lint> and return a hash reporting various statistics and a L<printable|/print> report
 {my ($outputDirectory, @fileExtensions) = @_;                                  # Directory to clear, types of files to analyze
  my @x;                                                                        # Lints for all L<files|/file>
  for my $dir($outputDirectory)                                                 # Directory
   {for my $ext(@fileExtensions)                                                # Extensions
     {for my $in(fileList(filePathExt($dir, qq(*), $ext)))
       {use Data::Dump qw(dump);
        push @x, Data::Edit::Xml::Lint::read($in);                              # Reload a previously written L<file|/file>
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
    my $q = p4($p, $f);

    push @project, [$project, $p, $f, $p + $f, p4($p, $f)];
   }
  @project = sort {$a->[4] <=> $b->[4]} @project;

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
   {my ($project, $pass, $fail, $total, $percent) = @{$project[$_-1]};
    push @report, sprintf("%4d %8.4f   %4d  %4d  %5d  %s\n",
      $_, $percent, $pass, $fail, $total, $project);
   }

  my @filesFail = sort                                                          # Sort by number of errors, project, file name
                   {my $e = $a->[0] <=> $b->[0];
                    my $p = $a->[1] cmp $b->[1];
                    my $f = $a->[2] cmp $b->[2];
                    return $e if $e;
                    return $p if $p;
                    $f
                   }
                  map {[$files{$_}, $filesToProjects{$_}, $_]}
                  grep {$files{$_} > 0}
                  keys %files;

  if (my $filesFail = @filesFail)                                               # Failing files report
   {push @report, <<END;

$filesFail FailingFiles
   #  Errors  Project       File
END
    for(1..@filesFail)
     {push @report, sprintf("%4d  %6d  %-12.12s  %s\n", $_, @{$filesFail[$_-1]});
     }
   }

  return bless                                                                  # Return report
   {passRatePercent  =>$totalPassFailPercent,
    timestamp        =>$ts,
    numberOfProjects =>$numberOfProjects,
    numberOfFiles    =>$numberOfFiles,
    failingFiles     =>[@filesFail],
    print            =>(join '', @report),
    projects         =>{map {$_->[0]=>$_} @project},
   }, 'Data::Edit::Xml::Lint::Report';
 }

#2 Attributes

if (1)
 {package Data::Edit::Xml::Lint::Report;
  use Data::Table::Text qw(:all);
  genLValueScalarMethods(qw(passRatePercent));                                  # Total number of passes as a percentage of all input files
  genLValueScalarMethods(qw(timestamp));                                        # Timestamp of report
  genLValueScalarMethods(qw(numberOfProjects));                                 # Number of L<projects|/project> defined - each L<project|/project> can contain zero or more L<files|/file>
  genLValueScalarMethods(qw(numberOfFiles));                                    # Number of L<files|/file> encountered
  genLValueScalarMethods(qw(failingFiles));                                     # Array of [number of errors, L<project|/project>, L<files|/file>] ordered from least to most errors
  genLValueScalarMethods(qw(projects));                                         # Hash of "project name"=>[L<project name|/project>, pass, fail, total, percent pass]
  genLValueScalarMethods(qw(print));                                            # A printable L<report|/report> of the above
 }

# podDocumentation

=pod

=encoding utf-8

=head1 Name

L<Data::Edit::Xml::Lint|Data::Edit::Xml::Lint> - L<lint|/lint> xml
L<files|/file> in parallel using xmllint and report the failure rate

=head1 Synopsis

=head2 Linting and reporting

Create some sample xml L<files|/file>, some with errors, lint them in parallel
and retrieve the number of errors and failing L<files|/file>:

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

  say STDERR Data::Edit::Xml::Lint::report($outDir, "xml")->print;              # Report total pass fail rate
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

=head2 Rereading

Once a L<file|/file> has been L<linted|/lint>, it can reread with L<read|/read>
to obtain details about the xml including id=?s defined (see: idDefs below) and
any L<labels|Data::Edit::Xml/Labels> that refer to these id=?s (see: labelDefs
below). Such L<labels|Data::Edit::Xml/Labels> provide additional names for a
node which cannot be stored in the xml itself.

  {catalog    => "/home/phil/hp/dtd/Dtd_2016_07_12/catalog-hpe.xml",
   definition => "bbb",
   docType    => "<!DOCTYPE concept PUBLIC \"-//HPE//DTD HPE DITA Concept//EN\" \"concept.dtd\" []>",
   errors     => 1,
   file       => "out/bbb1.xml",
   foo        => 1,
   header     => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
   idDefs     => { bbb => 1, c1 => 1 },
   labelDefs  => {
                   bbb => "bbb",
                   c1 => "c1",
                   conbody1 => "c1",
                   conbody2 => "c1",
                   concept1 => "bbb",
                   concept2 => "bbb",
                 },
   labels     => "bbb concept1 concept2",
   project    => "bbb",
   sha256     => "b00cdebf2e1837fa15140d25315e5558ed59eb735b5fad4bade23969babf9531",
   source     => "..."
  }

=head2 ReLinting

In order to fix references between L<files|/file>, a list of L<files|/file> can be
L<relinted|/relint>:

=over 2

=item 1

the specified L<files|/file> are L<read|/read>

=item 2

a map is constructed to locate all the ids and labels defined in the specified
L<files|/file>

=item 3

each L<file|/file> is L<reparsed|Data::Edit::Xml/new>

=item 4

the resulting L<parse tree|Data::Edit::Xml/new> and id map are handed to a caller provided 𝘀𝘂𝗯 that
can the traverse the L<parse tree|Data::Edit::Xml/new> fixing attributes which make references between
the L<files|/file>.

=item 5

the modified L<parse trees|Data::Edit::Xml/new> are written back to the
originating L<file|/file> thus fixing the changes

=back

=head1 Description

=head2 Constructor

Construct a new linter

=head3 new()

Create a new xml linter - call this method statically as in L<Data::Edit::Xml::Lint|/new>


=head3 Attributes

Attributes describing a lint

=head4 author :lvalue

Optional author of the xml - only needed if you want to generate an SDL file map


=head4 catalog :lvalue

Optional catalog file containing the locations of the DTDs used to validate the xml


=head4 ditaType :lvalue

Optional Dita topic type(concept|task|troubleshooting|reference) of the xml - only needed if you want to generate an SDL file map


=head4 docType :lvalue

The second line: the document type extracted from the L<source|/source>


=head4 dtds :lvalue

Optional directory containing the DTDs used to validate the xml


=head4 errors :lvalue

Number of lint errors detected by xmllint


=head4 file :lvalue

File that the xml will be written to and read from by L<lint|/lint>, L<read|/read> or L<relint|/relint>


=head4 guid :lvalue

Guid for outermost tag - only required if you want to generate an SD file map


=head4 header :lvalue

The first line: the xml header extracted from L<source|/source>


=head4 idDefs :lvalue

{id} = count - the number of times this id is defined in the xml contained in this L<file|/file>


=head4 labelDefs :lvalue

{label or id} = id - the id of the node containing a L<label|Data::Edit::Xml/Labels> defined on the xml


=head4 labels :lvalue

Optional parse tree to supply L<labels|Data::Edit::Xml/Labels> for the current L<source|/source> as the labels are present in the parse tree not in the string representing the parse tree


=head4 linted :lvalue

Date the lint was performed by L<lint|/lint>


=head4 processes :lvalue

Maximum number of xmllint processes to run in parallel - 8 by default


=head4 project :lvalue

Optional L<project|/project> name to allow error counts to be aggregated by L<project|/project> and to allow L<id and labels|Data::Edit::Xml/Labels> to be scoped to the L<files|/file> contained in each L<project|/project>


=head4 reusedInProject :lvalue

List of projects in which this file is reused


=head4 sha256 :lvalue

Sha256 hash of the string containing the xml processed by L<lint|/lint> or L<read|/read>


=head4 source :lvalue

The source Xml to be linted


=head4 title :lvalue

Optional title of the xml - only needed if you want to generate an SDL file map


=head2 Lint

Lint xml L<files|/file> in parallel

=head3 lint($@)

Store some xml in a L<files|/file>, apply xmllint in parallel and update the source file with the results

  1  $lint        Linter
  2  %attributes  Attributes to be recorded as xml comments

=head3 lintNOP($@)

Store some xml in a L<files|/file>, apply xmllint in single and update the source file with the results

  1  $lint        Linter
  2  %attributes  Attributes to be recorded as xml comments

=head3 nolint($@)

Store just the attributes in a file so that they can be retrieved later to process non xml objects referenced in the xml - like images

  1  $lint        Linter
  2  %attributes  Attributes to be recorded as xml comments

=head3 read($)

Reread a linted xml L<file|/file> and extract the L<attributes|/Attributes> associated with the L<lint|/lint>

  1  $file  File containing xml

=head3 waitAllProcesses()

Wait for all L<lints|/lint> to finish - this is a static method, call as Data::Edit::Xml::Lint::wait


=head3 clear(@)

Clear the results of a prior run

  1  @foldersAndExtensions  Directories to clear and extensions of files to remove

=head3 relint($$$@)

Locate all the L<labels or id|Data::Edit::Xml/Labels> in the specified L<files|/file>, analyze the map of labels and ids with B<analysisSub> parse each L<file|/file>, process each parse with B<processSub>, then L<lint/lint> the reprocessed xml back to the original L<file|/file> - this allows you to reprocess the contents of each L<file|/file> with knowledge of where L<labels or id|Data::Edit::Xml/Labels> are located in the other L<files|/file> associated with a L<project|/project>. The B<analysisSub>(linkmap = {project}{labels or id>}=[file, id]) should return true if the processing of each file is to be performed subsequently. The B<processSub>(parse tree representation of a file, id and label mapping, reloaded linter) should return true if a L<lint|/lint> is required to save the results after each L<file|/file> has been processed else false, L<files|/file> to reprocess

  1  $processes             Maximum number of processes to use
  2  $analysisSub           Analysis 𝘀𝘂𝗯
  3  $processSub            Process 𝘀𝘂𝗯
  4  @foldersAndExtensions  Folder containing files to process (recursively)

=head2 Report

Methods for L<reporting|Data::Edit::Xml::Lint/report> the results of L<linting|/lint> several L<files|/file>

=head3 report($@)

Analyse the results of prior L<lints|/lint> and return a hash reporting various statistics and a L<printable|/print> report

  1  $outputDirectory  Directory to clear
  2  @fileExtensions   Types of files to analyze

=head3 Attributes

=head4 passRatePercent :lvalue

Total number of passes as a percentage of all input files


=head4 timestamp :lvalue

Timestamp of report


=head4 numberOfProjects :lvalue

Number of L<projects|/project> defined - each L<project|/project> can contain zero or more L<files|/file>


=head4 numberOfFiles :lvalue

Number of L<files|/file> encountered


=head4 failingFiles :lvalue

Array of [number of errors, L<project|/project>, L<files|/file>] ordered from least to most errors


=head4 projects :lvalue

Hash of "project name"=>[L<project name|/project>, pass, fail, total, percent pass]


=head4 print :lvalue

A printable L<report|/report> of the above



=head1 Private Methods

=head2 lintOP($$@)

Store some xml in a L<files|/file>, apply xmllint in parallel or single and update the source file with the results

  1  $inParallel  In parallel or not
  2  $lint        Linter
  3  %attributes  Attributes to be recorded as xml comments

=head2 formatAttributes(%)

Format the attributes section of the output file

  1  $attributes  Hash of attributes

=head2 waitProcessing($)

Wait for a processor to become available

  1  $processes  Maximum number of processes

=head2 p4($$)

Format a fraction as a percentage to 4 decimal places

  1  $p  Pass
  2  $f  Fail


=head1 Index


L<author|/author>

L<catalog|/catalog>

L<clear|/clear>

L<ditaType|/ditaType>

L<docType|/docType>

L<dtds|/dtds>

L<errors|/errors>

L<failingFiles|/failingFiles>

L<file|/file>

L<formatAttributes|/formatAttributes>

L<guid|/guid>

L<header|/header>

L<idDefs|/idDefs>

L<labelDefs|/labelDefs>

L<labels|/labels>

L<lint|/lint>

L<linted|/linted>

L<lintNOP|/lintNOP>

L<lintOP|/lintOP>

L<new|/new>

L<nolint|/nolint>

L<numberOfFiles|/numberOfFiles>

L<numberOfProjects|/numberOfProjects>

L<p4|/p4>

L<passRatePercent|/passRatePercent>

L<print|/print>

L<processes|/processes>

L<project|/project>

L<projects|/projects>

L<read|/read>

L<relint|/relint>

L<report|/report>

L<reusedInProject|/reusedInProject>

L<sha256|/sha256>

L<source|/source>

L<timestamp|/timestamp>

L<title|/title>

L<waitAllProcesses|/waitAllProcesses>

L<waitProcessing|/waitProcessing>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut


# Tests and documentation

sub test
 {my $p = __PACKAGE__;
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
use Test::More tests=>144;
use Test::SharedFork;
use Data::Edit::Xml;

#Test::More->builder->output("/dev/null");                                      # Show only errors during testing - but this must be commented out for production

if (qx(xmllint --version 2>&1) !~ m/using libxml/)                              # Skip tests if xmllint is not installed
 {my $n = Test::More->builder->expected_tests;
  diag("xmllint not installed - skipping all tests");
  ok 1 for 1..$n;
  exit 0
 }

my $outDir = "out";                                                             # Output directory
my $numberOfFiles    = 10;
my $numberOfProjects = 3;

sub projectName($) {(qw(aaa bbb ccc))[$_[0] % $numberOfProjects]}               # Generate a project name

sub differentFileSameProject($)                                                 # Generate a link to another file
 {my ($n) = @_;
  for my $i($n+1..$numberOfFiles, reverse 1..$n-1)
   {return $i if $i % $numberOfProjects == $n % $numberOfProjects;
   }
  confess "This should not happen";
 }

sub fileShortName($)                                                            # Target file
 {my ($n) = @_;
  my $project = projectName($n);
  filePathExt($project.$n, qq(xml))
 }

sub fileName($)                                                                 # Target file
 {my ($n) = @_;
  my $project = projectName($n);
  filePathExt($outDir, $project.$n, qq(xml))
 }

sub addError($) {$_[0] % 2}                                                     # Introduce an error into some projects

sub catalogName                                                                 # Possible catalog
 {filePathExt(qw(/home phil hp dtd Dtd_2016_07_12 catalog-hpe xml))
 }

sub authorName {'bill@ryffine.com'}                                             # Author
sub ditaTypeValue{'concept'}                                                    # Concept

if (1)                                                                          # Lint some files, report the results, relint them to fix cross file references
 {Data::Edit::Xml::Lint::clear($outDir, "xml");                                 # Remove results of last run

  for my $n(1..$numberOfFiles)                                                  # Some projects
   {my $x = Data::Edit::Xml::Lint::new();                                       # New xml file linter
    my $project  = $x->project  = projectName($n);                              # Project name
    my $r        = differentFileSameProject($n);                                # A sample reference in the same project
    $x->source   = <<END;                                                       # Sample source
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//HPE//DTD HPE DITA Concept//EN" "concept.dtd" []>
<concept id="$project">
 <title>Project $project</title>
 <conbody id="c$n">
   <p>Body of $project 𝝰</p>
   <p>See: <xref href="#c$r"/></p>
 </conbody>
</concept>
END

    if (1)                                                                      # Add some labels
     {my $p = Data::Edit::Xml::new($x->source);
         $p->addLabels(qw(concept1 concept2));
      my $c = $p->get(qw(conbody));
         $c->addLabels(qw(conbody1 conbody2));
      $x->labels = $p;
     }

    $x->author   = authorName;                                                  # Author
    $x->catalog  = catalogName;                                                 # Use catalog if possible
    $x->ditaType = ditaTypeValue;                                               # Dita type
    $x->file     =    fileName($n);                                             # Target file
    $x->source   =~ s/id="\w+?"//gs if addError($n);                            # Introduce an error into some projects
    $x->title    = "Concept $n";                                                # Title of the xml
    $x->guid     = $n;                                                          # Guid for the xml
    $x->lint(foo=>1);                                                           # Write the source to the target file, lint using xmllint, include some attributes to be included as comments at the end of the target file
   }

  waitAllProcesses;                                                             # Wait for lints to complete

  my @files;                                                                    # Files to reprocess
  for my $n(1..$numberOfFiles)                                                  # Check each linted file
   {my $file = fileName($n);                                                    # The file to reload
    push @files, $file;                                                         # List of files to be reprocessed

    my $lint = Data::Edit::Xml::Lint::read($file);                              # Reload the linted file

    delete $lint->{linted};
    is_deeply $lint, &expectedRead if $lint->file eq "out/bbb1.xml";            # Check read results for a specific file

    ok $lint->{foo}   == 1;                                                     # Check the reloaded attributes
    ok $lint->project eq projectName($n);                                       # Check project name for file
    ok $lint->errors  == addError($n);                                          # Check errors in file
    ok $lint->docType eq "<!DOCTYPE concept PUBLIC \"-//HPE//DTD HPE DITA Concept//EN\" \"concept.dtd\" []>";
    ok $lint->header  eq "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";

    if (my $l = $lint->labelDefs)
     {my $p = $lint->project;
      my $c = "c".$n;
      my %l = %$l;
      is_deeply {$p=>1, $c=>1}, $lint->idDefs;
      is_deeply {$p=>$p,       $c=>$c,
                 conbody1=>$c, conbody2=>$c,
                 concept1=>$p, concept2=>$p,
                }, $lint->labelDefs;

     }
   }

  my $report = Data::Edit::Xml::Lint::report($outDir, "xml");                   # Report total pass fail rate
  delete $report->{$_} for qw(timestamp print);
  is_deeply $report, &expectedReport;

  Data::Edit::Xml::Lint::relint(1,                                              # Reprocess all the files
    sub                                                                         # Analysis sub
     {my ($labelDefs, $filesToGuids) = @_;                                      # Link map, files to guids
      for my $project(sort keys %$labelDefs)                                    # Each project
       {for(sort keys %$labelDefs)
         {ok $_->[1] eq $project                                                # An easy test
            for @{$labelDefs->{$project}{$project}};
         }
       }

      is_deeply &mld, [Data::Edit::Xml::Lint::multipleLabelDefs($labelDefs)];
      is_deeply &sld, [Data::Edit::Xml::Lint::singleLabelDefs($labelDefs)];

      ok resolveFileToGuid($filesToGuids, "out/bbb1.xml") == 1;
      1
     },
    sub                                                                         # Reprocess sub
     {my ($x, $labels, $fileToGuids, $lint) = @_;
      my $s = $x->string;

      $x->by(sub                                                                # Search the supplied parse tree for xrefs to update
       {my ($o) = @_;
        if ($o->at(qw(xref)))
         {my $h = $o->href =~ s(\A#)()gsr;
          if (my ($f) = resolveUniqueLink($labels, $h))
           {$o->href = "$f#$h";
           }
          else
           {confess "No target for $h in ".$lint->file;
           }
         }
        });
       ok $x->string ne $s;                                                     # Confirm that xml has been changed
       ok $s         !~ /xml#c/;
       ok $x->string =~ /xml#c/;
      1
     }, $outDir, "xml"
   );

  if (1)                                                                        # Confirm xref edits
   {my @s = split /\n/, readFile("out/bbb10.xml");
    ok $s[9] =~ m(<xref href=\"out/bbb7.xml#c7\"/>);
   }

  if (1)
   {my @s = split /\n/, readFile("out/bbb7.xml");
    ok $s[9] =~ m(<xref href="out/bbb10.xml#c10"/>);
   }

  if (1)
   {my @s = split /\n/, readFile("out/bbb1.xml");
    ok $s[9] =~ m(<xref href="out/bbb4.xml#c4"/>);
   }

  if (1)
   {my @f = searchDirectoryTreesForMatchingFiles($outDir, "xml");               # Remove results of last run
    is_deeply [sort {$a cmp $b} @files],
              [sort {$a cmp $b} @f];
   }
  Data::Edit::Xml::Lint::clear($outDir, "xml");                                 # Remove results of last run
  ok !scalar(searchDirectoryTreesForMatchingFiles($outDir, "xml"));             # Confirm removal

  rmdir $outDir;                                                                # Remove test folder
  ok !-d $outDir;                                                               # Confirm removal
 }

if (1)                                                                          # Nolint some files to save some attributes then read them to retrieve the attributes
 {my $project = qq(ppp);
  my $l       = Data::Edit::Xml::Lint::new();
  $l->file    = filePathExt($outDir, qw(test xml));
  $l->project = qq(ppp);
  $l->nolint(a=>1,b=>2);
  my $L = Data::Edit::Xml::Lint::read($l->file);
  ok $L->{a} == 1;
  ok $L->{b} == 2;
  ok $L->project eq $project;
 }

sub sld()                                                                       ## Expected single definition of labels or ids

 {[
  ["aaa", "c3"],
  ["aaa", "c6"],
  ["aaa", "c9"],
  ["bbb", "c1"],
  ["bbb", "c10"],
  ["bbb", "c4"],
  ["bbb", "c7"],
  ["ccc", "c2"],
  ["ccc", "c5"],
  ["ccc", "c8"],
 ]}

sub mld()                                                                       ## Expected multiple definition of labels or ids
 {[[
    "aaa",
    "aaa",
    [
      ["out/aaa3.xml", "aaa"],
      ["out/aaa6.xml", "aaa"],
      ["out/aaa9.xml", "aaa"],
    ],
  ],
  [
    "aaa",
    "conbody1",
    [
      ["out/aaa3.xml", "c3"],
      ["out/aaa6.xml", "c6"],
      ["out/aaa9.xml", "c9"],
    ],
  ],
  [
    "aaa",
    "conbody2",
    [
      ["out/aaa3.xml", "c3"],
      ["out/aaa6.xml", "c6"],
      ["out/aaa9.xml", "c9"],
    ],
  ],
  [
    "aaa",
    "concept1",
    [
      ["out/aaa3.xml", "aaa"],
      ["out/aaa6.xml", "aaa"],
      ["out/aaa9.xml", "aaa"],
    ],
  ],
  [
    "aaa",
    "concept2",
    [
      ["out/aaa3.xml", "aaa"],
      ["out/aaa6.xml", "aaa"],
      ["out/aaa9.xml", "aaa"],
    ],
  ],
  [
    "bbb",
    "bbb",
    [
      ["out/bbb1.xml", "bbb"],
      ["out/bbb10.xml", "bbb"],
      ["out/bbb4.xml", "bbb"],
      ["out/bbb7.xml", "bbb"],
    ],
  ],
  [
    "bbb",
    "conbody1",
    [
      ["out/bbb1.xml", "c1"],
      ["out/bbb10.xml", "c10"],
      ["out/bbb4.xml", "c4"],
      ["out/bbb7.xml", "c7"],
    ],
  ],
  [
    "bbb",
    "conbody2",
    [
      ["out/bbb1.xml", "c1"],
      ["out/bbb10.xml", "c10"],
      ["out/bbb4.xml", "c4"],
      ["out/bbb7.xml", "c7"],
    ],
  ],
  [
    "bbb",
    "concept1",
    [
      ["out/bbb1.xml", "bbb"],
      ["out/bbb10.xml", "bbb"],
      ["out/bbb4.xml", "bbb"],
      ["out/bbb7.xml", "bbb"],
    ],
  ],
  [
    "bbb",
    "concept2",
    [
      ["out/bbb1.xml", "bbb"],
      ["out/bbb10.xml", "bbb"],
      ["out/bbb4.xml", "bbb"],
      ["out/bbb7.xml", "bbb"],
    ],
  ],
  [
    "ccc",
    "ccc",
    [
      ["out/ccc2.xml", "ccc"],
      ["out/ccc5.xml", "ccc"],
      ["out/ccc8.xml", "ccc"],
    ],
  ],
  [
    "ccc",
    "conbody1",
    [
      ["out/ccc2.xml", "c2"],
      ["out/ccc5.xml", "c5"],
      ["out/ccc8.xml", "c8"],
    ],
  ],
  [
    "ccc",
    "conbody2",
    [
      ["out/ccc2.xml", "c2"],
      ["out/ccc5.xml", "c5"],
      ["out/ccc8.xml", "c8"],
    ],
  ],
  [
    "ccc",
    "concept1",
    [
      ["out/ccc2.xml", "ccc"],
      ["out/ccc5.xml", "ccc"],
      ["out/ccc8.xml", "ccc"],
    ],
  ],
  [
    "ccc",
    "concept2",
    [
      ["out/ccc2.xml", "ccc"],
      ["out/ccc5.xml", "ccc"],
      ["out/ccc8.xml", "ccc"],
    ],
  ],
]}

sub expectedReport
{{failingFiles     => [
                        [1, "aaa", "out/aaa3.xml"],
                        [1, "aaa", "out/aaa9.xml"],
                        [1, "bbb", "out/bbb1.xml"],
                        [1, "bbb", "out/bbb7.xml"],
                        [1, "ccc", "out/ccc5.xml"],
                      ],
  numberOfFiles    => 10,
  numberOfProjects => 3,
  passRatePercent  => 50,
  projects         => {
                        aaa => ["aaa", 1, 2, 3, 33.3333],
                        bbb => ["bbb", 2, 2, 4, 50],
                        ccc => ["ccc", 2, 1, 3, 66.6667],
                      },
   }
 }

sub expectedRead
{{author     => "bill\@ryffine.com",
  catalog    => "/home/phil/hp/dtd/Dtd_2016_07_12/catalog-hpe.xml",
  definition => "bbb",
  ditaType   => "concept",
  docType    => "<!DOCTYPE concept PUBLIC \"-//HPE//DTD HPE DITA Concept//EN\" \"concept.dtd\" []>",
  errors     => 1,
  file       => "out/bbb1.xml",
  foo        => 1,
  guid       => 1,
  header     => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
  idDefs     => { bbb => 1, c1 => 1 },
  labelDefs  => {
                  bbb => "bbb",
                  c1 => "c1",
                  conbody1 => "c1",
                  conbody2 => "c1",
                  concept1 => "bbb",
                  concept2 => "bbb",
                },
  labels     => "bbb concept1 concept2",
  project    => "bbb",
  reusedInProject=>[],
  sha256     => "b00cdebf2e1837fa15140d25315e5558ed59eb735b5fad4bade23969babf9531",
  source     => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//HPE//DTD HPE DITA Concept//EN\" \"concept.dtd\" []>\n<concept >\n <title>Project bbb</title>\n <conbody >\n   <p>Body of bbb \xF0\x9D\x9D\xB0</p>\n   <p>See: <xref href=\"#c4\"/></p>\n </conbody>\n</concept>",
  title      => "Concept 1",
}}
