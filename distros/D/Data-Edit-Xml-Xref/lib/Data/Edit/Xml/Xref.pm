#!/usr/bin/perl -I/home/phil/perl/cpan/DataEditXml/lib/ -I/home/phil/perl/cpan/DataTableText/lib/ -I/home/phil/perl/cpan/DitaGBStandard/lib/
#-------------------------------------------------------------------------------
# Cross reference Dita XML, match topics and ameliorate missing references.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2019
# Improvements and maxzoomin
#-------------------------------------------------------------------------------
# Check for image formats that will not display in a browser
# Do not consider companion files!
# Images that are referenced by topics which are not referenced by bookmaps showup as referenced
# It should be possible to remove reportImages by using generic references instead
# Conref processing in reportReferencesFromBookmaps
# Fix xref external/scope and eliminate error count if fixbadrefs in operation.
# Add labels to ditaRefs processing so that references to labels are also fixed
# Add xref expansion from id in file as it is a pain to code up the full details by hand
# Find topics that have no text in them per: PS2-617
# Need test for changeBadXrefToPh
# Unique target needs tests
# Create list of images found in input folder
# Conrefs report should use targets/ to update the conref file so conrefs fixed by fixDitaRefs are considered

package Data::Edit::Xml::Xref;
our $VERSION = 20200424;
use v5.26;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Edit::Xml;
use Data::Table::Text qw(:all);
use Dita::GB::Standard;
use Storable qw(store retrieve);
use Time::HiRes qw(time);
use utf8;

#sub improvementLength      {80}                                                 #P Maximum length of the test of an improvement suggestion
sub classificationMapSuffix{q(_classification.ditamap)}                         #P Suffix to add to map files to create corresponding classification map file

#D1 Cross reference                                                             # Check the cross references in a set of Dita files and report the results.

sub newXref(%)                                                                  #P Create a new cross referencer
 {my (%attributes) = @_;                                                        # Attributes

  my $xref = genHash(__PACKAGE__,                                               # Attributes used by the Xref cross referencer.
    addNavTitles                        => undef,                               #I If true, add navtitle to outgoing bookmap references to show the title of the target topic.
    allowUniquePartialMatches           => undef,                               # Allow unique partial matches - i.e ignore the stuff to the right of the # in a reference if doing so produces a unique result. This feature has been explicitly disabled for conrefs (PS2-561) and might need to be disabled for other types of reference as well.
    attributeCount                      => {},                                  # {file}{attribute name} == count of the different xml attributes found in the xml files.
    attributeNamesAndValuesCount        => {},                                  # {file}{attribute name}{value} = count
    author                              => {},                                  # {file} = author of this file.
    badGuidHrefs                        => {},                                  # Bad conrefs - all.
    badNavTitles                        => {},                                  # Details of nav titles that were not resolved
    badReferencesCount                  => 0,                                   # The number of bad references at the start of the run - however depending on what options were chosen Xref might ameliorate these bad references and thereby reduce this count.
    badTables                           => [],                                  # Array of tables that need fixing.
    badXml1                             => {},                                  # [Files] with a bad xml encoding header on the first line.
    badXml2                             => {},                                  # [Files] with a bad xml doc type on the second line.
    baseFiles                           => {},                                  # {base of file name}{full file name}++ Current location of the file via uniqueness guaranteed by the GB standard
    baseTag                             => {},                                  # Base Tag for each file
    bookMapRefs                         => {},                                  # {bookmap full file name}{href}{navTitle}++ References from bookmaps to topics via appendix, chapter, bookmapref.
    changeBadXrefToPh                   => undef,                               #I Change xrefs being placed in B<M3> by L<fixBadRefs> to B<ph>.
    classificationMaps                  => undef,                               #I Create classification maps if true
    conRefs                             => {},                                  # {file}{href}{tag}++ : conref source detail
    createReports1                      => [],                                  # Reports requested before references fixed
    createReports2                      => [],                                  # Reports requested after references fixed
    currentFolder                       => currentDirectory,                    # The current working folder used to make absolute file names from relative ones
    deleteUnusedIds                     => 0,                                   #I Delete ids (except on topics) that are not referenced in any reference in the corpus regardless of the file component of any such reference.
    deguidize                           => undef,                               #I Set true to replace guids in dita references with file name. Given reference B<g1#g2/id> convert B<g1> to a file name by locating the topic with topicId B<g2>.  This requires the guids to be genuinely unique. SDL guids are thought to be unique by language code but the same topic, translated to a different language might well have the same guid as the original topic with a different language code: =(de|en|es|fr).  If the source is in just one language then the guid uniqueness is a reasonable assumption.  If the conversion can be done in phases by language then the uniqueness of guids is again reasonably assured. L<Data::Edit::Xml::Lint> provides an alternative solution to deguidizing by using labels to record the dita reference in the input corpus for each id encountered, these references can then be resolved in the usual manner by L<Data::Edit::Xml::Lint::relint>.
    docType                             => {},                                  # {file} == docType:  the docType for each xml file.
    duplicateIds                        => {},                                  # [file, id]     Duplicate id definitions within each file.
    duplicateTopicIds                   => {},                                  # Duplicate topic ids
    duplicateTopicIds                   => {},                                  # [topicId, [files]] Files with duplicate topic ids - the id on the outermost tag.
    emptyTopics                         => {},                                  # {file} : topics where the *body is empty.
    errors                              => 0,                                   # Number of significant errors as reported in L<statusLine> or 0 if no such errors found
    exteriorMaps                        => {},                                  # {exterior map} : maps that are not referenced by another map
    fileExtensions                      => [qw(.dita .ditamap .xml .fodt)],     # Default file extensions to load
    fixBadRefs                          => undef,                               #I Fix any remaining bad references after any all allowed attempts have been made to fix failing references by moving the failing reference to the B<xtrf> attribute i.e. placing it in B<M3> possibly renaming the tag to B<ph> if L<changeBadXrefToPh> is in effect as well.
    fixDitaRefs                         => undef,                               #I Fix references in a corpus of L<Dita> documents that have been converted to the L<GBStandard> and whose target structure has been written to the named folder.
    fixedFolder                         => undef,                               #I Fixed files are placed in this folder.
    fixedFolderTemp                     => undef,                               #I Fixed files are placed in this folder if we are on aws but nit the session leader - this folder is then copied back to L<fixedFolder> on the session leader.
    fixedRefsBad                        => [],                                  # [] hrefs and conrefs from L<fixRefs|/fixRefs> which were moved to the "xtrf" attribute as requested by the L<fixBadHrefs|/fixBadHrefs> attribute because the reference was invalid and could not be improved by L<deguidization|/deguidize>.
    fixedRefsGB                         => [],                                  # [] files fixed to the Gearhart-Brenan file naming standard
    fixedRefsGood                       => [],                                  # [] hrefs and conrefs from L<fixRefs|/fixRefs> which were invalid but have been fixed by L<deguidizing|/deguidize> them to a valid file name.
    fixedRefsNoAction                   => [],                                  # [] hrefs and conrefs from L<fixRefs|/fixRefs> for which no action was taken.
    fixRefs                             => {},                                  # {file}{ref} where the href or conref target is not valid.
    fixRelocatedRefs                    => undef,                               #I Fix references to topics that have been moved around in the out folder structure assuming that all file names are unique which they will be if they have been renamed to the GB Standard.
    fixXrefsByTitle                     => undef,                               #I Try to fix invalid xrefs by the Gearhart Title Method enhanced by the Monroe map method if true
    flattenFiles                        => {},                                  # {old full file name} = file renamed to Gearhart-Brenan file naming standard
    flattenFolder                       => undef,                               #I Files are renamed to the Gearhart standard and placed in this folder if set.  References to the unflattened files are updated to references to the flattened files.  This option will eventually be deprecated as the Dita::GB::Standard is now fully available allowing files to be easily flattened before being processed by Xref.
    getFileUrl => qq(/cgi-bin/uiSelfServiceXref/client.pl?getFile=),            #I A url to retrieve a specified file from the server running xref used in generating html reports. The complete url is obtained by appending the fully qualified file name to this value.
    goodImageFiles                      => {},                                  # {file}++ : number of references to each good image
    goodNavTitles                       => {},                                  # Details of nav titles that were resolved.
    guidHrefs                           => {},                                  # {file}{href} = location where href starts with GUID- and is thus probably a guid.
    guidToFile                          => {},                                  # {topic id which is a guid} = file defining topic id.
    hrefUrlEncoding                     => {},                                  # Hrefs that need url encoding because they contain white space.
    html                                => undef,                               #I Generate html version of reports in this folder if supplied
    idNotReferenced                     => {},                                  # {file}{id}++ - id in a file that is not referenced
    idReferencedCount                   => {},                                  # {file}{id}++ - the number of times this id in this file is referenced from the rest of the corpus
    ids                                 => {},                                  # {file}{id}   - id definitions across all files.
    idsRemoved                          => {},                                  # {id}++ : Ids removed from all files
    idTags                              => {},                                  # {file}{id}[tag] The tags associated with each id in a file - there might be more than one if the id is duplicated
    images                              => {},                                  # {file}{href}   Count of image references in each file.
    imagesReferencedFromBookMaps        => {},                                  # {bookmap full file name}{full name of image referenced from topic referenced from bookmap}++
    imagesReferencedFromTopics          => {},                                  # {topic full file name}{full name of image referenced from topic}++
    imagesToRefferingBookMaps           => {},                                  # {image full file name}{bookmap full file name}++ : images to referring bookmaps
    indexWords                          => undef,                               #I Index words to topics and topics to words if true.
    indexWordsFolder                    => undef,                               #I Folder into which to save words to topic and topics to word indexes if L<indexWords> is true.
    indexedWords                        => {},                                  # {word}{full file name of topic the words occurs in}.
    inputFiles                          => [],                                  # Input files from L<inputFolder|/inputFolder>.
    inputFileToTargetTopics             => {},                                  # {input file}{target file}++ : Tells us the topics an input file was split into
    inputFolderImages                   => {},                                  # {full image file name} for all files in input folder thus including any images resent
    inputFolder                         => undef,                               #I A folder containing the dita and ditamap files to be cross referenced.
    ltgt                                => {},                                  # {text between &lt; and &gt}{filename} = count giving the count of text items found between &lt; and &gt;
    matchTopics                         => undef,                               #I Match topics by title and by vocabulary to the specified confidence level between 0 and 1.  This operation might take some time to complete on a large corpus.
    maximumNumberOfProcesses            => numberOfCpus(8),                     #I Maximum number of processes to run in parallel at any one time with a sensible default.
    maxZoomIn                           => undef,                               #I Optional hash of names to regular expressions to look for in each file
    maxZoomOut                          => {},                                  # Results from L<maxZoomIn|/maxZoomIn>  where {file name}{regular expression key name in L<maxZoomIn|/maxZoomIn>}++
    md5Sum                              => {},                                  # MD5 sum for each input file.
    md5SumDuplicates                    => {},                                  # {md5sum}{file}++ : md5 sums with more than one file
    missingImageFiles                   => {},                                  # [file, href] == Missing images in each file.
    missingTopicIds                     => {},                                  # Missing topic ids.
    noHref                              => {},                                  # Tags that should have an href but do not have one.
    notReferenced                       => {},                                  # {file name} Files in input area that are not referenced by a conref, image, bookmapref or xref tag and are not a bookmap.
    olBody                              => {},                                  # The number of ol under body by file
    originalSourceFileAndIdToNewFile    => {},                                  # {original file}{id} = new file: Record mapping from original source file and id to the new file containing the id
    otherMeta                           => {},                                  # {original file}{othermeta name}{othermeta content}++ : the contents of the other meta tags
    otherMetaDuplicatesSeparately       => [],                                  # Duplicate othermeta in bookmaps and topics considered separately
    otherMetaDuplicatesCombined         => [],                                  # Duplicate othermeta in bookmaps with called topics othermeta included
    otherMetaRemainWithTopic            => [],                                  # Othermeta that must stay in the topic
    otherMetaPushToBookMap              => [],                                  # Othermeta that can be pushed to the calling book map
    otherMetaBookMapsBeforeTopicIncludes=> [],                                  # Bookmap othermeta before topic othermeta has been included
    otherMetaBookMapsAfterTopicIncludes => [],                                  # Bookmap othermeta after  topic othermeta has been included
    otherMetaConsolidated               => {},                                  # {Name}{Content}++ : consolidated other meta data across entire corpus
    oxygenProjects                      => undef,                               #I Create oxygen project files for each map - the project file will have an extension of .xpr and the same name and path as the map file or the name return by your implementation of: Data::Edit::Xml::Xref::xprName($map) if present.
    parseFailed                         => {},                                  # {file} files that failed to parse.
    publicId                            => {},                                  # {file} = Public id on Doctype
    references                          => {},                                  # {file}{reference}++ - the various references encountered
    relocatedReferencesFailed           => [],                                  # Failing references that were not fixed by relocation
    relocatedReferencesFixed            => [],                                  # Relocated references fixed
    requestAttributeNameAndValueCounts  => undef,                               #I Report attribute name and value counts
    requiredCleanUp                     => undef,                               # {full file name}{cleanup} = number of required-cleanups
    reports                             => undef,                               #I Reports folder: Xref will write text versions of the generated reports to files in this folder.
    results                             => [],                                  # Summary of results table.
#   sourceFile                          => undef,                               # The source file from whic#h this structure was generated.
    sourceTopicToTargetBookMap          => {},                                  # {input topic cut into multiple pieces} = output bookmap representing pieces
    statusLine                          => undef,                               # Status line summarizing the cross reference.
    statusTable                         => undef,                               # Status table summarizing the cross reference.
    subjectSchemeMap                    => undef,                               #I Create a subject scheme map in the named file
    suppressReferenceChecks             => undef,                               #I Suppress reference checking - which normally happens by default - but which takes time and might be irrelevant if an earlier xref has already checked all the references.
    tableDimensions                     => {},                                  # {file}{columns}{rows} == count
    tagCount                            => {},                                  # {file}{tags} == count of the different tag names found in the xml files.
    tagsTextsRatio                      => undef,                               # Ratio of tags to text encountered
    tags                                => undef,                               # Number of tags encountered
    targetFolderContent                 => {},                                  # {file} = bookmap file name : the target folder content which shows us where an input file went
    targetTopicToInputFiles             => {},                                  # {current file} = the source file from which the current file was obtained
    texts                               => undef,                               # Number of texts encountered
    timeEnded                           => undef,                               # Time the run ended
    timeStart                           => undef,                               # Time the run started
    title                               => {},                                  # {full file name} = title of file.
    titleToFile                         => {},                                  # {title}{file}++ if L<fixXrefsByTitle> is in effect
    topicFlatteningFactor               => {},                                  # Topic flattening factor - higher is better
    topicFlattening                     => {},                                  # {topic}{sources}++ : the source files for each topic that was flattened
    topicIds                            => {},                                  # {file} = topic id - the id on the outermost tag.
    topicsFlattened                     => undef,                               # Number of topics flattened
    topicsNotReferencedFromBookMaps     => {},                                  # {topic file not referenced from any bookmap} = 1
    topicsReferencedFromBookMaps        => {},                                  # {bookmap full file name}{topic full file name}++ : bookmaps to topics
    topicsToReferringBookMaps           => {},                                  # {topic full file name}{bookmap full file name}++ : topics to referring bookmaps
    urls                                => {},                                  # {topic full file name}{url}++ : urls found in each file
    urlsBad                             => {},                                  # {url}{topic full file name}++ : failing urls found in each file
    urlsGood                            => {},                                  # {url}{topic full file name}++ : passing urls found in each file
    validateUrls                        => undef,                               #I Validate urls if true by fetching their headers with L<curl>
    validationErrors                    => {},                                  # True means that Lint detected errors in the xml contained in the file.
    vocabulary                          => {},                                  # The text of each topic shorn of attributes for vocabulary comparison.
    xrefBadFormat                       => {},                                  # External xrefs with no format=html.
    xrefBadScope                        => {},                                  # External xrefs with no scope=external.
    xRefs                               => {},                                  # {file}{href}++ Xrefs references.
    xrefsFixedByTitle                   => [],                                  # Xrefs fixed by locating a matching topic title from their text content.
   );

  loadHash($xref, @_);                                                          # Load attributes complaining about any invalid ones
 } # newXref

sub xref2(%)                                                                    #P Check the cross references in a set of Dita files held in  L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder. The possible attributes are defined in L<Data::Edit::Xml::Xref|/Data::Edit::Xml::Xref>
 {my (%attributes) = @_;                                                        # Attributes of cross referencer
  my ($xref) = newXref(@_);                                                     # Cross referencer
  $xref->timeStart = time;                                                      # Start time

  $xref->inputFolder or confess "Please supply a value for: inputFolder";
  $xref->inputFolder =~ s(\/+\Z) (\/)gs;                                        # Cleanup path names
  $xref->inputFolder =                                                          # Make input folder absolute
    absFromAbsPlusRel($xref->currentFolder, $xref->inputFolder)
    if $xref->inputFolder !~ m(\A/);

  $xref->reports or confess "Please supply a value for: reports";

  if (1)                                                                        # Write title and some of the parameters
   {my $r = $xref->reports;
    owf(fpe($r, qw(xref_parameter_settings txt)), dump($xref)) if $r;           # Print all parameters

    my $i = $xref->inputFolder;
    lll "Xref started on folder: $i, reports: $r"                               # Show that we are starting unless in development
      unless $i =~ m(/tmp/);
   }

  if (my $d = $xref->fixDitaRefs)                                               # Fully qualify and validate targets folder
   {$xref->fixDitaRefs = fullyQualifiedFile($d) ? $d :                          # Fully qualified target folder name
              absFromAbsPlusRel($xref->currentFolder, $d);                      # Get fully qualified target folder if necessary
    if (!-d $d)                                                                 # Check targets folder is available
     {confess "Targets folder does not exist: fixDitaRefs=>$d";
     }
    my @d = searchDirectoryTreesForMatchingFiles($d);
    @d or confess "Targets folder is empty: fixDitaRefs=>$d";
   }

  if (!$xref->fixedFolder and $xref->fixDitaRefs || $xref->fixRelocatedRefs)    # Fixing references
   {my $s = join ' and ',
     ($xref->fixDitaRefs      ? "fixDitaRefs"      : (),
      $xref->fixRelocatedRefs ? "fixRelocatedRefs" : ());
    warn "No fixedFolder attribute specified yet $s specified.\n".
         "Assuming inputFolder for fixedFolder.\n";
    $xref->fixedFolder = $xref->inputFolder;
   }

  if (my $f = $xref->fixedFolder)                                               # Fixing references in a folder other than the input folder requires us to copy the files across so we can make differential changes
   {if (my $i = $xref->inputFolder)
     {if ($f ne $i)
       {copyFolder($i, $f);
       }
     }
   }

  $xref->fixedFolderTemp //= fpd(temporaryFolder);                              # Preserve this temporary value across session instances

  my @series =                                                                  # Must be done in series at the start
   (q(loadInputFiles),
    q(analyzeInputFiles),
    q(reportReferencesFromBookMaps),                                            # Used by fixReferences to get bookmap references
    $xref->deguidize ? q(reportGuidsToFiles) : (),                              # Used by addNavTitleToMaps
    q(checkReferences),                                                         # Check all the references
    q(createReportsInParallel1),                                                # Create reports that do not rely on fixed references
    q(fixReferences),                                                           # Fix any failing references
    q(createReportsInParallel2),                                                # Create reports that        rely on fixed references
   );

  my @parallel1 =                                                               # Create reports in parallel that do not rely on fixed references
   (q(reportXml1),
    q(reportXml2),
    q(reportDuplicateIds),
    q(reportDuplicateTopicIds),
    q(reportNoHrefs),
    q(reportTables),
    q(reportParseFailed),
    q(reportAttributeCount),
    q(reportLtGt),
    q(reportTagCount),
    q(reportTagsAndTextsCount),
    q(reportDocTypeCount),
    q(reportFileExtensionCount),
    q(reportFileTypes),
    q(reportValidationErrors),
    q(reportGuidHrefs),
    q(reportExternalXrefs),
    q(reportTopicDetails),
    q(reportTopicReuse),
    q(reportMd5Sum),
    q(reportOlBody),
    q(reportHrefUrlEncoding),
    q(reportFixRefs),
    q(reportSourceFiles),
    q(reportOtherMeta),
    q(createSubjectSchemeMap),
    q(reportTopicsNotReferencedFromBookMaps),
    q(reportTableDimensions),
    q(reportExteriorMaps),
    q(createClassificationMaps),
    q(reportIdRefs),
    q(reportEmptyTopics),
    q(reportConRefMatching),
    q(reportPublicIds),
    q(reportRequiredCleanUps),
   );

  if ($xref->addNavTitles)                                                      # Add nav titles to bookmaps if requested
   {push @parallel1, q(addNavTitlesToMaps);
   }

  if ($xref->requestAttributeNameAndValueCounts)                                # Report attribute name and value counts
   {push @parallel1,  q(reportAttributeNameAndValueCounts);
   }

  if ($xref->flattenFolder)                                                     # Fix file names to the Gearhart-Brenan file naming standard
   {push @parallel1, q(fixFilesGB)
   }

  if ($xref->matchTopics)                                                       # Topic matching reports
   {push @parallel1, q(reportSimilarTopicsByTitle),
                     q(reportSimilarTopicsByVocabulary);
   }

  if ($xref->indexWords)                                                        # Word indexing required
   {push @parallel1, q(reportWordsByFile);
    $xref->indexWordsFolder or confess "Please set indexWordsFolder";
   }

  if ($xref->validateUrls)                                                      # Validate urls
   {push @parallel1, q(reportUrls);
   }

  push $xref->createReports1->@*, @parallel1;                                   # Create reports that do not rely on references being fixed

  my @parallel2 =                                                               # Create reports in parallel after references fixed
   (q(removeUnusedIds),                                                         # Count and/or remove unused ids
    q(reportImages),                                                            # Images relies on fixed references to locate images
   );

  if ($xref->oxygenProjects)                                                    # Create oxygen project files if requested
   {push @parallel2, q(createOxygenProjectMapFiles);
   }

  push $xref->createReports2->@*, @parallel2;                                   # Create reports that rely on references being fixed

  if (1)                                                                        # Perform phases in series that must be run in series
   {my @times;

    for my $phase(@series)                                                      # Each phase in series
     {my $startTime = time;
     #lll "Xref phase $phase";

      $xref->$phase;                                                            # Execute phase

     #mmm "Xref phase $phase";
      push @times, [$phase, sprintf("%12.4f", time - $startTime)];              # Phase time
     }

    my $delta = sprintf("%.3f seconds", time - $xref->timeStart);               # Time so far

    formatTables($xref, [sort {$$b[1] <=> $$a[1]} @times],                      # Update after each phase so we can see progress on long running jobs
      columns => <<END,
Phase         Xref processing phase
Time_Seconds  Time in seconds taken by this processing phase
END
      title   => qq(Processing phases elapsed times in descending order),
      head    => <<END,
Xref phases took the following times on DDDD

Total run time: $delta
END
      file    => fpe(q(timing), qw(xref_phases txt)));                          # Write phase times
   }

  formattedTablesReport                                                         # Needs update for reports in parallel
   (title=>q(Reports available),
    head=><<END,
NNNN reports available on DDDD

Sorted by title
END
   file=>fpe($xref->reports, qw(reports txt))) if $xref->reports;

  if (1)                                                                        # Summarize
   {my @o;
    my $save = sub
     {my ($levels, $field, $plural, $single) = @_;
      my $n = &countLevels($levels, $xref->{$field});
      push @o, [$n,            $plural]                   if $n >  1;
      push @o, [$n, $single // ($plural =~ s(s\Z) ()gsr)] if $n == 1;
     };

#   $save->(1, "badConRefsList",    q(conrefs));
#   $save->(1, "badConRefs",        q(files with bad conrefs), q(file with bad conrefs));
    $save->(1, "badGuidHrefs",      q(invalid guid hrefs));
    $save->(1, "badTables",         q(tables));
    $save->(1, "badXml1",           q(first lines));
    $save->(1, "badXml2",           q(second lines));
#   $save->(1, "badXRefsList",      q(xrefs));
#   $save->(1, "badXRefs",          q(files with bad xrefs), q(file with bad xrefs));
    $save->(2, "duplicateIds",      q(duplicate ids));
    $save->(1, "fixedRefsBad",      q(refs));                                   # Unable to resolve these references - L<fixBadRefs> can be used to ameliorate them.
    $save->(1, "hrefUrlEncoding",   q(href url encoding), q(href url encoding));
    $save->(2, "md5SumDuplicates",  q(duplicate files));
    $save->(1, "missingImageFiles", q(image refs));
    $save->(1, "missingTopicIds",   q(missing topic ids));
    $save->(1, "notReferenced",     q(files not referenced), q(file not referenced));
    $save->(1, "parseFailed",       q(files failed to parse), q(file failed to parse));
    $save->(1, "duplicateTopicIds", q(duplicate topic ids));
    $save->(2, "noHref",            q(hrefs missing), q(href missing));
    $save->(2, "validationErrors",  q(validation errors)); # Needs testing
    $save->(2, "xrefBadFormat",     q(External xrefs with no format=html));
    $save->(2, "xrefBadScope",      q(External xrefs with no scope=external));
    $save->(1, "urlsBad",           q(urls));

    my $files = $xref->inputFiles->@*;

    my $statusLine = $xref->statusLine = @o ? join " ",                         # Status line
      "Xref:", join ", ",
               map {join " ", @$_}
               sort
                {return $$a[1] cmp $$b[1] if $$b[0] == $$a[0];
                 $$b[0] <=> $$a[0]
                }
               @o : qq(Xref: processed $files files, found no errors);

    lll $statusLine;                                                            # Print Xref results summary with date and time

    $xref->errors = @o;

    $xref->statusTable = formatTable
     ([sort {$$b[0] <=> $$a[0]} @o], [qw(Count Condition)]);                    # Summary in status form
    $xref->results = \@o;                                                       # Save status line components
   }

  $xref->timeEnded = time;                                                      # Run ended time

  formatTables($xref, [[$xref->timeStart, $xref->timeEnded,                     # Write run times
               $xref->timeEnded - $xref->timeStart]],
    columns => <<END,
Start_Time   Start time of the run
End_Time     End time of the run
Elapsed_Time Xref took this many seconds to run
END
    title => qq(Run times in seconds),
    head  => qq(Xref took the following time to run on DDDD),
    file  => fpe(q(timing), qw(run txt)));

  formatHtmlTablesIndex($xref->reports, q(), $xref->getFileUrl, 2);             # Create an index of html files for use as an initial page of Xref results - this is done in Dita.pm as well but we need it here too so it can be tested.

  lll "Xref finished on folder: ", $xref->inputFolder unless                    # Show that we have finished unless in development
    $xref->inputFolder =~ m(/tmp/);

  $xref                                                                         # Return Xref results
 } # xref2

sub xref(%)                                                                     # Check the cross references in a set of Dita files held in L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder. The possible attributes are defined in L<Data::Edit::Xml::Xref|/Data::Edit::Xml::Xref>.
 {my (%attributes) = @_;                                                        # Cross referencer attribute value pairs
  my $x = callSubInParallel {xref2(%attributes)};                               # Process in alternate process to avoid memory fragmentation
  newXref %$x                                                                   # Return blessed results after creating in child process
 }

sub createReportsInParallel($@)                                                 #P Create reports in parallel
 {my ($xref, @reports) = @_;                                                    # Cross referencer, reports to be run

  runInParallel($xref->maximumNumberOfProcesses,
    sub                                                                         # Execute each report in parallel
     {my ($report) = @_;
      my ($result) = my @result = ($xref->$report);                             # Check that the value returned by the report is a single hash reference

      formatHtmlAndTextTablesWaitPids;                                          # Wait for report tables to be formatted in parallel

      if (scalar(@result) != 1)                                                 # Check return from multiverse to universe
       {confess "Phase $report does not return one result";
       }
      if ($result =~ m(hash)s)
       {confess "Phase $report does not return a hash reference";
       }

      $result                                                                   # Return results from report
     },
    sub                                                                         # Decode results
     {for my $r(@_)
       {for my $k(sort keys %$r)
         {$xref->{$k} = $$r{$k};
         }
       }
     },
    @reports);                                                                  # Each report to be run parallel
 }

sub createReportsInParallel1()                                                  #P Create reports in parallel that do not require fixed references
 {my ($xref) = @_;                                                              # Cross referencer
  createReportsInParallel($xref, $xref->createReports1->@*)
 }

sub createReportsInParallel2()                                                  #P Create reports in parallel that        require fixed references
 {my ($xref) = @_;                                                              # Cross referencer
  createReportsInParallel($xref, $xref->createReports2->@*)
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

sub fixingRun($)                                                                #P A fixing run fixes problems where it can and thus induces changes which might make the updated output different from the incoming source.  Returns a useful message describing this state of affairs.
 {my ($xref) = @_;                                                              # Cross referencer
  my @i;
  for my $i(qw(fixBadRefs fixDitaRefs fixRelocatedRefs  fixXrefsByTitle))
   {push @i, $i if $xref->{$i};
   }

  if (@i)                                                                       # Fixing run
   {my $i = join ', ', @i;
    return <<END;

Caution: this is a fixing run with options: $i set to on.

This report represents the status quo ante - i.e. what things look like at the
start of the run.  This is useful information for driving development of Xref
but confusing if you only want to improve your document corpus.

To get the state of play, a posteriori, request a copy of this report as
produced after an Xref run with all the options above set to off.

END
   }
  else                                                                          # Reporting run
   {return '';
   }
 }

sub loadInputFiles($)                                                           #P Load the names of the files to be processed
 {my ($xref) = @_;                                                              # Cross referencer

  my $in = $xref->inputFiles =
   [searchDirectoryTreesForMatchingFiles
    $xref->inputFolder, @{$xref->fileExtensions}];

  if (!$in or @$in == 0)                                                        # Complain if there are no input files to analyze
   {my $i = $xref->inputFolder;
    my $e = join " ", @{$xref->fileExtensions};
    my $x = -d $i ? "The input folder does exist." :
                    "The input folder does NOT exist!";
    confess join '',
      "No files with the specified file extensions ",
      "in the specified input folder:\n",
      "$e\n$i\n$x\n";
   }

  my @images = searchDirectoryTreesForMatchingFiles($xref->inputFolder);        # Input files
  $xref->inputFolderImages = {map {fn($_), $_} @images};                        # Image file name which works well for images because the md5 sum in their name is probably unique
 }

sub formatTables($$%)                                                           #P Using cross reference B<$xref> options and an array of arrays B<$data> format a report as a table using B<%options> as described in L<Data::Table::Text::formatTable> and L<Data::Table::Text::formatHtmlTable>.
 {my ($xref, $data, %options) = @_;                                             # Cross referencer, table to be formatted, options

  $xref && ref($xref) =~ m(xref)i or cluck "No cross referencer";               # Check parameters
  $data && ref($data) =~ m(array)i or cluck "No data for table";

  cluck "No file for table"    unless $options{file};                           # Check for required options
  cluck "No columns for table" unless $options{columns};
  cluck "No title for table"   unless $options{title};
  $options{zero} = 1 if $options{facet} and !$options{zero};

  formatHtmlAndTextTables
   ($xref->reports, $xref->html, $xref->getFileUrl,
    $xref->inputFolder, $data, %options);
 }

sub hashOfCountsToArray($)                                                      #P Convert a B<$hash> of {key} = count to an array so it can be formatted with L<formatTables>
 {my ($hash) = @_;                                                              # Hash to be converted
  my $array = [];
  for my $key(sort keys %$hash)
   {push @$array, [$$hash{$key}, $key];
   }
  $array
 }

sub reportGuidsToFiles($)                                                       #P Map and report guids to files
 {my ($xref) = @_;                                                              # Xref results
  my @r;
  if (my $xrefTopicIds = $xref->topicIds)
   {for   my $file(sort keys %{$xrefTopicIds})                                  # Each input file which will be absolute
     {if (my $topicId = $xrefTopicIds->{$file})                                 # Topic Id for file - we report missing topicIds in: reportDuplicateTopicIds
       {next unless $topicId =~ m(\AGUID-)is;
        $xref->guidToFile->{$topicId} = $file;                                  # Guid Topic Id to file
        push @r, [$topicId, $file];
       }
     }
   }

  formatTables($xref, \@r,
    columns  => <<END,
Guid The guid being defined
File The file that defines the guid
END
    title    =>qq(Guid topic definitions),
    head     =>qq(Xref found NNNN guid topic definitions on DDDD),
    summarize=>1,
    file     =>fpe(q(lists), qw(guidsToFiles txt)));
 }

sub editXml($$$)                                                                #P Edit an xml file retaining any existing XML headers and lint trailers
 {my ($in, $out, $source) = @_;                                                 # Input file, output file, source to write

  my @s = readFile($in);                                                        # Read existing source

  my @h;                                                                        # Headers if any present
  if (@s > 0)                                                                   # Remove header lines using a very basic parse that is not a general solution
   {if ($s[0] =~ m(\A\<\?xml)is)                                                # First line
     {push @h, shift @s;
      if (@s > 0 and $s[0] =~ m(\A<!DOCTYPE)s)                                  # Second line start
       {push @h, shift @s;
        while(@s > 0 and $s[0] !~ m(\A\s*<[a-z])i)                              # Parse to root tag
         {push @h, shift @s;
         }
       }
     }
   }

  my @l;                                                                        # Lint data if any
  if (1)
   {my $state;
    for my $s(@s)
     {if (!$state && $s =~ m(\A\<\!\-\-linted\:)s or $state)
       {push @l, $s;
        $state++;
       }
     }
   }

  owf($out, join '', @h, $source, @l)                                           # Insert new source between old headers and trailers
 }

# Fix a file by moving its hrefs and conrefs to the xtrf attribute unless
# deguidization is in effect and the guid can be converted into a valid Dita
# reference accessing a file in the input corpus.
#
# If fixRelocatedRefs is in effect: such references are fixed by assuming that
# the files mentioned in broken links have been relocated else where in the
# folder structure and can be located by base file name alone.
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
  my $fixed = newXref();                                                        # Fix results
  my $node;                                                                     # The current node we are working with
  my $attr;                                                                     # The current attribute we are working with
  my $ref;                                                                      # The current reference we are working with
  my @bad;  $fixed->fixedRefsBad  = \@bad;                                      # Hrefs that could not be fixed and so were ameliorated by moving them to @xtrf
  my @good; $fixed->fixedRefsGood = \@good;                                     # Hrefs that were fixed by resolving a Guid

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
   {my ($target, $r) = @_;                                                      # Target file, reason
    my $R = &$refDetails($r);
    push @good, [@$R[0..3], $target, @$R[4..$#$R]];                             # Insert target at correct location
    $R
   };

  my $fixXrefByTitle = sub                                                      # Attempt to fix an xref by using its text content to search for a matching title
   {return undef unless -t $node eq q(xref);                                    # Only works for xrefs

    my $xTitle      = nws($node->stringContent);                                # Normalized title from xref node
    if (my $topics  = $xref->titleToFile->{$xTitle})                            # Find the topics that match the title text content
     {my $N         = keys %$topics;                                            # Matching topics

      if ($N == 1)                                                              # Unique matching topic - the original Gearhart Title Method
       {my ($path)  = keys %$topics;
        my $rel     = relFromAbsAgainstAbs($path, $sourceFile);                 # Relative file name
        $node->href = $rel;                                                     # Update xref
        return &$good($path, q(Fixed by Gearhart Title Method));                # Report the fix made
       }
      elsif ($N > 1)                                                            # Multiple matches
       {if (my $l = fileLargestSize(sort keys %$topics))                        # Boldly choose the topic with the largest size to resolve the ambiguity on the basis that it is probably the most interesting
         {my $rel = relFromAbsAgainstAbs($l, $sourceFile);                      # File name of target topic relative to source file
          $node->href = $rel;                                                   # Update reference
          return &$good($l, q(Fixed by Gearhart Bold Title Method));            # Report the fix made
         }
       }
     }
    undef                                                                       # Failed
   };

  my $locateUniqueTopicSourceForTargetFile = sub                                # Unique source file in the input corpus corresponding to the specified target file else undef.  There could be multiple such files because of flattening: if there are then they are all supposed to be identical and so any one of them should do.
   {my ($targetFile) = @_;                                                      # The target file we want to locate a unique source file from
    my $inputFiles = $xref->targetTopicToInputFiles->{$targetFile};             # Input files corresponding to target file
    return undef unless $inputFiles;                                            # Only if we have input files corresponding to this target file
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

    if (my $docType = $xref->docType->{$sourceFile})                            # Must be a bookmap
     {if ($docType !~ m(map\Z)s)
       {lll "Not a bookmap: $sourceFile";
        return undef;
       }
     }
    else
     {lll "Not a file known to xref: $sourceFile";
      return undef;
     }

    if (my $bookMapSource = &$locateUniqueTopicSourceForTargetFile($sourceFile))# Source of the book map
     {my $sourceTopic = absFromAbsPlusRel($bookMapSource, $ref);                # Source topic relative to source bookmap

      if (my $sourceTarget = $xref->sourceTopicToTargetBookMap->{$sourceTopic}) # Target of source topic via targets/ folder
       {my $sourceDocType    = $sourceTarget->{sourceDocType} // q();           # Source document type
        my $sourceTargetType = $sourceTarget->{targetType}    // q();           # Target document type
        if ($sourceDocType !~ m(map\Z)s and $sourceTargetType =~ m(\Abookmap\Z))# Replace this chapter or topic with the content of the book map generated to represent a non bookmap topic that was split into several sub topics described by a bookmap
         {if (my $generatedBookMap = $sourceTarget->{target})
           {if (my $x = Data::Edit::Xml::new($generatedBookMap))                # Parse the generated bookmap for chapters
             {if ($x->at_bookmap)
               {if (my @c = $x->c_chapter)                                      # Chapters
                 {for my $c(reverse @c)                                         # Copy chapters
                   {$node->putFirstCut($c);
                   }
                  $node->unwrap;                                                # Unwrap the referencing topic
                 }
               }
              else
               {lll "Expected bookmap, got:", $x->tag,
                    "sourceDocType=$sourceDocType from file:\n$b";
               }
             }
            return &$good(q(), q(Expanded representative bookmap));             # Record the fix made
           }
          else
           {lll "Generated bookmap does not exist $generatedBookMap";
           }
         }
        else                                                                    # Not a bookmap so just upgrade href
         {my $path = $sourceTarget->{target};
          $node->href = relFromAbsAgainstAbs($path, $sourceFile);
          return &$good($path, q(Unique target from bookmap));                  # Record the fix made
         }
       }
     }
    else
     {lll "No source for $sourceFile\n";
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
     {if (my $referencedTarget = fileLargestSize(sort keys %$new))              # Boldly assume that the largest possible target is the one we want
       {my $link = relFromAbsAgainstAbs($referencedTarget, $sourceFile);        # Create relative link from book map
        $node->set($attr=>$link);# if $xref->fixBadRefs;                        # Reset reference - we know fixDitaRefs is true.
        &$good($link, q(unique target));                                        # Record successful fix
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
        $node->set($attr=>$href);# if $xref->fixBadRefs;                        # Reset href - we know fixDitaRefs is true.
        &$good($new, q(Unique target for file ref));                            # Record the fix made
        return 1;                                                               # Record the fix made
       }
     }

    if ($xref->allowUniquePartialMatches && $attr !~ m(\Aconref)s)              # Partial matching - i.e ignoring the stuff to the right of the # in the reference sometimes produces a unique result.
     {return &$fixOnePartialDitaRef($ref =~ s(#.*\Z) ()rs);                     # Try to resolve reference as a partial re
     }

    undef                                                                       # Failed
   };

  my $fixRelRef = sub                                                           # Attempt to fix a reference broken by relocation
   {my ($R, $rest) = split m(#)s, $ref, 2;                                      # Get referenced file name
    if ($R)
     {my $r = fne($R);                                                          # Href file base name
      if (my $F = $xref->baseFiles->{$r})                                       # Relocated else where
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
            my $saveRef = $ref; $ref = $newLink;                                # Try fixing the relocated reference as a dita reference.
            my $r = &$fixOneFullDitaRef;
            $ref = $saveRef;
            return $r;
           }
         }
       }
     }
    undef                                                                       # Failed
   };

  my $fixOneRef = sub                                                           # Fix one unresolved reference either by ameliorating it or by moving it to the xtrf attribute thereby putting it in M3.
   {return unless $xref->fixRefs->{$sourceFile}{$ref};                          # Fix not requested for this reference

    if ($xref->deguidize and $ref =~ m(GUID-)is)                                # On a guid and deguidization allowed so given g1#g2/id convert g1 to a file name by locating the topic with topicId g2.
     {my @refs = split /\s+/, $ref;                                             # There might be multiple references in the href
      my @unresolved;                                                           # Unresolved targets
      my @resolved;                                                             # Resolved targets

      for my $subRef(@refs)                                                     # Each reference in the reference
       {my ($guid, $rest) = split /#/, $subRef;
        if (my $target = $xref->guidToFile->{$guid})                            # Target file associated with guid
         {my $link = relFromAbsAgainstAbs($target, $sourceFile);                # Relative link
          $link .= q(#).$rest if $rest;                                         # Remainder of reference which does not change as it is not file related
          if (!@resolved)                                                       # First resolution
           {$node->set($attr=>$link);                                           # New href or conref
            &$good($target, q(Deguidized reference));                           # Report fix made
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

      if ($xref->changeBadXrefToPh)                                             # Change bad xref to ph if requested
       {if ($node->at_xref)
         {$node->change_ph;
         }
       }
      &$bad(q(No such target));                                                 # Report failure
     }
    else                                                                        # ffff - Fix not requested so href left alone
     {&$bad(q(Not fixable));                                                    # Unable to fix the reference using any known method
     }
   };

  my $x = Data::Edit::Xml::new($sourceFile);                                    # Parse xml - should parse OK else otherwise how did we find out that this file needed to be fixed
  my $s = -p $x;                                                                # Source before any changes

  $x->by(sub                                                                    # Check any references encountered on each node, Ameliorate some specific cases. If the reference is still invalid report the discrepancy.
   {my ($o) = @_;                                                               # Current node
    $node   = $o;                                                               # Make current node available globally
    my $t   = $node->tag;                                                       # Tag
    if ($t  =~  m(\A(appendix|chapter|image|link|mapref|topicref|xref)\Z)is)    # Hrefs that need to be fixed
     {if ($ref = $node->attr($attr = q(href)))                                  # The attribute and reference to ameliorate or fix
       #if ($t =~  m(\A(appendix|chapter|topicref)\Z)is)                        # Fix bookmap hrefs
       {if ($t =~  m(\A(appendix|chapter|mapref|topicref)\Z)is)                 # Fix bookmap hrefs
         {&$fixBookMapDitaRef or &$fixOneRef;                                   # Fix references to topics cut into multiple pieces and now represented by a bookmap
         }
        elsif ($t =~ m(\Aimage\Z)is)                                            # Check image references
         {&$checkImageRef or &$fixOneRef;                                       # No additional fixes available yet for images, as so far, the resolution of images is done in thee calling frame work.  Hence we only need to check whether the reference is valid and if it is not then the standard techniques can be applied and the results reported as usual.
         }
        else                                                                    # Fix hrefs without the benefit of the targets/ folder
         {&$fixOneFullDitaRef or &$fixOneRef;                                   # Fix references not in a bookmap
         }
       }
      elsif ($t =~ m(\Axref\Z)s and $xref->fixXrefsByTitle and &$fixXrefByTitle)# Try to fix a missing xref by title
       {
       }
     }
    if ($ref = $node->attr($attr = q(conref)))                                  # Fix a conref
     {&$fixOneFullDitaRef or &$fixOneRef;
     }
    if ($ref = $node->attr($attr = q(conrefend)))                               # Fix a conrefend
     {&$fixOneFullDitaRef or &$fixOneRef;
     }
   });

  if (my $S = -p $x)                                                            # Source after any changes
   {if ($S ne $s)                                                               # Write any changes - seems to be slightly faster than not checking
     {if (onAwsSecondary)                                                       # Write output to temporary folder regardless so it can be copied enmasse back to the session leader
       {my $f = swapFolderPrefix($sourceFile,                                   # Output file name
         $xref->inputFolder, $xref->fixedFolderTemp);
        editXml($sourceFile, $f, $S);                                           # Write the fixed file to the fixedFolder retaining headers and trailers
       }
      elsif (my $fixedFolder = $xref->fixedFolder)                              # New output file in fixedFolder
       {my $f = swapFolderPrefix($sourceFile, $xref->inputFolder, $fixedFolder);# Output file name
        editXml($sourceFile, $f, $S);                                           # Write the fixed file to the fixedFolder retaining headers and trailers
       }
      else
       {editXml($sourceFile, $sourceFile, $S);                                  # Edit existing xml retaining headers and trailers
       }
     }
   }

  $fixed                                                                        # Results of fixing this file
 } # fixReferencesInOneFile

sub fixReferencesParallel($$)                                                   #P Fix the references in one file
 {my ($xref, $file) = @_;                                                       # Cross referencer, file to fix

  newXref;                                                                      # Recreate Xref LVALUE methods

  if (my $d = $xref->fixedFolderTemp)                                           # Create the folder to be used for fixed files
   {makePath($d);
   }

  my $x = $xref->fixReferencesInOneFile($file);
  newXref(fixedRefsGood => $x->fixedRefsGood,
          fixedRefsBad  => $x->fixedRefsBad);
 };

sub fixReferencesResults($@)                                                    #P Consolidate the results of fixing references.
 {my ($xref, @results) = @_;                                                    # Cross referencer, results from fixReferencesInParallel
  newXref;                                                                      # Recreate LVALUE methods

  $xref->fixedRefsBad  = [];
  $xref->fixedRefsGood = [];
  for my $x(@results)
   {push $xref->fixedRefsBad ->@*, $x->fixedRefsBad ->@*;
    push $xref->fixedRefsGood->@*, $x->fixedRefsGood->@*;
   }

  if (onAwsPrimary)                                                             # Recover fixed files from secondary instances
   {my $s = $xref->fixedFolderTemp;
    makePath($s);
    my $t = $xref->fixedFolder // $xref->inputFolder;
    awsParallelGatherFolder($s);                                                # Recover fixed files from secondaries
    mergeFolder($s, $t);                                                        # Merge fixed files into the target area
   }

  $xref
 }

sub fixReferences($)                                                            #P Fix just the file containing references using a number of techniques and report those references that cannot be so fixed.
 {my ($xref) = @_;                                                              # Xref results
  my $startTime = time;                                                         # Time each block

  if (1)                                                                        # Map titles to files for the Gearhart Title Method
   {my %titleToFile;                                                            # Titles to file
    if (my $xrefTitle = $xref->title)
     {for my $file(keys %{$xrefTitle})                                          # Title for each file
       {if (my $tag = $xref->docType->{$file})                                  # Document type for file
         {if ($tag !~ m(map\Z)s)                                                # Ignore maps as we want the topic in the map not the map.
           {$titleToFile{nws($xrefTitle->{$file})}{$file}++;                    # Record title to topic
           }
         }
       }
     }

    $xref->titleToFile = \%titleToFile;                                         # Record titles to files

    if (1)                                                                      # Report titles with duplicated titles
     {my @r;

      for my $t(sort keys %titleToFile)
       {my %f = %{$titleToFile{$t}};
        if (my @f = sort keys %f)
         {if (@f > 1)
           {push @r, map {[$t, $_]} @f;
           }
         }
       }

      formatTables($xref, \@r,
        columns => <<END,
Title   Topic title
File    Topic file
END
        title => qq(Topics with duplicate titles),
        head  => <<END,
Xref noted NNNN topics have duplicated titles on DDDD
END
        clearUpLeft=>1,
        file=>(fpe(qw(bad topics_with_duplicated_titles txt))));
     }
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
      my $bookMapTarget = $bookMap->{target}        // q();                     # The target bookmap
      my $sourceDocType = $bookMap->{sourceDocType} // q();                     # The docType of the source input file if known
      my $targetType    = $bookMap->{targetType}    // q();                     # The target type, initially just a bookmap, now extended to include topics and images

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
    my $xrefIds = $xref->ids;
    for my $targetFile(keys %$xrefIds)                                          # Each target file with an id in it
     {if (my $sourceFiles = $targetToSource{$targetFile})                       # Originating source files for this target file
       {for my $sourceFile(keys %$sourceFiles)                                  # Each originating source files for this target file
         {for my $id(keys $xrefIds->{$targetFile}->%*)                          # Each id in the target file
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

    formatTables($xref, \@r,
      columns => <<END,
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
      file=>(fpe(qw(lists source_to_targets txt))));

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

      formatTables($xref, \@r,
        columns => <<END,
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
        file      => fpe(qw(lists topic_flattening txt)));
     }
   }

  if ($xref->fixRelocatedRefs)                                                  # Load base file name to full name but if needed to do relocation fixes
   {my %baseFiles;                                                              # Map base files back to full files. The base file is the file name shorn of the path - the reason the GB Standard is so important
    for my $file(searchDirectoryTreesForMatchingFiles($xref->inputFolder))      # All input files
     {my $base = fne $file;                                                     # Base file name - the GB Standard name for the file
      $baseFiles{$base}{$file}++;                                               # Current location of the file
     }
    $xref->baseFiles = \%baseFiles;
   }

  my @bad;                                                                      # Hrefs that could not be fixed and so were ameliorated by moving them to @xtrf
  my @good;                                                                     # Hrefs that were fixed by resolving a Guid
  if (my @files = sort keys %{$xref->fixRefs})                                  # Fix files if requested
   {awsParallelProcessFiles $xref,                                              # Fix files in parallel
      \&fixReferencesParallel,                                                  # Fix one file
      \&fixReferencesResults,                                                   # Consolidate results
      [@files];

    @good = $xref->fixedRefsGood->@*;                                           # Results from fixReferencesResults
    @bad  = $xref->fixedRefsBad ->@*;
   }

  @good = sort {join(' ', @$a) cmp join(' ', @$b)} @good;
  @bad  = sort {join(' ', @$a) cmp join(' ', @$b)} @bad;

  my $fbr   = $xref->fixBadRefs;                                                # Are we fixing bad refs?
  my $facet = q(Dita references);

  formatTables($xref, $xref->fixedRefsBad = \@bad,                              # Report references we cannot fix
    columns   => <<END,
Reason         The reason the reference was not fixed
Tag            The tag of the node in which the reference failure occurs
Attr           The attribute of the node in which the reference failure occurs
Reference      The reference not being fixed
File           The file in which the reference appears
Source_Files   One or more source files that from which this file was derived
END
    summarize => 1,
    title     => q(Invalid references),
    facet     => $facet,  aspectColor => q(red),
    head      => $fbr ? <<END : <<END2,
Xref moved NNNN invalid references to M3 on DDDD as fixBadRefs=>$fbr was specified
END
Xref was unable to resolve NNNN failing references on DDDD, fixBadRefs=> was not specified
END2
    zero      => 1,
    file      => fpe(qw(bad failing_references txt)));

  formatTables($xref, $xref->fixedRefsGood = \@good,                            # Report hrefs which were failing but were successfully resolved by ingenuity.
    columns   => <<END,
Method         The way that the reference was fixed
Tag            The tag of the node on which the reference was fixed
Attr           The attribute being fixed - normally href
Ref            The reference that is being resolved
Target_File    The file the reference resolves to.
File           The file in which the reference appears
Source_Files   The source files that gave rise to the file containing the reference after file flattening
END
    summarize => 1,
    title     => qq(These failing references were successfully resolved),
    facet     => $facet, aspectColor => q(green),
    head      => <<END,
Xref successfully resolved NNNN previously failing references on DDDD
END
    zero      => 1,
    file      => fpe(qw(good fixed_references txt)));

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

  my $target = fpf($xref->flattenFolder, $xref->flattenFiles->{$file});         # Previously assigned GB name.  We cannot use the very latest name because other files have to be told about it and in changing them to reflect the latest name we would change their name as well.  So close has to be good enough.
  editXml($file, $target, -p $x);                                               # Edit xml

  \@r                                                                           # Return report of items fixed
 }

sub fixFilesGB($)                                                               #P Rename files to the L<GBStandard>
 {my ($xref) = @_;                                                              # Xref results
  my @files  = grep {!$xref->parseFailed->{$_}} sort @{$xref->inputFiles};      # Fix files that parsed if requested

  my @r;                                                                        # Fixes made
  processFilesInParallel
    sub                                                                         # Each file
     {my ($file) = @_;                                                          # File to analyze
      $xref->fixOneFileGB($file);                                               # Analyze one input file
     },
    sub {push @r, deSquareArray @_}, @files;                                    # Flatten results

  formatTables($xref, $xref->fixedRefsGB = \@r,                                 # Report results
    columns => <<END,
Href           The href being fixed
Source         The source file containing the href
END
    summarize=>1,
    title=>qq(Hrefs that can not be renamed to the Gearhart-Brenan file naming standard),
    head=><<END,
Xref failed to fix NNNN hrefs to the Gearhart-Brenan file naming standard
END
    file=>(my $f = fpe(qw(bad fixedRefsGB txt))));

   {fixedRefsGB => $xref->fixedRefsGB,                                          # From multiverse to universe
   }
 } # fixFilesGB

sub analyzeOneFileParallel($$)                                                  #P Analyze one input file
 {my ($Xref, $iFile) = @_;                                                      # Xref request, File to analyze

  my $xref = newXref();                                                         # Cross referencer for this file
#    $xref->sourceFile = $iFile;                                                # File analyzed
  my %maxZoomIn = $Xref->maxZoomIn ?  %{$Xref->maxZoomIn} : ();                 # Regular expressions from maxZoomIn to look for text
  my %maxZoomOut;                                                               # Text elements that match a maxZoomIn regular expression
  my %countAttrNames;                                                           # Attribute names
  my %countAttrNamesAndValues;                                                  # Attribute names and values
  my %countTagNames;                                                            # Tag names
  my $changes;                                                                  # Changes made to the file
  my $tags; my $texts;                                                          # Number of tags and text elements

  my $source = readFile($iFile);                                                # Source of file so we can gets its GB Standard name

  my $x = eval {Data::Edit::Xml::new($iFile)};                                  # Parse xml - at this point if the caller is interested in line numbers they should have added them.

  if ($@)                                                                       # Check we were able to parse the xml
   {$xref->parseFailed->{$iFile}++;
    return $xref;
   }

  my $md5 = $xref->md5Sum->{$iFile} = -M $x;                                    # Md5 sum for parse tree

  if ($Xref->flattenFolder)
   {$xref->flattenFiles->{$iFile} =                                             # Record correspondence between existing file and its GB Standard file name
      Dita::GB::Standard::gbStandardFileName($source, fe($iFile), md5=>$md5);
   }

  my $saveReference = sub                                                       # Save a reference so it can be integrity checked later
   {my ($ref) = @_;                                                             # Reference
    return if externalReference($ref);                                          # Looks like an external reference
    $xref->references->{$iFile}{$ref}++;                                        # Save reference
   };

  my $isADitaMap = $x->isADitaMap;                                              # Map

  $x->by(sub                                                                    # Each node
   {my ($o) = @_;

#    my $content = sub                                                          #P First few characters of content on one line to avoid triggering multi table layouts
#     {my ($o) = @_;                                                            # String
#      nws($o->stringContent, improvementLength);                               # Length of improvement
#     };

    my $tag = -t $o;                                                            # Element tag
    if ($tag eq q(CDATA)) {++$texts} else {++$tags}                             # Count texts and tags

    if (my $h = $o->href)                                                       # Check href
     {if ($h =~ m(\s)s and externalReference($h))                               # Check href for url encoding needed
       {$xref->{hrefUrlEncoding}{$iFile}{$o->lineLocation} = $h;
       }
      if ($xref->{deguidize} and $h =~ m(\bguid-)is)                            # Deguidizing a href that looks as if it might have a guid in it
       {$xref->{fixRefs}{$iFile}{$h}++
       }
      &$saveReference($h);
     }

    if (my $conref = $o->attr(q(conref)))                                       # Conref
     {my $saveConRef = sub                                                      # Save a conref
       {my ($conRef) = @_;                                                      # Conref
        $xref->{conRefs}{$iFile}{$conRef}{$tag}++;
       };

      &$saveConRef($conref);
      &$saveReference($conref);

      if (my $conref = $o->attr(q(conrefend)))                                  # Conref end
       {&$saveConRef($conref);
        &$saveReference($conref);
       }
     }

    if (my $i = $o->id)                                                         # Id definitions
     {$xref->{ids}{$iFile}{$i}++;
      push $xref->{idTags}{$iFile}{$i}->@*, $tag;                               # Tags for each id in the file
     }

    if ($tag eq q(xref))                                                        # Xrefs but not to the web
     {if (my $h = $o->href)
       {if (externalReference($h))                                              # Check attributes on external links
         {if ($o->attrX(q(scope)) !~ m(\Aexternal\Z)s)
           {$xref->{xrefBadScope}{$iFile}{$h} = -A $o;
           }
          if ($o->attrX(q(format)) !~ m(\Ahtml\Z)s)
           {$xref->{xrefBadFormat}{$iFile}{$h} = -A $o;
           }
         }
        elsif ($h =~ m(\Aguid-)is)                                              # Href is a guid
         {$xref->{guidHrefs}{$iFile}{$h} = [$tag, $o->lineLocation];
         }
        else #if ($o->attrX_format =~ m(\Adita)i)                               # Check xref has format=dita
         {$xref->{xRefs}{$iFile}{$h}{$o->stringText}++;
         }
       }
      else
       {push @{$xref->{noHref}{$iFile}}, [$tag, $o->lineLocation, $iFile];      # No href
        $xref->{fixRefs}{$iFile}{q()}++                                         # Try and fix by the Gearhart Title method augmented by the Monroe Map Method
       }
     }
    elsif ($isADitaMap and $tag =~ m(\A(appendix|chapter|link|mapref|notices|topicref)\Z)is) # References from bookmaps at 2019.11.10 22:58:24 as mapref can be used in a topic
     {if (my $h = $o->href)
       {if ($h =~ m(\Aguid-)is)                                                 # Href is a guid
         {$xref->{guidHrefs}{$iFile}{$h} = [$tag, $o->lineLocation];
         }
        else
         {$xref->{bookMapRefs}{$iFile}{$h}{$o->attr_navtitle//$o->stringText}++;
         }
       }
      elsif ($tag ne q(notices))                                                # Notices is often positioned in a bookmap and left empty for author convenience
       {push @{$xref->{noHref}{$iFile}}, [$tag, $o->lineLocation, $iFile];      # No href
       }
     }
    elsif ($tag eq q(image))                                                    # Images
     {if (my $h = $o->href)
       {if ($h =~ m(\Aguid-)is)                                                 # Href is a guid
         {$xref->{guidHrefs}{$iFile}{$h} = [$tag, $o->lineLocation];            # Resolve image later
         }
        else
         {$xref->{images}{$iFile}{$h}++;
         }
        $xref->{imagesReferencedFromTopics}{$iFile}{$h}++;                      # Image referenced from a topic
       }
      else
       {push @{$xref->{noHref}{$iFile}}, [$tag, $o->lineLocation, $iFile];      # No href
       }
     }
    elsif ($tag eq q(required-cleanup))                                         # Required cleanup
     {$xref->{requiredCleanUp}{$iFile}{nws($o->stringContent)}++;
     }
    elsif ($tag eq q(title) and $o->parent == $x)                               # Title
     {$xref->{title}{$iFile} = $o->stringContent;                               # Topic Id
     }
    elsif ($tag eq q(mainbooktitle))                                            # Title for bookmaps
     {$xref->{title}{$iFile} //= $o->stringText;
     }
    elsif ($tag eq q(author))                                                   # Author
     {$xref->{author}{$iFile} = $o->stringContent;
     }
    elsif ($tag eq q(ol))                                                       # Ol
     {if (my $p = $o->parent)
       {if ($p->tag =~ m(body\Z)s)
         {$xref->{olBody}{$iFile}++;
         }
       }
     }
    elsif ($tag eq q(tgroup))                                                   # Tgroup cols
     {my $error = sub                                                           # Table error message
       {push @{$xref->{badTables}},
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
      if ($maxCols and my $rows = $stats->rows)                                 # Count table sizes
       {$xref->{tableDimensions}{$iFile}{$maxCols}{$rows}++;
       }
     }
    elsif ($tag =~ m(\Aothermeta\Z))                                            # Other meta tags
     {my $c = $o->attrX(q(content));
      my $n = $o->attrX(q(name));
      $xref->{otherMeta}{$iFile}{$n}{$c}++;
     }
    elsif ($tag =~ m(body\Z) and $o->isAllBlankText)                            # Empty body
     {$xref->{emptyTopics}{$iFile}++;
     }
    elsif ($o->isText)                                                          # Not much interest - obscured at the start of this 'if' statement - Check text for interesting constructs
     {my $t = $o->text;
      my @l = $t =~ m(&lt;(.*?)&gt;)g;
      for my $l(@l)
       {$xref->{ltgt}{$iFile}{$l}++;
       }
      if (keys %maxZoomIn)                                                      # Search for text using Micaela's Max Zoom In Method
       {for my $name(sort keys %maxZoomIn)                                      # Each regular expression to check
         {my $re = $maxZoomIn{$name};
          if ($t =~ m($re)is)
           {$maxZoomOut{$name}++
           }
         }
       }
     }

    if (my $a = $o->{attributes})                                               # Count tags, attributes, attribute values
     {for my $k(sort keys %$a)
       {$countAttrNames{$k}++;
        if (my $v = $$a{$k})
         {$countAttrNamesAndValues{$k}{$v}++;
         }
       }
      $countTagNames{$tag}++;
     }
   });

  $xref->maxZoomOut->{$iFile} = \%maxZoomOut;                                   # Save max zoom

  my $docType = parseXmlDocType($source);                                       # Get DocType details

  $xref->attributeCount              ->{$iFile} = \%countAttrNames;             # Attribute names
  $xref->attributeNamesAndValuesCount->{$iFile} = \%countAttrNamesAndValues;    # Attribute names and values
  $xref->tagCount                    ->{$iFile} = \%countTagNames;              # Tag names
  $xref->baseTag                     ->{$iFile} = $x->tag;                      # Tag on base node
  $xref->docType                     ->{$iFile} = $x->tag;                      # Document type
  $xref->publicId                    ->{$iFile} = $docType->{publicId};         # Public id on Doctype
  $xref->tags                        ->{$iFile} = $tags;                        # Number of tags
  $xref->texts                       ->{$iFile} = $texts;                       # Number of texts
  $xref->topicIds                    ->{$iFile} = $x->id;                       # Topic Id
  $xref->vocabulary                  ->{$iFile} = $x->stringTagsAndText         # Text of topic minus attributes
     if !$isADitaMap and $Xref->indexWords||$Xref->matchTopics;                 # Maps tend not to have any matchable text in them.

  if (my @urls = $source =~ m(["'](https?://[^"']*?)["'])g)                     # Urls found in file
   {$xref->urls->{$iFile} = {map {$_=>1} @urls};
   }

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
 } # analyzeOneFileParallel

sub analyzeOneFileResults($@)                                                   #P Merge a list of cross reference results into the first cross referencer in the list
 {my ($xref, @x) = @_;                                                          # Cross referencer to merge into, other cross referencers

  newXref;                                                                      # Create LVALUE methods

  my @fields = (                                                                # Fields to be merged
q(attributeCount),
q(attributeNamesAndValuesCount),
q(author),
q(badXml1),
q(badXml2),
q(baseTag),
q(conRefs),
q(docType),
q(emptyTopics),
q(fixRefs),
q(flattenFiles),
q(guidHrefs),
q(hrefUrlEncoding),
q(ids),
q(idTags),
q(images),
q(imagesReferencedFromTopics),
q(ltgt),
q(maxZoomOut),
q(md5Sum),
q(noHref),
q(olBody),
q(otherMeta),
q(parseFailed),
q(publicId),
q(references),
q(requiredCleanUp),
q(tableDimensions),
q(tagCount),
q(tags),
q(texts),
q(title),
q(topicIds),
q(bookMapRefs),
q(targetTopicToInputFiles),
q(urls),
q(validationErrors),
q(vocabulary),
q(xrefBadFormat),
q(xrefBadScope),
q(xRefs),
 );

  my $ip = awsCurrentIp;
  my @times;                                                                    # Time for each merge

  if (@x > 10)                                                                  # Merge in parallel if there are enough items to merge - 10 tests Xref but allows final merge to occur in series
   {my $fields = @fields;
    my $q = newProcessStarter($xref->maximumNumberOfProcesses);                 # Process starter
       $q->processingTitle   = q(Xref Analyze Merge on ip: $ip);
       $q->totalToBeStarted  = $fields;

    if (my $reports = $xref->reports)                                           # Log file for merge
     {$q->processingLogFile  = fpe($reports, qw(log xref analyzeMerge txt));
     }

    for my $field(@fields)                                                      # Merge hashes by file names which are unique - ffff
     {$q->start(sub
       {my $startTime = time;
        my $target = $xref->{$field} //= {};                                    # Field to be merged
        for my $x(@x)                                                           # Merge results from each file analyzed
         {if (my $xf = $x->{$field})
           {for my $f(keys %$xf)                                                # Each file analyzed
             {$target->{$f} = $xf->{$f}                                         # Merge
             }
           }
         }
        [$field, $xref, time - $startTime]                                      # Return results as a reference
       });
     }
    my @merge = $q->finish;                                                     # Load results

    for my $m(@merge)
     {my ($f, $x, $t) = @$m;
      $xref->{$f} = $x->{$f};
      push @times, [$f, $t];
     }
   }
  else                                                                          # Merge in series
   {for my $field(@fields)                                                      # Merge hashes by file names which are unique - ffff
     {my $startTime = time;
      my $target = $xref->{$field} //= {};                                      # Field to be merged
      for my $x(@x)                                                             # Merge results from each file analyzed
       {if (my $xf = $x->{$field})
         {for my $f(keys %$xf)                                                  # Each file analyzed
           {$target->{$f} = $xf->{$f}                                           # Merge
           }
         }
       }
      push @times, [$field, time - $startTime]                                  # Save merge times
     }
   }

  formatTables($xref, [sort {$$b[1] <=> $$a[1]} @times],
    columns => <<END,
Field Xref field merge
Time  Time in seconds to merge this field
END
    title=>qq(Field merging elapsed times in descending order),
    head =>qq(Xref field merging took the following times on DDDD),
    file =>fpe(q(timing), qw(merges txt)));

  for my $field(                                                                # Merge arrays
    qw(badTables))
   {for my $x(@x)                                                               # mmmm Merge results from each file analyzed
     {next unless my $xf = $x->{$field};
      push @{$xref->{$field}}, @$xf;
     }
   }

  $xref
 } # analyzeOneFileResults

sub analyzeInputFiles($)                                                        #P Analyze the input files
 {my ($xref) = @_;                                                              # Cross referencer

  awsParallelProcessFiles
   ($xref,
   \&analyzeOneFileParallel,
   \&analyzeOneFileResults,
    $xref->inputFiles);

 } # analyzeInputFiles

# 63.128s Salesforce restructure on one instance

sub reportIdRefs($)                                                             #P Report the number of times each id is referenced
 {my ($xref) = @_;                                                              # Cross referencer

  my %n;                                                                        # Ids that might not be referenced
  if (my $xrefIds = $xref->ids)
   {for   my $f(sort keys %{$xrefIds})                                          # Each input file
     {for my $i(sort keys %{$xrefIds->{$f}})                                    # Each id in each input file
       {$n{$f}{$i}++;                                                           # Ids that might not be referenced
       }
     }
   }

  my %c;                                                                        # Count of how often each id in each file was referenced
  if (my $xrefReferences = $xref->references)
   {for   my $f(sort keys %{$xrefReferences})                                   # Each input file
     {for my $r(sort keys %{$xrefReferences->{$f}})                             # Each reference from each input file
       {my ($rf, $rt, $ri) = parseDitaRef($r, $f);                              # Parse reference
        if ($ri)                                                                # If this is an id not a topic id
         {       $c{$rf}{$ri} += $xrefReferences->{$f}{$r};                     # Count id references
          delete $n{$rf}{$ri};                                                  # Remove ids that get referenced
         }
       }
     }
   }

  my @n; my $notTopicIds = 0;                                                   # Ids not referenced
  for   my $f(sort keys %n)                                                     # Each input file
   {my $topicId = $xref->topicIds->{$f} // q();
    for my $i(sort keys %{$n{$f}})                                              # Each unreferenced id in each input file
     {my $t = $i eq $topicId ? "**" : q();                                      # Show ids which are topic ids
      ++$notTopicIds unless $t;                                                 # Count non topic ids that are not referenced
      push @n, [$t, $i, $f];                                                    # Report as topicId or not, id, file
     }
   }

  my @c;
  for   my $f(sort keys %c)                                                     # Each input file
   {for my $i(sort keys %{$c{$f}})                                              # Each referenced id in each input file
     {push @c, [$c{$f}{$i}, $i, $f];                                            # Report as count, id, file
     }
   }

  my $facet = q(Ids referenced);

  formatTables($xref, \@n,
    columns   => <<END,
TopicId If this id is a topic id then this column will have ** in it.
Id      The id that has not been referenced
File    The file containing the id that has not been referenced
END
    title     => qq(Ids that have not been referenced),
    facet     => $facet, aspectColor=>q(red),
    head      => <<END,
Xref found $notTopicIds unreferenced ids on DDDD

The $notTopicIds ids below which are not marked with ** are not referenced by
any other file in this corpus and thus should be considered for removal.

END
    summarize => 1, csv => 1,
    file      => fpe(qw(bad ids_not_referenced txt)));

  formatTables($xref, \@c,
    columns   => <<END,
Count  The number of times this id is referenced
Id     The id in question
File   The file in which the id appears
END
    title     => qq(Ids referenced),
    facet     => $facet, aspectColor=>q(green),
    head      => <<END,
Xref found NNNN ids are being referenced on DDDD

END
    summarize => 1, csv => 1,
    file      => fpe(qw(good id_reference_counts txt)));

   {idReferencedCount => \%c,                                                   # From multiverse to universe
    idNotReferenced   => \%n,
   }
 } # reportIdRefs

sub removeUnusedIds($)                                                          #P Remove ids that do are not mentioned in any href or conref in the corpus regardless of the file component of any such reference. This is a very conservative approach which acknowledges that writers might be looking for an id if they mention it in a reference.
 {my ($xref) = @_;                                                              # Cross referencer

  my %keep;                                                                     # {id}++ : id to be kept as it occurs in a reference some where
  if (my $xrefReferences = $xref->references)
   {for   my $f(sort keys $xrefReferences->%*)                                  # Each input file with references
     {for my $r(sort keys $xrefReferences->{$f}->%*)                            # Each id in each input file with references
       {my (undef, undef, $i) = parseDitaRef($r);                               # Ids to keep as they might be referenced now or soon
        $keep{$i}++
       }
     }
   }

  my %remove;                                                                   # {file}{id}++ : id to be removed from a file
  my %ids;                                                                      # {id}++ : id removed from all files as a consequence of removing it from each file
  if (my $xrefIds = $xref->ids)
   {for   my $f(sort keys $xrefIds->%*)                                         # Each input file
     {for my $i(sort keys $xrefIds->{$f}->%*)                                   # Each id in each input file
       {next if $keep{$i};                                                      # Id that can be deleted as it is never referenced in any form
        $remove{$f}{$i}++;
        $ids   {$i}++
       }
     }
   }

  my $disposition = $xref->deleteUnusedIds ?                                    # Disposition of deletable ids
    q(The deleteUnusedIds option was set on so these ids have been removed.) :
    q(The deleteUnusedIds option was set off so these ids have been retained.);

  formatTables($xref, [map {[$_]} sort keys %ids],
    columns   => <<END,
Id     An unreferenced id
END
    title     => qq(Ids removed),
    head      => <<END,
Xref found NNNN unreferenced ids on DDDD

$disposition
END
    summarize => 1,
    file      => fpe(qw(lists ids_removed txt)));

  processFilesInParallel
   (sub
     {my ($f) = @_;                                                             # File with ids to be removed
      my %i = %{$remove{$f}};                                                   # Ids to remove
      my @remove;                                                               # [id, file] : removed this id in this file
      if (my $x = Data::Edit::Xml::new($f))                                     # Parse file with ids to be removed
       {$x->by(sub
         {my ($o) = @_;
          if ($o != $x and my $i = $o->id)                                      # Keep topic ids
           {if ($i{$i})
             {$o->id = undef;
              push @remove, [$i, $o->tag, $f];                                  # Report id removed
             }
           }
         });
        editXml($f, $f, -p $x) if @remove;
       }
      [@remove]
     },

    sub                                                                         # Consolidate removal report
     {my (@removed) = @_;

      my @r;
      for my $removed(@removed)                                                 # Consolidate each batch of removals
       {push @r, @$removed if $removed;
       }

      formatTables($xref, \@r,
        columns   => <<END,
Id     The id removed
Tag    The tag the removed id was on
File   The file in which the id appeared
END
        title     => qq(Ids removed from files),
        head      => <<END,
Xref removed NNNN unreferenced ids from files on DDDD

Ids are only removed if the id is not mentioned in any reference in the entire
corpus regardless of what file the reference is to.  This is to allow for the
possibility of fixing possibly broken references in the future.

END
        summarize => 1,
        file      => fpe(qw(lists ids_removed_from_files txt)));
     }, sort keys %remove) if $xref->deleteUnusedIds;                           # Remove unused ids unless except on the root element

  {idsRemoved => \%ids,                                                         # Multiverse to universe
  }
 } # removeUnusedIds

sub reportEmptyTopics($)                                                        #P Report empty topics
 {my ($xref) = @_;                                                              # Cross referencer

  my @E;                                                                        # Ids that might not be referenced
  for   my $f(sort keys %{$xref->emptyTopics})                                  # Each empty topic
   {my $d = $xref->docType->{$f};
    my $t = $xref->title->{$f} // q();
    push @E, [$d, $t, $f];
   }

  my @e = sort {$$a[1] cmp $$b[1]} @E;

  formatTables($xref, \@e,
    columns   => <<END,
TopicType The type of topic thatis empty
Title     The title of the empty topic
File      The source file containing the empty topic
END
    title     => <<END,
Empty Topics
END
    head      => <<END,
Xref found NNNN empty topics on DDDD

END
    summarize => 1,
    csv       => 1,
    file      => fpe(qw(lists empty_topics txt)));

   {                                                                            # From multiverse to universe
   }
 } # reportEmptyTopics

sub reportDuplicateIds($)                                                       #P Report duplicate ids
 {my ($xref) = @_;                                                              # Cross referencer

  my @dups;                                                                     # Duplicate ids definitions
  my %dups;
  my %active;  my %removed;                                                     # Active duplicate ids, removable ids
  if (my $xrefIds = $xref->ids)
   {for   my $f(sort keys %$xrefIds)                                            # Each input file
     {for my $i(sort keys  $xrefIds->{$f}->%*)                                  # Each id in the file
       {my $count   = $xrefIds->{$f}{$i};                                       # Number of definitions of this id in the file
        if ($count > 1)                                                         # Duplicate definition
         {if ($xref->idsRemoved->{$i})                                          # Duplicated and being referred to
           {$removed{$i}++;
           }
          else
           {$active{$i}++;
           }
          push @dups, [$i, $count, $active{$i} ? q(**) : q(), $f];              # Save details of duplicate definition
          $dups{$f}{$i} = $count;
         }
       }
     }
   }

  my $A = keys %active;                                                         # Number of possibly active duplicate ids
  my $R = keys %removed;                                                        # Number of ids removed

  my $r = $xref->deleteUnusedIds ? <<END :                                      # Explain active vs inactive ids
$R unused ids are being deleted as they are not active (used in a reference
regardless of the file component of the reference) and Xref was invoked with:

  deleteUnusedIds => 1

The $A active ids that cannot be removed are marked in this report with **.
END
  <<END;
$R unused ids could be deleted as they are not active (used in a reference
regardless of the file component of the reference). To remove these ids from
the entire corpus invoke Xref with:

  deleteUnusedIds => 1

The $A active ids that cannot be so removed are marked in this report with **.
END

  formatTables($xref, \@dups,
    columns => <<END,
Id     The id that has been duplicated
Count  The number of times the id was duplicated
Active ** if this id is possibly being referred to from elsewhere in the corpus.
File   The file in which the duplication occurs
END
    title=>qq(Duplicate id definitions within files),
    head=><<END,
Xref found NNNN duplicate id definitions within files on DDDD

$A of these ids are possibly being referred to - see rows containing **.

Duplicate topic ids are reported in ../bad/topicIds.txt.

$r
END
    summarize=>1, csv=>1,
    file=>(my $f = fpe(qw(bad duplicateIds txt))));

   {duplicateIds => \%dups,
   }                                                                            # From multiverse to universe
 } # reportDuplicateIds

sub reportDuplicateTopicIds($)                                                  #P Report duplicate topic ids
 {my ($xref) = @_;                                                              # Cross referencer

  my %dups;                                                                     # Duplicate topic ids definitions
  my @dups;                                                                     # Duplicate topic ids definitions report
  my @miss;                                                                     # Missing topic id definitions report
  if (my $xrefTopicIds = $xref->topicIds)                                       # Each input file
   {for my $file(sort keys %{$xrefTopicIds})                                    # Each input file
     {if (my $i = $xrefTopicIds->{$file})                                       # Topic Id
       {if (my $d = $dups{$i})                                                  # Duplicate topic id
         {push @dups, [$i, $file, $d];                                          # Save details of duplicate definition
         }
        else
         {$dups{$i} = $file;                                                    # Save topic id
         }
       }
      elsif ($xref->docType->{$file} !~ m(map\Z)s)                              # Maps are not required to have topics ids
       {push @miss, [$file];                                                    # Missing topic id
       }
     }
   }

  my $dups = $xref->duplicateTopicIds = {map {$$_[0]=>$_} @dups};               # All duplicates
  my $miss = $xref->missingTopicIds   = {map {$$_[0]=>$_} @miss};               # All missing

  formatTables($xref, \@dups, columns => <<END,                                 # Duplicate topic ids report
TopicId  The topic id that has been duplicated in File1 and File2
File1    The first file in which the duplicated topic id appears
File2    The second file in which the duplicated topic id appears
END
    title => qq(Duplicate topic id definitions),
    head  => <<END,
Xref found NNNN duplicate topic id definitions on DDDD
END
    file=>(fpe(qw(bad duplicate_topics_ids txt))));

  formatTables($xref, \@miss, columns => <<END,                                 # Missing topic ids report
File  A file containing a topic with no topic id
END
    title=>qq(Topics without ids),
    head=><<END,
Xref found NNNN topics that have no topic id on DDDD

END
    file=>(fpe(qw(bad topic_id_missing txt))));

   {duplicateTopicIds => $dups,
    missingTopicIds   => $miss,
   }
 } # reportDuplicateTopicIds

sub reportNoHrefs($)                                                            #P Report locations where an href was expected but not found
 {my ($xref) = @_;                                                              # Cross referencer
  my @t;
  if (my $xrefNoHref = $xref->noHref)
   {for my $file(sort keys %{$xrefNoHref})                                      # Each input file
     {push @t,             @{$xrefNoHref->{$file}};                             # Missing href details
     }
   }

  formatTables($xref, \@t,
    columns => <<END,
Tag        A tag that should have an xref.
Location   The location of the tag that should have an xref.
File       The source file containing the tag
END
    title=>qq(Missing hrefs),
    head=><<END,
Xref found NNNN tags that should have href attributes but did not on DDDD
END
    file=>(fpe(qw(bad missing_href_attributes txt))));
  {}                                                                            # From multiverse to universe
 } # reportNoHrefs

sub checkReferences($)                                                          #P Check each reference, report bad references and mark them for fixing.
 {my ($xref) = @_;                                                              # Cross referencer

  my @bad;                                                                      # Bad references
  my @good;                                                                     # Good references

  if (my $xrefReferences = $xref->references)
   {for   my $file(sort keys %$xrefReferences)                                  # Each input file which will be absolute
     {for my $ref (sort keys  $xrefReferences->{$file}->%*)                     # Each href in the file which will be relative
       {if (my $r = &oneBadRef($xref, $file, $ref))                             # Check reference
         {push @bad, $r;
          $xref->fixRefs->{$file}{$ref}++;                                      # Request fix attempt for this reference
          $xref->badReferencesCount++;                                          # Number of bad references encountered
         }
        else                                                                    # Good references
         {push @good, [$ref, $file]
         }
       }
     }
   }

  my $facet = q(References between topics at start);

  formatTables($xref, \@bad,                                                    # Report the failing references
    columns => <<END,
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
    title => qq(Bad references at start),
    facet => $facet,  aspectColor=>q(red),
    head  => <<END,
Xref found NNNN bad references on DDDD at the start of processing

Depending on the options chosen, Xref might fix or ameliorate these references
so that the actual number of references with problems is lower than this.  The
best way to find out how many references still need fixing after doing an Xref
run with fixing options enabled is to do another run with all of these options
disabled. The braver elements will be asking why we do not account for these
improvements in flight - that would significantly increase code complexity
while taking a lot of effort to validate yet produce no significant
improvements - so it is much easier not to when a second run suffices.
END
    csv   => 1, wide =>1, summarize=>1,
    file  => fpe(q(bad), q(references), q(txt)));

  formatTables($xref, \@good,                                                   # Report good references
    columns => <<END,
Href            A good href attribute
Source_File     The referencing source file
END
    title => qq(Good references at start),
    facet => $facet,  aspectColor=>q(green),
    head  => <<END,
Xref found NNNN good references on DDDD at the start of processing.
END
    csv   => 1, wide =>1, summarize=>1,
    file  => fpe(q(good), q(references), q(txt)));
#  {}                                                                            # From multiverse to universe  2019.08.29 - no need - we are in series
 } # checkReferences

sub reportGuidHrefs($)                                                          #P Report on guid hrefs
 {my ($xref) = @_;                                                              # Cross referencer

  my %guidToFile;                                                               # Map guids to files
  if (my $xrefTopicIds = $xref->topicIds)
   {for   my $file(sort keys %{$xrefTopicIds})                                  # Each input file containing a topic id
     {my $id = $xrefTopicIds->{$file};                                          # Each href in the file which will start with guid
      next unless defined $id;
      next unless $id =~ m(\bguid-)is;                                          # Check guid appears somewhere in href
      $guidToFile{$id} = $file;                                                 # We report duplicates in reportDuplicateTopicIds
     }
   }

  my @bad; my @good;                                                            # Good and bad guid hrefs
  for   my $file(sort keys %{$xref->guidHrefs})                                 # Each input file which will be absolute
   {my $sourceTopicId = $xref->topicIds->{$file};
    for my $href(sort keys %{$xref->guidHrefs->{$file}})                        # Each href in the file which will start with guid
     {my ($tag, $lineLocation) = @{$xref->guidHrefs->{$file}{$href}};           # Tag of node and location in source file of node doing the referencing
#  2019.08.29 The following line does not appear to be needed - it is happening to late to affect anything
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
         {# 2019.08.29 the following line happens too late to be useful
          $xref->fixRefs->{$file}{$href}++;
         }
        else
         {push @good, [$tag, $href, $lineLocation, $targetFile, $file];
         }
       }
     }
   }

  $xref->badGuidHrefs = {map {$$_[7]=>$_} @bad};                                # Bad references

  my $in = $xref->inputFolder//'';
  formatTables($xref, \@bad,
    columns => <<END,
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
    file     =>(fpe(q(bad), qw(guidHrefs txt))));

  formatTables($xref, \@good,
    columns => <<END,
Tag             The tag containing the href
Href            The href of the node doing the referencing
Line_Location   The line location where the href occurred in the source file
Source_File     The source file containing the reference
Target_File     The target file
END
    title    =>qq(Resolved GUID hrefs),
    head     =>qq(Xref found NNNN Resolved GUID hrefs on DDDD),
    file     =>(fpe(q(good), qw(guidHrefs txt))));

   {badGuidHrefs => $xref->badGuidHrefs,                                        # From multiverse to universe
   }
 } # reportGuidHrefs

sub reportImages($)                                                             #P Reports on images and references to images
 {my ($xref) = @_;                                                              # Cross referencer

  my %bad;                                                                      # Missing images
  for my $fail($xref->fixedRefsBad->@*)                                         # References that failed
   {my ($reason, $type, $attr, $ref, $file) = @$fail;
    next unless $type =~ m(\Aimage\Z)is;
    my $i = absFromAbsPlusRel($file, $ref);
    $bad{$i}++;
   }
  my @bad = map {[$bad{$_}, $_]} sort keys %bad;

  my $facet = q(Image files);

  formatTables($xref, \@bad,                                                    # Report missing images references
    columns   => <<END,
Count        The number of unresolved references to this missing image
Image_File   The file name of the missing image
END
    title     => qq(Missing images),
    facet     => $facet, aspectColor => qw(red),
    head      => qq(Xref found NNNN missing images on DDDD),
    summarize => 1, zero => 1,
    file      => fpe(qw(bad missing_images txt)));


  my %good;                                                                     # Good images
  for   my $topic(sort keys $xref->images->%*)                                  # Topics containing images
   {for my $ref  (sort keys $xref->images->{$topic}->%*)                        # Image references
     {my $i = absFromAbsPlusRel($topic, $ref);
      if (!$bad{$i})
       {$good{$i}++;
       }
     }
   }

  my @good = map {[$good{$_}, $_]} sort keys %good;                             # Report good images

  formatTables($xref, \@good,
    columns   => <<END,
Count       The number of references to this image
Image_File  The file name of the image
END
    title     => qq(Image files),
    facet     => $facet, aspectColor => qw(green),
    head=>qq(Xref found NNNN image files on DDDD),
    summarize => 1, zero => 1,
    file=>(fpe(qw(good image_files txt))));

   {missingImageFiles => \%bad,
    goodImageFiles    => \%good}

 } # reportImages

sub reportParseFailed($)                                                        #P Report failed parses
 {my ($xref) = @_;                                                              # Cross referencer

  formatTables($xref,
    hashOfCountsToArray($xref->parseFailed),
    columns => <<END,
Source The file that failed to parse as an absolute file path
END
    title=>qq(Files failed to parse),
    head=>qq(Xref found NNNN files failed to parse on DDDD),
    file=>(my $f = fpe(qw(bad parseFailed txt))));
  {}                                                                            # From multiverse to universe
 } # reportParseFailed

sub reportXml1($)                                                               #P Report bad xml on line 1
 {my ($xref) = @_;                                                              # Cross referencer

  formatTables($xref, [map {[$_]} sort keys %{$xref->badXml1}],
    columns => <<END,
Source  The source file containing bad xml on line
END
    title=>qq(Bad Xml line 1),
    head=>qq(Xref found NNNN Files with the incorrect xml on line 1 on DDDD),
    file=>(my $f = fpe(qw(bad xmlLine1 txt))));
  {}                                                                            # From multiverse to universe
 } # reportXml1

sub reportXml2($)                                                               #P Report bad xml on line 2
 {my ($xref) = @_;                                                              # Cross referencer

  formatTables($xref, [map {[$_]} sort keys %{$xref->badXml2}],
    columns => <<END,
Source  The source file containing bad xml on line
END
    title=>qq(Bad Xml line 2),
    head=>qq(Xref found NNNN Files with the incorrect xml on line 2 on DDDD),
    file=>(my $f = fpe(qw(bad xmlLine2 txt))));
  {}                                                                            # From multiverse to universe
 } # reportXml2

sub reportDocTypeCount($)                                                       #P Report doc type count
 {my ($xref) = @_;                                                              # Cross referencer

  my %d;
  if (my $xrefDocType = $xref->docType)
   {for my $f(sort keys %{$xrefDocType})
     {my $d = $xrefDocType->{$f};
      $d{$d}++
     }
   }

  formatTables($xref,
    hashOfCountsToArray(\%d),
    columns => <<END,
DocType  The root element tag of this document
END
    title=>qq(Document types),
    head=>qq(Xref found NNNN different doc types on DDDD),
    file=>(fpe(qw(count docTypes txt))));
  {}                                                                            # From multiverse to universe
 } # reportDocTypeCount

sub reportTagCount($)                                                           #P Report tag counts
 {my ($xref) = @_;                                                              # Cross referencer

  my %d;
  if (my $xrefTagCount = $xref->tagCount)
   {for   my $f(sort keys %{$xrefTagCount})
     {for my $t(sort keys %{$xrefTagCount->{$f}})
       {my $d = $xrefTagCount->{$f}{$t};
        $d{$t} += $d;
       }
     }
   }

  formatTables($xref, hashOfCountsToArray(\%d),
    columns => <<END,
Tag     The tag name of the xml node
Count   The number of times this tag name occurs
END
    title=>qq(Tags),
    head=>qq(Xref found NNNN different tags on DDDD),
    file=>(fpe(qw(count tags txt))));
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


  formatTables($xref, \@t,
    columns => <<END,
Item   A tag or some text
Count  The number of times the tag or text occurs
END
    title => q(Tags to Texts Ratio),
    head  => q(Xref found the following tag and text counts on DDDD),
    file  => (fpe(qw(count tagsAndTexts txt))));

   {tagsTextsRatio => $xref->tagsTextsRatio,                                    # From multiverse to universe
   }
 } # reportTagsAndTextsCount

sub reportLtGt($)                                                               #P Report items found between &lt; and &gt;
 {my ($xref) = @_;                                                              # Cross referencer

  my %d;
  if (my $xrefLtgt = $xref->ltgt)
   {for     my $f(sort keys %{$xrefLtgt})
     {for   my $t(sort keys %{$xrefLtgt->{$f}})
       {$d{$t} += $xrefLtgt->{$f}{$t};
       }
     }
   }

  formatTables($xref, [map {[$d{$_}, nws($_)]} sort keys %d],
    columns => <<END,
Count The number of times this text was found
Text  The text found between &lt; and &gt;. The white space has been normalized to make better use of the display.
END
    title=>qq(Text found between &lt; and &gt;),
    head=><<END,
Xref found NNNN different text items between &lt; and &gt; on DDDD
END
    file=>(fpe(qw(count ltgt txt))));
  {}                                                                            # From multiverse to universe
 } # reportLtGt

sub reportAttributeCount($)                                                     #P Report attribute counts
 {my ($xref) = @_;                                                              # Cross referencer

  my %d;
  if (my $xrefAttributeCount = $xref->attributeCount)
   {for   my $f(sort keys %{$xrefAttributeCount})
     {for my $t(sort keys %{$xrefAttributeCount->{$f}})
       {my $d = $xrefAttributeCount->{$f}{$t};
        $d{$t} += $d;
       }
     }
   }

  my @c;
  for   my $t(sort keys %d)
   {push @c, [$d{$t}, $t];
   }

  formatTables($xref, [@c],                                                     # Attribute count report
    columns => <<END,
Count     The number of times this attribute appears
Attribute The attribute name being counted
END
    title=>qq(Attributes),
    head=>qq(Xref found NNNN different attributes on DDDD),
    file=>(my $f = fpe(qw(count attributes txt))));
  {}                                                                            # From multiverse to universe
 } # reportAttributeCount

sub reportAttributeNameAndValueCounts($)                                        #P Report attribute value counts
 {my ($xref) = @_;                                                              # Cross referencer

  my %d;
  if (my $xrefAttributeNamesAndValuesCount = $xref->attributeNamesAndValuesCount)
   {for     my $f(sort keys %{$xrefAttributeNamesAndValuesCount})
     {for   my $a(sort keys %{$xrefAttributeNamesAndValuesCount->{$f}})
       {for my $v(sort keys %{$xrefAttributeNamesAndValuesCount->{$f}{$a}})
         {my $c =             $xrefAttributeNamesAndValuesCount->{$f}{$a}{$v};
          $d{$a}{$v} += $c;
         }
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


  formatTables($xref, \@d,
    columns => <<END,
Count     The number of  times this value occurs
Value     The value being counted
Attribute The attribute on which the value appears
END
    summarize => 1,
    title     => qq(Attribute value counts),
    head      => qq(Xref found NNNN attribute value combinations on DDDD),
    file      => (fpe(qw(count attributeNamesAndValues txt))));
  {}                                                                            # From multiverse to universe
 } # reportAttributeNameAndValueCounts

sub reportValidationErrors($)                                                   #P Report the files known to have validation errors
 {my ($xref) = @_;                                                              # Cross referencer

  my $e = $xref->validationErrors;

  formatTables($xref, [map {[$$e{$_}, $_]} sort keys %$e],                      #
    columns => <<END,
Count The number of valiation errors in the file
File  A file with xml validation errors
END
    title=>qq(Topics with xml validation errors),
    head=><<END,
Xref found NNNN topics with xml validation errors on DDDD
END
    file=>(fpe(qw(bad validationErrors txt))));
  {}                                                                            # From multiverse to universe
 } # reportValidationErrors

sub reportTables($)                                                             #P Report on tables that have problems
 {my ($xref) = @_;                                                              # Cross referencer

  formatTables($xref, $xref->badTables,
    columns => <<END,
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
    file=>(fpe(qw(bad tables txt))));
  {}                                                                            # From multiverse to universe
 } # reportTables

sub reportFileExtensionCount($)                                                 #P Report file extension counts
 {my ($xref) = @_;                                                              # Cross referencer

  my $folder = $xref->inputFolder;
  formatTables($xref,
    hashOfCountsToArray(countFileExtensions($folder)),
    columns => <<END,
Ext     An extension that appears in the input corpus
Count   The number of times the extension appears in the corpus.
END
    title=>qq(File extensions),
    head=><<END,
Xref found NNNN different file extensions on DDDD in folder: $folder
END
    file=>(fpe(qw(count fileExtensions txt))));
  {}                                                                            # From multiverse to universe
 } # reportFileExtensionCount

sub reportFileTypes($)                                                          #P Report file type counts - takes too long in series
 {my ($xref) = @_;                                                              # Cross referencer

  my $ft = countFileTypes($xref->inputFolder, $xref->maximumNumberOfProcesses); # Count file types

  formatTables($xref,
    hashOfCountsToArray($ft),
    columns=><<END,
Type    A file type that appears in the input corpus
Count   The number of times the file type appears in the corpus.
END
    title=>qq(Files types),
    head=><<END,
Xref found NNNN different file types on DDDD
END
    file=>(my $f = fpe(qw(count fileTypes txt))));
  {}                                                                            # From multiverse to universe
 } # reportFileTypes

sub reportExternalXrefs($)                                                      #P Report external xrefs missing other attributes
 {my ($xref) = @_;                                                              # Cross referencer

  my @s;
  if (my $xrefXrefBadScope = $xref->xrefBadScope)
   {for   my $f(sort keys %{$xrefXrefBadScope})
     {my $sourceTopicId = $xref->topicIds->{$f};
      for my $h(sort keys %{$xrefXrefBadScope->{$f}})
       {my $s = $xrefXrefBadScope->{$f}{$h};
        push @s, [q(Bad scope attribute), $h, $s, $sourceTopicId, $f];
       }
     }
   }

  if (my $xrefXrefBadFormat = $xref->xrefBadFormat)
   {for   my $f(sort keys %{$xrefXrefBadFormat})
     {my $sourceTopicId = $xref->topicIds->{$f};
      for my $h(sort keys %{$xrefXrefBadFormat->{$f}})
       {my $s = $xrefXrefBadFormat->{$f}{$h};
        push @s, [q(Bad format attribute), $h, $s, $sourceTopicId, $f];
       }
     }
   }

  formatTables($xref, \@s,
    columns => <<END,
Reason          The reason why the xref is unsatisfactory
Href            The href attribute of the xref in question
Xref_Statement  The xref statement in question
Source_Topic_Id The topic id of the source file containing file containing the bad external xref
File            The file containing the xref statement in question
END
    title=>qq(Bad external xrefs),
    head=>qq(Xref found bad external xrefs on DDDD),
    file=>(my $f = fpe(qw(bad externalXrefs txt))));
  {}                                                                            # From multiverse to universe
 } # reportExternalXrefs

sub reportMaxZoomOut($)                                                         #P Text located via Max Zoom In
 {my ($xref) = @_;                                                              # Cross referencer
  return {} unless my $names = $xref->maxZoomIn;                                # No point if maxZoomIn was not specified

  my @names   = (qw(File_Name Title), sort keys %$names);                       # Column Headers
  my $columns = join "\n", @names;                                              # Column Headers as lines suitable for format tables
  my %names   = map {$names[$_]=>$_} keys @names;                               # Assign regular expression names to columns in the output table/csv

  my @f;
  if (my $xrefMaxZoomOut = $xref->maxZoomOut // {})
   {for   my $f(sort keys %$xrefMaxZoomOut)                                     # One row per file processed showing which regular expression names matched
     {my @n = ($f,  $xref->title->{$f});
      my $c = 0;
      for my $n(sort keys %{$xrefMaxZoomOut->{$f}})
       {$n[$names{$n}] +=   $xrefMaxZoomOut->{$f}{$n};
        ++$c;
       }
      push @f, [@n] if $c;                                                      # Only save a row if it has something in it
     }
   }

  if (my $xrefMaxZoomOut = $xref->maxZoomOut // {})
   {for   my $f(sort keys %$xrefMaxZoomOut)
     {my $t = $xref->title->{$f};
      my $d = $xrefMaxZoomOut->{$f};
      $xrefMaxZoomOut->{$f} = {title=>$t, data=>$d};
     }
   }

  formatTables($xref, [sort {$$a[0] cmp $$b[0]} @f],                            # Sort by file name
    columns   => $columns,
    title     => qq(Max Zoom In Matches),
    head      => <<END,
Xref found NNNN file matches on DDDD
END
    file      =>(fpe(qw(lists maxZoom txt))),
    summarize => 1);

  dumpFile(fpe(qw(lists maxZoom data)), $xref->maxZoomOut);     # Dump the search results

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

  formatTables($xref, \@t,
    columns => <<END,
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
    file=>(fpe(qw(lists topics txt))),
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportTopicDetails

sub reportTopicReuse($)                                                         #P Count how frequently each topic is reused
 {my ($xref) = @_;                                                              # Cross referencer

  my %t;
  if (my $xrefBookMapRefs = $xref->bookMapRefs)
   {for   my $f(sort keys %{$xrefBookMapRefs})
     {for my $t(sort keys %{$xrefBookMapRefs->{$f}})
       {my $file = absFromAbsPlusRel($f, $t);
        $t{$file}{$f}++;
       }
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

  formatTables($xref, $t,
    columns => <<END,
Reuse           The number of times the target topic is reused over all topics
Count           The number of times the target topic is reused in the source topic
Target          The topic that is being reused == the target of reuse
Source          The topic that is referencing the reused topic
END
    title=>qq(Topic Reuses),
    head=><<END,
Xref found NNNN topics that are currently being reused on DDDD
END
    file=>(fpe(qw(lists topicReuse txt))),
    zero=>1,                                                                    # Reuse is very unlikely because the matching criteria is the MD5 sum
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportTopicReuse

# References might need fixing either because they are invalid or because we are
# deguidizing

sub reportFixRefs($)                                                            #P Report of hrefs that need to be fixed
 {my ($xref) = @_;                                                              # Cross referencer

  my @r;
  if (my $xrefFixRefs = $xref->fixRefs)
   {for   my $f(sort keys %{$xrefFixRefs})
     {for my $h(sort keys %{$xrefFixRefs->{$f}})
       {push @r, [$h, $f];
       }
     }
   }

  formatTables($xref, \@r,
    columns => <<END,
Reference       The reference to be fixed
Source          The topic that contains the reference
END
    title=>qq(References to fix),
    head=><<END,
Xref found NNNN hrefs that should be fixed on DDDD
END
    file=>(fpe(qw(lists fixRefs txt))),
    zero=>1,
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportFixRefs

sub reportSourceFiles($)                                                        #P Source file for each topic
 {my ($xref) = @_;                                                              # Cross referencer
  my @r;
  if (my $xrefTargetTopicToInputFiles = $xref->targetTopicToInputFiles)
   {for my $f(sort keys %{$xrefTargetTopicToInputFiles})                        # File
     {my $s = $xrefTargetTopicToInputFiles->{$f};                               # Source file for topic
      push @r, [$f, join ', ', sort keys %$s] if $s;
     }
   }

  formatTables($xref, [sort {$$a[0]cmp $$b[0]} @r],
    columns => <<END,
Topic     The topic file
Source    The source file(s) from which the topic was obtained
END
    title=>qq(Source file for each topic),
    head=><<END,
Xref found the source files for NNNN topics on DDDD
END
    file=>(fpe(qw(lists source_file_for_each_topic txt))),
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportSourceFiles

sub reportReferencesFromBookMaps($)                                             #P Topics and images referenced from bookmaps
 {my ($xref) = @_;                                                              # Cross referencer
  my %bi;                                                                       # Bookmap to image
  my %bt;                                                                       # Bookmap to topics
  my %ib;                                                                       # Images to bookmaps
  my %tb;                                                                       # Topics to bookmaps
  my @bi;                                                                       # Bookmap to image report
  my @bt;                                                                       # Bookmap to topic report
  my @ib;                                                                       # Images to bookmaps reports
  my @tb;                                                                       # Topics to bookmaps reports

  my $imageRefsFromTopic = sub                                                  # Image references from a topic
   {my ($b, $t) = @_;                                                           # Book map, topic
    for my $I(sort keys %{$xref->imagesReferencedFromTopics->{$t}})             # Image href
     {my $i = absFromAbsPlusRel($t, $I);
      push @bi, my $d = [$I, -e $i ? 1 : '', $i, $t, $b];
      $bi{$b}{$i}++;                                                            # Images from bookmap
      $ib{$i}{$b}++;                                                            # Images to bookmaps
     }
   };

  if (my $xrefBookMapRefs = $xref->bookMapRefs)                                 # Book map as that is the only kind of file containing a topic ref
   {for   my $b(sort keys %{$xrefBookMapRefs})                                  # Book map as that is the only kind of file containing a topic ref
     {for my $T(sort keys %{$xrefBookMapRefs->{$b}})                            # Topic href
       {my $t = absFromAbsPlusRel($b, $T);

        push @bt, [$T, (-e $T ? 1 : q()), $t, $b];                              # Report book map to topic
        $bt{$b}{$t}++;                                                          # Book maps to topics
        $tb{$t}{$b}++;                                                          # Topics to book maps

        &$imageRefsFromTopic($b, $t);
       }

      for my $C(sort keys %{$xref->conRefs->{$b}})                              # Conref
       {my ($t) = parseDitaRef($C, $b);
        &$imageRefsFromTopic($b, $t);
       }
     }
   }

  for   my $i(sort keys %ib)                                                    # Image
   {for my $b(sort keys %{$ib{$i}})                                             # Bookmap
     {my $c = $ib{$i}{$b};
      push @ib, [$c, $i, $b];
     }
   }

  for   my $t(sort keys %tb)                                                    # Topic
   {for my $b(sort keys %{$tb{$t}})                                             # Bookmap
     {my $c = $tb{$t}{$b};
      push @tb, [$c, $t, $b];
     }
   }
                                                                                # ALL FILES (below) ARE FULLY QUALIFIED!
  $xref->topicsToReferringBookMaps    = \%tb;                                   # Topics to referring bookmaps
  $xref->topicsReferencedFromBookMaps = \%bt;                                   # Topics referenced from bookmaps
  $xref->imagesReferencedFromBookMaps = \%bi;                                   # Images referenced from bookmaps
  $xref->imagesToRefferingBookMaps    = \%ib;                                   # Images to bookmaps

  formatTables($xref, \@bi,
    columns => <<END,
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
    file=>(fpe(qw(lists images_from_bookmaps txt))),
    zero=>1,
    summarize=>1);

  formatTables($xref, \@bt,
    columns => <<END,
Reference The topic reference
Exists    Whether the referenced topic exists or not
Topic     The topic that referenced the image
Bookmap   The book map that referenced the topic
END
    title=>qq(Topics referenced from bookmaps),
    head=><<END,
Xref found NNNN topics referenced from bookmaps via topics on DDDD
END
    file=>(fpe(qw(lists bookmaps_to_topics txt))),
    zero=>1,
    summarize=>1);

  formatTables($xref, \@tb,
    columns => <<END,
Count     The number of times this topic is reffered to by this bookmap
Topic     The topic in question
Bookmap   A bookmap that refers to this topic
END
    title=>qq(Topics to referring bookmaps),
    head=><<END,
Xref found NNNN topics referred to from bookmaps on DDDD
END
    file=>(fpe(qw(lists topics_to_bookmaps txt))),
    zero=>1,
    summarize=>1);

  formatTables($xref, \@ib,
    columns => <<END,
Count     The number of times this image is reffered to by this bookmap
Image     The image in question
Bookmap   A bookmap that refers to this image
END
    title=>qq(Images to referring bookmaps),
    head=><<END,
Xref found NNNN images referred to from bookmaps on DDDD
END
    file=>(fpe(qw(lists images_to_bookmaps txt))),
    zero=>1,
    summarize=>1);
 } # reportReferencesFromBookMaps

sub reportExteriorMaps($)                                                       #P Maps that are not referenced by any other map
 {my ($xref) = @_;                                                              # Cross referencer

  my %r;                                                                        # Map reference count
  if (my $xrefTopicsReferencedFromBookMaps = $xref->topicsReferencedFromBookMaps)
   {for   my $b(sort keys %{$xrefTopicsReferencedFromBookMaps})                 # Each map
     {$r{$b}++;                                                                 # Save map
      for my $t(sort keys %{$xrefTopicsReferencedFromBookMaps->{$b}})           # Each topic reference from the map
       {if (my $d = $xref->docType->{$t})                                       # Document type
         {if ($d =~ m(map\Z)s)                                                  # Its a map
           {$r{$t}--;                                                           # It has been referenced
           }
         }
       }
     }
   }

  my %u;                                                                        # Unreferenced maps
  for my $b(sort keys %r)                                                       # Each map
   {$u{$b}++ if $r{$b} > 0;                                                     # Unreferenced map
   }

  formatTables($xref,
    hashOfCountsToArray(\%u),
    columns => <<END,
Bookmap   An exterior bookmap
END
    title=>qq(Exterior bookmaps),
    head=><<END,
Xref found NNNN exterior bookmaps on DDDD

An exterior map is one that is not referenced from any other map in the corpus.
END
    file=>(fpe(qw(lists exterior_maps txt))),
    summarize=>1);

  {exteriorMaps => \%u,                                                         # Exterior maps == maps that are not referenced by another map
  }                                                                             # From multiverse to universe
 } # reportExteriorMaps

sub reportTopicsNotReferencedFromBookMaps($)                                    #P Topics not referenced from bookmaps
 {my ($xref) = @_;                                                              # Cross referencer

  my %r;                                                                        # Topics referenced from a bookmap
  if (my $xrefTopicsReferencedFromBookMaps = $xref->topicsReferencedFromBookMaps)
   {for   my $b(sort keys %{$xrefTopicsReferencedFromBookMaps})                 # Book maps
     {for my $f(sort keys %{$xrefTopicsReferencedFromBookMaps->{$b}})           # Topics referenced from bookmaps
       {$r{$f}++;                                                               # Topic reference count
       }
     }
   }

  my @n;                                                                        # Topic not referenced from a bookmap
  if (my $xrefDocType = $xref->docType)
   {for   my $f(sort keys %{$xrefDocType})                                      # Input xml files
     {next if $xrefDocType ->{$f} =~ m(map\Z)s;
      push @n, $f unless $r{$f};                                                # Topic not referenced from a bookmap
     }
   }

  my $facet = q(Topics referenced from bookmaps);                               # Facet

  my $n = $xref->topicsNotReferencedFromBookMaps = {map {$_=>1} @n};            #Topics not referenced by any bookmap

  formatTables($xref,
    [map {[$r{$_}, swapFilePrefix($_, $xref->inputFolder)]} sort keys %r],
    columns   => <<END,
Count Number of referring bookmaps
Topic Topic referenced from one or more bookmaps
END
    title     => qq(Topics referenced by bookmaps),
    facet     => $facet, aspectColor=>q(green),
    head      => <<END,
Xref found NNNN topics that are referenced by one or more bookmaps on DDDD
END
    file      => fpe(qw(good topics_referenced_from_bookmaps txt)),
    summarize => 1);

  formatTables($xref,
    [map {[swapFilePrefix($_, $xref->inputFolder)]} sort {$a cmp $b} @n],
    columns   => <<END,
Topic     Unreferenced topic file name
END
    title     => qq(Topics not referenced by any bookmap),
    facet     => $facet,  aspectColor=>q(red),
    head      => <<END,
Xref found NNNN topics that are not referenced by any bookmaps on DDDD
END
    file      => fpe(qw(bad topics_not_referenced_from_bookmaps txt)),
    summarize => 1);

  {topicsNotReferencedFromBookMaps=>$n
  }
 } # reportTopicsNotReferencedFromBookMaps


sub reportTableDimensions($)                                                    #P Report table dimensions
 {my ($xref) = @_;                                                              # Cross referencer

  my %d = %{$xref->tableDimensions};
  my %r;                                                                        # Topic not referenced from a bookmap
  for   my $f(keys %d)                                                          # Files with tables
   {for   my $c(keys %{$d{$f}})                                                 # Table columns
     {for my $r(keys %{$d{$f}{$c}})                                             # Table rows
       {push @{$r{$c}{$r}}, $f;
       }
     }
   }

  my @d;                                                                        # Topic not referenced from a bookmap
  for   my $c(sort {$a <=> $b} keys %r)                                         # Table columns
   {for my $r(sort {$a <=> $b} keys %{$r{$c}})                                  # Table rows
     {my ($f, @f) = @{$r{$c}{$r}};
      push @d, [$c, $r, $f];
      push @d, [q(), q(), $_] for @f;
     }
   }

  formatTables($xref, [@d],
    columns => <<END,
Columns Number of columns in table
Rows    Number of rows in table
File    A file that contains a table with this many columns and rows
END
    title=>qq(Table dimensions),
    head=><<END,
Xref found NNNN table dimensions on DDDD
END
    file=>(fpe(qw(count table_dimensions txt))),
    summarize=>1);

  {}
 } # reportTableDimensions

sub reportOtherMeta($)                                                          #P Advise in the feasibility of moving othermeta data from topics to bookmaps assuming that the othermeta data will be applied only at the head of the map rather than individually to each topic in the map.
 {my ($xref) = @_;                                                              # Cross referencer

  my %t; my %b; my %B;                                                          # Othermeta at topic level, othermeta to migrate to bookmap, othermeta already in bookmap
  for     my $b(sort keys $xref->bookMapRefs->%*)
   {for   my $n(sort keys $xref->otherMeta->{$b}->%*)                           # Name of othermeta
     {for my $c(sort keys $xref->otherMeta->{$b}->{$n}->%*)                     # Content of other meta
       {$b{$b}{$n}{$c}++;
        $B{$b}{$n}{$c}++;
       }
     }

    for my $r(sort keys $xref->bookMapRefs->{$b}->%*)                           # Each topic reached from the bookmap
     {my $t = absFromAbsPlusRel($b, $r);                                        # Topic references are relative
      if (my $o = $xref->otherMeta->{$t})
       {for   my $n(sort keys $o->%*)
         {for my $c(sort keys $o->{$n}->%*)
           {$t{$t}{$n}{$c}{$b}++;                                               # Othermeta by topic
            $b{$b}{$n}{$c}++;                                                   # Put topic othermeta in bookmap
           }
         }
       }
     }
   }

  if (1)                                                                        # Bookmaps and topics with duplicate othermeta should be empty
   {my @d;
    for     my $b(sort keys %B)                                                 # Bookmaps
     {for   my $n(sort keys $B{$b}->%*)
       {if (my $N =    keys $B{$b}{$n}->%*)
         {if ($N > 1)
           {my ($c, @c) = sort keys $B{$b}{$n}->%*;
            push @d, [$b, $n, $N, $c], map {[(q()) x 3, $_]} @c;
           }
         }
       }
     }

    for     my $t(sort keys %t)                                                 # Topics
     {for   my $n(sort keys $t{$t}->%*)
       {if (my $N =    keys $t{$t}{$n}->%*)
         {if ($N > 1)
           {my ($c, @c) = sort keys $t{$t}{$n}->%*;
            push @d, [$t, $n, $N, $c], map {[(q()) x 3, $_]} @c;
           }
         }
       }
     }

    formatTables($xref, $xref->otherMetaDuplicatesSeparately = [@d],
    columns => <<END,
Source   Bookmaps or topic files with duplicate othermeta data
Name     Duplicated othermeta name field
Count    Number of duplicates
Content  Othermeta content
END
    title=>q(Duplicate othermeta data in bookmaps and topics considered separately),
    head =>q(Found NNNN duplicate othermeta items on DDDD),
    clearUpLeft => -1, summarize=>1,
    file =>fpe(qw(other_meta duplicates_separately txt)));
   }

  if (1)                                                                        # Report duplicate othermeta in bookmaps with called topics othermeta included
   {my @d;

    for     my $b(sort keys %b)                                                 # Bookmaps
     {for   my $n(sort keys $b{$b}->%*)
       {if (my $N =    keys $b{$b}{$n}->%*)
         {if ($N > 1)
           {my ($c, @c) = sort keys $b{$b}{$n}->%*;
            push @d, [$b, $n, $N, $c], map {[(q()) x 3, $_]} @c;
           }
         }
       }
     }

    formatTables($xref, $xref->otherMetaDuplicatesCombined = [@d],
      columns => <<END,
Source   Bookmap with duplicate othermeta with called topics othermeta included
Name     Duplicated othermeta name field
Count    Number of duplicates
Content  Othermeta content
END
      title=>q(Duplicate othermeta in bookmaps with called topic othermeta included),
      head =>q(Found NNNN duplicate othermeta items on DDDD),
      clearUpLeft => -1, summarize=>1,
      file =>fpe(qw(other_meta duplicates txt)));
   }

  my %o;                                                                        # Topic overrides
  for       my $t(sort keys %t)                                                 # Find topic othermeta which must override bookmap othermeta
   {for     my $n(sort keys $t{$t}->%*)
     {for   my $c(sort keys $t{$t}{$n}->%*)
       {for my $b(sort keys $t{$t}{$n}{$c}->%*)
         {if (!$b{$b}{$n}{$c} or keys($b{$b}{$n}->%*) != 1)                     # Override the othermeta from the bookmap unless the bookmap agrees that there is only value for this name
           {$o{$t}{$n}{$c}{$b}++;
           }
         }
       }
     }
   }

  if (1)                                                                        # Keep in topic because we cannot push the meta data to all the calling bookmaps
   {my @k;
    for       my $t(sort keys %o)
     {for     my $n(sort keys $o{$t}->%*)
       {for   my $c(sort keys $o{$t}{$n}->%*)
         {push @k, [$t, $n, $c, sort keys $o{$t}{$n}{$c}->%*];                  # The bookmaps that cause the over ride
         }
       }
     }

    formatTables($xref, $xref->otherMetaRemainWithTopic = [@k],
      columns => <<END,
Topic    Topic file name
Name     Othermeta name field to be retained
Content  Othermeta name content to be retained
Bookmaps One or more bookmaps that prevented the migration of this othermeta to the calling bookmaps
END
    title=>q(Othermeta kept in topics because calling bookmaps disagree),
    clearUpLeft => -1, summarize=>1,
    head =>qq(Found NNNN othermeta items that must remain in topic on DDDD),
    file =>fpe(qw(other_meta must_remain_in_topic txt)));
   }

  if (1)                                                                        # Report othermeta pushed to the bookmaps
   {my @p;
    for       my $t(sort keys %t)
     {for     my $n(sort keys $t{$t}->%*)
       {for   my $c(sort keys $t{$t}{$n}->%*)
         {for my $b(sort keys $t{$t}{$n}{$c}->%*)
           {push @p, [$t, $n, $c, $b] unless $o{$t}{$n}{$c}{$b}                 # Can be pushed to bookmap
           }
         }
       }
     }

    formatTables($xref, $xref->otherMetaPushToBookMap = [@p],
      columns => <<END,
Topic    Topic file name
Name     Othermeta name field to be retained
Content  Othermeta name content to be retained
Bookmap  The bookmap data othermeta can be migrated to
END
    title=>q(Othermeta data that can be pushed to the calling bookmaps),
    clearUpLeft => -1, summarize=>1,
    head =>qq(Found NNNN othermeta items that can be pushed to the calling bookmaps on DDDD),
    file =>fpe(qw(other_meta push_to_book_maps txt)));
   }

  if (1)                                                                        # Report bookmap othermeta before topic othermeta has been included
   {my @b;

    for       my $b(sort keys %B)
     {for     my $n(sort keys $B{$b}->%*)
       {for   my $c(sort keys $B{$b}{$n}->%*)
         {push @b, [$b, $n, scalar(keys $B{$b}{$n}->%*), $c];

         }
       }
     }

  formatTables($xref, $xref->otherMetaBookMapsBeforeTopicIncludes = [@b],
    columns => <<END,
Bookmap Bookmap file name
Name    Bookmap othermeta name
Count   Number of distinct values for this othermeta name in this bookmap
Content Othermeta content for this name
END
    title=> q(Bookmap othermeta before topic othermeta has been included),
    clearUpLeft => -1, summarize=>1,
    head => qq(Xref found NNNN Bookmap othermeta tags before topic othermeta was included),
    file => fpe(qw(other_meta book_maps_before_topics_included txt)));
   }

  if (1)                                                                        # Report bookmap othermeta after topic othermeta has been included
   {my @b;

    for       my $b(sort keys %b)
     {for     my $n(sort keys $b{$b}->%*)
       {for   my $c(sort keys $b{$b}{$n}->%*)
         {push @b, [$b, $n, scalar(keys $b{$b}{$n}->%*), $c];
         }
       }
     }

    formatTables($xref, $xref->otherMetaBookMapsAfterTopicIncludes = [@b],
      columns => <<END,
Bookmap Bookmap file name
Name    Bookmap or topic othermeta name
Count   Number of distinct values for this othermeta name
Content Othermeta content for this name
END
    title=> q(Bookmap othermeta data after topic othermeta has been included),
    clearUpLeft => -1, summarize=>1,
    head => qq(Xref found NNNN Bookmap othermeta tags after topic othermeta was included on DDDD),
    file =>fpe(qw(other_meta book_maps_after_topics_included txt)));
   }

   {otherMetaDuplicatesSeparately         => $xref->otherMetaDuplicatesSeparately,
    otherMetaDuplicatesCombined           => $xref->otherMetaDuplicatesCombined,
    otherMetaRemainWithTopic              => $xref->otherMetaRemainWithTopic,
    otherMetaPushToBookMap                => $xref->otherMetaPushToBookMap,
    otherMetaBookMapsBeforeTopicIncludes  => $xref->otherMetaBookMapsBeforeTopicIncludes,
    otherMetaBookMapsAfterTopicIncludes   => $xref->otherMetaBookMapsAfterTopicIncludes,
   }

 } # reportOtherMeta

sub createSubjectSchemeMap($)                                                   #P Create a subject scheme map from othermeta
 {my ($xref) = @_;                                                              # Cross referencer

  my %o;                                                                        # Consolidated other meta
  for     my $f(sort keys $xref->otherMeta->%*)                                 # Each file containing othermeta
   {for   my $n(sort keys $xref->otherMeta->{$f}->%*)                           # Name of othermeta
     {for my $c(sort keys $xref->otherMeta->{$f}->{$n}->%*)                     # Content of other meta
       {$o{$n}{$c}++;
       }
     }
   }

  if (my $out = $xref->subjectSchemeMap)                                        # SubjectSchemeMap requested by supplying an output folder for the maps
   {my $makeNavTitle = sub                                                      # Create a nav title using the Gearhart NavTitle Method
     {my ($c) = @_;                                                             # Othermeta content
      ucfirst $c =~ s(_) ( )gsr                                                 # The Gearhart NavTitle method
     };

    my @m;
    for my $n(sort keys %o)                                                     # Layout map entries
     {next if $n =~ m(\Atopic_type\Z)i;
      my $t = &$makeNavTitle($n);
      push @m, qq(<subjectHead id="$n" navtitle="$t">);

      my %c;                                                                    # Normalize all the othermeta
      for my $content(sort keys $o{$n}->%*)
       {for my $c(split m(\s+)s, $content)
         {$c{$c}++
         }
       }
      for my $c(sort keys %c)                                                   # Write the normalized othermeta
       {my $t = &$makeNavTitle($c);
        push @m, qq(<subjectdef keys="$c" navtitle="$t"/>);
       }

      push @m, qq(</subjectHead>);
     }

    my $m = join "\n", q(<subjectScheme>), @m, q(</subjectScheme>);             # Map
    my $x = Data::Edit::Xml::new($m);                                           # Parse map
    owf($out, $x->ditaPrettyPrintWithHeaders);                                  # Print map
   }

   {otherMetaConsolidated=>\%o}                                                 # Consolidated meta data
 } # createSubjectSchemeMap

sub writeClassificationHtml($$)                                                 #P Write classification tree as html
 {my ($xref, $classification) = @_;                                             # Cross referencer, {title=>{subject=>{file=>++}}}
  push my @h, <<END;                                                            # Outer table
<style>
.sizeLargeBold
 {font-size: 1.2em;
  font-weight: bold;
 }
</style>
<table id="selectBySubject" border="1" cellpadding="10">
<tr><th>Select by Subject<th>Topics that have been selected
END
  push @h, <<END;                                                               # Table in column 1 of titles
<tr><td><table border="1" cellpadding="10">
<tr><th>Topic Subject<th>Subject Ref
END

  my $iTitle = 0; my $iSubject = 0;                                             # Id generator's for titles and subjects
  my @json;                                                                     # Json holding titles and subjects
  for my $t(sort keys %$classification)                                         # Each title
   {++$iTitle;
    push @h, <<END;                                                             # Hidden table of subjects
<tr>
<td valign="top"><a id="clickOnTitle_$iTitle"
                    onclick="clickOnTitle($iTitle)">$t</a>
<td><div style="display: none" id="title_$iTitle">
<table border="0" cellpadding="10">
END
    for my $s(sort keys $classification->{$t}->%*)                              # Each subject
     {++$iSubject;
      for my $f(sort keys $classification->{$t}{$s}->%*)                        # Load topics for title and subject
       {push @json, qq(topicDetails.push([$iTitle, $iSubject, "$f"]););
       }
      push @h, <<END;                                                           # Click on subject
<tr><td><span id="clickOnSubject_$iSubject"
              onclick='clickOnSubject($iTitle, $iSubject)'>$s</span>
END
     }
    push @h, <<END;                                                             # End hidden table of subjects
</table></div>
END
   }
  push @h, <<END;                                                               # End of table in column 1
</table>
END

  push @h, <<END;                                                               # Column 2 - selected topics
<td valign="top">
<div id="div"></div>
END

  my $json = join "\n", @json;                                                  # Json containing title and subjects to topics
  push @h, <<END;                                                               # Outer table
</table>
<script>
const topicDetails    = [];                                                     // [Title number, subject number, topic]
const topicsSelected  = {};                                                     // Topics that have been selected
const titleExpanded   = [];                                                     // Title has been expanded

$json;

function clickOnTitle(title)                                                    // Expand a title to see its subjects
 {const t = document.getElementById("clickOnTitle_"+title);                     // Button
  const T = document.getElementById("title_"+title);                            // Div

  T.style.display = titleExpanded[title] ? "none" : "block";                    // Expand/contract div
  titleExpanded[title] = !titleExpanded[title];
 }

function clickOnSubject(title, subject)                                         // Add or remove topics from the hash of topics selected
 {const sli = document.getElementById("clickOnSubject_"+subject);

  if (!sli.classList.contains("sizeLargeBold"))                                 // Add as not emphasized
   {for(let d of topicDetails)
     {if (d[1] == subject)
       {const s = d[2];
        if (topicsSelected[s]) topicsSelected[s]++; else topicsSelected[s] = 1;
       }
     }
    sli.classList.add("sizeLargeBold");
   }
  else                                                                          // Remove as emphasized
   {for(let d of topicDetails)
     {if (d[1] == subject)
       {const s = d[2];
        if  (topicsSelected && topicsSelected[s] > 0) topicsSelected[s]--
        else topicsSelected[s] = 0;
       }
     }
    sli.classList.remove("sizeLargeBold");
   }

  if (true)                                                                     // If any of the subjects are selected select teh title as well
   {let count = 0;
    for(let d of topicDetails)
     {if (d[0] == title)
       {const s = document.getElementById("clickOnSubject_"+d[1]);
        if (s.classList.contains("sizeLargeBold")) ++count;
       }
     }
    const t = document.getElementById("clickOnTitle_"+title);
    if (count > 0) t.classList.add   ("sizeLargeBold");
    else           t.classList.remove("sizeLargeBold");
   }

  let h = '';                                                                   // Create html to show the list of selected topics
  for (let [topic, count] of Object.entries(topicsSelected))
   {if (count > 0)
     {h += '<tr><td><a href="client.pl?getFile='+                               // Anchor for topic file
            topic+'">'+topic+'</a><td align="right">'+count+"\\n";
     }
   }

  const d = document.getElementById("div");
  d.innerHTML = '<table border="0" cellpadding="10">'+h+'</table>';
 }

</script>
END

  if (1)                                                                        # Classification html written as a report
   {my $f = fpe($xref->reports, qw(other_meta classificationScheme html));
    owf($f, join "\n", @h);
   }
 } # writeClassificationHtml

sub createClassificationMap($$$)                                                #P Create a classification map for each bookmap
 {my ($xref, $bookMap, $classification) = @_;                                   # Cross referencer, bookmap to classify, classification scheme

  for my $b($bookMap)                                                           # Book map
   {my $out = fpn($b).classificationMapSuffix;

    push my @o, <<END;                                                          # Other meta fields for classification map
<map>
  <topicmeta>
    <othermeta name="appaapps.classificationMap" content="yes"/>
    <othermeta name="appaapps.classificationMap.source" content="$bookMap"/>
  </topicmeta>
END

    for     my $f(sort keys $xref->topicsReferencedFromBookMaps->{$b}->%*)      # Book map topics
     {next unless my $tag = $xref->baseTag->{$f};                               # Check that the referenced topic exists locally

      my $F = $tag !~ m(map\Z)i ? $f : fpn($f).classificationMapSuffix;         # Reference classification map rather than actual map

      my $r = relFromAbsAgainstAbs($F, $out);

      push @o, <<END;
<topicref href="$r">
  <topicmeta>
    <keywords/>
  </topicmeta>
END

      for   my $n(sort keys $xref->otherMeta->{$f}->%*)                         # Name of other meta in book map topic
       {next if $n =~ m(\Atopic_type\Z)i;
        my ($navTitle) = sort keys $xref->otherMeta->{$f}{$n}->%*;

        push @o, <<END;
<topicsubject outputclass="$n" navtitle="$navTitle">
END
        for my $C(sort keys $xref->otherMeta->{$f}{$n}->%*)                     # Content of other meta
         {my @c = split /\s+/, $C;                                              # Von Sabine gefunden!
          for my $c(sort @c)
           {push @o, <<END;
<subjectref keyref="$c"></subjectref>
END
            $$classification{$navTitle}{$c}{$f}++                               # Classification scheme for file
           }
         }
        push @o, <<END;
</topicsubject>
END
       }

      push @o, <<END;
</topicref>
END
     }

    push @o, q(</map>);

    if (1)                                                                      # Write classification map
     {my $o = join "\n", @o;
      my $x = Data::Edit::Xml::new $o;
      my $y = $x->ditaPrettyPrintWithHeaders;
      owf($out, $y);
     }

    if (my $x = Data::Edit::Xml::new($b))                                       # Edit an xml file retaining any existing XML headers and lint trailers
     {my $href     = relFromAbsAgainstAbs($out, $b);
      my $topicRef = <<END;
<mapref href="$href" processing-role="resource-only" format="ditamap" type="xml" outputclass="classification-ditamap" scope="local"/>
END

      if (my $t = $x->go_topicmeta || $x->go_title)                             # Position the classification map reference
       {$t->putNextAsText($topicRef);
        editXml($b, $b, -p $x);
       }
      else                                                                      # Put the classification map reference first if no other place for it
       {$x->putFirstAsText($topicRef);
        editXml($b, $b, -p $x);
       }
     }
   }

 } # createClassificationMap

sub createClassificationMaps($)                                                 #P Create classification maps for each bookmap
 {my ($xref) = @_;                                                              # Cross referencer
  return {} unless $xref->classificationMaps;                                   # Only if requested

  my $c = {};                                                                   # Classification hash
  for my $b(sort keys $xref->bookMapRefs->%*)                                   # Ideally this should be in parallel - but it only takes 1/10 of the Xref time and is not used in most Xrefs anyway so it can probably continue in series for the moment at 2019.11.04
   {createClassificationMap($xref, $b, $c);
   }
  writeClassificationHtml($xref, $c);                                           # Write html to show the classification scheme

  {}                                                                            # Consolidated meta data
 } # createClassificationMaps

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

  formatTables($xref, $t,
    columns => <<END,
Similar          The number of topics similar to this one
Prefix           The prefix of the target file names being used for matching
Source           Topics that have the current prefix
END
    title => qq(Similar topics),
    head  => <<END,
Xref found NNNN topics that might be similar on DDDD
END
    clearUpLeft => -1, summarize=>1, zero=>1,
    file  => fpe(qw(similar byTitle txt)));
  {}                                                                            # From multiverse to universe
 } # reportSimilarTopicsByTitle

sub reportSimilarTopicsByVocabulary($)                                          #P Report topics likely to be similar on the basis of their vocabulary
 {my ($xref) = @_;                                                              # Cross referencer
  my $l = $xref->matchTopics;                                                   # Match level
  my $p = int($l * 100);                                                        # Match level as a percentage

  my @m = grep {scalar(@$_) > 1}                                                # Partition into like topics based on vocabulary - select the partitions with more than one element
  setPartitionOnIntersectionOverUnionOfHashStringSets($l, $xref->vocabulary);

  my @t;
  for my $a(@m)                                                                 # Each block of matching topics
   {my ($first, @rest) = @$a;
    push @t, [scalar(@$a), $first], map {[q(), $_]} @rest;
    push @t, [q(), q()];
   }

  my $m = @m;

  formatTables($xref, \@t,
    columns => <<END,
Similar The number of similar topics in this block
Topic   One of the similar topics
END
    title=>qq(Topics with similar vocabulary with $p % confidence),
    head=><<END,
Xref found $m groups of topics that have similar vocabulary with $p % confidence on DDDD
END
    clearUpLeft => -1, summarize=>1, zero=>1,
    file=>(my $f = fpe(qw(similar byVocabulary txt))));
  {}                                                                            # From multiverse to universe
 } # reportSimilarTopicsByVocabulary

sub reportWordsByFile($)                                                        #P Index words to the files they occur in
 {my ($xref) = @_;                                                              # Cross referencer

  my %w;                                                                        # Words to files
  for     my $f(sort keys $xref->vocabulary->%*)                                # Each file containing words
   {my $t = lc $xref->vocabulary->{$f};
    my @w = split /\s+/, $t =~ s([^a-z]) ( )gsr;                                # Only allow letters in words
    for my $w(@w)
     {$w{$w}{$f}++ if length($w) < 16;                                          # No one will want to type 16 letter words
     }
   }

  my $N = keys %w;                                                              # Number of words
  for   my $w(keys %w)                                                          # Delete useless words == appears in more than the square root of the number of files as they are not selective enough
   {my $n = keys %{$w{$w}};
    if ($n * $n > $N)                                                           # Not selective enough
     {delete $w{$w};
     }
   }

  my %t;                                                                        # Files to words
  for   my $w(keys %w)                                                          # Delete useless words == appears in more than the square root of the number of files as they are not selective enough
   {for my $t(keys %{$w{$w}})
     {$t{$t}{$w} = $w{$w}{$t};
     }
   }

  if (my $out = $xref->indexWordsFolder)                                        # Save the indexed words
   {makePath($out);
    store \%w, fpe($out, qw(words_to_topics data));                             # Index word to topics
    store \%t, fpe($out, qw(topics_to_words data));                             # Index topics to words
    store $xref->title, fpe($out, qw(topics_to_titles data));                   # Index topics to titles
   }

  {indexedWords => $N,                                                          # Retain number of indexed words - if we need the actual index it is in the file
  }                                                                             # From multiverse to universe
 } # reportWordsByFile

sub reportMd5Sum($)                                                             #P Report files with identical md5 sums
 {my ($xref) = @_;                                                              # Cross referencer

  my %m;                                                                        # {md5}{file}++
  if (my $xrefMd5Sum = $xref->md5Sum)
   {for my $f(sort keys %{$xrefMd5Sum})
     {if (my $m = $xrefMd5Sum->{$f})
       {$m{$m}{$f}++;
       }
     }
   }

  for my $m(keys %m)                                                            # Remove files with unique md5 sums
   {if (1 == keys %{$m{$m}})
     {delete $m{$m};
     }
   }

  my @r; my $M;                                                                 # Report files with same md5 sum clearing up and left
  for   my $m(sort  keys %m)
   {for my $f(sort  keys %{$m{$m}})
     {push @r, [$m, scalar(keys %{$m{$m}}), $f] unless $M;
      push @r, [q(), q(),                   $f] if     $M;
      $M = $m;
     }
    $M = undef;
   }

  formatTables($xref, \@r,
    columns => <<END,
Md5_Sum The md5 sum in question
Count   The number of files with this md5 sum
File    A file that has this md5 sum
END
    title=>qq(Files with identical md5 sums),
    head=><<END,
Xref found NNNN files with identical md5 sums on DDDD

Such files are very likely to be identical and thus duplications of each other.
END
    file=>(fpe(qw(bad same_md5_sum txt))),
    summarize=>1);

  {md5SumDuplicates=>\%m,                                                       # From multiverse to universe
  }
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

  formatTables($xref,
    [map {[$c{$_}, $_]} sort {$c{$b} <=> $c{$a}} sort keys %c],
    columns => <<END,
Count             Number of ol under a conbody tag
File_Name         The name of the file containing an ol under conbody
END
    title=>qq(ol under conbody indicative of task),
    head=><<END,
Xref found NNNN files with ol under a conbody tag on DDDD.

ol under a conbody tag is often indicative of steps in a task.
END
    file=>(fpe(qw(bad olUnderConBody txt))),
    summarize=>1);

  my %t = $select->(q(taskbody));

  formatTables($xref,
    [map {[$t{$_}, $_]} sort {$t{$b} <=> $t{$a}} sort keys %t],
    columns => <<END,
Count             Number of ol under a taskbody tag
File_Name         The name of the file containing an ol under taskbody
END
    title=>qq(ol under taskbody indicative of steps),
    head=><<END,
Xref found NNNN files with ol under a taskbody tag on DDDD.

ol under a taskbody tag is often indicative of steps in a task.
END
    file=>(fpe(qw(bad olUnderTaskBody txt))),
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportOlBody

sub reportHrefUrlEncoding($)                                                    #P href needs url encoding
 {my ($xref) = @_;                                                              # Cross referencer

  my @b;
  if (my $xrefHrefUrlEncoding = $xref->hrefUrlEncoding)
   {for my $f  (sort keys %{$xrefHrefUrlEncoding})
     {for my $l(sort keys %{$xrefHrefUrlEncoding->{$f}})
       {push @b,           [$xrefHrefUrlEncoding->{$f}{$l}, $l, $f];
       }
     }
   }

  formatTables($xref, [@b],
    columns => <<END,
Href             Href that needs url encoding
Line_location    Line location
File_Name        The file containing the href that needs url encoding
END
    title=>qq(Hrefs that need url encoding),
    head=><<END,
Xref found NNNN locations where an href needs to be url encoded on DDDD.
END
    file=>(fpe(qw(bad hrefs_that_need_url_encoding txt))),
    summarize=>1);
  {}                                                                            # From multiverse to universe
 } # reportHrefUrlEncoding

sub reportConRefMatching($)                                                     #P Report conref matching
 {my ($xref) = @_;                                                              # Cross referencer

  my %r;                                                                        # The number of references to each target id
  if (my $xrefConRefs = $xref->conRefs)
   {for my   $file(sort keys %{$xrefConRefs})                                   # Each file that has a conref
     {for my $ref (sort keys %{$xrefConRefs->{$file}})                          # Each conref
       {my ($rf, $rt, $ri) = parseDitaRef($ref, $file);                         # Parse the dita ref
        $r{$rf}{$ri}++;                                                         # Count the number of references to this id
       }
     }
   }

  my @r; my $N = 0;                                                             # Number of tags mismatched
  if (my $xrefConRefs = $xref->conRefs)
   {for my   $file(sort keys %{$xrefConRefs})                                   # Each file that has a conref
     {for my  $ref(sort keys %{$xrefConRefs->{$file}})                          # Each conref target file
       {my ($rf, $rt, $ri) = parseDitaRef($ref, $file);                         # Parse the dita ref
        if (my $targetTags = $xref->idTags->{$rf}{$ri})                         # Array of target tags that have this id
         {for my $t(@$targetTags)                                               # Each target tag
           {for my $st(sort keys %{$xrefConRefs->{$file}{$ref}})                # Each conref
             {$N++ if my $tagMisMatch = $st ne $t ? q(**) : q();                # Check for mismatch between source and target tags
              push @r, [$r{$rf}{$ri}, $tagMisMatch, $st, $t, $ref, $file, $rf];
             }
           }
         }
       }
     }
   }

  formatTables($xref, [@r],
    columns => <<END,
Count        Number of references to this target
Mismatch     ** if there is a mismatch between the source and target tags
Source_tag   The source tag
Target_tag   The target tag
Reference    The reference value from source to target
Source_File  The source file
Target_File  The target file
END
    title=>qq(Conrefs),
    head=><<END.fixingRun($xref),
Xref found NNNN conrefs on DDDD with $N mismatches**
END
    file=>(my $f = fpe(qw(lists conrefs txt))),
    summarize=>1);

  {}                                                                            # From multiverse to universe
 } # reportConRefMatching

sub reportPublicIds($)                                                          #P Report public ids in use
 {my ($xref) = @_;                                                              # Cross referencer

  my %p; my $missing = 0;                                                       # Public Id counts
  if (my $xrefPublicId = $xref->publicId)
   {for my $f(sort keys %{$xrefPublicId})                                     # Each file
     {if (my $p = $xrefPublicId->{$f})
       {$p{$p}++
       }
      else
       {++$missing
       }
     }
   }

  my @p;                                                                        # Public Id counts
  for my $p(sort keys %p)
   {push @p, [$p{$p}, $p];
   }

  formatTables($xref, [@p],
    columns => <<END,
Count        Number of references to this public id
Public_Id    A public Id found in the input corpus
END
    title=>qq(Public Ids),
    head=><<END,
Xref found NNNN public ids in use on DDDD

$missing files have a missing public id.
END
    file=>(my $f = fpe(qw(lists public_ids txt))),
    summarize=>1);

  {}                                                                            # From multiverse to universe
 } # reportPublicIds

sub reportRequiredCleanUps($)                                                   #P Report required clean ups
 {my ($xref) = @_;                                                              # Cross referencer

  my @r; my %r;                                                                 # Required clean ups
  if (my $xrefRequiredCleanUp = $xref->requiredCleanUp)
   {for my $f(sort keys %{$xrefRequiredCleanUp})                                # Each file
     {for my $t(sort keys %{$xrefRequiredCleanUp->{$f}})                        # Each clean up
       {push @r, [$xrefRequiredCleanUp->{$f}{$t}, firstNChars($t, 80), $f];
        $r{$t}++;
       }
     }
   }

  my $N = scalar keys %r;
  my $F = scalar keys %{$xref->requiredCleanUp};

  formatTables($xref, [@r],
    columns => <<END,
Count     Number of required clean ups
Clean_Up  The text of the clean up request
File_Name File name containing the required clean up requests
END
    title   => qq(Required cleans ups by file),
    head    => <<END,
Xref found $F files with $N required-cleanups on DDDD
END
    file=>(fpe(qw(lists required_clean_ups txt))),
    summarize=>1);

  {}                                                                            # From multiverse to universe
 } # reportRequiredCleanUps

sub reportUrls($)                                                               #P Report urls that fail to resolve
 {my ($xref) = @_;                                                              # Cross referencer

  my %u;                                                                        # Urls
  for   my $f(sort keys $xref->urls->%*)                                        # Each file
   {for my $u(sort keys$xref->urls->{$f}->%*)                                   # Each url
     {$u{$u}{$f}++;                                                             # Urls by file
     }
   }

  my %f;                                                                        # Failing urls
  runInParallel($xref->maximumNumberOfProcesses, sub
   {my ($url) = @_;
    qx(curl -Is --connect-timeout 5 $url 2>&1 1>/dev/null);
    [$url, $?]                                                                  # Fail if non zero return code
   }, sub
   {my (@results) = @_;                                                         # Consolidate results
    for my $r(@results)
     {my ($url, $code) = @$r;
      next unless $code;
      $f{$url}++;
     }
   }, sort keys %u);

  my %b; my %g;                                                                 # {url}{file} ++ : bad or good
  for   my $f(sort keys $xref->urls->%*)                                        # Each file
   {for my $u(sort keys$xref->urls->{$f}->%*)                                   # Each url
     {$b{$u}{$f}++ if  $f{$u};                                                  # Bad url
      $g{$u}{$f}++ if !$f{$u};                                                  # Good url
     }
   }

  my @bad; my @good; my $bu = 0; my $buf = 0; my $gu = 0; my $guf = 0;          # Report url status
  for my $u(sort keys %u)
   {if ($f{$u})                                                                 # Failing url
     {push @bad, [$u];                                                          # Url
      ++$bu;
      for my $f(sort keys $u{$u}->%*)                                           # Occurs in these files
       {push @bad, [q(), $f];
        ++$buf;
       }
     }
    else                                                                        # Successful url
     {push @good, [$u];
      ++$gu;
      for my $f(sort keys $u{$u}->%*)                                           # Occurs in these files
       {push @good, [q(), $f];
        ++$guf;
       }
     }
   }

  formatTables($xref, [@bad],
    columns => <<END,
Url       The url being tested
Files     The files the url occurs in
END
    title   => qq(Urls that fail),
    head    => <<END,
Xref found $bu failing urls in $buf files on DDDD
END
    file=>(fpe(qw(bad urls txt))),
    summarize=>1);

  formatTables($xref, [@good],
    columns => <<END,
Url       The url being tested
Files     The files the url occurs in
END
    title   => qq(Urls that pass),
    head    => <<END,
Xref found $gu good urls in $guf files on DDDD
END
    file=>(fpe(qw(good urls txt))),
    summarize=>1);

  {urlsBad  => {%b},
   urlsGood => {%g},
  }                                                                             # From multiverse to universe
 } # reportUrls

sub addNavTitlesToOneMap($$)                                                    #P Fix navtitles in one map
 {my ($xref, $file) = @_;                                                       # Xref results, file to fix
  my $changes = 0;                                                              # Number of successful changes
  my @r;                                                                        # Count of tags changed

  my $x = Data::Edit::Xml::new($file);                                          # Parse xml - should parse OK else otherwise how did we find out that this file needed to be fixed

  $x->by(sub                                                                    # Each node
   {my ($o) = @_;
    if ($o->at(qr(\A(appendix|chapter|mapref|topicref)\Z)is))                   # Nodes that take nav titles

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
   {editXml($file, $file, -p $x);                                               # Edit xml
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
   {processFilesInParallel                                                      # Process each file in parallel
      sub
       {my ($file) = @_;                                                        # File to process
        $xref->addNavTitlesToOneMap($file);                                     # Process one input file
       },
      sub {push @r, deSquareArray(@_)}, @files;
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

  my @bad  = sort {$$a[3] cmp $$b[3]} sort {$$a[1] cmp $$b[1]}                  # Sort results else we will get them in varying orders
                                      sort {$$a[0] cmp $$b[0]} @Bad;
  my @good = sort {$$a[2] cmp $$b[2]} sort {$$a[0] cmp $$b[0]}
             sort {$$a[3] cmp $$b[3]} sort {$$a[1] cmp $$b[1]} @Good;

  formatTables($xref, $xref->badNavTitles = \@bad,
    columns => <<END,
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
    file=>(my $f = fpe(qw(bad nav_titles txt))));

  formatTables($xref, $xref->goodNavTitles = \@good,
    columns => <<END,
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
    file=>(fpe(qw(good nav_titles txt))));

   {badNavTitles  => $xref->badNavTitles,
    goodNavTitles => $xref->goodNavTitles,
  }                                                                             # From multiverse to universe
 } # addNavTitlesToMaps

sub oxygenProjectFileMetaData                                                   #P Meta data for the oxygen project files
 {if (isSubInPackage(q(Data::Edit::Xml::Xref), q(xprMetaData)))
   {return &Data::Edit::Xml::Xref::xprMetaData(@_)                              # Call supplied sub to get optional meta data
   }
  q(<meta/>)                                                                    # Default
 } # oxygenProjectFileMetaData

sub createOxygenProjectFile($$$)                                                #P Create an Oxygen project file for the specified bookmap
 {my ($xref, $bm, $xprName) = @_;                                               # Xref, Bookmap, xpr name from bookmap

  my @mapRefs = ($bm);                                                          # Include this map in the project file

  my $extractRefs = sub                                                         # Extract references
   {my ($field) = @_;                                                           # Field to extract
    my %hash;

    for     my $bm(@mapRefs)                                                    # Initial plus referenced book maps
     {for   my $file(sort keys %{$xref->topicsReferencedFromBookMaps->{$bm}})   # Topics from referenced book maps
       {for my $href(sort keys %{$xref->{$field}->{$file}})                     # Href
         {if (my ($t) = parseDitaRef($href, $file))                             # Fully qualified target
           {$hash{$t}++;                                                        # Referenced file
           }
         }
       }
     }
    %hash
   };

  my $extractRefsAndWrapWithFileName = sub                                      # Extract some hrefs from the xref and wrap them with file name relative to the specified absolute file
   {my ($field, $xpr) = @_;                                                     # Field to extract, oxygen project file
    my %hash = &$extractRefs($field, $xpr);

    my @f;                                                                      # File names
    for my $file(sort keys %hash)
     {my $r = relFromAbsAgainstAbs $file, $xpr;
      push @f, qq(<file name="$r"/>);
     }

    join "\n", @f;
   };

  my $extractRefsAndWrapWithFolderName = sub                                    # Extract some hrefs from the xref and wrap them with containing folder names
   {my ($field, $xpr) = @_;                                                     # Field to extract, oxygen project file
    my %hash = &$extractRefs($field, $xpr);

    my %f;                                                                      # File names
    for my $file(sort keys %hash)
     {my $r = fp relFromAbsAgainstAbs $file, $xpr;
      $f{$r}++
     }

    my @f;                                                                      # Folder names
    for my $f(sort keys %f)
     {push @f, qq(<folder path="$f"/>);
     }

    join "\n", @f;
   };

  my $extractTopicsNotConrefs = sub                                             # Extract non conreffed topicrefs
   {my ($xpr) = @_;                                                             # Project file being built
    my %conRefs = &$extractRefs(q(conRefs), $xpr);

    my %p; my %s;                                                               # File names, files already seen
    for   my $bm(@mapRefs)                                                      # Each bookmap in this xpr
     {for my $file(sort keys $xref->topicsReferencedFromBookMaps->{$bm}->%*)    # Field to extract
       {if (my $docType = $xref->docType->{$file})                              # Include files only once even if they are referenced multiple times
         {if ($docType !~ m(map\Z)s and !$s{$file}++)                           # Include files only once even if they are referenced multiple times
           {if (!$conRefs{$file})
             {my $t = detagString($xref->title->{$file} // $file);
              my $r = relFromAbsAgainstAbs $file, $xpr;
              $p{fp $r}++
             }
           }
         }
       }
     }

    my @p;                                                                      # Folder names
    for my $p(sort keys %p)
     {push @p, qq(<folder path="$p"/>);
     }
    join "\n", sort @p;
   };

  my $extractTopicsNotConrefs22 = sub                                           # Extract non conreffed topicrefs
   {my ($xpr) = @_;                                                             # Project file being built
    my %conRefs = &$extractRefs(q(conRefs), $xpr);

    my @f; my %s;                                                               # File names, files already seen
    for   my $bm(@mapRefs)                                                      # Each bookmap in this xpr
     {for my $file(sort keys $xref->topicsReferencedFromBookMaps->{$bm}->%*)    # Field to extract
       {if (my $docType = $xref->docType->{$file})                              # Include files only once even if they are referenced multiple times
         {if ($docType !~ m(map\Z)s and !$s{$file}++)                           # Include files only once even if they are referenced multiple times
           {if (!$conRefs{$file})
             {my $t = detagString($xref->title->{$file} // $file);
              my $r = relFromAbsAgainstAbs $file, $xpr;
              push @f, <<END
<file name="$r"/>
END
             }
           }
         }
       }
     }

    join "\n", sort @f;
   };

  my $formatTargetsFolder = sub                                                 # Recreate the targets folder structure so that they can get from their old folder structure to the new flattened files
   {my ($xpr) = @_;                                                             # Oxygen project file

    my @r;
    my $r; $r = sub                                                             # Target files for each file in the bookmaps in this project file
     {my ($files) = @_;
      for my $f(sort keys %$files)
       {if (ref($$files{$f}))
         {push @r, qq(<folder name="$f">);
          &$r($$files{$f});
          push @r, qq(</folder>);
         }
        else
         {my $F = $$files{$f};                                                  # Find first containing bookmap
          for my $bm(@mapRefs)
           {if ($xref->topicsReferencedFromBookMaps->{$bm}{$F} or
                $xref->imagesReferencedFromBookMaps->{$bm}{$F})
             {my $t = detagString($xref->title->{$F} // $f);
              my $r = relFromAbsAgainstAbs $F, $xpr;
              push @r, <<END;
<folder name="$f" navTitle="$t">
  <file name="$r"/>
</folder>
END
              last;
             }
           }
         }
       }
     };

    join "\n", @r;
   };

  my $mapRefsFrom; $mapRefsFrom = sub                                           # Parse referenced bookmaps recursively
   {my ($bookMap, $href) = @_;                                                  # Bookmap, href in bookmap which refers to this bookmap

    my $bm = absFromAbsPlusRel($bookMap, $href);                                # Referenced bookmap
    push @mapRefs, $bm;                                                         # Save referenced bookmap

    if (my $x = eval {Data::Edit::Xml::new($bm)})                               # Parse bookmap
     {$x->by(sub                                                                # Traverse referenced bookmap
       {my ($o, $p, $q) = @_;
        if ($o->at_mapref)                                                      # Map reference in referenced bookmap
         {if (my $h = $o->href)
           {&$mapRefsFrom($bm, $h);
           }
         }
        elsif ($o->at_topicref)                                                 # Map referenced via topic ref in referenced bookmap
         {if ($o->attrX_format =~ m(\Aditamap\Z)i)
           {if (my $h = $o->href)
             {&$mapRefsFrom($bm, $h);
             }
           }
         }
       });
     }
   };

  my $x = Data::Edit::Xml::new($bm);                                            # Parse initial bookmap
  my $title;                                                                    # Title from initial bookmap

  $x->by(sub                                                                    # Traverse initial bookmap
   {my ($o, $p, $q) = @_;
    if    ($o->at(qr(title\Z)))
     {$title = $o->stringText;
     }
    elsif ($o->at_mapref)                                                       # Map ref in initial bookmap
     {if (my $h = $o->href)
       {&$mapRefsFrom($bm, $h, 1);
       }
     }
    elsif ($o->at_topicref)                                                     # Map referenced via a topic reference in the initial bookmap
     {if ($o->attrX_format =~ m(\Aditamap\Z)i)
       {if (my $h = $o->href)
         {&$mapRefsFrom($bm, $h, 1);
         }
       }
     }
   });

  $title //= q();                                                               # Default title
  my $out = &$xprName($bm, $title);                                             # Oxygen Project File name from bookmap name or title

  my $base      = fn $bm;                                                       # Remove MD5 sum to create an acceptable name but arbitrary name for the project tree
     $base      =~ s(_[a-f0-9]{32}\Z) ()i;                                      # Match book map name
  my $baseExt   = relFromAbsAgainstAbs($bm, $out);                              # Targeted book map that we are creating an xpr file for
  my $name      = fpe($base, q(xpr));                                           # Project tree name

  my $mapRefs   = join "\n",
    map
     {q(<file name=").relFromAbsAgainstAbs($_, $out).q("/>)                     # Xpr file out has references to bookmaps in other folders
     } @mapRefs;

  my $resources = &$extractRefsAndWrapWithFolderName(q(conRefs), $out);
  my $images    = &$extractRefsAndWrapWithFileName  (q(images),  $out);
  my $topics    = &$extractTopicsNotConrefs                     ($out);

  my $metaData  = &oxygenProjectFileMetaData;                                   # Add meta data if we are doing this for real otherwise ignore it as it is bulky and gets in the way

  my $X = eval {$x->new(<<END)};
<?xml version="1.0" encoding="UTF-8"?>
<project version="21.1">
    $metaData
    <projectTree name="$name">
        <folder masterFiles="true" name="Master Files">
           $mapRefs
        </folder>
        <folder name="$title Project">
          <folder name="$title Master Map">
            <file name="$baseExt"/>
          </folder>
          <folder name="Images">
            $images
          </folder>
          <folder name="Resources">
            $resources
          </folder>
          <folder name="Topics">
            $topics
          </folder>
        </folder>
        <folder name="CCX Content Repo (All)">
           <folder path="../"/>
        </folder>
    </projectTree>
</project>
END

# $X->go_projectTree->last->by(sub                                              # Cut out empty folders under the last folder otherwise we get lots of empty folders that contain no files because the files in them were not relevant to this bookmap
#  {my ($f) = @_;
#   $f->cutIfEmpty_folder;
#  });

  if ($@)
   {cluck "Unable to parse generated oxygen project file:\n$@"
   }
  else
   {my $text = Data::Edit::Xml::xmlHeader -p $X;

    owf($out, $text);
   }
 } # createOxygenProjectFile

sub createOxygenProjectMapFiles($)                                              #P Create Oxygen project files from Xref results
 {my ($xref) = @_;                                                              # Cross referencer

  my $xprName = sub                                                             # Method of choosing xpr file name
   {my $x = $xref->oxygenProjects;                                              # Method specified by caller
    if (isSubInPackage(q(Data::Edit::Xml::Xref), q(xprName)))
     {return sub {&Data::Edit::Xml::Xref::xprName(@_)}                          # Call supplied sub to generate xpr file name
     }
    return sub {my ($bm) = @_; setFileExtension($bm, q(xpr))} unless ref $x;    # xpr file mirrors book map
   }->();

  processFilesInParallel
    sub
     {my ($bm) = @_;
      createOxygenProjectFile($xref, $bm, $xprName);
     },
    sub {}, sort keys $xref->exteriorMaps->%*;                                  # Only for exterior book maps - i.e. only book maps that not referenced by any other book map.

  {}                                                                            # Multiverse to universe
 } # createOxygenProjectMapFiles

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
    return &$bad(q(No topic id))  unless $targetTopicId;                        # Check the target has a topic id
    return &$bad(q(Topic id does not match))
      unless $targetTopicId eq $topicId or $topicId eq q();                     # Check topic id of referenced topic against supplied topicId.  It is safe to assume that the target does have topic id as Dita requires one

    if ($id)                                                                    # Checkid if supplied
     {my $i = $xref->ids->{$target}{$id};                                       # Number of ids in the target topic with this value
      return &$bad(q(No such id in target topic)) unless $i;                    # No such id
      return &$bad(q(Duplicated id in target topic))                            # Duplicate ids
        unless $i == 1 or $i == 2 && $id eq $topicId;                           # Using dita topic references we can cope with one internal id that duplicates the topic id
     }
   }

  else                                                                          # No # in href
   {my $targetFile = absFromAbsPlusRel($file, $href);
    return [q(No such file), $href, $href, q(), q(), q(), q(),
            $file, $targetFile] unless &$fileExists($targetFile);               # Check target file exists
   }

  undef                                                                         # No error to report
 } # oneBadRef

#D0
# podDocumentation
=pod

=encoding utf-8

=head1 Name

Data::Edit::Xml::Xref - Cross reference Dita XML, match topics and ameliorate missing references.

=head1 Synopsis

L<Xref> scans an entire document corpus looking primarily for problems with
references between the files in the corpus; it reports any opportunities for
improvements it finds and makes changes to the corpus to implement these
improvements if so requested taking advantage of parallelism where ever
possible.

The following example checks the references in a corpus of Dita XML
documents held in folder L<inputFolder|/inputFolder>:

  use Data::Edit::Xml::Xref;

  my $x = xref(inputFolder   => q(in),
               fixBadRefs    => 1,
               flattenFolder => q(out2),
               matchTopics   => 0.9,
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
current corpus by other methods of fixing failing references such as:
L<fixDitaRefs>, L<fixRelocatedRefs> or L<fixXrefsByTitle>.

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
content of the B<xref> with the similarly normalized title of each topic that
is referenced by any book map that refers to the topic containing the B<xref>.

If a single matching candidate is located then it will be used to update the
B<href> attribute of the B<xref>.

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

=head2 Url checking

Xref will check urls by fetching their headers with L<curl> if the

  validateUrls=>1

is specified.  A list of failing L<url>s will be written to:

  reports/bad/urls.txt

while a corresponding list of passing L<url>s will be written to

  reports/good/urls.txt

=head1 Description

Cross reference Dita XML, match topics and ameliorate missing references.


Version 20200202.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Cross reference

Check the cross references in a set of Dita files and report the results.

=head2 xref(%attributes)

Check the cross references in a set of Dita files held in L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder. The possible attributes are defined in L<Data::Edit::Xml::Xref|/Data::Edit::Xml::Xref>.

     Parameter    Description
  1  %attributes  Cross referencer attribute value pairs

B<Example:>


  lll "Test 011";
    clearFolder(tests, 111);
    createSampleInputFilesForFixDitaRefsImproved3(tests);

    my $y = 𝘅𝗿𝗲𝗳(inputFolder => out, reports => reportFolder);                    # Check results without fixes
    ok $y->statusLine eq q(Xref: 1 ref);

    my $x = 𝘅𝗿𝗲𝗳
     (inputFolder => out,
      reports     => reportFolder,
      fixBadRefs  => 1,
      fixDitaRefs => targets,
      fixedFolder => outFixed);

    ok !$x->errors;


=head1 Create test data

Create files to test the various capabilities provided by Xref


=head2 Data::Edit::Xml::Xref Definition


Attributes used by the Xref cross referencer.




=head3 Input fields


B<addNavTitles> - If true, add navtitle to outgoing bookmap references to show the title of the target topic.

B<changeBadXrefToPh> - Change xrefs being placed in B<M3> by L<fixBadRefs> to B<ph>.

B<classificationMaps> - Create classification maps if true

B<deguidize> - Set true to replace guids in dita references with file name. Given reference B<g1#g2/id> convert B<g1> to a file name by locating the topic with topicId B<g2>.  This requires the guids to be genuinely unique. SDL guids are thought to be unique by language code but the same topic, translated to a different language might well have the same guid as the original topic with a different language code: =(de|en|es|fr).  If the source is in just one language then the guid uniqueness is a reasonable assumption.  If the conversion can be done in phases by language then the uniqueness of guids is again reasonably assured. L<Data::Edit::Xml::Lint> provides an alternative solution to deguidizing by using labels to record the dita reference in the input corpus for each id encountered, these references can then be resolved in the usual manner by L<Data::Edit::Xml::Lint::relint>.

B<deleteUnusedIds> - Delete ids (except on topics) that are not referenced in any reference in the corpus regardless of the file component of any such reference.

B<fixBadRefs> - Fix any remaining bad references after any all allowed attempts have been made to fix failing references by moving the failing reference to the B<xtrf> attribute i.e. placing it in B<M3> possibly renaming the tag to B<ph> if L<changeBadXrefToPh> is in effect as well.

B<fixDitaRefs> - Fix references in a corpus of L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> documents that have been converted to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> and whose target structure has been written to the named folder.

B<fixRelocatedRefs> - Fix references to topics that have been moved around in the out folder structure assuming that all file names are unique which they will be if they have been renamed to the GB Standard.

B<fixXrefsByTitle> - Try to fix invalid xrefs by the Gearhart Title Method enhanced by the Monroe map method if true

B<fixedFolder> - Fixed files are placed in this folder.

B<fixedFolderTemp> - Fixed files are placed in this folder if we are on aws but nit the session leader - this folder is then copied back to L<fixedFolder> on the session leader.

B<flattenFolder> - Files are renamed to the Gearhart standard and placed in this folder if set.  References to the unflattened files are updated to references to the flattened files.  This option will eventually be deprecated as the Dita::GB::Standard is now fully available allowing files to be easily flattened before being processed by Xref.

B<getFileUrl> - A url to retrieve a specified file from the server running xref used in generating html reports. The complete url is obtained by appending the fully qualified file name to this value.

B<html> - Generate html version of reports in this folder if supplied

B<indexWords> - Index words to topics and topics to words if true.

B<indexWordsFolder> - Folder into which to save words to topic and topics to word indexes if L<indexWords> is true.

B<inputFolder> - A folder containing the dita and ditamap files to be cross referenced.

B<matchTopics> - Match topics by title and by vocabulary to the specified confidence level between 0 and 1.  This operation might take some time to complete on a large corpus.

B<maxZoomIn> - Optional hash of names to regular expressions to look for in each file

B<maximumNumberOfProcesses> - Maximum number of processes to run in parallel at any one time with a sensible default.

B<oxygenProjects> - Create oxygen project files for each map - the project file will have an extension of .xpr and the same name and path as the map file or the name return by your implementation of: Data::Edit::Xml::Xref::xprName($map) if present.

B<reports> - Reports folder: Xref will write text versions of the generated reports to files in this folder.

B<requestAttributeNameAndValueCounts> - Report attribute name and value counts

B<subjectSchemeMap> - Create a subject scheme map in the named file

B<suppressReferenceChecks> - Suppress reference checking - which normally happens by default - but which takes time and might be irrelevant if an earlier xref has already checked all the references.

B<validateUrls> - Validate urls if true by fetching their headers with L<curl|https://linux.die.net/man/1/curl>



=head3 Output fields


B<allowUniquePartialMatches> - Allow unique partial matches - i.e ignore the stuff to the right of the # in a reference if doing so produces a unique result. This feature has been explicitly disabled for conrefs (PS2-561) and might need to be disabled for other types of reference as well.

B<attributeCount> - {file}{attribute name} == count of the different xml attributes found in the xml files.

B<attributeNamesAndValuesCount> - {file}{attribute name}{value} = count

B<author> - {file} = author of this file.

B<badGuidHrefs> - Bad conrefs - all.

B<badNavTitles> - Details of nav titles that were not resolved

B<badReferencesCount> - The number of bad references at the start of the run - however depending on what options were chosen Xref might ameliorate these bad references and thereby reduce this count.

B<badTables> - Array of tables that need fixing.

B<badXml1> - [Files] with a bad xml encoding header on the first line.

B<badXml2> - [Files] with a bad xml doc type on the second line.

B<baseFiles> - {base of file name}{full file name}++ Current location of the file via uniqueness guaranteed by the GB standard

B<baseTag> - Base Tag for each file

B<bookMapRefs> - {bookmap full file name}{href}{navTitle}++ References from bookmaps to topics via appendix, chapter, bookmapref.

B<conRefs> - {file}{href}{tag}++ : conref source detail

B<createReports1> - Reports requested before references fixed

B<createReports2> - Reports requested after references fixed

B<currentFolder> - The current working folder used to make absolute file names from relative ones

B<docType> - {file} == docType:  the docType for each xml file.

B<duplicateIds> - [file, id]     Duplicate id definitions within each file.

B<duplicateTopicIds> - [topicId, [files]] Files with duplicate topic ids - the id on the outermost tag.

B<emptyTopics> - {file} : topics where the *body is empty.

B<errors> - Number of significant errors as reported in L<statusLine> or 0 if no such errors found

B<exteriorMaps> - {exterior map} : maps that are not referenced by another map

B<fileExtensions> - Default file extensions to load

B<fixRefs> - {file}{ref} where the href or conref target is not valid.

B<fixedRefsBad> - [] hrefs and conrefs from L<fixRefs|/fixRefs> which were moved to the "xtrf" attribute as requested by the L<fixBadHrefs|/fixBadHrefs> attribute because the reference was invalid and could not be improved by L<deguidization|/deguidize>.

B<fixedRefsGB> - [] files fixed to the Gearhart-Brenan file naming standard

B<fixedRefsGood> - [] hrefs and conrefs from L<fixRefs|/fixRefs> which were invalid but have been fixed by L<deguidizing|/deguidize> them to a valid file name.

B<fixedRefsNoAction> - [] hrefs and conrefs from L<fixRefs|/fixRefs> for which no action was taken.

B<flattenFiles> - {old full file name} = file renamed to Gearhart-Brenan file naming standard

B<goodImageFiles> - {file}++ : number of references to each good image

B<goodNavTitles> - Details of nav titles that were resolved.

B<guidHrefs> - {file}{href} = location where href starts with GUID- and is thus probably a guid.

B<guidToFile> - {topic id which is a guid} = file defining topic id.

B<hrefUrlEncoding> - Hrefs that need url encoding because they contain white space.

B<idNotReferenced> - {file}{id}++ - id in a file that is not referenced

B<idReferencedCount> - {file}{id}++ - the number of times this id in this file is referenced from the rest of the corpus

B<idTags> - {file}{id}[tag] The tags associated with each id in a file - there might be more than one if the id is duplicated

B<ids> - {file}{id}   - id definitions across all files.

B<idsRemoved> - {id}++ : Ids removed from all files

B<images> - {file}{href}   Count of image references in each file.

B<imagesReferencedFromBookMaps> - {bookmap full file name}{full name of image referenced from topic referenced from bookmap}++

B<imagesReferencedFromTopics> - {topic full file name}{full name of image referenced from topic}++

B<imagesToRefferingBookMaps> - {image full file name}{bookmap full file name}++ : images to referring bookmaps

B<indexedWords> - {word}{full file name of topic the words occurs in}.

B<inputFileToTargetTopics> - {input file}{target file}++ : Tells us the topics an input file was split into

B<inputFiles> - Input files from L<inputFolder|/inputFolder>.

B<inputFolderImages> - {full image file name} for all files in input folder thus including any images resent

B<ltgt> - {text between &lt; and &gt}{filename} = count giving the count of text items found between &lt; and &gt;

B<maxZoomOut> - Results from L<maxZoomIn|/maxZoomIn>  where {file name}{regular expression key name in L<maxZoomIn|/maxZoomIn>}++

B<md5Sum> - MD5 sum for each input file.

B<md5SumDuplicates> - {md5sum}{file}++ : md5 sums with more than one file

B<missingImageFiles> - [file, href] == Missing images in each file.

B<missingTopicIds> - Missing topic ids.

B<noHref> - Tags that should have an href but do not have one.

B<notReferenced> - {file name} Files in input area that are not referenced by a conref, image, bookmapref or xref tag and are not a bookmap.

B<olBody> - The number of ol under body by file

B<originalSourceFileAndIdToNewFile> - {original file}{id} = new file: Record mapping from original source file and id to the new file containing the id

B<otherMeta> - {original file}{othermeta name}{othermeta content}++ : the contents of the other meta tags

B<otherMetaBookMapsAfterTopicIncludes> - Bookmap othermeta after  topic othermeta has been included

B<otherMetaBookMapsBeforeTopicIncludes> - Bookmap othermeta before topic othermeta has been included

B<otherMetaConsolidated> - {Name}{Content}++ : consolidated other meta data across entire corpus

B<otherMetaDuplicatesCombined> - Duplicate othermeta in bookmaps with called topics othermeta included

B<otherMetaDuplicatesSeparately> - Duplicate othermeta in bookmaps and topics considered separately

B<otherMetaPushToBookMap> - Othermeta that can be pushed to the calling book map

B<otherMetaRemainWithTopic> - Othermeta that must stay in the topic

B<parseFailed> - {file} files that failed to parse.

B<publicId> - {file} = Public id on Doctype

B<references> - {file}{reference}++ - the various references encountered

B<relocatedReferencesFailed> - Failing references that were not fixed by relocation

B<relocatedReferencesFixed> - Relocated references fixed

B<requiredCleanUp> - {full file name}{cleanup} = number of required-cleanups

B<results> - Summary of results table.

B<sourceTopicToTargetBookMap> - {input topic cut into multiple pieces} = output bookmap representing pieces

B<statusLine> - Status line summarizing the cross reference.

B<statusTable> - Status table summarizing the cross reference.

B<tableDimensions> - {file}{columns}{rows} == count

B<tagCount> - {file}{tags} == count of the different tag names found in the xml files.

B<tags> - Number of tags encountered

B<tagsTextsRatio> - Ratio of tags to text encountered

B<targetFolderContent> - {file} = bookmap file name : the target folder content which shows us where an input file went

B<targetTopicToInputFiles> - {current file} = the source file from which the current file was obtained

B<texts> - Number of texts encountered

B<timeEnded> - Time the run ended

B<timeStart> - Time the run started

B<title> - {full file name} = title of file.

B<titleToFile> - {title}{file}++ if L<fixXrefsByTitle> is in effect

B<topicFlattening> - {topic}{sources}++ : the source files for each topic that was flattened

B<topicFlatteningFactor> - Topic flattening factor - higher is better

B<topicIds> - {file} = topic id - the id on the outermost tag.

B<topicsFlattened> - Number of topics flattened

B<topicsNotReferencedFromBookMaps> - {topic file not referenced from any bookmap} = 1

B<topicsReferencedFromBookMaps> - {bookmap full file name}{topic full file name}++ : bookmaps to topics

B<topicsToReferringBookMaps> - {topic full file name}{bookmap full file name}++ : topics to referring bookmaps

B<urls> - {topic full file name}{url}++ : urls found in each file

B<urlsBad> - {url}{topic full file name}++ : failing urls found in each file

B<urlsGood> - {url}{topic full file name}++ : passing urls found in each file

B<validationErrors> - True means that Lint detected errors in the xml contained in the file.

B<vocabulary> - The text of each topic shorn of attributes for vocabulary comparison.

B<xRefs> - {file}{href}++ Xrefs references.

B<xrefBadFormat> - External xrefs with no format=html.

B<xrefBadScope> - External xrefs with no scope=external.

B<xrefsFixedByTitle> - Xrefs fixed by locating a matching topic title from their text content.



=head1 Private Methods

=head2 newXref(%attributes)

Create a new cross referencer

     Parameter    Description
  1  %attributes  Attributes

=head2 xref2(%attributes)

Check the cross references in a set of Dita files held in  L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder. The possible attributes are defined in L<Data::Edit::Xml::Xref|/Data::Edit::Xml::Xref>

     Parameter    Description
  1  %attributes  Attributes of cross referencer

=head2 createReportsInParallel($xref, @reports)

Create reports in parallel

     Parameter  Description
  1  $xref      Cross referencer
  2  @reports   Reports to be run

=head2 createReportsInParallel1()

Create reports in parallel that do not require fixed references


=head2 createReportsInParallel2()

Create reports in parallel that        require fixed references


=head2 countLevels($l, $h)

Count has elements to the specified number of levels

     Parameter  Description
  1  $l         Levels
  2  $h         Hash

=head2 externalReference($reference)

Check for an external reference

     Parameter   Description
  1  $reference  Reference to check

=head2 fixingRun($xref)

A fixing run fixes problems where it can and thus induces changes which might make the updated output different from the incoming source.  Returns a useful message describing this state of affairs.

     Parameter  Description
  1  $xref      Cross referencer

=head2 loadInputFiles($xref)

Load the names of the files to be processed

     Parameter  Description
  1  $xref      Cross referencer

=head2 formatTables($xref, $data, %options)

Using cross reference B<$xref> options and an array of arrays B<$data> format a report as a table using B<%options> as described in L<Data::Table::Text::formatTable> and L<Data::Table::Text::formatHtmlTable>.

     Parameter  Description
  1  $xref      Cross referencer
  2  $data      Table to be formatted
  3  %options   Options

=head2 hashOfCountsToArray($hash)

Convert a B<$hash> of {key} = count to an array so it can be formatted with L<formatTables>

     Parameter  Description
  1  $hash      Hash to be converted

=head2 reportGuidsToFiles($xref)

Map and report guids to files

     Parameter  Description
  1  $xref      Xref results

=head2 editXml($in, $out, $source)

Edit an xml file retaining any existing XML headers and lint trailers

     Parameter  Description
  1  $in        Input file
  2  $out       Output file
  3  $source    Source to write

=head2 fixReferencesInOneFile($xref, $sourceFile)

Fix one file by moving unresolved references to the xtrf attribute

     Parameter    Description
  1  $xref        Xref results
  2  $sourceFile  Source file to fix

=head2 fixReferencesParallel($xref, $file)

Fix the references in one file

     Parameter  Description
  1  $xref      Cross referencer
  2  $file      File to fix

=head2 fixReferencesResults($xref, @results)

Consolidate the results of fixing references.

     Parameter  Description
  1  $xref      Cross referencer
  2  @results   Results from fixReferencesInParallel

=head2 fixReferences($xref)

Fix just the file containing references using a number of techniques and report those references that cannot be so fixed.

     Parameter  Description
  1  $xref      Xref results

=head2 fixOneFileGB($xref, $file)

Fix one file to the Gearhart-Brenan standard

     Parameter  Description
  1  $xref      Xref results
  2  $file      File to fix

=head2 fixFilesGB($xref)

Rename files to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>

     Parameter  Description
  1  $xref      Xref results

=head2 analyzeOneFileParallel($Xref, $iFile)

Analyze one input file

     Parameter  Description
  1  $Xref      Xref request
  2  $iFile     File to analyze

=head2 analyzeOneFileResults($xref, @x)

Merge a list of cross reference results into the first cross referencer in the list

     Parameter  Description
  1  $xref      Cross referencer to merge into
  2  @x         Other cross referencers

=head2 analyzeInputFiles($xref)

Analyze the input files

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportIdRefs($xref)

Report the number of times each id is referenced

     Parameter  Description
  1  $xref      Cross referencer

=head2 removeUnusedIds($xref)

Remove ids that do are not mentioned in any href or conref in the corpus regardless of the file component of any such reference. This is a very conservative approach which acknowledges that writers might be looking for an id if they mention it in a reference.

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportEmptyTopics($xref)

Report empty topics

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportDuplicateIds($xref)

Report duplicate ids

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportDuplicateTopicIds($xref)

Report duplicate topic ids

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportNoHrefs($xref)

Report locations where an href was expected but not found

     Parameter  Description
  1  $xref      Cross referencer

=head2 checkReferences($xref)

Check each reference, report bad references and mark them for fixing.

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportGuidHrefs($xref)

Report on guid hrefs

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportImages($xref)

Reports on images and references to images

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportParseFailed($xref)

Report failed parses

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportXml1($xref)

Report bad xml on line 1

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportXml2($xref)

Report bad xml on line 2

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportDocTypeCount($xref)

Report doc type count

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportTagCount($xref)

Report tag counts

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportTagsAndTextsCount($xref)

Report tags and texts counts

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportLtGt($xref)

Report items found between &lt; and &gt;

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportAttributeCount($xref)

Report attribute counts

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportAttributeNameAndValueCounts($xref)

Report attribute value counts

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportValidationErrors($xref)

Report the files known to have validation errors

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportTables($xref)

Report on tables that have problems

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportFileExtensionCount($xref)

Report file extension counts

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportFileTypes($xref)

Report file type counts - takes too long in series

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportExternalXrefs($xref)

Report external xrefs missing other attributes

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportMaxZoomOut($xref)

Text located via Max Zoom In

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportTopicDetails($xref)

Things that occur once in each file

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportTopicReuse($xref)

Count how frequently each topic is reused

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportFixRefs($xref)

Report of hrefs that need to be fixed

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportSourceFiles($xref)

Source file for each topic

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportReferencesFromBookMaps($xref)

Topics and images referenced from bookmaps

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportExteriorMaps($xref)

Maps that are not referenced by any other map

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportTopicsNotReferencedFromBookMaps($xref)

Topics not referenced from bookmaps

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportTableDimensions($xref)

Report table dimensions

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportOtherMeta($xref)

Advise in the feasibility of moving othermeta data from topics to bookmaps assuming that the othermeta data will be applied only at the head of the map rather than individually to each topic in the map.

     Parameter  Description
  1  $xref      Cross referencer

=head2 createSubjectSchemeMap($xref)

Create a subject scheme map from othermeta

     Parameter  Description
  1  $xref      Cross referencer

=head2 writeClassificationHtml($xref, $classification)

Write classification tree as html

     Parameter        Description
  1  $xref            Cross referencer
  2  $classification  {title=>{subject=>{file=>++}}}

=head2 createClassificationMap($xref, $bookMap, $classification)

Create a classification map for each bookmap

     Parameter        Description
  1  $xref            Cross referencer
  2  $bookMap         Bookmap to classify
  3  $classification  Classification scheme

=head2 createClassificationMaps($xref)

Create classification maps for each bookmap

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportSimilarTopicsByTitle($xref)

Report topics likely to be similar on the basis of their titles as expressed in the non Guid part of their file names

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportSimilarTopicsByVocabulary($xref)

Report topics likely to be similar on the basis of their vocabulary

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportWordsByFile($xref)

Index words to the files they occur in

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportMd5Sum($xref)

Report files with identical md5 sums

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportOlBody($xref)

ol under body - indicative of a task

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportHrefUrlEncoding($xref)

href needs url encoding

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportConRefMatching($xref)

Report conref matching

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportPublicIds($xref)

Report public ids in use

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportRequiredCleanUps($xref)

Report required clean ups

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportUrls($xref)

Report urls that fail to resolve

     Parameter  Description
  1  $xref      Cross referencer

=head2 addNavTitlesToOneMap($xref, $file)

Fix navtitles in one map

     Parameter  Description
  1  $xref      Xref results
  2  $file      File to fix

=head2 addNavTitlesToMaps($xref)

Add nav titles to files containing maps.

     Parameter  Description
  1  $xref      Xref results

=head2 oxygenProjectFileMetaData()

Meta data for the oxygen project files


=head2 createOxygenProjectFile($xref, $bm, $xprName)

Create an Oxygen project file for the specified bookmap

     Parameter  Description
  1  $xref      Xref
  2  $bm        Bookmap
  3  $xprName   Xpr name from bookmap

=head2 createOxygenProjectMapFiles($xref)

Create Oxygen project files from Xref results

     Parameter  Description
  1  $xref      Cross referencer

=head2 oneBadRef($xref, $file, $href)

Check one reference and return the first error encountered or B<undef> if no errors encountered. Relies on L<topicIds> to test files present and test the B<topicId> is valid, relies on L<ids> to check that the referenced B<id> is valid.

     Parameter  Description
  1  $xref      Cross referencer
  2  $file      File containing reference
  3  $href      Reference

=head2 createSampleInputFilesBaseCase($in, $N)

Create sample input files for testing. The attribute B<inputFolder> supplies the name of the folder in which to create the sample files.

     Parameter  Description
  1  $in        Input folder
  2  $N         Number of sample files

=head2 createSampleInputFilesFixFolder($in)

Create sample input files for testing fixFolder

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createSampleInputFilesLtGt($in)

Create sample input files for testing items between &lt; and &gt;

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createSampleInputFilesForFixDitaRefs($in, $targets)

Create sample input files for fixing renamed topic refs

     Parameter  Description
  1  $in        Folder to create the files in
  2  $targets   Targets folder

=head2 createSampleInputFilesForFixDitaRefsXref($in)

Create sample input files for fixing references into renamed topics by xref

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createSampleConRefs($in)

Create sample input files for fixing a conref

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createSampleConRefMatching($in)

Create sample input files for matching conref source and targets

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createSampleDuplicateMd5Sum($in)

Create sample input files with duplicate md5 sums

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createSampleUnreferencedIds($in)

Create sample input files with unreferenced ids

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createEmptyBody($in)

Create sample input files for empty body detection

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createClassificationMapsTest($in)

Create sample input files for a classification map

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createWordsToFilesTest($in)

Index words to file

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createUrlTests($in)

Check urls

     Parameter  Description
  1  $in        Folder to create the files in

=head2 changeFolderAndWriteFiles($f, $D)

Change file structure to the current folder and write

     Parameter  Description
  1  $f         Data structure as a string
  2  $D         Target folder

=head2 createSampleInputFilesForFixDitaRefsImproved1($folder)

Create sample input files for fixing references via the targets/ folder

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createSampleInputFilesForFixDitaRefsImproved2($folder)

Create sample input files for fixing conref references via the targets/ folder

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createSampleInputFilesForFixDitaRefsImproved3($folder)

Create sample input files for fixing bookmap references to topics that get cut into multiple pieces

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createSampleInputFilesForFixDitaRefsImproved4($folder)

Create sample input files for fixing bookmap reference to a topic that did not get cut into  multiple pieces

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createSampleImageTest($folder)

Create sample input files for fixing bookmap reference to a topic that did not get cut into  multiple pieces

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createTestTopicFlattening($folder)

Create sample input files for testing topic flattening ratio reporting

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createTestReferencedToFlattenedTopic($folder)

Full reference to a topic that has been flattened

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createTestReferenceToCutOutTopic($folder)

References from a topic that has been cut out to a topic that has been cut out

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createSampleOtherMeta($out)

Create sample data for othermeta reports

     Parameter  Description
  1  $out       Folder

=head2 createTestOneNotRef($folder)

One topic refernced and the other not

     Parameter  Description
  1  $folder    Folder to switch to

=head2 createSampleTopicsReferencedFromBookMaps($in)

The number of times a topic is referenced from a bookmap

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createSampleImageReferences($in)

Good and bad image references

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createRequiredCleanUps($in)

Required clean ups report

     Parameter  Description
  1  $in        Folder to create the files in

=head2 createSoftConrefs($in)

Fix file part of conref even if the rest is invalid

     Parameter  Description
  1  $in        Folder to create the files in

=head2 checkXrefStructure($x, $field, @folders)

Check an output structure produced by Xrf

     Parameter  Description
  1  $x         Cross references
  2  $field     Field to check
  3  @folders   Folders to suppress

=head2 writeXrefStructure($x, $field, @folders)

Write the test for an Xref structure

     Parameter  Description
  1  $x         Cross referencer
  2  $field     Field
  3  @folders   Names of the folders to suppress

=head2 deleteVariableFields($x)

Remove time and other fields that do not affect the end results

     Parameter  Description
  1  $x         Cross referencer

=head2 testReferenceChecking()

Test reference checking



=head1 Index


1 L<addNavTitlesToMaps|/addNavTitlesToMaps> - Add nav titles to files containing maps.

2 L<addNavTitlesToOneMap|/addNavTitlesToOneMap> - Fix navtitles in one map

3 L<analyzeInputFiles|/analyzeInputFiles> - Analyze the input files

4 L<analyzeOneFileParallel|/analyzeOneFileParallel> - Analyze one input file

5 L<analyzeOneFileResults|/analyzeOneFileResults> - Merge a list of cross reference results into the first cross referencer in the list

6 L<changeFolderAndWriteFiles|/changeFolderAndWriteFiles> - Change file structure to the current folder and write

7 L<checkReferences|/checkReferences> - Check each reference, report bad references and mark them for fixing.

8 L<checkXrefStructure|/checkXrefStructure> - Check an output structure produced by Xrf

9 L<countLevels|/countLevels> - Count has elements to the specified number of levels

10 L<createClassificationMap|/createClassificationMap> - Create a classification map for each bookmap

11 L<createClassificationMaps|/createClassificationMaps> - Create classification maps for each bookmap

12 L<createClassificationMapsTest|/createClassificationMapsTest> - Create sample input files for a classification map

13 L<createEmptyBody|/createEmptyBody> - Create sample input files for empty body detection

14 L<createOxygenProjectFile|/createOxygenProjectFile> - Create an Oxygen project file for the specified bookmap

15 L<createOxygenProjectMapFiles|/createOxygenProjectMapFiles> - Create Oxygen project files from Xref results

16 L<createReportsInParallel|/createReportsInParallel> - Create reports in parallel

17 L<createReportsInParallel1|/createReportsInParallel1> - Create reports in parallel that do not require fixed references

18 L<createReportsInParallel2|/createReportsInParallel2> - Create reports in parallel that        require fixed references

19 L<createRequiredCleanUps|/createRequiredCleanUps> - Required clean ups report

20 L<createSampleConRefMatching|/createSampleConRefMatching> - Create sample input files for matching conref source and targets

21 L<createSampleConRefs|/createSampleConRefs> - Create sample input files for fixing a conref

22 L<createSampleDuplicateMd5Sum|/createSampleDuplicateMd5Sum> - Create sample input files with duplicate md5 sums

23 L<createSampleImageReferences|/createSampleImageReferences> - Good and bad image references

24 L<createSampleImageTest|/createSampleImageTest> - Create sample input files for fixing bookmap reference to a topic that did not get cut into  multiple pieces

25 L<createSampleInputFilesBaseCase|/createSampleInputFilesBaseCase> - Create sample input files for testing.

26 L<createSampleInputFilesFixFolder|/createSampleInputFilesFixFolder> - Create sample input files for testing fixFolder

27 L<createSampleInputFilesForFixDitaRefs|/createSampleInputFilesForFixDitaRefs> - Create sample input files for fixing renamed topic refs

28 L<createSampleInputFilesForFixDitaRefsImproved1|/createSampleInputFilesForFixDitaRefsImproved1> - Create sample input files for fixing references via the targets/ folder

29 L<createSampleInputFilesForFixDitaRefsImproved2|/createSampleInputFilesForFixDitaRefsImproved2> - Create sample input files for fixing conref references via the targets/ folder

30 L<createSampleInputFilesForFixDitaRefsImproved3|/createSampleInputFilesForFixDitaRefsImproved3> - Create sample input files for fixing bookmap references to topics that get cut into multiple pieces

31 L<createSampleInputFilesForFixDitaRefsImproved4|/createSampleInputFilesForFixDitaRefsImproved4> - Create sample input files for fixing bookmap reference to a topic that did not get cut into  multiple pieces

32 L<createSampleInputFilesForFixDitaRefsXref|/createSampleInputFilesForFixDitaRefsXref> - Create sample input files for fixing references into renamed topics by xref

33 L<createSampleInputFilesLtGt|/createSampleInputFilesLtGt> - Create sample input files for testing items between &lt; and &gt;

34 L<createSampleOtherMeta|/createSampleOtherMeta> - Create sample data for othermeta reports

35 L<createSampleTopicsReferencedFromBookMaps|/createSampleTopicsReferencedFromBookMaps> - The number of times a topic is referenced from a bookmap

36 L<createSampleUnreferencedIds|/createSampleUnreferencedIds> - Create sample input files with unreferenced ids

37 L<createSoftConrefs|/createSoftConrefs> - Fix file part of conref even if the rest is invalid

38 L<createSubjectSchemeMap|/createSubjectSchemeMap> - Create a subject scheme map from othermeta

39 L<createTestOneNotRef|/createTestOneNotRef> - One topic refernced and the other not

40 L<createTestReferencedToFlattenedTopic|/createTestReferencedToFlattenedTopic> - Full reference to a topic that has been flattened

41 L<createTestReferenceToCutOutTopic|/createTestReferenceToCutOutTopic> - References from a topic that has been cut out to a topic that has been cut out

42 L<createTestTopicFlattening|/createTestTopicFlattening> - Create sample input files for testing topic flattening ratio reporting

43 L<createUrlTests|/createUrlTests> - Check urls

44 L<createWordsToFilesTest|/createWordsToFilesTest> - Index words to file

45 L<deleteVariableFields|/deleteVariableFields> - Remove time and other fields that do not affect the end results

46 L<editXml|/editXml> - Edit an xml file retaining any existing XML headers and lint trailers

47 L<externalReference|/externalReference> - Check for an external reference

48 L<fixFilesGB|/fixFilesGB> - Rename files to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>

49 L<fixingRun|/fixingRun> - A fixing run fixes problems where it can and thus induces changes which might make the updated output different from the incoming source.

50 L<fixOneFileGB|/fixOneFileGB> - Fix one file to the Gearhart-Brenan standard

51 L<fixReferences|/fixReferences> - Fix just the file containing references using a number of techniques and report those references that cannot be so fixed.

52 L<fixReferencesInOneFile|/fixReferencesInOneFile> - Fix one file by moving unresolved references to the xtrf attribute

53 L<fixReferencesParallel|/fixReferencesParallel> - Fix the references in one file

54 L<fixReferencesResults|/fixReferencesResults> - Consolidate the results of fixing references.

55 L<formatTables|/formatTables> - Using cross reference B<$xref> options and an array of arrays B<$data> format a report as a table using B<%options> as described in L<Data::Table::Text::formatTable> and L<Data::Table::Text::formatHtmlTable>.

56 L<hashOfCountsToArray|/hashOfCountsToArray> - Convert a B<$hash> of {key} = count to an array so it can be formatted with L<formatTables>

57 L<loadInputFiles|/loadInputFiles> - Load the names of the files to be processed

58 L<newXref|/newXref> - Create a new cross referencer

59 L<oneBadRef|/oneBadRef> - Check one reference and return the first error encountered or B<undef> if no errors encountered.

60 L<oxygenProjectFileMetaData|/oxygenProjectFileMetaData> - Meta data for the oxygen project files

61 L<removeUnusedIds|/removeUnusedIds> - Remove ids that do are not mentioned in any href or conref in the corpus regardless of the file component of any such reference.

62 L<reportAttributeCount|/reportAttributeCount> - Report attribute counts

63 L<reportAttributeNameAndValueCounts|/reportAttributeNameAndValueCounts> - Report attribute value counts

64 L<reportConRefMatching|/reportConRefMatching> - Report conref matching

65 L<reportDocTypeCount|/reportDocTypeCount> - Report doc type count

66 L<reportDuplicateIds|/reportDuplicateIds> - Report duplicate ids

67 L<reportDuplicateTopicIds|/reportDuplicateTopicIds> - Report duplicate topic ids

68 L<reportEmptyTopics|/reportEmptyTopics> - Report empty topics

69 L<reportExteriorMaps|/reportExteriorMaps> - Maps that are not referenced by any other map

70 L<reportExternalXrefs|/reportExternalXrefs> - Report external xrefs missing other attributes

71 L<reportFileExtensionCount|/reportFileExtensionCount> - Report file extension counts

72 L<reportFileTypes|/reportFileTypes> - Report file type counts - takes too long in series

73 L<reportFixRefs|/reportFixRefs> - Report of hrefs that need to be fixed

74 L<reportGuidHrefs|/reportGuidHrefs> - Report on guid hrefs

75 L<reportGuidsToFiles|/reportGuidsToFiles> - Map and report guids to files

76 L<reportHrefUrlEncoding|/reportHrefUrlEncoding> - href needs url encoding

77 L<reportIdRefs|/reportIdRefs> - Report the number of times each id is referenced

78 L<reportImages|/reportImages> - Reports on images and references to images

79 L<reportLtGt|/reportLtGt> - Report items found between &lt; and &gt;

80 L<reportMaxZoomOut|/reportMaxZoomOut> - Text located via Max Zoom In

81 L<reportMd5Sum|/reportMd5Sum> - Report files with identical md5 sums

82 L<reportNoHrefs|/reportNoHrefs> - Report locations where an href was expected but not found

83 L<reportOlBody|/reportOlBody> - ol under body - indicative of a task

84 L<reportOtherMeta|/reportOtherMeta> - Advise in the feasibility of moving othermeta data from topics to bookmaps assuming that the othermeta data will be applied only at the head of the map rather than individually to each topic in the map.

85 L<reportParseFailed|/reportParseFailed> - Report failed parses

86 L<reportPublicIds|/reportPublicIds> - Report public ids in use

87 L<reportReferencesFromBookMaps|/reportReferencesFromBookMaps> - Topics and images referenced from bookmaps

88 L<reportRequiredCleanUps|/reportRequiredCleanUps> - Report required clean ups

89 L<reportSimilarTopicsByTitle|/reportSimilarTopicsByTitle> - Report topics likely to be similar on the basis of their titles as expressed in the non Guid part of their file names

90 L<reportSimilarTopicsByVocabulary|/reportSimilarTopicsByVocabulary> - Report topics likely to be similar on the basis of their vocabulary

91 L<reportSourceFiles|/reportSourceFiles> - Source file for each topic

92 L<reportTableDimensions|/reportTableDimensions> - Report table dimensions

93 L<reportTables|/reportTables> - Report on tables that have problems

94 L<reportTagCount|/reportTagCount> - Report tag counts

95 L<reportTagsAndTextsCount|/reportTagsAndTextsCount> - Report tags and texts counts

96 L<reportTopicDetails|/reportTopicDetails> - Things that occur once in each file

97 L<reportTopicReuse|/reportTopicReuse> - Count how frequently each topic is reused

98 L<reportTopicsNotReferencedFromBookMaps|/reportTopicsNotReferencedFromBookMaps> - Topics not referenced from bookmaps

99 L<reportUrls|/reportUrls> - Report urls that fail to resolve

100 L<reportValidationErrors|/reportValidationErrors> - Report the files known to have validation errors

101 L<reportWordsByFile|/reportWordsByFile> - Index words to the files they occur in

102 L<reportXml1|/reportXml1> - Report bad xml on line 1

103 L<reportXml2|/reportXml2> - Report bad xml on line 2

104 L<testReferenceChecking|/testReferenceChecking> - Test reference checking

105 L<writeClassificationHtml|/writeClassificationHtml> - Write classification tree as html

106 L<writeXrefStructure|/writeXrefStructure> - Write the test for an Xref structure

107 L<xref|/xref> - Check the cross references in a set of Dita files held in L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder.

108 L<xref2|/xref2> - Check the cross references in a set of Dita files held in  L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder.

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

if ($^O !~ m(bsd|linux)i)
 {plan skip_all => 'Not supported';
 }

Test::More->builder->output("/dev/null")                                        # Show only errors during testing
  if ((caller(1))[0]//'Data::Edit::Xml::Xref') eq "Data::Edit::Xml::Xref";

makeDieConfess;

my $conceptHeader = <<END =~ s(\s*\Z) ()gsr;                                    # Header for a concept
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Task//EN" "concept.dtd" []>
END

mmm "Tests started";

my $testsFolder = temporaryFolder;                                              # Tests folder

#goto latestTest;

sub tests       {$testsFolder}
sub in          {fpd tests, q(in)}                                              # Input folder
sub out         {fpd tests, q(out)}                                             # Output folder
sub outFixed    {fpd tests, q(outFixed)}                                        # Fixed output folder
sub reportFolder{fpd tests, q(report)}                                          # Reports folder
sub targets     {fpf tests, q(targets)}                                         # Tests targets folder

#D1 Create test data                                                            # Create files to test the various capabilities provided by Xref

sub createSampleInputFilesBaseCase($$)                                          #P Create sample input files for testing. The attribute B<inputFolder> supplies the name of the folder in which to create the sample files.
 {my ($in, $N) = @_;                                                            # Input folder, number of sample files
  clearFolder($in, 1e2);
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

sub createSampleConRefs($)                                                      #P Create sample input files for fixing a conref
 {my ($in) = @_;                                                                # Folder to create the files in
  my $d = fpd(currentDirectory, $in);
  owf(fpe($in, qw(c1 dita)), <<END);
<concept id="c1">
  <title>1111</title>
  <conbody>
    <p id="i1" conref="c2.dita#c2/p1"/>
    <p id="i2" conref="c2.dita#c2/p2"/>
    <p id="i2" conref="c2.dita#c2/p3"/>
    <xref id="c1" href="c1.dita#c1/i1"/>
    <xref id="x1" href="c1.dita#c1/i2"/>
    <xref href="c1.dita#c1/i3"/>
    <xref href="c1.dita#c1/i3"/>
    <xref href="c1.dita#c1/i3"/>
  </conbody>
</concept>
END
  owf(fpe($in, qw(c2 dita)), <<END);
<concept id="c2">
  <title id="c2">2222</title>
  <conbody>
    <p id="p1">p1p1p1p1</p>
    <p id="p2">p2p2p2p2</p>
  </conbody>
</concept>
END
 }

sub createSampleConRefMatching($)                                               #P Create sample input files for matching conref source and targets
 {my ($in) = @_;                                                                # Folder to create the files in
  my $d = fpd(currentDirectory, $in);
  owf(fpe($in, qw(c1 dita)), <<END);
<concept id="c1">
  <title>1111</title>
  <conbody>
    <p conref="c2.dita#c2/p1"/>
    <p conref="c2.dita#c2/q1"/>
  </conbody>
</concept>
END
  owf(fpe($in, qw(c2 dita)), <<END);
<concept id="c2">
  <title>2222</title>
  <conbody>
    <p id="p1">p1p1p1p1</p>
    <q id="q1">q1q1q1q1</q>
  </conbody>
</concept>
END
 }

sub createSampleDuplicateMd5Sum($)                                              #P Create sample input files with duplicate md5 sums
 {my ($in) = @_;                                                                # Folder to create the files in
  my $d = fpd(currentDirectory, $in);
  owf(fpe($in, $_, qw(c dita)), <<END) for 1..3;
<concept/>
END
  owf(fpe($in, $_, qw(t dita)), <<END) for 1..2;
<task/>
END
 }

sub createSampleUnreferencedIds($)                                              #P Create sample input files with unreferenced ids
 {my ($in) = @_;                                                                # Folder to create the files in
  my $d = fpd(currentDirectory, $in);
  owf(fpe($in, $_, qw(c1 dita)), <<END);
<concept id="c1">
  <title id="c1"/>
  <conbody>
    <p id="p1"/>
    <p id="p2"/>
    <p id="p2"/>
    <p id="p3"/>
    <p id="p3"/>
    <p id="p3"/>
  </conbody>
</concept>
END
  owf(fpe($in, $_, qw(c2 dita)), <<END);
<concept id="c2">
  <title id="c2"/>
  <conbody>
    <p href="c1.dita#p1"/>
    <p conref="c1.dita#c1/p2"/>
  </conbody>
</concept>
END
 }

sub createEmptyBody($)                                                          #P Create sample input files for empty body detection
 {my ($in) = @_;                                                                # Folder to create the files in
  my $d = fpd(currentDirectory, $in);
  owf(fpe($in, qw(c1 dita)), <<END);
$conceptHeader
<concept id="c1">
  <title>Empty</title>
  <conbody/>
</concept>
END
  owf(fpe($in, qw(c2 dita)), <<END);
$conceptHeader
<concept id="c2">
  <title>Full</title>
  <conbody>
    <p>2222</p>
  </conbody>
</concept>
END
 }

sub createClassificationMapsTest($)                                             #P Create sample input files for a classification map
 {my ($in) = @_;                                                                # Folder to create the files in
  my $d = fpd($in);
  owf(fpe($in, qw(maps m1 ditamap)), <<END);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE map PUBLIC "-//OASIS//DTD DITA Map//EN" "map.dtd">
<map id="m1">
    <title>A map that is not nested</title>
    <mapref   href="m2.ditamap"/>
    <topicref href="../c1.dita"/>
    <topicref href="../c2.dita"/>
</map>
END
  owf(fpe($in, qw(maps m2 ditamap)), <<END);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE map PUBLIC "-//OASIS//DTD DITA Map//EN" "map.dtd">
<map id="m2">
    <title>A map that is nested</title>
    <topicref href="../c1.dita"/>
    <topicref href="../c2.dita"/>
</map>
END
  owf(fpe($in, qw(c1 dita)), <<END);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd">
<concept id="c1">
    <title>Concept 1</title>
    <prolog>
        <metadata>
            <othermeta content="concept" name="topic_type ee ee aa"/>
            <othermeta content="Developer_Guide_Reference Salesforce_Console" name="app_area"/>
        </metadata>
    </prolog>
    <conbody/>
</concept>
END
  owf(fpe($in, qw(c2 dita)), <<END);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd">
<concept id="c2">
    <title>Concept 2</title>
    <prolog>
        <metadata>
            <othermeta content="Developer Partner" name="role"/>
            <othermeta content="PE EE PXE UE DE" name="edition"/>
            <othermeta content="aloha sfx aloha" name="ui_platform"/>
        </metadata>
    </prolog>
    <conbody/>
</concept>
END
 }

sub createWordsToFilesTest($)                                                   #P Index words to file
 {my ($in) = @_;                                                                # Folder to create the files in
  owf(fpe($in, qw(spaghetti dita)), <<END);
<task id="t1">
  <title>How to cook spaghetti</title>
  <taskbody>

    <context><p>You are in a well equipped kitchen with a packet of spaghetti
    to hand.  You wish to cook some spaghetti</p></context>

    <steps>
      <step>
        <cmd>Bring a large pan of water to a rolling boil</cmd>
      </step>
      <step>
        <cmd>Place the spaghetti in the boiling water</cmd>
      </step>
      <step>
        <cmd>Cover the pan with a lid and turn the heat down</cmd>
      </step>
      <step>
        <cmd>Cook for 15 minutes then drain through a collander</cmd>
      </step>
      </steps>
  </taskbody>
</task>
END
  owf(fpe($in, qw(tea dita)), <<END);
<task id="t2">
  <title>How to make a cup of tea</title>
  <taskbody>

    <context><p>You are in a well equipped kitchen with a packet of tea bags to hand.
    You wish to make a cup of tea</p></context>

    <steps>
      <step>
        <cmd>Bring a kettle of water to the boil</cmd>
      </step>
      <step>
        <cmd>Place a tea bag in an insulated glass</cmd>
      </step>
      <step>
        <cmd>Pour hot water over the tea bag until the glass is 80% full</cmd>
      </step>
      <step>
        <cmd>Place the glass in a microwave oven and power for 30 seconds.</cmd>
      </step>
      </steps>
  </taskbody>
</task>
END
 }

sub createUrlTests($)                                                           #P Check urls
 {my ($in) = @_;                                                                # Folder to create the files in
  owf(fpe($in, qw(concept dita)), <<END);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd">
<concept id="c">
  <title>Urls</title>
  <conbody>
    <p><xref format="html" href="https://www.appaapps.com" scope="external">aaa</xref></p>
    <p><xref format="html" href="https://ww2.appaapps.com" scope="external">bbb</xref></p>
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

sub createSampleOtherMeta($)                                                    #P Create sample data for othermeta reports
 {my ($out) = @_;                                                               # Folder

  package CreateSampleOtherMeta;
  use Carp;
  use Data::Dump qw(dump);
  use Data::Edit::Xml;
  use Data::Table::Text qw(:all);

  sub genMeta(%)                                                                # Generate meta data
   {my %m = @_;
    my @m;
    for my $n(sort keys %m)
     {my $c = $m{$n};
      push @m, qq(<othermeta name="$n" content="$c"/>);
     }
    join "\n", @m;
   }

  sub genTopic($$$)                                                             # Generate a topic
   {my ($out, $name, $meta) = @_;

    my $c      = Data::Edit::Xml::ditaSampleConcept
     (title    => $name,
      metadata => $meta,
     );

    owf(fpe($out, $name, qw(dita)), $c->ditaPrettyPrintWithHeaders);
   }

  sub genMap($$$@)                                                              # Generate a bookmap
   {my ($out, $name, $meta, @chapters) = @_;

    my @r;
    for my $f(@chapters)
     {my $F = swapFilePrefix($f, $out);
      push @r, qq(<chapter href="$F"/>);
     }

    my $r = join "\n", @r;

    my $b = Data::Edit::Xml::ditaSampleBookMap
     (chapters  => $r,
      metadata  => $meta,
      title     => $name,
     );

    owf(fpe($out, $name, qw(ditamap)), $b->ditaPrettyPrintWithHeaders);
   }

  clearFolder($out, 1e2);

  my %common = (aa=>q(AAAA), bb=>q(BBBB));

  my @topics =                                                                  # Topics
   (genTopic($out, q(ca), genMeta(%common, dd=>q(DD))),
    genTopic($out, q(cb), genMeta(%common, dd=>q(DD))),
   );

  genMap($out, q(b1), genMeta(%common, dd=>q(DD1111)), @topics);                # Bookmaps
  genMap($out, q(b2), genMeta(%common, dd=>q(DD2222)), @topics);
 } # createSampleOtherMeta

sub createTestOneNotRef($)                                                      #P One topic refernced and the other not
 {my ($folder) = @_;                                                            # Folder to switch to

  my $f = {
  "/home/phil/perl/cpan/DataEditXmlToDita/test/in/a.dita"    => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Task//EN\" \"concept.dtd\" []>\n<concept id=\"ca\">\n  <title>aaaa</title>\n  <conbody/>\n</concept>\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/in/a.ditamap" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE bookmap PUBLIC \"-//OASIS//DTD DITA BookMap//EN\" \"bookmap.dtd\" []>\n<bookmap id=\"bm\">\n  <chapter href=\"a.dita\" navtitle=\"aaaa\"/>\n</bookmap>\n",
  "/home/phil/perl/cpan/DataEditXmlToDita/test/in/b.dita"    => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE concept PUBLIC \"-//OASIS//DTD DITA Task//EN\" \"concept.dtd\" []>\n<concept id=\"cb\">\n  <title>bbbb</title>\n  <conbody/>\n</concept>\n",
  };

  changeFolderAndWriteFiles($f, $folder);                                       # Change folder and write files
 }

sub createSampleTopicsReferencedFromBookMaps($)                                 #P The number of times a topic is referenced from a bookmap
 {my ($in) = @_;                                                                # Folder to create the files in
  my $d = fpd(currentDirectory, $in);

  owf(fpe($in, qw(m1 dita)), <<END);
<map id="m1">
  <title>Map 1</title>
  <chapter href="c1.dita"/>
</map>
END

  owf(fpe($in, qw(m2 dita)), <<END);
<map id="m2">
  <title>Map 1</title>
  <topicref href="c1.dita"/>
  <topicref href="c2.dita"/>
</map>
END

  owf(fpe($in, qw(c1 dita)), <<END);
<concept id="c1">
  <title>c1</title>
  <conbody>
    <image href="1.png"/>;
  </conbody>
</concept>
END
  owf(fpe($in, qw(c2 dita)), <<END);
<concept id="c2">
  <title>c2</title>
  <conbody>
    <image href="1.png"/>;
    <image href="2.png"/>;
  </conbody>
</concept>
END
  owf(fpe($in, qw(c3 dita)), <<END);
<concept id="c3">
  <title>c3</title>
  <conbody>
    <image href="1.png"/>;
    <image href="2.png"/>;
    <image href="3.png"/>;
  </conbody>
</concept>
END
 }

sub createSampleImageReferences($)                                              #P Good and bad image references
 {my ($in) = @_;                                                                # Folder to create the files in
  my $d    = fpd(currentDirectory, $in);

  owf(fpe($in, qq(c$_), q(dita)), <<END) for 1..3;
<concept id="c$_">
  <title>C$_</title>
  <conbody>
    <image href="good1.png"/>
    <image href="good1.png"/>
    <image href="good2.png"/>
    <image href="good2.png"/>
    <image href="bad1.png"/>
    <image href="bad1.png"/>
  </conbody>
</concept>
END

  owf(fpe($in, qw(good1 png)), <<END);
<image/>
END

  owf(fpe($in, qw(good2 png)), <<END);
<image/>
END
 }

sub createRequiredCleanUps($)                                                   #P Required clean ups report
 {my ($in) = @_;                                                                # Folder to create the files in
  my $d    = fpd(currentDirectory, $in);

  owf(fpe($in, qq(c1), q(dita)), <<END);
<concept id="c1">
  <title>C1_</title>
  <conbody>
    <required-cleanup>aaa</required-cleanup>
    <required-cleanup>bbb</required-cleanup>
    <required-cleanup>bbb</required-cleanup>
  </conbody>
</concept>
END

  owf(fpe($in, qq(c2), q(dita)), <<END);
<concept id="c2">
  <title>C2_</title>
  <conbody>
    <required-cleanup>aaa</required-cleanup>
    <required-cleanup>bbb</required-cleanup>
    <required-cleanup>ccc</required-cleanup>
    <required-cleanup>CCC</required-cleanup>
  </conbody>
</concept>
END
 }

sub createSoftConrefs($)                                                        #P Fix file part of conref even if the rest is invalid
 {my ($in) = @_;                                                                # Folder to create the files in
  my $d    = fpd(currentDirectory, $in);

  my $r = fpe(qw(c_12345678123456781234567812345678 dita));                     # Relocatable
  owf(fpf($in, q(folder), $r), <<END);
$conceptHeader
<concept id="c">
  <title>C1</title>
  <conbody>
    <p id="p1">aaa</p>
    <p id="p1">bbb</p>
    <p conref="#c/p1"/>    <!-- FAILS -->
    <p conref="#c/pp"/>    <!-- FAILS: No such id -->
  </conbody>
</concept>
END

  owf(fpe($in, qw(c dita)), <<END);
$conceptHeader
<concept id="c">
  <title>C2</title>
  <conbody>
    <p conref="$r#c/p1"/>
    <p conref="$r#c1/p1"/>   <!-- PASSES: wrong topic id but we ignore topic ids-->
    <p conref="$r#c/bad"/>   <!-- PASSES: no such id - SHOULD FAIL even though we are relocating -->
    <p conref="$r"/>
    <p conref="c.dta"/>      <!-- FAILS: no such file -->
    <p id="q1">aaa</p>
    <p conref="#c/q1"/>
  </conbody>
</concept>
END
 }

sub checkXrefStructure($$@)                                                     #P Check an output structure produced by Xrf
 {my ($x, $field, @folders) = @_;                                               # Cross references, field to check, folders to suppress
  my $s = nws dump($x->{$field});                                               # Structure to be tested
  for my $folder($x->inputFolder, @folders)                                     # Remove specified folder names from structure to be tested
   {$s =~ s($folder) ()gs;                                                      # Remove folder name from structure to be tested
   }
  eval $s;                                                                      # Recreate structure
 }

sub writeXrefStructure($$@)                                                     #P Write the test for an Xref structure
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

sub deleteVariableFields($)                                                     #P Remove time and other fields that do not affect the end results
 {my ($x) = @_;                                                                 # Cross referencer
  delete $x->{$_} for qw(timeEnded timeStart maximumNumberOfProcesses);         # Remove time fields
  delete $x->{$_} for qw(tagsTextsRatio);                                       # Remove floating fields
  removeFilePathsFromStructure($x);
 }

sub testReferenceChecking                                                       #P Test reference checking
 {my $folder = q(/home/phil/);
  my @names  = qw(aaa bbb ccc);
  my @ids    = map {q(p).$_}                   @names;
  my @files  = map {fpe($folder, $_, q(dita))} @names;

  my $xref = newXref
   (currentFolder  => q(/aaa),
    reports        => fpd(currentDirectory, qw(test resports)),
    topicIds       => {map {$files[$_]=>$names[$_]}      0..$#names},
    ids            => {map {$files[$_]=>{$ids[$_]=>1}}   0..$#names},
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
  ok !oneBadRef($xref, q(/home/phil/aaa.dita), q(#paaa));

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
  is_deeply oneBadRef($xref, q(/home/phil/aaa.dita), q(#bbb/ccc)),
   ["Topic id does not match",
    "#bbb/ccc",
    "/home/phil/aaa.dita",
    "bbb",
    "ccc",
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
lll "Test 001";
  clearFolder($_, 420) for in, out, reportFolder;
  createSampleInputFilesBaseCase(in, 8);

  my $x = xref(inputFolder => in,
               reports     => reportFolder,
               html        => reportFolder);
  ok $x->statusLine eq q(Xref: 104 refs, 21 image refs, 14 first lines, 14 second lines, 8 duplicate ids, 4 duplicate topic ids, 4 invalid guid hrefs, 2 duplicate files, 2 tables, 1 External xrefs with no format=html, 1 External xrefs with no scope=external, 1 file failed to parse, 1 href missing);

  #lll $x->statusLine;
  #say STDERR writeXrefStructure($x, q(publicId), q(in));
  is_deeply checkXrefStructure($x, q(publicId), in),
   {"1.dita" => undef, "2.dita" => undef, "3.dita" => undef, "4.dita" => undef,
    "5.dita" => undef, "6.dita" => undef, "7.dita" => undef, "8.dita" => undef,
    "act1.dita" => undef, "act4.dita" => undef, "act5.dita" => undef,
    "map/bookmap3.ditamap" => undef,
    "map/bookmap.ditamap"  => undef, "map/bookmap2.ditamap" => undef,
    "act2.dita"  => "-//OASIS//DTD DITA Task//EN",
    "table.dita" => "-//OASIS//DTD DITA Task//EN", };

  ok readFile(fpe(reportFolder, qw(bad duplicate_topics_ids html))) =~ m(<tr><td>c2<td>)is;
  ok readFile(fpe(reportFolder, qw(bad duplicate_topics_ids txt)))  =~ m(1  c2)is;

  my $y = xref(inputFolder => in, reports=>reportFolder, fixBadRefs => 1, fixXrefsByTitle => 1);       # Update error counts
  ok $y->statusLine eq q(Xref: 103 refs, 21 image refs, 14 first lines, 14 second lines, 8 duplicate ids, 4 duplicate topic ids, 4 invalid guid hrefs, 2 duplicate files, 2 tables, 1 External xrefs with no format=html, 1 External xrefs with no scope=external, 1 file failed to parse, 1 href missing);

  is_deeply checkXrefStructure($y, q(fixedRefsGood)),
   [['Fixed by Gearhart Title Method', "xref", "href",
     "act1.dita#c1/title", "act1.dita", "act2.dita"]];
 }

if (1) {                                                                        #
lll "Test 002";
  clearFolder($_, 420) for in, out, reportFolder;
  createSampleInputFilesBaseCase(in, 8);

  my $x = xref(inputFolder                        => in,
               requestAttributeNameAndValueCounts => 1,
               reports                            => reportFolder,
               addNavTitles                       => 1,
               deguidize                          => 1,
               deleteUnusedIds                    => 1);


  ok $x->statusLine eq q(Xref: 88 refs, 18 image refs, 14 first lines, 14 second lines, 8 duplicate ids, 4 duplicate topic ids, 4 invalid guid hrefs, 2 duplicate files, 2 tables, 1 External xrefs with no format=html, 1 External xrefs with no scope=external, 1 file failed to parse, 1 href missing);

  is_deeply checkXrefStructure($x, q(topicsReferencedFromBookMaps)),
    {
      #"act2.dita"            => { "act1.dita" => 1, "act9999.dita" => 1 },
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
   {#"act2.dita" => {
    #   "act1.png"  => 1,
    #   "act2.png"  => 1,
    #   "guid-000"  => 1,
    #   "guid-9999" => 1,
    #   "guid-act1" => 1,                                 inputFolder
    # },
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

if (1) {                                                                          # Check topic matching
lll "Test 003";
  clearFolder($_, 420) for in, out, reportFolder;
  createSampleInputFilesBaseCase(in, 8);

  my $x = xref(inputFolder   => in,
               reports       => reportFolder,
               deguidize     => 1,
               fixBadRefs    => 1,
               matchTopics   => 0.9,
               flattenFolder => out,
               html          => reportFolder);

  ok $x->statusLine eq q(Xref: 97 refs, 20 image refs, 14 first lines, 14 second lines, 8 duplicate ids, 4 duplicate topic ids, 4 invalid guid hrefs, 2 duplicate files, 2 tables, 1 External xrefs with no format=html, 1 External xrefs with no scope=external, 1 file failed to parse, 1 href missing);
  ok readFile(fpe($x->reportFolder, qw(similar byVocabulary txt))) =~ m(1\s+8.*in/1\.dita);
 }

if (1) {                                                                        # Relocated refs
lll "Test 004";
  clearFolder($_, 420) for qw(in out reports);
  createSampleInputFilesBaseCase(in, 8);

  my $x = xref(inputFolder              => in,
               reports                  => reportFolder,
               deguidize                => 1,
               fixBadRefs               => 1,
               fixRelocatedRefs         => 1,
               fixedFolder              => outFixed,
               flattenFolder            => out);

  ok $x->statusLine eq q(Xref: 97 refs, 20 image refs, 14 first lines, 14 second lines, 8 duplicate ids, 4 duplicate topic ids, 4 invalid guid hrefs, 2 duplicate files, 2 tables, 1 External xrefs with no format=html, 1 External xrefs with no scope=external, 1 file failed to parse, 1 href missing);

  my $table = $x->statusTable;

  ok index($table, <<END) == 0;
    Count  Condition
 1     97  refs
 2     20  image refs
 3     14  first lines
 4     14  second lines
 5      8  duplicate ids
 6      4  invalid guid hrefs
 7      4  duplicate topic ids
 8      2  tables
 9      2  duplicate files
10      1  file failed to parse
11      1  href missing
12      1  External xrefs with no format=html
13      1  External xrefs with no scope=external
END

  is_deeply checkXrefStructure($x, q(fixedRefsGood), in, targets),
   [[ "Deguidized reference", "image",    "href",   "guid-000",                                          "act1.dita",            "act1.dita", ],
    [ "Deguidized reference", "link",     "href",   "guid-000",                                          "act1.dita",            "act2.dita", ],
    [ "Deguidized reference", "topicref", "href",   "guid-000",                                          "act1.dita",            "map/bookmap.ditamap", ],
    [ "Deguidized reference", "topicref", "href",   "guid-000",                                          "act1.dita",            "map/bookmap2.ditamap", ],
    [ "Deguidized reference", "xref",     "href",   "guid-000#c1/title2",                                "act1.dita",            "act2.dita", ],
    [ "Deguidized reference", "xref",     "href",   "guid-000#guid-000/title",                           "act1.dita",            "act2.dita", ],
    [ "Deguidized reference", "xref",     "href",   "guid-000#guid-000/title2",                          "act1.dita",            "act2.dita", ],
    [ "Deguidized reference", "xref",     "href",   "guid-001#guid-001/title guid-000#guid-000/title",   "act1.dita",            "act2.dita", ],
  #  [ "Relocated",            "p",        "conref", "bookmap.ditamap",                                   "map/bookmap.ditamap",  "act2.dita", ],
  #  [ "Relocated",            "p",        "conref", "bookmap2.ditamap",                                  "map/bookmap2.ditamap", "act2.dita", ],
  ];


# &writeXrefStructure($x, qw(fixedRefs in targets));
 }

if (!onAws) {                                                                   # Pending in AWS because we have not fixed deguidize to run in parallel
lll "Test 005 - Add Navtitles";
  my $N = 8;

  clearFolder($_, 420) for in, out, reportFolder;
  createSampleInputFilesBaseCase(in, $N);

  my $x = xref(inputFolder                        => in,
               requestAttributeNameAndValueCounts => 1,
               reports                            => reportFolder,
               addNavTitles                       => 1,
               deguidize                          => 1,
               deleteUnusedIds                    => 1);

  #&writeXrefStructure($x, qw(badNavTitles in));

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

  #&writeXrefStructure($x, qw(goodNavTitles in targets)); exit;

  my $y = xref(inputFolder                        => in,
               requestAttributeNameAndValueCounts => 1,
               reports                            => reportFolder,
               addNavTitles                       => 1,
               deguidize                          => 1,
               fixBadRefs                         => 1);

  is_deeply checkXrefStructure($y, q(goodNavTitles), in, targets),
   [[ "../act1.dita", "All Timing Codes Begin Here", "act1.dita", "map/bookmap.ditamap",  ],
    [ "../act1.dita", "All Timing Codes Begin Here", "act1.dita", "map/bookmap.ditamap",  ],
    [ "../act1.dita", "All Timing Codes Begin Here", "act1.dita", "map/bookmap2.ditamap", ],
    [ "../act1.dita", "All Timing Codes Begin Here", "act1.dita", "map/bookmap2.ditamap", ],
    [ "../act2.dita", "Jumping Through Hops",        "act2.dita", "map/bookmap.ditamap",  ],
    [ "../act2.dita", "Jumping Through Hops",        "act2.dita", "map/bookmap2.ditamap", ], ];

  my $r = fpe($x->reports, qw(count attributeNamesAndValues txt));
  ok -e $r && index(readFile($r), <<END) > 0;
Summary_of_column_Attribute
   Count  Attribute
1     98  href
2     29  id
3     20  conref
4      8  xtrf
5      2  navtitle
6      1  cols
7      1  format
END
 }
else
 {ok 1 for 1..3
 }

if (0) {                                                                        # Max zoom in - fails after upgrade to html reports
lll "Test 006";
  my $N = 8;

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

if (1) {                                                                        # fixedFolder
lll "Test 007";
  clearFolder($_, 1e3) for in, out, outFixed, reportFolder;
  createSampleInputFilesFixFolder(in);

  my $x = xref(inputFolder => in,
               reports     => reportFolder,
               fixBadRefs  => 1,
               fixedFolder => outFixed);

  ok $x->statusLine eq q(Xref: 2 refs, 2 second lines);
  my @files = searchDirectoryTreesForMatchingFiles(outFixed, q(dita));

  ok @files == 2;

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

#  &writeXrefStructure($x, qw(fixedRefsBad));

  is_deeply checkXrefStructure($x, q(fixedRefsBad)),
   [["No such target", "p",    "conref", "3.dita#c2/p1", "1.dita"],
    ["No such target", "xref", "href",   "3.dita#c2/p1", "1.dita"]];
 }

if (0) {                                                                        # ltgt
lll "Test 008";
  clearFolder($_, 1e3) for in, reports;
  createSampleInputFilesLtGt(in);

  my $x = xref(inputFolder => in, reports => reportFolder);
  my $r = readFile(fpe($x->reports, qw(count ltgt txt)));
  ok $r =~ m(1\s*1\s*aaa);
  ok $r =~ m(2\s*1\s*bbb);
 }

if (1) {                                                                        # fixDitaRefs using target files to locate flattened files
lll "Test 009";
  clearFolder(tests, 111);
  createSampleInputFilesForFixDitaRefsImproved1(tests);

  my $x = xref                                                                  # Fix with statistics showing the scale of the problem
   (inputFolder  => out,
    reports      => reportFolder,
    fixBadRefs   => 1,
    fixDitaRefs  => targets,
    fixedFolder  => outFixed,
    );

  ok !$x->errors;

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

  my  $y = xref(inputFolder => outFixed, reports => reportFolder);              # Check results
  ok !$y->errors;
 }

if (1) {                                                                        # fixDitaRefs using target files to resolve conrefs to renamed files
lll "Test 010";
  clearFolder(tests, 111);
  createSampleInputFilesForFixDitaRefsImproved2(tests);

  my $y = xref(inputFolder => out, reports => reportFolder);                    # Check results without fixes
  ok $y->statusLine eq q(Xref: 1 ref);

  my $x = xref
   (inputFolder => out,
    reports     => reportFolder,
    fixBadRefs  => 1,
    fixDitaRefs => targets,
    fixedFolder => outFixed);

  ok !$x->errors;

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

if (1) {                                                                        #Txref fixDitaRefs in bookmaps to topics that were cut into multiple pieces
lll "Test 011";
  clearFolder(tests, 111);
  createSampleInputFilesForFixDitaRefsImproved3(tests);

  my $y = xref(inputFolder => out, reports => reportFolder);                    # Check results without fixes
  ok $y->statusLine eq q(Xref: 1 ref);

  my $x = xref
   (inputFolder => out,
    reports     => reportFolder,
    fixBadRefs  => 1,
    fixDitaRefs => targets,
    fixedFolder => outFixed);

  ok !$x->errors;
 }

if (1) {                                                                        # fixDitaRefs in bookmaps to a topics that was not cut into multiple pieces
lll "Test 012";
  clearFolder(tests, 111);
  createSampleInputFilesForFixDitaRefsImproved4(tests);

  my $y = xref(inputFolder => out, reports => reportFolder);                    # Check results without fixes
  ok $y->statusLine eq q(Xref: 1 ref);

  my $x = xref
   (inputFolder => out,
    reports     => reportFolder,
    fixBadRefs  => 1,
    fixDitaRefs => targets,
    fixedFolder => outFixed);

  ok !$x->errors;

  ok int(1e2 * $y->tagsTextsRatio) == 233;
 }

if (1) {                                                                        # Images
lll "Test 013";
  clearFolder(tests, 111);
  createSampleImageTest(tests);

  my $x = xref
   (inputFolder => out,
    reports     => reportFolder,
    fixBadRefs  => 1,
    fixDitaRefs => targets,
    fixedFolder => outFixed);

  ok $x->statusLine eq q(Xref: 1 image ref, 1 ref);

  my ($file) = keys $x->missingImageFiles->%*;
  ok $file && $file =~ m(/images/b.png\Z);
 }

if (1) {                                                                        # Test topic flattening ratio reporting
lll "Test 014";
  clearFolder(tests, 111);
  createTestTopicFlattening(tests);

  my $x = xref
   (inputFolder => out,
    reports     => reportFolder,
    fixBadRefs  => 1,
    fixDitaRefs => targets,
    fixedFolder => outFixed);

  ok $x->topicsFlattened       == 3;
  ok $x->topicFlatteningFactor == 3;

  is_deeply checkXrefStructure($x, q(topicFlattening), in, targets),
   { "c_2b1faeb8f74e670e20450cde864e2e46.dita" =>
     [ "c1.dita", "c2.dita", "c3.dita", ],
   };
 }

#latestTest:;
if (1) {                                                                        # References to flattened files
lll "Test 016";
  clearFolder(tests, 111);
  createTestReferencedToFlattenedTopic(tests);

  my $x = xref(inputFolder => out, reports => reportFolder);
  ok $x->statusLine eq q(Xref: 1 ref);
  is_deeply checkXrefStructure($x, q(fixedRefsGood), in, targets), [];

  my $y = xref
   (inputFolder => out,
    reports     => reportFolder,
    fixBadRefs  => 1,
    fixDitaRefs => targets,
    fixedFolder => outFixed);

  ok $y->topicsFlattened == 2;
  ok $y->topicFlatteningFactor == 2;

  is_deeply checkXrefStructure($y, q(fixedRefsGood), in, targets),
   [["Unique target for file ref", "p", "conref", "b.dita#c/p1",
     "c_aaaa_8b028dc2faaca88ac747b3776189d4a6.dita",
     "c_aaaa_3119ee09e34375ed4d8a7a15274a9774.dita", "a.dita"]];

  ok !$y->errors;
  is_deeply checkXrefStructure($y, q(fixedRefsGood), in, targets),
    [["Unique target for file ref", "p", "conref", "b.dita#c/p1",
      "c_aaaa_8b028dc2faaca88ac747b3776189d4a6.dita",
      "c_aaaa_3119ee09e34375ed4d8a7a15274a9774.dita", "a.dita"]];

 }

#latestTest:;
if (1) {                                                                        # References from a topic that has been cut out to a topic that has been cut out
lll "Test 017";
  clearFolder(tests, 111);
  createTestReferenceToCutOutTopic(tests);

  my $x = xref
   (inputFolder => out,
    reports     => reportFolder,
    fixBadRefs  => 1,
    fixDitaRefs => targets,
    fixedFolder => outFixed);

  ok $x->statusLine eq q(Xref: 1 ref);

  is_deeply checkXrefStructure($x, q(inputFileToTargetTopics),          in, targets), { "a.xml" => { "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita" => 1, "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => 1, "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => 1, "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => 1, }, "b.xml" => { "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita" => 1, "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => 1, "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => 1, "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => 1, }, };
  is_deeply checkXrefStructure($x, q(targetTopicToInputFiles),          in, targets), { "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita" => { "a.xml" => 1, }, "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => { "a.xml" => 1, }, "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => { "a.xml" => 1, }, "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => { "a.xml" => 1, }, "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita" => { "b.xml" => 1, }, "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => { "b.xml" => 1, }, "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => { "b.xml" => 1, }, "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => { "b.xml" => 1, }, };
  is_deeply checkXrefStructure($x, q(sourceTopicToTargetBookMap),       in, targets), { "a.xml" => bless({ source => "a.xml", sourceDocType => "concept", target => "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap", targetType => "bookmap", }, "Bookmap"), "b.xml" => bless({ source => "b.xml", sourceDocType => "concept", target => "bm_b_d2806ba589f908da1106574afd9db642.ditamap", targetType => "bookmap", }, "Bookmap"), };
  is_deeply checkXrefStructure($x, q(topicFlattening),                  in, targets), {};
  is_deeply checkXrefStructure($x, q(originalSourceFileAndIdToNewFile), in, targets), { "a.xml" => { "GUID-400c2c59-95e1-7bf3-4647-3a135281bfaf" => "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita", "GUID-68822563-d568-f418-38ae-f1c62cb4ac8d" => "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita", "GUID-c67821ef-3da2-c89f-0fc9-9fba3937f368" => "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita", "GUID-f0c0e170-8128-10ef-045d-97602fdde76f" => "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita", }, "b.xml" => { "GUID-2b6aab4f-9328-e326-f55f-160771a8c3dd" => "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita", "GUID-86a684b0-1a0b-4c30-6da9-24c74ff1f0cc" => "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita", "GUID-96a20d7f-bbaf-deef-55ef-e09a0a059251" => "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita", "GUID-cfe7cb3d-05e7-a147-db10-dcbacaeecef7" => "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita", "p1" => "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita", "p2" => "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita", "p3" => "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita", }, };

  #dumpFile(q(/home/phil/z/xref.data), deleteVariableFields($x)); exit;
  is_deeply deleteVariableFields($x), do {
do {
  my $a = bless({
    addNavTitles                         => undef,
    allowUniquePartialMatches            => undef,
    attributeCount                       => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => { href => 4, id => 1, navtitle => 4, product => 1, version => 1 },
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => { href => 4, id => 1, navtitle => 4, product => 1, version => 1 },
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => { id => 1 },
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => { conref => 1, id => 1 },
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => { conref => 1, id => 1 },
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => { conref => 1, id => 1 },
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => { id => 2 },
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => { id => 1 },
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => { id => 2 },
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => { id => 2 },
                                            },
    attributeNamesAndValuesCount         => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => {
                                                                                                       href => {
                                                                                                         "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => 1,
                                                                                                         "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => 1,
                                                                                                         "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => 1,
                                                                                                         "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => 1,
                                                                                                       },
                                                                                                       id => { "GUID-80a6bceb-0817-2a54-4d9e-ea67eed112b3" => 1 },
                                                                                                       navtitle => { "aaaa" => 1, "aaaa bbbb" => 1, "aaaa cccc" => 1, "aaaa dddd" => 1 },
                                                                                                     },
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => {
                                                                                                       href => {
                                                                                                         "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => 1,
                                                                                                         "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => 1,
                                                                                                         "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => 1,
                                                                                                         "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => 1,
                                                                                                       },
                                                                                                       id => { "GUID-21696006-94ec-4e53-78c5-24a93641a474" => 1 },
                                                                                                       navtitle => { "bbbb" => 1, "bbbb aaaa" => 1, "bbbb bbbb" => 1, "bbbb cccc" => 1 },
                                                                                                     },
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => { id => { "GUID-c67821ef-3da2-c89f-0fc9-9fba3937f368" => 1 } },
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => {
                                                                                                       conref => { p1 => 1 },
                                                                                                       id => { "GUID-f0c0e170-8128-10ef-045d-97602fdde76f" => 1 },
                                                                                                     },
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => {
                                                                                                       conref => { p2 => 1 },
                                                                                                       id => { "GUID-400c2c59-95e1-7bf3-4647-3a135281bfaf" => 1 },
                                                                                                     },
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => {
                                                                                                       conref => { p3 => 1 },
                                                                                                       id => { "GUID-68822563-d568-f418-38ae-f1c62cb4ac8d" => 1 },
                                                                                                     },
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => {
                                                                                                       id => { "GUID-96a20d7f-bbaf-deef-55ef-e09a0a059251" => 1, "p1" => 1 },
                                                                                                     },
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => { id => { "GUID-86a684b0-1a0b-4c30-6da9-24c74ff1f0cc" => 1 } },
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => {
                                                                                                       id => { "GUID-cfe7cb3d-05e7-a147-db10-dcbacaeecef7" => 1, "p2" => 1 },
                                                                                                     },
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => {
                                                                                                       id => { "GUID-2b6aab4f-9328-e326-f55f-160771a8c3dd" => 1, "p3" => 1 },
                                                                                                     },
                                            },
    author                               => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap" => "",
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap" => "",
                                            },
    badGuidHrefs                         => {},
    badNavTitles                         => {},
    badReferencesCount                   => 3,
    badTables                            => [],
    badXml1                              => {},
    badXml2                              => {},
    baseFiles                            => {},
    baseTag                              => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => "bookmap",
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => "bookmap",
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => "concept",
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => "concept",
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => "concept",
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => "concept",
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => "concept",
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => "concept",
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => "concept",
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => "concept",
                                            },
    bookMapRefs                          => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap" => {
                                                                                                   "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => { aaaa => 1 },
                                                                                                   "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => { "aaaa bbbb" => 1 },
                                                                                                   "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => { "aaaa cccc" => 1 },
                                                                                                   "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => { "aaaa dddd" => 1 },
                                                                                                 },
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap" => {
                                                                                                   "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => { bbbb => 1 },
                                                                                                   "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => { "bbbb aaaa" => 1 },
                                                                                                   "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => { "bbbb bbbb" => 1 },
                                                                                                   "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => { "bbbb cccc" => 1 },
                                                                                                 },
                                            },
    changeBadXrefToPh                    => undef,
    classificationMaps                   => undef,
    conRefs                              => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => {},
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => {},
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => { p1 => { p => 1 } },
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => { p2 => { p => 1 } },
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => { p3 => { p => 1 } },
                                            },
    createReports1                       => [
                                              "reportXml1",
                                              "reportXml2",
                                              "reportDuplicateIds",
                                              "reportDuplicateTopicIds",
                                              "reportNoHrefs",
                                              "reportTables",
                                              "reportParseFailed",
                                              "reportAttributeCount",
                                              "reportLtGt",
                                              "reportTagCount",
                                              "reportTagsAndTextsCount",
                                              "reportDocTypeCount",
                                              "reportFileExtensionCount",
                                              "reportFileTypes",
                                              "reportValidationErrors",
                                              "reportGuidHrefs",
                                              "reportExternalXrefs",
                                              "reportTopicDetails",
                                              "reportTopicReuse",
                                              "reportMd5Sum",
                                              "reportOlBody",
                                              "reportHrefUrlEncoding",
                                              "reportFixRefs",
                                              "reportSourceFiles",
                                              "reportOtherMeta",
                                              "createSubjectSchemeMap",
                                              "reportTopicsNotReferencedFromBookMaps",
                                              "reportTableDimensions",
                                              "reportExteriorMaps",
                                              "createClassificationMaps",
                                              "reportIdRefs",
                                              "reportEmptyTopics",
                                              "reportConRefMatching",
                                              "reportPublicIds",
                                              "reportRequiredCleanUps",
                                            ],
    createReports2                       => ["removeUnusedIds", "reportImages"],
    currentFolder                        => "",
    deguidize                            => undef,
    deleteUnusedIds                      => 0,
    docType                              => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => "bookmap",
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => "bookmap",
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => "concept",
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => "concept",
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => "concept",
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => "concept",
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => "concept",
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => "concept",
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => "concept",
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => "concept",
                                            },
    duplicateIds                         => {},
    duplicateTopicIds                    => {},
    emptyTopics                          => {
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => 1,
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => 1,
                                            },
    errors                               => 1,
    exteriorMaps                         => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap" => 1,
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap" => 1,
                                            },
    fileExtensions                       => [".dita", ".ditamap", ".xml", ".fodt"],
    fixBadRefs                           => 1,
    fixDitaRefs                          => "targets",
    fixedFolder                          => "",
    fixedFolderTemp                      => "",
    fixedRefsBad                         => [
                                              [
                                                "No such target",
                                                "p",
                                                "conref",
                                                "p2",
                                                "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita",
                                                "a.xml",
                                              ],
                                            ],
    fixedRefsGB                          => [],
    fixedRefsGood                        => [
                                              [
                                                "Unique target for file ref",
                                                "p",
                                                "conref",
                                                "p1",
                                                "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita",
                                                "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita",
                                                "a.xml",
                                              ],
                                              [
                                                "Unique target for file ref",
                                                "p",
                                                "conref",
                                                "p3",
                                                "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita",
                                                "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita",
                                                "a.xml",
                                              ],
                                            ],
    fixedRefsNoAction                    => [],
    fixRefs                              => {
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => { p1 => 1 },
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => { p2 => 1 },
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => { p3 => 1 },
                                            },
    fixRelocatedRefs                     => undef,
    fixXrefsByTitle                      => undef,
    flattenFiles                         => {},
    flattenFolder                        => undef,
    getFileUrl                           => "client.pl?getFile=",
    goodImageFiles                       => {},
    goodNavTitles                        => {},
    guidHrefs                            => {},
    guidToFile                           => {},
    hrefUrlEncoding                      => {},
    html                                 => undef,
    idNotReferenced                      => {
                                              "b.xml" => {},
                                              "bb.xml" => {},
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap" => { "GUID-80a6bceb-0817-2a54-4d9e-ea67eed112b3" => 1 },
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap" => { "GUID-21696006-94ec-4e53-78c5-24a93641a474" => 1 },
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita" => { "GUID-c67821ef-3da2-c89f-0fc9-9fba3937f368" => 1 },
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => { "GUID-f0c0e170-8128-10ef-045d-97602fdde76f" => 1 },
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => { "GUID-400c2c59-95e1-7bf3-4647-3a135281bfaf" => 1 },
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => { "GUID-68822563-d568-f418-38ae-f1c62cb4ac8d" => 1 },
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita" => { "GUID-96a20d7f-bbaf-deef-55ef-e09a0a059251" => 1, "p1" => 1 },
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => { "GUID-86a684b0-1a0b-4c30-6da9-24c74ff1f0cc" => 1 },
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => { "GUID-cfe7cb3d-05e7-a147-db10-dcbacaeecef7" => 1, "p2" => 1 },
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => { "GUID-2b6aab4f-9328-e326-f55f-160771a8c3dd" => 1, "p3" => 1 },
                                            },
    idReferencedCount                    => { "b.xml" => { p1 => 1, p3 => 1 }, "bb.xml" => { p2 => 1 } },
    ids                                  => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => { "GUID-80a6bceb-0817-2a54-4d9e-ea67eed112b3" => 1 },
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => { "GUID-21696006-94ec-4e53-78c5-24a93641a474" => 1 },
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => { "GUID-c67821ef-3da2-c89f-0fc9-9fba3937f368" => 1 },
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => { "GUID-f0c0e170-8128-10ef-045d-97602fdde76f" => 1 },
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => { "GUID-400c2c59-95e1-7bf3-4647-3a135281bfaf" => 1 },
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => { "GUID-68822563-d568-f418-38ae-f1c62cb4ac8d" => 1 },
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => { "GUID-96a20d7f-bbaf-deef-55ef-e09a0a059251" => 1, "p1" => 1 },
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => { "GUID-86a684b0-1a0b-4c30-6da9-24c74ff1f0cc" => 1 },
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => { "GUID-cfe7cb3d-05e7-a147-db10-dcbacaeecef7" => 1, "p2" => 1 },
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => { "GUID-2b6aab4f-9328-e326-f55f-160771a8c3dd" => 1, "p3" => 1 },
                                            },
    idsRemoved                           => {
                                              "GUID-21696006-94ec-4e53-78c5-24a93641a474" => 1,
                                              "GUID-2b6aab4f-9328-e326-f55f-160771a8c3dd" => 1,
                                              "GUID-400c2c59-95e1-7bf3-4647-3a135281bfaf" => 1,
                                              "GUID-68822563-d568-f418-38ae-f1c62cb4ac8d" => 1,
                                              "GUID-80a6bceb-0817-2a54-4d9e-ea67eed112b3" => 1,
                                              "GUID-86a684b0-1a0b-4c30-6da9-24c74ff1f0cc" => 1,
                                              "GUID-96a20d7f-bbaf-deef-55ef-e09a0a059251" => 1,
                                              "GUID-c67821ef-3da2-c89f-0fc9-9fba3937f368" => 1,
                                              "GUID-cfe7cb3d-05e7-a147-db10-dcbacaeecef7" => 1,
                                              "GUID-f0c0e170-8128-10ef-045d-97602fdde76f" => 1,
                                            },
    idTags                               => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => { "GUID-80a6bceb-0817-2a54-4d9e-ea67eed112b3" => ["bookmap"] },
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => { "GUID-21696006-94ec-4e53-78c5-24a93641a474" => ["bookmap"] },
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => { "GUID-c67821ef-3da2-c89f-0fc9-9fba3937f368" => ["concept"] },
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => { "GUID-f0c0e170-8128-10ef-045d-97602fdde76f" => ["concept"] },
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => { "GUID-400c2c59-95e1-7bf3-4647-3a135281bfaf" => ["concept"] },
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => { "GUID-68822563-d568-f418-38ae-f1c62cb4ac8d" => ["concept"] },
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => {
                                                                                                       "GUID-96a20d7f-bbaf-deef-55ef-e09a0a059251" => ["concept"],
                                                                                                       "p1" => ["p"],
                                                                                                     },
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => { "GUID-86a684b0-1a0b-4c30-6da9-24c74ff1f0cc" => ["concept"] },
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => {
                                                                                                       "GUID-cfe7cb3d-05e7-a147-db10-dcbacaeecef7" => ["concept"],
                                                                                                       "p2" => ["p"],
                                                                                                     },
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => {
                                                                                                       "GUID-2b6aab4f-9328-e326-f55f-160771a8c3dd" => ["concept"],
                                                                                                       "p3" => ["p"],
                                                                                                     },
                                            },
    images                               => {},
    imagesReferencedFromBookMaps         => {},
    imagesReferencedFromTopics           => {
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => {},
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => {},
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => {},
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => {},
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => {},
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => {},
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => {},
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => {},
                                            },
    imagesToRefferingBookMaps            => {},
    indexedWords                         => {},
    indexWords                           => undef,
    indexWordsFolder                     => undef,
    inputFiles                           => [
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap",
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap",
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita",
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita",
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita",
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita",
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita",
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita",
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita",
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita",
                                            ],
    inputFileToTargetTopics              => {
                                              "a.xml" => {
                                                           "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => 1,
                                                           "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => 1,
                                                           "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => 1,
                                                           "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => 1,
                                                         },
                                              "b.xml" => {
                                                           "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => 1,
                                                           "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => 1,
                                                           "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => 1,
                                                           "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => 1,
                                                         },
                                            },
    inputFolder                          => "",
    inputFolderImages                    => {
                                              bm_a_9d0a9f8e0ac234de9e22c19054b6e455        => "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap",
                                              bm_b_d2806ba589f908da1106574afd9db642        => "bm_b_d2806ba589f908da1106574afd9db642.ditamap",
                                              c_aaaa_121939eab89cd7d2c3eb4c4189772a1f      => "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita",
                                              c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b => "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita",
                                              c_aaaa_cccc_a91633094220d068c453eecae1726eff => "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita",
                                              c_aaaa_dddd_914b8e11993908497768c50d992ea0f0 => "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita",
                                              c_bbbb_6100b51ca1f789836cd4f31893ed67d2      => "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita",
                                              c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d => "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita",
                                              c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b => "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita",
                                              c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3 => "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita",
                                            },
    ltgt                                 => {},
    matchTopics                          => undef,
    maxZoomIn                            => undef,
    maxZoomOut                           => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => {},
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => {},
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => {},
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => {},
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => {},
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => {},
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => {},
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => {},
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => {},
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => {},
                                            },
    md5Sum                               => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => "80a6bceb08172a544d9eea67eed112b3",
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => "2169600694ec4e5378c524a93641a474",
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => "c67821ef3da2c89f0fc99fba3937f368",
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => "f0c0e170812810ef045d97602fdde76f",
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => "400c2c5995e17bf346473a135281bfaf",
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => "68822563d568f41838aef1c62cb4ac8d",
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => "96a20d7fbbafdeef55efe09a0a059251",
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => "86a684b01a0b4c306da924c74ff1f0cc",
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => "cfe7cb3d05e7a147db10dcbacaeecef7",
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => "2b6aab4f9328e326f55f160771a8c3dd",
                                            },
    md5SumDuplicates                     => {},
    missingImageFiles                    => {},
    missingTopicIds                      => {},
    noHref                               => {},
    notReferenced                        => {},
    olBody                               => {},
    originalSourceFileAndIdToNewFile     => {
                                              "a.xml" => {
                                                           "GUID-400c2c59-95e1-7bf3-4647-3a135281bfaf" => "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita",
                                                           "GUID-68822563-d568-f418-38ae-f1c62cb4ac8d" => "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita",
                                                           "GUID-c67821ef-3da2-c89f-0fc9-9fba3937f368" => "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita",
                                                           "GUID-f0c0e170-8128-10ef-045d-97602fdde76f" => "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita",
                                                         },
                                              "b.xml" => {
                                                           "GUID-2b6aab4f-9328-e326-f55f-160771a8c3dd" => "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita",
                                                           "GUID-86a684b0-1a0b-4c30-6da9-24c74ff1f0cc" => "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita",
                                                           "GUID-96a20d7f-bbaf-deef-55ef-e09a0a059251" => "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita",
                                                           "GUID-cfe7cb3d-05e7-a147-db10-dcbacaeecef7" => "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita",
                                                           "p1" => "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita",
                                                           "p2" => "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita",
                                                           "p3" => "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita",
                                                         },
                                            },
    otherMeta                            => {},
    otherMetaBookMapsAfterTopicIncludes  => [],
    otherMetaBookMapsBeforeTopicIncludes => [],
    otherMetaConsolidated                => {},
    otherMetaDuplicatesCombined          => [],
    otherMetaDuplicatesSeparately        => [],
    otherMetaPushToBookMap               => [],
    otherMetaRemainWithTopic             => [],
    oxygenProjects                       => undef,
    parseFailed                          => {},
    publicId                             => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => "EN",
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => "EN",
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => "EN",
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => "EN",
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => "EN",
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => "EN",
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => "EN",
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => "EN",
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => "EN",
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => "EN",
                                            },
    references                           => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => {
                                                                                                       "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => 1,
                                                                                                       "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => 1,
                                                                                                       "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => 1,
                                                                                                       "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => 1,
                                                                                                     },
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => {
                                                                                                       "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => 1,
                                                                                                       "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => 1,
                                                                                                       "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => 1,
                                                                                                       "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => 1,
                                                                                                     },
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => { p1 => 1 },
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => { p2 => 1 },
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => { p3 => 1 },
                                            },
    relocatedReferencesFailed            => [],
    relocatedReferencesFixed             => [],
    reports                              => '',
    requestAttributeNameAndValueCounts   => undef,
    requiredCleanUp                      => {},
    results                              => [[1, "ref"]],
    sourceTopicToTargetBookMap           => {
                                              "a.xml" => bless({
                                                           source => "a.xml",
                                                           sourceDocType => "concept",
                                                           target => "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap",
                                                           targetType => "bookmap",
                                                         }, "Bookmap"),
                                              "b.xml" => bless({
                                                           source => "b.xml",
                                                           sourceDocType => "concept",
                                                           target => "bm_b_d2806ba589f908da1106574afd9db642.ditamap",
                                                           targetType => "bookmap",
                                                         }, "Bookmap"),
                                            },
    statusLine                           => "Xref: 1 ref",
    statusTable                          => "   Count  Condition\n1      1  ref\n",
    subjectSchemeMap                     => undef,
    suppressReferenceChecks              => undef,
    tableDimensions                      => {},
    tagCount                             => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => {
                                                                                                       appendices        => 1,
                                                                                                       approved          => 1,
                                                                                                       author            => 1,
                                                                                                       bookchangehistory => 1,
                                                                                                       booklists         => 1,
                                                                                                       bookmap           => 1,
                                                                                                       bookmeta          => 1,
                                                                                                       bookowner         => 1,
                                                                                                       bookrights        => 1,
                                                                                                       booktitle         => 1,
                                                                                                       brand             => 1,
                                                                                                       category          => 1,
                                                                                                       CDATA             => 1,
                                                                                                       chapter           => 1,
                                                                                                       copyrfirst        => 1,
                                                                                                       frontmatter       => 1,
                                                                                                       keyword           => 1,
                                                                                                       keywords          => 1,
                                                                                                       mainbooktitle     => 1,
                                                                                                       notices           => 1,
                                                                                                       preface           => 1,
                                                                                                       prodinfo          => 1,
                                                                                                       prodname          => 1,
                                                                                                       prognum           => 1,
                                                                                                       relcell           => 4,
                                                                                                       relcolspec        => 2,
                                                                                                       relheader         => 1,
                                                                                                       relrow            => 2,
                                                                                                       reltable          => 1,
                                                                                                       revisionid        => 1,
                                                                                                       shortdesc         => 1,
                                                                                                       source            => 1,
                                                                                                       toc               => 1,
                                                                                                       topicref          => 3,
                                                                                                       vrm               => 1,
                                                                                                       vrmlist           => 1,
                                                                                                       year              => 1,
                                                                                                     },
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => {
                                                                                                       appendices        => 1,
                                                                                                       approved          => 1,
                                                                                                       author            => 1,
                                                                                                       bookchangehistory => 1,
                                                                                                       booklists         => 1,
                                                                                                       bookmap           => 1,
                                                                                                       bookmeta          => 1,
                                                                                                       bookowner         => 1,
                                                                                                       bookrights        => 1,
                                                                                                       booktitle         => 1,
                                                                                                       brand             => 1,
                                                                                                       category          => 1,
                                                                                                       CDATA             => 1,
                                                                                                       chapter           => 1,
                                                                                                       copyrfirst        => 1,
                                                                                                       frontmatter       => 1,
                                                                                                       keyword           => 1,
                                                                                                       keywords          => 1,
                                                                                                       mainbooktitle     => 1,
                                                                                                       notices           => 1,
                                                                                                       preface           => 1,
                                                                                                       prodinfo          => 1,
                                                                                                       prodname          => 1,
                                                                                                       prognum           => 1,
                                                                                                       relcell           => 4,
                                                                                                       relcolspec        => 2,
                                                                                                       relheader         => 1,
                                                                                                       relrow            => 2,
                                                                                                       reltable          => 1,
                                                                                                       revisionid        => 1,
                                                                                                       shortdesc         => 1,
                                                                                                       source            => 1,
                                                                                                       toc               => 1,
                                                                                                       topicref          => 3,
                                                                                                       vrm               => 1,
                                                                                                       vrmlist           => 1,
                                                                                                       year              => 1,
                                                                                                     },
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => { CDATA => 1, conbody => 1, concept => 1, title => 1 },
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => { CDATA => 1, conbody => 1, concept => 1, p => 1, title => 1 },
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => { CDATA => 1, conbody => 1, concept => 1, p => 1, title => 1 },
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => { CDATA => 1, conbody => 1, concept => 1, p => 1, title => 1 },
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => { CDATA => 2, conbody => 1, concept => 1, p => 1, title => 1 },
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => { CDATA => 1, conbody => 1, concept => 1, title => 1 },
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => { CDATA => 2, conbody => 1, concept => 1, p => 1, title => 1 },
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => { CDATA => 2, conbody => 1, concept => 1, p => 1, title => 1 },
                                            },
    tags                                 => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => 43,
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => 43,
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => 3,
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => 4,
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => 4,
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => 4,
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => 4,
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => 3,
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => 4,
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => 4,
                                            },
    targetFolderContent                  => {
                                              "a.xml" => "bless({\n  source => \"a.xml\",\n  sourceDocType => \"concept\",\n  target => \"bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap\",\n  targetType => \"bookmap\",\n}, \"SourceToTarget\")",
                                              "b.xml" => "bless({\n  source => \"b.xml\",\n  sourceDocType => \"concept\",\n  target => \"bm_b_d2806ba589f908da1106574afd9db642.ditamap\",\n  targetType => \"bookmap\",\n}, \"SourceToTarget\")",
                                            },
    targetTopicToInputFiles              => {
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => { "a.xml" => 1 },
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => { "a.xml" => 1 },
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => { "a.xml" => 1 },
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => { "a.xml" => 1 },
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => { "b.xml" => 1 },
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => { "b.xml" => 1 },
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => { "b.xml" => 1 },
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => { "b.xml" => 1 },
                                            },
    texts                                => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => 1,
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => 1,
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => 1,
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => 1,
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => 1,
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => 1,
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => 2,
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => 1,
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => 2,
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => 2,
                                            },
    title                                => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => "a",
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => "b",
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => "aaaa",
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => "aaaa bbbb",
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => "aaaa cccc",
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => "aaaa dddd",
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => "bbbb",
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => "bbbb aaaa",
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => "bbbb bbbb",
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => "bbbb cccc",
                                            },
    titleToFile                          => {
                                              "aaaa"      => { "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita" => 1 },
                                              "aaaa bbbb" => { "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => 1 },
                                              "aaaa cccc" => { "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => 1 },
                                              "aaaa dddd" => { "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => 1 },
                                              "bbbb"      => { "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita" => 1 },
                                              "bbbb aaaa" => { "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => 1 },
                                              "bbbb bbbb" => { "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => 1 },
                                              "bbbb cccc" => { "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => 1 },
                                            },
    topicFlattening                      => {},
    topicFlatteningFactor                => 0,
    topicIds                             => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"     => "GUID-80a6bceb-0817-2a54-4d9e-ea67eed112b3",
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap"     => "GUID-21696006-94ec-4e53-78c5-24a93641a474",
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => "GUID-c67821ef-3da2-c89f-0fc9-9fba3937f368",
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => "GUID-f0c0e170-8128-10ef-045d-97602fdde76f",
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => "GUID-400c2c59-95e1-7bf3-4647-3a135281bfaf",
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => "GUID-68822563-d568-f418-38ae-f1c62cb4ac8d",
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => "GUID-96a20d7f-bbaf-deef-55ef-e09a0a059251",
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => "GUID-86a684b0-1a0b-4c30-6da9-24c74ff1f0cc",
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => "GUID-cfe7cb3d-05e7-a147-db10-dcbacaeecef7",
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => "GUID-2b6aab4f-9328-e326-f55f-160771a8c3dd",
                                            },
    topicsFlattened                      => 0,
    topicsNotReferencedFromBookMaps      => {},
    topicsReferencedFromBookMaps         => {
                                              "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap" => 'fix',
                                              "bm_b_d2806ba589f908da1106574afd9db642.ditamap" => 'fix',
                                            },
    topicsToReferringBookMaps            => {
                                              "c_aaaa_121939eab89cd7d2c3eb4c4189772a1f.dita"      => { "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap" => 1 },
                                              "c_aaaa_bbbb_55baefe9258538b26a95b0015a8d5a2b.dita" => { "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap" => 1 },
                                              "c_aaaa_cccc_a91633094220d068c453eecae1726eff.dita" => { "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap" => 1 },
                                              "c_aaaa_dddd_914b8e11993908497768c50d992ea0f0.dita" => { "bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap" => 1 },
                                              "c_bbbb_6100b51ca1f789836cd4f31893ed67d2.dita"      => { "bm_b_d2806ba589f908da1106574afd9db642.ditamap" => 1 },
                                              "c_bbbb_aaaa_cfd3a140e06a914fc8469583ad87829d.dita" => { "bm_b_d2806ba589f908da1106574afd9db642.ditamap" => 1 },
                                              "c_bbbb_bbbb_c90ebf976073b2a3f7a8dc27a3c8254b.dita" => { "bm_b_d2806ba589f908da1106574afd9db642.ditamap" => 1 },
                                              "c_bbbb_cccc_d1c80714275637cde524bdfa1304a8f3.dita" => { "bm_b_d2806ba589f908da1106574afd9db642.ditamap" => 1 },
                                            },
    urls                                 => {},
    urlsBad                              => {},
    urlsGood                             => {},
    validateUrls                         => undef,
    validationErrors                     => {},
    vocabulary                           => {},
    xrefBadFormat                        => {},
    xrefBadScope                         => {},
    xRefs                                => {},
    xrefsFixedByTitle                    => [],
  }, "Data::Edit::Xml::Xref");
  $a->{topicsReferencedFromBookMaps}{"bm_a_9d0a9f8e0ac234de9e22c19054b6e455.ditamap"} = $a->{inputFileToTargetTopics}{"a.xml"};
  $a->{topicsReferencedFromBookMaps}{"bm_b_d2806ba589f908da1106574afd9db642.ditamap"} = $a->{inputFileToTargetTopics}{"b.xml"};
  $a;
}};
 }

#latestTest:;
if (1) {                                                                        # Othermeta migration
lll "Test 018";
  clearFolder(tests, 111);
  createSampleOtherMeta(in);

  my $x = xref(inputFolder      => in,
               reports          => reportFolder,
               subjectSchemeMap => fpe(out, qw(subjectScheme map)));

  ok !$x->errors;

  is_deeply checkXrefStructure($x, q(otherMetaDuplicatesSeparately)), [];

  is_deeply checkXrefStructure($x, q(otherMetaDuplicatesCombined)),
   [["b1.ditamap", "dd", 2, "DD"], ["", "", "", "DD1111"],
    ["b2.ditamap", "dd", 2, "DD"], ["", "", "", "DD2222"]];

  is_deeply checkXrefStructure($x, q(otherMetaRemainWithTopic)),
   [[ "ca.dita", "dd", "DD", "b1.ditamap", "b2.ditamap"],
    [ "cb.dita", "dd", "DD", "b1.ditamap", "b2.ditamap"]];

  is_deeply checkXrefStructure($x, q(otherMetaPushToBookMap)),
   [[ "ca.dita", "aa", "AAAA", "b1.ditamap"],
    [ "ca.dita", "aa", "AAAA", "b2.ditamap"],
    [ "ca.dita", "bb", "BBBB", "b1.ditamap"],
    [ "ca.dita", "bb", "BBBB", "b2.ditamap"],
    [ "cb.dita", "aa", "AAAA", "b1.ditamap"],
    [ "cb.dita", "aa", "AAAA", "b2.ditamap"],
    [ "cb.dita", "bb", "BBBB", "b1.ditamap"],
    [ "cb.dita", "bb", "BBBB", "b2.ditamap"]];

  is_deeply checkXrefStructure($x, q(otherMetaBookMapsBeforeTopicIncludes)),
   [["b1.ditamap", "aa", 1, "AAAA"],
    ["b1.ditamap", "bb", 1, "BBBB"],
    ["b1.ditamap", "dd", 1, "DD1111"],
    ["b2.ditamap", "aa", 1, "AAAA"],
    ["b2.ditamap", "bb", 1, "BBBB"],
    ["b2.ditamap", "dd", 1, "DD2222"]];

  is_deeply checkXrefStructure($x, q(otherMetaBookMapsAfterTopicIncludes)),
   [["b1.ditamap", "aa", 1, "AAAA"],
    ["b1.ditamap", "bb", 1, "BBBB"],
    ["b1.ditamap", "dd", 2, "DD"],
    ["b1.ditamap", "dd", 2, "DD1111"],
    ["b2.ditamap", "aa", 1, "AAAA"],
    ["b2.ditamap", "bb", 1, "BBBB"],
    ["b2.ditamap", "dd", 2, "DD"],
    ["b2.ditamap", "dd", 2, "DD2222"]];
 }

#latestTest:;
if (1) {                                                                        # Othermeta migration
lll "Test 019";
  clearFolder(tests, 111);
  createTestOneNotRef(tests);

  my $x = xref(inputFolder => in, reports => reportFolder);

  ok !$x->errors;

  is_deeply checkXrefStructure($x, q(topicsNotReferencedFromBookMaps)),
            {"b.dita" => 1};
  is_deeply checkXrefStructure($x, q(topicsReferencedFromBookMaps)),
            {"a.ditamap" => {"a.dita" => 1}};
 }

#latestTest:;
if (1) {                                                                        # Classification and subject scheme maps
lll "Test 020";
  clearFolder(tests, 111);
  createClassificationMapsTest(in);

  my $x = xref
   (inputFolder        => in,
    reports            => reportFolder,
    classificationMaps => 1,
    subjectSchemeMap   => fpe(reportFolder, qw(subjectSchemeAndClassification ditamap)));

  ok !$x->errors;
  my $m1 = fpe(in, qw(maps m1_classification ditamap));
  my $m2 = fpe(in, qw(maps m2_classification ditamap));
  ok -e $_ for $m1, $m2;
  ok readFile($m1) =~ m'<topicref href="m2_classification.ditamap">'i;
 }

#latestTest:;
if (1) {                                                                        # Classification and subject scheme maps
lll "Test 021";
  clearFolder(tests, 111);
  createWordsToFilesTest(in);

  my $x = xref(inputFolder      => in,
               reports          => reportFolder,
               indexWords       => 1,
               indexWordsFolder => fpd(reportFolder, q(words)));
  ok  65 == $x->indexedWords;

  my $wt = fpe($x->indexWordsFolder, qw(words_to_topics data));
  my $tw = fpe($x->indexWordsFolder, qw(topics_to_words data));

  ok -e $wt;
  ok -e $tw;

  my $index = retrieve $wt;
  my $i     = intersectionOfHashesAsArrays(map {$index->{$_}} qw(make tea));

  is_deeply removeFilePathsFromStructure($i), { "tea.dita" => [2, 5] };
 }

#latestTest:;
if (1) {                                                                        # Classification and subject scheme maps
lll "Test 022";
  clearFolder(tests, 111);
  createSampleConRefs(&in);

  my $x = xref
   (inputFolder      => in,
    reports          => reportFolder,
    fixBadRefs       => 1,
    fixRelocatedRefs => 1,
    fixXrefsByTitle  => 1,
    fixedFolder      => outFixed,
   );

  is_deeply removeFilePathsFromStructure($x->ids),
   { "c1.dita" => { c1 => 2, i1 => 1, i2 => 2, x1 => 1 },
     "c2.dita" => { c2 => 2, p1 => 1, p2 => 1 },
   };

  is_deeply removeFilePathsFromStructure($x->references),
   { "c1.dita" => { "i1" => 1, "i2" => 1, "i3" => 3, "p1" => 1, "p2" => 1, "p3" => 1, },
   };

  is_deeply removeFilePathsFromStructure($x->idNotReferenced),
   { "c1.dita" => { c1 => 1, x1 => 1 },
     "c2.dita" => { c2 => 1 },
   };

  is_deeply removeFilePathsFromStructure($x->idReferencedCount),
   { "c1.dita" => { i1 => 1, i2 => 1, i3 => 3 },
     "c2.dita" => { p1 => 1, p2 => 1, p3 => 1 },
   };

  ok $x->statusLine eq q(Xref: 5 refs, 3 duplicate ids, 2 first lines, 2 second lines);

  my $fr = readFile(fpe(reportFolder, qw(bad failing_references txt)));
  ok index($fr, q(Comma_Separated_Values_of_column_Reference: "c1.dita#c1/i2","c1.dita#c1/i3","c2.dita#c2/p3")) > -1;
  ok index($fr, q(Comma_Separated_Values_of_column_Attr: "conref","href"))                                      > -1;

  my $di = readFile(fpe(reportFolder, qw(bad duplicateIds txt)));
  ok index($di, q(Comma_Separated_Values_of_column_Id: "c1","c2","i2")) > -1;
  ok index($di, q(Comma_Separated_Values_of_column_Count: 2))           > -1;
 }

#latestTest:;
if (1) {                                                                         # Classification and subject scheme maps
lll "Test 023";
  clearFolder(tests, 111);
  createEmptyBody(&in);

  my $x = xref(inputFolder => in, reports => reportFolder);

  ok !$x->errors;

  #say STDERR writeStructureTest($x->emptyTopics, q($x->emptyTopics));
  is_deeply removeFilePathsFromStructure($x->emptyTopics),
   {"c1.dita" => 1};
 }

#latestTest:;
if (1) {                                                                        # Topics to referring bookmaps
lll "Test 024";
  clearFolder(tests, 111);
  createSampleTopicsReferencedFromBookMaps(&in);

  my $x = xref(inputFolder => in, reports => reportFolder);

  ok $x->statusLine eq q(Xref: 6 refs, 5 first lines, 5 second lines, 3 image refs);

  is_deeply removeFilePathsFromStructure($x->topicsToReferringBookMaps),
   { "c1.dita" => { "m1.dita" => 1, "m2.dita" => 1, },
     "c2.dita" => { "m2.dita" => 1, },
   };

  is_deeply removeFilePathsFromStructure($x->topicsReferencedFromBookMaps),
   { "m1.dita" => { "c1.dita" => 1, },
     "m2.dita" => { "c1.dita" => 1, "c2.dita" => 1, },
   };

  is_deeply removeFilePathsFromStructure($x->imagesToRefferingBookMaps),
   { "1.png" => { "m1.dita" => 1, "m2.dita" => 2, },
     "2.png" => { "m2.dita" => 1, },
     };

  is_deeply removeFilePathsFromStructure($x->imagesReferencedFromBookMaps),
   { "m1.dita" => { "1.png" => 1, },
     "m2.dita" => { "1.png" => 2, "2.png" => 1, },
   };
 }

#latestTest:;
if (1) {                                                                        # Conref matching
lll "Test 025";
  clearFolder(tests, 111);
  createSampleConRefMatching(&in);

  my $x = xref(inputFolder => in, reports => reportFolder);
  ok $x->statusLine eq q(Xref: 2 first lines, 2 second lines);
 }

#latestTest:;
if (1) {                                                                        # Md5 sum duplicates
lll "Test 026";
  clearFolder(tests, 111);
  createSampleDuplicateMd5Sum(&in);

  my $x = xref(inputFolder => in, reports => reportFolder, html => reportFolder);
  ok $x->statusLine eq q(Xref: 5 duplicate files, 5 first lines, 5 missing topic ids, 5 second lines);

  #say STDERR writeStructureTest($x->md5SumDuplicates, q($x->md5SumDuplicates));
  is_deeply removeFilePathsFromStructure($x->md5SumDuplicates),
   { "3b6840b4a7409ae6b0f6daed9aa8f1db" => { "t.dita" => 1, "t.dita" => 1, },
     "a5899fda929f90ff7a2419fc61d5f8c3" => { "c.dita" => 1, "c.dita" => 1, "c.dita" => 1, },
   };
 }

#latestTest:;
if (1) {                                                                        # Remove unreferenced ids
lll "Test 027";
  clearFolder(tests, 111);
  createSampleUnreferencedIds(&in);

  my $x = xref(inputFolder => in, reports => reportFolder, deleteUnusedIds => 1);
  ok $x->statusLine eq q(Xref: 4 duplicate ids, 2 first lines, 2 second lines, 1 ref);
  is_deeply $x->idsRemoved, {c1=>1, c2=>1, p3=>1};

  ok readFile(fpe(&in, qw(c1 dita))) eq <<END;
<concept id="c1">
  <title/>
  <conbody>
    <p id="p1"/>
    <p id="p2"/>
    <p id="p2"/>
    <p/>
    <p/>
    <p/>
  </conbody>
</concept>
END

  ok readFile(fpe(&in, qw(c2 dita))) eq <<END;
<concept id="c2">
  <title/>
  <conbody>
    <p href="c1.dita#p1"/>
    <p conref="c1.dita#c1/p2"/>
  </conbody>
</concept>
END

  my $y = xref(inputFolder => in, reports => reportFolder, html=>reportFolder);
  ok $y->statusLine eq q(Xref: 2 first lines, 2 second lines, 1 duplicate id, 1 ref);

  #say STDERR writeStructureTest($y->duplicateIds, q($y->duplicateIds));
  is_deeply removeFilePathsFromStructure($y->duplicateIds),
   { "c1.dita" => { p2 => 2 },
   };

  ok readFile(fpe(reportFolder, qw(index_of_reports html))) =~ m(<b>31</b> reports available);
 }

#latestTest:;
if (1) {                                                                        # Remove unreferenced ids
lll "Test 028";
  clearFolder(tests, 111);
  createSampleImageReferences(&in);

  my $x = xref(inputFolder => in, reports => reportFolder);
  ok $x->statusLine eq q(Xref: 6 refs, 3 first lines, 3 second lines, 1 image ref);

  #say STDERR writeStructureTest($x->goodImageFiles, q($x->goodImageFiles));
  is_deeply removeFilePathsFromStructure($x->goodImageFiles),
   { "good1.png" => 3, "good2.png" => 3};

  #say STDERR writeStructureTest($x->missingImageFiles, q($x->missingImageFiles));
  is_deeply removeFilePathsFromStructure($x->missingImageFiles),
   { "bad1.png" => 6, };
 }

#latestTest:;
if (1) {                                                                        # Required clean ups report
lll "Test 029";
  clearFolder(tests, 111);
  createRequiredCleanUps(&in);

  my $x = xref(inputFolder => in, reports => reportFolder);
  ok $x->statusLine eq q(Xref: 2 first lines, 2 second lines);

  #dumpFile(q(/home/phil/z/xref.data), deleteVariableFields($x)); exit;
  is_deeply deleteVariableFields($x),
 {addNavTitles                         => undef,
  allowUniquePartialMatches            => undef,
  attributeCount                       => { "c1.dita" => { id => 1 }, "c2.dita" => { id => 1 } },
  attributeNamesAndValuesCount         => {
                                            "c1.dita" => { id => { c1 => 1 } },
                                            "c2.dita" => { id => { c2 => 1 } },
                                          },
  author                               => {},
  badGuidHrefs                         => {},
  badNavTitles                         => {},
  badReferencesCount                   => 0,
  badTables                            => [],
  badXml1                              => { "c1.dita" => 1, "c2.dita" => 1 },
  badXml2                              => { "c1.dita" => 1, "c2.dita" => 1 },
  baseFiles                            => {},
  baseTag                              => { "c1.dita" => "concept", "c2.dita" => "concept" },
  bookMapRefs                          => {},
  changeBadXrefToPh                    => undef,
  classificationMaps                   => undef,
  conRefs                              => {},
  createReports1                       => [
                                            "reportXml1",
                                            "reportXml2",
                                            "reportDuplicateIds",
                                            "reportDuplicateTopicIds",
                                            "reportNoHrefs",
                                            "reportTables",
                                            "reportParseFailed",
                                            "reportAttributeCount",
                                            "reportLtGt",
                                            "reportTagCount",
                                            "reportTagsAndTextsCount",
                                            "reportDocTypeCount",
                                            "reportFileExtensionCount",
                                            "reportFileTypes",
                                            "reportValidationErrors",
                                            "reportGuidHrefs",
                                            "reportExternalXrefs",
                                            "reportTopicDetails",
                                            "reportTopicReuse",
                                            "reportMd5Sum",
                                            "reportOlBody",
                                            "reportHrefUrlEncoding",
                                            "reportFixRefs",
                                            "reportSourceFiles",
                                            "reportOtherMeta",
                                            "createSubjectSchemeMap",
                                            "reportTopicsNotReferencedFromBookMaps",
                                            "reportTableDimensions",
                                            "reportExteriorMaps",
                                            "createClassificationMaps",
                                            "reportIdRefs",
                                            "reportEmptyTopics",
                                            "reportConRefMatching",
                                            "reportPublicIds",
                                            "reportRequiredCleanUps",
                                          ],
  createReports2                       => ["removeUnusedIds", "reportImages"],
  currentFolder                        => "",
  deguidize                            => undef,
  deleteUnusedIds                      => 0,
  docType                              => { "c1.dita" => "concept", "c2.dita" => "concept" },
  duplicateIds                         => {},
  duplicateTopicIds                    => {},
  emptyTopics                          => {},
  errors                               => 2,
  exteriorMaps                         => {},
  fileExtensions                       => [".dita", ".ditamap", ".xml", ".fodt"],
  fixBadRefs                           => undef,
  fixDitaRefs                          => undef,
  fixedFolder                          => undef,
  fixedFolderTemp                      => "",
  fixedRefsBad                         => [],
  fixedRefsGB                          => [],
  fixedRefsGood                        => [],
  fixedRefsNoAction                    => [],
  fixRefs                              => {},
  fixRelocatedRefs                     => undef,
  fixXrefsByTitle                      => undef,
  flattenFiles                         => {},
  flattenFolder                        => undef,
  getFileUrl                           => "client.pl?getFile=",
  goodImageFiles                       => {},
  goodNavTitles                        => {},
  guidHrefs                            => {},
  guidToFile                           => {},
  hrefUrlEncoding                      => {},
  html                                 => undef,
  idNotReferenced                      => { "c1.dita" => { c1 => 1 }, "c2.dita" => { c2 => 1 } },
  idReferencedCount                    => {},
  ids                                  => { "c1.dita" => { c1 => 1 }, "c2.dita" => { c2 => 1 } },
  idsRemoved                           => { c1 => 1, c2 => 1 },
  idTags                               => {
                                            "c1.dita" => { c1 => ["concept"] },
                                            "c2.dita" => { c2 => ["concept"] },
                                          },
  images                               => {},
  imagesReferencedFromBookMaps         => {},
  imagesReferencedFromTopics           => {},
  imagesToRefferingBookMaps            => {},
  indexedWords                         => {},
  indexWords                           => undef,
  indexWordsFolder                     => undef,
  inputFiles                           => ["c1.dita", "c2.dita"],
  inputFileToTargetTopics              => {},
  inputFolder                          => "",
  inputFolderImages                    => { c1 => "c1.dita", c2 => "c2.dita" },
  ltgt                                 => {},
  matchTopics                          => undef,
  maxZoomIn                            => undef,
  maxZoomOut                           => { "c1.dita" => {}, "c2.dita" => {} },
  md5Sum                               => {
                                            "c1.dita" => "92ab49a6d97f749545ec5dc873f53bdb",
                                            "c2.dita" => "a3df8bdda952294d6a533b7ff4f6faeb",
                                          },
  md5SumDuplicates                     => {},
  missingImageFiles                    => {},
  missingTopicIds                      => {},
  noHref                               => {},
  notReferenced                        => {},
  olBody                               => {},
  originalSourceFileAndIdToNewFile     => {},
  otherMeta                            => {},
  otherMetaBookMapsAfterTopicIncludes  => [],
  otherMetaBookMapsBeforeTopicIncludes => [],
  otherMetaConsolidated                => {},
  otherMetaDuplicatesCombined          => [],
  otherMetaDuplicatesSeparately        => [],
  otherMetaPushToBookMap               => [],
  otherMetaRemainWithTopic             => [],
  oxygenProjects                       => undef,
  parseFailed                          => {},
  publicId                             => { "c1.dita" => undef, "c2.dita" => undef },
  references                           => {},
  relocatedReferencesFailed            => [],
  relocatedReferencesFixed             => [],
  reports                              => '',
  requestAttributeNameAndValueCounts   => undef,
  requiredCleanUp                      => {
                                            "c1.dita" => { aaa => 1, bbb => 2 },
                                            "c2.dita" => { aaa => 1, bbb => 1, ccc => 1, CCC => 1 },
                                          },
  results                              => [[2, "first lines"], [2, "second lines"]],
  sourceTopicToTargetBookMap           => {},
  statusLine                           => "Xref: 2 first lines, 2 second lines",
  statusTable                          => "   Count  Condition\n1      2  first lines\n2      2  second lines\n",
  subjectSchemeMap                     => undef,
  suppressReferenceChecks              => undef,
  tableDimensions                      => {},
  tagCount                             => {
                                            "c1.dita" => {
                                                           "CDATA" => 4,
                                                           "conbody" => 1,
                                                           "concept" => 1,
                                                           "required-cleanup" => 3,
                                                           "title" => 1,
                                                         },
                                            "c2.dita" => {
                                                           "CDATA" => 5,
                                                           "conbody" => 1,
                                                           "concept" => 1,
                                                           "required-cleanup" => 4,
                                                           "title" => 1,
                                                         },
                                          },
  tags                                 => { "c1.dita" => 6, "c2.dita" => 7 },
  targetFolderContent                  => {},
  targetTopicToInputFiles              => {},
  texts                                => { "c1.dita" => 4, "c2.dita" => 5 },
  title                                => { "c1.dita" => "C1_", "c2.dita" => "C2_" },
  titleToFile                          => { C1_ => { "c1.dita" => 1 }, C2_ => { "c2.dita" => 1 } },
  topicFlattening                      => {},
  topicFlatteningFactor                => {},
  topicIds                             => { "c1.dita" => "c1", "c2.dita" => "c2" },
  topicsFlattened                      => undef,
  topicsNotReferencedFromBookMaps      => { "c1.dita" => 1, "c2.dita" => 1 },
  topicsReferencedFromBookMaps         => {},
  topicsToReferringBookMaps            => {},
  urls                                 => {},
  urlsBad                              => {},
  urlsGood                             => {},
  validateUrls                         => undef,
  validationErrors                     => {},
  vocabulary                           => {},
  xrefBadFormat                        => {},
  xrefBadScope                         => {},
  xRefs                                => {},
  xrefsFixedByTitle                    => [],
};

  #say STDERR writeStructureTest($x->requiredCleanUp, q($x->requiredCleanUp));
  is_deeply removeFilePathsFromStructure($x->requiredCleanUp),
   { "c1.dita" => { aaa => 1, bbb => 2 },
     "c2.dita" => { aaa => 1, bbb => 1, ccc => 1, CCC => 1 },
   };
 }

#latestTest:;
if (1) {                                                                        # Soft conrefs
lll "Test 030";
  clearFolder(tests, 111);
  createSoftConrefs(&in);

  my $x = xref(inputFolder      => in, reports => reportFolder);
  ok $x->statusLine eq q(Xref: 7 refs, 1 duplicate id, 1 duplicate topic id);

  my $y = xref
   (inputFolder      => in,
    reports          => reportFolder,
    fixRelocatedRefs => 1,
    fixedFolder      => outFixed,
   );

  ok $y->statusLine eq q(Xref: 7 refs, 1 duplicate id, 1 duplicate topic id);

  my $z = xref(inputFolder => outFixed, reports => reportFolder);
  ok $z->statusLine eq q(Xref: 6 refs, 1 duplicate id, 1 duplicate topic id);

  #dumpFile(q(/home/phil/z/xref.data), deleteVariableFields($z)); exit;
  is_deeply deleteVariableFields($z),
 {addNavTitles                         => undef,
  allowUniquePartialMatches            => undef,
  attributeCount                       => {
                                            "c.dita" => { conref => 6, id => 2 },
                                            "c_12345678123456781234567812345678.dita" => { conref => 2, id => 3 },
                                          },
  attributeNamesAndValuesCount         => {
                                            "c.dita" => {
                                              conref => {
                                                "bad" => 1,
                                                "c.dta" => 1,
                                                "c_12345678123456781234567812345678.dita" => 1,
                                                "p1" => 1,
                                                "q1" => 1,
                                              },
                                              id => { c => 1, q1 => 1 },
                                            },
                                            "c_12345678123456781234567812345678.dita" => { conref => { p1 => 1, pp => 1 }, id => { c => 1, p1 => 2 } },
                                          },
  author                               => {},
  badGuidHrefs                         => {},
  badNavTitles                         => {},
  badReferencesCount                   => 6,
  badTables                            => [],
  badXml1                              => {},
  badXml2                              => {},
  baseFiles                            => {},
  baseTag                              => {
                                            "c.dita" => "concept",
                                            "c_12345678123456781234567812345678.dita" => "concept",
                                          },
  bookMapRefs                          => {},
  changeBadXrefToPh                    => undef,
  classificationMaps                   => undef,
  conRefs                              => {
                                            "c.dita" => {
                                              "bad" => { p => 1 },
                                              "c.dta" => { p => 1 },
                                              "c_12345678123456781234567812345678.dita" => { p => 1 },
                                              "p1" => { p => 1 },
                                              "q1" => { p => 1 },
                                            },
                                            "c_12345678123456781234567812345678.dita" => { p1 => { p => 1 }, pp => { p => 1 } },
                                          },
  createReports1                       => [
                                            "reportXml1",
                                            "reportXml2",
                                            "reportDuplicateIds",
                                            "reportDuplicateTopicIds",
                                            "reportNoHrefs",
                                            "reportTables",
                                            "reportParseFailed",
                                            "reportAttributeCount",
                                            "reportLtGt",
                                            "reportTagCount",
                                            "reportTagsAndTextsCount",
                                            "reportDocTypeCount",
                                            "reportFileExtensionCount",
                                            "reportFileTypes",
                                            "reportValidationErrors",
                                            "reportGuidHrefs",
                                            "reportExternalXrefs",
                                            "reportTopicDetails",
                                            "reportTopicReuse",
                                            "reportMd5Sum",
                                            "reportOlBody",
                                            "reportHrefUrlEncoding",
                                            "reportFixRefs",
                                            "reportSourceFiles",
                                            "reportOtherMeta",
                                            "createSubjectSchemeMap",
                                            "reportTopicsNotReferencedFromBookMaps",
                                            "reportTableDimensions",
                                            "reportExteriorMaps",
                                            "createClassificationMaps",
                                            "reportIdRefs",
                                            "reportEmptyTopics",
                                            "reportConRefMatching",
                                            "reportPublicIds",
                                            "reportRequiredCleanUps",
                                          ],
  createReports2                       => ["removeUnusedIds", "reportImages"],
  currentFolder                        => "",
  deguidize                            => undef,
  deleteUnusedIds                      => 0,
  docType                              => {
                                            "c.dita" => "concept",
                                            "c_12345678123456781234567812345678.dita" => "concept",
                                          },
  duplicateIds                         => { "c_12345678123456781234567812345678.dita" => { p1 => 2 } },
  duplicateTopicIds                    => { c => ["c", "c_12345678123456781234567812345678.dita", "c.dita"] },
  emptyTopics                          => {},
  errors                               => 3,
  exteriorMaps                         => {},
  fileExtensions                       => [".dita", ".ditamap", ".xml", ".fodt"],
  fixBadRefs                           => undef,
  fixDitaRefs                          => undef,
  fixedFolder                          => undef,
  fixedFolderTemp                      => "",
  fixedRefsBad                         => [
                                            [
                                              "Not fixable",
                                              "p",
                                              "conref",
                                              "p1",
                                              "c_12345678123456781234567812345678.dita",
                                            ],
                                            [
                                              "Not fixable",
                                              "p",
                                              "conref",
                                              "pp",
                                              "c_12345678123456781234567812345678.dita",
                                            ],
                                            ["Not fixable", "p", "conref", "c.dta", "c.dita"],
                                            ["Not fixable", "p", "conref", "bad", "c.dita"],
                                            ["Not fixable", "p", "conref", "p1", "c.dita"],
                                            ["Not fixable", "p", "conref", "p1", "c.dita"],
                                          ],
  fixedRefsGB                          => [],
  fixedRefsGood                        => [],
  fixedRefsNoAction                    => [],
  fixRefs                              => {
                                            "c.dita" => { "bad" => 1, "c.dta" => 1, "p1" => 1 },
                                            "c_12345678123456781234567812345678.dita" => { p1 => 1, pp => 1 },
                                          },
  fixRelocatedRefs                     => undef,
  fixXrefsByTitle                      => undef,
  flattenFiles                         => {},
  flattenFolder                        => undef,
  getFileUrl                           => "client.pl?getFile=",
  goodImageFiles                       => {},
  goodNavTitles                        => {},
  guidHrefs                            => {},
  guidToFile                           => {},
  hrefUrlEncoding                      => {},
  html                                 => undef,
  idNotReferenced                      => {
                                            "c.dita" => { c => 1 },
                                            "c_12345678123456781234567812345678.dita" => { c => 1 },
                                          },
  idReferencedCount                    => {
                                            "c.dita" => { q1 => 1 },
                                            "c_12345678123456781234567812345678.dita" => { bad => 1, p1 => 3, pp => 1 },
                                          },
  ids                                  => {
                                            "c.dita" => { c => 1, q1 => 1 },
                                            "c_12345678123456781234567812345678.dita" => { c => 1, p1 => 2 },
                                          },
  idsRemoved                           => { c => 2 },
  idTags                               => {
                                            "c.dita" => { c => ["concept"], q1 => ["p"] },
                                            "c_12345678123456781234567812345678.dita" => { c => ["concept"], p1 => ["p", "p"] },
                                          },
  images                               => {},
  imagesReferencedFromBookMaps         => {},
  imagesReferencedFromTopics           => {},
  imagesToRefferingBookMaps            => {},
  indexedWords                         => {},
  indexWords                           => undef,
  indexWordsFolder                     => undef,
  inputFiles                           => ["c.dita", "c_12345678123456781234567812345678.dita"],
  inputFileToTargetTopics              => {},
  inputFolder                          => "",
  inputFolderImages                    => {
                                            c => "c.dita",
                                            c_12345678123456781234567812345678 => "c_12345678123456781234567812345678.dita",
                                          },
  ltgt                                 => {},
  matchTopics                          => undef,
  maxZoomIn                            => undef,
  maxZoomOut                           => { "c.dita" => {}, "c_12345678123456781234567812345678.dita" => {} },
  md5Sum                               => {
                                            "c.dita" => "c7c95918b94057943d448ca99e5424cc",
                                            "c_12345678123456781234567812345678.dita" => "d3d1c1ce281895768bd92f27fd492191",
                                          },
  md5SumDuplicates                     => {},
  missingImageFiles                    => {},
  missingTopicIds                      => {},
  noHref                               => {},
  notReferenced                        => {},
  olBody                               => {},
  originalSourceFileAndIdToNewFile     => {},
  otherMeta                            => {},
  otherMetaBookMapsAfterTopicIncludes  => [],
  otherMetaBookMapsBeforeTopicIncludes => [],
  otherMetaConsolidated                => {},
  otherMetaDuplicatesCombined          => [],
  otherMetaDuplicatesSeparately        => [],
  otherMetaPushToBookMap               => [],
  otherMetaRemainWithTopic             => [],
  oxygenProjects                       => undef,
  parseFailed                          => {},
  publicId                             => { "c.dita" => "EN", "c_12345678123456781234567812345678.dita" => "EN" },
  references                           => {
                                            "c.dita" => {
                                              "bad" => 1,
                                              "c.dta" => 1,
                                              "c_12345678123456781234567812345678.dita" => 1,
                                              "p1" => 1,
                                              "q1" => 1,
                                            },
                                            "c_12345678123456781234567812345678.dita" => { p1 => 1, pp => 1 },
                                          },
  relocatedReferencesFailed            => [],
  relocatedReferencesFixed             => [],
  reports                              => '',
  requestAttributeNameAndValueCounts   => undef,
  requiredCleanUp                      => {},
  results                              => [[1, "duplicate id"], [6, "refs"], [1, "duplicate topic id"]],
  sourceTopicToTargetBookMap           => {},
  statusLine                           => "Xref: 6 refs, 1 duplicate id, 1 duplicate topic id",
  statusTable                          => "   Count  Condition\n1      6  refs\n2      1  duplicate id\n3      1  duplicate topic id\n",
  subjectSchemeMap                     => undef,
  suppressReferenceChecks              => undef,
  tableDimensions                      => {},
  tagCount                             => {
                                            "c.dita" => { CDATA => 2, conbody => 1, concept => 1, p => 7, title => 1 },
                                            "c_12345678123456781234567812345678.dita" => { CDATA => 3, conbody => 1, concept => 1, p => 4, title => 1 },
                                          },
  tags                                 => { "c.dita" => 10, "c_12345678123456781234567812345678.dita" => 7 },
  targetFolderContent                  => {},
  targetTopicToInputFiles              => {},
  texts                                => { "c.dita" => 2, "c_12345678123456781234567812345678.dita" => 3 },
  title                                => { "c.dita" => "C2", "c_12345678123456781234567812345678.dita" => "C1" },
  titleToFile                          => {
                                            C1 => { "c_12345678123456781234567812345678.dita" => 1 },
                                            C2 => { "c.dita" => 1 },
                                          },
  topicFlattening                      => {},
  topicFlatteningFactor                => {},
  topicIds                             => { "c.dita" => "c", "c_12345678123456781234567812345678.dita" => "c" },
  topicsFlattened                      => undef,
  topicsNotReferencedFromBookMaps      => { "c.dita" => 1, "c_12345678123456781234567812345678.dita" => 1 },
  topicsReferencedFromBookMaps         => {},
  topicsToReferringBookMaps            => {},
  urls                                 => {},
  urlsBad                              => {},
  urlsGood                             => {},
  validateUrls                         => undef,
  validationErrors                     => {},
  vocabulary                           => {},
  xrefBadFormat                        => {},
  xrefBadScope                         => {},
  xRefs                                => {},
  xrefsFixedByTitle                    => [],
};
 }

#latestTest:;
if (1) {                                                                        # Oxygen project files
lll "Test 031";
  clearFolder(tests, 111);
  createSampleInputFilesBaseCase(&in, 8);

  my $x = xref(inputFolder => in, reports => reportFolder, oxygenProjects=>1);
  ok $x->statusLine eq q(Xref: 104 refs, 21 image refs, 14 first lines, 14 second lines, 8 duplicate ids, 4 duplicate topic ids, 4 invalid guid hrefs, 2 duplicate files, 2 tables, 1 External xrefs with no format=html, 1 External xrefs with no scope=external, 1 file failed to parse, 1 href missing);
 }

#latestTest:;
if (0) {                                                                        # Performance tests 1.419
lll "Test 032";
  my $folder = q(/home/phil/perl/cpan/DataEditXmlXref/lib/Data/Edit/Xml/samples/);
  xref(inputFolder => $folder);
 }

#latestTest:;
if (1) {                                                                        # Urls
lll "Test 033 Urls";
  clearFolder(tests, 222);
  createUrlTests(&in);

  my $x = xref(inputFolder => in, reports => reportFolder, validateUrls=>1);

  ok $x->statusLine eq q(Xref: 2 urls);

#  dumpFile(q(/home/phil/z/xref.data), deleteVariableFields($x));
  is_deeply deleteVariableFields($x),
bless({
  addNavTitles                         => undef,
  allowUniquePartialMatches            => undef,
  attributeCount                       => {
                                            "concept.dita" => { format => 2, href => 2, id => 1, scope => 2 },
                                          },
  attributeNamesAndValuesCount         => {
                                            "concept.dita" => {
                                              format => { html => 2 },
                                              href => { "ww2.appaapps.com" => 1, "www.appaapps.com" => 1 },
                                              id => { c => 1 },
                                              scope => { external => 2 },
                                            },
                                          },
  author                               => {},
  badGuidHrefs                         => {},
  badNavTitles                         => {},
  badReferencesCount                   => 0,
  badTables                            => [],
  badXml1                              => {},
  badXml2                              => {},
  baseFiles                            => {},
  baseTag                              => { "concept.dita" => "concept" },
  bookMapRefs                          => {},
  changeBadXrefToPh                    => undef,
  classificationMaps                   => undef,
  conRefs                              => {},
  createReports1                       => [
                                            "reportXml1",
                                            "reportXml2",
                                            "reportDuplicateIds",
                                            "reportDuplicateTopicIds",
                                            "reportNoHrefs",
                                            "reportTables",
                                            "reportParseFailed",
                                            "reportAttributeCount",
                                            "reportLtGt",
                                            "reportTagCount",
                                            "reportTagsAndTextsCount",
                                            "reportDocTypeCount",
                                            "reportFileExtensionCount",
                                            "reportFileTypes",
                                            "reportValidationErrors",
                                            "reportGuidHrefs",
                                            "reportExternalXrefs",
                                            "reportTopicDetails",
                                            "reportTopicReuse",
                                            "reportMd5Sum",
                                            "reportOlBody",
                                            "reportHrefUrlEncoding",
                                            "reportFixRefs",
                                            "reportSourceFiles",
                                            "reportOtherMeta",
                                            "createSubjectSchemeMap",
                                            "reportTopicsNotReferencedFromBookMaps",
                                            "reportTableDimensions",
                                            "reportExteriorMaps",
                                            "createClassificationMaps",
                                            "reportIdRefs",
                                            "reportEmptyTopics",
                                            "reportConRefMatching",
                                            "reportPublicIds",
                                            "reportRequiredCleanUps",
                                            "reportUrls",
                                          ],
  createReports2                       => ["removeUnusedIds", "reportImages"],
  currentFolder                        => "",
  deguidize                            => undef,
  deleteUnusedIds                      => 0,
  docType                              => { "concept.dita" => "concept" },
  duplicateIds                         => {},
  duplicateTopicIds                    => {},
  emptyTopics                          => {},
  errors                               => 1,
  exteriorMaps                         => {},
  fileExtensions                       => [".dita", ".ditamap", ".xml", ".fodt"],
  fixBadRefs                           => undef,
  fixDitaRefs                          => undef,
  fixedFolder                          => undef,
  fixedFolderTemp                      => "",
  fixedRefsBad                         => [],
  fixedRefsGB                          => [],
  fixedRefsGood                        => [],
  fixedRefsNoAction                    => [],
  fixRefs                              => {},
  fixRelocatedRefs                     => undef,
  fixXrefsByTitle                      => undef,
  flattenFiles                         => {},
  flattenFolder                        => undef,
  getFileUrl                           => "client.pl?getFile=",
  goodImageFiles                       => {},
  goodNavTitles                        => {},
  guidHrefs                            => {},
  guidToFile                           => {},
  hrefUrlEncoding                      => {},
  html                                 => undef,
  idNotReferenced                      => { "concept.dita" => { c => 1 } },
  idReferencedCount                    => {},
  ids                                  => { "concept.dita" => { c => 1 } },
  idsRemoved                           => { c => 1 },
  idTags                               => { "concept.dita" => { c => ["concept"] } },
  images                               => {},
  imagesReferencedFromBookMaps         => {},
  imagesReferencedFromTopics           => {},
  imagesToRefferingBookMaps            => {},
  indexedWords                         => {},
  indexWords                           => undef,
  indexWordsFolder                     => undef,
  inputFiles                           => ["concept.dita"],
  inputFileToTargetTopics              => {},
  inputFolder                          => "",
  inputFolderImages                    => { concept => "concept.dita" },
  ltgt                                 => {},
  matchTopics                          => undef,
  maxZoomIn                            => undef,
  maxZoomOut                           => { "concept.dita" => {} },
  md5Sum                               => { "concept.dita" => "f38f3212622c0fd073b213176a045e47" },
  md5SumDuplicates                     => {},
  missingImageFiles                    => {},
  missingTopicIds                      => {},
  noHref                               => {},
  notReferenced                        => {},
  olBody                               => {},
  originalSourceFileAndIdToNewFile     => {},
  otherMeta                            => {},
  otherMetaBookMapsAfterTopicIncludes  => [],
  otherMetaBookMapsBeforeTopicIncludes => [],
  otherMetaConsolidated                => {},
  otherMetaDuplicatesCombined          => [],
  otherMetaDuplicatesSeparately        => [],
  otherMetaPushToBookMap               => [],
  otherMetaRemainWithTopic             => [],
  oxygenProjects                       => undef,
  parseFailed                          => {},
  publicId                             => { "concept.dita" => "EN" },
  references                           => {},
  relocatedReferencesFailed            => [],
  relocatedReferencesFixed             => [],
  reports                              => "",
  requestAttributeNameAndValueCounts   => undef,
  requiredCleanUp                      => {},
  results                              => [[2, "urls"]],
  sourceTopicToTargetBookMap           => {},
  statusLine                           => "Xref: 2 urls",
  statusTable                          => "   Count  Condition\n1      2  urls\n",
  subjectSchemeMap                     => undef,
  suppressReferenceChecks              => undef,
  tableDimensions                      => {},
  tagCount                             => {
                                            "concept.dita" => { CDATA => 3, conbody => 1, concept => 1, p => 2, title => 1, xref => 2 },
                                          },
  tags                                 => { "concept.dita" => 7 },
  targetFolderContent                  => {},
  targetTopicToInputFiles              => {},
  texts                                => { "concept.dita" => 3 },
  title                                => { "concept.dita" => "Urls" },
  titleToFile                          => { Urls => { "concept.dita" => 1 } },
  topicFlattening                      => {},
  topicFlatteningFactor                => {},
  topicIds                             => { "concept.dita" => "c" },
  topicsFlattened                      => undef,
  topicsNotReferencedFromBookMaps      => { "concept.dita" => 1 },
  topicsReferencedFromBookMaps         => {},
  topicsToReferringBookMaps            => {},
  urls                                 => {
                                            "concept.dita" => { "ww2.appaapps.com" => 1, "www.appaapps.com" => 1 },
                                          },
  urlsBad                              => {
                                            "ww2.appaapps.com" => { "concept.dita" => 1 },
                                            "www.appaapps.com" => { "concept.dita" => 1 },
                                          },
  urlsGood                             => {},
  validateUrls                         => 1,
  validationErrors                     => {},
  vocabulary                           => {},
  xrefBadFormat                        => {},
  xrefBadScope                         => {},
  xRefs                                => {},
  xrefsFixedByTitle                    => [],
}, "Data::Edit::Xml::Xref")
 }

clearFolder($_, 1e3) for in, out, outFixed, reportFolder, tests, targets, q(zzzParseErrors);

done_testing;

lll "Tests finished:";  # 16.212
