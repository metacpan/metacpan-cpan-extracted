#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More; 
use Catalyst::Test 'PlainTestApp';

is get('/foo'), 'foo', 'view was reached via RenderView';

done_testing;

