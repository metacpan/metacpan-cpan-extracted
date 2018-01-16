#!perl -T
use v5.22;

use strict;
use warnings;
use Test::More tests => 52;
use Test::Exception;

use Time::Piece;
use Date::Lectionary::Daily;

my $testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-03-11", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{1},
    'Exodus 1:1-14, (15-21); 1:22-2:10',
	'The first reading for morning prayer on 2017-03-11 should be Exodus 1:1-14, (15-21); 1:22-2:10'
);

$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-03-11", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    'Colossians 1:21-2:7',
	'The first reading for morning prayer on 2017-03-11 should be Colossians 1:21-2:7'
);

#Lectionary Week: The Sixth Sunday of Epiphany -- Day: Thursday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2025-2-20", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{1},
    'Baruch 4:36-5:end',
	'The second reading for morning prayer on 2025-2-20 should be Baruch 4:36-5:end'
);

#Lectionary Week: Sunday Closest to October 26 -- Day: Sunday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2016-10-23", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    'Matthew 18:1-20',
	'The second reading for morning prayer on 2016-10-23 should be Matthew 18:1-20'
);

#Lectionary Week: The Sunday after Ascension Day -- Day: Thursday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2024-5-16", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{1},
    'Judges 11:29-12:7',
	'The second reading for morning prayer on 2024-5-16 should be Judges 11:29-12:7'
);

#Lectionary Week: Easter Day -- Day: Tuesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2023-4-11", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    '1 Peter 1:1-12',
	'The second reading for morning prayer on 2023-4-11 should be 1 Peter 1:1-12'
);

#Lectionary Week: Sunday Closest to September 28 -- Day: Monday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-10-2", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    '1 Timothy 1:1-17',
	'The second reading for morning prayer on 2017-10-2 should be 1 Timothy 1:1-17'
);

#Lectionary Week: The Second Sunday in Advent -- Day: Sunday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2025-12-7", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{1},
    'Isaiah 5:(17-30); 5:18-end',
	'The second reading for morning prayer on 2025-12-7 should be Isaiah 5:(17-30); 5:18-end'
);

#Lectionary Week: Sunday Closest to June 29 -- Day: Friday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2025-7-4", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    'Romans 14',
	'The second reading for morning prayer on 2025-7-4 should be Romans 14'
);

#Lectionary Week: Sunday Closest to September 14 -- Day: Tuesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2024-9-17", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    'John 18:1-27',
	'The second reading for morning prayer on 2024-9-17 should be John 18:1-27'
);

#Lectionary Week: Sunday Closest to August 17 -- Day: Thursday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2016-8-18", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{1},
    '2 Kings 18:1-8, (9-12)',
	'The second reading for morning prayer on 2016-8-18 should be 2 Kings 18:1-8, (9-12)'
);

#Lectionary Week: The Second Sunday of Christmas -- Day: Monday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2024-1-8", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    'Galatians 1',
	'The second reading for morning prayer on 2024-1-8 should be Galatians 1'
);

#Lectionary Week: Sunday Closest to August 3 -- Day: Tuesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2021-8-3", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    'Luke 21:5-end',
	'The second reading for morning prayer on 2021-8-3 should be Luke 21:5-end'
);

#Lectionary Week: Sunday Closest to October 5 -- Day: Wednesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2024-10-9", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    'Hebrews 11:17-end',
	'The second reading for morning prayer on 2024-10-9 should be Hebrews 11:17-end'
);

#Lectionary Week: Sunday Closest to September 14 -- Day: Thursday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2023-9-21", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    '1 Thessalonians 1',
	'The second reading for morning prayer on 2023-9-21 should be 1 Thessalonians 1'
);

#Lectionary Week: Sunday Closest to October 12 -- Day: Tuesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2025-10-14", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    'James 2:1-13',
	'The second reading for morning prayer on 2025-10-14 should be James 2:1-13'
);

#Lectionary Week: Sunday Closest to November 2 -- Day: Tuesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2024-11-5", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    'Acts 10:1-23',
	'The second reading for morning prayer on 2024-11-5 should be Acts 10:1-23'
);

#Lectionary Week: Sunday Closest to August 17 -- Day: Monday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2022-8-15", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    'John 3:1-21',
	'The second reading for morning prayer on 2022-8-15 should be John 3:1-21'
);

#Lectionary Week: The Fourth Sunday in Advent -- Day: Wednesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2018-12-26", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{1},
    '2 Chronicles 24:15-22',
	'The second reading for morning prayer on 2018-12-26 should be 2 Chronicles 24:15-22'
);

#Lectionary Week: Sunday Closest to August 24 -- Day: Monday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-8-28", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    'Ephesians 2:11-end',
	'The second reading for morning prayer on 2017-8-28 should be Ephesians 2:11-end'
);

#Lectionary Week: The Second Sunday of Epiphany -- Day: Saturday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2023-1-21", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{1},
    'Habakkuk 1',
	'The second reading for morning prayer on 2023-1-21 should be Habakkuk 1'
);

#Lectionary Week: Sunday Closest to October 5 -- Day: Sunday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2019-10-6", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{1},
    'Jonah 3-4',
	'The second reading for morning prayer on 2019-10-6 should be Jonah 3-4'
);

#Lectionary Week: Sunday Closest to September 7 -- Day: Saturday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2020-9-12", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    'Colossians 2:20-3:11',
	'The second reading for morning prayer on 2020-9-12 should be Colossians 2:20-3:11'
);

#Lectionary Week: Sunday Closest to September 28 -- Day: Wednesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2024-10-2", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    '1 Timothy 3',
	'The second reading for morning prayer on 2024-10-2 should be 1 Timothy 3'
);

#Lectionary Week: Sunday Closest to August 24 -- Day: Saturday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2025-8-30", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{1},
    'Jeremiah 27:2-end',
	'The second reading for morning prayer on 2025-8-30 should be Jeremiah 27:2-end'
);

#Lectionary Week: The Fifth Sunday in Lent -- Day: Thursday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2024-3-21", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    '2 Timothy 2',
	'The second reading for morning prayer on 2024-3-21 should be 2 Timothy 2'
);

#Lectionary Week: The First Sunday in Lent -- Day: Thursday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2016-2-18", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{1},
    'Genesis 47:13-end',
	'The second reading for morning prayer on 2016-2-18 should be Genesis 47:13-end'
);

#Lectionary Week: The Fourth Sunday of Easter -- Day: Tuesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2018-4-24", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    'Acts 16:6-end',
	'The second reading for morning prayer on 2018-4-24 should be Acts 16:6-end'
);

#Lectionary Week: Sunday Closest to August 31 -- Day: Thursday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2023-9-7", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    'Philippians 1:12-end',
	'The second reading for morning prayer on 2023-9-7 should be Philippians 1:12-end'
);

#Lectionary Week: Sunday Closest to November 16 -- Day: Sunday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2025-11-16", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    'Luke 20:1-19',
	'The second reading for morning prayer on 2025-11-16 should be Luke 20:1-19'
);

#Lectionary Week: Sunday Closest to July 6 -- Day: Friday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2016-7-8", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{1},
    '2 Samuel 2:1-3:1',
	'The second reading for morning prayer on 2016-7-8 should be 2 Samuel 2:1-3:1'
);

#Lectionary Week: Sunday Closest to July 6 -- Day: Sunday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2020-7-5", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    'Acts 8:4-17',
	'The second reading for morning prayer on 2020-7-5 should be Acts 8:4-17'
);

#Lectionary Week: The First Sunday in Advent -- Day: Saturday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2025-12-6", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    'Revelation 11',
	'The second reading for morning prayer on 2025-12-6 should be Revelation 11'
);

#Lectionary Week: The Second Sunday of Christmas -- Day: Tuesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2025-1-7", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    'Matthew 6:1-18',
	'The second reading for morning prayer on 2025-1-7 should be Matthew 6:1-18'
);

#Lectionary Week: The First Sunday in Advent -- Day: Monday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-12-4", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    'Mark 1:1-20',
	'The second reading for morning prayer on 2017-12-4 should be Mark 1:1-20'
);

#Lectionary Week: Sunday Closest to October 26 -- Day: Tuesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2024-10-29", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{1},
    '1 Maccabees 2:1-28',
	'The second reading for morning prayer on 2024-10-29 should be 1 Maccabees 2:1-28'
);

#Lectionary Week: The Fourth Sunday in Lent -- Day: Tuesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2022-3-29", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{1},
    'Exodus (27); 28:1-4, (5-28), 29-43',
	'The second reading for morning prayer on 2022-3-29 should be Exodus (27); 28:1-4, (5-28), 29-43'
);

#Lectionary Week: The First Sunday in Lent -- Day: Wednesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2019-3-13", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{1},
    'Genesis 46:26-47:12',
	'The second reading for morning prayer on 2019-3-13 should be Genesis 46:26-47:12'
);

#Lectionary Week: Sunday Closest to November 9 -- Day: Friday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2020-11-13", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    'Acts 20:1-16',
	'The second reading for morning prayer on 2020-11-13 should be Acts 20:1-16'
);

#Lectionary Week: Easter Day -- Day: Saturday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2018-4-7", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{1},
    'Jeremiah 31:1-14',
	'The second reading for morning prayer on 2018-4-7 should be Jeremiah 31:1-14'
);

#Lectionary Week: The Third Sunday in Advent -- Day: Wednesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2016-12-14", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    'Revelation 20',
	'The second reading for morning prayer on 2016-12-14 should be Revelation 20'
);

#Lectionary Week: The Fifth Sunday of Epiphany -- Day: Monday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2019-2-11", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{1},
    'Tobit 4:5-19',
	'The second reading for morning prayer on 2019-2-11 should be Tobit 4:5-19'
);

#Lectionary Week: Sunday Closest to August 24 -- Day: Wednesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-8-30", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    'John 6:41-end',
	'The second reading for morning prayer on 2017-8-30 should be John 6:41-end'
);

#Lectionary Week: Sunday Closest to November 16 -- Day: Monday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2018-11-19", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    'Acts 21:17-36',
	'The second reading for morning prayer on 2018-11-19 should be Acts 21:17-36'
);

#Lectionary Week: The Second Sunday of Epiphany -- Day: Friday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2019-1-25", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    '1 Corinthians 15:1-34',
	'The second reading for morning prayer on 2019-1-25 should be 1 Corinthians 15:1-34'
);

#Lectionary Week: Sunday Closest to July 20 -- Day: Friday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2016-7-22", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    '1 Corinthians 14:20-end',
	'The second reading for morning prayer on 2016-7-22 should be 1 Corinthians 14:20-end'
);

#Lectionary Week: Sunday Closest to July 13 -- Day: Tuesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2019-7-16", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    '1 Corinthians 6',
	'The second reading for morning prayer on 2019-7-16 should be 1 Corinthians 6'
);

#Lectionary Week: Easter Day -- Day: Friday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2019-4-26", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{1},
    'Song of Solomon 6:1-7:10',
	'The second reading for morning prayer on 2019-4-26 should be Song of Solomon 6:1-7:10'
);

#Lectionary Week: Sunday Closest to November 2 -- Day: Sunday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2018-11-4", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{2},
    'Matthew 21:12-32',
	'The second reading for morning prayer on 2018-11-4 should be Matthew 21:12-32'
);

#Lectionary Week: The Fifth Sunday in Lent -- Day: Tuesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2019-4-9", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    'John 11:1-44',
	'The second reading for morning prayer on 2019-4-9 should be John 11:1-44'
);

#Lectionary Week: The Transfiguration -- Day: Tuesday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-8-9", "%Y-%m-%d" ) );
is(
    $testReading->readings->{morning}->{2},
    '2 Corinthians 7:2-end',
    'The second reading for morning prayer on 2017-8-9 should be 2 Corinthians 7:2-end'
);

#Lectionary Week: Christ the King -- Day: Monday
$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-11-27", "%Y-%m-%d" ) );
is(
    $testReading->readings->{evening}->{1},
    'Wisdom 2',
    'The first reading for evening prayer on 2017-11-27 should be Wisdom 2'
);