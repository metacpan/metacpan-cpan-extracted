use strict;
use warnings;

use Test::More;

BEGIN { use_ok 'AudioFile::Info' }

my $song = AudioFile::Info->new('t/test.mp3',
                                { mp3 => 'AudioFile::Info::MP3::Info' });
ok(ref $song eq 'AudioFile::Info::MP3::Info');
ok($song->title eq 'test');
ok($song->artist eq 'davorg');
ok($song->album eq 'none');
ok($song->track eq '0');
ok($song->year eq '2003');
ok($song->genre eq 'nonsense');

done_testing();
