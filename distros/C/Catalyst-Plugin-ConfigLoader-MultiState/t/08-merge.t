use strict;
use warnings;
use Test::More qw/no_plan/;
use FindBin;
use lib "$FindBin::Bin/lib";

use TestApp {
    'Plugin::ConfigLoader::MultiState' => {local => '08-local.conf', dir => '08-conf'},
};
use Catalyst::Test 'TestApp';

is(TestApp->cfg->{core}, 'left', 'merge1');
is(TestApp->cfg->{local_here}, 1, 'merge2');

is(TestApp->cfg->{s}, 2, 'merge_scalar');
is_deeply(TestApp->cfg->{a}, [4,5,6], 'merge_array');
is_deeply(TestApp->cfg->{h}, {
    a => 1, b => 4, c => 3, d => 5,
    hs => {k1 => 'v11', k2 => 'v2', k3 => 'v3'},
}, 'merge_hash');

