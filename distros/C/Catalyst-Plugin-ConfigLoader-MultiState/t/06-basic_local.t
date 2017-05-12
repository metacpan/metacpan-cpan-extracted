use strict;
use warnings;
use Test::More qw/no_plan/;
use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

is(TestApp->cfg->{local_ok}, 'yup', 'basic_local');
