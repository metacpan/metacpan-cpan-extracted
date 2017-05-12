use Test::More;
use App::DoubleUp;

my $app = App::DoubleUp->new({config_file => 't/doubleuprc'});
$app->process_args(qw/listdb/);

is_deeply([$app->credentials], [qw/testuser testpass/]);

is($app->command, 'listdb');
is_deeply($app->database_names, ['ww_test']);

done_testing();
