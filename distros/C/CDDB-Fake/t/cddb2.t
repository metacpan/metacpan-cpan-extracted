use strict;
use Test::More tests => 3;

BEGIN { use_ok('CDDB::Fake') };

my $data;
eval {
     $data = CDDB::Fake->new(\*DATA);
};
print STDERR $@ if $@;
ok($data, "load");

is($data->as_cddb, <<'EOD', "as_cddb");
# xmcd 2.0 CD database file
# Copyright (C) 1996,2004 Johan Vromans
#
DISCID=00000000
DTITLE=Various / Various
TTITLE0=Body And Soul
TTITLE1=Fly Me To The Moon
TTITLE2=Lover Man
TTITLE3=Freddie Freeloader
TTITLE4=Billie's Bounce
TTITLE5=Softly As In A Morning Sunrise
EXTD=Generated\nby\nls2nocddb
EXTT0=
EXTT1=This is\na great recording.
EXTT2=
EXTT3=
EXTT4=
EXTT5=
PLAYORDER=
EOD

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
