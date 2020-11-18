use strict;
use warnings;

use Test::More tests => 15;

BEGIN { use_ok('AudioFile::Info'); }

use File::Copy;
use FindBin qw($Bin);

copy "$Bin/test.mp3", "$Bin/test2.mp3";

my $song = AudioFile::Info->new('t/test2.mp3',
                                { mp3 => 'AudioFile::Info::MP3::Tag' });
is(ref $song, 'AudioFile::Info::MP3::Tag');
is($song->title, 'test');
is($song->artist, 'davorg');
is($song->album, 'none');
is($song->track, '0');
is($song->year, '2003');
is($song->genre, 'nonsense');
$song->genre('xxx');
$song->title('xxx');
$song->artist('xxx');
$song->album('xxx');
$song->track('1');
$song->year('2000');

undef $song;

$song = AudioFile::Info->new('t/test2.mp3',
                             { mp3 => 'AudioFile::Info::MP3::Tag' });
is(ref $song, 'AudioFile::Info::MP3::Tag');
is($song->genre, 'xxx');
is($song->title, 'xxx');
is($song->artist, 'xxx');
is($song->album, 'xxx');
is($song->track, '1');
is($song->year, '2000');

unlink("$Bin/test2.mp3");
