use strict;
use warnings;

use Test::Fatal;
use Test::More;
use lib 't/lib';

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'memcached';

    eval 'use Cache::Memcached';
    plan skip_all => "Cache::Memcached required to run these tests" if $@;

    eval 'use Dancer2::Session::Memcached 0.003';
    plan skip_all => "Dancer2::Session::Memcached >= 0.003 required to run these tests" if $@;
}

my $memd = Cache::Memcached->new(servers =>['127.0.0.1:11211']);
$memd->set( dancer2_plugin_pagehistory => 1 );

plan skip_all => "Cannot run tests: memcached server is not available"
  unless $memd->get('dancer2_plugin_pagehistory');

diag "Cache::Memcached $Cache::Memcached::VERSION Dancer2::Session::Memcached $Dancer2::Session::Memcached::VERSION";

use Tests;

Tests::run_tests();

done_testing;
