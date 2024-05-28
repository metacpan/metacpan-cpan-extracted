use strict;
use warnings;
use Test::More;

use Plack::Request;
use Plack::Test;
use Test::Requires 'Amon2::Lite';

use HTTP::Session::State::URI;

my ($session_id, $session_key) = (undef, 'sid');
my $state = HTTP::Session::State::URI->new(
    session_id_name => $session_key,
);

my $app = do {
    package MyApp::Web;
    use Amon2::Lite;

    sub load_config { +{} }

    __PACKAGE__->template_options(
        syntax => 'Kolon',
    );

    __PACKAGE__->load_plugins(
        'Web::Flash',
        'Web::HTTPSession' => {
            state => $state,
            store => 'OnMemory',
        },
    );

    get '/session' => sub {
        my $c = shift;
        $session_id = $c->session->{session_id};
        $c->render('index.tx', +{
            flash => $c->flash,
        });
    };

    get '/set' => sub {
        my $c = shift;
        $session_id = $c->session->{session_id};
        $c->flash(honey => "Honey");
        $c->flash(apple => "Apple");
        $c->render('index.tx', +{
            flash => $c->flash,
        });
    };

    get '/use' => sub {
        my $c = shift;
        $session_id = $c->session->{session_id};
        $c->render('index.tx', +{
            flash => $c->flash,
        });
    };

    get '/now' => sub {
        my $c = shift;
        $session_id = $c->session->{session_id};
        $c->flash_now(peach => "Peach");
        $c->render('index.tx', +{
            flash => $c->flash,
        });
    };

    get '/discard' => sub {
        my $c = shift;
        $session_id = $c->session->{session_id};
        $c->flash_now(honey => "Honey");
        $c->flash_now(apple => "Apple");
        $c->flash_discard('honey');
        $c->render('index.tx', +{
            flash => $c->flash,
        });
    };

    get '/discard_all' => sub {
        my $c = shift;
        $session_id = $c->session->{session_id};
        $c->flash_now(honey => "Honey");
        $c->flash_now(apple => "Apple");
        $c->flash_discard;
        $c->render('index.tx', +{
            flash => $c->flash,
        });
    };

    get '/keep' => sub {
        my $c = shift;
        $session_id = $c->session->{session_id};
        $c->flash_keep('honey');
        $c->render('index.tx', +{
            flash => $c->flash,
        });
    };

    get '/keep_all' => sub {
        my $c = shift;
        $session_id = $c->session->{session_id};
        $c->flash_now(honey => "Honey");
        $c->flash_keep;
        $c->render('index.tx', +{
            flash => $c->flash,
        });
    };

    __PACKAGE__->to_app;
};

sub deftest($&) {
    my ($desc, $sub) = @_;
    subtest $desc => sub {
        test_psgi(
            app => $app,
            client => sub {
                my $cb = shift;
                $cb->(HTTP::Request->new(GET => "http://localhost/session")); # set session_id
                $sub->($cb);
                done_testing;
            }
        );
    };
}

sub request {
    my ($cb, $action) = @_;

    my $res = $cb->(HTTP::Request->new(GET => "http://localhost/$action?$session_key=$session_id"));
    note $res->content;
    return $res->content;
}

##### Tests starts here ####

deftest 'set and get and turn' => sub {
    my $cb = shift;
    unlike request($cb, 'set'), qr/honey is Honey/;
    like request($cb, 'use'), qr/honey is Honey/;
    unlike request($cb, 'use'), qr/honey is Honey/;
};

deftest 'now' => sub {
    my $cb = shift;
    like request($cb, 'now'), qr/peach is Peach/;
};

deftest 'discard' => sub {
    my $cb = shift;
    my $content = request($cb, 'discard');
    unlike $content, qr/honey is Honey/;
    like $content, qr/apple is Apple/;
};

deftest 'discard_all' => sub {
    my $cb = shift;
    my $content = request($cb, 'discard_all');
    unlike $content, qr/honey is Honey/;
    unlike $content, qr/apple is Apple/;
};

deftest 'keep' => sub {
    my $cb = shift;
    request($cb, 'set');
    request($cb, 'keep');
    my $content = request($cb, 'use');
    like $content, qr/honey is Honey/;
    unlike $content, qr/apple is Apple/;
};

deftest 'keep_all' => sub {
    my $cb = shift;
    request($cb, 'set');
    request($cb, 'keep_all');
    my $content = request($cb, 'use');
    like $content, qr/honey is Honey/;
    like $content, qr/apple is Apple/;
    $content = request($cb, 'use');
    unlike $content, qr/honey is Honey/;
    unlike $content, qr/apple is Apple/;
};

done_testing;

package MyApp::Web;
__DATA__

@@ index.tx
: for $flash.keys() -> $k {
<: $k :> is <: $flash[$k] :>
: }
