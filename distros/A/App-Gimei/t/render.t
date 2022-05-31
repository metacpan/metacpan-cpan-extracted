use warnings;
use v5.22;

use lib ".";
use t::CLI;

use Test::More;

my $app = t::CLI->new;

{
    $app->run('name');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+\s\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('name:name');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+\s\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('name:kanji');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+\s\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('name:family:hiragana');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('address:katakana');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('address:prefecture:name');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('address:romaji');
    is $app->exit_code, 255;
    ok !$app->stdout;
    ok !$app->stderr;
    is $app->error_message, "Error: unknown subtype or rendering: romaji\n";

    $app->run('address:prefecture:romaji');
    is $app->exit_code, 255;
    ok !$app->stdout;
    ok !$app->stderr;
    is $app->error_message, "Error: unknown subtype or rendering: romaji\n";
}

done_testing;
