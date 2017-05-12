use strict;
use warnings;
use Test::More 0.96;
use File::Temp 0.19; # newdir
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;

{
    package App;

    use Dancer2;
    use Dancer2::Plugin::Auth::Tiny;

    set show_errors => 1;
    set session     => 'Simple';
    set plugins     => {
      'Auth::Tiny' => {
        login_route   => '/signin',
        logged_in_key => 'user_id',
        callback_key  => 'next_url',
      },
    };

    get '/public' => sub { return 'index' };

    get '/private' => needs login => sub { return 'private' };

    get '/signin' => sub {
      session "user_id" => "Larry Wall";
      return "login and to back to " . params->{next_url};
    };

    get '/logout' => sub {
      app->destroy_session;
      redirect uri_for('/public');
    };
}

my $test = Plack::Test->create( App->to_app );
my $url  = 'http://localhost';
my $jar  = HTTP::Cookies->new();

subtest 'default' => sub {
    my $res = $test->request( GET "$url/public" );
    is $res->content, 'index', "GET /public works";
};

subtest 'private' => sub {
    my $redir_url;

    {
        my $res = $test->request( GET "$url/private" );

        ok $res->is_redirect, '/private redirects';
        like
            $res->content,
            qr{This item has moved},
            'Correct content';

        $redir_url = $res->header('Location');

        like $redir_url, qr{/signin\?next_url=}, 'GET /private redirects to signin';
        like $redir_url, qr{private}, 'GET /login knows to return to /private';
        $jar->extract_cookies($res);
    }

    {
        my $req = GET $redir_url;
        $jar->add_cookie_header($req);

        my $res = $test->request($req);
        like $res->content, qr{^login and to back to}, '/signin correct response';
    }

    {
        my $req = GET "$url/private";
        $jar->add_cookie_header($req);

        my $res = $test->request($req);
        is $res->content, 'private', "GET /private now works";
    }

    {
        my $req = GET "$url/logout";
        $jar->add_cookie_header($req);

        my $res = $test->request($req);
        ok $res->is_redirect, 'GET /logout redirects';

        $redir_url = $res->header('Location');
        like $redir_url, qr{/public}, 'GET /logout redirects to public';

        $jar->extract_cookies($res);
    }

    {
        my $req = GET $redir_url;
        $jar->add_cookie_header($req);

        my $res = $test->request($req);
        is $res->content, 'index', '/public returns index';
    }

    {
        my $req = GET "$url/private";
        $jar->add_cookie_header($req);

        my $res = $test->request($req);
        ok $res->is_redirect, 'GET /private redirects';
        like $res->header('Location'), qr{/signin}, 'GET /private redirects to login again';
    }
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
