#!perl -T

use strict;
use Test::More tests => 5;

BEGIN {
    use_ok( 'Data::iRealPro::Input' );
}

SKIP: {

eval { require XML::LibXML };
if ( $@ ) {
    diag( "SKIPPED -- No support for MusicXML import" );
    skip "No support for MusicXML import", 4;
}
my $in = Data::iRealPro::Input->new;
ok( $in, "Create input handler" );

my $data1 = <<'EOD';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 2.0 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise xmlns:tools="http://schemas.android.com/tools" version="2.0" tools:ignore="EnforceUTF8">
	<movement-title>Bloomdido</movement-title>
	<identification>
		<creator type="composer">Charlie Parker</creator>
		<creator type="lyricist">Up Tempo Swing</creator>
		<rights>Made with iReal Pro</rights>
		<encoding>
			<software>iReal Pro (Android)</software>
			<encoding-date>2016-12-02</encoding-date>
			<supports element="accidental" type="no"/>
			<supports element="transpose" type="no"/>
			<supports attribute="new-page" element="print" type="yes" value="yes"/>
			<supports attribute="new-system" element="print" type="yes" value="yes"/>
		</encoding>
	</identification>
	<defaults>
		<scaling>
			<millimeters>7</millimeters>
			<tenths>40</tenths>
		</scaling>
		<page-layout>
			<page-height>1700</page-height>
			<page-width>1200</page-width>
			<page-margins type="both">
				<left-margin>72</left-margin>
				<right-margin>72</right-margin>
				<top-margin>72</top-margin>
				<bottom-margin>72</bottom-margin>
			</page-margins>
		</page-layout>
		<system-layout>
			<system-margins>
				<left-margin>22</left-margin>
				<right-margin>0</right-margin>
			</system-margins>
			<system-distance>100</system-distance>
			<top-system-distance>73</top-system-distance>
		</system-layout>
		<?DoletiRealb StaffJustificationPercentage=65?>
		<appearance>
			<line-width type="beam">5</line-width>
			<line-width type="heavy barline">5</line-width>
			<line-width type="leger">1.5625</line-width>
			<line-width type="light barline">1.5625</line-width>
			<line-width type="slur middle">2.1875</line-width>
			<line-width type="slur tip">0.625</line-width>
			<line-width type="staff">0.9375</line-width>
			<line-width type="stem">0.9375</line-width>
			<line-width type="tie middle">2.1875</line-width>
			<line-width type="tie tip">0.625</line-width>
			<note-size type="grace">60</note-size>
			<note-size type="cue">75</note-size>
		</appearance>
		<music-font font-family="Opus,music"/>
		<word-font font-family="Times New Roman"/>
	</defaults>
	<part-list>
		<score-part id="P1">
			<part-name print-object="no">Lead sheet</part-name>
		</score-part>
	</part-list>
    <!--=========================================================-->
	<part id="P1">
	<measure number="1">
      <print>
        <system-layout>
          <top-system-distance>210</top-system-distance>
        </system-layout>
      </print>
      <attributes>
        <divisions>768</divisions>
        <key>
          <fifths>-2</fifths>
          <mode>major</mode>
        </key>
        <time>
          <beats>4</beats>
          <beat-type>4</beat-type>
        </time>
        <clef>
          <sign>G</sign>
          <line>2</line>
        </clef>
      </attributes>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <harmony print-frame="no" default-y="25" relative-x="10">
        <root>
          <root-step>B</root-step>
          <root-alter>-1</root-alter>
        </root>
        <kind text="7">dominant</kind>
      </harmony>
      <note>
        <pitch>
          <step>B</step>
          <alter>-1</alter>
          <octave>4</octave>
        </pitch>
        <duration>3072</duration>
        <type>whole</type>
        <notehead>diamond</notehead>
      </note>
    </measure>
    <!--=========================================================-->
    <measure number="2">
      <print/>
      <attributes/>
      <harmony print-frame="no" default-y="25" relative-x="10">
        <root>
          <root-step>C</root-step>
          <root-alter>0</root-alter>
        </root>
        <kind text="m7">minor-seventh</kind>
      </harmony>
      <note>
        <pitch>
          <step>B</step>
          <alter>-1</alter>
          <octave>4</octave>
        </pitch>
        <duration>1536</duration>
        <type>half</type>
        <notehead>diamond</notehead>
      </note>
      <harmony print-frame="no" default-y="25" relative-x="10">
        <root>
          <root-step>F</root-step>
          <root-alter>0</root-alter>
        </root>
        <kind text="7">dominant</kind>
      </harmony>
      <note>
        <pitch>
          <step>B</step>
          <alter>-1</alter>
          <octave>4</octave>
        </pitch>
        <duration>1536</duration>
        <type>half</type>
        <notehead>diamond</notehead>
      </note>
    </measure>
    <!--=========================================================-->
    <measure number="3">
      <print/>
      <attributes/>
      <harmony print-frame="no" default-y="25" relative-x="10">
        <root>
          <root-step>B</root-step>
          <root-alter>-1</root-alter>
        </root>
        <kind text="7">dominant</kind>
      </harmony>
      <note>
        <pitch>
          <step>B</step>
          <alter>-1</alter>
          <octave>4</octave>
        </pitch>
        <duration>3072</duration>
        <type>whole</type>
        <notehead>diamond</notehead>
      </note>
    </measure>
    <!--=========================================================-->
    <measure number="4">
      <print/>
      <attributes/>
      <harmony print-frame="no" default-y="25" relative-x="10">
        <root>
          <root-step>B</root-step>
          <root-alter>-1</root-alter>
        </root>
        <kind text="7">dominant</kind>
      </harmony>
      <note>
        <pitch>
          <step>B</step>
          <alter>-1</alter>
          <octave>4</octave>
        </pitch>
        <duration>3072</duration>
        <type>whole</type>
        <notehead>diamond</notehead>
      </note>
    </measure>
    <!--=========================================================-->
    <measure number="5">
      <print new-system="yes"/>
      <attributes/>
      <harmony print-frame="no" default-y="25" relative-x="10">
        <root>
          <root-step>E</root-step>
          <root-alter>-1</root-alter>
        </root>
        <kind text="7">dominant</kind>
      </harmony>
      <note>
        <pitch>
          <step>B</step>
          <alter>-1</alter>
          <octave>4</octave>
        </pitch>
        <duration>3072</duration>
        <type>whole</type>
        <notehead>diamond</notehead>
      </note>
    </measure>
    <!--=========================================================-->
    <measure number="6">
      <print/>
      <attributes/>
      <harmony print-frame="no" default-y="25" relative-x="10">
        <root>
          <root-step>E</root-step>
          <root-alter>-1</root-alter>
        </root>
        <kind text="m7">minor-seventh</kind>
      </harmony>
      <note>
        <pitch>
          <step>B</step>
          <alter>-1</alter>
          <octave>4</octave>
        </pitch>
        <duration>3072</duration>
        <type>whole</type>
        <notehead>diamond</notehead>
      </note>
    </measure>
    <!--=========================================================-->
    <measure number="7">
      <print/>
      <attributes/>
      <harmony print-frame="no" default-y="25" relative-x="10">
        <root>
          <root-step>B</root-step>
          <root-alter>-1</root-alter>
        </root>
        <kind text="7">dominant</kind>
      </harmony>
      <note>
        <pitch>
          <step>B</step>
          <alter>-1</alter>
          <octave>4</octave>
        </pitch>
        <duration>3072</duration>
        <type>whole</type>
        <notehead>diamond</notehead>
      </note>
    </measure>
    <!--=========================================================-->
    <measure number="8">
      <print/>
      <attributes/>
      <harmony print-frame="no" default-y="25" relative-x="10">
        <root>
          <root-step>C</root-step>
          <root-alter>1</root-alter>
        </root>
        <kind text="m7">minor-seventh</kind>
      </harmony>
      <note>
        <pitch>
          <step>B</step>
          <alter>-1</alter>
          <octave>4</octave>
        </pitch>
        <duration>3072</duration>
        <type>whole</type>
        <notehead>diamond</notehead>
      </note>
    </measure>
    <!--=========================================================-->
    <measure number="9">
      <print new-system="yes"/>
      <attributes/>
      <harmony print-frame="no" default-y="25" relative-x="10">
        <root>
          <root-step>C</root-step>
          <root-alter>0</root-alter>
        </root>
        <kind text="m7">minor-seventh</kind>
      </harmony>
      <note>
        <pitch>
          <step>B</step>
          <alter>-1</alter>
          <octave>4</octave>
        </pitch>
        <duration>3072</duration>
        <type>whole</type>
        <notehead>diamond</notehead>
      </note>
    </measure>
    <!--=========================================================-->
    <measure number="10">
      <print/>
      <attributes/>
      <harmony print-frame="no" default-y="25" relative-x="10">
        <root>
          <root-step>F</root-step>
          <root-alter>0</root-alter>
        </root>
        <kind text="7">dominant</kind>
      </harmony>
      <note>
        <pitch>
          <step>B</step>
          <alter>-1</alter>
          <octave>4</octave>
        </pitch>
        <duration>3072</duration>
        <type>whole</type>
        <notehead>diamond</notehead>
      </note>
    </measure>
    <!--=========================================================-->
    <measure number="11">
      <print/>
      <attributes/>
      <harmony print-frame="no" default-y="25" relative-x="10">
        <root>
          <root-step>B</root-step>
          <root-alter>-1</root-alter>
        </root>
        <kind text="7">dominant</kind>
      </harmony>
      <note>
        <pitch>
          <step>B</step>
          <alter>-1</alter>
          <octave>4</octave>
        </pitch>
        <duration>3072</duration>
        <type>whole</type>
        <notehead>diamond</notehead>
      </note>
    </measure>
    <!--=========================================================-->
    <measure number="12">
      <print/>
      <attributes/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline/>
      <barline location="right">
        <bar-style>light-heavy</bar-style>
      </barline>
      <harmony print-frame="no" default-y="25" relative-x="10">
        <root>
          <root-step>C</root-step>
          <root-alter>0</root-alter>
        </root>
        <kind text="m7">minor-seventh</kind>
      </harmony>
      <note>
        <pitch>
          <step>B</step>
          <alter>-1</alter>
          <octave>4</octave>
        </pitch>
        <duration>1536</duration>
        <type>half</type>
        <notehead>diamond</notehead>
      </note>
      <harmony print-frame="no" default-y="25" relative-x="10">
        <root>
          <root-step>F</root-step>
          <root-alter>0</root-alter>
        </root>
        <kind text="7">dominant</kind>
      </harmony>
      <note>
        <pitch>
          <step>B</step>
          <alter>-1</alter>
          <octave>4</octave>
        </pitch>
        <duration>1536</duration>
        <type>half</type>
        <notehead>diamond</notehead>
      </note>
    </measure>
    <!--=========================================================-->
  </part>
</score-partwise>
EOD

my $u = $in->parsedata($data1);
ok( $u->{playlist}, "Got playlist" );
my $pl = $u->{playlist};
is( scalar(@{$pl->{songs}}), 1, "Got one song" );

my $res = $u->as_string(1);

my $exp = <<'EOD';
irealb://Bloomdido%3DParker%20Charlie%3D%3DRock%20Ballad%3DBb%3D%3D1r34LbKcu7B%7CQyXBb7XyQyX7bE%7CQyX7bB%7CyQX7bBZL7F%207-C%7CQ%7CEb-7%2C44T%5Bb7XyQ%7CC%23-7XyQ%7CC-7XyQ%7CF7XyQ%7CBb7XyQ%7CC-7%20F7%20%5D%20%3D%3D100%3D0%3D%3D%3DImport%20via%20MusicXML
EOD
chomp($exp);

is_deeply( $res, $exp, "MusicXML input" );

} # SKIP
