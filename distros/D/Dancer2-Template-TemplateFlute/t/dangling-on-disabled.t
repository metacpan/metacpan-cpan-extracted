use strict;
use warnings;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'disable-check-dangling';
}

use Test::More;
use Test::Deep;
use Plack::Test;
use HTTP::Request::Common;

{

    package TestDisableCheckDangling;
    use Dancer2;

    get '/' => sub {
        template product => {};
    };
}

subtest 'development with disable_check_dangling' => sub {
    my $app = TestDisableCheckDangling->to_app;
    is ref $app, 'CODE', 'Got app';

    my $test = Plack::Test->create($app);
    my $trap = TestDisableCheckDangling->dancer_app->logger_engine->trapper;

    my $res = $test->request( GET '/' );
    ok $res->is_success, "GET / successful";

    like $res->content, qr/product-gallery/, "content looks good for /";

    my $logs = $trap->read;
    is_deeply $logs, [],
      "No logs found in development with disable_check_dangling"
      or diag explain $logs;
};

done_testing;
