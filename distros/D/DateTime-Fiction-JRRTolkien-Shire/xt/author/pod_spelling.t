package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::Spelling;
	1;
    } or do {
	print "1..0 # skip Test::Spelling not available.\n";
	exit;
    };
    Test::Spelling->import();
}

add_stopwords (<DATA>);

all_pod_files_spelling_ok ();

1;
__DATA__
Afterlithe
Braun
dow
doy
durations
Forelithe
Hevensday
Houghton
iso
mday
merchantability
Mersday
Mifflin
mon
Overlithe
Rethe
Rolsky
rata
Specio
Sterday
th
Trewsday
TRW
wday
Wedmath
Wyant
