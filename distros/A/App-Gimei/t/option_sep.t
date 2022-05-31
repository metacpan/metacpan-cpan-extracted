use warnings;
use v5.22;

use lib ".";
use t::CLI;

use Test::More;

my $app = t::CLI->new;

{
    $app->run(qw|-sep :|);
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+\s\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;

    $app->run(qw|-sep : address:prefecture address:city|);
    is $app->exit_code, 0;
    like $app->stdout, qr/^[^:]+:[^:]+$/;
    ok !$app->stderr;
    ok !$app->error_message;
}

done_testing;
