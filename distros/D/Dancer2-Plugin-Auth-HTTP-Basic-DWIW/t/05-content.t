use Test::More tests => 8;
use Plack::Test;
use HTTP::Request::Common;

{

    package TestAppAuthCheck;

    use Dancer2;
    use Dancer2::Plugin::Auth::HTTP::Basic::DWIW;

    http_basic_auth_handler check_login => sub {
        my ( $user, $pass ) = @_;
        
        return $user eq 'foo' && $pass eq 'bar';
    };

    http_basic_auth_handler no_auth => sub {
        return 'Not authenticated!';
    };

    get '/' => http_basic_auth required => sub {
        my ( $user, $password ) = http_basic_auth_login;

        return $user;
    };
}

my $test1 = Plack::Test->create( TestAppAuthCheck->to_app );
my $res1  = $test1->request( GET '/' );
is( $res1->code, 401,
    '[Checked User, no Authorization header] Correct status code (401)' );
is(
    $res1->header('WWW-Authenticate'),
    'Basic realm="Please login"',
    '[Checked user, no Authorization header] Correct WWW-Authenticate header',
);
is(
    $res1->content,
    'Not authenticated!',
    '[Checked user, no Authorization header] Correct body returned',
);

my $test2 = Plack::Test->create( TestAppAuthCheck->to_app );
my $res2  = $test2->request(
    HTTP::Request->new( 'GET', '/', [ 'Authorization', 'Basic Zm9vOmJhcg==' ] )
);

is( $res2->code, 200,
    '[Checked user, correct login] Correct status code (200)' );
is( $res2->content, 'foo',
    '[Checked user, correct login] Correct body content' );

my $test3 = Plack::Test->create( TestAppAuthCheck->to_app );
my $res3  = $test3->request(
    HTTP::Request->new(
        'GET', '/', [ 'Authorization', 'Basic YmxhOmJsdWJiCg==' ]
    )
);

is( $res3->code, 401,
    '[Checked user, incorrect login] Correct status code (401)' );
is(
    $res3->header('WWW-Authenticate'),
    'Basic realm="Please login"',
    '[Checked user, incorrect login] Correct WWW-Authenticate header'
);
is(
    $res3->content,
    'Not authenticated!',
    '[Checked user, no Authorization header] Correct body returned',
);
