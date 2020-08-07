use Test::More tests => 1;
use Plack::Test;
use HTTP::Request::Common;

{
    package TestCanAccessAppInstance;

    use Dancer2;
    use Dancer2::Plugin::Auth::HTTP::Basic::DWIW;

    get '/' => http_basic_auth required => sub {
        my $app = shift;
        return ref $app;
    };
}

my $test = Plack::Test->create(TestCanAccessAppInstance->to_app);
my $res = $test->request(
    HTTP::Request->new('GET', '/', ['Authorization', 'Basic Zm9vOmJhcg=='])
);

is($res->content, 'Dancer2::Core::App',
    '[Can access Dancer2 App] First argument given to sub is Dancer2::Core::App');
