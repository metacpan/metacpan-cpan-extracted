use strict;
use warnings;
use 5.008_001;

use Test::More 0.98;

use App::Memcached::CLI::Constants ':all';
use App::Memcached::CLI::Util ':all';

subtest 'With no args' => sub {
    is(create_addr(), DEFAULT_ADDR(), DEFAULT_ADDR());
};

subtest 'With ipaddr with port' => sub {
    my $addr = '192.168.0.1:1986';
    is(create_addr($addr), $addr, $addr);
};

subtest 'With ipaddr only' => sub {
    my $addr = '192.168.0.1';
    my $expect = $addr . ':' . DEFAULT_PORT();
    is(create_addr($addr), $expect, $expect);
};

done_testing;

