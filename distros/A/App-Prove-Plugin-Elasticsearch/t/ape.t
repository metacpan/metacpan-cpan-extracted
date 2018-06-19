use strict;
use warnings;

use Test::More tests => 2;
use FindBin;

require_ok("$FindBin::Bin/../bin/ape");

no warnings qw{redefine once};
local *App::ape::new = sub { return bless({},"App::ape::grape") };
local *App::ape::grape::run = sub { return 1 };
use warnings;

is(Bin::ape::main(),1,"ape binary can run all the way through");
