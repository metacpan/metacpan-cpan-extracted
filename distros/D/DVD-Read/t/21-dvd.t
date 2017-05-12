use strict;
use Test::More tests => 16;
BEGIN { use_ok('DVD::Read') };
BEGIN { use_ok('DVD::Read::Title') };

my $testdir = 'tdvd';

ok(my $dvd = DVD::Read->new('tdvd/idiocracy'), "Can get a DVD::Read object");
isa_ok($dvd, 'DVD::Read');
is($dvd->titles_count, 11, 'can get title count');
is($dvd->title_chapters_count(1), 21, 'can get chapters for title 1 count');
ok(!$dvd->volid, 'can try to get volid');

ok(my $title = $dvd->get_title(1), "Can get title 1");
isa_ok($title, 'DVD::Read::Title');
is($title->title_nr, 5, "can get title_nr from title");
is($title->chapters_count, 21, "Can get chapters count from title");
my @audios = $title->audios;
is(scalar(@audios), 2, "Can get audio count");
is($title->chapter_first_sector(1), 0, "can get first sector");
is($title->length, 5_047_300, "Can get title length");
eval {
    $title->xxxxxxx();
};
ok($@, 'calling non exitant function failed');
eval {
    $dvd->xxxxxxx();
};
ok($@, 'calling non exitant function failed');
