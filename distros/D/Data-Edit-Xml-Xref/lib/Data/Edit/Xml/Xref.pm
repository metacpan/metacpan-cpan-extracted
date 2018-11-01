#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib
#-------------------------------------------------------------------------------
# Cross reference Dita XML.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2018
#-------------------------------------------------------------------------------
# podDocumentation
# Handle url encoded file names such as blank to %20?
# Handle relative files in hrefs, conrefs etc.

package Data::Edit::Xml::Xref;
our $VERSION = 20181101;
use v5.20;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Edit::Xml;
use Data::Table::Text qw(:all);
use utf8;

#D1 Cross reference                                                             # Check the cross references in a set of Dita files and report the results.

sub xref(%)                                                                     # Check the cross references in a set of Dita files held in  L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder. The possible atributes are defined in L<Data::Edit::Xml::Xref|/Data::Edit::Xml::Xref>
 {my (%attributes) = @_;                                                        # Attributes
  my $xref = genHash(__PACKAGE__,                                               # Attributes used by cross referencer.
    badImageRefs=>[],                                                           # [file, href]   Missing images.
    badXml1=>[],                                                                # Files with a bad xml encoding header on the first line.
    badXml2=>[],                                                                # Files with a bad xml doc type on the second line.
    badXRefs=>[],                                                               # [file, href]   Invalid href attributes on xref tags.
    badTopicRefs=>[],                                                           # [file, href]   Invalid href attributes topicref tags.
    badConRefs=>[],                                                             # [file, href]   Invalid conref attributes.
    conRefs=>{},                                                                # {file}{id}++   Conref definitions.
    duplicateIds=>[],                                                           # [file, id]     Duplicate id definitions within a file.
    ids=>{},                                                                    # {file}{id}++   Id definitions across all files.
    images=>{},                                                                 # {file}{href}++ Images references.
    imagesFound=>{},                                                            # Consolidated images found
    imagesMissing=>{},                                                          # Consolidated images missing
    inputFiles=>[],                                                             # Input files from L<inputFolder|/inputFolder>.
    inputFolder=>undef,                                                         # A folder containing the dita and ditamap files to be cross referenced.
    parseFailed=>[],                                                            # [file] files that failed to parse
    topicRefs=>{},                                                              # {file}{href}++ Topic references.
    xRefs=>{},                                                                  # {file}{href}++ Xrefs references.
    results=>[],                                                                # Results table
    reports=>q(reports),                                                        # Reports folder: the cross referencer will write reports to files in this folder.
    statusLine=>undef,                                                          # Status line summarizing the cross reference.
    summary=>1,                                                                 # Print the summary line.
    topicIds=>{},                                                               # {file} = topic id
    duplicateTopicIds=>[],                                                      # [topicId, [files]] Files with duplicate topic ids
    maximumNumberOfProcesses=>4,                                                # Maximum number of processes to run
   );
  loadHash($xref, @_);                                                          # Load attributes complaining about any invalid ones

  $xref->inputFolder = absFromAbsPlusRel(currentDirectory, $xref->inputFolder)  # Make input folder absolute
    if $xref->inputFolder !~ m(\A/);

  my @phases = qw(loadInputFiles analyze reportBadXml1 reportBadXml2
                  reportDuplicateIds reportBadXrefs reportBadTopicRefs
                  reportBadConrefs reportImages reportParseFailed);
  for my $phase(@phases)                                                        # Perform analysis phases
   {$xref->$phase;
   }

  if (1)                                                                        # Summarize
   {my $i = @{$xref->badImageRefs};
    my $t = @{$xref->badTopicRefs};
    my $x = @{$xref->badXRefs};
    my $c = @{$xref->badConRefs};
    my $d = @{$xref->duplicateIds};
    my $b = @{$xref->badXml1};
    my $B = @{$xref->badXml2};
    my $I = keys %{$xref->imagesFound};
    my $M = keys %{$xref->imagesMissing};
    my $p = @{$xref->parseFailed};
    my @o;
    push @o, [$p, q(files failed to parse)] if $p >  1;
    push @o, [$p, q(file failed to parse)]  if $p == 1;
    push @o, [$x, q(bad xrefs)]             if $x >  1;
    push @o, [$x, q(bad xref)]              if $x == 1;
    push @o, [$c, q(bad conrefs)]           if $c >  1;
    push @o, [$c, q(bad conref)]            if $c == 1;
    push @o, [$t, q(bad topicrefs)]         if $t >  1;
    push @o, [$t, q(bad topicref)]          if $t == 1;
    push @o, [$i, q(missing image refs)]    if $i >  1;
    push @o, [$i, q(missing image ref)]     if $i == 1;
#   push @o, [$I, q(image files found)]     if $I >  1;
#   push @o, [$I, q(image file found)]      if $I == 1;
    push @o, [$M, q(missing image files)]   if $M >  1;
    push @o, [$M, q(missing image file)]    if $M == 1;
    push @o, [$d, q(duplicate ids)]         if $d >  1;
    push @o, [$d, q(duplicate id)]          if $d == 1;
    push @o, [$b, q(bad first lines)]       if $b >  1;
    push @o, [$b, q(bad first line)]        if $b == 1;
    push @o, [$B, q(bad second lines)]      if $B >  1;
    push @o, [$B, q(bad second line)]       if $B == 1;
    $xref->statusLine = @o ? join " ",
      "Xref Errors:", join ", ", map {join " ", @$_} @o : q();
    $xref->results    = \@o;
    if (@o and $xref->summary)
     {say STDERR $xref->statusLine;
     }
   }

  $xref
 }

sub loadInputFiles($)                                                           #P Load the names of the files to be processed
 {my ($xref) = @_;                                                              # Cross referencer
  $xref->inputFiles = [searchDirectoryTreesForMatchingFiles
    $xref->inputFolder, qw(.dita .ditamap .xml)];
 }

sub analyzeOneFile($)                                                           #P Analyze one input file
 {my ($iFile) = @_;                                                             # File to analyze
  my $xref = bless {};                                                          # Cross referencer for this file

  my $x = eval {Data::Edit::Xml::new($iFile)};                                  # Parse xml

  if ($@)
   {push @{$xref->parseFailed}, [$iFile];
    return $xref;
   }

  $x->by(sub                                                                    # Each node
   {my ($o) = @_;
    if (my $i = $o->id)                                                         # Id definitions
     {$xref->ids->{$iFile}{$i}++;
     }
    if ($o->at_xref)                                                            # Xrefs but not to the web
     {if (my $h = $o->href)
       {if ($h !~ m(\A(https?://|mailto:))i)
         {$xref->xRefs->{$iFile}{$h}++;
         }
       }
     }
    elsif ($o->at_topicref)                                                     # TopicRefs
     {if (my $h = $o->href)
       {$xref->topicRefs->{$iFile}{$h}++;
       }
     }
    elsif ($o->at(qw(image)))                                                   # Images
     {if (my $h = $o->href)
       {$xref->images->{$iFile}{$h}++;
       }
     }
    if (my $conref = $o->attr_conref)                                           # Conref
     {$xref->conRefs->{$iFile}{$conref}++;
     }
   });

  $xref->topicIds->{$iFile} = $x->id;                                           # Topic Id

  if (1)                                                                        # Check xml headers
   {my @h = split /\n/, readFile($iFile);
    if (!$h[0] or $h[0] !~ m(\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?>\Z))
     {push @{$xref->badXml1}, $iFile;
     }
    my $tag = $x->tag;
    if (!$h[1] or $h[1] !~ m(\A<!DOCTYPE $tag PUBLIC "-//))
     {push @{$xref->badXml2}, $iFile;
     }
   }

  $xref
 }

sub analyze($)                                                                  #P Analyze the input files
 {my ($xref) = @_;                                                              # Cross referencer

  my $process = temporaryFolder;
  my $ps = newProcessStarter($xref->maximumNumberOfProcesses, $process);        # Process starter

  my @in = @{$xref->inputFiles};                                                # Input files
  for my $iFile(@in)                                                            # Each input file
   {$ps->start(sub{analyzeOneFile($iFile)});                                    # Analyze one input file
   }

  for my $x($ps->finish)                                                        # Merge results from each file analyzed
   {for my $field(qw(parseFailed badXml1 badXml2))                              # Merge arrays
     {next unless my $xf = $x->{$field};
      push @{$xref->{$field}}, @$xf;
     }

    for my $field(qw(ids xRefs topicRefs images conRefs topicIds))              # Merge hashes
     {next unless my $xf = $x->{$field};
      for my $f(sort keys %$xf)
       {$xref->{$field}{$f} = $xf->{$f};
       }
     }
   }

  clearFolder($process, scalar @in);
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

  $xref->duplicateIds = \@dups;                                                 # All duplicates

  formatTable(\@dups, [qw(Id Count File)],
    head=>qq(Data::Edit::Xml::Xref found NNNN duplicate id definitions on DDDD),
    file=>(my $f = fpe($xref->reports, qw(duplicateIdDefinitions txt))));
 }

sub reportBadRefs($$)                                                           #P Report bad references found in xrefs or conrefs as they have the same structure
 {my ($xref, $type) = @_;                                                       # Cross referencer, type of reference to be processed

  my @bad; my @good;                                                            # Bad xrefs
  for   my $file(sort keys %{$xref->{${type}.q(Refs)}})                         # Each input file which will be absolute
   {for my $href(sort keys %{$xref->{${type}.q(Refs)}->{$file}})                # Each href in the file which will be relative
     {if ($href =~ m(#))                                                        # Href with #
       {my ($hFile, $hId) = split m(#), $href;                                  # File, topicId components
        my ($topic, $id)  = split m(/), $hId;                                   # Topic, id
                    $id //= '';
        my $fFile = $hFile ? absFromAbsPlusRel($file, $hFile) : $file;          # Target file absolute
        if ($hFile and !(-e $fFile or -e wwwDecode($fFile)))                    # Check target file
         {push @bad, [qq(No such file), $href,
           $hFile, $id, $topic, q(), $fFile, $file];
         }

        elsif (my $t = $xref->topicIds->{$fFile})                               # Check topic id
         {if ($t eq $topic)
           {if (my $i = $xref->ids->{$fFile}{$id})
             {if ($i == 1)
               {push @good,[$href, $fFile, $file];
               }
              else
               {push @bad, [qq(Duplicate id in topic), $href,
                 $hFile, $topic, $t, $id, $file, $fFile];
               }
             }
            elsif ($id)
             {push @bad, [qq(No such id in topic), $href,
                $hFile, $topic, $t, $id, $file, $t, $fFile];

             }
            else
             {push @good, [$href, $fFile, $file];
             }
           }
          else
           {push @bad, [qq(Topic id mismatch), $href,
             $hFile, $topic, $id, $t, $file, $t, $fFile];
           }
         }
        elsif ($topic)
         {push @bad, [qq(No topic id on topic in target file), $href,
           $hFile, $topic, $id, $t, $file, $t, $fFile];
         }
        else
         {push @good,[$href, $fFile, $file];
         }
       }
      else                                                                      # No # in href
       {my $fFile = absFromAbsPlusRel($file, $href);
        if (!-e $fFile and !-e wwwDecode($fFile))                               # Actual file name or www encoded file name
         {push @bad, [qq(No such file), $href,
           $fFile, q(), q(), q(), $file, $fFile];
         }
        else
         {push @good,[$href, $fFile, $file];
         }
       }
     }
   }

  my $Type = ucfirst $type;
  $xref->{my $t = q(bad).$Type.q(Refs)} = \@bad;                                # Bad references

  my $in = $xref->inputFolder//'';
  formatTable(\@bad, [qw(Reason Href Href-File Href-Topic-Id Target-Topic-Id
                         HRef-Id Source-File Target-File)],
    head=><<END,
NNNN Bad $type refs relative to folder $in on DDDD

Reason          The reason why the conref failed to resolve
Href            The href in the source file
Href-File       The target file referenced by the href in the source files
Href-Topic-Id   The id of the topic referenced by the href in the source file
Target-Topic-Id The actual id of the topic in the target file
HRef-Id         The id of the statement in the body of the topic referenced by the href in the source file
Source-File     The source file containing the reference
Target-File     The target file
END
    file=>(my $f = fpe($xref->reports, qq(bad${Type}Refs), q(txt))));

  formatTable(\@good, [qw(Href Source-File Target-File)],
    head=><<END,
NNNN Good $type refs relative to folder $in on DDDD

Href            The href in the source file
Source-File     The source file containing the reference
Target-File     The target file
END
    file=>(fpe($xref->reports, qq(good${Type}Refs), q(txt))));
 }

sub reportBadXrefs($)                                                           #P Report bad xrefs
 {my ($xref) = @_;                                                              # Cross referencer
  reportBadRefs($xref, q(x));
 }

sub reportBadTopicRefs($)                                                       #P Report bad topic refs
 {my ($xref) = @_;                                                              # Cross referencer

  my @bad; my @good;                                                            # Bad xrefs
  for my $file(sort keys %{$xref->topicRefs})                                   # Each input file
   {for my $href(sort keys %{$xref->topicRefs->{$file}})                        # Each topic ref in the file
     {my $f = absFromAbsPlusRel(fullFileName($file), $href);                    # Target file absolute
      if ($f)
       {if (!-e $f and !-e wwwDecode($f))                                       # Check target file
         {push @bad, [qq(No such file), $f, $href, $file];
         }
        else
         {push @good, [$f, $href, $file];
         }
       }
     }
   }

  $xref->badTopicRefs = \@bad;                                                  # Bad references
  my $in = $xref->inputFolder//'';
  formatTable(\@bad, [qw(Reason FullFileName Href Source)],
    head=><<END,
NNNN Bad topicrefs on DDDD relative to folder $in
END
    file=>(fpe($xref->reports, qw(badTopicRefs txt))));

  formatTable(\@good, [qw(FullFileName Href Source)],
    head=><<END,
NNNN Good topicrefs on DDDD relative to folder $in
END
    file=>(fpe($xref->reports, qw(goodTopicRefs txt))));
 }

sub reportBadConrefs($)                                                         #P Report bad conrefs refs
 {my ($xref) = @_;                                                              # Cross referencer
  reportBadRefs($xref, q(con));
 }

sub reportImages($)                                                             #P Reports on images and references to images
 {my ($xref) = @_;                                                              # Cross referencer

  my @bad;                                                                      # Bad images
  for my $file(sort keys %{$xref->images})                                      # Each input file
   {for my $href(sort keys %{$xref->images->{$file}})                           # Each image in the file
     {my $image = absFromAbsPlusRel($file, $href);                              # Image relative to current file
      if (-e $image or -e wwwDecode($image))                                    # Actual image name or www encoded image name
       {$xref->imagesFound->{$image}++;                                         # Found image
       }
      else
       {push @bad, [$href, $file];                                              # Missing image
        $xref->imagesMissing->{$image}++;                                       # Number of missing references
       }
     }
   }

  $xref->badImageRefs = \@bad;                                                  # Bad image references

  formatTable(\@bad, [qw(Href File)],
    head=>qq(NNNN Bad image references on DDDD),
    file=>(my $f = fpe($xref->reports, qw(badImageRefs txt))));

  my $found = [map {[$xref->imagesFound->{$_}, $_]}
              keys %{$xref->imagesFound}];
  formatTable($found, [qw(Count ImageFileName)],
    head=><<END,
NNNN image files found on DDDD

Count - Number of references to each image file found.
END
    file=>(fpe($xref->reports, qw(imagesFound txt))));

  my $missing = [map {[$xref->imagesMissing->{$_}, $_]}
                keys %{$xref->imagesMissing}];
  formatTable($missing, [qw(Count ImageFileName)],
    head=><<END,
NNNN images missing on DDDD),

Count - Number of references to each missing image.
END
    file=>(fpe($xref->reports, qw(imagesMissing txt))));
 }

sub reportParseFailed($)                                                        #P Report failed parses
 {my ($xref) = @_;                                                              # Cross referencer

  formatTable($xref->parseFailed, [qw(File)],
    head=>qq(NNNN files failed to parse on DDDD),
    file=>(my $f = fpe($xref->reports, qw(parseFailed txt))));
 }

sub reportBadXml1($)                                                            #P Report bad xml on line 1
 {my ($xref) = @_;                                                              # Cross referencer

  formatTable($xref->badXml1, [qw(File)],
    head=>qq(Data::Edit::Xml::Xref found NNNN Files with the incorrect xml on line 1 on DDDD),
    file=>(my $f = fpe($xref->reports, qw(badXmlLine1 txt))));
 }

sub reportBadXml2($)                                                            #P Report bad xml on line 2
 {my ($xref) = @_;                                                              # Cross referencer

  formatTable($xref->badXml2, [qw(File)],
    head=>qq(Data::Edit::Xml::Xref found NNNN Files with the incorrect xml on line 2 on DDDD),
    file=>(my $f = fpe($xref->reports, qw(badXmlLine2 txt))));
 }

sub createSampleInputFiles($)                                                   #P Create sample input files for testing. The attribute B<inputFolder> supplies the name of the folder in which to create the sample files.
 {my ($N) = @_;                                                                 # Number of sample files
  my $in = q(in);
  clearFolder($in, 20);
  if (1)
   {for my $n(1..$N)
     {my $o = $n + 1; $o -= $N if $o > $N;
      my $f = owf(fpe($in, $n, q(dita)), <<END);
<concept id="c$n">
  <title>Concept $n refers to $o</title>
  <conbody id="b$n">
     <xref id="x$n" href="$o.dita#c$o/x$o">Good</xref>
     <xref id="x$n" href="$o.dita#c$n/x$o">Duplicate id</xref>
     <xref id="b1$n" href="bad$o.dita#c$o/x$o">Bad file</xref>
     <xref id="b2$n" href="$o.dita#c$n/x$o">Bad topic id</xref>
     <xref id="b3$n" href="$o.dita#c$o/x$n">Bad id in topic</xref>
     <xref id="g1$n" href="$o.dita#c$o">Good 1</xref>
     <xref id="g2$n" href="#c$o/x$o">Good 2</xref>
     <xref id="g3$n" href="#c$o">Good 3</xref>
     <p conref="#c$n">Good conref</p>
     <p conref="#b$n">Bad conref</p>
     <image href="a$n.png"/>
  </conbody>
</concept>
END
#   push @{$cross->inputFiles}, $f;                                             # Save input file name
     }
   }
  owf(fpe($in, qw(act1 dita)), <<END);
<concept id="c1">
  <title id="title">All Timing Codes Begin Here</title>
  <conbody/>
</concept>
END
  owf(fpe($in, qw(act2 dita)), <<END);
<concept id="c2">
  <title id="title">All Timing Codes Begin Here</title>
  <conbody>
    <xref href="act1.dita#c1/title"/>
  </conbody>
</concept>
END
  owf(fpe($in, qw(act3 dita)), <<END);
<concept id="c3">
  <title>Error</title>
  <conbody>
    <p/>
  </body>
</concept>
END
  owf(fpe($in, qw(map bookmap ditamap)), <<END);
<map>
  <title>Test</title>
  <topicref href="../act1.dita"/>
  <topicref href="../act2.dita"/>
  <topicref href="../map/aaa.txt"/>
  <topicref href="bbb.txt"/>
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
  ok $x->statusLine =~ m(\AXref Errors: 56 bad xrefs, 8 bad conrefs, 2 bad topicrefs, 8 missing images, 8 duplicate ids, 11 bad first lines, 11 bad second lines\Z);
    Xref Errors: 1 file failed to parse, 48 bad xrefs, 8 bad conrefs,
    2 bad topicrefs, 7 missing image refs, 1 image file found,
    7 missing image files, 8 duplicate ids, 11 bad first lines,
    11 bad second lines\Z);


More detailed reports are produced in the  L<reports|_/reports> folder:

  $x->reports

=head1 Description

Cross reference Dita XML.


Version 20181101.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Cross reference

Check the cross references in a set of Dita files and report the results.

=head2 xref(%)

Check the cross references in a set of Dita files held in  L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder. The possible atributes are defined in L<Data::Edit::Xml::Xref|/Data::Edit::Xml::Xref>

     Parameter    Description
  1  %attributes  Attributes

B<Example:>


    my $x = 𝘅𝗿𝗲𝗳(inputFolder=>q(in), maximumNumberOfProcesses=>2);                
  


=head1 Hash Definitions




=head2 Data::Edit::Xml::Xref Definition


Attributes used by cross referencer.


B<badConRefs> - [file, href]   Invalid conref attributes.

B<badImageRefs> - [file, href]   Missing images.

B<badTopicRefs> - [file, href]   Invalid href attributes topicref tags.

B<badXRefs> - [file, href]   Invalid href attributes on xref tags.

B<badXml1> - Files with a bad xml encoding header on the first line.

B<badXml2> - Files with a bad xml doc type on the second line.

B<conRefs> - {file}{id}++   Conref definitions.

B<duplicateIds> - [file, id]     Duplicate id definitions within a file.

B<duplicateTopicIds> - [topicId, [files]] Files with duplicate topic ids

B<ids> - {file}{id}++   Id definitions across all files.

B<images> - {file}{href}++ Images references.

B<imagesFound> - Consolidated images found

B<imagesMissing> - Consolidated images missing

B<inputFiles> - Input files from L<inputFolder|/inputFolder>.

B<inputFolder> - A folder containing the dita and ditamap files to be cross referenced.

B<maximumNumberOfProcesses> - Maximum number of processes to run

B<parseFailed> - [file] files that failed to parse

B<reports> - Reports folder: the cross referencer will write reports to files in this folder.

B<results> - Results table

B<statusLine> - Status line summarizing the cross reference.

B<summary> - Print the summary line.

B<topicIds> - {file} = topic id

B<topicRefs> - {file}{href}++ Topic references.

B<xRefs> - {file}{href}++ Xrefs references.



=head1 Private Methods

=head2 loadInputFiles($)

Load the names of the files to be processed

     Parameter  Description
  1  $xref      Cross referencer

=head2 analyzeOneFile($)

Analyze one input file

     Parameter  Description
  1  $iFile     File to analyze

=head2 analyze($)

Analyze the input files

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportDuplicateIds($)

Report duplicate ids

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportBadRefs($$)

Report bad references found in xrefs or conrefs as they have the same structure

     Parameter  Description
  1  $xref      Cross referencer
  2  $type      Type of reference to be processed

=head2 reportBadXrefs($)

Report bad xrefs

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportBadTopicRefs($)

Report bad topic refs

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportBadConrefs($)

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

=head2 reportBadXml1($)

Report bad xml on line 1

     Parameter  Description
  1  $xref      Cross referencer

=head2 reportBadXml2($)

Report bad xml on line 2

     Parameter  Description
  1  $xref      Cross referencer

=head2 createSampleInputFiles($)

Create sample input files for testing. The attribute B<inputFolder> supplies the name of the folder in which to create the sample files.

     Parameter  Description
  1  $N         Number of sample files


=head1 Index


1 L<analyze|/analyze> - Analyze the input files

2 L<analyzeOneFile|/analyzeOneFile> - Analyze one input file

3 L<createSampleInputFiles|/createSampleInputFiles> - Create sample input files for testing.

4 L<loadInputFiles|/loadInputFiles> - Load the names of the files to be processed

5 L<reportBadConrefs|/reportBadConrefs> - Report bad conrefs refs

6 L<reportBadRefs|/reportBadRefs> - Report bad references found in xrefs or conrefs as they have the same structure

7 L<reportBadTopicRefs|/reportBadTopicRefs> - Report bad topic refs

8 L<reportBadXml1|/reportBadXml1> - Report bad xml on line 1

9 L<reportBadXml2|/reportBadXml2> - Report bad xml on line 2

10 L<reportBadXrefs|/reportBadXrefs> - Report bad xrefs

11 L<reportDuplicateIds|/reportDuplicateIds> - Report duplicate ids

12 L<reportImages|/reportImages> - Reports on images and references to images

13 L<reportParseFailed|/reportParseFailed> - Report failed parses

14 L<xref|/xref> - Check the cross references in a set of Dita files held in  L<inputFolder|/inputFolder> and report the results in the L<reports|/reports> folder.

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

if (1)
 {my $N = 8;
  createSampleInputFiles($N);
  my $x = xref(inputFolder=>q(in), maximumNumberOfProcesses=>2);                #Txref
  ok nws($x->statusLine) eq nws(<<END);
Xref Errors:
  1 file failed to parse,
 48 bad xrefs,
  8 bad conrefs,
  2 bad topicrefs,
  7 missing image refs,
  7 missing image files,
  8 duplicate ids,
  11 bad first lines,
  11 bad second lines
END
 }

1

