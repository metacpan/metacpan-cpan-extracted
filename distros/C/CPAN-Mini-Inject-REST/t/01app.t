#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'CPAN::Mini::Inject::REST';

ok( request('/')->is_success, 'Request should succeed' );

done_testing();
