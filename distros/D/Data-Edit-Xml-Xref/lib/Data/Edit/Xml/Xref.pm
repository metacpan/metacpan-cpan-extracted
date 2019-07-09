#!/usr/bin/perl  -I/home/phil/perl/cpan/DataEditXml/lib/ -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Cross reference Dita XML, match topics and ameliorate missing references.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2019
#-------------------------------------------------------------------------------
# podDocumentation
# Results cannot be accurate until we are at 100% lint
# It is easier to criticize than to fix - but we do some fixes any way.
# Check for image formats that will not display in a browser
# Needs more tests
# Do not consider companion files!
# Images that are referenced by topics which are not referenced by bookmaps showup as referenced
# It should be possible to remove reportImages by using generic references instead
# CONREF processing in reportReferencesFromBookmaps
# Fix xref external/scope and eliminate error count if fixbadrefs in operation.
# Add labels to ditaRefs processing so that references to labels are also fixed
# Eliminate unused ids?
# Concepts can be nested inside concepts and so each sub concept can establish its own address range.  If there is duplication of referenced ids in teh sub ranges then we have to account for the topic id to help disambiguate references -at the moment the ids are assumed to be unique and so no effort is made to use this extra information
# Reports after fix references can be done in parallel as can reports before reportReferencesFromBookMaps

package Data::Edit::Xml::Xref;
our $VERSION = 20190708;
use v5.20;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Edit::Xml;
use Data::Table::Text qw(:all);
use Dita::GB::Standard;
use Time::HiRes qw(time);
use utf8;

sub improvementLength     {80}                                                  #P Maximum length of the test of an improvement suggestion

#D1 Cross reference                                                             # Check the cross references in a set of Dita files and report the results.

sub newXref(%)                                                                  #P Create a new cross referencer
 {my (%attributes) = @_;                                                        # Attributes

  my $xref = genHash(__PACKAGE__,                                               # Attributes used by the Xref cross referencer.
    addNavTitles=>undef,                                                        #I If true, add navtitle to outgoing bookmap references to show the title of the target topic.
    allowUniquePartialMatches=>undef,                                           # Allow unique partial matches - i.e ignore the stuff to the right of the # in a reference if doing so produces a unique result. This feature has been explicitly disabled for conrefs (PS2-561) and might need to be disabled for other types of reference as well.
    attributeCount=>{},                                   # Make input folder absolute                      # {file}{attribute name} == count of the different xml attributes found in the xml files.
    attributeNamesAndValuesCount=>{},                                           # {file}{attribute name}{value} = count
    author=>{},                                                                 # {file} = author of this file.
#   badBookMaps=>{},                                                            # Bad book maps.
#   badConRefsList=>{},                                                         # Bad conrefs - by file.
#   badConRefs=>{},                                                             # {sourceFile} = [file, href] indicating the file has at least one bad conref.
#   badBookMapRefs=>{},                                                         # [file, href]   Invalid href attributes found on bookmapref tags.
    badGuidHrefs=>{},                                                           # Bad conrefs - all.
#   badImageRefs=>{},                                                           # Consolidated images missing.
    badNavTitles=>{},                                                           # Details of nav titles that were not resolved
    badReferencesCount=>0,                                                      # The number of bad references encountered
    badTables=>[],                                                              # Array of tables that need fixing.
    badXml1=>{},                                                                # [Files] with a bad xml encoding header on the first line.
    badXml2=>{},                                                                # [Files] with a bad xml doc type on the second line.
#   badXRefs=>{},                                                               # Bad Xrefs - by file
#   badXRefsList=>{},                                                           # Bad Xrefs - all
    baseTag=>{},                                                                # Base Tag for each file
    bookMapRefs=>{},                                                            # {bookmap full file name}{href}{navTitle}++ References from bookmaps to topics via appendix, chapter, bookmapref.
    changeBadXrefToPh=>undef,                                                   #I Change xrefs being placed in B<M3> by L<fixBadRefs> to B<ph>.
    conRefs=>{},                                                                # {file}{href}   Count of conref definitions in each file.
    currentFolder=>currentDirectory,                                            # The current working folder used to make absolute file names from relative ones
#   debugTimes=>undef,                                                          #I Write timing information if true
    deguidize=>undef,                                                           #I Set true to replace guids in dita references with file name. Given reference B<g1#g2/id> convert B<g1> to a file name by locating the topic with topicId B<g2>.  This requires the guids to be genuinely unique. SDL guids are thought to be unique by language code but the same topic, translated to a different language might well have the same guid as the original topic with a different language code: =(de|en|es|fr).  If the source is in just one language then the guid uniqueness is a reasonable assumption.  If the conversion can be done in phases by language then the uniqueness of guids is again reasonably assured. L<Data::Edit::Xml::Lint> provides an alternative solution to deguidizing by using labels to record the dita reference in the input corpus for each id encountered, these references can then be resolved in the usual manner by L<Data::Edit::Xml::Lint::relint>.
    docType=>{},                                                                # {file} == docType:  the docType for each xml file.
    duplicateIds=>{},                                                           # [file, id]     Duplicate id definitions within each file.
    duplicateTopicIds=>{},                                                      # Duplicate topic ids
    duplicateTopicIds=>{},                                                      # [topicId, [files]] Files with duplicate topic ids - the id on the outermost tag.
    fileExtensions=>[qw(.dita .ditamap .xml .fodt)],                            # Default file extensions to load
    fixBadRefs=>undef,                                                          #I Try to fix bad references in L<these files|/fixRefs> where possible by either changing a guid to a file name assuming the right file is present in the corpus being scanned and L<deguidize|/deguidize> has been set true or failing that by moving the failing reference to the B<xtrf> attribute i.e. placing it in B<M3> possibly renaming the tag to B<ph> if L<changeBadXrefToPh> is in effect.
    fixDitaRefs=>undef,                                                         #I Fix references in a corpus of L<Dita> documents that have been converted to the L<GBStandard> and whose target structure has been written to the named folder.
#   fixedDitaRefs=>[],                                                          # [] topic refs fixed by L<fixDitaRefs>
    fixedFolder=>undef,                                                         # Fixed files are placed in this folder if L<fixBadRefs|/fixBadRefs> has been specified.
    fixedRefsFailed=>[],                                                        # [] hrefs and conrefs from L<fixRefs|/fixRefs> which were moved to the "xtrf" attribute as requested by the L<fixBadHrefs|/fixBadHrefs> attribute because the reference was invalid and could not be improved by L<deguidization|/deguidize>.
    fixedRefsGB=>[],                                                            # [] files fixed to the Gearhart-Brenan file naming standard
    fixedRefs=>[],                                                              # [] hrefs and conrefs from L<fixRefs|/fixRefs> which were invalid but have been fixed by L<deguidizing|/deguidize> them to a valid file name.
    fixedRefsNoAction=>[],                                                      # [] hrefs and conrefs from L<fixRefs|/fixRefs> for which no action was taken.
    fixRefs=>{},                                                                # {file}{ref} where the href or conref target is not valid.
    fixRelocatedRefs=>undef,                                                    #I Fix references to topics that have been moved around in the out folder structure assuming that all file names are unique.
    fixXrefsByTitle=>undef,                                                     #I Try to fix invalid xrefs by the Gearhart Title Method if true
    flattenFiles=>{},                                                           # {old full file name} = file renamed to Gearhart-Brenan file naming standard
    flattenFolder=>undef,                                                       #I Files are renamed to the Gearhart standard and placed in this folder if set.  References to the unflattened files are updated to references to the flattened files.  This option will eventually be deprecated as the Dita::GB::Standard is now fully available allowing files to be easily flattened before being processed by Xref.
#   goodBookMaps=>{},                                                           # Good book maps.
#   goodConRefs=>{},                                                            # Good con refs - by file.
#   goodConRefsList=>{},                                                        # Good con refs - all.
#   goodGuidHrefs=>{},                                                          # {file}{href}{location}++ where a href that starts with GUID- has been correctly resolved.
#   goodImageRefs=>{},                                                          # Consolidated images found.
    goodNavTitles=>{},                                                          # Details of nav titles that were resolved
#   goodBookMapRefs=>{},                                                          # Good topic refs.
#   goodXRefs=>{},                                                              # Good xrefs - by file.
#   goodXRefsList=>{},                                                          # Good xrefs - all.
    guidHrefs=>{},                                                              # {file}{href} = location where href starts with GUID- and is thus probably a guid.
    guidToFile=>{},                                                             # {topic id which is a guid} = file defining topic id.
    hrefUrlEncoding=>{},                                                        # Hrefs that need url encoding because they contain white space
    ids=>{},                                                                    # {file}{id}     Id definitions across all files.
    images=>{},                                                                 # {file}{href}   Count of image references in each file.
    imagesReferencedFromBookMaps=>{},                                           # {bookmap full file name}{full name of image referenced from topic referenced from bookmap}++
    imagesReferencedFromTopics=>{},                                             # {topic full file name}{full name of image referenced from topic}++
    improvements=>{},                                                           # Suggested improvements - a list of improvements that might be made.
    inputFiles=>[],                                                             # Input files from L<inputFolder|/inputFolder>.
    inputFileToTargetTopics=>{},                                                # {input file}{target file}++ : Tells us the topics an input file was split into
    inputFolderImages=>{},                                                      # {full image file name} for all files in input folder thus including any images resent
    inputFolder=>undef,                                                         #I A folder containing the dita and ditamap files to be cross referenced.
    ltgt=>{},                                                                   # {text between &lt; and &gt}{filename} = count giving the count of text items found between &lt; and &gt;
    matchTopics=>undef,                                                         #I Match topics by title and by vocabulary to the specified confidence level between 0 and 1.  This operation might take some time to complete on a large corpus.
    maximumNumberOfProcesses=>4,                                                #I Maximum number of processes to run in parallel at any one time.
    maxZoomIn=>undef,                                                           #I Optional hash of names to regular expressions to look for in each file
    maxZoomOut=>{},                                                             # Results from L<maxZoomIn|/maxZoomIn>  where {file name}{regular expression key name in L<maxZoomIn|/maxZoomIn>}++
    md5Sum=>{},                                                                 # MD5 sum for each input file.
    missingImageFiles=>{},                                                      # [file, href] == Missing images in each file.
    missingTopicIds=>{},                                                        # Missing topic ids.
    noHref=>{},                                                                 # Tags that should have an href but do not have one.
    notReferenced=>{},                                                          # {file name} Files in input area that are not referenced by a conref, image, bookmapref or xref tag and are not a bookmap.
    olBody=>{},                                                                 # The number of ol under body by file
    originalSourceFileAndIdToNewFile=>{},                                       # {original file}{id} = new file: Record mapping from original source file and id to the new file containing the id
    parseFailed=>{},                                                            # {file} files that failed to parse.
    printSummaryLine=>1,                                                        #I Print the summary line if true - on by default.
    references=>{},                                                             # {file}{reference}++ - the various references encountered
    relocatedReferencesFailed=>[],                                              # Failing references that were not fixed by relocation
    relocatedReferencesFixed=>[],                                               # Relocated references fixed
    requestAttributeNameAndValueCounts=>undef,                                  #I Report attribute name and value counts
    reports=>q(reports),                                                        #I Reports folder: the cross referencer will write reports to files in this folder.
    results=>[],                                                                # Summary of results table.
    sourceFile=>undef,                                                          # The source file from which this structure was generated.
    sourceTopicToTargetBookMap=>{},                                             # {input topic cut into multiple pieces} = output bookmap representing pieces
    statusLine=>undef,                                                          # Status line summarizing the cross reference.
    statusTable=>undef,                                                         # Status table summarizing the cross reference.
    tagCount=>{},                                                               # {file}{tags} == count of the different tag names found in the xml files.
    tagsTextsRatio=>undef,                                                      # Ratio of tags to text encountered
    tags=>undef,                                                                # Number of tags encountered
    targetFolderContent=>{},                                                    # {file} = bookmap file name : the target folder content which shows us where an input file went
    targetTopicToInputFiles=>{},                                                # {current file} = the source file from which the current file was obtained
    texts=>undef,                                                               # Number of texts encountered
    timeEnded=>undef,                                                           # Time the run ended
    timeStart=>undef,                                                           # Time the run started
    title=>{},                                                                  # {file} = title of file.
    titleToFile=>{},                                                            # {title}{file}++ if L<fixXrefsByTitle> is in effect
    topicIds=>{},                                                               # {file} = topic id - the id on the outermost tag.
    topicsFlattened=>undef,                                                     # Number of topics flattened
    topicFlattening=>{},                                                        # {topic}{sources}++ : the source files for each topic that was flattened
    topicFlatteningFactor=>{},                                                  # Topic flattening factor - higher is better
    topicsReferencedFromBookMaps=>{},                                           # {bookmap file, file name}{topic full file name}++
    validationErrors=>{},                                                       # True means that Lint detected errors in the xml contained in the file.
    vocabulary=>{},                                                             # The text of each topic shorn of attributes for vocabulary comparison.
    xrefBadFormat=>{},                                                          # External xrefs with no format=html.
    xrefBadScope=>{},                                                           # External xrefs with no scope=external.
    xRefs=>{},                                                                  # {file}{href}++ Xrefs references.
    xrefsFixedByTitle=>[],                                                      # Xrefs fixed by locating a matching topic title from their text content.
   );

  loadHash($xref, @_);                                                          # Load attributes complaining about any invalid ones
 } # newXref

sub xref(%)                                                                     # Check the cross references in a set of Dita files held in  L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder. The possible attributes are defined in L<Data::Edit::Xml::Xref|/Data::Edit::Xml::Xref>
 {my $xref = newXref(@_);                                                       # create the cross referencer

  $xref->timeStart = time;                                                      # Start time

  $xref->inputFolder or confess "Please supply a value for: inputFolder";
  $xref->inputFolder =~ s(\/+\Z) (\/)gs;                                        # Cleanup path names
  $xref->inputFolder =                                                          # Make input folder absolute
    absFromAbsPlusRel($xref->currentFolder, $xref->inputFolder)
    if $xref->inputFolder !~ m(\A/);

  if (my $d = $xref->fixDitaRefs)                                               # Fully qualify and validate targets folder
   {$xref->fixDitaRefs = fullyQualifiedFile($d) ? $d :                          # Fully qualified target folder name
              absFromAbsPlusRel($xref->currentFolder, $d);                      # Get fully qualified target folder if necessary
    if (!-d $d)                                                                 # Check targets folder is available
     {confess "Targets folder does not exist: fixDitaRefs=>$d";
     }
    my @d = searchDirectoryTreesForMatchingFiles($d);
    @d or confess "Targets folder is empty: fixDitaRefs=>$d";
   }

  my @series =   (q(loadInputFiles),                                            # Must be done in series
                  q(analyzeInputFiles),
                  q(reportReferencesFromBookMaps),                              # Used by fixReferences to get bookmap references
                  $xref->deguidize ? q(reportGuidsToFiles) : (),                # Used by addNavTitleToMaps
                  q(checkReferences),                                           # Check all the references
                  q(fixReferences),                                             # Fix any failing references
                 );

  my @parallel = (                                                              # Can be done in parallel
#                 q(reportXrefs),                                               # Unified reference processing
#                 q(reportBookMapRefs),                                         # Bad BookMapRefs incorrectly set
                  q(reportXml1),
                  q(reportXml2),
                  q(reportDuplicateIds),
                  q(reportDuplicateTopicIds),
                  q(reportNoHrefs),
                  q(reportTables),
#                 q(reportConrefs),                                             # Unified reference processing
                  q(reportImages),
                  q(reportParseFailed),
                  q(reportAttributeCount),
                  q(reportLtGt),
                  q(reportTagCount),
                  q(reportTagsAndTextsCount),
                  q(reportDocTypeCount),
                  q(reportFileExtensionCount),
                  q(reportFileTypes),
                  q(reportValidationErrors),
#                 q(reportBookMaps),                                            # Bad BookMapRefs incorrectly set
                  q(reportGuidHrefs),
                  q(reportExternalXrefs),
                  q(reportPossibleImprovements),
                  q(reportMaxZoomOut),
                  q(reportTopicDetails),
                  q(reportTopicReuse),
#                 q(reportMd5Sum),                                              # Not parallelized: takes too much time in series
                  q(reportOlBody),
                  q(reportHrefUrlEncoding),
                  q(reportFixRefs),
                  q(reportSourceFiles),
                 );

  if ($xref->addNavTitles)                                                      # Add nav titles to bookmaps if requested
   {push @parallel, q(addNavTitlesToMaps);
   }

  if ($xref->requestAttributeNameAndValueCounts)                                # Report attribute name and value counts
   {push @parallel,  q(reportAttributeNameAndValueCounts);
   }

  if ($xref->flattenFolder)                                                     # Fix file names to the Gearhart-Brenan file naming standard
   {push @parallel, q(fixFilesGB)
   }

  if ($xref->matchTopics)                                                       # Topic matching reports
   {push @parallel, q(reportSimilarTopicsByTitle),
                    q(reportSimilarTopicsByVocabulary);
   }

# push @parallel, q(reportNotReferenced);                                       # Need to account for changes made by fixFiles or FixFilesGB

  if (1)                                                                        # Perform phases in series that must be run in series
   {my @times;
    for my $phase(@series)
     {my $startTime = time;
      $xref->$phase;
      push @times, [$phase, time - $startTime];
     }

    formatTable([sort {$$b[1] <=> $$a[1]} @times], <<END,
Phase Xref processing phase
Time  Time in seconds taken by processing phase
END
    title=>qq(Processing phases elapsed times in descending order),
    head =>qq(Xref phases took the following times on DDDD),
    file =>fpe($xref->reports, q(timing), qw(phases txt)));                     # Write phase times
   }

  if (1)                                                                        # Perform phases in parallel that can be run in parallel
   {runInParallel($xref->maximumNumberOfProcesses,
      sub                                                                       # Execute each phase in parallel
       {my ($phase) = @_;
        $xref->$phase
       },
      sub                                                                       # Decode results
       {for my $r(@_)
         {next unless $r;
          for my $k(sort keys %$r)
           {$xref->{$k} = $$r{$k};
           }
         }
       },
      @parallel);                                                               # Each phase to be run parallel
   }

  formattedTablesReport
   (title=>q(Reports available),
    head=><<END,
NNNN reports available on DDDD

Sorted by title
END
   file=>fpe($xref->reports, qw(reports txt)));

  if (1)                                                                        # Summarize
   {my @o;
    my $save = sub
     {my ($levels, $field, $plural, $single) = @_;
      my $n = &countLevels($levels, $xref->{$field});
      push @o, [$n,            $plural]                   if $n >  1;
      push @o, [$n, $single // ($plural =~ s(s\Z) ()gsr)] if $n == 1;
     };

#   $save->(1, "badBookMapRefs",    q(bad bookmaprefs));
#   $save->(1, "badBookMaps",       q(bad book maps));                          # Status line components
    $save->(1, "badConRefsList",    q(conrefs));
    $save->(1, "badConRefs",        q(files with bad conrefs), q(file with bad conrefs));
    $save->(1, "badGuidHrefs",      q(invalid guid hrefs));
#   $save->(1, "badImageRefs",      q(missing image files));
    $save->(1, "badTables",         q(tables));
#   $save->(0, "badReferencesCount",q(bad refs));
    $save->(1, "badXml1",           q(first lines));
    $save->(1, "badXml2",           q(second lines));
    $save->(1, "badXRefsList",      q(xrefs));
    $save->(1, "badXRefs",          q(files with bad xrefs), q(file with bad xrefs));
    $save->(1, "duplicateIds",      q(duplicate ids));
    $save->(1, "fixedRefsFailed",   q(refs));                                   # Unable to resolve these references - L<fixBadRefs> can be used to ameliorate them.
    $save->(1, "hrefUrlEncoding",   q(href url encoding), q(href url encoding));
    $save->(1, "missingImageFiles", q(image refs));
    $save->(1, "missingTopicIds",   q(missing topic ids));
    $save->(1, "notReferenced",     q(files not referenced), q(file not referenced));
    $save->(1, "parseFailed",       q(files failed to parse), q(file failed to parse));
    $save->(2, "duplicateTopicIds", q(duplicate topic ids));
#   $save->(2, "improvements",      q(improvements));
    $save->(2, "noHref",            q(hrefs missing), q(href missing));
    $save->(2, "validationErrors",  q(validation errors)); # Needs testing
    $save->(2, "xrefBadFormat",     q(External xrefs with no format=html));
    $save->(2, "xrefBadScope",      q(External xrefs with no scope=external));

    $xref->statusLine = @o ? join " ",                                          # Status line
      "Xref:", join ", ",
               map {join " ", @$_}
               sort
                {return $$a[1] cmp $$b[1] if $$b[0] == $$a[0];
                 $$b[0] <=> $$a[0]
                }
               @o : q();

    $xref->statusTable = formatTable
     ([sort {$$b[0] <=> $$a[0]} @o], [qw(Count Condition)]);                    # Summary in status form
    $xref->results = \@o;                                                       # Save status line components

    if (@o and $xref->printSummaryLine)                                         # Summary line
     {say STDERR $xref->statusLine;
     }
   }

  $xref->timeEnded = time;                                                      # Run ended time

  formatTable([[$xref->timeStart, $xref->timeEnded,                             # Write run times
                $xref->timeEnded - $xref->timeStart]],
  <<END,
Start_Time   Start time of the run
End_Time     End time of the run
Elapsed_Time Xref took this many seconds to run
END
    title => qq(Run times in seconds),
    head  => qq(Xref took the following time to run on DDDD),
    file  => fpe($xref->reports, q(timing), qw(run txt)));

  $xref                                                                         # Return Xref results
 }

sub countLevels($$)                                                             #P Count has elements to the specified number of levels
 {my ($l, $h) = @_;                                                             # Levels, hash
  if ($l == 0)
   {return $h;
   }
  if ($l == 1)
   {return scalar keys @$h if ref($h) =~ m(array)i;
    return scalar keys %$h if ref($h) =~ m(hash)i;
   }
  my $n = 0;
  if   (ref($h) =~ m(hash)i)
   {$n += &countLevels($l-1, $_) for values %$h;
   }
  elsif (ref($h) =~ m(array)i)
   {$n += &countLevels($l-1, $_) for values @$h;
   }
  $n
 }

sub externalReference($)                                                        #P Check for an external reference
 {my ($reference) = @_;                                                         # Reference to check
  $reference =~ m(\A(https?:|mailto:|www))is                                    # Check reference
 }

sub loadInputFiles($)                                                           #P Load the names of the files to be processed
 {my ($xref) = @_;                                                              # Cross referencer
  my @in = $xref->inputFiles =
   [searchDirectoryTreesForMatchingFiles
    $xref->inputFolder, @{$xref->fileExtensions}];

  if (@in == 0)                                                                 # Complain if there are no input files to analyze
   {my $i = $xref->inputFolder;
    my $e = join " ", @{$xref->fileExtensions};
    my $x = -d $i ? "The input folder does exist." :
                    "The input folder does NOT exist!";
    lll "No files with the specified file extensions",
        " in the specified input folder:\n",
        "$e\n$i\n$x";
   }

  my @images = searchDirectoryTreesForMatchingFiles($xref->inputFolder);        # Input files
  $xref->inputFolderImages = {map {fn($_), $_} @images};                        # Image file name which works well for images because the md5 sum in their name is probably unique
 }

sub analyzeOneFile($$)                                                          #P Analyze one input file
 {my ($Xref, $iFile) = @_;                                                      # Xref request, File to analyze
  my $xref = bless {};                                                          # Cross referencer for this file
     $xref->sourceFile = $iFile;                                                # File analyzed
  my @improvements;                                                             # Possible improvements
  my %maxZoomIn = $Xref->maxZoomIn ?  %{$Xref->maxZoomIn} : ();                 # Regular expressions from maxZoomIn to look for text
  my %maxZoomOut;                                                               # Text elements that match a maxZoomIn regular expression
  my $changes;                                                                  # Changes made to the file
  my $tags; my $texts;                                                          # Number of tags and text elements

  my $source = readFile($iFile);                                                # Source of file so we can gets its GB Standard name

  my $x = eval {Data::Edit::Xml::new($iFile)};                                  # Parse xml - at this point if the caller is interested in line numbers they should have added them.

  if ($@)                                                                       # Check we were able to parse the xml
   {$xref->parseFailed->{$iFile}++;
    return $xref;
   }

  my $md5    = $xref->md5Sum->{$iFile} = -M $x;                                 # Md5 sum for parse tree

  $xref->flattenFiles->{$iFile} =                                               # Record correspondence between existing file and its GB Standard file name
    Dita::GB::Standard::gbStandardFileName($source, fe($iFile), md5=>$md5);

  my $saveReference = sub                                                       # Save a reference so it can be integrity checked later
   {my ($ref) = @_;                                                             # Reference
    return if externalReference($ref);                                          # Looks like an external reference
    $xref->references->{$iFile}{$ref}++;                                        # Save reference
   };

  $x->by(sub                                                                    # Each node
   {my ($o) = @_;
    if ($o->isText) {++$texts} else {++$tags}

    my $content = sub                                                           #P First few characters of content on one line to avoid triggering multi table layouts
     {my ($o) = @_;                                                             # String
      nws($o->stringContent, improvementLength);                                # Length of improvement
     };

    my $loc = sub                                                               #P Location
     {my ($o) = @_;                                                             # String
      ($o->lineLocation, $iFile)
     };

    my $tag = -t $o;

    if (my $i = $o->id)                                                         # Id definitions
     {$xref->ids->{$iFile}{$i}++;
     }

    if ($tag eq q(xref))                                                        # Xrefs but not to the web
     {if (my $h = $o->href)
       {if (externalReference($h))                                              # Check attributes on external links
         {if ($o->attrX_scope !~ m(\Aexternal\Z)s)
           {$xref->xrefBadScope->{$iFile}{$h} = -A $o;
           }
          if ($o->attrX_format !~ m(\Ahtml\Z)s)
           {$xref->xrefBadFormat->{$iFile}{$h} = -A $o;
           }
         }
        elsif ($h =~ m(\Aguid-)is)                                              # Href is a guid
         {$xref->guidHrefs->{$iFile}{$h} = [$tag, $o->lineLocation];
         }
        else #if ($o->attrX_format =~ m(\Adita)i)                               # Check xref has format=dita AW83 at 2018.12.13 01:10:33
         {$xref->xRefs->{$iFile}{$h}{$o->stringText}++;
         }
       }
      else
       {push @{$xref->noHref->{$iFile}}, [$tag, $o->lineLocation, $iFile];      # No href
       }
     }
    elsif ($tag =~ m(\A(appendix|chapter|link|mapref|notices|topicref)\Z)is)    # References from bookmaps
     {if (my $h = $o->href)
       {if ($h =~ m(\Aguid-)is)                                                 # Href is a guid
         {$xref->guidHrefs->{$iFile}{$h} = [$tag, $o->lineLocation];
         }
        else
         {$xref->bookMapRefs->{$iFile}{$h}{$o->attr_navtitle//$o->stringText}++;
         }
       }
      elsif ($tag !~ m(\A(notices)\Z)s)                                         # Notices is often positioned in a bookmap and left empty for author convenience
       {push @{$xref->noHref->{$iFile}}, [$tag, $o->lineLocation, $iFile];      # No href
       }
     }
    elsif ($tag eq q(image))                                                    # Images
     {if (my $h = $o->href)
       {if ($h =~ m(\Aguid-)is)                                                 # Href is a guid
         {$xref->guidHrefs->{$iFile}{$h} = [$tag, $o->lineLocation];            # Resolve image later
         }
        else
         {$xref->images->{$iFile}{$h}++;
         }
        $xref->imagesReferencedFromTopics->{$iFile}{$h}++;                      # Image referenced from a topic
       }
      else
       {push @{$xref->noHref->{$iFile}}, [$tag, $o->lineLocation, $iFile];      # No href
       }
     }

    if (my $conref = $o->attr_conref)                                           # Conref
     {$xref->conRefs->{$iFile}{$conref}++;
      &$saveReference($conref);
     }

    if (my $conref = $o->attr_conrefend)                                        # Conref end
     {$xref->conRefs->{$iFile}{$conref}++;
      &$saveReference($conref);
     }

    if ($o->isText_p)                                                           # Notes
     {my $t = nws($o->text, improvementLength);
      if ($t =~ m(\b(Attention|Caution|Danger|Fastpath|Important|Notice|Note|Remember|Restriction|Tip|Trouble|Warning)\b)is)
       {push @improvements, ["Note", $t, &$loc];
       }
     }
    elsif ($tag eq q(required-cleanup))                                         # Required cleanup
     {my $t = &$content;
      push @improvements, [-t $o, $t, &$loc];
     }
    elsif ($tag eq q(steps-unordered))                                          # Steps unordered
     {my $t = nws(-c $o, improvementLength);
      push @improvements, [-t $o, $t, &$loc];
     }
    elsif ($tag eq q(p))                                                        # Paragraphs with lots of bold
     {my $n = my @c = $o->c_b;
      if ($n >= 3)
       {my $t = &$content;
        push @improvements,
         [q(More than 3 bold in p), $t, &$loc];
       }
     }
    elsif ($tag eq q(title) and $o->parent == $x)                               # Title
     {my $t = $o->stringContent;
      $xref->title->{$iFile} = $t;                                              # Topic Id

      if (my $p = $o->parent)
       {if (my ($w) = split /\s+/, $t, 2)
         {my $task = $w =~ m(\AHow|ing\Z)is;                                    # How/ing concept/task

          if ($p->at_concept && $task)
           {push @improvements, [q(Better as task?),    $t, &$loc];
           }
          elsif ($p->at_task && !$task)
           {push @improvements, [q(Better as concept?), $t, &$loc];
           }
         }
       }
     }
    elsif ($o->at_mainbooktitle_booktitle_bookmap)                              # Title for bookmaps
     {my $t = $xref->title->{$iFile} //= $o->stringText;
     }
    elsif ($tag eq q(author))                                                   # Author
     {$xref->author->{$iFile} = my $t = &$content;
     }
    elsif ($tag eq q(ol))                                                       # Ol
     {if (my $p = $o->parent)
       {if ($p->tag =~ m(body\Z)s)
         {$xref->olBody->{$iFile}++;
         }
       }
     }
    elsif ($tag eq q(tgroup))                                                   # Tgroup cols
     {my $error = sub                                                           # Table error message
       {push @{$xref->badTables},
         [join('', @_), $tag, $o->lineLocation, $iFile];
       };

      my $stats     = $o->ditaTGroupStatistics;                                 # Statistics for table
      my $cols      = $stats->colsAttribute;
      my $maxCols   = max($stats->maxHead//0, $stats->maxBody//0);
      my $maxColsMP = max($stats->maxHeadMinusPadding//0,
                          $stats->maxBodyMinusPadding//0);
      if (($stats->maxHead//0) == $maxCols &&                                   # The right combination of body and header
          ($stats->minHead//0) == $maxCols &&
          ($stats->maxBody//0) == $maxCols &&
          ($stats->minBody//0) == $maxCols &&
           $stats->colSpec     == $maxCols
       or !defined($stats->maxHead)        &&                                   # No headers but everything else looks good
          ($stats->maxBody//0) == $maxCols &&
          ($stats->minBody//0) == $maxCols &&
           $stats->colSpec     == $maxCols)
       {if (!$cols)                                                             # Check for cols attribute
         {$error->(qq(No cols attribute, should be $maxCols));
         }
        elsif ($cols ne $maxCols)                                               # Cols present but wrong
         {$error->(qq(Cols attribute is $cols but should be $maxCols));
         }
       }
      elsif ($maxColsMP > (my $actual = $stats->maxHead//0))                    # Not enough headers
       {$error->(qq(Not enough headers, $actual vs $maxColsMP));
       }
      else
       {$error->(qq(Column padding required));
       }
     }
    elsif (keys %maxZoomIn and $o->isText)                                      # Search for text using Micaela's Max Zoom In Method
     {my $t = $o->text;
      for my $name(sort keys %maxZoomIn)                                        # Each regular expression to check
       {my $re = $maxZoomIn{$name};
        if ($t =~ m($re)is)
         {$maxZoomOut{$name}++
         }
       }
     }

    if (my $h = $o->href)                                                       # Check href
     {if ($h =~ m(\s)s and externalReference($h))                               # Check href for url encoding needed
       {$xref->hrefUrlEncoding->{$iFile}{$o->lineLocation} = $h;
       }
      if ($xref->deguidize and $h =~ m(\bguid-)is)                              # Deguidizing a href that looks as if it might have a guid in it
       {$xref->fixRefs->{$iFile}{$h}++
       }

      &$saveReference($h);
     }

    if ($o->isText)                                                             # Check text for interesting constructs
     {my $t = $o->text;
      my @l = $t =~ m(&lt;(.*?)&gt;)g;
      for my $l(@l)
       {$xref->ltgt->{$iFile}{$l}++;
       }
     }
   });

  push @{$xref->improvements->{$iFile}}, @improvements if @improvements;        # Save improvements
  $xref->maxZoomOut->{$iFile} = \%maxZoomOut;                                   # Save max zoom

  $xref->topicIds                    ->{$iFile} = $x->id;                       # Topic Id
  $xref->docType                     ->{$iFile} = $x->tag;                      # Document type
  $xref->attributeCount              ->{$iFile} = $x->countAttrNames;           # Attribute names
  $xref->attributeNamesAndValuesCount->{$iFile} = $x->countAttrNamesAndValues;  # Attribute names and values
  $xref->baseTag                     ->{$iFile} = $x->tag;                      # Tag on base node
  $xref->tagCount                    ->{$iFile} = $x->countTagNames;            # Tag names
  $xref->tags                        ->{$iFile} = $tags;                        # Number of tags
  $xref->texts                       ->{$iFile} = $texts;                       # Number of texts
  $xref->vocabulary                  ->{$iFile} = $x->stringTagsAndText;        # Text of topic minus attributes

  if (1)                                                                        # Check xml headers and lint errors
   {my @h = split /\n/, my $s = readFile($iFile);
    if (!$h[0] or $h[0] !~ m(\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?>\Z))
     {$xref->badXml1->{$iFile}++;
     }
    my $tag = $x->tag;
    if (!$h[1] or $h[1] !~ m(\A<!DOCTYPE $tag PUBLIC "-//))
     {$xref->badXml2->{$iFile}++;
     }

    $xref->validationErrors->{$iFile}++ if $s =~ m(<!--compressedErrors:)s;     # File has validation errors
   }

  $xref
 } # analyzeOneFile

sub reportGuidsToFiles($)                                                       #P Map and report guids to files
 {my ($xref) = @_;                                                              # Xref results
  my @r;
  for   my $file(sort keys %{$xref->topicIds})                                  # Each input file which will be absolute
   {if (my $topicId = $xref->topicIds->{$file})                                 # Topic Id for file - we report missing topicIds in: reportDuplicateTopicIds
     {next unless $topicId =~ m(\AGUID-)is;
      $xref->guidToFile->{$topicId} = $file;                                    # Guid Topic Id to file
      push @r, [$topicId, $file];
     }
   }

  formatTable(\@r, <<END,
Guid The guid being defined
File The file that defines the guid
END
    title    =>qq(Guid topic definitions),
    head     =>qq(Xref found NNNN guid topic definitions on DDDD),
    summarize=>1,
    file     =>fpe($xref->reports, q(lists), qw(guidsToFiles txt)));
 }

sub editXml($$$)                                                                #P Edit an xml file
 {my ($in, $out, $x) = @_;                                                      # Input file, output file, parse tree
  my $s = readFile($in);
  my ($l1, $l2)      = split m/\n/, $s, 3;                                      # Header lines
  my (undef, $lint)  = split m/(?=\<\!\-\-linted\:)/, $s, 2;                    # Lint comments
  my $t = (-p $x).($lint ? qq(\n$lint) : q());                                  # Insert new file contents
  if ($l1 =~ m(\A<\?xml))                                                       # Check headers - should be improved
   {owf($out, qq($l1\n$l2\n$t));
   }
  else
   {owf($out, $t);
   }
 }

# Fix a file by moving its hrefs and conrefs to the xtrf attribute unless
# deguidization is in effect and the guid can be converted into a valid Dita
# reference accessing a file in the input corpus.
#
# If fixRelocatedRefs is in effect: such references are fixed by assuming that
# the files mentioned in broken links have been relocated else where in the
# elsewhere in the folder structure and can be located by base file name alone.
#
# If fixXrefsByTitle is in effect apply the Gearhart Title Method: fix broken
# xrefs by looking for a unique topic with the same title text as the content of
# the xref.
#
# If fixDitaRefs is in effect we are converting Dita to Dita: relink Dita
# references that were valid in the input corpus to make them valid again in the
# output corpus even after files have been cut out and renamed to the GB Standard.
# The targets/ folder provides the mapping between the input and output corpii.

sub fixReferencesInOneFile($$)                                                  #P Fix one file by moving unresolved references to the xtrf attribute
 {my ($xref, $sourceFile) = @_;                                                 # Xref results, source file to fix
  my $node;                                                                     # The current node we are working with
  my $attr;                                                                     # The current attribute we are working with
  my $ref;                                                                      # The current reference we are working with
  my @bad;                                                                      # Hrefs that could not be fixed and so were ameliorated by moving them to @xtrf
  my @good;                                                                     # Hrefs that were fixed by resolving a Guid

  my %baseFiles;                                                                # Map base files back to full files. The base file is the file name shorn of the path - the reason the GB Standard is so important
  if ($xref->fixRelocatedRefs)                                                  # Load base file name to full name but if needed to do relocation fixes
   {for my $file(searchDirectoryTreesForMatchingFiles($xref->inputFolder))      # All input files
     {my $base = fne $file;                                                     # Base file name - the GB Standard name for the file
      $baseFiles{$base}{$file}++;                                               # Current location of the file
     }
   }

  my $refDetails = sub                                                          # Save details of a reference
   {my ($r) = @_;
    my $s = $xref->targetTopicToInputFiles->{$sourceFile};                      # The source file(s) from which each target was obtained
    [$r, $node->tag, $attr, $ref, $sourceFile, sort keys %$s]                   # Construct reference details
   };

  my $bad = sub                                                                 # Save details of a bad reference
   {my ($r) = @_;
    push @bad, my $R = &$refDetails($r);
    $R
   };

  my $good = sub                                                                # Save details of a good reference
   {my ($r) = @_;
    push @good, my $R = &$refDetails($r);
    $R
   };

  my $fixXrefByTitle = sub                                                      # Attempt to fix an xref by using its text content to search for a matching title
   {return undef unless -t $node eq q(xref);                                    # Only works for xrefs

    my $content     = -C $node;
    if (my $topics  = $xref->titleToFile->{nws($content)})                      # Find the topics that match the title text content
     {if (keys %$topics == 1)                                                   # Unique matching topic
       {my ($path)  = keys %$topics;
        my $rel     = relFromAbsAgainstAbs($path, $sourceFile);                 # Relative file name
        $node->href = $rel;                                                     # Update xref
        return &$good(q(Fixed by title));                                       # Report fix made
       }
     }
    undef                                                                       # Failed
   };

  my $fixRelRef = sub                                                           # Attempt to fix a reference broken by relocation
   {my ($R, $rest) = split m(#)s, $ref;                                         # Get referenced file name
    if ($R)
     {my $r = fne($R);                                                          # Href file base name
      if (my $F = $baseFiles{$r})                                               # Relocated else where
       {my @targets = sort keys(%$F);                                           # Relocation targets
        if (@targets == 1)                                                      # Just one such relocation
         {my $f = relFromAbsAgainstAbs($targets[0], $sourceFile);               # Link to it
          if ($f ne $R)
           {my $newLink;                                                        # Fix if the target is else where
            if ($rest)                                                          # Link has more than one component
             {$node->set($attr=>($newLink = $f.q(#).$rest));                    # Reset link
             }
            else                                                                # Link has just one component
             {$node->set($attr=>($newLink = $f));                               # Reset link
             }
            return &$good(q(Relocated));                                        # Report fix of a relocated reference
           }
         }
       }
     }
    undef                                                                       # Failed
   };


  my $locateUniqueTopicSourceForTargetFile = sub                                # Unique source file in the input corpus corresponding to the specified target file else undef
   {my ($targetFile) = @_;                                                      # The target file we want to locate a unique source file from
    my $inputFiles = $xref->targetTopicToInputFiles->{$targetFile};             # Input files corresponding to target file
    return undef unless $inputFiles;                                            # Only if we have input files corresponding to this target file
###    return undef unless keys %$inputFiles == 1;                              # Unique source file - there might be multiple source files due to flattening
    my ($inputFile) = sort keys %$inputFiles;                                   # The unique source file
    $inputFile
   };

# Given a bookmap and a href to a topic in in in/ find that topic in out/
#   - Find source of bookmap
#     - Find source of topic
#       - Find target of topic
#         - If target is a bookmap, substitute it
#         - If target is a topic, replace it
# The original source topic was split into several sub topics as described by a bookmap.
# A Dita Book Map reference to such a topic should be replaced by the bookmap content.
# Conversely, existing map to map references should be left alone

  my $fixBookMapDitaRef = sub                                                   # Fix a partial dita reference in a bookmap.  If the reference is to a single topic then replace the href with the renamed topic.  If the reference is to a topic that was cut into multiple sub topics then replace the reference with the bookmap that represents the cut out topic.
   {return undef unless $xref->fixDitaRefs;                                     # Only works if we have the targets folder information

    $sourceFile =~ m(ditamap\Z)s or confess "Not a bookmap: $sourceFile";       # Must be a bookmap - need a better test

    my $bookMapSource = &$locateUniqueTopicSourceForTargetFile($sourceFile);    # Source of the book map
       $bookMapSource or confess "No source for $sourceFile";

    my $sourceTopic = absFromAbsPlusRel($bookMapSource, $ref);                  # Source topic relative to source bookmap
       $sourceTopic or confess "No source for $bookMapSource + $ref";

    if (my $sourceTarget = $xref->sourceTopicToTargetBookMap->{$sourceTopic})   # Target of source topic via targets/ folder
     {my $sourceDocType    = $sourceTarget->sourceDocType;                      # Source document type
      my $sourceTargetType = $sourceTarget->targetType;                         # Target document type
      if ($sourceDocType !~ m(map\Z)s and $sourceTargetType =~ m(\Abookmap\Z))  # Replace this chapter or topic with the content of the book map generated to represent a non bookmap topic that was split into several sub topics described by a bookmap
       {my $generatedBookMap = $sourceTarget->target;
        -e $generatedBookMap or
          confess "Generated bookmap does not exist $generatedBookMap";

        if (my $x = Data::Edit::Xml::new($generatedBookMap))                    # Parse the generated bookmap for chapters
         {$x->at_bookmap or confess
           "Expected bookmap, got:".$x->tag." sourceDocType=$sourceDocType from file:\n$b";
          if (my @c = $x->c_chapter)                                            # Chapters
           {for my $c(reverse @c)                                               # Copy chapters
             {$node->putFirstCut($c);
             }
            $node->unwrap;                                                      # Unwrap the referencing topic
           }
         }
        return &$good(q(Expanded representative bookmap));
       }
      else                                                                      # Not a bookmap so just upgrade href
       {$node->href = relFromAbsAgainstAbs($sourceTarget->target, $sourceFile);
        return &$good(q(Unique target));
       }
     }
    undef                                                                       # Failed
   };

  my $checkImageRef = sub                                                       # Check whether an image exists or not
   {my $i = absFromAbsPlusRel($sourceFile, $ref);                               # Local file name
    return 1 if -e $i;                                                          # Local file exists
    return 2 if -e wwwDecode($i);                                               # Local file exists
    undef                                                                       # Local file exists after decoding % signs
   };

  my $fixOnePartialDitaRef = sub                                                # Fix a partial dita reference to an externally cut out topic renamed to the GB Standard where such a reference is just a file name as used in a bookmapref.
   {my ($ref) = @_;                                                             # Partial reference
    return undef unless $xref->fixDitaRefs;                                     # Fixing dita references not requested

    my $topicSource = &$locateUniqueTopicSourceForTargetFile($sourceFile);      # Unique source file corresponding to the target file else undef
    return undef unless $topicSource;                                           # The references can not be resolved without a unique source file.

    my $refIn = absFromAbsPlusRel($topicSource, $ref);                          # The referenced input file that was present in the input being transformed because we assume that (most of) the input Dita refs were valid

    if (my $new = $xref->inputFileToTargetTopics->{$refIn})                     # The target files new files that were cut out of the referenced input file - there might several such
     {if (my ($referencedTarget) = sort keys %$new)                             # Boldly assume that the first possible target in sort order is the required one
       {my $link = relFromAbsAgainstAbs($referencedTarget, $sourceFile);        # Create relative link from book map
        $node->set($attr=>$link);                                               # Reset reference
        return &$good(q(unique target));                                        # Record successful fix
        return 1;                                                               # Success
       }
     }
    undef                                                                       # Failed
   };

  my $fixOneFullDitaRef = sub                                                   # Fix a full dita reference to an externally cut out topic renamed to the GB Standard where such a reference is: file#topicId/label
   {return undef unless $xref->fixDitaRefs;                                     # Fixing dita references not requested

    return &$fixOnePartialDitaRef($ref) unless $ref =~ m(#);                    # Confirm it is a full reference else fix it as a partial reference

    my $topicSource    = &$locateUniqueTopicSourceForTargetFile($sourceFile);   # Unique source file corresponding to the target file  else undef
    return undef unless $topicSource;                                           # The references can not be resolved without a unique source file.
    my ($rf, $rt, $ri) = parseDitaRef($ref, $topicSource);                      # Parse the dita ref

    if (my $new        = $xref->originalSourceFileAndIdToNewFile->{$rf}{$ri})   # The new files cut out of the original topic source file
     {my $targetFile   = relFromAbsAgainstAbs($new, $sourceFile);               # Create relative link from current file
      if (my $topicId  = $xref->topicIds->{$new})                               # Topic id for target file
       {my $href       = qq($targetFile#$topicId/$ri);                          # New href
        $node->set($attr=>$href);                                               # Reset href
        return &$good(q(Unique target for file ref));                           # Record the action
       }
     }

    if ($xref->allowUniquePartialMatches && $attr !~ m(\Aconref)s)              # Partial matching - i.e ignoring the stuff to the right of the # in the reference sometimes produces a unique result.
     {return &$fixOnePartialDitaRef($ref =~ s(#.*\Z) ()rs);                     # Try to resolve reference as a partial re
     }

    undef                                                                       # Failed
   };

  my $fixOneRef = sub                                                           # Fix one unresolved reference either by ameliorating it or by moving it to the xtrf attribute thereby putting it in M3.
   {return unless $xref->fixRefs->{$sourceFile}{$ref};                          # Fix not requested for this reference

    if ($xref->deguidize and $ref =~ m(GUID-)is)                                # On a guid and deguidization allowed so given g1#g2/id convert g1 to a file name by locating the topic with topicId g2.
     {my @refs = split /\s+/, $ref;                                             # There might be multiple references in the href
      my @unresolved;
      my @resolved;

      for my $subRef(@refs)                                                     # Each reference in the reference
       {my ($guid, $rest) = split /#/, $subRef;
        if (my $target = $xref->guidToFile->{$guid})                            # Target file associated with guid
         {my $link = relFromAbsAgainstAbs($target, $sourceFile);                # Relative link
          $link .= q(#).$rest if $rest;                                         # Remainder of reference which does not change as it is not file related
          if (!@resolved)                                                       # First resolution
           {$node->set($attr=>$link);                                           # New href or conref
            &$good(q(Deguidized reference));                                    # Report fix
           }
          push @resolved, $subRef;
         }
        else
         {push @unresolved, $subRef;
         }
       }

      if (@unresolved and $xref->fixBadRefs)                                    # Unresolved - transfer all references to xtrf so some-one else can try
       {$node->renameAttr($attr, q(xtrf));                                      # No target file for guid
        &$bad(q(No file for guid));                                             # Report failure
       }
     }
    elsif ($xref->fixRelocatedRefs and &$fixRelRef)                             # Try to fix as a relocated ref if possible
     {
     }
    elsif ($xref->fixXrefsByTitle  and &$fixXrefByTitle)                        # Try to fix a missing xref by title
     {
     }
    elsif ($xref->fixBadRefs)                                                   # Move href to xtrf as no other fix seems possible given that we have already tried to fix it as a guid and it was reportedly not working as a standard dita reference.
     {$node->renameAttr($attr, q(xtrf));                                        # No target file for guid
      $node->change_ph if $node->at_xref and $xref->changeBadXrefToPh;          # Change bad xref to ph if requested

      &$bad(q(No such target));                                                 # Report failure
     }
    else                                                                        # ffff - Fix not requested so href left alone
     {&$bad(q(Not fixable));                                                    # Unable to fix the reference using any known method
     }
   };

  my $x = Data::Edit::Xml::new($sourceFile);                                    # Parse xml - should parse OK else otherwise how did we find out that this file needed to be fixed

  $x->by(sub                                                                    # Check any references encountered on each node, Ameliorate some specific cases. If the reference is still invalid report the discrepancy.
   {my ($o) = @_;                                                               # Current node
    $node   = $o;                                                               # Make current node available globally
    my $t   = $node->tag;                                                       # Tag
    if ($t  =~  m(\A(appendix|chapter|image|link|topicref|xref)\Z)is)           # Hrefs that need to be fixed
     {if ($ref = $node->attr($attr = q(href)))                                  # The attribute and reference to ameliorate or fix
       {if ($t =~  m(\A(appendix|chapter|topicref)\Z)is)                        # Fix bookmap hrefs
         {&$fixBookMapDitaRef or &$fixOneRef;                                   # Fix references to topics cut into multiple pieces and now represented by a bookmap
         }
        elsif ($t =~ m(\Aimage\Z)is)                                            # Check image references
         {&$checkImageRef or &$fixOneRef;                                       # No additional fixes available yet for images, as so far, the resolution of images is done in thee calling frame work.  Hence we only need to check whether the reference is valid and if it is not then the standard techniques can be applied and the results reported as usual.
         }
        else                                                                    # Fix hrefs without the benefit of the targets/ folder
         {&$fixOneFullDitaRef or &$fixOneRef;                                   # Fix references not in a bookmap
         }
       }
     }
    if ($ref = $node->attr($attr = q(conref)))                                  # Fix a conref
     {&$fixOneFullDitaRef or &$fixOneRef;
     }
    if ($ref = $node->attr($attr = q(conrefend)))                               # Fix a conrefend
     {&$fixOneFullDitaRef or &$fixOneRef;
     }
   });

  if (my $fixedFolder = $xref->fixedFolder)                                     # Write the fixed file to the fixedFolder copying the doctype
   {my $s = readFile($sourceFile);

    if ($s =~ m((<!DOCTYPE[^>]*>))s)
     {my $d = $1;
      my $t = -p $x;
      my $f = swapFolderPrefix($sourceFile, $xref->inputFolder, $fixedFolder);
      owf($f, <<END);
<?xml version="1.0" encoding="UTF-8"?>
$d
$t
END
     }
   }
  else
   {editXml($sourceFile, $sourceFile, $x);                                      # Edit xml processed by Data::Edit::Xml::Lint
   }

  [\@good, \@bad]
 } # fixReferencesInOneFile

sub fixReferences($)                                                            #P Fix just the file containing references using a number of techniques and report those references that cannot be so fixed.
 {my ($xref) = @_;                                                              # Xref results
  my @bad;                                                                      # Hrefs that could not be fixed and so were ameliorated by moving them to @xtrf
  my @good;                                                                     # Hrefs that were fixed by resolving a Guid

  if (1)                                                                        # Map titles to files for the Gearhart Title Method
   {my %titleToFile;                                                            # Titles to file
    for my $file(keys %{$xref->title})                                          # Title for each file
     {if (my $tag = $xref->docType->{$file})                                    # Document type for file
       {if ($tag !~ m(map\Z)s)                                                  # Ignore maps as we want the topic in the map not the map.
         {$titleToFile{nws($xref->title->{$file})}{$file}++;                    # Record title to topic
         }
       }
     }
    $xref->titleToFile = \%titleToFile;                                         # Record titles to files
   }

  if (my $d = $xref->fixDitaRefs)                                               # Map where the input files went and where the target files came from
   {my $bookmaps = $xref->targetFolderContent = readFiles($d);                  # The targets produced from each input file

    my @r;                                                                      # Source to target report
    my %sourceToTarget;                                                         # Maps a source file to its resulting output topics
    my %sourceTopicToTargetBookMap;                                             # Source topic cut into multiple parts produces a bookmap

    for my $source(sort keys %$bookmaps)                                        # Each input file represented in the targets folder
     {my $sourceToTarget = eval $$bookmaps{$source};                            # Mapping for input file
      $@ and confess $@;                                                        # Check eval was successful

      my $bookMap       = genHash(qq(Bookmap), %$sourceToTarget);               # Details of bookmap representing source file after possible cutting out
      my $bookMapSource = $bookMap->source;                                     # Input file name from input folder rather than target folder
      my $bookMapTarget = $bookMap->target;                                     # The target bookmap
      my $sourceDocType = $bookMap->{sourceDocType} // '';                      # The docType of the source input file if known
      my $targetType    = $bookMap->targetType;                                 # The target type, initially just a bookmap, now extended to include topics and images

      push @r, [$targetType, $sourceDocType, $bookMapSource, $bookMapTarget];   # Report source to targets
      $sourceTopicToTargetBookMap{$bookMapSource} = $bookMap;                   # Source to target details of topic

      if    ($sourceDocType =~ m(map\Z)s)                                       # If the input file was a map then its target is a map
       {$sourceToTarget{$bookMapSource} = {$bookMapTarget=>1};
       }
      elsif ($targetType =~ m(\Atopic\Z)is)                                     # If the input file produced a single dita topic then the target is that topic
       {$sourceToTarget{$bookMapSource} = {$bookMapTarget=>1};
       }
      elsif ($targetType =~ m(\Abookmap\Z)i)                                    # If the input file was a topic that was cut into multiple topics then the target is a bookmap
       {if (my $refs = $xref->topicsReferencedFromBookMaps->{$bookMapTarget})   # The references from the bookmap the source file became
         {$sourceToTarget{$bookMapSource} = $refs;                              # The output files files this source input file was split into
         }
        else
         {#lll "No references from bookmap $bookMapTarget";
         }
       }
     }

    my %targetToSource;                                                         # The source files for each output topic - the reverse of sourceTotarget - output topics that have been flattened will have multiple sources
    for my $source(sort keys %sourceToTarget)                                   # Each source input file
     {for my $target(sort keys %{$sourceToTarget{$source}})                     # Each of the target topics that were derived from this source file
       {$targetToSource{$target}{$source}++;                                    # Maps an output topic back to the input files that gave rise to it
       }
     }

    my %targetToSourceDuplicated;                                               # The target files for which there is more than one source file
    for my $target(sort keys %targetToSource)                                   # Each of the target topics that were derived from this source file
     {my %s = %{$targetToSource{$target}};                                      # Each source input file
      if (keys %s > 1)                                                          # Mapping is not injective
       {push @{$targetToSourceDuplicated{$target}}, sort keys %s;
       }
     }

    my %si;                                                                     # Source ids: {original source input file}{id} = target file
    for my $targetFile(keys %{$xref->ids})                                      # Each target file with an id in it
     {if (my $sourceFiles = $targetToSource{$targetFile})                       # Originating source files for this target file
       {for my $sourceFile(keys %$sourceFiles)                                  # Each originating source files for this target file
         {for my $id(keys %{$xref->ids->{$targetFile}})                         # Each id in the target file
           {$si{$sourceFile}{$id} = $targetFile;                                # The new file containing the id defined in the source file
           }
         }
       }
     }

    $xref->inputFileToTargetTopics    = \%sourceToTarget;                       # The targets for each input file
    $xref->targetTopicToInputFiles    = \%targetToSource;                       # The source file from which each target was obtained
    $xref->sourceTopicToTargetBookMap = \%sourceTopicToTargetBookMap;           # The bookmap representing a cut up topic
    $xref->topicFlattening            = \%targetToSourceDuplicated;             # Topics that arose from flattening several source files
    $xref->originalSourceFileAndIdToNewFile = \%si;                             # Record mapping from original source file and id to the new file containing the id

    formatTable(\@r, <<END,
Type    The type of reference
DocType Document type of the source file
Source  Source file
Target  Cut out file
END
    summarize=>1,
    title=>qq(The target topics cut out of the source documents),
    head=><<END,
Xref noted NNNN cut out topics on DDDD
END
    file=>(fpe($xref->reports, qw(lists source_to_targets txt))));


    if (1)                                                                      # Report topic flattening
     {my @r;
      my $s = 0; my $t = 0;
      for my $target(sort keys %targetToSourceDuplicated)                       # Each of the target topics that were derived from this source file
       {my @s = @{$targetToSourceDuplicated{$target}};                          # Each source input file
        push @r, [scalar(@s), $target];
        push @r, [q(), q(  ).$_] for @s;
        push @r, [q()];
        ++$t; $s += @s;
       }
      $xref->topicsFlattened = $s;                                              # Record the number of topics flattened
      my $F = $xref->topicFlatteningFactor = $t ? $s / $t : 0;                  # Topic flattening factor - higher is better
      my $f = sprintf("%7.4f", $F);
      my $n = @{$xref->inputFiles};                                             # Number of topics
      my $p = sprintf("%7.4f", $n ? 100*$t/$n : 0);                             # Percentage topics flattened versus total number of topics

      formatTable(\@r, <<END,
Count   Number of sources that created this target
Target  The target file flattened out from multiple source files
END
        summarize => 1,
        title     => qq(Topic files flattened from multiple sources),
        head      => <<END,
Xref noted that $s source topics were reduced to $t target topics on DDDD

This represents a flattening factor of:  $f  (higher is better) in the topics that got flattened

Total number of topics    : $n
Number of topics flattened: $t
Percent topics   flattened: $p
END
        file      => fpe($xref->reports, qw(lists topic_flattening txt)));
     }
   }

  if (my @files = sort keys %{$xref->fixRefs})                                  # Fix files if requested
   {my @square = squareArray(@files);                                           # Divide the task

    my $ps = newProcessStarter($xref->maximumNumberOfProcesses);                # Process starter
       $ps->processingTitle   = q(Xref);
       $ps->totalToBeStarted  = scalar @square;
       $ps->processingLogFile = fpe($xref->reports, qw(log xref fix txt));

    for my $row(@square)                                                        # Each row of input files file
     {$ps->start(sub
       {my @r;                                                                  # Results
        for my $col(@$row)                                                      # Each column in the row
         {push @r, $xref->fixReferencesInOneFile($col);                         # Analyze each input file in parallel
         }
        [@r]                                                                    # Return results as a reference
       });
     }

    for my $r(deSquareArray($ps->finish))                                       # Consolidate results
     {my ($good, $bad) = @$r;
      push @bad,  @$bad;
      push @good, @$good;
     }
   }

  my $fbr = $xref->fixBadRefs;

  formatTable($xref->fixedRefsFailed = \@bad, <<END,                            # Report invalid references
Reason         The reason the reference was not fixed
Tag            The tag of the node in which the reference failure occurs
Attr           The attribute of the node in which the reference failure occurs
Reference      The reference not being fixed
File           The file in which the reference appears
Source_Files   One or more source files that from which this file was derived
END
    summarize => 1,
    title     => q(Invalid references),
    head      => $fbr ? <<END : <<END2,
Xref moved NNNN invalid references to M3 on DDDD as fixBadRefs=>$fbr was specified
END
Xref moved NNNN found invalid references on DDDD, fixBadRefs=> was not specified
END2
    file=>(fpe($xref->reports, qw(bad references txt))));

#  formatTable($xref->fixedRefsNoAction = \@none, <<END,                        # Report hrefs on which no action was taken
#Reason         The reason no action was taken on the reference despite action being requested
#Href           The reference on which no action was taken
#Source_File    The source file in which the reference appears
#END
#    summarize=>1,
#    title=>qq(No action was taken on these failing references despite a request that the href be fixed),
#    head=><<END,
#Xref took no action on NNNN references despite a request that the href be fixed on DDDD
#
#See below for the readons why no action was taken on the specified references.
#END
#    file=>(fpe($xref->reports, qw(bad no_action_on_invalid_references txt))));

  formatTable($xref->fixedRefs = \@good, <<END,                                 # Report hrefs which were interpreted as guids and successfully resolved
Href           The reference which might contain more than one reference specification
Ref            The actual reference from the reference that is being resolved
Target_File    The located target file
Source_File    The source file in which the reference appears
END
    summarize=>1,
    title=>qq(These failing references were reinterpreted as guids and successfully resolved),
    head=><<END,
Xref successfully resolved NNNN hrefs as guids on DDDD
END
    file=>(fpe($xref->reports, qw(good fixed_guid_references txt))));


#  return {fixedRefsFailed => $xref->fixedRefsFailed,                            # From multiverse to universe
#          fixedRefs       => $xref->fixedRefs,
#         }
#  formatTable($xref->relocatedReferencesFixed = \@fixRelRefsFixed, <<END,       # Relocated references fixed
#New_Reference  The newly created reference
#Old_Reference  The original reference
#Source_File    The source file containing the reference
#END
#    summarize=>1,
#    title=>qq(These failing references were reinterpreted as relocated references and successfully resolved),
#    head=><<END,
#Xref successfully resolved NNNN relocated hrefs on DDDD
#END
#    file=>(fpe($xref->reports, qw(good relocated_references txt))));
#
#  formatTable($xref->relocatedReferencesFailed = \@fixRelRefsFailed, <<END,     # Relocated references that were not fixed by relocation
#Reason      The reason the reference could not be fixed by relocation
#Targets     A list of the possible target locations for this reference if there are more than one
#Reference   The reference that might be fixable by relocation
#Source_File The source file containing the reference
#END
#    summarize=>1,
#    title=>qq(These failing references could not be fixed by relocation),
#    head=><<END,
#Xref failed to relocate NNNN failing conrefs/hrefs on DDDD
#END
#    file=>(fpe($xref->reports, qw(bad relocated_references txt))));
#
#  if (my $fxt = $xref->fixXrefsByTitle)                                         # Xrefs fixed by title
#   {formatTable($xref->xrefsFixedByTitle = \@fixByTitle, <<END,
#Content     The text content of the link
#Relative    Relative path of file containing target of link
#Target_File Target file
#Source_File The source file containing the reference
#END
#      summarize=>1,
#      title=>qq(Fixed by topic title),
#      head=><<END,
#Xref fixed NNNN failing xrefs by locating the unique topic with the same title
#as the text of xref on DDDD.
#
#This action was enabled by setting: fixXrefsByTitle=>$fxt
#END
#      file=>(my $f = fpe($xref->reports, qw(good xrefs_fixed_by_titles txt))));
#   }
#
#  if (my $ftr = $xref->fixDitaRefs)                                             # Renamed bookmaprefs
#   {formatTable($xref->fixedDitaRefs = \@fixedDitaRefs, <<END,
#Old     The existing topic ref
#New     The new topic ref
#File    The file in which the old topic ref was updated to the new topic ref
#END
#      summarize=>1,
#      title=>qq(Fixed topics refs),
#      head=><<END,
#Xref fixed NNNN renamed bookmaprefs on DDDD.
#
#This action was enabled by setting: fixDitaRefs=>$ftr
#END
#      file=>(my $f = fpe($xref->reports, qw(good bookmap_references_updated txt))));
#   }
 } # fixReferences

sub fixOneFileGB($$)                                                            #P Fix one file to the Gearhart-Brenan standard
 {my ($xref, $file) = @_;                                                       # Xref results, file to fix
  my @r;                                                                        # Hrefs changed

  my $x = Data::Edit::Xml::new($file);                                          # Parse xml - should parse OK else otherwise how did we find out that this file needed to be fixed

  $x->by(sub                                                                    # Each node
   {my ($o) = @_;
    if (my $h = $o->href)                                                       # Href encountered
     {my ($localFile, $rest) = split /#/, $h, 2;                                # Split reference
      my $fullFile = absFromAbsPlusRel($file, $localFile);                      # Full name of referenced file
      if (my $target = $xref->flattenFiles->{$fullFile})                        # Target file name
       {$o->href = $target.($rest ? qq(#$rest) : qq());                         # Reassemble href
       }
      else
       {push @r, [$h, $file];
       }
     }
   });


# editXml($file, fpf($xref->flattenFolder, $xref->flattenFiles->{$file}), $x);  # Edit xml
  my $target = fpf($xref->flattenFolder, $xref->flattenFiles->{$file});         # Previously assigned GB name.  We cannot use the very latest name because other files have to be told about it and in changing them to reflect the latest name we would change their name as well.  So close has to be good enough.
  editXml($file, $target, $x);                                                  # Edit xml

  \@r                                                                           # Return report of items fixed
 }

sub fixFilesGB($)                                                               #P Rename files to the L<GBStandard>
 {my ($xref) = @_;                                                              # Xref results
  my @files  = grep {!$xref->parseFailed->{$_}} sort @{$xref->inputFiles};      # Fix files that parsed if requested
  my @square = squareArray(@files);                                             # Divide the task

# Done faster in analyzeOneFile at 2019.06.18 20:06:24
#  for my $file(@files)                                                         # New target file name for each input file
#   {my $target = sub
#     {my $t = $xref->title->{$file} // q();                                    # Title
#         $t =~ s([^a-zA-Z0-9]+) (_)gs;                                         # Title reduced to basics
#      my $m = $xref->md5Sum->{$file} // q();
#      my $s = substr($xref->baseTag->{$file}//q(u), 0, 1);                     # First letter of tag
#      join q(_), $s, firstNChars($t, maximumFileNameChars), $m;                # The Gearhart-Brenan file naming standard
#     }->();
#
#    $xref->flattenFiles->{$file} = fpe($target, fe $file);                     # Record correspondence between existing file and standardized file name
#   }

  my $ps = newProcessStarter($xref->maximumNumberOfProcesses);                  # Process starter
     $ps->processingTitle   = q(Xref Gearhart);
     $ps->totalToBeStarted  = scalar @square;
     $ps->processingLogFile = fpe($xref->reports, qw(log flatten txt));

  my @r;                                                                        # Fixes made
  for my $row(@square)                                                          # Each row of input files
   {$ps->start(sub
     {my @r;                                                                    # Results
      for my $col(@$row)                                                        # Each column in the row
       {push @r, $xref->fixOneFileGB($col);                                     # Analyze one input file
       }
      [@r]                                                                      # Return results as a reference
     });
   }

  for my $r(deSquareArray($ps->finish))                                         # Consolidate results
   {push @r, @$r;
   }

  formatTable($xref->fixedRefsGB = \@r, <<END,                                  # Report results
Href           The href being fixed
Source         The source file containing the href
END
    summarize=>1,
    title=>qq(Hrefs that can not be renamed to the Gearhart-Brenan file naming standard),
    head=><<END,
Xref failed to fix NNNN hrefs to the Gearhart-Brenan file naming standard
END
    file=>(my $f = fpe($xref->reports, qw(bad fixedRefsGB txt))));

   {fixedRefsGB => $xref->fixedRefsGB,                                          # From multiverse to universe
   }
 } # fixFilesGB

sub analyzeInputFiles($)                                                        #P Analyze the input files
 {my ($xref) = @_;                                                              # Cross referencer
  my @in = @{$xref->inputFiles};                                                # Input files

  my @square = squareArray(@in);                                                # Divide the task
  my $square = @square;

  my $p = newProcessStarter($xref->maximumNumberOfProcesses);                   # Process starter
     $p->processingTitle   = q(Xref Analyze);
     $p->totalToBeStarted  = $square;
     $p->processingLogFile = fpe($xref->reports, qw(log xref analyze txt));

  for my $row(@square)                                                          # Each row of input files file
   {$p->start(sub
     {my @r;                                                                    # Results
      for my $col(@$row)                                                        # Each column in the row
       {push @r, analyzeOneFile($xref, $col);                                   # Analyze one input file
       }
      [@r]                                                                      # Return results as a reference
     });
   }

  my @x = deSquareArray($p->finish);                                            # Load results

  my @fields = (                                                                # Fields to be merged
q(attributeCount),
q(attributeNamesAndValuesCount),
q(author),
q(badXml1),
q(badXml2),
q(baseTag),
q(conRefs),
q(docType),
q(fixRefs),
q(flattenFiles),
q(guidHrefs),
q(hrefUrlEncoding),
q(ids),
q(images),
q(imagesReferencedFromTopics),
q(improvements),
q(ltgt),
q(maxZoomOut),
q(md5Sum),
q(noHref),
q(olBody),
q(parseFailed),
q(references),
q(tagCount),
q(tags),
q(texts),
q(title),
q(topicIds),
q(bookMapRefs),
q(targetTopicToInputFiles),
q(validationErrors),
q(vocabulary),
q(xrefBadFormat),
q(xrefBadScope),
q(xRefs),
 );

  my $fields = @fields;
  my $q = newProcessStarter($xref->maximumNumberOfProcesses);                   # Process starter
     $q->processingTitle   = q(Xref Analyze Merge);
     $q->totalToBeStarted  = $fields;
     $q->processingLogFile = fpe($xref->reports, qw(log xref analyzeMerge txt));

  for my $field(@fields)                                                        # Merge hashes by file names which are unique - ffff
   {$q->start(sub
     {my $startTime = time;
      my $target = $xref->{$field} //= {};                                      # Field to be merged
      for my $x(@x)                                                             # mmmm Merge results from each file analyzed
       {if (my $xf = $x->{$field})
         {for my $f(keys %$xf)                                                  # Each file analyzed
           {$target->{$f} = $xf->{$f}                                           # Merge
           }
         }
       }
      [$field, $xref, time - $startTime]                                        # Return results as a reference
     });
   }

  my @merge = $q->finish;                                                       # Load results
  my @times;                                                                    # Time for each merge
  for my $m(@merge)
   {my ($f, $x, $t) = @$m;
    $xref->{$f} = $x->{$f};
    push @times, [$f, $t];
   }

  formatTable([sort {$$b[1] <=> $$a[1]} @times], <<END,
Field Xref field merge
Time  Time in seconds to merge this field
END
    title=>qq(Field merging elapsed times in descending order),
    head =>qq(Xref field merging took the following times on DDDD),
    file =>fpe($xref->reports, q(timing), qw(merges txt)));

  for my $field(                                                                # Merge arrays
    qw(badTables))
   {for my $x(@x)                                                               # mmmm Merge results from each file analyzed
     {next unless my $xf = $x->{$field};
      push @{$xref->{$field}}, @$xf;
     }
   }
 } # analyzeInputFiles

sub reportDuplicateIds($)                                                       #P Report duplicate ids
 {my ($xref) = @_;                                                              # Cross referencer

  my @dups;                                                                     # Duplicate ids definitions
  for my $file(sort keys %{$xref->ids})                                         # Each input file
   {for my $id(sort keys %{$xref->ids->{$file}})                                # Each id in the file
     {my $count = $xref->ids->{$file}{$id};                                     # Number of definitions of this id in the file
      if ($count > 1)                                                           # Duplicate definition
       {push @dups, [$id, $count, $file];                                       # Save details of duplicate definition
       }
     }
   }

  my $dups = $xref->duplicateIds = {map {$$_[2]=>$_} @dups};                    # All duplicates

  formatTable(\@dups, [qw(Id Count File)],
    title=>qq(Duplicate id definitions within files),
    head=><<END,
Xref found NNNN duplicate id definitions within files on DDDD

These ids are duplicated within a file, possibly because they were copied from
another part of the same file.  This report does not show ids that are the same
in different files as this is not a problem using Dita's three part addressing
scheme which requires only that the topic id be unique across all files.

Duplicate topic ids are reported in ../bad/topicIds.txt.

END
    file=>(my $f = fpe($xref->reports, qw(bad duplicateIds txt))));

   {duplicateIds => $dups,
   }                                                                            # From multiverse to universe
 } # reportDuplicateIds

sub reportDuplicateTopicIds($)                                                  #P Report duplicate topic ids
 {my ($xref) = @_;                                                              # Cross referencer

  my %dups;                                                                     # Duplicate topic ids definitions
  my @dups;                                                                     # Duplicate topic ids definitions report
  my @miss;                                                                     # Missing topic id definitions report
  for my $file(sort keys %{$xref->topicIds})                                    # Each input file
   {if (my $i = $xref->topicIds->{$file})                                       # Topic Id
     {if (my $d = $dups{$i})                                                    # Duplicate topic id
       {push @dups, [$i, $file, $d];                                            # Save details of duplicate definition
       }
      else
       {$dups{$i} = $file;                                                      # Save topic id
       }
     }
    else
     {push @miss, [$file];                                                      # Missing topic id
     }
   }

  my $dups = $xref->duplicateTopicIds = {map {$$_[0]=>$_} @dups};               # All duplicates
  my $miss = $xref->missingTopicIds   = {map {$$_[0]=>$_} @miss};               # All missing

  formatTable(\@dups, [qw(TopicId File1 File2)],
    title=>qq(Duplicate topic id definitions),
    head=><<END,
Xref found NNNN duplicate topic id definitions on DDDD

File1, File2 are two files that both define TopicId

END
    file=>(fpe($xref->reports, qw(bad duplicateTopicIds txt))));

  formatTable(\@miss, [qw(File)],
    title=>qq(Topics without ids),
    head=><<END,
Xref found NNNN topics that have no topic id on DDDD

END
    file=>(fpe($xref->reports, qw(bad topicIdDefinitionsMissing txt))));

   {duplicateTopicIds => $dups,
    missingTopicIds   => $miss,
   }
 } # reportDuplicateTopicIds

sub reportNoHrefs($)                                                            #P Report locations where an href was expected but not found
 {my ($xref) = @_;                                                              # Cross referencer
  my @t;
  for my $file(sort keys %{$xref->noHref})                                      # Each input file
   {push @t,             @{$xref->noHref->{$file}};                             # Missing href details
   }

  formatTable(\@t, <<END,
Tag        A tag that should have an xref.
Location   The location of the tag that should have an xref.
File       The source file containing the tag
END
    title=>qq(Missing hrefs),
    head=><<END,
Xref found NNNN tags that should have href attributes but did not on DDDD
END
    file=>(fpe($xref->reports, qw(bad missing_href_attributes txt))));
  {}                                                                            # From multiverse to universe
 } # reportNoHrefs

sub checkReferences($)                                                          #P Check each reference, report bad references and mark them for fixing.
 {my ($xref) = @_;                                                              # Cross referencer

  my @bad;                                                                      # Bad references
  my %references = %{$xref->references};                                        # References
  for   my $file(sort keys %references)                                         # Each input file which will be absolute
   {for my $ref (sort keys %{$references{$file}})                               # Each href in the file which will be relative
     {if (my $r = &oneBadRef($xref, $file, $ref))                               # Check reference
       {push @bad, $r;
        $xref->fixRefs->{$file}{$ref}++;                                        # Request fix attempt for this reference
        $xref->badReferencesCount++;                                            # Number of bad references encountered
       }
     }
   }

  formatTable(\@bad, <<END,                                                     # Report the failing references
Reason          The reason why the reference failed to resolve
Reference       The href in the source file
Ref_File        The file containing the referenced topic relative to the referencing file
Ref_TopicId     The topic id of the referenced topic
Ref_Id          The id of the statement in the referenced topic
Source_TopicId  The topic id of the referencing file
Target_TopicId  The topic id of the referenced file
Source_File     The referencing source file
Target_File     The referenced target file
END
    title => qq(Bad references),
    head  => qq(Xref found NNNN Bad references on DDDD),
    csv   => 1, wide =>1, summarize=>1,
    file  => my $f = fpe($xref->reports, q(bad), q(references), q(txt)));
  {}                                                                            # From multiverse to universe
 } # checkReferences

#sub reportRefs($$)                                                              #P Report bad references found in xrefs or conrefs as they have the same structure
# {my ($xref, $type) = @_;                                                       # Cross referencer, type of reference to be processed
#
#  my @bad; my @good;                                                            # Bad xrefs.
#  for   my $file(sort keys %{$xref->{${type}.q(Refs)}})                         # Each input file which will be absolute
#   {my $sourceTopicId = $xref->topicIds->{$file};
#    for my $href(sort keys %{$xref->{${type}.q(Refs)}{$file}})                  # Each href in the file which will be relative
#     {my @text;
#
#      if (               ref($xref->{${type}.q(Refs)}{$file}{$href}))           # xRef: Text associated with reference deemed helpful by Bill
#       {@text =  sort keys %{$xref->{${type}.q(Refs)}{$file}{$href}};
#        s(\s+) ( )gs for @text;                                                 # Normalize white space
#       }
#
#      if ($href =~ m(#))                                                        # Full Dita href
#       {my ($target, $topic, $id) = parseDitaRef($href, $file, $sourceTopicId); # Parse full Dita href
#
#        my $good = sub                                                          # Save a good reference
#         {push @good, [$href, $target, $file];
#         };
#
#        my $bad = sub                                                           # Save a bad reference
#         {my ($reason, $t) = @_;
#          push @bad,
#           [$reason, $href, $topic, $id, $t, $sourceTopicId, $file, $target, @text];
#         };
#
#        if ($target and !(-e $target or -e wwwDecode($target)))                  # Check target file
#         {&$bad(q(No such file), q());
#         }
#        elsif (my $t = $xref->topicIds->{$target})                              # Check topic id
#         {if ($t eq $topic)
#           {if (my $i = $xref->ids->{$target}{$id})
#             {if ($i == 1)
#               {&$good;
#               }
#              else
#               {&$bad(q(Duplicate id in topic), $t);
#               }
#             }
#            elsif ($id)
#             {&$bad(q(No such id in topic), $t);
#             }
#            else
#             {&$good;
#             }
#           }
#          else
#           {&$bad(q(Topic id does not match target topic), $t);
#           }
#         }
#        elsif ($topic =~ m(\S)s)                                                # The href contains a topic id but there is not topic with that id
#         {&$bad(q(No topic id on topic in target file), $t);
#         }
#        else
#         {&$good;
#         }
#       }
#      else                                                                      # No # in href
#       {my $target = absFromAbsPlusRel($file, $href);
#        if (!-e $target and !-e wwwDecode($target))                             # Actual file name or www encoded file name
#         {push @bad, my $p = [qq(No such file), $href,
#            q(), q(), q(), $sourceTopicId, $file, $target, @text];
#         }
#        else
#         {push @good, my $p = [$href, $target, $file];
#         }
#       }
#     }
#   }
#
#  for my $bad(@bad)                                                             # List of files to fix
#   {my $href = $$bad[1];
#    my $file = $$bad[6];
#    $xref->fixRefs->{$file}{$href}++;
#   }
#
#  my $Type = ucfirst $type;
#  $xref->{q(bad).$Type.q(Refs)}  = {map {$$_[6]=>$_} @bad};                     # Bad references
#  $xref->{q(good).$Type.q(Refs)} = {map {$$_[1]=>$_} @good};                    # Good references
#
#  for my $good(@good)
#   {my (undef, $t, $s) = @$good;
#    my $T = $xref->docType->{$t} || q();
#    my $S = $xref->docType->{$s} || q();
#    $$good[1] = swapFilePrefix($$good[2], $xref->inputFolder);
#    pop @$good;
#
#    if ($T eq $S)
#     {unshift @$good, $T, q();
#     }
#    else
#     {unshift @$good, $T, $S;
#     }
#   }
#
#  $xref->{q(bad).$Type.q(RefsList)}  = \@bad;                                   # Bad references list
#  $xref->{q(good).$Type.q(RefsList)} = \@good;                                  # Good references list
#
#  my $in = $xref->inputFolder//'';
#  formatTable(\@bad, <<END,
#Reason          The reason why the conref failed to resolve
#Href            The href in the source file
#Href_Topic_Id   The id of the topic referenced by the href in the source file
#Target_Topic_Id The actual id of the topic in the target file
#HRef_Id         The id of the statement in the body of the topic referenced by the href in the source file
#Source_TopicId  The topic id at the top of the source file containing the bad reference
#Source_File     The source file containing the reference
#Target_File     The target file pointed to by the reference
#Example_Text    Any text associated with the link such as the navtitle of a bad bookMapRef or the CDATA text of an xref.
#END
#    title    =>qq(Bad ${type}Refs),
#    head     =>qq(Xref found NNNN Bad ${type}Refs on DDDD),
#    summarize=>1, csv=>1,
#    wide     =>1,
#    file     =>(fpe($xref->reports, q(bad), qq(${Type}Refs), q(txt))));
#
#  formatTable(\@good, <<END,
#Target          Target topic type if different from source topic type
#Source          Source topic type if different from target topic type
#Href            The href in the source file
#Source_File     The source file containing the xref
#END
##Target_File     The target file
#    title    =>qq(Good ${type}Refs),
#    head     =>qq(Xref found NNNN Good $type refs on DDDD),
#    file     =>(fpe($xref->reports, q(good), qq(${Type}Refs), q(txt))));
# } # reportRefs


# Report on hrefs that have been guidized and mark them for fixing.  The reasons
# we do not fix them here are:
#
#  - we do not have access to a parse tree in which to fix them
#  - the caller might not want them fixed
#  - the caller might want to choose the fixing strategy.
#
# Thus this report merely identifies hrefs with guids in them in line with xrefs
# initial goal of reporting the state of play, while the question of actually
# improving the situation is deferred until later.

sub reportGuidHrefs($)                                                          #P Report on guid hrefs
 {my ($xref) = @_;                                                              # Cross referencer

  my %guidToFile;                                                               # Map guids to files
  for   my $file(sort keys %{$xref->topicIds})                                  # Each input file containing a topic id
   {my $id = $xref->topicIds->{$file};                                          # Each href in the file which will start with guid
    next unless defined $id;
    next unless $id =~ m(\bguid-)is;                                            # Check guid appears somewhere in href
    $guidToFile{$id} = $file;                                                   # We report duplicates in reportDuplicateTopicIds
   }

  my @bad; my @good;                                                            # Good and bad guid hrefs
  for   my $file(sort keys %{$xref->guidHrefs})                                 # Each input file which will be absolute
   {my $sourceTopicId = $xref->topicIds->{$file};
    for my $href(sort keys %{$xref->guidHrefs->{$file}})                        # Each href in the file which will start with guid
     {my ($tag, $lineLocation) = @{$xref->guidHrefs->{$file}{$href}};           # Tag of node and location in source file of node doing the referencing

      $xref->fixRefs->{$file}{$href}++ unless $xref->fixRefs->{$file}{$href};   # Avoid double counting - all guid hrefs will be fixed if we are fixing hrefs as both good and bad will fail.

      if ($href =~ m(#))                                                        # Href with #
       {my ($guid, $topic, $id) = split m(#|\/), $href, 3;                      # Guid, topic, remainder
        my $targetFile   = $guidToFile{$guid};                                  # Locate file defining guid

        if (!defined $targetFile)                                               # No definition of this guid
         {push @bad,                                                            # Report missing guid
           ["No such guid defined", $tag, $href, $lineLocation, q(),
            $sourceTopicId, $targetFile, $file];
          next;
         }

        my $targetFileId = $xref->topicIds->{$targetFile} // '';                # Actual id in target file

        my $bad = sub
         {push @bad,
           [@_, $tag, $href, $lineLocation, $targetFileId, $sourceTopicId,
            $targetFile, $file];
         };

        my $good = sub
         {push @good,
           [$href, $tag, $lineLocation, $targetFile, $file];
         };

        if (!-e $targetFile)                                                    # Existence of file
         {$bad->(q(No such file));
         }
        elsif (defined $topic)                                                  # Topic defined so it must be an xref
         {if ($topic ne $guid)
           {$bad->(q(Guid does not match topic id));
           }
          elsif (defined $id)
           {if (my $i = $xref->ids->{$targetFile}{$id})                         # Check id exists in target file
             {if ($i == 1)
               {&$good;
               }
              else
               {$bad->(q(Duplicate id in topic));
               }
             }
            $bad->(q(No such id in topic));
           }
          else
           {&$good;
           }
         }
        else
         {&$good;
         }
       }
      elsif ($tag eq q(image))                                                  # Image reference
       {my $guid = $href =~ s(guid|-) ()igsr;
        if (my $image = $xref->inputFolderImages->{$guid})
         {push @good, [$tag, $href, $lineLocation, $image, $file];
          #$xref->goodImageRefs->{$image}++;                                     # Found image
         }
        else
         {push @bad, [qq(No such image guid defined), $tag, $href,
           $lineLocation, q(), $sourceTopicId, q(), $file];
         }
       }
      else                                                                      # No # in href and not an image so it must be a bookmap element
       {my $targetFile = $guidToFile{$href};
        if (!defined $targetFile)                                               # No such guid
         {push @bad, [qq(No such guid defined), $tag, $href,
           $lineLocation, q(), $sourceTopicId, q(), $file];
         }
        elsif (!-e $targetFile)                                                 # Actual file name
         {push @bad, my $p = [qq(No such file), $tag, $href,
           $lineLocation, q(), $sourceTopicId, $targetFile, $file];
         }
        elsif ($xref->fixBadRefs)                                               # The file exists and we want to fix such references
         {$xref->fixRefs->{$file}{$href}++;
         }
        else
         {push @good, [$tag, $href, $lineLocation, $targetFile, $file];
          #$xref->goodBookMapRefs->{$targetFile}++;                             # Mark reference as found
         }
       }
     }
   }

#  for my $bad(@bad)                                                             # List of files to fix
#   {my $href = $$bad[2];
#    my $file = $$bad[-1];
##   $xref->fixRefs->{$file}{$href}++ unless $xref->fixRefs->{$file}{$href};     # Avoid double counting
#   }
#
   $xref->badGuidHrefs  = {map {$$_[7]=>$_} @bad};                              # Bad references
##  $xref->{goodGuidHrefs} = {map {$$_[4]=>$_} @good};                            # Good references

  my $in = $xref->inputFolder//'';
  formatTable(\@bad, <<END,
Reason          The reason why the href failed to resolve
Tag             The tag of the node doing the referencing
Href            The href of the node doing the referencing
Line_Location   The line location where the href occurred in the source file
Target_Topic_Id The actual id of the topic in the target file
Source_Topic_Id The topic id in the source file
Target_File     The target file
Source_file     The source file containing the reference
END
    title    =>qq(Unresolved GUID hrefs),
    head     =>qq(Xref found NNNN unresolved GUID hrefs on DDDD),
    summarize=>1,
    wide     =>1,
    file     =>(fpe($xref->reports, q(bad), qw(guidHrefs txt))));

  formatTable(\@good, <<END,
Tag             The tag containing the href
Href            The href of the node doing the referencing
Line_Location   The line location where the href occurred in the source file
Source_File     The source file containing the reference
Target_File     The target file
END
    title    =>qq(Resolved GUID hrefs),
    head     =>qq(Xref found NNNN Resolved GUID hrefs on DDDD),
    file     =>(fpe($xref->reports, q(good), qw(guidHrefs txt))));

   {badGuidHrefs => $xref->badGuidHrefs,                                        # From multiverse to universe
    ##fixRefs      => $xref->fixRefs,
   }
 } # reportGuidHrefs

#sub reportXrefs($)                                                              #P Report bad xrefs
# {my ($xref) = @_;                                                              # Cross referencer
#  reportRefs($xref, q(x));
# }

# Relies on badBookMapReferences which is incorrectly sset
#sub reportBookMapRefs($)                                                        #P Report topic refs
# {my ($xref) = @_;                                                              # Cross referencer
#
#  my %topicIdsToFile;                                                           # All the topic ids encountered - we have already reported the duplicates so now we can assume that there are no duplicates
#  for my $file(sort keys %{$xref->topicIds})                                    # Each input file
#   {if (my $topicId = $xref->topicIds->{$file})                                 # Topic Id for file - we report missing topicIds in: reportDuplicateTopicIds
#     {$topicIdsToFile{$topicId} = $file;                                        # Topic Id to file
#     }
#   }
#
#  my @bad; my @good;                                                            # Bad xrefs
#  for   my $file(sort keys %{$xref->bookMapRefs})                               # Each input file
#   {my $sourceTopicId = $xref->topicIds->{$file};
#    for my $href(sort keys %{$xref->bookMapRefs->{$file}})                      # Each topic ref in the file
#     {my @text;
#
#if ($href =~ m(#)s) # We will have to do something about this if we encounter href on topic/link ref that has # in the href.
# {lll "Data::Edit::Xml::Xref # in href in topic reference: $href";
# }
#
#      if (               ref($xref->bookMapRefs->{$file}{$href}))               # Text associated with reference
#       {@text =  sort keys %{$xref->bookMapRefs->{$file}{$href}};
#        s(\s+) ( )gs for @text;                                                 # Normalize white space
#       }
#      my $f = absFromAbsPlusRel($file, $href);                                  # Target file absolute
##say STDERR "AAAA ", dump([$file, $href, '=', $f]);
#      if ($f)
#       {if (!-e $f and !-e wwwDecode($f))                                       # Check target file
#         {push @bad, my $p = [qq(No such file), $f, qq("$href"),
#                             $sourceTopicId, $file, @text];
#          $xref->fixRefs->{$file}{$href}++;
#         }
#        else
#         {push @good, my $p = [$f, $href, $file];
#         }
#       }
#     }
#   }
#
#  $xref->badBookMapRefs  = {map {$$_[1]=>$_} @bad};                             # Bad topic references
#  $xref->goodBookMapRefs = {map {$$_[0]=>$_} @good};                            # Good topic references
#
#  my $in = $xref->inputFolder//'';
#  formatTable(\@bad, <<END,
#Reason          Reason the topic reference failed
#FullFileName    Name of the targeted file
#Href            Href text
#Source_Topic_Id The topic id of the file containing the bad xref
#Absolute_Path   The source file containing the reference as an absolute file path
#Example_Text    Any text bracketed by the topic ref
#END
#    title    =>qq(Bad bookmaprefs),
#    head     =>qq(Xref found NNNN Bad bookmaprefs on DDDD),
#    summarize=>1,
#    wide     =>1,
#    file     =>(fpe($xref->reports, qw(bad bookMapRefs txt))));
#
#  formatTable(\@good, <<END,
#FullFileName  The target file name
#Href          The href text in the source file
#Source        The source file
#END
#    title=>qq(Good bookmaprefs),
#    head=>qq(Xref found NNNN Good bookmaprefs on DDDD),
#    file=>(fpe($xref->reports, qw(good bookMapRefs txt))));
# }

#sub reportConrefs($)                                                            #P Report bad conrefs refs
# {my ($xref) = @_;                                                              # Cross referencer
#  reportRefs($xref, q(con));
# }
=pod
say STDERR  "DDDD ", dump([@bad]);

  formatTable($xref->fixedRefsFailed = \@bad, <<END,                            # Report invalid references
Reason         The reason the reference was not fixed
Tag            The tag of the node in which the reference failure occurs
Attr           The attribute of the node in which the reference failure occurs
Href           The reference not being fixed
File           The file in which the reference appears
Source_Files   One or more files that contained the content in this file
END
    summarize=>1,
    title=>$xref->fixBadRefs
      ? qq(These failing references refer to files that could not be located and so were put in M3)
      : qq(These failing references refer to files that could not be located),
    head=><<END,
Xref moved NNNN failing references on DDDD
END
    file=>(fpe($xref->reports, qw(bad failingReferences txt))));
=cut

sub reportImages($)                                                             #P Reports on images and references to images
 {my ($xref) = @_;                                                              # Cross referencer
  my @bad =                                                                     # Image reference failures
    sort {$$a[1] cmp $$b[1]}                                                    # Sort by source file
    sort {$$a[0] cmp $$b[0]}                                                    # Sort by href
    map  {[@$_[3..5]]}                                                          # Relevant details
    grep {$$_[1] =~ m(\Aimage\Z)s} @{$xref->fixedRefsFailed};                   # Bad images

  $xref->missingImageFiles = [@bad];                                            # Missing image file names

  formatTable([@bad], <<END,                                                    # Report missing images references
Href           The image reference that could not be resolved
File           The source file in which the image reference appears
Source_Files   One or more files that contained the content in this source file
END
    title=>qq(Bad image references),
    head=>qq(Xref found NNNN bad image references on DDDD),
    summarize=>1,
    file=>(my $f = fpe($xref->reports, qw(bad missing_images txt))));

  return {missingImageFiles => $xref->missingImageFiles}
#  my $found = [map {[$xref->goodImageRefs->{$_}, $_]}
#              keys %{$xref->goodImageRefs}];
#
#  formatTable($found, <<END,
#Count          Number of references to each image file found.
#ImageFileName  Full image file name
#END
#    title=>qq(Image files),
#    head=>qq(Xref found NNNN image files found on DDDD),
#    file=>(fpe($xref->reports, qw(good imagesFound txt))));
#
#  my $missing = [map {[$xref->badImageRefs->{$_}, $_]}
#                 sort keys %{$xref->badImageRefs}];
#
#  formatTable($missing, <<END,
#Count          Number of references to each image file found.
#ImageFileName  Full image file name
#END
#    title=>qq(Missing image references),
#    head=>qq(Xref found NNNN images missing on DDDD),
#    file=>(fpe($xref->reports, qw(bad imagesMissing txt))));
 } # reportImages

sub reportParseFailed($)                                                        #P Report failed parses
 {my ($xref) = @_;                                                              # Cross referencer

  formatTable($xref->parseFailed, <<END,
Source The file that failed to parse as an absolute file path
END
    title=>qq(Files failed to parse),
    head=>qq(Xref found NNNN files failed to parse on DDDD),
    file=>(my $f = fpe($xref->reports, qw(bad parseFailed txt))));
  {}                                                                            # From multiverse to universe
 } # reportParseFailed

sub reportXml1($)                                                               #P Report bad xml on line 1
 {my ($xref) = @_;                                                              # Cross referencer

  formatTable([sort keys %{$xref->badXml1}], <<END,
Source  The source file containing bad xml on line
END
    title=>qq(Bad Xml line 1),
    head=>qq(Xref found NNNN Files with the incorrect xml on line 1 on DDDD),
    file=>(my $f = fpe($xref->reports, qw(bad xmlLine1 txt))));
  {}                                                                            # From multiverse to universe
 } # reportXml1

sub reportXml2($)                                                               #P Report bad xml on line 2
 {my ($xref) = @_;                                                              # Cross referencer

  formatTable([sort keys %{$xref->badXml2}], <<END,
Source  The source file containing bad xml on line
END
    title=>qq(Bad Xml line 2),
    head=>qq(Xref found NNNN Files with the incorrect xml on line 2 on DDDD),
    file=>(my $f = fpe($xref->reports, qw(bad xmlLine2 txt))));
  {}                                                                            # From multiverse to universe
 } # reportXml2

sub reportDocTypeCount($)                                                       #P Report doc type count
 {my ($xref) = @_;                                                              # Cross referencer

  my %d;
  for my $f(sort keys %{$xref->docType})
   {my $d = $xref->docType->{$f};
    $d{$d}++
   }

  formatTable(\%d, [qw(DocType)],
    title=>qq(Document types),
    head=>qq(Xref found NNNN different doc types on DDDD),
    file=>(fpe($xref->reports, qw(count docTypes txt))));
  {}                                                                            # From multiverse to universe
 } # reportDocTypeCount

sub reportTagCount($)                                                           #P Report tag counts
 {my ($xref) = @_;                                                              # Cross referencer

  my %d;
  for   my $f(sort keys %{$xref->tagCount})
   {for my $t(sort keys %{$xref->tagCount->{$f}})
     {my $d = $xref->tagCount->{$f}{$t};
      $d{$t} += $d;
     }
   }

  formatTable(\%d, [qw(Tag Count)],
    title=>qq(Tags),
    head=>qq(Xref found NNNN different tags on DDDD),
    file=>(fpe($xref->reports, qw(count tags txt))));
  {}                                                                            # From multiverse to universe
 } # reportTagCount

sub reportTagsAndTextsCount($)                                                  #P Report tags and texts counts
 {my ($xref) = @_;                                                              # Cross referencer

  my $tags  = 1; $tags  += $xref->tags ->{$_}||0 for keys %{$xref->tags};
  my $texts = 1; $texts += $xref->texts->{$_}||0 for keys %{$xref->texts};

  my @t;
  push @t, [q(Tags),          $tags];
  push @t, [q(Texts),         $texts];
  my $ratio = $xref->tagsTextsRatio = $tags/$texts;
  push @t, [q(Tags to Texts), sprintf("%7.4f", $ratio)];


  formatTable(\@t, [qw(Item Count)],
    title => q(Tags to Texts Ratio),
    head  => q(Xref found the following tag and text counts on DDDD),
    file  => (fpe($xref->reports, qw(count tagsAndTexts txt))));

   {tagsTextsRatio => $xref->tagsTextsRatio,                                    # From multiverse to universe
   }
 } # reportTagsAndTextsCount

sub reportLtGt($)                                                               #P Report items found between &lt; and &gt;
 {my ($xref) = @_;                                                              # Cross referencer

  my %d;
  for     my $f(sort keys %{$xref->ltgt})
   {for   my $t(sort keys %{$xref->ltgt->{$f}})
     {$d{$t} += $xref->ltgt->{$f}{$t};
     }
   }

  formatTable([map {[$d{$_}, nws($_)]} sort keys %d], <<END,
Count The number of times this text was found
Text  The text found between &lt; and &gt;. The white space has been normalized to make better use of the display.
END
    title=>qq(Text found between &lt; and &gt;),
    head=><<END,
Xref found NNNN different text items between &lt; and &gt; on DDDD
END
    file=>(fpe($xref->reports, qw(count ltgt txt))));
  {}                                                                            # From multiverse to universe
 } # reportLtGt

sub reportAttributeCount($)                                                     #P Report attribute counts
 {my ($xref) = @_;                                                              # Cross referencer

  my %d;
  for   my $f(sort keys %{$xref->attributeCount})
   {for my $t(sort keys %{$xref->attributeCount->{$f}})
     {my $d = $xref->attributeCount->{$f}{$t};
      $d{$t} += $d;
     }
   }

  formatTable(\%d, [qw(Attribute Count)],
    title=>qq(Attributes),
    head=>qq(Xref found NNNN different attributes on DDDD),
    file=>(my $f = fpe($xref->reports, qw(count attributes txt))));
  {}                                                                            # From multiverse to universe
 } # reportAttributeCount

sub reportAttributeNameAndValueCounts($)                                        #P Report attribute value counts
 {my ($xref) = @_;                                                              # Cross referencer

  my %d;
  for     my $f(sort keys %{$xref->attributeNamesAndValuesCount})
   {for   my $a(sort keys %{$xref->attributeNamesAndValuesCount->{$f}})
     {for my $v(sort keys %{$xref->attributeNamesAndValuesCount->{$f}{$a}})
       {my $c =             $xref->attributeNamesAndValuesCount->{$f}{$a}{$v};
        $d{$a}{$v} += $c;
       }
     }
   }

  my @D;
  for   my $a(sort keys %d)
   {for my $v(sort keys %{$d{$a}})
     {push @D, [$d{$a}{$v}, firstNChars($v, 128), $a];                          # Otherwise the report can get surprisingly wide
     }
   }

  my @d = sort {$$a[2] cmp $$b[2]}
          sort {$$b[0] <=> $$a[0]} @D;


  formatTable(\@d, <<END,
Count     The number of  times this value occurs
Value     The value being counted
Attribute The attribute on which the value appears
END
    summarize => 1,
    title     => qq(Attribute value counts),
    head      => qq(Xref found NNNN attribute value combinations on DDDD),
    file      => (fpe($xref->reports, qw(count attributeNamesAndValues txt))));
  {}                                                                            # From multiverse to universe
 } # reportAttributeNameAndValueCounts

sub reportValidationErrors($)                                                   #P Report the files known to have validation errors
 {my ($xref) = @_;                                                              # Cross referencer

  formatTable([map {[$_]} sort keys %{$xref->validationErrors}], [qw(File)],
    title=>qq(Topics with validation errors),
    head=><<END,
Xref found NNNN topics with validation errors on DDDD
END
    file=>(fpe($xref->reports, qw(bad validationErrors txt))));
  {}                                                                            # From multiverse to universe
 } # reportValidationErrors

# Relies on badBookMapRefs which is incorrectly set
#sub checkBookMap($$)                                                            #P Check whether a bookmap is valid or not
# {my ($xref, $bookMap) = @_;                                                    # Cross referencer, bookmap
#
#  for my $href($bookMap, sort keys %{$xref->bookMapRefs->{$bookMap}})           # Each topic ref in the bookmap
#   {my $t = absFromAbsPlusRel($bookMap, $href);
#    for my $field                                                               # Fields that report errors
#     (qw(parseFailed badXml1 badXml2 badBookMapRefs badXRefs
#         imagesMissing badConRefs missingTopicIds
#         validationErrors))
#     {if ($xref->{$field}->{$t})
#       {return [$field, $xref->topicIds->{$bookMap}, $bookMap, $href, $t];
#       }
#     }
#   }
#  undef                                                                         # No errors
# }

#sub reportBookMaps($)                                                           #P Report on whether each bookmap is good or bad
# {my ($xref) = @_;                                                              # Cross referencer
#
#  my @bad;
#  my @good;
#  for my $f(sort keys %{$xref->docType})
#   {if ($xref->docType->{$f} =~ m(map\Z)s)
#     {if (my $r = $xref->checkBookMap($f))
#       {push @bad, $r;
#       }
#      else
#       {push @good, [$f];
#       }
#     }
#   }
#  $xref-> badBookMaps = [@bad];                                                 # Bad bookmaps
#  $xref->goodBookMaps = [@good];                                                # Good book maps
#
#  formatTable(\@bad, <<END,
#Reason          Reason bookmap failed
#Source_Topic_Id The topic id of the failing bookmap
#Bookmap         Bookmap source file name
#Topic_Ref       Failing appendix, chapter or topic ref.
#Topic_File      Targeted topic file if known
#END
#    title=>qq(Bookmaps with errors),
#    head=><<END,
#Xref found NNNN bookmaps with errors on DDDD
#END
#    summarize=>1,
#    file=>(fpe($xref->reports, qw(bad bookMap txt))));
#
#  formatTable(\@good, [qw(File)],
#    title=>qq(Good bookmaps),
#    head=><<END,
#Xref found NNNN good bookmaps on DDDD
#END
#    file=>(fpe($xref->reports, qw(good bookMap txt))));
# }

sub reportTables($)                                                             #P Report on tables that have problems
 {my ($xref) = @_;                                                              # Cross referencer

  formatTable($xref->badTables, <<END,
Reason          Reason bookmap failed
Attributes      The tag and attributes of the table element in question
Location        The location at which the error was detected
Source_File     The file in which the error was detected
END
    title=>qq(Tables with errors),
    head=><<END,
Xref found NNNN table errors on DDDD
END
    summarize=>1,
    file=>(fpe($xref->reports, qw(bad tables txt))));
  {}                                                                            # From multiverse to universe
 } # reportTables

sub reportFileExtensionCount($)                                                 #P Report file extension counts
 {my ($xref) = @_;                                                              # Cross referencer

  formatTable(countFileExtensions($xref->inputFolder), [qw(Ext Count)],
    title=>qq(File extensions),
    head=><<END,
Xref found NNNN different file extensions on DDDD
END
    file=>(fpe($xref->reports, qw(count fileExtensions txt))));
  {}                                                                            # From multiverse to universe
 } # reportFileExtensionCount

sub reportFileTypes($)                                                          #P Report file type counts - takes too long in series
 {my ($xref) = @_;                                                              # Cross referencer

  formatTable(countFileTypes
   ($xref->inputFolder, $xref->maximumNumberOfProcesses),
   [qw(Type Count)],
    title=>qq(Files types),
    head=><<END,
Xref found NNNN different file types on DDDD
END
    file=>(my $f = fpe($xref->reports, qw(count fileTypes txt))));
  {}                                                                            # From multiverse to universe
 } # reportFileTypes

# Relies on bookMapRefs which is set incorrectly
#sub reportNotReferenced($)                                                      #P Report files not referenced by any of conref, image, bookmapref, xref and are not bookmaps.
# {my ($xref) = @_;                                                              # Cross referencer
#
#  my %files = map {$_=>1}                                                       # Locate files of interest - all files minus companion files and other control files.
#    grep {m(\.\w+\Z) and !m(\.directory)}
#    searchDirectoryTreesForMatchingFiles
#     ($xref->inputFolder);
#
#  my %target;                                                                   # Targets of xrefs and conrefs
#  $target{$xref->{goodConRefs}{$_}[2]}++ for keys %{$xref->{goodConRefs}};
#  $target{$xref->{goodXRefs}  {$_}[2]}++ for keys %{$xref->{goodXRefs}};
#
#  my @T = sort keys %target;                                                    # Xref and Conref targets
#  my @i = sort keys %{$xref->goodImageRefs},                                    # Image files
#  my @t = sort keys %{$xref->goodBookMapRefs},                                  # Topic Refs
#  my @r = map {$$_[2]} @{$xref->fixedRefs};                                     # Files whose names have been changed as a result of deguidization
#  my @g = map {$$_[1]} @{$xref->fixedRefsGB};                                   # Files whose names have been changed as a result of renaming to the GB standard
#
#  for my $file(@i, @t,, @r, @g, @T)                                             # Remove referenced files
#   {delete $files{$file};
#   }
#
#  for my $file(sort keys %{$xref->docType})                                     # Remove bookmaps from consideration as they are not usually referenced
#   {my $tag = $xref->docType->{$file};
#    if ($tag =~ m(\Abookmap\Z)is)
#     {delete $files{$file};
#     }
#   }
#
#  $xref->notReferenced = \%files;                                               # Hash of files that are not referenced
#
#  formatTable([sort keys %files],
#   [qw(FileNo Unreferenced)],
#    title=>qq(Unreferenced files),
#    head=><<END,
#Xref found NNNN unreferenced files on DDDD.
#
#These files are not mentioned in any conref or href attribute and are not
#bookmaps.
#
#END
#    file=>(my $f = fpe($xref->reports, qw(bad notReferenced txt))));
# }

sub reportExternalXrefs($)                                                      #P Report external xrefs missing other attributes
 {my ($xref) = @_;                                                              # Cross referencer

  my @s;
  for   my $f(sort keys %{$xref->xrefBadScope})
   {my $sourceTopicId = $xref->topicIds->{$f};
    for my $h(sort keys %{$xref->xrefBadScope->{$f}})
     {my $s = $xref->xrefBadScope->{$f}{$h};
      push @s, [q(Bad scope attribute), $h, $s, $sourceTopicId, $f];
     }
   }

  for   my $f(sort keys %{$xref->xrefBadFormat})
   {my $sourceTopicId = $xref->topicIds->{$f};
    for my $h(sort keys %{$xref->xrefBadFormat->{$f}})
     {my $s = $xref->xrefBadFormat->{$f}{$h};
      push @s, [q(Bad format attribute), $h, $s, $sourceTopicId, $f];
     }
   }

  formatTable(\@s, <<END,
Reason          The reason why the xref is unsatisfactory
Href            The href attribute of the xref in question
Xref_Statement  The xref statement in question
Source_Topic_Id The topic id of the source file containing file containing the bad external xref
File            The file containing the xref statement in question
END
    title=>qq(Bad external xrefs),
    head=>qq(Xref found bad external xrefs on DDDD),
    file=>(my $f = fpe($xref->reports, qw(bad externalXrefs txt))));
  {}                                                                            # From multiverse to universe
 } # reportExternalXrefs

sub reportPossibleImprovements($)                                               #P Report improvements possible
 {my ($xref) = @_;                                                              # Cross referencer

  my @S;
  for   my $i(sort keys %{$xref->improvements})
   {push @S, @{$xref->improvements->{$i}};
   }

  my @s = sort {$$a[0] cmp $$b[0]}
          sort {$$a[3] cmp $$b[3]} @S;

  formatTable(\@s, <<END,
Improvement     The improvement that might be made.
Text            The text that suggested the improvement.
Line_Number     The line number at which the improvement could be made.
File            The file in which the improvement could be made.
END
    title=>qq(Possible improvements),
    head=><<END,
Xref found NNNN opportunities for improvements that might be
made on DDDD
END
    file=>(fpe($xref->reports, qw(improvements txt))),
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportPossibleImprovements

sub reportMaxZoomOut($)                                                         #P Text located via Max Zoom In
 {my ($xref) = @_;                                                              # Cross referencer
  return unless my $names = $xref->maxZoomIn;                                   # No point if maxZoomIn was not specified

  my @names = (qw(File_Name Title), sort keys %$names);                         # Column Headers
  my %names = map {$names[$_]=>$_} keys @names;                                 # Assign regular expression names to columns in the output table/csv

  my @f;
  for   my $f(sort keys %{$xref->maxZoomOut // {}})                             # One row per file processed showing which regular expression names matched
   {my @n = ($f,  $xref->title->{$f});
    my $c = 0;
    for my $n(sort keys %{$xref->maxZoomOut->{$f}})
     {$n[$names{$n}] += $xref->maxZoomOut->{$f}{$n};
      ++$c;
     }
    push @f, [@n] if $c;                                                        # Only save a row if it has something in it
   }

  for   my $f(sort keys %{$xref->maxZoomOut // {}})
   {my $t = $xref->title->{$f};
    my $d = $xref->maxZoomOut->{$f};
    $xref->maxZoomOut->{$f} = {title=>$t, data=>$d};
   }

  formatTable([sort {$$a[0] cmp $$b[0]} @f], [@names],                          # Sort by file name
    title=>qq(Max Zoom In Matches),
    head=><<END,
Xref found NNNN file matches on DDDD
END
    file=>(fpe($xref->reports, qw(lists maxZoom txt))),
    summarize=>1);

  dumpFile(fpe($xref->reports, qw(lists maxZoom data)), $xref->maxZoomOut);     # Dump the search results

   {maxZoomOut => $xref->maxZoomOut,                                            # From multiverse to universe
   }
 } # reportMaxZoomOut

sub reportTopicDetails($)                                                       #P Things that occur once in each file
 {my ($xref) = @_;                                                              # Cross referencer

  my @t;
  for my $f(sort @{$xref->inputFiles})
   {push @t, [$xref->docType ->{$f}//q(),
              $xref->topicIds->{$f}//q(),
              $xref->author  ->{$f}//q(),
              $xref->title   ->{$f}//q(),
              $f,
             ];
   }

  formatTable(\@t, <<END,
Tag             The outermost tag
Id              The id on the outermost tag
Author          The author of the topic
Title           The title of the topic
File            The source file name as a relative file name
END
    title=>qq(Topics),
    head=><<END,
Xref found NNNN topics on DDDD
END
    file=>(fpe($xref->reports, qw(lists topics txt))),
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportTopicDetails

sub reportTopicReuse($)                                                         #P Count how frequently each topic is reused
 {my ($xref) = @_;                                                              # Cross referencer

  my %t;
  for   my $f(sort keys %{$xref->bookMapRefs})
   {for my $t(sort keys %{$xref->bookMapRefs->{$f}})
     {my $file = absFromAbsPlusRel($f, $t);
      $t{$file}{$f}++;
     }
   }
  for my $t(keys %t)                                                            # Eliminate bookmaprefs that are used only once
   {if (keys (%{$t{$t}}) <= 1)
     {delete $t{$t};
     }
   }

  my @t;
  for   my $t(keys %t)                                                          # Target
   {for my $s(keys %{$t{$t}})                                                   # Source
     {push @t, [scalar(keys %{$t{$t}}), $t{$t}{$s},  $t, $s];
     }
   }

  my $t = [sort {$a->[0] <=> $b->[0]}                                           # Order report
           sort {$a->[2] cmp $b->[2]}  @t];

  for   my $i(keys @$t)                                                         # Deduplicate first column from third column
   {next unless $i;
    my $a = $t->[$i-1];
    my $b = $t->[$i];
    $b->[0] = '' if $a->[2] eq $b->[2];
   }

  formatTable($t,                                                               # Format report
               <<END,
Reuse           The number of times the target topic is reused over all topics
Count           The number of times the target topic is reused in the source topic
Target          The topic that is being reused == the target of reuse
Source          The topic that is referencing the reused topic
END
    title=>qq(Topic Reuses),
    head=><<END,
Xref found NNNN topics that are currently being reused on DDDD
END
    file=>(fpe($xref->reports, qw(lists topicReuse txt))),
    zero=>1,                                                                    # Reuse is very unlikely because the matching criteria is the MD5 sum
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportTopicReuse

# References might need fixing either because they are invalid or because we are
# deguidizing

sub reportFixRefs($)                                                            #P Report of hrefs that need to be fixed
 {my ($xref) = @_;                                                              # Cross referencer

  my @r;
  for   my $f(sort keys %{$xref->fixRefs})
   {for my $h(sort keys %{$xref->fixRefs->{$f}})
     {push @r, [$h, $f];
     }
   }

  formatTable(\@r,                                                              # Format report
               <<END,
Reference       The reference to be fixed
Source          The topic that contains the reference
END
    title=>qq(References to fix),
    head=><<END,
Xref found NNNN hrefs that should be fixed on DDDD
END
    file=>(fpe($xref->reports, qw(lists fixRefs txt))),
    zero=>1,
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportFixRefs

sub reportSourceFiles($)                                                        #P Source file for each topic
 {my ($xref) = @_;                                                              # Cross referencer
  my @r;
  for my $f(sort keys %{$xref->targetTopicToInputFiles})                        # File
   {my $s = $xref->targetTopicToInputFiles->{$f};                               # Source file for topic
    push @r, [$f, join ' ', sort keys %$s] if $s;
   }

  formatTable([sort {$$a[0]cmp $$b[0]} @r], <<END,                              # Report source files
Topic     The topic file
Source    The source file from which the topic was obtained
END
    title=>qq(Source file for each topic),
    head=><<END,
Xref found the source files for NNNN topics on DDDD
END
    file=>(fpe($xref->reports, qw(lists source_file_for_each_topic txt))),
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportSourceFiles

sub reportReferencesFromBookMaps($)                                             #P Topics and images referenced from bookmaps
 {my ($xref) = @_;                                                              # Cross referencer
  my %bi;                                                                       # Bookmap to image
  my %bt;                                                                       # Bookmap to topics
  my @bi;                                                                       # Bookmap to image report
  my @bt;                                                                       # Bookmap to topic report

  my $imageRefsFromTopic = sub                                                  # Image references from a topic
   {my ($b, $t) = @_;                                                           # Book map, topic

    for my $I(sort keys %{$xref->imagesReferencedFromTopics->{$t}})             # Image href
     {my $i = absFromAbsPlusRel($t, $I);
      push @bi, my $d = [$I, -e $i ? 1 : '', $i, $t, $b];
      $bi{$b}{$i}++;                                                            # Images from bookmap
     }
   };

  for   my $b(sort keys %{$xref->bookMapRefs})                                  # Bookmap as that is the only kind of file containing a topic ref
   {for my $T(sort keys %{$xref->bookMapRefs->{$b}})                            # Topic href
     {my $t = absFromAbsPlusRel($b, $T);

      push @bt, [$T, -e $t ? 1 : '', $t, $b];                                   # Report bookmap to topic
      $bt{$b}{$t}++;                                                            # Topics from bookmap

      &$imageRefsFromTopic($b, $t);
     }

    for my $C(sort keys %{$xref->conRefs->{$b}})                                # Conref
     {my ($t) = parseDitaRef($C, $b);
      &$imageRefsFromTopic($b, $t);
     }
   }

  $xref->topicsReferencedFromBookMaps = \%bt;                                   # Topics referenced from bookmaps
  $xref->imagesReferencedFromBookMaps = \%bi;                                   # Images referenced from bookmaps

  formatTable(\@bi, <<END,                                                      # Report images
Href      The href that contains an image reference
Exists    Whether the referenced image exists or not
Image     The name of the image file
Topic     The topic that referenced the image
Bookmap   The book map that referenced the topic
END
    title=>qq(Images referenced from bookmaps),
    head=><<END,
Xref found NNNN images referenced from bookmaps via topics on DDDD
END
    file=>(fpe($xref->reports, qw(lists images_from_bookmaps txt))),
    zero=>1,
    summarize=>1);

  formatTable(\@bt, <<END,                                                      # Report topics
Reference The topic reference
Exists    Whether the referenced topic exists or not
Topic     The topic that referenced the image
Bookmap   The book map that referenced the topic
END
    title=>qq(Topics referenced from bookmaps),
    head=><<END,
Xref found NNNN topics referenced from bookmaps via topics on DDDD
END
    file=>(fpe($xref->reports, qw(lists topics_from_bookmaps txt))),
    zero=>1,
    summarize=>1);

  {topicsReferencedFromBookMaps => \%bt,                                        # Topics referenced from bookmaps
   imagesReferencedFromBookMaps => \%bi,                                        # Images referenced from bookmaps
  }                                                                             # From multiverse to universe
 } # reportReferencesFromBookMaps

sub reportSimilarTopicsByTitle($)                                               #P Report topics likely to be similar on the basis of their titles as expressed in the non Guid part of their file names
 {my ($xref) = @_;                                                              # Cross referencer

  my %t;
  for   my $File(@{$xref->inputFiles})                                          # Each input file
   {my $F = fn $File;
    my $f = $F =~ s([0-9a-f]{32}\Z) (_)gsr;                                     # Remove md5 sum from file name
    $t{$f}{$F}++;
   }

  for my $t(keys %t)                                                            # Eliminate files that have no similar counter parts
   {if (keys (%{$t{$t}}) <= 1)
     {delete $t{$t};
     }
   }

  my @t;
  for   my $t(keys %t)                                                          # Target
   {for my $s(keys %{$t{$t}})                                                   # Source
     {push @t, [scalar(keys %{$t{$t}}), $t, $s];
     }
   }

  my $t = [sort {$b->[0] <=> $a->[0]}                                           # Order report so that most numerous are first
           sort {$a->[1] cmp $b->[1]}  @t];

  for   my $i(keys @$t)                                                         # Deduplicate first column from third column
   {next unless $i;
    my $a = $t->[$i-1];
    my $b = $t->[$i];
    $b->[0] = '' if $a->[1] eq $b->[1];
   }

  formatTable($t,                                                               # Format report
               <<END,
Similar          The number of topics similar to this one
Prefix           The prefix of the target file names being used for matching
Source           Topics that have the current prefix
END
    title=>qq(Topic Reuses),
    head=><<END,
Xref found NNNN topics that might be similar on DDDD
END
    file=>(fpe($xref->reports, qw(lists similar byTitle txt))),
    zero=>1,
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportSimilarTopicsByTitle

sub reportSimilarTopicsByVocabulary($)                                          #P Report topics likely to be similar on the basis of their vocabulary
 {my ($xref) = @_;                                                              # Cross referencer

  my @m = grep {scalar(@$_) > 1}                                                # Partition into like topics based on vocabulary - select the partitions with more than one element
  setPartitionOnIntersectionOverUnionOfHashStringSets
   ($xref->matchTopics, $xref->vocabulary);

  my @t;
  for my $a(@m)
   {my ($first, @rest) = @$a;
    push @t, [scalar(@$a), $first], map {[q(), $_]} @rest;
    push @t, [q(), q()];
   }
  formatTable(\@t,                                                              # Format report
               <<END,
Similar          The number of similar topics in this block
Topic            One of the similar topics
END
    title=>qq(Topics with similar vocabulary),
    head=><<END,
Xref found NNNN topics that have similar vocabulary on DDDD
END
    file=>(my $f = fpe($xref->reports, qw(lists similar byVocabulary txt))));
  {}                                                                            # From multiverse to universe
 } # reportSimilarTopicsByVocabulary

sub reportMd5Sum($)                                                             #P Good files have short names which uniquely represent their content and thus can be used instead of their md5sum to generate unique names
 {my ($xref) = @_;                                                              # Cross referencer

  my %f;                                                                        # {short file}{md5}++ means this short file name has the specified md5 sum.  We want there to be only one md5 sum per short file name
  for my $F(sort keys %{$xref->md5Sum})
   {if (my $m = $xref->md5Sum->{$F})
     {my $f = fn $F;
      $f{$f}{$m}++;
     }
   }

  for my $f(sort keys %f)                                                       # These are the good md5 sums that are in one-to-one correspondence with short file names
   {delete $f{$f} unless keys %{$f{$f}} == 1;
   }

  my @good;                                                                     # File name matches and md5 sum matches or opposite
  my @bad;                                                                      # Md5 sum matches but file name is not equal or file name is equal but md5 differs
  for my $F(sort keys %{$xref->md5Sum})
   {if (my $m = $xref->md5Sum->{$F})
     {my $f = fn $F;
      if ($f{$f}{$m})
       {push @good, [$m, $f, $F];
       }
      else
       {push @bad, [$m, $f, $F];
       }
     }
     ### Need check for undef $m
   }

  formatTable(\@bad, <<END,
Md5_Sum           The md5 sum in question
Short_File_Name   The short name of the file
File              The file name
END
    title=>qq(Files whose short names are not bi-jective with their md5 sums),
    head=><<END,
Xref found NNNN such files on DDDD
END
    file=>(fpe($xref->reports, qw(bad short_name_to_md5_sum txt))),
    summarize=>1);

  formatTable(\@good, <<END,
Md5_Sum           The md5 sum in question
Short_File_Name   The short name of the file
File              The file name
END
    title=>qq(Files whose short names are bi-jective with their md5 sums),
    head=><<END,
Xref found NNNN such files on DDDD
END
    file=>(fpe($xref->reports, qw(good short_name_to_md5_sum txt))),
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportMd5Sum

sub reportOlBody($)                                                             #P ol under body - indicative of a task
 {my ($xref) = @_;                                                              # Cross referencer

  my $select = sub                                                              # Select files with specified body
   {my ($body) = @_;
    my %b = %{$xref->olBody};
    for my $b(keys %b)
     {if (my $tag = $xref->baseTag->{$b})
       {if ($tag ne $body)
         {delete $b{$b} if $tag ne $body;
         }
       }
     }
    %b
   };

  my %c = $select->(q(conbody));

  formatTable([map {[$c{$_}, $_]} sort {$c{$b} <=> $c{$a}} sort keys %c], <<END,
Count             Number of ol under a conbody tag
File_Name         The name of the file containing an ol under conbody
END
    title=>qq(ol under conbody indicative of task),
    head=><<END,
Xref found NNNN files with ol under a conbody tag on DDDD.

ol under a conbody tag is often indicative of steps in a task.
END
    file=>(fpe($xref->reports, qw(bad olUnderConBody txt))),
    summarize=>1);

  my %t = $select->(q(taskbody));

  formatTable([map {[$t{$_}, $_]} sort {$t{$b} <=> $t{$a}} sort keys %t], <<END,
Count             Number of ol under a taskbody tag
File_Name         The name of the file containing an ol under taskbody
END
    title=>qq(ol under taskbody indicative of steps),
    head=><<END,
Xref found NNNN files with ol under a taskbody tag on DDDD.

ol under a taskbody tag is often indicative of steps in a task.
END
    file=>(fpe($xref->reports, qw(bad olUnderTaskBody txt))),
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportOlBody

sub reportHrefUrlEncoding($)                                                    #P href needs url encoding
 {my ($xref) = @_;                                                              # Cross referencer

  my @b;
  for my $f  (sort keys %{$xref->hrefUrlEncoding})
   {for my $l(sort keys %{$xref->hrefUrlEncoding->{$f}})
     {push @b,           [$xref->hrefUrlEncoding->{$f}{$l}, $l, $f];
     }
   }

  formatTable([@b], <<END,
Href             Href that needs url encoding
Line_location    Line location
File_Name        The file containing the href that needs url encoding
END
    title=>qq(Hrefs that need url encoding),
    head=><<END,
Xref found NNNN locations where an href needs to be url encoded on DDDD.
END
    file=>(fpe($xref->reports, qw(bad hrefs_that_need_url_encoding txt))),
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportHrefUrlEncoding

sub addNavTitlesToOneMap($$)                                                    #P Fix navtitles in one map
 {my ($xref, $file) = @_;                                                       # Xref results, file to fix
  my $changes = 0;                                                              # Number of successful changes
  my @r;                                                                        # Count of tags changed

  my $x = Data::Edit::Xml::new($file);                                          # Parse xml - should parse OK else otherwise how did we find out that this file needed to be fixed

  $x->by(sub                                                                    # Each node
   {my ($o) = @_;
    if ($o->at(qr(\A(appendix|chapter|topicref)\Z)is))                          # Nodes that take nv titles
     {if (my $h = $o->href)                                                     # href to target
       {if ($h =~ m(\AGUID-)is)                                                 # Target by guid
         {if (my $target = $xref->guidToFile->{$h})                             # Absolute target name
           {if (my $title = $xref->title->{$target})                            # Nav title
             {$o->set(navtitle=>$title);                                        # Set nav title
              push @r, [q(set by guid), $h, $title, $target, $file];            # Record set
              ++$changes;
             }
            else                                                                # No such target file
             {push @r, [q(No title for guid target), -A $o, $target, $file];
             }
           }
          else                                                                  # No mapping from guid to target file
           {push @r, [q(No file for guid), -A $o, $target, $file];
           }
         }
        else                                                                    # Target by file name
         {my $target = absFromAbsPlusRel($file, $h);                            # Absolute target name
          if (my $title = $xref->title->{$target})                              # Nav title
           {$o->set(navtitle=>$title);                                          # Set nav title
            push @r, [q(set), $h, $title, $target, $file];                      # Record set
            ++$changes;
           }
          else
           {push @r, [q(No title for target), -A $o, $target, $file];
           }
         }
       }
      else
       {push @r, [q(No href), -A $o, q(), $file];
       }
     }
   });

  if ($changes)                                                                 # Replace xml in source file if we changed anything successfully
   {editXml($file, $file, $x);                                                  # Edit xml
   }

  \@r                                                                           # Return report of actions taken
 } # addNavTitlesToOneMap

sub addNavTitlesToMaps($)                                                       #P Add nav titles to files containing maps.
 {my ($xref) = @_;                                                              # Xref results
  my @r;                                                                        # Additions made
  my @files =
    sort
    grep  {$xref->baseTag->{$_} =~ m(map\Z)s}                                   # Files containing maps
    keys %{$xref->baseTag};                                                     # Files with any base tags

  if (@files)                                                                   # Add nav titles to files
   {my @square = squareArray(@files);                                           # Divide the task

    my $ps = newProcessStarter($xref->maximumNumberOfProcesses);                # Process starter
       $ps->processingTitle   = q(Xref navtitles);
       $ps->totalToBeStarted  = scalar @square;
       $ps->processingLogFile = fpe($xref->reports, qw(log xref navtitles txt));

    for my $row(@square)                                                        # Each row of input files file
     {$ps->start(sub
       {my @r;                                                                  # Results
        for my $col(@$row)                                                      # Each column in the row
         {push @r, $xref->addNavTitlesToOneMap($col);                           # Process one input file
         }
        [@r]                                                                    # Return results as a reference
       });
     }

    for my $r(deSquareArray($ps->finish))                                       # Consolidate results
     {push @r, @$r;
     }
   }

  my @Bad;
  my @Good;
  for my $r(@r)
   {if ($$r[0] =~ m(\ANo)s)
     {push @Bad, $r;
     }
    else
     {shift @$r;
      push @Good, $r;
     }
   }

  my @bad  = sort {$$a[3] cmp $$b[3]} sort {$$a[1] cmp $$b[1]} @Bad;            # Sort results else we will get them in varying orders
  my @good = sort {$$a[2] cmp $$b[2]} sort {$$a[0] cmp $$b[0]} @Good;

  formatTable($xref->badNavTitles = \@bad, <<END,                               # Report bad results
Reason         The reason why a nav title was not added
Statement      The source xml statement requesting a navtitle
Title          The title of the the navtitle attribute
Target_File    The target of the href
Source_File    The source file being editted
END
    summarize=>1,
    title=>qq(Failing Nav titles),
    head=><<END,
Xref was unable to add NNNN navtitles as requested by the addNavTitles attribute on DDDD
END
    file=>(my $f = fpe($xref->reports, qw(bad nav_titles txt))));

  formatTable($xref->goodNavTitles = \@good, <<END,                             # Report good results
Statement      The source xml statement requesting a navtitle
Title          The title of the the navtitle attribute
Target_File    The target of the href
Source_File    The source file being editted
END
    summarize=>1,
    title=>qq(Succeding Nav titles),
    head=><<END,
Xref was able to add NNNN navtitles as requested by the addNavTitles parameter on DDDD
END
    file=>(fpe($xref->reports, qw(good nav_titles txt))));

   {badNavTitles  => $xref->badNavTitles,
    goodNavTitles => $xref->goodNavTitles,
  }                                                                             # From multiverse to universe
 } # addNavTitlesToMaps

sub oneBadRef($$$)                                                              #P Check one reference and return the first error encountered or B<undef> if no errors encountered. Relies on L<topicIds> to test files present and test the B<topicId> is valid, relies on L<ids> to check that the referenced B<id> is valid.
 {my ($xref, $file, $href) = @_;                                                # Cross referencer, file containing reference, reference

  my $fileExists = sub                                                          # Check that the specified file exists by looking for the topic id which L<Dita> guarantees will exist
   {my ($file) = @_;                                                            # File to check
    return 1 if $xref->topicIds->{$file};                                       # File exists
    my $decodedTarget = wwwDecode($file);                                       # Decode file name by expanding % signs to see if we can get a match
    return 2 if $xref->topicIds->{$decodedTarget};                              # File exists after decoding % signs
    return 3 if -e $file;                                                       # Images
    undef                                                                       # Cannot locate file
   };

  if ($href =~ m(#))                                                            # Full Dita href
   {my $sourceTopicId = $xref->topicIds->{$file};                               # Source id for referencing file
    my ($target, $topicId, $id) = parseDitaRef($href, $file, $sourceTopicId);   # Parse full Dita href

    my $targetFile    = absFromAbsPlusRel($file, $target//$file);               # Absolute target file which might be the current file
    my $targetTopicId = $xref->topicIds->{$targetFile};                         # Topic Id of target file

    my $bad = sub                                                               # Report a bad reference
     {my ($r) = @_;                                                             # Reason
       [$r, $href, $target, $topicId, $id, $sourceTopicId,
        $targetTopicId, $file, $targetFile];
     };

    return &$bad(q(No such file)) unless &$fileExists($targetFile);             # Check target file exists

    return &$bad(q(Topic id does not match)) unless $targetTopicId eq $topicId; # Check topic id of referenced topic against supplied topicId.  It is safe to assume that the target does have topic id as Dita requires one

    if ($id)                                                                    # Checkid if supplied
     {my $i = $xref->ids->{$target}{$id};                                       # Number of ids in the target topic with this value
      return &$bad(q(No such id in target topic))    unless $i;                 # No such id
      return &$bad(q(Duplicated id in target topic)) unless $i == 1;            # Duplicate ids
     }
   }

  else                                                                          # No # in href
   {my $targetFile = absFromAbsPlusRel($file, $href);
    return [q(No such file), $href, $href, q(), q(), q(), q(),
            $file, $targetFile] unless &$fileExists($targetFile);               # Check target file exists
   }

  undef                                                                         # No error to report
 } # oneBadRef

#D1 Create test data                                                            # Create files to test the various capabilities provided by Xref

my $conceptHeader = <<END =~ s(\s*\Z) ()gsr;                                    # Header for a concept
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Task//EN" "concept.dtd" []>
END

sub createSampleInputFiles($$)                                                  #P Create sample input files for testing. The attribute B<inputFolder> supplies the name of the folder in which to create the sample files.
 {my ($in, $N) = @_;                                                            # Input folder, number of sample files
  clearFolder($in, 20);
  for my $n(1..$N)
   {my $o = $n + 1; $o -= $N if $o > $N;
    my $f = owf(fpe($in, $n, q(dita)), <<END);
<concept id="c$n" xtrf="$n.dita">
  <title>Concept $n refers to $o</title>
  <conbody id="b$n">
     <xref id="x$n"  format="dita" href="$o.dita#c$o/x$o">Good</xref>
     <xref id="x$n"  format="dita" href="$o.dita#c$n/x$o">Duplicate id</xref>
     <xref id="b1$n" format="dita" href="bad$o.dita#c$o/x$o">Bad file</xref>
     <xref id="b2$n" format="dita" href="$o.dita#c$n/x$o">Bad topic id</xref>
     <xref id="b3$n" format="dita" href="$o.dita#c$o/x$n">Bad id in topic</xref>
     <xref id="g1$n" format="dita" href="$o.dita#c$o">Good 1</xref>
     <xref id="g2$n" format="dita" href="#c$o/x$o">Good 2</xref>
     <xref id="g3$n" format="dita" href="#c$o">Good 3</xref>
     <p conref="#c$n">Good conref</p>
     <p conref="#b$n">Bad conref</p>
     <image href="a$n.png"/>
     <image href="b$n.png"/>
     <ol><li/><li/></ol>
  </conbody>
</concept>
END
   }

  owf(fpe($in, qw(act1 dita)), <<END);
<concept id="guid-000">
  <title id="title">All Timing Codes Begin Here</title>
  <author>Phil</author>
  <conbody>
    <p>Note: see below</p>
    <p>Important: ignore all notes above</p>
    <image href="guid-000"/>
    <image href="guid-act1"/>
    <image href="guid-9999"/>
    <image href="act1.png"/>
    <xref/>
     <ol><li/><li/></ol>
     <ol><li/><li/></ol>
  </conbody>
</concept>
END

  owf(fpe($in, qw(act2 dita)), <<END);
$conceptHeader
<concept id="c2">
  <title id="title">Jumping Through Hops</title>
  <conbody>
    <section>
      <title/>
      <xref  format="dita" href="act1.dita#c1/title">All Timing Codes Begin Here</xref>
      <note  conref="act2.dita#c2/title"/>
      <xref  format="dita" href="9999#c1/title"/>
      <xref  format="dita" href="guid-000#guid-000/title"/>
      <xref  format="dita" href="guid-001#guid-001/title guid-000#guid-000/title"/>
      <xref  format="dita" href="guid-000#guid-000/title2"/>
      <xref  format="dita" href="guid-000#c1/title2"/>
      <xref  format="dita" href="guid-999#c1/title2"/>
      <xref  href="http://"/>
      <image href="act2.png"/>
      <link href="guid-000"/>
      <link href="guid-999"/>
      <link href="act1.dita"/>
      <link href="act9999.dita"/>
      <p conref="9999.dita"/>
      <p conref="bookmap.ditamap"/>
      <p conref="bookmap2.ditamap"/>
    </section>
    <required-cleanup>PLEX18</required-cleanup>
  </conbody>
</concept>
<!--linted: 2018-Nov-23 -->
END

  owf(fpe($in, qw(act3 dita)), <<END);
<concept id="c3">
  <title>Jumping Through Hops</title>
  <conbody>
    <p/>
  </body>
</concept>
END

  owf(fpe($in, qw(act4 dita)), <<END);
<concept id="c4">
  <taskbody/>
</concept>
END

  owf(fpe($in, qw(act5 dita)), <<END);
<concept id="c5">
  <taskbody/>
</concept>
END

  owf(fpe($in, qw(table dita)), <<END);
$conceptHeader
<concept id="table">
  <title>Tables</title>
  <conbody>
    <image href="new pass.png"/>
    <table>
      <tgroup cols="1">
        <thead>
          <row>
            <entry>
              <p>Significant Event</p>
            </entry>
            <entry>
              <p>Audit Event</p>
            </entry>
          </row>
        </thead>
        <tbody>
          <row>
            <entry/>
          </row>
        </tbody>
      </tgroup>
    </table>
    <table>
      <tgroup cols="1">
        <colspec/>
        <colspec/>
        <thead>
          <row>
            <entry>aaaa</entry>
            <entry>bbbb</entry>
          </row>
        </thead>
        <tbody>
          <row>
            <entry>aaaa</entry>
            <entry>bbbb</entry>
          </row>
          <row>
            <entry>aaaa</entry>
            <entry>bbbb</entry>
          </row>
        </tbody>
      </tgroup>
    </table>
  </conbody>
</concept>
END

  owf(fpe($in, qw(map bookmap ditamap)), <<END);
<map id="m1">
  <title>Test</title>
  <chapter  href="yyyy.dita">
    <topicref href="../act1.dita">Interesting topic</topicref>
    <topicref href="../act2.dita"/>
    <topicref href="../map/r.txt"/>
    <topicref href="9999.dita"/>
    <topicref href="bbb.txt"/>
    <topicref href="guid-000"/>
    <topicref href="guid-888"/>
    <topicref href="guid-999"/>
  </chapter>
</map>
END
  owf(fpe($in, qw(map bookmap2 ditamap)), <<END);
<map id="m2">
  <title>Test 2</title>
  <chapter  href="zzzz.dita">
    <topicref href="../act1.dita">Interesting topic</topicref>
    <topicref href="../act2.dita"/>
    <topicref href="../map/r.txt"/>
    <topicref href="9999.dita"/>
    <topicref href="bbb.txt"/>
    <topicref href="guid-000"/>
    <topicref href="guid-888"/>
    <topicref href="guid-999"/>
  </chapter>
</map>
END
  owf(fpe($in, qw(map bookmap3 ditamap)), <<END);
<map id="m2">
  <title>Test 3</title>
  <chapter  href="../act3.dita"/>
  <chapter  href="../act4.dita"/>
  <chapter  href="../act5.dita"/>
</map>
END
  createEmptyFile(fpe($in, qw(a1 png)));
 }

sub createSampleInputFilesFixFolder($)                                          #P Create sample input files for testing fixFolder
 {my ($in) = @_;                                                                # Folder to create the files in
  owf(fpe($in, 1, q(dita)), <<END);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE reference PUBLIC "-//PHIL//DTD DITA Task//EN" "concept.dtd" []>
<concept id="c1">
  <title>Concept 1 which refers to concept 2</title>
  <conbody>
     <p conref="2.dita#c2/p1"/>
     <p conref="2.dita#c2/p2"/>
     <p conref="3.dita#c2/p1"/>
     <xref href="2.dita#c2/p1"/>
     <xref href="2.dita#c2/p2"/>
     <xref href="3.dita#c2/p1"/>
  </conbody>
</concept>
END

  owf(fpe($in, 2, q(dita)), <<END);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE reference PUBLIC "-//PHIL//DTD DITA Task//EN" "concept.dtd" []>
<concept id="c2">
  <title>Concept 2 which does not refer to anything</title>
  <conbody>
     <p id="p1">Para 1 &lt;hello&gt; aaa &lt;goodbye&gt;</p>
     <p id="p2">Para 2 &lt;hello&gt; bbb &lt;goodbye&gt;</p>
  </conbody>
</concept>
END
 }

sub createSampleInputFilesLtGt($)                                               #P Create sample input files for testing items between &lt; and &gt;
 {my ($in) = @_;                                                                # Folder to create the files in
  owf(fpe($in, 1, q(dita)), <<END);
$conceptHeader
<concept id="c1">
  <title>Concept 1 which refers to concept 2</title>
  <conbody>
     <p>&lt;aaa&gt; AAAA &lt;bbb&gt;</p>
  </conbody>
</concept>
END
 }

sub createSampleInputFilesForFixDitaRefs($$)                                    #P Create sample input files for fixing renamed topic refs
 {my ($in, $targets) = @_;                                                      # Folder to create the files in, targets folder
  my $d = absFromAbsPlusRel(currentDirectory, $in);
  my @targets;

  push @targets, [owf(fpe($in, 1, q(ditamap)), <<END), q(1.ditamap)];
<map xtrf="${d}1.ditamap">
  <title>aaaa map</title>
  <topicref href="a.dita"/>
</map>
END

  push @targets, [owf(fpe($in, qw(a1 dita)), <<END), q(a.dita)];
<concept id="ca1" xtrf="${d}a.dita">
  <title>aaaa topic 111</title>
  <conbody>
    <p id="a1" conref="b.dita#b/b1"/>
  </conbody>
</concept>
END

  push @targets, [owf(fpe($in, qw(a2 dita)), <<END), q(a2.dita)];
<concept id="ca2" xtrf="${d}a.dita">
  <title>aaaa topic 222</title>
  <conbody>
    <p id="a2" conref="#./a1"/>
  </conbody>
</concept>
END

  push @targets, [owf(fpe($in, qw(b1 dita)), <<END), q(b1.dita)];
<concept id="cb1" xtrf="${d}b.dita">
  <title>bbbb topic 111</title>
  <conbody>
    <p id="b1" conref="a.dita#a/a1"/>
  </conbody>
</concept>
END

  push @targets, [owf(fpe($in, qw(b2 dita)), <<END), q(b2.dita)];
<concept id="cb2" xtrf="${d}b.dita">
  <title>bbbb topic 222</title>
  <conbody>
    <p id="b2" conref="#./b2"/>
  </conbody>
</concept>
END

  for my $target(@targets)                                                      # Create targets folder
   {owf(fpf($targets, $$target[1]), $$target[0]);
   }
 }

sub createSampleInputFilesForFixDitaRefsXref($)                                 #P Create sample input files for fixing references into renamed topics by xref
 {my ($in) = @_;                                                                # Folder to create the files in
  my $d = fpd(currentDirectory, $in);
  owf(fpe($in, qw(a1 dita)), <<END);
<concept id="ca1" xtrf="${d}a.dita">
  <title>aaaa topic 111</title>
  <conbody>
    <xref href="b.dita#b/b1"/>
  </conbody>
</concept>
END
  owf(fpe($in, qw(b1 dita)), <<END);
<concept id="cb1" xtrf="${d}b.dita">
  <title>bbbb topic 111</title>
  <conbody>
    <p id="b1"/>
  </conbody>
</concept>
END
  owf(fpe($in, qw(b2 dita)), <<END);
<concept id="cb2" xtrf="${d}b.dita">
  <title>bbbb topic 222</title>
  <conbody>
    <p id="b2"/>
  </conbody>
</concept>
END
 }

sub changeFolderAndWriteFiles($$)                                               #P Change file structure to the current folder and write
 {my ($f, $D) = @_;                                                             # Data structure as a string, target folder
  my $d = q(/home/phil/perl/cpan/DataEditXmlToDita/test/);
  my $F = eval(dump($f) =~ s($d) ($D)gsr);
  writeFiles($F);                                                               # Change folder and write test files
 }

sub createSampleInputFilesForFixDitaRefsImproved1($)                            #P Create sample input files for fixing references via the targets/ folder
 {my ($folder) = @_;                                                            # Folder to switch to
  my $f = {
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_4ef751d67c53ac33272c3bbe16284b0d.ditamap"  => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE bookmap PUBLIC \"-//OASIS//DTD DITA BookMap//EN\" \"bookmap.dtd\" []>\n<bookmap id=\"GUID-18c89db5-781b-666a-f24a-fbafa6d70733\">\n  <chapter href=\"a.dita\" navtitle=\"aaaa\">\n    <topicref href=\"b.dita\" navtitle=\"aaaa\"/>\n  </chapter>\n</bookmap>\n<!--linted: 2019-06-22 at 21:16:47 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: bookmap -->\n<!--docType: <!DOCTYPE bookmap PUBLIC \"-//OASIS//DTD DITA BookMap//EN\" \"bookmap.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_4ef751d67c53ac33272c3bbe16284b0d.ditamap -->\n<!--guid: GUID-18c89db5-781b-666a-f24a-fbafa6d70733 -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/ab.ditamap -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 885 -->\n<!--project: all -->\n<!--title: ab -->\n<!--definition: GUID-18c89db5-781b-666a-f24a-fbafa6d70733 -->\n<!--labels: GUID-18c89db5-781b-666a-f24a-fbafa6d70733 b1 -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_ca202b3f0a58c67675f9704a32546cea.dita" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-1581d732-b13a-edf0-2651-220a78f1c0fa\">\n  <title>aaaa</title>\n  <conbody>\n    <p>Aaa aaa aaa</p>\n  </conbody>\n</concept>\n<!--linted: 2019-06-22 at 21:16:47 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_ca202b3f0a58c67675f9704a32546cea.dita -->\n<!--guid: GUID-1581d732-b13a-edf0-2651-220a78f1c0fa -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/b.dita -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 885 -->\n<!--project: all -->\n<!--title: aaaa -->\n<!--definition: GUID-1581d732-b13a-edf0-2651-220a78f1c0fa -->\n<!--labels: GUID-1581d732-b13a-edf0-2651-220a78f1c0fa cb -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/a.dita"                                   => "{\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/a.dita\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_ca202b3f0a58c67675f9704a32546cea.dita\",\n  targetType => \"topic\",\n}",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/ab.ditamap"                               => "{\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/ab.ditamap\",\n  sourceDocType => \"bookmap\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_4ef751d67c53ac33272c3bbe16284b0d.ditamap\",\n  targetType => \"bookmap\",\n}",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/b.dita"                                   => "{\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/b.dita\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_ca202b3f0a58c67675f9704a32546cea.dita\",\n  targetType => \"topic\",\n}",
  };

  changeFolderAndWriteFiles($f, $folder);                                       # Change folder and write files
 }

sub createSampleInputFilesForFixDitaRefsImproved2($)                            #P Create sample input files for fixing conref references via the targets/ folder
 {my ($folder) = @_;                                                            # Folder to switch to
  my $f = {
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_c8e30fbb422819ab92e1752ca50bb158.dita" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-48fb251a-9a88-3bcc-d81b-301f426ed439\">\n  <title>aaaa</title>\n  <conbody>\n    <p conref=\"b.dita#cb/p1\">aaaa</p>\n  </conbody>\n</concept>\n<!--linted: 2019-06-22 at 21:16:47 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_c8e30fbb422819ab92e1752ca50bb158.dita -->\n<!--guid: GUID-48fb251a-9a88-3bcc-d81b-301f426ed439 -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/a.dita -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 885 -->\n<!--project: all -->\n<!--title: aaaa -->\n<!--definition: GUID-48fb251a-9a88-3bcc-d81b-301f426ed439 -->\n<!--labels: GUID-48fb251a-9a88-3bcc-d81b-301f426ed439 ca -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_bbbb_e374c26206dc955160cecea10306509d.dita" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-e9997c20-3dcf-6958-f762-09d8250bc53e\">\n  <title>bbbb</title>\n  <conbody>\n    <p id=\"p1\">bbbb</p>\n  </conbody>\n</concept>\n<!--linted: 2019-06-22 at 21:16:47 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_bbbb_e374c26206dc955160cecea10306509d.dita -->\n<!--guid: GUID-e9997c20-3dcf-6958-f762-09d8250bc53e -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/b.dita -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 885 -->\n<!--project: all -->\n<!--title: bbbb -->\n<!--definition: p1 -->\n<!--definition: GUID-e9997c20-3dcf-6958-f762-09d8250bc53e -->\n<!--labels: GUID-e9997c20-3dcf-6958-f762-09d8250bc53e cb -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/a.dita"                                   => "{\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/a.dita\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_c8e30fbb422819ab92e1752ca50bb158.dita\",\n  targetType => \"topic\",\n}",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/b.dita"                                   => "{\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/b.dita\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_bbbb_e374c26206dc955160cecea10306509d.dita\",\n  targetType => \"topic\",\n}",
  };

  changeFolderAndWriteFiles($f, $folder);                                       # Change folder and write files
 }

sub createSampleInputFilesForFixDitaRefsImproved3($)                            #P Create sample input files for fixing bookmap references to topics that get cut into multiple pieces
 {my ($folder) = @_;                                                            # Folder to switch to
  my $f = {
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_6661b95b6e3802e892116df5a3307e8f.ditamap"   => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE bookmap PUBLIC \"-//OASIS//DTD DITA BookMap//EN\" \"bookmap.dtd\" []>\n<bookmap id=\"GUID-2a901384-59f3-9fdb-de14-546a63d03dfa\">\n  <chapter href=\"a.dita\" navtitle=\"aaaa\"/>\n</bookmap>\n<!--linted: 2019-06-25 at 21:04:31 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: bookmap -->\n<!--docType: <!DOCTYPE bookmap PUBLIC \"-//OASIS//DTD DITA BookMap//EN\" \"bookmap.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_6661b95b6e3802e892116df5a3307e8f.ditamap -->\n<!--guid: GUID-2a901384-59f3-9fdb-de14-546a63d03dfa -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/a.ditamap -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 929 -->\n<!--project: all -->\n<!--title: a -->\n<!--definition: GUID-2a901384-59f3-9fdb-de14-546a63d03dfa -->\n<!--labels: GUID-2a901384-59f3-9fdb-de14-546a63d03dfa bm -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_a_6b2bcb0e0a5337f3bb3b28099e892b3d.ditamap" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE bookmap PUBLIC \"-//OASIS//DTD DITA BookMap//EN\" \"bookmap.dtd\" []>\n<bookmap id=\"GUID-8e2504aa-ea92-9307-7bd1-82f52370aca2\">\n  <booktitle>\n    <mainbooktitle>a</mainbooktitle>\n  </booktitle>\n  <bookmeta>\n    <shortdesc/>\n    <author/>\n    <source/>\n    <category/>\n    <keywords>\n      <keyword/>\n    </keywords>\n    <prodinfo>\n      <prodname product=\"\"/>\n      <vrmlist>\n        <vrm version=\"\"/>\n      </vrmlist>\n      <prognum/>\n      <brand/>\n    </prodinfo>\n    <bookchangehistory>\n      <approved>\n        <revisionid/>\n      </approved>\n    </bookchangehistory>\n    <bookrights>\n      <copyrfirst>\n        <year/>\n      </copyrfirst>\n      <bookowner/>\n    </bookrights>\n  </bookmeta>\n  <frontmatter>\n    <notices/>\n    <booklists>\n      <toc/>\n    </booklists>\n    <preface/>\n  </frontmatter>\n  <chapter href=\"c_aaaa_e56ab0e797826adf7d4fef41f9c39fe1.dita\" navtitle=\"aaaa\">\n    <topicref href=\"c_bbbb_e374c26206dc955160cecea10306509d.dita\" navtitle=\"bbbb\"/>\n  </chapter>\n  <appendices/>\n  <reltable>\n    <relheader>\n      <relcolspec/>\n      <relcolspec/>\n    </relheader>\n    <relrow>\n      <relcell/>\n      <relcell/>\n    </relrow>\n    <relrow>\n      <relcell/>\n      <relcell/>\n    </relrow>\n  </reltable>\n</bookmap>\n<!--linted: 2019-06-25 at 21:04:32 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: bookmap -->\n<!--docType: <!DOCTYPE bookmap PUBLIC \"-//OASIS//DTD DITA BookMap//EN\" \"bookmap.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_a_6b2bcb0e0a5337f3bb3b28099e892b3d.ditamap -->\n<!--guid: GUID-8e2504aa-ea92-9307-7bd1-82f52370aca2 -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/a.dita -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 929 -->\n<!--project: all -->\n<!--title: a -->\n<!--definition: GUID-8e2504aa-ea92-9307-7bd1-82f52370aca2 -->\n<!--labels: GUID-8e2504aa-ea92-9307-7bd1-82f52370aca2 GUID-d42dec6e-0ce9-ebc1-c018-e656df6c3a06 -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_e56ab0e797826adf7d4fef41f9c39fe1.dita"  => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-fa5dea13-6bbb-2d62-2a55-f5feefe9ae89\">\n  <title>aaaa</title>\n  <conbody>\n    <p>aaaa</p>\n  </conbody>\n</concept>\n<!--linted: 2019-06-25 at 21:04:32 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_e56ab0e797826adf7d4fef41f9c39fe1.dita -->\n<!--guid: GUID-fa5dea13-6bbb-2d62-2a55-f5feefe9ae89 -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/a.dita -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 929 -->\n<!--project: all -->\n<!--title: aaaa -->\n<!--definition: GUID-fa5dea13-6bbb-2d62-2a55-f5feefe9ae89 -->\n<!--labels: GUID-fa5dea13-6bbb-2d62-2a55-f5feefe9ae89 ca -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_bbbb_e374c26206dc955160cecea10306509d.dita"  => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-e9997c20-3dcf-6958-f762-09d8250bc53e\">\n  <title>bbbb</title>\n  <conbody>\n    <p id=\"p1\">bbbb</p>\n  </conbody>\n</concept>\n<!--linted: 2019-06-25 at 21:04:31 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_bbbb_e374c26206dc955160cecea10306509d.dita -->\n<!--guid: GUID-e9997c20-3dcf-6958-f762-09d8250bc53e -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/a.dita -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 929 -->\n<!--project: all -->\n<!--title: bbbb -->\n<!--definition: p1 -->\n<!--definition: GUID-e9997c20-3dcf-6958-f762-09d8250bc53e -->\n<!--labels: GUID-e9997c20-3dcf-6958-f762-09d8250bc53e cb -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/a.dita"                                    => "bless({\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/a.dita\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_a_6b2bcb0e0a5337f3bb3b28099e892b3d.ditamap\",\n  targetType => \"bookmap\",\n}, \"SourceToTarget\")",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/a.ditamap"                                 => "bless({\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/a.ditamap\",\n  sourceDocType => \"bookmap\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_6661b95b6e3802e892116df5a3307e8f.ditamap\",\n  targetType => \"bookmap\",\n}, \"SourceToTarget\")",
  };

  changeFolderAndWriteFiles($f, $folder);                                       # Change folder and write files
 }

sub createSampleInputFilesForFixDitaRefsImproved4($)                            #P Create sample input files for fixing bookmap reference to a topic that did not get cut into  multiple pieces
 {my ($folder) = @_;                                                            # Folder to switch to
  my $f = {
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_6661b95b6e3802e892116df5a3307e8f.ditamap"  => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE bookmap PUBLIC \"-//OASIS//DTD DITA BookMap//EN\" \"bookmap.dtd\" []>\n<bookmap id=\"GUID-2a901384-59f3-9fdb-de14-546a63d03dfa\">\n  <chapter href=\"a.dita\" navtitle=\"aaaa\"/>\n</bookmap>\n<!--linted: 2019-06-25 at 22:41:31 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: bookmap -->\n<!--docType: <!DOCTYPE bookmap PUBLIC \"-//OASIS//DTD DITA BookMap//EN\" \"bookmap.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_6661b95b6e3802e892116df5a3307e8f.ditamap -->\n<!--guid: GUID-2a901384-59f3-9fdb-de14-546a63d03dfa -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/a.ditamap -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 929 -->\n<!--project: all -->\n<!--title: a -->\n<!--definition: GUID-2a901384-59f3-9fdb-de14-546a63d03dfa -->\n<!--labels: GUID-2a901384-59f3-9fdb-de14-546a63d03dfa bm -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_e56ab0e797826adf7d4fef41f9c39fe1.dita" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-fa5dea13-6bbb-2d62-2a55-f5feefe9ae89\">\n  <title>aaaa</title>\n  <conbody>\n    <p>aaaa</p>\n  </conbody>\n</concept>\n<!--linted: 2019-06-25 at 22:41:31 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_e56ab0e797826adf7d4fef41f9c39fe1.dita -->\n<!--guid: GUID-fa5dea13-6bbb-2d62-2a55-f5feefe9ae89 -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/a.dita -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 929 -->\n<!--project: all -->\n<!--title: aaaa -->\n<!--definition: GUID-fa5dea13-6bbb-2d62-2a55-f5feefe9ae89 -->\n<!--labels: GUID-fa5dea13-6bbb-2d62-2a55-f5feefe9ae89 ca -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/a.dita"                                   => "bless({\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/a.dita\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_e56ab0e797826adf7d4fef41f9c39fe1.dita\",\n  targetType => \"topic\",\n}, \"SourceToTarget\")",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/a.ditamap"                                => "bless({\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/a.ditamap\",\n  sourceDocType => \"bookmap\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_6661b95b6e3802e892116df5a3307e8f.ditamap\",\n  targetType => \"bookmap\",\n}, \"SourceToTarget\")",
  };

  changeFolderAndWriteFiles($f, $folder);                                       # Change folder and write files
 }

sub createSampleImageTest($)                                                    #P Create sample input files for fixing bookmap reference to a topic that did not get cut into  multiple pieces
 {my ($folder) = @_;                                                            # Folder to switch to

  my $f = {
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_concept_1_476bcb2107e9e6c19659ac20ae123fe6.dita" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-3984fb53-1379-7649-e0ac-272f39376156\">\n  <title>concept 1</title>\n  <conbody>\n    <image href=\"png_31d0017136191f418bbef189d417802a.png\"/>\n    <image href=\"../images/b.png\"/>\n  </conbody>\n</concept>\n\n<!--linted: 2019-07-05 at 23:31:12 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_concept_1_476bcb2107e9e6c19659ac20ae123fe6.dita -->\n<!--guid: GUID-3984fb53-1379-7649-e0ac-272f39376156 -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/concepts/c.dita -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 945 -->\n<!--project: all -->\n<!--title: concept 1 -->\n<!--definition: GUID-3984fb53-1379-7649-e0ac-272f39376156 -->\n<!--labels: GUID-3984fb53-1379-7649-e0ac-272f39376156 c1 -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/png_31d0017136191f418bbef189d417802a"              => "{\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/download/images/a.png\",\n}",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/png_31d0017136191f418bbef189d417802a.png"          => "png image a\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/concepts/c.dita"                               => "bless({\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/concepts/c.dita\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_concept_1_476bcb2107e9e6c19659ac20ae123fe6.dita\",\n  targetType => \"topic\",\n}, \"SourceToTarget\")",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/images/a.png"                                  => "bless({\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/download/images/a.png\",\n  sourceDocType => \"image\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/png_31d0017136191f418bbef189d417802a.png\",\n  targetType => \"image\",\n}, \"SourceToTarget\")",
  };

  changeFolderAndWriteFiles($f, $folder);                                       # Change folder and write files
 }

sub createTestTopicFlattening($)                                                #P Create sample input files for testing topic flattening ratio reporting
 {my ($folder) = @_;                                                            # Folder to switch to

  my $f = {
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_2b1faeb8f74e670e20450cde864e2e46.dita" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-707b18f0-a3e8-2566-446f-cdcfc467318c\">\n  <title/>\n  <conbody/>\n</concept>\n<!--linted: 2019-07-06 at 22:01:57 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_2b1faeb8f74e670e20450cde864e2e46.dita -->\n<!--guid: GUID-707b18f0-a3e8-2566-446f-cdcfc467318c -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/c1.dita -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 945 -->\n<!--project: all -->\n<!--definition: GUID-707b18f0-a3e8-2566-446f-cdcfc467318c -->\n<!--labels: GUID-707b18f0-a3e8-2566-446f-cdcfc467318c c -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/c1.dita"                             => "bless({\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/c1.dita\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_2b1faeb8f74e670e20450cde864e2e46.dita\",\n  targetType => \"topic\",\n}, \"SourceToTarget\")",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/c2.dita"                             => "bless({\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/c2.dita\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_2b1faeb8f74e670e20450cde864e2e46.dita\",\n  targetType => \"topic\",\n}, \"SourceToTarget\")",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/c3.dita"                             => "bless({\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/c3.dita\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_2b1faeb8f74e670e20450cde864e2e46.dita\",\n  targetType => \"topic\",\n}, \"SourceToTarget\")",
  };

  changeFolderAndWriteFiles($f, $folder);                                       # Change folder and write files
 }

sub createTestReferencedToFlattenedTopic($)                                     #P Full reference to a topic that has been flattened
 {my ($folder) = @_;                                                            # Folder to switch to

  my $f = {
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_3119ee09e34375ed4d8a7a15274a9774.dita" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-7b56e1e5-a8b5-7f09-73e5-e6ecb15d5e8f\">\n  <title>aaaa</title>\n  <conbody>\n    <p conref=\"b.dita#c/p1\"/>\n  </conbody>\n</concept>\n\n<!--linted: 2019-07-07 at 00:40:33 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_3119ee09e34375ed4d8a7a15274a9774.dita -->\n<!--guid: GUID-7b56e1e5-a8b5-7f09-73e5-e6ecb15d5e8f -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/a.dita -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 945 -->\n<!--project: all -->\n<!--title: aaaa -->\n<!--definition: GUID-7b56e1e5-a8b5-7f09-73e5-e6ecb15d5e8f -->\n<!--labels: GUID-7b56e1e5-a8b5-7f09-73e5-e6ecb15d5e8f c -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_8b028dc2faaca88ac747b3776189d4a6.dita" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-d003c721-d7e5-e4e8-3d84-ba7b4c80f56c\">\n  <title>aaaa</title>\n  <conbody>\n    <p id=\"p1\">pppp</p>\n  </conbody>\n</concept>\n<!--linted: 2019-07-07 at 00:40:33 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_8b028dc2faaca88ac747b3776189d4a6.dita -->\n<!--guid: GUID-d003c721-d7e5-e4e8-3d84-ba7b4c80f56c -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/c.ditamap -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 945 -->\n<!--project: all -->\n<!--title: aaaa -->\n<!--definition: p1 -->\n<!--definition: GUID-d003c721-d7e5-e4e8-3d84-ba7b4c80f56c -->\n<!--labels: GUID-d003c721-d7e5-e4e8-3d84-ba7b4c80f56c c -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/a.dita"                                   => "bless({\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/a.dita\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_3119ee09e34375ed4d8a7a15274a9774.dita\",\n  targetType => \"topic\",\n}, \"SourceToTarget\")",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/b.dita"                                   => "bless({\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/b.dita\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_8b028dc2faaca88ac747b3776189d4a6.dita\",\n  targetType => \"topic\",\n}, \"SourceToTarget\")",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/c.ditamap"                                => "bless({\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/c.ditamap\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_8b028dc2faaca88ac747b3776189d4a6.dita\",\n  targetType => \"topic\",\n}, \"SourceToTarget\")",
  };

  changeFolderAndWriteFiles($f, $folder);                                       # Change folder and write files
 }

sub createTestReferenceToCutOutTopic($)                                         #P References from a topic that has been cut out to a topic that has been cut out
 {my ($folder) = @_;                                                            # Folder to switch to

  my $f = {
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE bookmap PUBLIC \"-//OASIS//DTD DITA BookMap//EN\" \"bookmap.dtd\" []>\n<bookmap id=\"GUID-80a6bceb-0817-2a54-4d9e-ea67eed112b3\">\n  <booktitle>\n    <mainbooktitle>a</mainbooktitle>\n  </booktitle>\n  <bookmeta>\n    <shortdesc/>\n    <author/>\n    <source/>\n    <category/>\n    <keywords>\n      <keyword/>\n    </keywords>\n    <prodinfo>\n      <prodname product=\"\"/>\n      <vrmlist>\n        <vrm version=\"\"/>\n      </vrmlist>\n      <prognum/>\n      <brand/>\n    </prodinfo>\n    <bookchangehistory>\n      <approved>\n        <revisionid/>\n      </approved>\n    </bookchangehistory>\n    <bookrights>\n      <copyrfirst>\n        <year/>\n      </copyrfirst>\n      <bookowner/>\n    </bookrights>\n  </bookmeta>\n  <frontmatter>\n    <notices/>\n    <booklists>\n      <toc/>\n    </booklists>\n    <preface/>\n  </frontmatter>\n  <chapter href=\"c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita\" navtitle=\"aaaa\">\n    <topicref href=\"c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita\" navtitle=\"aaaa bbbb\">\n      <topicref href=\"c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita\" navtitle=\"aaaa cccc\"/>\n    </topicref>\n    <topicref href=\"c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita\" navtitle=\"aaaa dddd\"/>\n  </chapter>\n  <appendices/>\n  <reltable>\n    <relheader>\n      <relcolspec/>\n      <relcolspec/>\n    </relheader>\n    <relrow>\n      <relcell/>\n      <relcell/>\n    </relrow>\n    <relrow>\n      <relcell/>\n      <relcell/>\n    </relrow>\n  </reltable>\n</bookmap>\n\n<!--linted: 2019-07-07 at 20:33:58 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: bookmap -->\n<!--docType: <!DOCTYPE bookmap PUBLIC \"-//OASIS//DTD DITA BookMap//EN\" \"bookmap.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap -->\n<!--guid: GUID-80a6bceb-0817-2a54-4d9e-ea67eed112b3 -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/a.xml -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 945 -->\n<!--project: all -->\n<!--title: a -->\n<!--definition: GUID-80a6bceb-0817-2a54-4d9e-ea67eed112b3 -->\n<!--labels: GUID-80a6bceb-0817-2a54-4d9e-ea67eed112b3 GUID-621a0a8a-4af5-08b9-a9ba-ed7a27b59934 -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE bookmap PUBLIC \"-//OASIS//DTD DITA BookMap//EN\" \"bookmap.dtd\" []>\n<bookmap id=\"GUID-21696006-94ec-4e53-78c5-24a93641a474\">\n  <booktitle>\n    <mainbooktitle>b</mainbooktitle>\n  </booktitle>\n  <bookmeta>\n    <shortdesc/>\n    <author/>\n    <source/>\n    <category/>\n    <keywords>\n      <keyword/>\n    </keywords>\n    <prodinfo>\n      <prodname product=\"\"/>\n      <vrmlist>\n        <vrm version=\"\"/>\n      </vrmlist>\n      <prognum/>\n      <brand/>\n    </prodinfo>\n    <bookchangehistory>\n      <approved>\n        <revisionid/>\n      </approved>\n    </bookchangehistory>\n    <bookrights>\n      <copyrfirst>\n        <year/>\n      </copyrfirst>\n      <bookowner/>\n    </bookrights>\n  </bookmeta>\n  <frontmatter>\n    <notices/>\n    <booklists>\n      <toc/>\n    </booklists>\n    <preface/>\n  </frontmatter>\n  <chapter href=\"c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita\" navtitle=\"bbbb\">\n    <topicref href=\"c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita\" navtitle=\"bbbb aaaa\">\n      <topicref href=\"c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita\" navtitle=\"bbbb bbbb\"/>\n    </topicref>\n    <topicref href=\"c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita\" navtitle=\"bbbb cccc\"/>\n  </chapter>\n  <appendices/>\n  <reltable>\n    <relheader>\n      <relcolspec/>\n      <relcolspec/>\n    </relheader>\n    <relrow>\n      <relcell/>\n      <relcell/>\n    </relrow>\n    <relrow>\n      <relcell/>\n      <relcell/>\n    </relrow>\n  </reltable>\n</bookmap>\n\n<!--linted: 2019-07-07 at 20:33:58 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: bookmap -->\n<!--docType: <!DOCTYPE bookmap PUBLIC \"-//OASIS//DTD DITA BookMap//EN\" \"bookmap.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_b_d2806ba589f908da1106574afd9db642.ditamap -->\n<!--guid: GUID-21696006-94ec-4e53-78c5-24a93641a474 -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/b.xml -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 945 -->\n<!--project: all -->\n<!--title: b -->\n<!--definition: GUID-21696006-94ec-4e53-78c5-24a93641a474 -->\n<!--labels: GUID-21696006-94ec-4e53-78c5-24a93641a474 GUID-b3f88460-8608-df56-bc6c-1215327bcc24 -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-c67821ef-3da2-c89f-0fc9-9fba3937f368\">\n  <title>aaaa</title>\n  <conbody/>\n</concept>\n<!--linted: 2019-07-07 at 20:33:58 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita -->\n<!--guid: GUID-c67821ef-3da2-c89f-0fc9-9fba3937f368 -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/a.xml -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 945 -->\n<!--project: all -->\n<!--title: aaaa -->\n<!--definition: GUID-c67821ef-3da2-c89f-0fc9-9fba3937f368 -->\n<!--labels: GUID-c67821ef-3da2-c89f-0fc9-9fba3937f368 a -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-f0c0e170-8128-10ef-045d-97602fdde76f\">\n  <title>aaaa bbbb</title>\n  <conbody>\n    <p conref=\"b.xml#b/p1\"/>\n  </conbody>\n</concept>\n\n<!--linted: 2019-07-07 at 20:33:58 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita -->\n<!--guid: GUID-f0c0e170-8128-10ef-045d-97602fdde76f -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/a.xml -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 945 -->\n<!--project: all -->\n<!--title: aaaa bbbb -->\n<!--definition: GUID-f0c0e170-8128-10ef-045d-97602fdde76f -->\n<!--labels: GUID-f0c0e170-8128-10ef-045d-97602fdde76f ab -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-400c2c59-95e1-7bf3-4647-3a135281bfaf\">\n  <title>aaaa cccc</title>\n  <conbody>\n    <p conref=\"bb.xml#bb/p2\"/>\n  </conbody>\n</concept>\n\n<!--linted: 2019-07-07 at 20:33:58 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita -->\n<!--guid: GUID-400c2c59-95e1-7bf3-4647-3a135281bfaf -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/a.xml -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 945 -->\n<!--project: all -->\n<!--title: aaaa cccc -->\n<!--definition: GUID-400c2c59-95e1-7bf3-4647-3a135281bfaf -->\n<!--labels: GUID-400c2c59-95e1-7bf3-4647-3a135281bfaf ac -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-68822563-d568-f418-38ae-f1c62cb4ac8d\">\n  <title>aaaa dddd</title>\n  <conbody>\n    <p conref=\"b.xml#b/p3\"/>\n  </conbody>\n</concept>\n\n<!--linted: 2019-07-07 at 20:33:58 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita -->\n<!--guid: GUID-68822563-d568-f418-38ae-f1c62cb4ac8d -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/a.xml -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 945 -->\n<!--project: all -->\n<!--title: aaaa dddd -->\n<!--definition: GUID-68822563-d568-f418-38ae-f1c62cb4ac8d -->\n<!--labels: GUID-68822563-d568-f418-38ae-f1c62cb4ac8d ad -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-96a20d7f-bbaf-deef-55ef-e09a0a059251\">\n  <title>bbbb</title>\n  <conbody>\n    <p id=\"p1\">1111</p>\n  </conbody>\n</concept>\n<!--linted: 2019-07-07 at 20:33:58 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita -->\n<!--guid: GUID-96a20d7f-bbaf-deef-55ef-e09a0a059251 -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/b.xml -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 945 -->\n<!--project: all -->\n<!--title: bbbb -->\n<!--definition: p1 -->\n<!--definition: GUID-96a20d7f-bbaf-deef-55ef-e09a0a059251 -->\n<!--labels: GUID-96a20d7f-bbaf-deef-55ef-e09a0a059251 b -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-86a684b0-1a0b-4c30-6da9-24c74ff1f0cc\">\n  <title>bbbb aaaa</title>\n  <conbody/>\n</concept>\n<!--linted: 2019-07-07 at 20:33:58 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita -->\n<!--guid: GUID-86a684b0-1a0b-4c30-6da9-24c74ff1f0cc -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/b.xml -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 945 -->\n<!--project: all -->\n<!--title: bbbb aaaa -->\n<!--definition: GUID-86a684b0-1a0b-4c30-6da9-24c74ff1f0cc -->\n<!--labels: GUID-86a684b0-1a0b-4c30-6da9-24c74ff1f0cc ba -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-cfe7cb3d-05e7-a147-db10-dcbacaeecef7\">\n  <title>bbbb bbbb</title>\n  <conbody>\n    <p id=\"p2\">2222</p>\n  </conbody>\n</concept>\n<!--linted: 2019-07-07 at 20:33:58 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita -->\n<!--guid: GUID-cfe7cb3d-05e7-a147-db10-dcbacaeecef7 -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/b.xml -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 945 -->\n<!--project: all -->\n<!--title: bbbb bbbb -->\n<!--definition: p2 -->\n<!--definition: GUID-cfe7cb3d-05e7-a147-db10-dcbacaeecef7 -->\n<!--labels: GUID-cfe7cb3d-05e7-a147-db10-dcbacaeecef7 bb -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/out/c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []>\n<concept id=\"GUID-2b6aab4f-9328-e326-f55f-160771a8c3dd\">\n  <title>bbbb cccc</title>\n  <conbody>\n    <p id=\"p3\">3333</p>\n  </conbody>\n</concept>\n<!--linted: 2019-07-07 at 20:33:58 -->\n<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->\n<!--ditaType: concept -->\n<!--docType: <!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Concept//EN\" \"concept.dtd\" []> -->\n<!--file: /home/phil/perl/cpan/DataEditXmlToDita/test/out/c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita -->\n<!--guid: GUID-2b6aab4f-9328-e326-f55f-160771a8c3dd -->\n<!--header: <?xml version=\"1.0\" encoding=\"UTF-8\"?> -->\n<!--inputFile: /home/phil/perl/cpan/DataEditXmlToDita/test/in/b.xml -->\n<!--lineNumber: Data::Edit::Xml::To::DitaVb /home/phil/perl/cpan/DataEditXmlToDita/lib/Data/Edit/Xml/To/DitaVb.pm 945 -->\n<!--project: all -->\n<!--title: bbbb cccc -->\n<!--definition: p3 -->\n<!--definition: GUID-2b6aab4f-9328-e326-f55f-160771a8c3dd -->\n<!--labels: GUID-2b6aab4f-9328-e326-f55f-160771a8c3dd bc -->\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/a.xml"                                         => "bless({\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/a.xml\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap\",\n  targetType => \"bookmap\",\n}, \"SourceToTarget\")",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/targets/b.xml"                                         => "bless({\n  source => \"/home/phil/perl/cpan/DataEditXmlToDita/test/in/b.xml\",\n  sourceDocType => \"concept\",\n  target => \"/home/phil/perl/cpan/DataEditXmlToDita/test/out/bm_b_d2806ba589f908da1106574afd9db642.ditamap\",\n  targetType => \"bookmap\",\n}, \"SourceToTarget\")",
  };

  changeFolderAndWriteFiles($f, $folder);                                       # Change folder and write files
 }

sub checkXrefStructure($$@)                                                     #P Check an output structure produced by Xrf
 {my ($x, $field, @folders) = @_;                                               # Cross references, field to check, folders to suppress
  my $s = nws dump($x->{$field});                                               # Structure to be tested
  for my $folder($x->inputFolder, @folders)                                     # Remove specified folder names from structure to be tested
   {$s =~ s($folder) ()gs;                                                      # Remove folder name from structure to be tested
   }
  eval $s;                                                                      # Recreate structure
 }

sub writeXrefStructureTest($$@)                                                 #P Write the test for an Xref structure
 {my ($x, $field, @folders) = @_;                                               # Cross referencer, field, names of the folders to suppress
  my $in = $x->inputFolder;
  my $s = nws(dump($x->{$field}) =~ s($in) ()gsr);                              # Field to be tested
     $s =~ s(\],\s+\[) (],\n    [)gs;
     $s =~ s(\},\s+\{) (},\n    {)gs;
  for my $folderName(@folders)                                                  # Remove specified folder names from structure to be tested
   {no strict qw(refs);
    my $folder = &{$folderName};                                                # Folder name
    $s =~ s($folder) ()gs;                                                      # Remove folder name from structure to be tested
   }

  my $f = join ', ', @folders;                                                  # Folders to remove
  my $t = <<END;                                                                # Format test
  is_deeply checkXrefStructure(\$x, q($field), $f), $s;
END

  say STDERR $t;                                                                # Write test
 }

#D
# podDocumentation
=pod

=encoding utf-8

=head1 Name

Data::Edit::Xml::Xref - Cross reference Dita XML, match topics and ameliorate missing references.

=head1 Synopsis

Check the references in a large corpus of Dita XML documents held in folder
L<inputFolder|/inputFolder> running processes in parallel where ever possible
to take advantage of multi-cpu computers:

  use Data::Edit::Xml::Xref;

  my $x = xref(inputFolder              => q(in),
               maximumNumberOfProcesses => 512,
               fixBadRefs               => 1,
               flattenFolder            => q(out2),
               matchTopics              => 0.9,
              );

The cross reference analysis can be requested as a L<status line|/statusLine>:

  ok nws($x->statusLine) eq nws(<<END);
Xref: 108 references fixed, 50 bad xrefs, 16 missing image files, 16 missing image references, 13 bad first lines, 13 bad second lines, 9 bad conrefs, 9 duplicate topic ids, 9 files with bad conrefs, 9 files with bad xrefs, 8 duplicate ids, 6 bad topicrefs, 6 files not referenced, 4 invalid guid hrefs, 2 bad book maps, 2 bad tables, 1 External xrefs with no format=html, 1 External xrefs with no scope=external, 1 file failed to parse, 1 href missing
END

Or as a tabular report:

  ok nws($x->statusTable) eq nws(<<END);
Xref:
    Count  Condition
 1    108  references fixed
 2     50  bad xrefs
 3     16  missing image files
 4     16  missing image references
 5     13  bad first lines
 6     13  bad second lines
 7      9  files with bad conrefs
 8      9  bad conrefs
 9      9  files with bad xrefs
10      9  duplicate topic ids
11      8  duplicate ids
12      6  bad topicrefs
13      6  files not referenced
14      4  invalid guid hrefs
15      2  bad book maps
16      2  bad tables
17      1  href missing
18      1  file failed to parse
19      1  External xrefs with no format=html
20      1  External xrefs with no scope=external
END

More detailed reports are produced in the L<reports|/reports> folder:

  $x->reports

and indexed by the L<reports> report:

  reports/reports.txt

which contains a list of all the L<reports> generated:

    Rows  Title                                                           File
 1     5  Attributes                                                      reports/count/attributes.txt
 2    13  Bad Xml line 1                                                  reports/bad/xmlLine1.txt
 3    13  Bad Xml line 2                                                  reports/bad/xmlLine2.txt
 4     9  Bad conRefs                                                     reports/bad/ConRefs.txt
 5     2  Bad external xrefs                                              reports/bad/externalXrefs.txt
 6    16  Bad image references                                            reports/bad/imageRefs.txt
 7     9  Bad topicrefs                                                   reports/bad/bookMapRefs.txt
 8    50  Bad xRefs                                                       reports/bad/XRefs.txt
 9     2  Bookmaps with errors                                            reports/bad/bookMap.txt
10     2  Document types                                                  reports/count/docTypes.txt
11     8  Duplicate id definitions within files                           reports/bad/idDefinitionsDuplicated.txt
12     3  Duplicate topic id definitions                                  reports/bad/topicIdDefinitionsDuplicated.txt
13     3  File extensions                                                 reports/count/fileExtensions.txt
14     1  Files failed to parse                                           reports/bad/parseFailed.txt
15     0  Files types                                                     reports/count/fileTypes.txt
16    16  Files whose short names are bi-jective with their md5 sums      reports/good/shortNameToMd5Sum.txt
17     0  Files whose short names are not bi-jective with their md5 sums  reports/bad/shortNameToMd5Sum.txt
18   108  Fixes Applied To Failing References                             reports/lists/referencesFixed.txt
19     0  Good bookmaps                                                   reports/good/bookMap.txt
20     9  Good conRefs                                                    reports/good/ConRefs.txt
21     5  Good topicrefs                                                  reports/good/bookMapRefs.txt
22     8  Good xRefs                                                      reports/good/XRefs.txt
23     1  Guid topic definitions                                          reports/lists/guidsToFiles.txt
24     2  Image files                                                     reports/good/imagesFound.txt
25     1  Missing hrefs                                                   reports/bad/missingHrefAttributes.txt
26    16  Missing image references                                        reports/bad/imagesMissing.txt
27     4  Possible improvements                                           reports/improvements.txt
28     2  Resolved GUID hrefs                                             reports/good/guidHrefs.txt
29     2  Tables with errors                                              reports/bad/tables.txt
30    23  Tags                                                            reports/count/tags.txt
31    11  Topic Reuses                                                    reports/lists/topicReuse.txt
32     0  Topic Reuses                                                    reports/lists/similar/byTitle.txt
33    16  Topics                                                          reports/lists/topics.txt
34    15  Topics with similar vocabulary                                  reports/lists/similar/byVocabulary.txt
35     0  Topics with validation errors                                   reports/bad/validationErrors.txt
36     0  Topics without ids                                              reports/bad/topicIdDefinitionsMissing.txt
37     6  Unreferenced files                                              reports/bad/notReferenced.txt
38    11  Unresolved GUID hrefs                                           reports/bad/guidHrefs.txt

=head2 Add navigation titles to topic references

Xref will create or update the navigation titles B<navtitles> of topic refs
B<appendix|chapter|topicref> in maps if requested by both file name and GUID
reference:

  addNavTitle => 1

Reports of successful updates will be written to:

  reports/good/navTitles.txt

Reports of unsuccessful updates will be written to:

  reports/bad/navTitles.txt

=head2 Fix bad references

It is often desirable to ameliorate unresolved Dita href attributes so that
incomplete content can be loaded into a content management system.  The:

  fixBadRefs => 1

attribute requests that the:

 conref and href

attributes be renamed to:

 xtrf

if the B<conref> or B<href> attribute specification cannot be resolved in the
current corpus.

If the L<fixedFolder|/fixedFolder> attribute is set, the fixed files are
written into this folder, else they are written back into the
L<inputFolder|/inputFolder>.  Two reports are generated by this action:

  reports/bad/fixedRefs.txt

  reports/bad/fixedRefsNoAction.txt

This feature designed by L<mailto:mim@cpan.org>.

=head2 Deguidize

Some content management systems use guids, some content management systems use
file names as their means of identifying content. When moving from a guid to a
file name content management system it might be necessary to replace the guids
representing file names with the actual underlying file names.  If the

  deguidize => 1

parameter is set to true, Xref will replace any such file guids with the
underlying file name if it is present in the content being cross referenced.

=head2 File flattening

It is often desirable to flatten or reflatten the topic files in a corpus so
that they can coexist in a single folder of a content management system without
colliding with each other.

The presence of the input attribute:

 flattenFolder => folder-to-flatten-files-into

causes topic files to be flattened into the named folder using the
L<GBStandard> to generate the flattened file names.  Xref will then update all
L<Dita> references to match these new file names.  If the L<flattenFolder>
folder is the same as the L<inputFolder> then the input files are flattened in
place.

=head2 Locating relocated files

File references in B<conref> or B<hrefs> that have a unique valid base file
name and an invalid path can be fixed by setting the input attribute:

 fixRelocatedRefs => 1

to a true value to request that Xref should replace the incorrect paths to the
unique bases file names with the correct path.

If coded in conjunction with the B<fixBadRefs> input attribute this will cause
Xref to first try and fix any missing xrefs, any that still fail to resolve
will then be ameliorated by moving them to the B<xtrf> attribute.

=head2 Fix Xrefs by Title

L<Dita> B<xref> tags with broken or missing B<href> attributes can sometimes be
fixed by matching the text content of the B<xref> with the titles of topics.

If:

  fixXrefsByTitle => 1

is specified, L<Xref> will locate possible targets for a broken B<href> by
matching the white space normalized L<Data::Table::Text::nws> of the text
content of the B<xref> with the similarly normalized title of each topic.  If a
single matching candidate is located then it will be used to update the B<href>
attribute of the B<xref>.

=head2 Fix References in Dita To Dita Conversions

When converting a L<Dita> input source corpus to L<Dita> the referenced topics
are usually renamed and flattened via the L<GBStandard>. If enabled:

  fixDitaRefs => targets/

updates valid L<Dita> references in the input corpus with the latest name for
the referenced topic to make links that were valid in the input corpus valid in
the output corpus as well.

The B<targets/> folder should contain the same set of file names as the
original input corpus, each such file should contain the name of a B<bookmap>
topic present in the B<inputFolder=> whose B<chapter> and B<topicref>s identify
the new names of the files cut out and flattened from the existing input
corpus.

The creation of the B<target/> folder is usually done by some other piece of
software such as L<Data::Edit::Xml::To::Dita> as it is too complex and
laborious to be performed reliably by hand.  No validation of the contents of
this folder is performed as it is assumed that it has been created reliably in
software.

=head2 Topic Matching

Topics can be matched on title and vocabulary to assist authors in finding
similar topics by specifying the:

  matchTopics => 0.9

attribute where the value of this attribute is the confidence level between 0
and 1.

Topic matching produces the reports:

  reports/lists/similar/byTitle.txt
  reports/lists/similar/byVocabulary.txt

Topic matching might take some time for large input folders.

=head3 Title matching

This report can be found at:

  reports/lists/similar/byTitle.txt

Title sorts topics by their titles so that topic with similar titles can be
easily located:

    Similar  Prefix        Source
 1       14  c_Notices__   c_Notices_5614e96c7a3eaf3dfefc4a455398361b
 2           c_Notices__   c_Notices_14a9f467215dea879d417de884c21e6d
 3           c_Notices__   c_Notices_19011759a2f768d76581dc3bba170a44
 4           c_Notices__   c_Notices_aa741e6223e6cf8bc1a5ebdcf0ba867c
 5           c_Notices__   c_Notices_f0009b28c3c273094efded5fac32b83f
 6           c_Notices__   c_Notices_b1480ac1af812da3945239271c579bb1
 7           c_Notices__   c_Notices_5f3aa15d024f0b6068bd8072d4942f6d
 8           c_Notices__   c_Notices_17c1f39e8d70c765e1fbb6c495bedb03
 9           c_Notices__   c_Notices_7ea35477554f979b3045feb369b69359
10           c_Notices__   c_Notices_4f200259663703065d247b35d5500e0e
11           c_Notices__   c_Notices_e3f2eb03c23491c5e96b08424322e423
12           c_Notices__   c_Notices_06b7e9b0329740fc2b50fedfecbc5a94
13           c_Notices__   c_Notices_550a0d84dfc94982343f58f84d1c11c2
14           c_Notices__   c_Notices_fa7e563d8153668db9ed098d0fe6357b
15        3  c_Overview__  c_Overview_f9e554ee9be499368841260344815f58
16           c_Overview__  c_Overview_f234dc10ea3f4229d0e1ab4ad5e8f5fe
17           c_Overview__  c_Overview_96121d7bcd41cf8be318b96da0049e73


=head3 Vocabulary matching

This report can be found at:

  reports/lists/similar/byVocabulary.txt

Vocabulary matching compares the vocabulary of pairs of topics: topics with
similar vocabularies within the confidence level specified are reported
together:

    Similar  Topic
 1        8  in/1.dita
 2           in/2.dita
 3           in/3.dita
 4           in/4.dita
 5           in/5.dita
 6           in/6.dita
 7           in/7.dita
 8           in/8.dita
 9
10        2  in/map/bookmap.ditamap
11           in/map/bookmap2.ditamap
12
13        2  in/act4. dita
14           in/act5.dita

=head1 Description

Cross reference Dita XML, match topics and ameliorate missing references.


Version 20190708.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Cross reference

Check the cross references in a set of Dita files and report the results.

=head2 xref(%)

Check the cross references in a set of Dita files held in  L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder. The possible attributes are defined in L<Data::Edit::Xml::Xref|/Data::Edit::Xml::Xref>

     Parameter                 Description
  1  {my $xref = newXref(@_);  Create the cross referencer

B<Example:>


  if (1)                                                                           References from a topic that has been cut out to a topic that has been cut out
   {clearFolder(tests, 111);
    createTestReferenceToCutOutTopic(tests);
  
    my $x = 𝘅𝗿𝗲𝗳(inputFolder => out, fixDitaRefs => targets);
    ok $x->statusLine eq q(Xref: 1 ref);
  
    is_deeply checkXrefStructure($x, q(inputFileToTargetTopics),          in, targets), { "a.xml" => { "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita" => 1, "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => 1, "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => 1, "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => 1, }, "b.xml" => { "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita" => 1, "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => 1, "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => 1, "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => 1, }, };
    is_deeply checkXrefStructure($x, q(targetTopicToInputFiles),          in, targets), { "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita" => { "a.xml" => 1, }, "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => { "a.xml" => 1, }, "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => { "a.xml" => 1, }, "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => { "a.xml" => 1, }, "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita" => { "b.xml" => 1, }, "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => { "b.xml" => 1, }, "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => { "b.xml" => 1, }, "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => { "b.xml" => 1, }, };
    is_deeply checkXrefStructure($x, q(sourceTopicToTargetBookMap),       in, targets), { "a.xml" => bless({ source => "a.xml", sourceDocType => "concept", target => "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap", targetType => "bookmap", }, "Bookmap"), "b.xml" => bless({ source => "b.xml", sourceDocType => "concept", target => "bm_b_d2806ba589f908da1106574afd9db642.ditamap", targetType => "bookmap", }, "Bookmap"), };
    is_deeply checkXrefStructure($x, q(topicFlattening),                  in, targets), {};
    is_deeply checkXrefStructure($x, q(originalSourceFileAndIdToNewFile), in, targets), { "a.xml" => { "GUID-400c2c59-95e1-7bf3-4647-3a135281bfaf" => "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita", "GUID-68822563-d568-f418-38ae-f1c62cb4ac8d" => "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita", "GUID-c67821ef-3da2-c89f-0fc9-9fba3937f368" => "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita", "GUID-f0c0e170-8128-10ef-045d-97602fdde76f" => "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita", }, "b.xml" => { "GUID-2b6aab4f-9328-e326-f55f-160771a8c3dd" => "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita", "GUID-86a684b0-1a0b-4c30-6da9-24c74ff1f0cc" => "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita", "GUID-96a20d7f-bbaf-deef-55ef-e09a0a059251" => "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita", "GUID-cfe7cb3d-05e7-a147-db10-dcbacaeecef7" => "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita", "p1" => "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita", "p2" => "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita", "p3" => "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita", }, };
   }
  

=head1 Create test data

Create files to test the various capabilities provided by Xref


=head2 Data::Edit::Xml::Xref Definition


Attributes used by the Xref cross referencer.




=head3 Input fields


B<addNavTitles> - If true, add navtitle to outgoing bookmap references to show the title of the target topic.

B<changeBadXrefToPh> - Change xrefs being placed in B<M3> by L<fixBadRefs> to B<ph>.

B<deguidize> - Set true to replace guids in dita references with file name. Given reference B<g1#g2/id> convert B<g1> to a file name by locating the topic with topicId B<g2>.  This requires the guids to be genuinely unique. SDL guids are thought to be unique by language code but the same topic, translated to a different language might well have the same guid as the original topic with a different language code: =(de|en|es|fr).  If the source is in just one language then the guid uniqueness is a reasonable assumption.  If the conversion can be done in phases by language then the uniqueness of guids is again reasonably assured. L<Data::Edit::Xml::Lint> provides an alternative solution to deguidizing by using labels to record the dita reference in the input corpus for each id encountered, these references can then be resolved in the usual manner by L<Data::Edit::Xml::Lint::relint>.

B<fixBadRefs> - Try to fix bad references in L<these files|/fixRefs> where possible by either changing a guid to a file name assuming the right file is present in the corpus being scanned and L<deguidize|/deguidize> has been set true or failing that by moving the failing reference to the B<xtrf> attribute i.e. placing it in B<M3> possibly renaming the tag to B<ph> if L<changeBadXrefToPh> is in effect.

B<fixDitaRefs> - Fix references in a corpus of L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> documents that have been converted to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> and whose target structure has been written to the named folder.

B<fixRelocatedRefs> - Fix references to topics that have been moved around in the out folder structure assuming that all file names are unique.

B<fixXrefsByTitle> - Try to fix invalid xrefs by the Gearhart Title Method if true

B<flattenFolder> - Files are renamed to the Gearhart standard and placed in this folder if set.  References to the unflattened files are updated to references to the flattened files.  This option will eventually be deprecated as the Dita::GB::Standard is now fully available allowing files to be easily flattened before being processed by Xref.

B<inputFolder> - A folder containing the dita and ditamap files to be cross referenced.

B<matchTopics> - Match topics by title and by vocabulary to the specified confidence level between 0 and 1.  This operation might take some time to complete on a large corpus.

B<maxZoomIn> - Optional hash of names to regular expressions to look for in each file

B<maximumNumberOfProcesses> - Maximum number of processes to run in parallel at any one time.

B<printSummaryLine> - Print the summary line if true - on by default.

B<reports> - Reports folder: the cross referencer will write reports to files in this folder.

B<requestAttributeNameAndValueCounts> - Report attribute name and value counts



=head3 Output fields


B<allowUniquePartialMatches> - Allow unique partial matches - i.e ignore the stuff to the right of the # in a reference if doing so produces a unique result. This feature has been explicitly disabled for conrefs (PS2-561) and might need to be disabled for other types of reference as well.

B<attributeCount> - Make input folder absolute                      # {file}{attribute name} == count of the different xml attributes found in the xml files.

B<attributeNamesAndValuesCount> - {file}{attribute name}{value} = count

B<author> - {file} = author of this file.

B<badGuidHrefs> - Bad conrefs - all.

B<badNavTitles> - Details of nav titles that were not resolved

B<badReferencesCount> - The number of bad references encountered

B<badTables> - Array of tables that need fixing.

B<badXml1> - [Files] with a bad xml encoding header on the first line.

B<badXml2> - [Files] with a bad xml doc type on the second line.

B<baseTag> - Base Tag for each file

B<bookMapRefs> - {bookmap full file name}{href}{navTitle}++ References from bookmaps to topics via appendix, chapter, bookmapref.

B<conRefs> - {file}{href}   Count of conref definitions in each file.

B<currentFolder> - The current working folder used to make absolute file names from relative ones

B<docType> - {file} == docType:  the docType for each xml file.

B<duplicateIds> - [file, id]     Duplicate id definitions within each file.

B<duplicateTopicIds> - [topicId, [files]] Files with duplicate topic ids - the id on the outermost tag.

B<fileExtensions> - Default file extensions to load

B<fixRefs> - {file}{ref} where the href or conref target is not valid.

B<fixedFolder> - Fixed files are placed in this folder if L<fixBadRefs|/fixBadRefs> has been specified.

B<fixedRefs> - [] hrefs and conrefs from L<fixRefs|/fixRefs> which were invalid but have been fixed by L<deguidizing|/deguidize> them to a valid file name.

B<fixedRefsFailed> - [] hrefs and conrefs from L<fixRefs|/fixRefs> which were moved to the "xtrf" attribute as requested by the L<fixBadHrefs|/fixBadHrefs> attribute because the reference was invalid and could not be improved by L<deguidization|/deguidize>.

B<fixedRefsGB> - [] files fixed to the Gearhart-Brenan file naming standard

B<fixedRefsNoAction> - [] hrefs and conrefs from L<fixRefs|/fixRefs> for which no action was taken.

B<flattenFiles> - {old full file name} = file renamed to Gearhart-Brenan file naming standard

B<goodNavTitles> - Details of nav titles that were resolved

B<guidHrefs> - {file}{href} = location where href starts with GUID- and is thus probably a guid.

B<guidToFile> - {topic id which is a guid} = file defining topic id.

B<hrefUrlEncoding> - Hrefs that need url encoding because they contain white space

B<ids> - {file}{id}     Id definitions across all files.

B<images> - {file}{href}   Count of image references in each file.

B<imagesReferencedFromBookMaps> - {bookmap full file name}{full name of image referenced from topic referenced from bookmap}++

B<imagesReferencedFromTopics> - {topic full file name}{full name of image referenced from topic}++

B<improvements> - Suggested improvements - a list of improvements that might be made.

B<inputFileToTargetTopics> - {input file}{target file}++ : Tells us the topics an input file was split into

B<inputFiles> - Input files from L<inputFolder|/inputFolder>.

B<inputFolderImages> - {full image file name} for all files in input folder thus including any images resent

B<ltgt> - {text between &lt; and &gt}{filename} = count giving the count of text items found between &lt; and &gt;

B<maxZoomOut> - Results from L<maxZoomIn|/maxZoomIn>  where {file name}{regular expression key name in L<maxZoomIn|/maxZoomIn>}++

B<md5Sum> - MD5 sum for each input file.

B<missingImageFiles> - [file, href] == Missing images in each file.

B<missingTopicIds> - Missing topic ids.

B<noHref> - Tags that should have an href but do not have one.

B<notReferenced> - {file name} Files in input area that are not referenced by a conref, image, bookmapref or xref tag and are not a bookmap.

B<olBody> - The number of ol under body by file

B<originalSourceFileAndIdToNewFile> - {original file}{id} = new file: Record mapping from original source file and id to the new file containing the id

B<parseFailed> - {file} files that failed to parse.

B<references> - {file}{reference}++ - the various references encountered

B<relocatedReferencesFailed> - Failing references that were not fixed by relocation

B<relocatedReferencesFixed> - Relocated references fixed

B<results> - Summary of results table.

B<sourceFile> - The source file from which this structure was generated.

B<sourceTopicToTargetBookMap> - {input topic cut into multiple pieces} = output bookmap representing pieces

B<statusLine> - Status line summarizing the cross reference.

B<statusTable> - Status table summarizing the cross reference.

B<tagCount> - {file}{tags} == count of the different tag names found in the xml files.

B<tags> - Number of tags encountered

B<tagsTextsRatio> - Ratio of tags to text encountered

B<targetFolderContent> - {file} = bookmap file name : the target folder content which shows us where an input file went

B<targetTopicToInputFiles> - {current file} = the source file from which the current file was obtained

B<texts> - Number of texts encountered

B<timeEnded> - Time the run ended

B<timeStart> - Time the run started

B<title> - {file} = title of file.

B<titleToFile> - {title}{file}++ if L<fixXrefsByTitle> is in effect

B<topicFlattening> - {topic}{sources}++ : the source files for each topic that was flattened

B<topicFlatteningFactor> - Topic flattening factor - higher is better

B<topicIds> - {file} = topic id - the id on the outermost tag.

B<topicsFlattened> - Number of topics flattened

B<topicsReferencedFromBookMaps> - {bookmap file, file name}{topic full file name}++

B<validationErrors> - True means that Lint detected errors in the xml contained in the file.

B<vocabulary> - The text of each topic shorn of attributes for vocabulary comparison.

B<xRefs> - {file}{href}++ Xrefs references.

B<xrefBadFormat> - External xrefs with no format=html.

B<xrefBadScope> - External xrefs with no scope=external.

B<xrefsFixedByTitle> - Xrefs fixed by locating a matching topic title from their text content.



=head1 Private Methods

=head2 newXref(%)

Create a new cross referencer

     Parameter    Description
  1  %attributes  Attributes

=head2 countLevels($$)

Count has elements to the specified number of levels

     Parameter  Description
  1  $l         Levels
  2  $h         Hash

=head2 externalReference($)

Check for an external reference

     Parameter   Description
  1  $reference  Reference to check

=head2 loadInputFiles($)

Load the names of the files to be processed

     Parameter  Description
  1  $xref      Cross referencer

=head2 analyzeOneFile($$)

Analyze one input file

     Parameter  Description
  1  $Xref      Xref request
  2  $iFile     File to analyze

=head2 reportGuidsToFiles($)

Map and report guids to files

     Parameter  Description
  1  $xref      Xref results

=head2 editXml($$$)

Edit an xml file

     Parameter  Description
  1  $in        Input file
  2  $out       Output file
  3  $x         Parse tree

=head2 fixReferencesInOneFile($$)

Fix one file by moving unresolved references to the xtrf attribute

     Parameter    Description
  1  $xref        Xref results
  2  $sourceFile  Source file to fix

=head2 fixReferences($)

Fix just the file containing references using a number of techniques and report those references that cannot be so fixed.

     Parameter  Description
  1  $xref      Xref results

=head2 fixOneFileGB($$)

Fix one file to the Gearhart-Brenan standard

     Parameter  Description
  1  $xref      Xref results
  2  $file      File to fix

=head2 fixFilesGB($)

Rename files to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>

     Parameter  Description
  1  $xref      Xref results

=head2 analyzeInputFiles($)

Analyze the input files

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportDuplicateIds($)

Report duplicate ids

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportDuplicateTopicIds($)

Report duplicate topic ids

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportNoHrefs($)

Report locations where an href was expected but not found

     Parameter  Description
  1  $xref      Cross referencer

=head2 checkReferences($)

Check each reference, report bad references and mark them for fixing.

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportGuidHrefs($)

Report on guid hrefs

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportImages($)

Reports on images and references to images

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportParseFailed($)

Report failed parses

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportXml1($)

Report bad xml on line 1

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportXml2($)

Report bad xml on line 2

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportDocTypeCount($)

Report doc type count

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportTagCount($)

Report tag counts

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportTagsAndTextsCount($)

Report tags and texts counts

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportLtGt($)

Report items found between &lt; and &gt;

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportAttributeCount($)

Report attribute counts

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportAttributeNameAndValueCounts($)

Report attribute value counts

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportValidationErrors($)

Report the files known to have validation errors

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportTables($)

Report on tables that have problems

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportFileExtensionCount($)

Report file extension counts

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportFileTypes($)

Report file type counts - takes too long in series

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportExternalXrefs($)

Report external xrefs missing other attributes

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportPossibleImprovements($)

Report improvements possible

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportMaxZoomOut($)

Text located via Max Zoom In

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportTopicDetails($)

Things that occur once in each file

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportTopicReuse($)

Count how frequently each topic is reused

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportFixRefs($)

Report of hrefs that need to be fixed

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportSourceFiles($)

Source file for each topic

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportReferencesFromBookMaps($)

Topics and images referenced from bookmaps

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportSimilarTopicsByTitle($)

Report topics likely to be similar on the basis of their titles as expressed in the non Guid part of their file names

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportSimilarTopicsByVocabulary($)

Report topics likely to be similar on the basis of their vocabulary

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportMd5Sum($)

Good files have short names which uniquely represent their content and thus can be used instead of their md5sum to generate unique names

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportOlBody($)

ol under body - indicative of a task

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportHrefUrlEncoding($)

href needs url encoding

     Parameter  Description
  1  $xref      Cross referencer

=head2 addNavTitlesToOneMap($$)

Fix navtitles in one map

     Parameter  Description
  1  $xref      Xref results
  2  $file      File to fix

=head2 addNavTitlesToMaps($)

Add nav titles to files containing maps.

     Parameter  Description
  1  $xref      Xref results

=head2 oneBadRef($$$)

Check one reference and return the first error encountered or B<undef> if no errors encountered. Relies on L<topicIds> to test files present and test the B<topicId> is valid, relies on L<ids> to check that the referenced B<id> is valid.

     Parameter  Description
  1  $xref      Cross referencer
  2  $file      File containing reference
  3  $href      Reference

=head2 createSampleInputFiles($$)

Create sample input files for testing. The attribute B<inputFolder> supplies the name of the folder in which to create the sample files.

     Parameter  Description
  1  $in        Input folder
  2  $N         Number of sample files

=head2 createSampleInputFilesFixFolder($)

Create sample input files for testing fixFolder

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createSampleInputFilesLtGt($)

Create sample input files for testing items between &lt; and &gt;

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createSampleInputFilesForFixDitaRefs($$)

Create sample input files for fixing renamed topic refs

     Parameter  Description
  1  $in        Folder to create the files in
  2  $targets   Targets folder

=head2 createSampleInputFilesForFixDitaRefsXref($)

Create sample input files for fixing references into renamed topics by xref

     Parameter  Description
  1  $in        Folder to create the files in

=head2 changeFolderAndWriteFiles($$)

Change file structure to the current folder and write

     Parameter  Description
  1  $f         Data structure as a string
  2  $D         Target folder

=head2 createSampleInputFilesForFixDitaRefsImproved1($)

Create sample input files for fixing references via the targets/ folder

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createSampleInputFilesForFixDitaRefsImproved2($)

Create sample input files for fixing conref references via the targets/ folder

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createSampleInputFilesForFixDitaRefsImproved3($)

Create sample input files for fixing bookmap references to topics that get cut into multiple pieces

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createSampleInputFilesForFixDitaRefsImproved4($)

Create sample input files for fixing bookmap reference to a topic that did not get cut into  multiple pieces

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createSampleImageTest($)

Create sample input files for fixing bookmap reference to a topic that did not get cut into  multiple pieces

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createTestTopicFlattening($)

Create sample input files for testing topic flattening ratio reporting

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createTestReferencedToFlattenedTopic($)

Full reference to a topic that has been flattened

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createTestReferenceToCutOutTopic($)

References from a topic that has been cut out to a topic that has been cut out

     Parameter  Description
  1  $folder    Folder to switch to

=head2 checkXrefStructure($$@)

Check an output structure produced by Xrf

     Parameter  Description
  1  $x         Cross references
  2  $field     Field to check
  3  @folders   Folders to suppress

=head2 writeXrefStructureTest($$@)

Write the test for an Xref structure

     Parameter  Description
  1  $x         Cross referencer
  2  $field     Field
  3  @folders   Names of the folders to suppress


=head1 Index


1 L<addNavTitlesToMaps|/addNavTitlesToMaps> - Add nav titles to files containing maps.

2 L<addNavTitlesToOneMap|/addNavTitlesToOneMap> - Fix navtitles in one map

3 L<analyzeInputFiles|/analyzeInputFiles> - Analyze the input files

4 L<analyzeOneFile|/analyzeOneFile> - Analyze one input file

5 L<changeFolderAndWriteFiles|/changeFolderAndWriteFiles> - Change file structure to the current folder and write

6 L<checkReferences|/checkReferences> - Check each reference, report bad references and mark them for fixing.

7 L<checkXrefStructure|/checkXrefStructure> - Check an output structure produced by Xrf

8 L<countLevels|/countLevels> - Count has elements to the specified number of levels

9 L<createSampleImageTest|/createSampleImageTest> - Create sample input files for fixing bookmap reference to a topic that did not get cut into  multiple pieces

10 L<createSampleInputFiles|/createSampleInputFiles> - Create sample input files for testing.

11 L<createSampleInputFilesFixFolder|/createSampleInputFilesFixFolder> - Create sample input files for testing fixFolder

12 L<createSampleInputFilesForFixDitaRefs|/createSampleInputFilesForFixDitaRefs> - Create sample input files for fixing renamed topic refs

13 L<createSampleInputFilesForFixDitaRefsImproved1|/createSampleInputFilesForFixDitaRefsImproved1> - Create sample input files for fixing references via the targets/ folder

14 L<createSampleInputFilesForFixDitaRefsImproved2|/createSampleInputFilesForFixDitaRefsImproved2> - Create sample input files for fixing conref references via the targets/ folder

15 L<createSampleInputFilesForFixDitaRefsImproved3|/createSampleInputFilesForFixDitaRefsImproved3> - Create sample input files for fixing bookmap references to topics that get cut into multiple pieces

16 L<createSampleInputFilesForFixDitaRefsImproved4|/createSampleInputFilesForFixDitaRefsImproved4> - Create sample input files for fixing bookmap reference to a topic that did not get cut into  multiple pieces

17 L<createSampleInputFilesForFixDitaRefsXref|/createSampleInputFilesForFixDitaRefsXref> - Create sample input files for fixing references into renamed topics by xref

18 L<createSampleInputFilesLtGt|/createSampleInputFilesLtGt> - Create sample input files for testing items between &lt; and &gt;

19 L<createTestReferencedToFlattenedTopic|/createTestReferencedToFlattenedTopic> - Full reference to a topic that has been flattened

20 L<createTestReferenceToCutOutTopic|/createTestReferenceToCutOutTopic> - References from a topic that has been cut out to a topic that has been cut out

21 L<createTestTopicFlattening|/createTestTopicFlattening> - Create sample input files for testing topic flattening ratio reporting

22 L<editXml|/editXml> - Edit an xml file

23 L<externalReference|/externalReference> - Check for an external reference

24 L<fixFilesGB|/fixFilesGB> - Rename files to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>

25 L<fixOneFileGB|/fixOneFileGB> - Fix one file to the Gearhart-Brenan standard

26 L<fixReferences|/fixReferences> - Fix just the file containing references using a number of techniques and report those references that cannot be so fixed.

27 L<fixReferencesInOneFile|/fixReferencesInOneFile> - Fix one file by moving unresolved references to the xtrf attribute

28 L<loadInputFiles|/loadInputFiles> - Load the names of the files to be processed

29 L<newXref|/newXref> - Create a new cross referencer

30 L<oneBadRef|/oneBadRef> - Check one reference and return the first error encountered or B<undef> if no errors encountered.

31 L<reportAttributeCount|/reportAttributeCount> - Report attribute counts

32 L<reportAttributeNameAndValueCounts|/reportAttributeNameAndValueCounts> - Report attribute value counts

33 L<reportDocTypeCount|/reportDocTypeCount> - Report doc type count

34 L<reportDuplicateIds|/reportDuplicateIds> - Report duplicate ids

35 L<reportDuplicateTopicIds|/reportDuplicateTopicIds> - Report duplicate topic ids

36 L<reportExternalXrefs|/reportExternalXrefs> - Report external xrefs missing other attributes

37 L<reportFileExtensionCount|/reportFileExtensionCount> - Report file extension counts

38 L<reportFileTypes|/reportFileTypes> - Report file type counts - takes too long in series

39 L<reportFixRefs|/reportFixRefs> - Report of hrefs that need to be fixed

40 L<reportGuidHrefs|/reportGuidHrefs> - Report on guid hrefs

41 L<reportGuidsToFiles|/reportGuidsToFiles> - Map and report guids to files

42 L<reportHrefUrlEncoding|/reportHrefUrlEncoding> - href needs url encoding

43 L<reportImages|/reportImages> - Reports on images and references to images

44 L<reportLtGt|/reportLtGt> - Report items found between &lt; and &gt;

45 L<reportMaxZoomOut|/reportMaxZoomOut> - Text located via Max Zoom In

46 L<reportMd5Sum|/reportMd5Sum> - Good files have short names which uniquely represent their content and thus can be used instead of their md5sum to generate unique names

47 L<reportNoHrefs|/reportNoHrefs> - Report locations where an href was expected but not found

48 L<reportOlBody|/reportOlBody> - ol under body - indicative of a task

49 L<reportParseFailed|/reportParseFailed> - Report failed parses

50 L<reportPossibleImprovements|/reportPossibleImprovements> - Report improvements possible

51 L<reportReferencesFromBookMaps|/reportReferencesFromBookMaps> - Topics and images referenced from bookmaps

52 L<reportSimilarTopicsByTitle|/reportSimilarTopicsByTitle> - Report topics likely to be similar on the basis of their titles as expressed in the non Guid part of their file names

53 L<reportSimilarTopicsByVocabulary|/reportSimilarTopicsByVocabulary> - Report topics likely to be similar on the basis of their vocabulary

54 L<reportSourceFiles|/reportSourceFiles> - Source file for each topic

55 L<reportTables|/reportTables> - Report on tables that have problems

56 L<reportTagCount|/reportTagCount> - Report tag counts

57 L<reportTagsAndTextsCount|/reportTagsAndTextsCount> - Report tags and texts counts

58 L<reportTopicDetails|/reportTopicDetails> - Things that occur once in each file

59 L<reportTopicReuse|/reportTopicReuse> - Count how frequently each topic is reused

60 L<reportValidationErrors|/reportValidationErrors> - Report the files known to have validation errors

61 L<reportXml1|/reportXml1> - Report bad xml on line 1

62 L<reportXml2|/reportXml2> - Report bad xml on line 2

63 L<writeXrefStructureTest|/writeXrefStructureTest> - Write the test for an Xref structure

64 L<xref|/xref> - Check the cross references in a set of Dita files held in  L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Data::Edit::Xml::Xref

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
use Test::More;
use warnings FATAL=>qw(all);
use strict;

if ($^O =~ m(bsd|linux)i)
 {plan tests => 66;
 }
else
 {plan skip_all => 'Not supported';
 }

Test::More->builder->output("/dev/null")                                        # Show only errors during testing
  if ((caller(1))[0]//'Data::Edit::Xml::Xref') eq "Data::Edit::Xml::Xref";

#goto latestTest;

sub tests      {fpd currentDirectory, q(test)}                                  # Tests folder
sub in         {fpd tests, q(in)}                                               # Input folder
sub out        {fpd tests, q(out)}                                              # Output folder
sub outFixed   {fpd tests, q(outFixed)}                                         # Fixed output folder
sub reports    {fpd tests, q(report)}                                           # Reports folder
sub targets    {fpf(tests, q(targets))}                                         # Tests targets folder

sub testReferenceChecking                                                       # Test reference checking
 {my $folder = q(/home/phil/);
  my @names  = qw(aaa bbb ccc);
  my @ids    = map {q(p).$_}                   @names;
  my @files  = map {fpe($folder, $_, q(dita))} @names;

  my $xref = newXref
   (currentFolder  => q(/aaa),
    reports        => fpd(currentDirectory, qw(test resports)),
    topicIds       => {map {$files[$_]=>$names[$_]}      0..$#names},
    ids            => {map {$files[$_]=>{$ids[$_]=>1}}    0..$#names},
   );

  for my $i(0..$#names)                                                         # Create some references
   {my $j = ($i + 1) % $#names;
    $xref->references->{$files[0]}{q(../phil/).$names[$i].q(.dita#).$names[$i].q(/).$ids[$i]}++;
    $xref->references->{$files[1]}{q(../phil/).$names[$i].q(.dita#).$names[$i].q(/).$ids[$j]}++;
    $xref->references->{$files[2]}{q(../phil/).$names[$i].q(.dita#).$names[$j].q(/).$ids[$i]}++;
   }

  ok !oneBadRef($xref, q(/home/phil/aaa.dita), q(../phil/bbb.dita#bbb/pbbb));   # Test reference checking
  ok !oneBadRef($xref, q(/home/phil/aaa.dita), q(../phil/bbb.dita));
  ok !oneBadRef($xref, q(/home/phil/aaa.dita), q(#aaa/paaa));
  ok !oneBadRef($xref, q(/home/phil/aaa.dita), q(#./paaa));
  ok !oneBadRef($xref, q(/home/phil/aaa.dita), q(#aaa));

  is_deeply oneBadRef($xref, q(/home/phil/aaa.dita), q(../phil/bbb.dita#bbb/pccc)),
   ["No such id in target topic",
    "../phil/bbb.dita#bbb/pccc",
    "/home/phil/bbb.dita",
    "bbb",
    "pccc",
    "aaa",
    "bbb",
    "/home/phil/aaa.dita",
    "/home/phil/bbb.dita",
  ];
  is_deeply oneBadRef($xref, q(/home/phil/aaa.dita), q(../phil/bbb.dita#aaa/pbbb)),
   ["Topic id does not match",
    "../phil/bbb.dita#aaa/pbbb",
    "/home/phil/bbb.dita",
    "aaa",
    "pbbb",
    "aaa",
    "bbb",
    "/home/phil/aaa.dita",
    "/home/phil/bbb.dita",
  ];
  is_deeply oneBadRef($xref, q(/home/phil/aaa.dita), q(../phil/ddd.dita#bbb/pbbb)),
   ["No such file",
    "../phil/ddd.dita#bbb/pbbb",
    "/home/phil/ddd.dita",
    "bbb",
    "pbbb",
    "aaa",
    undef,
    "/home/phil/aaa.dita",
    "/home/phil/ddd.dita",
  ];
  is_deeply oneBadRef($xref, q(/home/phil/aaa.dita), q(../phil/ddd.dita)),
  [ "No such file",
    "../phil/ddd.dita",
    "../phil/ddd.dita",
    "",
    "",
    "",
    "",
    "/home/phil/aaa.dita",
    "/home/phil/ddd.dita",
  ];
  is_deeply oneBadRef($xref, q(/home/phil/aaa.dita), q(#./pbbb)),
   ["No such id in target topic",
    "#./pbbb",
    "/home/phil/aaa.dita",
    "aaa",
    "pbbb",
    "aaa",
    "aaa",
    "/home/phil/aaa.dita",
    "/home/phil/aaa.dita",
  ];
  is_deeply oneBadRef($xref, q(/home/phil/aaa.dita), q(#bbb/pbbb)),
   ["Topic id does not match",
    "#bbb/pbbb",
    "/home/phil/aaa.dita",
    "bbb",
    "pbbb",
    "aaa",
    "aaa",
    "/home/phil/aaa.dita",
    "/home/phil/aaa.dita",
  ];
  is_deeply oneBadRef($xref, q(/home/phil/aaa.dita), q(#bbb)),
   ["Topic id does not match",
    "#bbb",
    "/home/phil/aaa.dita",
    "bbb",
    "",
    "aaa",
    "aaa",
    "/home/phil/aaa.dita",
    "/home/phil/aaa.dita",
  ];

 checkReferences($xref);                                                        # Report fixes required

 is_deeply $xref->fixRefs,
  {"/home/phil/bbb.dita" => {
                              "../phil/aaa.dita#aaa/pbbb" => 1,
                              "../phil/bbb.dita#bbb/paaa" => 1,
                              "../phil/ccc.dita#ccc/pbbb" => 1,
                            },
   "/home/phil/ccc.dita" => {
                              "../phil/aaa.dita#bbb/paaa" => 1,
                              "../phil/bbb.dita#aaa/pbbb" => 1,
                              "../phil/ccc.dita#bbb/pccc" => 1,
                            },
 };


 } # testReferenceChecking

&testReferenceChecking;

if (1) {                                                                        # Fix xrefs by title  - there should be just one so fixed
  clearFolder($_, 420) for in, out, reports;
  createSampleInputFiles(in, 8);

  my $x = xref(inputFolder     => in);

  ok $x->statusLine eq q(Xref: 112 refs, 21 image refs, 14 first lines, 14 second lines, 12 duplicate topic ids, 8 duplicate ids, 4 invalid guid hrefs, 2 tables, 1 External xrefs with no format=html, 1 External xrefs with no scope=external, 1 file failed to parse, 1 href missing);

  my $y = xref(inputFolder     => in, fixXrefsByTitle =>  1);                   # Update error counts

  ok $y->statusLine eq q(Xref: 111 refs, 21 image refs, 14 first lines, 14 second lines, 12 duplicate topic ids, 8 duplicate ids, 4 invalid guid hrefs, 2 tables, 1 External xrefs with no format=html, 1 External xrefs with no scope=external, 1 file failed to parse, 1 href missing);

  is_deeply checkXrefStructure($y, q(fixedRefs)),
   [["Fixed by title", "xref", "href", "act1.dita#c1/title", "act2.dita"]];
 }

if (1)
 {clearFolder($_, 420) for in, out, reports;
  createSampleInputFiles(in, 8);

  my $x = xref(inputFolder => in);
  ok $x->statusLine eq q(Xref: 112 refs, 21 image refs, 14 first lines, 14 second lines, 12 duplicate topic ids, 8 duplicate ids, 4 invalid guid hrefs, 2 tables, 1 External xrefs with no format=html, 1 External xrefs with no scope=external, 1 file failed to parse, 1 href missing);

  is_deeply checkXrefStructure($x, q(topicsReferencedFromBookMaps)),
    {
      "act2.dita"            => { "act1.dita" => 1, "act9999.dita" => 1 },
      "map/bookmap.ditamap"  => {
                                   "act1.dita"     => 1,
                                   "act2.dita"     => 1,
                                   "map/9999.dita" => 1,
                                   "map/bbb.txt"   => 1,
                                   "map/r.txt"     => 1,
                                   "map/yyyy.dita" => 1,
                                 },
      "map/bookmap2.ditamap" => {
                                   "act1.dita"     => 1,
                                   "act2.dita"     => 1,
                                   "map/9999.dita" => 1,
                                   "map/bbb.txt"   => 1,
                                   "map/r.txt"     => 1,
                                   "map/zzzz.dita" => 1,
                                 },
      "map/bookmap3.ditamap" => { "act3.dita" => 1, "act4.dita" => 1, "act5.dita" => 1 },
    };

  is_deeply checkXrefStructure($x, q(imagesReferencedFromBookMaps)),
   {"act2.dita" => {
       "act1.png"  => 1,
       "act2.png"  => 1,
       "guid-000"  => 1,
       "guid-9999" => 1,
       "guid-act1" => 1,
     },
     "map/bookmap.ditamap" => {
       "act1.png"  => 1,
       "act2.png"  => 1,
       "guid-000"  => 1,
       "guid-9999" => 1,
       "guid-act1" => 1,
     },
     "map/bookmap2.ditamap" => {
       "act1.png"  => 1,
       "act2.png"  => 1,
       "guid-000"  => 1,
       "guid-9999" => 1,
       "guid-act1" => 1,
     },
   };
 }

if (1)                                                                          # Check topic matching
 {clearFolder($_, 420) for in, out, reports;
  createSampleInputFiles(in, 8);

  my $x = xref(inputFolder              => in,
               deguidize                => 1,
               fixBadRefs               => 1,
               matchTopics              => 0.9,
               flattenFolder            => out);

  ok $x->statusLine eq q(Xref: 105 refs, 20 image refs, 14 first lines, 14 second lines, 12 duplicate topic ids, 8 duplicate ids, 4 invalid guid hrefs, 2 tables, 1 External xrefs with no format=html, 1 External xrefs with no scope=external, 1 file failed to parse, 1 href missing);
  ok readFile(fpe($x->reports, qw(lists similar byVocabulary txt))) =~ m(1\s+8.*in/1\.dita);
 }

if (1) {                                                                        # Relocated refs
  clearFolder($_, 420) for qw(in out reports);
  createSampleInputFiles(in, 8);

  my $x = xref(inputFolder              => in,
               deguidize                => 1,
               fixBadRefs               => 1,
               fixRelocatedRefs         => 1,
               flattenFolder            => out);

  ok $x->statusLine eq q(Xref: 103 refs, 20 image refs, 14 first lines, 14 second lines, 12 duplicate topic ids, 8 duplicate ids, 4 invalid guid hrefs, 2 tables, 1 External xrefs with no format=html, 1 External xrefs with no scope=external, 1 file failed to parse, 1 href missing);

  my $table = $x->statusTable;
  say STDERR $table;
  ok index($table, <<END) == 0;
    Count  Condition
 1    103  refs
 2     20  image refs
 3     14  first lines
 4     14  second lines
 5     12  duplicate topic ids
 6      8  duplicate ids
 7      4  invalid guid hrefs
 8      2  tables
 9      1  file failed to parse
10      1  href missing
11      1  External xrefs with no format=html
12      1  External xrefs with no scope=external
END

  is_deeply checkXrefStructure($x, q(fixedRefs), in, targets),
   [["Deguidized reference", "image",    "href",   "guid-000",                                        "act1.dita"],
    ["Deguidized reference", "xref",     "href",   "guid-000#guid-000/title",                         "act2.dita"],
    ["Deguidized reference", "xref",     "href",   "guid-001#guid-001/title guid-000#guid-000/title", "act2.dita"],
    ["Deguidized reference", "xref",     "href",   "guid-000#guid-000/title2",                        "act2.dita"],
    ["Deguidized reference", "xref",     "href",   "guid-000#c1/title2",                              "act2.dita"],
    ["Deguidized reference", "link",     "href",   "guid-000",                                        "act2.dita"],
    ["Relocated",            "p",        "conref", "bookmap.ditamap",                                 "act2.dita"],
    ["Relocated",            "p",        "conref", "bookmap2.ditamap",                                "act2.dita"],
    ["Deguidized reference", "topicref", "href",   "guid-000",                                        "map/bookmap.ditamap"],
    ["Deguidized reference", "topicref", "href",   "guid-000",                                        "map/bookmap2.ditamap"],
   ];
 }

if (1)                                                                          # Add nav titles
 {my $N = 8;

  clearFolder($_, 420) for in, out, reports;
  createSampleInputFiles(in, $N);

  my $x = xref(inputFolder  => in, requestAttributeNameAndValueCounts=>1,
               addNavTitles => 1, deguidize=>1);

  is_deeply checkXrefStructure($x, q(badNavTitles), in, targets),
   [["No title for target",  "chapter href=\"yyyy.dita\"",     "map/yyyy.dita",  "map/bookmap.ditamap"],
    ["No title for target",  "topicref href=\"../map/r.txt\"", "map/r.txt",      "map/bookmap.ditamap"],
    ["No title for target",  "topicref href=\"9999.dita\"",    "map/9999.dita",  "map/bookmap.ditamap"],
    ["No title for target",  "topicref href=\"bbb.txt\"",      "map/bbb.txt",    "map/bookmap.ditamap"],
    ["No file for guid",     "topicref href=\"guid-888\"",      undef,           "map/bookmap.ditamap"],
    ["No file for guid",     "topicref href=\"guid-999\"",      undef,           "map/bookmap.ditamap"],
    ["No title for target",  "chapter href=\"zzzz.dita\"",     "map/zzzz.dita",  "map/bookmap2.ditamap"],
    ["No title for target",  "topicref href=\"../map/r.txt\"", "map/r.txt",      "map/bookmap2.ditamap"],
    ["No title for target",  "topicref href=\"9999.dita\"",    "map/9999.dita",  "map/bookmap2.ditamap"],
    ["No title for target",  "topicref href=\"bbb.txt\"",      "map/bbb.txt",    "map/bookmap2.ditamap"],
    ["No file for guid",     "topicref href=\"guid-888\"",      undef,           "map/bookmap2.ditamap"],
    ["No file for guid",     "topicref href=\"guid-999\"",      undef,           "map/bookmap2.ditamap"],
    ["No title for target",  "chapter href=\"../act3.dita\"",  "act3.dita",      "map/bookmap3.ditamap"],
    ["No title for target",  "chapter href=\"../act4.dita\"",  "act4.dita",      "map/bookmap3.ditamap"],
    ["No title for target",  "chapter href=\"../act5.dita\"",  "act5.dita",      "map/bookmap3.ditamap"]];


  is_deeply checkXrefStructure($x, q(goodNavTitles), in, targets),
   [[ "../act1.dita", "All Timing Codes Begin Here", "act1.dita", "map/bookmap.ditamap",  ],
    [ "../act1.dita", "All Timing Codes Begin Here", "act1.dita", "map/bookmap.ditamap",  ],
    [ "../act1.dita", "All Timing Codes Begin Here", "act1.dita", "map/bookmap2.ditamap", ],
    [ "../act1.dita", "All Timing Codes Begin Here", "act1.dita", "map/bookmap2.ditamap", ],
    [ "../act2.dita", "Jumping Through Hops",        "act2.dita", "map/bookmap.ditamap",  ],
    [ "../act2.dita", "Jumping Through Hops",        "act2.dita", "map/bookmap2.ditamap", ], ];

  ok index(readFile(fpe($x->reports, qw(count attributeNamesAndValues txt))), <<END) > 0;
Summary_of_column_Attribute
   Count  Attribute
1    100  href
2     77  id
3     20  conref
4      8  xtrf
5      1  cols
6      1  format
END
 }

if (1)                                                                          # Max zoom in
 {my $N = 8;

  clearFolder($_, 420) for in, out, reports;
  createSampleInputFiles(in, $N);

  my $x = xref(inputFolder => in,
               maxZoomIn   => {bad=>q(Bad), good=>q(Good)});

  is_deeply checkXrefStructure($x, q(maxZoomOut)),
   {"1.dita"               => { data => { bad => 3, good => 4 }, title => "Concept 1 refers to 2" },
    "2.dita"               => { data => { bad => 3, good => 4 }, title => "Concept 2 refers to 3" },
    "3.dita"               => { data => { bad => 3, good => 4 }, title => "Concept 3 refers to 4" },
    "4.dita"               => { data => { bad => 3, good => 4 }, title => "Concept 4 refers to 5" },
    "5.dita"               => { data => { bad => 3, good => 4 }, title => "Concept 5 refers to 6" },
    "6.dita"               => { data => { bad => 3, good => 4 }, title => "Concept 6 refers to 7" },
    "7.dita"               => { data => { bad => 3, good => 4 }, title => "Concept 7 refers to 8" },
    "8.dita"               => { data => { bad => 3, good => 4 }, title => "Concept 8 refers to 1" },
    "act1.dita"            => { data => {}, title => "All Timing Codes Begin Here" },
    "act2.dita"            => { data => {}, title => "Jumping Through Hops" },
    "act4.dita"            => { data => {}, title => undef },
    "act5.dita"            => { data => {}, title => undef },
    "map/bookmap.ditamap"  => { data => {}, title => "Test" },
    "map/bookmap2.ditamap" => { data => {}, title => "Test 2" },
    "map/bookmap3.ditamap" => { data => {}, title => "Test 3" },
    "table.dita"           => { data => {}, title => "Tables" },
   };
 }

if (1)                                                                          # fixedFolder
 {clearFolder($_, 1e3) for in, out, outFixed, reports;
  createSampleInputFilesFixFolder(in);

  my $x = xref(inputFolder => in,
               fixBadRefs  => 1,
               fixedFolder => outFixed);

  ok $x->statusLine eq q(Xref: 2 refs, 2 second lines);

  my @files = searchDirectoryTreesForMatchingFiles(outFixed, q(dita));

  ok @files == 1;
  ok nws(readFile($files[0])) eq nws(<<END);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE reference PUBLIC "-//PHIL//DTD DITA Task//EN" "concept.dtd" []>
<concept id="c1">
  <title>Concept 1 which refers to concept 2</title>
  <conbody>
    <p conref="2.dita#c2/p1"/>
    <p conref="2.dita#c2/p2"/>
    <p xtrf="3.dita#c2/p1"/>
    <xref href="2.dita#c2/p1"/>
    <xref href="2.dita#c2/p2"/>
    <xref xtrf="3.dita#c2/p1"/>
  </conbody>
</concept>
END
 }

if (1)                                                                          # ltgt
 {clearFolder($_, 1e3) for in, reports;
  createSampleInputFilesLtGt(in);

  my $x = xref(inputFolder => in);
  my $r = readFile(fpe($x->reports, qw(count ltgt txt)));
  ok $r =~ m(1\s*1\s*aaa);
  ok $r =~ m(2\s*1\s*bbb);
 }

if (1)                                                                          # fixDitaRefs using target files to locate flattened files
 {clearFolder(tests, 111);
  createSampleInputFilesForFixDitaRefsImproved1(tests);

  my $x = xref(inputFolder => out, fixDitaRefs => targets);                     # Fix with statistics showing the scale of the problem
  ok !$x->statusLine;

  is_deeply checkXrefStructure($x, q(inputFileToTargetTopics), tests),
   {"in/a.dita"     => {"c_aaaa_ca202b3f0a58c67675f9704a32546cea.dita" => 1},
    "in/ab.ditamap" => {"bm_4ef751d67c53ac33272c3bbe16284b0d.ditamap"  => 1},
    "in/b.dita"     => {"c_aaaa_ca202b3f0a58c67675f9704a32546cea.dita" => 1}
   };

  is_deeply checkXrefStructure($x, q(originalSourceFileAndIdToNewFile), tests),
   {"in/a.dita"     => {"GUID-1581d732-b13a-edf0-2651-220a78f1c0fa" => "c_aaaa_ca202b3f0a58c67675f9704a32546cea.dita"},
    "in/ab.ditamap" => {"GUID-18c89db5-781b-666a-f24a-fbafa6d70733" => "bm_4ef751d67c53ac33272c3bbe16284b0d.ditamap"},
    "in/b.dita"     => {"GUID-1581d732-b13a-edf0-2651-220a78f1c0fa" => "c_aaaa_ca202b3f0a58c67675f9704a32546cea.dita"}
   };

  is_deeply checkXrefStructure($x, q(targetTopicToInputFiles), tests),
   {"bm_4ef751d67c53ac33272c3bbe16284b0d.ditamap"  => {"in/ab.ditamap" => 1},
    "c_aaaa_ca202b3f0a58c67675f9704a32546cea.dita" => {"in/a.dita" => 1, "in/b.dita" => 1}
   };

  my $y = xref(inputFolder => out);                                             # Check results
  ok $y->statusLine eq q();
 }

if (1)                                                                          # fixDitaRefs using target files to resolve conrefs to renamed files
 {clearFolder(tests, 111);
  createSampleInputFilesForFixDitaRefsImproved2(tests);

  my $y = xref(inputFolder => out);                                             # Check results without fixes
  ok $y->statusLine eq q(Xref: 1 ref);

  my $x = xref(inputFolder => out, fixDitaRefs => targets);                     # Fix
  ok !$x->statusLine;

  is_deeply checkXrefStructure($x, q(inputFileToTargetTopics), tests),
   {"in/a.dita" => {"c_aaaa_c8e30fbb422819ab92e1752ca50bb158.dita"=>1},
    "in/b.dita" => {"c_bbbb_e374c26206dc955160cecea10306509d.dita"=>1}
   };

  is_deeply checkXrefStructure($x, q(originalSourceFileAndIdToNewFile),tests),
   {"in/a.dita" => {"GUID-48fb251a-9a88-3bcc-d81b-301f426ed439" => "c_aaaa_c8e30fbb422819ab92e1752ca50bb158.dita"},
    "in/b.dita" => {"GUID-e9997c20-3dcf-6958-f762-09d8250bc53e" => "c_bbbb_e374c26206dc955160cecea10306509d.dita",
                    "p1"                                        => "c_bbbb_e374c26206dc955160cecea10306509d.dita"}
   };

  is_deeply checkXrefStructure($x, q(targetTopicToInputFiles), tests),
   {"c_aaaa_c8e30fbb422819ab92e1752ca50bb158.dita" => {"in/a.dita" => 1},
    "c_bbbb_e374c26206dc955160cecea10306509d.dita" => {"in/b.dita" => 1}
   };
 }

if (1)                                                                          # fixDitaRefs in bookmaps to topics that was cut into multiple pieces
 {clearFolder(tests, 111);
  createSampleInputFilesForFixDitaRefsImproved3(tests);

  my $y = xref(inputFolder => out);                                             # Check results without fixes
  ok $y->statusLine eq q(Xref: 1 ref);

  my $x = xref(inputFolder => out, fixDitaRefs => targets);                     # Fix
  ok !$x->statusLine;
 }

if (1)                                                                          # fixDitaRefs in bookmaps to a topics that was not cut into multiple pieces
 {clearFolder(tests, 111);
  createSampleInputFilesForFixDitaRefsImproved4(tests);

  my $y = xref(inputFolder => out);                                             # Check results without fixes
  ok $y->statusLine eq q(Xref: 1 ref);

  my $x = xref(inputFolder => out, fixDitaRefs => targets);                     # Fix
  ok !$x->statusLine;

  ok int(1e2 * $y->tagsTextsRatio) == 233;

 }

if (1)                                                                          # Images
 {clearFolder(tests, 111);
  createSampleImageTest(tests);

  my $x = xref(inputFolder => out, fixDitaRefs => targets);

  ok $x->statusLine eq q(Xref: 1 image ref, 1 ref);
  ok $x->missingImageFiles->[0][0] eq q(../images/b.png);
 }

if (1)                                                                          # Test topic flattening ratio reporting
 {clearFolder(tests, 111);
  createTestTopicFlattening(tests);

  my $x = xref(inputFolder => out, fixDitaRefs => targets);

  ok $x->topicsFlattened       == 3;
  ok $x->topicFlatteningFactor == 3;

  is_deeply checkXrefStructure($x, q(topicFlattening), in, targets),
   { "c_2b1faeb8f74e670e20450cde864e2e46.dita" =>
     [ "c1.dita", "c2.dita", "c3.dita", ],
   };
 }

if (1)                                                                          # References to flattened files
 {clearFolder(tests, 111);
  createTestReferencedToFlattenedTopic(tests);

  my $x = xref(inputFolder => out);
  ok $x->statusLine eq q(Xref: 1 ref);
  is_deeply checkXrefStructure($x, q(fixedRefs), in, targets), [];

  my $y = xref(inputFolder => out, fixDitaRefs => targets);
  ok $y->topicsFlattened == 2;
  ok $y->topicFlatteningFactor == 2;

  is_deeply checkXrefStructure($y, q(fixedRefs), in, targets),
   [["Unique target for file ref", "p", "conref", "b.dita#c/p1",
     "c_aaaa_3119ee09e34375ed4d8a7a15274a9774.dita", "a.dita"]];

  ok !$y->statusLine;
  is_deeply checkXrefStructure($y, q(fixedRefs), in, targets),
    [["Unique target for file ref", "p", "conref", "b.dita#c/p1",
      "c_aaaa_3119ee09e34375ed4d8a7a15274a9774.dita", "a.dita"]];

 }

latestTest:;

if (1)                                                                          #Txref References from a topic that has been cut out to a topic that has been cut out
 {clearFolder(tests, 111);
  createTestReferenceToCutOutTopic(tests);

  my $x = xref(inputFolder => out, fixDitaRefs => targets);
  ok $x->statusLine eq q(Xref: 1 ref);

  is_deeply checkXrefStructure($x, q(inputFileToTargetTopics),          in, targets), { "a.xml" => { "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita" => 1, "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => 1, "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => 1, "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => 1, }, "b.xml" => { "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita" => 1, "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => 1, "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => 1, "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => 1, }, };
  is_deeply checkXrefStructure($x, q(targetTopicToInputFiles),          in, targets), { "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita" => { "a.xml" => 1, }, "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => { "a.xml" => 1, }, "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => { "a.xml" => 1, }, "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => { "a.xml" => 1, }, "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita" => { "b.xml" => 1, }, "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => { "b.xml" => 1, }, "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => { "b.xml" => 1, }, "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => { "b.xml" => 1, }, };
  is_deeply checkXrefStructure($x, q(sourceTopicToTargetBookMap),       in, targets), { "a.xml" => bless({ source => "a.xml", sourceDocType => "concept", target => "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap", targetType => "bookmap", }, "Bookmap"), "b.xml" => bless({ source => "b.xml", sourceDocType => "concept", target => "bm_b_d2806ba589f908da1106574afd9db642.ditamap", targetType => "bookmap", }, "Bookmap"), };
  is_deeply checkXrefStructure($x, q(topicFlattening),                  in, targets), {};
  is_deeply checkXrefStructure($x, q(originalSourceFileAndIdToNewFile), in, targets), { "a.xml" => { "GUID-400c2c59-95e1-7bf3-4647-3a135281bfaf" => "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita", "GUID-68822563-d568-f418-38ae-f1c62cb4ac8d" => "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita", "GUID-c67821ef-3da2-c89f-0fc9-9fba3937f368" => "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita", "GUID-f0c0e170-8128-10ef-045d-97602fdde76f" => "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita", }, "b.xml" => { "GUID-2b6aab4f-9328-e326-f55f-160771a8c3dd" => "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita", "GUID-86a684b0-1a0b-4c30-6da9-24c74ff1f0cc" => "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita", "GUID-96a20d7f-bbaf-deef-55ef-e09a0a059251" => "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita", "GUID-cfe7cb3d-05e7-a147-db10-dcbacaeecef7" => "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita", "p1" => "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita", "p2" => "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita", "p3" => "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita", }, };
 }

clearFolder($_, 1e3) for in, out, outFixed, reports, tests, targets, q(zzzParseErrors);

1

# &writeXrefStructureTest($x, qw(topicFlattening in targets));
