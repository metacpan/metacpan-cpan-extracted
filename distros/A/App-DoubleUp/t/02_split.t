use Test::More tests => 4;
use App::DoubleUp;
use Data::Dumper;

my $app = App::DoubleUp->new();
my @stmts = $app->split_sql_file('test.sql');
is(@stmts, 3);

is($stmts[0], "CREATE TABLE IF NOT EXISTS `test` (\n   `test` INT\n)");
is($stmts[1], "SELECT 1 FROM `test`");
is($stmts[2], "SELECT 2 FROM `test`");
