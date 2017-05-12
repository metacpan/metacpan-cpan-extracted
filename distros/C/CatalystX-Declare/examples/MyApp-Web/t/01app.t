#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../../lib";

BEGIN { use_ok 'Catalyst::Test', 'MyApp::Web' }

ok( request('/')->is_success, 'Request should succeed' );
