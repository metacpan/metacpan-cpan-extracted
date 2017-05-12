use Test::More;
use Plack::Test;
use HTTP::Request::Common;

{

    package TestAppAnyUser;

    use Dancer2;
    use Dancer2::Plugin::Auth::HTTP::Basic::DWIW;

    get '/' => http_basic_auth required => sub {
        my ( $user, $password ) = http_basic_auth_login;

        return $password;
    };
}

# credentials are: test:foo:bar
my $test1 = Plack::Test->create( TestAppAnyUser->to_app );
my $res1  = $test1->request( GET '/' );
is( $res1->code, 401,
    '[Any User, no Authorization header] Correct status code (401)' );
is(
    $res1->header('WWW-Authenticate'),
    'Basic realm="Please login"',
    '[Any user, no Authorization header] Correct WWW-Authenticate header'
);

my $test2 = Plack::Test->create( TestAppAnyUser->to_app );
my $res2  = $test2->request(
    HTTP::Request->new( 'GET', '/', [ 'Authorization', 'Basic dGVzdDpmb286YmFy==' ] ) );

is( $res2->code, 200,
    '[Any user, valid Authorization header] Correct status code (200)' );

is( $res2->content, 'foo:bar',
    '[Any user, valid Authorization header] Correct body content' );

done_testing;
