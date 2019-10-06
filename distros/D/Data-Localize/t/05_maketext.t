use strict;
use Cwd ();
BEGIN {
    unshift @INC, Cwd::abs_path()
}
use utf8;
use Test::More (tests => 1);

TODO: {
    todo_skip("TODO", 1);
    # define a namespace localizer, and call method names with it:
    # [method,_1] and what not. The infrastructure is there, but
    # I'm going to release first with the speed improvement
}

