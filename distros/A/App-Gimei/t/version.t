use warnings;
use v5.22;

use lib ".";
use t::CLI;

use App::Gimei;
use Test::More;

my $app = t::CLI->new;

$app->run('-version');
is $app->exit_code, 0;
is $app->stdout,    "$App::Gimei::VERSION\n";
ok !$app->stderr;
ok !$app->error_message;

$app->run('-v');
is $app->exit_code, 0;
is $app->stdout,    "$App::Gimei::VERSION\n";
ok !$app->stderr;
ok !$app->error_message;

done_testing;
