use strict;
use Test::More 0.98;

use_ok $_ for qw(
    App::CpanfileSlipstop
    App::CpanfileSlipstop::CLI
    App::CpanfileSlipstop::Resolver
    App::CpanfileSlipstop::Writer
);

done_testing;
