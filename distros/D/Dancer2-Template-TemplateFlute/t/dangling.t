use strict;
use warnings;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'dangling';
}

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

{
    package TestApp;
    use Dancer2;

    get '/' => sub {
        template product => {};
    };
}

my $test = Plack::Test->create( TestApp->to_app );
my $trap = TestApp->dancer_app->logger_engine->trapper;

my $res = $test->request( GET '/' );
ok $res->is_success, "GET / successful";
like $res->content, qr/product-gallery/, "content looks good for /";

my $logs = $trap->read;
ok( @$logs == 4, "Found 4 logs" ) or diag explain $logs;
foreach my $log (@$logs) {
    is $log->{level}, "debug", "Debug found";
    like $log->{message}, qr/Found dangling element/, "log looks good";
}

done_testing;
