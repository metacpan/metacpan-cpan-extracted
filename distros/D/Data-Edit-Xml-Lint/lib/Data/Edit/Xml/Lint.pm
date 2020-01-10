#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I/home/phil/perl/cpan/DataEditXml/lib/
#-------------------------------------------------------------------------------
# Lint xml files in parallel using xmllint and report the pass/failure rate.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2019
#-------------------------------------------------------------------------------
# podDocumentation
# Id definitions should be processed independently of labels
# What sort of tag is on the end of the link?
# Report resolved, unresolved, missing links - difficult because of forking
# Check that the file actually has a lint section in read and do something about it if it does not
# Separate reference fixup into a separate framework (like Dita::Conversion)
# Show number of compressed errors on Lint summary line
# Highlight error counts in bold using boldText() or perhaps enclosed alphanumerics
# Relint load data in parallel
# option to print xmllint command
# inputFile=>name unicode seems to be failing
# Lots more tests needed

package Data::Edit::Xml::Lint;
our $VERSION = 20200108;
use warnings FATAL => qw(all);
use strict;
use Carp qw(cluck confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Time::HiRes qw(time);
use Encode;

sub maxLintMsgLength {128}                                                      # Truncate xml lint messages longer then this
sub maxExampleFiles  {3}                                                        # Maximum number of example files

#D1 Constructor                                                                 # Construct a new linter

sub new                                                                         #S Create a new xml linter - call this method statically as in L<Data::Edit::Xml::Lint|/new> and then fill in the relevant L<Attributes>.
 {bless {}                                                                      # Create xml linter
 }

#D2 Attributes                                                                  # Attributes describing a lint.

genLValueScalarMethods(qw(author));                                             # Optional author of the xml - only needed if you want to generate an SDL file map.
genLValueScalarMethods(qw(catalog));                                            # Optional catalog file containing the locations of the DTDs used to validate the xml or  use L<dtds|/dtds> to supply a B<DTD> instead.
genLValueScalarMethods(qw(compressedErrors));                                   # Number of compressed errors discovered.
genLValueScalarMethods(qw(compressedErrorText));                                # Text of compressed errors.
genLValueScalarMethods(qw(ditaType));                                           # Optional Dita topic type(concept|task|troubleshooting|reference) of the xml - only needed if you want to generate an SDL file map.
genLValueScalarMethods(qw(docType));                                            # The second line: the document type extracted from the L<source|/source>.
genLValueScalarMethods(qw(dtds));                                               # Optional directory containing the DTDs used to validate the xml.
genLValueScalarMethods(qw(errors));                                             # Total number of uncompressed lint errors detected by xmllint over all files.
genLValueScalarMethods(qw(errorText));                                          # Text of uncompressed lint errors detected by xmllint over all files.
genLValueScalarMethods(qw(file));                                               # File that the xml should be written to or read from by L<lint|/lint>, L<read|/read> or L<relint|/relint>.
genLValueScalarMethods(qw(fileNumber));                                         # File number - assigned by the caller to help debugging transformations.
genLValueScalarMethods(qw(lineNumber));                                         # The file and line number of the caller so we can identify which request for lint gave rise to a particular file
genLValueScalarMethods(qw(guid));                                               # Guid or id of the outermost tag - if not supplied the first definition encountered in each file will be used on the basis that all Dita topics require an id.
genLValueScalarMethods(qw(header));                                             # The first line: the xml header extracted from L<source|/source>.
genLValueScalarMethods(qw(idDefs));                                             # {id} = count - the number of times this id is defined in the xml contained in this L<file|/file>.
genLValueScalarMethods(qw(inputFile));                                          # The file from which this xml was obtained.
genLValueScalarMethods(qw(labelDefs));                                          # {label or id} = id - the id of the node containing a L<label|Data::Edit::Xml/Labels> defined on the xml.
genLValueScalarMethods(qw(labels));                                             # Optional parse tree to supply L<labels|Data::Edit::Xml/Labels> for the current L<source|/source> as the labels are present in the parse tree not in the string representing the parse tree.
genLValueScalarMethods(qw(linted));                                             # Date the lint was performed by L<lint|/lint>.  We avoid adding a time as well because this then induces much longer sync times with AWS S3.
genLValueScalarMethods(qw(preferredSource));                                    # Preferred representation of the xml source, used by L<relint|/relint> to supply a preferred representation for the source.
genLValueScalarMethods(qw(processes));                                          # Maximum number of xmllint processes to run in parallel - 8 by default if linting in parallel is being used. Linting in parallel is pointless if each file is already being converted in parallel. Conversely, linting in parallel is helpful if the xml files are being converted serially.
genLValueScalarMethods(qw(project));                                            # Optional L<project|/project> name to allow error counts to be aggregated by L<project|/project> and to allow L<id and labels|Data::Edit::Xml/Labels> to be scoped to the L<files|/file> contained in each L<project|/project>.
genLValueArrayMethods(qw(reusedInProject));                                     # List of projects in which this file is reused, which can be set via L<reuseFileInProject|/reuseFileInProject> every time you discover another project in which a file is reused.
genLValueScalarMethods(qw(source));                                             # The source Xml to be written to L<file|/file> and linted.
genLValueScalarMethods(qw(title));                                              # Optional title of the xml - only needed if you want to generate an SDL file map.

#D1 Lint                                                                        # Lint xml L<files|/file> in parallel

sub lint($@)                                                                    #P Lint a L<files|/file>, using xmllint and update the source file with the results in text format so as to be be easy to search with grep.
 {my ($lint, %attributes) = @_;                                                 # Linter, attributes to be recorded as xml comments
      $lint->lineNumber = join ' ', caller;                                     # Calling context
  my $source = $lint->source;
  $source or confess "Use the source() method to provide the source xml";       # Check that we have some source
  $lint->file or confess "Use the ->file method to provide the target file";    # Check that we have an output file

  $source =~ s/\s+\Z//gs;                                                       # Xml text to be written minus trailing blanks
  my @lines = split /\n/, $source;                                              # Split source into lines

  my $file = $lint->file;                                                       # File to be written to
  confess "File name contains a new line:\n$file\n" if $file =~ m/\n/s;         # Complain if the source file contains a new line

  for(qw(author catalog ditaType dtds file fileNumber lineNumber),              # Map parameters to attributes
      qw(inputFile guid project title))
   {my $a = $lint->$_;
    $attributes{$_} = $a if $a;
   }

  if ($source =~ m(<!DOCTYPE))                                                  # Source details
   {($attributes{docType}) = (grep {m(<!DOCTYPE)} @lines);
   }
  $attributes{header} = $lines[0];

  my $time   = "<!--linted: ".dateTimeStamp." -->";                             # Time stamp marks the start of the added comments
  my $attr   = &formatAttributes({%attributes});                                # Attributes to be recorded with the xml

  my $labels = sub                                                              # Process any labels in the parse tree
   {return '' unless $lint->labels;                                             # No supplied parse tree in which to finds ids and labels
    my $s = '';                                                                 # Labels as text
    $lint->labels->by(sub                                                       # Search the supplied parse tree for any id or label definitions
     {my ($o) = @_;

      if (my $i = $o->id)                                                       # Id for this node but no labels
       {$i =~ s(--) (\\-\\-)gs;                                                 # Escape any double hyphens as they are not allowed in XML comments
        $s .= "<!--definition: $i -->\n";                                       # Id definition
        my $d = $lint->idDefs //= {};                                           # Id definitions for this file
        $d->{$i} = $i;                                                          # Record id definition
       }

      if (my @labels = $o->getLabels)                                           # Labels for this node
       {my $i = $o->id;                                                         # Id for this node
        $i or confess "No id for node with labels:\n".$o->prettyString;

        for(grep {m(\s)s} @labels)                                              # Complain about any white space in any label as it cannot be stored in the current scheme
         {lll qq(Data::Edit::Xml::Lint::lint White space in label: "$_");
          s(\s) ()gs                                                            # Remove white space
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

  $source .= "\n$time\n$attr\n$labels$reusedInProject";                         # Xml plus comments
  my $temp = writeFile(undef, $source);                                         # Write xml to a temporary file

  if (my $v = qx(xmllint --version 2>&1))                                       # Check xmllint is present
   {unless ($v =~ m(\Axmllint)is)
     {confess "xmllint missing, install with:\nsudo apt-get install libxml2-utils";
     }
   }
  my $c = sub                                                                   # Lint command
   {my $p = " --noent --noout --valid";                                         # Suppress printed output and entity transformation, validate
    my $c = quoteFile($lint->catalog);                                          # Catalog to use
    my $r = qq(export XML_CATALOG_FILES=$c && xmllint $p - < $temp 2>&1);       # Lint command
    $r
   }->();

  my $errors = qx($c);                                                          # Perform lint
  my @errors = $errors ? split(/\n/, $errors) : ();                             # Each error line

  for my $m(@errors)                                                            # Reverse the expected and got message components as they are more useful that way around
   {my @m = split /:/, $m;
    if (@m and $m[-1] =~ m(, got )s)
     {my $t = pop @m;
      push @m, join ' ', reverse split /, got /, $t;
      $m = join ':', @m;
     }
   }

  if (@errors and $errors !~ m(parser error : Document is empty)s)              # Add errors as comments.
   {my @e;                                                                      # Wrap errors in comments
    for my $e(@errors)                                                          # Each error
     {$e =~ s(\-+)   (-)gs;                                                     # Remove multiple hyphens which would prevent reparses
      $e =~ s(\s*\Z) ()s;                                                       # Remove any trailing white space
      $e =~ s(\n)    ( )gs;                                                     # Replace in line new lines
      push @e, "<!-- $e -->\n";
     }
    my $e = join '', @e;                                                        # Error block
    my $n = $lint->errors = int @errors / 3;                                    # Three lines per error message
    my $t = "<!--errors: $n -->";                                               # Number of errors
    my $z = &compressErrors(@errors);                                           # Compress the errors per Micaela
    my $w = "$source\n$e\n$t$z";                                                # Text to write

    overWriteFile($temp, $w);                                                   # Update xml file with errors
   }
  else                                                                          # No errors detected
   {$lint->errors = 0;
   }

  makePath($file);                                                              # Create folder for file
  rename $temp, $file;                                                          # Rename temporary file to obtain a more atomic rename

  $lint
 } # lint

sub squeezeDitaRef($)                                                           #S Squeeze a string so it can be safely stored inside blank separated list inside an xml comment.
 {my ($ref) = @_;                                                               # String to squeeze
  $ref =~ s((\s+|--)) (_)gsr;                                                   # Squeeze!
 }

sub compressErrors(@)                                                           #PS Compress the errors so we count the ones that do not look similar. Errors typically occupy three lines with the last line containing ^ at the end to mark the location of the error.
 {my (@errors) = @_;                                                            # Errors
  my @e;                                                                        # Third lines
  my %c;                                                                        # Compressed errors

  for(1..@errors)                                                               # Every third line
   {push @e, $errors[$_-1] if $_ % 3 == 1;
   }

# for(@e)                                                                       # Reduce error line
#  {my $c =  s(-:\d+?:) ()sr;                                                   # Remove line number
#      $c =~ s(\s+\^\Z) ()s;                                                    # Remove error pointer
#      $c =~ s(expect.*) ()s;                                                   # Remove expected
#      $c =~ s(\-\-+) (-)gs;                                                    # Remove multiple hyphens as they cause relint errors at 2019.05.07 03:52:28
#  $c{$c}++;
#  }                                                                            # Format compressed errors block

  for my $e(@e)                                                                 # Reduce error line
   {my @c = split /:/, $e;
    $c{$c[-1]}++;
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
      qw(inputFile labelDefs labels linted processes project sha256),
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

   !defined($v) and m(docType) and confess "No doc type set for the xml to be linted";
    defined($v) or confess "Attribute $_ has no value";
    $v =~ s/--/\\-\\-/gs;                                                       # Replace -- with \-\- as -- will upset the use of xml comments to hold the data in a greppable form - but only for title - for files we need to see an error message
#   $v =~ m/--/s and confess "Found -- in value of $_=>$v";                     # Confess if -- present in attribute value as this will mess up the xml comments
    push @s, "<!--${_}: $v -->";                                                # Place attribute inside a comment
   }
  join "\n", @s
 }

sub read($)                                                                     #S Reread a linted xml L<file|/file> and extract the L<attributes|/Attributes> associated with the L<lint|/lint>
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
  my ($U, $C) = split /(?=<!--compressedErrors:)/s, $S[-1]//'';                 # Split errors
  my @U = $U ? split /\n+/, $U : ();                                            # Split uncompressed errors
  my @C = $C ? split /\n+/, $C : ();                                            # Split   compressed errors
  shift @C;                                                                     # Remove the number of compressed errors
  $_ = nws($_) for @C;                                                          # Normalize white space

  my $lint = bless                                                              # Create a matching linter
   {%a,                                                                         # Directly loaded fields
    source              =>  $S,                                                 # Computed fields
#    header              =>  $a[0],                                             # Available in end of file comments
#    docType             =>  $a[1],
    file                =>  $file,
    idDefs              =>  $d,
    labels              =>  undef,                                              #  2019.03.16 01:42:37 property of the parse tree only
    labelDefs           =>  $l,
    reusedInProject     => [sort keys %$r],
    compressedErrorText => [@C],
    errorText           => [@U],
   };

  $lint->project          //= q();                                              # Supply a default bank project
  $lint->errors           //= 0;
  $lint->compressedErrors //= 0;
  $lint                                                                         # Return a matching linter
 } # read

sub reload($)                                                                   # Reload a parse tree from a linted file restoring any labels and return the parse tree or B<undef> if the file is not a lint file.
 {my ($file) = @_;                                                              # File to read

  return undef unless my $l = &read($file);                                     # Read lint file or fail
  my %labels;                                                                   # Labels for each id
  my %labelDefs = %{$l->labelDefs};                                             # Label definitions
  for my $label(sort keys %labelDefs)                                           # Each label definition
   {my $id = $labelDefs{$label};                                                # Id for label
    if ($id ne $label)                                                          # Ignore self definitions
     {push @{$labels{$id}}, $label;                                             # Map id to labels
     }
   }

  my $x = Data::Edit::Xml::new($l->source);                                     # Parse source which is assumed to be parseable as it has been linted

  $x->by(sub                                                                    # Restore labels at each id
   {my ($o) = @_;
    if (my $i = $o->id)                                                         # Node has an id
     {if (my $labels = $labels{$i})                                             # Id has labels
       {$o->addLabels(@$labels);                                                # Restore labels for id
       }
     }
   });

  $x                                                                            # Return restored parse tree
 }

sub lintAttributes($)                                                           #S Get all the attributes minus the source of all the linted files in the specified folder
 {my ($folder) = @_;                                                            # Folder to search
  my @l;
  my @f = searchDirectoryTreesForMatchingFiles($folder);                        # All files
  for my $file(@f)                                                              # Each file
   {next unless $file =~ m(\.(dita(map)?|xml)\Z)s;                              # Skip files that are not xml files
     if (my $l = &read($file))                                                  # Load lint details if possible
     {delete $$l{$_} for qw(errorText preferredSource source);                  # Remove attributes that take a lot of space
      push @l, $l;
     }
   }
  @l                                                                            # Lint attributes array
 }

sub relint($$$@)                                                                #S Locate all the L<labels or id|Data::Edit::Xml/Labels> in the specified L<files|/file>, analyze the map of labels and ids with B<analysisSub> parse each L<file|/file>, process each parse with B<processSub>, then L<lint/lint> the reprocessed xml back to the original L<file|/file> - this allows you to reprocess the contents of each L<file|/file> with knowledge of where L<labels or id|Data::Edit::Xml/Labels> are located in the other L<files|/file> associated with a L<project|/project>. The B<analysisSub>(linkmap = {project}{labels or id>}=[file, id]) should return true if the processing of each file is to be performed subsequently. The B<processSub>(parse tree representation of a file, id and label mapping, reloaded linter) should return true if a L<lint|/lint> is required to save the results after each L<file|/file> has been processed else false. Optionally, the B<analysisSub> may set the L<preferredSource|/preferredSource> attribute to indicate the preferred representation of the xml.
 {my ($processes, $analysisSub, $processSub, @foldersAndExtensions) = @_;       # Maximum number of processes to use, analysis 𝘀𝘂𝗯, Process 𝘀𝘂𝗯, folders and extensions of files to process (recursively)
  my @files = searchDirectoryTreesForMatchingFiles(@foldersAndExtensions);      # Search for files to relint
  my $links;                                                                    # {project}{label or id} = [file, label or id] : the file containing  each label or id in each project
  my $fileToGuid;                                                               # {file name} to guid
  my $files = @files;
  for my $i(keys @files)                                                        # Reload each file to reprocess
   {my $file = $files[$i];
    #lll " $i/$files Data::Edit::Xml::Lint::relint file: $file";

    my $lint = Data::Edit::Xml::Lint::read($file);                              # Reconstructed linter

    next unless $lint->project;                                                 # File has the right format
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
    else                                                                        # Get last id defined as topic id if no topic id has been explicitly set via guid
     {$fileToGuid->{$file} = $lint->{definition};
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

  #lll "Data::Edit::Xml::Lint::relint: Linkmap completed";                      # Progress

  if ($analysisSub->($links, $fileToGuid))                                      # Analyze links and guids
   {my $ps = newProcessStarter($processes);                                     # Process starter

    for my $i(keys @files)                                                      # Reload, reparse, process, lint each file
     {my $file = $files[$i];

      $ps->start(sub                                                            # Process in parallel
       {my $lint = Data::Edit::Xml::Lint::read($file);                          # Reconstructed linter
        confess "Unable to read lint data for file: $file\n"
          unless $lint;# and $lint->project;                                      # Confirm that we read a file in the expected format
        confess "No source for file: $file\n"
          unless $lint->source;                                                 # Files without source are assumed to have been written to store some attributes

        my $x = eval{Data::Edit::Xml::new($lint->source)};                      # Reparse source trapping errors
        $@  and confess "$@\nFailed to parse file:\n$file\n";                   # Xml file failed to parse
        !$x and confess "Failed to parse file:\n$file\n";                       # Xml file failed to parse

        if (my $links = $lint->labelDefs)                                       # Reload labels
         {my $r;                                                                # {primary id}[label]
          for my $source(sort keys %$links)                                     # Construct primary id to labels
           {my $target = $links->{$source};
            push @{$r->{$target}}, $source unless $source eq $target;           # No need to reverse the primary id
           }

          $x->by(sub                                                            # Reload labels
           {my ($o) = @_;
            if (defined($o->attr(qw(id))) and my $i = $o->id)                   # Id if defined
             {if (my $labels = $r->{$i})                                        # Labels for this id if present
               {for my $label(@$labels)                                         # Each label for this id
                 {$o->addLabels($label);                                        # Add the label
                 }
               }
             }
           });
         }

        if ($processSub->($x, $links->{$lint->project}, $fileToGuid, $lint))    # Call user method to process parse tree with labels in place and the location of all the labels and ids
         {my $l = $lint;                                                        # Shorten name
          my $s = $l->preferredSource // $x->prettyString;                      # Representation of xml
          $l->source = join "\n", $l->header, $l->docType, $s;                  # Reconstruct source
          $l->labels = $x;                                                      # Associated parse tree so we can save the labels
          my %a = map {$_=>$l->{$_}} grep{!($l->can($_))} keys %$l;             # Reconstruct attributes as this items which do not have a method attached

          $l->lint(%a);                                                         # Lint reprocessed source
         }
       });
     }
    $ps->finish;
   }
 } # relint

sub resolveUniqueLink($$)                                                       #S Return the unique (file, leading id) of the specified link in the link map or () if no such definition exists
 {my ($linkMap, $link) = @_;                                                    # Link map, label
  if ($link =~ m(\s)s)                                                          # Complain about any white space in the label
   {cluck "White space in label removed: $link";
    $link =~ s(\s) ()gs;                                                        # Remove white space from label
   }
  my $l = $linkMap->{$link};                                                    # Attempt to resolve link
  return () unless $l;                                                          # No definition
  return () if @$l != 1;                                                        # Too many definitions
  @{$l->[0]}                                                                    # (file, leading id)
 } # resolveUniqueLink

sub urlEncode($)                                                                #S Return a url encoded string
 {my ($s) = @_;                                                                 # String
  $s =~ s(\s) (%20)gsr;
 }

sub resolveDitaLink($$$$)                                                       #S Given a specified B<$link>Return the unique (file, leading id, topic ) of the specified link in the link map or () if no such definition exists
 {my ($linkMap, $fileToGuid, $link, $sourceFile) = @_;                          # Link map, file map, label, file we are resolving from

  if ($link =~ m(\s)s)                                                          # Complain about any white space in the label
   {cluck "White space in label removed: $link";
    $link =~ s(\s) ()gs;                                                        # Remove white space from label
   }

  if (my $l = $linkMap->{$link})                                                # Attempt to resolve link
   {if (@$l == 1)                                                               # Require a unique target
     {my ($targetFile, $id) = @{$l->[0]};                                       # (file, id)

      if (my $topicId = $fileToGuid->{$targetFile})                             # Topic id for target file
       {if ($sourceFile eq $targetFile)                                         # Link in same file
         {return urlEncode("#$topicId/$id");
         }
        else                                                                    # Link to a different file
         {my $f = $targetFile =~ s(\A.*\/) ()r;
          if ($topicId ne $id)                                                  # Link to sub topic in different file
           {return urlEncode("$f#$topicId/$id");
           }
          else                                                                  # Link to topic in different file
           {return urlEncode("$f#$topicId");
           }
         }
       }
      else
       {warn "Data::Edit::Xml::Lint No topic id recorded for file $targetFile";
       }
     }
    else
     {warn "Data::Edit::Xml::Lint Not a unique link =$link=\n";
     }
   }
  else
   {warn "Data::Edit::Xml::Lint No such link =$link=\n";                        # Xref will report any failures in detail
   }
  undef                                                                         # Resolution failed
 } # resolveDitaLink;

sub reuseInProject($)                                                           #PS Record the reuse of an item in the named project
 {my ($project) = @_;                                                           # Name of the project in which it is reused
  qq(\n<!--reusedInProject: $project -->);
 }

sub reuseFileInProject($$)                                                      #S Record the reuse of the specified file in the specified project
 {my ($file, $project) = @_;                                                    # Name of file that is being reused, name of project in which it is reused
  appendFile($file, reuseInProject($project));                                  # Add a reuse record to the file being reused.
 }

sub countLinkTargets($$)                                                        #PS Count the number of targets this link resolves to.
 {my ($linkMap, $link) = @_;                                                    # Link map, label
  my $l = $linkMap->{$link};                                                    # Attempt to resolve link
  return 0 unless $l;                                                           # No definition
  scalar @$l;                                                                   # Definition count
 } # countLinkTargets

sub resolveFileToGuid($$)                                                       #S Return the unique definition of the specified link in the link map or undef if no such definition exists
 {my ($fileToGuids, $file) = @_;                                                # File to guids map, file
  $fileToGuids->{$file};                                                        # Attempt to resolve file
 } # resolveFileToGuid

sub multipleLabelDefs($)                                                        #S Return ([L<project|/project>; L<source label or id|Data::Edit::Xml/Labels>; targets count]*) of all L<labels or id|Data::Edit::Xml/Labels> that have multiple definitions
 {my ($labelDefs) = @_;                                                         # Label definitions
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

sub multipleLabelDefsReport($)                                                  #S Return a L<report|/report> showing L<labels and id|Data::Edit::Xml/Labels> with multiple definitions in each L<project|/project> ordered by most defined
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

sub singleLabelDefs($)                                                          #S Return ([L<project|/project>; label or id]*) of all labels or ids that have a single definition
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

sub singleLabelDefsReport($)                                                    #S Return a L<report|/report> showing L<label or id|Data::Edit::Xml/Labels> with just one definitions ordered by L<project|/project>, L<label name|Data::Edit::Xml/Labels>
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


#D1 Report                                                                      # Methods for L<reporting|Data::Edit::Xml::Lint/report> the results of L<linting|/lint> several L<files|/file>

sub p4($$)                                                                      #PS Format a fraction as a percentage to 4 decimal places
 {my ($p, $f) = @_;                                                             # Pass, fail
  my $n = $p + $f;
  return 0 if $n == 0;
  $n > 0 or confess "Division by zero";
  my $r = sprintf("%3.4f", 100 * $p / $n);
  $r =~ s/\.0+\Z//gsr                                                           # Remove trailing zeroes
 }

sub report($;$)                                                                 #S Analyze the results of prior L<lints|/lint> and return a hash reporting various statistics and a L<printable|/print> report
 {my ($outputDirectory, $filter) = @_;                                          # Directory to search, optional regular expression to filter files

  my @x;                                                                        # Lints for all L<files|/file>
  for my $in(findFiles($outputDirectory))                                       # Find files to report on
   {next if $filter and $in !~ m($filter);                                      # Filter files if a filter has been supplied
    push @x, Data::Edit::Xml::Lint::read($in);                                  # Reload a previously written L<file|/file>
   }

  lll "No files selected" unless @x;                                            # No files selected
  return undef unless @x;

  my %projects;                                                                 # Pass/Fail by project
  my %files;                                                                    # Pass fail by file
  my %filesToProjects;                                                          # Project from file name
  my $totalErrors = 0;                                                          # Total number of errors
  my $totalCompressedErrorsFileByFile = 0;                                      # Total number of errors summed file by file
  my %examples;                                                                 # Compressed errors example files
  my %docTypes;                                                                 # Document types

  for my $x(@x)                                                                 # Aggregate the results of individual lints
   {my $file    = $x->file;
    next unless $file;                                                          # Not in the expected format
    my $project = $x->project // 'unknown';
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
     {for my $message(@$cet)
       {$message =~ s(\A<!--)  ()gs;                                            # Remove xml comments
        $message =~ s(-->\Z)   ()gs;
        $message =~ s(\s*\x29) (\x29)gs;
        $message = deduplicateSequentialWordsInString($message);                # Remove duplicate sequential words in message

        my $m = firstNChars $message, maxLintMsgLength;                         # Limit the length of messages to make the report more readable and collect similar errors together.
        $examples{$m}{$file}++                                                  # Files that exhibit this message
       }
     }
    if (my $d = $x->docType)                                                    # Document type summary
     {$docTypes{(split /\s+/, $d)[1]//$d}++;
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

  my $failingProjects       = @failingProjects;
  my $passingProjects       = @passingProjects;

  my $totalNumberOfFails    = scalar grep {$files{$_}  > 0} keys %files;
  my $totalNumberOfPasses   = scalar grep {$files{$_} == 0} keys %files;
  my $totalPassFailPercent  = p4($totalNumberOfPasses, $totalNumberOfFails);
  my $ts                    = dateTimeStamp;
  my $numberOfProjects      = keys %projects;
  my $numberOfFiles         = $totalNumberOfPasses + $totalNumberOfFails;
  my $totalCompressedErrors = scalar keys %examples;
  my $totalPassFailPercentB = boldString($totalPassFailPercent);

  my $summary = <<END;                                                          # Report summary
$totalPassFailPercent % success. Projects: $failingProjects+$passingProjects=$numberOfProjects.  Files: $totalNumberOfFails+$totalNumberOfPasses=$numberOfFiles. Errors: $totalCompressedErrors,$totalErrors  On $ts
END

  push my @report, $summary, "\n";

  push @report, sprintf(<<END,                                                  # Report title
CompressedErrorMessagesByCount: %8d

FailingFiles   :  %8d
PassingFiles   :  %8d

FailingProjects:  %8d
PassingProjects:  %8d
END
  scalar keys %examples,
  $totalNumberOfFails,
  $totalNumberOfPasses,
  scalar(@failingProjects),
  scalar(@passingProjects));

  if (@failingProjects)                                                         # Failing projects report
   {push @report, sprintf(<<END,


FailingProjects:  %8d
   #  Percent   Pass  Fail  Total  Project
END
    scalar(@failingProjects));

    for(1..@failingProjects)
     {my ($project, $pass, $fail, $total, $percent) = @{$failingProjects[$_-1]};
      push @report, sprintf("%4d %8.4f   %4d  %4d  %5d  %s\n",
        $_, $percent, $pass, $fail, $total, $project);
     }
   }

  if (@passingProjects)                                                         # Passing projects report
   {push @report, sprintf(<<END,


PassingProjects:  %8d
   #   Files  Project
END
    scalar(@passingProjects));

    for(1..@passingProjects)
     {my ($project, $files) = @{$passingProjects[$_-1]};
      push @report, sprintf("%4d    %4d  %s\n",
        $_, $files, $project);
     }
   }

  if (my $N = keys %examples)                                                   # Compressed errors report
   {my @ce = sort {$b->[0] <=> $a->[0]}
             map  {my @f = keys $examples{$_}->%*; [scalar(@f), $_, \@f]}
             keys %examples;

    my @e;
    for my $ce(@ce)
     {my ($count, $message, $files) = @$ce;
      $message =~ s(\A<!--)  ()gs;
      $message =~ s(-->\Z)   ()gs;
      $message =~ s(\s*\x29) (\x29)gs;
      $message = trim($message);

      my @f = map {fne($_)} sort {fileSize($a) <=> fileSize($b)} @$files;       # Smallest examples first, shorten file names
        $#f = maxExampleFiles if scalar(@f) > maxExampleFiles;                  # Limit example files

      push @e, [$count, $message, shift @f];                                    # First line
      push @e, [q(), q(), $_]     for   @f;                                     # Subsequent lines
     }

    push @report, <<END,


CompressedErrorMessagesByCount: $N

END
#   formatTableBasic(\@e);

    formatTable(\@e, <<END,                                                     # Report compressed error messages
Count    Number of times this message appears
Message  The error message from xmllint - compressed and truncated if necessary
Examples Files that exhibit this message
END
    title     => q(Compressed Error messages by Count),
    head      => <<END,
NNNN compressed error messages on DDDD
END
     );
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

  if (my $filesFail = @filesFail)                                               # Failing files report
   {my @r;
    for my $n(1..@filesFail)
     {my ($errors, $project, $file) = @{$filesFail[$n-1]};
      push @r, [$n, $errors, $file];
     }
    push @report, <<END, formatTable(\@r, <<END2);

FailingFiles: $totalNumberOfFails  Files that failed to pass lint by number of compressed errors

END
#       Failing File number
Errors  The number of errors in this file
File    The file with errors
END2
   }

  if (my $N = scalar keys %docTypes)                                            # Document type summary
   {my $s = formatTable(\%docTypes, [qw(Document Count)]);
    push @report, <<END;


DocumentTypes: $N

$s
END
   }

  push @report, "\n", (split /\n/, $report[0])[0];                              # Repeat summary line

  if (my $d = dateTimeStamp)
   {unshift @report, <<END,                                                     # Time stamp
Summary of passing and failing projects on: $d
END
   }

  return genHash('Data::Edit::Xml::Lint::Report',                               # Return report
    compressedErrors                => \%examples,
    docTypes                        => \%docTypes,
    failingFiles                    => [@filesFail],
    failingProjects                 => [@failingProjects],
    filter                          => $filter,
    numberOfFiles                   => $numberOfFiles,
    numberOfProjects                => $numberOfProjects,
    passingProjects                 => [@passingProjects],
    passRatePercent                 => $totalPassFailPercent,
    print                           => (join '', @report),
    summary                         => $summary,
    timestamp                       => $ts,
    totalCompressedErrorsFileByFile => $totalCompressedErrorsFileByFile,
    totalCompressedErrors           => scalar keys %examples,
    totalErrors                     => $totalErrors,
   );
 } # report

sub fixDitaXrefHrefs($@)                                                        # Fix the dita xref href attributes in the corpus determined by B<foldersAndExtensions>.
 {my ($maximumNumberOfProcesses, @foldersAndExtensions) = @_;                   # Maximum number of processes to run in parallel, folders and file extensions to process.
  relint($maximumNumberOfProcesses,                                             # Reprocess all the files
  sub                                                                           # Analysis sub
   {my ($linkMap, $filesToGuids) = @_;                                          # Link map, files to guids
    1
   },
  sub                                                                           # Reprocess sub
   {my ($x, $linkMap, $filesToGuids, $lint) = @_;
    my $count;                                                                  # Count the number of changes made
    $x->by(sub                                                                  # Look for xrefs in parse tree
     {my ($r) = @_;
      if ($r->at_xref)
       {if (my $h = $r->href)                                                   # Href
         {if ($h !~ m(#)s)                                                      # If the href has a # in it we assume that it has already been fixed!
           {if (my $H = resolveDitaLink
                         ($linkMap, $filesToGuids, $h, $lint->file))
             {$r->href = $H;                                                    # Fix href
              ++$count;
             }
           }
         }
       }
     });

    $count
   }, @foldersAndExtensions);
 }

#D2 Attributes

if (1)
 {package Data::Edit::Xml::Lint::Report;
  use Data::Table::Text qw(:all);
  genLValueScalarMethods(qw(compressedErrors));                                 # Compressed errors over all files
  genLValueScalarMethods(qw(docTypes));                                         # Array of [number of errors, L<project|/project>, L<files|/file>] ordered from least to most errors
  genLValueScalarMethods(qw(failingFiles));                                     # {docType}++ - Hash of document types encountered
  genLValueScalarMethods(qw(failingProjects));                                  # [Projects with xmllint errors]
  genLValueScalarMethods(qw(filter));                                           # File selection filter
  genLValueScalarMethods(qw(numberOfFiles));                                    # Number of L<files|/file> encountered
  genLValueScalarMethods(qw(numberOfProjects));                                 # Number of L<projects|/project> defined - each L<project|/project> can contain zero or more L<files|/file>
  genLValueScalarMethods(qw(passingProjects));                                  # [Projects with no xmllint errors]
  genLValueScalarMethods(qw(passRatePercent));                                  # Total number of passes as a percentage of all input files
  genLValueScalarMethods(qw(print));                                            # A printable L<report|/report> of the above
  genLValueScalarMethods(qw(timestamp));                                        # Timestamp of report
  genLValueScalarMethods(qw(totalCompressedErrorsFileByFile));                  # Total number of errors summed file by file
  genLValueScalarMethods(qw(totalCompressedErrors));                            # Number of compressed errors
  genLValueScalarMethods(qw(totalErrors));                                      # Total number of errors
 }

sub createTest($$$;$)                                                           #P Create a test file
 {my ($project, $source, $target, $additional) = @_;                            # Project name, source of topic, target of references, additional text for topic
  $additional //= '';
  [$project, $source, $target, $additional, <<END]
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []>
<concept id="c_${project}_${source}">
 <title>project=$project source=$source target=$target</title>
 <conbody id="b_${project}_${source}">
   <p>See: <xref href="B_${project}_${target}"/></p>$additional
 </conbody>
</concept>
END
 }

sub createTests                                                                 #P Create some tests
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

#D podDocumentation

=pod

=encoding utf-8

=head1 Name

L<Data::Edit::Xml::Lint|Data::Edit::Xml::Lint> - L<lint|/lint> xml
L<files|/file> in parallel using xmllint, report the failure rate and reprocess
linted files to fix cross references.

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

Once a L<file|/file> has been L<linted|/lint>, it can be reread with L<read|/read>
to obtain details about the xml including any B<id> attributes defined (see: idDefs below) and
any L<labels|Data::Edit::Xml/Labels> that refer to these B<id> attributes (see: labelDefs
below). Such L<labels|Data::Edit::Xml/Labels> provide additional identities for a
node beyond that provided by the B<id> attribute.

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
L<relinted|/relint> which performs the following actions:

=over 2

=item 1

reads the specified L<files|/file> via L<read|/read>

=item 2

constructs an B<id map> to locate an B<id>s from B<label>s defined in the
specified L<files|/file>

=item 3

L<Reparses|Data::Edit::Xml/new> each of the specified L<files|/file> to build a
parse tree representing the xml in each file.

=item 4

Calls a user supplied B<sub> passing it the L<parse tree|Data::Edit::Xml/new>
for each specified file and the B<id map>. The B<sub> should traverse the
L<parse tree|Data::Edit::Xml/new> fixing attributes which make references
between the L<files|/file> using the supplied B<id map>.

=item 5

Writes any modified L<parse trees|Data::Edit::Xml/new> back to the originating
L<file|/file> thus fixing the changes

=back

=head1 Description



Version 20190721.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Constructor

Construct a new linter

=head2 new()

Create a new xml linter - call this method statically as in L<Data::Edit::Xml::Lint|/new> and then fill in the relevant L<Attributes>.


This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::new


=head2 Attributes

Attributes describing a lint.

=head3 author :lvalue

Optional author of the xml - only needed if you want to generate an SDL file map.


=head3 catalog :lvalue

Optional catalog file containing the locations of the DTDs used to validate the xml or  use L<dtds|/dtds> to supply a B<DTD> instead.


=head3 compressedErrors :lvalue

Number of compressed errors discovered.


=head3 compressedErrorText :lvalue

Text of compressed errors.


=head3 ditaType :lvalue

Optional Dita topic type(concept|task|troubleshooting|reference) of the xml - only needed if you want to generate an SDL file map.


=head3 docType :lvalue

The second line: the document type extracted from the L<source|/source>.


=head3 dtds :lvalue

Optional directory containing the DTDs used to validate the xml.


=head3 errors :lvalue

Total number of uncompressed lint errors detected by xmllint over all files.


=head3 errorText :lvalue

Text of uncompressed lint errors detected by xmllint over all files.


=head3 file :lvalue

File that the xml should be written to or read from by L<lint|/lint>, L<read|/read> or L<relint|/relint>.


=head3 fileNumber :lvalue

File number - assigned by the caller to help debugging transformations.


=head3 lineNumber :lvalue

The file and line number of the caller so we can identify which request for lint gave rise to a particular file


=head3 guid :lvalue

Guid or id of the outermost tag - if not supplied the first definition encountered in each file will be used on the basis that all Dita topics require an id.


=head3 header :lvalue

The first line: the xml header extracted from L<source|/source>.


=head3 idDefs :lvalue

{id} = count - the number of times this id is defined in the xml contained in this L<file|/file>.


=head3 inputFile :lvalue

The file from which this xml was obtained.


=head3 labelDefs :lvalue

{label or id} = id - the id of the node containing a L<label|Data::Edit::Xml/Labels> defined on the xml.


=head3 labels :lvalue

Optional parse tree to supply L<labels|Data::Edit::Xml/Labels> for the current L<source|/source> as the labels are present in the parse tree not in the string representing the parse tree.


=head3 linted :lvalue

Date the lint was performed by L<lint|/lint>.  We avoid adding a time as well because this then induces much longer sync times with AWS S3.


=head3 preferredSource :lvalue

Preferred representation of the xml source, used by L<relint|/relint> to supply a preferred representation for the source.


=head3 processes :lvalue

Maximum number of xmllint processes to run in parallel - 8 by default if linting in parallel is being used. Linting in parallel is pointless if each file is already being converted in parallel. Conversely, linting in parallel is helpful if the xml files are being converted serially.


=head3 project :lvalue

Optional L<project|/project> name to allow error counts to be aggregated by L<project|/project> and to allow L<id and labels|Data::Edit::Xml/Labels> to be scoped to the L<files|/file> contained in each L<project|/project>.


=head3 reusedInProject :lvalue

List of projects in which this file is reused, which can be set via L<reuseFileInProject|/reuseFileInProject> every time you discover another project in which a file is reused.


=head3 source :lvalue

The source Xml to be written to L<file|/file> and linted.


=head3 title :lvalue

Optional title of the xml - only needed if you want to generate an SDL file map.


=head1 Lint

Lint xml L<files|/file> in parallel

=head2 squeezeDitaRef($)

Squeeze a string so it can be safely stored inside blank separated list inside an xml comment.

     Parameter  Description
  1  $ref       String to squeeze

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::squeezeDitaRef


=head2 nolint($@)

Store just the attributes in a file so that they can be retrieved later to process non xml objects referenced in the xml - like images

     Parameter    Description
  1  $lint        Linter
  2  %attributes  Attributes to be recorded as xml comments

=head2 read($)

Reread a linted xml L<file|/file> and extract the L<attributes|/Attributes> associated with the L<lint|/lint>

     Parameter  Description
  1  $file      File containing xml

B<Example:>


  if (1)
   {my $x = Data::Edit::Xml::new(<<END);
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []>
  <concept id="c1">
    <title/>
    <conbody>
    </conbody>
  </concept>
  END

    $x->addLabels_c2_c3_c4;
    $x->createGuidId;
    is_deeply [$x->getLabels], [qw(c1 c2 c3 c4)];

    my $l = new;                                                                  # Linter
       $l->catalog   = $catalog;                                                  # Catalog
       $l->ditaType  = -t $x;                                                     # Topic type
       $l->file      = fpf($outDir, q(zzz.dita));                                 # Output file
       $l->guid      = $x->id;                                                    # Guid
       $l->inputFile = q(zzz.xml);                                                # Add source file information
       $l->labels    = $x;                                                        # Add label information to the output file so when all the files are written they can be retargeted by Data::Edit::Xml::Lint
       $l->project   = q(aaa);                                                    # Group files into Id scopes
       $l->title     = q(test lint);                                              # Title
       $l->source    = $x->ditaPrettyPrintWithHeaders;                            # Source from parse tree
    $l->lint;

    my $m = &𝗿𝗲𝗮𝗱($l->file);
    my $y = &reload($l->file);
    ok $l->source eq $m->source;
    ok -p $x eq -p $y;
    is_deeply [$x->getLabels], [$y->getLabels];
    clearFolder($outDir, 1e2);
   }


This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::read


=head2 reload($)

Reload a parse tree from a linted file restoring any labels and return the parse tree or B<undef> if the file is not a lint file.

     Parameter  Description
  1  $file      File to read

=head2 lintAttributes($)

Get all the attributes minus the source of all the linted files in the specified folder

     Parameter  Description
  1  $folder    Folder to search

B<Example:>


  if (1)
   {my @a = 𝗹𝗶𝗻𝘁𝗔𝘁𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝘀($outDir);
    ok $_->project eq q(aaa) for @a;
   }


This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::lintAttributes


=head2 relint($$$@)

Locate all the L<labels or id|Data::Edit::Xml/Labels> in the specified L<files|/file>, analyze the map of labels and ids with B<analysisSub> parse each L<file|/file>, process each parse with B<processSub>, then L<lint/lint> the reprocessed xml back to the original L<file|/file> - this allows you to reprocess the contents of each L<file|/file> with knowledge of where L<labels or id|Data::Edit::Xml/Labels> are located in the other L<files|/file> associated with a L<project|/project>. The B<analysisSub>(linkmap = {project}{labels or id>}=[file, id]) should return true if the processing of each file is to be performed subsequently. The B<processSub>(parse tree representation of a file, id and label mapping, reloaded linter) should return true if a L<lint|/lint> is required to save the results after each L<file|/file> has been processed else false. Optionally, the B<analysisSub> may set the L<preferredSource|/preferredSource> attribute to indicate the preferred representation of the xml.

     Parameter              Description
  1  $processes             Maximum number of processes to use
  2  $analysisSub           Analysis 𝘀𝘂𝗯
  3  $processSub            Process 𝘀𝘂𝗯
  4  @foldersAndExtensions  Folders and extensions of files to process (recursively)

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::relint


=head2 resolveUniqueLink($$)

Return the unique (file, leading id) of the specified link in the link map or () if no such definition exists

     Parameter  Description
  1  $linkMap   Link map
  2  $link      Label

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::resolveUniqueLink


=head2 urlEncode($)

Return a url encoded string

     Parameter  Description
  1  $s         String

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::urlEncode


=head2 resolveDitaLink($$$$)

Given a specified B<$link>Return the unique (file, leading id, topic ) of the specified link in the link map or () if no such definition exists

     Parameter    Description
  1  $linkMap     Link map
  2  $fileToGuid  File map
  3  $link        Label
  4  $sourceFile  File we are resolving from

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::resolveDitaLink


=head2 reuseFileInProject($$)

Record the reuse of the specified file in the specified project

     Parameter  Description
  1  $file      Name of file that is being reused
  2  $project   Name of project in which it is reused

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::reuseFileInProject


=head2 resolveFileToGuid($$)

Return the unique definition of the specified link in the link map or undef if no such definition exists

     Parameter     Description
  1  $fileToGuids  File to guids map
  2  $file         File

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::resolveFileToGuid


=head2 multipleLabelDefs($)

Return ([L<project|/project>; L<source label or id|Data::Edit::Xml/Labels>; targets count]*) of all L<labels or id|Data::Edit::Xml/Labels> that have multiple definitions

     Parameter   Description
  1  $labelDefs  Label definitions

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::multipleLabelDefs


=head2 multipleLabelDefsReport($)

Return a L<report|/report> showing L<labels and id|Data::Edit::Xml/Labels> with multiple definitions in each L<project|/project> ordered by most defined

     Parameter   Description
  1  $labelDefs  Label and Id definitions

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::multipleLabelDefsReport


=head2 singleLabelDefs($)

Return ([L<project|/project>; label or id]*) of all labels or ids that have a single definition

     Parameter   Description
  1  $labelDefs  Label and Id definitions

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::singleLabelDefs


=head2 singleLabelDefsReport($)

Return a L<report|/report> showing L<label or id|Data::Edit::Xml/Labels> with just one definitions ordered by L<project|/project>, L<label name|Data::Edit::Xml/Labels>

     Parameter   Description
  1  $labelDefs  Label and Id definitions

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::singleLabelDefsReport


=head1 Report

Methods for L<reporting|Data::Edit::Xml::Lint/report> the results of L<linting|/lint> several L<files|/file>

=head2 report($$)

Analyze the results of prior L<lints|/lint> and return a hash reporting various statistics and a L<printable|/print> report

     Parameter         Description
  1  $outputDirectory  Directory to search
  2  $filter           Optional regular expression to filter files

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::report


=head2 fixDitaXrefHrefs($@)

Fix the dita xref href attributes in the corpus determined by B<foldersAndExtensions>.

     Parameter                  Description
  1  $maximumNumberOfProcesses  Maximum number of processes to run in parallel
  2  @foldersAndExtensions      Folders and file extensions to process.

B<Example:>


  𝗳𝗶𝘅𝗗𝗶𝘁𝗮𝗫𝗿𝗲𝗳𝗛𝗿𝗲𝗳𝘀(1, $outDir, "xml");


=head2 Attributes

=head3 compressedErrors :lvalue

Compressed errors over all files


=head3 docTypes :lvalue

Array of [number of errors, L<project|/project>, L<files|/file>] ordered from least to most errors


=head3 failingFiles :lvalue

{docType}++ - Hash of document types encountered


=head3 failingProjects :lvalue

[Projects with xmllint errors]


=head3 filter :lvalue

File selection filter


=head3 numberOfFiles :lvalue

Number of L<files|/file> encountered


=head3 numberOfProjects :lvalue

Number of L<projects|/project> defined - each L<project|/project> can contain zero or more L<files|/file>


=head3 passingProjects :lvalue

[Projects with no xmllint errors]


=head3 passRatePercent :lvalue

Total number of passes as a percentage of all input files


=head3 print :lvalue

A printable L<report|/report> of the above


=head3 timestamp :lvalue

Timestamp of report


=head3 totalCompressedErrorsFileByFile :lvalue

Total number of errors summed file by file


=head3 totalCompressedErrors :lvalue

Number of compressed errors


=head3 totalErrors :lvalue

Total number of errors



=head1 Private Methods

=head2 lint($@)

Lint a L<files|/file>, using xmllint and update the source file with the results in text format so as to be be easy to search with grep.

     Parameter    Description
  1  $lint        Linter
  2  %attributes  Attributes to be recorded as xml comments

=head2 compressErrors(@)

Compress the errors so we count the ones that do not look similar. Errors typically occupy three lines with the last line containing ^ at the end to mark the location of the error.

     Parameter  Description
  1  @errors    Errors

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::compressErrors


=head2 formatAttributes(%)

Format the attributes section of the output file

     Parameter    Description
  1  $attributes  Hash of attributes

=head2 reuseInProject($)

Record the reuse of an item in the named project

     Parameter  Description
  1  $project   Name of the project in which it is reused

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::reuseInProject


=head2 countLinkTargets($$)

Count the number of targets this link resolves to.

     Parameter  Description
  1  $linkMap   Link map
  2  $link      Label

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::countLinkTargets


=head2 p4($$)

Format a fraction as a percentage to 4 decimal places

     Parameter  Description
  1  $p         Pass
  2  $f         Fail

This is a static method and so should be invoked as:

  Data::Edit::Xml::Lint::p4


=head2 createTest($$$$)

Create a test file

     Parameter    Description
  1  $project     Project name
  2  $source      Source of topic
  3  $target      Target of references
  4  $additional  Additional text for topic

=head2 createTests()

Create some tests



=head1 Index


1 L<author|/author> - Optional author of the xml - only needed if you want to generate an SDL file map.

2 L<catalog|/catalog> - Optional catalog file containing the locations of the DTDs used to validate the xml or  use L<dtds|/dtds> to supply a B<DTD> instead.

3 L<compressedErrors|/compressedErrors> - Compressed errors over all files

4 L<compressedErrorText|/compressedErrorText> - Text of compressed errors.

5 L<compressErrors|/compressErrors> - Compress the errors so we count the ones that do not look similar.

6 L<countLinkTargets|/countLinkTargets> - Count the number of targets this link resolves to.

7 L<createTest|/createTest> - Create a test file

8 L<createTests|/createTests> - Create some tests

9 L<ditaType|/ditaType> - Optional Dita topic type(concept|task|troubleshooting|reference) of the xml - only needed if you want to generate an SDL file map.

10 L<docType|/docType> - The second line: the document type extracted from the L<source|/source>.

11 L<docTypes|/docTypes> - Array of [number of errors, L<project|/project>, L<files|/file>] ordered from least to most errors

12 L<dtds|/dtds> - Optional directory containing the DTDs used to validate the xml.

13 L<errors|/errors> - Total number of uncompressed lint errors detected by xmllint over all files.

14 L<errorText|/errorText> - Text of uncompressed lint errors detected by xmllint over all files.

15 L<failingFiles|/failingFiles> - {docType}++ - Hash of document types encountered

16 L<failingProjects|/failingProjects> - [Projects with xmllint errors]

17 L<file|/file> - File that the xml should be written to or read from by L<lint|/lint>, L<read|/read> or L<relint|/relint>.

18 L<fileNumber|/fileNumber> - File number - assigned by the caller to help debugging transformations.

19 L<filter|/filter> - File selection filter

20 L<fixDitaXrefHrefs|/fixDitaXrefHrefs> - Fix the dita xref href attributes in the corpus determined by B<foldersAndExtensions>.

21 L<formatAttributes|/formatAttributes> - Format the attributes section of the output file

22 L<guid|/guid> - Guid or id of the outermost tag - if not supplied the first definition encountered in each file will be used on the basis that all Dita topics require an id.

23 L<header|/header> - The first line: the xml header extracted from L<source|/source>.

24 L<idDefs|/idDefs> - {id} = count - the number of times this id is defined in the xml contained in this L<file|/file>.

25 L<inputFile|/inputFile> - The file from which this xml was obtained.

26 L<labelDefs|/labelDefs> - {label or id} = id - the id of the node containing a L<label|Data::Edit::Xml/Labels> defined on the xml.

27 L<labels|/labels> - Optional parse tree to supply L<labels|Data::Edit::Xml/Labels> for the current L<source|/source> as the labels are present in the parse tree not in the string representing the parse tree.

28 L<lineNumber|/lineNumber> - The file and line number of the caller so we can identify which request for lint gave rise to a particular file

29 L<lint|/lint> - Lint a L<files|/file>, using xmllint and update the source file with the results in text format so as to be be easy to search with grep.

30 L<lintAttributes|/lintAttributes> - Get all the attributes minus the source of all the linted files in the specified folder

31 L<linted|/linted> - Date the lint was performed by L<lint|/lint>.

32 L<multipleLabelDefs|/multipleLabelDefs> - Return ([L<project|/project>; L<source label or id|Data::Edit::Xml/Labels>; targets count]*) of all L<labels or id|Data::Edit::Xml/Labels> that have multiple definitions

33 L<multipleLabelDefsReport|/multipleLabelDefsReport> - Return a L<report|/report> showing L<labels and id|Data::Edit::Xml/Labels> with multiple definitions in each L<project|/project> ordered by most defined

34 L<new|/new> - Create a new xml linter - call this method statically as in L<Data::Edit::Xml::Lint|/new> and then fill in the relevant L<Attributes>.

35 L<nolint|/nolint> - Store just the attributes in a file so that they can be retrieved later to process non xml objects referenced in the xml - like images

36 L<numberOfFiles|/numberOfFiles> - Number of L<files|/file> encountered

37 L<numberOfProjects|/numberOfProjects> - Number of L<projects|/project> defined - each L<project|/project> can contain zero or more L<files|/file>

38 L<p4|/p4> - Format a fraction as a percentage to 4 decimal places

39 L<passingProjects|/passingProjects> - [Projects with no xmllint errors]

40 L<passRatePercent|/passRatePercent> - Total number of passes as a percentage of all input files

41 L<preferredSource|/preferredSource> - Preferred representation of the xml source, used by L<relint|/relint> to supply a preferred representation for the source.

42 L<print|/print> - A printable L<report|/report> of the above

43 L<processes|/processes> - Maximum number of xmllint processes to run in parallel - 8 by default if linting in parallel is being used.

44 L<project|/project> - Optional L<project|/project> name to allow error counts to be aggregated by L<project|/project> and to allow L<id and labels|Data::Edit::Xml/Labels> to be scoped to the L<files|/file> contained in each L<project|/project>.

45 L<read|/read> - Reread a linted xml L<file|/file> and extract the L<attributes|/Attributes> associated with the L<lint|/lint>

46 L<relint|/relint> - Locate all the L<labels or id|Data::Edit::Xml/Labels> in the specified L<files|/file>, analyze the map of labels and ids with B<analysisSub> parse each L<file|/file>, process each parse with B<processSub>, then L<lint/lint> the reprocessed xml back to the original L<file|/file> - this allows you to reprocess the contents of each L<file|/file> with knowledge of where L<labels or id|Data::Edit::Xml/Labels> are located in the other L<files|/file> associated with a L<project|/project>.

47 L<reload|/reload> - Reload a parse tree from a linted file restoring any labels and return the parse tree or B<undef> if the file is not a lint file.

48 L<report|/report> - Analyze the results of prior L<lints|/lint> and return a hash reporting various statistics and a L<printable|/print> report

49 L<resolveDitaLink|/resolveDitaLink> - Given a specified B<$link>Return the unique (file, leading id, topic ) of the specified link in the link map or () if no such definition exists

50 L<resolveFileToGuid|/resolveFileToGuid> - Return the unique definition of the specified link in the link map or undef if no such definition exists

51 L<resolveUniqueLink|/resolveUniqueLink> - Return the unique (file, leading id) of the specified link in the link map or () if no such definition exists

52 L<reusedInProject|/reusedInProject> - List of projects in which this file is reused, which can be set via L<reuseFileInProject|/reuseFileInProject> every time you discover another project in which a file is reused.

53 L<reuseFileInProject|/reuseFileInProject> - Record the reuse of the specified file in the specified project

54 L<reuseInProject|/reuseInProject> - Record the reuse of an item in the named project

55 L<singleLabelDefs|/singleLabelDefs> - Return ([L<project|/project>; label or id]*) of all labels or ids that have a single definition

56 L<singleLabelDefsReport|/singleLabelDefsReport> - Return a L<report|/report> showing L<label or id|Data::Edit::Xml/Labels> with just one definitions ordered by L<project|/project>, L<label name|Data::Edit::Xml/Labels>

57 L<source|/source> - The source Xml to be written to L<file|/file> and linted.

58 L<squeezeDitaRef|/squeezeDitaRef> - Squeeze a string so it can be safely stored inside blank separated list inside an xml comment.

59 L<timestamp|/timestamp> - Timestamp of report

60 L<title|/title> - Optional title of the xml - only needed if you want to generate an SDL file map.

61 L<totalCompressedErrors|/totalCompressedErrors> - Number of compressed errors

62 L<totalCompressedErrorsFileByFile|/totalCompressedErrorsFileByFile> - Total number of errors summed file by file

63 L<totalErrors|/totalErrors> - Total number of errors

64 L<urlEncode|/urlEncode> - Return a url encoded string

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Data::Edit::Xml::Lint

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2019 Philip R Brenan.

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
use strict;
use warnings FATAL=>qw(all);
use Test::More;
use Test::SharedFork;
use Data::Edit::Xml;

Test::More->builder->output("/dev/null")                                        # Show only errors during testing
  if ((caller(1))[0]//'Data::Edit::Xml::Lint') eq "Data::Edit::Xml::Lint";

if (!-e q(/home/phil/))
 {plan skip_all => 'Not supported';
 }

if (qx(xmllint --version 2>&1) !~ m/using libxml/)                              # Skip tests if xmllint is not installed
 {my $n = Test::More->builder->expected_tests;
  diag("xmllint not installed - skipping all tests");
  ok 1 for 1..$n;
  exit 0
 }

my $catalog = q(/home/phil/r/dita/dita-ot-3.1/catalog-dita.xml);                # Dita catalog to be used for linting.

my $outDir  = "out";                                                            # Output directory
clearFolder($outDir, 1e2);

#goto latestTest;

# Test without file reuse
my @lints;                                                                      # Lints for each test
my %tests;                                                                      # Tests by title

for my $test(createTests)                                                       # Each test within the current project
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
  $lint->catalog   = $catalog;                                                  # Catalog
  $lint->file      = filePathExt($outDir, $project.$source, qw(xml));           # Target file
  $lint->source    = $xml;                                                      # Xml source
  $lint->guid      = my $g = "$project.$source";                                # Guid for this topic
  $lint->lint(foo=>1);                                                          # Write the source to the target file, lint using xmllint, include some attributes to be included as comments at the end of the target file
  $tests{$g} = [$lint, @$test];                                                 # Tests
 }

ok @lints == 16;

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
    ok $s eq q(SingleLabelOrIdDefinitions (96):N 1  Project  LabelN 2  aaa      B1_aaa_1N 3  aaa      B1_aaa_2N 4  aaa      B1_aaa_3N 5  aaa      B1_aaa_4N 6  aaa      B2_aaa_1N 7  aaa      B2_aaa_2N 8  aaa      B2_aaa_3N 9  aaa      B2_aaa_4N10  aaa      C1_aaa_1N11  aaa      C1_aaa_2N12  aaa      C1_aaa_3N13  aaa      C1_aaa_4N14  aaa      C2_aaa_1N15  aaa      C2_aaa_2N16  aaa      C2_aaa_3N17  aaa      C2_aaa_4N18  aaa      b_aaa_1N19  aaa      b_aaa_2N20  aaa      b_aaa_3N21  aaa      b_aaa_4N22  aaa      c_aaa_1N23  aaa      c_aaa_2N24  aaa      c_aaa_3N25  aaa      c_aaa_4N26  bbb      B1_bbb_1N27  bbb      B1_bbb_2N28  bbb      B1_bbb_3N29  bbb      B1_bbb_4N30  bbb      B2_bbb_1N31  bbb      B2_bbb_2N32  bbb      B2_bbb_3N33  bbb      B2_bbb_4N34  bbb      C1_bbb_1N35  bbb      C1_bbb_2N36  bbb      C1_bbb_3N37  bbb      C1_bbb_4N38  bbb      C2_bbb_1N39  bbb      C2_bbb_2N40  bbb      C2_bbb_3N41  bbb      C2_bbb_4N42  bbb      b_bbb_1N43  bbb      b_bbb_2N44  bbb      b_bbb_3N45  bbb      b_bbb_4N46  bbb      c_bbb_1N47  bbb      c_bbb_2N48  bbb      c_bbb_3N49  bbb      c_bbb_4N50  ccc      B1_ccc_1N51  ccc      B1_ccc_2N52  ccc      B1_ccc_3N53  ccc      B1_ccc_4N54  ccc      B2_ccc_1N55  ccc      B2_ccc_2N56  ccc      B2_ccc_3N57  ccc      B2_ccc_4N58  ccc      C1_ccc_1N59  ccc      C1_ccc_2N60  ccc      C1_ccc_3N61  ccc      C1_ccc_4N62  ccc      C2_ccc_1N63  ccc      C2_ccc_2N64  ccc      C2_ccc_3N65  ccc      C2_ccc_4N66  ccc      b_ccc_1N67  ccc      b_ccc_2N68  ccc      b_ccc_3N69  ccc      b_ccc_4N70  ccc      c_ccc_1N71  ccc      c_ccc_2N72  ccc      c_ccc_3N73  ccc      c_ccc_4N74  ddd      B1_ddd_1N75  ddd      B1_ddd_2N76  ddd      B1_ddd_3N77  ddd      B1_ddd_4N78  ddd      B2_ddd_1N79  ddd      B2_ddd_2N80  ddd      B2_ddd_3N81  ddd      B2_ddd_4N82  ddd      C1_ddd_1N83  ddd      C1_ddd_2N84  ddd      C1_ddd_3N85  ddd      C1_ddd_4N86  ddd      C2_ddd_1N87  ddd      C2_ddd_2N88  ddd      C2_ddd_3N89  ddd      C2_ddd_4N90  ddd      b_ddd_1N91  ddd      b_ddd_2N92  ddd      b_ddd_3N93  ddd      b_ddd_4N94  ddd      c_ddd_1N95  ddd      c_ddd_2N96  ddd      c_ddd_3N97  ddd      c_ddd_4N);
    1
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

clearFolder($outDir, 1e2);

#-------------------------------------------------------------------------------
# Test xref linking
#-------------------------------------------------------------------------------

my $xrefSource = [q(aaa1), <<'END'];
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []>
<concept id="sourceTopic">
  <title>Source of xref</title>
  <conbody>
    <p><xref href="targetTagLabel"/></p>
  </conbody>
</concept>
<!--linted: 2019-03-12 at 16:40:17 -->
<!--author: author@author.com -->
<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->
<!--definition: sourceTopic -->
<!--docType: <!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []> -->
<!--file: out/aaa1.xml -->
<!--foo: 1 -->
<!--guid: sourceTopic -->
<!--header: <?xml version="1.0" encoding="UTF-8"?> -->
<!--project: aaa -->
<!--sha256: 3f75bcceaca8b9f3e1a40f0ad939136ee135c87443427fca9e4147d979f17527 -->
END

my $xrefTarget = [q(aaa2), <<'END'];
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []>
<concept id="targetTopic">
  <title>Target of xref</title>
  <conbody>
    <p id="targetTag">Target</p>
  </conbody>
</concept>
<!--linted: 2019-03-12 at 16:40:17 -->
<!--author: author@author.com -->
<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->
<!--definition: targetTopic -->
<!--definition: targetTag -->
<!--docType: <!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []> -->
<!--file: out/aaa2.xml -->
<!--foo: 1 -->
<!--guid: targetTopic -->
<!--header: <?xml version="1.0" encoding="UTF-8"?> -->
<!--project: aaa -->
<!--sha256: 3f75bcceaca8b9f3e1a40f0ad939136ee135c87443427fca9e4147d979f17527 -->
<!--labels: targetTopic targetTopicLabel -->
<!--labels: targetTag   targetTagLabel -->
END

owf(fpe($outDir, $$_[0], q(xml)), $$_[1]) for $xrefSource, $xrefTarget;

fixDitaXrefHrefs(1, $outDir, "xml");                                            #TfixDitaXrefHrefs
ok readFile(fpe($outDir, $$xrefSource[0], q(xml))) =~ m(xref href="aaa2.xml#targetTopic/targetTag")s;

if (1)                                                                          #TlintAttributes
 {my @a = lintAttributes($outDir);
  ok $_->project eq q(aaa) for @a;
 }

if (1)                                                                          #Tread
 {my $x = Data::Edit::Xml::new(<<END);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []>
<concept id="c1">
  <title/>
  <conbody>
  </conbody>
</concept>
END

  $x->addLabels_c2_c3_c4;
  $x->createGuidId;
  is_deeply [$x->getLabels], [qw(c1 c2 c3 c4)];

  my $l = new;                                                                  # Linter
     $l->catalog   = $catalog;                                                  # Catalog
     $l->ditaType  = -t $x;                                                     # Topic type
     $l->file      = fpf($outDir, q(zzz.dita));                                 # Output file
     $l->guid      = $x->id;                                                    # Guid
     $l->inputFile = q(zzz.xml);                                                # Add source file information
     $l->labels    = $x;                                                        # Add label information to the output file so when all the files are written they can be retargeted by Data::Edit::Xml::Lint
     $l->project   = q(aaa);                                                    # Group files into Id scopes
     $l->title     = q(test lint);                                              # Title
     $l->source    = $x->ditaPrettyPrintWithHeaders;                            # Source from parse tree
  $l->lint;

  my $m = &read($l->file);
  my $y = &reload($l->file);
  ok $l->source eq $m->source;
  ok -p $x eq -p $y;
  is_deeply [$x->getLabels], [$y->getLabels];
  clearFolder($outDir, 1e2);
 }

latestTest:;
if (1)                                                                          # Message compression
 {my $N = 10;
   my $x = Data::Edit::Xml::new(<<END);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []>
<concept id="c1">
  <conbody/>
</concept>
END

  for my $i(1..$N)
   {my $l = new;
       $l->catalog   = $catalog;
       $l->file      = fpf($outDir, qq(z$i.dita));
       $l->source    = $x->ditaPrettyPrintWithHeaders;
    $l->lint;
   }

  my $r = report($outDir);
  my ($e) = values %{$r->compressedErrors};
  ok $N == scalar keys %$e;

  clearFolder($outDir, $N+1);
 }

done_testing;
