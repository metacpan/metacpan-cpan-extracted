#!/usr/bin/perl  -I/home/phil/perl/cpan/DataEditXml/lib/ -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Cross reference Dita XML.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2018
#-------------------------------------------------------------------------------
# It is easier to criticize than to fix.
# podDocumentation

package Data::Edit::Xml::Xref;
our $VERSION = 20190121;
use v5.20;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Edit::Xml;
use Data::Table::Text qw(:all);
use utf8;

#D1 Cross reference                                                             # Check the cross references in a set of Dita files and report the results.

sub improvementLength {80}                                                      # Improvement length

sub lll(@)                                                                      #P Write a message
 {my (@m) = @_;                                                                 # Message text
  say STDERR timeStamp, join "", " Xref: ", @_;
 }

sub xref(%)                                                                     # Check the cross references in a set of Dita files held in  L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder. The possible attributes are defined in L<Data::Edit::Xml::Xref|/Data::Edit::Xml::Xref>
 {my (%attributes) = @_;                                                        # Attributes
  my $xref = genHash(__PACKAGE__,                                               # Attributes used by the Xref cross referencer.
    attributeCount=>{},                                                         # {file}{attribute} == count of the different xml attributes found in the xml files.
    author=>{},                                                                 # {file} = author of file
    badBookMaps=>{},                                                            # Bad book maps
    badConRefs=>{},                                                             # {sourceFile} = [file, href] indicating the file has at least one bad conref
    badConRefsList=>{},                                                         # Bad conrefs - by file
    badGuidHrefs=>{},                                                           # Bad conrefs - all
    badImageRefs=>{},                                                           # Consolidated images missing.
    badTables=>[],                                                              # Array of tables that need fixing
    badTopicRefs=>{},                                                           # [file, href]   Invalid href attributes found on topicref tags.
    badXml1=>{},                                                                # [Files] with a bad xml encoding header on the first line.
    badXml2=>{},                                                                # [Files] with a bad xml doc type on the second line.
    badXRefs=>{},                                                               # Bad Xrefs - by file
    badXRefsList=>{},                                                           # Bad Xrefs - all
    conRefs=>{},                                                                # {file}{href}   Count of conref definitions in each file.
    docType=>{},                                                                # {file} == docType:  the docType for each xml file.
    duplicateIds=>{},                                                           # [file, id]     Duplicate id definitions within each file.
    duplicateTopicIds=>{},                                                      # Duplicate topic ids
    duplicateTopicIds=>{},                                                      # [topicId, [files]] Files with duplicate topic ids - the id on the outermost tag.
    fileExtensions=>[qw(.dita .ditamap .xml .fodt)],                            # Default file extensions to load
    fixBadRefs=>undef,                                                          # Try to fix bad references in L<these files|/fixRefs> where possible by either changing a guid to a file name assuming the right file is present or failing that by moving the failing reference to the "xtrf" attribute.
    fixRefs=>{},                                                                # {file}{ref} where the href or conref target is not present.
    fixedRefs=>[],                                                              # [] hrefs and conrefs from L<fixRefs|/fixRefs which have been ameliorated where possible by either changing a guid to a file name assuming the right file is present or failing that by moving the failing reference to the "xtrf" attribute.
    goodBookMaps=>{},                                                           # Good book maps
    goodConRefs=>{},                                                            # Good con refs - by file
    goodConRefsList=>{},                                                        # Good con refs - all
    goodGuidHrefs=>{},                                                          # {file}{href}{location}++ where a href that starts with GUID- has been correctly resolved
    goodImageRefs=>{},                                                          # Consolidated images found.
    goodTopicRefs=>{},                                                          # Good topic refs
    goodXRefs=>{},                                                              # Good xrefs - by file
    goodXRefsList=>{},                                                          # Good xrefs - all
    guidHrefs=>{},                                                              # {file}{href} = location where href starts with GUID- and is thus probably a guid
    guidToFile=>{},                                                             # {topic id which is a guid} = file defining topic id
    ids=>{},                                                                    # {file}{id}     Id definitions across all files.
    images=>{},                                                                 # {file}{href}   Count of image references in each file.
    improvements=>{},                                                           # Improvements needed
    inputFiles=>[],                                                             # Input files from L<inputFolder|/inputFolder>.
    inputFolder=>undef,                                                         # A folder containing the dita and ditamap files to be cross referenced.
    inputFolderImages=>{},                                                      # {filename} = full file name which works well for images because the md5 sum in their name is probably unique
    maximumNumberOfProcesses=>4,                                                # Maximum number of processes to run in parallel at any one time.
    md5Sum=>{},                                                                 # MD5 sum for each input file
    missingImageFiles=>{},                                                      # [file, href] == Missing images in each file.
    missingTopicIds=>{},                                                        # Missing topic ids
    noHref=>{},                                                                 # Tags that should have an href but do not have one
    notReferenced=>{},                                                          # Files in input area that are not referenced by a conref, image, topicref or xref tag and are not a bookmap.
    parseFailed=>{},                                                            # [file] files that failed to parse
    reports=>q(reports),                                                        # Reports folder: the cross referencer will write reports to files in this folder.
    results=>[],                                                                # Summary of results table
    sourceFile=>undef,                                                          # The source file from which this structure was generated
    statusLine=>undef,                                                          # Status line summarizing the cross reference.
    statusTable=>undef,                                                         # Status table summarizing the cross reference.
    summary=>1,                                                                 # Print the summary line.
    tagCount=>{},                                                               # {file}{tags} == count of the different tag names found in the xml files.
    title=>{},                                                                  # {file} = title of file
    topicIds=>{},                                                               # {file} = topic id - the id on the outermost tag.
    topicRefs=>{},                                                              # {file}{href}++ References from bookmaps to topics via appendix, chapter, topicref.
    validationErrors=>{},                                                       # True means that Lint detected errors in the xml contained in the file
    xRefs=>{},                                                                  # {file}{href}++ Xrefs references.
    xrefBadScope=>{},                                                           # External xrefs with no scope=external
    xrefBadFormat=>{},                                                          # External xrefs with no format=html
    windowsPath=>undef,                                                         # Path to be used to name files on windows in reports
    unixPath=>undef,                                                            # Path to be used to name files on unix in reports
   );
  loadHash($xref, @_);                                                          # Load attributes complaining about any invalid ones

  $xref->inputFolder or confess "Please supply a value for: inputFolder";
  $xref->inputFolder =~ s(\/*\Z) (\/)s;                                         # Cleanup path names
  $xref->windowsPath =~ s(\/*\Z) (\/)s if $xref->windowsPath;
  $xref->unixPath    =~ s(\/*\Z) (\/)s if $xref->unixPath;
  $xref->inputFolder = absFromAbsPlusRel(currentDirectory, $xref->inputFolder)  # Make input folder absolute
    if $xref->inputFolder !~ m(\A/);

  my @phases = qw(loadInputFiles analyze reportXml1 reportXml2
                  reportDuplicateIds reportDuplicateTopicIds reportNoHrefs
                  reportXrefs reportTopicRefs reportTables
                  reportConrefs reportImages reportParseFailed
                  reportAttributeCount reportTagCount reportDocTypeCount
                  reportFileExtensionCount reportFileTypes
                  reportValidationErrors reportBookMaps reportGuidHrefs
                  reportGuidsToFiles
                  reportNotReferenced reportExternalXrefs
                  reportPossibleImprovements
                  reportTopicDetails reportMd5Sum
                 );
  for my $phase(@phases)                                                        # Perform analysis phases
   {$xref->$phase;
   }

  if ($xref->fixBadRefs)                                                        # Fix files if requested
   {$xref->fixFiles;
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

    $save->(1, "badBookMaps",       q(bad book maps));                          # Status line components
    $save->(1, "badConRefs",        q(files with bad conrefs), q(file with bad conrefs));
    $save->(1, "badConRefsList",    q(bad conrefs));
    $save->(1, "badGuidHrefs",      q(invalid guid hrefs));
    $save->(1, "badImageRefs",      q(missing image references));
    $save->(1, "badTopicRefs",      q(bad topicrefs));
    $save->(1, "badTables",         q(bad tables));
    $save->(1, "badXml1",           q(bad first lines));
    $save->(1, "badXml2",           q(bad second lines));
    $save->(1, "badXRefs",          q(files with bad xrefs), q(file with bad xrefs));
    $save->(1, "badXRefsList",      q(bad xrefs));
    $save->(1, "duplicateIds",      q(duplicate ids));
    $save->(2, "duplicateTopicIds", q(duplicate topic ids));
    $save->(1, "fixedRefs",         q(references fixed), q(reference fixed));
#   $save->(2, "improvements",      q(improvements));
    $save->(1, "missingImageFiles", q(missing image files));
    $save->(1, "missingTopicIds",   q(missing topic ids));
    $save->(2, "noHref",            q(hrefs missing), q(href missing));
    $save->(1, "notReferenced",     q(files not referenced), q(file not referenced));
    $save->(1, "parseFailed",       q(files failed to parse), q(file failed to parse));
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

    if (@o and $xref->summary)                                                  # Summary line
     {say STDERR $xref->statusLine;
     }
   }

  $xref                                                                         # Return Xref results
 }

sub countLevels($$)                                                             #P Count has elements to the specified number of levels
 {my ($l, $h) = @_;                                                             # Levels, hash
  if ($l <= 1)
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

sub windowsFile($$)                                                             #P Format file name for easy use on windows
 {my ($xref, $file) = @_;                                                       # Xref, file

  if (my $w = $xref->windowsPath)
   {if (my $i = $xref->inputFolder)
     {return                     swapFilePrefix($file, $i, $w);
      return fileInWindowsFormat(swapFilePrefix($file, $i, $w));
     }
   }
  $file
 }

sub unixFile($$)                                                                #P Format file name for easy use on unix
 {my ($xref, $file) = @_;                                                       # Xref, file
  return $file; # Because we use these file names as keys and we have not got them all converted
  if (my $u = $xref->unixPath // $xref->inputFolder)
   {if (my $i = $xref->inputFolder)
     {return swapFilePrefix($file, $i, $u);
     }
   }
  $file
 }

sub formatFileNames($$$)                                                        #P Format file names for easy use on unix and windows
 {my ($xref, $array, $column) = @_;                                             # Xref, Array of arrays containing file names in unix format, column containing file names

  for my $array(@$array)
   {if (my $f = $array->[$column])
     {$array->[$column] = windowsFile($xref, $f);
      splice @$array, $column+1, 1, unixFile($xref, $f);
     }
   }
 }

sub loadInputFiles($)                                                           #P Load the names of the files to be processed
 {my ($xref) = @_;                                                              # Cross referencer
  $xref->inputFiles = [searchDirectoryTreesForMatchingFiles
    $xref->inputFolder, @{$xref->fileExtensions}];

  my @images = searchDirectoryTreesForMatchingFiles($xref->inputFolder);        # Input files
  $xref->inputFolderImages = {map {fn($_), $_} @images};                        # Image file name which works well for images because the md5 sun in their name is probably unique
 }

sub analyzeOneFile($)                                                           #P Analyze one input file
 {my ($iFile) = @_;                                                             # File to analyze
  my $xref = bless {};                                                          # Cross referencer for this file
     $xref->sourceFile = $iFile;                                                # File analyzed
  my @improvements;                                                             # Possible improvements

  $xref->md5Sum->{$iFile} = fileMd5Sum($iFile);                                 # Md5 sum for input file

  my $x = eval {Data::Edit::Xml::new($iFile, lineNumbers=>1)};                  # Parse xml

  if ($@)
   {$xref->parseFailed->{$iFile}++;
    return $xref;
   }

  $x->by(sub                                                                    # Each node
   {my ($o) = @_;

    my $content = sub                                                           #P First few characters of content on one line to avoid triggering multi table layouts
     {my ($o) = @_;                                                             # String
      nws($o->stringContent, improvementLength)
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
       {if ($h =~ m(\A(https?://|mailto:|www.))i)                               # Check attributes on external links
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
         {$xref->topicRefs->{$iFile}{$h}{$o->attr_navtitle//$o->stringText}++;
         }
       }
      else
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
       }
      else
       {push @{$xref->noHref->{$iFile}}, [$tag, $o->lineLocation, $iFile];      # No href
       }
     }
    if (my $conref = $o->attr_conref)                                           # Conref
     {$xref->conRefs->{$iFile}{$conref}++;
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
    elsif ($tag eq q(title))                                                    # Title
     {my $t = &$content;
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
    elsif ($tag eq q(author))                                                   # Author
     {$xref->author->{$iFile} = my $t = &$content;
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
        elsif ($cols != $maxCols)                                               # Cols present but wrong
         {$error->(qq(Cols attribute is $cols but should be $maxCols));
         }
       }
      elsif (($stats->maxHead//0) < $maxColsMP)                                 # Not enough headers
       {$error->(qq(Not enough headers));
       }
      else
       {$error->(qq(Column padding required));
       }
     }
   });

  push @{$xref->improvements->{$iFile}}, @improvements if @improvements;        # Save improvements

  $xref->topicIds->{$iFile} = $x->id;                                           # Topic Id
  $xref->docType ->{$iFile} = $x->tag;                                          # Document type
  $xref->attributeCount->{$iFile} = $x->countAttrNames;                         # Attribute names
  $xref->tagCount      ->{$iFile} = $x->countTagNames;                          # Tag names

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
 }

sub reportGuidsToFiles($)                                                         #P Map and report guids to files
 {my ($xref) = @_;                                                              # Xref results
  my @r;
  for   my $file(sort keys %{$xref->topicIds})                                  # Each input file which will be absolute
   {if (my $topicId = $xref->topicIds->{$file})                                 # Topic Id for file - we report missing topicIs in: reportDuplicateTopicIds
     {next unless $topicId =~ m(\AGUID-)is;
      $xref->guidToFile->{$topicId} = $file;                                    # Guid Topic Id to file
      push @r, [$topicId, $file];
     }
   }
  formatFileNames($xref, \@r,  1);                                              # Format file names for easy use on unix and windows

  formatTable(\@r, <<END,
Guid            The guid being defined
Source_Windows  The source file that defines the guid in windows format
Source_Unix     The source file that defines the guid in unix format
END
    title    =>qq(Guid topic definitions),
    head     =>qq(Xref found NNNN guid topic definitions on DDDD),
    summarize=>1,
    file     =>fpe($xref->reports, q(lists), qw(guidsToFiles txt)));
 }

sub fixOneFile($$)                                                              #P Fix one file by moving unresolved references to the xtrf attribute
 {my ($xref, $file) = @_;                                                       # Xref results, file to fix
  my @r;                                                                        # Count of tags changed

  my $x = Data::Edit::Xml::new($file);                                          # Parse xml - should parse OK else otherwise how did we find out that this file needed to be fixed

  $x->by(sub                                                                    # Each node
   {my ($o) = @_;
    my $t  = $o->tag;                                                           # Tag
    if ($t =~  m(\A(appendix|chapter|image|link|topicref|xref)\Z)is)            # Hrefs that need to be fixed
     {if (my $h = $o->href)                                                     # Fix the href by moving it to xtrf
       {if ($xref->fixRefs->{$file}{$h})
         {if ($h =~ m(\AGUID-)is)                                               # Fixable guid reference
           {if (my $f = $xref->guidToFile->{$h})                                # File associated with guid
             {$o->href = my $H = relFromAbsAgainstAbs($f, $file);               # New href
              $o->xtrf = $h;                                                    # Save original xref so we can find it with grep
              push @r, [q(File from Guid), -A $o, $H, $file];                   # Report fix
             }
            else
             {$o->renameAttr_href_xtrf;                                         # No target file for guid
              push @r, [q(No file for Guid), -A $o, q(), $file];                # Report fix
             }
           }
          else                                                                  # Move href to xtrf as no other fix seems possible
           {$o->renameAttr_href_xtrf;
            push @r, [q(Href to xtrf), -A $o, q(), $file];
           }
         }
        else                                                                    # Fix not requested so href left alone
         {push @r, [q(Fix not requested), -A $o, q(), $file];
         }
       }
      else                                                                      # No href
       {push @r, [q(No Href), -A $o, q(), $file];
       }
     }
    if (my $conref = $o->attr_conref)                                           # Fix the conref by moving it to xtrf
     {if ($xref->fixRefs->{$file}{$conref})
       {$o->renameAttr_conref_xtrf;
        push @r, [q(Moved conref to xtrf),     -A $o, $conref, $file];          # Report fix
       }
      else
       {push @r, [q(Conref fix not requested), -A $o, $conref, $file];          # Report not fixed
       }
     }
   });

  if (1)                                                                        # Replace xml in source file
   {my ($l, $L) = split m/\n/, readFile($file);
    my $t = -p $x;
    if ($l =~ m(\A<\?xml))                                                      # Check headers - should be improved
     {owf($file, qq($l\n$L\n$t));
     }
    else
     {owf($file, $t);
     }
   }

  \@r                                                                           # Return report of items fixed
 }

sub fixFiles($)                                                                 #P Fix files by moving unresolved references to the xtrf attribute
 {my ($xref) = @_;                                                              # Xref results
  my @r;                                                                        # Fixes made
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
         {push @r, $xref->fixOneFile($col);                                     # Analyze one input file
         }
        [@r]                                                                    # Return results as a reference
       });
     }

    for my $r(deSquareArray($ps->finish))                                       # Consolidate results
     {push @r, @$r;
     }
   }

  formatFileNames($xref, \@r,  3);                                              # Format file names for easy use on unix and windows

  formatTable($xref->fixedRefs = \@r, <<END,                                    # Report results
Fix            The type of fix applied
Item           The item being fixed
Target         The new target the reference has been directed to
Source_Windows The source file being fixed in windows format.
Source_Unix    The source file being fixed in unix format.
END
    title=>qq(Fixes Applied To Failing References),
    head=><<END,
Xref applied the following fixes to failing hrefs and conrefs as requested by
the fixBadRefs parameter on DDDD
END
    file=>(my $f = fpe($xref->reports, qw(lists referencesFixed txt))));
 }

sub analyze($)                                                                  #P Analyze the input files
 {my ($xref) = @_;                                                              # Cross referencer
  my @in = @{$xref->inputFiles};                                                # Input files
  my @square = squareArray(@in);                                                # Divide the task

  my $ps = newProcessStarter($xref->maximumNumberOfProcesses);                  # Process starter
     $ps->processingTitle   = q(Xref);
     $ps->totalToBeStarted  = scalar @square;
     $ps->processingLogFile = fpe($xref->reports, qw(log xref analyze txt));

  for my $row(@square)                                                          # Each row of input files file
   {$ps->start(sub
     {my @r;                                                                    # Results
      for my $col(@$row)                                                        # Each column in the row
       {push @r, analyzeOneFile($col);                                          # Analyze one input file
       }
      [@r]                                                                      # Return results as a reference
     });
   }

  for my $x(deSquareArray($ps->finish))                                         # mmmm Merge results from each file analyzed
   {for my $field(                                                              # Merge hashes by file names which are unique - ffff
      qw(parseFailed badXml1 badXml2
         ids xRefs topicRefs images conRefs topicIds
         validationErrors docType attributeCount tagCount
         xrefBadScope xrefBadFormat improvements title
         author noHref guidHrefs md5Sum))
     {next unless my $xf = $x->{$field};
      for my $f(sort keys %$xf)
       {$xref->{$field}{$f} = $xf->{$f};
       }
     }
    for my $field(                                                              # Merge arrays
      qw(badTables))
     {next unless my $xf = $x->{$field};
      push @{$xref->{$field}}, @$xf;
     }
   }
 }

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

  $xref->duplicateIds = {map {$$_[2]=>$_} @dups};                               # All duplicates

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
    file=>(my $f = fpe($xref->reports, qw(bad idDefinitionsDuplicated txt))));
 }

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
     {push @miss, [$file];                                                        # Missing topic id
     }
   }

  $xref->duplicateTopicIds = {map {$$_[0]=>$_} @dups};                          # All duplicates
  $xref->missingTopicIds   = {map {$$_[0]=>$_} @miss};                          # All missing

  formatTable(\@dups, [qw(TopicId File1 File2)],
    title=>qq(Duplicate topic id definitions),
    head=><<END,
Xref found NNNN duplicate topic id definitions on DDDD

File1, File2 are two files that both define TopicId

END
    file=>(fpe($xref->reports, qw(bad topicIdDefinitionsDuplicated txt))));

  formatTable(\@miss, [qw(File)],
    title=>qq(Topics without ids),
    head=><<END,
Xref found NNNN topics that have no topic id on DDDD

END
    file=>(fpe($xref->reports, qw(bad topicIdDefinitionsMissing txt))));
 }

sub reportNoHrefs($)                                                            #P Report locations where an href was expected but not found
 {my ($xref) = @_;                                                              # Cross referencer
  my @t;
  for my $file(sort keys %{$xref->noHref})                                      # Each input file
   {push @t,             @{$xref->noHref->{$file}};                             # Missing href details
   }

  formatFileNames($xref, \@t,  2);                                              # Format file names for easy use on unix and windows

  formatTable(\@t, <<END,
Tag            A tag that should have an xref.
Location       The location of the tag that should have an xref.
Source_Windows The source file containing the tag in windows format.
Source_Unix    The source file containing the tag in unix format.
END
    title=>qq(Missing hrefs),
    head=><<END,
Xref found NNNN tags that should have href attributes but did not on DDDD
END
    file=>(fpe($xref->reports, qw(bad missingHrefAttributes txt))));
 }

sub reportRefs($$)                                                              #P Report bad references found in xrefs or conrefs as they have the same structure
 {my ($xref, $type) = @_;                                                       # Cross referencer, type of reference to be processed

  my @bad; my @good;                                                            # Bad xrefs.
  for   my $file(sort keys %{$xref->{${type}.q(Refs)}})                         # Each input file which will be absolute
   {my $sourceTopicId = $xref->topicIds->{$file};
    for my $href(sort keys %{$xref->{${type}.q(Refs)}{$file}})                  # Each href in the file which will be relative
     {my @text;
      if (               ref($xref->{${type}.q(Refs)}{$file}{$href}))           # xRef: Text associated with reference deemed helpful by Bill
       {@text =  sort keys %{$xref->{${type}.q(Refs)}{$file}{$href}};
        s(\s+) ( )gs for @text;                                                 # Normalize white space
       }
      if ($href =~ m(#))                                                        # Href with #
       {my ($hFile, $hId) = split m(#), $href;                                  # File, topicId components
        my ($topic, $id)  = split m(/), $hId;                                   # Topic, id
                    $id //= '';

        my $target = $hFile ? absFromAbsPlusRel($file, $hFile) : $file;         # Target file absolute

        if ($hFile and !(-e $target or -e wwwDecode($target)))                  # Check target file
         {push @bad, [qq(No such file), $href,
           $hFile, $id, $topic, q(), $sourceTopicId, $file, $target, @text];
         }
        elsif (my $t = $xref->topicIds->{$target})                              # Check topic id
         {if ($t eq $topic)
           {if (my $i = $xref->ids->{$target}{$id})
             {if ($i == 1)
               {push @good,[$href, $target, $file];
               }
              else
               {push @bad, [qq(Duplicate id in topic), $href,
                 $hFile, $topic, $t, $id, $sourceTopicId, $file, $target, @text];
               }
             }
            elsif ($id)
             {push @bad, [qq(No such id in topic), $href,
                $hFile, $topic, $t, $id, $sourceTopicId, $file, $target, @text];

             }
            else
             {push @good, [$href, $target, $file];
             }
           }
          else
           {push @bad, [qq(Topic id does not match target topic), $href,
             $hFile, $topic, $id, $t, $sourceTopicId, $file, $target, @text];
           }
         }
        elsif ($topic =~ m(\S)s)                                                # The href contains a topic id but there is not topic with that id
         {push @bad, [qq(No topic id on topic in target file), $href,
           $hFile, $topic, $id, $t, $sourceTopicId, $file, $target, @text];
         }
        else
         {push @good,[$href, $target, $file];
         }
       }
      else                                                                      # No # in href
       {my $target = absFromAbsPlusRel($file, $href);
        if (!-e $target and !-e wwwDecode($target))                             # Actual file name or www encoded file name
         {push @bad, my $p = [qq(No such file), $href,
           $target, q(), q(), q(), $sourceTopicId, $file, $target, @text];
         }
        else
         {push @good, my $p = [$href, $target, $file];
         }
       }
     }
   }

  for my $bad(@bad)                                                             # List of files to fix
   {my $href = $$bad[1];
    my $file = $$bad[7];
    $xref->fixRefs->{$file}{$href}++;
   }

  my $Type = ucfirst $type;
  $xref->{q(bad).$Type.q(Refs)}  = {map {$$_[7]=>$_} @bad};                     # Bad references
  $xref->{q(good).$Type.q(Refs)} = {map {$$_[1]=>$_} @good};                    # Good references

  formatFileNames($xref, \@bad,   7);                                           # Format file names for easy use on unix and windows
  formatFileNames($xref, \@good,  1);                                           # Format file names for easy use on unix and windows

  $xref->{q(bad).$Type.q(RefsList)}  = \@bad;                                   # Bad references list
  $xref->{q(good).$Type.q(RefsList)} = \@good;                                  # Good references list

  my $in = $xref->inputFolder//'';
  formatTable(\@bad, <<END,
Reason          The reason why the conref failed to resolve
Href            The href in the source file
Href_File       The target file referenced by the href in the source files
Href_Topic_Id   The id of the topic referenced by the href in the source file
Target_Topic_Id The actual id of the topic in the target file
HRef_Id         The id of the statement in the body of the topic referenced by the href in the source file
Source_TopicId  The topic id at the top of the source file containing the bad reference
Source_Windows  The source file containing the reference in windows format
Source_Unix     The source file containing the reference in unix format
Target_File     The target file
Example_Text    Any text associated with the link such as the navtitle of a bad topicRef or the CDATA text of an xref.
END
    title    =>qq(Bad ${type}Refs),
    head     =>qq(Xref found NNNN Bad ${type}Refs on DDDD),
    summarize=>1, csv=>1,
    wide     =>1,
    file     =>(fpe($xref->reports, q(bad), qq(${Type}Refs), q(txt))));

  formatTable(\@good, <<END,
Href            The href in the source file
Source_Window   The source file containing the reference in windows format
Source_Unix     The source file containing the reference in unix format
Target_File     The target file
END
    title    =>qq(Good ${type}Refs),
    head     =>qq(Xref found NNNN Good $type refs on DDDD),
    file     =>(fpe($xref->reports, q(good), qq(${Type}Refs), q(txt))));
 } # reportRefs

sub reportGuidHrefs($)                                                          #P Report on guid hrefs
 {my ($xref) = @_;                                                              # Cross referencer

  my %guidToFile;                                                               # Map guids to files
  for   my $file(sort keys %{$xref->topicIds})                                  # Each input file containing a topic id
   {my $id = $xref->topicIds->{$file};                                          # Each href in the file which will start with guid
    next unless defined $id;
    next unless $id =~ m(\Aguid-)is;
    $guidToFile{$id} = $file;                                                   # We report duplicates in reportDuplicateTopicIds
   }

  my @bad; my @good;                                                            # Good and bad guid hrefs
  for   my $file(sort keys %{$xref->guidHrefs})                                 # Each input file which will be absolute
   {my $sourceTopicId = $xref->topicIds->{$file};
    for my $href(sort keys %{$xref->guidHrefs->{$file}})                        # Each href in the file which will start with guid
     {my ($tag, $lineLocation) = @{$xref->guidHrefs->{$file}{$href}};           # Tag of node and location in source file of node doing the referencing
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
          $xref->goodImageRefs->{$image}++;                                     # Found image
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
          $xref->goodTopicRefs->{$targetFile}++;                                # Mark reference as found
         }
       }
     }
   }

  for my $bad(@bad)                                                             # List of files to fix
   {my $href = $$bad[2];
    my $file = $$bad[-1];
    $xref->fixRefs->{$file}{$href}++ unless $xref->fixRefs->{$file}{$href};     # Avoid double counting
   }

  $xref->{badGuidHrefs}  = {map {$$_[7]=>$_} @bad};                             # Bad references
  $xref->{goodGuidHrefs} = {map {$$_[4]=>$_} @good};                            # Good references

  formatFileNames($xref, \@bad,   7);                                           # Format file names for easy use on unix and windows
  formatFileNames($xref, \@good,  4);                                           # Format file names for easy use on unix and windows

  my $in = $xref->inputFolder//'';
  formatTable(\@bad, <<END,
Reason          The reason why the href failed to resolve
Tag             The tag of the node doing the referencing
Href            The href of the node doing the referencing
Line_Location   The line location where the href occurred in the source file
Target_Topic_Id The actual id of the topic in the target file
Source_Topic_Id The topic id in the source file
Target_File     The target file
Source_Windows  The source file containing the reference in windows format
Source_Unix     The source file containing the reference in unix format
END
    title    =>qq(Unresolved GUID hrefs),
    head     =>qq(Xref found NNNN unresolved GUID hrefs on DDDD),
    summarize=>1,
    wide     =>1,
    file     =>(fpe($xref->reports, q(bad), qw(guidHrefs txt))));

  formatTable(\@good, <<END,
Href            The href in the source file
Line_Location   The line location where the href occurred in the source file
Target_File     The target file
Source_Window   The source file containing the reference in windows format
Source_Unix     The source file containing the reference in unix format
Target_File     The target file
END
    title    =>qq(Resolved GUID hrefs),
    head     =>qq(Xref found NNNN Resolved GUID hrefs on DDDD),
    file     =>(fpe($xref->reports, q(good), qw(guidHrefs txt))));
 } # reportGuidHrefs

sub reportXrefs($)                                                              #P Report bad xrefs
 {my ($xref) = @_;                                                              # Cross referencer
  reportRefs($xref, q(x));
 }

sub reportTopicRefs($)                                                          #P Report bad topic refs
 {my ($xref) = @_;                                                              # Cross referencer

  my %topicIdsToFile;                                                           # All the topic ids encountered - we have already reported the duplicates so now we can assume that there are no duplicates
  for my $file(sort keys %{$xref->topicIds})                                    # Each input file
   {if (my $topicId = $xref->topicIds->{$file})                                 # Topic Id for file - we report missing topicIs in: reportDuplicateTopicIds
     {$topicIdsToFile{$topicId} = $file;                                        # Topic Id to file
     }
   }

  my @bad; my @good;                                                            # Bad xrefs
  for   my $file(sort keys %{$xref->topicRefs})                                 # Each input file
   {my $sourceTopicId = $xref->topicIds->{$file};
    for my $href(sort keys %{$xref->topicRefs->{$file}})                        # Each topic ref in the file
     {my @text;

if ($href =~ m(#)s) # We will have to do something about this if we encounter href on topic/link ref that has # in the href.
 {cluck "# in href in topic reference requires new code";
 }
      next if $topicIdsToFile{$href};                                           # The href is satisfied by the topic id of a file containing a topic - we will assume that this has occurred as a result of renaming files and so is ok

      if (               ref($xref->topicRefs->{$file}{$href}))                 # Text associated with reference
       {@text =  sort keys %{$xref->topicRefs->{$file}{$href}};
        s(\s+) ( )gs for @text;                                                 # Normalize white space
       }

      my $f = absFromAbsPlusRel(fullFileName($file), $href);                    # Target file absolute
      if ($f)
       {if (!-e $f and !-e wwwDecode($f))                                       # Check target file
         {push @bad, my $p = [qq(No such file), $f, qq("$href"),
                             $sourceTopicId, $file, @text];
          $xref->fixRefs->{$file}{$href}++;
         }
        else
         {push @good, my $p = [$f, $href, $file];
         }
       }
     }
   }
  formatFileNames($xref, \@good, 0);                                            # Format file names for easy use on unix and windows

  $xref->badTopicRefs  = {map {$$_[1]=>$_} @bad};                               # Bad topic references
  $xref->goodTopicRefs = {map {$$_[1]=>$_} @good};                              # Good topic references

  my $in = $xref->inputFolder//'';
  formatTable(\@bad, <<END,
Reason          Reason the topic reference failed
FullFileName    Name of the targeted file
Href            Href text
Source_Topic_Id The topic id of the file containing the bad xref
Source_Windows  The source file containing the reference in windows format
Source_Unix     The source file containing the reference in unix format
Example_Text    Any text bracketed by the topic ref
END
    title    =>qq(Bad topicrefs),
    head     =>qq(Xref found NNNN Bad topicrefs on DDDD),
    summarize=>1,
    wide     =>1,
    file     =>(fpe($xref->reports, qw(bad topicRefs txt))));

  formatTable(\@good, <<END,
FullFileName  The target file name
Href          The href text in the source file
Source        The source file
END
    title=>qq(Good topicrefs),
    head=>qq(Xref found NNNN Good topicrefs on DDDD),
    file=>(fpe($xref->reports, qw(good topicRefs txt))));
 }

sub reportConrefs($)                                                            #P Report bad conrefs refs
 {my ($xref) = @_;                                                              # Cross referencer
  reportRefs($xref, q(con));
 }

sub reportImages($)                                                             #P Reports on images and references to images
 {my ($xref) = @_;                                                              # Cross referencer

  my @bad;                                                                      # Bad images
  for my $file(sort keys %{$xref->images})                                      # Each input file
   {my $sourceTopicId = $xref->topicIds->{$file};
    for my $href(sort keys %{$xref->images->{$file}})                           # Each image in the file
     {my $image = absFromAbsPlusRel($file, $href);                              # Image relative to current file
      if (-e $image or -e wwwDecode($image))                                    # Actual image name or www encoded image name
       {$xref->goodImageRefs->{$image}++;                                       # Found image
       }
      else
       {push @bad, [$href, $image, $sourceTopicId, $file];                      # Missing image reference
        $xref->badImageRefs->{$image}++;                                        # Number of missing references
        $xref->fixRefs->{$file}{$href}++;
       }
     }
   }

  $xref->missingImageFiles = [@bad];                                            # Missing image file names

  formatTable([sort {$$a[0] cmp $$b[0]} @bad], <<END,
Href            Image reference in source file
Image           Targetted image name
Source_Topic_Id The topic id of the file containing the missing image
Source          The source file containing the image reference in unix format

END
    title=>qq(Bad image references),
    head=>qq(Xref found NNNN bad image references on DDDD),
    summarize=>1,
    file=>(my $f = fpe($xref->reports, qw(bad imageRefs txt))));

  my $found = [map {[$xref->goodImageRefs->{$_}, $_]}
              keys %{$xref->goodImageRefs}];

  formatTable($found, <<END,
Count          Number of references to each image file found.
ImageFileName  Full image file name
END
    title=>qq(Image files),
    head=>qq(Xref found NNNN image files found on DDDD),
    file=>(fpe($xref->reports, qw(good imagesFound txt))));

  my $missing = [map {[$xref->badImageRefs->{$_}, $_]}
                 sort keys %{$xref->badImageRefs}];

  formatTable($missing, <<END,
Count          Number of references to each image file found.
ImageFileName  Full image file name
END
    title=>qq(Missing image references),
    head=>qq(Xref found NNNN images missing on DDDD),
    file=>(fpe($xref->reports, qw(bad imagesMissing txt))));
 }

sub reportParseFailed($)                                                        #P Report failed parses
 {my ($xref) = @_;                                                              # Cross referencer

  formatTable($xref->parseFailed, <<END,
Source The file that failed to parse in unix format
END
    title=>qq(Files failed to parse),
    head=>qq(Xref found NNNN files failed to parse on DDDD),
    file=>(my $f = fpe($xref->reports, qw(bad parseFailed txt))));
 }

sub reportXml1($)                                                            #P Report bad xml on line 1
 {my ($xref) = @_;                                                              # Cross referencer


  formatTable([sort keys %{$xref->badXml1}], <<END,
Source  The source file containing bad xml on line
END
    title=>qq(Bad Xml line 1),
    head=>qq(Xref found NNNN Files with the incorrect xml on line 1 on DDDD),
    file=>(my $f = fpe($xref->reports, qw(bad xmlLine1 txt))));
 }

sub reportXml2($)                                                            #P Report bad xml on line 2
 {my ($xref) = @_;                                                              # Cross referencer

  formatTable([sort keys %{$xref->badXml2}], <<END,
Source  The source file containing bad xml on line
END
    title=>qq(Bad Xml line 2),
    head=>qq(Xref found NNNN Files with the incorrect xml on line 2 on DDDD),
    file=>(my $f = fpe($xref->reports, qw(bad xmlLine2 txt))));
 }

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
 }

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
 }

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
 }

sub reportValidationErrors($)                                                   #P Report the files known to have validation errors
 {my ($xref) = @_;                                                              # Cross referencer

  formatTable([map {[$_]} sort keys %{$xref->validationErrors}], [qw(File)],
    title=>qq(Topics with validation errors),
    head=><<END,
Xref found NNNN topics with validation errors on DDDD
END
    file=>(fpe($xref->reports, qw(bad validationErrors txt))));
 }

sub checkBookMap($$)                                                            #P Check whether a bookmap is valid or not
 {my ($xref, $bookMap) = @_;                                                    # Cross referencer, bookmap

  for my $href($bookMap, sort keys %{$xref->topicRefs->{$bookMap}})             # Each topic ref in the bookmap
   {my $t = absFromAbsPlusRel($bookMap, $href);
    for my $field                                                               # Fields that report errors
     (qw(parseFailed badXml1 badXml2 badTopicRefs badXRefs
         imagesMissing badConRefs missingTopicIds
         validationErrors))
     {if ($xref->{$field}->{$t})
       {return [$field, $xref->topicIds->{$bookMap}, $bookMap, $href, $t];
       }
     }
   }
  undef                                                                         # No errors
 }

sub reportBookMaps($)                                                           #P Report on whether each bookmap is good or bad
 {my ($xref) = @_;                                                              # Cross referencer

  my @bad;
  my @good;
  for my $f(sort keys %{$xref->docType})
   {if ($xref->docType->{$f} =~ m(map\Z)s)
     {if (my $r = $xref->checkBookMap($f))
       {push @bad, $r;
       }
      else
       {push @good, [$f];
       }
     }
   }
  $xref-> badBookMaps = [@bad];                                                 # Bad bookmaps
  $xref->goodBookMaps = [@good];                                                # Good book maps

  formatTable(\@bad, <<END,
Reason          Reason bookmap failed
Source_Topic_Id The topic id of the failing bookmap
Bookmap         Bookmap source file name
Topic_Ref       Failing appendix, chapter or topic ref.
Topic_File      Targeted topic file if known
END
    title=>qq(Bookmaps with errors),
    head=><<END,
Xref found NNNN bookmaps with errors on DDDD
END
    summarize=>1,
    file=>(fpe($xref->reports, qw(bad bookMap txt))));

  formatTable(\@good, [qw(File)],
    title=>qq(Good bookmaps),
    head=><<END,
Xref found NNNN good bookmaps on DDDD
END
    file=>(fpe($xref->reports, qw(good bookMap txt))));
 }

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
 }

sub reportFileExtensionCount($)                                                 #P Report file extension counts
 {my ($xref) = @_;                                                              # Cross referencer

  formatTable(countFileExtensions($xref->inputFolder), [qw(Ext Count)],
    title=>qq(File extensions),
    head=><<END,
Xref found NNNN different file extensions on DDDD
END
    file=>(fpe($xref->reports, qw(count fileExtensions txt))));
 }

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
 }

sub reportNotReferenced($)                                                      #P Report files not referenced by any of conref, image, topicref, xref and are not bookmaps.
 {my ($xref) = @_;                                                              # Cross referencer

  my %files = map {$_=>1}
    searchDirectoryTreesForMatchingFiles($xref->inputFolder);

  my %target;                                                                   # Targets of xrefs and conrefs
  $target{$xref->{goodConRefs}{$_}[2]}++ for keys %{$xref->{goodConRefs}};
  $target{$xref->{goodXRefs}  {$_}[2]}++ for keys %{$xref->{goodXRefs}};

  for my $file(sort keys %{$xref->goodImageRefs},                               # Remove referenced files
               sort keys %{$xref->goodTopicRefs},
               sort keys %target,
              )
   {delete $files{$file};
   }

  for my $file(sort keys %{$xref->docType})                                     # Remove bookmaps from consideration as they are not usually referenced
   {my $tag = $xref->docType->{$file};
    if ($tag =~ m(\Abookmap\Z)is)
     {delete $files{$file};
     }
   }

  $xref->notReferenced = \%files;
  formatTable([sort keys %files],
   [qw(FileNo Unreferenced)],
    title=>qq(Unreferenced files),
    head=><<END,
Xref found NNNN unreferenced files on DDDD.

These files are not mentioned in any href attribute and are not bookmaps.

END
    file=>(my $f = fpe($xref->reports, qw(bad notReferenced txt))));
 }

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

  formatFileNames($xref, \@s, 4);                                               # Format file names for easy use on unix and windows

  formatTable(\@s, <<END,
Reason          The reason why the xref is unsatisfactory
Href            The href attribute of the xref in question
Xref_Statement  The xref statement in question
Source_Topic_Id The topic id of the source file containing file containing the bad external xref
File            The file containing the xref statement in question
File_Windows    The source file containing the xref statement in question in windows format
File_Unix       The source file containing the xref statement in question in unix format
END
    title=>qq(Bad external xrefs),
    head=>qq(Xref found bad external xrefs on DDDD),
    file=>(my $f = fpe($xref->reports, qw(bad externalXrefs txt))));
 }

sub reportPossibleImprovements($)                                               #P Report improvements possible
 {my ($xref) = @_;                                                              # Cross referencer

  my @S;
  for   my $i(sort keys %{$xref->improvements})
   {push @S, @{$xref->improvements->{$i}};
   }

  formatFileNames($xref, \@S, 3);                                               # Format file names for easy use on unix and windows

  my @s = sort {$$a[0] cmp $$b[0]}
          sort {$$a[3] cmp $$b[3]} @S;

  formatTable(\@s, <<END,
Improvement     The improvement that might be made.
Text            The text that suggested the improvement.
Line_Number     The line number at which the improvement could be made.
Source_Windows  The file in which the improvement could be made.
Source_Unix     The file in which the improvement could be made.
END
    title=>qq(Possible improvements),
    head=><<END,
Xref found NNNN opportunities for improvements that might be
made on DDDD
END
    file=>(fpe($xref->reports, qw(improvements txt))),
    summarize=>1);
 }

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

  formatFileNames($xref, \@t, 4);                                               # Format file names for easy use on unix and windows

  formatTable(\@t, <<END,
Tag             The outermost tag
Id              The id on the outermost tag
Author          The author of the topic
Title           The title of the topic
Source_Windows  The source file name in windows format
Source_Unix     The source file name in unix format
END
    title=>qq(Topics),
    head=><<END,
Xref found NNNN topics on DDDD
END
    file=>(fpe($xref->reports, qw(lists topics txt))),
    summarize=>1);
 }

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

  formatFileNames($xref, \@bad,  2);                                            # Format file names for easy use on unix and windows
  formatFileNames($xref, \@good, 2);

  formatTable(\@bad, <<END,
Md5_Sum           The md5 sum in question
Short_File_Name   The short name of the file
File_Name_Windows The file name in windows format
File_Name_Unix    The file name in unix format
END
    title=>qq(Files whose short names that are not one to one with their md5 sums),
    head=><<END,
Xref found NNNN such files on DDDD
END
    file=>(fpe($xref->reports, qw(bad shortNameToMd5Sum txt))),
    summarize=>1);

  formatTable(\@good, <<END,
Md5_Sum           The md5 sum in question
Short_File_Name   The short name of the file
File_Name_Windows The file name in windows format
File_Name_Unix    The file name in unix format
END
    title=>qq(Files whose short names that are one to one with their md5 sums),
    head=><<END,
Xref found NNNN such files on DDDD
END
    file=>(fpe($xref->reports, qw(good shortNameToMd5Sum txt))),
    summarize=>1);
 }

sub createSampleInputFiles($)                                                   #P Create sample input files for testing. The attribute B<inputFolder> supplies the name of the folder in which to create the sample files.
 {my ($N) = @_;                                                                 # Number of sample files
  my $in = q(in);
  clearFolder($in, 20);
  for my $n(1..$N)
   {my $o = $n + 1; $o -= $N if $o > $N;
    my $f = owf(fpe($in, $n, q(dita)), <<END);
<concept id="c$n">
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
    <image href="act1.dita"/>
    <xref/>
  </conbody>
</concept>
END

  owf(fpe($in, qw(act2 dita)), <<END);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd">
<concept id="c2">
  <title id="title">Jumping Through Hops</title>
  <conbody>
    <section>
      <title/>
      <xref  format="dita" href="act1.dita#c1/title"/>
      <note  conref="act2.dita#c2/title"/>
      <xref  format="dita" href="9999#c1/title"/>
      <xref  format="dita" href="guid-000#guid-000/title"/>
      <xref  format="dita" href="guid-000#guid-000/title2"/>
      <xref  format="dita" href="guid-000#c1/title2"/>
      <xref  format="dita" href="guid-999#c1/title2"/>
      <xref  href="http://"/>
      <image href="9999.png"/>
      <link href="guid-000"/>
      <link href="guid-999"/>
      <link href="act1.dita"/>
      <link href="act9999.dita"/>
      <p conref="9999.dita"/>
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
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []>
<concept id="table">
  <title>Tables</title>
  <conbody>
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
  createEmptyFile(fpe($in, qw(a1 png)));
 }

#D
# podDocumentation
=pod

=encoding utf-8

=head1 Name

Data::Edit::Xml::Xref - Cross reference Dita XML.

=head1 Synopsis

Check the references in a set of Dita XML documents held in folder
L<inputFolder|/inputFolder>:

  use Data::Edit::Xml::Xref;

  my $x = xref(inputFolder=>q(in));
  ok nws($x->statusLine) eq nws(<<END);
Xref:
 10 bad first lines,
 10 bad second lines,
  9 bad conrefs,
  9 bad xrefs,
  8 duplicate ids,
  8 missing image files,
  8 missing image references,
  3 bad topicrefs,
  2 duplicate topic ids,
  1 bad book map,
  1 file failed to parse,
  1 file not referenced
END

The counts listed in the L<statusLine|/statusLine> are the counts of the files
that have the described problems not a count of all the instances of the
problem in all the files which would be larger.

More detailed reports are produced in the  L<reports|/reports> folder:

  $x->reports

=head1 Description

Cross reference Dita XML.


Version 20190121.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Cross reference

Check the cross references in a set of Dita files and report the results.

=head2 xref(%)

Check the cross references in a set of Dita files held in  L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder. The possible attributes are defined in L<Data::Edit::Xml::Xref|/Data::Edit::Xml::Xref>

     Parameter    Description
  1  %attributes  Attributes

B<Example:>


    my $N = 8;                                                                    
  


=head1 Hash Definitions




=head2 Data::Edit::Xml::Xref Definition


Attributes used by the Xref cross referencer.


B<attributeCount> - {file}{attribute} == count of the different xml attributes found in the xml files.

B<author> - {file} = author of file

B<badBookMaps> - Bad book maps

B<badConRefs> - {sourceFile} = [file, href] indicating the file has at least one bad conref

B<badConRefsList> - Bad conrefs - by file

B<badGuidHrefs> - Bad conrefs - all

B<badImageRefs> - Consolidated images missing.

B<badTables> - Array of tables that need fixing

B<badTopicRefs> - [file, href]   Invalid href attributes found on topicref tags.

B<badXRefs> - Bad Xrefs - by file

B<badXRefsList> - Bad Xrefs - all

B<badXml1> - [Files] with a bad xml encoding header on the first line.

B<badXml2> - [Files] with a bad xml doc type on the second line.

B<conRefs> - {file}{href}   Count of conref definitions in each file.

B<docType> - {file} == docType:  the docType for each xml file.

B<duplicateIds> - [file, id]     Duplicate id definitions within each file.

B<duplicateTopicIds> - [topicId, [files]] Files with duplicate topic ids - the id on the outermost tag.

B<fileExtensions> - Default file extensions to load

B<fixBadRefs> - Try to fix bad references in L<these files|/fixRefs> where possible by either changing a guid to a file name assuming the right file is present or failing that by moving the failing reference to the "xtrf" attribute.

B<fixRefs> - {file}{ref} where the href or conref target is not present.

B<fixedRefs> - [] hrefs and conrefs from L<fixRefs|/fixRefs which have been ameliorated where possible by either changing a guid to a file name assuming the right file is present or failing that by moving the failing reference to the "xtrf" attribute.

B<goodBookMaps> - Good book maps

B<goodConRefs> - Good con refs - by file

B<goodConRefsList> - Good con refs - all

B<goodGuidHrefs> - {file}{href}{location}++ where a href that starts with GUID- has been correctly resolved

B<goodImageRefs> - Consolidated images found.

B<goodTopicRefs> - Good topic refs

B<goodXRefs> - Good xrefs - by file

B<goodXRefsList> - Good xrefs - all

B<guidHrefs> - {file}{href} = location where href starts with GUID- and is thus probably a guid

B<guidToFile> - {topic id which is a guid} = file defining topic id

B<ids> - {file}{id}     Id definitions across all files.

B<images> - {file}{href}   Count of image references in each file.

B<improvements> - Improvements needed

B<inputFiles> - Input files from L<inputFolder|/inputFolder>.

B<inputFolder> - A folder containing the dita and ditamap files to be cross referenced.

B<inputFolderImages> - {filename} = full file name which works well for images because the md5 sum in their name is probably unique

B<maximumNumberOfProcesses> - Maximum number of processes to run in parallel at any one time.

B<md5Sum> - MD5 sum for each input file

B<missingImageFiles> - [file, href] == Missing images in each file.

B<missingTopicIds> - Missing topic ids

B<noHref> - Tags that should have an href but do not have one

B<notReferenced> - Files in input area that are not referenced by a conref, image, topicref or xref tag and are not a bookmap.

B<parseFailed> - [file] files that failed to parse

B<reports> - Reports folder: the cross referencer will write reports to files in this folder.

B<results> - Summary of results table

B<sourceFile> - The source file from which this structure was generated

B<statusLine> - Status line summarizing the cross reference.

B<statusTable> - Status table summarizing the cross reference.

B<summary> - Print the summary line.

B<tagCount> - {file}{tags} == count of the different tag names found in the xml files.

B<title> - {file} = title of file

B<topicIds> - {file} = topic id - the id on the outermost tag.

B<topicRefs> - {file}{href}++ References from bookmaps to topics via appendix, chapter, topicref.

B<unixPath> - Path to be used to name files on unix in reports

B<validationErrors> - True means that Lint detected errors in the xml contained in the file

B<windowsPath> - Path to be used to name files on windows in reports

B<xRefs> - {file}{href}++ Xrefs references.

B<xrefBadFormat> - External xrefs with no format=html

B<xrefBadScope> - External xrefs with no scope=external



=head1 Attributes


The following is a list of all the attributes in this package.  A method coded
with the same name in your package will over ride the method of the same name
in this package and thus provide your value for the attribute in place of the
default value supplied for this attribute by this package.

=head2 Replaceable Attribute List


improvementLength 


=head2 improvementLength

Improvement length




=head1 Private Methods

=head2 lll(@)

Write a message

     Parameter  Description
  1  @m         Message text

=head2 countLevels($$)

Count has elements to the specified number of levels

     Parameter  Description
  1  $l         Levels
  2  $h         Hash

=head2 windowsFile($$)

Format file name for easy use on windows

     Parameter  Description
  1  $xref      Xref
  2  $file      File

=head2 unixFile($$)

Format file name for easy use on unix

     Parameter  Description
  1  $xref      Xref
  2  $file      File

=head2 formatFileNames($$$)

Format file names for easy use on unix and windows

     Parameter  Description
  1  $xref      Xref
  2  $array     Array of arrays containing file names in unix format
  3  $column    Column containing file names

=head2 loadInputFiles($)

Load the names of the files to be processed

     Parameter  Description
  1  $xref      Cross referencer

=head2 analyzeOneFile($)

Analyze one input file

     Parameter  Description
  1  $iFile     File to analyze

=head2 reportGuidsToFiles($)

Map and report guids to files

     Parameter  Description
  1  $xref      Xref results

=head2 fixOneFile($$)

Fix one file by moving unresolved references to the xtrf attribute

     Parameter  Description
  1  $xref      Xref results
  2  $file      File to fix

=head2 fixFiles($)

Fix files by moving unresolved references to the xtrf attribute

     Parameter  Description
  1  $xref      Xref results

=head2 analyze($)

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

=head2 reportRefs($$)

Report bad references found in xrefs or conrefs as they have the same structure

     Parameter  Description
  1  $xref      Cross referencer
  2  $type      Type of reference to be processed

=head2 reportGuidHrefs($)

Report on guid hrefs

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportXrefs($)

Report bad xrefs

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportTopicRefs($)

Report bad topic refs

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportConrefs($)

Report bad conrefs refs

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

=head2 reportAttributeCount($)

Report attribute counts

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportValidationErrors($)

Report the files known to have validation errors

     Parameter  Description
  1  $xref      Cross referencer

=head2 checkBookMap($$)

Check whether a bookmap is valid or not

     Parameter  Description
  1  $xref      Cross referencer
  2  $bookMap   Bookmap

=head2 reportBookMaps($)

Report on whether each bookmap is good or bad

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

=head2 reportNotReferenced($)

Report files not referenced by any of conref, image, topicref, xref and are not bookmaps.

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

=head2 reportTopicDetails($)

Things that occur once in each file

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportMd5Sum($)

Good files have short names which uniquely represent their content and thus can be used instead of their md5sum to generate unique names

     Parameter  Description
  1  $xref      Cross referencer

=head2 createSampleInputFiles($)

Create sample input files for testing. The attribute B<inputFolder> supplies the name of the folder in which to create the sample files.

     Parameter  Description
  1  $N         Number of sample files


=head1 Index


1 L<analyze|/analyze> - Analyze the input files

2 L<analyzeOneFile|/analyzeOneFile> - Analyze one input file

3 L<checkBookMap|/checkBookMap> - Check whether a bookmap is valid or not

4 L<countLevels|/countLevels> - Count has elements to the specified number of levels

5 L<createSampleInputFiles|/createSampleInputFiles> - Create sample input files for testing.

6 L<fixFiles|/fixFiles> - Fix files by moving unresolved references to the xtrf attribute

7 L<fixOneFile|/fixOneFile> - Fix one file by moving unresolved references to the xtrf attribute

8 L<formatFileNames|/formatFileNames> - Format file names for easy use on unix and windows

9 L<lll|/lll> - Write a message

10 L<loadInputFiles|/loadInputFiles> - Load the names of the files to be processed

11 L<reportAttributeCount|/reportAttributeCount> - Report attribute counts

12 L<reportBookMaps|/reportBookMaps> - Report on whether each bookmap is good or bad

13 L<reportConrefs|/reportConrefs> - Report bad conrefs refs

14 L<reportDocTypeCount|/reportDocTypeCount> - Report doc type count

15 L<reportDuplicateIds|/reportDuplicateIds> - Report duplicate ids

16 L<reportDuplicateTopicIds|/reportDuplicateTopicIds> - Report duplicate topic ids

17 L<reportExternalXrefs|/reportExternalXrefs> - Report external xrefs missing other attributes

18 L<reportFileExtensionCount|/reportFileExtensionCount> - Report file extension counts

19 L<reportFileTypes|/reportFileTypes> - Report file type counts - takes too long in series

20 L<reportGuidHrefs|/reportGuidHrefs> - Report on guid hrefs

21 L<reportGuidsToFiles|/reportGuidsToFiles> - Map and report guids to files

22 L<reportImages|/reportImages> - Reports on images and references to images

23 L<reportMd5Sum|/reportMd5Sum> - Good files have short names which uniquely represent their content and thus can be used instead of their md5sum to generate unique names

24 L<reportNoHrefs|/reportNoHrefs> - Report locations where an href was expected but not found

25 L<reportNotReferenced|/reportNotReferenced> - Report files not referenced by any of conref, image, topicref, xref and are not bookmaps.

26 L<reportParseFailed|/reportParseFailed> - Report failed parses

27 L<reportPossibleImprovements|/reportPossibleImprovements> - Report improvements possible

28 L<reportRefs|/reportRefs> - Report bad references found in xrefs or conrefs as they have the same structure

29 L<reportTables|/reportTables> - Report on tables that have problems

30 L<reportTagCount|/reportTagCount> - Report tag counts

31 L<reportTopicDetails|/reportTopicDetails> - Things that occur once in each file

32 L<reportTopicRefs|/reportTopicRefs> - Report bad topic refs

33 L<reportValidationErrors|/reportValidationErrors> - Report the files known to have validation errors

34 L<reportXml1|/reportXml1> - Report bad xml on line 1

35 L<reportXml2|/reportXml2> - Report bad xml on line 2

36 L<reportXrefs|/reportXrefs> - Report bad xrefs

37 L<unixFile|/unixFile> - Format file name for easy use on unix

38 L<windowsFile|/windowsFile> - Format file name for easy use on windows

39 L<xref|/xref> - Check the cross references in a set of Dita files held in  L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Data::Edit::Xml::Xref

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
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>1;

my $windows = $^O =~ m(MSWin32)is;
my $mac     = $^O =~ m(darwin)is;

Test::More->builder->output("/dev/null")                                        # Show only errors during testing
  if ((caller(1))[0]//'Data::Edit::Xml::Xref') eq "Data::Edit::Xml::Xref";

if (!$windows) {
if (1) {
  my $N = 8;                                                                    #Txref
  clearFolder(q(reports), 33);
  createSampleInputFiles($N);
  my $x = xref(inputFolder=>q(in), fixBadRefs=>1, maximumNumberOfProcesses=>2,
               windowsPath=>q(c:/win));
  ok nws($x->statusLine) eq nws(<<END);
Xref: 133 references fixed, 50 bad xrefs, 16 missing image files, 16 missing image references, 13 bad first lines, 13 bad second lines, 9 bad conrefs, 9 duplicate topic ids, 9 files with bad conrefs, 9 files with bad xrefs, 8 duplicate ids, 6 bad topicrefs, 6 files not referenced, 4 invalid guid hrefs, 2 bad book maps, 2 bad tables, 1 External xrefs with no format=html, 1 External xrefs with no scope=external, 1 file failed to parse, 1 href missing
END
  say STDERR $x->statusTable;
# say STDERR "AAAA ", dump($x->notReferenced);
 }
 }
else
 {ok 1 for 1..1;
 }

1


