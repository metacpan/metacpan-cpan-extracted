#!/usr/bin/env perl

BEGIN {
    $ENV{CATALYST_SCRIPT_GEN} = 40;
}

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../../../lib", "$FindBin::Bin/../../../inc";
use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('TestApp', 'Server');

1;
