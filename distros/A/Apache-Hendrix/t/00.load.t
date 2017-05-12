use strict;
use warnings;
use Apache::Test;
use Test::More;

BEGIN {
    use_ok('Apache::Dancerish');
}

diag("Testing Apache::Dancerish $Apache::Dancerish::VERSION");

done_testing();
