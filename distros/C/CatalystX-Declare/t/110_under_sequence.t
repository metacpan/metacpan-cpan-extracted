#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More; 
use Catalyst::Test 'TestApp';

is get('/under_seq/foo'), 'foo', 'basic action';
is get('/under_seq/bar/test_bar'), 'bar', 'first action in under scope';
is get('/under_seq/baz/test_baz'), 'baz', 'following base and under scope';

done_testing;


