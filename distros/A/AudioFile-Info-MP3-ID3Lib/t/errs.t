use strict;
use warnings;

use Test::More;
use Test::Exception;

use AudioFile::Info::MP3::ID3Lib;

throws_ok {
  my $x = AudioFile::Info::MP3::ID3Lib->new;
} qr/without an MP3 file/, 'Correct error without a file';

done_testing;
