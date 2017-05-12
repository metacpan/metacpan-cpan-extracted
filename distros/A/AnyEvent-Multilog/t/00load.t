use strict;
use warnings;
use Test::More;

use t::lib::multilog qw(check_multilog);

BEGIN {
    check_multilog 1;
}

use ok 'AnyEvent::Multilog';

done_testing;
