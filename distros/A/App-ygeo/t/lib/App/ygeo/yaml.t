#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN { use_ok( 'App::ygeo::yaml', qw[:ALL] ); }

subtest "keys_exists_no_empty" => sub {
    ok keys_exists_no_empty( { api_key => 1111, city => 'ROV' },
        [ 'api_key', 'city' ] ),
      'all ok';
    ok !keys_exists_no_empty( { api_key => 1111 }, [ 'api_key', 'city' ] ),
      'no key';
    ok !keys_exists_no_empty(
        { api_key => 1111, city => '' },
        [ 'api_key', 'city' ]
      ),
      'has key but empty val';
};

done_testing;
