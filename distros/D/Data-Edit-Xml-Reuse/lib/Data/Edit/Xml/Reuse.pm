#!/usr/bin/perl -I/home/phil/r/salesForce/perl/ -I/home/phil/perl/cpan/DataEditXml/lib  -I/home/phil/perl/cpan/DataTableText/lib -I/home/phil/perl/cpan/DitaGBStandard/lib -I/home/phil/perl/cpan/DataEditXmlToDita/lib -I/home/phil/perl/cpan/DataEditXmlXref/lib -I/home/phil/perl/cpan/DataEditXmlLint/lib/ -I/home/phil/perl/cpan/GitHubCrud/lib/ -I/home/phil/perl/cpan/DataEditXml/lib/ -I/home/phil/perl/cpan/DitaPCD/lib/ -I/home/phil/perl/cpan/FlipFlop/lib/ -I/home/phil/perl/cpan/DataEditXmlReuse/lib/
#-------------------------------------------------------------------------------
# Reuse Xml via Dita conrefs.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2019
#-------------------------------------------------------------------------------
# podDocumentation

package Data::Edit::Xml::Reuse;
our $VERSION = 20200503;
use v5.26;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Edit::Xml;
use Data::Edit::Xml::Xref;
use Data::Table::Text qw(:all);
use Dita::GB::Standard;
use Storable qw(store retrieve);
use Time::HiRes qw(time);
use utf8;

#D1 Reuse Xml                                                                   # Reuse Xml via Dita conrefs.

sub newReuse(%)                                                                 #P Create a new cross reuser.
 {my (%attributes) = @_;                                                        # Attributes

  my $reuse = genHash(__PACKAGE__,                                              # Attributes used by the reuser.
    dictionary                          => undef,                               #I The dictionary file into which to store the duplicate L<Xml>.
    fileExtensions                      => [qw(.dita .ditamap .xml .fodt)],     #I The extensions of the L<Xml> files to examine in the L<inputFolder>.
    getFileUrl => qq(/cgi-bin/uiSelfServiceXref/client.pl?getFile=),            #I An optional url to retrieve a specified file from the server running xref used in generating html reports. The complete url is obtained by appending the fully qualified file name to this value.
    htmlFolder                          => undef,                               #I Folder into which to write reports as html.
    inputFiles                          => [],                                  # The files selected from L<inputFolder> for analysis because their extensions matched L<fileExtensions>.
    inputFolder                         => undef,                               #I A folder containing the L<xml> files with extensions named in L<fileExtensions> to be analyzed for reuse.
    matchBlocks                         => [],                                  # [[md5, content]*] blocks of content that match with the confidence level expressed by L<matchSimilarContent>
    matchInBlock                        => {},                                  # {md5 => matchBlocks} : index into L<matchBlocks> by md5 sum.
    matchSimilarTagContent              => 0.5,                                 #I Confidence level between 0 and 1: match content under L<tags> with this level of confidence.
    maximumColumnWidth                  => 180,                                 #I Truncate columns in text reports to this length or allow any width if B<undef>.
    minimumLength                       =>  16,                                 #I The minimum length content must have to be considered for matching.
    minimumReferences                   =>   2,                                 #I The minimum number of references content must have before it can be reused.
    outputFolder                        => undef,                               #I A folder into which to write the deduplicated L<Xml>.
    reportsFolder                       => undef,                               #I A folder into which reports will be written.
    reusableContent                     => {},                                  # {tag}{md5sum}{content}++ potentially reusable content.
    tags                                => {p=>1},                              #I {tag=>1} only consider tags that appear as keys in this hash with truthful values.
    timeEnded                           => undef,                               # Time the run ended.
    timeStart                           => undef,                               # Time the run started.
   );

  loadHash($reuse, @_);                                                         # Load attributes complaining about any invalid ones
 } # newReuse

sub reuse(%)                                                                    # Check Xml for reuse opportunities.
 {my (%attributes) = @_;                                                        # Reuse attributes
  my $reuse = newReuse(%attributes);                                            # Create the reuser

  $reuse->timeStart = time;                                                     # Start time

  for my $attr(qw(inputFolder outputFolder reportsFolder))
   {$reuse->{$attr} or confess "Please supply a value for: $attr";
   }

  $reuse->dictionary //= fpe($reuse->outputFolder, qw(dictionary xml));         # Default dictionary

  lll "Reuse started on input folder:", $reuse->inputFolder;                    # Title

  my @series =                                                                  # Must be done in series at the start
   (q(loadInputFiles),
    q(analyzeInputFiles),
    q(conRef),
   );

  if (1)                                                                        # Perform phases in series that must be run in series
   {my @times;

    for my $phase(@series)                                                      # Each phase in series
     {my $startTime = time;
      lll "Reuse phase $phase";

      $reuse->$phase;                                                           # Execute phase

      push @times, [$phase, sprintf("%12.4f", time - $startTime)];              # Phase time
     }

    my $delta = sprintf("%.3f seconds", time - $reuse->timeStart);              # Time so far

    formatTables($reuse, [sort {$$b[1] <=> $$a[1]} @times],                     # Update after each phase so we can see progress on long running jobs
      columns => <<END,
Phase         Reuse processing phase
Time_Seconds  Time in seconds taken by this processing phase
END
      title   => qq(Processing phases elapsed times in descending order),
      head    => <<END,
Reuse phases took the following times on DDDD

Total run time: $delta
END
      file    => fpe(q(timing), qw(reuse_phases txt)));                         # Write phase times
   }

  $reuse->timeEnded = time;                                                     # Run ended time

  formatTables($reuse, [[$reuse->timeStart, $reuse->timeEnded,                  # Write run times
               $reuse->timeEnded - $reuse->timeStart]],
    columns => <<END,
Start_Time   Start time of the run
End_Time     End time of the run
Elapsed_Time Reuse took this many seconds to run
END
    title => qq(Run times in seconds),
    head  => qq(Reuse took the following time to run on DDDD),
    file  => fpe(q(timing), qw(run txt)));

  lll "Reuse finished on folder:", $reuse->inputFolder unless                   # Show that we have finished unless in development
    $reuse->inputFolder =~ m(cpan/DataEditXmlReuse);

  $reuse                                                                        # Return Reuse results
 }

sub formatTables($$%)                                                           #P Format reports.
 {my ($reuse, $data, %options) = @_;                                            # Reuser, table to be formatted, options

  $reuse && ref($reuse) =~ m(reuse)i or cluck "No reuser";                      # Check parameters
  $data && ref($data) =~ m(array)i or cluck "No data for table";

  cluck "No file for table"    unless $options{file};                           # Check for required options
  cluck "No columns for table" unless $options{columns};
  cluck "No title for table"   unless $options{title};

  formatHtmlAndTextTables
   ($reuse->reportsFolder, $reuse->htmlFolder, $reuse->getFileUrl,
    $reuse->inputFolder, $data, %options,
    maximumColumnWidth => $reuse->maximumColumnWidth,
   );
 }

sub loadInputFiles($)                                                           #P Load the names of the files to be processed.
 {my ($reuse) = @_;                                                             # Cross referencer
  my @in = searchDirectoryTreesForMatchingFiles                                 # Input files
    $reuse->inputFolder, $reuse->fileExtensions->@*;

  $reuse->inputFiles = [@in];

  if (@in == 0)                                                                 # Complain if there are no input files to analyze
   {my $i = $reuse->inputFolder;
    my $e = join " ", @{$reuse->fileExtensions};
    my $x = -d $i ? "The input folder does exist." :
                    "The input folder does NOT exist!";
    confess join '',
      "No files with the specified file extensions ",
      "in the specified input folder:\n",
      "$e\n$i\n$x\n";
   }
 }

sub ffc($$)                                                                     #P First few characters of a string with white space normalized.
 {my ($reuse, $string) = @_;                                                    # Reuser, String
  firstNChars(nws($string), $reuse->maximumColumnWidth)
 }

sub reuseParams($)                                                              #P Tabulate reuse parameters.
 {my ($reuse) = @_;                                                             # Reuser

  push my @t,
   [q(MinimumLength:),     $reuse->minimumLength,     q(The minimum size for content to be reused)],
   [q(MinimumReferences:), $reuse->minimumReferences, q(The minimum number of references for content to be reused)];

  formatTableBasic(\@t);
 }

sub analyzeOneFile($$)                                                          #P Analyze one input file.
 {my ($reuse, $file) = @_;                                                      # Reuser, File to analyze

  my $x = Data::Edit::Xml::new($file);                                          # Parse xml

  $x->subMd5($reuse->tags->%*);                                                 # Md5 sum for each sub tree in parse tree
 } # analyzeOneFile

sub analyzeInputFiles($)                                                        #P Analyze the input files.
 {my ($reuse) = @_;                                                             # Reuser
  lll "Reuse: analyze input files";
  my $ml = $reuse->minimumLength;
  my $mr = $reuse->minimumReferences;

  processFilesInParallel                                                        # Md5 sums for each parse tree
    sub
     {analyzeOneFile $reuse, $_[0];
     },
    sub                                                                         # Merge results for all parse trees
     {my @results = @_;
      mmm "Reuse: merge results";

      my %r;                                                                    # Reuse

      for       my $h(@results)                                                 # Merge
       {for     my $t(sort keys $h->%*)                                         # Tag
         {for   my $m(sort keys $h->{$t}->%*)                                   # Md5
           {for my $s(sort keys $h->{$t}->{$m}->%*)                             # String
             {if (length($s) >= $ml)
               {$r{$t}{$m}{$s} += $$h{$t}{$m}{$s};                              # Count of reuses
               }
             }
           }
         }
       }

      $reuse->reusableContent = \%r;

      mmm "Reuse: create dictionary";
      my @t; my @report;                                                        # Create a generic concept to conref from
      for     my $t(sort keys %r)
       {my @r;
        for   my $m(sort keys $r{$t}->%*)
         {for my $s(sort keys $r{$t}{$m}->%*)
           {if ((my $c = $r{$t}{$m}{$s}) >= $mr)                                # Reuse if there are enough references
             {my $g = guidFromMd5($m);
              push @r, [$s, qq(<$t id="$g">$s</$t>)];
              push @report, [$c, $t, length($s), ffc($reuse, $s), guidFromMd5 $m];
             }
           }
         }
        push @t, map {$$_[1]} sort {$$a[0] cmp $$b[0]} @r;
       }

      my $t = join "\n", <<END, @t, <<END2;
<concept id="dictionary">
  <title>Dictionary</title>
  <conbody>
END
  </conbody>
</concept>
END2
      my %seen;                                                                 # List of elements already seen
      my $x = Data::Edit::Xml::new($t);

      $x->by(sub                                                                # Reuse text within the dictionary
       {my ($o) = @_;
        if (my ($m, $s) = $o->subMd5Tree)
         {if (length($s) >= $ml)
           {my $t = -t $o;
            if ($r{$t}{$m})
             {if ($seen{$m}++)
               {$o->set(id=>undef, conref=>q(#dictionary/).guidFromMd5($m));
                $o->deleteContent;
                $o->putNextAsComment($s);
               }
              else
               {$o->id = guidFromMd5($m);
               }
             }
           }
         }
       });

      overWriteFile($reuse->dictionary, -p $x);                                 # Create dictionary
      my $p = reuseParams($reuse);

      formatTable([sort {$$b[0] <=> $$a[0]} @report], <<END,                    # Report reuse count
Count   Number of times the following content is reused
Tag     The tag the following content occurred under
Length  Length of the content being reused
Content Content being reused - first  few characters there-of.
Md5     Md5 sum of content being reused
END
        title     => q(Reuse content by tag),
        head      => <<END,
NNNN blocks of content have been reused on DDDD

The content field below shows the first few characters of each block after
white space normalization.

$p
END
        summarize => 0,
        file      => fpe($reuse->reportsFolder, qw(lists reused_content_by_tag txt)));
     }, $reuse->inputFiles->@*;

  reportSimilarContent($reuse) if $reuse->matchSimilarTagContent;               # Look for similar content - done here so we can mark up files for similar content search
 } # analyzeInputFiles

sub conRefOneFile($$)                                                           #P Conref one file.
 {my ($reuse, $file) = @_;                                                      # Reuser, File to analyze
  my $of = swapFilePrefix $file, $reuse->inputFolder, $reuse->outputFolder;     # Output file
  my %t = $reuse->tags->%*;
  my $l = $reuse->minimumLength;
  my $n = $reuse->minimumReferences;
  my $x = Data::Edit::Xml::new($file);                                          # Parse xml
  my $r = $reuse->reusableContent;

  $x->downToDie(sub                                                             # Replace largest blocks possible
   {my ($o) = @_;
    my $t = -t $o;
    if ($t{$t})                                                                 # Move duplicate content to dictionary
     {if (my ($m, $s) = $o->subMd5Tree)
       {if (length($s) >= $l)
         {if ($$r{$t}{$m}{$s} >= $n)
           {$o->deleteContent;
            my $f = relFromAbsAgainstAbs($reuse->dictionary, $of);
            $o->set(conref=>qq($f#dictionary/).guidFromMd5($m));
            $o->putNextAsComment($s);
            die;
           }
         }
       }
     }
   });

  $x->by(sub                                                                    # Mark similar content with guids of similar items
   {my ($o) = @_;
    my $t = -t $o;
    if ($t{$t})
     {if (my ($m, $s) = $o->subMd5Tree)
       {if (length($s) >= $l)
         {if (my $b = $reuse->matchInBlock->{$m})                               # Mark similar content with guids of similar items
           {my $r = join ' ', map{guidFromMd5 $_} grep{$_ ne $m} @$b;           # Related guids
            $o->set(id=>guidFromMd5($m), xtrf=>$r);
           }
         }
       }
     }
   });

  Data::Edit::Xml::Xref::editXml $file, $of, -p $x;
 } # conRefOneFile

sub conRef($)                                                                   #P Replace common text with conrefs.
 {my ($reuse) = @_;                                                             # Cross referencer
  lll "Create conrefs";
  processFilesInParallel                                                        # Md5 sums for each parse tree
    sub
     {conRefOneFile($reuse, $_[0]);
     },
    undef, $reuse->inputFiles->@*;
 } # conRef

sub reportSimilarContent($)                                                     #P Report content likely to be similar on the basis of their vocabulary.
 {my ($reuse) = @_;                                                             # Reuser
  lll "Reuse: find similar content";

  my $l = $reuse->matchSimilarTagContent;                                       # Match level
  my $p = int($l * 100);                                                        # Match level as a percentage

  my %content;
  if (my $r = $reuse->reusableContent)                                          # Content to be matched identified by md5 sum
   {for     my $t(sort keys %$r)
     {for   my $m(sort keys $$r{$t}->%*)
       {for my $s(sort keys $$r{$t}{$m}->%*)
         {my $t = detagString $s;
          $content{$m} = $t if length($t) >= $l;
         }
       }
     }
   }

  mmm "Reuse: partition similar content";
  my @m = grep {scalar(@$_) > 1}                                                # Partition into like content based on vocabulary
    setPartitionOnIntersectionOverUnionOfHashStringSetsInParallel
     ($l, \%content);

  $reuse->matchBlocks = [@m];                                                   # Blocks of tags whose content is similar

  for my $b(@m)
   {for my $m(@$b)
     {$reuse->matchInBlock->{$m} = $b;
     }
   }

  mmm "Reuse: report similar content";
  my @t;
  for my $a(@m)                                                                 # Each block of matching topics
   {my ($first, @rest) = @$a;
    push @t, [scalar(@$a), ffc($reuse, $content{$first}), guidFromMd5 $first],
        map {[q(),         ffc($reuse, $content{$_}),     guidFromMd5 $_    ]} @rest;
    push @t, [q(),         q(),              q()];
   }

  my $m = @m;
  my $q = reuseParams($reuse);
  formatTables($reuse, \@t,
    columns => <<END,
Similar      The number of similar tags in this block
Tag_Content  First few characters of similar content with white space normalized.
Md5Sum       Md5 sum of originating tag content
END
    title=>qq(Tags with similar vocabulary with $p % confidence),
    head=><<END,
Reuse found $m groups of tags which have similar vocabulary in their content with $p % confidence on DDDD

$q

The GUIDS on the right an be used to L<grep> the output L<corpus> for the
corresponding text.
END
    clearUpLeft => -1, summarize=>0, zero=>1,
    file=>(my $f = fpe(qw(similar tag_blocks_by_vocabulary txt))));
 } # reportSimilarTopicsByVocabulary

#D0
# podDocumentation
=pod

=encoding utf-8

=head1 Name

Data::Edit::Xml::Reuse - Reuse L<Xml> via the L<Dita> L<conref> facility.

=head1 Synopsis

=head2 Reusing Identical Content

L<Data::Edit::Xml::Reuse> scans an entire document L<corpus> looking for
opportunities to reuse identical L<Xml> via the L<Dita> L<conref> facility.
Duplicated identical content is moved to a separate L<Xml> file called the
B<dictionary>. Duplicated content in the L<corpus> is replaced with references to
the singular content in the dictionary. Larger blocks of identical content are
favored over smaller blocks of content where possible.

L<Data::Edit::Xml::Reuse> provides parameters that qualify the minimum size of
a block of content and the minimum number of references to a block of content
to be moved to the dictionary.

The following example checks the a L<corpus> of Dita L<Xml> documents held in
folder L<inputFolder|/inputFolder>. A copy of the L<corpus> with a L<conref>
replacing each block of identical content under the B<table> and B<p> tags is
placed in the L<outputFolder|/outputFolder> as long as such content is at least
32 characters long and has a minimum of 4 references to it:

  use Data::Edit::Xml::Reuse;

  my $x = Data::Edit::Xml::Reuse::reuse
   (inputFolder       => q(in),
    outputFolder      => q(out),
    reportsFolder     => q(reports),
    minimumLength     => 32,
    minimumReferences => 4,
    tags              => {map {$_=>1} qw(table p)},
   );

The actual number of times each block of content was reused can be found in
report:

 lists/reused_content_by_tag.txt

in the L<reportsFolder|/reportsFolder>.

=head2 Matching Similar Content

Optionally, L<Data::Edit::Xml::Reuse> will also report similar content using
the:

  matchSimilarTagContent => 0.9,

keyword. Content under the specified L<tags> that matches to the specified
level of confidence between 0 and 1 is assigned a L<guid> B<id> attribute and
written to report:

  similar/tag_blocks_by_vocabulary.txt

in the L<reportsFolder|/reportsFolder>.

The L<tags> containing similar content will have this L<guid> listed on their
B<xtrf> attribute making it easy to locate related content using L<grep>.

The report, combined with the id and xtrf attributes, helps identify similar
text, in situ, perhaps to be standardized further and eventually reused.

=head1 Description

Reuse L<Xml|https://en.wikipedia.org/wiki/XML> via the L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> L<conref|http://docs.oasis-open.org/dita/dita/v1.3/errata02/os/complete/part3-all-inclusive/archSpec/base/conref.html#conref> facility.


Version 20191221.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Reuse Xml

Reuse Xml via Dita conrefs.

=head2 reuse(%)

Check Xml for reuse opportunities.

     Parameter    Description
  1  %attributes  Reuse attributes

B<Example:>


  if (1) {
    owf($in[0], <<END);                                                           # Base file
    <concept id="c">
      <title>Ordering information</title>
      <conbody>
        <p>For further information, please visit our web site or contact your local sales company.</p>
        <p>Made in Sweden</p>
        <table>
          <tbody>
            <row>
              <entry><p>Ice Associates</p></entry>
              <entry><p>North Pole 1</p></entry>
            </row>
          </tbody>
        </table>
        <p>aaa bbb ccc ddd eee</p>
      </conbody>
    </concept>
  END

    owf($in[1], <<END);                                                           # Similar file
    <concept id="c">
      <title>Ordering information</title>
      <conbody>
        <p>For further information, please visit our web site or contact your local sales company.</p>
        <p>Copyright © 2018 - 2019. All rights reserved.</p>
        <p>Made in Norway</p>
        <table>
          <tbody>
            <row>
              <entry><p>Ice Associates</p></entry>
              <entry><p>North Pole 1</p></entry>
            </row>
          </tbody>
        </table>
        <p>aaa bbb ccc ddd fff</p>
      </conbody>
    </concept>
  END

    my $dictionary  = fpf($outputFolder, qw(dictionary xml));                     # Dictionary file name

    my $r = Data::Edit::Xml::Reuse::𝗿𝗲𝘂𝘀𝗲
     (dictionary             => $dictionary,                                      # Reuse request
      inputFolder            => $inputFolder,
      matchSimilarTagContent => 0.5,
      outputFolder           => $outputFolder,
      reportsFolder          => $reportsFolder,
      tags                   => {map {$_=>1} qw(p table)},
     );

    ok readFile($dictionary) eq <<END;                                            # Resulting dictionary
  <concept id="dictionary">
    <title>Dictionary</title>
    <conbody>
      <p id="GUID-63271233-3e86-9ac1-5fe8-086bc8b37b51">For further information, please visit our web site or contact your local sales company.</p>
      <table id="GUID-e7a012a5-8ff5-6f12-5b96-0137c5c0a0b4">
        <tbody>
          <row>
            <entry>
              <p>Ice Associates</p>
            </entry>
            <entry>
              <p>North Pole 1</p>
            </entry>
          </row>
        </tbody>
      </table>
    </conbody>
  </concept>
  END

    if (my $h =                                                                   # Similar XML report
      readFile(fpe($reportsFolder, qw(similar tag_blocks_by_vocabulary txt))))
     {ok index($h, <<END) > 0;
     Similar  Tag_Content          Md5Sum
  1        2  aaa bbb ccc ddd eee  GUID-3c8810e0-d8aa-0484-84b8-a57230b756de
  2           aaa bbb ccc ddd fff  GUID-7472a890-4587-8393-9c34-0aa3859d2e21
  END
     }

    ok readFile(fpe($testFolder, qw(out 1 xml))) eq <<END;                        # Deduplicated XML file - Sweden
  <concept id="c">
    <title>Ordering information</title>
    <conbody>
      <p conref="dictionary/xml#dictionary/GUID-63271233-3e86-9ac1-5fe8-086bc8b37b51"/>
  <!-- For further information, please visit our web site or contact your local sales company. -->
      <p>Made in Sweden</p>
      <table conref="dictionary/xml#dictionary/GUID-e7a012a5-8ff5-6f12-5b96-0137c5c0a0b4"/>
  <!-- <tbody><row><entry><p>Ice Associates</p></entry><entry><p>North Pole 1</p></entry></row></tbody> -->
      <p id="GUID-3c8810e0-d8aa-0484-84b8-a57230b756de" xtrf="GUID-7472a890-4587-8393-9c34-0aa3859d2e21">aaa bbb ccc ddd eee</p>
    </conbody>
  </concept>
  END

    ok readFile(fpe($testFolder, qw(out 2 xml))) eq <<END;                        # Deduplicated XML file - Norway
  <concept id="c">
    <title>Ordering information</title>
    <conbody>
      <p conref="dictionary/xml#dictionary/GUID-63271233-3e86-9ac1-5fe8-086bc8b37b51"/>
  <!-- For further information, please visit our web site or contact your local sales company. -->
      <p>Copyright © 2018 - 2019. All rights reserved.</p>
      <p>Made in Norway</p>
      <table conref="dictionary/xml#dictionary/GUID-e7a012a5-8ff5-6f12-5b96-0137c5c0a0b4"/>
  <!-- <tbody><row><entry><p>Ice Associates</p></entry><entry><p>North Pole 1</p></entry></row></tbody> -->
      <p id="GUID-7472a890-4587-8393-9c34-0aa3859d2e21" xtrf="GUID-3c8810e0-d8aa-0484-84b8-a57230b756de">aaa bbb ccc ddd fff</p>
    </conbody>
  </concept>
  END

   }



=head2 Data::Edit::Xml::Reuse Definition


Attributes used by the reuser.




=head3 Input fields


B<dictionary> - The dictionary file into which to store the duplicate L<Xml|https://en.wikipedia.org/wiki/XML>.

B<fileExtensions> - The extensions of the L<Xml|https://en.wikipedia.org/wiki/XML> files to examine in the L<inputFolder>.

B<getFileUrl> - An optional url to retrieve a specified file from the server running xref used in generating html reports. The complete url is obtained by appending the fully qualified file name to this value.

B<htmlFolder> - Folder into which to write reports as html.

B<inputFolder> - A folder containing the L<Xml|https://en.wikipedia.org/wiki/XML> files with extensions named in L<fileExtensions> to be analyzed for reuse.

B<matchSimilarTagContent> - Confidence level between 0 and 1: match content under L<tags> with this level of confidence.

B<maximumColumnWidth> - Truncate columns in text reports to this length or allow any width if B<undef>.

B<minimumLength> - The minimum length content must have to be considered for matching.

B<minimumReferences> - The minimum number of references content must have before it can be reused.

B<outputFolder> - A folder into which to write the deduplicated L<Xml|https://en.wikipedia.org/wiki/XML>.

B<reportsFolder> - A folder into which reports will be written.

B<tags> - {tag=>1} only consider tags that appear as keys in this hash with truthful values.



=head3 Output fields


B<inputFiles> - The files selected from L<inputFolder> for analysis because their extensions matched L<fileExtensions>.

B<matchBlocks> - [[md5, content]*] blocks of content that match with the confidence level expressed by L<matchSimilarContent>

B<matchInBlock> - {md5 => matchBlocks} : index into L<matchBlocks> by md5 sum.

B<reusableContent> - {tag}{md5sum}{content}++ potentially reusable content.

B<timeEnded> - Time the run ended.

B<timeStart> - Time the run started.



=head1 Private Methods

=head2 newReuse(%)

Create a new cross reuser.

     Parameter    Description
  1  %attributes  Attributes

=head2 formatTables($$%)

Format reports.

     Parameter  Description
  1  $reuse     Reuser
  2  $data      Table to be formatted
  3  %options   Options

=head2 loadInputFiles($)

Load the names of the files to be processed.

     Parameter  Description
  1  $reuse     Cross referencer

=head2 ffc($$)

First few characters of a string with white space normalized.

     Parameter  Description
  1  $reuse     Reuser
  2  $string    String

=head2 reuseParams($)

Tabulate reuse parameters.

     Parameter  Description
  1  $reuse     Reuser

=head2 analyzeOneFile($$)

Analyze one input file.

     Parameter  Description
  1  $reuse     Reuser
  2  $file      File to analyze

=head2 analyzeInputFiles($)

Analyze the input files.

     Parameter  Description
  1  $reuse     Reuser

=head2 conRefOneFile($$)

Conref one file.

     Parameter  Description
  1  $reuse     Reuser
  2  $file      File to analyze

=head2 conRef($)

Replace common text with conrefs.

     Parameter  Description
  1  $reuse     Cross referencer

=head2 reportSimilarContent($)

Report content likely to be similar on the basis of their vocabulary.

     Parameter  Description
  1  $reuse     Reuser


=head1 Index


1 L<analyzeInputFiles|/analyzeInputFiles> - Analyze the input files.

2 L<analyzeOneFile|/analyzeOneFile> - Analyze one input file.

3 L<conRef|/conRef> - Replace common text with conrefs.

4 L<conRefOneFile|/conRefOneFile> - Conref one file.

5 L<ffc|/ffc> - First few characters of a string with white space normalized.

6 L<formatTables|/formatTables> - Format reports.

7 L<loadInputFiles|/loadInputFiles> - Load the names of the files to be processed.

8 L<newReuse|/newReuse> - Create a new cross reuser.

9 L<reportSimilarContent|/reportSimilarContent> - Report content likely to be similar on the basis of their vocabulary.

10 L<reuse|/reuse> - Check Xml for reuse opportunities.

11 L<reuseParams|/reuseParams> - Tabulate reuse parameters.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Data::Edit::Xml::Reuse

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
  if ((caller(1))[0]//'Data::Edit::Xml::Reuse') eq "Data::Edit::Xml::Reuse";

makeDieConfess;

mmm "Tests started";

my $nFiles        = 1e2;
my $testFolder    = temporaryFolder;
#  $testFolder    = q(/home/phil/perl/cpan/DataEditXmlReuse/lib/Data/Edit/Xml/tests/);
clearFolder($testFolder, $nFiles);

my $inputFolder   = fpd($testFolder, qw(in));
my $outputFolder  = fpd($testFolder, qw(out));
my $reportsFolder = fpd($testFolder, qw(reports));

my @in = map {fpe($inputFolder, $_, q(xml))} 1..9;

if (1) {                                                                        #Treuse
  owf($in[0], <<END);                                                           # Base file
  <concept id="c">
    <title>Ordering information</title>
    <conbody>
      <p>For further information, please visit our web site or contact your local sales company.</p>
      <p>Made in Sweden</p>
      <table>
        <tbody>
          <row>
            <entry><p>Ice Associates</p></entry>
            <entry><p>North Pole 1</p></entry>
          </row>
        </tbody>
      </table>
      <p>aaa bbb ccc ddd eee</p>
    </conbody>
  </concept>
END

  owf($in[1], <<END);                                                           # Similar file
  <concept id="c">
    <title>Ordering information</title>
    <conbody>
      <p>For further information, please visit our web site or contact your local sales company.</p>
      <p>Copyright © 2018 - 2019. All rights reserved.</p>
      <p>Made in Norway</p>
      <table>
        <tbody>
          <row>
            <entry><p>Ice Associates</p></entry>
            <entry><p>North Pole 1</p></entry>
          </row>
        </tbody>
      </table>
      <p>aaa bbb ccc ddd fff</p>
    </conbody>
  </concept>
END

  my $dictionary  = fpf($outputFolder, qw(dictionary xml));                     # Dictionary file name

  my $r = Data::Edit::Xml::Reuse::reuse
   (dictionary             => $dictionary,                                      # Reuse request
    inputFolder            => $inputFolder,
    matchSimilarTagContent => 0.5,
    outputFolder           => $outputFolder,
    reportsFolder          => $reportsFolder,
    tags                   => {map {$_=>1} qw(p table)},
   );

  ok readFile($dictionary) eq <<END;                                            # Resulting dictionary
<concept id="dictionary">
  <title>Dictionary</title>
  <conbody>
    <p id="GUID-63271233-3e86-9ac1-5fe8-086bc8b37b51">For further information, please visit our web site or contact your local sales company.</p>
    <table id="GUID-e7a012a5-8ff5-6f12-5b96-0137c5c0a0b4">
      <tbody>
        <row>
          <entry>
            <p>Ice Associates</p>
          </entry>
          <entry>
            <p>North Pole 1</p>
          </entry>
        </row>
      </tbody>
    </table>
  </conbody>
</concept>
END

  if (my $h =                                                                   # Similar XML report
    readFile(fpe($reportsFolder, qw(similar tag_blocks_by_vocabulary txt))))
   {ok index($h, <<END) > 0;
   Similar  Tag_Content          Md5Sum
1        2  aaa bbb ccc ddd eee  GUID-3c8810e0-d8aa-0484-84b8-a57230b756de
2           aaa bbb ccc ddd fff  GUID-7472a890-4587-8393-9c34-0aa3859d2e21
END
   }

  ok readFile(fpe($testFolder, qw(out 1 xml))) eq <<END;                        # Deduplicated XML file - Sweden
<concept id="c">
  <title>Ordering information</title>
  <conbody>
    <p conref="dictionary/xml#dictionary/GUID-63271233-3e86-9ac1-5fe8-086bc8b37b51"/>
<!-- For further information, please visit our web site or contact your local sales company. -->
    <p>Made in Sweden</p>
    <table conref="dictionary/xml#dictionary/GUID-e7a012a5-8ff5-6f12-5b96-0137c5c0a0b4"/>
<!-- <tbody><row><entry><p>Ice Associates</p></entry><entry><p>North Pole 1</p></entry></row></tbody> -->
    <p id="GUID-3c8810e0-d8aa-0484-84b8-a57230b756de" xtrf="GUID-7472a890-4587-8393-9c34-0aa3859d2e21">aaa bbb ccc ddd eee</p>
  </conbody>
</concept>
END

  ok readFile(fpe($testFolder, qw(out 2 xml))) eq <<END;                        # Deduplicated XML file - Norway
<concept id="c">
  <title>Ordering information</title>
  <conbody>
    <p conref="dictionary/xml#dictionary/GUID-63271233-3e86-9ac1-5fe8-086bc8b37b51"/>
<!-- For further information, please visit our web site or contact your local sales company. -->
    <p>Copyright © 2018 - 2019. All rights reserved.</p>
    <p>Made in Norway</p>
    <table conref="dictionary/xml#dictionary/GUID-e7a012a5-8ff5-6f12-5b96-0137c5c0a0b4"/>
<!-- <tbody><row><entry><p>Ice Associates</p></entry><entry><p>North Pole 1</p></entry></row></tbody> -->
    <p id="GUID-7472a890-4587-8393-9c34-0aa3859d2e21" xtrf="GUID-3c8810e0-d8aa-0484-84b8-a57230b756de">aaa bbb ccc ddd fff</p>
  </conbody>
</concept>
END

 }

done_testing;

#clearFolder($testFolder, $nFiles);

mmm "Tests finished:";

# owf(q(/home/phil/z/testResults.txt), dump($h));
