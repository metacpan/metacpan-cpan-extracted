#!/usr/bin/perl
use strict;
use warnings;
use t::TestUTX_TBX;
use Test::XML;
plan tests => 1*blocks();

filters {
	utx => 'convert_utx',
};

for my $block(blocks()){
	is_xml($block->utx, $block->output, "Expected");
}

__DATA__
=== Header
--- utx chomp
#UTX 1.11; de/en-US; 2013-12-20T17:00:45; copyright: Francis Bond (2008); license: CC-by 3.0; bidirectional; Dictionary ID: 18347322;
#description: djalbja;

--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>18347322</id>
		<creator>Francis Bond (2008)</creator>
		<license>CC-by 3.0</license>
		<directionality>bidirectional</directionality>
		<description>djalbja</description>
		<languages source="de" target="en-US"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
	</body>
</TBX>

=== Test unstated directionality
--- utx chomp
#UTX 1.11; de/en-US; 2013-12-20T17:00:45; copyright: Francis Bond (2008); license: CC-by 3.0; Dictionary ID: 18347322;
#description: djalbja;

--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>18347322</id>
		<creator>Francis Bond (2008)</creator>
		<license>CC-by 3.0</license>
		<directionality>monodirectional</directionality>
		<description>djalbja</description>
		<languages source="de" target="en-US"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
	</body>
</TBX>

=== Test monodirectional
--- utx chomp
#UTX 1.11; de/en-US; 2013-12-20T17:00:45; copyright: Francis Bond (2008); license: CC-by 3.0; Dictionary ID: 18347322;
#description: djalbja;

--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>18347322</id>
		<creator>Francis Bond (2008)</creator>
		<license>CC-by 3.0</license>
		<directionality>monodirectional</directionality>
		<description>djalbja</description>
		<languages source="de" target="en-US"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
	</body>
</TBX>

=== Body(Repeated concept ID should get changed in TBX)
--- utx chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	tgt:comment	customer	concept ID
Hund	dog	noun	noun	approved		SAP	C002
Hund	hound	noun	noun		however bloodhound is used rather than blooddog	SAP	C002
Katze	cat	noun	noun			SAP	c008


--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Klaus-Dirk Schmidt</creator>
		<license>CC BY license can be freely copied and modified</license>
		<directionality>monodirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
		<entry id="C002">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>dog</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
			<entry id="C001">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>hound</term>
					<customer>SAP</customer>
					<note>however bloodhound is used rather than blooddog</note>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="c008">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>cat</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
	</body>
</TBX>


=== No_Concept_IDs
--- utx chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	tgt:comment	customer
Hund	dog	noun	noun	approved		SAP
Hund	hound	noun	noun		however bloodhound is used rather than blooddog	SAP
Katze	cat	noun	noun			SAP


--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Klaus-Dirk Schmidt</creator>
		<license>CC BY license can be freely copied and modified</license>
		<directionality>monodirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
		<entry id="C001">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>dog</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
			<entry id="C002">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>hound</term>
					<customer>SAP</customer>
					<note>however bloodhound is used rather than blooddog</note>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="C003">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>cat</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
	</body>
</TBX>


=== Some_Concept_IDs
--- utx chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	tgt:comment	customer	concept ID
Hund	dog	noun	noun	approved		SAP	C002
Hund	hound	noun	noun		however bloodhound is used rather than blooddog	SAP	-
Katze	cat	noun	noun			SAP	C008
Foo	bar	noun	noun				
Bar	Foo	noun	noun	approved	Foobar	Walmart	C001


--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Klaus-Dirk Schmidt</creator>
		<license>CC BY license can be freely copied and modified</license>
		<directionality>monodirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
		<entry id="C002">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>dog</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="C003">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>hound</term>
					<customer>SAP</customer>
					<note>however bloodhound is used rather than blooddog</note>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="C008">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>cat</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="C004">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Foo</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>bar</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="C001">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Bar</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>Foo</term>
					<customer>Walmart</customer>
					<note>Foobar</note>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
	</body>
</TBX>

=== Test implied approved term status with bidirectional flag
--- utx chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; bidirectional; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	tgt:comment	customer	concept ID
Hund	dog	noun	noun		SAP	C002
Hund	hound	noun	noun	however bloodhound is used rather than blooddog	SAP	-
Katze	cat	noun	noun		SAP	C008
Foo	bar	noun	noun			
Bar	Foo	noun	noun	Foobar	Walmart	C001


--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Klaus-Dirk Schmidt</creator>
		<license>CC BY license can be freely copied and modified</license>
		<directionality>bidirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
		<entry id="C002">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>dog</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="C003">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>hound</term>
					<customer>SAP</customer>
					<note>however bloodhound is used rather than blooddog</note>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="C008">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Katze</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>cat</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="C004">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Foo</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>bar</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="C001">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Bar</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>Foo</term>
					<customer>Walmart</customer>
					<note>Foobar</note>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
	</body>
</TBX>



=== Test approved term status insertion without flag or term status column
--- utx chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	tgt:comment	customer	concept ID
Hund	dog	noun	noun		SAP	C002
Hund	hound	noun	noun	however bloodhound is used rather than blooddog	SAP	-
Katze	cat	noun	noun		SAP	C008
Foo	bar	noun	noun			
Bar	Foo	noun	noun	Foobar	Walmart	C001


--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Klaus-Dirk Schmidt</creator>
		<license>CC BY license can be freely copied and modified</license>
		<directionality>monodirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
		<entry id="C002">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>dog</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="C003">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>hound</term>
					<customer>SAP</customer>
					<note>however bloodhound is used rather than blooddog</note>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="C008">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>cat</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="C004">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Foo</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>bar</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="C001">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Bar</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>Foo</term>
					<customer>Walmart</customer>
					<note>Foobar</note>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
	</body>
</TBX>

=== Custom Columns Not Converted to TBX
--- utx chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	tgt:custom	customer	concept ID
Hund	dog	noun	noun	approved	CUSTOM NOTE	SAP	C002
Hund	hound	noun	noun		however bloodhound is used rather than blooddog	SAP	C002
Katze	cat	noun	noun		CUSTOM NOTE	SAP	c008


--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Klaus-Dirk Schmidt</creator>
		<license>CC BY license can be freely copied and modified</license>
		<directionality>monodirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
		<entry id="C002">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>dog</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
			<entry id="C001">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>hound</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="c008">
			<langGroup xml:lang="de">
				<termGroup>
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>cat</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
		</entry>
	</body>
</TBX>
