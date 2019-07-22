#!/usr/bin/perl -I/home/phil/perl/cpan/DataEditXml/lib  -I/home/phil/perl/cpan/DataTableText/lib -I/home/phil/perl/cpan/DitaGBStandard/lib -I/home/phil/perl/cpan/DataEditXmlToDita/lib -I/home/phil/perl/cpan/DataEditXmlXref/lib -I/home/phil/perl/cpan/DataEditXmlLint/lib/ -I/home/phil/perl/cpan/GitHubCrud/lib/ -I/home/phil/perl/cpan/DataEditXml/lib/
#-------------------------------------------------------------------------------
# Convert Dita to Dita conforming to the GB Standard
# Philip R Brenan at gmail dot com, Ryffine Inc., 2019
#-------------------------------------------------------------------------------
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Edit::Xml;
use Data::Edit::Xml::Lint;
use Data::Edit::Xml::To::Dita;
use Data::Edit::Xml::Xref;
use Data::Table::Text qw(:all);
use Test::More;
use feature qw(say current_sub);
use utf8;

if ($^O !~ m(bsd|linux)i)
 {plan skip_all => 'Not supported';
 }

sub home           {fpd(currentDirectory, q(test))}
sub develop        {0}
sub download       {0}
sub makeXml        {1}
sub exchange       {0}
sub upload         {0}
sub notify         {0}
sub fixBadRefs     {0}
sub fixDitaRefs    {0}

my $conceptHeader = <<END =~ s(\s*\Z) ()gsr;                                    # Header for a concept
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Task//EN" "concept.dtd" []>
END

sub createTest1                                                                 # Collapse a topic referenced from a bookmap
 {owf(fpe(&downloads, qw(a dita)), <<END);
$conceptHeader
<concept id="ca">
  <title>aaaa</title>
  <conbody>
    <p>Aaa aaa aaa</p>
  </conbody>
</concept>
END

  owf(fpe(&downloads, qw(b dita)), <<END);
$conceptHeader
<concept id="cb">
  <title>aaaa</title>
  <conbody>
    <p>Aaa aaa aaa</p>
  </conbody>
</concept>
END

  owf(fpe(&downloads, qw(ab ditamap)), <<END);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE bookmap PUBLIC "-//OASIS//DTD DITA BookMap//EN" "bookmap.dtd" []>
<bookmap id="b1">
  <chapter href="a.dita" navtitle="aaaa">
    <topicref href="b.dita" navtitle="aaaa"/>
  </chapter>
</bookmap>
END
 }

sub createTest2                                                                 # Conref resolution
 {owf(fpe(&downloads, qw(a dita)), <<END);
$conceptHeader
<concept id="ca">
  <title>aaaa</title>
  <conbody>
    <p conref="b.dita#cb/p1">aaaa</p>
  </conbody>
</concept>
END

  owf(fpe(&downloads, qw(b dita)), <<END);
$conceptHeader
<concept id="cb">
  <title>bbbb</title>
  <conbody>
    <p id="p1">bbbb</p>
  </conbody>
</concept>
END
 }

sub createTest3                                                                 # Bookmap reference to topic with multiple cut outs
 {owf(fpe(&downloads, qw(a ditamap)), <<END);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE bookmap PUBLIC "-//OASIS//DTD DITA BookMap//EN" "bookmap.dtd" []>
<bookmap id="bm">
  <chapter href="a.dita" navtitle="aaaa"/>
</bookmap>
END

  owf(fpe(&downloads, qw(a dita)), <<END);
$conceptHeader
<concept id="ca">
  <title>aaaa</title>
  <conbody>
    <p>aaaa</p>
    <concept id="cb">
      <title>bbbb</title>
      <conbody>
        <p id="p1">bbbb</p>
      </conbody>
    </concept>
  </conbody>
</concept>
END
 }

sub createTest4                                                                 # Bookmap reference to topic with no cut outs
 {owf(fpe(&downloads, qw(a ditamap)), <<END);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE bookmap PUBLIC "-//OASIS//DTD DITA BookMap//EN" "bookmap.dtd" []>
<bookmap id="bm">
  <chapter href="a.dita" navtitle="aaaa"/>
</bookmap>
END

  owf(fpe(&downloads, qw(a dita)), <<END);
$conceptHeader
<concept id="ca">
  <title>aaaa</title>
  <conbody>
    <p>aaaa</p>
  </conbody>
</concept>
END
 }

sub createSampleImageTest                                                       #P Test image file resolution
 {my $f = owf(fpe(&downloads, qw(concepts c dita)), <<END);
$conceptHeader
<concept id="c1">
  <title>concept 1</title>
  <conbody>
    <image href="../images/a.png"/>
    <image href="../images/b.png"/>
  </conbody>
</concept>
END

  owf(fpe(&downloads, qw(images a png)), <<END);
png image a
END
 }

sub createTestTopicFlattening                                                   #P Topic flattening
 {for(1..3)
   {owf(fpe(&downloads, q(c).$_, q(dita)), <<END);
$conceptHeader
<concept id="c">
  <title/>
  <conbody/>
</concept>
END
   }
 }

sub createTestReferenceToFlattenedTopic                                         # Reference to a topic that has been flattened
 {owf(fpe(&downloads, qw(a dita)), <<END);
$conceptHeader
<concept id="c">
  <title>aaaa</title>
  <conbody>
    <p conref="b.dita#c/p1"/>
  </conbody>
</concept>
END

  owf(fpe(&downloads, qw(b dita)), <<END);
$conceptHeader
<concept id="c">
  <title>aaaa</title>
  <conbody>
    <p id="p1">pppp</p>
  </conbody>
</concept>
END

  owf(fpe(&downloads, qw(c ditamap)), <<END);
$conceptHeader
<concept id="c">
  <title>aaaa</title>
  <conbody>
    <p id="p1">pppp</p>
  </conbody>
</concept>
END
 }

sub createTestReferenceToCutOutTopic                                            # References from a topic that has been cut out to a topic that has been cut out
 {owf(fpe(&downloads, qw(a xml)), <<END);
$conceptHeader
<concept id="a">
  <title>aaaa</title>
  <conbody/>

  <concept id="ab">
    <title>aaaa bbbb</title>
    <conbody>
      <p conref="b.xml#b/p1"/>
    </conbody>

    <concept id="ac">
      <title>aaaa cccc</title>
      <conbody>
        <p conref="bb.xml#bb/p2"/>
      </conbody>
    </concept>
  </concept>

  <concept id="ad">
    <title>aaaa dddd</title>
    <conbody>
      <p conref="b.xml#b/p3"/> <!--invalid-->
    </conbody>
  </concept>
</concept>
END

  owf(fpe(&downloads, qw(b xml)), <<END);
$conceptHeader
<concept id="b">
  <title>bbbb</title>
  <conbody>
    <p id="p1">1111</p>
  </conbody>

  <concept id="ba">
    <title>bbbb aaaa</title>
    <conbody/>
    <concept id="bb">
      <title>bbbb bbbb</title>
      <conbody>
        <p id="p2">2222</p>
      </conbody>
    </concept>
  </concept>

  <concept id="bc">
    <title>bbbb cccc</title>
    <conbody>
      <p id="p3">3333</p>
    </conbody>
  </concept>
</concept>
END
 }

sub createHtml                                                                  # Html Topics
 {owf(fpe(&downloads, qw(a html)), <<END);
<html>
  <p>aaaa
  <h2>Chapter 1</h2>
  <p>Chapter 1 at heading 2
  <h4>Chapter 1.1</h4>
  <p>Chapter 1.1 at heading 4
  <h4>Chapter 1.2</h4>
  <p>Chapter 1.2 at heading 2
  <h3>Chapter 1.3</h3>
  <p>Chapter 1.3 at heading 3

  <h1>Chapter 1</h1>
  <p>Chapter 1 at heading 1
  <h4>Chapter 1.1</h4>
  <p>Chapter 1.1 at heading 4
  <h4>Chapter 1.2</h4>
  <p>Chapter 1.2 at heading 2
  <h3>Chapter 1.3</h3>
  <p>Chapter 1.3 at heading 3
</html>
END
 }

sub createDocBook                                                               # DocBook topics
 {owf(fpe(&downloads, qw(docBook xml)), <<END);
<article>
<articleinfo>
<title>Sample DocBook</title>
</articleinfo>
<para>This is a sample DocBook article that illustrates some simple DocBook XML tags.
</para>
<sect1>
  <title>Section 1</title>   <para>Paragraph 1 of section 1</para>
  <sect2>
    <title>Section 1.1</title>
    <para>Paragraph 1 of section 1.1</para>
    <para>Paragraph 2 of section 1.1</para> </sect2> <sect2>
  <title>Section 1.2</title> <para>Paragraph 1 of section 1.2</para> </sect2> </sect1> <sect1>
  <title>Section 2</title>
  <para>Second high-level section in this article </para>
</sect1>
</article>
END
 }

sub convertDocument($$)                                                         #r Convert one document.
 {my ($project, $x) = @_;                                                       # Project == document to convert, parse tree.
  $x                                                                            # Return parse tree
 }

sub createTest($$)                                                              # Create one test
 {my ($title, $testCreationSub) = @_;                                           # Title for test, sub to create test scenario
  clearFolder($_, 1e2) for &in, &downloads;                                     # Clear folders
  &$testCreationSub;                                                            # Create the test scenario

  my $r = &convertXmlToDita;                                                    # Convert creating targets/ and out/ in the process

  ok $r->totalErrors == 0;

  my $f = readFiles(&out, &targets);                                            # Pack files to use as tests in Xref
# say STDERR $title, " ", dump($f);
 }

Data::Edit::Xml::To::Dita::overrideMethods;

createTest(q(aaaa), \&createTest1);
createTest(q(bbbb), \&createTest2);
createTest(q(cccc), \&createTest3);
createTest(q(dddd), \&createTest4);
createTest(q(eeee), \&createSampleImageTest);
createTest(q(ffff), \&createTestTopicFlattening);
createTest(q(gggg), \&createTestReferenceToFlattenedTopic);
createTest(q(hhhh), \&createTestReferenceToCutOutTopic);
createTest(q(iiii),  \&createHtml);
createTest(q(jjjj),  \&createDocBook);

done_testing;
