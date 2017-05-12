use Test::More;
use App::DoubleUp;

my $app = App::DoubleUp->new();
$app->process_args(qw/import1 dbname file1 file2/);

is($app->command, 'import');
is_deeply($app->database_names, [qw/dbname/]);
is_deeply($app->files, [qw/file1 file2/]);

done_testing();
