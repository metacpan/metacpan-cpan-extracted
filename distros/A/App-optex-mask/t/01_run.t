use strict;
use warnings;
use utf8;
use Test::More;

use lib '.';
use t::Util;

my $txt = <<END;
ROT13 (Rotate13, "rotate by 13 places", sometimes hyphenated ROT-13) is
a simple letter substitution cipher that replaces a letter with the 13th
letter after it in the Latin alphabet. ROT13 is a special case of the
Caesar cipher which was developed in ancient Rome.
END

my @rot13 = ('perl', '-pE',
             's/\G(?|(.*?)(<m id=\d+ \/>)|(.+)())/$1 =~ tr[a-zA-Z][n-za-mN-ZA-M]r . $2/ge');

is( optex(@rot13)->setstdin($txt)->run->stdout, <<END
EBG13 (Ebgngr13, "ebgngr ol 13 cynprf", fbzrgvzrf ulcurangrq EBG-13) vf
n fvzcyr yrggre fhofgvghgvba pvcure gung ercynprf n yrggre jvgu gur 13gu
yrggre nsgre vg va gur Yngva nycunorg. EBG13 vf n fcrpvny pnfr bs gur
Pnrfne pvcure juvpu jnf qrirybcrq va napvrag Ebzr.
END
, 'rot13');

is( optex(qw(-Mmask (?i)ROT-?13 --), @rot13)->setstdin($txt)->run->stdout, <<END
ROT13 (Ebgngr13, "ebgngr ol 13 cynprf", fbzrgvzrf ulcurangrq ROT-13) vf
n fvzcyr yrggre fhofgvghgvba pvcure gung ercynprf n yrggre jvgu gur 13gu
yrggre nsgre vg va gur Yngva nycunorg. ROT13 vf n fcrpvny pnfr bs gur
Pnrfne pvcure juvpu jnf qrirybcrq va napvrag Ebzr.
END
, 'rot13 w/mask');

is( optex(qw(-Mmask::set=decode=0 (?i)ROT-?13 --), @rot13)->setstdin($txt)->run->stdout, <<END
<m id=1 /> (Ebgngr13, "ebgngr ol 13 cynprf", fbzrgvzrf ulcurangrq <m id=2 />) vf
n fvzcyr yrggre fhofgvghgvba pvcure gung ercynprf n yrggre jvgu gur 13gu
yrggre nsgre vg va gur Yngva nycunorg. <m id=3 /> vf n fcrpvny pnfr bs gur
Pnrfne pvcure juvpu jnf qrirybcrq va napvrag Ebzr.
END
, 'rot13 w/mask decode=0');

no warnings 'qw';
is( optex(qw(-Mmask::set=decode=0,start=1001 (?i)ROT-?13 --), @rot13)->setstdin($txt)->run->stdout, <<END
<m id=1001 /> (Ebgngr13, "ebgngr ol 13 cynprf", fbzrgvzrf ulcurangrq <m id=1002 />) vf
n fvzcyr yrggre fhofgvghgvba pvcure gung ercynprf n yrggre jvgu gur 13gu
yrggre nsgre vg va gur Yngva nycunorg. <m id=1003 /> vf n fcrpvny pnfr bs gur
Pnrfne pvcure juvpu jnf qrirybcrq va napvrag Ebzr.
END
, 'rot13 w/mask decode=0,start=1001');

done_testing;
