# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Audio-Digest-MP3.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 2 };

use Audio::Digest::MP3;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

(my $file = __FILE__) =~ s/[\w\-.]+$/dark.mp3/;
my $streaminfo = Audio::Digest::MP3->scan($file, 'MD5');

is_deeply(
	{
        stream_size => $streaminfo->bytes,
        file_size => -s $file,
        bitrate => $streaminfo->bitrate,
        playing_time => $streaminfo->playing_time(2),
        md5 => $streaminfo->digest,
    },
    {
        'stream_size' => 50155,
        'file_size'  => 50283,
        'bitrate' => 96,
        'playing_time' => '0:04.18',
        'md5' => '4c3167f3e93ec657e489c6945a2d1406',
    },
	'Scan results are as expected');
