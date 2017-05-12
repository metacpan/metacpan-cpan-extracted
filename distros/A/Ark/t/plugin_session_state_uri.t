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
        verify_ua   => undef,
        mobile_only => undef,
    };

    package T::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub get_sessid :Local {
        my ($self, $c) = @_;

        $c->session->set('dummy' => 1);
        $c->res->body($c->session->session_id);
    }

    sub counter :Local {
        my ($self, $c) = @_;

        my $count = $c->session->get('counter') || 0;
        $c->session->set( counter => ++$count );

        $c->res->body($count);
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
is get('/counter?sid='. $sess_id1), 1, 'user1 counter 1 ok';
is get('/counter?sid='. $sess_id1), 2, 'user1 counter 2 ok';

my $sess_id2 = get '/get_sessid';
is get('/counter?sid='. $sess_id2), 1, 'user2 counter 1 ok';
is get('/counter?sid='. $sess_id2), 2, 'user2 counter 2 ok';

like get('/uri_for?sid='.$sess_id2), qr/$sess_id2/;

done_testing;
