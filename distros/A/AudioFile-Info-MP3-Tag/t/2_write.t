use Test::More tests => 15;

BEGIN { use_ok('AudioFile::Info'); }

use File::Copy;
use FindBin qw($Bin);

copy "$Bin/test.mp3", "$Bin/test2.mp3";

my $song = AudioFile::Info->new('t/test2.mp3',
                                { mp3 => 'AudioFile::Info::MP3::Tag' });
ok(ref $song eq 'AudioFile::Info::MP3::Tag');
ok($song->title eq 'test');
ok($song->artist eq 'davorg');
ok($song->album eq 'none');
ok($song->track eq '0');
ok($song->year eq '2003');
ok($song->genre eq 'nonsense');
$song->genre('xxx');
$song->title('xxx');
$song->artist('xxx');
$song->album('xxx');
$song->track('1');
$song->year('2000');

undef $song;

$song = AudioFile::Info->new('t/test2.mp3',
                             { mp3 => 'AudioFile::Info::MP3::Tag' });
ok(ref $song eq 'AudioFile::Info::MP3::Tag');
ok($song->genre eq 'xxx');
ok($song->title eq 'xxx');
ok($song->artist eq 'xxx');
ok($song->album eq 'xxx');
ok($song->track eq '1');
ok($song->year eq '2000');

unlink("$Bin/test2.mp3");
