use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'no-default-pages';
}

{

    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible;

    get '/login' => sub {
        return "Not the default login page";
    };

    get '/login/denied' => sub {
        return "Not the default denied page";
    };
}

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

{
    my $res = $test->request( GET '/login' );
    ok $res->is_success, "GET /login response is OK";
    is $res->content,    "Not the default login page",
      "... and we see our custom login page";
}
{
    my $res = $test->request( GET '/login/denied' );
    ok $res->is_success, "GET /login/denied response is OK";
    is $res->content,    "Not the default denied page",
      "... and we see our custom login page";
}

done_testing;
