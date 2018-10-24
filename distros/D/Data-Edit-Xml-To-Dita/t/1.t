#!/usr/bin/perl -I../lib
#-------------------------------------------------------------------------------
# Test a Dita conversion
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018
#-------------------------------------------------------------------------------

require v5.16;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Table::Text qw(fpe readFile);
use Data::Edit::Xml::To::Dita;
use Test::More tests=>2;

sub testDocuments {qw(1)}                                                       # List of production documents to test or () for normal testing locally and normal production on AWS

sub home          {qw(/home/phil/zzz/DataEditXmlToDita/)}                       # Home folder
sub upload        {0 or !&develop or Flip::Flop::uploadToS3(0)}                 # Upload to S3 if true.
sub download      {0 or !&develop or Flip::Flop::download(0)}                   # Download from S3 if true.
sub unicode       {1 or !&develop or Flip::Flop::unicode(0)}                    # Convert to utf8 if true.
sub convert       {1 or             !Flip::Flop::convert(0)}                    # Convert documents to dita if true.
sub lint          {-e q(/home/phil/) or !&develop or testDocuments}             # Lint output xml if true or write directly if false.

sub catalog       {q(/home/phil/r/dita/dita-ot-3.1/catalog-dita.xml)}           # Dita catalog to be used for linting.
sub s3Bucket      {q(aci.dita)}                                                 # Bucket on S3 holding documents to convert and the converted results.
sub s3FolderIn    {q(PoC)}                                                      # Folder on S3 containing original documents.
sub s3FolderUp    {q(mim)}                                                      # Folder on S3 containing results of conversion.
sub s3Parms       {q(--profile fmc --quiet --delete)}                           # Additional S3 parameters for uploads and downloads.

sub convertDocument($$)                                                         #r Convert one document.
 {my ($project, $x) = @_;                                                       # Project == one document to convert, parse tree.
  $x->by(sub
   {my ($c) = @_;
    if ($c->at_conbody)
     {$c->putFirst($c->new(<<END));
<p>Hello world!</p>
END
     }
   });
 }

if (1)                                                                          # Create some input files and convert one of them.
 {Data::Edit::Xml::To::Dita::createSampleInputFiles;                            # Create sample input files
  Data::Edit::Xml::To::Dita::convertXmlToDita;                                  # Convert input files
 }

if (lint)                                                                       # Lint report if available
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
else
 {ok 1;
 }

if (1)                                                                          # Converted file
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
<!--linted: 2018-Oct-21 -->

<!--catalog: /home/phil/r/dita/dita-ot-3.1/catalog-dita.xml -->
<!--docType: <!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []> -->
<!--file: /home/phil/zzz/DataEditXmlToDita/out/hello_world.dita -->
<!--header: <?xml version="1.0" encoding="UTF-8"?> -->
<!--project: 1 -->
<!--sha256: cd1a890e4473513babe6f96e62e83e8414b0d450d38aadbe3556ec8d12ab0c72 -->
END
  ok $S eq $s;
 }
