package SlowStart;

# Test aid: load EV, then let 3 seconds pass without running the loop, so
# every timer that counts from the loop's cached "now" is long overdue.
# Use: PERL5OPT=-MSlowStart prove -It/lib -l t/<file>
use strict;
use warnings;
use EV;

EV::run(EV::RUN_NOWAIT());
select undef, undef, undef, 3;

1;
