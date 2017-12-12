use strict;
use warnings;

use Test::More tests => 1;
BEGIN { 
    SKIP: {
        eval "use Module::Refresh";
        skip "Module::Refresh not installed", 1 if $@;
        use_ok('App::PerlShell::ModRefresh')
    }
};
