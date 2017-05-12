# make sure that basic2min works correctly
# note that this will only work after adding ../lib to perl's
# include path, like with prove -l
use strict;
use warnings;

use Test::More 0.88 tests => 3;
use Test::LongString;
use Test::XML;
use Data::Section::Simple 'get_data_section';
use FindBin '$Bin';
use Path::Tiny;
use Capture::Tiny 'capture';
use Devel::FindPerl qw(find_perl_interpreter);

my $PERL  = find_perl_interpreter() || die "can't find perl!\n";
$PERL = $^X if $PERL ne $^X;
my $script_path = path( $Bin, qw(.. bin basic2min) )->realpath;
my $include_path = path($Bin, qw(.. lib))->realpath;
my $data_path = path($Bin, qw(corpus basic_sample.tbx));

my ($stdout, $stderr) = capture {
    system(qq{$PERL}, qq{-I"$include_path"},
        qq{$script_path}, qq{$data_path}, 'en', 'fr');
};

ok($? == 0, 'process exited successfully')
  or note $stderr;

my $data = get_data_section();
is_xml($stdout, $data->{xml}, 'correct TBX output');
is_string_nows($stderr, $data->{log}, 'correct log output');

__DATA__
@@ xml
<TBX dialect="TBX-Min">
  <header>
    <id>TBX-Basic Sample File</id>
    <description>This document is a sample TBX-Basic document instance showing various types of
          terminological entries. The entries in this file are for demonstration purposes
          only and do not reflect actual terminology data. Any references to real
          companies are fabricated for demonstration purposes only.
This is a sample TBX-Basic file from the Translation Research Group (tbxconvert.gevterm.net).
        Address any enquiries to akmtrg@gmail.com.</description>
    <languages source="en" target="fr"/>
  </header>
  <body>
    <termEntry id="c5">
      <langSet xml:lang="en">
        <tig>
          <term>e-mail</term>
        </tig>
      </langSet>
      <langSet xml:lang="fr">
        <tig>
          <term>courriel</term>
        </tig>
      </langSet>
    </termEntry>
    <termEntry id="c6">
      <langSet xml:lang="en">
        <tig>
          <term>federated database</term>
          <noteGrp>
            <note>
              <noteKey>context</noteKey>
              <noteValue>Users and applications interface with the federated
                            database managed by the federated server. </noteValue>
            </note>
          </noteGrp>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
      </langSet>
      <langSet xml:lang="fr">
        <tig>
          <term>base de donnees federee</term>
          <noteGrp>
            <note>
              <noteKey>context</noteKey>
              <noteValue>Une base de donnees federee est une base de donnees
                            repartie heterogene constituee de donnees federees, et necessite donc
                            une architecture qui permet la communication entre les differentes
                            sources de donnees. </noteValue>
            </note>
          </noteGrp>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
      </langSet>
    </termEntry>
    <termEntry id="c7">
      <langSet xml:lang="en">
        <tig>
          <term>progressive lens</term>
          <termStatus>preferred</termStatus>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
        <tig>
          <term>progressive addition lens</term>
          <noteGrp>
            <note>
              <noteKey>termType</noteKey>
              <noteValue>fullForm</noteValue>
            </note>
          </noteGrp>
          <termStatus>admitted</termStatus>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
        <tig>
          <term>PAL</term>
          <noteGrp>
            <note>
              <noteKey>termType</noteKey>
              <noteValue>acronym</noteValue>
            </note>
          </noteGrp>
          <termStatus>notRecommended</termStatus>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
        <tig>
          <term>progressive power lens</term>
          <termStatus>admitted</termStatus>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
        <tig>
          <term>graduated lens</term>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
      </langSet>
      <langSet xml:lang="fr">
        <tig>
          <term>lentille progressive</term>
          <noteGrp>
            <note>
              <noteKey>grammaticalGender</noteKey>
              <noteValue>feminine</noteValue>
            </note>
          </noteGrp>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
      </langSet>
    </termEntry>
    <termEntry id="c1">
      <subjectField>manufacturing</subjectField>
      <langSet xml:lang="en">
        <tig>
          <term>scheduled operation</term>
          <customer>IBM</customer>
          <noteGrp>
            <note>
              <noteKey>termType</noteKey>
              <noteValue>fullForm</noteValue>
            </note>
            <note>
              <noteKey>grammaticalGender</noteKey>
              <noteValue>masculine</noteValue>
            </note>
            <note>
              <noteKey>geographicalUsage</noteKey>
              <noteValue>Canada</noteValue>
            </note>
            <note>
              <noteKey>termLocation</noteKey>
              <noteValue>menuItem</noteValue>
            </note>
            <note>
              <noteKey>source</noteKey>
              <noteValue>IBM</noteValue>
            </note>
            <note>
              <noteKey>projectSubset</noteKey>
              <noteValue>Tivoli Storage Manager</noteValue>
            </note>
          </noteGrp>
          <termStatus>preferred</termStatus>
          <partOfSpeech>verb</partOfSpeech>
        </tig>
      </langSet>
    </termEntry>
    <termEntry id="c2">
      <subjectField>manufacturing</subjectField>
      <langSet xml:lang="en">
        <tig>
          <term>unscheduled operation</term>
          <customer>SAX Manufacturing</customer>
          <noteGrp>
            <note>
              <noteKey>termType</noteKey>
              <noteValue>fullForm</noteValue>
            </note>
            <note>
              <noteKey>grammaticalGender</noteKey>
              <noteValue>masculine</noteValue>
            </note>
            <note>
              <noteKey>geographicalUsage</noteKey>
              <noteValue>en-US</noteValue>
            </note>
            <note>
              <noteKey>termLocation</noteKey>
              <noteValue>radioButton</noteValue>
            </note>
            <note>
              <noteKey>context</noteKey>
              <noteValue>Unscheduled operations should be recorded in a log.</noteValue>
            </note>
            <note>
              <noteKey>source</noteKey>
              <noteValue>Manufacturing Process Manual V2</noteValue>
            </note>
            <note>
              <noteKey>projectSubset</noteKey>
              <noteValue>Service department</noteValue>
            </note>
            <note>
              <noteKey>source</noteKey>
              <noteValue>Manufacturing Process Manual V2</noteValue>
            </note>
            <note>
              <noteKey>projectSubset</noteKey>
              <noteValue>Service department</noteValue>
            </note>
            <note>
              <noteValue>2007-07-22</noteValue>
            </note>
            <note>
              <noteValue>2007-07-23</noteValue>
            </note>
            <note>
              <noteValue>This is a sample entry with some data categories at the term or
                            language level</noteValue>
            </note>
          </noteGrp>
          <termStatus>admitted</termStatus>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
      </langSet>
    </termEntry>
  </body>
</TBX>

@@ log
element /martif/martifHeader/encodingDesc/p not converted
element /martif/martifHeader/encodingDesc not converted
element /martif/text/body/termEntry[3]/descripGrp/descrip not converted
element /martif/text/body/termEntry[3]/descripGrp/admin not converted
element /martif/text/body/termEntry[3]/descripGrp not converted
element /martif/text/body/termEntry[4]/descripGrp/descrip not converted
element /martif/text/body/termEntry[4]/descripGrp/admin not converted
element /martif/text/body/termEntry[4]/descripGrp not converted
element /martif/text/body/termEntry[4]/transacGrp/transac not converted
element /martif/text/body/termEntry[4]/transacGrp/transacNote not converted
element /martif/text/body/termEntry[4]/transacGrp/date not converted
element /martif/text/body/termEntry[4]/transacGrp[2]/transac not converted
element /martif/text/body/termEntry[4]/transacGrp[2]/transacNote not converted
element /martif/text/body/termEntry[4]/transacGrp[2]/date not converted
element /martif/text/body/termEntry[4]/note not converted
element /martif/text/body/termEntry[4]/ref not converted
element /martif/text/body/termEntry[4]/xref not converted
element /martif/text/body/termEntry[4]/xref[2] not converted
element /martif/text/body/termEntry[4]/langSet/tig/descripGrp/descrip not converted
element /martif/text/body/termEntry[4]/langSet/tig/descripGrp/admin not converted
element /martif/text/body/termEntry[4]/langSet/tig/descripGrp not converted
element /martif/text/body/termEntry[5]/langSet/descrip not converted
element /martif/text/body/termEntry[5]/langSet/tig/transacGrp/transac not converted
element /martif/text/body/termEntry[5]/langSet/tig/transacGrp/transacNote not converted
element /martif/text/body/termEntry[5]/langSet/tig/transacGrp[2]/transac not converted
element /martif/text/body/termEntry[5]/langSet/tig/transacGrp[2]/transacNote not converted
element /martif/text/body/termEntry[5]/langSet/tig/ref not converted
element /martif/text/body/termEntry[5]/langSet/tig/xref not converted
element /martif/text/back/refObjectList/refObject/item not converted
element /martif/text/back/refObjectList/refObject/item[2] not converted
element /martif/text/back/refObjectList/refObject/item[3] not converted
element /martif/text/back/refObjectList/refObject not converted
element /martif/text/back/refObjectList/refObject[2]/item not converted
element /martif/text/back/refObjectList/refObject[2]/item[2] not converted
element /martif/text/back/refObjectList/refObject[2]/item[3] not converted
element /martif/text/back/refObjectList/refObject[2] not converted
element /martif/text/back/refObjectList not converted
element /martif/text/back not converted