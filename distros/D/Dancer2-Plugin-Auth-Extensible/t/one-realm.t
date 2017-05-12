use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use lib 't/lib';

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'one-realm';
}

{

    package TestApp;
    use Test::More;
    use Test::Deep;
    use Test::Fatal;
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible;

    my $plugin = app->with_plugin('Auth::Extensible');

    is exception {
        $plugin->create_user( username => 'one-realm1', password => 'pwd1' );
    }, undef, "No need to pass realm to create_user since we have only one.";

    post '/create_user' => sub {
        my $params = body_parameters->as_hashref;
        my $user   = create_user %$params;
        return $user ? 1 : 0;
    };

    post '/update_user' => sub {
        my $params   = body_parameters->as_hashref;
        my $username = delete $params->{username};
        my $user     = update_user $username, %$params;
        return $user->{name};
    };
}

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
my $url  = 'http://localhost';
my $trap = TestApp->dancer_app->logger_engine->trapper;

{
    my $res =
      $test->request( POST "$url/create_user", [ username => 'one-realm2' ] );
    ok $res->is_success, "POST /create_user is_success";
    is $res->content, 1, "... and response shows user was created.";
}
{
    my $res =
      $test->request( POST "$url/update_user", [ username => 'one-realm2', name => 'fred' ] );
    ok $res->is_success, "POST /update_user is_success"
      or diag explain $trap->read;
    is $res->content, 'fred', "... and response shows user was updated.";
}

done_testing;
