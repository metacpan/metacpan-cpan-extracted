use 5.010;
use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;

{
    package App;
    use Dancer2;
    use Dancer2::Plugin::Deferred;

    set confdir => '.';

    @{engine('template')->config}{qw(start_tag end_tag)} = qw(<% %>);

    set show_errors => 1;
    set views       => path( 't', 'views' );
    set session     => 'Simple';

    get '/direct/:message' => sub {
      deferred msg => params->{message};
      template 'index';
    };

    get '/indirect/:message' => sub {
      deferred msg => params->{message};
      redirect '/fake';
    };

    get '/fake' => sub {
      redirect '/show';
    };

    get '/show' => sub {
      template 'index';
    };
};

{
    package App2;
    # import plugin a second time
    # https://github.com/PerlDancer/dancer2-plugin-deferred/pull/9
    use Dancer2 appname => 'App';
    use Dancer2::Plugin::Deferred;
}

my $test = Plack::Test->create( App->to_app );
my $url  = "http://localhost/";
my $jar  = HTTP::Cookies->new;

{
    my $res = $test->request(GET $url . "show");
    like $res->content, qr/^message:\s*$/sm, "no messages pending";
    $jar->extract_cookies($res);
}

{
    my $req = GET $url . "direct/hello";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    like $res->content, qr/^message: hello/sm, "message set and returned";
    $jar->extract_cookies($res);
}

{
    my $req = GET $url . "show";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    like $res->content, qr/^message:\s*$/sm, "no messages pending";
    $jar->extract_cookies($res);
}

my $loc;
{
    my $req = GET $url . "indirect/goodbye";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok( $res->is_redirect, 'indirect/goodbye redirects' );
    $loc = $res->header('Location')->as_string;
    like( $loc, qr{^http://localhost/fake}, 'to /fake' );
    $jar->extract_cookies($res);
}

{
    my $req = GET $loc;
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok( $res->is_redirect, '/fake redirects' );
    $loc = $res->header('Location')->as_string;
    like( $loc, qr{^http://localhost/show}, 'to /show' );
    $jar->extract_cookies($res);
}

{
    my $req = GET $loc;
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    like $res->content, qr/^message: goodbye/sm, "message set and returned";
    $jar->extract_cookies($res);
}

{
    my $req = GET $url . "show";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    like $res->content, qr/^message:\s*$/sm, "no messages pending";
    $jar->extract_cookies($res);
}

done_testing;

# COPYRIGHT
