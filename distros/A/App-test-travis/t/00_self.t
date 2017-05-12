use strict;
use warnings;
use Test::More;

use App::test::travis;

for my $config(glob('t/lang/*.yml')) {
    is(App::test::travis->run('--dry-run', $config), 0, $config);
}

done_testing;

