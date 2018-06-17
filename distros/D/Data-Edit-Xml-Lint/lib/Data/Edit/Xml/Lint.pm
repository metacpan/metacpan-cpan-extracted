#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Lint xml files in parallel using xmllint and report the failure rate
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------
# podDocumentation
# Id definitions should be processed independently of labels
# What sort of tag is on the end of the link?
# Report resolved, unresolved, missing links - difficult because of forking
# Pass Fail statistics should be repeated at bottom to be more usable on terminals

package Data::Edit::Xml::Lint;
our $VERSION = 20180616;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp qw(cluck confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Digest::SHA qw(sha256_hex);
use Encode;

#1 Constructor                                                                  # Construct a new linter

sub new                                                                         # Create a new xml linter - call this method statically as in L<Data::Edit::Xml::Lint|/new>
 {bless {}                                                                      # Create xml linter
 }

#2 Attributes                                                                   # Attributes describing a lint

genLValueScalarMethods(qw(author));                                             # Optional author of the xml - only needed if you want to generate an SDL file map
genLValueScalarMethods(qw(catalog));                                            # Optional catalog file containing the locations of the DTDs used to validate the xml
genLValueScalarMethods(qw(compressedErrors));                                   # Number of compressed errors
genLValueScalarMethods(qw(compressedErrorText));                                # Text of compressed errors
genLValueScalarMethods(qw(ditaType));                                           # Optional Dita topic type(concept|task|troubleshooting|reference) of the xml - only needed if you want to generate an SDL file map
genLValueScalarMethods(qw(docType));                                            # The second line: the document type extracted from the L<source|/source>
genLValueScalarMethods(qw(dtds));                                               # Optional directory containing the DTDs used to validate the xml
genLValueScalarMethods(qw(errors));                                             # Number of uncompressed lint errors detected by xmllint
genLValueScalarMethods(qw(errorText));                                          # Text of uncompressed lint errors detected by xmllint
genLValueScalarMethods(qw(file));                                               # File that the xml will be written to and read from by L<lint|/lint>, L<read|/read> or L<relint|/relint>
genLValueScalarMethods(qw(fileNumber));                                         # File number - assigned early on by the caller to help debugging transformations
genLValueScalarMethods(qw(guid));                                               # Guid for outermost tag - only required if you want to generate an SD file map
genLValueScalarMethods(qw(header));                                             # The first line: the xml header extracted from L<source|/source>
genLValueScalarMethods(qw(idDefs));                                             # {id} = count - the number of times this id is defined in the xml contained in this L<file|/file>
genLValueScalarMethods(qw(labelDefs));                                          # {label or id} = id - the id of the node containing a L<label|Data::Edit::Xml/Labels> defined on the xml
genLValueScalarMethods(qw(labels));                                             # Optional parse tree to supply L<labels|Data::Edit::Xml/Labels> for the current L<source|/source> as the labels are present in the parse tree not in the string representing the parse tree
genLValueScalarMethods(qw(linted));                                             # Date the lint was performed by L<lint|/lint>
genLValueScalarMethods(qw(preferredSource));                                    # Preferred representation of the xml source, used by L<relint|/relint> to supply a preferred representation for the source
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

  for(qw(author catalog ditaType dtds file fileNumber guid project title))      # Map parameters to attributes
   {my $a = $lint->$_;
    $attributes{$_} = $a if $a;
   }

  $attributes{docType} = $lines[1];                                             # Source details
  $attributes{header}  = $lines[0];
  $attributes{sha256}  = sha256_hex(encode("ascii", $lint->source));            # Digest of source string

  my $time   = "<!--linted: ".dateStamp." -->\n";                               # Time stamp marks the start of the added comments
  my $attr   = &formatAttributes({%attributes});                                # Attributes to be recorded with the xml

  my $labels = sub                                                              # Process any labels in the parse tree
   {return '' unless $lint->labels;                                             # No supplied parse tree in which to finds ids and labels
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

        for(grep {m(\s)s} @labels)                                             # Complain about any white space in the label
         {cluck "Whitespace in label removed: $_";
          s(\s) ()gs                                                            # Remove whitespace
         }

        $s .= "<!--labels: $i ".join(' ', @labels)." -->\n";
        my $l = $lint->labelDefs //= {};                                        # Labels for this file
        $l->{$_} = $i for @labels;                                              # Link each label to its primary id
       }
     });
    $s
   }->();

  my $reusedInProject = sub                                                     # Process any reused in project comments
   {my $rip = $lint->reusedInProject;
    return '' unless $rip;
    my $s = '';
    $s .= &reuseInProject($_) for @$rip;
    $s
   }->();

  my $source = $lint->source."\n$time\n$attr\n$labels$reusedInProject";         # Xml plus comments
  writeFile($file, $source);                                                    # Write xml to file

  if (my $v = qx(xmllint --version 2>&1))                                       # Check xmllint is present
   {unless ($v =~ m(\Axmllint)is)
     {confess "xmllint missing, install with:\nsudo apt-get install libxml2-utils";
     }
   }
#Install You will also need to install B<xmllint>:\m  sudo apt-get install libxml2-utils
  my $c = sub                                                                   # Lint command
   {my $d = $lint->dtds;                                                        # Optional dtd to use
    my $f = $file;                                                              # File name
    my $p = " --noent --noout --valid";                                         # Suppress printed output and entity transformation, validate
    return qq(xmllint --path "$d" $p "$f" 2>&1) if $d;                          # Lint against DTDs
    my $c = $lint->catalog;                                                     # Optional dtd catalog to use
    return qq(xmllint $p - < "$f" 2>&1) unless $c;                              # Normal lint
    qq(export XML_CATALOG_FILES='$c' && xmllint $p - < '$f' 2>&1)               # Catalog lint
   }->();

  if (my @errors = qx($c))                                                      # Perform lint and add errors as comments
   {my $s = readFile($file);
    my $e = join '', map {chomp; "<!-- $_ -->\n"} @errors;
    my $n = $lint->errors = int @errors / 3;                                    # Three lines per error message

    my $t = "<!--errors: $n -->";
    my $c = &compressErrors(@errors);                                           # Compress the errors per Micaela
    writeFile($file, "$source\n$time$e\n$t$c");                                 # Update xml file with errors
   }
  else                                                                          # No errors detected
   {$lint->errors = 0;
   }

  exit if $inParallel;
 } # lint

sub compressErrors(@)                                                           #PS Compress the errors so we cound the ones that do not look similar. Errors typically occupy three lines with the last line containing ^ at the end to mark the location of the error.
 {my (@errors) = @_;                                                            # Errors
  my %c;
  my @e;

  for(1..@errors)                                                               # Group errors in threes to make an error line
   {push @e, $errors[$_-1] if $_ % 3 == 1;
   }
  for(@e)                                                                       # Reduce error line
   {my $c =  s(-:\d+?:) ()sr;                                                   # Remove line number
       $c =~ s(\s+\^\Z) ()s;                                                    # Remove error pointer
       $c =~ s(expected:.*) ()s;                                                # Remove expected
    $c{$c}++;
   }                                                                            # Format compressed errors block
  if (my $n = scalar(keys %c))
   {my @t = (qq(<!--compressedErrors: $n -->));                                 # Number of errors
    for my $e(sort keys %c)                                                     # Each unique reduced error line
     {push @t, qq(<!--${e}-->);
     }
    my $t = join "\n", '', @t;
    return $t;
   }
  qq(<!--compressedErrors: 0 -->);                                              # No errors
 }

sub nolint($@)                                                                  # Store just the attributes in a file so that they can be retrieved later to process non xml objects referenced in the xml - like images
 {my ($lint, %attributes) = @_;                                                 # Linter, attributes to be recorded as xml comments
  !$lint->source or confess "Source specified for nolint(), use lint()";        # Source not permitted for nolint()
  my $file = $lint->file;                                                       # File to be written to
     $file or confess "Use the ->file method to provide the target file";       # Check that we have an output file

# for(qw(author ditaType file guid project title))                              # Map parameters to attributes
  for(qw(author catalog ditaType docType dtds errors file guid header idDefs),
      qw(labelDefs labels linted processes project sha256),
      qw(source title))
   {my $a = $lint->$_;
    $attributes{$_}  = $a if $a;
   }

  my $time = "<!--linted: ".dateStamp." -->\n";                                 # Time stamp marks the start of the added comments
  my $attr = &formatAttributes({%attributes});                                  # Attributes to be recorded with the xml

  if (my $r = $lint->{reusedInProject})
   {$attr .= &reuseInProject($_) for @$r;
   }

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

  my ($S, @S) = split /(?=<!--linted:)/s, $s;                                   # Split source on errors
  my ($U, $C) = split /(?=<!--compressedErrors:)/s, $S[-1];                     # Split errors
  my @U = $U ? split /\n+/, $U : ();                                            # Split uncompressed errors
  my @C = $C ? split /\n+/, $C : ();                                            # Split   compressed errors
  shift @C;                                                                     # Remove the number of compressed errors
  $_ = nws($_) for @C;                                                          # Normalize white space

  my $lint = bless                                                              # Create a matching linter
   {%a,                                                                         # Directly loaded fields
    source              =>  $S,                                                 # Computed fields
    header              =>  $a[0],
    docType             =>  $a[1],
    idDefs              =>  $d,
    labelDefs           =>  $l,
    reusedInProject     => [sort keys %$r],
    compressedErrorText => [@C],
    errorText           => [@U],
   };

  $lint->errors //= 0;
  $lint->compressedErrors //= 0;
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

sub relint($$$@)                                                                # Locate all the L<labels or id|Data::Edit::Xml/Labels> in the specified L<files|/file>, analyze the map of labels and ids with B<analysisSub> parse each L<file|/file>, process each parse with B<processSub>, then L<lint/lint> the reprocessed xml back to the original L<file|/file> - this allows you to reprocess the contents of each L<file|/file> with knowledge of where L<labels or id|Data::Edit::Xml/Labels> are located in the other L<files|/file> associated with a L<project|/project>. The B<analysisSub>(linkmap = {project}{labels or id>}=[file, id]) should return true if the processing of each file is to be performed subsequently. The B<processSub>(parse tree representation of a file, id and label mapping, reloaded linter) should return true if a L<lint|/lint> is required to save the results after each L<file|/file> has been processed else false. Optionally, the B<analysisSub> may set the L<preferredSource|/preferredSource> attribute to indicate the preferred representation of the xml.
 {my ($processes, $analysisSub, $processSub, @foldersAndExtensions) = @_;       # Maximum number of processes to use, analysis 𝘀𝘂𝗯, Process 𝘀𝘂𝗯, folder containing files to process (recursively), extensions of files to process
  my @files = searchDirectoryTreesForMatchingFiles(@foldersAndExtensions);      # Search for files to relint
  my $links;                                                                    # {project}{label or id} = [file, label or id] : the file containing  each label or id in each project
  my $fileToGuid;                                                               # {file name} to guid
  for my $file(@files)                                                          # Reload each file to reprocess
   {my $lint = Data::Edit::Xml::Lint::read($file);                              # Reconstructed linter

    if (my $g = $lint->guid)                                                    # Record file to guid mapping
     {if (my $lintFile = $lint->file)
       {if (my $G = $fileToGuid->{$lintFile})
         {if ($g ne $G)
           {confess "Guids $g and $G are both used for file $lintFile"
           }
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
      $@ and cluck "$@\nFailed to parse file:\n$file";                          # Xml file failed to parse
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
       }
      else
       {if ($processSub->($x, $links->{$lint->project}, $fileToGuid, $lint))    # Call user method to process parse tree with labels in place and the location of all the labels and ids
         {my $l = $lint;                                                        # Shorten name
          my $s = $l->preferredSource // $x->prettyString;                      # Representation of xml
          $l->source = join "\n", $l->header, $l->docType, $s;                  # Reconstruct source
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
  if ($link =~ m(\s)s)                                                          # Complain about any white space in the label
   {cluck "Whitespace in label removed: $link";
    $link =~ s(\s) ()gs;                                                        # Remove white space from label
   }
  my $l = $linkMap->{$link};                                                    # Attempt to resolve link
  return () unless $l;                                                          # No definition
  return () if @$l != 1;                                                        # Too many definitions
  @{$l->[0]}                                                                    # (file, leading id)
 } # resolveUniqueLink

sub reuseInProject($)                                                           # Record the reuse of an item in the named project
 {my ($project) = @_;                                                           # Name of the project in which it is reused
  qq(\n<!--reusedInProject: $project -->);
 }

sub reuseFileInProject($$)                                                      # Record the reuse of the specified file in the specified project
 {my ($file, $project) = @_;                                                    # Name of file that is being reused, name of project in which it is reused
  appendFile($file, reuseInProject($project));                                  # Add a reuse record to the file being reused.
 }

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
 {my ($labelDefs) = @_;
  return () unless $labelDefs;                                                  # Label and Id definitions
  ref($labelDefs) =~ /hash/is or confess "No labelDefs provided";               # Check definitions have been provided

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

sub report($;$)                                                                 # Analyse the results of prior L<lints|/lint> and return a hash reporting various statistics and a L<printable|/print> report
 {my ($outputDirectory, $filter) = @_;                                          # Directory to search, optional regular expression to filter files

  my @x;                                                                        # Lints for all L<files|/file>
  for my $in(findFiles($outputDirectory))                                       # Find files to report on
   {next if $filter and $in !~ m($filter);                                      # Filter files if a filter has been supplied
    push @x, Data::Edit::Xml::Lint::read($in);                                  # Reload a previously written L<file|/file>
   }
  confess "No files selected" unless @x;                                        # No files selected

  my %projects;                                                                 # Pass/Fail by project
  my %files;                                                                    # Pass fail by file
  my %filesToProjects;                                                          # Project from file name
  my $totalErrors = 0;                                                          # Total number of errors
  my $totalCompressedErrorsFileByFile = 0;                                      # Total number of errors summed file by file
  my %CE;                                                                       # Compressed errors over all files

  for my $x(@x)                                                                 # Aggregate the results of individual lints
   {my $project = $x->project // 'unknown';
    my $file    = $x->file;
    my $cErrors = $x->compressedErrors;                                         # Compressed errors
    my $errors  = $x->errors;                                                   # Number of uncompressed errors
    my $cet     = $x->compressedErrorText;                                      # Compressed errors
    my $et      = $x->errorText;                                                # Uncompressed error text
    $filesToProjects{$file} = $project;
    my $pf = $errors ? qq(fail) : qq(pass);
    $projects{$project}{$pf}++;
    $files{$file}                     = $cErrors;
    $totalErrors                     += $errors;
    $totalCompressedErrorsFileByFile += $cErrors;

    if ($cet)                                                                   # Compressed errors over all files
     {for(@$cet)
       {$CE{$_}++;
       }
     }
   }

  my @passingProjects;
  my @failingProjects;
  for my $project(sort keys %projects)                                          # Count pass/fail files by project
   {my $p = $projects{$project}{pass} // 0;
    my $f = $projects{$project}{fail} // 0;
    my $q = p4($p, $f);

    if ($f)
     {push @failingProjects, [$project, $p, $f, $p + $f, p4($p, $f)];
     }
    else
     {push @passingProjects, [$project, $p];
     }
   }
  @failingProjects = sort {$a->[4] <=> $b->[4]} @failingProjects;
  @passingProjects = sort {$a->[0] cmp $b->[0]} @passingProjects;

  my $totalNumberOfFails    = scalar grep {$files{$_}  > 0} keys %files;
  my $totalNumberOfPasses   = scalar grep {$files{$_} == 0} keys %files;
  my $totalPassFailPercent  = p4($totalNumberOfPasses, $totalNumberOfFails);
  my $ts = dateTimeStamp;
  my $numberOfProjects      = keys %projects;
  my $numberOfFiles         = $totalNumberOfPasses + $totalNumberOfFails;
  my $totalCompressedErrors = scalar keys %CE;

  my @report;
  push @report, sprintf(<<END,                                                  # Report title
$totalPassFailPercent %% success converting $numberOfProjects projects containing $numberOfFiles xml files on $ts

CompressedErrorMessagesByCount (at the end of this file): %8d

FailingFiles   :  %8d
PassingFiles   :  %8d

FailingProjects:  %8d
PassingProjects:  %8d


FailingProjects:  %8d
   #  Percent   Pass  Fail  Total  Project
END
  scalar keys %CE,
  $totalNumberOfFails,
  $totalNumberOfPasses,
  scalar(@failingProjects),
  scalar(@passingProjects),
  scalar(@failingProjects));

  for(1..@failingProjects)                                                      # Failing projects
   {my ($project, $pass, $fail, $total, $percent) = @{$failingProjects[$_-1]};
    push @report, sprintf("%4d %8.4f   %4d  %4d  %5d  %s\n",
      $_, $percent, $pass, $fail, $total, $project);
   }

  push @report, sprintf(<<END,                                                  # Passing projects


PassingProjects:  %8d
   #   Files  Project
END
  scalar(@passingProjects));

  for(1..@passingProjects)
   {my ($project, $files) = @{$passingProjects[$_-1]};
    push @report, sprintf("%4d    %4d  %s\n",
      $_, $files, $project);
   }

  my @filesFail = sort                                                          # Failing files: sort by number of errors, project, file name
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

  if (my $filesFail = @filesFail)
   {push @report, <<END;


FailingFiles: $totalNumberOfFails  Files that failed to pass lint by number of compressed errors
   #  Errors  Project       File
END
    for(1..@filesFail)
     {push @report, sprintf("%4d  %6d  %-12.12s  %s\n", $_, @{$filesFail[$_-1]});
     }
   }

  if (my $N = scalar keys %CE)                                                  # Compressed errors
   {my @ce = sort {$b->[0] <=> $a->[0]}
             map  {[$CE{$_}, $_]}
             keys %CE;
    push @report, <<END;


CompressedErrorMessagesByCount: $N

 Count  Message
END
    for(@ce)
     {my ($count, $message) = @$_;
      $message =~ s(\A<!--) ()gs;
      $message =~ s(-->\Z)  ()gs;
      push @report, sprintf("%6d %s\n", $count, $message);
     }
   }
  return bless {                                                                # Return report
    compressedErrors                => \%CE,
    failingFiles                    => [@filesFail],
    failingProjects                 => [@failingProjects],
    filter                          => $filter,
    numberOfFiles                   => $numberOfFiles,
    numberOfProjects                => $numberOfProjects,
    passingProjects                 => [@passingProjects],
    passRatePercent                 => $totalPassFailPercent,
    print                           => (join '', @report),
    timestamp                       => $ts,
    totalCompressedErrorsFileByFile => $totalCompressedErrorsFileByFile,
    totalCompressedErrors           => scalar keys %CE,
    totalErrors                     => $totalErrors,
   }, 'Data::Edit::Xml::Lint::Report';
 }

#2 Attributes

if (1)
 {package Data::Edit::Xml::Lint::Report;
  use Data::Table::Text qw(:all);
  genLValueScalarMethods(qw(compressedErrors));                                 # Compressed errors over all files
  genLValueScalarMethods(qw(failingFiles));                                     # Array of [number of errors, L<project|/project>, L<files|/file>] ordered from least to most errors
  genLValueScalarMethods(qw(failingProjects));                                  # [Projects with xmllint errors]
  genLValueScalarMethods(qw(filter));                                           # File selection filter
  genLValueScalarMethods(qw(numberOfFiles));                                    # Number of L<files|/file> encountered
  genLValueScalarMethods(qw(numberOfProjects));                                 # Number of L<projects|/project> defined - each L<project|/project> can contain zero or more L<files|/file>
  genLValueScalarMethods(qw(passingProjects));                                  # [Projects with no xmllint errors]
  genLValueScalarMethods(qw(passRatePercent));                                  # Total number of passes as a percentage of all input files
  genLValueScalarMethods(qw(print));                                            # A printable L<report|/report> of the above
  genLValueScalarMethods(qw(timestamp));                                        # Timestamp of report
  genLValueScalarMethods(qw(totalCompressedErrorsFileByFile));                  # Total number of errros summed file by file
  genLValueScalarMethods(qw(totalCompressedErrors));                            # Number of compressed errors
  genLValueScalarMethods(qw(totalErrors));                                      # Total number of errors
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


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Constructor

Construct a new linter

=head2 new()

Create a new xml linter - call this method statically as in L<Data::Edit::Xml::Lint|/new>


=head2 Attributes

Attributes describing a lint

=head3 author :lvalue

Optional author of the xml - only needed if you want to generate an SDL file map


=head3 catalog :lvalue

Optional catalog file containing the locations of the DTDs used to validate the xml


=head3 ditaType :lvalue

Optional Dita topic type(concept|task|troubleshooting|reference) of the xml - only needed if you want to generate an SDL file map


=head3 docType :lvalue

The second line: the document type extracted from the L<source|/source>


=head3 dtds :lvalue

Optional directory containing the DTDs used to validate the xml


=head3 errors :lvalue

Number of lint errors detected by xmllint


=head3 file :lvalue

File that the xml will be written to and read from by L<lint|/lint>, L<read|/read> or L<relint|/relint>


=head3 fileNumber :lvalue

File number - assigned early on by the caller to help debugging transformations


=head3 guid :lvalue

Guid for outermost tag - only required if you want to generate an SD file map


=head3 header :lvalue

The first line: the xml header extracted from L<source|/source>


=head3 idDefs :lvalue

{id} = count - the number of times this id is defined in the xml contained in this L<file|/file>


=head3 labelDefs :lvalue

{label or id} = id - the id of the node containing a L<label|Data::Edit::Xml/Labels> defined on the xml


=head3 labels :lvalue

Optional parse tree to supply L<labels|Data::Edit::Xml/Labels> for the current L<source|/source> as the labels are present in the parse tree not in the string representing the parse tree


=head3 linted :lvalue

Date the lint was performed by L<lint|/lint>


=head3 preferredSource :lvalue

Preferred representation of the xml source, used by L<relint|/relint> to supply a preferred representation for the source


=head3 processes :lvalue

Maximum number of xmllint processes to run in parallel - 8 by default


=head3 project :lvalue

Optional L<project|/project> name to allow error counts to be aggregated by L<project|/project> and to allow L<id and labels|Data::Edit::Xml/Labels> to be scoped to the L<files|/file> contained in each L<project|/project>


=head3 reusedInProject :lvalue

List of projects in which this file is reused


=head3 sha256 :lvalue

Sha256 hash of the string containing the xml processed by L<lint|/lint> or L<read|/read>


=head3 source :lvalue

The source Xml to be linted


=head3 title :lvalue

Optional title of the xml - only needed if you want to generate an SDL file map


=head1 Lint

Lint xml L<files|/file> in parallel

=head2 lint($@)

Store some xml in a L<files|/file>, apply xmllint in parallel and update the source file with the results

     Parameter    Description
  1  $lint        Linter
  2  %attributes  Attributes to be recorded as xml comments

=head2 lintNOP($@)

Store some xml in a L<files|/file>, apply xmllint in single and update the source file with the results

     Parameter    Description
  1  $lint        Linter
  2  %attributes  Attributes to be recorded as xml comments

=head2 nolint($@)

Store just the attributes in a file so that they can be retrieved later to process non xml objects referenced in the xml - like images

     Parameter    Description
  1  $lint        Linter
  2  %attributes  Attributes to be recorded as xml comments

=head1 Report

Methods for L<reporting|Data::Edit::Xml::Lint/report> the results of L<linting|/lint> several L<files|/file>

=head2 report($$)

Analyse the results of prior L<lints|/lint> and return a hash reporting various statistics and a L<printable|/print> report

     Parameter         Description
  1  $outputDirectory  Directory to search
  2  $filter           Optional regular expression to filter files

=head2 Attributes

=head3 passRatePercent :lvalue

Total number of passes as a percentage of all input files


=head3 timestamp :lvalue

Timestamp of report


=head3 numberOfProjects :lvalue

Number of L<projects|/project> defined - each L<project|/project> can contain zero or more L<files|/file>


=head3 numberOfFiles :lvalue

Number of L<files|/file> encountered


=head3 failingFiles :lvalue

Array of [number of errors, L<project|/project>, L<files|/file>] ordered from least to most errors


=head3 failingProjects :lvalue

[Projects with xmllint errors]


=head3 passingProjects :lvalue

[Projects with no xmllint errors]


=head3 totalErrors :lvalue

Total number of errors


=head3 projects :lvalue

Hash of "project name"=>[L<project name|/project>, pass, fail, total, percent pass]


=head3 print :lvalue

A printable L<report|/report> of the above



=head1 Private Methods

=head2 lintOP($$@)

Store some xml in a L<files|/file>, apply xmllint in parallel or single and update the source file with the results

     Parameter    Description
  1  $inParallel  In parallel or not
  2  $lint        Linter
  3  %attributes  Attributes to be recorded as xml comments

=head2 p4($$)

Format a fraction as a percentage to 4 decimal places

     Parameter  Description
  1  $p         Pass
  2  $f         Fail


=head1 Index


1 L<author|/author>

2 L<catalog|/catalog>

3 L<ditaType|/ditaType>

4 L<docType|/docType>

5 L<dtds|/dtds>

6 L<errors|/errors>

7 L<failingFiles|/failingFiles>

8 L<failingProjects|/failingProjects>

9 L<file|/file>

10 L<fileNumber|/fileNumber>

11 L<guid|/guid>

12 L<header|/header>

13 L<idDefs|/idDefs>

14 L<labelDefs|/labelDefs>

15 L<labels|/labels>

16 L<lint|/lint>

17 L<linted|/linted>

18 L<lintNOP|/lintNOP>

19 L<lintOP|/lintOP>

20 L<new|/new>

21 L<nolint|/nolint>

22 L<numberOfFiles|/numberOfFiles>

23 L<numberOfProjects|/numberOfProjects>

24 L<p4|/p4>

25 L<passingProjects|/passingProjects>

26 L<passRatePercent|/passRatePercent>

27 L<preferredSource|/preferredSource>

28 L<print|/print>

29 L<processes|/processes>

30 L<project|/project>

31 L<projects|/projects>

32 L<report|/report>

33 L<reusedInProject|/reusedInProject>

34 L<sha256|/sha256>

35 L<source|/source>

36 L<timestamp|/timestamp>

37 L<title|/title>

38 L<totalErrors|/totalErrors>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Data::Edit::Xml::Lint

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
use Test::More tests=>103;
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

sub createTest($$;$)                                                           # Create a test
 {my ($project, $source, $target, $additional) = @_;
  $additional //= '';
  [$project, $source, $target, $additional, <<END]
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//HPE//DTD HPE DITA Concept//EN" "concept.dtd" []>
<concept id="c_${project}_${source}">
 <title>project=$project source=$source target=$target</title>
 <conbody id="b_${project}_${source}">
   <p>See: <xref href="B_${project}_${target}"/></p>$additional
 </conbody>
</concept>
END
 }

sub tests                                                                       # Create tests
 {my @tests;
  for my $project(qw(aaa bbb ccc ddd))
   {push @tests,
     (createTest($project, 1, 1),
      createTest($project, 2, 1),
      createTest($project, 3, 2),
      createTest($project, 4, 3));
   }
  @tests
 }

# Test without file reuse
my @lints;                                                                      # Lints for each test
my %tests;                                                                      # Tests by title

for my $test(tests)                                                             # Each test within the current project
 {my ($project, $source, $target, $additional, $xml) = @$test;

  my $x = Data::Edit::Xml::new($xml);
     $x->addLabels("C1_${project}_$source","C2_${project}_$source");
  my $c = $x->go(qw(conbody));
     $c->addLabels("B1_${project}_$source","B2_${project}_$source");

  my $lint = Data::Edit::Xml::Lint::new;                                        # Lint each test file
  push @lints, [$lint, $test];
  $lint->project   = $project;
  $lint->labels    = $x;
  $lint->author    = 'author@author.com';                                       # Author
  $lint->file      = filePathExt($outDir, $project.$source, qw(xml));           # Target file
  $lint->source    = $xml;                                                      # Xml source
  $lint->guid      = my $g = "$project.$source";                                # Guid for this topic
  $lint->lint(foo=>1);                                                          # Write the source to the target file, lint using xmllint, include some attributes to be included as comments at the end of the target file
  $tests{$g} = [$lint, @$test];                                                 # Tests
 }

ok @lints == 16;

waitAllProcesses;                                                               # Wait for lints to complete

my $report = Data::Edit::Xml::Lint::report($outDir, "xml");
delete $report->{$_} for qw(timestamp print);

is_deeply $report,
 {failingFiles     => [],
  numberOfFiles    => 16,
  numberOfProjects => 4,
  passRatePercent  => 100,
  projects         => {
                      aaa => ["aaa", 4, 0, 4, 100],
                      bbb => ["bbb", 4, 0, 4, 100],
                      ccc => ["ccc", 4, 0, 4, 100],
                      ddd => ["ddd", 4, 0, 4, 100],
                    },
 } if 0; # Where will we find the DTD's required by xmllint?

Data::Edit::Xml::Lint::relint(1,                                                # Reprocess all the files
  sub                                                                           # Analysis sub
   {my ($labels, $filesToGuids) = @_;                                           # Link map, files to guids
    is_deeply($labels,       &labelsInXml);
    is_deeply($filesToGuids, &filesToGuidsX);

    my $r = resolveFileToGuid($filesToGuids, "out/ddd4.xml");                   # Return the unique definition of the specified link in the link map or undef if no such definition exists
    ok $r eq "ddd.4";
    ok multipleLabelDefsReport($labels) eq "No MultipleLabelOrIdDefinitions";

    my $s = singleLabelDefsReport($labels) =~ s(\n) (N)gsr;
    ok $s eq "SingleLabelOrIdDefinitions (96):N 1  Project  Label     N 2  aaa      B1_aaa_1  N 3  aaa      B1_aaa_2  N 4  aaa      B1_aaa_3  N 5  aaa      B1_aaa_4  N 6  aaa      B2_aaa_1  N 7  aaa      B2_aaa_2  N 8  aaa      B2_aaa_3  N 9  aaa      B2_aaa_4  N10  aaa      C1_aaa_1  N11  aaa      C1_aaa_2  N12  aaa      C1_aaa_3  N13  aaa      C1_aaa_4  N14  aaa      C2_aaa_1  N15  aaa      C2_aaa_2  N16  aaa      C2_aaa_3  N17  aaa      C2_aaa_4  N18  aaa      b_aaa_1   N19  aaa      b_aaa_2   N20  aaa      b_aaa_3   N21  aaa      b_aaa_4   N22  aaa      c_aaa_1   N23  aaa      c_aaa_2   N24  aaa      c_aaa_3   N25  aaa      c_aaa_4   N26  bbb      B1_bbb_1  N27  bbb      B1_bbb_2  N28  bbb      B1_bbb_3  N29  bbb      B1_bbb_4  N30  bbb      B2_bbb_1  N31  bbb      B2_bbb_2  N32  bbb      B2_bbb_3  N33  bbb      B2_bbb_4  N34  bbb      C1_bbb_1  N35  bbb      C1_bbb_2  N36  bbb      C1_bbb_3  N37  bbb      C1_bbb_4  N38  bbb      C2_bbb_1  N39  bbb      C2_bbb_2  N40  bbb      C2_bbb_3  N41  bbb      C2_bbb_4  N42  bbb      b_bbb_1   N43  bbb      b_bbb_2   N44  bbb      b_bbb_3   N45  bbb      b_bbb_4   N46  bbb      c_bbb_1   N47  bbb      c_bbb_2   N48  bbb      c_bbb_3   N49  bbb      c_bbb_4   N50  ccc      B1_ccc_1  N51  ccc      B1_ccc_2  N52  ccc      B1_ccc_3  N53  ccc      B1_ccc_4  N54  ccc      B2_ccc_1  N55  ccc      B2_ccc_2  N56  ccc      B2_ccc_3  N57  ccc      B2_ccc_4  N58  ccc      C1_ccc_1  N59  ccc      C1_ccc_2  N60  ccc      C1_ccc_3  N61  ccc      C1_ccc_4  N62  ccc      C2_ccc_1  N63  ccc      C2_ccc_2  N64  ccc      C2_ccc_3  N65  ccc      C2_ccc_4  N66  ccc      b_ccc_1   N67  ccc      b_ccc_2   N68  ccc      b_ccc_3   N69  ccc      b_ccc_4   N70  ccc      c_ccc_1   N71  ccc      c_ccc_2   N72  ccc      c_ccc_3   N73  ccc      c_ccc_4   N74  ddd      B1_ddd_1  N75  ddd      B1_ddd_2  N76  ddd      B1_ddd_3  N77  ddd      B1_ddd_4  N78  ddd      B2_ddd_1  N79  ddd      B2_ddd_2  N80  ddd      B2_ddd_3  N81  ddd      B2_ddd_4  N82  ddd      C1_ddd_1  N83  ddd      C1_ddd_2  N84  ddd      C1_ddd_3  N85  ddd      C1_ddd_4  N86  ddd      C2_ddd_1  N87  ddd      C2_ddd_2  N88  ddd      C2_ddd_3  N89  ddd      C2_ddd_4  N90  ddd      b_ddd_1   N91  ddd      b_ddd_2   N92  ddd      b_ddd_3   N93  ddd      b_ddd_4   N94  ddd      c_ddd_1   N95  ddd      c_ddd_2   N96  ddd      c_ddd_3   N97  ddd      c_ddd_4   N";
   },
  sub                                                                           # Reprocess sub
   {my ($x, $labels, $filesToGuids, $lint) = @_;
    my $project = $lint->project;

    if (1)                                                                      # Prove we can resolve links
     {my $source = "C1_${project}_1";
      my $target = ["out/${project}1.xml", "c_${project}_1"];
      my $resolve = [resolveUniqueLink($labels, $source)];                      # Return the unique (file, leading id) of the specified link in the link map or () if no such definition exists
      is_deeply $target, $resolve;
     }

    if ($project !~ m(\Aaaa\Z)s)                                                # Show that we cannot resolve this link in the other projects
     {my $source = "C1_aaa_1";
      my $target = ["out/aaa1.xml", "c_aaa_1"];
      my ($resolve) = resolveUniqueLink($labels, $source);                      # Return the unique (file, leading id) of the specified link in the link map or () if no such definition exists
      ok !$resolve;
     }

    is_deeply $filesToGuids, &filesToGuidsX;

    1
   }, $outDir, "xml");

# Test with file reuse

if (1)
 {my $reuseFile = filePathExt($outDir, "aaa1", qw(xml));                        # File to reuse in all projects
  for my $project(qw(bbb ccc ddd))
   {reuseFileInProject($reuseFile, $project);                                   # Reuse this file in all the other projects
   }
  my $l = Data::Edit::Xml::Lint::read($reuseFile);
  is_deeply $l->reusedInProject, ["bbb", "ccc", "ddd"];                         # Check reuse has been recorded
 }

Data::Edit::Xml::Lint::relint(1,                                                # Reprocess all the files
  sub                                                                           # Analysis sub
   {my ($labels, $filesToGuids) = @_;                                           # Link map, files to guids
    if (my $a = &labelsInXml)
     {$a->{bbb}{B1_aaa_1}[0] = $a->{aaa}{B1_aaa_1}[0];
      $a->{bbb}{B2_aaa_1}[0] = $a->{aaa}{B2_aaa_1}[0];
      $a->{bbb}{b_aaa_1}[0] = $a->{aaa}{b_aaa_1}[0];
      $a->{bbb}{C1_aaa_1}[0] = $a->{aaa}{C1_aaa_1}[0];
      $a->{bbb}{C2_aaa_1}[0] = $a->{aaa}{C2_aaa_1}[0];
      $a->{bbb}{c_aaa_1}[0] = $a->{aaa}{c_aaa_1}[0];
      $a->{ccc}{B1_aaa_1}[0] = $a->{aaa}{B1_aaa_1}[0];
      $a->{ccc}{B2_aaa_1}[0] = $a->{aaa}{B2_aaa_1}[0];
      $a->{ccc}{b_aaa_1}[0] = $a->{aaa}{b_aaa_1}[0];
      $a->{ccc}{C1_aaa_1}[0] = $a->{aaa}{C1_aaa_1}[0];
      $a->{ccc}{C2_aaa_1}[0] = $a->{aaa}{C2_aaa_1}[0];
      $a->{ccc}{c_aaa_1}[0] = $a->{aaa}{c_aaa_1}[0];
      $a->{ddd}{B1_aaa_1}[0] = $a->{aaa}{B1_aaa_1}[0];
      $a->{ddd}{B2_aaa_1}[0] = $a->{aaa}{B2_aaa_1}[0];
      $a->{ddd}{b_aaa_1}[0] = $a->{aaa}{b_aaa_1}[0];
      $a->{ddd}{C1_aaa_1}[0] = $a->{aaa}{C1_aaa_1}[0];
      $a->{ddd}{C2_aaa_1}[0] = $a->{aaa}{C2_aaa_1}[0];
      $a->{ddd}{c_aaa_1}[0] = $a->{aaa}{c_aaa_1}[0];

      is_deeply($labels, $a);
     }
    is_deeply($filesToGuids, &filesToGuidsX);

    my $r = resolveFileToGuid($filesToGuids, "out/ddd4.xml");                   # Return the unique definition of the specified link in the link map or undef if no such definition exists
    ok $r eq "ddd.4";
    ok multipleLabelDefsReport($labels) eq "No MultipleLabelOrIdDefinitions";
   },
  sub                                                                           # Reprocess sub
   {my ($x, $labels, $filesToGuids, $lint) = @_;
    my $project = $lint->project;

    if (1)
     {my $source = "C1_${project}_1";
      my $target = ["out/${project}1.xml", "c_${project}_1"];
      my $resolve = [resolveUniqueLink($labels, $source)];                      # Return the unique (file, leading id) of the specified link in the link map or () if no such definition exists

      is_deeply $target, $resolve;
     }

    if (1)                                                                      # Show that we can resolve this link in all projects
     {my $source = "C1_aaa_1";
      my $target = ["out/aaa1.xml", "c_aaa_1"];
      my $resolve = [resolveUniqueLink($labels, $source)];                      # Return the unique (file, leading id) of the specified link in the link map or () if no such definition exists
      is_deeply $target, $resolve;
     }

    is_deeply $filesToGuids, &filesToGuidsX;

    1
   }, $outDir, "xml");

sub filesToGuidsX
{{
  "out/aaa1.xml" => "aaa.1",
  "out/aaa2.xml" => "aaa.2",
  "out/aaa3.xml" => "aaa.3",
  "out/aaa4.xml" => "aaa.4",
  "out/bbb1.xml" => "bbb.1",
  "out/bbb2.xml" => "bbb.2",
  "out/bbb3.xml" => "bbb.3",
  "out/bbb4.xml" => "bbb.4",
  "out/ccc1.xml" => "ccc.1",
  "out/ccc2.xml" => "ccc.2",
  "out/ccc3.xml" => "ccc.3",
  "out/ccc4.xml" => "ccc.4",
  "out/ddd1.xml" => "ddd.1",
  "out/ddd2.xml" => "ddd.2",
  "out/ddd3.xml" => "ddd.3",
  "out/ddd4.xml" => "ddd.4",
}}

sub labelsInXml
 {{aaa => {
           B1_aaa_1 => [["out/aaa1.xml", "b_aaa_1"]],
           B1_aaa_2 => [["out/aaa2.xml", "b_aaa_2"]],
           B1_aaa_3 => [["out/aaa3.xml", "b_aaa_3"]],
           B1_aaa_4 => [["out/aaa4.xml", "b_aaa_4"]],
           B2_aaa_1 => [["out/aaa1.xml", "b_aaa_1"]],
           B2_aaa_2 => [["out/aaa2.xml", "b_aaa_2"]],
           B2_aaa_3 => [["out/aaa3.xml", "b_aaa_3"]],
           B2_aaa_4 => [["out/aaa4.xml", "b_aaa_4"]],
           b_aaa_1  => [["out/aaa1.xml", "b_aaa_1"]],
           b_aaa_2  => [["out/aaa2.xml", "b_aaa_2"]],
           b_aaa_3  => [["out/aaa3.xml", "b_aaa_3"]],
           b_aaa_4  => [["out/aaa4.xml", "b_aaa_4"]],
           C1_aaa_1 => [["out/aaa1.xml", "c_aaa_1"]],
           C1_aaa_2 => [["out/aaa2.xml", "c_aaa_2"]],
           C1_aaa_3 => [["out/aaa3.xml", "c_aaa_3"]],
           C1_aaa_4 => [["out/aaa4.xml", "c_aaa_4"]],
           C2_aaa_1 => [["out/aaa1.xml", "c_aaa_1"]],
           C2_aaa_2 => [["out/aaa2.xml", "c_aaa_2"]],
           C2_aaa_3 => [["out/aaa3.xml", "c_aaa_3"]],
           C2_aaa_4 => [["out/aaa4.xml", "c_aaa_4"]],
           c_aaa_1  => [["out/aaa1.xml", "c_aaa_1"]],
           c_aaa_2  => [["out/aaa2.xml", "c_aaa_2"]],
           c_aaa_3  => [["out/aaa3.xml", "c_aaa_3"]],
           c_aaa_4  => [["out/aaa4.xml", "c_aaa_4"]],
         },
  bbb => {
           B1_bbb_1 => [["out/bbb1.xml", "b_bbb_1"]],
           B1_bbb_2 => [["out/bbb2.xml", "b_bbb_2"]],
           B1_bbb_3 => [["out/bbb3.xml", "b_bbb_3"]],
           B1_bbb_4 => [["out/bbb4.xml", "b_bbb_4"]],
           B2_bbb_1 => [["out/bbb1.xml", "b_bbb_1"]],
           B2_bbb_2 => [["out/bbb2.xml", "b_bbb_2"]],
           B2_bbb_3 => [["out/bbb3.xml", "b_bbb_3"]],
           B2_bbb_4 => [["out/bbb4.xml", "b_bbb_4"]],
           b_bbb_1  => [["out/bbb1.xml", "b_bbb_1"]],
           b_bbb_2  => [["out/bbb2.xml", "b_bbb_2"]],
           b_bbb_3  => [["out/bbb3.xml", "b_bbb_3"]],
           b_bbb_4  => [["out/bbb4.xml", "b_bbb_4"]],
           C1_bbb_1 => [["out/bbb1.xml", "c_bbb_1"]],
           C1_bbb_2 => [["out/bbb2.xml", "c_bbb_2"]],
           C1_bbb_3 => [["out/bbb3.xml", "c_bbb_3"]],
           C1_bbb_4 => [["out/bbb4.xml", "c_bbb_4"]],
           C2_bbb_1 => [["out/bbb1.xml", "c_bbb_1"]],
           C2_bbb_2 => [["out/bbb2.xml", "c_bbb_2"]],
           C2_bbb_3 => [["out/bbb3.xml", "c_bbb_3"]],
           C2_bbb_4 => [["out/bbb4.xml", "c_bbb_4"]],
           c_bbb_1  => [["out/bbb1.xml", "c_bbb_1"]],
           c_bbb_2  => [["out/bbb2.xml", "c_bbb_2"]],
           c_bbb_3  => [["out/bbb3.xml", "c_bbb_3"]],
           c_bbb_4  => [["out/bbb4.xml", "c_bbb_4"]],
         },
  ccc => {
           B1_ccc_1 => [["out/ccc1.xml", "b_ccc_1"]],
           B1_ccc_2 => [["out/ccc2.xml", "b_ccc_2"]],
           B1_ccc_3 => [["out/ccc3.xml", "b_ccc_3"]],
           B1_ccc_4 => [["out/ccc4.xml", "b_ccc_4"]],
           B2_ccc_1 => [["out/ccc1.xml", "b_ccc_1"]],
           B2_ccc_2 => [["out/ccc2.xml", "b_ccc_2"]],
           B2_ccc_3 => [["out/ccc3.xml", "b_ccc_3"]],
           B2_ccc_4 => [["out/ccc4.xml", "b_ccc_4"]],
           b_ccc_1  => [["out/ccc1.xml", "b_ccc_1"]],
           b_ccc_2  => [["out/ccc2.xml", "b_ccc_2"]],
           b_ccc_3  => [["out/ccc3.xml", "b_ccc_3"]],
           b_ccc_4  => [["out/ccc4.xml", "b_ccc_4"]],
           C1_ccc_1 => [["out/ccc1.xml", "c_ccc_1"]],
           C1_ccc_2 => [["out/ccc2.xml", "c_ccc_2"]],
           C1_ccc_3 => [["out/ccc3.xml", "c_ccc_3"]],
           C1_ccc_4 => [["out/ccc4.xml", "c_ccc_4"]],
           C2_ccc_1 => [["out/ccc1.xml", "c_ccc_1"]],
           C2_ccc_2 => [["out/ccc2.xml", "c_ccc_2"]],
           C2_ccc_3 => [["out/ccc3.xml", "c_ccc_3"]],
           C2_ccc_4 => [["out/ccc4.xml", "c_ccc_4"]],
           c_ccc_1  => [["out/ccc1.xml", "c_ccc_1"]],
           c_ccc_2  => [["out/ccc2.xml", "c_ccc_2"]],
           c_ccc_3  => [["out/ccc3.xml", "c_ccc_3"]],
           c_ccc_4  => [["out/ccc4.xml", "c_ccc_4"]],
         },
  ddd => {
           B1_ddd_1 => [["out/ddd1.xml", "b_ddd_1"]],
           B1_ddd_2 => [["out/ddd2.xml", "b_ddd_2"]],
           B1_ddd_3 => [["out/ddd3.xml", "b_ddd_3"]],
           B1_ddd_4 => [["out/ddd4.xml", "b_ddd_4"]],
           B2_ddd_1 => [["out/ddd1.xml", "b_ddd_1"]],
           B2_ddd_2 => [["out/ddd2.xml", "b_ddd_2"]],
           B2_ddd_3 => [["out/ddd3.xml", "b_ddd_3"]],
           B2_ddd_4 => [["out/ddd4.xml", "b_ddd_4"]],
           b_ddd_1  => [["out/ddd1.xml", "b_ddd_1"]],
           b_ddd_2  => [["out/ddd2.xml", "b_ddd_2"]],
           b_ddd_3  => [["out/ddd3.xml", "b_ddd_3"]],
           b_ddd_4  => [["out/ddd4.xml", "b_ddd_4"]],
           C1_ddd_1 => [["out/ddd1.xml", "c_ddd_1"]],
           C1_ddd_2 => [["out/ddd2.xml", "c_ddd_2"]],
           C1_ddd_3 => [["out/ddd3.xml", "c_ddd_3"]],
           C1_ddd_4 => [["out/ddd4.xml", "c_ddd_4"]],
           C2_ddd_1 => [["out/ddd1.xml", "c_ddd_1"]],
           C2_ddd_2 => [["out/ddd2.xml", "c_ddd_2"]],
           C2_ddd_3 => [["out/ddd3.xml", "c_ddd_3"]],
           C2_ddd_4 => [["out/ddd4.xml", "c_ddd_4"]],
           c_ddd_1  => [["out/ddd1.xml", "c_ddd_1"]],
           c_ddd_2  => [["out/ddd2.xml", "c_ddd_2"]],
           c_ddd_3  => [["out/ddd3.xml", "c_ddd_3"]],
           c_ddd_4  => [["out/ddd4.xml", "c_ddd_4"]],
         },
}}
