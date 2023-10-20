use warnings;
use v5.22;

use lib ".";
use t::CLI;

use Test::More;

my $app = t::CLI->new;

{    # default
    $app->run('name');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+\s\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;
}

{    # address->romaji
    $app->run('address:romaji');
    is $app->exit_code, 255;
    ok !$app->stdout;
    ok !$app->stderr;
    is $app->error_message, "Error: rendering romaji is not supported for address\n";
}

{    # gender
    $app->run('name:gender');
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;
}

{
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
}

{    # unknown rendering
    $app->run('address:prefecture:romaji');
    is $app->exit_code, 255;
    ok !$app->stdout;
    ok !$app->stderr;
    is $app->error_message, "Error: rendering romaji is not supported for address\n";
}

done_testing;
