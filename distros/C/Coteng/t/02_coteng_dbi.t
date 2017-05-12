use strict;
use warnings;

use t::cotengtest;
use Test::More;

subtest use => sub {
    use_ok "Coteng::DBI";
};

done_testing;
