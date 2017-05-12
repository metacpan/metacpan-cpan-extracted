#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More; 
use Catalyst::Test 'TestApp';

is get('/view_test/normal'),    'view rendered', 'normal view rendering';
is get('/view_test/role_test'), 'view rendered modified', 'view role changed rendering';


done_testing;
