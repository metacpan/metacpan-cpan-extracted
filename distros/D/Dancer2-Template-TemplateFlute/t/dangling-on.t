use strict;
use warnings;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = undef;
}

use Test::More;
use Test::Deep;
use Plack::Test;
use HTTP::Request::Common;

{

    package TestApp;
    use Dancer2;

    get '/' => sub {
        template product => {};
    };
}

subtest 'no environment' => sub {
    my $app = TestApp->to_app;
    is ref $app, 'CODE', 'Got app';

    my $test = Plack::Test->create($app);
    my $trap = TestApp->dancer_app->logger_engine->trapper;

    my $res = $test->request( GET '/' );
    ok $res->is_success, "GET / successful";

    like $res->content, qr/product-gallery/, "content looks good for /";

    my $expected = {
        level   => 'debug',
        message => re(qr/Found dangling element/),
    };

    my $logs = $trap->read;
    cmp_deeply $logs,
      superbagof(
        superhashof($expected), superhashof($expected),
        superhashof($expected), superhashof($expected),
      ),
      "Got debug log 'Found dangling element' four times"
      or diag explain $logs;
};

{

    package TestProduction;
    use Dancer2;

    set environment => 'production';

    get '/' => sub {
        template product => {};
    };
}

subtest 'production' => sub {
    my $app = TestProduction->to_app;
    is ref $app, 'CODE', 'Got app';

    my $test = Plack::Test->create($app);
    my $trap = TestProduction->dancer_app->logger_engine->trapper;

    my $res = $test->request( GET '/' );
    ok $res->is_success, "GET / successful";

    like $res->content, qr/product-gallery/, "content looks good for /";

    my $logs = $trap->read;
    is_deeply $logs, [], "No logs found in production" or diag explain $logs;
};

done_testing;
