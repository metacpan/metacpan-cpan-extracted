use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'no-reset-password-handler';
}

{

    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible;
    set logger => 'null';
}

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

{
    my $res = $test->request( GET '/login' );
    like $res->content, qr/input.+name="password"/,
      "... and we have the login page.";
    unlike $res->content,
      qr/Enter your username to obtain an email to reset your password/,
      "... which does NOT have password reset option (reset_password_handler=>0).";
}

done_testing;
