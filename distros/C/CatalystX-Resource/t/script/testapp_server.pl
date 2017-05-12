#!/usr/bin/env perl

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../../lib";

BEGIN {
    $ENV{CATALYST_SCRIPT_GEN} = 40;
}

use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('TestApp', 'Server');

1;
