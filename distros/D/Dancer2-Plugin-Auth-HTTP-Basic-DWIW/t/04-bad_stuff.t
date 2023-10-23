use Test::More;
use Plack::Test;
use HTTP::Request::Common;

{

    package TestAppCrashingHandler;

    use Dancer2;
    use Dancer2::Plugin::Auth::HTTP::Basic::DWIW;

    http_basic_auth_handler check_login => sub {
        my ( $user, $pass ) = @_;
        die 'foo';
        return $user eq 'foo' && $pass eq 'bar';
    };

    get '/' => http_basic_auth required => sub {
        my ( $user, $password ) = http_basic_auth_login;

        return $user;
    };
}

my $test2 = Plack::Test->create( TestAppCrashingHandler->to_app );
my $res2  = $test2->request(
    HTTP::Request->new( 'GET', '/', [ 'Authorization', 'Basic Zm9vOmJhcg==' ] )
);

is( $res2->code, 500,
    '[Crashing handler] Correct status code (500)' );

done_testing;
