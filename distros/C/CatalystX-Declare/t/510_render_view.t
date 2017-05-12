#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More; 

eval { require Catalyst::Action::RenderView };
plan skip_all => 'Catalyst::Action::RenderView required' 
    if $@;

use Catalyst::Test 'RenderViewTestApp';

is get('/foo'), 'RenderViewTestApp::View::Test', 'view was reached via RenderView';

done_testing;
