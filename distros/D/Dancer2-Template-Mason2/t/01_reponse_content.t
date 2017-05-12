use Test::More tests => 4;
use Plack::Test;
use HTTP::Request::Common;

{

    package MyApp;
    use Dancer2;

    set template => 'mason2';
    set engines  => {
        template => {
            mason2 => {},
        },
    };

    get '/nolayout' => sub { template 'index', {}, { layout => undef } };
    get '/layout' => sub { template 'index', {}, { layout => 'main' } };

}

my $app   = MyApp->to_app;
my $plack = Plack::Test->create($app);

test_psgi $app, sub {
    my $res = $plack->request( GET '/nolayout' );
    is( $res->code, 200, '[GET /] Request successful' );
    like( $res->content, qr/hello, world/, '[GET /] Correct content' );
};

test_psgi $app, sub {
    my $res = $plack->request( GET '/layout' );
    is( $res->code, 200, '[GET /] Request successful' );
    like( $res->content, qr/hello, world/, '[GET /] Correct content' );
};

done_testing;
