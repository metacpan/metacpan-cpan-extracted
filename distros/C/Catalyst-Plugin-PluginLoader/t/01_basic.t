use strict;
use warnings;

use Test::More tests => 6;

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test "MyApp";

# 4 tests run from 4 plugins' setup methods

is(get('/'), "MyApp::Plugin::One Catalyst::Plugin::Two Catalyst::Plugin::Three",
    'plugin methods work');

is(get('/test_role'), 'mtfnpy',
    'loading roles works');
