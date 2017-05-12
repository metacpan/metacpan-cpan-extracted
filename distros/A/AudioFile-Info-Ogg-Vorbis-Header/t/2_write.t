# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
use AudioFile::Info;
ok(1);

use File::Copy;
use FindBin qw($Bin);

copy "$Bin/test.ogg", "$Bin/test2.ogg";

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $song = AudioFile::Info->new('t/test2.ogg',
                                { ogg => 'AudioFile::Info::Ogg::Vorbis::Header' });
isa_ok($song, 'AudioFile::Info::Ogg::Vorbis::Header');
is($song->title, 'test');
is($song->artist, 'davorg');
is($song->album, 'none');
is($song->track, '00');
is($song->year, '2003');
is($song->genre, 'nonsense');
$song->genre('xxx');
$song->title('xxx');
$song->artist('xxx');
$song->album('xxx');
$song->track('1');
$song->year('2000');

undef $song;

$song = AudioFile::Info->new('t/test2.ogg',
                             { ogg => 'AudioFile::Info::Ogg::Vorbis::Header' });
isa_ok($song, 'AudioFile::Info::Ogg::Vorbis::Header');
is($song->genre, 'xxx');
is($song->title, 'xxx');
is($song->artist, 'xxx');
is($song->album, 'xxx');
is($song->track, '1');
is($song->year, '2000');

unlink("$Bin/test2.ogg");

done_testing();
