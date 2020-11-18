use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok('AudioFile::Info'); }

my $song = AudioFile::Info->new('t/test.mp3',
                                { mp3 => 'AudioFile::Info::MP3::Tag' });
is(ref $song, 'AudioFile::Info::MP3::Tag');
is($song->title, 'test');
is($song->artist, 'davorg');
is($song->album, 'none');
is($song->track, '0');
is($song->year, '2003');
is($song->genre, 'nonsense');
