use warnings;
use v5.22;

use lib ".";
use t::CLI;

use Test::More;

my $app = t::CLI->new;

{    # subtype_name
    $app->run('name:family');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('name:last');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('male:given');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('female:first');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('name:gender');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('name:sex');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('female:unknown');
    is $app->exit_code, 255;
    ok !$app->stdout;
    ok !$app->stderr;
    is $app->error_message, "Error: unknown subtype or rendering: unknown\n";
}

{    #subtype_address
    $app->run('address:prefecture');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('address:city');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('address:town');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run('address:unknown');
    is $app->exit_code, 255;
    ok !$app->stdout;
    ok !$app->stderr;
    is $app->error_message, "Error: unknown subtype or rendering: unknown\n";
}

done_testing;
