use strict;
use warnings;

use Test::More tests => 6;
use Plack::Test;
use HTTP::Request::Common;

{
    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Flash;

    BEGIN {
        set plugins => {
            Flash => {
                token_name => 'flash',
                session_hash_key => '_flash'
            },
        };
        setting views => path('t', 'views');
    }

    get '/nothing' => sub {
        template 'index', { foo => 'bar' };
    };

    get '/' => sub {
        template 'index', { };
    };

    get '/different' => sub {
        flash(error => 'plop');
        template 'index', { foo => 'bar' };
    };

}

{
    my $app  = TestApp->to_app;
    my $test = Plack::Test->create($app);

    my $res = $test->request( GET '/nothing' );
    is( $res->code, 200, '[GET /nothing] Request successful' );
    like( $res->content, qr/foo : bar, message :\s*$/, '[GET /nothing] Correct content' );

    $res = $test->request( GET '/' );
    is( $res->code, 200, '[GET /] Request successful' );
    like( $res->content, qr/foo :\s*, message :\s*$/, '[GET /] Correct content' );

    $res = $test->request( GET '/different' );
    is( $res->code, 200, '[GET /different] Request successful' );
    like( $res->content, qr/foo : bar, message : plop$/, '[GET /different] Correct content' );

}
