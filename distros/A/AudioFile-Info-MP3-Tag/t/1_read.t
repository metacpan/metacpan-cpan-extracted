use Test::More tests => 8;
BEGIN { use_ok('AudioFile::Info'); }

my $song = AudioFile::Info->new('t/test.mp3',
                                { mp3 => 'AudioFile::Info::MP3::Tag' });
ok(ref $song eq 'AudioFile::Info::MP3::Tag');
ok($song->title eq 'test');
ok($song->artist eq 'davorg');
ok($song->album eq 'none');
ok($song->track eq '0');
ok($song->year eq '2003');
ok($song->genre eq 'nonsense');
