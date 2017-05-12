#!perl

use strict;
use Test::More tests => 1;

BEGIN{
    require_ok 'App::cpantimes';

    # in the future ...
    # require_ok 'App::cpanminus::script'; 
}

diag("App::cpantimes/$App::cpantimes::VERSION");

__DATA__
