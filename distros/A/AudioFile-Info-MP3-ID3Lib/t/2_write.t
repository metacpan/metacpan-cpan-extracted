# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 15;

BEGIN { use_ok('AudioFile::Info') };

use File::Copy;
use FindBin qw($Bin);

copy "$Bin/test.mp3", "$Bin/test2.mp3";

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $song = AudioFile::Info->new('t/test2.mp3',
                                { mp3 => 'AudioFile::Info::MP3::ID3Lib' });
is(ref $song, 'AudioFile::Info::MP3::ID3Lib');
is($song->title, 'test');
is($song->artist, 'davorg');
is($song->album, 'none');
is($song->track, '0');
is($song->year, '2003');
is($song->genre, 'nonsense');

$song->title('xxx');
$song->artist('xxx');
$song->album('xxx');
$song->track('1');
$song->year('2000');
$song->genre('xxx');

undef $song;

$song = AudioFile::Info->new('t/test2.mp3',
                             { mp3 => 'AudioFile::Info::MP3::ID3Lib' });
is(ref $song, 'AudioFile::Info::MP3::ID3Lib');
is($song->title, 'xxx');
is($song->artist, 'xxx');
is($song->album, 'xxx');
is($song->track, '1');
is($song->year, '2000');
SKIP: {
  skip 'Writing genre doesn\'t work reliably', 1;
  is($song->genre, 'xxx');
}

unlink("$Bin/test2.mp3");
