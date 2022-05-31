use warnings;
use v5.22;

use lib ".";
use t::CLI;

use Test::More;

my $app = t::CLI->new;

$app->run();
is $app->exit_code, 0;
like $app->stdout, qr/^\S+\s\S+$/;
ok !$app->stderr;
ok !$app->error_message;

$app->run('name');
is $app->exit_code, 0;
like $app->stdout, qr/^\S+\s\S+$/;
ok !$app->stderr;
ok !$app->error_message;

$app->run('male');
is $app->exit_code, 0;
like $app->stdout, qr/^\S+\s\S+$/;
ok !$app->stderr;
ok !$app->error_message;

$app->run('female');
is $app->exit_code, 0;
like $app->stdout, qr/^\S+\s\S+$/;
ok !$app->stderr;
ok !$app->error_message;

$app->run('address');
is $app->exit_code, 0;
like $app->stdout, qr/^\S+$/;
ok !$app->stderr;
ok !$app->error_message;

$app->run('NOT_SUPPORTED');
is $app->exit_code,     255;
is $app->stdout,        '';
is $app->stderr,        '';
is $app->error_message, "Error: unknown word_type: NOT_SUPPORTED\n";

done_testing;
