package CHI::Driver::MemcachedFast::t::Sanity;
use strict;
use warnings;
use CHI::Driver::Memcached::Test;
use base qw(CHI::Driver::MemcachedFast::Test::Class);

sub test_ok : Test(1) {
    ok( 1, '1 is ok' );
}

1;
