use strict;
use warnings;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
use AudioFile::Info;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $song = AudioFile::Info->new('t/test.ogg',
                            { ogg => 'AudioFile::Info::Ogg::Vorbis::Header' });
isa_ok($song, 'AudioFile::Info::Ogg::Vorbis::Header');
is($song->title, 'test');
is($song->artist, 'davorg');
is($song->album, 'none');
is($song->track, '00');
is($song->year, '2003');
is($song->genre, 'nonsense');

done_testing();
