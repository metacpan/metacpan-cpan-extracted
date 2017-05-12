use strict;
use warnings;
use Test::More qw/no_plan/;
use FindBin;
use lib "$FindBin::Bin/lib";

use TestApp {
    'Plugin::ConfigLoader::MultiState' => {local => '07-local.conf'},
};
use Catalyst::Test 'TestApp';

is(TestApp->cfg->{custom_local}, 'yes', 'custom_local');
