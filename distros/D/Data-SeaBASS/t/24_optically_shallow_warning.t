#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
use Test::Trap qw(:default);

use Data::SeaBASS;

my @DATA = split(m"<BR/>\s*", join('', <DATA>));

trap {my $sb_file = Data::SeaBASS->new(\$DATA[0]);};
is($trap->leaveby, 'return', "warning trap");
like(join('',@{$trap->warn}), qr"optically_shallow", "warning 1");

trap {my $sb_file = Data::SeaBASS->new(\$DATA[1]);};
is($trap->leaveby, 'return', "no warning trap");
is(join('',@{$trap->warn}), '', "warning 2");

trap {my $sb_file = Data::SeaBASS->new(\$DATA[0], {optional_warnings => 0});};
is($trap->leaveby, 'return', "disabled warnings trap");
is(join('',@{$trap->warn}), '', "warning 3");

__DATA__
/begin_header
/missing=-999
/below_detection_limit=-888
/above_detection_limit=-777
/data_use_warning=optically_shallow
/delimiter=space
/fields=date,time,lat,lon,depth,wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 -999 -111
19920109 16:30:00 31.389 -64.702 3.4 -888 -111
19920109 16:30:00 31.389 -64.702 3.4 -777 -111
<BR/>
/begin_header
/missing=-999
/below_detection_limit=-888
/above_detection_limit=-777
/data_use_warning=
/delimiter=space
/fields=date,time,lat,lon,depth,wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 -999 -111
19920109 16:30:00 31.389 -64.702 3.4 -888 -111
19920109 16:30:00 31.389 -64.702 3.4 -777 -111
