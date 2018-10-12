#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Cross reference data held in the XML format.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2018
#-------------------------------------------------------------------------------
# podDocumentation
# Handle relative files in hrefs, conrefs etc.

package Data::Edit::Xml::Xref;
our $VERSION = 20181010;
use v5.8.0;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Edit::Xml;
use Data::Table::Text qw(:all);
use utf8;

#D1 Attributes                                                                  # Create a cross referencer.

our $attributes = genHash(q(Data::Edit::Xml::Xref),                             # Attributes used by a cross referencer
  badImages=>[],                                                                # [file, href]   Missing images
  badXml1=>[],                                                                  # Files with a bad xml encoding header on line 1
  badXml2=>[],                                                                  # Files with a bad xml doc type on line 2
  badXRefs=>[],                                                                 # [file, href]   Invalid xrefs
  badTopicRefs=>[],                                                             # [file, href]   Invalid topic refs
  badConRefs=>[],                                                               # [file, href]   Invalid conrefs
  conRefs=>{},                                                                  # {file}{id}++   Conref definitions
  duplicateIds=>[],                                                             # [file, id]     Duplicate id definitions within a file
  ids=>{},                                                                      # {file}{id}++   Id definitions across all files
  images=>{},                                                                   # {file}{href}++ Images references
  inputFiles=>[],                                                               # Input files from L<inputFolder|/inputFolder>.
  inputFolder=>undef,                                                           # A folder containing the dita and ditamap files to be cross referenced.
  topicRefs=>{},                                                                # {file}{href}++ Topic refs
  xRefs=>{},                                                                    # {file}{href}++ Xrefs references
  reports=>q(reports),                                                          # Reports folder, use this to receive reports from the cross reference.
  statusLine=>undef,                                                            # Status line
  summary=>1,                                                                   # Print a summary line
  topicIds=>{},                                                                 # {file} = topic id
 );

#D1 Cross reference                                                             # Check the cross references in a set of Dita files and report the results.

sub xref(%)                                                                     # Check the cross references in a set of Dita files held in B<inputFolder=>>B<folder> and report the results.
 {my (%attributes) = @_;                                                        # Attributes
  my $xref = genHash(__PACKAGE__, %$attributes, @_);

  $xref->inputFolder = absFromAbsPlusRel(currentDirectory, $xref->inputFolder)  # Make input folder absolute
    if $xref->inputFolder !~ m(\A/);

  my @phases = qw(loadInputFiles analyze reportBadXml1 reportBadXml2
                  reportDuplicateIds reportBadXrefs reportBadTopicRefs
                  reportBadConrefs reportBadImages);
  for my $phase(@phases)                                                        # Perform analysis phases
   {$xref->$phase;
   }

  if (1)                                                                        # Summarize
   {my $i = @{$xref->badImages};
    my $t = @{$xref->badTopicRefs};
    my $x = @{$xref->badXRefs};
    my $c = @{$xref->badConRefs};
    my $d = @{$xref->duplicateIds};
    my $b = @{$xref->badXml1};
    my $B = @{$xref->badXml2};
    my @o;
    push @o, "$x bad xrefs"           if $x >  1;
    push @o, "$x bad xref"            if $x == 1;
    push @o, "$c bad conrefs"         if $c >  1;
    push @o, "$c bad conref"          if $c == 1;
    push @o, "$t bad topicrefs"       if $t >  1;
    push @o, "$t bad topicref"        if $t == 1;
    push @o, "$i missing images"      if $i >  1;
    push @o, "$i missing image"       if $i == 1;
    push @o, "$d duplicate ids"       if $d >  1;
    push @o, "$d duplicate id"        if $d == 1;
    push @o, "$b bad first lines"     if $b >  1;
    push @o, "$b bad first line"      if $b == 1;
    push @o, "$B bad second lines"    if $B >  1;
    push @o, "$B bad second line"     if $B == 1;
    $xref->statusLine = undef;
    if (@o)
     {my $m = "Xref Errors: ". join q(, ), @o;
      $xref->statusLine = $m;
      say STDERR $m if $xref->summary;
     }
   }

  $xref
 }

sub loadInputFiles($)                                                           #P Load the names of the files to be processed
 {my ($xref) = @_;                                                              # Cross referencer
  $xref->inputFiles = [searchDirectoryTreesForMatchingFiles
    $xref->inputFolder, qw(.dita .ditamap .xml)];
 }

sub analyze($)                                                                  #P Analyze the input files
 {my ($xref) = @_;                                                              # Cross referencer

  for my $iFile(@{$xref->inputFiles})                                           # Each input file
   {my $x = Data::Edit::Xml::new($iFile);                                       # Parse xml

    $x->by(sub                                                                  # Each node
     {my ($o) = @_;
      if (my $i = $o->id)                                                       # Id definitions
       {$xref->ids->{$iFile}{$i}++;
       }
      if ($o->at_xref)                                                          # Xrefs but not to the web
       {if (my $h = $o->href)
         {if ($h !~ m(\A(https?://|mailto:))s)
           {$xref->xRefs->{$iFile}{$h}++;
           }
         }
       }
      elsif ($o->at_topicref)                                                   # TopicRefs
       {if (my $h = $o->href)
         {$xref->topicRefs->{$iFile}{$h}++;
         }
       }
      elsif ($o->at(qw(image)))                                                 # Images
       {if (my $h = $o->href)
         {$xref->images->{$iFile}{$h}++;
         }
       }
      if (my $conref = $o->attr_conref)                                         # Conref
       {$xref->conRefs->{$iFile}{$conref}++;
       }
     });

    $xref->topicIds->{$iFile} = $x->id;                                         # Topic Id

    if (1)                                                                      # Check xml headers
     {my @h = split /\n/, readFile($iFile);
      if (!$h[0] or $h[0] !~ m(\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?>\Z))
       {push @{$xref->badXml1}, $iFile;
       }
      my $tag = $x->tag;
      if (!$h[1] or $h[1] !~ m(\A<!DOCTYPE $tag PUBLIC "-//))
       {push @{$xref->badXml2}, $iFile;
       }
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
        if ($hFile and !-e $fFile)                                              # Check target file
         {push @bad, [qq(No such file),
           $hFile, $topic, $id, q(), $href, $fFile];
         }

        if (my $t = $xref->topicIds->{$fFile})                                  # Check topic id
         {if ($t eq $topic)
           {if (my $i = $xref->ids->{$fFile}{$id})
             {if ($i == 1)
               {push @good,[$fFile, $href, $fFile];
               }
              else
               {push @bad, [qq(Duplicate id in topic),
                 $hFile, $topic, $id, $t, $href, $fFile];
               }
             }
            elsif ($id)
             {push @bad, [qq(No such id in topic),
                $hFile, $topic, $id, $t, $href, $fFile];

             }
            else
             {push @good,[$fFile, $href, $fFile];
             }
           }
          else
           {push @bad, [qq(Topic id mismatch),
             $hFile, $topic, $id, $t, $href, $fFile];
           }
         }
        elsif ($topic)
         {push @bad, [qq(No topic id on topic in target file),
           $hFile, $topic, $id, $t, $href, $fFile];
         }
        else
         {push @good,[$fFile, $href, $fFile];
         }
       }
      else                                                                      # No # in href
       {my $fFile = absFromAbsPlusRel($file, $href);
        if (!-e $fFile)
         {push @bad, [qq(No such file),
           $fFile, q(), q(), q(), $href, $fFile];
         }
        else
         {push @good,[$fFile, $href, $fFile];
         }
       }
     }
   }

  my $Type = ucfirst $type;
  $xref->{my $t = q(bad).$Type.q(Refs)} = \@bad;                                # Bad references

  my $in = $xref->inputFolder//'';
  formatTable(\@bad, [qw(Reason hrefFile hrefTopic HrefId TopicId Source File)],
    head=><<END,
NNNN Bad $type refs relative to folder $in on DDDD
END
    file=>(my $f = fpe($xref->reports, qq(bad${Type}Refs), q(txt))));

  formatTable(\@good, [qw(FullFileName Href Source)],
    head=><<END,
NNNN Good $type refs relative to folder $in on DDDD
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
       {if (!-e $f)                                                             # Check target file
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

sub reportBadImages($)                                                          #P Report bad images
 {my ($xref) = @_;                                                              # Cross referencer

  my @bad;                                                                      # Bad images
  for my $file(sort keys %{$xref->images})                                      # Each input file
   {for my $href(sort keys %{$xref->images->{$file}})                           # Each image in the file
     {my $image = absFromAbsPlusRel($file, $href);                              # Image relative to current file
      next if -e $image;
      push @bad, [$href, $file];                                                # Missing image
     }
   }

  $xref->badImages = \@bad;                                                     # Bad images

  formatTable(\@bad, [qw(Href File)],
    head=>qq(NNNN Bad images on DDDD),
    file=>(my $f = fpe($xref->reports, qw(badImages txt))));
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
  owf(fpe($in, qw(map bookmap ditamap)), <<END);
<map>
  <title>Test</title>
  <topicref href="../act1.dita"/>
  <topicref href="../act2.dita"/>
  <topicref href="../map/aaa.txt"/>
  <topicref href="bbb.txt"/>
</map>
END
 }

#D
# podDocumentation
=pod

=encoding utf-8

=head1 Name

Data::Edit::Xml::Xref - Cross reference data held in the XML format.

=head1 Synopsis

Check the references in a set of XML documents held in a folder:

  use Data::Edit::Xml::Xref;

  my $x = xref(inputFolder=>q(in));
  ok $x->statusLine =~ m(\AXref Errors: 56 bad xrefs, 8 bad conrefs, 2 bad topicrefs, 8 missing images, 8 duplicate ids, 11 bad first lines, 11 bad second lines\Z);

         {push @bad, [qq(No topic id on topic in target file),
More detailed reports are produced in the:

  $x->reports

folder.

=head1 Description

Cross reference data held in the XML format.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Attributes

Create a cross referencer.

=head1 Cross reference

Check the cross references in a set of Dita files and report the results.

=head2 xref(%)

Check the cross references in a set of Dita files held in B<inputFolder=>>B<folder> and report the results.

     Parameter    Description
  1  %attributes  Attributes

B<Example:>


    my $x = 𝘅𝗿𝗲𝗳(inputFolder=>q(in));                                             
  


=head1 Hash Definitions




=head2 Data::Edit::Xml::Xref Definition


Attributes used by a cross referencer


B<badConRefs> - [file, href]   Invalid conrefs

B<badImages> - [file, href]   Missing images

B<badTopicRefs> - [file, href]   Invalid topic refs

B<badXRefs> - [file, href]   Invalid xrefs

B<badXml1> - Files with a bad xml encoding header on line 1

B<badXml2> - Files with a bad xml doc type on line 2

B<conRefs> - {file}{id}++   Conref definitions

B<duplicateIds> - [file, id]     Duplicate id definitions within a file

B<ids> - {file}{id}++   Id definitions across all files

B<images> - {file}{href}++ Images references

B<inputFiles> - Input files from L<inputFolder|/inputFolder>.

B<inputFolder> - A folder containing the dita and ditamap files to be cross referenced.

B<reports> - Reports folder, use this to receive reports from the cross reference.

B<statusLine> - Status line

B<summary> - Print a summary line

B<topicIds> - {file} = topic id

B<topicRefs> - {file}{href}++ Topic refs

B<xRefs> - {file}{href}++ Xrefs references



=head1 Private Methods

=head2 loadInputFiles($)

Load the names of the files to be processed

     Parameter  Description
  1  $xref      Cross referencer

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

=head2 reportBadImages($)

Report bad images

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

2 L<createSampleInputFiles|/createSampleInputFiles> - Create sample input files for testing.

3 L<loadInputFiles|/loadInputFiles> - Load the names of the files to be processed

4 L<reportBadConrefs|/reportBadConrefs> - Report bad conrefs refs

5 L<reportBadImages|/reportBadImages> - Report bad images

6 L<reportBadRefs|/reportBadRefs> - Report bad references found in xrefs or conrefs as they have the same structure

7 L<reportBadTopicRefs|/reportBadTopicRefs> - Report bad topic refs

8 L<reportBadXml1|/reportBadXml1> - Report bad xml on line 1

9 L<reportBadXml2|/reportBadXml2> - Report bad xml on line 2

10 L<reportBadXrefs|/reportBadXrefs> - Report bad xrefs

11 L<reportDuplicateIds|/reportDuplicateIds> - Report duplicate ids

12 L<xref|/xref> - Check the cross references in a set of Dita files held in B<inputFolder=>>B<folder> and report the results.

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
  my $x = xref(inputFolder=>q(in));                                             #Txref
  ok $x->statusLine =~ m(\AXref Errors: 56 bad xrefs, 8 bad conrefs, 2 bad topicrefs, 8 missing images, 8 duplicate ids, 11 bad first lines, 11 bad second lines\Z);
 }

1

