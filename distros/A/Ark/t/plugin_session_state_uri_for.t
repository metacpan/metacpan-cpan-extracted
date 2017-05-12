use Test::More;

{
    package T;
    use Ark;

    use_plugins qw{
        Session
        Session::State::URI
        Session::Store::Memory
    };

    config 'Plugin::Session::State::URI' => {
        verify_ua        => undef,
        mobile_only      => undef,
        uri_for_override => undef,
    };

    package T::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub get_sessid :Local {
        my ($self, $c) = @_;

        $c->session->set('dummy' => 1);
        $c->res->body($c->session->session_id);
    }

    sub uri_for :Local {
        my ($self, $c) = @_;

        $c->session->get('dummy');
        $c->res->body($c->uri_for('/hoge'));
    }
}

use Ark::Test 'T',
    components => [qw/Controller::Root/],
    reuse_conneciton => 1;

my $sess_id1 = get '/get_sessid';
unlike get('/uri_for?sid='.$sess_id1), qr/$sess_id1/;

done_testing;
