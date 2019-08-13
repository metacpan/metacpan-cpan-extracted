#!perl

use strict;
use Test::More tests => 13;

use_ok("Check::GlobalPhase");

foreach my $phase (
    qw/
    PERL_PHASE_CONSTRUCT
    PERL_PHASE_START
    PERL_PHASE_CHECK
    PERL_PHASE_INIT
    PERL_PHASE_RUN
    PERL_PHASE_END
    /
    )
{
    my $constsub = Check::GlobalPhase->can($phase);
    ok $constsub;
    ok defined $constsub->(), "$phase";
}

done_testing;
