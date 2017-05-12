#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use lib 't/lib';
use App::Mimosa::Test;
use Test::DBIx::Class;

fixtures_ok 'basic_ss';

ok( request('/')->is_success, 'Request should succeed' );

done_testing();
