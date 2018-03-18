#!perl -T
use v5.22;

use strict;
use warnings;
use Test::More tests => 31;
use Test::Exception;

use Time::Piece;
use Date::Lectionary::Daily;

my $testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-12-24", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{1}, 
    'Isaiah 51', 
    'The first reading for morning prayer on 2018- should be Isaiah 51' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-03-12", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{2}, 
    'Matthew 5', 
    'The second reading for morning prayer on 2018-03-12 should be Matthew 5' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-12-01", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{1}, 
    'Isaiah 6', 
    'The first reading for evening prayer on 2018-12-01 should be Isaiah 6' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-01-25", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{2}, 
    '1 Corinthians 10', 
    'The second reading for evening prayer on 2018-01-25 should be 1 Corinthians 10' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-07-20", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{1}, 
    'Ezekiel 46', 
    'The first reading for morning prayer on 2018-07-20 should be Ezekiel' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-07-04", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{2}, 
    'Acts 15:1-21', 
    'The second reading for morning prayer on 2018-07-04 should be Acts 15:1-21' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-12-25", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{1}, 
    'Isaiah 54', 
    'The first reading for evening prayer on 2018-12-25 should be Isaiah 54' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-04-01", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{2}, 
    '1 Timothy 5', 
    'The second reading for evening prayer on 2018-04-01 should be 1 Timothy 5' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-03-15", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{1}, 
    'Joshua 5', 
    'The first reading for morning prayer on 2018-03-15 should be Joshua 5' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-01-01", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{2}, 
    'John 1:1-28', 
    'The second reading for morning prayer on 2018-01-01 should be John 1:1-28' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-02-14", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{1}, 
    'Exodus 39', 
    'The first reading for evening prayer on 2018-02-14 should be Exodus 39' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-11-01", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{2}, 
    'Matthew 22:34-23:12', 
    'The second reading for evening prayer on 2018-11-01 should be Matthew 22:34-23:12' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-10-31", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{1}, 
    'Ecclesiasticus 34', 
    'The first reading for morning prayer on 2018-10-31 should be Ecclesiasticus 34' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2016-02-29", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{2}, 
    'Mark 13:14-end', 
    'The second reading for morning prayer on 2018-02-29 should be Mark 13:14-end' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-01-06", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{1}, 
    'Genesis 12', 
    'The first reading for evening prayer on 2018-01-06 should be Genesis 12' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-11-14", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{2}, 
    'Luke 1:24-56', 
    'The second reading for evening prayer on 2018-11-14 should be Luke 1:24-56' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-09-17", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{1}, 
    'Proverbs 4', 
    'The first reading for morning prayer on 2018-09-17 should be Proverbs 4' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-12-19", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{2}, 
    'Revelation 21:1-14', 
    'The second reading for morning prayer on 2018-12-19 should be Revelation 21:1-14' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-06-01", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{1}, 
    'Jeremiah 5', 
    'The first reading for evening prayer on 2018-06-01 should be Jeremiah 5' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-06-18", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{2}, 
    '1 Corinthians 14:20-end', 
    'The second reading for evening prayer on 2018-06-18 should be 1 Corinthians 14:20-end' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-08-04", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{1}, 
    'Ezra 6', 
    'The first reading for morning prayer on 2018-08-04 should be Ezra 6' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-08-23", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{2}, 
    '1 Timothy 5', 
    'The second reading for morning prayer on 2018-08-23 should be 1 Timothy 5' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-03-02", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{1}, 
    'Deuteronomy 14', 
    'The first reading for evening prayer on 2018-03-02 should be Deuteronomy 14' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-09-09", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{2}, 
    'Mark 6:30-end', 
    'The second reading for evening prayer on 2018-09-09 should be Mark 6:30-end' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-10-07", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{1}, 
    'Job 13', 
    'The first reading for morning prayer on 2018-10-07 should be Job 13' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-11-28", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{2}, 
    'Revelation 1', 
    'The second reading for morning prayer on 2018-11-28 should be Revelation 1' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-01-24", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{1}, 
    'Genesis 48', 
    'The first reading for evening prayer on 2018-01-24 should be Genesis 48' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-02-28", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{2}, 
    'Romans 12', 
    'The second reading for evening prayer on 2018-02-28 should be Romans 12' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-04-16", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{1}, 
    '1 Samuel 25', 
    'The first reading for morning prayer on 2018-04-16 should be 1 Samuel 25' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-05-26", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{morning}->{2}, 
    'Luke 17:20-end', 
    'The second reading for morning prayer on 2018-05-26 should be Luke 17:20-end' 
);

$testReading = Date::Lectionary::Daily->new( 
    'date' => Time::Piece->strptime( "2018-12-29", "%Y-%m-%d" ), 
    'lectionary' => 'acna-sec' 
);
is( 
    $testReading->readings->{evening}->{1}, 
    'Isaiah 62', 
    'The first reading for evening prayer on 2018-12-29 should be Isaiah 62' 
);