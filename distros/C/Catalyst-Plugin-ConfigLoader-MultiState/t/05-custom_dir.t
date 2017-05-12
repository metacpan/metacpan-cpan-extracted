use strict;
use warnings;
use Test::More qw/no_plan/;
use FindBin;
use lib "$FindBin::Bin/lib";

use TestApp {
    'Plugin::ConfigLoader::MultiState' => {dir => '05-conf'},
};
use Catalyst::Test 'TestApp';

is(TestApp->cfg->{custom_dir}, 'yes', 'custom_dir');
