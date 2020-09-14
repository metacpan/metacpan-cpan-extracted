use strict;
use warnings;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;

BEGIN { use_ok('AudioFile::Info') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $song = AudioFile::Info->new('t/test.mp3',
                                { mp3 => 'AudioFile::Info::MP3::ID3Lib' });
is(ref $song, 'AudioFile::Info::MP3::ID3Lib');
is($song->title, 'test');
is($song->artist, 'davorg');
is($song->album, 'none');
is($song->track, '0');
is($song->year, '2003');
is($song->genre, 'nonsense');
