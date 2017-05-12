use strict;
use warnings FATAL => 'all';

use Apache::TestRequest;

#  a dummy request to / to get the scoreboard counters going
my $discard = GET_BODY "/index.html";

print GET_BODY_ASSERT "/TestInternal__basic";
