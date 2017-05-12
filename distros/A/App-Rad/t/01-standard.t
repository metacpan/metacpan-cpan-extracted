use Test::More tests => 14;

use App::Rad;

# tests the existance of the API
my $m = 'App::Rad';
can_ok($m, 'commands');
can_ok($m, 'create_command_name');
can_ok($m, 'run');

#tests the existance of the control functions
can_ok($m, 'setup');
can_ok($m, 'pre_process');
can_ok($m, 'post_process');
can_ok($m, 'default');
can_ok($m, 'teardown');

# tests the existance of basic commands
use App::Rad::Exclude;
$m = 'App::Rad::Exclude';
can_ok($m, 'load');
can_ok($m, 'exclude');

use App::Rad::Include;
$m = 'App::Rad::Include';
can_ok($m, 'load');
can_ok($m, 'include');

$m = 'App::Rad::Help';
can_ok($m, 'load');
can_ok($m, 'help');

