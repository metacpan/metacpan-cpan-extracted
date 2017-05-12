BEGIN {
    $ENV{PERL_DATETIME_PP} = 1;
}

use strict;
use warnings;

use Test::More 0.88;

use_ok('DateTime');

done_testing();

