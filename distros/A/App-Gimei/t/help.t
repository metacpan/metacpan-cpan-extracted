use warnings;
use v5.22;

use lib ".";
use t::CLI;

use Test::More;

my $app = t::CLI->new;

$app->run('-help');
is $app->exit_code, 0;
ok $app->stdout;
ok !$app->stderr;
ok !$app->error_message;

$app->run('-h');
is $app->exit_code, 0;
ok $app->stdout;
ok !$app->stderr;
ok !$app->error_message;

done_testing;
