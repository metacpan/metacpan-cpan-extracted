use strict;
use Test::More tests => 17;
BEGIN { use_ok('DVD::Read::Dvd') };
BEGIN { use_ok('DVD::Read::Dvd::Ifo') };
BEGIN { use_ok('DVD::Read::Dvd::Ifo::Pgc') };

my $testdir = 'tdvd';

{ # pgn tests
ok(my $dvd = DVD::Read::Dvd->new("$testdir/idiocracy"), "can open dvd");
ok(my $ifo = DVD::Read::Dvd::Ifo->new($dvd, 0), "can get main ifo");
ok(my $vtsifo = DVD::Read::Dvd::Ifo->new($dvd, 5), "can get ifo 1");
is(my $ttn = $ifo->title_ttn(1), 1, "Can get ttn");
is(my $pgcid = $vtsifo->vts_pgc_id($ttn, 1), 1, 'can get pgn');
ok(my $pgc = $vtsifo->vts_pgc($pgcid), 'can get pgc');
is(my $pgc_num = $vtsifo->vts_pgc_num($ttn, 1), 1, "can get pgc_num");
$vtsifo = undef;
is($pgc->id, $pgcid, 'can get pgn from pgc object');
is($pgc->_programs_count, 21, 'can get programs count');
is($pgc->cells_count, 33, 'can get cells count');
is($pgc->cell_number($pgc_num), 1, "can get cell number");
ok(my $cell = $pgc->cell($pgc->cell_number($pgc_num)), "can get cell");
$pgc = undef;
is($cell->first_sector, 0, "can get first sector");
is($cell->cellid, 1, "can et cell id");
}
