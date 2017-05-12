use strict;
use Test::More tests => 17;

BEGIN { use_ok('CDDB::Fake') };

my $data;
eval {
     $data = CDDB::Fake->new(\*DATA);
};
print STDERR $@ if $@;
ok($data, "load");

is($data->title, "Various", "title");
is($data->artist, "Various", "artist");
is($data->track_count, 6, "count");
is($data->extd, "Generated\nby\nls2nocddb\n", "extd");

my $track = ($data->tracks)[1];
is($track->number, 2, "number1");
is($track->title, "Fly Me To The Moon", "title1");
is($track->artist, "Dick Onstenk", "title1");
is($track->extd, "This is\na great recording.", "extt1");

$track = ($data->tracks)[2];
is($track->number, 3, "number2");
is($track->title, "Lover Man", "title2");
is($track->artist, "Various", "title2");

$track = ($data->tracks)[5];
is($track->number, 6, "number5");
is($track->title, "Softly As In A Morning Sunrise", "title5");
is($track->artist, "Dick Onstenk", "title5");
ok(!$track->length, "length5");

__DATA__
Various

     1. Body And Soul
     2. Dick Onstenk / Fly Me To The Moon
	This is\na great
	recording.
     3. Lover Man
     4. Freddie Freeloader
     5. Billie's Bounce
     6. Dick Onstenk: Softly As In A Morning Sunrise

Generated\nby\nls2nocddb
