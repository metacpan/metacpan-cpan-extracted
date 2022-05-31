use warnings;
use v5.22;

use lib ".";
use t::CLI;

use Test::More;

my $app = t::CLI->new;

{    # number expected
    $app->run(qw|-n Alice|);
    is $app->exit_code, 255;
    ok !$app->stdout;
    ok !$app->stderr;
    is $app->error_message,
      "Error: Value \"Alice\" invalid for option n (number expected)\n";
}

{    # positive number expected
    $app->run(qw|-n -1|);
    is $app->exit_code, 255;
    ok !$app->stdout;
    ok !$app->stderr;
    is $app->error_message,
      "Error: value -1 invalid for option n (must be positive number)\n";
}

{    # -n 1
    $app->run(qw|-n 1|);
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+\s\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;
}

{    # -n 2
    $app->run(qw|-n 2 name:family|);
    is $app->exit_code, 0;
    like $app->stdout, qr/^\S+\n\S+$/;
    ok !$app->stderr;
    ok !$app->error_message;
}

done_testing;

