use strict;
use warnings;

use Test::More tests => 15;

BEGIN { use_ok('AudioFile::Info') }

use File::Copy;
use FindBin qw($Bin);

SKIP: {
  skip "AudioFile::Info::Ogg::Vorbis::Header::PurePerl doesn't support writing yet", 14;

  copy "$Bin/test.ogg", "$Bin/test2.ogg";

  my $song = AudioFile::Info->new('t/test2.ogg',
                                  { ogg => 'AudioFile::Info::Ogg::Vorbis::Header::PurePerl' });
  is(ref $song, 'AudioFile::Info::Ogg::Vorbis::Header::PurePerl');
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

  $song = AudioFile::Info->new('t/test2.ogg',
                               { ogg => 'AudioFile::Info::Ogg::Vorbis::Header::PurePerl' });
  is(ref $song, 'AudioFile::Info::Ogg::Vorbis::Header::PurePerl');
  is($song->title, 'xxx');
  is($song->artist, 'xxx');
  is($song->album, 'xxx');
  is($song->track, '1');
  is($song->year, '2000');
  is($song->genre, 'xxx');

  unlink("$Bin/test2.ogg");
}
