#!/usr/bin/perl
use strict;
use warnings;
use t::TestUTX_TBX;
use Test::LongString;
plan tests => 1*blocks();

filters {
	tbx => 'convert_tbx',
};

for my $block(blocks()){
	is_string_nows($block->tbx, $block->output, "Expected");
}

__DATA__
=== Header
--- tbx chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Francis Bond (2008)</creator>
		<license>CC-by 3.0</license>
		<directionality>monodirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en-US"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
	</body>
</TBX>

--- output chomp
#UTX 1.11; de/en-US; 2013-12-20T17:00:45; copyright: Francis Bond (2008); license: CC-by 3.0; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos



=== Body
--- tbx chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<description>A short sample file demonstrating TBX-Min</description>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
		<languages source="de" target="en"/>
		<creator>Klaus-Dirk Schmidt</creator>
		<directionality>bidirectional</directionality>
		<license>CC BY license can be freely copied and modified</license>
	</header>
	<body>
		<entry id="C002">
		<subjectField>biology</subjectField>
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>dog</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
					<customer>SAP</customer>
				</termGroup>
				<termGroup>
					<term>hound</term>
					<termStatus>notRecommended</termStatus>
					<partOfSpeech>noun</partOfSpeech>
					<customer>SAP</customer>
					<note>however bloodhound is used rather than blooddog</note>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="c008">
		<subjectField>biology</subjectField>
			<langGroup xml:lang="de">
				<termGroup>
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>cat</term>
					<partOfSpeech>noun</partOfSpeech>
					<customer>SAP</customer>
				</termGroup>
			</langGroup>
		</entry>
	</body>
</TBX>

--- output chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	tgt:comment	customer	concept ID
Hund	dog	noun	noun	approved		SAP	C002
Hund	hound	noun	noun	non-standard	however bloodhound is used rather than blooddog	SAP	C002
Katze	cat	noun	noun			SAP	c008

=== test UTX conformant conversion of properNoun to noun
--- tbx chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<description>A short sample file demonstrating TBX-Min</description>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
		<languages source="de" target="en"/>
		<creator>Klaus-Dirk Schmidt</creator>
		<directionality>monodirectional</directionality>
		<license>CC BY license can be freely copied and modified</license>
	</header>
	<body>
		<entry id="C002">
		<subjectField>biology</subjectField>
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>dog</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
					<customer>SAP</customer>
				</termGroup>
				<termGroup>
					<term>hound</term>
					<termStatus>notRecommended</termStatus>
					<partOfSpeech>noun</partOfSpeech>
					<customer>SAP</customer>
					<note>however bloodhound is used rather than blooddog</note>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="c008">
		<subjectField>biology</subjectField>
			<langGroup xml:lang="de">
				<termGroup>
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>cat</term>
					<partOfSpeech>properNoun</partOfSpeech>
					<customer>SAP</customer>
				</termGroup>
			</langGroup>
		</entry>
	</body>
</TBX>

--- output chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	tgt:comment	customer	concept ID
Hund	dog	noun	noun	approved		SAP	C002
Hund	hound	noun	noun	non-standard	however bloodhound is used rather than blooddog	SAP	C002
Katze	cat	noun	noun			SAP	c008


=== Test conversion to valid use of bidirectional flag in UTX
--- tbx chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<description>A short sample file demonstrating TBX-Min</description>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
		<languages source="de" target="en"/>
		<creator>Klaus-Dirk Schmidt</creator>
		<directionality>bidirectional</directionality>
		<license>CC BY license can be freely copied and modified</license>
	</header>
	<body>
		<entry id="C002">
		<subjectField>biology</subjectField>
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>dog</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
					<customer>SAP</customer>
				</termGroup>
				<termGroup>
					<term>hound</term>
					<termStatus>admitted</termStatus>
					<partOfSpeech>noun</partOfSpeech>
					<customer>SAP</customer>
					<note>however bloodhound is used rather than blooddog</note>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="c008">
		<subjectField>biology</subjectField>
			<langGroup xml:lang="de">
				<termGroup>
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>cat</term>
					<partOfSpeech>noun</partOfSpeech>
					<customer>SAP</customer>
				</termGroup>
			</langGroup>
		</entry>
	</body>
</TBX>

--- output chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	tgt:comment	customer	concept ID
Hund	dog	noun	noun	approved		SAP	C002
Hund	hound	noun	noun	provisional	however bloodhound is used rather than blooddog	SAP	C002
Katze	cat	noun	noun			SAP	c008




=== Test conversion to valid use of bidirectional flag in UTX
--- tbx chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<description>A short sample file demonstrating TBX-Min</description>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
		<languages source="de" target="en"/>
		<creator>Klaus-Dirk Schmidt</creator>
		<directionality>bidirectional</directionality>
		<license>CC BY license can be freely copied and modified</license>
	</header>
	<body>
		<entry id="C002">
		<subjectField>biology</subjectField>
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>dog</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
					<customer>SAP</customer>
				</termGroup>
				<termGroup>
					<term>hound</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
					<customer>SAP</customer>
					<note>however bloodhound is used rather than blooddog</note>
				</termGroup>
			</langGroup>
		</entry>
		<entry id="c008">
		<subjectField>biology</subjectField>
			<langGroup xml:lang="de">
				<termGroup>
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>cat</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
					<customer>SAP</customer>
				</termGroup>
			</langGroup>
		</entry>
	</body>
</TBX>

--- output chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; bidirectional; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	tgt:comment	customer	concept ID
Hund	dog	noun	noun		SAP	C002
Hund	hound	noun	noun	however bloodhound is used rather than blooddog	SAP	C002
Katze	cat	noun	noun		SAP	c008