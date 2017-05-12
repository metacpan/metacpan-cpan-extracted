use strict;
use Test::More;

use App::DoubleUp;
use Path::Tiny;

{
    my $app = App::DoubleUp->new({ config_file => 't/doubleuprc' });
    ok($app);
}

{
    my $app = App::DoubleUp->new({ config_file => 't/doubleuprc' });
    is($app->config_file, 't/doubleuprc');
}

{
    path('.doubleuprc')->spew(<<"CONFIG");
credentials:
  - testuser
  - testpass
source:
  type: config
  databases:
    - ww_test
    - ww_blurp
CONFIG
    my $app = App::DoubleUp->new();
    is($app->config_file, './.doubleuprc');
}

done_testing();
