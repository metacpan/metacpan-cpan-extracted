use strict;
use Test::More tests => 18;

# here we test code will not segfault
# eg everything should failed, but we should
# reach the end

BEGIN { use_ok('DVD::Read::Dvd') };
BEGIN { use_ok('DVD::Read::Dvd::File') };
BEGIN { use_ok('DVD::Read::Dvd::Ifo') };

my $testdir = 'tdvd';

{ # start with shadock, cd n°1

ok(my $dvd = DVD::Read::Dvd->new("$testdir/shadok1"), "can open dvd");
ok(my $file = DVD::Read::Dvd::File->new($dvd, 1, 'IFO'), "can open video file");
ok(!DVD::Read::Dvd::File->new($dvd, 1, 'NAWAK'), "cannot open wrong type file");
ok(my $ifo = DVD::Read::Dvd::Ifo->new($dvd, 1), "can open ifo file");
ok(my $vmg = DVD::Read::Dvd::Ifo->new($dvd, 0), "can open ifo file");

ok(! DVD::Read::Dvd::Ifo->new($dvd, 45), "cannot get non existing IFO");
ok(! DVD::Read::Dvd::Ifo->new($dvd, -1), "cannot get negative IFO");
ok(! $vmg->title_chapters_count(-1), "cannot get chapter count on negative title");
ok(! $vmg->title_chapters_count(45), "cannot get chapter count on excessive title");
ok(! $ifo->vts_audio_id(456), "cannot get audio on excessive id");
ok(! $ifo->vts_audio_id(-2), "cannot get audio id with negative id");

ok(! DVD::Read::Dvd::File->new($dvd, 45, 'IFO'), 'cannot get non existing IFO file');
ok(! DVD::Read::Dvd::File->new($dvd, -1, 'IFO'), 'cannot get negative IFO file');
ok(! $file->readblock(-1, 1), "cannot read negative block");
ok(! $file->readblock(0, -1), "cannot read negative block count");
}
