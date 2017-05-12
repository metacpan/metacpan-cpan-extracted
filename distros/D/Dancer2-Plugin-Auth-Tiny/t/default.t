use strict;
use warnings;
use Test::More 0.96;
use File::Temp 0.19; # newdir
use Plack::Test;
use HTTP::Cookies;
use HTTP::Request;

{
    package App;
    use Dancer2;
    use Dancer2::Plugin::Auth::Tiny;

    set show_errors => 1;
    set session     => 'Simple';

    get '/public' => sub { return 'index' };

    get '/private' => needs login => sub { return 'private' };

    get '/login' => sub {
      session "user" => "Larry Wall";
      return "login and to back to " . params->{return_url};
    };

    get '/logout' => sub {
      app->destroy_session;
      redirect uri_for('/public');
    };
}

my $test = Plack::Test->create( App->to_app );
my $jar  = HTTP::Cookies->new();
my $url  = 'http://localhost';

subtest '/public' => sub {
    my $req = HTTP::Request->new( GET => "$url/public" );
    $jar->add_cookie_header($req);

    my $res = $test->request($req);
    like $res->content, qr/index/i, "GET /public works";

    $jar->extract_cookies($res);
};

subtest 'changing private' => sub {
    my $login_url;

    {
        my $req = HTTP::Request->new( GET => "$url/private" );
        $jar->add_cookie_header($req);

        my $res = $test->request($req);
        ok $res->is_redirect, 'GET /private redirects';
        like $res->header('Location'), qr{/login\?return_url=}, 'GET /private redirects to /login';
        like
            $res->content,
            qr{This item has moved},
            'Correct content';

        $login_url = $res->header('Location');

        $jar->extract_cookies($res);
    }

    {
        my $req = HTTP::Request->new( GET => $login_url );
        $jar->add_cookie_header($req);

        my $res = $test->request($req);
        like $res->content, qr/login and to back to/, 'GET /login succeeds';
        $jar->extract_cookies($res);
    }

    {
        my $req = HTTP::Request->new( GET => "$url/private" );
        $jar->add_cookie_header($req);

        my $res = $test->request($req);
        like $res->content, qr/private/i, "GET /private now works";

        $jar->extract_cookies($res);
    }
};

subtest 'logout' => sub {
    my $req = HTTP::Request->new( GET => "$url/logout" );
    $jar->add_cookie_header($req);

    my $res = $test->request($req);
    ok $res->is_redirect, 'GET /logout redirects';
    like $res->header('Location'), qr{/public}, 'GET /logout redirects to public';
    like
        $res->content,
        qr{This item has moved},
        'Correct content';

    $jar->extract_cookies($res);
};

subtest 'private redirects again' => sub {
    my $req = HTTP::Request->new( GET => "$url/private" );
    $jar->add_cookie_header($req);

    my $res = $test->request($req);
    ok $res->is_redirect, 'GET /private redirects';
    like $res->header('Location'), qr{/login}, 'GET /private redirects to login again';
    like
        $res->content,
        qr{This item has moved},
        'Correct content';
};

done_testing;
#
# This file is part of Dancer2-Plugin-Auth-Tiny
#
# This software is Copyright (c) 2016 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

